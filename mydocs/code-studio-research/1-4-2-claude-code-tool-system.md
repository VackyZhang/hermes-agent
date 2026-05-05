# Claude Code 工具系统详解

> **文档定位**：深入 Claude Code 的工具系统（tools/*.ts，TypeScript 类型安全）。

---

## 一、工具系统概述

Claude Code 的工具系统在 `tools/` 目录中实现，使用 TypeScript 类定义工具。

**核心设计理念**：

- **TypeScript 类型安全**：工具定义、参数、返回值都有完整类型
- **统一执行接口**：所有工具实现 `Tool` 接口
- **工具发现**：手动注册（tools/index.ts）

---

## 二、Tool 接口定义

```typescript
// tools/tool.ts
export interface Tool {
    name: string;
    description: string;
    inputSchema: object;
    
    execute(input: any): Promise<string>;
}

export interface ToolCallResult {
    output?: string;
    error?: string;
    continue?: boolean;
    stopReason?: string;
}
```text

---

## 三、工具定义示例

### 3.1 BashTool

```typescript
// tools/BashTool/index.ts
export class BashTool implements Tool {
    name = "Bash";
    description = `Execute a bash command and return the output.
    
    Before calling this tool, think about whether it is safe and expected to:

    - Run the command as the user (not as a daemon or background process)
    - Read stdout/stderr (if the command returns stdout/stderr, you should read it)
|     - Check if the command is safe (no rm -rf /, no curl | sh) |
    - Check if the command is expected (user asked you to run it)

    `;
    
    inputSchema = {
        type: "object",
        properties: {
            command: {
                type: "string",
                description: "The bash command to execute..."
            },
            // ...
        },
        required: ["command"]
    };
    
    async execute(input: BashInput): Promise<string> {
        const { command } = input;
        
        // 1. Check if command is safe
        if (isDangerousCommand(command)) {
            return JSON.stringify({
                error: "Dangerous command blocked",
                suggestion: "Please confirm if you really want to run this command."
            });
        }
        
        // 2. Execute command
        const result = await execAsync(command);
        
        // 3. Return result
        return JSON.stringify({
            stdout: result.stdout,
            stderr: result.stderr,
            exitCode: result.exitCode
        });
    }
}
```text

### 3.2 ReadTool

```typescript
// tools/ReadTool/index.ts
export class ReadTool implements Tool {
    name = "Read";
    description = "Read the contents of a file...";
    
    inputSchema = {
        type: "object",
        properties: {
            path: {
                type: "string",
                description: "The absolute path to the file to read"
            },
            offset: {
                type: "number",
                description: "The line number to start reading from (0-indexed)"
            },
            limit: {
                type: "number",
                description: "The number of lines to read"
            }
        },
        required: ["path"]
    };
    
    async execute(input: ReadInput): Promise<string> {
        const { path, offset, limit } = input;
        
        // 1. Read file
        const content = await fs.readFile(path, 'utf-8');
        
        // 2. Apply offset and limit
        const lines = content.split('\n');
|         const start = offset || 0; |
        const end = limit ? start + limit : lines.length;
        const selectedLines = lines.slice(start, end);
        
        // 3. Return result (with line numbers)
        return selectedLines.map((line, i) => `${start + i + 1}:${line}`).join('\n');
    }
}
```text

---

## 四、工具注册（tools/index.ts）

```typescript
// tools/index.ts
import { BashTool } from './BashTool';
import { ReadTool } from './ReadTool';
import { WriteTool } from './WriteTool';
// ...

export function registerTools(): ToolRegistry {
    const registry = new ToolRegistry();
    
    registry.register(new BashTool());
    registry.register(new ReadTool());
    registry.register(new WriteTool());
    // ...
    
    return registry;
}
```text

---

## 五、工具执行流程

```text
LLM 返回 tool_call
    ↓
handleFunctionCall()
    ↓
[1] 查找工具（ToolRegistry）
    ↓
[2] 验证参数（inputSchema）
    ↓
[3] 执行工具（tool.execute()）
    ↓
[4] 返回结果（ToolCallResult）
    ↓
追加到 messages（role: "tool"）
    ↓
继续 Agent 循环
```text

---

## 六、与 Hermes Agent 的对比

| 维度 | Claude Code | Hermes Agent |
| ------ | ------------- | -------------- |
| **工具定义** | TypeScript 类（tools/*.ts） | Python 函数（tools/*.py） |
| **工具发现** | 手动注册（tools/index.ts） | 自动发现（tools/*.py 自动导入） |
| **类型安全** | TypeScript 类型安全 | Python 类型提示（可选） |
| **工具执行** | TypeScript 方法调用 | Python 函数调用 |
| **错误处理** | ToolCallResult（统一格式） | JSON 字符串（统一格式） |

---

**文档状态**：✅ 第一版完成（从 `1-4-claude-code-analysis.md` 拆分）

**下一步**：

- [ ] 补充更多工具的示例（从 `tools/` 目录提取）
- [ ] 补充工具权限控制的详细设计（从 `utils/permissions.ts` 提取）
