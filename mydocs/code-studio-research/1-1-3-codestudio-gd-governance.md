# CodeStudio GD 三域治理体系详解

> **⚠️ 重要说明**：本文档描述 CodeStudio 的**设计方案**，当前系统**尚未实现**。
>
> **文档定位**：深入 CodeStudio 的 GD（Good Design）三域治理体系。

---

## 一、GD 三域治理概述

GD（Good Design）是 CodeStudio 的治理框架，分为三个域：

| 域 | 名称 | 职责 | 对应 CCGS 的什么？ |
| ----- | ------ | ------ | --------------------- |
| **GD-1** | 实例层 | Session 级别的实例化（注入项目特定的 knowledge + constraint） | CCGS 的 Agent 实例化（但 CCGS 没有"实例"概念） |
| **GD-2** | 组织资产 | 约束 + 流程（constraint + checklist） | CCGS 的 Rules + Director Gates |
| **GD-3** | 能力域 | CAP 能力（CAP-1~5） | CCGS 的 Agent/Tool/Hook 系统 |

**核心差异**（相对 CCGS）：

- ✅ **GD-2 是形式化的**（Constraint + Checklist 有结构化格式，不是自由文本）
- ✅ **GD-3 是可组合的**（CAP-1~5 可以按需启用，不是全部启用）

---

## 二、GD-1 实例层

**目标**：Session 级别的实例化，注入项目特定的 knowledge + constraint。

**关键设计**：

- 每个 session 是一个实例
- 实例包含：project_input + knowledge + constraint
- 实例隔离：不同 session 可以有不同的 knowledge/constraint 组合

**与 CCGS 的对比**：

| 维度 | CCGS | CodeStudio |
| ------ | ------- | ------------ |
| **实例化** | Agent 是静态的（.claude/agents/*.md） | Session 是动态的（实例化时注入） |
| **项目特定知识** | 静态 .md 文档 | 动态注入（可更新） |
| **约束** | Director Gates（自由文本） | Constraint（结构化格式） |

---

## 三、GD-2 组织资产

**目标**：管理约束 + 流程（constraint + checklist）。

**约束（Constraint）格式**：

```yaml

# catalog/constraints/db-change.md

---
name: db-change
description: "数据库变更必须有回滚方案"
scope: [dev, debug]
severity: error  # error / warning / info
check:
  type: checklist
  items:

    - "是否有回滚脚本？"
    - "是否在生产环境测试过？"
    - "是否有数据备份？"

---
```text

**Checklist 格式**：

```yaml

# catalog/flows/deploy.md

---
name: deploy
description: "部署流程"
steps:

  - name: "运行 staging 测试"
    required: true

  - name: "检查数据库迁移"
    required: true

  - name: "备份生产数据"
    required: true
---
```text

**与 CCGS 的对比**：

| 维度 | CCGS | CodeStudio |
| ------ | ------- | ------------ |
| **约束格式** | Director Gates（自由文本） | Constraint（结构化 YAML + JSON Schema 验证） |
| **流程格式** | 无（依赖 Skill 工作流） | Flow（结构化 YAML） |
| **验证方式** | 人工审查 | 自动化验证（CAP-2 Enforcer） |

---

## 四、GD-3 能力域

**目标**：管理 CAP 能力（CAP-1~5）。

**CAP 能力可组合**：

| CAP | 是否必须？ | 说明 |
| ----- | ----------- | ------ |
| **CAP-1** | 推荐 | 注入知识，提升 AI 输出质量 |
| **CAP-2** | 强烈推荐 | 强制执行约束，防止 AI 做坏事 |
| **CAP-3** | 可选 | 记录 trace，用于知识进化 |
| **CAP-4** | 推荐 | 捕获异常，防止 AI 失控 |
| **CAP-5** | 推荐 | 自动分类意图，提升用户体验 |

**与 CCGS 的对比**：

| 维度 | CCGS | CodeStudio |
| ------ | ------- | ------------ |
| **Agent 系统** | 49 个 Agent（全部启用） | CAP-5 Router（按需启用） |
| **Tool 系统** | Claude Code 内置工具（全部启用） | MCP 工具（按需接入） |
| **Hook 系统** | 12 个 Hooks（全部启用） | CAP-4 Interceptor（按需启用） |

---

**文档状态**：✅ 第一版完成（从 `1-1-code-studio-analysis.md` 拆分）

**下一步**：

- [ ] 补充更多 GD-2 约束示例（从 `codestudio-spec/` 提取）
- [ ] 补充 CAP 能力组合策略（哪些场景需要哪些 CAP）
