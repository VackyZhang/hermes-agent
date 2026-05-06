# mugc_tools Rules 系统详解
> **文档定位**：深入 mugc_server_ai_tools 的 Rules 系统（.mdc 文件、强制规则机制）。

---

## 一、Rules 系统概述
mugc_server_ai_tools 包含 **Rules 系统**，存放在 `rules/` 目录，文件格式为 `.mdc`（Markdown with YAML front matter）。

**核心设计理念**：

- **强制规则机制**：`alwaysApply: true` 的规则在每次 AI 会话中**始终生效**
- **YAML front matter**：每个 .mdc 文件包含 YAML front matter 和 Markdown 格式的规则内容
- **集中管理**：所有 Rules 通过 symlink 部署到目标项目，便于版本同步

---

## 二、Rules 格式（.mdc 文件）
**Rules 文件结构**：

```markdown
---
alwaysApply: true
---

# Rule Title
Rule content...

## Subsection
More rule content...
```text

**YAML Front Matter 字段**：

| 字段 | 类型 | 说明 |
| ------ | ------ | ------ |
| `alwaysApply` | boolean | 是否始终生效（true = 强制规则） |
| `paths` | string[] | （可选）规则适用的路径模式 |
| `description` | string | （可选）规则描述 |

---

## 三、Rules 示例
### 3.1 `code-review.mdc`
```markdown
---
alwaysApply: true
---

# Code Review Requirement
After writing code, you must call `skills:code-reviewer` for code review.

## Steps
1. Write code

2. Call `skills:code-reviewer`

3. Fix issues found by code reviewer
```text

### 3.2 `skill-context-first.mdc`
```markdown
---
alwaysApply: true
---

# Skill Context First
Before developing a feature, you must first read the corresponding skill document.

## Steps
1. Identify which skill is relevant to the feature

2. Read the skill document (SKILL.md)

3. Follow the workflow defined in the skill
```text

---

## 四、Rules 部署
**部署方式**：通过 `install/` 脚本，将 `rules/` 链接到对应工具的配置目录。

**部署路径**：

| 工具 | Rules 配置目录 |
| ------ | --------------------- |
| CodeBuddy | `.codebuddy/rules/` |
| Claude Code | `.claude/rules/` |
| Gemini | `.gemini/rules/` |
| Codex | `.codex/rules/` |
| Cursor | `.cursor/rules/` |

---

## 五、与 CCGS Rules 的对比
| 维度 | CCGS Rules（11 条） | mugc_tools Rules（3 个 .mdc 文件） |
| ------ | --------------------- | ------------------------------ |
| **格式** | Markdown（YAML front matter + 规则内容） | Markdown（YAML front matter + 规则内容） |
| **强制机制** | ❌ 无（依赖模型遵守） | ✅ `alwaysApply: true`（强制规则） |
| **路径级规则** | ✅ 有（`paths:` 字段） | ✅ 有（`paths:` 字段） |

---

**文档状态**：✅ 第一版完成（从 `1-5-1-mugc-tools-analysis.md` 拆分）

**下一步**：

- [ ] 补充所有 Rules 文件的详细内容（从 `rules/` 目录提取）
- [ ] 补充路径级规则的详细设计（如何匹配路径模式）
