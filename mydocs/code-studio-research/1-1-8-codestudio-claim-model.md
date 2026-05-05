# CodeStudio Claim 模型详解

> **⚠️ 重要说明**：本文档描述 CodeStudio 的**设计方案**，当前系统**尚未实现**。
>
> **文档定位**：深入 CodeStudio 的 Claim 模型（并发 session 管理）。

---

## 一、Claim 模型概述

> **问题**：多个 Claude Code session 可能同时启动，如何避免重复分配同一 sid？

**Claim 模型核心保证**：

- **原子性**：使用 `fcntl.flock(LOCK_EX)` 保护 pending/ 目录，并发 claim 不会重复分配同一 sid
- **FIFO**：按 `created_at` 排序，最旧的 pending 优先被 claim
- **幂等性**：同一 `cc_session_id` 被 claim 后移入 claimed/，不可重复 claim

---

## 二、Claim 流程

```text
Claude Code Session 启动
    ↓
SessionStart Hook 触发
    ↓
create_pending_session --cc-session-id <UUID>
    ↓
在 pending/ 目录创建预注册记录
    ↓
Host LLM 收到 CLAUDE.md 指令
    ↓
调用 claim_session（原子 pop pending session，获取 harness_sid）
    ↓
后续所有工具调用均传入此 sid
```text

**pending/ 目录结构**：

```text
projects/<project-id>/pending/
├── sess-20260429-143052-a1b2.json    # 预注册记录
├── sess-20260429-143055-c3d4.json
└── ...
```text

**预注册记录格式**：

```json
{
  "cc_session_id": "cc-sess-20260429-143052",
  "created_at": "2026-04-29T14:30:52+08:00",
  "status": "pending"
}
```text

---

## 三、claim_session MCP 工具

**工具定义**：

```python

# harness/api/tools/claim_session.py

def claim_session(cc_session_id: str) -> dict:
    """
    原子 pop pending session，获取 harness_sid.
    
    Args:
        cc_session_id: Claude Code session ID（UUID）
    
    Returns:
        {
            "harness_sid": "sid-20260429-143052-a1b2",
            "status": "claimed"
        }
    
    Raises:
        PendingSessionNotFound: 没有可用的 pending session
        ClaimFailed: claim 失败（并发冲突）
    """

    # 1. 获取文件锁（LOCK_EX）

    with flock("projects/<project-id>/pending/"):

        # 2. 按 created_at 排序，找到最旧的 pending session

        pending_sessions = sorted(glob("pending/*.json"), key=lambda x: x['created_at'])
        if not pending_sessions:
            raise PendingSessionNotFound("没有可用的 pending session")
        
        # 3. 读取 pending session

        pending_session = pending_sessions[0]
        if pending_session['cc_session_id'] != cc_session_id:
            raise ClaimFailed("cc_session_id 不匹配")
        
        # 4. 移动到 claimed/ 目录

        shutil.move(f"pending/{pending_session['cc_session_id']}.json", 
                    f"claimed/{pending_session['cc_session_id']}.json")
        
        # 5. 生成 harness_sid

        harness_sid = f"sid-{pending_session['created_at']}-{random_string(4)}"
        
        return {"harness_sid": harness_sid, "status": "claimed"}
```text

---

## 四、Claim 模型的优势

| 优势 | 说明 |
| ------ | ------ |
| **并发安全** | 使用 `fcntl.flock(LOCK_EX)` 保证原子性 |
| **FIFO** | 按 `created_at` 排序，公平分配 |
| **幂等性** | 同一 `cc_session_id` 不可重复 claim |
| **可追踪** | pending/ → claimed/ → done/，完整生命周期 |

**与 CCGS 的对比**：

| 维度 | CCGS | CodeStudio |
| ------ | ------- | ------------ |
| **并发管理** | ❌ 没有（依赖用户手动启动） | ✅ Claim 模型（原子 pop pending session） |
| **Session 生命周期** | ❌ 没有（Session 隐式存在） | ✅ pending → claimed → done（可追踪） |

---

**文档状态**：✅ 第一版完成（从 `1-1-code-studio-analysis.md` 拆分）

**下一步**：

- [ ] 补充 claim_session 的单元测试（并发场景）
- [ ] 补充 Claim 模型的边界情况（网络断开、进程崩溃、...）
