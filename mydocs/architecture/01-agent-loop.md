# Agent 核心循环分析

> 分析对象：`run_agent.py` — `AIAgent.run_conversation()`

---

## 待填充

阅读源码后在此记录：

1. **入口点**：`AIAgent.__init__()` 的关键参数
2. **主循环**：`run_conversation()` 的 while 循环条件
3. **消息格式**：OpenAI 格式的 messages 如何组装
4. **工具调用**：`response.tool_calls` 的处理流程
5. **预算控制**：`iteration_budget` 的实现
6. **中断机制**：`_interrupt_requested` 如何被设置

---

## 调试断点建议

```python
# 在 plugins/vacky_debug/hooks.py 中添加：
# 观察每次 LLM 调用前的消息列表
# 观察工具调用后的结果
```

---

## 相关文件

- `run_agent.py` — 主循环
- `model_tools.py` — 工具调用处理
- `agent/` — Agent 内部模块
