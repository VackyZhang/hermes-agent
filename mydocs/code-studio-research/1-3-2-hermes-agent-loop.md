# Hermes Agent 循环详解

> **文档定位**：深入 Hermes Agent 的 Agent 循环（run_agent.py）。

---

## 一、Agent 循环概述

Hermes Agent 的核心循环在 `run_agent.py` 中的 `AIAgent.run_conversation()` 方法实现。

**核心循环**（简化）：

```python

# run_agent.py

while (api_call_count < max_iterations and iteration_budget.remaining > 0) \
        or self._budget_grace_call:
    if self._interrupt_requested: break
    
    response = client.chat.completions.create(
        model=model,
        messages=messages,
        tools=tool_schemas
    )
    
    if response.tool_calls:
        for tool_call in response.tool_calls:
            result = handle_function_call(tool_call.name, tool_call.args, task_id)
            messages.append(tool_result_message(result))
        api_call_count += 1
    else:
        return response.content
```text

**关键特性**：

| 特性 | 说明 |
| ------ | ------ |
| **迭代预算** | `IterationBudget` 类，线程安全，`max_total` 控制总预算 |
| **中断检查** | `_interrupt_requested`，支持用户中断 |
| **Tool 执行** | `handle_function_call()` 统一处理 |
| **消息格式** | OpenAI 格式（`{"role": "system/user/assistant/tool", ...}`） |
| **Budget Grace Call** | `_budget_grace_call`，允许最后一次工具调用完成 |

**`IterationBudget` 类（实际实现，`run_agent.py` 第 271-297 行）**：

```python
class IterationBudget:
    """Thread-safe iteration counter for an agent."""
    
    def __init__(self, max_total: int):
        self.max_total = max_total
        self._used = 0
        self._lock = threading.Lock()
    
    def consume(self) -> bool:
        """Try to consume one iteration. Returns True if allowed."""
        with self._lock:
            if self._used >= self.max_total:
                return False
            self._used += 1
            return True
    
    def refund(self) -> None:
        """Refund an iteration (for execute_code)."""
        with self._lock:
            self._used = max(0, self._used - 1)
```text

> **注意**：文档中的简化代码示例仅供参考，实际实现请参考 `run_agent.py` 源代码。

---

## 二、AIAgent 类详解

### 2.1 初始化参数（`__init__`）

```python
class AIAgent:
    def __init__(self,
        base_url: str = None,
        api_key: str = None,
        provider: str = None,
|         api_mode: str = None,              # "chat_completions" | "codex_responses" | ... |
        model: str = "",                   # empty → resolved from config/provider later
        max_iterations: int = 90,          # tool-calling iterations (shared with subagents)
        enabled_toolsets: list = None,
        disabled_toolsets: list = None,
        quiet_mode: bool = False,
        save_trajectories: bool = False,
        platform: str = None,              # "cli", "telegram", etc.
        session_id: str = None,
        skip_context_files: bool = False,
        skip_memory: bool = False,
        credential_pool=None,

        # ... plus callbacks, thread/user/chat IDs, iteration_budget, fallback_model,

        # checkpoints config, prefill_messages, service_tier, reasoning_config, etc.

    ): ...
```text

**关键参数说明**：

| 参数 | 类型 | 说明 |
| ------ | ------ | ------ |
| `max_iterations` | int | 最大工具调用迭代次数（默认 90） |
| `iteration_budget` | Budget | 迭代预算（控制总预算） |
| `enabled_toolsets` | list | 启用的 toolset 列表 |
| `disabled_toolsets` | list | 禁用的 toolset 列表 |
| `platform` | str | 平台名称（"cli", "telegram", etc.） |
| `session_id` | str | Session ID（用于 Session DB） |
| `credential_pool` | CredentialPool | 凭证池（用于多凭证轮换） |

### 2.2 核心方法

#### `chat(self, message: str) -> str`

```python
def chat(self, message: str) -> str:
    """Simple interface — returns final response string."""
    result = self.run_conversation(user_message=message)
    return result["final_response"]
```text

#### `run_conversation(self, user_message: str, system_message: str = None, conversation_history: list = None, task_id: str = None) -> dict`

```python
def run_conversation(self, user_message: str, system_message: str = None,
                     conversation_history: list = None, task_id: str = None) -> dict:
    """
    Full interface — returns dict with final_response + messages.
    
    Returns:
        {
            "final_response": str,
            "messages": list[dict],  # Full message history
            "tool_calls": list[dict],  # All tool calls made
            "token_usage": dict,       # Token usage statistics
        }
    """

    # 1. Initialize messages

    messages = []
    if system_message:
        messages.append({"role": "system", "content": system_message})
    if conversation_history:
        messages.extend(conversation_history)
    messages.append({"role": "user", "content": user_message})
    
    # 2. Run agent loop

    api_call_count = 0
    while (api_call_count < self.max_iterations and self.iteration_budget.remaining > 0) \
            or self._budget_grace_call:
        if self._interrupt_requested: break
        
        # 3. Call LLM API

        response = self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            tools=self.tool_schemas
        )
        
        # 4. Handle tool calls

        if response.tool_calls:
            for tool_call in response.tool_calls:
                result = self.handle_function_call(tool_call.name, tool_call.args, task_id)
                messages.append({
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "content": result
                })
            api_call_count += 1
        else:

            # 5. No tool calls → final response

            return {
                "final_response": response.content,
                "messages": messages,
                "tool_calls": ...,
                "token_usage": ...
            }
    
    # 6. Max iterations reached or budget exhausted

    return {
        "final_response": "Max iterations reached or budget exhausted.",
        "messages": messages,
        "tool_calls": ...,
        "token_usage": ...
    }
```text

---

## 三、工具调用处理（handle_function_call）

```python
def handle_function_call(tool_name: str, tool_args: dict, task_id: str = None) -> str:
    """
    Handle function call from LLM.
    
    Args:
        tool_name: Tool name (e.g., "read_file")
        tool_args: Tool arguments (dict)
        task_id: Task ID (optional)
    
    Returns:
        Tool execution result (JSON string)
    """

    # 1. Check if tool is enabled

    if not is_tool_enabled(tool_name):
        return json.dumps({"error": f"Tool {tool_name} is disabled"})
    
    # 2. Check if tool is allowed (permissions)

    if not is_tool_allowed(tool_name, tool_args):
        return json.dumps({"error": f"Tool {tool_name} is not allowed"})
    
    # 3. Execute tool

    try:
        result = execute_tool(tool_name, tool_args, task_id)
        return result
    except Exception as e:
        return json.dumps({"error": str(e)})
```text

**工具执行流程**：

```text
LLM 返回 tool_call
    ↓
handle_function_call()
    ↓
[1] 检查工具是否启用（enabled_toolsets / disabled_toolsets）
    ↓
[2] 检查工具是否允许（permissions）
    ↓
[3] 执行工具（execute_tool()）
    ↓
[4] 返回结果（JSON string）
    ↓
追加到 messages（role: "tool"）
    ↓
继续 Agent 循环
```text

---

## 四、中断检查（_interrupt_requested）

```python
def check_interrupt(self):
    """Check if user requested interrupt."""
    if self._interrupt_requested:
        logger.info("Interrupt requested, stopping agent loop")
        return True
    return False
```text

**中断触发方式**：

| 触发方式 | 说明 |
| ---------- | ------ |
| **CLI** | `Ctrl+C` 触发中断 |
| **Gateway** | 用户发送 `/stop` 命令 |
| **API** | 调用 `interrupt()` 方法 |

---

## 五、预算控制（iteration_budget）

```python
class IterationBudget:
    def __init__(self, total_budget: int):
        self.total_budget = total_budget
        self.remaining = total_budget
        self.used = 0
    
    def consume(self, amount: int = 1):
        if self.remaining < amount:
            return False  # Budget exhausted
        self.remaining -= amount
        self.used += amount
        return True
    
    def grace(self):
        """Enter grace period (allow one more iteration)."""
        self._budget_grace_call = True
```text

**预算控制流程**：

```text
Agent 循环开始
    ↓
检查 iteration_budget.remaining > 0
    ↓
是 → 继续执行
否 → 检查 _budget_grace_call
    ↓
是 → 允许最后一次迭代（grace call）
否 → 终止 Agent 循环
```text

---

## 六、消息格式（OpenAI 格式）

**消息格式**：

```python

# System message

{"role": "system", "content": "You are a helpful assistant..."}

# User message

{"role": "user", "content": "What's the weather today?"}

# Assistant message (with tool calls)

{
    "role": "assistant",
    "content": None,
    "tool_calls": [
        {
            "id": "call_abc123",
            "type": "function",
            "function": {
                "name": "get_weather",
                "arguments": "{\"location\": \"San Francisco\"}"
            }
        }
    ]
}

# Tool result message

{
    "role": "tool",
    "tool_call_id": "call_abc123",
    "content": "{\"temperature\": 72, \"condition\": \"sunny\"}"
}
```text

**Reasoning 内容**（如果模型支持）：

```python

# Assistant message (with reasoning)

{
    "role": "assistant",
    "content": "The weather is sunny and 72°F.",
    "reasoning": "I need to call get_weather first, then format the response..."
}
```text

---

**文档状态**：✅ 第一版完成（从 `1-3-hermes-analysis.md` 拆分）

**下一步**：

- [ ] 补充更多 Agent 循环的细节（从 `run_agent.py` 提取）
- [ ] 补充预算控制的边界情况（预算耗尽时的行为）
