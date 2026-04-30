"""
vacky_debug/tools.py — 调试工具实现

提供几个用于观察和调试 hermes-agent 内部状态的工具，
帮助学习 agent 循环、工具调用、上下文管理等机制。
"""

from __future__ import annotations

import inspect
import json
import logging
import os
import sys
import traceback
from typing import Any, Callable

logger = logging.getLogger("vacky.debug")

VACKY_DEBUG = os.getenv("VACKY_DEBUG", "").lower() in ("1", "true", "yes")


def _get_object_state(obj: Any, max_depth: int = 2) -> dict:
    """安全地提取对象的公开属性状态。"""
    if max_depth <= 0:
        return {"_type": type(obj).__name__, "_repr": repr(obj)[:200]}

    state: dict[str, Any] = {"_type": type(obj).__name__}

    for attr_name in dir(obj):
        if attr_name.startswith("_"):
            continue
        try:
            attr_val = getattr(obj, attr_name)
            if callable(attr_val):
                state[attr_name] = f"<method {attr_name}>"
            elif isinstance(attr_val, (str, int, float, bool, type(None))):
                state[attr_name] = attr_val
            elif isinstance(attr_val, (list, tuple)):
                state[attr_name] = f"<list len={len(attr_val)}>"
            elif isinstance(attr_val, dict):
                state[attr_name] = f"<dict keys={list(attr_val.keys())}>"
            else:
                state[attr_name] = _get_object_state(attr_val, max_depth - 1)
        except Exception as e:
            state[attr_name] = f"<error: {e}>"

    return state


def _find_instance(module_name: str, class_name: str) -> Any | None:
    """在已加载的模块中查找指定类的实例（用于 hook 后的对象）。"""
    try:
        mod = sys.modules.get(module_name)
        if not mod:
            return None
        cls = getattr(mod, class_name, None)
        if not cls:
            return None
        # 查找 gc 中该类的实例
        import gc
        for obj in gc.get_objects():
            if isinstance(obj, cls):
                return obj
    except Exception:
        pass
    return None


# ─────────────────────────────────────────
# Tool 1: vacky_inspect_state — 观察对象状态
# ─────────────────────────────────────────

VACKY_INSPECT_STATE_SCHEMA = {
    "name": "vacky_inspect_state",
    "description": (
        "Inspect the runtime state of a named hermes object. "
        "Targets: 'agent' (AIAgent), 'cli' (HermesCLI), 'session' (SessionDB). "
        "Returns a JSON summary of public attributes."
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "target": {
                "type": "string",
                "enum": ["agent", "cli", "session"],
                "description": "Which object to inspect",
            },
            "detail": {
                "type": "string",
                "enum": ["summary", "full"],
                "default": "summary",
                "description": "Level of detail",
            },
        },
        "required": ["target"],
    },
}


def _handle_vacky_inspect_state(args: dict) -> str:
    target = args.get("target", "")
    detail = args.get("detail", "summary")
    max_depth = 3 if detail == "full" else 1

    result: dict[str, Any] = {"target": target, "detail": detail}

    try:
        if target == "agent":
            obj = _find_instance("run_agent", "AIAgent")
            if obj:
                result["state"] = _get_object_state(obj, max_depth)
            else:
                result["error"] = "No AIAgent instance found in memory"
        elif target == "cli":
            obj = _find_instance("cli", "HermesCLI")
            if obj:
                result["state"] = _get_object_state(obj, max_depth)
            else:
                result["error"] = "No HermesCLI instance found in memory"
        elif target == "session":
            from hermes_state import SessionDB
            db = SessionDB()
            result["state"] = {
                "db_path": str(db.db_path) if hasattr(db, "db_path") else "unknown",
                "session_count": db.count_sessions() if hasattr(db, "count_sessions") else "N/A",
            }
        else:
            result["error"] = f"Unknown target: {target}"
    except Exception as e:
        result["error"] = str(e)
        result["traceback"] = traceback.format_exc()

    return json.dumps(result, indent=2, default=str)


# ─────────────────────────────────────────
# Tool 2: vacky_dump_context — 导出当前上下文
# ─────────────────────────────────────────

VACKY_DUMP_CONTEXT_SCHEMA = {
    "name": "vacky_dump_context",
    "description": (
        "Dump the current conversation context / messages to a local file "
        "for offline analysis. File is written to ~/.hermes/logs/vacky-dumps/."
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "label": {
                "type": "string",
                "default": "dump",
                "description": "Label for the dump file",
            },
            "max_messages": {
                "type": "integer",
                "default": 50,
                "description": "Max messages to include",
            },
        },
    },
}


def _handle_vacky_dump_context(args: dict) -> str:
    label = args.get("label", "dump")
    max_messages = args.get("max_messages", 50)

    from hermes_constants import get_hermes_home
    dump_dir = get_hermes_home() / "logs" / "vacky-dumps"
    dump_dir.mkdir(parents=True, exist_ok=True)

    # 尝试从 agent 实例中获取 messages
    messages: list[Any] = []
    try:
        agent = _find_instance("run_agent", "AIAgent")
        if agent and hasattr(agent, "messages"):
            raw = agent.messages
            messages = raw[-max_messages:] if isinstance(raw, list) else []
    except Exception as e:
        return json.dumps({"error": f"Failed to get messages: {e}"})

    dump_path = dump_dir / f"{label}-{__import__('time').time():.0f}.json"
    try:
        dump_data = {
            "label": label,
            "message_count": len(messages),
            "messages": messages,
        }
        dump_path.write_text(
            json.dumps(dump_data, indent=2, default=str),
            encoding="utf-8",
        )
        return json.dumps(
            {"success": True, "path": str(dump_path), "message_count": len(messages)}
        )
    except Exception as e:
        return json.dumps({"error": str(e), "traceback": traceback.format_exc()})


# ─────────────────────────────────────────
# Tool 3: vacky_trigger_breakpoint — 触发断点
# ─────────────────────────────────────────

VACKY_TRIGGER_BREAKPOINT_SCHEMA = {
    "name": "vacky_trigger_breakpoint",
    "description": (
        "Trigger a pdb breakpoint in the current process. "
        "Only works when VACKY_DEBUG=1 is set. "
        "Useful for inspecting live state during agent execution."
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "message": {
                "type": "string",
                "default": "vacky breakpoint triggered",
                "description": "Message to display before breaking",
            },
        },
    },
}


def _handle_vacky_trigger_breakpoint(args: dict) -> str:
    if not VACKY_DEBUG:
        return json.dumps(
            {
                "success": False,
                "message": "Breakpoint skipped (set VACKY_DEBUG=1 to enable)",
            }
        )

    message = args.get("message", "vacky breakpoint triggered")
    print(f"\n{'='*60}")
    print(f"[VACKY DEBUG] {message}")
    print(f"{'='*60}")
    print("Dropping into pdb. Type 'c' to continue, 'q' to quit.")
    print("Local variables are available. Use 'pp locals()' to inspect.")
    print(f"{'='*60}\n")

    import pdb
    pdb.set_trace()

    return json.dumps({"success": True, "message": "Breakpoint resumed"})
