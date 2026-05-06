# Hermes Agent Skill 系统详解

> **文档定位**：深入 Hermes Agent 的 Skill 系统（skills/ 目录）。

---

## 一、Skill 系统概述

Hermes Agent 的 Skill 系统在 `skills/` 目录中实现。

**核心设计理念**：

- **Skill 目录结构**：每个 Skill 是一个目录，包含 `SKILL.md` 和可选的 `references/` 目录
- **Skill 调用方式**：slash 命令（/skill-name）、LLM 自动选择、Hook 触发
- **Skill 注册**：自动发现（skills/ 目录下的所有 Skill 自动注册）
- **Skill 执行**：读取 `SKILL.md`，按工作流执行

---

## 二、Skill 目录结构

```text
skills/<skill-name>/
├── SKILL.md          # Skill 定义：触发条件、工作流、输出格式
└── references/       # 参考文档：领域知识、规范、示例
```text

**SKILL.md 格式**：

```markdown
---
name: skill-name
description: Skill description
whenToUse: When to use this skill
argumentHint: [arg1] [arg2]
allowedTools: ["Read", "Write", "Edit"]
---

# Skill Name

## Workflow

1. Step 1

2. Step 2

3. ...

## Output Format

...
```text

---

## 三、Skill 调用方式

### 3.1 slash 命令

**触发方式**：用户通过 `/skill-name` 手动触发

**示例**：

```text
User: /debug "login failed"
```text

### 3.2 LLM 自动选择

**触发方式**：当 Skill 的 `whenToUse` 匹配时，LLM 自动调用 Skill

**示例**：

```text
User: Can you review my code?
→ Claude Code 自动调用 /code-review Skill
```text

### 3.3 Hook 触发

**触发方式**：通过 Hook 系统触发 Skill

**示例**：

```text
PostToolUse Hook 调用 type: "agent" 触发子 Agent 验证
→ 子 Agent 执行 /verify Skill
```text

---

## 四、Skill 注册与发现

**自动发现流程**：

```text
Hermes Agent 启动
    ↓
扫描 skills/ 目录
    ↓
读取每个 Skill 目录下的 SKILL.md
    ↓
解析 YAML front matter
    ↓
注册 Skill 到 SkillRegistry
```text

**SkillRegistry 结构**：

```python

# skills/registry.py

class SkillRegistry:
    def __init__(self):
        self._skills = {}  # name → {description, whenToUse, argumentHint, ...}
    
    def register(self, name: str, description: str, whenToUse: str, ...):
        """Register a skill."""
        self._skills[name] = {
            "description": description,
            "whenToUse": whenToUse,
            ...
        }
    
    def get_skill(self, name: str) -> dict:
        """Get skill by name."""
        return self._skills.get(name)
    
    def get_all_skills(self) -> list[dict]:
        """Get all registered skills."""
        return list(self._skills.values())
```text

---

## 五、内置 Skill 列表

Hermes Agent 的内置 Skill 在 `skills/` 目录中。

**部分内置 Skill 列表**：

| Skill 名称 | 说明 | 触发命令 |
| ----------- | ------ | ---------- |
| `brainstorm` | 脑暴工具 | `/brainstorm` |
| `code-review` | 代码审查 | `/code-review` |
| `debug` | 调试代码 | `/debug` |
| `implement` | 实现功能 | `/implement` |
| `test` | 编写测试 | `/test` |

---

## 六、与 CCGS/Claude Code 的对比

### 6.1 与 CCGS 的对比

| 维度 | CCGS | Hermes Agent |
| ------ | ------- | ------------ |
| **Skill 定义** | Markdown 文件（.claude/skills/*.md） | Markdown 文件（skills/<name>/SKILL.md） |
| **Skill 目录** | 单文件 | 目录（SKILL.md + references/） |
| **Skill 发现** | 手动配置（.claude/settings.json） | 自动发现（skills/ 目录） |
| **Skill 执行** | Claude Code 内置执行器 | Python 函数调用 |

### 6.2 与 Claude Code 的对比

| 维度 | Claude Code | Hermes Agent |
| ------ | ------------- | ------------ |
| **Skill 定义** | Markdown 文件（skills/<name>/SKILL.md） | Markdown 文件（skills/<name>/SKILL.md） |
| **Skill 来源** | bundled / user-defined / plugin | 内置（skills/ 目录） |
| **Skill 注册** | registerBundledSkill() / registerPluginSkill() | 自动发现（skills/ 目录） |
| **Skill 执行** | TypeScript 函数调用 | Python 函数调用 |

---

**文档状态**：✅ 第一版完成（从 `1-3-1-hermes-analysis.md` 拆分）

**下一步**：

- [ ] 补充更多内置 Skill 的详细说明（从 `skills/` 目录提取）
- [ ] 补充 Skill 执行的详细流程（如何解析 SKILL.md，如何执行工作流）
