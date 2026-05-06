# mugc_server_ai_tools 分析 #

> **文档定位**：梳理 mugc_server_ai_tools 的设计、实现、亮点，对比 CodeStudio，并针对 `0-problems-and-goals.md` 中的问题提出解决思路。
>
> **本文结构**：

> - **主文档**（本文件）：总结性输出，建立整体认知
> - **子文档**（深入细节）：
>   - `1-5-1-mugc-tools-architecture.md`：整体架构、Agent 系统、Command 系统、Skill 系统、Rules 系统、OpenSpec 元数据
>   - `1-5-2-mugc-tools-agents.md`：11 个 Agent 详细说明（YAML front matter + Markdown）
>   - `1-5-3-mugc-tools-commands.md`：19 个 Command 详细说明（OpenSpec 工作流）
>   - `1-5-4-mugc-tools-skills.md`：69 个 Skill 模块详细说明（SKILL.md + references/）
>   - `1-5-5-mugc-tools-rules.md`：Rules 系统详细说明（.mdc 文件、强制规则机制）
>   - `1-5-6-mugc-tools-openspec.md`：OpenSpec 元数据详细说明（变更管理流程）

---

## 一、一句话总结 ##

mugc_server_ai_tools 是一个为**多种 AI 编码助手**提供 `rules`、`commands`、`skills` 和 `openspec` 元数据的**工具仓库**。支持 CodeBuddy、Claude Code、Gemini CLI、Codex、Cursor 等工具。

**核心设计理念**：

- **Symlink 部署模型**：所有内容通过**符号链接**集成到目标项目，不复制文件，便于集中管理和版本同步

- **多工具支持**：通过 `install.sh` 脚本，将 `rules/`、`commands/`、`skills/` 链接到对应工具的配置目录（`.codebuddy/`, `.claude/`, `.gemini/`, `.codex/`, `.cursor/`）

- **强制规则机制**：`rules/*.mdc` 中使用 `alwaysApply: true`，规则在每次 AI 会话中始终生效

- **OpenSpec 工作流**：提供从需求探索 → 提案 → 设计 → 实现 → 验证 → 归档的完整变更管理流程

---

## 二、核心设计概览 ##

### 2.1 整体架构 ###

```text
mugc_server_ai_tools/
├── agents/             ← Agent 定义（11 个 .md 文件，YAML front matter + Markdown）
├── commands/           ← OpenSpec 工作流命令（19 个 .md 文件）
├── contexts/           ← 上下文文件（待分析）
├── docker/             ← Docker 配置（部署相关）
├── install/            ← 安装脚本（总入口 + 各工具独立脚本）
├── mcps/              ← MCP 配置（MCP 服务器配置）
├── openspec/           ← OpenSpec 规范元数据（47 个 .md 文件）
│   ├── meta/          ← OpenSpec 元数据（链接到目标项目）
│   └── templates/    ← 提案、设计、规格说明、条件模板
├── rules/              ← CodeBuddy 规则定义（.mdc 文件，含 YAML front matter）
├── skills/             ← 技能模块（387 个文件！174 个 .md + 107 个 .py + ...）
│   ├── activity-creator/
│   ├── code-reviewer/
│   ├── openspec-new-change/
│   └── ...（22 个技能模块）
├── token-saving/       ← Token 节省策略（待分析）
└── README.md           ← 项目概述
```text

**深入细节** → 详见 `1-5-1-mugc-tools-architecture.md`

### 2.2 Agent 系统（11 个） ###

**Agent 定义格式**（YAML front matter + Markdown）：

```markdown
---
name: architect
description: Software architecture specialist for system design...
tools: ["Read", "Grep", "Glob"]
model: opus
---

You are a senior software architect...
```text

**Agent 列表**（11 个）：

| Agent 名称 | 模型 | 主要职责 |
| ----------- | ------ | ---------- |
| `architect` | opus | 软件架构师，系统设计、技术决策 |
| `architecture-expert` | ? | 架构专家 |
| `build-expert` | ? | 构建专家 |
| `code-reviewer` | ? | 代码审查 |
| `harness-optimizer` | ? | Harness 优化器 |
| `java-code-style-reviewer` | ? | Java 代码风格审查 |
| `java-reviewer` | ? | Java 代码审查 |
| `performance-optimizer` | ? | 性能优化器 |
| `security-reviewer` | ? | 安全审查 |
| `server-updater` | ? | 服务器更新器 |
| `simulator4j-tester` | ? | Simulator4j 测试器 |

**与 CCGS 的对比**：

| 维度 | CCGS（49 个 Agent） | mugc_tools（11 个 Agent） |
| ------ | --------------------- | -------------------------- |
| **数量** | 49 个（非常多） | 11 个（精简） |
| **定位** | 游戏开发全流程 | 服务器端开发 + Java 生态 |
| **模型** | 全部指定（Opus/Sonnet/Haiku） | 部分指定 |
| **工具** | 全部指定 | 部分指定 |

**深入细节** → 详见 `1-5-2-mugc-tools-agents.md`

### 2.3 Command 系统（19 个） ###

**Command 定义格式**（Markdown 文件）：

- 文件路径：`commands/<command-name>.md`

- 内容：命令的工作流、使用示例、输出格式

**OpenSpec 工作流命令**（19 个）：

| 命令 | 说明 |
| ------ | ------ |
| `openspec-new-change` | 创建新变更提案 |
| `openspec-continue-change` | 继续已有变更 |
| `openspec-apply-change` | 应用变更到代码 |
| `openspec-verify-change` | 验证变更 |
| `openspec-archive-change` | 归档已完成变更 |
| `openspec-bulk-archive-change` | 批量归档 |
| `openspec-explore` | 探索需求 |
| `openspec-onboard` | 新成员入门 |
| `openspec-publish-wiki` | 发布到 Wiki |
| `openspec-review-change` | 审查变更 |
| `openspec-sync-specs` | 同步规格说明 |
| ... | ... |

**与 CCGS Skill 的对比**：

| 维度 | CCGS Skill（72 个） | mugc_tools Command（19 个） |
| ------ | --------------------- | ---------------------------- |
| **数量** | 72 个 | 19 个 |
| **格式** | Markdown（YAML front matter + 工作流） | Markdown（工作流） |
| **调用方式** | `/skill-name`（slash 命令） | `/<command-name>` |
| **功能** | 游戏开发全流程 | OpenSpec 变更管理 + 代码生成 |

**深入细节** → 详见 `1-5-3-mugc-tools-commands.md`

### 2.4 Skill 系统（22 个模块，387 个文件） ###

**Skill 结构约定**（统一结构）：

```text
skills/<skill-name>/
├── SKILL.md          # 技能定义：触发条件、工作流、输出格式
└── references/       # 参考文档：领域知识、规范、示例
```text

**Skill 分类**（22 个）：

| 分类 | 数量 | 示例 |
| ------ | ------ | ------ |
| **OpenSpec 工作流** | 8 | `openspec-new-change`, `openspec-continue-change`, `openspec-apply-change`, ... |
| **代码生成** | 3 | `activity-creator`, `condition-creator`, `res-creator` |
| **代码分析** | 3 | `code-reviewer`, `protocol-call-tracer`, `config-usage-tracer` |
| **辅助工具** | 8 | `brainstorming`, `skill-creator`, `xlsx`, `excel-to-md`, ... |

**与 CCGS Skill 的对比**：

| 维度 | CCGS Skill | mugc_tools Skill |
| ------ | ------------- | ------------------- |
| **结构** | 单文件（.md） | 目录（SKILL.md + references/） |
| **参考文档** | ❌ 无 | ✅ 有（references/ 目录） |
| **领域专注** | 游戏开发 | 服务器端开发 + Java 生态 + OpenSpec |

**深入细节** → 详见 `1-5-4-mugc-tools-skills.md`

### 2.5 Rules 系统（.mdc 文件） ###

**Rules 格式**（CodeBuddy 规则，`.mdc` 文件）：

```markdown
---
alwaysApply: true
---

# Rule Title

Rule content...
```text

**关键设计**：

- `alwaysApply: true`：规则在每次 AI 会话中**始终生效**（强制规则机制）

- 示例：`code-review.mdc` — 强制要求：代码编写完成后必须调用 `skills:code-reviewer` 进行审查

- 示例：`skill-context-first.mdc` — 强制要求：需求开发前必须先阅读对应领域的 skill 文档

**与 CCGS Rules 的对比**：

| 维度 | CCGS Rules（11 条） | mugc_tools Rules（.mdc 文件） |
| ------ | --------------------- | ------------------------------ |
| **格式** | Markdown（YAML front matter + 规则内容） | Markdown（YAML front matter + 规则内容） |
| **强制机制** | ❌ 无（依赖模型遵守） | ✅ `alwaysApply: true`（强制规则） |
| **路径级规则** | ✅ 有（`paths:` 字段） | ?（待分析） |

**深入细节** → 详见 `1-5-5-mugc-tools-rules.md`

### 2.6 OpenSpec 元数据（openspec/ 目录） ###

**OpenSpec 设计**：

- **目标**：提供从需求探索 → 提案 → 设计 → 实现 → 验证 → 归档的完整变更管理流程

- **元数据存放**：`openspec/meta/` 链接到 `<目标项目>/openspec/meta/` 下

- **模板**：`openspec/templates/` 包含提案（`proposal.md`）、设计（`design.md`）、规格说明（`spec.md`）、条件（`condition.md`）模板

**OpenSpec 工作流**：

```text
[1] openspec-explore      → 探索需求
         ↓
[2] openspec-new-change   → 创建新变更提案
         ↓
[3] openspec-continue-change → 继续已有变更
         ↓
[4] openspec-apply-change → 应用变更到代码
         ↓
[5] openspec-verify-change → 验证变更
         ↓
[6] openspec-archive-change → 归档已完成变更
```text

**与 CodeStudio 的对比**：

| 维度 | CodeStudio（设计上） | mugc_tools（已实现） |
| ------ | --------------------- | ----------------------- |
| **变更管理** | GD-2 组织资产（Constraint + Checklist） | OpenSpec 工作流（变更提案、设计、验证、归档） |
| **形式化** | ✅ 计划中实现 | ✅ 已实现（但非形式化） |
| **与项目集成** | ⏳ 待实现 | ✅ 已实现（通过 symlink） |

**深入细节** → 详见 `1-5-6-mugc-tools-openspec.md`

---

## 三、亮点与创新 ##

| 亮点 | 说明 | 相对 CCGS/Claude Code 的优势 |
| ------ | ------ | ---------------------------------- |
| **① 多工具支持** | 通过 symlink 部署模型，支持 5 种 AI 工具 | CCGS/Claude Code 只支持 Claude Code |
| **② 强制规则机制** | `alwaysApply: true` 的 `.mdc` 规则 | CCGS 的规则依赖模型遵守（不可靠） |
| **③ OpenSpec 工作流** | 完整的变更管理流程 | CCGS 没有（只有单独的 Skill） |
| **④ Symlink 部署模型** | 集中管理，版本同步，不复制文件 | CCGS 需要手动复制到项目目录 |
| **⑤ 领域专注** | 针对 letsgo_server + Java 生态优化 | CCGS 是通用游戏开发模板 |

---

## 四、当前状态（2026-05） ##

| 维度 | 完成度 | 说明 |
| ------ | -------- | ------ |
| **多工具支持** | ✅ 完成 | 支持 5 种 AI 工具（CodeBuddy、Claude Code、Gemini、Codex、Cursor） |
| **Agent 定义** | ✅ 完成（基础） | 11 个 Agent，部分需要补充模型/工具定义 |
| **Command 定义** | ✅ 完成 | 19 个 OpenSpec 工作流命令 |
| **Skill 定义** | ✅ 完成（基础） | 22 个技能模块，387 个文件 |
| **Rules 定义** | ✅ 完成（基础） | `.mdc` 文件，强制规则机制 |
| **OpenSpec 元数据** | ✅ 完成 | 47 个 .md 文件，完整的变更管理流程 |
| **文档** | 🔨 进行中 | README.md 已完成，部分技能需要补充文档 |

---

## 五、与 CodeStudio 的对比 ##

### 5.1 定位对比 ###

| 维度 | mugc_tools | CodeStudio | CodeStudio 的优势 |
| ------ | -------------- | ------------ | ------------------- |
| **定位** | 工具仓库（rules/commands/skills/openspec） | Agent Harness 框架（治理 Agent 行为） | CodeStudio 更通用，不绑定特定领域 |
| **依赖** | 各 AI 工具（CodeBuddy、Claude Code...） | 自己实现 Harness | CodeStudio 支持多 LLM、多 CLI |
| **知识复用** | Symlink 部署模型（集中管理） | CAP-1 Injector + 证据链闭环 | CodeStudio 的知识进化更系统化 |
| **流程确认** | OpenSpec 工作流（非形式化） | CAP-2 Enforcer + GD+CC 双轴治理 | CodeStudio 有形式化流程确认 |
| **多工具支持** | ✅ 已实现（5 种 AI 工具） | ✅ 设计上支持 | 两者都支持，但方式不同 |

---

## 六、针对 0- 中的问题的解决方案 ##

### 6.1 Q1：知识复用效率低 ###

**mugc_tools 的解决方案**：

| 机制 | 说明 | 状态 |
| ------ | ------ | ------ |
| **Symlink 部署模型** | 集中管理，版本同步，不复制文件 | ✅ 已实现 |
| **OpenSpec 元数据** | 变更管理流程（提案、设计、验证、归档） | ✅ 已实现 |
| **Skills（目录结构）** | `SKILL.md` + `references/`（参考文档） | ✅ 已实现 |

**不足**：

- 知识是**静态的**（不会从实践中学习）

- 没有**证据链闭环**（`trace → evidence → knowledge → injection`）

- `references/` 目录是静态参考文档（不会进化）

**对 CodeStudio 的启发**：

1. **借鉴**：Symlink 部署模型（多工具支持）

2. **借鉴**：Skills 目录结构（`SKILL.md` + `references/`）

3. **改进**：实现证据链闭环（系统化学习）

### 6.2 Q2：流程确认依赖人工 ###

**mugc_tools 的解决方案**：

| 机制 | 说明 | 不足 |
| ------ | ------ | ------ |
| **OpenSpec 工作流** | 变更管理流程（非形式化） | 依赖用户手动执行每个步骤 |
| **强制规则** | `alwaysApply: true`（.mdc 规则） | 只强制"必须先做某事"，不检查"是否做对了" |

**不足**：

- 没有**形式化流程确认**机制

- 没有**约束检查器**（CAP-2 Enforcer）

- 依赖**用户手动执行** OpenSpec 工作流

**对 CodeStudio 的启发**：

1. **借鉴**：OpenSpec 工作流（变更管理流程）

2. **改进**：实现 CAP-2 Enforcer（形式化约束检查）

3. **改进**：将 OpenSpec 工作流形式化为 GD-2 组织资产

### 6.3 Q3：知识格式不清晰 ###

**mugc_tools 的解决方案**：

| 知识类型 | 格式 | 示例 |
| --------- | ------ | ------ |
| **静态知识** | `.mdc` 规则（rules/） | `code-review.mdc`, `skill-context-first.mdc` |
| **流程知识** | OpenSpec 命令（commands/opsx/） | `openspec-new-change.md`, `openspec-apply-change.md` |
| **技能知识** | Skill 目录（skills/<name>/） | `SKILL.md` + `references/` |
| **变更元数据** | OpenSpec 元数据（openspec/meta/） | `proposal.md`, `design.md`, `spec.md` |

**优势**（相对 CCGS）：

- **Symlink 部署模型**：集中管理，版本同步

- **强制规则机制**：`alwaysApply: true`

- **Skills 目录结构**：`SKILL.md` + `references/`（参考文档）

**不足**：

- 知识格式**不统一**（.mdc、.md、目录结构）

- 没有**结构化知识格式**（如 JSON Schema）

- 知识是**静态的**（不会进化）

**对 CodeStudio 的启发**：

1. **借鉴**：Skills 目录结构（`SKILL.md` + `references/`）

2. **借鉴**：OpenSpec 元数据（变更管理）

3. **改进**：定义结构化的知识格式（JSON Schema）

### 6.4 Q4：缺乏系统性学习 ###

**mugc_tools 的解决方案**：

| 机制 | 说明 | 状态 |
| ------ | ------ | ------ |
| **无** | ❌ mugc_tools 没有系统性学习机制 | ❌ 未实现 |

**不足**：

- 没有**证据链闭环**（`trace → evidence → knowledge → injection`）

- 不会从实践中**系统化学习**

- 知识是**静态的**（不会进化）

**对 CodeStudio 的启发**：

1. **实现**：证据链闭环（系统化学习）

2. **实现**：`catalog/` 目录结构（结构化知识管理）

### 6.5 Q5：实践验证不足 ###

**mugc_tools 的解决方案**：

| 机制 | 说明 | 状态 |
| ------ | ------ | ------ |
| **无** | ❌ mugc_tools 没有实践验证机制 | ❌ 未实现 |

**不足**：

- 没有** A/B 测试**不同配置的效果

- 没有**量化指标**（如 tool_call 成功率、用户满意度）

- 依赖**手动测试**和**用户反馈**

**对 CodeStudio 的启发**：

1. **实现**：实践验证机制（A/B 测试不同配置）

2. **实现**：量化指标（tool_call 成功率、预算使用效率、用户满意度）

---

## 七、总结与下一步 ##

### 7.1 核心结论 ###

1. **mugc_server_ai_tools 是多工具知识仓库**：通过 Symlink 部署模型，支持 5 种 AI 工具，提供集中管理的 rules/commands/skills/openspec

2. **mugc_tools 的亮点**：多工具支持、强制规则机制、OpenSpec 工作流、Symlink 部署模型

3. **mugc_tools 的不足**：缺乏形式化流程确认、缺乏系统性学习、知识复用效率有待提高

4. **CodeStudio 可以改进的方向**：在 mugc_tools 的基础上，增加治理层（CAP-2 Enforcer、证据链闭环、GD+CC 双轴治理、统一 Hook 系统、知识进化机制）

### 7.2 下一步 ###

| 任务 | 优先级 | 预计时间 |
| ------ | -------- | --------- |
| **① 整合 mugc_tools 的亮点** | P0 | 1-2 周 |
| **② 实现 CAP-2 Enforcer** | P0 | 1-2 周 |
| **③ 实现证据链闭环** | P0 | 2-3 周 |
| **④ 在 letsgo_server 上验证** | P1 | 立即 |

---

**文档状态**：✅ 第二版完成（主文档 + 子文档结构，总结性输出 + 深入细节拆分）

**子文档列表**：

| 子文档 | 内容 |
| --------- | ------ |
| `1-5-1-mugc-tools-architecture.md` | 整体架构、Agent 系统、Command 系统、Skill 系统、Rules 系统、OpenSpec 元数据 |
| `1-5-2-mugc-tools-agents.md` | 11 个 Agent 详细说明（YAML front matter + Markdown、与 CCGS 的对比） |
| `1-5-3-mugc-tools-commands.md` | 19 个 Command 详细说明（OpenSpec 工作流、与 CCGS Skill 的对比） |
| `1-5-4-mugc-tools-skills.md` | 22 个 Skill 模块详细说明（SKILL.md + references/、与 CCGS Skill 的对比） |
| `1-5-5-mugc-tools-rules.md` | Rules 系统详细说明（.mdc 文件、强制规则机制、与 CCGS Rules 的对比） |
| `1-5-6-mugc-tools-openspec.md` | OpenSpec 元数据详细说明（变更管理流程、与 CodeStudio 的对比） |

**下一步**：

- [ ] 与 CCGS/Hermes Agent/Claude Code 做更详细的对比

- [ ] 启动 letsgo_server 实证，记录卡点

- [ ] 整合 mugc_tools 的亮点（Symlink 部署模型、Skills 目录结构）到 CodeStudio
