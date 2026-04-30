#!/bin/bash
#
# sync-upstream.sh — 从 NousResearch/hermes-agent 同步最新 main 到本地及你的 fork
#
# 特性：
#   - 可重入：多次运行不会报错
#   - 幂等：remote 已存在则跳过配置
#   - 安全：只在 main 分支上 fast-forward，不会破坏你的 vacky/dev
#
# 用法：
#   chmod +x sync-upstream.sh
#   ./sync-upstream.sh
#

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

UPSTREAM_URL="https://github.com/NousResearch/hermes-agent.git"
UPSTREAM_NAME="upstream"
ORIGIN_NAME="origin"
MAIN_BRANCH="main"
DEV_BRANCH="vacky/dev"

# ─────────────────────────────────────────
# 1. 检查是否在 git 仓库内
# ─────────────────────────────────────────
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    err "当前目录不是 git 仓库，请在 hermes-agent 仓库根目录运行此脚本"
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"
info "工作目录: $REPO_ROOT"

# ─────────────────────────────────────────
# 2. 配置 remote（可重入：已存在则跳过）
# ─────────────────────────────────────────
info "检查 remote 配置..."

# 配置 upstream
if git remote get-url "$UPSTREAM_NAME" > /dev/null 2>&1; then
    EXISTING_URL=$(git remote get-url "$UPSTREAM_NAME")
    if [ "$EXISTING_URL" = "$UPSTREAM_URL" ] || [ "$EXISTING_URL" = "${UPSTREAM_URL%.git}" ]; then
        ok "remote '$UPSTREAM_NAME' 已配置: $EXISTING_URL"
    else
        warn "remote '$UPSTREAM_NAME' URL 不匹配，更新为 $UPSTREAM_URL"
        git remote set-url "$UPSTREAM_NAME" "$UPSTREAM_URL"
    fi
else
    info "添加 remote '$UPSTREAM_NAME': $UPSTREAM_URL"
    git remote add "$UPSTREAM_NAME" "$UPSTREAM_URL"
    ok "remote '$UPSTREAM_NAME' 添加成功"
fi

# 检查 origin 是否存在（你的 fork）
if ! git remote get-url "$ORIGIN_NAME" > /dev/null 2>&1; then
    err "remote '$ORIGIN_NAME' 不存在！请先关联你的 fork:"
    err "  git remote add origin git@github.com:你的用户名/hermes-agent.git"
    exit 1
fi

ORIGIN_URL=$(git remote get-url "$ORIGIN_NAME")
ok "remote '$ORIGIN_NAME' 已配置: $ORIGIN_URL"

# ─────────────────────────────────────────
# 3. 拉取 upstream 最新内容
# ─────────────────────────────────────────
info "拉取 upstream 最新内容..."
git fetch "$UPSTREAM_NAME" "$MAIN_BRANCH"
ok "upstream/$MAIN_BRANCH 已更新到最新"

# ─────────────────────────────────────────
# 4. 保存当前分支名，后续恢复
# ─────────────────────────────────────────
CURRENT_BRANCH=$(git branch --show-current)
info "当前分支: $CURRENT_BRANCH"

# ─────────────────────────────────────────
# 5. 更新本地 main 分支
# ─────────────────────────────────────────
info "更新本地 $MAIN_BRANCH 分支..."

# 确保本地有 main 分支
if ! git show-ref --verify --quiet "refs/heads/$MAIN_BRANCH"; then
    info "本地不存在 $MAIN_BRANCH 分支，从 upstream/main 创建"
    git checkout -b "$MAIN_BRANCH" "$UPSTREAM_NAME/$MAIN_BRANCH"
else
    git checkout "$MAIN_BRANCH"
    # 检查是否能 fast-forward
    LOCAL_HASH=$(git rev-parse "$MAIN_BRANCH")
    UPSTREAM_HASH=$(git rev-parse "$UPSTREAM_NAME/$MAIN_BRANCH")

    if [ "$LOCAL_HASH" = "$UPSTREAM_HASH" ]; then
        ok "本地 $MAIN_BRANCH 已是最新 (commit: ${LOCAL_HASH:0:8})"
    else
        # 检查是否可以 fast-forward（本地没有额外提交）
        if git merge-base --is-ancestor "$MAIN_BRANCH" "$UPSTREAM_NAME/$MAIN_BRANCH"; then
            git merge --ff-only "$UPSTREAM_NAME/$MAIN_BRANCH"
            ok "本地 $MAIN_BRANCH 已 fast-forward 到最新 (commit: ${UPSTREAM_HASH:0:8})"
        else
            warn "本地 $MAIN_BRANCH 有上游没有的提交，无法 fast-forward"
            warn "如果你确定要覆盖为 upstream 版本，可以手动执行:"
            warn "  git checkout $MAIN_BRANCH && git reset --hard upstream/$MAIN_BRANCH"
            exit 1
        fi
    fi
fi

# ─────────────────────────────────────────
# 6. 推送更新到你的 fork (origin/main)
# ─────────────────────────────────────────
info "推送 $MAIN_BRANCH 到你的 fork..."
git push "$ORIGIN_NAME" "$MAIN_BRANCH"
ok "origin/$MAIN_BRANCH 已同步"

# ─────────────────────────────────────────
# 7. 恢复原来的分支
# ─────────────────────────────────────────
if [ "$CURRENT_BRANCH" != "$MAIN_BRANCH" ]; then
    git checkout "$CURRENT_BRANCH"
    ok "已切回分支: $CURRENT_BRANCH"
fi

# ─────────────────────────────────────────
# 8. 提示 vacky/dev 的同步
# ─────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "同步完成！本地 main 和 origin/main 都已是最新"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检查 vacky/dev 是否需要更新
if git show-ref --verify --quiet "refs/heads/$DEV_BRANCH"; then
    DEV_BASE=$(git merge-base "$DEV_BRANCH" "$MAIN_BRANCH")
    MAIN_HASH=$(git rev-parse "$MAIN_BRANCH")

    if [ "$DEV_BASE" != "$MAIN_HASH" ]; then
        echo ""
        warn "你的 '$DEV_BRANCH' 分支可能落后于最新的 main"
        info "如需同步，请执行:"
        echo -e "  ${GREEN}git checkout $DEV_BRANCH${NC}"
        echo -e "  ${GREEN}git rebase $MAIN_BRANCH${NC}  # 或 git merge $MAIN_BRANCH"
    else
        ok "'$DEV_BRANCH' 已基于最新的 main"
    fi
else
    info "未检测到 '$DEV_BRANCH' 分支。如需创建:"
    echo -e "  ${GREEN}git checkout -b $DEV_BRANCH $MAIN_BRANCH${NC}"
fi

echo ""
info "你的 main 分支永远是上游的干净镜像，你的开发在 $DEV_BRANCH 上进行"
info "两者独立，互不影响。"
