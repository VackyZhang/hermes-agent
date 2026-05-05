# CodeStudio Trace v2 详解

> **⚠️ 重要说明**：本文档描述 CodeStudio 的**设计方案**，当前系统**尚未实现**。
>
> **文档定位**：深入 CodeStudio 的 Trace v2（AI 行为全维度记录）。

---

## 一、Trace v2 概述

> **版本**：v2（2026-04-29 更新）。v1 仅有 3 个事件骨架，v2 覆盖 AI 行为全维度。

**Trace v2 目标**：记录 AI 行为的全维度，用于：

1. **证据链闭环**：从 trace 中提取证据，升格为 knowledge

2. **调试与审计**：回溯 AI 的决策过程

3. **性能分析**：分析 AI 的响应时间、tool_call 频率等

---

## 二、Base Event 结构

```json
{
  "v": 2,
  "timestamp": "2026-04-29T14:30:52+08:00",
  "sid": "sid-20260429-143052-a1b2",
  "event_type": "tool_call",
  "data": { ... },
  "task_id": "task-20260429-143055-c3d4",
  "skill_id": "skill-20260429-143100-d4e5",
  "flow": "debug",
  "flow_step": "reproduce"
}
```text

**字段说明**：

| 字段 | 类型 | 说明 |
| ------ | ------ | ------ |
| `v` | int | Trace 版本（2） |
| `timestamp` | string | 时间戳（ISO 8601） |
| `sid` | string | Session ID |
| `event_type` | string | 事件类型（见下方） |
| `data` | object | 事件数据（因 event_type 而异） |
| `task_id` | string | Task ID（可选，用于关联同一 task 的事件） |
| `skill_id` | string | Skill ID（可选，用于关联同一 skill 的事件） |
| `flow` | string | Flow 名称（可选，用于关联同一 flow 的事件） |
| `flow_step` | string | Flow 步骤（可选，用于关联同一 flow step 的事件） |

---

## 三、Event Type 详解

### 3.1 基础事件（v1 已有）

| event_type | 说明 | 写入时机 |
| ------------ | ------ | ---------- |
| `session_start` | Session 启动 | Session 启动时 |
| `session_close` | Session 关闭 | Session 关闭时 |
| `tool_call` | 工具调用 | AI 调用工具时 |
| `tool_result` | 工具结果 | 工具返回结果时 |

### 3.2 新增事件（v2）

| event_type | 说明 | 写入时机 |
| ------------ | ------ | ---------- |
| `evidence` | 证据记录（替代 v1 中被错误分类为 `tool_result` 的 evidence 事件） | Host LLM / Skill 执行 |
| `ai_reasoning` | AI 推理步骤（每个推理步骤完成后由 AI 调用 `record_ai_reasoning` MCP 工具写入） | AI 完成一个推理阶段后 |
| `ai_action` | AI 声明工具调用意图（在工具调用前通过 `record_evidence` 写入 `ai_action` 类型） | 工具调用前 |
| `flow_enter` | 进入 flow 步骤 | 进入 flow 步骤时 |
| `flow_exit` | 退出 flow 步骤（与 `flow_enter` 配对） | 退出 flow 步骤时 |
| `session_summary` | Session 关闭前由 Host LLM 在 `session_close` 触发前自主填写 | Session 关闭前 |

---

## 四、端到端示例（debug flow）

```jsonl
{"v":2,"timestamp":"...","sid":"sid-...","event_type":"session_start","data":{}}
{"v":2,"timestamp":"...","sid":"sid-...","event_type":"intent_classified","data":{"intent":"debug","confidence":0.8}}
{"v":2,"timestamp":"...","sid":"sid-...","event_type":"flow_enter","flow":"debug","flow_step":"reproduce","data":{"flow":"debug","step":"reproduce","entered_at":"..."}}
{"v":2,"timestamp":"...","sid":"sid-...","event_type":"ai_reasoning","data":{"step":"analyze_input","reasoning":"用户报告登录失败，需要先复现..."}}
{"v":2,"timestamp":"...","sid":"sid-...","event_type":"tool_call","data":{"tool":"read_file","params":{"path":"auth/login.go"}}}
{"v":2,"timestamp":"...","sid":"sid-...","event_type":"tool_result","data":{"tool":"read_file","success":true,"result_summary":"package auth..."}}
{"v":2,"timestamp":"...","sid":"sid-...","event_type":"flow_exit","flow":"debug","flow_step":"reproduce","data":{"flow":"debug","step":"reproduce","duration_ms":4200,"outcome":"completed"}}
{"v":2,"timestamp":"...","sid":"sid-...","event_type":"evidence","data":{"evidence_type":"finding","content":{"root_cause":"JWT timeout hardcoded to 30s"}}}
{"v":2,"timestamp":"...","sid":"sid-...","event_type":"task_complete","data":{"level":2,"summary":"修复 JWT 超时配置"}}
{"v":2,"timestamp":"...","sid":"sid-...","event_type":"session_summary","data":{"tasks_completed":["task-xxx"],"ai_self_assessment":"Session 完成 1 个任务..."}}
{"v":2,"timestamp":"...","sid":"sid-...","event_type":"session_close","data":{}}
```text

---

## 五、Trace v2 的存储与查询

**存储**：

- Trace 存储为 JSONL 文件（每行一个 JSON 对象）
- 文件路径：`projects/<project-id>/traces/<session-id>.jsonl`

**查询**：

- 通过 `record_ai_reasoning` MCP 工具查询当前 session 的 trace
- 通过 `query_knowledge` MCP 工具查询历史 trace 中的 knowledge

---

**文档状态**：✅ 第一版完成（从 `1-1-code-studio-analysis.md` 拆分）

**下一步**：

- [ ] 补充更多 event_type 的示例（从 `codestudio-spec/` 提取）
- [ ] 补充 Trace 查询 API 的详细文档
