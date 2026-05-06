# Matt Pocock Skills 仓库分析（二）：核心 Skills 深度分析

> **分析对象**：[mattpocock/skills](https://github.com/mattpocock/skills)  
> **分析日期**：2026-05-06  
> **分析目的**：理解 Matt Pocock 的 Skills 设计理念，为 CodeStudio 提供借鉴

**完整分析**：[`1-6-matt-pocock-skills-analysis.md`](./1-6-matt-pocock-skills-analysis.md)（已拆分为 1-6-1 ~ 1-6-4）

---

## 三、核心 Skills 深度分析

### 3.1 diagnose（调试循环）

**核心思想**：**构建反馈循环是 90% 的工作**。有了快速、确定的反馈循环，bug 必然能找到。

#### 六阶段流程

```
Phase 1: Build a feedback loop（构建反馈循环）
   ↓
Phase 2: Reproduce（复现）
   ↓
Phase 3: Hypothesise（提出假设）
   ↓
Phase 4: Instrument（注入探针）
   ↓
Phase 5: Fix + regression test（修复 + 回归测试）
   ↓
Phase 6: Cleanup + post-mortem（清理 + 事后分析）
```

#### 关键设计

1. **Feedback Loop 是核心**：
   - 提供 10 种构建反馈循环的方法（failing test、curl script、CLI invocation、headless browser、replay trace、throwaway harness、property fuzz、bisection、differential、HITL bash script）
   - 优先顺序：从最快、最确定到最慢、最不确定
   - **关键洞察**：没有 feedback loop，任何 stare at code 都救不了你

2. **Hypothesis 必须可证伪**：
   - 生成 3-5 个排名的假设
   - 每个假设必须做出预测："如果 X 是原因，那么改变 Y 会让 bug 消失"
   - 向用户展示排名列表，利用用户领域知识重新排名

3. **Instrument 一次改一个变量**：
   - 优先：Debugger/REPL > Targeted logs > 全量 logs
   - 所有 debug log 必须加唯一前缀（如 `[DEBUG-a4f2]`），方便清理

4. **Regression Test 需要正确的 seam**：
   - 在修复**前**写回归测试
   - 但只在有**正确的 seam**时（测试能 exercise 真实 bug pattern）
   - 如果没有正确 seam，**这就是发现** → 代码架构阻碍了 bug 被锁定 → 交给 `improve-codebase-architecture`

5. **Post-mortem 问"什么能预防这个 bug？"**：
   - 如果答案涉及架构变更 → 交给 `improve-codebase-architecture`
   - 在修复**后**提建议，而非修复前（你现在信息更多）

---

### 3.2 grill-with-docs（对齐会 + 共建语言）

**核心思想**：**对齐会 + 共建领域语言 + 更新文档**，三位一体。

#### 与 grill-me 的区别

| 特性 | grill-me | grill-with-docs |
|------|-----------|------------------|
| **文档更新** | ❌ 无 | ✅ 更新 CONTEXT.md 和 ADRs |
| **领域语言** | ❌ 无 | ✅ 挑战术语，共建语言 |
| **适用场景** | 非代码任务 | 代码任务（需要理解系统设计） |

#### 关键设计

1. **Domain Awareness**（领域意识）：
   - 在会话中，查找 `CONTEXT.md`（领域术语表）
   - 查找 `docs/adr/`（架构决策记录）
   - 如果术语冲突 → 立即指出："你的术语表定义 'cancellation' 为 X，但你好像指的是 Y"

2. **Sharpen Fuzzy Language**（锐化模糊语言）：
   - 当用户使用模糊或重载的术语 → 提出精确的规范术语
   - 示例："你说 'account' — 指的是 Customer 还是 User？它们是不同的东西"

3. **Cross-reference with Code**（与代码交叉引用）：
   - 当用户陈述某个功能如何工作 → 检查代码是否同意
   - 如果发现矛盾 → 提出："你的代码取消了整个 Order，但你刚才说部分取消是可能的 — 哪个是对的？"

4. **Update CONTEXT.md Inline**（实时更新 CONTEXT.md）：
   - 当术语 resolved → 立即更新 `CONTEXT.md`
   - **不要批量更新** → 在发生时立即捕获
   - 格式参考 `CONTEXT-FORMAT.md`

5. **Offer ADRs Sparingly**（谨慎提供 ADR）：
   - 仅当同时满足 3 个条件时才提供 ADR：
     1. **Hard to reverse**（难以逆转）
     2. **Surprising without context**（没有上下文会令人惊讶）
     3. **Result of a real trade-off**（真实权衡的结果）
   - 格式参考 `ADR-FORMAT.md`

---

### 3.3 tdd（测试驱动开发）

**核心思想**：**测试应该验证行为，而非实现细节**。

#### 反模式：Horizontal Slices（水平切片）

❌ **错误方式**：
```
RED:   test1, test2, test3, test4, test5  (写所有测试)
GREEN: impl1, impl2, impl3, impl4, impl5 (写所有实现)
```

**问题**：
- 测试是基于**想象的行为**，而非实际行为
- 测试的是**形状**（数据结构、函数签名），而非用户可见行为
- 测试对真实变化不敏感（行为没变，测试却挂了）
- 你跑出了头灯（outrun your headlights），在实现前就提交了测试结构

✅ **正确方式**：Vertical Slices（垂直切片）

```
RED→GREEN: test1→impl1
RED→GREEN: test2→impl2
RED→GREEN: test3→impl3
```

**优势**：
- 每个测试响应你从上一轮学到的东西
- 因为你刚写了代码，你确切知道什么行为重要，以及如何验证它

---

#### Workflow

1. **Planning**（规划）：
   - 确认接口变更
   - 确认要测试的行为（优先级）
   - 寻找深模块机会（参考：[Deep Modules](https://en.wikipedia.org/wiki/Information_hiding) 设计原则）
   - 为可测试性设计接口（参考：[Interface Design](https://en.wikipedia.org/wiki/Interface_(computing)) 设计原则）
   - **你不能测试所有东西** → 和用户确认哪些行为最重要

2. **Tracer Bullet**（追踪子弹）：
   - 写 ONE 个测试确认 ONE 件事
   - 这是你的追踪子弹 → 证明路径 end-to-end 可行

3. **Incremental Loop**（增量循环）：
   - 一次一个测试
   - 只写足够通过当前测试的代码
   - 不要预测未来测试

4. **Refactor**（重构）：
   - 所有测试通过后，寻找重构机会（参考：[Refactoring Techniques](https://refactoring.guru/refactoring/techniques)）
   - **永远不要在 RED 时重构** → 先到 GREEN

---

#### Good Test vs Bad Test

| 维度 | Good Test | Bad Test |
|------|-----------|----------|
| **验证内容** | 公开接口的行为 | 实现细节 |
| **存活能力** | 重构后仍然通过（行为没变） | 重构后挂掉（行为没变） |
| **示例** | "user can checkout with valid cart" | 测试私有方法、mock 内部协作者 |

**警告信号**：重命名内部函数后测试挂了 → 这些测试在测试实现，而非行为。

---

### 3.4 improve-codebase-architecture（改进代码架构）

**核心思想**：寻找**深化机会**（deepening opportunities）— 将浅模块变为深模块。

#### 关键概念（来自 A Philosophy of Software Design）

| 术语 | 定义 |
|------|------|
| **Module** | 任何有接口和实现的东西（函数、类、包、切片） |
| **Interface** | 调用者必须使用模块的所有知识：类型、不变量、错误模式、顺序、配置。（不仅仅是类型签名） |
| **Implementation** | 内部代码 |
| **Depth**（深度） | 接口的杠杆作用：小接口背后有大量行为。**Deep** = 高杠杆。**Shallow** = 接口几乎和实现一样复杂 |
| **Seam**（缝） | 接口所在的地方；行为可以在不编辑原位的情况下改变。（用这个，而非 "boundary"） |
| **Adapter**（适配器） | 在 seam 上满足接口的具体东西 |
| **Leverage**（杠杆） | 调用者从深度中获得的东西 |
| **Locality**（局部性） | 维护者从深度中获得的东西：变更、bug、知识集中在一个地方 |

---

#### 关键原则

1. **Deletion Test**（删除测试）：
   - 想象删除模块。如果复杂性**消失** → 它是 pass-through（浅模块）。如果复杂性**重新出现在 N 个调用者中** → 它在赚钱（深模块）
   - **"yes, concentrates" 是你要的信号**

2. **Interface is the Test Surface**（接口是测试面）

3. **One adapter = hypothetical seam. Two adapters = real seam.**（一个适配器 = 假设缝。两个适配器 = 真实缝）

---

#### 流程

1. **Explore**（探索）：
   - 读取 `CONTEXT.md` 和 `docs/adr/`
   - 使用 Agent tool（`subagent_type=Explore`）walk 代码库
   - 注意你遇到摩擦的地方：
     - 理解一个概念需要在多个小模块间跳转？
     - 模块是**浅的** — 接口几乎和实现一样复杂？
     - 纯函数被提取出来只是为了可测试性，但真正的 bug 藏在它们如何被调用（没有**局部性**）？
     - 紧耦合的模块穿过它们的 seam 泄漏？
     - 代码库的哪些部分未被测试，或通过当前接口难以测试？

2. **Present Candidates**（提出候选）：
   - 展示深化机会的编号列表
   - 每个候选包括：
     - **Files** — 涉及哪些文件/模块
     - **Problem** — 为什么当前架构导致摩擦
     - **Solution** — 会改变什么的简明英语描述
     - **Benefits** — 用局部性和杠杆解释，以及测试如何改善
   - 使用 `CONTEXT.md` 词汇表用于领域，使用 `LANGUAGE.md` 词汇表用于架构
   - **不要提出接口** → 问用户："你想探索哪个？"

3. **Grilling Loop**（盘问循环）：
   - 一旦用户选择一个候选 → 进入盘问对话
   - 和他们一起 walk 设计树 — 约束、依赖、深化模块的形状、seam 后面是什么、哪些测试能存活
   - **副作用在决策 crystallize 时发生**：
     - 用 `CONTEXT.md` 中没有的概念命名深化模块？→ 添加到 `CONTEXT.md`
     - 对话中锐化模糊术语？→ 更新 `CONTEXT.md`
     - 用户以有分量的理由拒绝候选？→ 提供 ADR

---

### 3.5 to-prd（创建 PRD）

**核心思想**：**不要面试用户 — 直接综合你已经知道的东西**。

#### 与 grill-with-docs 的区别

| 特性 | grill-with-docs | to-prd |
|------|------------------|---------|
| **目的** | 深度规划 + 对齐 | 将对话转为 PRD |
| **面试** | ✅ 大量面试 | ❌ 无面试 |
| **输入** | 用户的模糊想法 | 当前对话上下文 + 代码库理解 |
| **输出** | 更新的 CONTEXT.md + ADRs | PRD 发布到 Issue Tracker |

---

#### PRD 模板

```markdown
## Problem Statement
（用户视角的问题）

## Solution
（用户视角的解决方案）

## User Stories
（长编号列表，格式：As a <actor>, I want <feature>, so that <benefit>）

## Implementation Decisions
（实现决策：模块、接口、技术澄清、架构决策、Schema 变更、API 契约、具体交互）

## Testing Decisions
（测试决策：好测试的定义、要测试的模块、类似测试的先验艺术）

## Out of Scope
（超出范围的东西）

## Further Notes
（关于功能的任何进一步笔记）
```

---

#### 关键设计

1. **Do NOT include specific file paths or code snippets**（不要包含具体文件路径或代码片段）：
   - 它们可能很快过时
   - 例外：如果原型产生了比散文更精确地编码决策的代码段（状态机、reducer、schema、类型形状）→ 在相关决策中内联它

2. **Use the project's domain glossary vocabulary throughout the PRD**（在 PRD 中全程使用项目的领域术语表词汇）

3. **Apply the `needs-triage` label**（应用 `needs-triage` 标签）→ 让它进入正常的 triage 流程

---

### 3.6 to-issues（将 PRD 拆分为独立 issue）

**核心思想**：**用垂直切片（tracer bullets）将计划拆分为独立可抓取的 issues**。

#### 与 Horizontal Slices 的区别

| 维度 | Horizontal Slices | Vertical Slices（Tracer Bullets） |
|------|-------------------|-----------------------------------|
| **切片方式** | 按层切片（前端/后端/测试） | 每个切片贯穿所有层（端到端） |
| **可演示性** | 所有层完成后才能演示 | 每个切片独立完成都可以演示/验证 |
| **依赖关系** | 层间强依赖 | 每个切片相对独立 |

---

#### Vertical Slice 规则

- 每个切片交付一个**窄但完整**的路径贯穿每一层（schema、API、UI、测试）
- 完成的切片可以**独立演示或验证**
- **优先多个薄切片而非少数厚切片**

---

#### 流程

1. **Gather Context**（收集上下文）：
   - 从对话上下文中工作
   - 如果用户传递了 issue 引用（issue number、URL 或路径），从 issue tracker 获取并读取完整 body 和 comments

2. **Explore the codebase (optional)**（探索代码库（可选））：
   - 如果尚未探索代码库，这样做以理解代码的当前状态
   - Issue 标题和描述应使用项目的领域术语表词汇，并尊重所在区域的 ADRs

3. **Draft vertical slices**（起草垂直切片）：
   - 将计划拆分为 **tracer bullet** issues
   - 切片可以是 'HITL' 或 'AFK'
   - HITL 切片需要人类交互（如架构决策或设计审查）
   - AFK 切片可以无需人类交互即可实现和合并
   - **优先 AFK 而非 HITL**

4. **Quiz the user**（询问用户）：
   - 将提议的拆分呈现为编号列表
   - 对于每个切片，显示：
     - **Title**：简短描述性名称
     - **Type**：HITL / AFK
     - **Blocked by**：哪些其他切片必须先完成
     - **User stories covered**：这个切片解决了哪些用户故事（如果源材料有）
   - 询问用户：
     - 粒度感觉对吗？（太粗/太细）
     - 依赖关系正确吗？
     - 任何切片应该合并或进一步拆分吗？
     - 正确的切片标记为 HITL 和 AFK 了吗？
   - 迭代直到用户批准拆分

5. **Publish the issues to the issue tracker**（发布 issues 到 issue tracker）：
   - 对于每个批准的切片，发布一个新 issue 到 issue tracker
   - 使用下面的 issue body 模板
   - 这些 issues 被认为是 ready for AFK agents，所以除非另有指示，否则用正确的 triage label 发布它们
   - 按依赖顺序发布 issues（blockers 优先），这样你可以在 "Blocked by" 字段中引用真实的 issue 标识符

---

#### Issue 模板

```markdown
## Parent

对 issue tracker 上父 issue 的引用（如果源是现有 issue，否则省略此部分）。

## What to build

这个垂直切片的简明描述。描述端到端行为，而非层-by-层的实现。

避免具体文件路径或代码片段 — 它们很快过时。例外：如果原型产生了比散文更精确地编码决策的代码段（状态机、reducer、schema、类型形状），在此内联它并简要说明它来自原型。修剪到决策丰富的部分 — 不是工作演示，只是重要部分。

## Acceptance criteria

- [ ] Criterion1
- [ ] Criterion2
- [ ] Criterion3

## Blocked by

- 对阻塞 ticket 的引用（如果有）

或 "None - can start immediately"（如果没有阻塞）。
```

---

### 3.7 triage（Issue 分类）

**核心思想**：通过**状态机**将 issues 移动到不同角色。

#### 角色定义

**两类角色**：

1. **Category Roles**（类别角色）：
   - `bug` — 东西坏了
   - `enhancement` — 新功能或改进

2. **State Roles**（状态角色）：
   - `needs-triage` — 维护者需要评估
   - `needs-info` — 等待报告者提供更多信息
   - `ready-for-agent` — 完全指定，准备好给 AFK agent
   - `ready-for-human` — 需要人类实现
   - `wontfix` — 不会行动

**规则**：每个 triaged issue 应该**恰好携带一个类别角色和一个状态角色**。

---

#### 状态转换

```
unlabeled → needs-triage
needs-triage → needs-info / ready-for-agent / ready-for-human / wontfix
needs-info → needs-triage（一旦报告者回复）
```

维护者可以随时覆盖 → 标记不寻常的转换并询问 before proceeding。

---

#### 流程

1. **Gather Context**（收集上下文）：
   - 读取完整 issue（body、comments、labels、reporter、dates）
   - 解析任何先前的 triage 笔记，这样你不会重新问已解决的问题
   - 使用项目的领域术语表探索代码库，尊重该区域的 ADRs
   - 读取 `.out-of-scope/*.md` 并提出任何类似于此 issue 的先前拒绝

2. **Recommend**（推荐）：
   - 告诉维护者你的类别和状态推荐及推理，加上与 issue 相关的代码库摘要
   - 等待方向

3. **Reproduce (bugs only)**（复现（仅 bug））：
   - 在任何盘问之前，尝试复现：读取报告者的步骤，trace 相关代码，运行测试或命令
   - 报告发生了什么 — 成功复现并有代码路径、失败复现、或细节不足（强烈的 `needs-info` 信号）
   - 确认的复现制作更强的 agent brief

4. **Grill (if needed)**（盘问（如果需要））：
   - 如果 issue 需要充实 → 运行 `/grill-with-docs` 会话

5. **Apply the outcome**（应用结果）：
   - `ready-for-agent` — 发布 agent brief 评论
   - `ready-for-human` — 与 agent brief 相同的结构，但注意为什么不能委托（判断调用、外部访问、设计决策、手动测试）
   - `needs-info` — 发布 triage 笔记（模板如下）
   - `wontfix` (bug) — 礼貌解释，然后关闭
   - `wontfix` (enhancement) — 写入 `.out-of-scope/`，从评论链接到它，然后关闭
   - `needs-triage` — 应用角色。可选评论如果有部分进度

---

#### Needs-info 模板

```markdown
## Triage Notes

**What we've established so far:**

- point 1
- point 2

**What we still need from you (@reporter):**

- question 1
- question 2
```

Capture everything resolved during grilling under "established so far" so the work isn't lost. Questions must be specific and actionable, not "please provide more info".

---

### 3.8 caveman（压缩通信）

**核心思想**：**超压缩通信模式，削减 ~75% tokens，同时保持完整技术准确性**。

#### 规则

- **Drop**（丢弃）：articles (a/an/the), filler (just/really/basically/actually/simply), pleasantries (sure/certainly/of course/happy to), hedging
- **Fragments OK**（片段可以）
- **Short synonyms**（短同义词）：big → large, fix → "implement a solution for"
- **Abbreviate common terms**（缩写常见术语）：DB/auth/config/req/res/fn/impl
- **Strip conjunctions**（剥离连词）
- **Use arrows for causality**（用箭头表示因果关系）：X -> Y
- **One word when one word enough**（一个词足够时用一个词）

**Technical terms stay exact**（技术术语保持精确）。**Code blocks unchanged**（代码块不变）。**Errors quoted exact**（错误精确引用）。

---

#### 模式

```
[thing] [action] [reason]. [next step].
```

**示例**：

❌ Not:
> Sure! I'd be happy to help you with that. The issue you're experiencing is likely caused by...

✅ Yes:
> Bug in auth middleware. Token expiry check use `<` not `<=`. Fix:

---

#### Auto-Clarity Exception（自动清晰例外）

暂时 drop caveman 用于：
- Security warnings
- Irreversible action confirmations
- Multi-step sequences where fragment order risks misread
- User asks to clarify or repeats question

Resumer caveman after clear part done.

**示例 — destructive op**:

> **Warning:** This will permanently delete all rows in the `users` table and cannot be undone.
>
> ```sql
> DROP TABLE users;
> ```
>
> Caveman resume. Verify backup exist first.

---

### 3.9 zoom-out（获取更广阔视角）

**核心思想**：**告诉 Agent 放大抽象层级，获取 broader context**。

#### 设计

- **非常简单的 Skill**：只有 2 行指令
- **用途**：当用户不熟悉某段代码或需要理解它如何融入 bigger picture 时
- **关键指令**："Go up a layer of abstraction. Give me a map of all the relevant modules and callers, using the project's domain glossary vocabulary."

#### 与 improve-codebase-architecture 的区别

| 维度 | zoom-out | improve-codebase-architecture |
|------|----------|-------------------------------|
| **目的** | 快速获取 broader context | 寻找深化机会 |
| **输出** | 模块和调用者的地图 | 深化机会的候选列表 |
| **复杂度** | 简单（2 行指令） | 复杂（3 阶段流程） |

---

### 3.10 grill-me（对齐会 - 无文档）

**核心思想**：** relentless 面试用户，直到达到共享理解**。

#### 设计

- **与 grill-with-docs 的区别**：不更新文档，仅用于非代码任务
- **流程**：
  1. 一次问一个问题
  2. 如果问题可以通过探索代码库来回答，则探索代码库
  3. 提供你的推荐答案
  4. 等待反馈后再继续

#### 示例问题

- "你想要实现 X 或 Y？"
- "这个功能的边界是什么？"
- "你考虑过 Z 场景吗？"

---

### 3.11 write-a-skill（创建新 Skill）

**核心思想**：**帮助用户在 Claude Code 中创建新 Skill**。

#### Skill 结构

```
skill-name/
├── SKILL.md           # Main instructions（必需）
├── REFERENCE.md       # Detailed docs（如果需要）
├── EXAMPLES.md        # Usage examples（如果需要）
└── scripts/           # Utility scripts（如果需要）
    └── helper.js
```

---

#### SKILL.md 模板

```markdown
---
name: skill-name
description: Brief description of capability. Use when [specific triggers].
---

# Skill Name

## Quick start

[Minimal working example]

## Workflows

[Step-by-step processes with checklists for complex tasks]

## Advanced features

[Link to separate files: See `REFERENCE.md`]
```

---

#### Description 要求

**Description 是 Agent 决定加载哪个 Skill 时看到的唯一东西**。

**目标**：给 Agent 足够的信息知道：
1. 这个 Skill 提供什么能力
2. 何时/为什么触发它（具体关键词、上下文、文件类型）

**格式**：
- 最多 1024 字符
- 用第三人称写
- 第一句：它做什么
- 第二句："Use when [specific triggers]"

**好例子**：
```
Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when user mentions PDFs, forms, or document extraction.
```

**坏例子**：
```
Helps with documents.
```

---

#### 何时添加 Scripts

当以下情况时添加 utility scripts：
- 操作是确定性的（validation、formatting）
- 相同代码会反复生成
- 错误需要显式处理

Scripts 节省 tokens 并提高可靠性（vs 生成的代码）。

---

#### 何时拆分文件

当以下情况时拆分为单独文件：
- SKILL.md 超过 100 行
- 内容有不同领域（finance vs sales schemas）
- 高级功能很少需要

---

#### Review Checklist

起草后，验证：
- [ ] Description 包含触发器（"Use when..."）
- [ ] SKILL.md 在 100 行以下
- [ ] 无时间敏感信息
- [ ] 术语一致
- [ ] 包含具体示例
- [ ] 引用只有一层深

---

### 3.12 prototype（构建可丢弃原型）

**核心思想**：**构建可丢弃的原型来回答问题**，而非直接实现。

#### 两个分支

根据要回答的问题选择分支：

1. **"Does this logic / state model feel right?"** → `LOGIC.md`
   - 构建一个小型交互式终端应用
   - 将状态机推送到难以在纸上推理的案例

2. **"What should this look like?"** → `UI.md`
   - 在单个路由上生成几个完全不同的 UI 变体
   - 可通过 URL 搜索参数和可浮动底部栏切换

---

#### 规则（适用于两个分支）

1. **从第一天就是可丢弃的，并明确标记**：
   - 将原型代码放在实际使用位置附近（紧邻它为之后原型设计的模块或页面），这样上下文显而易见
   - 但命名要让 casual reader 能看出它是原型，而非生产代码
   - 对于可丢弃的 UI 路由，遵守项目已使用的任何路由约定；不要发明新的顶层结构

2. **一个命令运行**：
   - 无论项目现有的任务运行器支持什么 — `pnpm <name>`、`python <path>`、`bun <path>` 等
   - 用户必须能够无需思考即可启动它

3. **默认无持久化**：
   - 状态存在于内存中
   - 持久化是原型**检查的**东西，而非它应该依赖的东西
   - 如果问题明确涉及数据库，使用 scratch DB 或具有清晰 "PROTOTYPE — wipe me" 名称的本地文件

4. **跳过润色**：
   - 无测试，无超出让原型*可运行*的错误处理，无抽象
   - 重点是快速学习然后删除它

5. **Surface the state**：
   - 每次操作后（logic）或每个变体切换时（UI），打印或渲染完整的相关状态，以便用户可以看到发生了什么变化

6. **完成后删除或吸收**：
   - 当原型回答了它的问题，要么删除它，要么将验证的决策折叠到真实代码中 — 不要让它烂在仓库中

---

#### 完成时

原型的**答案**是唯一值得保留的东西。将答案捕获到持久位置（commit message、ADR、issue 或原型旁边的 `NOTES.md`），连同它正在回答的问题。

如果用户在场，捕获就是快速对话；如果不在，留下占位符，以便他们（或你，在下一轮）可以在删除原型之前填写裁决。

---

### 3.13 setup-matt-pocock-skills（初始化配置）

**核心思想**：**为工程 skills 搭建每个仓库的配置**（issue tracker、triage label vocabulary、domain doc layout）。

#### 为什么需要这个 Skill？

工程 skills（`to-issues`、`to-prd`、`triage`、`diagnose`、`tdd`、`improve-codebase-architecture`、`zoom-out`）需要读取每个仓库的配置：
- Issue tracker 在哪里？
- Triage 标签使用什么字符串？
- `CONTEXT.md` 和 `docs/adr/` 在哪里？

这个 skill 就是用来配置这些的。

---

#### 流程

1. **Explore**（探索）：
   - 查看当前仓库以理解其起始状态
   - 读取已存在的东西；不要假设：
     - `git remote -v` 和 `.git/config` — 这是 GitHub 仓库吗？哪个？
     - 仓库根部的 `AGENTS.md` 和 `CLAUDE.md` — 是否存在？是否已经有 `## Agent skills` 部分？
     - 仓库根部的 `CONTEXT.md` 和 `CONTEXT-MAP.md`
     - `docs/adr/` 和任何 `src/*/docs/adr/` 目录
     - `docs/agents/` — 这个 skill 的先前输出是否已存在？
     - `.scratch/` — 表示本地 markdown issue tracker 约定已在使用中

2. **Present findings and ask**（展示发现并询问）：
   - 总结存在什么和缺少什么
   - 然后**一次一个地**引导用户完成三个决策 — 展示一个部分，获取用户的答案，然后移动到下一个
   - 假设用户不知道这些术语的含义。每个部分以简短说明开始（它是什么，为什么这些 skills 需要它，如果他们不同地选择会发生什么变化）。然后显示选择和默认值

   **Section A — Issue tracker：**
   > 说明： "issue tracker" 是此仓库的 issues 所在的位置。`to-issues`、`triage`、`to-prd` 和 `qa` 等 Skills 从中读取并写入 — 它们需要知道是调用 `gh issue create`、在 `.scratch/` 下写入 markdown 文件，还是遵循你描述的其他工作流。选择你实际为此仓库跟踪工作的地方。

   默认姿态：这些 skills 是为 GitHub 设计的。如果 `git remote` 指向 GitHub，提议它。如果 `git remote` 指向 GitLab（`gitlab.com` 或自托管主机），提议 GitLab。否则（或如果用户更喜欢），提供：
   - **GitHub** — issues 存在于仓库的 GitHub Issues 中（使用 `gh` CLI）
   - **GitLab** — issues 存在于仓库的 GitLab Issues 中（使用 [`glab`](https://gitlab.com/gitlab-org/cli) CLI）
   - **Local markdown** — issues 作为此仓库中 `.scratch/<feature>/` 下的文件存在（适用于独立项目或无远程的仓库）
   - **Other**（Jira、Linear 等）— 要求用户用一段文字描述工作流；skill 将将其记录为自由格式散文

   **Section B — Triage label vocabulary：**
   > 说明：当 `triage` skill 处理传入的 issue 时，它通过状态机移动它 — 需要评估、等待报告者、准备好让 AFK agent 接收、准备好让人类接收，或不会修复。要做到这一点，它需要应用标签（或你的 issue tracker 中的等效物），这些标签*你实际已配置*。如果你的仓库已使用不同的标签名称（例如 `bug:triage` 而不是 `needs-triage`），请在此处映射它们，以便 skill 应用正确的标签而不是创建重复项。

   五个规范角色：
   - `needs-triage` — 维护者需要评估
   - `needs-info` — 等待报告者
   - `ready-for-agent` — 完全指定，准备好接收 AFK agent
   - `ready-for-human` — 需要人类实现
   - `wontfix` — 不会行动

   默认：每个角色的字符串等于其名称。询问用户是否要覆盖任何字符串。如果用户的 issue tracker 没有现有标签，默认值没问题。

   **Section C — Domain docs：**
   > 说明：某些 skills（`improve-codebase-architecture`、`diagnose`、`tdd`）读取 `CONTEXT.md` 文件以学习项目的领域语言，并读取 `docs/adr/` 以了解过去的架构决策。他们需要知道仓库是有一个全局上下文还是多个（例如具有单独前端/后端上下文的 monorepo），以便他们在正确的位置查找。

   确认布局：
   - **Single-context** — 一个 `CONTEXT.md` + 仓库根部的 `docs/adr/`。大多数仓库都是这样。
   - **Multi-context** — 根部的 `CONTEXT-MAP.md` 指向每个上下文的 `CONTEXT.md` 文件（通常是 monorepo）。

3. **Confirm and edit**（确认并编辑）：
   - 向用户展示以下内容草案：
     - 要添加到 `CLAUDE.md` / `AGENTS.md` 的 `## Agent skills` 块（参见步骤 4 的选择规则）
     - `docs/agents/issue-tracker.md`、`docs/agents/triage-labels.md`、`docs/agents/domain.md` 的内容
   - 让他们在写入前进行编辑

4. **Write**（写入）：
   - **选择要编辑的文件：**
     - 如果 `CLAUDE.md` 存在，编辑它。
     - 否则如果 `AGENTS.md` 存在，编辑它。
     - 如果两者都不存在，询问用户创建哪个 — 不要为他们选择。
     - 当 `CLAUDE.md` 已存在时（反之亦然），永远不要创建 `AGENTS.md` — 始终编辑已存在的那个。
     - 如果所选文件中的 `## Agent skills` 块已存在，就地更新其内容，而不是附加重复项。不要覆盖用户对周围部分的编辑。

   - **块格式：**
   ```markdown
   ## Agent skills

   ### Issue tracker

   [一行摘要，说明 issues 的跟踪位置]。参见 `docs/agents/issue-tracker.md`。

   ### Triage labels

   [一行摘要，说明标签词汇表]。参见 `docs/agents/triage-labels.md`。

   ### Domain docs

   [一行摘要 — "single-context" 或 "multi-context"]。参见 `docs/agents/domain.md`。
   ```

   - 然后使用此 skill 文件夹中的种子模板写入三个 docs 文件：
     - [issue-tracker-github.md](https://github.com/mattpocock/skills/blob/main/skills/engineering/setup-matt-pocock-skills/issue-tracker-github.md) — GitHub issue tracker
     - [issue-tracker-gitlab.md](https://github.com/mattpocock/skills/blob/main/skills/engineering/setup-matt-pocock-skills/issue-tracker-gitlab.md) — GitLab issue tracker
     - [issue-tracker-local.md](https://github.com/mattpocock/skills/blob/main/skills/engineering/setup-matt-pocock-skills/issue-tracker-local.md) — 本地 markdown issue tracker
     - [triage-labels.md](https://github.com/mattpocock/skills/blob/main/skills/engineering/setup-matt-pocock-skills/triage-labels.md) — 标签映射
     - [domain.md](https://github.com/mattpocock/skills/blob/main/skills/engineering/setup-matt-pocock-skills/domain.md) — 领域文档使用者规则和布局

   对于 "other" issue trackers，使用用户的描述从头编写 `docs/agents/issue-tracker.md`。

5. **Done**（完成）：
   - 告诉用户设置已完成，以及哪些工程 skills 现在将从中读取
   - 提及他们稍后可以直接编辑 `docs/agents/*.md` — 仅当他们想要切换 issue trackers 或从头开始重新启动时，才需要重新运行此 skill

---

### 3.14 git-guardrails-claude-code（Git 安全钩子）

**核心思想**：**在 Claude Code 执行危险 git 命令之前阻止它们**。

#### 被阻止的命令

- `git push`（所有变体，包括 `--force`）
- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

被阻止时，Claude 会看到一条消息，告诉它无权访问这些命令。

---

#### 步骤

1. **Ask scope**（询问范围）：
   - 询问用户：安装到**仅此项目** (`.claude/settings.json`) 还是**所有项目** (`~/.claude/settings.json`)？

2. **Copy the hook script**（复制钩子脚本）：
   - 捆绑的脚本位于：[scripts/block-dangerous-git.sh](scripts/block-dangerous-git.sh)
   - 根据范围将其复制到目标位置：
     - **Project**：`.claude/hooks/block-dangerous-git.sh`
     - **Global**：`~/.claude/hooks/block-dangerous-git.sh`
   - 使用 `chmod +x` 使其可执行

3. **Add hook to settings**（添加钩子到设置）：
   - 添加到适当的设置文件：

   **Project** (`.claude/settings.json`):
   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash",
           "hooks": [
             {
               "type": "command",
               "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-dangerous-git.sh"
             }
           ]
         }
       ]
     }
   }
   ```

   **Global** (`~/.claude/settings.json`):
   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash",
           "hooks": [
             {
               "type": "command",
               "command": "~/.claude/hooks/block-dangerous-git.sh"
             }
           ]
         }
       ]
     }
   }
   ```

   如果设置文件已存在，将钩子合并到现有的 `hooks.PreToolUse` 数组中 — 不要覆盖其他设置。

4. **Ask about customization**（询问自定义）：
   - 询问用户是否要从阻止列表中添加或删除任何模式。相应地编辑复制的脚本。

5. **Verify**（验证）：
   - 运行快速测试：
   ```bash
   echo '{"tool_input":{"command":"git push origin main"}}' | <path-to-script>
   ```
   - 应以代码 2 退出并将 BLOCKED 消息打印到 stderr。

---

### 3.15 scaffold-exercises（搭建练习结构）

**核心思想**：**为编程练习创建目录结构**，包括 sections、problems、solutions 和 explainers。

#### 创建的目录结构

```
exercises/
├── section-1/
│   ├── problem-1/
│   │   ├── README.md          # 问题描述
│   │   ├── solution.ts        # 解决方案
│   │   └── explainer.md      # 解释
│   └── problem-2/
└── section-2/
```

---

### 3.16 setup-pre-commit（设置预提交钩子）

**核心思想**：**设置 Husky pre-commit hooks**，包含 lint-staged、Prettier、type checking 和 tests。

#### 安装的工具

- **Husky** — git hooks 管理器
- **lint-staged** — 对暂存文件运行 linters
- **Prettier** — 代码格式化
- **Type checking** — 类型检查（如果项目使用 TypeScript）
- **Tests** — 测试（如果项目有测试配置）

---

### 3.17 migrate-to-shoehorn（迁移测试）

**核心思想**：**将测试文件从 `as` 类型断言迁移到 @total-typescript/shoehorn**。

#### 为什么需要这个？

`@total-typescript/shoehorn` 提供了更好的类型断言工具，替代了标准的 `as` 断言。

#### 迁移示例

```typescript
// Before
const result = someFunction() as string;

// After
const result = shoehorn(someFunction()) as string;
```

---

**文档结构**：
- [一、仓库概述 + 仓库结构（1-6-1）](./1-6-1-matt-pocock-skills-overview-and-structure.md)
- 二、核心 Skills 深度分析（**本文**）
- [三、与 CodeStudio 的对比 + 核心洞察（1-6-3）](./1-6-3-matt-pocock-skills-vs-codestudio.md)
- [四、行动建议（1-6-4）](./1-6-4-matt-pocock-skills-action-plan.md)
