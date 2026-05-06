# Claude Code CLI Hook 系统分析

> **文档定位**：详细分析 Claude Code 的 CLI Hook 系统（不是 React Hooks），包括 Hook 类型、触发时机、配置格式、执行机制。

---

## 一、Claude Code CLI Hook 系统概述

### 1.1 重要澄清

> **⚠️ 注意**：Claude Code 的 `hooks/` 目录是 **React Hooks**（用于 UI），**不是** CLI Hook 系统！

**CLI Hook 系统位置**：

| 组件 | 文件路径 |
| ------ | ---------- |
| Hook 类型定义 | `types/hooks.ts` |
| Hook Schema 定义 | `schemas/hooks.ts` |
| Hook 执行逻辑 | `utils/hooks.ts`（155.72 KB） |
| 工具 Hook 处理 | `services/tools/toolHooks.ts` |
| Hook 配置管理 | `utils/hooks/hooksConfigManager.ts` |
| Hook 事件定义 | `types/hooks.ts` 中的 `HookEvent` |

---

## 二、Hook 类型（4 种）

Claude Code 支持 **4 种 Hook 类型**，通过 `type` 字段区分：

### 2.1 command（Shell 命令 Hook）

**说明**：执行 shell 命令，通过 stdin/stdout 传递 JSON 数据。

**Schema**：

```typescript
// schemas/hooks.ts
const BashCommandHookSchema = z.object({
  type: z.literal('command').describe('Shell command hook type'),
  command: z.string().describe('Shell command to execute'),
  if: IfConditionSchema(),
  shell: z.enum(SHELL_TYPES).optional().describe(
    "Shell interpreter. 'bash' uses your $SHELL (bash/zsh/sh); 'powershell' uses pwsh. Defaults to bash."
  ),
  timeout: z.number().positive().optional().describe('Timeout in seconds for this specific command'),
  statusMessage: z.string().optional().describe('Custom status message to display in spinner while hook runs'),
  once: z.boolean().optional().describe('If true, hook runs once and is removed after execution'),
  async: z.boolean().optional().describe('If true, hook runs in background without blocking'),
  asyncRewake: z.boolean().optional().describe(
    'If true, hook runs in background and wakes the model on exit code 2 (blocking error). Implies async.'
  ),
})
```text

**示例配置**（`.claude/settings.json`）：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'echo \"Writing to $TOOL_INPUT\" >> /tmp/claude-hooks.log'",
            "timeout": 30,
            "statusMessage": "Checking write operation..."
          }
        ]
      }
    ]
  }
}
```text

---

### 2.2 prompt（LLM 评估 Hook）

**说明**：让 LLM 评估 Hook input，返回决策（allow/deny/ask）。

**Schema**：

```typescript
const PromptHookSchema = z.object({
  type: z.literal('prompt').describe('LLM prompt hook type'),
  prompt: z.string().describe(
    'Prompt to evaluate with LLM. Use $ARGUMENTS placeholder for hook input JSON.'
  ),
  if: IfConditionSchema(),
  timeout: z.number().positive().optional().describe('Timeout in seconds for this specific prompt evaluation'),
  model: z.string().optional().describe(
    'Model to use for this prompt hook (e.g., "claude-sonnet-4-6"). If not specified, uses the default small fast model.'
  ),
  statusMessage: z.string().optional().describe('Custom status message to display in spinner while hook runs'),
  once: z.boolean().optional().describe('If true, hook runs once and is removed after execution'),
})
```text

**示例配置**：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if the command is dangerous: $ARGUMENTS. If dangerous, return JSON: {\"decision\": \"deny\", \"reason\": \"...\"}. Otherwise return {\"decision\": \"allow\"}.",
            "model": "claude-haiku-4-6",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```text

---

### 2.3 http（HTTP Hook）

**说明**：向指定 URL 发送 HTTP POST 请求，携带 Hook input JSON。

**Schema**：

```typescript
const HttpHookSchema = z.object({
  type: z.literal('http').describe('HTTP hook type'),
  url: z.string().url().describe('URL to POST the hook input JSON to'),
  if: IfConditionSchema(),
  timeout: z.number().positive().optional().describe('Timeout in seconds for this specific request'),
  headers: z.record(z.string(), z.string()).optional().describe(
    'Additional headers to include in the request. Values may reference environment variables using $VAR_NAME or ${VAR_NAME} syntax (e.g., "Authorization": "Bearer $MY_TOKEN"). Only variables listed in allowedEnvVars will be interpolated.'
  ),
  allowedEnvVars: z.array(z.string()).optional().describe(
    'Explicit list of environment variable names that may be interpolated in header values. Only variables listed here will be resolved; all other $VAR references are left as empty strings. Required for env var interpolation to work.'
  ),
  statusMessage: z.string().optional().describe('Custom status message to display in spinner while hook runs'),
  once: z.boolean().optional().describe('If true, hook runs once and is removed after execution'),
})
```text

**示例配置**：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "http",
            "url": "https://example.com/hook",
            "headers": {
              "Authorization": "Bearer $MY_TOKEN"
            },
            "allowedEnvVars": ["MY_TOKEN"],
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```text

---

### 2.4 agent（子 Agent 验证 Hook）

**说明**：启动一个子 Agent 来执行验证任务。

**Schema**：

```typescript
const AgentHookSchema = z.object({
  type: z.literal('agent').describe('Agentic verifier hook type'),
  prompt: z.string().describe(
    'Prompt describing what to verify (e.g. "Verify that unit tests ran and passed."). Use $ARGUMENTS placeholder for hook input JSON.'
  ),
  if: IfConditionSchema(),
  timeout: z.number().positive().optional().describe('Timeout in seconds for agent execution (default 60)'),
  model: z.string().optional().describe(
    'Model to use for this agent hook (e.g., "claude-sonnet-4-6"). If not specified, uses Haiku.'
  ),
  statusMessage: z.string().optional().describe('Custom status message to display in spinner while hook runs'),
  once: z.boolean().optional().describe('If true, hook runs once and is removed after execution'),
})
```text

**示例配置**：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify that the written code passes lint: $ARGUMENTS",
            "model": "claude-sonnet-4-6",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```text

---

## 三、Hook 触发时机（13 种事件）

Claude Code 定义了 **13 种 Hook 事件**（统一命名）：

| 统一事件名 | 触发时机 | 典型用途 | 对应 CCGS 的什么？ |
| ------------ | ---------- | ---------- | --------------------- |
| `SessionStart` | Session 启动 / 恢复 / clear | 注入初始上下文 | CCGS 的 `SessionStart` Hook |
| `SessionEnd` | Session 结束 | 清理、日志持久化 | CCGS 的 `SessionEnd` Hook |
| `UserPromptSubmit` | 用户提交消息后、Agent 开始前 | 验证输入、注入上下文 | CCGS 没有（CCGS 依赖用户手动） |
| `PreToolUse` | 工具调用前 | **拦截 / 允许 / 询问** | CCGS 的 `PreToolUse` Hook |
| `PostToolUse` | 工具调用后 | 审计、格式化输出 | CCGS 的 `PostToolUse` Hook |
| `PermissionRequest` | 权限请求时 | 自定义审批逻辑 | CCGS 没有（CCGS 依赖用户手动） |
| `BeforeModel` | LLM 请求前 | 修改 prompt、注入上下文 | CCGS 没有 |
| `AfterModel` | LLM 响应后 | 处理输出、提取信息 | CCGS 没有 |
| `BeforeToolSelection` | 工具选择前 | 过滤/优先排序工具 | CCGS 没有 |
| `Stop` | Agent 主动停止时 | 收尾、知识沉淀 | CCGS 的 `Stop` Hook |
| `SubagentStop` | 子 Agent 完成时 | 扩展/标注子任务 | CCGS 没有 |
| `Notification` | 通知事件（错误/警告） | 日志、告警 | CCGS 没有 |
| `PreCompact` | 上下文压缩前 | 保留关键信息 | CCGS 没有 |

---

## 四、Hook 配置格式

### 4.1 配置文件位置

| 层级 | 文件路径 | 说明 |
| ------ | ---------- | ------ |
| 用户级 | `~/.claude/settings.json` | 全局配置，对所有项目生效 |
| 项目级 | `.claude/settings.json` | 项目配置，只对当前项目生效 |
| 本地级 | `.claude/settings.local.json` | 本地配置，不提交到 Git |

### 4.2 配置结构

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'echo \"Session started\" >> /tmp/claude.log'",
            "timeout": 10
          }
        ]
      }
    ],
    "PreToolUse": [
      {
|         "matcher": "Write | Edit", |
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/check_write.sh",
            "timeout": 30,
            "statusMessage": "Checking write operation..."
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if the command is dangerous: $ARGUMENTS. If dangerous, return JSON: {\"decision\": \"deny\", \"reason\": \"...\"}.",
            "model": "claude-haiku-4-6",
            "timeout": 30
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "http",
            "url": "https://example.com/hook",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/session_close.sh",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```text

### 4.3 matchers 语法

`matcher` 字段支持类似 permission rule 的语法，用于过滤 Hook 触发条件：

| 示例 | 说明 |
| ------ | ------ |
| `""` | 空字符串，匹配所有工具/事件 |
| `"Write"` | 只匹配 `Write` 工具 |
| `"Write | Edit"` | 匹配 `Write` 或 `Edit` 工具 |
| `"Bash(git *)"` | 只匹配 `Bash` 工具且参数以 `git ` 开头的命令 |

---

## 五、Hook 执行机制

### 5.1 执行流程

```text
Hook 事件触发（如 PreToolUse）
    ↓
查找匹配的 matchers（按配置文件中的顺序）
    ↓
对每个匹配的 matcher，执行其 hooks 数组
    ↓
根据 type 执行不同逻辑：

  - command：spawn shell 进程，传递 JSON 到 stdin，读取 stdout JSON
  - prompt：调用 LLM API，传递 prompt + $ARGUMENTS，解析 LLM 响应
  - http：发送 HTTP POST 请求到指定 URL，携带 JSON body
  - agent：启动子 Agent，传递 prompt + $ARGUMENTS，等待子 Agent 返回

    ↓
解析 Hook 输出（JSON）
    ↓
根据 decision 字段决定下一步：

  - allow：继续
  - deny：阻止操作，显示 reason
  - ask：询问用户

    ↓
继续执行或中止
```text

### 5.2 Hook 输出协议

所有 Hook 类型都支持以下核心字段（语义一致）：

| 字段 | 说明 | 适用事件 |
| ------ | ------ | ---------- |
| `decision` | `allow` / `deny` / `ask` | PreToolUse / PermissionRequest |
| `reason` | 拒绝/询问原因 | 同上 |
| `continue` | `false` 时终止 Agent 循环 | 任意 |
| `stopReason` | 终止原因 | 同上 |
| `additionalContext` | 注入上下文 | SessionStart / UserPromptSubmit |
| `systemMessage` | 显示给用户的消息 | 任意 |

### 5.3 超时与错误处理

| 场景 | 处理方式 |
| ------ | ---------- |
| **超时** | 默认 10 分钟（TOOL_HOOK_EXECUTION_TIMEOUT_MS = 10 * 60 * 1000），可通过 `timeout` 字段覆盖；SessionEnd Hook 默认 15 秒（SESSION_END_HOOK_TIMEOUT_MS_DEFAULT = 15000），可通过环境变量 `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` 覆盖 |
| **非 0 退出码** | command 类型 Hook 退出码为 2 时，表示 blocking error，终止操作；其他非 0 退出码表示错误，但允许操作继续 |
| **stdout 不是 JSON** | 视为 stdout 字符串，显示给用户 |
| **stderr 有输出** | 记录到日志，但不阻止操作（除非退出码为 2） |

---

## 六、与 CodeStudio 的对比

### 6.1 Hook 系统对比

| 维度 | Claude Code | CodeStudio | CodeStudio 的优势 |
| ------ | ------------- | ------------ | ------------------- |
| **Hook 类型** | 4 种（command / prompt / http / agent） | CAP-4 Interceptor（原生集成） | CodeStudio 的 Hook 是"治理导向"，更结构化 |
| **配置方式** | `.claude/settings.json`（JSON） | `catalog/constraints/` + `install/<cli>/hooks/` | CodeStudio 的配置更分散，但更灵活 |
| **触发时机** | 13 种事件 | 5 种事件（SessionStart / PreToolUse / PostToolUse / Stop / PermissionRequest） | Claude Code 的事件更多，但 CodeStudio 的事件更精简 |
| **执行机制** | spawn shell / call LLM / send HTTP / spawn agent | 执行 hooks 脚本 + MCP 调用 | CodeStudio 的执行机制更简单（只依赖脚本 + MCP） |
| **决策方式** | 读取 stdout JSON（`decision` / `reason`） | strength 字段（doc-only / call-time / runtime） | CodeStudio 的决策更明确（strength 字段） |

### 6.2 对 CodeStudio 的启发

| Claude Code 特性 | 对 CodeStudio 的启发 |
| ------ | --------------------- |
| **4 种 Hook 类型** | CodeStudio 可以考虑支持 prompt/agent 类型（当前只支持 command） |
| **matcher 语法** | CodeStudio 可以借鉴 matcher 语法，用于过滤 constraint 适用范围 |
| **超时配置** | CodeStudio 的 Hook 超时配置可以细化到每个 Hook |
| **async/asyncRewake** | CodeStudio 可以支持异步 Hook（不阻塞 Agent 循环） |

---

## 七、总结

### 7.1 Claude Code CLI Hook 系统亮点

| 亮点 | 说明 |
| ------ | ------ |
| **① 4 种 Hook 类型** | command / prompt / http / agent，覆盖不同场景 |
| **② 13 种触发事件** | 覆盖 Session 全生命周期 |
| **③ matchers 语法** | 灵活过滤 Hook 触发条件 |
| **④ 异步 Hook 支持** | async/asyncRewake，不阻塞 Agent 循环 |
| **⑤ 超时配置** | 每个 Hook 可单独配置超时 |

### 7.2 Claude Code CLI Hook 系统不足（相对 CodeStudio）

| 不足 | 说明 |
| ------ | ------ |
| **① 配置分散** | Hook 配置在 `.claude/settings.json`，constraint 在 `.claude/rules/`，skill 在 `.claude/commands/`，没有统一治理 |
| **② 无形式化约束** | Hook 决策依赖 stdout JSON，没有结构化的 constraint schema |
| **③ 无证据链闭环** | Hook 执行记录不会自动沉淀为知识 |

---

**文档状态**：✅ 第一版完成（基于 `types/hooks.ts` + `schemas/hooks.ts` + `utils/hooks.ts`）

**下一步**：

- [ ] 阅读 `services/tools/toolHooks.ts`，理解工具 Hook 执行细节
- [ ] 阅读 `utils/hooks/execPromptHook.ts`，理解 prompt Hook 执行细节
- [ ] 阅读 `utils/hooks/execAgentHook.ts`，理解 agent Hook 执行细节
- [ ] 与 CodeStudio CAP-4 Interceptor 做更详细的对比
