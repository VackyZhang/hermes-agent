"""
vacky_debug — 个人调试插件

用途：
    在不修改任何核心源码的前提下，通过注册 hook 和工具来观察、
    调试 hermes-agent 的内部运行机制。

特性：
    - 所有调试逻辑通过生命周期 hook 实现，零侵入
    - 提供 3 个调试工具供 agent 调用或手动触发
    - 环境变量 VACKY_DEBUG=1 控制启用，默认关闭
    - kind=backend 的 bundled 插件，自动加载

目录结构：
    plugins/vacky_debug/
        __init__.py     ← 注册入口（本文档）
        plugin.yaml     ← 插件清单
        hooks.py        ← hook 实现
        tools.py        ← 调试工具实现

使用方法：
    export VACKY_DEBUG=1
    hermes

在 hermes 中可以直接调用：
    /vacky_inspect_state agent
    /vacky_dump_context label=before_tool_call
    /vacky_trigger_breakpoint
"""

from __future__ import annotations

from plugins.vacky_debug.hooks import (
    on_post_llm_call,
    on_post_tool_call,
    on_pre_llm_call,
    on_pre_tool_call,
    on_session_end,
    on_session_start,
    on_transform_tool_result,
)
from plugins.vacky_debug.tools import (
    VACKY_DUMP_CONTEXT_SCHEMA,
    VACKY_INSPECT_STATE_SCHEMA,
    VACKY_TRIGGER_BREAKPOINT_SCHEMA,
    _handle_vacky_dump_context,
    _handle_vacky_inspect_state,
    _handle_vacky_trigger_breakpoint,
)

# 工具注册表：(name, schema, handler)
_TOOLS = (
    ("vacky_inspect_state", VACKY_INSPECT_STATE_SCHEMA, _handle_vacky_inspect_state),
    ("vacky_dump_context", VACKY_DUMP_CONTEXT_SCHEMA, _handle_vacky_dump_context),
    ("vacky_trigger_breakpoint", VACKY_TRIGGER_BREAKPOINT_SCHEMA, _handle_vacky_trigger_breakpoint),
)

# Hook 注册表：(hook_name, callback)
_HOOKS = (
    ("pre_tool_call", on_pre_tool_call),
    ("post_tool_call", on_post_tool_call),
    ("pre_llm_call", on_pre_llm_call),
    ("post_llm_call", on_post_llm_call),
    ("on_session_start", on_session_start),
    ("on_session_end", on_session_end),
    ("transform_tool_result", on_transform_tool_result),
)


def register(ctx) -> None:
    """Plugin entry point — called once by the plugin loader on startup."""
    # 注册调试工具
    for name, schema, handler in _TOOLS:
        ctx.register_tool(
            name=name,
            toolset="vacky_debug",
            schema=schema,
            handler=handler,
            check_fn=None,
            emoji="🐛",
        )

    # 注册生命周期 hook
    for hook_name, callback in _HOOKS:
        ctx.register_hook(hook_name, callback)
