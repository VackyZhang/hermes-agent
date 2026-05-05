# mugc_tools Command 系统详解 #

> **文档定位**：深入 mugc_server_ai_tools 的 Command 系统（19 个）。

---

## 一、Command 系统概述 ##

mugc_server_ai_tools 包含 **19 个 Command** 定义，存放在 `commands/` 目录。

**核心设计理念**：

- **OpenSpec 工作流**：Command 实现 OpenSpec 变更管理流程
- **Markdown 文件**：每个 Command 是一个 .md 文件，包含工作流、使用示例、输出格式
- **调用方式**：`/<command-name>`

---

## 二、Command 定义格式 ##

**文件路径**：`commands/<command-name>.md`

**内容结构**：

```markdown
# Command Name #

> **Description**: Command description.

## Usage ##

```text
/command-name [args]
```text

## Workflow ##

1. Step 1

2. Step 2

3. ...

## Output Format ##

...
```text

---

## 三、Command 列表（19 个） ##

### 3.1 OpenSpec 工作流命令 ###

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

### 3.2 其他命令 ###

| 命令 | 说明 |
| ------ | ------ |
| ... | ... |

---

## 四、OpenSpec 工作流详解 ##

### 4.1 `openspec-new-change` ###

**工作流程**：

```text
User: /openspec-new-change "add login feature"
    ↓
[1] 探索需求（ask clarifying questions）
    ↓
[2] 创建变更提案（proposal.md）
    ↓
[3] 等待用户确认
    ↓
[4] 创建设计文档（design.md）
    ↓
[5] 创建设计文档（spec.md）
    ↓
[6] 返回变更 ID
```text

### 4.2 `openspec-continue-change` ###

**工作流程**：

```text
User: /openspec-continue-change <change-id>
    ↓
[1] 读取变更提案（proposal.md）
    ↓
[2] 继续未完成的工作
    ↓
[3] 返回当前状态
```text

### 4.3 `openspec-apply-change` ###

**工作流程**：

```text
User: /openspec-apply-change <change-id>
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

## 五、与 CCGS Skill 的对比 ##

| 维度 | CCGS Skill（72 个） | mugc_tools Command（19 个） |
| ------ | --------------------- | ---------------------------- |
| **数量** | 72 个 | 19 个 |
| **格式** | Markdown（YAML front matter + 工作流） | Markdown（工作流） |
| **调用方式** | `/skill-name`（slash 命令） | `/opsx/<command-name>` |
| **功能** | 游戏开发全流程 | OpenSpec 变更管理 + 代码生成 |

---

**文档状态**：✅ 第一版完成（从 `1-5-mugc-tools-analysis.md` 拆分）

**下一步**：

- [ ] 补充所有 19 个 Command 的详细说明（工作流、使用示例、输出格式）
- [ ] 补充 OpenSpec 工作流的完整示例（从需求探索到归档）
