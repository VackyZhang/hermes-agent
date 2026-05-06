# CodeStudio 综合设计方案（二）

> **文档定位**：基于 `1-1` ~ `1-6` 分析，输出 CodeStudio 综合设计方案  
> **创建日期**：2026-05-06  
> **设计人**：Vacky + AI  
> **文档状态**：📝 初稿完成，待实践验证

**关联文档**：
- 问题分析：`0-1-problems-and-goals.md`
- 规划文档：`0-2-code-studio-planning.md`
- 假设与决策：`0-3-hypotheses-and-decisions.md`
- 行动清单：`0-4-action-plan.md`

---

## 一、设计总览

### 1.1 设计目标

基于 6 个工具的分析，CodeStudio 要实现 **3 个核心能力**：

| 能力 | 目标 | 关键设计 |
|------|------|----------|
| **知识系统** | 让 AI 快速获取项目背景知识 | Evidence Chain（闭环） |
| **流程确认** | 确保关键流程符合规范（强制） | GD 治理（形式化约束） |
| **安全机制** | 防止破坏性操作，提供回滚 | Sandbox + Checkpoint + Audit Log |

### 1.2 设计原则

从 6 个工具中学到的设计原则：

| 原则 | 来源 | 说明 |
|------|------|------|
| ✅ **N+M 架构** | CodeStudio | 解耦 Tool（原子能力）和 Skill（工作流封装） |
| ✅ **形式化约束** | CodeStudio | JSON Schema 验证（而非软性 Gates） |
| ✅ **Evidence Chain** | CodeStudio | 操作记录 → 提炼知识 → 注入上下文（闭环） |
| ✅ **Skills 即工作流封装** | Matt Pocock | 可复用的 AI 工作流（SKILL.md + docs/agents/） |
| ✅ **渐进式设计** | Matt Pocock | 从简单开始，逐步增加复杂度（TDD、diagnose、grill-with-docs） |
| ✅ **Hook 机制** | Claude Code | 27 种事件（最细粒度），Pre-tool Hook 检查约束 |
| ✅ **Memory 插件系统** | Hermes Agent | 8 个插件（mem0、honcho、supermemory），可扩展 |

---

## 二、架构设计

### 2.1 N+M 架构（解耦）

**设计理念**：Tool 提供原子能力，Skill 封装工作流，两者解耦。

```
┌─────────────────────────────────────────────────┐
│              Skill Layer（工作流封装）           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ tdd      │  │ diagnose │  │ deploy   │   │
│  └──────────┘  └──────────┘  └──────────┘   │
│  （调用多个 Tool，封装为可复用工作流）          │
└─────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────┐
│              Tool Layer（原子能力）               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ read_file│  │ edit_file│  │ run_cmd  │   │
│  └──────────┘  └──────────┘  └──────────┘   │
│  （单一职责，可独立测试）                       │
└─────────────────────────────────────────────────┘
```

**关键设计**：
- Tool：单一职责，可独立测试（参考 Matt Pocock 的 `grill-me` Skill）
- Skill：调用多个 Tool，封装为可复用工作流（参考 Matt Pocock 的 `tdd` Skill）
- 解耦：Skill 不依赖具体 Tool 实现，通过接口调用

**参考来源**：
- ✅ CodeStudio：`N+M` 架构（Tool vs Skill）
- ✅ Matt Pocock：`tdd`、`diagnose` Skills（工作流封装）

---

### 2.2 分层架构

```
┌─────────────────────────────────────┐
│       User Interface Layer          │  ← CLI、TUI、Gateway
├─────────────────────────────────────┤
│       Skill Layer（工作流封装）      │  ← tdd、diagnose、deploy
├─────────────────────────────────────┤
│       Tool Layer（原子能力）         │  ← read_file、edit_file、run_cmd
├─────────────────────────────────────┤
│       Governance Layer（治理框架）   │  ← GD-1（定义）、GD-2（实例化）、Enforcer
├─────────────────────────────────────┤
│       Evidence Layer（证据链）       │  ← Trace（操作记录）、Evidence（提炼知识）
├─────────────────────────────────────┤
│       Safety Layer（安全机制）       │  ← Sandbox、Checkpoint、Audit Log
├─────────────────────────────────────┤
│       Knowledge Layer（知识管理）     │  ← Static（.md）、Dynamic（Evidence Chain）
└─────────────────────────────────────┘
```

**各层职责**：
- **UI Layer**：用户交互（CLI、TUI、Gateway）
- **Skill Layer**：工作流封装（调用多个 Tool）
- **Tool Layer**：原子能力（单一职责）
- **Governance Layer**：流程强制执行（形式化约束）
- **Evidence Layer**：操作记录和知识提炼（闭环）
- **Safety Layer**：安全机制（Sandbox、Checkpoint、Audit Log）
- **Knowledge Layer**：知识管理（静态 + 动态）

---

## 三、核心能力设计

### 3.1 知识系统（Knowledge System）

**目标**：让 AI 快速获取项目背景知识，不重复劳动。

**设计**：Evidence Chain（闭环）

```
┌──────────────────────────────────────────────────┐
│              Evidence Chain（闭环）                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Trace    │→│ Evidence  │→│Knowledge │     │
│  │（操作记录│  │（提炼知识│  │（结构化 │     │
│  │  日志）  │  │    ）    │  │  存储）  │     │
│  └──────────┘  └──────────┘  └──────────┘     │
│        ↑            ↑               ↓             │
│  ┌──────────────────────────────────────┐      │
│  │        Injection（注入上下文）         │      │
│  └──────────────────────────────────────┘      │
└──────────────────────────────────────────────────┘
```

**具体实现**：

#### 3.1.1 静态知识（项目架构、部署流程）
- **存储格式**：`.md` 文档 + OpenSpec（参考 mugc_tools）
- **组织方式**：按模块分类（参考 CCGS 的 `.claude/docs/*.md`）
- **注入机制**：自动注入相关上下文（参考 Claude Code 的 Skill 注入）

#### 3.1.2 动态知识（常见 bug、调试经验）
- **来源**：Trace（操作记录）
- **提炼**：Evidence（从 Trace 中提炼知识）
- **存储**：Structured Storage（JSON、Markdown）
- **注入**：Injection（根据当前任务，自动注入相关 Knowledge）

#### 3.1.3 Knowledge Lifecycle Management（知识全生命周期管理）
- **初始化**：人工编写（静态知识） + 自动提取（动态知识）
- **组织**：按类型分类（静态/动态/流程/上下文） + 索引（关键词 + 语义搜索）
- **注入**：智能注入（根据触发时机、注入内容、注入量）
- **更新**：Evidence Chain 驱动更新（检测过时 → 标记可疑 → 人工审核 → 更新）
- **废弃**：安全废弃（检测废弃条件 → 标记废弃 → 观察期 → 永久删除）

**参考来源**：
- ✅ CCGS：`.claude/docs/*.md`
- ✅ mugc_tools：OpenSpec
- ✅ Hermes Agent：Memory 插件
- ✅ Matt Pocock：`CONTEXT.md`（领域语言）

---

### 3.2 流程确认（Process Enforcement）

**目标**：确保关键流程（如生产部署）符合规范，**强制**而非**建议**。

**设计**：GD 治理（形式化约束）

```
┌──────────────────────────────────────────────────┐
│              GD 治理框架                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ GD-1     │→│ GD-2     │→│ Enforcer │     │
│  │（治理定义│  │（治理实例│  │（强制执行│     │
│  │   ）    │  │    ）    │  │    ）    │     │
│  └──────────┘  └──────────┘  └──────────┘     │
│       ↓                ↓               ↓          │
│  [JSON Schema]  [项目特定配置]  [Pre-tool Hook] │
└──────────────────────────────────────────────────┘
```

**具体实现**：

#### 3.2.1 GD-1（治理定义）
- **格式**：JSON Schema
- **内容**：定义"应该做什么"（约束条件）
- **示例**：
```json
{
  "type": "object",
  "properties": {
    "deploy": {
      "type": "object",
      "properties": {
        "require_staging": { "type": "boolean", "const": true },
        "require_tests": { "type": "boolean", "const": true }
      },
      "required": ["require_staging", "require_tests"]
    }
  }
}
```

#### 3.2.2 GD-2（治理实例）
- **格式**：YAML（项目特定配置）
- **内容**：将 GD-1 实例化为具体项目的约束
- **示例**：
```yaml
deploy:
  require_staging: true
  require_tests: true
  allowed_regions: ["us-east-1", "eu-west-1"]
```

#### 3.2.3 Enforcer（强制执行）
- **机制**：Pre-tool Hook（参考 Claude Code 的 Hook 机制）
- **时机**：关键操作前（如部署前）
- **动作**：
  1. 检查 GD-2 约束是否满足
  2. 如果不满足，阻止操作并提示
  3. 如果满足，记录 Evidence（操作证据）

**参考来源**：
- ✅ CCGS：Director Gates（但软性）
- ✅ CodeStudio：GD-1/2（形式化）
- ✅ Claude Code：Pre-tool Hook

---

### 3.3 安全机制（Safety Mechanisms）

**目标**：防止 AI 做出破坏性操作，提供回滚能力。

**设计**：Sandbox + Checkpoint + Audit Log

```
┌──────────────────────────────────────────────────┐
│              Safety Mechanisms                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Sandbox  │  │Checkpoint│  │ Audit Log│     │
│  │（隔离环境│  │（还原点）│  │（操作日志│     │
│  │   ）    │  │    ）    │  │    ）    │     │
│  └──────────┘  └──────────┘  └──────────┘     │
│       ↓                ↓               ↓          │
│  [Dry-run]    [Git Commit]    [Session DB]      │
└──────────────────────────────────────────────────┘
```

**具体实现**：

#### 3.3.1 Sandbox（隔离环境）
- **机制**：在 staging 环境先跑（参考 Claude Code 的 Dry-run 模式）
- **实现**：Docker 容器 / 云开发环境（参考 hermes-agent 的 environments/）
- **目的**：隔离生产环境，避免破坏性操作

#### 3.3.2 Checkpoint（还原点）
- **机制**：操作前创建还原点（参考 Docker commit）
- **实现**：Git Commit（自动提交当前状态）
- **目的**：提供回滚能力

#### 3.3.3 Audit Log（审计日志）
- **机制**：记录所有操作（参考 Hermes Agent 的 Session DB）
- **实现**：SQLite（操作类型、时间戳、用户、结果）
- **目的**：追责 + 调试

**参考来源**：
- ✅ Claude Code：Dry-run 模式
- ✅ Hermes Agent：Session DB
- ✅ hermes-agent：environments/（隔离环境）

---

## 四、Skill 系统设计

### 4.1 设计理念（基于 Matt Pocock Skills）

**核心洞察**：
- ✅ **Skills 即工作流封装**：将常见任务封装为可复用工作流
- ✅ **渐进式设计**：从简单开始，逐步增加复杂度（TDD、diagnose、grill-with-docs）
- ✅ **SKILL.md + docs/agents/**：标准化 Skill 结构
- ✅ **Feedback Loop**：Skill 内部有反馈循环（如 diagnose 的 5 种调试策略）

**设计原则**：
1. **单一职责**：每个 Skill 只做一件事（参考 Matt Pocock 的 `grill-me` Skill）
2. **可组合**：Skill 可以调用其他 Skill（参考 Matt Pocock 的 `tdd` Skill）
3. **可测试**：每个 Skill 应该有清晰的输入/输出（参考 Matt Pocock 的 `tdd` Skill）

---

### 4.2 Skill 结构规范

**基于 Matt Pocock 的设计**，定义 CodeStudio Skill 结构：

```
skills/
├── tdd/
│   ├── SKILL.md          # Skill 描述（触发条件、执行步骤、注意事项）
│   ├── docs/
│   │   └── agents/
│   │       └── tdd.md    # 详细文档（注入到上下文）
│   └── index.ts          # Skill 实现（可选，复杂 Skill 需要）
├── diagnose/
│   ├── SKILL.md
│   └── docs/
│       └── agents/
│           └── diagnose.md
└── deploy-with-checks/
    ├── SKILL.md
    └── docs/
        └── agents/
            └── deploy-with-checks.md
```

**SKILL.md 格式**（参考 Matt Pocock）：

```markdown
# TDD Skill

## Trigger（触发条件）
- User says: "implement X with tests"
- User says: "add tests for X"

## Steps（执行步骤）
1. Write failing test
2. Run test（verify it fails）
3. Write minimal implementation
4. Run test（verify it passes）
5. Refactor（if needed）

## Notes（注意事项）
- Always write test first
- Run test after each step
- Refactor only after tests pass
```

**docs/agents/*.md 格式**（参考 Matt Pocock）：

```markdown
# TDD Workflow

## Overview
Test-Driven Development workflow for AI-assisted coding.

## Steps
### 1. Write Failing Test
- Understand the requirement
- Write a minimal failing test

### 2. Run Test（Verify It Fails）
- Run the test
- Confirm it fails（this ensures the test is valid）

### 3. Write Minimal Implementation
- Write the minimal code to make the test pass
- Don't over-engineer

### 4. Run Test（Verify It Passes）
- Run the test
- Confirm it passes

### 5. Refactor（If Needed）
- Look for refactoring opportunities
- Run test after each refactoring

## Tips
- Always run test after each step
- Don't skip the "verify it fails" step
- Refactor only after tests pass
```

---

### 4.3 核心 Skills 设计

基于 Matt Pocock 的 Skills，设计 CodeStudio 核心 Skills：

| Skill | 目的 | 参考来源 | 执行步骤 |
|-------|------|----------|----------|
| **tdd** | 测试驱动开发 | Matt Pocock | Write failing test → Run test → Write implementation → Run test → Refactor |
| **diagnose** | 调试循环 | Matt Pocock | Understand error → Form hypothesis → Test hypothesis → Repeat |
| **grill-me** | 任务开始前强制对齐 | Matt Pocock | Ask clarifying questions → Confirm understanding → Start task |
| **deploy-with-checks** | 安全部署 | 新设计 | Check staging → Run tests → Create checkpoint → Deploy → Verify |
| **caveman** | 压缩通信（省 token） | Matt Pocock | Replace verbose text with primitive language |
| **improve-architecture** | 架构改进 | Matt Pocock | Analyze current architecture → Identify problems → Propose improvements |

---

## 五、实现路线图

### 5.1 Phase 1：基础架构（1-2 周）

**目标**：实现 N+M 架构 + GD 治理框架

| 任务 | 输出 | 优先级 |
|------|------|--------|
| ① 实现 Tool 层（原子能力） | `tools/` 目录 | 高 |
| ② 实现 Skill 层（工作流封装） | `skills/` 目录 + SKILL.md 规范 | 高 |
| ③ 实现 GD-1（治理定义） | JSON Schema 验证器 | 高 |
| ④ 实现 GD-2（治理实例） | YAML 配置解析器 | 高 |
| ⑤ 实现 Enforcer（Pre-tool Hook） | Hook 机制 | 高 |

---

### 5.2 Phase 2：知识系统（1 周）

**目标**：实现 Evidence Chain + Knowledge Lifecycle Management

| 任务 | 输出 | 优先级 |
|------|------|--------|
| ① 实现 Trace（操作记录） | SQLite 日志 | 高 |
| ② 实现 Evidence（提炼知识） | 自动提炼算法 | 中 |
| ③ 实现 Knowledge（结构化存储） | JSON + Markdown | 高 |
| ④ 实现 Injection（注入上下文） | 智能注入算法 | 高 |
| ⑤ 实现 Knowledge Lifecycle Manager | 初始化、组织、注入、更新、废弃 | 中 |

---

### 5.3 Phase 3：安全机制（1 周）

**目标**：实现 Sandbox + Checkpoint + Audit Log

| 任务 | 输出 | 优先级 |
|------|------|--------|
| ① 实现 Sandbox（隔离环境） | Docker 容器 / 云开发环境 | 高 |
| ② 实现 Checkpoint（还原点） | Git Commit 自动创建 | 高 |
| ③ 实现 Audit Log（审计日志） | SQLite 操作日志 | 中 |

---

### 5.4 Phase 4：核心 Skills（2 周）

**目标**：实现 6 个核心 Skills

| 任务 | 输出 | 优先级 |
|------|------|--------|
| ① 实现 `tdd` Skill | SKILL.md + docs/agents/tdd.md | 高 |
| ② 实现 `diagnose` Skill | SKILL.md + docs/agents/diagnose.md | 高 |
| ③ 实现 `grill-me` Skill | SKILL.md + docs/agents/grill-me.md | 高 |
| ④ 实现 `deploy-with-checks` Skill | SKILL.md + docs/agents/deploy-with-checks.md | 高 |
| ⑤ 实现 `caveman` Skill | SKILL.md + docs/agents/caveman.md | 中 |
| ⑥ 实现 `improve-architecture` Skill | SKILL.md + docs/agents/improve-architecture.md | 中 |

---

## 六、验证方法

### 6.1 假设验证

| 假设 | 验证方法 | 成功标准 |
|------|----------|----------|
| 假设 1：知识复用能显著提升 AI 开发效率 | 实践验证（Round 1-3） | 任务完成时间减少 30% |
| 假设 2：形式化门禁比软性 Gates 更安全 | 对比测试 | 违规操作减少 90% |
| 假设 3：不同知识需要不同格式（.md / skill / evidence） | 实践验证 | AI 能正确使用不同格式的知识 |

---

### 6.2 设计验证

| 设计 | 验证方法 | 成功标准 |
|------|----------|----------|
| N+M 架构 | 单元测试 + 集成测试 | Tool 和 Skill 解耦，可独立测试 |
| GD 治理框架 | 部署流程测试 | 违规部署被阻止，合规部署通过 |
| Evidence Chain | 知识提炼测试 | 能从 Trace 中提炼有用知识 |
| Skill 系统 | Skill 执行测试 | Skill 能正确执行，减少重复劳动 |

---

## 七、风险评估

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| ❌ Evidence Chain 提炼算法不准确 | 动态知识质量低 | 人工审核 + 标记可疑 |
| ❌ GD 治理框架太严格，影响开发效率 | 开发者不愿意使用 | 提供 Dry-run 模式 + 人工审批 |
| ❌ Skill 系统复杂度高，难以维护 | 技术债务积累 | 标准化 Skill 结构 + 文档 |
| ❌ 安全机制性能开销大 | 开发体验差 | 可选开启 + 异步执行 |

---

## 八、下一步行动

### 8.1 立即行动（本周）

| 任务 | 优先级 | 预计时间 | 输出 |
|------|--------|----------|-------|
| ① 实现 `tdd` Skill | 高 | 2-3 小时 | SKILL.md + docs/agents/tdd.md |
| ② 实现 `diagnose` Skill | 高 | 2-3 小时 | SKILL.md + docs/agents/diagnose.md |
| ③ 实现 `grill-me` Skill | 高 | 1-2 小时 | SKILL.md + docs/agents/grill-me.md |
| ④ 实现 GD-1（JSON Schema 验证器） | 高 | 3-4 小时 | JSON Schema 验证器 |
| ⑤ 实现 Enforcer（Pre-tool Hook） | 高 | 2-3 小时 | Hook 机制 |

---

### 8.2 短期计划（2-4 周）

- [ ] 完成 Phase 1：基础架构（N+M + GD 治理）
- [ ] 完成 Phase 2：知识系统（Evidence Chain）
- [ ] 完成 Phase 3：安全机制（Sandbox + Checkpoint + Audit Log）
- [ ] 完成 Phase 4：核心 Skills（6 个 Skills）
- [ ] 实践验证 Round 1（在 letsgo_server 上做真实任务）

---

## 九、文档更新日志

| 日期 | 更新内容 | 更新人 |
|------|----------|----------|
| 2026-05-06 | 创建文档，基于 `1-1` ~ `1-6` 分析，输出 CodeStudio 综合设计方案 | Vacky + AI |

---

**文档状态**：📝 初稿完成，待实践验证

**下一步**：
- [ ] 实践验证 Round 1（创建 `3-1-practice-round1.md`）
- [ ] 根据实践反馈，修正设计方案
- [ ] 进入 Phase 1 实现

---

**参考文档**：
- CodeStudio 分析：`1-1-1-code-studio-analysis.md`
- CCGS 分析：`1-2-1` ~ `1-2-6`
- Hermes Agent 分析：`1-3-1` ~ `1-3-6`
- Claude Code 分析：`1-4-1` ~ `1-4-8`
- mugc_tools 分析：`1-5-1` ~ `1-5-7`
- Matt Pocock Skills 分析：`1-6-1` ~ `1-6-4`
