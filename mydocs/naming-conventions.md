# 命名规范与术语定义

> 全局统一的术语定义和文件编写规范，确保人与 AI 协作时语义一致。

---

## 一、术语定义（全局唯一）

### 1.1 核心概念

| 术语 | 英文 | 定义 | 相关文件 |
|------|------|------|---------|
| **Agent** | AIAgent | hermes 的核心智能体，负责对话循环、工具调用、上下文管理 | `run_agent.py` |
| **会话** | Session | 一次完整的用户交互序列，包含多条消息，有唯一 session_id | `hermes_state.py`, `gateway/session.py` |
| **消息** | Message | OpenAI 格式的对话单元，role ∈ {system, user, assistant, tool} | `run_agent.py` 中 `messages` 列表 |
| **工具** | Tool | Agent 可调用的外部功能，通过 JSON schema 描述 | `tools/*.py`, `model_tools.py` |
| **工具集** | Toolset | 工具的集合，如 `core`, `web`, `terminal` | `toolsets.py` |
| **工具调用** | Tool Call | LLM 返回的 function_call，包含 name 和 arguments | `run_agent.py` `response.tool_calls` |
| **Hook** | Hook | 生命周期回调，如 `pre_tool_call`, `post_llm_call` | `hermes_cli/plugins.py` `VALID_HOOKS` |
| **插件** | Plugin | 通过 `register(ctx)` 注册工具和 hook 的扩展模块 | `plugins/` |
| **上下文** | Context | 当前会话的全部消息历史 + 系统提示 + 工具定义 | `messages` 列表整体 |
| **迭代** | Iteration | Agent 循环的一次完整执行（LLM 调用 + 可选工具执行） | `run_agent.py` `api_call_count` |
| **预算** | Budget | 迭代次数和 token 的消耗限制 | `run_agent.py` `iteration_budget` |

### 1.2 模块/组件

| 术语 | 定义 | 相关文件/目录 |
|------|------|--------------|
| **CLI** | 命令行交互界面，基于 prompt_toolkit | `cli.py`, `hermes_cli/` |
| **TUI** | 终端图形界面，基于 Ink (React) | `ui-tui/`, `tui_gateway/` |
| **Gateway** | 消息网关，连接外部平台（Telegram/Discord 等） | `gateway/` |
| **Registry** | 工具注册中心，管理所有可用工具 | `tools/registry.py` |
| **Skin Engine** | CLI 主题皮肤系统 | `hermes_cli/skin_engine.py` |
| **Platform Adapter** | 网关的平台适配器，处理特定消息协议 | `gateway/platforms/` |

### 1.3 调试相关（vacky_debug 专用）

| 术语 | 定义 |
|------|------|
| **Debug Mode** | `VACKY_DEBUG=1` 环境变量启用的调试状态 |
| **Inspect** | 观察对象运行时状态（`vacky_inspect_state`） |
| **Dump** | 导出上下文到文件（`vacky_dump_context`） |
| **Breakpoint** | 触发 pdb 断点（`vacky_trigger_breakpoint`） |
| **Hook Log** | hook 触发时打印的调试日志 |

---

## 二、文件编写规范

### 2.1 架构分析文件（`architecture/*.md`）

```markdown
# <编号>-<模块名>.md

## 1. 概述
（一句话定义这个模块是什么，在系统中的位置）

## 2. 架构图
```
（ASCII 数据流图或文字描述）
```

## 3. 核心类/函数

### 3.1 <ClassName>
| 属性/方法 | 类型 | 说明 |
|-----------|------|------|
| attr1 | str | ... |
| method1() | -> dict | ... |

### 3.2 <FunctionName>
| 参数 | 类型 | 说明 |
|------|------|------|
| param1 | str | ... |

## 4. 数据流
1. 步骤一：...
2. 步骤二：...
3. 步骤三：...

## 5. 关键代码路径
```python
# 伪代码或关键代码片段
```

## 6. 调试观察点
| 观察点 | 文件 | 行号范围 | 调试方式 |
|--------|------|---------|---------|
| XXX | run_agent.py | 800-850 | pre_llm_call hook |

## 7. 与其他模块的关系
- 上游依赖：...
- 下游消费：...

## 8. 疑问与待办
- [ ] 问题 1
- [ ] 问题 2
```

### 2.2 调试记录文件（`debugging/sessions/YYYY-MM-DD-*.md`）

```markdown
# 调试记录 — YYYY-MM-DD 标题

## 环境
- 分支：vacky/dev
- Commit：`29532c1`
- 启动命令：`VACKY_DEBUG=1 hermes`

## 目标
本次想验证/观察什么？

## 过程

### 步骤 1：...
- 操作：...
- 观察：...
- 日志/输出：...

## 结果
- 成功/失败/待确认
- 关键发现

## 关联
- 相关架构笔记：`architecture/01-agent-loop.md`
- 相关代码：`run_agent.py:850`
```

### 2.3 命名约定

| 场景 | 规范 | 示例 |
|------|------|------|
| 架构文件 | `<2位编号>-<kebab-case>.md` | `01-agent-loop.md` |
| 调试记录 | `<YYYY-MM-DD>-<kebab-case>.md` | `2026-04-30-first-test.md` |
| 实验目录 | `<kebab-case>/` | `context-compaction-test/` |
| 代码中的变量 | snake_case | `tool_call_count`, `session_id` |
| 类名 | PascalCase | `AIAgent`, `PluginManager` |
| 常量 | UPPER_SNAKE_CASE | `MAX_ITERATIONS`, `VALID_HOOKS` |
| Hook 名称 | snake_case | `pre_tool_call`, `post_llm_call` |
| 工具名 | snake_case | `vacky_inspect_state` |
| 插件名 | snake_case | `vacky_debug` |
| 分支名 | `<name>/<purpose>` | `vacky/dev`, `feature/mcp-tools` |

---

## 三、AI 协作提示词模板

当让 AI 协助分析某个模块时，使用以下格式提供上下文：

```
请分析 hermes-agent 的 <模块名>：

**术语定义**（参考 naming-conventions.md）：
- Agent：...
- Session：...

**分析目标**：
- 理解 XXX 的执行流程
- 观察 YYY 时的数据变化

**相关文件**：
- `run_agent.py:800-900`
- `model_tools.py:100-200`

**当前观察**：
- 通过 vacky_debug 的 pre_tool_call hook 看到 ...

**输出要求**：
- 按 architecture/*.md 的格式输出
- 包含架构图、数据流、调试观察点
```

---

## 四、文件状态标记

在文档顶部用注释标记完成状态：

```markdown
<!--
状态：draft | in-progress | review | done
阶段：Phase X
最后更新：YYYY-MM-DD
-->
```
