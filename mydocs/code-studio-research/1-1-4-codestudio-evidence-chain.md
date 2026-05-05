# CodeStudio 证据链闭环详解

> **⚠️ 重要说明**：本文档描述 CodeStudio 的**设计方案**，当前系统**尚未实现**。
>
> **文档定位**：深入 CodeStudio 的证据链闭环（`trace → evidence → knowledge → injection`）。

---

## 一、证据链闭环概述

**问题**：AI 不会从实践中学习，每次都要重新了解项目背景。

**解决方案**：证据链闭环

```text
[AI 执行任务]
        ↓
[CAP-3 Recorder] → 记录 trace（工具调用日志、用户反馈）
        ↓
[Evidence 提取] → 从 trace 中提取模式（例如，"每次玩家掉线都伴随数据库连接池耗尽"）
        ↓
[Knowledge 升格] → 将 evidence 更新到 catalog/knowledge/*.md
        ↓
[CAP-1 Injector] → 下次会话时，自动注入新 knowledge
        ↓
[AI 执行任务]（这次，AI 知道"玩家掉线可能是数据库连接池耗尽"）
```text

**CCGS 没有这个闭环**：

- CCGS 的知识是静态的（`.claude/docs/*.md`）
- CCGS 不会从实践中学习

---

## 二、Trace 记录（CAP-3 Recorder）

**Trace 内容**：

| 字段 | 说明 |
| ------ | ------ |
| `session_id` | Session ID |
| `timestamp` | 时间戳 |
| `event_type` | 事件类型（tool_call / tool_result / user_feedback / ...） |
| `data` | 事件数据（JSON） |

**示例 trace 记录**：

```json
{
  "session_id": "sess-20260429-143052",
  "timestamp": "2026-04-29T14:30:52+08:00",
  "event_type": "tool_call",
  "data": {
    "tool": "read_file",
    "params": {"path": "auth/login.go"},
    "result": {"success": true, "content": "package auth..."}
  }
}
```text

**Trace v2 新增事件类型**（详见 `1-1-7-codestudio-trace-v2.md`）：

- `evidence`：证据记录
- `ai_reasoning`：AI 推理步骤
- `ai_action`：AI 声明工具调用意图
- `flow_enter` / `flow_exit`：进入/退出 flow 步骤
- `session_summary`：Session 关闭前总结

---

## 三、Evidence 提取

**问题**：如何从 trace 中提取有用的证据？

**Evidence 类型**：

| 类型 | 说明 | 示例 |
| ------ | ------ | ------ |
| **模式识别** | 从多次 tool_call 中发现模式 | "每次玩家掉线都伴随数据库连接池耗尽" |
| **用户反馈** | 用户对 AI 输出的反馈 | "这个 SQL 查询太慢了" |
| **错误记录** | AI 执行失败记录 | "AI 尝试修复 bug，但编译失败" |

**Evidence 存储格式**：

```yaml

# catalog/knowledge/db-connection-pool.md

---
name: db-connection-pool
type: evidence
source: trace
confidence: high
---

## 证据

- 2026-04-29：玩家掉线 3 次，每次都伴随数据库连接池耗尽
- 2026-04-30：增加数据库连接池大小后，掉线问题消失

## 结论

玩家掉线可能是数据库连接池耗尽导致的。
```text

---

## 四、Knowledge 升格

**问题**：如何将 evidence 更新到 catalog/knowledge/？

**升格流程**：

1. **Evidence 提取**：从 trace 中提取证据（模式识别、用户反馈、错误记录）

2. **Evidence 验证**：验证证据的可信度（confidence: high / medium / low）

3. **Knowledge 更新**：将证据更新到 catalog/knowledge/*.md

4. **Knowledge 注入**：下次会话时，CAP-1 Injector 自动注入新 knowledge

**自动化 vs 人工**：

| 方式 | 说明 | 适用场景 |
| ------ | ------ | ---------- |
| **自动化** | Evidence 提取 + Knowledge 升格全部自动 | 高置信度证据（confidence: high） |
| **人工审核** | Evidence 提取自动，Knowledge 升格需人工审核 | 中/低置信度证据（confidence: medium / low） |

---

## 五、Knowledge 注入（CAP-1 Injector）

**问题**：如何将 knowledge 注入到 AI 上下文？

**注入时机**：

| 时机 | 说明 |
| ------ | ------ |
| **Session 启动** | 注入 project_input + knowledge + constraint |
| **按需查询** | AI 通过 `query_knowledge` MCP 工具查询 knowledge |

**注入格式**：

```markdown

# 注入的 knowledge

## 数据库迁移

- 每次数据库迁移必须有回滚脚本
- 每次数据库迁移必须在 staging 环境测试通过

## 玩家掉线问题

- 玩家掉线可能是数据库连接池耗尽导致的
- 增加数据库连接池大小可能解决问题

```text

---

**文档状态**：✅ 第一版完成（从 `1-1-code-studio-analysis.md` 拆分）

**下一步**：

- [ ] 补充 Evidence 提取算法（如何从 trace 中提取模式）
- [ ] 补充 Knowledge 升格策略（何时自动升格，何时需人工审核）
