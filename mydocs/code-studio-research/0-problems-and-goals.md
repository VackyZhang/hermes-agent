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

## 四、CodeStudio 规划（基于学习的设计方向）

> 本节在学习过程中持续更新，记录我们对 CodeStudio 的设计思考。

### 4.1 当前思考（基于 5 个工具的分析）

**知识系统**：

- ✅ 学习 CodeStudio：N+M 架构，治理驱动开发
- ✅ 学习 CCGS：用 `.claude/docs/*.md` 存放静态知识
- ✅ 学习 CCGS：用 Skill 封装工作流
- ✅ 学习 Hermes Agent：用 Memory 插件管理记忆
- ✅ 学习 mugc_tools：用 OpenSpec 管理上下文
- ⚠️ 问题：静态知识不会进化，需要从实践中学习
- 💡 方向：实现 `trace → evidence → knowledge → injection` 闭环

**流程确认**：

- ✅ 学习 CCGS：用 Director Gates 做流程确认
- ✅ 学习 CodeStudio：用 GD-1/2 做治理约束
- ⚠️ 问题：Gates 是软性的，Agent 可以不遵守
- 💡 方向：实现形式化门禁（JSON Schema 验证 + 自动化检查）

**多 CLI 支持**：

- ✅ 学习：CCGS 只支持 Claude Code
- ✅ 学习：Hermes Agent 支持多 Provider
- 💡 方向：设计统一的 Agent 抽象层，支持多 CLI

**Agent 系统**：

- ✅ 学习 CCGS：49 个 Agent，三层结构
- ✅ 学习 Hermes Agent：AIAgent 核心循环
- ✅ 学习 Claude Code：27 种 Hook 事件
- 💡 方向：形式化 Agent 系统（CAP-5 Router）

**Tool 系统**：

- ✅ 学习 Hermes Agent：Registry 模式，自动发现
- ✅ 学习 Claude Code：原生工具 + 外部工具
- 💡 方向：通过 MCP 协议接入（通用）

**Hook 系统**：

- ✅ 学习 Hermes Agent：14 种事件（Pre/Post/Notification/Session-stop）
- ✅ 学习 Claude Code：27 种事件（更细粒度）
- 💡 方向：治理导向的 Hook（CAP-4 Interceptor）

**Skill 系统**：

- ✅ 学习 CCGS：72 个 Skill，Slash 命令实现
- ✅ 学习 Hermes Agent：内置 + optional-skills
- ✅ 学习 Claude Code：注入机制
- 💡 方向：Skill 即治理单元（GD-2）

### 4.2 如何让 AI 独立完成服务器开发？

> 基于 5 个工具的分析 + AI 自己的理解，探索 CodeStudio 的发展方向。

#### 核心问题

**目标**：让 AI（Claude Code / CodeBuddy CLI）能**独立完成**线上服务器的开发、Review、Debug。

**当前瓶颈**：
1. **知识缺失**：AI 不知道项目上下文（架构、部署流程、常见 bug）
2. **流程无强制**：AI 可能跳过关键步骤（如"部署前必须跑 staging"）
3. **验证能力弱**：AI 能写代码，但无法验证在生产环境是否真的 work
4. **安全风险**：AI 可能做出破坏性操作（误删数据库、错误配置）

---

#### 从 5 个工具中学到的

| 工具 | 贡献 | 局限性 |
|------|----------|----------|
| **CCGS** | ✅ 结构化工作流（7 个阶段）<br>✅ Director Gates（质量门禁） | ❌ Gates 是软性的（Agent 可以不遵守）<br>❌ 静态知识（不会从实践学习） |
| **Claude Code** | ✅ 27 种 Hook 事件（最细粒度）<br>✅ 原生工具 + 外部工具 | ❌ 无内置知识管理<br>❌ 无流程强制执行 |
| **Hermes Agent** | ✅ Memory 插件系统（8 个）<br>✅ Session DB（历史管理） | ❌ 无治理框架<br>❌ 无流程强制执行 |
| **mugc_tools** | ✅ OpenSpec（上下文管理）<br>✅ 服务器开发特化工具 | ❌ 限于特定场景<br>❌ 无形式化门禁 |
| **CodeStudio** | ✅ N+M 架构（解耦）<br>✅ GD 治理（形式化约束）<br>✅ Evidence Chain（闭环） | ⏳ 未实现（需要验证） |

---

#### CodeStudio 的 3 个核心能力

##### 能力 1：知识系统（Knowledge System）

**目标**：让 AI 能快速获取项目背景知识，不重复劳动。

**设计方向**：
```
trace → evidence → knowledge → injection
   ↓          ↓           ↓            ↓
操作记录   →  提炼知识  →  结构化存储  →  注入上下文
```

**具体实现**：
- **静态知识**（项目架构、部署流程）：`.md` 文档 + OpenSpec
- **动态知识**（常见 bug、调试经验）：从实践中提炼（Evidence Chain）
- **注入机制**：自动注入相关上下文（类似 Claude Code 的 Skill 注入）

**参考**：
- ✅ CCGS：`.claude/docs/*.md`
- ✅ mugc_tools：OpenSpec
- ✅ Hermes Agent：Memory 插件

---

##### 能力 2：流程确认（Process Enforcement）

**目标**：确保关键流程（如生产部署）符合规范，**强制**而非**建议**。

**设计方向**：
```
GD-1（治理定义）→ GD-2（治理实例）→ Enforcer（执行）
   ↓                    ↓                    ↓
定义约束           实例化约束        强制执行约束
```

**具体实现**：
- **形式化 Gates**：JSON Schema 验证（而非 CCGS 的自由文本）
- **自动化检查**：Pre-tool Hook 检查（如"部署前必须跑 staging"）
- **证据收集**：收集操作证据（如"staging 测试通过截图"）
- **人工审批**：高风险操作需要人工确认

**参考**：
- ✅ CCGS：Director Gates（但软性）
- ✅ CodeStudio：GD-1/2（形式化）
- ✅ Claude Code：Pre-tool Hook（但无 Governance 层）

---

##### 能力 3：安全机制（Safety Mechanisms）

**目标**：防止 AI 做出破坏性操作，提供回滚能力。

**设计方向**：
```
Sandbox → Dry-run → Checkpoint → Audit Log
   ↓          ↓          ↓            ↓
隔离环境    预演操作    创建还原点    记录所有操作
```

**具体实现**：
- **沙箱执行**：在 staging 环境先跑（Claude Code 有类似机制）
- **Dry-run 模式**：显示"会做什么"，不实际执行
- **Checkpoint/Restore**：操作前创建还原点（类似 Docker commit）
- **审计日志**：所有操作记录到 Session DB（Hermes Agent 有类似机制）

**参考**：
- ✅ Claude Code：Dry-run 模式
- ✅ Hermes Agent：Session DB
- ❌ CCGS：无安全机制

---

#### CodeStudio 的差异化定位

| 维度 | Claude Code | CodeStudio |
|------|-------------|-------------|
| **定位** | 通用 Coding Agent | 服务器开发特化 Agent |
| **知识管理** | 静态（.claude/ 目录） | 动态（Evidence Chain） |
| **流程强制** | 无（依赖用户配置 Hook） | 有（GD 治理框架） |
| **安全机制** | 基础（Dry-run） | 增强（Sandbox + Checkpoint） |
| **多 CLI 支持** | ❌ 只支持 Anthropic API | ✅ 支持多 Provider |

---

#### 开放问题（需要验证）

##### Q1：知识系统如何设计？

**选项 1**：静态知识（.md 文档）
- ✅ 简单，易于 humans 编写
- ❌ 不会进化，可能过时

**选项 2**：动态知识（Evidence Chain）
- ✅ 从实践中学习，持续改进
- ❌ 复杂，需要设计提炼算法

**选项 3**：混合（静态 + 动态）
- ✅ 兼顾简单性和进化能力
- ❌ 需要设计融合机制

**我的建议**：**选项 3**（混合）
- 静态知识：项目架构、部署流程（稳定，不常变）
- 动态知识：常见 bug、调试经验（易变，需持续更新）

---

##### Q2：流程强制如何实现？

**选项 1**：软性 Gates（像 CCGS）
- ✅ 简单，易于实现
- ❌ Agent 可以不遵守

**选项 2**：形式化 Gates（JSON Schema 验证）
- ✅ 可自动化验证
- ❌ 需要设计 Schema

**选项 3**：Hook + Governance（像 CodeStudio 设计的）
- ✅ 强制执衟，可自动化
- ❌ 复杂，需要设计 Enforcer

**我的建议**：**选项 3**（Hook + Governance）
- Pre-tool Hook 检查 Gates 状态
- Enforcer 强制执行（exit code ≠ 0 → 阻断操作）
- Evidence 收集（证明 Gates 已通过）

---

##### Q3：如何验证 AI 的输出？

**选项 1**：人工验证（像现在）
- ✅ 安全
- ❌ 慢，成本高

**选项 2**：自动化测试（Unit + Integration + E2E）
- ✅ 快速，可重复
- ❌ 需要写测试（可能 AI 也要写）

**选项 3**：金丝雀发布（Canary Deployment）
- ✅ 真实流量验证
- ❌ 需要基础设施支持

**我的建议**：**选项 2 + 选项 3**（混合）
- 自动化测试：覆盖核心路径
- 金丝雀发布：小流量验证
- 自动回滚：失败 → 自动回滚

---

### 4.3 待验证的假设

| 假设 | 验证方法 | 状态 |
| ------ | --------- | ------ |
| 假设 1：知识复用能显著提升 AI 开发效率 | 实践验证（Round 1-3） | ⏳ 待验证 |
| 假设 2：形式化门禁比软性 Gates 更安全 | 对比测试 | ⏳ 待验证 |
| 假设 3：不同知识需要不同格式（.md / skill / evidence） | 实践验证 | ⏳ 待验证 |

---

### 4.4 设计决策记录（DR）

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

#### DR-002：知识系统采用混合模式（静态 + 动态）

**决策**：✅ 是，采用混合模式（静态知识 + 动态知识）

**理由**：

1. 静态知识（项目架构、部署流程）稳定，不常变，适合手动编写

2. 动态知识（常见 bug、调试经验）易变，需从实践中持续更新

3. 混合模式兼顾简单性和进化能力

**替代方案**：

- ❌ 纯静态知识 → 不会进化，可能过时
- ❌ 纯动态知识 → 复杂，需要设计提炼算法

**状态**：✅ 已决策，待设计 Evidence Chain

---

#### DR-003：安全机制采用 Sandbox + Checkpoint

**决策**：✅ 是，实现 Sandbox + Checkpoint + Audit Log

**理由**：

1. 服务器开发高风险，必须有安全机制

2. Sandbox 可以在隔离环境预演操作

3. Checkpoint 提供回滚能力

4. Audit Log 记录所有操作，便于追责

**替代方案**：

- ❌ 无安全机制 → 高风险
- ❌ 只有 Dry-run → 无法回滚

**状态**：✅ 已决策，待设计 Safety Module

---

## 五、行动清单（下一步做什么？）

### 5.1 立即行动（本周）

| 任务 | 优先级 | 预计时间 | 输出 | 状态 |
| ------ | -------- | --------- | ------ | ------ |
| ① 开始实践验证（Round 1） | 高 | 2-3 小时 | `2-1-practice-round1.md` 第一版 | ⏳ 待开始 |
| ② 完成综合设计文档 | 高 | 3-5 小时 | `3-synthesis-and-design.md` 第一版 | ⏳ 待开始 |
| ③ 补充 Hermes Memory 系统分析 | 中 | 1-2 小时 | 更新 `1-3-5-hermes-memory-system.md` | ✅ 已完成 |

### 5.2 短期计划（本月）

- [ ] 完成 `2-1-practice-round1.md`（实践验证 Round 1）
- [ ] 完成 `2-2-practice-round2.md`（实践验证 Round 2）
- [ ] 完成 `2-3-practice-round3.md`（实践验证 Round 3）
- [ ] 完成 `3-synthesis-and-design.md`（综合设计）
- [ ] 完成 `4-practice-learnings.md`（实践学习总结）

---

## 六、文档更新日志

| 日期 | 更新内容 | 更新人 |
| ------ | --------- | -------- |
| 2026-05-05 | 基于最新 1-x 和 2-x 文档更新：1. 更新学习计划表（3.1）状态为 ✅ 已完成 2. 更新阶段性目标（2.2）文档编号 3. 更新学习问题（3.2）Claude Code、mugc_tools、Hermes Agent 状态 4. 更新 CodeStudio 规划（4.1）添加基于 5 个工具分析的思考 5. 更新行动清单（五）任务状态 | Vacky + AI |
| 2026-05-04 | 创建文档，记录核心问题、目标、学习规划 | Vacky + AI |

---

**文档状态**：📝 持续更新

**下一步**：

- [ ] 开始分析 Claude Code 源码（填写第三节的"Claude Code CLI"部分）
- [ ] 做一个超小实践（验证 Q1-Q5）
- [ ] 记录第一个设计决策（DR-002）
