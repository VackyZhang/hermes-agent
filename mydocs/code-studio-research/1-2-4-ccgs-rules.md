# CCGS Rules 详细说明（11 条）

> **文档定位**：详细描述 CCGS 的 11 条路径级 Rules，包括适用路径、规则内容、正确/错误示例。
---

### `ai-code`

**适用路径**：`['"src/ai/**"']`
**规则内容**：
> # AI Code Rules
> - AI update budget: 2ms per frame maximum — profile to verify
> - All AI parameters must be tunable from data files (behavior tree weights, perception ranges, timers)
> - AI must be debuggable: implement visualization hooks for all AI state (paths, perception cones, decision trees)
> - AI should telegraph intentions — players need time to read and react
> - Prefer utility-based or behavior tree approaches over hard-coded if/else chains
> - Group AI must support formation, flanking, and role assignment from data
> - All AI state machines must log transitions for debugging
> - Never trust AI input from the network without validation

---

### `data-files`

**适用路径**：`['"assets/data/**"']`
**规则内容**：
> # Data File Rules
> - All JSON files must be valid JSON — broken JSON blocks the entire build pipeline
> - File naming: lowercase with underscores only, following `[system]_[name].json` pattern
> - Every data file must have a documented schema (either JSON Schema or documented in the corresponding design doc)
> - Numeric values must include comments or companion docs explaining what the numbers mean
> - Use consistent key naming: camelCase for keys within JSON files
> - No orphaned data entries — every entry must be referenced by code or another data file
> - Version data files when making breaking schema changes
> - Include sensible defaults for all optional fields
> **Correct** naming and structure (`combat_enemies.json`):

---

### `design-docs`

**适用路径**：`['"design/gdd/**"']`
**规则内容**：
> # Design Document Rules
> - Every design document MUST contain these 8 sections: Overview, Player Fantasy, Detailed Rules, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria
> - Formulas must include variable definitions, expected value ranges, and example calculations
> - Edge cases must explicitly state what happens, not just "handle gracefully"
> - Dependencies must be bidirectional — if system A depends on B, B's doc must mention A
> - Tuning knobs must specify safe ranges and what gameplay aspect they affect
> - Acceptance criteria must be testable — a QA tester must be able to verify pass/fail
> - No hand-waving: "the system should feel good" is not a valid specification
> - Balance values must link to their source formula or rationale
> - Design documents MUST be written incrementally: create skeleton first, then fill

---

### `engine-code`

**适用路径**：`['"src/core/**"']`
**规则内容**：
> # Engine Code Rules
> - ZERO allocations in hot paths (update loops, rendering, physics) — pre-allocate, pool, reuse
> - All engine APIs must be thread-safe OR explicitly documented as single-thread-only
> - Profile before AND after every optimization — document the measured numbers
> - Engine code must NEVER depend on gameplay code (strict dependency direction: engine <- gameplay)
> - Every public API must have usage examples in its doc comment
> - Changes to public interfaces require a deprecation period and migration guide
> - Use RAII / deterministic cleanup for all resources
> - All engine systems must support graceful degradation
> - Before writing engine API code, consult `docs/engine-reference/` for the current engine version and verify APIs against the reference docs

---

### `gameplay-code`

**适用路径**：`['"src/gameplay/**"']`
**规则内容**：
> # Gameplay Code Rules
> - ALL gameplay values MUST come from external config/data files, NEVER hardcoded
> - Use delta time for ALL time-dependent calculations (frame-rate independence)
> - NO direct references to UI code — use events/signals for cross-system communication
> - Every gameplay system must implement a clear interface
> - State machines must have explicit transition tables with documented states
> - Write unit tests for all gameplay logic — separate logic from presentation
> - Document which design doc each feature implements in code comments
> - No static singletons for game state — use dependency injection
> **Correct** (data-driven):

---

### `narrative`

**适用路径**：`['"design/narrative/**"']`
**规则内容**：
> # Narrative Rules
> - All new lore must be cross-referenced against existing lore for contradictions
> - Every lore entry must specify canon level: Established / Provisional / Under Review
> - Character dialogue must match the voice profile defined for that character
> - World rules (what is possible/impossible) must be explicitly documented and consistent
> - Mysteries must have documented "true answers" even if players never learn them
> - Faction motivations, relationships, and power structures must be internally logical
> - All narrative text must be localization-ready: no idioms that don't translate, named placeholders for variables
> - No line of dialogue should exceed 120 characters for dialogue box constraints

---

### `network-code`

**适用路径**：`['"src/networking/**"']`
**规则内容**：
> # Network Code Rules
> - Server is AUTHORITATIVE for all gameplay-critical state — never trust the client
> - All network messages must be versioned for forward/backward compatibility
> - Client predicts locally, reconciles with server — implement rollback for mispredictions
> - Handle disconnection, reconnection, and host migration gracefully
> - Rate-limit all network logging to prevent log flooding
> - All networked values must specify replication strategy: reliable/unreliable, frequency, interpolation
> - Bandwidth budget: define and track per-message-type bandwidth usage
> - Security: validate all incoming packet sizes and field ranges

---

### `prototype-code`

**适用路径**：`['"prototypes/**"']`
**规则内容**：
> # Prototype Code Standards (Relaxed)
> Prototypes are throwaway code for validating ideas. Standards are intentionally
> relaxed to maximize iteration speed. The goal is learning, not production quality.
> ## What's Allowed in Prototypes
> - Hardcoded values (no need for data-driven config)
> - Minimal or no doc comments
> - Simple architecture (no dependency injection required)
> - Singletons and global state
> - Copy-pasted code (no need for abstraction)
> - Debug output left in place

---

### `shader-code`

**适用路径**：`['"assets/shaders/**"']`
**规则内容**：
> # Shader Code Standards
> All shader files in `assets/shaders/` must follow these standards to maintain
> visual quality, performance, and cross-platform compatibility.
> ## Naming Conventions
> - File naming: `[type]_[category]_[name].[ext]`
>   - `spatial_env_water.gdshader` (Godot)
>   - `SG_Env_Water` (Unity Shader Graph)
>   - `M_Env_Water` (Unreal Material)
> - Use descriptive names that indicate the material purpose
> - Prefix with shader type: `spatial_`, `canvas_`, `particles_`, `post_`

---

### `test-standards`

**适用路径**：`['"tests/**"']`
**规则内容**：
> # Test Standards
> - Test naming: `test_[system]_[scenario]_[expected_result]` pattern
> - Every test must have a clear arrange/act/assert structure
> - Unit tests must not depend on external state (filesystem, network, database)
> - Integration tests must clean up after themselves
> - Performance tests must specify acceptable thresholds and fail if exceeded
> - Test data must be defined in the test or in dedicated fixtures, never shared mutable state
> - Mock external dependencies — tests should be fast and deterministic
> - Every bug fix must have a regression test that would have caught the original bug
> **Correct** (proper naming + Arrange/Act/Assert):

---

### `ui-code`

**适用路径**：`['"src/ui/**"']`
**规则内容**：
> # UI Code Rules
> - UI must NEVER own or directly modify game state — display only, use commands/events to request changes
> - All UI text must go through the localization system — no hardcoded user-facing strings
> - Support both keyboard/mouse AND gamepad input for all interactive elements
> - All animations must be skippable and respect user motion/accessibility preferences
> - UI sounds trigger through the audio event system, not directly
> - UI must never block the game thread
> - Scalable text and colorblind modes are mandatory, not optional
> - Test all screens at minimum and maximum supported resolutions

---
