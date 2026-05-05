# CCGS Hook 详细说明（12 个）

> **文档定位**：详细描述 CCGS 的 12 个 Hook，包括 9 种事件类型、触发时机、检查逻辑、退出码含义。
---

## 一、Hook 事件类型（9 种）

| Hook 类型 | 触发时机 | CCGS 使用的脚本 |
| ----------- | ---------- | ------------------ |
| **SessionStart** | 会话开始时 | `session-start.sh` |
| **PreToolUse** | 工具调用前 | `pre-compact.sh`, `validate-commit.sh`, `validate-push.sh` |
| **PostToolUse** | 工具调用后 | `post-compact.sh`, `validate-assets.sh`, `validate-skill-change.sh` |
| **PreCompact** | 上下文压缩前 | （在 PreToolUse 中处理） |
| **PostCompact** | 上下文压缩后 | （在 PostToolUse 中处理） |
| **Stop** | 会话停止时 | `session-stop.sh` |
| **SubagentStart** | 子 Agent 启动时 | `log-agent.sh` |
| **SubagentStop** | 子 Agent 停止时 | `log-agent-stop.sh` |
| **Notification** | 通知事件发生时 | `detect-gaps.sh`, `notify.sh` |

---

## 二、详细 Hook 说明

### 2.1 SessionStart Hooks（1 个）

---

#### `session-start.sh`

**描述**：!/bin/bash Claude Code PreCompact hook: Dump session state before context compression This output appears in the conversation right before compaction, ensuring
**退出码 0**：允许操作继续

### `validate-commit.sh`

**描述**：!/bin/bash Claude Code PreToolUse hook: Validates git commit commands Receives JSON on stdin with tool_input.command
**退出码 0**：允许操作继续
**退出码 2**：阻止操作（严重错误）

### `validate-push.sh`

**描述**：!/bin/bash Claude Code PreToolUse hook: Validates git push commands Warns on pushes to protected branches
**退出码 0**：允许操作继续
**退出码 2**：阻止操作（严重错误）

---

## Post-tool（3 个）

---

### `post-compact.sh`

**描述**：!/usr/bin/env bash post-compact.sh — fires after conversation compaction Reminds Claude to restore session state from the file-backed checkpoint.

### `validate-assets.sh`

**描述**：!/bin/bash Claude Code PostToolUse hook: Validates asset files after Write/Edit Checks naming conventions for files in assets/ directory
**退出码 0**：允许操作继续（或仅警告，不阻止）
**退出码 1**：阻止操作（严重错误，如 JSON 无效）

### `validate-skill-change.sh`

**描述**：!/bin/bash Claude Code PostToolUse hook: Advises running skill-test after skill file changes Fires when any file inside .claude/skills/ is written or edited.
**退出码 0**：允许操作继续

---

## Notification（2 个）

---

### `detect-gaps.sh`

**描述**：!/bin/bash Hook: detect-gaps.sh Event: SessionStart
**退出码 0**：允许操作继续

### `notify.sh`

**描述**：!/usr/bin/env bash Notification hook — fires when Claude Code sends a notification Shows a Windows toast via PowerShell

---

## Session-stop（4 个）

---

### `log-agent-stop.sh`

**描述**：!/bin/bash Claude Code SubagentStop hook: Log agent completion for audit trail Tracks when agents finish and their outcome
**退出码 0**：允许操作继续

### `log-agent.sh`

**描述**：!/bin/bash Claude Code SubagentStart hook: Log agent invocations for audit trail Tracks which agents are being used and when
**退出码 0**：允许操作继续

### `session-start-2.sh`（参见第 28 行）

**描述**：!/bin/bash Claude Code SessionStart hook: Load project context at session start Outputs context information that Claude sees when a session begins
**退出码 0**：允许操作继续

### `session-stop.sh`

**描述**：!/bin/bash Claude Code Stop hook: Log session summary when Claude finishes Records what was worked on for audit trail and sprint tracking
**退出码 0**：允许操作继续

---
