# mugc_tools Agent 系统详解 #

> **文档定位**：深入 mugc_server_ai_tools 的 Agent 系统（11 个）。

---

## 一、Agent 系统概述 ##

mugc_server_ai_tools 包含 **11 个 Agent** 定义，存放在 `agents/` 目录。

**核心设计理念**：

- **YAML front matter + Markdown**：每个 Agent 是一个 .md 文件，包含 YAML front matter 和 Markdown 格式的 prompt
- **精简**：11 个 Agent（相对 CCGS 的 49 个）
- **领域专注**：服务器端开发 + Java 生态

---

## 二、Agent 定义格式 ##

```markdown
---
name: architect
description: Software architecture specialist for system design...
tools: ["Read", "Grep", "Glob"]
model: opus
---

You are a senior software architect...
```text

**YAML Front Matter 字段**：

| 字段 | 类型 | 说明 |
| ------ | ------ | ------ |
| `name` | string | Agent 名称（必须唯一） |
| `description` | string | Agent 描述（用于 LLM 选择） |
| `tools` | string[] | 此 Agent 允许使用的工具（白名单） |
| `model` | string | 使用的模型（opus/sonnet/haiku） |

---

## 三、Agent 列表（11 个） ##

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

---

## 四、Agent 部署 ##

**部署方式**：通过 `install/` 脚本，将 `agents/` 链接到对应工具的配置目录。

**部署路径**：

| 工具 | Agent 配置目录 |
| ------ | --------------------- |
| CodeBuddy | `.codebuddy/agents/` |
| Claude Code | `.claude/agents/` |
| Gemini | `.gemini/agents/` |
| Codex | `.codex/agents/` |
| Cursor | `.cursor/agents/` |

---

**文档状态**：✅ 第一版完成（从 `1-5-1-mugc-tools-analysis.md` 拆分）

**下一步**：

- [ ] 补充所有 11 个 Agent 的详细说明（YAML 配置、职责描述、协作协议）
- [ ] 补充 Agent 的协作协议（如何委托任务、如何审查输出）
