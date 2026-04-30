# Hermes Agent 学习与调试指南（零冲突工作流）

> 目标：在 `vacky/dev` 分支上自由学习、调试、实验，同时保证 `main` 同步时永远零冲突。
>
> 核心原则：**核心源码只读，扩展通过插件/配置/外部脚本实现。**

---

## 1. 目录结构约定

```
hermes-agent/
├── mydocs/                          ← 你的领地（已 gitignore，不会进 git）
│   ├── vacky-dev-guide.md           ← 本文档
│   ├── architecture-notes.md        ← 源码分析笔记
│   ├── debug-log.md                 ← 调试过程记录
│   └── scratch/                     ← 临时实验代码
│
├── plugins/vacky_debug/             ← 调试插件（git 追踪，但永远不会与上游冲突）
│   ├── __init__.py                  ← 插件入口
│   ├── hooks.py                     ← 自定义 hook / monkey-patch
│   └── utils.py                     ← 调试工具函数
│
├── scripts/vacky/                   ← 你的辅助脚本（git 追踪，新目录无冲突）
│   └── quick-test.sh                ← 本地验证脚本
│
└── .hermes/                         ← 运行时配置（不在仓库中）
    ├── config.yaml                  ← 个人配置
    └── .env                         ← API 密钥
```

---

## 2. 核心文件黑名单（绝对不要直接修改）

以下文件/目录是上游高频更新区域，**任何直接修改都会导致后续 merge/rebase 冲突**。

```
❌ agent/                    ← Agent 核心逻辑
❌ tools/                    ← 工具实现（除新增文件外）
❌ cli.py                    ← CLI 入口
❌ run_agent.py              ← Agent 主循环
❌ model_tools.py            ← 工具编排
❌ toolsets.py               ← 工具集定义
❌ hermes_state.py           ← 状态管理
❌ gateway/                  ← Gateway 核心代码
❌ ui-tui/                   ← TUI 前端（除新增组件外）
❌ tui_gateway/              ← TUI 后端
❌ acp_adapter/              ← ACP 适配器
❌ environments/             ← 环境实现
❌ tests/                    ← 测试文件
❌ pyproject.toml            ← 依赖配置
❌ setup.py / setup.cfg      ← 包配置
```

**允许修改的模式：**

| 场景 | 正确做法 | 错误做法 |
|------|---------|---------|
| 加日志/打印 | 在 `plugins/vacky_debug/` 里加 hook | 在 `run_agent.py` 里加 `print()` |
| 改配置 | 编辑 `~/.hermes/config.yaml` | 修改 `cli-config.yaml.example` |
| 加新工具 | 创建 `tools/my_tool.py` + `registry.register()` | 修改 `tools/registry.py` |
| 加新技能 | 创建 `skills/my-skill/` 目录 | 修改 `skills/` 下已有文件 |
| 调 CLI 主题 | 修改 `~/.hermes/config.yaml` 的 `display.skin` | 修改 `hermes_cli/skin_engine.py` |
| 实验性代码 | 放 `mydocs/scratch/` | 直接改核心文件 |

---

## 3. 调试插件开发（推荐方式）

### 3.1 创建插件骨架

```bash
mkdir -p plugins/vacky_debug
```

创建 `plugins/vacky_debug/__init__.py`：

```python
"""
vacky_debug - 个人调试插件

所有调试逻辑集中在这里，不修改任何核心文件。
加载方式：hermes 启动时自动扫描 plugins/ 目录
"""

import logging
import os

logger = logging.getLogger("vacky.debug")

# 通过环境变量控制是否启用调试模式
VACKY_DEBUG = os.getenv("VACKY_DEBUG", "").lower() in ("1", "true", "yes")

if VACKY_DEBUG:
    logger.info("[vacky_debug] 调试模式已启用")
    # 在这里挂载你的调试逻辑
    _install_hooks()


def _install_hooks():
    """安装调试 hook，示例：拦截 AIAgent.chat"""
    try:
        from run_agent import AIAgent
        original_chat = AIAgent.chat

        def patched_chat(self, message: str) -> str:
            logger.info(f"[DEBUG] AIAgent.chat 被调用，message 长度: {len(message)}")
            result = original_chat(self, message)
            logger.info(f"[DEBUG] AIAgent.chat 返回，result 长度: {len(result)}")
            return result

        AIAgent.chat = patched_chat
        logger.info("[vacky_debug] AIAgent.chat 已挂接调试 hook")
    except Exception as e:
        logger.warning(f"[vacky_debug] 挂接 hook 失败: {e}")
```

### 3.2 启用调试模式

```bash
VACKY_DEBUG=1 hermes
# 或
export VACKY_DEBUG=1
hermes
```

### 3.3 插件不会冲突的原因

- `plugins/vacky_debug/` 是**全新的目录**，上游没有这个目录
- 即使上游以后加了 `plugins/` 下的其他内容，也不会和你的目录冲突
- 你的插件通过 `import` 和 monkey-patch 工作，**不修改任何已有文件**

---

## 4. 学习笔记管理

### 4.1 笔记目录结构

```
mydocs/
├── README.md                      ← 索引
├── vacky-dev-guide.md             ← 本文档
├── architecture/                  ← 架构分析
│   ├── agent-loop.md              ← run_agent.py 分析
│   ├── tool-system.md             ← 工具系统分析
│   └── cli-architecture.md        ← CLI 架构分析
├── debugging/                     ← 调试记录
│   ├── session-2026-04-30.md      ← 某次调试记录
│   └── common-issues.md           ← 常见问题汇总
└── scratch/                       ← 临时实验
    └── experiment-cli-parser.py   ← 随手写的测试脚本
```

### 4.2 笔记规范（建议）

```markdown
# 文件名: mydocs/architecture/agent-loop.md

## 分析对象
run_agent.py:AIAgent.run_conversation()

## 核心流程
1. while 循环检查 budget 和 iteration
2. 调用 client.chat.completions.create()
3. 处理 tool_calls → handle_function_call()
4. 组装 messages 返回

## 关键断点（如需调试）
- 第 XXX 行: response 解析后
- 第 YYY 行: tool_result 组装前

## 相关文件
- model_tools.py: handle_function_call()
- toolsets.py: _HERMES_CORE_TOOLS
```

### 4.3 mydocs 已 gitignore

```bash
cat .gitignore | grep mydocs
# mydocs/
```

**`mydocs/` 下的所有内容不会被 git 追踪**，你可以随意写、随意删，不会影响仓库状态。

---

## 5. 配置管理

### 5.1 个人配置位置

```bash
~/.hermes/
├── config.yaml          ← 主配置文件（优先级高于仓库默认值）
├── .env                 ← API 密钥
└── logs/                ← 日志文件
```

### 5.2 常用调试配置

编辑 `~/.hermes/config.yaml`：

```yaml
# 日志级别调低，方便调试
logging:
  level: DEBUG
  file_level: DEBUG

# CLI 显示更多细节
display:
  show_tool_calls: true
  show_token_usage: true

# 限制迭代次数，快速验证
agent:
  max_iterations: 5

# 启用特定工具集做验证
tools:
  enabled:
    - core
    - vacky_debug
```

### 5.3 为什么配置放 ~/.hermes 而不是仓库里

- 仓库里的 `cli-config.yaml.example` 是模板，会被上游更新覆盖
- `~/.hermes/config.yaml` 是个人覆盖配置，**不在 git 追踪中**，永远无冲突
- hermes 的加载顺序：`默认值` → `仓库配置` → `~/.hermes/config.yaml`，后者优先级最高

---

## 6. 本地验证脚本

创建 `scripts/vacky/quick-test.sh`：

```bash
#!/bin/bash
# 快速验证脚本，测试特定功能

set -e

echo ">>> 运行 hermes CLI 版本检查"
python -m hermes_cli --version

echo ">>> 运行特定工具的单元测试"
python -m pytest tests/unit/tools/test_registry.py -v -x

echo ">>> 启动 hermes 并执行简单命令（限时 10 秒）"
timeout 10s python run_agent.py --quick-test || true

echo ">>> 验证完成"
```

```bash
chmod +x scripts/vacky/quick-test.sh
```

---

## 7. 日常工作流（记住这三步）

```bash
# 第一步：同步上游到 main（在任意分支运行）
./sync-upstream.sh

# 第二步：把 main 同步到 vacky/dev（在任意分支运行）
./sync-dev.sh

# 第三步：启动 hermes 做验证
VACKY_DEBUG=1 hermes
```

### 7.1 学习和调试时

```bash
# 读源码时，在 mydocs/ 里做笔记
vim mydocs/architecture/agent-loop.md

# 需要调试时，写插件
vim plugins/vacky_debug/hooks.py

# 调配置
vim ~/.hermes/config.yaml

# 验证改动
VACKY_DEBUG=1 python run_agent.py
```

### 7.2 提交改动时

```bash
# 查看你改了什么（应该只有 plugins/ 和 scripts/vacky/）
git status

# 提交插件更新
git add plugins/vacky_debug/
git add scripts/vacky/
git commit -m "debug: 添加 XX 调试 hook"

# 推送
git push origin vacky/dev
```

---

## 8. 冲突自查清单

在运行 `./sync-dev.sh` 前，检查以下内容：

```bash
# 查看你是否不小心改了核心文件
git diff main --name-only

# 输出应该只包含：
# plugins/vacky_debug/...
# scripts/vacky/...
# 如果有 agent/ tools/ cli.py 等，说明越界了，需要撤销
```

### 撤销误修改

```bash
# 撤销对某个核心文件的修改
git checkout main -- run_agent.py

# 撤销所有核心文件的修改（保留你的插件和脚本）
git checkout main -- agent/ tools/ cli.py run_agent.py model_tools.py
```

---

## 9. 总结：零冲突黄金法则

| 法则 | 说明 |
|------|------|
| **不动核心源码** | `agent/` `tools/` `cli.py` `run_agent.py` 等只读 |
| **调试走插件** | 所有 hook/monkey-patch 放 `plugins/vacky_debug/` |
| **笔记放 mydocs** | `mydocs/` 已 gitignore，随意写 |
| **配置放 ~/.hermes** | 个人配置不进入仓库 |
| **脚本放 scripts/vacky/** | 辅助脚本集中管理 |
| **频繁同步** | 每周跑 `./sync-dev.sh`，单次变更量小 |

**只要遵守以上法则，`./sync-dev.sh` 永远不会遇到冲突。**

---

## 附录：常用命令速查

```bash
# 查看分支状态
git branch -vv

# 查看与 main 的差异文件
git diff main --name-only

# 查看具体文件的差异
git diff main -- plugins/vacky_debug/

# 临时保存当前工作
git stash push -m "debug wip"

# 恢复暂存
git stash pop

# 查看插件是否被加载
VACKY_DEBUG=1 hermes 2>&1 | grep vacky_debug

# 查看日志
hermes logs --follow
```
