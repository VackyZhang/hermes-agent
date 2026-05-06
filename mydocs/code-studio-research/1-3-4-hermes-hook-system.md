# Hermes Agent Hook 系统详解

> **文档定位**：深入 Hermes Agent 的 Hook 系统（Python 原生）。

---

## 一、Hook 系统概述

> **⚠️ 重要更新**：Hermes Agent 实际支持 **14 种 Hook 事件**（不是 4 种）。

Hermes Agent 的 Hook 系统在 `hermes_cli/plugins.py` 和 `tools/registry.py` 中实现。

**核心设计理念**：

- **两种机制**：Shell Hooks（shell 脚本）和 Plugin Hooks（Python 函数）
- **14 种事件类型**：覆盖 Agent 循环全生命周期
- **Hook 配置**：`config.yaml` 的 `hooks:` 块（不是 `hermes_constants.py`）
- **Hook 执行**：Python 函数调用（Plugin Hooks）或 shell 脚本执行（Shell Hooks）

**14 种 Hook 事件类型**（`hermes_cli/plugins.py` 第 78-114 行）：

| 事件类型 | 触发时机 | 用途 |
| ---------- | ---------- | ------ |
| `pre_tool_call` | 工具调用前 | 检查/阻止工具调用 |
| `post_tool_call` | 工具调用后 | 记录/审计工具结果 |
| `transform_terminal_output` | 终端输出前 | 转换/过滤终端输出 |
| `transform_tool_result` | 工具结果返回前 | 转换/过滤工具结果 |
| `pre_llm_call` | LLM 请求前 | 修改 prompt、注入上下文 |
| `post_llm_call` | LLM 响应后 | 处理/记录 LLM 响应 |
| `pre_api_request` | API 请求前 | 修改 API 请求参数 |
| `post_api_request` | API 请求后 | 处理 API 响应 |
| `on_session_start` | Session 启动时 | 注入初始上下文 |
| `on_session_end` | Session 结束时 | 清理、日志持久化 |
| `on_session_finalize` | Session 最终化时 | 最终化处理 |
| `on_session_reset` | Session 重置时 | 重置状态 |
| `subagent_stop` | 子 Agent 停止时 | 处理子 Agent 结果 |
| `pre_gateway_dispatch` | 网关分发前 | 拦截/修改网关消息 |
| `pre_approval_request` | 权限请求前 | 自定义审批逻辑 |
| `post_approval_response` | 权限响应后 | 处理审批结果 |

---

## 二、Hook 类型

### 2.1 pre_tool（工具调用前）

**触发时机**：工具调用前

**用途**：

- 检查工具调用是否合规
- 阻止不合规的工具调用
- 修改工具参数

**示例**：

```python

# hermes_cli/hooks/pre_tool.py

def pre_tool_hook(tool_name: str, tool_params: dict) -> dict:
    """
    Pre-tool hook.
    
    Returns:
        {
            "allow": True/False,
            "reason": "..." (if not allowed)
        }
    """

    # Example: Block Bash tool with "rm -rf /"

    if tool_name == "Bash":
        command = tool_params.get("command", "")
        if "rm -rf /" in command:
            return {"allow": False, "reason": "Dangerous command blocked"}
    
    return {"allow": True}
```text

### 2.2 post_tool（工具调用后）

**触发时机**：工具调用后

**用途**：

- 记录工具调用结果
- 审计工具调用
- 触发后续动作

**示例**：

```python

# hermes_cli/hooks/post_tool.py

def post_tool_hook(tool_name: str, tool_params: dict, tool_result: str) -> None:
    """Post-tool hook."""

    # Example: Log tool call

    logger.info(f"Tool called: {tool_name}, Result: {tool_result[:100]}")
```text

### 2.3 session_start（Session 启动时）

**触发时机**：Session 启动时

**用途**：

- 注入初始上下文
- 加载 Session DB 中的历史对话
- 初始化工具集

**示例**：

```python

# hermes_cli/hooks/session_start.py

def session_start_hook(session_id: str) -> dict:
    """
    Session start hook.
    
    Returns:
        {
            "additional_context": "...",  # Additional context to inject
        }
    """

    # Example: Load session history from Session DB

    history = load_session_history(session_id)
    return {"additional_context": history}
```text

### 2.4 session_stop（Session 结束时）

**触发时机**：Session 结束时

**用途**：

- 清理临时文件
- 持久化 Session 数据
- 记录 Session 日志

**示例**：

```python

# hermes_cli/hooks/session_stop.py

def session_stop_hook(session_id: str) -> None:
    """Session stop hook."""

    # Example: Save session data to Session DB

    save_session_data(session_id)
```text

---

## 三、Hook 配置

**配置位置**：`hermes_constants.py` 中的 `HOOKS` 配置。

**配置格式**：

```python

# hermes_constants.py

HOOKS = {
    "pre_tool": [
        "hermes_cli.hooks.pre_tool.pre_tool_hook",
        ...
    ],
    "post_tool": [
        "hermes_cli.hooks.post_tool.post_tool_hook",
        ...
    ],
    "session_start": [
        "hermes_cli.hooks.session_start.session_start_hook",
        ...
    ],
    "session_stop": [
        "hermes_cli.hooks.session_stop.session_stop_hook",
        ...
    ],
}
```text

**Hook 注册**：

```python

# hermes_cli/hooks/__init__.py

def register_hooks():
    """Register all hooks."""
    for hook_type, hook_list in HOOKS.items():
        for hook_path in hook_list:
            module_path, func_name = hook_path.rsplit(".", 1)
            module = importlib.import_module(module_path)
            hook_func = getattr(module, func_name)
            register_hook(hook_type, hook_func)
```text

---

## 四、Hook 执行流程

```text
Agent 循环开始
    ↓
[Session Start]
    ↓
执行 session_start hooks
    ↓
注入 additional_context 到 messages
    ↓
[Tool Call]
    ↓
执行 pre_tool hooks
    ↓
检查 hook 结果（allow/deny）
    ↓
允许 → 执行工具
    ↓
执行 post_tool hooks
    ↓
[Session Stop]
    ↓
执行 session_stop hooks
    ↓
Session 结束
```text

---

## 五、与 CCGS/Claude Code 的对比

### 5.1 与 CCGS 的对比

| 维度 | CCGS | Hermes Agent |
| ------ | ------- | ------------ |
| **Hook 实现** | bash/powershell 脚本 | Python 函数 |
| **Hook 配置** | .claude/settings.json | hermes_constants.py 中的 HOOKS 配置 |
| **Hook 执行** | 子进程调用（bash script） | Python 函数调用（同一进程） |
| **扩展性** | 需要编写 bash 脚本 | 直接编写 Python 函数，易于扩展 |

### 5.2 与 Claude Code 的对比

| 维度 | Claude Code | Hermes Agent |
| ------ | ------------- | ------------ |
| **Hook 实现** | TypeScript 函数（utils/hooks.ts） | Python 函数 |
| **Hook 类型** | 4 种（command/prompt/http/agent） | 4 种（pre_tool/post_tool/session_start/session_stop） |
| **Hook 事件** | 13 种（SessionStart, PreToolUse, ...） | 4 种（pre_tool, post_tool, session_start, session_stop） |
| **Hook 配置** | .claude/settings.json | hermes_constants.py 中的 HOOKS 配置 |

---

**文档状态**：✅ 第一版完成（从 `1-3-1-hermes-analysis.md` 拆分）

**下一步**：

- [ ] 补充更多 Hook 示例（从 `hermes_cli/` 和 `gateway/` 目录提取）
- [ ] 补充 Hook 执行顺序的详细设计（多个 hooks 的执行顺序）
