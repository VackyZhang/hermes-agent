# Hermes Agent 工具系统详解

> **文档定位**：深入 Hermes Agent 的工具系统（model_tools.py + tools/）。

---

## 一、工具系统概述

Hermes Agent 的工具系统在 `model_tools.py` 和 `tools/` 目录中实现。

**核心设计理念**：

- **工具注册表**（ToolRegistry）：集中管理所有工具
- **自动发现**：任何 `tools/*.py` 文件，只要有顶层 `registry.register()` 调用，就会被自动导入
- **统一执行**：`handle_function_call()` 统一处理工具调用
- **错误处理**：工具执行错误统一包装为 JSON 格式返回

---

## 二、工具注册表（ToolRegistry）

### 2.1 注册表结构

```python

# model_tools.py

class ToolRegistry:
    def __init__(self):
        self._tools = {}      # name → {schema, handler, check_fn, requires_env}
        self._enabled = set() # enabled tool names
    
    def register(self, name: str, toolset: str, schema: dict, 
                handler: Callable, check_fn: Callable = None, 
                requires_env: list = None, is_async: bool = False,
                description: str = "", emoji: str = "",
|                 max_result_size_chars: int | float | None = None): |
        """Register a tool."""

        # 实际实现使用 ToolEntry 类（不是 dict）

        entry = ToolEntry(
            name=name,
            toolset=toolset,
            schema=schema,
            handler=handler,
            check_fn=check_fn,
            requires_env=requires_env or [],
            is_async=is_async,
            description=description,
            emoji=emoji,
            max_result_size_chars=max_result_size_chars
        )
        self._tools[name] = entry
        self._enabled.add(name)
    
    def unregister(self, name: str):
        """Unregister a tool."""
        if name in self._tools:
            del self._tools[name]
            self._enabled.discard(name)
    
    def get_schema(self, name: str) -> dict:
        """Get tool schema (for LLM API)."""
        if name not in self._enabled:
            return None
        return self._tools[name]["schema"]
    
    def get_all_schemas(self) -> list[dict]:
        """Get all enabled tool schemas."""
        return [t["schema"] for t in self._tools.values() if t["name"] in self._enabled]
    
    def execute(self, name: str, args: dict, task_id: str = None) -> str:
        """Execute a tool."""
        if name not in self._enabled:
            return json.dumps({"error": f"Tool {name} is disabled"})
        
        tool = self._tools[name]
        
        # Check if required env vars are set

        for env_var in tool["requires_env"]:
            if not os.getenv(env_var):
                return json.dumps({"error": f"Missing required env var: {env_var}"})
        
        # Execute handler

        try:
            result = tool["handler"](args, task_id=task_id)
            return result
        except Exception as e:
            return json.dumps({"error": str(e)})
```text

### 2.2 工具注册示例

```python

# tools/your_tool.py

import json, os
from tools.registry import registry

def check_requirements() -> bool:
    return bool(os.getenv("EXAMPLE_API_KEY"))

def example_tool(param: str, task_id: str = None) -> str:
    return json.dumps({"success": True, "data": "..."})

registry.register(
    name="example_tool",
    schema={"name": "example_tool", "description": "...", "parameters": {...}},
    handler=lambda args, **kw: example_tool(param=args.get("param", ""), task_id=kw.get("task_id")),
    check_fn=check_requirements,
    requires_env=["EXAMPLE_API_KEY"],
)
```text

---

## 三、自动发现机制

**自动发现流程**：

```text
Hermes Agent 启动
    ↓
model_tools.py 导入
    ↓
tools/registry.py 导入
    ↓
遍历 tools/*.py
    ↓
执行每个文件的顶层代码（registry.register() 调用）
    ↓
工具注册到 ToolRegistry
```text

**关键设计**：

- 任何 `tools/*.py` 文件，只要有顶层 `registry.register()` 调用，就会被自动导入
- 不需要手动维护工具列表（toolsets.py 中的 _HERMES_CORE_TOOLS 列表是可选的，用于指定核心工具）

---

## 四、工具执行流程

```text
LLM 返回 tool_call
    ↓
handle_function_call()
    ↓
[1] 检查工具是否启用（ToolRegistry._enabled）
    ↓
[2] 检查工具是否允许（permissions）
    ↓
[3] 检查所需环境变量（requires_env）
    ↓
[4] 执行工具（ToolRegistry.execute()）
    ↓
[5] 返回结果（JSON string）
```text

**错误处理**：

| 错误类型 | 返回格式 |
| ---------- | ---------- |
| 工具禁用 | `{"error": "Tool xxx is disabled"}` |
| 工具不允许 | `{"error": "Tool xxx is not allowed"}` |
| 缺少环境变量 | `{"error": "Missing required env var: XXX"}` |
| 执行异常 | `{"error": "..."}` |

---

## 五、工具 Schema 格式

**工具 Schema 示例**：

```json
{
    "name": "read_file",
    "description": "Read the contents of a file. The output includes line numbers and may be truncated if the file is too long.",
    "parameters": {
        "type": "object",
        "properties": {
            "path": {
                "type": "string",
                "description": "The absolute path to the file to read"
            },
            "offset": {
                "type": "integer",
                "description": "The line number to start reading from (0-indexed)"
            },
            "limit": {
                "type": "integer",
                "description": "The number of lines to read"
            }
        },
        "required": ["path"]
    }
}
```text

---

## 六、与 CCGS/Claude Code 的对比

### 6.1 与 CCGS 的对比

| 维度 | CCGS | Hermes Agent |
| ------ | ------- | ------------ |
| **工具定义** | Claude Code 内置工具（Bash, Read, Write, Edit, ...） | Python 函数（tools/*.py） |
| **工具发现** | 手动配置（.claude/settings.json） | 自动发现（tools/*.py 自动导入） |
| **工具执行** | Claude Code 内置执行器 | Python 函数调用 |
| **错误处理** | Claude Code 内置错误处理 | 统一包装为 JSON 格式返回 |

### 6.2 与 Claude Code 的对比

| 维度 | Claude Code | Hermes Agent |
| ------ | ------------- | ------------ |
| **工具定义** | TypeScript 类（tools/*.ts） | Python 函数（tools/*.py） |
| **工具发现** | 手动注册（tools/index.ts） | 自动发现（tools/*.py 自动导入） |
| **类型安全** | TypeScript 类型安全 | Python 类型提示（可选） |
| **工具执行** | TypeScript 方法调用 | Python 函数调用 |

---

**文档状态**：✅ 第一版完成（从 `1-3-hermes-analysis.md` 拆分）

**下一步**：

- [ ] 补充更多工具的示例（从 `tools/` 目录提取）
- [ ] 补充工具权限控制的详细设计
