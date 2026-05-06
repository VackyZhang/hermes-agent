# Claude Code Hook 系统详解
> **文档定位**：深入 Claude Code 的 CLI Hook 系统（4 种类型、27 种事件）。

---

## 一、CLI Hook 系统概述
> **⚠️ 注意**：Claude Code 的 `hooks/` 目录是 React Hooks（UI），**不是** CLI Hook 系统！

**CLI Hook 系统位置**：

| 组件 | 文件路径 |
| ------ | ---------- |
| Hook 事件定义 | `entrypoints/sdk/coreTypes.ts`（27 个事件） |
| Hook 类型定义 | `types/hooks.ts` |
| Hook Schema 定义 | `schemas/hooks.ts` |
| Hook 执行逻辑 | `utils/hooks.ts`（155.72 KB） |
| 工具 Hook 处理 | `services/tools/toolHooks.ts` |
| Hook 配置管理 | `utils/hooks/hooksConfigManager.ts` |

---

## 二、Hook 类型（4 种）
| Hook 类型 | 说明 | 触发时机 |
| ----------- | ------ | ---------- |
| **command** | 执行 shell 命令 | 工具调用前后 |
| **prompt** | LLM 评估 | 需要 LLM 决策时 |
| **http** | HTTP 请求 | 需要远程调用时 |
| **agent** | 子 Agent 验证 | 需要复杂验证时 |

### 2.1 command 类型
**说明**：执行 shell 命令。

**示例配置**：

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

### 2.2 prompt 类型
**说明**：LLM 评估。

**示例配置**：

```json
// .claude/settings.json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "prompt",
        "prompt": "Is this command safe to execute?",
        "matcher": "Bash"
      }
    ]
  }
}
```text

### 2.3 http 类型
**说明**：HTTP 请求。

**示例配置**：

```json
// .claude/settings.json
{
  "hooks": {
    "PostToolUse": [
      {
        "type": "http",
        "url": "https://example.com/log",
        "method": "POST",
        "body": {
          "tool": "{{tool_name}}",
          "result": "{{tool_result}}"
        }
      }
    ]
  }
}
```text

### 2.4 agent 类型
**说明**：子 Agent 验证。

**示例配置**：

```json
// .claude/settings.json
{
  "hooks": {
    "PostToolUse": [
      {
        "type": "agent",
        "agent": "code-reviewer",
        "matcher": "Write"
      }
    ]
  }
}
```text

---

## 三、Hook 事件（27 种）
> **⚠️ 注意**：实际源代码中定义了 **27 种事件**（不是 13 种），以下表格列出所有事件。

| 事件名 | 触发时机 | 典型用途 |
| -------- | ---------- | ---------- |
| `SessionStart` | Session 启动 / 恢复 / clear | 注入初始上下文 |
| `SessionEnd` | Session 结束 | 清理、日志持久化 |
| `UserPromptSubmit` | 用户提交消息后、Agent 开始前 | 验证输入、注入上下文 |
| `PreToolUse` | 工具调用前 | **拦截 / 允许 / 询问** |
| `PostToolUse` | 工具调用后 | 审计、格式化输出 |
| `PostToolUseFailure` | 工具调用失败后 | 错误处理、重试逻辑 |
| `PermissionRequest` | 权限请求时 | 自定义审批逻辑 |
| `PermissionDenied` | 权限被拒绝时 | 处理拒绝逻辑、重试 |
| `Stop` | Agent 主动停止时 | 收尾、知识沉淀 |
| `StopFailure` | Agent 停止失败时 | 错误处理 |
| `SubagentStart` | 子 Agent 启动时 | 注入上下文、初始化 |
| `SubagentStop` | 子 Agent 完成时 | 扩展/标注子任务 |
| `PreCompact` | 上下文压缩前 | 保留关键信息 |
| `PostCompact` | 上下文压缩后 | 验证压缩结果 |
| `Setup` | Hook 系统初始化 | 初始化 Hook 环境 |
| `TeammateIdle` | Teammate 空闲时 | 触发后台任务 |
| `TaskCreated` | 任务创建时 | 任务管理 |
| `TaskCompleted` | 任务完成时 | 任务完成处理 |
| `Elicitation` | Elicitation 请求 | 收集用户输入 |
| `ElicitationResult` | Elicitation 结果 | 处理用户输入 |
| `ConfigChange` | 配置变更时 | 动态更新配置 |
| `WorktreeCreate` | Worktree 创建时 | Git worktree 管理 |
| `WorktreeRemove` | Worktree 删除时 | Git worktree 清理 |
| `InstructionsLoaded` | 指令加载时 | 初始化指令 |
| `CwdChanged` | 工作目录变更时 | 更新路径监听 |
| `FileChanged` | 文件变更时 | 触发文件监听逻辑 |
| `Notification` | 通知事件（错误/警告） | 日志、告警 |

> **说明**：`BeforeModel`、`AfterModel`、`BeforeToolSelection` 事件**不存在**于实际源代码中。

---

## 四、Hook 配置位置
| 层级 | 文件路径 | 说明 |
| ------ | ---------- | ------ |
| 用户级 | `~/.claude/settings.json` | 全局配置，对所有项目生效 |
| 项目级 | `.claude/settings.json` | 项目配置，只对当前项目生效 |
| 本地级 | `.claude/settings.local.json` | 本地配置，不提交到 Git |

---

## 五、Hook 输出协议
所有 Hook 类型都支持以下核心字段（语义一致）：

| 字段 | 说明 | 适用事件 |
| ------ | ------ | ---------- |
| `decision` | `approve` / `block` | 大多数事件（PreToolUse, PostToolUse, ...） |
| `behavior` | `allow` / `deny` | PermissionRequest 事件 |
| `reason` | 拒绝/询问原因 | PreToolUse / PermissionRequest |
| `continue` | `false` 时终止 Agent 循环 | 任意 |
| `stopReason` | 终止原因 | 同上 |
| `additionalContext` | 注入上下文 | SessionStart / UserPromptSubmit |
| `systemMessage` | 显示给用户的消息 | 任意 |

**遗漏的重要字段**（文档未提及）：

| 字段 | 说明 | 适用事件 |
| ------ | ------ | ---------- |
| `suppressOutput` | 隐藏 stdout 从 transcript（默认 false） | 任意 |
| `hookSpecificOutput` | 事件特定的输出（如 `updatedInput`, `updatedMCPToolOutput` 等） | 特定事件 |
| `async` | 标识异步 Hook | 任意 |
| `asyncTimeout` | 异步 Hook 超时时间 | 异步 Hook |

**Hook 退出码含义**（源代码 `utils/hooks.ts`）：

| 退出码 | 含义 | 说明 |
| -------- | ------ | ------ |
| **0** | 成功 | Hook 执行成功，继续正常流程 |
| **2** | 阻塞错误 | 触发 asyncRewoke，唤醒模型处理 |
| **其他** | 错误 | 非阻塞错误，记录但不中断 |

**输出格式示例**：

```json
// Hook 输出（JSON）
{
  "decision": "deny",
  "reason": "Dangerous command: rm -rf /",
  "systemMessage": "Blocked dangerous command: rm -rf /"
}
```text

---

## 六、与 CodeStudio/Hermes Agent 的对比
### 6.1 与 CodeStudio 的对比
| 维度 | Claude Code | CodeStudio |
| ------ | ------------- | ------------ |
| **Hook 实现** | TypeScript 函数（utils/hooks.ts） | Python 函数（CAP-4 Interceptor） |
| **Hook 类型** | 4 种（command/prompt/http/agent） | 1 种（Python 函数） |
| **Hook 事件** | 13 种（SessionStart, PreToolUse, ...） | 4 种（pre_tool, post_tool, session_start, session_stop） |
| **Hook 配置** | .claude/settings.json | catalog/constraints/ + MCP 工具 |
| **治理导向** | ❌ 无（Hook 是工具） | ✅ 有（CAP-4 Interceptor 是治理导向） |

### 6.2 与 Hermes Agent 的对比
| 维度 | Claude Code | Hermes Agent |
| ------ | ------------- | -------------- |
| **Hook 实现** | TypeScript 函数（utils/hooks.ts） | Python 函数 |
| **Hook 类型** | 4 种（command/prompt/http/agent） | 4 种（pre_tool, post_tool, session_start, session_stop） |
| **Hook 事件** | 13 种（SessionStart, PreToolUse, ...） | 4 种（pre_tool, post_tool, session_start, session_stop） |
| **Hook 配置** | .claude/settings.json | hermes_constants.py 中的 HOOKS 配置 |

---

**文档状态**：✅ 第一版完成（从 `1-4-1-claude-code-analysis.md` 拆分）

**下一步**：

- [ ] 补充更多 Hook 示例（从 `utils/hooks.ts` 提取）
- [ ] 补充 Hook 执行顺序的详细设计（多个 Hooks 的执行顺序）
