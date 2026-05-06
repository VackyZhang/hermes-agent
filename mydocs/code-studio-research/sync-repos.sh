#!/usr/bin/env bash
# sync-repos.sh
# 同步/拉取 Code Studio 研究相关的 Git 仓库
# 用法: bash sync-repos.sh
#
# 行为说明:
#   - 若本地目录已存在且是 git 仓库 → git pull（更新）
#   - 若本地目录不存在 → git clone（拉取）
#   - 若本地目录存在但不是 git 仓库 → 报错，跳过

set -euo pipefail

# ============================================================
# 自动检测 Root 路径（支持 Linux 服务器 / macOS）
# ============================================================
case "$(uname -s)" in
  Darwin) ROOT="/Users/vacky/VackyAI" ;;
  Linux)  ROOT="/data/vacky/VackyAI" ;;
  *)
    echo "不支持的系统: $(uname -s)"
    exit 1
    ;;
esac

# ============================================================
# 仓库配置
# 格式: "相对路径|远程地址|仓库说明"（相对路径会自动拼接 ROOT）
# ============================================================
REPOS=(
  "andrej-karpathy-skills|https://github.com/forrestchang/andrej-karpathy-skills.git|Andrej Karpathy 系列技术技能资料整理，涵盖 LLM、神经网络等学习资源"
  "ClaudeCode|git@github.com:VackyZhang/ClaudeCode.git|ClaudeCode 项目：基于 Claude 的 AI 编程助手核心实现，包含工具系统、Hook 机制、技能系统等"
  "Claude-Code-Game-Studios|https://github.com/Donchitos/Claude-Code-Game-Studios.git|Claude Code Game Studios：以游戏化方式构建 Claude Code 的多智能体协作框架，包含导演门控、Agent 编排等设计"
  "CodeStudio|git@github.com:VackyZhang/CodeStudio.git|CodeStudio：Vacky 主导的 AI 编程工作室项目，研究 N+M 架构、Trace 机制、GD 治理等核心设计"
  "mugc_server_ai_tools|https://git.woa.com/MUGC/mugc_server_ai_tools.git|MUGC 服务端 AI 工具集：腾讯 MUGC 团队的 AI 辅助工具，包含 Agent、命令系统、OpenSpec 等实践"
  "skills|https://github.com/mattpocock/skills.git|Matt Pocock 技能课程仓库：TypeScript 及前端工程化技能训练材料，作为技能系统设计参考"
)

# ============================================================
# 颜色输出
# ============================================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log_info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${RESET}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $*"; }
log_header()  { echo -e "\n${BOLD}━━━ $* ━━━${RESET}"; }

# ============================================================
# 主逻辑
# ============================================================
SUCCESS=0
FAILED=0
TOTAL=${#REPOS[@]}

echo -e "${BOLD}Code Studio 研究仓库同步脚本${RESET}"
echo -e "当前系统: $(uname -s)  Root: ${ROOT}"
echo -e "同步时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "仓库总数: ${TOTAL}"

for entry in "${REPOS[@]}"; do
  REL_PATH="${entry%%|*}"
  LOCAL_PATH="${ROOT}/${REL_PATH}"
  REST="${entry#*|}"
  REMOTE_URL="${REST%%|*}"
  DESCRIPTION="${REST#*|}"

  log_header "$(basename "$LOCAL_PATH")"
  log_info "本地路径: $LOCAL_PATH"
  log_info "远程地址: $REMOTE_URL"
  log_info "说明: $DESCRIPTION"

  if [ -d "$LOCAL_PATH/.git" ]; then
    # 已是 git 仓库 → 更新
    log_info "已存在，执行 git pull..."
    if git -C "$LOCAL_PATH" pull --ff-only 2>&1; then
      log_ok "更新完成"
      SUCCESS=$(( SUCCESS + 1 ))
    else
      log_warn "fast-forward 失败，尝试 fetch + rebase..."
      if git -C "$LOCAL_PATH" fetch origin && git -C "$LOCAL_PATH" rebase origin/HEAD 2>&1; then
        log_ok "rebase 更新完成"
        SUCCESS=$(( SUCCESS + 1 ))
      else
        log_error "更新失败，请手动检查 $LOCAL_PATH"
        FAILED=$(( FAILED + 1 ))
      fi
    fi
  elif [ -d "$LOCAL_PATH" ]; then
    # 目录存在但不是 git 仓库
    log_error "目录已存在但不是 git 仓库，跳过: $LOCAL_PATH"
    FAILED=$(( FAILED + 1 ))
  else
    # 目录不存在 → 克隆
    PARENT_DIR="$(dirname "$LOCAL_PATH")"
    log_info "目录不存在，执行 git clone..."
    if git clone "$REMOTE_URL" "$LOCAL_PATH" 2>&1; then
      log_ok "克隆完成"
      SUCCESS=$(( SUCCESS + 1 ))
    else
      log_error "克隆失败: $REMOTE_URL"
      FAILED=$(( FAILED + 1 ))
    fi
  fi
done

# ============================================================
# 汇总
# ============================================================
echo -e "\n${BOLD}━━━ 同步结果汇总 ━━━${RESET}"
echo -e "  总计: ${TOTAL}  ${GREEN}成功: ${SUCCESS}${RESET}  ${RED}失败: ${FAILED}${RESET}"
if [ "$FAILED" -gt 0 ]; then
  echo -e "  ${YELLOW}部分仓库同步失败，请检查网络或权限配置${RESET}"
  exit 1
fi
echo -e "  ${GREEN}全部同步完成！${RESET}"
