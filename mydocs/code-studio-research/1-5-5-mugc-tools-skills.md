# mugc_tools Skill 系统详解

> **文档定位**：深入 mugc_server_ai_tools 的 Skill 系统（69 个模块）。

---

## 一、Skill 系统概述

mucg_server_ai_tools 包含 **69 个 Skill 模块**，存放在 `skills/` 目录。

**核心设计理念**：

- **Skill 目录结构**：每个 Skill 是一个目录，包含 `SKILL.md` 和可选的 `references/` 目录
- **参考文档**：`references/` 目录存放领域知识、规范、示例
- **集中管理**：所有 Skill 通过 symlink 部署到目标项目

---

## 二、Skill 结构约定（统一结构）

```text
skills/<skill-name>/
├── SKILL.md          # 技能定义：触发条件、工作流、输出格式
└── references/       # 参考文档：领域知识、规范、示例
```

**SKILL.md 格式**：

```markdown
---
name: skill-name
description: Skill description
whenToUse: When to use this skill
argumentHint: [arg1] [arg2]
---

# Skill Name
## Workflow
1. Step1
2. Step2
3. ...

## Output Format
...
```

---

## 三、Skill 分类（69 个）

### 3.1 OpenSpec 工作流（10 个）

| Skill 名称 | 说明 |
| ----------- | ------ |
| `openspec-new-change` | 创建新变更提案 |
| `openspec-continue-change` | 继续已有变更 |
| `openspec-apply-change` | 应用变更到代码 |
| `openspec-verify-change` | 验证变更 |
| `openspec-archive-change` | 归档已完成变更 |
| `openspec-bulk-archive-change` | 批量归档变更 |
| `openspec-explore` | 探索现有变更 |
| `openspec-onboard` | 初始化 OpenSpec 工作流 |
| `openspec-publish-wiki` | 发布规范化文档到 Wiki |
| `openspec-review-change` | 审查变更 |
| `openspec-sync-specs` | 同步规格说明 |

### 3.2 代码生成（5 个）

| Skill 名称 | 说明 |
| ----------- | ------ |
| `activity-creator` | 创建 Activity |
| `activity-config-checker` | 检查 Activity 配置 |
| `activity-config-guide-creator` | 创建 Activity 配置指南 |
| `activity-design-doc-reviewer` | 审查 Activity 设计文档 |
| `activity-template-advisor` | Activity 模板建议 |
| `condition-creator` | 创建 Condition |
| `condition-guide` | Condition 指南 |
| `res-creator` | 创建 Resource |
| `res-excel-editor` | 编辑 Resource Excel |
| `spec-creator` | 创建规格说明 |

### 3.3 代码分析（6 个）

| Skill 名称 | 说明 |
| ----------- | ------ |
| `code-reviewer` | 代码审查 |
| `protocol-call-tracer` | 协议调用追踪 |
| `config-usage-tracer` | 配置使用追踪 |
| `java-pkg-split-analyzer` | Java 包拆分分析 |
| `java-unit-test` | Java 单元测试生成 |
| `java-hotpatch-reviewer` | Java 热补丁审查 |

### 3.4 游戏后台专家（4 个）

| Skill 名称 | 说明 |
| ----------- | ------ |
| `game-backend-expert` | 游戏后台领域专家 |
| `drop-system-troubleshooter` | 掉落系统故障排查 |
| `output-control-troubleshooter` | 输出控制故障排查 |
| `gen-new-svr` | 生成新服务器代码 |

### 3.5 辅助工具（10 个）

| Skill 名称 | 说明 |
| ----------- | ------ |
| `brainstorming` | 脑暴工具 |
| `skill-creator` | 创建新 Skill |
| `xlsx` | 处理 Excel 文件 |
| `excel-to-md` | Excel 转 Markdown |
| `import-export` | 导入导出工具 |
| `image-ocr` | 图片 OCR 识别 |
| `prompt-optimizer` | 提示词优化 |
| `strategic-compact` | 策略性上下文压缩 |
| `context-budget` | 上下文预算管理 |
| `token-budget-advisor` | Token 预算建议 |

### 3.6 知识管理（5 个）

| Skill 名称 | 说明 |
| ----------- | ------ |
| `auto-knowledge` | 自动知识沉淀 |
| `qdrant-knowledge-skill` | Qdrant 向量数据库集成 |
| `working-memory` | 工作记忆管理 |
| `architecture-decision-records` | 架构决策记录 |
| `pua` | 项目上下文自动分析 |

### 3.7 团队协作（2 个）

| Skill 名称 | 说明 |
| ----------- | ------ |
| `mugc-team-agent` | MUGCR 团队 Agent |
| `bklog-query` | 蓝鲸日志查询 |
| `bkm-dashboard` | 知识库仪表板 |

### 3.8 项目管理（3 个）

| Skill 名称 | 说明 |
| ----------- | ------ |
| `project-log-search` | 项目日志搜索 |
| `raffle-config-checker` | 抽奖配置检查 |
| `sync-from-letsgo` | 从 LetsGo 同步 |

### 3.9 性能优化（2 个）

| Skill 名称 | 说明 |
| ----------- | ------ |
| `cost-aware-llm-pipeline` | 成本感知的 LLM 管道 |
| `idea-index-profiler` | IDEA 索引性能分析 |

### 3.10 元信息工具（4 个）

| Skill 名称 | 说明 |
| ----------- | ------ |
| `idea-exclude-folders` | IDEA 排除文件夹配置 |
| `time-to-timestamp` | 时间转时间戳 |
| `tlog-analyzer` | 日志分析 |
| `gm-creator` | GM 工具生成 |

### 3.11 王者系列专属（6 个）

| Skill 名称 | 说明 |
| ----------- | ------ |
| `ymzx-env-query` | 王者环境查询 |
| `ymzx-gameplay-query` | 王者玩法查询 |
| `ymzx-log-trace-query` | 王者日志追踪查询 |
| `ymzx-player-issue-troubleshooter` | 王者玩家问题排查 |
| `ymzx-pod-inspector` | 王者 Pod 检查 |
| `ymzx-res-query` | 王者资源查询 |

### 3.12 文档工具（2 个）

| Skill 名称 | 说明 |
| ----------- | ------ |
| `design-doc-reviewer` | 设计文档审查 |
| `wecom-doc-skills` | 企业微信文档技能 |

---

## 四、Skill 部署

**部署方式**：通过 `install/` 脚本，将 `skills/` 链接到对应工具的配置目录。

**部署路径**：

| 工具 | Skill 配置目录 |
| ------ | --------------------- |
| CodeBuddy | `.codebuddy/skills/` |
| Claude Code | `.claude/skills/` |
| Gemini | `.gemini/skills/` |
| Codex | `.codex/skills/` |
| Cursor | `.cursor/skills/` |

---

## 五、与 CCGS Skill 的对比

| 维度 | CCGS Skill | mugc_tools Skill |
| ------ | ------------- | ------------------- |
| **结构** | 单文件（.md） | 目录（SKILL.md + references/） |
| **参考文档** | ❌ 无 | ✅ 有（references/ 目录） |
| **领域专注** | 游戏开发 | 服务器端开发 + Java 生态 + OpenSpec + 王者系列 |

---

**文档状态**：✅ 第二版完成（补充完整的 69 个 Skill 分类）

**下一步**：

- [ ] 补充每个 Skill 的详细说明（SKILL.md 内容、references/ 内容）
- [ ] 补充 Skill 的协作协议（如何与其他 Skill 配合）
