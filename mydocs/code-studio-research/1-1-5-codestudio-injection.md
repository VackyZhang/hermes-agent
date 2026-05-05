# CodeStudio 四层注入机制详解

> **⚠️ 重要说明**：本文档描述 CodeStudio 的**设计方案**，当前系统**尚未实现**。
>
> **文档定位**：深入 CodeStudio 的四层注入机制（AgentINJ-L1~L4）。

---

## 一、四层注入机制概述

> **替代"三轨制"**：CodeStudio 采用四层注入机制，而非"三轨制"。

| 层 | 名称 | 载体 | 时机 |
| ------ | ------ | ------ | ------ |
| **AgentINJ-L1** | 上下文规则注入 | CLAUDE.md / AGENTS.md（规则文件） | Session 启动时自动加载 |
| **AgentINJ-L2** | Hook 注入 | session_start.sh / pre_tool_use.sh / … | 工具调用前后触发 |
| **AgentINJ-L3** | MCP 工具注入 | `codestudio-harness` CodeStudioServer | 按需调用 |
| **AgentINJ-L4** | 权限注入 | settings.json / config.toml permissions | 工具权限白名单 |

---

## 二、L1 最小安全网原则

**问题**：若 L1 规则文件仅包含 MCP 入口说明（"请调用 session_start"），一旦 CodeStudioServer 启动失败（常见于环境问题），Agent 将在零约束状态下运行。

**原则**：L1 规则文件必须自给自足——即使 MCP 不可用，Agent 仍能：

1. 识别意图（内置分类 schema）

2. 遵守核心约束（C1 禁止硬编码敏感信息、C2 禁止写生产环境、C3 Lifecycle 完整性）

3. 执行基本 Session 协议（4 阶段 lifecycle）

**L1 规则文件示例**：

```markdown

# CLAUDE.md

## Session 协议

你必须遵循以下 4 阶段 lifecycle：

1. **session_start**：调用 `session_start` MCP 工具（如果可用），创建 session

2. **intent_identify**：识别用户意图（dev/debug/review/free）

3. **execute**：执行任务

4. **session_close**：调用 `session_close` MCP 工具（如果可用），关闭 session

如果 MCP 不可用，你仍必须：

- 识别意图（内置分类 schema）
- 遵守核心约束（见下方"核心约束"）
- 执行基本 Session 协议（记录你的工作，以便下次会话继续）

## 核心约束

- C1：禁止硬编码敏感信息（密码、API key、...）
- C2：禁止写生产环境（除非用户明确授权）
- C3：Lifecycle 完整性（必须调用 session_close）

## MCP 工具（如果可用）

如果 CodeStudioServer 可用，你必须调用以下 MCP 工具：

- `session_start`：创建 session
- `report_intent`：报告意图
- `record_evidence`：记录证据
- `session_close`：关闭 session

```text

**L3 补充**：CodeStudioServer 提供的是 catalog 的**完整按需查询能力**——详细约束正文、当前项目知识、动态技能列表。L3 是 L1 的增强，不是替代。

---

## 三、L2 Hook 注入

**Hook 类型**（4 种）：

| Hook 类型 | 说明 | 触发时机 |
| ----------- | ------ | ---------- |
| **command** | 执行 shell 命令 | 工具调用前后 |
| **prompt** | LLM 评估 | 需要 LLM 决策时 |
| **http** | HTTP 请求 | 需要远程调用时 |
| **agent** | 子 Agent 验证 | 需要复杂验证时 |

**Hook 配置位置**：

| 层级 | 文件路径 | 说明 |
| ------ | ---------- | ------ |
| 用户级 | `~/.claude/settings.json` | 全局配置，对所有项目生效 |
| 项目级 | `.claude/settings.json` | 项目配置，只对当前项目生效 |
| 本地级 | `.claude/settings.local.json` | 本地配置，不提交到 Git |

**Hook 示例**：

```json
// .claude/settings.json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": "~/.claude/hooks/validate-db-change.sh",
        "matcher": "Write"
      }
    ]
  }
}
```text

---

## 四、L3 MCP 工具注入

**MCP 工具列表**（8 个）：

| 工具 | 阶段/层 | 职责 |
| ------ | --------- | ------ |
| `claim_session` | Claim 阶段 | 原子 pop pending session，获取 harness_sid（iter-001 新增） |
| `session_start` | Stage 1 | 创建会话，初始化上下文 |
| `report_intent` | Stage 2 | 意图识别与 flow 选择 |
| `record_evidence` | CAP-3 | 记录行为证据 |
| `query_constraint` | CAP-2 | 查询适用约束规则 |
| `query_knowledge` | CAP-1 | 查询知识库 |
| `session_close` | Stage 4 | 关闭会话，升格知识 |
| `record_ai_reasoning` | CAP-3 | 记录 AI 推理步骤，形成推理证据链（Trace v2 新增） |

**MCP 工具调用示例**：

```xml
<!-- AI 调用 MCP 工具 -->
<invoke name="session_start">
  <parameter name="project_id">letsgo_server</parameter>
  <parameter name="knowledge">["db-migration", "player-disconnect"]</parameter>
</invoke>
```text

---

## 五、L4 权限注入

**权限配置示例**：

```json
// .claude/settings.json
{
  "permissions": {
    "allow": [
      "Read",
      "Write",
      "Edit",
      "Glob",
      "Grep"
    ],
    "deny": [
      "Bash(git push origin main)",
      "Bash(rm -rf /)"
    ]
  }
}
```text

**权限注入时机**：Session 启动时，从 settings.json / config.toml 读取权限配置，注入到 Agent 上下文。

---

**文档状态**：✅ 第一版完成（从 `1-1-code-studio-analysis.md` 拆分）

**下一步**：

- [ ] 补充更多 Hook 示例（从 `codestudio-spec/` 提取）
- [ ] 补充权限注入的边界情况（如何处理 denied 权限）
