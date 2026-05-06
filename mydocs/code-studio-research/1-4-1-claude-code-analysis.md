# Claude Code 分析

> **文档定位**：梳理 Claude Code 的设计、实现、亮点，对比 CodeStudio/CCGS/Hermes Agent。

---

## 一、一句话总结

Claude Code 是 Anthropic 官方出品的 **AI Coding CLI**，提供可靠的 Agent 循环、工具系统、Hook
系统、Skill 系统。

**核心设计理念**：

- **Agent 循环**：`bridge/replBridge.ts` 或 `bridge/bridgeMain.ts` 实现主循环
- **工具系统**：TypeScript 类型安全的工具定义（tools/*.ts）
- **Hook 系统**：支持 4 种类型（command/prompt/http/agent）、27 种事件
- **Skill 系统**：支持 3 种来源（bundled/user-defined/plugin）

---

## 二、核心设计概览

### 2.1 整体架构

```text
claude-code/
├── bridge/             ← Agent 循环桥接层（sessionRunner.ts, replBridge.ts）
├── cli/               ← CLI 入口（19 个文件）
├── commands/           ← 命令实现（207 个文件）
├── components/         ← React UI 组件（389 个文件）
├── hooks/             ← React Hooks（104 个文件，用于 UI）⚠️ 不是 CLI Hooks！
├── tools/             ← 工具定义（184 个文件）
│   ├── BashTool/
│   ├── FileEditTool/
│   ├── FileWriteTool/
│   ├── GlobTool/
│   ├── GrepTool/
│   ├── WebFetchTool/
│   ├── WebSearchTool/
│   ├── TaskTool/       ← Agent 间任务委派
│   └── MCPTool/        ← MCP 工具适配
├── skills/            ← 技能系统（20 个文件）
├── state/             ← 状态管理（110 个文件）
└── utils/             ← 工具函数（564 个文件）
```

**⚠️ 重要发现**：Claude Code 的 `hooks/` 目录是 **React Hooks**（用于 UI），**不是** CLI Hook
系统！

**CLI Hook 系统位置**（详见 `1-4-3-claude-code-hook-system.md`）：

| 组件 | 文件路径 |
| ------ | ---------- |
| Hook 类型定义 | `types/hooks.ts` |
| Hook Schema 定义 | `schemas/hooks.ts` |
| Hook 执行逻辑 | `utils/hooks.ts`（155.72 KB） |
| 工具 Hook 处理 | `services/tools/toolHooks.ts` |
| Hook 配置管理 | `utils/hooks/hooksConfigManager.ts` |

### 2.2 Agent 循环（bridge/sessionRunner.ts）

**核心循环**（简化）：

```typescript
// bridge/sessionRunner.ts
while (apiCallCount < maxIterations && iterationBudget.remaining > 0) {
    if (interruptRequested) break;
    
    const response = await client.chat.completions.create({
        model,
        messages,
        tools: toolSchemas
    });
    
    if (response.tool_calls) {
        for (const toolCall of response.tool_calls) {
const result = await handleFunctionCall(toolCall.name, toolCall.args);
            messages.push(toolResultMessage(result));
        }
        apiCallCount++;
    } else {
        return response.content;
    }
}
```

**关键特性**：

| 特性 | 说明 |
| ------ | ------ |
| **迭代预算** | `maxIterations=90`，`iterationBudget` 控制总预算 |
| **中断检查** | `interruptRequested`，支持用户中断 |
| **Tool 执行** | `handleFunctionCall()` 统一处理 |
| **消息格式** | Anthropic 格式（与 OpenAI 不同） |

### 2.3 工具系统（tools/ 目录）

**工具定义结构**（TypeScript）：

```typescript
// tools/BashTool/index.ts
export class BashTool implements Tool {
    name = "Bash";
    description = "Execute a bash command...";
    
    inputSchema = {
        type: "object",
        properties: {
            command: { type: "string", description: "..." },
            // ...
        },
        required: ["command"]
    };
    
    async execute(input: BashInput): Promise<string> {
        // 执行 bash 命令
    }
}
```

**内置工具列表**（部分）：

| 工具 | 说明 |
| ------ | ------ |
| `Bash` | 执行 bash 命令 |
| `Read` | 读取文件 |
| `Write` | 写入文件 |
| `Edit` | 编辑文件 |
| `Glob` | 文件模式匹配 |
| `Grep` | 内容搜索 |
| `WebFetch` | 获取网页内容 |
| `WebSearch` | 网页搜索 |
| `Task` | 创建子 Agent 任务 |
| `MCPTool` | MCP 工具适配 |

### 2.4 Hook 系统（CLI Hooks）

> **⚠️ 注意**：Claude Code 的 `hooks/` 目录是 React Hooks（UI），不是 CLI Hooks。

Claude Code 的 CLI Hook 系统支持 **4 种类型**：

| Hook 类型 | 说明 | 触发时机 |
| ----------- | ------ | ---------- |
| **command** | 执行 shell 命令 | 工具调用前后 |
| **prompt** | LLM 评估 | 需要 LLM 决策时 |
| **http** | HTTP 请求 | 需要远程调用时 |
| **agent** | 子 Agent 验证 | 需要复杂验证时 |

**CLI Hook 配置位置**：

| 层级 | 文件路径 | 说明 |
| ------ | ---------- | ------ |
| 用户级 | `~/.claude/settings.json` | 全局配置，对所有项目生效 |
| 项目级 | `.claude/settings.json` | 项目配置，只对当前项目生效 |
| 本地级 | `.claude/settings.local.json` | 本地配置，不提交到 Git |

**27 种 Hook 事件**（基于 `entrypoints/sdk/coreTypes.ts`）：

| 事件名 | 触发时机 | 典型用途 |
| -------- | ---------- | ---------- |
| `SessionStart` | Session 启动 / 恢复 / clear | 注入初始上下文 |
| `Setup` | Hook 系统初始化 | 初始化 Hook 环境 |
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
| `Notification` | 通知事件（错误/警告） | 日志、告警 |
| `Elicitation` | Elicitation 请求 | 收集用户输入 |
| `ElicitationResult` | Elicitation 结果 | 处理用户输入 |
| `TeammateIdle` | Teammate 空闲时 | 触发后台任务 |
| `TaskCreated` | 任务创建时 | 任务管理 |
| `TaskCompleted` | 任务完成时 | 任务完成处理 |
| `ConfigChange` | 配置变更时 | 动态更新配置 |
| `WorktreeCreate` | Worktree 创建时 | Git worktree 管理 |
| `WorktreeRemove` | Worktree 删除时 | Git worktree 清理 |
| `InstructionsLoaded` | 指令加载时 | 初始化指令 |
| `CwdChanged` | 工作目录变更时 | 更新路径监听 |
| `FileChanged` | 文件变更时 | 触发文件监听逻辑 |

> **说明**：`BeforeModel`、`AfterModel`、`BeforeToolSelection` 事件**不存在**于实际源代码中。

**Hook 输出协议**：

所有 Hook 类型都支持以下核心字段（语义一致）：

| 字段 | 说明 | 适用事件 |
| ------ | ------ | ---------- |
| `decision` | `approve` / `block` | 大多数事件（PreToolUse, PostToolUse, ...） |
| `behavior` | `allow` / `deny` | PermissionRequest 事件 |
| `reason` | 拒绝/询问原因 | 同上 |
| `continue` | `false` 时终止 Agent 循环 | 任意 |
| `stopReason` | 终止原因 | 同上 |
| `additionalContext` | 注入上下文 | SessionStart / UserPromptSubmit |
| `systemMessage` | 显示给用户的消息 | 任意 |

### 2.5 Skill 系统

**Skill 定义结构**（详见 `1-4-4-claude-code-skill-system.md`）：

Claude Code 的 Skill 系统支持 **3 种来源**：

| Skill 来源 | 说明 | 注册方式 |
| ------------ | ------ | ---------- |
| **bundled** |
| `registerBundledSkill()` 注册 |
| **user-defined** | 用户定义 Skill | 存放在 `.claude/commands/` 目录，Markdown 文件 |
| **plugin** | 插件 Skill | 插件在初始化时调用 `registerPluginSkill()` 注册 |

**Skill Frontmatter**（元数据）：

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

**Skill 触发方式**（3 种）：

| 触发方式 | 说明 | 示例 |
| ---------- | ------ | ------ |
| **slash 命令** | 用户通过 `/skill-name` 手动触发 | User: `/debug "login failed"` |
| **LLM 自动选择** |
| review my code?` → Claude Code 自动调用 `/review` Skill |
| **Hook 触发** |
| `PostToolUse` Hook 调用 `type: "agent"` 触发子 Agent 验证 |

---

## 三、亮点与创新

| 亮点 | 说明 | 相对 CCGS 的优势 |
| ------ | ------ | --------------------- |
| **① 官方实现** | Anthropic 官方出品，与 Claude API 深度集成 | CCGS 是第三方模板 |
| **② TypeScript 类型安全** | 工具定义、消息格式都有完整类型 | CCGS 是 Markdown + YAML（无类型检查） |
| **③ 丰富的 UI** | React 组件库（389 个文件） | CCGS 无 UI（依赖 Claude Code 的终端 UI） |
| **④ MCP 原生支持** | `MCPTool` 原生支持 MCP 协议 | CCGS 依赖 Claude Code 的 MCP 支持 |
| **⑤ 多平台支持** | 桌面端、Web、VS Code 扩展 | CCGS 只支持 Claude Code 终端 |
| **⑥ 4 种 Hook 类型** |
| 脚本（单一类型） |
| **⑦ 27 种 Hook 事件** | 覆盖 Session 全生命周期 | CCGS 的 Hook 事件较少 |
| **⑧ 3 种 Skill 来源** |
| 都是用户定义 |
| **⑨ Skill 级 Hook** | Skill 可以关联 Hook，实现更复杂的工作流 | CCGS 没有（Skill 不包含 Hook） |

**不足**（相对 CodeStudio）：

| 不足 | 说明 |
| ------ | ------ |
| **① 无形式化治理** | 没有 CAP-2 Enforcer、GD+CC 双轴治理 |
| **② 无证据链闭环** | 没有 `trace → evidence → knowledge → injection` |
| **③ 无多 CLI 抽象** | 只支持 Claude API（Anthropic 官方） |
| **④ Hook 系统不统一** |
| `.claude/rules/`，skill 在 `.claude/commands/`，没有统一治理 |
| **⑤ 无知识进化机制** | Skill 执行记录不会自动沉淀为知识 |

---

## 四、当前状态（2026-05）

| 维度 | 完成度 | 说明 |
| ------ | -------- | ------ |
| **Agent 循环** | ✅ 完成 | `bridge/sessionRunner.ts` |
| **工具系统** | ✅ 完成 | `tools/*.ts`（TypeScript 类） |
| **Hook 系统** | ✅ 完成 | `utils/hooks.ts`（4 种类型，27 种事件） |
| **Skill 系统** | ✅ 完成 | `skills/`（3 种来源，内置 Skill 数量取决于 feature flags） |
| **多平台支持** | ✅ 完成 | 桌面端、Web、VS Code 扩展 |
| **文档** | 🔨 进行中 | README.md 已完成，部分 Skill 需要补充文档 |

---

**文档状态**：✅ 第二版完成（主文档 + 子文档结构，总结性输出 + 深入细节拆分）

**子文档列表**：

| 子文档 | 内容 |
| --------- | ------ |
| `1-4-2-claude-code-architecture.md` | 整体架构、Agent 循环细节 |
| `1-4-5-claude-code-tool-system.md` |
| 类型安全、工具定义结构、内置工具列表） |
| `1-4-3-claude-code-hook-system.md` |
| 输出协议、配置位置） |
| `1-4-4-claude-code-skill-system.md` |
| Frontmatter、Skill 触发方式） |
| `1-4-5-claude-code-summary.md` | 总结、对比、对 CodeStudio 的启发 |

**下一步**：

- [ ] 读取 `bridge/sessionRunner.ts` 完整代码，分析 Agent 循环细节
- [ ] 详细对比 Claude Code 与 CCGS 的异同
- [ ] 与 CodeStudio 深度对比，提炼 CodeStudio 可以借鉴的特性
- [ ] 在 letsgo_server 上做真实验证
