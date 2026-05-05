# CCGS Skill 详细说明（72 个）

> **文档定位**：详细描述 CCGS 的 72 个 Skill，包括 YAML 配置、功能描述、使用流程。
---

## 其他（43 个）

---

### `/adopt`

**描述**："Brownfield onboarding — audits existing project artifacts for template format compliance (not just existence), classifies gaps by impact, and produces a numbered migration plan. Run this when joining an in-progress project or upgrading from an older template version. Distinct from /project-stage-detect (which checks what exists) — this checks whether what exists will actually work with the template's skills."
| **参数**：`"[focus: full | gdds | adrs | stories | infra]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> # Adopt — Brownfield Template Adoption
> This skill audits an existing project's artifacts for **format compliance** with
> the template's skill pipeline, then produces a prioritised migration plan.
> **This is not `/project-stage-detect`.**
> `/project-stage-detect` answers: *what exists?*
> `/adopt` answers: *will what exists actually work with the template's skills?*

### `/architecture-decision`

**描述**："Creates an Architecture Decision Record (ADR) documenting a significant technical decision, its context, alternatives considered, and consequences. Every major technical choice should have an ADR."
| **参数**：`"[title] [--review full | lean | solo]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> When this skill is invoked:
> ## 0. Parse Arguments — Detect Retrofit Mode
> Resolve the review mode (once, store for all gate spawns this run):
| > 1. If `--review [full | lean | solo]` was passed → use that |
> 2. Else read `production/review-mode.txt` → use that value
> 3. Else → default to `lean`

### `/art-bible`

**描述**："Guided, section-by-section Art Bible authoring. Creates the visual identity specification that gates all asset production. Run after /brainstorm is approved and before /map-systems or any GDD authoring begins."
| **参数**：`"[--review full | lean | solo]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> ## Phase 0: Parse Arguments and Context Check
> Resolve the review mode (once, store for all gate spawns this run):
| > 1. If `--review [full | lean | solo]` was passed → use that |
> 2. Else read `production/review-mode.txt` → use that value
> 3. Else → default to `lean`
> See `.claude/docs/director-gates.md` for the full check pattern.

**... 还有 40 个 skill（略）**

---

## 协作 & 审查（5 个）

---

### `/architecture-review`

**描述**："Validates completeness and consistency of the project architecture against all GDDs. Builds a traceability matrix mapping every GDD technical requirement to ADRs, identifies coverage gaps, detects cross-ADR conflicts, verifies engine compatibility consistency across all decisions, and produces a PASS/CONCERNS/FAIL verdict. The architecture equivalent of /design-review."
| **参数**：`"[focus: full | coverage | consistency | engine | single-gdd path/to/gdd.md]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> # Architecture Review
> The architecture review validates that the complete body of architectural decisions
> covers all game design requirements, is internally consistent, and correctly targets
> the project's pinned engine version. It is the quality gate between Technical Setup
> and Pre-Production.
> **Argument modes:**
> - **No argument / `full`**: Full review — all phases

### `/code-review`

**描述**："Performs an architectural and quality code review on a specified file or set of files. Checks for coding standard compliance, architectural pattern adherence, SOLID principles, testability, and performance concerns."
**参数**：`"[path-to-file-or-directory]"`
**用户可调用的**：是

**工作流程**（正文摘要）：
> ## Phase 1: Load Target Files
> Read the target file(s) in full. Read CLAUDE.md for project coding standards.
> ## Phase 2: Identify Engine Specialists
> Read `.claude/docs/technical-preferences.md`, section `## Engine Specialists`. Note:

### `/gate-check`

**描述**："Validate readiness to advance between development phases. Produces a PASS/CONCERNS/FAIL verdict with specific blockers and required artifacts. Use when user says 'are we ready to move to X', 'can we advance to production', 'check if we can start the next phase', 'pass the gate'."
| **参数**：`"[target-phase: systems-design | technical-setup | pre-production | production | polish | release] [--review full | lean | solo]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> # Phase Gate Validation
> This skill validates whether the project is ready to advance to the next development
> phase. It checks for required artifacts, quality standards, and blockers.
> **Distinct from `/project-stage-detect`**: That skill is diagnostic ("where are we?").
> This skill is prescriptive ("are we ready to advance?" with a formal verdict).
> ## Production Stages (7)

**... 还有 2 个 skill（略）**

---

## 设计 & 脑暴（7 个）

---

### `/brainstorm`

**描述**："Guided game concept ideation — from zero idea to a structured game concept document. Uses professional studio ideation techniques, player psychology frameworks, and structured creative exploration."
| **参数**：`"[genre or theme hint, or 'open'] [--review full | lean | solo]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> When this skill is invoked:
> 1. **Parse the argument** for an optional genre/theme hint (e.g., `roguelike`,
>    `space survival`, `cozy farming`). If `open` or no argument, start from
>    scratch. Also resolve the review mode (once, store for all gate spawns this run):
| >    1. If `--review [full | lean | solo]` was passed → use that |
>    2. Else read `production/review-mode.txt` → use that value
>    3. Else → default to `lean`

### `/design-review`

**描述**："Reviews a game design document for completeness, internal consistency, implementability, and adherence to project design standards. Run this before handing a design document to programmers."
| **参数**：`"[path-to-design-doc] [--depth full | lean | solo]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> ## Phase 0: Parse Arguments
| > Extract `--depth [full | lean | solo]` if present. Default is `full` when no flag is given. |
> **Note**: `--depth` controls the *analysis depth* of this skill (how many specialist agents are spawned). It is independent of the global review mode in `production/review-mode.txt`, which controls director gate spawning. These are two different concepts — `--depth` is about how thoroughly *this* skill analyses the document.
> - **`full`**: Complete review — all phases + specialist agent delegation (Phase 3b)
> - **`lean`**: All phases, no specialist agents — faster, single-session analysis
> - **`solo`**: Phases 1-4 only, no delegation, no Phase 5 next-step prompt — use when called from within another skill

### `/design-system`

**描述**："Guided, section-by-section GDD authoring for a single game system. Gathers context from existing docs, walks through each required section collaboratively, cross-references dependencies, and writes incrementally to file."
| **参数**：`"<system-name> [--review full | lean | solo]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> When this skill is invoked:
> ## 1. Parse Arguments & Validate
> Resolve the review mode (once, store for all gate spawns this run):
| > 1. If `--review [full | lean | solo]` was passed → use that |
> 2. Else read `production/review-mode.txt` → use that value
> 3. Else → default to `lean`

**... 还有 4 个 skill（略）**

---

## 项目管理（5 个）

---

### `/create-epics`

**描述**："Translate approved GDDs + architecture into epics — one epic per architectural module. Defines scope, governing ADRs, engine risk, and untraced requirements. Does NOT break into stories — run /create-stories [epic-slug] after each epic is created."
| **参数**：`"[system-name | layer: foundation | core | feature | presentation | all] [--review full | lean | solo]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> # Create Epics
> An epic is a named, bounded body of work that maps to one architectural module.
> It defines **what** needs to be built and **who owns it architecturally**. It
> does not prescribe implementation steps — that is the job of stories.
> **Run this skill once per layer** as you approach that layer in development.
> Do not create Feature layer epics until Core is nearly complete — the design
> will have changed.

### `/qa-plan`

**描述**："Generate a QA test plan for a sprint or feature. Reads GDDs and story files, classifies stories by test type (Logic/Integration/Visual/UI), and produces a structured test plan covering automated tests required, manual test cases, smoke test scope, and playtest sign-off requirements. Run before sprint begins or when starting a major feature."
| **参数**：`"[sprint | feature: system-name | story: path]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> # QA Plan
> This skill generates a structured QA plan for a sprint, feature, or individual
> story. It reads all in-scope story files and their referenced GDDs, classifies
> each story by test type, and produces a plan that tells developers exactly what
> to automate, what to verify manually, what the smoke test scope is, and when
> to bring in a playtester.
> Run this before a sprint begins so the team knows upfront what testing work

### `/scope-check`

**描述**："Analyze a feature or sprint for scope creep by comparing current scope against the original plan. Flags additions, quantifies bloat, and recommends cuts. Use when user says 'any scope creep', 'scope review', 'are we staying in scope'."
**参数**：`"[feature-name or sprint-N]"`
**用户可调用的**：是

**工作流程**（正文摘要）：
> # Scope Check
> This skill is read-only — it reports findings but writes no files.
> Compares original planned scope against current state to detect, quantify, and triage
> scope creep.
> **Argument:** `$ARGUMENTS[0]` — feature name, sprint number, or milestone name.

**... 还有 2 个 skill（略）**

---

## 发布 & 部署（4 个）

---

### `/day-one-patch`

**描述**："Prepare a day-one patch for a game launch. Scopes, prioritises, implements, and QA-gates a focused patch addressing known issues discovered after gold master but before or immediately after public launch. Treats the patch as a mini-sprint with its own QA gate and rollback plan."
| **参数**：`"[scope: known-bugs | cert-feedback | all]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> # Day-One Patch
> Every shipped game has a day-one patch. Planning it before launch day prevents
> chaos. This skill scopes the patch to only what is safe and necessary, gates it
> through a lightweight QA pass, and ensures a rollback plan exists before anything
> ships. It is a mini-sprint — not a hotfix, not a full sprint.
> **When to run:**
> - After the gold master build is locked (cert approved or launch candidate tagged)

### `/patch-notes`

**描述**："Generate player-facing patch notes from git history, sprint data, and internal changelogs. Translates developer language into clear, engaging player communication."
| **参数**：`"[version] [--style brief | detailed | full]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> ## Phase 1: Parse Arguments
> - `version`: the release version to generate notes for (e.g., `1.2.0`)
> - `--style`: output style — `brief` (bullet points), `detailed` (with context), `full` (with developer commentary). Default: `detailed`.
> If no version is provided, ask the user before proceeding.

### `/release-checklist`

**描述**："Generates a comprehensive pre-release validation checklist covering build verification, certification requirements, store metadata, and launch readiness."
| **参数**：`"[platform: pc | console | mobile | all]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> > **Explicit invocation only**: This skill should only run when the user explicitly requests it with `/release-checklist`. Do not auto-invoke based on context matching.
> ## Phase 1: Parse Arguments
> Read the argument for the target platform (`pc`, `console`, `mobile`, or `all`). If no platform is specified, default to `all`.
> ## Phase 2: Load Project Context

**... 还有 1 个 skill（略）**

---

## 测试 & 质量保证（8 个）

---

### `/playtest-report`

**描述**："Generates a structured playtest report template or analyzes existing playtest notes into a structured format. Use this to standardize playtest feedback collection and analysis."
| **参数**：`"[new | analyze path-to-notes] [--review full | lean | solo]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> ## Phase 1: Parse Arguments
> Resolve the review mode (once, store for all gate spawns this run):
| > 1. If `--review [full | lean | solo]` was passed → use that |
> 2. Else read `production/review-mode.txt` → use that value
> 3. Else → default to `lean`
> See `.claude/docs/director-gates.md` for the full check pattern.

### `/skill-test`

**描述**："Validate skill files for structural compliance and behavioral correctness. Three modes: static (linter), spec (behavioral), audit (coverage report)."
| **参数**：`"static [skill-name | all] | spec [skill-name] | category [skill-name | all] | audit"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> # Skill Test
> Validates `.claude/skills/*/SKILL.md` files for structural compliance and
> behavioral correctness. No external dependencies — runs entirely within the
> existing skill/hook/template architecture.
> **Four modes:**
| > | Mode | Command | Purpose | Token Cost |

### `/soak-test`

**描述**："Generate a soak test protocol for extended play sessions. Defines what to observe, measure, and log during long play sessions to surface slow leaks, fatigue effects, and edge cases that only appear after sustained play. Primarily used in Polish and Release phases."
| **参数**：`"[duration: 30m | 1h | 2h | 4h] [focus: memory | stability | balance | all]"` |
**用户可调用的**：是

**工作流程**（正文摘要）：
> # Soak Test
> A soak test (also called an endurance test) is an extended play session run
> with specific observation goals. Unlike a smoke check (broad critical path,
> ~10 min) or a single-feature playtest (~30 min), a soak test runs for **30
> minutes to several hours** to surface:
> - **Memory leaks** — gradual heap growth that only appears after scene transitions
> - **Performance drift** — frame time degradation that worsens over time

**... 还有 5 个 skill（略）**

---
