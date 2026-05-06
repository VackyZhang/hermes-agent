# Hermes Agent 分析

> **文档定位**：梳理 Hermes Agent 的设计、实现、亮点，对比 CodeStudio/CCGS/Claude Code，并针对 `0-problems-and-goals.md` 中的问题提出解决思路。
>
> **本文结构**：

> - **主文档**（本文件）：总结性输出，建立整体认知
> - **子文档**（深入细节）：
>   - `1-3-2-hermes-agent-loop.md`：Agent 循环详细分析（run_agent.py）
>   - `1-3-3-hermes-tool-system.md`：工具系统详细分析（model_tools.py + tools/）
>   - `1-3-4-hermes-hook-system.md`：Hook 系统详细分析（Python 原生）
>   - `1-3-5-hermes-skill-system.md`：Skill 系统详细分析（skills/ 目录）
>   - `1-3-6-hermes-memory-system.md`：记忆系统详细分析（hermes_state.py + plugins/memory/）

---

## 一、一句话总结

Hermes Agent 是一个 **AI Agent 框架**，实现了可靠的 Agent 循环、工具系统、Hook 系统、Skill 系统、记忆系统。

**核心设计理念**：

- **Agent 循环**：`run_agent.py` 实现可靠的多轮对话 + 工具调用循环

- **工具系统**：`model_tools.py` + `tools/` 实现统一的工具定义、执行、错误处理

- **Hook 系统**：Python 原生实现，在工具调用前后自动执行检查

- **Skill 系统**：`skills/` 目录存放 Skill 定义，支持 slash 命令调用

- **记忆系统**：`hermes_state.py` + `plugins/memory/` 实现跨会话记忆

---

## 二、核心设计概览

### 2.1 整体架构

```text
hermes-agent/
├── run_agent.py          ← AIAgent 类 — 核心对话循环（~12k LOC）
├── model_tools.py        ← Tool 编排，discover_builtin_tools(), handle_function_call()
├── toolsets.py          ← Toolset 定义，_HERMES_CORE_TOOLS 列表
├── cli.py               ← HermesCLI 类 — 交互式 CLI 编排器（~11k LOC）
├── hermes_state.py       ← SessionDB — SQLite session store（FTS5 搜索）
├── hermes_constants.py  ← get_hermes_home(), display_hermes_home() — profile-aware paths
├── hermes_logging.py   ← setup_logging() — agent.log / errors.log / gateway.log（profile-aware）
├── batch_runner.py      ← 并行批处理
├── agent/                ← Agent 内部（provider adapters, memory, caching, compression, ...）
├── hermes_cli/           ← CLI 子命令，setup wizard, plugins loader, skin engine
├── tools/                ← 工具实现 — 自动发现 via tools/registry.py
│   └── environments/     ← 终端后端（local, docker, ssh, modal, daytona, singularity）
├── gateway/              ← Messaging gateway — run.py + session.py + platforms/
│   ├── platforms/        ← 适配器 per platform（telegram, discord, slack, whatsapp, ...）
│   └── builtin_hooks/   ← 扩展点 for always-registered gateway hooks（none shipped）
├── plugins/              ← 插件系统（see "Plugins" section below）
│   ├── memory/           ← Memory-provider 插件（honcho, mem0, supermemory, ...）
│   ├── context_engine/   ← Context-engine 插件
│   └── <others>/        ← Dashboard, image-gen, disk-cleanup, examples, ...
├── optional-skills/      ← 更重/小众 skills 有船但 NOT 活跃 by default
├── skills/               ← 内置 skills bundled with the repo
├── ui-tui/               ← Ink（React）终端 UI — `hermes --tui`
│   └── src/             ← entry.tsx, app.tsx, gatewayClient.ts + app/components/hooks/lib
├── tui_gateway/          ← Python JSON-RPC backend for the TUI
├── acp_adapter/          ← ACP server（VS Code / Zed / JetBrains integration）
├── cron/                 ← Scheduler — jobs.py, scheduler.py
├── environments/         ← RL training environments（Atropos）
├── scripts/              ← run_tests.sh, release.py, auxiliary scripts
├── website/              ← Docusaurus docs site
└── tests/               ← Pytest suite（~15k tests across ~700 files as of Apr 2026）
```text

**深入细节** → 详见 `1-3-2-hermes-agent-loop.md`（Agent 循环）、`1-3-3-hermes-tool-system.md`（工具系统）

### 2.2 Agent 循环（run_agent.py）

**核心循环**（简化）：

```python

# run_agent.py

while (api_call_count < max_iterations and iteration_budget.remaining > 0) or self._budget_grace_call:
    if self._interrupt_requested: break
    
    response = client.chat.completions.create(
        model=model,
        messages=messages,
        tools=tool_schemas
    )
    
    if response.tool_calls:
        for tool_call in response.tool_calls:
            result = handle_function_call(tool_call.name, tool_call.args, task_id)
            messages.append(tool_result_message(result))
        api_call_count += 1
    else:
        return response.content
```text

**关键特性**：

| 特性 | 说明 |
| ------ | ------ |
| **迭代预算** | `max_iterations=90`，`iteration_budget` 控制总预算 |
| **中断检查** | `_interrupt_requested`，支持用户中断 |
| **Tool 执行** | `handle_function_call()` 统一处理 |
| **消息格式** | OpenAI 格式（`{"role": "system/user/assistant/tool", ...}`） |

**深入细节** → 详见 `1-3-2-hermes-agent-loop.md`

### 2.3 工具系统（model_tools.py + tools/）

**工具注册机制**：

```python

# tools/registry.py

registry = ToolRegistry()

def register(name, schema, handler, check_fn, requires_env):
    registry.register(name, schema, handler, check_fn, requires_env)

# tools/your_tool.py

def your_tool(param: str, task_id: str = None) -> str:
    return json.dumps({"success": True, "data": "..."})

registry.register(
    name="your_tool",
    schema={"name": "your_tool", "description": "...", "parameters": {...}},
    handler=lambda args, **kw: your_tool(param=args.get("param", ""), task_id=kw.get("task_id")),
    check_fn=lambda: bool(os.getenv("YOUR_API_KEY")),
    requires_env=["YOUR_API_KEY"]
)
```text

**自动发现**：任何 `tools/*.py` 文件，只要有顶层 `registry.register()` 调用，就会被自动导入。

**深入细节** → 详见 `1-3-3-hermes-tool-system.md`

### 2.4 Hook 系统（Python 原生）

**Hook 类型**：

| Hook 类型 | 触发时机 | 示例 |
| ----------- | ---------- | ------ |
| **pre_tool** | 工具调用前 | 检查工具调用是否合规 |
| **post_tool** | 工具调用后 | 记录工具调用结果 |
| **session_start** | Session 启动时 | 注入初始上下文 |
| **session_stop** | Session 结束时 | 清理、日志持久化 |

**Hook 配置位置**：`hermes_constants.py` 中的 `HOOKS` 配置。

**深入细节** → 详见 `1-3-4-hermes-hook-system.md`

### 2.5 Skill 系统（skills/ 目录）

**Skill 定义结构**：

```text
skills/<skill-name>/
├── SKILL.md          # Skill 定义：触发条件、工作流、输出格式
└── references/       # 参考文档：领域知识、规范、示例
```text

**Skill 调用方式**：

| 调用方式 | 说明 | 示例 |
| ---------- | ------ | ------ |
| **slash 命令** | 用户通过 `/skill-name` 手动触发 | User: `/debug "login failed"` |
| **LLM 自动选择** | 当 Skill 的 `whenToUse` 匹配时，LLM 自动调用 | User: `Can you review my code?` → Hermes Agent 自动调用 `/code-review` Skill |
| **Hook 触发** | 通过 Hook 系统触发 Skill | `post_tool` Hook 调用 `code-review` Skill |

**深入细节** → 详见 `1-3-5-hermes-skill-system.md`

### 2.6 记忆系统（hermes_state.py + plugins/memory/）

**记忆类型**：

| 记忆类型 | 存储位置 | 说明 |
| --------- | ---------- | ------ |
| **Session DB** | `hermes_state.py`（SQLite） | 对话历史，支持 FTS5 搜索 |
| **Memory 插件** | `plugins/memory/`（honcho, mem0, supermemory, ...） | 跨会话记忆，结构化存储 |
| **项目文档** | `.hermes/docs/*.md` | 项目特定的知识文档 |

**记忆注入时机**：

| 时机 | 说明 |
| ------ | ------ |
| **Session 启动** | 注入 Session DB 中的历史对话 |
| **按需查询** | LLM 通过 `query_memory` 工具查询记忆 |

**深入细节** → 详见 `1-3-6-hermes-memory-system.md`

---

## 三、亮点与创新

| 亮点 | 说明 | 相对 CCGS/Claude Code 的优势 |
| ------ | ------ | ---------------------------------- |
| **① 可靠的 Agent 循环** | `run_agent.py` 实现可靠的多轮对话 + 工具调用循环 | CCGS 依赖 Claude Code 的 Agent 循环 |
| **② 统一的工具系统** | `model_tools.py` + `tools/` 实现统一的工具定义、执行、错误处理 | CCGS 的工具系统依赖 Claude Code 的内置工具 |
| **③ Python 原生 Hook** | Hook 系统用 Python 实现，易于扩展 | CCGS 的 Hook 是 bash/powershell 脚本 |
| **④ Skill 系统** | `skills/` 目录存放 Skill 定义，支持 slash 命令调用 | CCGS 的 Skill 是 Markdown 文件 |
| **⑤ 记忆系统** | `hermes_state.py` + `plugins/memory/` 实现跨会话记忆 | CCGS 的 Agent 记忆是静态的（`memory: project/user`） |
| **⑥ 多平台支持** | `gateway/` 目录支持 Telegram、Discord、Slack、... | CCGS 只支持 Claude Code 终端 |
| **⑦ 插件系统** | `plugins/` 目录支持 Memory、Context Engine、... | CCGS 没有插件系统 |

**不足**（相对 CodeStudio）：

| 不足 | 说明 | CodeStudio 的解决方案 |
| ------ | ------ | --------------------- |
| **① 无形式化治理** | 没有 CAP-2 Enforcer、GD+CC 双轴治理 | CodeStudio 的 CAP-2 Enforcer 是硬性约束 |
| **② 无证据链闭环** | 没有 `trace → evidence → knowledge → injection` | CodeStudio 的证据链闭环 |
| **③ 无多 CLI 抽象** | Hermes Agent 是独立 CLI，不支持其他 CLI | CodeStudio 的 N+M 架构支持多 CLI |

---

## 四、当前状态（2026-05）

| 维度 | 完成度 | 说明 |
| ------ | -------- | ------ |
| **Agent 循环** | ✅ 完成 | `run_agent.py`（~12k LOC） |
| **工具系统** | ✅ 完成 | `model_tools.py` + `tools/`（自动发现） |
| **Hook 系统** | ✅ 完成 | Python 原生实现 |
| **Skill 系统** | ✅ 完成 | `skills/` 目录 |
| **记忆系统** | ✅ 完成 | `hermes_state.py` + `plugins/memory/` |
| **网关** | ✅ 完成 | `gateway/` 目录（多平台支持） |
| **文档** | 🔨 进行中 | AGENTS.md 已完成，部分技能需要补充文档 |

---

## 五、与 CodeStudio/CCGS/Claude Code 的对比

### 5.1 与 CodeStudio 的对比

| 维度 | Hermes Agent | CodeStudio | CodeStudio 的优势 |
| ------ | -------------- | ------------ | ------------------- |
| **定位** | AI Agent 框架（实现 Agent 循环 + 工具系统） | Agent Harness 框架（治理 Agent 行为） | 定位不同：Hermes Agent 是"实现"，CodeStudio 是"治理" |
| **知识复用** | Session DB（对话历史）+ Memory 插件 | `trace → evidence → knowledge → injection` 闭环 | CodeStudio 的知识进化更系统化 |
| **流程确认** | ❌ 无（依赖模型遵守） | ✅ CAP-2 Enforcer + GD+CC 双轴治理 | CodeStudio 有形式化流程确认 |
| **多 CLI 支持** | ✅ 支持（Hermes Agent 是独立 CLI） | ✅ 支持（通过 Harness 抽象层） | 两者都支持，但方式不同 |
| **Hook 系统** | ✅ 有（Python 原生） | ✅ CAP-4 Interceptor（原生集成） | 两者都有，但 CodeStudio 的 Hook 是"治理导向" |
| **工具系统** | ✅ 有（Tool Registry + Toolset） | ✅ 有（通过 MCP 协议接入） | 两者都有，但 CodeStudio 的工具系统更通用（支持多 CLI） |

**核心结论**：

- Hermes Agent 是 **CodeStudio 的底层实现之一**（CodeStudio 可以用 Hermes Agent 作为 Harness 的实现）

- CodeStudio 关注**治理层**，Hermes Agent 关注**执行层**

### 5.2 与 CCGS 的对比

| 维度 | CCGS | Hermes Agent | Hermes Agent 的优势 |
| ------ | ------------ | -------------- | --------------------- |
| **定位** | 应用层模板（游戏开发工作流） | AI Agent 框架（通用） | Hermes Agent 更通用，不绑定特定领域 |
| **Agent 循环** | 依赖 Claude Code | 自己实现（run_agent.py） | Hermes Agent 的 Agent 循环更可控 |
| **工具系统** | 依赖 Claude Code 的内置工具 | 自己实现（model_tools.py + tools/） | Hermes Agent 的工具系统更灵活 |
| **Hook 系统** | bash/powershell 脚本 | Python 原生 | Hermes Agent 的 Hook 系统更易于扩展 |
| **Skill 系统** | Markdown 文件 | `skills/` 目录 | 两者类似，但 Hermes Agent 支持插件 |
| **记忆系统** | 静态（`memory: project/user`） | 动态（Session DB + Memory 插件） | Hermes Agent 的记忆系统更强大 |

### 5.3 与 Claude Code 的对比

| 维度 | Claude Code | Hermes Agent | Hermes Agent 的优势 |
| ------ | ------------- | -------------- | --------------------- |
| **定位** | AI Coding CLI（官方） | AI Agent 框架（第三方） | 定位不同：Claude Code 是"工具"，Hermes Agent 是"框架" |
| **Agent 循环** | TypeScript（bridge/sessionRunner.ts） | Python（run_agent.py） | 两者都有，但 Hermes Agent 更易于扩展 |
| **工具系统** | TypeScript 类（tools/*.ts） | Python 函数（tools/*.py） | 两者都有，但 Hermes Agent 支持自动发现 |
| **Hook 系统** | 4 种类型，13 种事件 | Python 原生 | 两者都有，但 Claude Code 的 Hook 系统更丰富 |
| **Skill 系统** | 3 种来源（bundled/user-defined/plugin） | `skills/` 目录 | 两者都有，但 Claude Code 的 Skill 更丰富 |
| **多平台支持** | 桌面端、Web、VS Code 扩展 | 网关（Telegram、Discord、Slack、...） | 两者都有，但 Hermes Agent 支持更多平台 |

---

## 六、针对 0- 中的问题的解决方案

### 6.1 Q1：知识复用效率低

**Hermes Agent 的解决方案**：

| 机制 | 说明 | 状态 |
| ------ | ------ | ------ |
| **Session DB** | 对话历史，支持 FTS5 搜索 | ✅ 已实现 |
| **Memory 插件** | 跨会话记忆，结构化存储 | ✅ 已实现（honcho, mem0, supermemory, ...） |
| **项目文档** | `.hermes/docs/*.md` | ✅ 已实现 |

**不足**：

- 知识是**静态的**（不会从实践中学习）

- 没有**证据链闭环**（`trace → evidence → knowledge → injection`）

**对 CodeStudio 的启发**：

1. **借鉴**：Session DB（对话历史）

2. **借鉴**：Memory 插件（跨会话记忆）

3. **改进**：实现证据链闭环（系统化学习）

### 6.2 Q2：流程确认依赖人工

**Hermes Agent 的解决方案**：

| 机制 | 说明 | 不足 |
| ------ | ------ | ------ |
| **无** | ❌ Hermes Agent 没有形式化流程确认机制 | 依赖模型遵守（不可靠） |

**对 CodeStudio 的启发**：

1. **实现**：CAP-2 Enforcer（形式化约束检查）

2. **实现**：GD+CC 双轴治理

### 6.3 Q3：知识格式不清晰

**Hermes Agent 的解决方案**：

| 知识类型 | 格式 | 示例 |
| --------- | ------ | ------ |
| **对话历史** | SQLite（hermes_state.py） | Session DB |
| **跨会话记忆** | 取决于 Memory 插件（honcho, mem0, supermemory, ...） | Memory 插件 |
| **项目文档** | `.md` 文件（.hermes/docs/*.md） | 项目特定的知识文档 |

**不足**：

- 知识格式**不统一**（SQLite、Memory 插件、.md 文件）

- 没有**结构化知识格式**（如 JSON Schema）

**对 CodeStudio 的启发**：

1. **定义**：`catalog/` 的目录结构

2. **定义**：knowledge / flows / constraints 的格式规范

3. **改进**：定义结构化的知识格式（JSON Schema）

### 6.4 Q4：缺乏系统性学习

**Hermes Agent 的解决方案**：

| 机制 | 说明 | 状态 |
| ------ | ------ | ------ |
| **无** | ❌ Hermes Agent 没有系统性学习机制 | 不会从实践中学习 |

**对 CodeStudio 的启发**：

1. **实现**：证据链闭环（`trace → evidence → knowledge → injection`）

2. **实现**：`catalog/` 目录结构（结构化知识管理）

### 6.5 Q5：实践验证不足

**Hermes Agent 的解决方案**：

| 机制 | 说明 | 状态 |
| ------ | ------ | ------ |
| **无** | ❌ Hermes Agent 没有实践验证机制 | 难以量化"这个配置的效果如何" |

**对 CodeStudio 的启发**：

1. **实现**：实践验证机制（A/B 测试不同配置）

2. **实现**：量化指标（tool_call 成功率、预算使用效率、用户满意度）

---

## 七、总结与下一步

### 7.1 核心结论

1. **Hermes Agent 是 AI Agent 框架**，实现了可靠的 Agent 循环、工具系统、Hook 系统、Skill 系统、记忆系统

2. **Hermes Agent 的亮点**：Python 原生 Hook、Memory 插件、多平台支持、插件系统

3. **Hermes Agent 的不足**：缺乏形式化治理、缺乏系统性学习、无多 CLI 支持

4. **CodeStudio 可以改进的方向**：在 Hermes Agent 的基础上，增加治理层（CAP-2 Enforcer、证据链闭环、GD+CC 双轴治理）

### 7.2 下一步

| 任务 | 优先级 | 预计时间 |
| ------ | -------- | --------- |
| **① 整合 Hermes Agent 的亮点** | P0 | 1-2 周 |
| **② 实现 CAP-2 Enforcer** | P0 | 1-2 周 |
| **③ 实现证据链闭环** | P0 | 2-3 周 |
| **④ 在 letsgo_server 上验证** | P1 | 立即 |

---

**文档状态**：✅ 第一版完成（主文档 + 子文档结构，总结性输出 + 深入细节拆分）

**子文档列表**：

| 子文档 | 内容 |
| --------- | ------ |
| `1-3-2-hermes-agent-loop.md` | Agent 循环详细分析（run_agent.py，核心循环、中断检查、预算控制） |
| `1-3-3-hermes-tool-system.md` | 工具系统详细分析（model_tools.py + tools/，工具注册、自动发现、执行、错误处理） |
| `1-3-4-hermes-hook-system.md` | Hook 系统详细分析（Python 原生，Hook 类型、触发时机、配置方式） |
| `1-3-5-hermes-skill-system.md` | Skill 系统详细分析（skills/ 目录，Skill 定义、调用方式、与 CCGS/Claude Code 的对比） |
| `1-3-6-hermes-memory-system.md` | 记忆系统详细分析（hermes_state.py + plugins/memory/，记忆类型、注入时机、与 CCGS 的对比） |

**下一步**：

- [ ] 在 letsgo_server 上做真实验证

- [ ] 记录卡点，迭代设计

- [ ] 补全单元测试 + 集成测试
