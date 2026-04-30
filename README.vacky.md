# Vacky 的 Hermes Agent 开发环境指南

> 这是个人 Fork 的开发环境快速恢复指南。  
> 换机器或重装环境时，按此文档操作即可恢复完整工作流。

---

## 1. 环境要求

- **OS**: macOS / Linux / WSL2
- **Python**: >= 3.11（推荐 3.14）
- **Git**: 已配置 SSH key 到 GitHub

---

## 2. 首次初始化（新机器）

### 2.1 克隆你的 Fork

```bash
git clone git@github.com:VackyZhang/hermes-agent.git
cd hermes-agent
```

### 2.2 添加上游仓库

```bash
git remote add upstream https://github.com/NousResearch/hermes-agent.git
git remote -v
# 应该看到 origin（你的 fork）和 upstream（源仓库）
```

### 2.3 创建虚拟环境并安装依赖

```bash
# 创建虚拟环境
python3 -m venv .venv

# 激活（每次工作前都需要）
source .venv/bin/activate

# 升级 pip
pip install --upgrade pip

# 安装 hermes-agent 及所有开发依赖
pip install -e ".[dev]"
```

### 2.4 验证安装

```bash
# 检查版本
hermes --version

# 验证插件加载
python3 -c "
from hermes_cli.plugins import discover_plugins
from tools.registry import registry
discover_plugins()
print('vacky tools:', [t for t in registry._tools.keys() if 'vacky' in t])
"
# 预期输出：vacky tools: ['vacky_inspect_state', 'vacky_dump_context', 'vacky_trigger_breakpoint']
```

### 2.5 配置 API Key（必需）

```bash
mkdir -p ~/.hermes
cat > ~/.hermes/.env << 'EOF'
OPENAI_API_KEY=sk-your-key-here
# 或其他提供商的 key
EOF
```

---

## 3. 日常开发工作流

### 3.1 启动工作

```bash
cd hermes-agent
source .venv/bin/activate
```

### 3.2 同步上游更新

```bash
# 同步 upstream/main → 本地 main → origin main
./sync-upstream.sh

# 将 main 同步到 vacky/dev
./sync-dev.sh
```

### 3.3 启动 hermes 并启用调试

```bash
VACKY_DEBUG=1 hermes
```

在 hermes 中使用调试工具：
```
/vacky_inspect_state agent
/vacky_dump_context label=session_start
/vacky_trigger_breakpoint
```

### 3.4 查看日志

```bash
# 实时跟踪
hermes logs --follow

# 只看 DEBUG 级别
hermes logs --level DEBUG

# 过滤 vacky 相关
hermes logs --level DEBUG | grep vacky
```

### 3.5 快速验证脚本

```bash
# 运行环境检查
./scripts/vacky/quick-test.sh
```

---

## 4. 目录结构说明

```
hermes-agent/
├── .venv/                    ← 虚拟环境（不提交）
├── mydocs/                   ← 个人笔记（已 gitignore）
│   ├── learning-roadmap.md   ← 学习路线图
│   ├── naming-conventions.md ← 术语定义与规范
│   ├── architecture/         ← 架构分析笔记
│   ├── debugging/            ← 调试记录
│   └── experiments/          ← 实验代码
│
├── plugins/vacky_debug/      ← 调试插件（已提交到 git）
├── scripts/vacky/            ← 辅助脚本
├── sync-upstream.sh          ← 同步上游脚本
├── sync-dev.sh               ← 同步 dev 分支脚本
└── ...（上游源码，只读）
```

---

## 5. 分支策略

| 分支 | 用途 | 操作 |
|------|------|------|
| `main` | 上游镜像 | 只运行 `./sync-upstream.sh`，**从不直接修改** |
| `vacky/dev` | 开发分支 | 所有学习、调试、实验在此进行 |

**核心原则**：核心源码（`agent/`, `tools/`, `cli.py`, `run_agent.py` 等）**只读**，所有调试通过 `plugins/vacky_debug/` 实现。

---

## 6. 常见问题

### Q: 换机器后需要重新配置什么？
A: 只需执行「2. 首次初始化」的全部步骤，然后复制 `~/.hermes/.env` 中的 API key。

### Q: mydocs/ 里的笔记会丢失吗？
A: `mydocs/` 已加入 `.gitignore`，**不会随 git 同步**。换机器时需要手动复制，或使用云盘同步。

### Q: 如何确认 vacky_debug 插件已加载？
A: 运行 `VACKY_DEBUG=1 hermes`，然后输入 `/vacky_inspect_state agent`，如果有输出则加载成功。

### Q: sync-dev.sh 报冲突怎么办？
A: 检查是否修改了核心文件。运行 `git diff main --name-only`，如果看到 `agent/`、`tools/`、`cli.py` 等，说明越界了，需要撤销。

---

## 7. 学习路线图速查

按 `mydocs/learning-roadmap.md` 推进：

| 阶段 | 目标 | 笔记位置 |
|------|------|---------|
| Phase 0 | 环境验证 | `mydocs/debugging/sessions/2026-04-30-env-setup.md` |
| Phase 1 | Agent 核心循环 | `mydocs/architecture/01-agent-loop.md` |
| Phase 2 | 工具系统 | `mydocs/architecture/02-tool-system.md` |
| Phase 3 | CLI 架构 | `mydocs/architecture/03-cli-architecture.md` |
| Phase 4 | Gateway 网关 | `mydocs/architecture/04-gateway-overview.md` |
| Phase 5 | TUI 前后端 | `mydocs/architecture/05-tui-internals.md` |
| Phase 6 | 插件系统深度 | `mydocs/architecture/06-plugin-system.md` |
| Phase 7 | 端到端实战 | `mydocs/experiments/` |

---

## 8. 关键命令速查

```bash
# 环境
source .venv/bin/activate

# 同步
./sync-upstream.sh
./sync-dev.sh

# 启动
VACKY_DEBUG=1 hermes

# 日志
hermes logs --follow
hermes logs --level DEBUG

# 验证
./scripts/vacky/quick-test.sh

# Git
git status
git diff main --name-only    # 检查是否越界修改核心文件
```

---

> 最后更新：2026-04-30  
> 如有问题，参考 `mydocs/vacky-dev-guide.md` 或 `mydocs/naming-conventions.md`
