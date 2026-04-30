# Hermes Agent 学习路线图

> 目标：架构与细节并进，边学边调，每阶段都有可运行的验证点。
>
> 核心方法：**先跑起来 → 打断点看数据 → 读源码理解 → 写笔记 → 改插件验证**

---

## 学习原则

| 原则 | 说明 |
|------|------|
| **先宏观后微观** | 先理解数据流和模块关系，再深入某个函数 |
| **先运行后阅读** | 用调试工具/日志观察行为，带着问题读源码 |
| **先 hook 后修改** | 通过 `plugins/vacky_debug/` 观察，不动核心文件 |
| **每阶段有产出** | 每个阶段结束，mydocs/ 里要有一篇分析笔记 |

---

## Phase 0：环境热身（1 天）

**目标**：确保 hermes 能跑起来，调试工具可用。

### 任务清单

- [ ] 运行 `./scripts/vacky/quick-test.sh` 验证环境
- [ ] 配置 `~/.hermes/config.yaml`（API key、模型选择）
- [ ] 启动 hermes 并发送第一条消息
- [ ] 启用调试模式，验证插件加载

```bash
# 验证环境
./scripts/vacky/quick-test.sh

# 配置 API key
cat > ~/.hermes/.env << 'EOF'
OPENAI_API_KEY=sk-...
EOF

# 启动 hermes
VACKY_DEBUG=1 hermes

# 在 hermes 中测试调试工具
/vacky_inspect_state agent
/vacky_dump_context label=hello_world
```

### 调试重点

- 观察 `vacky_debug` 插件是否自动加载
- 查看 `hermes logs` 中 `vacky.debug` 的日志输出
- 确认 hook 在 `pre_llm_call` 和 `post_tool_call` 时触发

### 产出

- `mydocs/debugging/sessions/2026-04-30-env-setup.md` — 环境配置记录

---

## Phase 1：Agent 核心循环（3-4 天）

**目标**：彻底理解 `AIAgent.run_conversation()` 的执行流程。

### 架构层面

```
用户输入 → AIAgent.chat() → run_conversation()
    → while 循环
        → LLM API 调用
        ← 有 tool_calls?
            → 是: 执行工具 → 结果加入 messages → 继续循环
            → 否: 返回最终回复
```

### 细节层面

| 关注点 | 文件 | 调试方式 |
|--------|------|---------|
| 循环条件 | `run_agent.py` ~line 800+ | 在 hook 中打印 `api_call_count` |
| 消息组装 | `run_agent.py` ~messages 列表 | `vacky_dump_context` 导出 |
| 工具调用解析 | `run_agent.py` ~response.tool_calls | `pre_tool_call` hook |
| 预算控制 | `run_agent.py` ~iteration_budget | 观察 `max_iterations` 递减 |
| 中断机制 | `run_agent.py` ~_interrupt_requested | 发送 Ctrl+C 观察 |

### 调试任务

```bash
# 1. 限制迭代次数，观察循环
# 在 ~/.hermes/config.yaml 中设置：
# agent:
#   max_iterations: 3

# 2. 发送一个会触发工具调用的请求
# 例如："列出当前目录的文件"
# 观察：
#   - pre_llm_call 触发（第一次）
#   - pre_tool_call 触发（LLM 要求调用工具）
#   - post_tool_call 触发（工具返回结果）
#   - pre_llm_call 再次触发（第二次，带工具结果）
#   - 最终返回文本回复

# 3. 导出上下文分析消息流转
/vacky_dump_context label=after_first_tool_call
```

### 源码阅读路线

```
run_agent.py
  ├── AIAgent.__init__()          ← 参数初始化
  ├── AIAgent.chat()              ← 简单接口
  └── AIAgent.run_conversation()  ← 核心循环
        ├── _prepare_messages()   ← 消息组装
        ├── _call_llm()           ← API 调用
        ├── _handle_tool_calls()  ← 工具调用处理
        └── _finalize_response()  ← 结果整理
```

### 产出

- `mydocs/architecture/agent-loop.md` — 完整的循环流程分析
- `mydocs/debugging/sessions/` 下 2-3 次调试记录

---

## Phase 2：工具系统（3-4 天）

**目标**：理解工具如何注册、发现、调用。

### 架构层面

```
tools/*.py 文件
    → 导入时执行 registry.register()
        → 注册到全局 registry
            → model_tools.py 触发 discover_builtin_tools()
                → run_agent.py 获取 tool_schemas 传给 LLM
                    → LLM 返回 tool_calls
                        → handle_function_call() 路由到对应 handler
```

### 细节层面

| 关注点 | 文件 | 调试方式 |
|--------|------|---------|
| 注册机制 | `tools/registry.py` | 打印 `registry._tools` |
| 自动发现 | `tools/registry.py` `discover_builtin_tools()` | 观察导入顺序 |
| Schema 格式 | `tools/*.py` 中的 `registry.register()` | 对比 OpenAI function schema |
| 调用分发 | `model_tools.py` `handle_function_call()` | `pre_tool_call` hook |
| 工具集分组 | `toolsets.py` | `hermes tools` 命令输出 |

### 调试任务

```bash
# 1. 查看所有已注册工具
hermes tools

# 2. 观察某个具体工具的 schema
# 在 vacky_debug/hooks.py 的 pre_tool_call 中打印完整 schema

# 3. 写一个自定义工具验证注册流程
# 创建 tools/my_test_tool.py（临时，学习后删除）
# 观察 hermes 启动时是否自动加载

# 4. 跟踪一次完整的工具调用
# 请求："读取 README.md 的前 10 行"
# 观察：
#   - LLM 如何选择 read_file 工具
#   - handle_function_call 如何路由
#   - 工具结果如何包装回 messages
```

### 源码阅读路线

```
tools/registry.py
  ├── registry.register()         ← 注册入口
  ├── discover_builtin_tools()    ← 自动发现
  └── registry.dispatch()         ← 调用分发

model_tools.py
  ├── get_tool_definitions()      ← 收集 schemas
  └── handle_function_call()      ← 执行路由

toolsets.py
  └── _HERMES_CORE_TOOLS          ← 工具集定义
```

### 产出

- `mydocs/architecture/tool-system.md` — 工具系统完整分析
- 一个临时自定义工具（验证后删除或移到 plugins/）

---

## Phase 3：CLI 架构（2-3 天）

**目标**：理解交互式 CLI 的启动流程和命令系统。

### 架构层面

```
python cli.py
    → HermesCLI.__init__()
        → 加载配置、皮肤、插件
        → 初始化 AIAgent
    → HermesCLI.run()
        → REPL 循环
            → 读取用户输入
            → 解析命令（/ 开头）或消息
            → 调用 agent.chat() 或命令处理器
            → 显示结果
```

### 细节层面

| 关注点 | 文件 | 调试方式 |
|--------|------|---------|
| 配置加载 | `cli.py` `load_cli_config()` | 打印合并后的配置 |
| 命令注册 | `hermes_cli/commands.py` | 查看 `COMMAND_REGISTRY` |
| 皮肤引擎 | `hermes_cli/skin_engine.py` | 切换不同皮肤观察 |
| 输入处理 | `cli.py` REPL 循环 | 打断点观察输入解析 |
| 插件加载 | `hermes_cli/plugins.py` | `discover_plugins()` 日志 |

### 调试任务

```bash
# 1. 观察启动过程
VACKY_DEBUG=1 hermes 2>&1 | head -50

# 2. 测试各种 slash 命令
/help
/tools
/sessions
/config

# 3. 切换皮肤（如果有多个）
# 在 config.yaml 中修改 display.skin

# 4. 观察插件加载顺序
hermes logs --level DEBUG | grep -i plugin
```

### 源码阅读路线

```
cli.py
  ├── HermesCLI.__init__()        ← 初始化
  ├── HermesCLI.run()             ← 主循环
  └── HermesCLI.process_command() ← 命令分发

hermes_cli/commands.py
  └── COMMAND_REGISTRY            ← 命令定义

hermes_cli/skin_engine.py
  └── SkinEngine                  ← 主题系统
```

### 产出

- `mydocs/architecture/cli-architecture.md` — CLI 架构分析

---

## Phase 4：Gateway 消息网关（3-4 天）

**目标**：理解多平台消息接入和会话管理。

### 架构层面

```
用户消息（Telegram/Discord/Slack/...）
    → Gateway 平台适配器
        → 创建/恢复 Session
            → 调用 AIAgent
                → 返回回复
                    → 通过适配器发送回用户
```

### 细节层面

| 关注点 | 文件 | 调试方式 |
|--------|------|---------|
| 平台适配器 | `gateway/platforms/` | 启动不同平台观察 |
| 会话管理 | `gateway/session.py` | 查看 session 数据库 |
| 消息路由 | `gateway/run.py` | `pre_gateway_dispatch` hook |
| Hook 系统 | `gateway/builtin_hooks/` | 观察 hook 触发 |

### 调试任务

```bash
# 1. 启动 gateway（如果配置了平台）
hermes gateway --platform telegram

# 2. 观察 session 数据库
sqlite3 ~/.hermes/sessions.db ".tables"

# 3. 在 vacky_debug/hooks.py 中注册 pre_gateway_dispatch hook
# 观察每条消息的流转
```

### 产出

- `mydocs/architecture/gateway-overview.md` — Gateway 架构分析

---

## Phase 5：TUI 前后端（3-4 天）

**目标**：理解 Ink + Python JSON-RPC 的协作模式。

### 架构层面

```
hermes --tui
    → 启动 Python JSON-RPC 后端 (tui_gateway/server.py)
        → 启动 Ink React 前端 (ui-tui/src/app.tsx)
            → stdio JSON-RPC 通信
                → 前端渲染，后端处理业务
```

### 细节层面

| 关注点 | 文件 | 调试方式 |
|--------|------|---------|
| 进程模型 | `tui_gateway/server.py` | 观察进程树 |
| 消息协议 | JSON-RPC over stdio | 抓包或打印 |
| React 组件 | `ui-tui/src/app.tsx` | 修改观察效果 |
| 主题系统 | `ui-tui/src/theme.ts` | 切换主题 |

### 调试任务

```bash
# 1. 启动 TUI
hermes --tui

# 2. 观察 JSON-RPC 通信
# 在 tui_gateway/server.py 中添加日志

# 3. 修改前端组件验证热更新
cd ui-tui && npm run dev
```

### 产出

- `mydocs/architecture/tui-internals.md` — TUI 架构分析

---

## Phase 6：插件系统深度（2-3 天）

**目标**：彻底掌握插件开发，能够独立扩展 hermes。

### 内容

- 插件生命周期：`register()` → hook 注册 → 运行时触发
- 工具注册：`ctx.register_tool()` 的完整参数
- Hook 类型：所有 `VALID_HOOKS` 的使用场景
- 用户插件 vs Bundled 插件：加载优先级

### 实践任务

- [ ] 给 `vacky_debug` 添加一个新的调试工具
- [ ] 注册一个新的 hook（如 `pre_approval_request`）
- [ ] 写一个独立的插件（如数据统计插件）

### 产出

- `mydocs/architecture/plugin-system.md` — 插件系统深度分析
- 一个功能完整的自定义插件

---

## Phase 7：端到端实战（持续）

**目标**：用所学知识解决实际问题。

### 可选方向

| 方向 | 任务 | 所需知识 |
|------|------|---------|
| 性能优化 | 分析上下文膨胀，优化 token 使用 | Phase 1 + 2 |
| 新平台接入 | 为 Gateway 添加新消息平台 | Phase 4 |
| 工具开发 | 开发一个实用的自定义工具 | Phase 2 + 6 |
| UI 定制 | 修改 TUI 主题或添加组件 | Phase 5 |
| 自动化 | 用 batch_runner 做批量任务 | Phase 1 |

---

## 学习节奏建议

| 时间 | 活动 |
|------|------|
| 每天 1-2 小时 | 读源码 + 做笔记 |
| 每周末 | 跑一遍 `./sync-dev.sh` 保持同步 |
| 每阶段结束 | 写一篇完整的架构分析笔记 |
| 遇到问题时 | 先加 hook 观察，再读源码，最后查文档 |

---

## 调试工具速查

```bash
# 启用调试模式
export VACKY_DEBUG=1

# 在 hermes 中使用
/vacky_inspect_state agent      # 观察 Agent 状态
/vacky_inspect_state cli        # 观察 CLI 状态
/vacky_dump_context label=xxx   # 导出上下文到文件
/vacky_trigger_breakpoint       # 触发 pdb 断点

# 查看日志
hermes logs --follow
hermes logs --level DEBUG
hermes logs --session <id>

# 快速验证
./scripts/vacky/quick-test.sh
```

---

## 笔记模板

每个阶段结束后，在 `mydocs/architecture/` 下创建笔记：

```markdown
# XXX 分析

## 架构图
（用文字或 ASCII 画数据流）

## 关键类/函数
| 名称 | 文件 | 作用 |
|------|------|------|

## 数据流
1. ...
2. ...

## 调试观察
（记录实际运行时的数据）

## 疑问与待办
- [ ] ...
```
