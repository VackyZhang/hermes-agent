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

---

### 1.2 解决的问题

Matt Pocock 构建这些 skills 是为了修复 Claude Code、Codex 等 Coding Agent 的常见失败模式：

| 问题 | 表现 | 解决方案 |
|------|------|----------|
| **#1: Agent 没做我想要的事** | 沟通鸿沟，理解偏差 | `grill-me` / `grill-with-docs`（对齐会） |
| **#2: Agent 太啰嗦** | 不使用领域语言，20 个词描述 1 个词的事 | `grill-with-docs`（共建语言）<br>`caveman`（压缩通信） |
| **#3: 代码不 work** | 缺乏反馈循环，盲目编码 | `tdd`（红绿重构）<br>`diagnose`（调试循环） |
| **#4: 代码变成大泥球** | 加速编码 = 加速软件熵增 | `improve-codebase-architecture`<br>`to-prd`（模块规划）<br>`zoom-out`（系统视角） |

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
├── scripts/                 # 脚本
├── README.md                # 总览 + Skill 索引
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
- `description`：触发条件（when to use）
- `disable-model-invocation`（可选）：设为 `true` 时，不自动触发

---

### 2.3 Skills 分类

#### Engineering Skills（工程类，日常使用）

| Skill | 用途 | 触发条件 |
|-------|------|----------|
| **diagnose** | disciplined 调试循环 | "diagnose this" / "debug this" / 报告 bug |
| **grill-with-docs** | 对齐会 + 共建语言 + 更新文档 | 需要深度规划时 |
| **tdd** | 测试驱动开发（红绿重构） | 提到 "TDD" / "red-green-refactor" |
| **to-prd** | 将对话转为 PRD 并发布到 Issue Tracker | 想要创建 PRD |
| **to-issues** | 将 PRD 拆分为独立 issue | 需要任务拆分 |
| **triage** | Issue 分类（状态机） | 管理 issue 工作流 |
| **improve-codebase-architecture** | 寻找架构改进机会 | 想要改善架构 |
| **zoom-out** | 获取 broader context | 不熟悉某段代码 |
| **prototype** | 构建 throwaway 原型 | 需要验证设计 |
| **setup-matt-pocock-skills** | 初始化配置（Issue Tracker、标签等） | 首次使用（必须先运行） |

---

#### Productivity Skills（效率类，非代码）

| Skill | 用途 | 触发条件 |
|-------|------|----------|
| **grill-me** | 对齐会（无文档） | 需要深度规划 |
| **caveman** | 超压缩通信模式（节省 ~75% tokens） | "caveman mode" / "be brief" |
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

**文档结构**：
- 一、仓库概述（**本文**）
- [二、核心 Skills 深度分析（1-6-2）](./1-6-2-matt-pocock-skills-deep-dive.md)
- [三、与 CodeStudio 的对比 + 核心洞察（1-6-3）](./1-6-3-matt-pocock-skills-vs-codestudio.md)
- [四、行动建议（1-6-4）](./1-6-4-matt-pocock-skills-action-plan.md)
