#!/bin/bash
#
# sync-dev.sh — 一键同步：upstream → main → vacky/dev
#
# 使用方式：
#   ./sync-dev.sh
#
# 行为：
#   1. 调用 sync-upstream.sh（如果 main 已是最新则自动跳过实际网络操作）
#   2. 将 vacky/dev rebase 到最新 main
#   3. force push 到 origin
#
# 结束后自动切回原来的分支。
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

DEV_BRANCH="vacky/dev"
MAIN_BRANCH="main"

# ── 检查 git 仓库 ──
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    err "当前目录不是 git 仓库"
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

CURRENT_BRANCH=$(git branch --show-current)
info "当前分支: $CURRENT_BRANCH"

# ── 1. 确保 main 是最新 ──
info "步骤 1/3: 确保 main 是最新..."
if [ -f "$REPO_ROOT/sync-upstream.sh" ]; then
    "$REPO_ROOT/sync-upstream.sh"
else
    err "未找到 sync-upstream.sh"
    exit 1
fi
echo ""

# ── 2. 确认 vacky/dev 存在 ──
if ! git show-ref --verify --quiet "refs/heads/$DEV_BRANCH"; then
    err "本地不存在 '$DEV_BRANCH' 分支"
    info "如需创建: git checkout -b $DEV_BRANCH $MAIN_BRANCH"
    exit 1
fi

# ── 3. 检查 dev 是否已是最新 ──
MAIN_HASH=$(git rev-parse "$MAIN_BRANCH")
DEV_BASE=$(git merge-base "$DEV_BRANCH" "$MAIN_BRANCH")

if [ "$DEV_BASE" = "$MAIN_HASH" ]; then
    ok "'$DEV_BRANCH' 已经基于最新的 main，无需更新"
    if [ "$CURRENT_BRANCH" != "$DEV_BRANCH" ]; then
        git checkout "$CURRENT_BRANCH" 2>/dev/null || true
    fi
    exit 0
fi

BEHIND_COUNT=$(git rev-list --count "$DEV_BASE..$MAIN_HASH")
info "'$DEV_BRANCH' 落后 main $BEHIND_COUNT 个提交，开始同步..."

# ── 4. rebase dev 到 main ──
info "步骤 2/3: rebase '$DEV_BRANCH' 到 '$MAIN_BRANCH'..."
git checkout "$DEV_BRANCH"

if git rebase "$MAIN_BRANCH"; then
    ok "rebase 完成"
else
    err "rebase 遇到冲突，请手动解决后执行:"
    err "  git add ."
    err "  git rebase --continue"
    err "完成后推送: git push origin $DEV_BRANCH --force-with-lease"
    exit 1
fi

# ── 5. 推送到 origin ──
info "步骤 3/3: 推送到 origin..."
if git push origin "$DEV_BRANCH" --force-with-lease; then
    ok "已推送 '$DEV_BRANCH' 到 origin"
else
    warn "推送失败，请检查远程状态"
    exit 1
fi

# ── 6. 恢复原来的分支 ──
if [ "$CURRENT_BRANCH" != "$DEV_BRANCH" ]; then
    git checkout "$CURRENT_BRANCH"
    ok "已切回分支: $CURRENT_BRANCH"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "同步完成！$DEV_BRANCH 已更新到最新 main"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
