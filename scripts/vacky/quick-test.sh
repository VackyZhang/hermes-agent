#!/bin/bash
#
# quick-test.sh — 快速验证脚本
#
# 用于在修改后快速验证 hermes-agent 的基本功能是否正常，
# 以及 vacky_debug 插件是否正确加载。
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[TEST]${NC}  $*"; }
ok()    { echo -e "${GREEN}[PASS]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[FAIL]${NC}  $*"; }

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

info "工作目录: $REPO_ROOT"
echo ""

# ─────────────────────────────────────────
# 1. 检查 Python 环境
# ─────────────────────────────────────────
info "检查 Python 环境..."
python --version || { err "Python 未安装"; exit 1; }
ok "Python 版本: $(python --version 2>&1)"

# ─────────────────────────────────────────
# 2. 检查虚拟环境
# ─────────────────────────────────────────
info "检查虚拟环境..."
if [ -f ".venv/bin/activate" ]; then
    ok "找到 .venv"
elif [ -f "venv/bin/activate" ]; then
    ok "找到 venv"
else
    warn "未找到虚拟环境，尝试使用系统 Python"
fi

# ─────────────────────────────────────────
# 3. 检查核心文件是否存在
# ─────────────────────────────────────────
info "检查核心文件..."
for f in run_agent.py cli.py model_tools.py tools/registry.py; do
    if [ -f "$f" ]; then
        ok "$f 存在"
    else
        err "$f 缺失"
        exit 1
    fi
done

# ─────────────────────────────────────────
# 4. 检查 vacky_debug 插件结构
# ─────────────────────────────────────────
info "检查 vacky_debug 插件..."
for f in plugins/vacky_debug/__init__.py plugins/vacky_debug/plugin.yaml plugins/vacky_debug/hooks.py plugins/vacky_debug/tools.py; do
    if [ -f "$f" ]; then
        ok "$f 存在"
    else
        err "$f 缺失"
        exit 1
    fi
done

# ─────────────────────────────────────────
# 5. 尝试导入插件（不启动 hermes）
# ─────────────────────────────────────────
info "验证插件可导入..."
python -c "
import sys
sys.path.insert(0, '$REPO_ROOT')
try:
    from plugins.vacky_debug import register
    print('✓ register() 函数存在')
    from plugins.vacky_debug.hooks import get_stats
    print('✓ hooks 模块可导入')
    from plugins.vacky_debug.tools import _handle_vacky_inspect_state
    print('✓ tools 模块可导入')
    print('所有插件模块导入成功')
except Exception as e:
    print(f'导入失败: {e}')
    sys.exit(1)
" || { err "插件导入失败"; exit 1; }

ok "插件导入验证通过"

# ─────────────────────────────────────────
# 6. 检查 hermes 命令（可选）
# ─────────────────────────────────────────
info "检查 hermes 命令..."
if command -v hermes &> /dev/null; then
    ok "hermes 命令可用"
    hermes --version 2>/dev/null || warn "hermes --version 失败"
else
    warn "hermes 命令未安装到 PATH，尝试从仓库直接运行..."
    python -c "import cli" 2>/dev/null && ok "cli.py 可直接导入" || warn "cli.py 导入失败"
fi

# ─────────────────────────────────────────
# 7. 检查日志目录
# ─────────────────────────────────────────
info "检查日志目录..."
HERMES_LOGS="$HOME/.hermes/logs"
if [ -d "$HERMES_LOGS" ]; then
    ok "日志目录: $HERMES_LOGS"
    ls -la "$HERMES_LOGS" | tail -5
else
    warn "日志目录不存在: $HERMES_LOGS"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "快速验证通过！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "后续操作："
echo "  1. 启动 hermes:         VACKY_DEBUG=1 hermes"
echo "  2. 测试调试工具:        /vacky_inspect_state agent"
echo "  3. 查看调试日志:        hermes logs --follow"
echo "  4. 同步上游:            ./sync-upstream.sh"
echo "  5. 同步到 dev:          ./sync-dev.sh"
