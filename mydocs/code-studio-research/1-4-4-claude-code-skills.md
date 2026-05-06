# Claude Code Skill 系统分析

> **文档定位**：详细分析 Claude Code 的 Skill 系统，包括 Skill 类型、加载机制、触发方式、配置格式。

---

## 一、Claude Code Skill 系统概述

### 1.1 重要澄清

> **⚠️ 注意**：Claude Code 的 `skills/` 目录是 **Skill 系统**（用于封装常用工作流），**不是** React 组件！

**Skill 系统位置**：

| 组件 | 文件路径 |
| ------ | ---------- |
| bundled Skills | `skills/bundled/`（14 个内置 Skill） |
| Skill 加载逻辑 | `skills/loadSkillsDir.ts` |
| bundled Skill 定义 | `skills/bundledSkills.ts` |
| MCP Skill 构建器 | `skills/mcpSkillBuilders.ts` |

---

## 二、Skill 类型（3 种）

Claude Code 支持 **3 种 Skill 类型**，通过 `loadedFrom` 字段区分：

### 2.1 bundled（内置 Skill）

**说明**：随 CLI 二进制文件一起发布，所有用户都可用。

**注册方式**：在 `skills/bundledSkills.ts` 中调用 `registerBundledSkill()` 注册。

**内置 Skill 列表**（14 个）：

| Skill 名称 | 说明 | 触发命令 |
| ----------- | ------ | ---------- |
| `batch` | 批量处理文件 | `/batch` |
| `claudeApi` | 调用 Claude API | `/claude-api` |
| `claudeInChrome` | 在 Chrome 中调试 | `/claude-in-chrome` |
| `debug` | 调试代码 | `/debug` |
| `keybindings` | 查看快捷键绑定 | `/keybindings` |
| `loop` | 循环执行命令 | `/loop` |
| `loremIpsum` | 生成测试文本 | `/lorem-ipsum` |
| `remember` | 记住信息 | `/remember` |
| `scheduleRemoteAgents` | 调度远程 Agent | `/schedule-remote-agents` |
| `simplify` | 简化代码 | `/simplify` |
| `skillify` | 将工作流转换为 Skill | `/skillify` |
| `stuck` | 当 Agent 卡住时使用 | `/stuck` |
| `updateConfig` | 更新配置 | `/update-config` |
| `verify` | 验证代码 | `/verify` |

**示例**：`debug` Skill 定义（`skills/bundled/debug.ts`）

```typescript
// skills/bundled/debug.ts
export function registerDebugSkill() {
  registerBundledSkill({
    name: "debug",
    description: "Debug code by analyzing errors and suggesting fixes",
    whenToUse: "When the user encounters an error or unexpected behavior",
    argumentHint: "Error description or file to debug",
    allowedTools: ["Read", "Write", "Bash", "Grep"],
    userInvocable: true,
    isEnabled: () => true,
    getPromptForCommand: async (args, context) => {
      return [
        {
          type: "text",
          text: `Debug the following: ${args}\n\nFollow these steps:\n1. Reproduce the issue\n2. Identify the root cause\n3. Implement a fix\n4. Verify the fix works`
        }
      ];
    }
  });
}
```text

---

### 2.2 user-defined（用户定义 Skill）

**说明**：用户自定义的 Skill，存放在 `.claude/commands/` 目录。

**文件格式**：Markdown 文件，支持 frontmatter（元数据）。

**示例**：`.claude/commands/review.md`

```markdown
---
description: "Review code changes"
allowed-tools: ["Read", "Bash"]
when-to-use: "When the user asks for a code review"
---

Review the following changes:
$ARGUMENTS

Steps:

1. Read the diff

2. Check for common issues

3. Suggest improvements
```text

**触发方式**：通过 slash 命令调用（如 `/review`）。

---

### 2.3 plugin（插件 Skill）

**说明**：由插件提供的 Skill，存放在插件目录。

**注册方式**：插件在初始化时调用 `registerPluginSkill()` 注册。

**示例**：插件提供的 Skill

```typescript
// plugin/MyPlugin.ts
export function registerPluginSkills() {
  registerPluginSkill({
    name: "my-plugin-skill",
    description: "My plugin skill",
    getPromptForCommand: async (args, context) => {
      return [
        {
          type: "text",
          text: "My plugin skill prompt"
        }
      ];
    }
  });
}
```text

---

## 三、Skill 加载机制

### 3.1 加载流程

```text
CLI 启动
    ↓
加载 bundled Skills（skills/bundledSkills.ts）
    ↓
扫描 .claude/commands/（用户定义 Skill）
    ↓
扫描插件目录（插件 Skill）
    ↓
合并所有 Skill，去重（同名时，用户定义 > 插件 > bundled）
    ↓
注册到 Command Registry
    ↓
用户通过 slash 命令调用
```text

### 3.2 加载优先级

| 优先级 | Skill 类型 | 说明 |
| -------- | ----------- | ------ |
| **最高** | user-defined | 用户定义的 Skill 优先级最高 |
| **中等** | plugin | 插件提供的 Skill 次之 |
| **最低** | bundled | 内置 Skill 优先级最低 |

**去重规则**：同名时，高优先级的 Skill 覆盖低优先级的 Skill。

---

## 四、Skill Frontmatter（元数据）

Skill 支持以下 frontmatter 字段（YAML 或 TypeScript 对象）：

| 字段 | 类型 | 说明 |
| ------ | ------ | ------ |
| `name` | string | Skill 名称（必须唯一） |
| `description` | string | Skill 描述（用于 LLM 选择） |
| `whenToUse` | string | 何时使用此 Skill（用于 LLM 自动选择） |
| `argumentHint` | string | 参数提示（显示给用户） |
| `allowedTools` | string[] | 此 Skill 允许使用的工具（白名单） |
| `disableModelInvocation` | boolean | 是否禁用 LLM 调用（纯脚本 Skill） |
| `userInvocable` | boolean | 是否允许用户通过 slash 命令调用（默认 true） |
| `hooks` | HookMatcher[] | 此 Skill 关联的 Hook（Skill 级 Hook） |
| `context` | 'inline' | 'fork' | Skill 执行上下文（inline=当前会话，fork=子 Agent） |
| `agent` | string | 指定子 Agent 名称（当 context='fork' 时） |
| `isEnabled` | () => boolean | 是否启用此 Skill（运行时判断） |
| `isHidden` | boolean | 是否隐藏此 Skill（不显示在帮助中） |

---

## 五、Skill 触发方式（3 种）

Claude Code 的 Skill 支持 **3 种触发方式**：

### 5.1 slash 命令（用户手动触发）

**说明**：用户通过 `/skill-name` 手动触发。

**示例**：

```text
User: /debug "login failed"
Claude: I'll help you debug the login failure. Let me start by...
```text

---

### 5.2 LLM 自动选择（自动触发）

**说明**：当 `userInvocable: true` 且 LLM 认为合适时，自动调用 Skill。

**前提条件**：

1. Skill 的 `description` 和 `whenToUse` 字段必须清晰

2. LLM 根据用户输入和 Skill 描述自动匹配

**示例**：

```text
User: Can you review my code?
Claude: (automatically calls /review skill)
```text

---

### 5.3 Hook 触发（事件触发）

**说明**：通过 Hook 系统触发 Skill（例如，`PostToolUse` Hook 触发 `verify` Skill）。

**配置示例**（`.claude/settings.json`）：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify the written code: $ARGUMENTS",
            "model": "claude-sonnet-4-6"
          }
        ]
      }
    ]
  }
}
```text

---

## 六、Skill 与 Hook 的关系

### 6.1 Skill 可以关联 Hook

Skill 可以通过 `hooks` 字段关联 Hook（Skill 级 Hook）：

```typescript
registerBundledSkill({
  name: "verify",
  description: "Verify code changes",
  hooks: {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify the written code"
          }
        ]
      }
    ]
  },
  getPromptForCommand: async (args, context) => {
    // ...
  }
});
```text

### 6.2 Hook 可以触发 Skill

Hook 可以通过 `type: "agent"` 触发 Skill（实际上是启动子 Agent 执行验证）：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "agent",
            "prompt": "Run /verify skill: $ARGUMENTS"
          }
        ]
      }
    ]
  }
}
```text

---

## 七、与 CodeStudio 的对比

### 7.1 Skill 系统对比

| 维度 | Claude Code | CodeStudio | CodeStudio 的优势 |
| ------ | ------------- | ------------ | ------------------- |
| **Skill 类型** | 3 种（bundled / user-defined / plugin） | 1 种（catalog/skills/） | CodeStudio 的 Skill 系统更统一（不区分来源） |
| **Skill 格式** | Markddown + frontmatter | Markdown + frontmatter（YAML） | 两者类似 |
| **Skill 触发** | slash 命令 / LLM 自动选择 / Hook 触发 | MCP 工具调用（`record_evidence`） | CodeStudio 的触发更显式（通过 MCP） |
| **Skill 级 Hook** | ✅ 支持（`hooks` 字段） | ❌ 不支持（Skill 不包含 Hook） | Claude Code 更灵活 |
| **Skill 优先级** | ✅ 支持（user > plugin > bundled） | ❌ 不支持（所有 Skill 平等） | Claude Code 更灵活 |

### 7.2 对 CodeStudio 的启发

| Claude Code 特性 | 对 CodeStudio 的启发 |
| ---------------- | --------------------- |
| **Skill 级 Hook** | CodeStudio 可以考虑支持 Skill 级 Hook（在 Skill 执行前后触发） |
| **Skill 优先级** | CodeStudio 可以考虑支持 Skill 优先级（项目级 > 用户级 > 内置） |
| **LLM 自动选择** | CodeStudio 可以考虑支持 LLM 自动选择 Skill（根据 `whenToUse` 字段） |

---

## 八、总结

### 8.1 Claude Code Skill 系统亮点

| 亮点 | 说明 |
| ------ | ------ |
| **① 3 种 Skill 类型** | bundled / user-defined / plugin，覆盖不同场景 |
| **② Frontmatter 元数据** | 支持丰富的元数据（description / whenToUse / allowedTools / hooks 等） |
| **③ 多种触发方式** | slash 命令 / LLM 自动选择 / Hook 触发 |
| **④ Skill 级 Hook** | Skill 可以关联 Hook，实现更复杂的工作流 |
| **⑤ 优先级机制** | user-defined > plugin > bundled，用户可以覆盖内置 Skill |

### 8.2 Claude Code Skill 系统不足（相对 CodeStudio）

| 不足 | 说明 |
| ------ | ------ |
| **① 无形式化治理** | Skill 之间没有依赖关系，无法保证执行顺序 |
| **② 无证据链闭环** | Skill 执行记录不会自动沉淀为知识 |
| **③ 无 GD-2 组织资产** | Skill 之间是平级关系，没有约束 + 流程（constraint + checklist） |

---

**文档状态**：✅ 第一版完成（基于 `skills/bundledSkills.ts` + `skills/loadSkillsDir.ts` + `skills/bundled/debug.ts`）

**下一步**：

- [ ] 阅读更多 bundled Skill 示例（如 `verify.ts`、`simplify.ts`）
- [ ] 分析 Skill 与 Hook 的交互细节
- [ ] 与 CodeStudio catalog/skills/ 做更详细的对比
