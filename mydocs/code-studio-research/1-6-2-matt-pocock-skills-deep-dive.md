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
   - 寻找[深模块](deep-modules.md)机会
   - 为[可测试性](interface-design.md)设计接口
   - **你不能测试所有东西** → 和用户确认哪些行为最重要

2. **Tracer Bullet**（追踪子弹）：
   - 写 ONE 个测试确认 ONE 件事
   - 这是你的追踪子弹 → 证明路径 end-to-end 可行

3. **Incremental Loop**（增量循环）：
   - 一次一个测试
   - 只写足够通过当前测试的代码
   - 不要预测未来测试

4. **Refactor**（重构）：
   - 所有测试通过后，寻找[重构机会](refactoring.md)
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

### 3.6 triage（Issue 分类）

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

### 3.7 caveman（压缩通信）

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

**文档结构**：
- [一、仓库概述 + 仓库结构（1-6-1）](./1-6-1-matt-pocock-skills-overview-and-structure.md)
- 二、核心 Skills 深度分析（**本文**）
- [三、与 CodeStudio 的对比 + 核心洞察（1-6-3）](./1-6-3-matt-pocock-skills-vs-codestudio.md)
- [四、行动建议（1-6-4）](./1-6-4-matt-pocock-skills-action-plan.md)
