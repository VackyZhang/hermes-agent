# mugc_tools OpenSpec 详解
> **文档定位**：深入 mugc_server_ai_tools 的 OpenSpec 元数据（变更管理流程）。

---

## 一、OpenSpec 概述
mugc_server_ai_tools 包含 **OpenSpec 元数据**，存放在 `openspec/` 目录。

**核心设计理念**：

- **变更管理流程**：提供从需求探索 → 提案 → 设计 → 实现 → 验证 → 归档的完整变更管理流程
- **元数据存放**：`openspec/meta/` 链接到 `<目标项目>/openspec/meta/` 下
- **模板**：`openspec/templates/` 包含提案（`proposal.md`）、设计（`design.md`）、规格说明（`spec.md`）、条件（`condition.md`）模板

---

## 二、OpenSpec 工作流
### 2.1 工作流概览
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

### 2.2 `openspec-new-change` 详解
**工作流程**：

```text
User: /opsx/openspec-new-change "add login feature"
    ↓
[1] 探索需求（ask clarifying questions）
    ↓
[2] 创建变更提案（proposal.md）
    ↓
[3] 等待用户确认
    ↓
[4] 创建设计文档（design.md）
    ↓
[5] 创建规格说明（spec.md）
    ↓
[6] 返回变更 ID
```text

### 2.3 `openspec-apply-change` 详解
**工作流程**：

```text
User: /opsx/openspec-apply-change <change-id>
    ↓
[1] 读取设计文档（design.md）和规格说明（spec.md）
    ↓
[2] 应用变更到代码
    ↓
[3] 运行测试
    ↓
[4] 返回应用结果
```text

---

## 三、OpenSpec 模板
### 3.1 提案模板（`openspec/templates/proposal.md`）
```markdown
# Proposal: <title>
## Summary
<summary>

## Motivation
<motivation>

## Solution
<solution>

## Alternatives Considered
<alternatives>

## Verification
<verification>
```text

### 3.2 设计模板（`openspec/templates/design.md`）
```markdown
# Design: <title>
## Context
<context>

## Decisions
<decisions>

## Consequences
<consequences>
```text

### 3.3 规格说明模板（`openspec/templates/spec.md`）
```markdown
# Spec: <title>
## Requirements
<requirements>

## Interfaces
<interfaces>

## Tests
<tests>
```text

---

## 四、OpenSpec 元数据存放
**元数据存放路径**：

```text
<目标项目>/openspec/meta/
├── changes/           ← 变更提案（proposal.md, design.md, spec.md）
└── archive/          ← 已归档的变更
```text

**链接方式**：`openspec/meta/` 链接到 `<目标项目>/openspec/meta/` 下。

---

## 五、与 CodeStudio 的对比
| 维度 | CodeStudio（设计上） | mugc_tools（已实现） |
| ------ | --------------------- | ----------------------- |
| **变更管理** | GD-2 组织资产（Constraint + Checklist） | OpenSpec 工作流（变更提案、设计、验证、归档） |
| **形式化** | ✅ 计划中实现 | ✅ 已实现（但非形式化） |
| **与项目集成** | ⏳ 待实现 | ✅ 已实现（通过 symlink） |

---

**文档状态**：✅ 第一版完成（从 `1-5-1-mugc-tools-analysis.md` 拆分）

**下一步**：

- [ ] 补充 OpenSpec 工作流的完整示例（从需求探索到归档）
- [ ] 补充 OpenSpec 元数据的详细格式（from `openspec/templates/` 提取）
