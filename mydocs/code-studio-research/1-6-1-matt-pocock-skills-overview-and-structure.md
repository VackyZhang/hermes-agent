# Matt Pocock Skills 仓库分析（一）：概述与结构

> **分析对象**：[mattpocock/skills](https://github.com/mattpocock/skills)  
> **分析日期**：2026-05-06  
> **分析目的**：理解 Matt Pocock 的 Skills 设计理念，为 CodeStudio 提供借鉴

**完整分析**：[`1-6-matt-pocock-skills-analysis.md`](./1-6-matt-pocock-skills-analysis.md)（已拆分为 1-6-1 ~ 1-6-4）

---

## 一、仓库概述

### 1.1 核心理念

> "My agent skills that I use every day to do real engineering - not vibe coding."  
> — Matt Pocock

**设计哲学**：
- ✅ **小而美**：每个 skill 小而专注，易于理解和修改
- ✅ **可组合**：Skills 可以组合使用，而非大而全的框架
- ✅ **模型无关**：基于 decades 的工程经验，适用于任何模型
- ❌ **不拥有流程**：不同于 GSD、BMAD、Spec-Kit 等框架，不剥夺用户控制权

**来源**：Matt Pocock 是一位 TypeScript 专家，拥有超过 20 年的工程经验。他创建这些 skills 是因为现有框架（GSD、BMAD、Spec-Kit）"own the process"（拥有流程），让开发者失去了对代码库的控制。

---

### 1.2 解决的问题

Matt Pocock 构建这些 skills 是为了修复 Claude Code、Codex 等 Coding Agent 的常见失败模式：

| 问题 | 表现 | 解决方案 |
|------|------|----------|
| **#1: Agent 没做我想要的事** | 沟通鸿沟，理解偏差 | `grill-me` / `grill-with-docs`（对齐会） |
| **#2: Agent 太啰嗦** | 不使用领域语言，20 个词描述 1 个词的事 | `grill-with-docs`（共建语言）<br>`caveman`（压缩通信） |
| **#3: 代码不 work** | 缺乏反馈循环，盲目编码 | `tdd`（红绿重构）<br>`diagnose`（调试循环） |
| **#4: 代码变成大泥球** | 加速编码 = 加速软件熵增 | `improve-codebase-architecture`<br>`to-prd`（模块规划）<br>`zoom-out`（系统视角） |

**理论支持**：每个问题都引用了经典软件工程书籍：
- #1 → *The Pragmatic Programmer* (David Thomas & Andrew Hunt)
- #2 → *Domain-Driven Design* (Eric Evans)
- #3 → *The Pragmatic Programmer* (David Thomas & Andrew Hunt)
- #4 → *Extreme Programming Explained* (Kent Beck) + *A Philosophy of Software Design* (John Ousterhout)

---

### 1.3 快速开始（30 秒设置）

1. **运行安装器**：
   ```bash
   npx skills@latest add mattpocock/skills
   ```

2. **选择 skills 和 coding agents**：
   - 确保选择 `/setup-matt-pocock-skills`

3. **在 agent 中运行 `/setup-matt-pocock-skills`**：
   - 询问你想使用哪个 issue tracker（GitHub、Linear 或本地文件）
   - 询问你 triage issues 时应用什么标签（`/triage` 使用标签）
   - 询问你想将创建的任何文档保存到哪里

4. **Bam - 你已准备好开始**：

---

## 二、仓库结构

### 2.1 目录结构

```
skills/
├── skills/                   # Skills 主目录
│   ├── engineering/          # 工程类 skills（日常代码工作）
│   ├── productivity/         # 效率类 skills（非代码工作流）
│   ├── misc/                # 杂项 skills（不常用）
│   ├── personal/            # 个人 skills（不公开）
│   ├── in-progress/        # 进行中（未发布）
│   └── deprecated/          # 已废弃
├── docs/                    # 文档
│   └── adr/               # 架构决策记录
├── scripts/                 # 脚本
├── README.md                # 总览 + Skill 索引 + "为什么存在这些 Skills"
├── CLAUDE.md               # Skills 组织规则
└── CONTEXT.md              # 领域语言定义
```

---

### 2.2 Skill 结构

每个 skill 是一个**目录**，包含 `SKILL.md` 文件：

```
skills/engineering/diagnose/
├── SKILL.md                # Skill 定义（必需）
├── examples.md              # 示例（可选）
└── scripts/                # 辅助脚本（可选）
```

**`SKILL.md` 格式**：

```markdown
---
name: diagnose
description: Disciplined diagnosis loop for hard bugs...
---

# Diagnose

[Skill 的具体指令和流程]
```

**Frontmatter 字段**：
- `name`：Skill 名称（kebab-case）
- `description`：触发条件（when to use）**← 这是 Agent 决定加载哪个 Skill 时看到的唯一东西**
- `disable-model-invocation`（可选）：设为 `true` 时，不自动触发（如 `zoom-out`、`setup-matt-pocock-skills`）

---

### 2.3 Skills 组织规则（来自 CLAUDE.md）

1. **Bucket folders**：
   - `engineering/` — 日常代码工作
   - `productivity/` — 日常非代码工作流工具
   - `misc/` — 保留但很少使用
   - `personal/` — 绑定到 Matt 自己的设置，不推广
   - `in-progress/` — 草稿，尚未准备好发布
   - `deprecated/` — 不再使用

2. **文档要求**：
   - `engineering/`、`productivity/`、`misc/` 中的每个 skill **必须**在顶层 `README.md` 中有引用，并且在 `.claude-plugin/plugin.json` 中有条目
   - `personal/`、`in-progress/`、`deprecated/` 中的 skills **不得**出现在这两个文件中
   - 每个 bucket folder 有一个 `README.md`，列出该 bucket 中的每个 skill 及其一行描述，skill 名称链接到其 `SKILL.md`

3. **Description 要求**（来自 `write-a-skill` skill）：
   - Description 是 Agent 在决定加载哪个 skill 时看到的**唯一东西**
   - 它和所有其他已安装的 skills 一起出现在系统提示中
   - Agent 读取这些描述并根据用户的请求选择相关的 skill
   - **目标**：给你的 agent 足够的信息知道：
     1. 这个 skill 提供什么能力
     2. 何时/为什么触发它（具体关键词、上下文、文件类型）
   - **格式**：
     - 最多 1024 字符
     - 用第三人称写
     - 第一句：它做什么
     - 第二句："Use when [specific triggers]"
   - **好例子**：
     ```
     Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when user mentions PDFs, forms, or document extraction.
     ```
   - **坏例子**：
     ```
     Helps with documents.
     ```

---

### 2.4 Skills 分类

#### Engineering Skills（工程类，日常使用）

| Skill | 用途 | 触发条件 |
|-------|------|----------|
| **diagnose** | disciplined 调试循环 | "diagnose this" / "debug this" / 报告 bug |
| **grill-with-docs** | 对齐会 + 共建语言 + 更新文档 | 需要深度规划时 |
| **triage** | Issue 分类（状态机） | 管理 issue 工作流 |
| **improve-codebase-architecture** | 寻找架构改进机会 | 想要改善架构 |
| **setup-matt-pocock-skills** | 初始化配置（Issue Tracker、标签等） | 首次使用（必须先运行） |
| **tdd** | 测试驱动开发（红绿重构） | 提到 "TDD" / "red-green-refactor" |
| **to-issues** | 将 PRD 拆分为独立 issue | 需要任务拆分 |
| **to-prd** | 将对话转为 PRD 并发布到 Issue Tracker | 想要创建 PRD |
| **zoom-out** | 获取 broader context | 不熟悉某段代码 |
| **prototype** | 构建 throwaway 原型 | 需要验证设计 |

---

#### Productivity Skills（效率类，非代码）

| Skill | 用途 | 触发条件 |
|-------|------|----------|
| **caveman** | 超压缩通信模式（节省 ~75% tokens） | "caveman mode" / "be brief" |
| **grill-me** | 对齐会（无文档） | 需要深度规划 |
| **write-a-skill** | 创建新 skill | 需要自定义 skill |

---

#### Misc Skills（杂项，不常用）

| Skill | 用途 |
|-------|------|
| **git-guardrails-claude-code** | 阻止危险 git 命令 |
| **migrate-to-shoehorn** | 迁移测试到 @total-typescript/shoehorn |
| **scaffold-exercises** | 创建练习目录结构 |
| **setup-pre-commit** | 设置 Husky pre-commit hooks |

---

## 三、领域语言（CONTEXT.md）

### 3.1 为什么需要领域语言？

> "With a ubiquitous language, conversations among developers and expressions of the code are all derived from the same domain model."  
> — Eric Evans, *Domain-Driven Design*

**问题**：在项目开始时，开发者（和领域专家）通常说着不同的语言。AI agents 也被 dropped into 项目并被要求边走边理解行话。所以它们用 20 个词来描述 1 个词就能说清的事。

**解决方案**：一个共享语言。这是一个帮助 agents 解码项目中使用的行话的文档。

**示例**（来自 Matt 的 `course-video-manager` 仓库）：
- **BEFORE**："There's a problem when a lesson inside a section of a course is made 'real' (i.e. given a spot in the file system)"
- **AFTER**："There's a problem with the materialization cascade"

这种简洁性在会话 after 会话中都有回报。

---

### 3.2 CONTEXT.md 的格式

#### 单上下文仓库（大多数仓库）

```
/
├── CONTEXT.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

#### 多上下文仓库（monorepo）

如果仓库有多个上下文（如 monorepo），使用 `CONTEXT-MAP.md`：

```
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          ← 系统级决策
├── src/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/                 ← 上下文特定决策
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

`CONTEXT-MAP.md` 指向每个上下文的 `CONTEXT.md` 所在位置。

---

### 3.3 懒惰文件创建

- 仅在您有内容要写入时才创建文件
- 如果不存在 `CONTEXT.md`，在第一个术语 resolved 时创建一个
- 如果不存在 `docs/adr/`，在第一个 ADR 需要时创建它

---

## 四、架构决策记录（ADRs）

### 4.1 何时创建 ADR？

仅当**同时满足 3 个条件**时才提供 ADR：

1. **Hard to reverse**（难以逆转）
2. **Surprising without context**（没有上下文会令人惊讶）
3. **The result of a real trade-off**（真实权衡的结果）

如果任何三个缺失，跳过 ADR。

---

### 4.2 ADR 格式

```markdown
# ADR-XXXX: [Title]

## Status

[Proposed / Accepted / Deprecated / Superseded]

## Context

[What is the issue that we're seeing?]

## Decision

[What have we decided to do?]

## Consequences

[What becomes easier or more difficult because of this decision?]
```

---

**文档结构**：
- 一、仓库概述 + 仓库结构（**本文**）
- [二、核心 Skills 深度分析（1-6-2）](./1-6-2-matt-pocock-skills-deep-dive.md)
- [三、与 CodeStudio 的对比 + 核心洞察（1-6-3）](./1-6-3-matt-pocock-skills-vs-codestudio.md)
- [四、行动建议（1-6-4）](./1-6-4-matt-pocock-skills-action-plan.md)
