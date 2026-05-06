# mugc_tools 架构详解

> **文档定位**：深入 mugc_server_ai_tools 的整体架构、Agent 系统、Command 系统、Skill 系统、Rules 系统、OpenSpec 元数据。

---

## 一、整体架构

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

**核心设计理念**：

- **Symlink 部署模型**：所有内容通过**符号链接**集成到目标项目，不复制文件，便于集中管理和版本同步
- **多工具支持**：通过 `install.sh` 脚本，将 `rules/`、`commands/`、`skills/` 链接到对应工具的配置目录（`.codebuddy/`, `.claude/`, `.gemini/`, `.codex/`, `.cursor/`）
- **强制规则机制**：`rules/*.mdc` 中使用 `alwaysApply: true`，规则在每次 AI 会话中始终生效
- **OpenSpec 工作流**：提供从需求探索 → 提案 → 设计 → 实现 → 验证 → 归档的完整变更管理流程

---

## 二、Agent 系统（11 个）

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

**深入细节** → 详见 `1-5-3-mugc-tools-agents.md`

---

## 三、Command 系统（19 个）

**Command 定义格式**（Markdown 文件）：

- 文件路径：`commands/opsx/<command-name>.md`
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
| **调用方式** | `/skill-name`（slash 命令） | `/opsx/<command-name>` |
| **功能** | 游戏开发全流程 | OpenSpec 变更管理 + 代码生成 |

**深入细节** → 详见 `1-5-4-mugc-tools-commands.md`

---

## 四、Skill 系统（22 个模块，387 个文件）

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

**深入细节** → 详见 `1-5-5-mugc-tools-skills.md`

---

## 五、Rules 系统（.mdc 文件）

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

**深入细节** → 详见 `1-5-6-mugc-tools-rules.md`

---

## 六、OpenSpec 元数据（openspec/ 目录）

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

**深入细节** → 详见 `1-5-7-mugc-tools-openspec.md`

---

**文档状态**：✅ 第一版完成（从 `1-5-mugc-tools-analysis.md` 拆分）

**下一步**：

- [ ] 补充更多架构细节（从 mugc_server_ai_tools 源码提取）
- [ ] 补充 Symlink 部署模型的详细实现（install.sh）
