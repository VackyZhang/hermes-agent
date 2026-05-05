# CodeStudio 问题、目标与学习规划

> **元文档**：记录我们的问题、目标、学习计划，以及基于学习的 CodeStudio 规划。
> 本文档持续更新，记录决策过程和推理链条。

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

| 阶段 | 目标 | 成功标准 |
| ------ | ------ | --------- |
| **阶段 1**（分析学习） | 系统性分析 CCGS、Claude Code、mugc_tools、Hermes Agent | 完成 `1-`、`2-`、`3-` 分析文档 |
| **阶段 2**（实践验证） | 在 `letsgo_server` 上做 2-3 个真实任务，记录 AI 卡点 | 完成 `4-practice-learnings.md` |
| **阶段 3**（设计） | 基于前两个阶段，输出 CodeStudio 设计方案 | 完成 `5-synthesis-and-design.md` |
| **阶段 4**（实现） | 实现 CodeStudio 的核心功能（知识系统、流程确认） | 可运行的原型 |
| **阶段 5**（迭代） | 在 `letsgo_server` 上使用 CodeStudio，收集反馈，持续迭代 | 实践验证通过 |

---

## 三、学习规划（我们要从每个代码库学什么？）

### 3.1 学习计划表

| 代码库 | 学习目标 | 关键问题 | 输出文档 | 状态 |
| -------- | --------- | --------- | --------- | ------ |
| **CCGS** | 学习应用层 Agent 协作模式 | - Agent 如何分工？- Director Gates 如何实现？- Skill 如何封装工作流？ | `1-ccgs-analysis.md` | ✅ 已完成 |
| **Claude Code CLI** | 学习底层 Agent/Tool/Hook 实现 | - Agent 系统如何设计？- Tool 如何注册和执行？- Hook 的生命周期？ | `2-claude-code-analysis.md` | ⏳ 待开始 |
| **mugc_server_ai_tools** | 学习 letsgo_server 的 AI 实践 | - 如何组织"服务器开发"的知识？- 有哪些独特设计？ | `3-mugc-tools-analysis.md` | ⏳ 待开始 |
| **Hermes Agent** | 学习 Memory 插件和 Session DB | - 如何管理对话历史？- 如何搜索相关知识？ | （已部分分析） | ⏳ 待补充 |

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

#### Claude Code CLI（⏳ 待开始）

**关键问题**：

1. **Agent 系统**：

   - Agent 如何定义（YAML front matter？还是其他格式？）
   - Agent 如何调度（如何通过 `Task` 工具调用其他 Agent？）
   - Agent 之间如何通信（共享上下文？还是独立上下文？）

2. **Tool 系统**：

   - Tool 如何注册（自动发现？还是手动注册？）
   - Tool 如何执行（沙箱？还是直接执行？）
   - Tool 的权限控制如何实现（`allowedTools` / `disallowedTools`？）

3. **Hook 系统**：

   - Hook 的生命周期（Pre-tool / Post-tool / Session-stop？）
   - Hook 如何接收数据（stdin？还是环境变量？）
   - Hook 如何返回数据（stdout？还是 exit code？）
   - Hook 如何阻断操作（exit code ≠ 0？）

4. **上下文管理**：

   - 上下文窗口如何管理（压缩策略？）
   - 如何做记忆管理（跨会话记忆？）

**学习方法**：

- 阅读 `/Users/vacky/VackyAI/ClaudeCode` 源码
- 重点关注：`agent/`、`tools/`、`hooks/`、`context/` 等目录
- 提取关键设计模式，填写 `2-claude-code-analysis.md`

#### mugc_server_ai_tools（⏳ 待开始）

**关键问题**：

1. **知识组织**：

   - 如何组织"服务器开发"的背景知识？
   - 知识格式是什么（`.md`？skill？还是其他？）
   - 知识如何复用（自动注入？还是手动引用？）

2. **独特设计**：

   - 相比 CCGS，有什么独特设计？
   - 是否解决了 CCGS 没有解决的问题？
   - 效果如何？

**学习方法**：

- 阅读 `/Users/vacky/VackyAI/mugc_server_ai_tools` 源码
- 重点关注：知识文件结构、Skill 定义、配置文件
- 提取关键设计，填写 `3-mugc-tools-analysis.md`

---

## 四、CodeStudio 规划（基于学习的设计方向）

> 本节在学习过程中持续更新，记录我们对 CodeStudio 的设计思考。

### 4.1 当前思考（基于 CCGS 分析）

**知识系统**：

- ✅ 学习：CCGS 用 `.claude/docs/*.md` 存放静态知识
- ✅ 学习：CCGS 用 Skill 封装工作流
- ⚠️ 问题：静态知识不会进化，需要从实践中学习
- 💡 方向：实现 `trace → evidence → knowledge → injection` 闭环

**流程确认**：

- ✅ 学习：CCGS 用 Director Gates 做流程确认
- ⚠️ 问题：Gates 是软性的，Agent 可以不遵守
- 💡 方向：实现形式化门禁（JSON Schema 验证 + 自动化检查）

**多 CLI 支持**：

- ✅ 学习：CCGS 只支持 Claude Code
- 💡 方向：设计统一的 Agent 抽象层，支持多 CLI

### 4.2 待验证的假设

| 假设 | 验证方法 | 状态 |
| ------ | --------- | ------ |
| 假设 1：知识复用能显著提升 AI 开发效率 | 实践验证（Round 1-3） | ⏳ 待验证 |
| 假设 2：形式化门禁比软性 Gates 更安全 | 对比测试 | ⏳ 待验证 |
| 假设 3：不同知识需要不同格式（.md / skill / evidence） | 实践验证 | ⏳ 待验证 |

### 4.3 设计决策记录（DR）

> 记录关键设计决策和推理过程。

#### DR-001：是否实现形式化 Gates？

**决策**：✅ 是，要实现形式化 Gates（相比 CCGS 的软性 Gates）

**理由**：

1. CCGS 的 Gates 依赖 Agent 自愿遵守，没有强制机制

2. 生产环境的流程确认必须有强制性（否则没有意义）

3. 形式化验证（JSON Schema）可以自动化，减少人工审查成本

**替代方案**：

- ❌ 软性 Gates（像 CCGS 那样）→ 不安全
- ❌ 完全人工审查 → 成本高

**状态**：✅ 已决策，待设计

---

#### DR-002：[待记录下一个决策]

**决策**：

**理由**：

**替代方案**：

**状态**：⏳ 待决策

---

## 五、行动清单（下一步做什么？）

### 5.1 立即行动（本周）

| 任务 | 优先级 | 预计时间 | 输出 |
| ------ | -------- | --------- | ------ |
| ① 开始分析 Claude Code 源码 | 高 | 2-3 小时 | `2-claude-code-analysis.md` 第一版 |
| ② 做一个超小实践（Round 1） | 高 | 1-2 小时 | `4-practice-learnings.md` Round 1 记录 |
| ③ 阅读 mugc_server_ai_tools 代码 | 中 | 1-2 小时 | `3-mugc-tools-analysis.md` 第一版 |

### 5.2 短期计划（本月）

- [ ] 完成 `2-claude-code-analysis.md`
- [ ] 完成 `3-mugc-tools-analysis.md`
- [ ] 完成 `4-practice-learnings.md`（至少 2-3 个 Round）
- [ ] 开始写 `5-synthesis-and-design.md`（综合设计）

---

## 六、文档更新日志

| 日期 | 更新内容 | 更新人 |
| ------ | --------- | -------- |
| 2026-05-04 | 创建文档，记录核心问题、目标、学习规划 | Vacky + AI |

---

**文档状态**：📝 持续更新

**下一步**：

- [ ] 开始分析 Claude Code 源码（填写第三节的"Claude Code CLI"部分）
- [ ] 做一个超小实践（验证 Q1-Q5）
- [ ] 记录第一个设计决策（DR-002）
