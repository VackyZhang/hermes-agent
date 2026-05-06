# CCGS 分析

> **文档定位**：梳理 CCGS 的设计、实现、亮点，对比 CodeStudio，并针对 `0-problems-and-goals.md` 中的问题提出解决思路。
>
> **本文结构**：

> - **主文档**（本文件）：总结性输出，建立整体认知
> - **子文档**（深入细节）：
>   - `1-2-2-ccgs-agents.md`：49 个 Agent 详细说明（三层结构、协作协议）
>   - `1-2-3-ccgs-skills.md`：72 个 Skill 详细说明（9 个功能分类、工作流）
>   - `1-2-4-ccgs-hooks.md`：12 个 Hook 详细说明（4 个 Hook 类型、触发时机）
>   - `1-2-5-ccgs-rules.md`：11 条 Rules 详细说明（路径级规则、编码规范）
>   - `1-2-6-ccgs-director-gates.md`：17 个 Director Gates 详细说明（三层 Gates、裁决格式）

---

## 一、一句话总结

CCGS（Claude Code Game Studios）是基于 Claude Code 的**结构化游戏开发工作流模板**，将完整的游戏工作室流程"装进" Claude Code。

**核心设计理念**：

- **结构化流程**：7 个开发阶段，覆盖从脑暴到发布的完整流程

- **Agent 协作规范**：49 个 Agent，明确分工、交接、审查机制

- **自动化检查**：12 个 Hooks，在工具调用前后自动检查

- **知识文档化**：`.claude/docs/*.md`，让 AI 读取设计理论

---

## 二、核心设计概览

### 2.1 整体架构

```text
Claude Code（运行时环境）
    ↑
CCGS 模板（.claude/ 目录）
    ├── agents/          # 49 个 Agent 定义（Markdown + YAML frontmatter）
    ├── skills/          # 72 个技能（Slash 命令实现）
    ├── hooks/           # 12 个自动化检查脚本（bash / powershell）
    ├── rules/           # 11 条路径级编码规范
    ├── docs/            # 游戏设计理论文档（MDA、SDT 等）
    └── settings.json    # 权限配置、hook 注册
```text

**关键设计**：

1. **Agent 定义即 Prompt**：每个 `.claude/agents/*.md` 文件就是一段精心设计的 prompt

2. **Skill 即 Slash 命令**：每个 `.claude/skills/*.md` 文件定义一个 `/slash` 命令的实现

3. **Hook 即自动化检查**：bash/powershell 脚本，在工具调用前后自动执行

4. **路径级规则**：不同目录（gameplay、network、ui...）强制执行不同的编码规范

**深入细节** → 详见 `1-2-2-ccgs-agents.md`（Agent 系统）、`1-2-3-ccgs-skills.md`（Skill 系统）

### 2.2 Agent 系统（49 个）

**三层结构**：

| 层级 | 模型 | 职责 | 示例 |
| ------ | ------ | ------ | ------ |
| **Tier 1 - 总监层** | Opus | 创意/技术/生产决策 | `creative-director`, `technical-director`, `producer` |
| **Tier 2 - 部门负责人层** | Sonnet（少数是 Haiku） | 部门内任务分配与审查 | `lead-programmer`, `art-director`, `qa-lead` |
| **Tier 2 例外** | Haiku（`community-manager`） | 轻量级任务 | `community-manager` |
| **Tier 3 - 专员层** | Sonnet/Haiku | 执行具体任务 | `gameplay-programmer`, `ui-programmer`, `level-designer` |

**Agent YAML Front Matter 示例**：

```yaml
---
name: creative-director
description: "The Creative Director is the highest-level creative authority..."
tools: Read, Glob, Grep, Write, Edit, WebSearch
model: opus
maxTurns: 30
memory: user
disallowedTools: Bash
skills: [brainstorm, design-review]
---
```text

**深入细节** → 详见 `1-2-2-ccgs-agents.md`（49 个 Agent 详细说明、协作协议）

### 2.3 Skill 系统（72 个）

**9 个功能分类**：

| 分类 | 数量 | 示例 |
| ------ | ------ | ------ |
| 设计 & 脑暴 | 28 | `/brainstorm`, `/define-pillars`, `/create-gdd` |
| 项目管理 | 12 | `/create-epics`, `/plan-sprint`, `/scope-check` |
| 开发 & 实现 | 10 | `/implement-system`, `/write-code`, `/refactor` |
| 测试 & 质量保证 | 8 | `/run-tests`, `/write-tests`, `/debug` |
| 发布 & 部署 | 6 | `/build`, `/deploy`, `/create-patch-notes` |
| 协作 & 审查 | 4 | `/code-review`, `/gate-check`, `/create-pull-request` |

**深入细节** → 详见 `1-2-3-ccgs-skills.md`（72 个 Skill 详细说明、工作流）

### 2.4 Hook 系统（12 个）

**9 个 Hook 类型**（基于 `settings.json` 中的事件类型）：

| Hook 类型 | 触发时机 | 示例 |
| ----------- | ---------- | ------ |
| **SessionStart** | 会话开始时 | `session-start.sh`（加载项目上下文） |
| **PreToolUse** | 工具调用前 | `validate-commit.sh`（检查 git commit 命令） |
| **PostToolUse** | 工具调用后 | `validate-assets.sh`（检查修改后的资产） |
| **PreCompact** | 上下文压缩前 | `pre-compact.sh`（ dump 会话状态） |
| **PostCompact** | 上下文压缩后 | `post-compact.sh`（提醒恢复会话状态） |
| **Stop** | 会话停止时 | `session-stop.sh`（记录会话摘要） |
| **SubagentStart** | 子 Agent 启动时 | `log-agent.sh`（记录 Agent 调用） |
| **SubagentStop** | 子 Agent 停止时 | `log-agent-stop.sh`（记录 Agent 完成） |
| **Notification** | 通知事件发生时 | `notify.sh`（显示桌面通知） |

**深入细节** → 详见 `1-2-4-ccgs-hooks.md`（12 个 Hook 详细说明、退出码含义）

### 2.5 Rules 系统（11 条）

**路径级规则**：

| 规则文件 | 适用路径 | 核心规则 |
| ---------- | ---------- | ---------- |
| `gameplay-code.md` | `src/gameplay/**` | 数据驱动、帧率独立、解耦通信、接口清晰 |
| `ai-code.md` | `src/ai/**` | 性能预算、可调试、数据结构、抽象感知 |
| `engine-code.md` | `src/core/**` | 热路径零分配、线程安全、性能分析、RAII |
| `ui-code.md` | `src/ui/**` | 数据驱动布局、无游戏逻辑、响应式、本地化 |
| `network-code.md` | `src/network/**` | 确定性、延迟补偿、带宽优化、安全 |

**深入细节** → 详见 `1-2-5-ccgs-rules.md`（11 条 Rules 详细说明、编码规范）

### 2.6 Director Gates（17 个）

**三层 Gates**：

| 层级 | 数量 | 示例 |
| ------ | ------ | ------ |
| **Tier 1 - Creative Director Gates** | 6 | `CD-PiLLARS`, `CD-GDD-ALIGN`, `CD-SYSTEMS` |
| **Tier 1 - Technical Director Gates** | 6 | `TD-SYSTEM-BOUNDARY`, `TD-FEASIBILITY`, `TD-ARCHITECTURE` |
| **Tier 1 - Producer Gates** | 5 | `PR-SCOPE`, `PR-SPRINT`, `PR-MILESTONE` |

**Review Modes**（审查模式）：

| 模式 | 行为 | 适用场景 |
| ------ | ------ | ---------- |
| `full` | 所有 Gates 激活 | 团队开发、学习用户 |
| `lean` | 仅 PHASE-GATEs | **默认设置** — 独立开发者 |
| `solo` | 跳过所有 Gates | Game jam、原型开发 |

> **说明**：Review Modes 控制 Director Gates 是否执行，平衡质量与速度。

**Gate 裁决格式**：

```text
GATE VERDICTS:

- APPROVE: Ready to proceed

- READY: Minor issues, but can proceed

- CONCERNS: Major issues, recommend revision

- REJECT: Block, must revise

ESCALATION RULES:

- Any REJECT → Overall: FAIL

- Any CONCERNS → Overall: CONCERNS

- All APPROVE/READY → Overall: PASS

```text

**深入细节** → 详见 `1-2-6-ccgs-director-gates.md`（17 个 Director Gates 详细说明、裁决逻辑）

---

## 三、亮点与创新

| 亮点 | 说明 | 相对 CodeStudio 的不足 |
| ------ | ------ | --------------------- |
| **① 结构化游戏开发流程** | 7 个开发阶段，覆盖从脑暴到发布的完整流程 | CodeStudio 的 Lifecycle 只有 4 阶段 |
| **② Agent 协作协议** | 49 个 Agent，明确分工、委托、升级、审查机制 | CodeStudio 的 CAP-5 Router 还未实现 |
| **③ Director Gates** | 17 个门禁，确保输出质量 | Gates 是软性的（自由文本裁决），CodeStudio 是硬性约束（JSON Schema 验证） |
| **④ 路径级规则** | 11 条规则，不同目录强制执行不同编码规范 | CodeStudio 的 GD-2 组织资产还未实现 |
| **⑤ Review Modes** | `full/lean/solo` 三种审查模式，平衡质量与速度 | CodeStudio 没有类似的审查模式 |

**核心不足**（相对 CodeStudio）：

| 不足 | 说明 | CodeStudio 的解决方案 |
| ------ | ------ | --------------------- |
| **① 软性 Gates** | Director Gates 是自由文本裁决，Agent 可以不遵守 | CodeStudio 的 CAP-2 Enforcer 是硬性约束（JSON Schema 验证） |
| **② 静态知识** | 知识是静态的（`.claude/docs/*.md`），不会从实践中学习 | CodeStudio 的 evidence 链闭环（`trace → evidence → knowledge → injection`） |
| **③ 无意图分类** | 依赖用户手动选择 Agent | CodeStudio 的 CAP-5 Router 自动分类意图 |
| **④ 无多 CLI 支持** | 只支持 Claude Code | CodeStudio 的 N+M 架构支持多 CLI |

---

## 四、与 CodeStudio 的对比

### 4.1 定位对比

| 维度 | CCGS | CodeStudio | CodeStudio 的优势 |
| ------ | ------------ | ------------ | ------------------- |
| **定位** | 应用层模板（游戏开发工作流） | 基础设施层（Agent Harness 框架） | CodeStudio 更通用，不绑定特定领域 |
| **依赖** | Claude Code（Anthropic 官方 CLI） | 自己实现 Harness | CodeStudio 支持多 CLI |
| **知识复用** | 静态 `.md` 文档 | `trace → evidence → knowledge → injection` 闭环 | CodeStudio 能从实践中学习 |
| **流程确认** | 软性 Director Gates（自由文本裁决） | 形式化 GD+CC 双轴治理（结构化约束） | CodeStudio 的约束是硬性的，可自动化验证 |
| **复杂度控制** | 49 agents + 72 skills（不可控） | 1（harness) + k（catalog) + N（projects） | CodeStudio 的复杂度可控 |
| **多 CLI 支持** | ❌ 只支持 Claude Code | ✅ 设计上支持多 CLI | CodeStudio 更灵活 |
| **意图分类** | ❌ 依赖用户手动选择 Agent | ✅ CAP-5 Router 自动分类 | CodeStudio 更智能 |
| **四层注入** | ❌ 只有 AgentINJ-L1（规则文件） | ✅ AgentINJ-L1~L4（四层注入机制） | CodeStudio 的注入更全面 |
| **N+M 适配** | ❌ 没有（每个 Agent 完整复制） | ✅ N+M 多 Agent 适配架构 | CodeStudio 避免 N×M 重复 |
| **Trace 记录** | ❌ 没有（只有简单工具调用日志） | ✅ Trace v2（AI 行为全维度记录） | CodeStudio 的追溯更完整 |
| **并发管理** | ❌ 没有（依赖用户手动启动） | ✅ Claim 模型（原子 pop pending session） | CodeStudio 支持并发 session |

**核心结论**：

- CCGS 是**应用层的最佳实践案例**（展示了如何在 Claude Code 的能力边界内实现结构化工作流）

- CodeStudio 是**基础设施层的设计**（学习 CCGS 的优点，但在底层实现上做得更通用、更形式化、更可扩展）

---

## 五、针对 0- 中的问题的解决方案

### 5.1 Q1：知识复用效率低

**CCGS 的解决方案**：

| 机制 | 说明 | 不足 |
| ------ | ------ | ------ |
| **静态文档**（`.claude/docs/*.md`） | 存放游戏设计理论、引擎参考 | 静态，不会从实践中学习 |
| **Skill 封装**（`.claude/skills/*`） | 封装工作流程 | Skill 是静态的，不会进化 |
| **Agent 记忆**（`memory: project/user`） | 跨会话记忆 | 非结构化，难以精确检索 |

**对 CodeStudio 的启发**：

1. **借鉴**：知识文档化（`.md` 文件）

2. **改进**：实现证据链闭环（`trace → evidence → knowledge → injection` 闭环）

### 5.2 Q2：流程确认依赖人工

**CCGS 的解决方案**：

| 机制 | 说明 | 不足 |
| ------ | ------ | ------ |
| **Director Gates**（17 个） | 审查输出质量 | Gates 是软性的，Agent 可以不遵守 |
| **Review Modes**（`full/lean/solo`） | 控制审查严格程度 | 全局设置，不能针对"生产环境"加严 |
| **Agent 层级审批** | Tier 1 审批 Tier 2/3 的输出 | 依赖 Agent 的"诚信"，没有强制机制 |

**对 CodeStudio 的启发**：

1. **借鉴**：Gates 概念（阶段门禁）

2. **改进**：形式化 Gates（JSON Schema 验证 + 自动化检查）

### 5.3 Q3：知识格式不清晰

**CCGS 的解决方案**：

| 知识类型 | 格式 | 示例 |
| --------- | ------ | ------ |
| 静态知识 | `.md` 文档（.claude/docs/*.md） | 游戏设计理论、引擎参考 |
| 流程知识 | Skill（.claude/skills/*.md） | `/gate-check`, `/create-architecture` |
| 约束知识 | Rules（.claude/rules/*.md） | `gameplay-code.md`, `ai-code.md` |

**对 CodeStudio 的启发**：

1. **借鉴**：不同知识用不同格式（.md / skill / rules）

2. **改进**：结构化约束格式（JSON Schema）

### 5.4 Q4：缺乏系统性学习

**CCGS 的解决方案**：

| 机制 | 说明 | 不足 |
| ------ | ------ | ------ |
| **Agent 记忆**（`memory: project/user`） | 跨会话记忆 | 非结构化，难以精确检索 |
| **静态文档**（`.claude/docs/*.md`） | 存放设计理论 | 静态，不会从实践中学习 |

**对 CodeStudio 的启发**：

1. **借鉴**：记忆机制（`memory: project/user`）

2. **改进**：系统性学习机制（`trace → evidence → knowledge → injection` 闭环）

### 5.5 Q5：实践验证不足

**CCGS 的解决方案**：

| 机制 | 说明 | 不足 |
| ------ | ------ | ------ |
| **无** | CCGS 没有系统的实践验证机制 | 难以量化"这个 Gate 的效果如何" |

**对 CodeStudio 的启发**：

1. **实现**：实践验证机制（A/B 测试不同 Gate 配置）

2. **实现**：量化指标（Gate 通过率、审查时间、bug 率）

---

## 六、总结与下一步

### 6.1 核心结论

1. **CCGS 是应用层的最佳实践案例**：展示了如何在 Claude Code 的能力边界内实现结构化工作流

2. **CCGS 的局限性**：软性 Gates、静态知识、缺乏系统性学习

3. **CodeStudio 可以改进的方向**：形式化 Gates、知识进化、多 CLI 支持

### 6.2 下一步

| 任务 | 优先级 | 预计时间 |
| ------ | -------- | --------- |
| **① 实现 CAP-2 Enforcer** | P0 | 1-2 周 |
| **② 实现证据链闭环** | P0 | 2-3 周 |
| **③ 支持多 CLI** | P1 | 1-2 周 |

---

**文档状态**：✅ 第二版完成（主文档 + 子文档结构，总结性输出 + 深入细节拆分）

**子文档列表**：

| 子文档 | 内容 |
| --------- | ------ |
| `1-2-2-ccgs-agents.md` | 49 个 Agent 详细说明（三层结构、协作协议、YAML 配置） |
| `1-2-3-ccgs-skills.md` | 72 个 Skill 详细说明（9 个功能分类、工作流、YAML 配置） |
| `1-2-4-ccgs-hooks.md` | 12 个 Hook 详细说明（4 个 Hook 类型、触发时机、退出码含义） |
| `1-2-5-ccgs-rules.md` | 11 条 Rules 详细说明（路径级规则、编码规范、YAML 配置） |
| `1-2-6-ccgs-director-gates.md` | 17 个 Director Gates 详细说明（三层 Gates、裁决格式、升级规则） |

**下一步**：

- [ ] 与 Hermes Agent 做更详细的对比

- [ ] 与 Claude Code 做更详细的对比

- [ ] 在 letsgo_server 上做真实验证
