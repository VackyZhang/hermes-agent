# CodeStudio 架构详解

> **⚠️ 重要说明**：本文档描述 CodeStudio 的**设计方案**，当前系统**尚未实现**。
>
> **文档定位**：深入 CodeStudio 的整体架构、四阶段 Lifecycle、五层 CAP 能力、CodeStudioServer 接口。

---

## 一、整体架构

```text
CodeStudio/
├── codestudio-spec/     ← 施工图纸（规格 + 设计，SSOT）
├── harness/             ← 框架代码（models / api / caps / lifecycle / adapters）
├── catalog/             ← 共享规则库（constraints / flows / skills，k 因子）
├── projects/            ← 各接入项目数据（N 因子，待建）
├── tests/               ← 单元测试 / 集成测试 / E2E 测试
└── docs/               ← 历史与外部参考文档（非当前规范 SSOT）
```text

**核心设计理念**：

- **OCIC**：`harness(1)` + `catalog(k)` + `projects(N)` = 复杂度 **1+k+N**（可控增长）
- **Spec-first**：Markdown 规格驱动 AI 执行，`codestudio-spec/` 为唯一 SSOT
- **证据链闭环**：上下文注入 → AI 执行 → Trace → Evidence 采集 → Knowledge 升格 → 上下文注入

---

## 二、四阶段 Lifecycle

```text
[1] session_start   → 创建 session，CAP-1 注入上下文，CAP-3 启动 trace
[2] intent_identify → 接收首条消息，CAP-5 分类（dev/debug/review/free）
[3] execute         → 3a Task Mode（CAP-1~5 全参与）/ 3b Free Mode（可升格为 task）
[4] session_close   → 收尾 task，Evidence 升格为 Knowledge，生成总结
```text

**关键设计**：

- **Stage 1**（session_start）：初始化 session，注入 project_input + knowledge + constraint
- **Stage 2**（intent_identify）：意图分类，选择 flow
- **Stage 3**（execute）：执行任务（Task Mode 或 Free Mode）
- **Stage 4**（session_close）：收尾，知识升格

---

## 三、五层 CAP 能力

| CAP | 名称 | 职责 | 对应 CCGS 的什么？ |
| ----- | ------ | ------ | --------------------- |
| **CAP-1** | Injector | 注入 project_input + knowledge + constraint | CCGS 的 `.claude/docs/*.md` + Skill |
| **CAP-2** | Enforcer | 执行前/后验证操作是否违规约束 | CCGS 的 Director Gates（但 CCGS 是软性，CAP-2 是硬性） |
| **CAP-3** | Recorder | 记录 trace（流日志）+ evidence（结构化证据） | CCGS 没有（CCGS 没有 trace 记录） |
| **CAP-4** | Interceptor | Runtime hook，捕获异常防失控 | CCGS 的 Hooks（但 CCGS 是外部脚本，CAP-4 是原生集成） |
| **CAP-5** | Router | 意图分类、flow 选择、任务分发 | CCGS 没有（CCGS 依赖用户手动选择 Agent） |

**核心差异**（相对 CCGS）：

- ✅ **CAP-2 是硬性约束**（不是软性 Gates）
- ✅ **CAP-3 实现知识闭环**（CCGS 没有）
- ✅ **CAP-5 实现自动意图分类**（CCGS 依赖用户手动选择）

---

## 四、CodeStudioServer 接口（8 个工具）

| 工具 | 阶段/层 | 职责 |
| ------ | --------- | ------ |
| `claim_session` | Claim 阶段 | 原子 pop pending session，获取 harness_sid（iter-001 新增） |
| `session_start` | Stage 1 | 创建会话，初始化上下文 |
| `report_intent` | Stage 2 | 意图识别与 flow 选择 |
| `record_evidence` | CAP-3 | 记录行为证据 |
| `query_constraint` | CAP-2 | 查询适用约束规则 |
| `query_knowledge` | CAP-1 | 查询知识库 |
| `session_close` | Stage 4 | 关闭会话，升格知识 |
| `record_ai_reasoning` | CAP-3 | 记录 AI 推理步骤，形成推理证据链（Trace v2 新增） |

**传输层**：遵循 MCP 协议（Model Context Protocol），统一使用 **Streamable HTTP**（常驻 daemon，port 8765）

---

**文档状态**：✅ 第一版完成（从 `1-1-code-studio-analysis.md` 拆分）

**下一步**：

- [ ] 补充更多实现细节（从 `codestudio-spec/` 提取）
- [ ] 添加示例代码（从 `harness/` 目录提取）
