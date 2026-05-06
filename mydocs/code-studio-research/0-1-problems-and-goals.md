# CodeStudio 问题、目标与学习规划（一）

> **元文档**：记录我们的问题、目标、学习计划。
> 本文档持续更新，记录决策过程和推理链条。
>
> **关联文档**：
> - CodeStudio 规划：见 [0-2-code-studio-planning.md](./0-2-code-studio-planning.md)
> - 假设与决策：见 [0-3-hypotheses-and-decisions.md](./0-3-hypotheses-and-decisions.md)
> - 行动清单：见 [0-4-action-plan.md](./0-4-action-plan.md)
> - 更新日志：见 [0-5-update-log.md](./0-5-update-log.md)

---

## 一、核心问题（我们为什么要做 CodeStudio？）

### 1.1 问题定义

我们在 `letsgo_server` 的 AI 辅助开发（dev/review/debug）中，遇到以下核心问题：

| # | 问题 | 现状 | 影响 |
| --- | ------ | ------ | ------ |
| **Q1** | **知识复用效率低** | AI 每次都需要重新了解项目背景（架构、部署流程、常见 bug） | 开发速度慢，重复劳动 |
| **Q2** | **流程确认依赖人工** | 没有自动化机制确保"部署前必须跑 staging"、"数据库变更必须有回滚方案" | 生产事故风险 |
| **Q3** | **知识格式不清晰** | 不知道背景知识应该用 `.md`、skill 还是其他格式 | 不知道如何组织知识库 |
| **Q4** | **缺乏系统性学习** | 看了 CCGS、Hermes Agent，但没有系统性对比和提炼 | 可能重复造轮子，或遗漏关键设计 |
| **Q5** | **实践验证不足** | 对"AI 在 letsgo_server 上到底卡在哪里"缺乏数据 | 可能设计错误的功能 |

### 1.2 问题优先级

| 问题 | 优先级 | 理由 |
| ------ | -------- | ------ |
| Q1（知识复用） | **高** | 直接影响开发效率 |
| Q2（流程确认） | **高** | 直接影响生产安全 |
| Q3（知识格式） | **中** | 可以边做边调整 |
| Q4（系统性学习） | **中** | 需要时间，但值得投入 |
| Q5（实践验证） | **高** | 确保设计方向正确 |

---

## 二、目标（我们想做成什么？）

### 2.1 终极目标

**构建一个 AI Agent 基础设施（CodeStudio）**，使得：

1. **知识可复用**：AI 能快速获取项目背景知识，不重复劳动

2. **流程可确认**：自动化机制确保关键流程（如生产部署）符合规范

3. **多 CLI 兼容**：支持 Claude Code / Codex / CodeBuddy 等多种 CLI

4. **持续进化**：系统能从实践中学习，不断优化

### 2.2 阶段性目标

| 阶段 | 目标 | 成功标准 | 状态 |
| ------ | ------ | --------- | ------ |
| **阶段 1**（分析学习） | 系统性分析 CodeStudio、CCGS、Claude Code、mugc_tools、Hermes Agent | 完成 `1-1-x`、`1-2-x`、`1-3-x`、`1-4-x`、`1-5-x` 分析文档 | ✅ 已完成 |
| **阶段 2**（实践验证） | 在 `letsgo_server` 上做 2-3 个真实任务，记录 AI 卡点 | 完成 `2-1-practice-round1.md`、`2-2-practice-round2.md`、`2-3-practice-round3.md` | ⏳ 待开始 |
| **阶段 3**（设计） | 基于前两个阶段，输出 CodeStudio 设计方案 | 完成 `3-synthesis-and-design.md` | ⏳ 待开始 |
| **阶段 4**（实现） | 实现 CodeStudio 的核心功能（知识系统、流程确认） | 可运行的原型 | ⏳ 待开始 |
| **阶段 5**（迭代） | 在 `letsgo_server` 上使用 CodeStudio，收集反馈，持续迭代 | 实践验证通过 | ⏳ 待开始 |

---

## 三、学习规划（我们要从每个代码库学什么？）

### 3.1 学习计划表

| 代码库 | 学习目标 | 关键问题 | 输出文档 | 状态 |
| -------- | --------- | --------- | --------- | ------ |
| **CodeStudio** | 学习 N+M 架构、GD 治理、Evidence Chain | - N+M 架构如何解耦？- GD-1/2 如何实现治理？- Evidence Chain 如何闭环？ | `1-1-x` 系列（8 个文档） | ✅ 已完成 |
| **CCGS** | 学习应用层 Agent 协作模式 | - Agent 如何分工？- Director Gates 如何实现？- Skill 如何封装工作流？ | `1-2-x` 系列（6 个文档） | ✅ 已完成 |
| **Hermes Agent** | 学习 Agent 循环、Tool/Hook/Skill/Memory 系统 | - Agent 循环如何工作？- Tool 如何注册和执行？- Hook 生命周期？- Memory 插件如何工作？ | `1-3-x` 系列（6 个文档） | ✅ 已完成 |
| **Claude Code CLI** | 学习底层 Agent/Tool/Hook/Skill 实现 | - Agent 系统如何设计？- Tool 如何注册和执行？- Hook 的生命周期？- Skill 如何注入？ | `1-4-x` 系列（7 个文档） | ✅ 已完成 |
| **mugc_server_ai_tools** | 学习 letsgo_server 的 AI 实践 | - 如何组织"服务器开发"的知识？- 有哪些独特设计？- OpenSpec 如何工作？ | `1-5-x` 系列（7 个文档） | ✅ 已完成 |
| **Matt Pocock Skills** | 学习开源 Skills 设计理念 | - Skills 如何组织？- 如何设计可复用的 AI 工作流？- 与 CodeStudio 的关系？ | `1-6-x` 系列（4 个文档） | ✅ 已完成 |

### 3.2 每个代码库的具体学习问题

#### CCGS（✅ 已完成）

**已回答的问题**：

- ✅ Agent 如何分层（Tier 1/2/3）？
- ✅ Director Gates 如何工作？
- ✅ Skill 如何封装工作流？
- ✅ Hook 如何实现流程自动化？
- ✅ Rules 如何约束代码质量？

**未完成的问题**（可能需要深入研究）：

- ⏳ CCGS 在实际项目中效果如何？（缺乏用户反馈数据）
- ⏳ CCGS 的性能如何？（Agent 调用链有多长？）

#### Claude Code CLI（✅ 已完成）

**已回答的问题**：

- ✅ Agent 系统如何设计？（架构 + Slash 命令注册）
- ✅ Tool 如何注册和执行？（原生工具 + 外部工具）
- ✅ Hook 的生命周期？（27 种事件）
- ✅ Skill 如何注入？（打包为 `command` 对象，通过 `injectSkills` 注入）
- ✅ 上下文管理策略？（压缩策略 + 记忆管理）

**未完成的问题**（可能需要深入研究）：

- ⏳ Claude Code 在实际项目中效果如何？（缺乏用户反馈数据）
- ⏳ Claude Code 的性能如何？（Tool 调用延迟、上下文压缩效率）

**详细分析**：见 `1-4-x` 系列文档。

---

#### mugc_server_ai_tools（✅ 已完成）

**已回答的问题**：

- ✅ 如何组织"服务器开发"的背景知识？（OpenSpec 体系）
- ✅ 知识格式是什么？（`.md` 文档 + Skill + Command）
- ✅ 知识如何复用？（自动注入 + 手动引用）
- ✅ 相比 CCGS，有什么独特设计？（OpenSpec、服务器开发特指工具）
- ✅ Rules 系统如何工作？（项目级 + 全局 + 自动发现）

**未完成的问题**（可能需要深入研究）：

- ⏳ mugc_tools 在实际项目中效果如何？（缺乏用户反馈数据）
- ⏳ mugc_tools 的性能如何？（Tool 调用延迟、上下文压缩效率）

**详细分析**：见 `1-5-x` 系列文档。

---

#### Matt Pocock Skills（✅ 已完成）

**已回答的问题**：

- ✅ Skills 如何组织？（仓库结构 + 分类体系）
- ✅ 如何设计可复用的 AI 工作流？（7 个核心 Skills 详解）
- ✅ Skill 与 CodeStudio 的关系？（对比分析 + 可借鉴设计）
- ✅ 如何注入上下文？（SKILL.md + docs/agents/）
- ✅ 如何设计渐进式工作流？（TDD、diagnose、grill-with-docs）

**未完成的问题**（可能需要深入研究）：

- ⏳ Matt Pocock Skills 在实际项目中效果如何？（缺乏用户反馈数据）
- ⏳ 如何大规模推广 Skills？（Skill 发现和分发机制）

**详细分析**：见 `1-6-x` 系列文档。

---

#### Hermes Agent（✅ 已完成）

**已回答的问题**：

- ✅ Agent 循环如何工作？（主循环 + 迭代控制 + 预算控制）
- ✅ Tool 如何注册和执行？（Registry 模式 + 沙箱执行）
- ✅ Hook 生命周期？（14 种事件）
- ✅ Skill 如何注入？（Skills 注册 + 注入机制）
- ✅ Memory 插件如何工作？（8 个插件 + 记忆注入时机）

**未完成的问题**（可能需要深入研究）：

- ⏳ Hermes Agent 在实际项目中效果如何？（缺乏用户反馈数据）
- ⏳ Hermes Agent 的性能如何？（Tool 调用延迟、上下文压缩效率）

**详细分析**：见 `1-3-x` 系列文档。

---

## 四、待验证的假设

> 本节约表格已迁移至 [0-3-hypotheses-and-decisions.md](./0-3-hypotheses-and-decisions.md)。

---

**文档状态**：📝 持续更新

**下一步**：
- [ ] 查看 CodeStudio 规划：[0-2-code-studio-planning.md](./0-2-code-studio-planning.md)
- [ ] 查看假设与决策：[0-3-hypotheses-and-decisions.md](./0-3-hypotheses-and-decisions.md)
- [ ] 查看行动清单：[0-4-action-plan.md](./0-4-action-plan.md)
