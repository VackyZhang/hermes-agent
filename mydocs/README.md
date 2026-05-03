# Vacky 的 Hermes Agent 学习空间

> 个人学习和调试 hermes-agent 的笔记与实验空间。  
> 本目录随仓库提交，切换环境 `git pull` 即可同步。

---

## 目录结构

```
mydocs/
├── README.md                          ← 本文档（索引 + 环境恢复指南）
├── agent-learning-handbook.md         ← Agent 开发学习与设计手册（一站式）
├── vacky-dev-guide.md                 ← 开发规范与工作流指南
├── naming-conventions.md              ← 术语定义与文件编写规范
│
├── architecture/                      ← 架构分析笔记（按 s1.x/s2.x 编号）
│   ├── s1.1-hermes-first-impression.md ← 阶段1子1: Hermes Agent 环境初体验
│   ├── s1.2-claude-first-impression.md ← 阶段1子2: Claude Code 环境初体验
│   ├── s1.3-hermes-main-loop.svg     ← 阶段1子3: Hermes Agent 主循环泳道图
│   ├── s1.4-claude-main-loop.svg     ← 阶段1子4: Claude Code 主循环泳道图
│   ├── s2.1-agent-loop.md             ← 阶段2子1: AIAgent 核心循环
│   ├── s2.2-cli-architecture.md     ← 阶段2子2: CLI 架构与命令
│   ├── s2.3-claude-tool-design.md    ← 阶段2子3: Claude Code 工具设计精读
│   ├── s2.4-tool-system.md           ← 阶段2子4: 工具注册与调用
│   ├── s2.5-gateway-overview.md     ← 阶段2子5: Gateway 消息网关（占位）
│   ├── s2.6-tui-internals.md        ← 阶段2子6: TUI 前后端（占位）
│   └── s2.7-plugin-system.md         ← 阶段2子7: 插件系统深度
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

按 `agent-learning-handbook.md` 的 5 个阶段推进：

### 阶段 1：建立地图感（1-2周）
| 子阶段 | 目标 | 笔记位置 | 状态 |
|---------|------|---------|------|
| s1.1 | Hermes Agent 环境初体验 | `architecture/s1.1-hermes-first-impression.md` | ⬜ |
| s1.2 | Claude Code 环境初体验 | `architecture/s1.2-claude-first-impression.md` | ⬜ |
| s1.3 | Hermes 主循环泳道图 | `architecture/s1.3-hermes-main-loop.svg` | ⬜ |
| s1.4 | Claude 主循环泳道图 | `architecture/s1.4-claude-main-loop.svg` | ⬜ |

### 阶段 2：框架理解 + 单点突破（3-4个月）
| 子阶段 | 目标 | 笔记位置 | 状态 |
|---------|------|---------|------|
| s2.1 | AIAgent 核心循环 | `architecture/s2.1-agent-loop.md` | ⬜ |
| s2.2 | CLI 架构与命令 | `architecture/s2.2-cli-architecture.md` | ⬜ |
| s2.3 | Claude Code 工具设计精读 | `architecture/s2.3-claude-tool-design.md` | ⬜ |
| s2.4 | Hermes 工具系统精读 | `architecture/s2.4-tool-system.md` | ⬜ |
| s2.5~s2.7 | Gateway/TUI/插件（待补充） | `architecture/` 待创建 | ⬜ |

### 阶段 3：工作流设计 + 领域深化（3-4个月）
| 子阶段 | 目标 | 笔记位置 | 状态 |
|---------|------|---------|------|
| s3.1 | 工作流编排 | `architecture/` 待创建 | ⬜ |
| s3.2 | 领域适配 | `architecture/` 待创建 | ⬜ |
| s3.3 | 多 Agent 协作 | `architecture/` 待创建 | ⬜ |
| s3.4 | 效果评估 | `architecture/` 待创建 | ⬜ |

### 阶段 4：系统整合 + 方法论提炼（4-6个月）
| 子阶段 | 目标 | 笔记位置 | 状态 |
|---------|------|---------|------|
| s4.1 | 系统整合 | `architecture/` 待创建 | ⬜ |
| s4.2 | 方法论提炼 | `architecture/` 待创建 | ⬜ |
| s4.3 | 前沿跟踪 | `architecture/` 待创建 | ⬜ |

### 阶段 5：真实落地迭代（持续）
| 子阶段 | 目标 | 笔记位置 | 状态 |
|---------|------|---------|------|
| s5.1 | StarQuant 迭代 | `experiments/` 下的实际项目 | ⬜ |
| s5.2 | CodeStudio 迭代 | `experiments/` 下的实际项目 | ⬜ |

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

## 环境搭建（新机器）

### 1. 克隆仓库并切换分支

```bash
git clone git@github.com:VackyZhang/hermes-agent.git
cd hermes-agent
git checkout vacky/dev
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
A: `mydocs/` 随仓库提交，只要正常 `git push` 就不会丢失。
换机器后 `git pull` 即可恢复。

### Q: 如何确认 vacky_debug 插件已加载？
A: 运行 `VACKY_DEBUG=1 hermes`，然后输入 `/vacky_inspect_state agent`，有输出即成功。

### Q: sync-dev.sh 报冲突怎么办？
A: 运行 `git diff main --name-only`，如果看到 `agent/`、`tools/`、`cli.py` 等核心文件，说明越界修改了，需要撤销：`git checkout main -- <文件>`

### Q: 虚拟环境需要重新创建吗？
A: `.venv/` 已加入 `.gitignore`，换机器后需要重新创建（见上文步骤 3）。

---

> 最后更新：2026-05-03
> 完整规范见：`vacky-dev-guide.md`、`naming-conventions.md`
