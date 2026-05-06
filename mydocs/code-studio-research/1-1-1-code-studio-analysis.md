# CodeStudio 分析

> **⚠️ 重要说明**：本文档描述 CodeStudio 的**设计方案**，当前系统**尚未实现**。

> - 规格设计：进行中（目标 9000+ 行 Markdown）
> - 框架代码：进行中（目标 5000+ 行 Python）
> - 单元测试：进行中（目标 15% 覆盖率）

>
> **文档定位**：梳理 CodeStudio 的设计、实现、亮点，对比 CCGS/Hermes Agent/Claude Code，并针对 `0-problems-and-goals.md` 中的问题提出解决思路。
>
> **本文结构**：

> - **主文档**（本文件）：总结性输出，建立整体认知
> - **子文档**（深入细节）：
>   - `1-1-2-codestudio-architecture.md`：整体架构、四阶段 Lifecycle、五层 CAP 能力
>   - `1-1-3-codestudio-gd-governance.md`：GD 三域治理体系
>   - `1-1-4-codestudio-evidence-chain.md`：证据链闭环
>   - `1-1-5-codestudio-injection.md`：四层注入机制（AgentINJ-L1~L4）
>   - `1-1-6-codestudio-n+m-architecture.md`：N+M 多 Agent 适配架构
>   - `1-1-7-codestudio-trace-v2.md`：Trace v2（AI 行为全维度记录）
>   - `1-1-8-codestudio-claim-model.md`：Claim 模型（并发 session 管理）

---

## 一、一句话总结

CodeStudio 是 AI Coding Agent 的 **Harness Engineering 框架**，通过 GD+CC 双轴治理体系保证输出质量，让 AI 稳定完成 dev/debug/review。

**核心设计理念**：

- **OCIC**：`harness(1)` + `catalog(k)` + `projects(N)` = 复杂度 **1+k+N**（可控增长）

- **Spec-first**：Markdown 规格驱动 AI 执行，`codestudio-spec/` 为唯一 SSOT

- **证据链闭环**：上下文注入 → AI 执行 → Trace → Evidence 采集 → Knowledge 升格 → 上下文注入

---

## 二、核心设计概览

### 2.1 整体架构

```text
CodeStudio/
├── codestudio-spec/     ← 施工图纸（规格 + 设计，SSOT）
├── harness/             ← 框架代码（models / api / caps / lifecycle / adapters）
├── catalog/             ← 共享规则库（constraints / flows / skills，k 因子）
├── projects/            ← 各接入项目数据（N 因子，待建）
├── tests/               ← 单元测试 / 集成测试 / E2E 测试
└── docs/               ← 历史与外部参考文档（非当前规范 SSOT）
```text

**深入细节** → 详见 `1-1-2-codestudio-architecture.md`

### 2.2 四阶段 Lifecycle

```text
[1] session_start   → 创建 session，CAP-1 注入上下文，CAP-3 启动 trace
[2] intent_identify → 接收首条消息，CAP-5 分类（dev/debug/review/free）
[3] execute         → 3a Task Mode（CAP-1~5 全参与）/ 3b Free Mode（可升格为 task）
[4] session_close   → 收尾 task，Evidence 升格为 Knowledge，生成总结
```text

**深入细节** → 详见 `1-1-2-codestudio-architecture.md`

### 2.3 五层 CAP 能力

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

**深入细节** → 详见 `1-1-2-codestudio-architecture.md`

### 2.4 GD 三域治理体系

| 域 | 名称 | 职责 | 对应 CCGS 的什么？ |
| ----- | ------ | ------ | --------------------- |
| **GD-1** | 实例层 | Session 级别的实例化（注入项目特定的 knowledge + constraint） | CCGS 的 Agent 实例化（但 CCGS 没有"实例"概念） |
| **GD-2** | 组织资产 | 约束 + 流程（constraint + checklist） | CCGS 的 Rules + Director Gates |
| **GD-3** | 能力域 | CAP 能力（CAP-1~5） | CCGS 的 Agent/Tool/Hook 系统 |

**深入细节** → 详见 `1-1-3-codestudio-gd-governance.md`

### 2.5 证据链闭环

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

**CCGS 没有这个闭环**：CCGS 的知识是静态的（`.claude/docs/*.md`），不会从实践中学习。

**深入细节** → 详见 `1-1-4-codestudio-evidence-chain.md`

### 2.6 四层注入机制（AgentINJ-L1~L4）

| 层 | 名称 | 载体 | 时机 |
| ------ | ------ | ------ | ------ |
| **AgentINJ-L1** | 上下文规则注入 | CLAUDE.md / AGENTS.md（规则文件） | Session 启动时自动加载 |
| **AgentINJ-L2** | Hook 注入 | session_start.sh / pre_tool_use.sh / … | 工具调用前后触发 |
| **AgentINJ-L3** | MCP 工具注入 | `codestudio-harness` CodeStudioServer | 按需调用 |
| **AgentINJ-L4** | 权限注入 | settings.json / config.toml permissions | 工具权限白名单 |

**L1 最小安全网原则**：

- 问题：若 L1 规则文件仅包含 MCP 入口说明（"请调用 session_start"），一旦 CodeStudioServer 启动失败（常见于环境问题），Agent 将在零约束状态下运行。

- 原则：L1 规则文件必须自给自足——即使 MCP 不可用，Agent 仍能：

  1. 识别意图（内置分类 schema）

  2. 遵守核心约束（C1 禁止硬编码敏感信息、C2 禁止写生产环境、C3 Lifecycle 完整性）

  3. 执行基本 Session 协议（4 阶段 lifecycle）

**深入细节** → 详见 `1-1-5-codestudio-injection.md`

### 2.7 N+M 多 Agent 适配架构

```text
┌─────────────────────────────────────────────────────────┐
│                    catalog/（N=1，共用）                  │
│  constraints/*.md + skills/*/SKILL.md + flows/*.md       │
│  projects/<proj>/input.md + knowledge/*.md               │
└─────────────────────┬───────────────────────────────────┘
                      │ 标准数据（dict list）
                      ▼
┌─────────────────────────────────────────────────────────┐
│              harness/api/server.py（CodeStudioServer）         │
│  MCP 工具：session_start / report_intent /              │
│           record_evidence / query_constraint / ...       │
│  读取 catalog/，向 Agent L3 提供按需查询能力             │
└─────────────────────┬───────────────────────────────────┘
                      │ 标准内容块（project_input / constraints / skills / knowledge）
                      ▼
┌──────────┬──────────┬──────────┬──────────┐  M 个薄适配层
│ claude-  │ codebuddy│  codex   │  gemini  │  harness/adapters/<agent>/
│ code     │          │（规划中）│（规划中）│  renderer.py：格式翻译
│          │          │          │          │  hooks.py：hook handler
└────┬─────┴────┬─────┴──────────┴──────────┘
     │          │
     ▼          ▼
install/       install/
claude-code/   codebuddy/
  CLAUDE.md      CODEBUDDY.md
  settings.json  config.toml
  hooks/         hooks/
```text

**职责边界**：

| 层 | 代码位置 | 职责 | 不做什么 |
| ------ | ---------- | ------ | ---------- |
| **N 层（catalog）** | `catalog/`, `projects/` | 定义约束 / 技能 / 知识的**内容** | 不关心 Agent 格式 |
| **N 层（API server）** | `harness/api/server.py` | 将 catalog 内容通过 MCP 暴露给 Agent | 不输出 Agent 配置文件 |
| **M 层（renderer）** | `harness/adapters/<agent>/renderer.py` | 读取 catalog，**格式翻译**为 Agent 所需文件 | 不定义约束 / 技能内容 |
| **M 层（hooks）** | `harness/adapters/<agent>/hooks.py` | 处理 Agent hook 事件（PreToolUse / PostToolUse / Stop） | 不包含业务逻辑，委托给 CAP |

**深入细节** → 详见 `1-1-6-codestudio-n+m-architecture.md`

### 2.8 Trace v2（AI 行为全维度记录）

**Base Event 结构**：

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

**新增 event_type**（v2）：

| event_type | 说明 | 写入时机 |
| ------------ | ------ | ---------- |
| `evidence` | 证据记录（替代 v1 中被错误分类为 `tool_result` 的 evidence 事件） | Host LLM / Skill 执行 |
| `ai_reasoning` | AI 推理步骤（每个推理步骤完成后由 AI 调用 `record_ai_reasoning` MCP 工具写入） | AI 完成一个推理阶段后 |
| `ai_action` | AI 声明工具调用意图（在工具调用前通过 `record_evidence` 写入 `ai_action` 类型） | 工具调用前 |
| `flow_enter` | 进入 flow 步骤 | 进入 flow 步骤时 |
| `flow_exit` | 退出 flow 步骤（与 `flow_enter` 配对） | 退出 flow 步骤时 |
| `session_summary` | Session 关闭前由 Host LLM 在 `session_close` 触发前自主填写 | Session 关闭前 |

**深入细节** → 详见 `1-1-7-codestudio-trace-v2.md`

### 2.9 Claim 模型（iter-001 新增）

**问题**：多个 Claude Code session 可能同时启动，如何避免重复分配同一 sid？

**Claim 模型核心保证**：

- **原子性**：使用 `fcntl.flock(LOCK_EX)` 保护 pending/ 目录，并发 claim 不会重复分配同一 sid

- **FIFO**：按 `created_at` 排序，最旧的 pending 优先被 claim

- **幂等性**：同一 `cc_session_id` 被 claim 后移入 claimed/，不可重复 claim

**流程**：

```text
Claude Code Session 启动
    ↓
SessionStart Hook 触发
    ↓
create_pending_session --cc-session-id <UUID>
    ↓
在 pending/ 目录创建预注册记录
    ↓
Host LLM 收到 CLAUDE.md 指令
    ↓
调用 claim_session（原子 pop pending session，获取 harness_sid）
    ↓
后续所有工具调用均传入此 sid
```text

**深入细节** → 详见 `1-1-8-codestudio-claim-model.md`

---

## 三、亮点与创新

| 亮点 | 说明 | 相对 CCGS 的优势 |
| ------ | ------ | --------------------- |
| **① 形式化治理体系** | GD + CC 双轴治理，Constraint + Checklist 有结构化格式 | CCGS 的 Director Gates 是软性自由文本 |
| **② 证据链闭环** | `trace → evidence → knowledge → injection` | CCGS 没有（知识是静态的） |
| **③ 五层 CAP 能力** | CAP-1~5 可组合，按需启用 | CCGS 的 Agent/Tool/Hook 是捆绑的（不能按需启用） |
| **④ OCIC 复杂度控制** | `1（harness) + k（catalog) + N（projects）` | CCGS 的复杂度是 `49 agents + 72 skills`（不可控） |
| **⑤ 多 CLI 兼容** | 通过 Harness 抽象层，支持多种 CLI | CCGS 只支持 Claude Code |
| **⑥ Spec-first** | Markdown 规格驱动 AI 执行 | CCGS 没有（CCGS 依赖自由文本指令） |
| **⑦ 四层注入机制** | AgentINJ-L1~L4，L1 最小安全网 | CCGS 只有 AgentINJ-L1（规则文件） |
| **⑧ N+M 多 Agent 适配** | 避免 N×M 重复，catalog 内容生成逻辑维护一次 | CCGS 没有（每个 Agent 完整复制） |
| **⑨ Trace v2** | AI 行为全维度记录，推理证据链 | CCGS 没有（只有简单工具调用日志） |
| **⑩ Claim 模型** | 并发 session 管理，原子 pop pending session | CCGS 没有（依赖用户手动启动） |

---

## 四、当前状态（2026-05）

| 维度 | 完成度 | 说明 |
| ------ | -------- | ------ |
| **规格设计** | ✅ 完成 | 9000+ 行 Markdown，4 层分离 |
| **框架代码** | ✅ 骨架完成 | 5000+ 行 Python，细节待补强 |
| **单元测试** | 🔨 约 15% | 需补全至 60%+（P0） |
| **集成测试** | ⏳ 0% | 待编写 4 阶段协作用例 |
| **真实验证** | ⏳ 0% | 待 letsgo_server 落地 |

**关键路径**：

1. ✅ 规格设计完成（9000+ 行 Markdown）

2. ✅ 框架代码骨架完成（5000+ 行 Python）

3. 🔨 单元测试补全（当前约 15%，需补到 60%+）

4. ⏳ 集成测试编写（4 阶段协作用例）

5. ⏳ 真实验证（letsgo_server 落地）

---

## 五、与 CCGS/Hermes Agent/Claude Code 的对比

### 5.1 与 CCGS 的对比

| 维度 | CCGS | CodeStudio | CodeStudio 的优势 |
| ------ | ------------ | ------------ | ------------------- |
| **定位** | 应用层模板（游戏开发工作流） | 基础设施层（Agent Harness 框架） | CodeStudio 更通用，不绑定特定领域 |
| **依赖** | Claude Code（Anthropic 官方 CLI） | 自己实现 Harness | CodeStudio 支持多 CLI |
| **知识复用** | 静态 `.md` 文档 | `trace → evidence → knowledge → injection` 闭环 | CodeStudio 能从实践中学习 |
| **流程确认** | 软性 Director Gates（自由文本裁决） | 形式化 GD+CC 双轴治理（结构化约束） | CodeStudio 的约束是硬性的，可自动化验证 |
| **复杂度控制** | 49 agents + 72 skills（不可控） | 1（harness) + k（catalog) + N（projects） | CodeStudio 的复杂度可控 |
| **多 CLI 支持** | ❌ 只支持 Claude Code | ✅ 设计上支持多 CLI | CodeStudio 更灵活 |
| **意图分类** | ❌ 依赖用户手动选择 Agent | ✅ CAP-5 Router 自动分类 | CodeStudio 更智能 |
| **四层注入** | ❌ 只有 AgentINJ-L1（规则文件） | ✅ AgentINJ-L1~L4（四层注入机制） | CodeStudio 的注入更全面 |
| **N+M 适配** | ❌ 没有（每个 Agent 完整复制） | ✅ N+M 多 Agent 适配架构 | CodeStudio 避免 N×M 重复 |
| **Trace 记录** | ❌ 没有（只有简单工具调用日志） | ✅ Trace v2（AI 行为全维度记录） | CodeStudio 的追溯更完整 |
| **并发管理** | ❌ 没有（依赖用户手动启动） | ✅ Claim 模型（原子 pop pending session） | CodeStudio 支持并发 session |

**核心结论**：

- CCGS 是**应用层的最佳实践案例**（展示了如何在 Claude Code 的能力边界内实现结构化工作流）

- CodeStudio 是**基础设施层的设计**（学习 CCGS 的优点，但在底层实现上做得更通用、更形式化、更可扩展）

### 5.2 与 Hermes Agent 的对比

| 维度 | Hermes Agent | CodeStudio | CodeStudio 的优势 |
| ------ | -------------- | ------------ | ------------------- |
| **定位** | AI Agent 框架（实现 Agent 循环 + 工具系统） | Agent Harness 框架（治理 Agent 行为） | 定位不同：Hermes Agent 是"实现"，CodeStudio 是"治理" |
| **知识复用** | Session DB（对话历史）+ Memory 插件 | `trace → evidence → knowledge → injection` 闭环 | CodeStudio 的知识进化更系统化 |
| **流程确认** | ❌ 无（依赖模型遵守） | ✅ CAP-2 Enforcer + GD+CC 双轴治理 | CodeStudio 有形式化流程确认 |
| **多 CLI 支持** | ✅ 支持（Hermes Agent 是独立 CLI） | ✅ 支持（通过 Harness 抽象层） | 两者都支持，但方式不同 |
| **Hook 系统** | ✅ 有（Python 原生） | ✅ CAP-4 Interceptor（原生集成） | 两者都有，但 CodeStudio 的 Hook 是"治理导向" |
| **工具系统** | ✅ 有（Tool Registry + Toolset） | ✅ 有（通过 MCP 协议接入） | 两者都有，但 CodeStudio 的工具系统更通用（支持多 CLI） |

**核心结论**：

- Hermes Agent 是 **CodeStudio 的底层实现之一**（CodeStudio 可以用 Hermes Agent 作为 Harness 的实现）

- CodeStudio 关注**治理层**，Hermes Agent 关注**执行层**

### 5.3 与 Claude Code 的对比

| 维度 | Claude Code | CodeStudio | CodeStudio 的优势 |
| ------ | ------------- | ------------ | ------------------- |
| **定位** | AI Coding CLI（官方） | Agent Harness 框架（第三方） | 定位不同：Claude Code 是"工具"，CodeStudio 是"治理框架" |
| **Agent 系统** | ✅ 有（Task 工具） | ✅ 有（CAP-5 Router + GD-1 实例层） | CodeStudio 的 Agent 系统更形式化 |
| **Tool 系统** | ✅ 有（Bash, Read, Write, Edit...） | ✅ 有（通过 MCP 协议接入） | CodeStudio 的 Tool 系统更通用（支持多 CLI） |
| **Hook 系统** | ✅ 有（Pre-tool / Post-tool / Session-stop） | ✅ 有（CAP-4 Interceptor） | CodeStudio 的 Hook 是"治理导向" |
| **知识管理** | ❌ 无（依赖用户手动提供上下文） | ✅ CAP-1 Injector + 证据链闭环 | CodeStudio 的知识管理更系统化 |
| **多 CLI 支持** | ❌ 只支持 Anthropic API | ✅ 设计上支持多 CLI | CodeStudio 更灵活 |
| **四层注入** | ❌ 只有 AgentINJ-L1~L2（规则文件 + Hooks） | ✅ AgentINJ-L1~L4（四层注入机制） | CodeStudio 的注入更全面 |
| **Trace 记录** | ❌ 没有（只有简单工具调用日志） | ✅ Trace v2（AI 行为全维度记录） | CodeStudio 的追溯更完整 |

**核心结论**：

- Claude Code 是 **CodeStudio 的支持目标之一**（CodeStudio 可以包裹 Claude Code，为其添加治理能力）

- CodeStudio 关注**治理层**，Claude Code 关注**执行层**

---

## 六、针对 0- 中的问题的解决方案

### 6.1 Q1：知识复用效率低

**CodeStudio 的解决方案**：

| 机制 | 说明 | 状态 |
| ------ | ------ | ------ |
| **CAP-1 Injector** | 注入 project_input + knowledge + constraint | ✅ 设计中（codestudio-spec/） |
| **证据链闭环** | `trace → evidence → knowledge → injection` | ✅ 设计中（codestudio-spec/） |
| **catalog/knowledge/** | 结构化知识目录 | ⏳ 待实现 |

**下一步**：

- [ ] 实现 CAP-1 Injector（注入知识到上下文）

- [ ] 实现 CAP-3 Recorder（记录 trace）

- [ ] 实现 Evidence 提取逻辑（从 trace 中提取模式）

- [ ] 实现 Knowledge 升格逻辑（将 evidence 更新到 catalog/knowledge/）

### 6.2 Q2：流程确认依赖人工

**CodeStudio 的解决方案**：

| 机制 | 说明 | 状态 |
| ------ | ------ | ------ |
| **CAP-2 Enforcer** | 执行前/后验证操作是否违规约束 | ✅ 设计中（codestudio-spec/） |
| **GD-2 组织资产** | 约束 + 流程（constraint + checklist） | ✅ 设计中（codestudio-spec/） |
| **结构化约束格式** | Constraint 有 JSON Schema 验证（不是自由文本） | ✅ 设计中（codestudio-spec/） |

**下一步**：

- [ ] 定义 Constraint 的结构化格式（JSON Schema）

- [ ] 实现 CAP-2 Enforcer（验证操作是否违规约束）

- [ ] 实现 GD-2 组织资产（约束 + 流程）

- [ ] 在 letsgo_server 上验证（例如，"部署前必须跑 staging"）

### 6.3 Q3：知识格式不清晰

**CodeStudio 的解决方案**：

| 知识类型 | 格式 | 示例 |
| --------- | ------ | ------ |
| **静态知识** | `.md` 文档（catalog/knowledge/*.md） | 服务器架构文档、部署流程 |
| **流程知识** | `flow`（catalog/flows/*.md） | 部署流程、代码审查流程 |
| **案例知识** | `evidence`（由 CAP-3 Recorder 生成） | 历史 bug 修复案例、性能优化案例 |
| **约束知识** | `constraint`（catalog/constraints/*.md） | "数据库变更必须有回滚方案" |

**下一步**：

- [ ] 定义 `catalog/` 的目录结构

- [ ] 定义 knowledge / flows / constraints 的格式规范

- [ ] 在 letsgo_server 上验证（哪种格式最适合哪种场景）

### 6.4 Q4：缺乏系统性学习

**CodeStudio 的解决方案**：

| 机制 | 说明 | 状态 |
| ------ | ------ | ------ |
| **证据链闭环** | 系统性地从实践中学习 | ✅ 设计中（codestudio-spec/） |
| **codestudio-spec/** | 9000+ 行 Markdown，系统化设计 | ✅ 完成 |
| **单元测试 + 集成测试** | 系统性地验证功能 | 🔨 进行中（约 15%） |

**下一步**：

- [ ] 补全单元测试（至 60%+）

- [ ] 编写集成测试（4 阶段协作用例）

- [ ] 在 letsgo_server 上做真实验证

### 6.5 Q5：实践验证不足

**CodeStudio 的解决方案**：

| 机制 | 说明 | 状态 |
| ------ | ------ | ------ |
| **letsgo_server 实证** | 首个实证项目 | ⏳ 待启动 |
| **codestudio-spec/1-03-letsgo_server项目理解.md** | letsgo_server 的项目背景 | ✅ 已完成 |
| **codestudio-spec/1-04-letsgo_server应用场景.md** | letsgo_server 的 dev/debug/review 场景 | ✅ 已完成 |
| **codestudio-spec/1-05-letsgo_server期望与约束.md** | CodeStudio 在 letsgo_server 上落地的约束 | ✅ 已完成 |

**下一步**：

- [ ] 启动 letsgo_server 实证（第一个真实任务）

- [ ] 记录 AI 的卡点（更新 `3-1-practice-round1.md`）

- [ ] 基于实践反馈，迭代 CodeStudio 设计

---

## 七、总结与下一步

### 7.1 核心结论

1. **CodeStudio 是基础设施层**，CCGS 是应用层模板 → CodeStudio 更通用、更形式化

2. **CodeStudio 的亮点**：形式化治理体系、证据链闭环、五层 CAP 能力、OCIC 复杂度控制、四层注入机制、N+M 多 Agent 适配、Trace v2、Claim 模型

3. **CodeStudio 的不足**：当前处于框架完成期，测试补全 + 真实验证为下一工作重心

### 7.2 下一步

| 任务 | 优先级 | 预计时间 |
| ------ | -------- | --------- |
| **① 补全单元测试** | P0 | 1-2 周 |
| **② 编写集成测试** | P0 | 1 周 |
| **③ 启动 letsgo_server 实证** | P1 | 立即 |
| **④ 基于实践反馈，迭代设计** | P1 | 持续 |

---

**文档状态**：✅ 第三版完成（主文档 + 子文档结构，总结性输出 + 深入细节拆分）

**子文档列表**：

| 子文档 | 内容 |
| --------- | ------ |
| `1-1-2-codestudio-architecture.md` | 整体架构、四阶段 Lifecycle、五层 CAP 能力、CodeStudioServer 接口 |
| `1-1-3-codestudio-gd-governance.md` | GD 三域治理体系 |
| `1-1-4-codestudio-evidence-chain.md` | 证据链闭环 |
| `1-1-5-codestudio-injection.md` | 四层注入机制（AgentINJ-L1~L4） |
| `1-1-6-codestudio-n+m-architecture.md` | N+M 多 Agent 适配架构 |
| `1-1-7-codestudio-trace-v2.md` | Trace v2（AI 行为全维度记录） |
| `1-1-8-codestudio-claim-model.md` | Claim 模型（并发 session 管理） |

**下一步**：

- [ ] 在 letsgo_server 上做真实验证

- [ ] 记录卡点，迭代设计

- [ ] 补全单元测试 + 集成测试
