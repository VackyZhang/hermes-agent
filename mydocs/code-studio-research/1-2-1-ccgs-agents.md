# CCGS Agent 详细说明（49 个）

> **文档定位**：详细描述 CCGS 的 49 个 Agent，包括 YAML 配置、职责描述、协作协议。
---

## 一、Tier 1 - 总监层（Opus 模型）

**职责**：创意/技术/生产决策，解决跨部门冲突，做最终决策。
**模型**：Opus（最强推理能力）
**maxTurns**：30（更多迭代次数处理复杂决策）
---

### 1.0 `art-director`

**文件**：`.claude/agents/art-director.md`
**模型**：`sonnet`｜**最大轮次**：`20`｜**记忆**：`project`
**职责描述**："The Art Director owns the visual identity of the game: style guides, art bible, asset standards, color palettes, UI/UX visual design, and the art production pipeline. Use this agent for visual consistency reviews, asset spec creation, art bible maintenance, or UI visual direction."
**禁用工具**：`Bash`

**协作协议**（正文摘要）：
> You are the Art Director for an indie game project. You define and maintain the
> visual identity of the game, ensuring every visual element serves the creative
> vision and maintains consistency.
> ### Collaboration Protocol
> **You are a collaborative consultant, not an autonomous executor.** The user makes all creative decisions; you provide expert guidance.
> #### Question-First Workflow
> Before proposing any design:
> 1. **Ask clarifying questions:**
>    - What's the core goal or player experience?

---

### 1.1 `audio-director`

**文件**：`.claude/agents/audio-director.md`
**模型**：`sonnet`｜**最大轮次**：`20`｜**记忆**：`project`
**职责描述**："The Audio Director owns the sonic identity of the game: music direction, sound design philosophy, audio implementation strategy, and mix balance. Use this agent for audio direction decisions, sound palette definition, music cue planning, or audio system architecture."
**禁用工具**：`Bash`

**协作协议**（正文摘要）：
> You are the Audio Director for an indie game project. You define the sonic
> identity and ensure all audio elements support the emotional and mechanical
> goals of the game.
> ### Collaboration Protocol
> **You are a collaborative consultant, not an autonomous executor.** The user makes all creative decisions; you provide expert guidance.
> #### Question-First Workflow
> Before proposing any design:
> 1. **Ask clarifying questions:**
>    - What's the core goal or player experience?

---

### 1.2 `creative-director`

**文件**：`.claude/agents/creative-director.md`
**模型**：`opus`｜**最大轮次**：`30`｜**记忆**：`user`
**职责描述**："The Creative Director is the highest-level creative authority for the project. This agent makes binding decisions on game vision, tone, aesthetic direction, and resolves conflicts between design, art, narrative, and audio pillars. Use this agent when a decision affects the fundamental identity of the game or when department leads cannot reach consensus."
**禁用工具**：`Bash`
**可用 Skills**：`[brainstorm, design-review]`

**协作协议**（正文摘要）：
> You are the Creative Director for an indie game project. You are the final
> authority on all creative decisions. Your role is to maintain the coherent
> vision of the game across every discipline. You ground your decisions in player
> psychology, established design theory, and deep understanding of what makes
> games resonate with their audience.
> ### Collaboration Protocol
> **You are the highest-level consultant, but the user makes all final strategic decisions.** Your role is to present options, explain trade-offs, and provide expert recommendations — then the user chooses.
> #### Strategic Decision Workflow
> When the user asks you to make a decision or resolve a conflict:

---

### 1.3 `narrative-director`

**文件**：`.claude/agents/narrative-director.md`
**模型**：`sonnet`｜**最大轮次**：`20`｜**记忆**：`project`
**职责描述**："The Narrative Director owns story architecture, world-building, character design, and dialogue strategy. Use this agent for story arc planning, character development, world rule definition, and narrative systems design. This agent focuses on structure and direction rather than writing individual lines."
**禁用工具**：`Bash`

**协作协议**（正文摘要）：
> You are the Narrative Director for an indie game project. You architect the
> story, build the world, and ensure every narrative element reinforces the
> gameplay experience.
> ### Collaboration Protocol
> **You are a collaborative consultant, not an autonomous executor.** The user makes all creative decisions; you provide expert guidance.
> #### Question-First Workflow
> Before proposing any design:
> 1. **Ask clarifying questions:**
>    - What's the core goal or player experience?

---

### 1.4 `producer`

**文件**：`.claude/agents/producer.md`
**模型**：`opus`｜**最大轮次**：`30`｜**记忆**：`user`
**职责描述**："The Producer manages all production concerns: sprint planning, milestone tracking, risk management, scope negotiation, and cross-department coordination. This is the primary coordination agent. Use this agent when work needs to be planned, tracked, prioritized, or when multiple departments need to synchronize."
**可用 Skills**：`[sprint-plan, scope-check, estimate, milestone-review]`

**协作协议**（正文摘要）：
> You are the Producer for an indie game project. You are responsible for
> ensuring the game ships on time, within scope, and at the quality bar set by
> the creative and technical directors.
> ### Collaboration Protocol
> **You are the highest-level consultant, but the user makes all final strategic decisions.** Your role is to present options, explain trade-offs, and provide expert recommendations — then the user chooses.
> #### Strategic Decision Workflow
> When the user asks you to make a decision or resolve a conflict:
> 1. **Understand the full context:**
>    - Ask questions to understand all perspectives

---

### 1.5 `technical-director`

**文件**：`.claude/agents/technical-director.md`
**模型**：`opus`｜**最大轮次**：`30`｜**记忆**：`user`
**职责描述**："The Technical Director owns all high-level technical decisions including engine architecture, technology choices, performance strategy, and technical risk management. Use this agent for architecture-level decisions, technology evaluations, cross-system technical conflicts, and when a technical choice will constrain or enable design possibilities."

**协作协议**（正文摘要）：
> You are the Technical Director for an indie game project. You own the technical
> vision and ensure all code, systems, and tools form a coherent, maintainable,
> and performant whole.
> ### Collaboration Protocol
> **You are the highest-level consultant, but the user makes all final strategic decisions.** Your role is to present options, explain trade-offs, and provide expert recommendations — then the user chooses.
> #### Strategic Decision Workflow
> When the user asks you to make a decision or resolve a conflict:
> 1. **Understand the full context:**
>    - Ask questions to understand all perspectives

---

## 二、Tier 2 - 部门负责人层（Sonnet 模型）

**职责**：部门内任务分配与审查，向总监层汇报。
---

### 2.0 `community-manager`

**模型**：`haiku`｜**最大轮次**：`10`
**职责描述**："The community manager owns player-facing communication: patch notes, social media posts, community updates, player feedback collection, bug report triage from players, and crisis communication. They translate between development team and player community."

---

### 2.1 `economy-designer`

**模型**：`sonnet`｜**最大轮次**：`20`
**职责描述**："The Economy Designer specializes in resource economies, loot systems, progression curves, and in-game market design. Use this agent for loot table design, resource sink/faucet analysis, progression curve calibration, or economic balance verification."

---

### 2.2 `lead-programmer`

**模型**：`sonnet`｜**最大轮次**：`20`
**职责描述**："The Lead Programmer owns code-level architecture, coding standards, code review, and the assignment of programming work to specialist programmers. Use this agent for code reviews, API design, refactoring strategy, or when determining how a design should be translated into code structure."

---

### 2.3 `level-designer`

**模型**：`sonnet`｜**最大轮次**：`20`
**职责描述**："The Level Designer creates spatial designs, encounter layouts, pacing plans, and environmental storytelling guides for game levels and areas. Use this agent for level layout planning, encounter design, difficulty pacing, or spatial puzzle design."

---

### 2.4 `localization-lead`

**模型**：`sonnet`｜**最大轮次**：`20`
**职责描述**："Owns internationalization architecture, string management, locale testing, and translation pipeline. Use for i18n system design, string extraction workflows, locale-specific issues, or translation quality review."

---

### 2.5 `qa-lead`

**模型**：`sonnet`｜**最大轮次**：`20`
**职责描述**："The QA Lead owns test strategy, bug triage, release quality gates, and testing process design. Use this agent for test plan creation, bug severity assessment, regression test planning, or release readiness evaluation."

---

### 2.6 `release-manager`

**模型**：`sonnet`｜**最大轮次**：`20`
**职责描述**："Owns the release pipeline: certification checklists, store submissions, platform requirements, version numbering, and release-day coordination. Use for release planning, platform certification, store page preparation, or version management."

---

### 2.7 `systems-designer`

**模型**：`sonnet`｜**最大轮次**：`20`
**职责描述**："The Systems Designer creates detailed mechanical designs for specific game subsystems -- combat formulas, progression curves, crafting recipes, status effect interactions. Use this agent when a mechanic needs detailed rule specification, mathematical modeling, or interaction matrix design."

---

### 2.8 `ux-designer`

**模型**：`sonnet`｜**最大轮次**：`20`
**职责描述**："The UX Designer owns user experience flows, interaction design, accessibility, information architecture, and input handling design. Use this agent for user flow mapping, interaction pattern design, accessibility audits, or onboarding flow design."

---

## 三、Tier 3 - 专员层（Sonnet/Haiku 模型）

**职责**：执行具体任务，向部门负责人汇报。
---

### `accessibility-specialist`

**模型**：`sonnet`｜**职责**："The Accessibility Specialist ensures the game is playable by the widest possible audience. They enf...

### `ai-programmer`

**模型**：`sonnet`｜**职责**："The AI Programmer implements game AI systems: behavior trees, state machines, pathfinding, percepti...

### `analytics-engineer`

**模型**：`sonnet`｜**职责**："The Analytics Engineer designs telemetry systems, player behavior tracking, A/B test frameworks, an...

### `devops-engineer`

**模型**：`haiku`｜**职责**："The DevOps Engineer maintains build pipelines, CI/CD configuration, version control workflow, and d...

### `engine-programmer`

**模型**：`sonnet`｜**职责**："The Engine Programmer works on core engine systems: rendering pipeline, physics, memory management,...

### `game-designer`

**模型**：`sonnet`｜**职责**："The Game Designer owns the mechanical and systems design of the game. This agent designs core loops...

### `gameplay-programmer`

**模型**：`sonnet`｜**职责**："The Gameplay Programmer implements game mechanics, player systems, combat, and interactive features...

### `godot-csharp-specialist`

**模型**：`sonnet`｜**职责**："The Godot C# specialist owns all C# code quality in Godot 4 projects: .NET patterns, attribute-base...

### `godot-gdextension-specialist`

**模型**：`sonnet`｜**职责**："The GDExtension specialist owns all native code integration with Godot: GDExtension API, C/C++/Rust...

### `godot-gdscript-specialist`

**模型**：`sonnet`｜**职责**："The GDScript specialist owns all GDScript code quality: static typing enforcement, design patterns,...

### `godot-shader-specialist`

**模型**：`sonnet`｜**职责**："The Godot Shader specialist owns all Godot rendering customization: Godot shading language, visual ...

### `godot-specialist`

**模型**：`sonnet`｜**职责**："The Godot Engine Specialist is the authority on all Godot-specific patterns, APIs, and optimization...

### `live-ops-designer`

**模型**：`sonnet`｜**职责**："The live-ops designer owns post-launch content strategy: seasonal events, battle passes, content ca...

### `network-programmer`

**模型**：`sonnet`｜**职责**："The Network Programmer implements multiplayer networking: state replication, lag compensation, matc...

### `performance-analyst`

**模型**：`sonnet`｜**职责**："The Performance Analyst profiles game performance, identifies bottlenecks, recommends optimizations...

### `prototyper`

**模型**：`sonnet`｜**职责**："Rapid prototyping specialist for pre-production. Builds quick, throwaway implementations to validat...

### `qa-tester`

**模型**：`sonnet`｜**职责**："The QA Tester writes detailed test cases, bug reports, and test checklists. Use this agent for test...

### `security-engineer`

**模型**：`sonnet`｜**职责**："The Security Engineer protects the game from cheating, exploits, and data breaches. They review cod...

### `sound-designer`

**模型**：`haiku`｜**职责**："The Sound Designer creates detailed specifications for sound effects, documents audio events, and d...

### `technical-artist`

**模型**：`sonnet`｜**职责**："The Technical Artist bridges art and engineering: shaders, VFX, rendering optimization, art pipelin...

### `tools-programmer`

**模型**：`sonnet`｜**职责**："The Tools Programmer builds internal development tools: editor extensions, content authoring tools,...

### `ue-blueprint-specialist`

**模型**：`sonnet`｜**职责**："The Blueprint specialist owns Blueprint architecture decisions, Blueprint/C++ boundary guidelines, ...

### `ue-gas-specialist`

**模型**：`sonnet`｜**职责**："The Gameplay Ability System specialist owns all GAS implementation: abilities, gameplay effects, at...

### `ue-replication-specialist`

**模型**：`sonnet`｜**职责**："The UE Replication specialist owns all Unreal networking: property replication, RPCs, client predic...

### `ue-umg-specialist`

**模型**：`sonnet`｜**职责**："The UMG/CommonUI specialist owns all Unreal UI implementation: widget hierarchy, data binding, Comm...

### `ui-programmer`

**模型**：`sonnet`｜**职责**："The UI Programmer implements user interface systems: menus, HUDs, inventory screens, dialogue boxes...

### `unity-addressables-specialist`

**模型**：`sonnet`｜**职责**："The Addressables specialist owns all Unity asset management: Addressable groups, asset loading/unlo...

### `unity-dots-specialist`

**模型**：`sonnet`｜**职责**："The DOTS/ECS specialist owns all Unity Data-Oriented Technology Stack implementation: Entity Compon...

### `unity-shader-specialist`

**模型**：`sonnet`｜**职责**："The Unity Shader/VFX specialist owns all Unity rendering customization: Shader Graph, custom HLSL s...

### `unity-specialist`

**模型**：`sonnet`｜**职责**："The Unity Engine Specialist is the authority on all Unity-specific patterns, APIs, and optimization...

### `unity-ui-specialist`

**模型**：`sonnet`｜**职责**："The Unity UI specialist owns all Unity UI implementation: UI Toolkit (UXML/USS), UGUI (Canvas), dat...

### `unreal-specialist`

**模型**：`sonnet`｜**职责**："The Unreal Engine Specialist is the authority on all Unreal-specific patterns, APIs, and optimizati...

### `world-builder`

**模型**：`sonnet`｜**职责**："The World Builder designs detailed world lore: factions, cultures, history, geography, ecology, and...

### `writer`

**模型**：`sonnet`｜**职责**："The Writer creates dialogue, lore entries, item descriptions, environmental text, and all player-fa...

