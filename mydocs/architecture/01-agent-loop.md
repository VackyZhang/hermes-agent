<!--
状态：in-progress
阶段：Phase 1
最后更新：2026-04-30
-->

# 01-agent-loop.md — AIAgent 核心循环分析

## 1. 概述

`AIAgent.run_conversation()` 是 hermes-agent 的核心入口，负责管理一次完整的用户交互（turn）。

它实现了**"请求-响应-工具执行"循环**：
1. 接收用户输入
2. 调用 LLM API
3. 如果 LLM 要求调用工具 → 执行工具 → 将结果返回给 LLM → 继续步骤 2
4. 如果 LLM 返回纯文本 → 作为最终回复返回给用户

## 2. 架构图

```
用户输入
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                    run_conversation()                        │
│                                                              │
│  1. 初始化                                                   │
│     • 生成 task_id                                           │
│     • 重置重试计数器                                          │
│     • 设置 iteration_budget                                  │
│     • 加载/构建 system_prompt                                │
│     • 预压缩上下文（如果超出阈值）                             │
│                                                              │
│  2. 添加用户消息 → messages[]                                │
│                                                              │
│  3. while 循环（核心）                                        │
│     │                                                        │
│     ├── 检查中断请求                                          │
│     ├── 检查预算（iteration_budget）                          │
│     ├── 构建 api_messages（注入 context、清理字段）            │
│     ├── 调用 LLM API（带重试机制）                            │
│     ├── 处理响应：                                            │
│     │   ├── 被截断（length）→ 请求继续/重试                   │
│     │   ├── 有 tool_calls → 执行工具 → 结果加入 messages → continue
│     │   └── 纯文本 → 作为 final_response → break              │
│     │                                                        │
│     └── 错误恢复：                                            │
│         ├── 压缩上下文（413/上下文溢出）                        │
│         ├── 切换 fallback provider（429/401）                 │
│         └── 指数退避重试（其他错误）                           │
│                                                              │
│  4. 收尾                                                     │
│     • 保存 session                                           │
│     • 触发 post_llm_call hook                                │
│     • 后台 memory/skill review                               │
│     • 返回结果 dict                                          │
└─────────────────────────────────────────────────────────────┘
```

## 3. 核心类/函数

### 3.1 AIAgent.__init__()

| 关键参数 | 默认值 | 说明 |
|----------|--------|------|
| `max_iterations` | 90 | 最大工具调用迭代次数 |
| `iteration_budget` | None | 迭代预算（更精细的控制） |
| `tools` | None | 可用工具列表（从 registry 加载） |
| `session_id` | None | 会话 ID（自动生成） |
| `context_compressor` | None | 上下文压缩器 |
| `compression_enabled` | False | 是否启用上下文压缩 |

### 3.2 AIAgent.run_conversation()

```python
def run_conversation(
    self,
    user_message: str,
    system_message: str = None,
    conversation_history: List[Dict] = None,
    task_id: str = None,
    stream_callback: Optional[callable] = None,
) -> Dict[str, Any]:
```

**返回值**：
```python
{
    "final_response": str,          # 最终回复文本
    "messages": List[Dict],          # 完整消息历史
    "api_calls": int,                # API 调用次数
    "completed": bool,               # 是否成功完成
    "partial": bool,                 # 是否部分完成（因错误停止）
    "interrupted": bool,             # 是否被中断
    "model": str,                    # 使用的模型
    "provider": str,                 # 使用的提供商
    # ... 还有 token 使用量、成本等
}
```

### 3.3 循环条件

```python
while (api_call_count < self.max_iterations
       and self.iteration_budget.remaining > 0) \
      or self._budget_grace_call:
```

- `max_iterations`: 硬上限（默认 90）
- `iteration_budget`: 软上限，可配置
- `_budget_grace_call`: 预算耗尽后的最后一次"恩典"调用

## 4. 数据流

### 4.1 正常流程（无工具调用）

```
用户: "你好"
    │
    ▼
messages = [{"role": "user", "content": "你好"}]
    │
    ▼
LLM API 调用
    │
    ▼
response.content = "你好！有什么可以帮你的？"
    │
    ▼
final_response = "你好！有什么可以帮你的？"
messages.append({"role": "assistant", "content": "你好！有什么可以帮你的？"})
    │
    ▼
返回结果
```

### 4.2 工具调用流程

```
用户: "列出当前目录的文件"
    │
    ▼
messages = [{"role": "user", "content": "列出当前目录的文件"}]
    │
    ▼
LLM API 调用 #1
    │
    ▼
response.tool_calls = [
    {"name": "list_directory", "arguments": {"path": "."}}
]
    │
    ▼
messages.append(assistant_msg_with_tool_calls)
    │
    ▼
执行 list_directory(path=".")
    │
    ▼
tool_result = "file1.txt\nfile2.py\n..."
messages.append({"role": "tool", "tool_call_id": "...", "content": tool_result})
    │
    ▼
LLM API 调用 #2（带工具结果）
    │
    ▼
response.content = "当前目录有：file1.txt, file2.py, ..."
    │
    ▼
final_response = "当前目录有：file1.txt, file2.py, ..."
    │
    ▼
返回结果
```

### 4.3 消息角色序列

| 步骤 | 消息角色 | 说明 |
|------|---------|------|
| 1 | system | 系统提示（持久化缓存） |
| 2 | user | 用户输入 |
| 3 | assistant | LLM 回复（可能包含 tool_calls） |
| 4 | tool | 工具执行结果 |
| 5 | assistant | LLM 对工具结果的回复 |
| ... | ... | 重复 3-5 直到无 tool_calls |

## 5. 关键代码路径

### 5.1 循环入口（~10464）

```python
while (api_call_count < self.max_iterations
       and self.iteration_budget.remaining > 0) \
      or self._budget_grace_call:
```

### 5.2 API 调用构建（~10575-10727）

```python
# 1. 清理消息（移除内部字段）
# 2. 注入 ephemeral context（memory prefetch、plugin context）
# 3. 添加 system prompt
# 4. 添加 prefill messages
# 5. 应用 Anthropic prompt caching
# 6. 安全检查（清理孤儿 tool results）
# 7. 规范化 whitespace 和 tool-call JSON
```

### 5.3 响应处理分支（~12738）

```python
if assistant_message.tool_calls:
    # 有工具调用 → 执行工具 → continue
    self._execute_tool_calls(assistant_message, messages, effective_task_id, api_call_count)
else:
    # 无工具调用 → 最终回复 → break
    final_response = assistant_message.content
```

### 5.4 工具执行（~12968）

```python
self._execute_tool_calls(assistant_message, messages, effective_task_id, api_call_count)
```

内部流程：
1. 验证工具名（修复/拒绝无效工具）
2. 验证参数 JSON
3. 去重工具调用
4. 逐个调用 `handle_function_call()`
5. 将结果加入 messages

## 6. 调试观察点

| 观察点 | 文件 | 行号 | 调试方式 |
|--------|------|------|---------|
| 循环开始 | run_agent.py | ~10464 | pre_llm_call hook |
| API 调用前 | run_agent.py | ~10575 | pre_api_request hook |
| 响应接收后 | run_agent.py | ~12562 | post_api_request hook |
| 工具调用执行 | run_agent.py | ~12968 | pre_tool_call / post_tool_call hook |
| 循环结束 | run_agent.py | ~13387 | post_llm_call hook |
| 消息列表变化 | run_agent.py | 全程 | vacky_dump_context 工具 |

### 6.1 使用 vacky_debug 观察

```bash
VACKY_DEBUG=1 hermes
```

在 hermes 中：
```
# 观察当前 Agent 状态
/vacky_inspect_state agent

# 导出当前上下文
/vacky_dump_context label=after_tool_call

# 查看调试日志（另一个终端）
hermes logs --level DEBUG | grep "HOOK:"
```

## 7. 与其他模块的关系

```
run_agent.py (AIAgent)
    │
    ├── 依赖 → model_tools.py (handle_function_call)
    │
    ├── 依赖 → tools/registry.py (工具注册)
    │
    ├── 依赖 → hermes_cli/plugins.py (hook 系统)
    │
    ├── 依赖 → agent/ (各种 adapter、transport)
    │
    └── 被调用 → cli.py (HermesCLI.run())
    │
    └── 被调用 → gateway/run.py (GatewayRunner)
```

## 8. 疑问与待办

- [ ] `iteration_budget` 和 `max_iterations` 的具体区别和协作方式
- [ ] `_budget_grace_call` 的触发条件和用途
- [ ] 上下文压缩的触发阈值和策略
- [ ] fallback provider 的切换逻辑
- [ ] subagent 的委派机制（delegate_task）

## 9. 学习验证

### 验证 1：观察简单对话的循环

```bash
VACKY_DEBUG=1 hermes
# 输入："你好"
# 预期：1 次 pre_llm_call，无 tool_calls，1 次 post_llm_call
```

### 验证 2：观察工具调用的循环

```bash
VACKY_DEBUG=1 hermes
# 输入："当前时间"
# 预期：1 次 pre_llm_call，1 次 pre_tool_call (datetime)，
#       1 次 post_tool_call，1 次 pre_llm_call（带工具结果），
#       最终回复
```

### 验证 3：观察多轮工具调用

```bash
VACKY_DEBUG=1 hermes
# 输入："读取 README.md，然后总结内容"
# 预期：可能多轮工具调用（read_file → 可能还有 web_search 等）
```

---

> 下一章：[02-tool-system.md](02-tool-system.md)
