# Vacky 的 Hermes Agent 学习空间

> 个人学习和调试 hermes-agent 的笔记与实验空间。  
> `mydocs/` 已加入 `.gitignore`，所有内容不会被 git 追踪。
>
> **换机器恢复指南**：见本文档末尾「环境恢复」章节。

---

## 目录结构

```
mydocs/
├── README.md                          ← 本文档（索引 + 环境恢复指南）
├── learning-roadmap.md                ← 完整学习路线图（7 个阶段）
├── vacky-dev-guide.md                 ← 开发规范与工作流指南
├── naming-conventions.md              ← 术语定义与文件编写规范
│
├── architecture/                      ← 架构分析笔记（按阶段编号）
│   ├── 01-agent-loop.md               ← Phase 1: AIAgent 核心循环
│   ├── 02-tool-system.md              ← Phase 2: 工具注册与调用
│   ├── 03-cli-architecture.md         ← Phase 3: CLI 架构与命令
│   ├── 04-gateway-overview.md         ← Phase 4: Gateway 消息网关
│   ├── 05-tui-internals.md            ← Phase 5: TUI 前后端
│   └── 06-plugin-system.md            ← Phase 6: 插件系统深度
│
├── debugging/                         ← 调试记录
│   ├── common-issues.md               ← 常见问题汇总（持续更新）
│   ├── session-template.md            ← 调试记录模板
│   └── sessions/                      ← 按日期组织的调试日志
│       └── 2026-04-30-env-setup.md
│
└── experiments/                       ← 实验代码与临时脚本
    └── (临时验证代码)
```

---

## 快速开始（日常）

```bash
# 1. 进入仓库并激活环境
cd hermes-agent
source .venv/bin/activate

# 2. 同步上游（可选）
./sync-upstream.sh
./sync-dev.sh

# 3. 启动 hermes 并启用调试
VACKY_DEBUG=1 hermes

# 4. 在 hermes 中使用调试工具
/vacky_inspect_state agent
/vacky_dump_context label=session_start

# 5. 查看调试日志
hermes logs --level DEBUG | grep vacky
```

---

## 学习路线图

按 `learning-roadmap.md` 的 7 个阶段推进：

| 阶段 | 目标 | 笔记位置 | 状态 |
|------|------|---------|------|
| Phase 0 | 环境热身 | `debugging/sessions/2026-04-30-env-setup.md` | ✅ |
| Phase 1 | Agent 核心循环 | `architecture/01-agent-loop.md` | ⬜ |
| Phase 2 | 工具系统 | `architecture/02-tool-system.md` | ⬜ |
| Phase 3 | CLI 架构 | `architecture/03-cli-architecture.md` | ⬜ |
| Phase 4 | Gateway 网关 | `architecture/04-gateway-overview.md` | ⬜ |
| Phase 5 | TUI 前后端 | `architecture/05-tui-internals.md` | ⬜ |
| Phase 6 | 插件系统深度 | `architecture/06-plugin-system.md` | ⬜ |
| Phase 7 | 端到端实战 | `experiments/` 下的实际项目 | ⬜ |

---

## 核心原则（防冲突）

1. **不动核心源码** —— 不修改 `agent/`, `tools/`, `cli.py`, `run_agent.py`
2. **调试走插件** —— 所有 hook 和工具放在 `plugins/vacky_debug/`
3. **笔记放 mydocs** —— 学习分析记录在这里
4. **实验放 experiments** —— 临时代码和验证脚本
5. **配置放 ~/.hermes** —— 个人配置不进入仓库
6. **术语统一** —— 参考 `naming-conventions.md`

详见：`vacky-dev-guide.md`

---

## 环境恢复（换机器/重装系统）

> `mydocs/` 已 gitignore，**换机器时本文件不会自动同步**。  
> 建议：将 `mydocs/` 放入 iCloud/Dropbox 同步，或定期手动备份。

### 1. 克隆仓库

```bash
git clone git@github.com:VackyZhang/hermes-agent.git
cd hermes-agent
```

### 2. 添加上游仓库

```bash
git remote add upstream https://github.com/NousResearch/hermes-agent.git
git remote -v
# 确认看到 origin 和 upstream
```

### 3. 创建虚拟环境并安装依赖

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -e ".[dev]"
```

### 4. 验证安装

```bash
hermes --version
./scripts/vacky/quick-test.sh
```

### 5. 配置 API Key

```bash
mkdir -p ~/.hermes
cat > ~/.hermes/.env << 'EOF'
OPENAI_API_KEY=sk-your-key-here
EOF
```

### 6. 恢复 mydocs 笔记（手动）

```bash
# 从旧机器复制 mydocs/ 目录，或从云盘同步
# 然后确认结构完整
ls mydocs/architecture/
ls mydocs/debugging/sessions/
```

### 7. 确认 vacky/dev 分支

```bash
git checkout vacky/dev
# 确认插件和脚本都在
git log --oneline -3
```

---

## 关键命令速查

```bash
# 环境
source .venv/bin/activate

# 同步
./sync-upstream.sh          # upstream → 本地 main → origin main
./sync-dev.sh               # main → vacky/dev

# 启动
VACKY_DEBUG=1 hermes        # 启用调试模式
hermes --tui                # TUI 模式

# 日志
hermes logs --follow
hermes logs --level DEBUG
hermes logs --session <id>

# 验证
./scripts/vacky/quick-test.sh

# Git 检查
git status
git diff main --name-only    # 检查是否越界修改核心文件

# 插件验证
python3 -c "from hermes_cli.plugins import discover_plugins; discover_plugins()"
```

---

## 常见问题

### Q: mydocs/ 笔记会丢失吗？
A: `mydocs/` 已 gitignore，**不会随 git 同步**。建议：
- 使用 iCloud/Dropbox 同步整个 `mydocs/` 目录
- 或定期 `tar czf mydocs-backup-$(date +%Y%m%d).tar.gz mydocs/`

### Q: 如何确认 vacky_debug 插件已加载？
A: 运行 `VACKY_DEBUG=1 hermes`，然后输入 `/vacky_inspect_state agent`，有输出即成功。

### Q: sync-dev.sh 报冲突怎么办？
A: 运行 `git diff main --name-only`，如果看到 `agent/`、`tools/`、`cli.py` 等核心文件，说明越界修改了，需要撤销：`git checkout main -- <文件>`

### Q: 虚拟环境需要重新创建吗？
A: `.venv/` 已加入 `.gitignore`，换机器后需要重新创建（见上文步骤 3）。

---

> 最后更新：2026-04-30  
> 完整规范见：`vacky-dev-guide.md`、`naming-conventions.md`
