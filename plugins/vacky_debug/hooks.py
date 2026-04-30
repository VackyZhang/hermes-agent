"""
vacky_debug/hooks.py — 调试 Hook 实现

通过注册 hermes 生命周期 hook，在不修改核心代码的前提下
观察 agent 循环、工具调用、LLM 请求等关键环节。

启用方式：
    export VACKY_DEBUG=1
    hermes

所有 hook 只在 VACKY_DEBUG=1 时生效，生产环境无影响。
"""

from __future__ import annotations

import json
import logging
import os
import time
from typing import Any

logger = logging.getLogger("vacky.debug")

VACKY_DEBUG = os.getenv("VACKY_DEBUG", "").lower() in ("1", "true", "yes")

# 运行时统计（用于观察 agent 行为模式）
_stats: dict[str, Any] = {
    "tool_calls": [],
    "llm_calls": [],
    "session_start_time": None,
}


def _format_duration(start: float | None) -> str:
    if start is None:
        return "N/A"
    return f"{time.time() - start:.3f}s"


# ─────────────────────────────────────────
# pre_tool_call — 工具调用前
# ─────────────────────────────────────────

def on_pre_tool_call(**kwargs: Any) -> None:
    """在工具被调用前触发。kwargs 包含 tool_name, arguments, task_id 等。"""
    if not VACKY_DEBUG:
        return

    tool_name = kwargs.get("tool_name", "unknown")
    arguments = kwargs.get("arguments", {})
    task_id = kwargs.get("task_id", "N/A")

    logger.info(
        "[HOOK:pre_tool_call] tool=%s task_id=%s args=%s",
        tool_name,
        task_id,
        json.dumps(arguments, default=str)[:500],
    )

    _stats["tool_calls"].append(
        {
            "hook": "pre",
            "tool": tool_name,
            "task_id": task_id,
            "timestamp": time.time(),
        }
    )


# ─────────────────────────────────────────
# post_tool_call — 工具调用后
# ─────────────────────────────────────────

def on_post_tool_call(**kwargs: Any) -> None:
    """在工具被调用后触发。kwargs 包含 tool_name, result, duration_ms 等。"""
    if not VACKY_DEBUG:
        return

    tool_name = kwargs.get("tool_name", "unknown")
    result = kwargs.get("result", "")
    duration_ms = kwargs.get("duration_ms", 0)

    result_preview = str(result)[:300].replace("\n", " ")
    logger.info(
        "[HOOK:post_tool_call] tool=%s duration=%sms result_preview=%s",
        tool_name,
        duration_ms,
        result_preview,
    )


# ─────────────────────────────────────────
# pre_llm_call — LLM 请求前
# ─────────────────────────────────────────

def on_pre_llm_call(**kwargs: Any) -> None:
    """在发送给 LLM 前触发。kwargs 包含 messages, model, tools 等。"""
    if not VACKY_DEBUG:
        return

    messages = kwargs.get("messages", [])
    model = kwargs.get("model", "unknown")
    tool_count = len(kwargs.get("tools", []))

    msg_count = len(messages)
    total_chars = sum(len(str(m.get("content", ""))) for m in messages)

    logger.info(
        "[HOOK:pre_llm_call] model=%s messages=%d tools=%d total_chars=%d",
        model,
        msg_count,
        tool_count,
        total_chars,
    )

    _stats["llm_calls"].append(
        {
            "hook": "pre",
            "model": model,
            "message_count": msg_count,
            "tool_count": tool_count,
            "timestamp": time.time(),
        }
    )


# ─────────────────────────────────────────
# post_llm_call — LLM 响应后
# ─────────────────────────────────────────

def on_post_llm_call(**kwargs: Any) -> None:
    """在收到 LLM 响应后触发。kwargs 包含 response, usage 等。"""
    if not VACKY_DEBUG:
        return

    response = kwargs.get("response", {})
    usage = response.get("usage", {}) if isinstance(response, dict) else {}

    logger.info(
        "[HOOK:post_llm_call] tokens_prompt=%s tokens_completion=%s model=%s",
        usage.get("prompt_tokens", "N/A"),
        usage.get("completion_tokens", "N/A"),
        response.get("model", "unknown") if isinstance(response, dict) else "unknown",
    )


# ─────────────────────────────────────────
# on_session_start / on_session_end
# ─────────────────────────────────────────

def on_session_start(**kwargs: Any) -> None:
    if not VACKY_DEBUG:
        return

    session_id = kwargs.get("session_id", "unknown")
    _stats["session_start_time"] = time.time()
    _stats["tool_calls"] = []
    _stats["llm_calls"] = []

    logger.info("[HOOK:on_session_start] session_id=%s", session_id)


def on_session_end(**kwargs: Any) -> None:
    if not VACKY_DEBUG:
        return

    duration = _format_duration(_stats.get("session_start_time"))
    logger.info(
        "[HOOK:on_session_end] duration=%s tool_calls=%d llm_calls=%d",
        duration,
        len(_stats.get("tool_calls", [])),
        len(_stats.get("llm_calls", [])),
    )


# ─────────────────────────────────────────
# transform_tool_result — 修改工具返回结果（用于观察）
# ─────────────────────────────────────────

def on_transform_tool_result(**kwargs: Any) -> dict | None:
    """可以修改或包装工具返回结果。返回 dict 则替换原结果。"""
    if not VACKY_DEBUG:
        return None

    tool_name = kwargs.get("tool_name", "unknown")
    result = kwargs.get("result", "")

    # 示例：记录超大结果，帮助发现潜在的上下文膨胀问题
    result_len = len(str(result))
    if result_len > 10000:
        logger.warning(
            "[HOOK:transform_tool_result] tool=%s returned VERY LARGE result: %d chars",
            tool_name,
            result_len,
        )

    return None  # 不修改结果，只记录日志


# ─────────────────────────────────────────
# 获取当前统计信息（供工具调用）
# ─────────────────────────────────────────

def get_stats() -> dict[str, Any]:
    """返回当前 session 的运行时统计。"""
    return {
        "session_duration": _format_duration(_stats.get("session_start_time")),
        "tool_call_count": len(_stats.get("tool_calls", [])),
        "llm_call_count": len(_stats.get("llm_calls", [])),
        "recent_tool_calls": _stats.get("tool_calls", [])[-5:],
        "recent_llm_calls": _stats.get("llm_calls", [])[-5:],
    }
