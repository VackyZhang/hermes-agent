# CCGS Director Gates 详解

> **文档定位**：深入 CCGS 的 17 个 Director Gates，包括三层 Gates、裁决格式、升级规则。

---

## 一、Director Gates 概述

**问题**：如何确保输出质量？CCGS 通过 **Director Gates**（总监门禁）来实现。

**三层 Gates**：

| 层级 | 数量 | 示例 |
| ------ | ------ | ------ |
| **Tier 1 - Creative Director Gates** | 6 | `CD-PiLLARS`, `CD-GDD-ALIGN`, `CD-SYSTEMS` |
| **Tier 1 - Technical Director Gates** | 6 | `TD-SYSTEM-BOUNDARY`, `TD-FEASIBILITY`, `TD-ARCHITECTURE` |
| **Tier 1 - Producer Gates** | 5 | `PR-SCOPE`, `PR-SPRINT`, `PR-MILESTONE` |

---

## 二、Creative Director Gates（6 个）

### 2.1 `CD-PILLARS`

**职责**：验证设计是否符合创意支柱（Creative Pillars）。

**裁决格式**：

```text
GATE: CD-PILLARS
INPUT: GDD (Game Design Document)
| VERDICT: APPROVE | READY | CONCERNS | REJECT |
REASONING:

  - Pillar 1 (Exploration): ✅ Well supported by mechanic X
  - Pillar 2 (Strategy): ⚠️ Under-developed, suggest adding Y
  - Pillar 3 (Narrative): ❌ Missing entirely

ESCALATION: If REJECT, escalate to Creative Director for binding decision.
```text

### 2.2 `CD-GDD-ALIGN`

**职责**：验证 GDD 与创意支柱的对齐程度。

### 2.3 `CD-SYSTEMS`

**职责**：验证系统设计的完整性。

### 2.4 `CD-ART-BIBLE`

**职责**：验证美术风格指南的完整性。

### 2.5 `CD-NARRATIVE-ARC`

**职责**：验证叙事弧线的连贯性。

### 2.6 `CD-PLAYER-PSYCHOLOGY`

**职责**：验证设计是否符合玩家心理学原理。

---

## 三、Technical Director Gates（6 个）

### 3.1 `TD-SYSTEM-BOUNDARY`

**职责**：验证系统边界是否清晰定义。

### 3.2 `TD-FEASIBILITY`

**职责**：验证技术可行性（性能、平台限制、...）。

### 3.3 `TD-ARCHITECTURE`

**职责**：验证架构设计是否符合引擎最佳实践。

### 3.4 `TD-PERFORMANCE-BUDGET`

**职责**：验证性能预算是否合理（FPS、内存、加载时间）。

### 3.5 `TD-ENGINE-COMPATIBILITY`

**职责**：验证引擎版本兼容性（Unity version、Unreal version、...）。

### 3.6 `TD-SECURITY-AUDIT`

**职责**：验证安全性（防作弊、数据加密、...）。

---

## 四、Producer Gates（5 个）

### 4.1 `PR-SCOPE`

**职责**：验证范围是否在预算内。

### 4.2 `PR-SPRINT`

**职责**：验证 Sprint 计划是否合理（故事点、任务分配、...）。

### 4.3 `PR-MILESTONE`

**职责**：验证里程碑交付物是否完整。

### 4.4 `PR-RISK-MANAGEMENT`

**职责**：验证风险管理计划是否充分。

### 4.5 `PR-CROSS-DEPARTMENT-SYNC`

**职责**：验证跨部门同步是否到位。

---

## 五、Gate 裁决格式

**注意**：不同 Gate 类型使用不同的裁决词汇（不是所有 Gate 都用 APPROVE/REJECT）。

| Gate 类型 | 裁决词汇 | 说明 |
| ----------- | ---------- | ------ |
| **Creative Director Gates** | `APPROVE` / `CONCERNS` / `REJECT` | 创意决策 |
| **Technical Director Gates** | `VIABLE` / `CONCERNS` / `HIGH RISK` | 技术可行性 |
| **Producer Gates** | `REALISTIC` / `OPTIMISTIC` / `UNREALISTIC` | 范围可行性 |
| **Phase Gates**（所有类型） | `READY` / `CONCERNS` / `NOT READY` | 阶段转换检查 |

**通用裁决格式**（以 CD Gates 为例）：

```text
GATE: CD-PILLARS
| VERDICT: APPROVE | CONCERNS | REJECT |
REASONING:

  - Pillar 1 (Exploration): ✅ Well supported
  - Pillar 2 (Strategy): ⚠️ Under-developed
  - Pillar 3 (Narrative): ❌ Missing entirely

ESCALATION: If REJECT, escalate to Creative Director for binding decision.
```text

**升级规则**：

- Any REJECT/NOT READY → Overall: FAIL
- Any CONCERNS → Overall: CONCERNS
- All APPROVE/READY → Overall: PASS

**示例裁决**：

```text
GATE: TD-FEASIBILITY
VERDICT: CONCERNS
REASONING:

  - Performance: ⚠️ Target FPS 60, but current prototype runs at 45 FPS on low-end devices
  - Memory: ✅ Within budget (200 MB allocated, 150 MB used)
  - Load Time: ❌ Main menu takes 8s to load (target: 3s)

ESCALATION: If not resolved in 2 sprints, escalate to Technical Director for binding decision.
```text

---

## 六、Gate 的不足（相对 CodeStudio）

| 不足 | 说明 | CodeStudio 的解决方案 |
| ------ | ------ | --------------------- |
| **软性裁决** | Gates 是自由文本裁决，Agent 可以不遵守 | CodeStudio 的 CAP-2 Enforcer 是硬性约束（JSON Schema 验证） |
| **无自动化验证** | Gates 依赖 Agent 自觉，没有自动验证机制 | CodeStudio 的 CAP-2 Enforcer 自动验证（PreToolUse / PostToolUse） |
| **无结构化格式** | Gates 裁决是自由文本，难以解析 | CodeStudio 的 Constraint 有 JSON Schema 验证 |

---

**文档状态**：✅ 第一版完成（从 `1-2-1-ccgs-analysis.md` 拆分）

**下一步**：

- [ ] 补充所有 17 个 Gates 的详细裁决逻辑（从 CCGS 源码提取）
- [ ] 补充 Gates 之间的依赖关系（哪些 Gates 需要先通过？）
