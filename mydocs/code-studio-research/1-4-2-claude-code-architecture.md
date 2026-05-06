# Claude Code 架构详解

> **文档定位**：深入 Claude Code 的整体架构、Agent 循环、工具系统概览。

---

## 一、整体架构

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
```text

**⚠️ 重要发现**：Claude Code 的 `hooks/` 目录是 **React Hooks**（用于 UI），**不是** CLI Hook 系统！

**CLI Hook 系统位置**（详见 `1-4-3-claude-code-hook-system.md`）：

| 组件 | 文件路径 |
| ------ | ---------- |
| Hook 类型定义 | `types/hooks.ts` |
| Hook Schema 定义 | `schemas/hooks.ts` |
| Hook 执行逻辑 | `utils/hooks.ts`（155.72 KB） |
| 工具 Hook 处理 | `services/tools/toolHooks.ts` |
| Hook 配置管理 | `utils/hooks/hooksConfigManager.ts` |

---

## 二、Agent 循环（bridge/sessionRunner.ts）

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
```text

**关键特性**：

| 特性 | 说明 |
| ------ | ------ |
| **迭代预算** | `maxIterations=90`，`iterationBudget` 控制总预算 |
| **中断检查** | `interruptRequested`，支持用户中断 |
| **Tool 执行** | `handleFunctionCall()` 统一处理 |
| **消息格式** | Anthropic 格式（与 OpenAI 不同） |

---

## 三、工具系统概览（tools/ 目录）

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
```text

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

**深入细节** → 详见 `1-4-5-claude-code-tool-system.md`

---

## 四、与 CodeStudio 的对比

### 4.1 Agent 循环对比

| 维度 | Claude Code | CodeStudio |
| ------ | ------------- | ------------ |
| **Agent 循环实现** | `bridge/sessionRunner.ts`（TypeScript） | `harness/lifecycle/runner.py`（Python） |
| **迭代预算** | `maxIterations=90`，`iterationBudget` | `max_iterations=90`，`iteration_budget` |
| **中断检查** | `interruptRequested` | `_interrupt_requested` |
| **消息格式** | Anthropic 格式 | OpenAI 格式 |

### 4.2 工具系统对比

| 维度 | Claude Code | CodeStudio |
| ------ | ------------- | ------------ |
| **工具定义** | TypeScript 类（tools/*.ts） | Python 函数（tools/*.py） |
| **工具发现** | 手动注册（tools/index.ts） | 自动发现（tools/*.py 自动导入） |
| **类型安全** | TypeScript 类型安全 | Python 类型提示（可选） |
| **工具执行** | TypeScript 方法调用 | Python 函数调用 |

---

**文档状态**：✅ 第一版完成（从 `1-4-claude-code-analysis.md` 拆分）

**下一步**：

- [ ] 补充 Agent 循环的更多细节（从 `bridge/sessionRunner.ts` 提取）
- [ ] 补充工具系统的更多示例（从 `tools/` 目录提取）
