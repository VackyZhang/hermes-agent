# CodeStudio Research - 索引

> **文档定位**：快速查询所有 Skill、Tool、Hook、Rules 的索引文件。

---

## 一、Skill 索引

### 1.1 CCGS Skill（72 个）

> 详见 [`1-2-2-ccgs-skills.md`](1-2-2-ccgs-skills.md)

| 名称 | 分类 | 用户可调用 |
| ------ | ------ | ------------- |
| `/brainstorm-game-concept` | 设计 & 脑暴 | ✅ |
| `/design-gdd` | 设计 & 脑暴 | ✅ |
| `/design-pillar` | 设计 & 脑暴 | ✅ |
| `/epic-create` | 项目管理 | ❌ |
| `/sprint-plan` | 项目管理 | ❌ |
| `/implement-feature` | 开发 & 实现 | ❌ |
| `/write-code` | 开发 & 实现 | ❌ |
| `/test-unit` | 测试 & 质量保证 | ❌ |
| `/debug-issue` | 测试 & 质量保证 | ❌ |
| `/build-release` | 发布 & 部署 | ❌ |
| `/review-pr` | 协作 & 审查 | ✅ |
| ... | ... | ... |

**统计**：72 个 Skill，分为 6 大类。

---

### 1.2 Hermes Skill（内置 + 可选）

> 详见 [`1-3-4-hermes-skill-system.md`](1-3-4-hermes-skill-system.md)

| 名称 | 来源 | 描述 |
| ------ | ------ | ------ |
| `brainstorm` | 内置 | 头脑风暴 |
| `diagram` | 内置 | 生成图表 |
| `research` | 内置 | 网络搜索 |
| `pdf` | optional-skills | PDF 处理 |
| `docx` | optional-skills | Word 文档处理 |
| `xlsx` | optional-skills | Excel 处理 |

**统计**：内置 3 个，optional-skills 20+ 个。

---

### 1.3 Claude Code Skill（内置）

> 详见 [`1-4-4-claude-code-skill-system.md`](1-4-4-claude-code-skill-system.md)

| 名称 | 来源 | 描述 |
| ------ | ------ | ------ |
| `/brainstorm` | 内置 | 头脑风暴 |
| `/explain` | 内置 | 解释代码 |
| `/fix` | 内置 | 修复 Bug |
| `/optimize` | 内置 | 优化性能 |
| ... | ... | ... |

**统计**：取决于 feature flags，通常 5-10 个。

---

### 1.4 mugc_tools Skill（69 个）

> 详见 [`1-5-4-mugc-tools-skills.md`](1-5-4-mugc-tools-skills.md)

| 分类 | 数量 | 示例 |
| ------ | ------ | ------ |
| 代码审查与协作 | 10 | `review-pr`, `code-review` |
| 代码质量与测试 | 9 | `test-unit`, `lint-check` |
| 文档生成 | 8 | `gen-doc`, `api-doc` |
| DevOps/部署 | 8 | `deploy`, `rollback` |
| 数据分析 | 6 | `analyze-data`, `visualize` |
| Web 开发 | 6 | `setup-frontend`, `setup-backend` |
| Git 工作流 | 5 | `git-commit`, `git-pr` |
| 性能优化 | 4 | `profile`, `optimize-db` |
| 安全 | 4 | `security-audit`, `scan-secrets` |
| 其他 | 9 | `meeting-notes`, `translate` |

**统计**：69 个 Skill，分为 12 大类。

---

### 1.5 Matt Pocock Skills（12 个核心 Skills）

> 详见 [`1-6-matt-pocock-skills-analysis.md`](1-6-matt-pocock-skills-analysis.md)

| 分类 | 数量 | 示例 |
| ------ | ------ | ------ |
| Engineering Skills | 9 | `diagnose`, `grill-with-docs`, `tdd`, `to-prd`, `improve-codebase-architecture` |
| Productivity Skills | 3 | `grill-me`, `caveman`, `write-a-skill` |
| Misc Skills | 4 | `git-guardrails-claude-code`, `setup-pre-commit` |

**统计**：12 个核心 Skills（小而美，可组合）。

---

## 二、Tool 索引

### 2.1 Hermes Tool（50 个，分 8 类）

> 详见 [`1-3-2-hermes-tool-system.md`](1-3-2-hermes-tool-system.md)

| 分类 | 数量 | 示例 |
| ------ | ------ | ------ |
| 文件操作 | 12 | `read_file`, `write_to_file`, `search_file` |
| 终端操作 | 4 | `execute_command`, `execute_in_environment` |
| 记忆操作 | 3 | `query_memory`, `store_memory`, `delete_memory` |
| 视觉操作 | 5 | `take_screenshot`, `analyze_image` |
| 知识库操作 | 4 | `knowledge_base_search`, `knowledge_base_add` |
| 代码操作 | 8 | `codebase_search`, `read_lints`, `replace_in_file` |
| 部署操作 | 6 | `connect_cloud_service`, `invoke_integration` |
| 系统操作 | 8 | `task`, `mcp_get_tool_description`, `automation_update` |

**统计**：50 个 Tool，通过 `tools/registry.py` 自动发现。

---

### 2.2 mugc_tools Command（58 个）

> 详见 [`1-5-3-mugc-tools-commands.md`](1-5-3-mugc-tools-commands.md)

| 分类 | 数量 | 示例 |
| ------ | ------ | ------ |
| 代码审查 | 10 | `review-pr`, `code-review` |
| 测试 | 8 | `test-unit`, `test-integration` |
| 部署 | 8 | `deploy`, `rollback` |
| 文档 | 6 | `gen-doc`, `readme-gen` |
| Git | 6 | `git-commit`, `git-pr` |
| 优化 | 5 | `optimize`, `refactor` |
| 安全 | 4 | `security-audit`, `scan-secrets` |
| 其他 | 11 | `meeting-notes`, `translate` |

**统计**：58 个 Command，存放在 `commands/` 目录。

---

## 三、Hook 索引

### 3.1 CCGS Hook（12 个）

> 详见 [`1-2-3-ccgs-hooks.md`](1-2-3-ccgs-hooks.md)

| 类型 | 数量 | 示例 |
| ------ | ------ | ------ |
| Pre-tool | 4 | `pre-compact-check`, `pre-tool-validation` |
| Post-tool | 4 | `post-compact-summary`, `post-tool-verify` |
| Notification | 2 | `notify-director`, `notify-user` |
| Session-stop | 2 | `session-stop`, `log-agent-stats` |

**统计**：12 个 Hook，存放在 `.claude/hooks/` 目录。

---

### 3.2 Hermes Hook（14 种事件）

> 详见 [`1-3-3-hermes-hook-system.md`](1-3-3-hermes-hook-system.md)

| 事件 | 触发时机 | 典型用途 |
| ------ | ---------- | ---------- |
| `on_tool_call` | 工具调用前 | 权限检查 |
| `on_tool_result` | 工具返回后 | 结果验证 |
| `on_session_start` | Session 开始时 | 加载上下文 |
| `on_session_end` | Session 结束时 | 自动提取记忆 |
| ... | ... | ... |

**统计**：14 种事件，Python 装饰器实现。

---

### 3.3 Claude Code Hook（27 种事件）

> 详见 [`1-4-1-claude-code-hooks.md`](1-4-1-claude-code-hooks.md)

| 事件 | 触发时机 | 典型用途 |
| ------ | ---------- | ---------- |
| `PreToolUse` | 工具调用前 | 权限检查 |
| `PostToolUse` | 工具返回后 | 结果验证 |
| `Notification` | 通知产生时 | 发送通知 |
| `SessionStart` | Session 开始时 | 加载上下文 |
| ... | ... | ... |

**统计**：27 种事件，Bash 脚本实现。

---

## 四、Rules 索引

### 4.1 CCGS Rules（3 条）

> 详见 [`1-2-4-ccgs-rules.md`](1-2-4-ccgs-rules.md)

| 名称 | 适用路径 | 规则内容 |
| ------ | ---------- | ---------- |
| `api-design.rules` | `src/api/**` | API 设计约束 |
| `frontend-style.rules` | `src/ui/**` | 前端代码风格 |
| `database-migration.rules` | `migrations/**` | 数据库迁移规范 |

**统计**：3 条路径级 Rules。

---

### 4.2 mugc_tools Rules（8 条）

> 详见 [`1-5-5-mugc-tools-rules.md`](1-5-5-mugc-tools-rules.md)

| 名称 | 适用路径 | 规则内容 |
| ------ | ---------- | ---------- |
| `code-style.rules` | `**/*.py` | Python 代码风格 |
| `security.rules` | `**/*` | 安全约束 |
| `performance.rules` | `**/*` | 性能要求 |
| ... | ... | ... |

**统计**：8 条 Rules，存放在 `rules/` 目录。

---

## 五、快速导航

### 5.1 按工具查找

- **想了解 Skill？** 跳转至 [一、Skill 索引](#一skill-索引)
- **想了解 Tool？** 跳转至 [二、Tool 索引](#二tool-索引)
- **想了解 Hook？** 跳转至 [三、Hook 索引](#三hook-索引)
- **想了解 Rules？** 跳转至 [四、Rules 索引](#四rules-索引)

### 5.2 按文档查找

- **CCGS 相关**：[`1-2-ccgs-analysis.md`](1-2-ccgs-analysis.md)
- **Hermes 相关**：[`1-3-hermes-analysis.md`](1-3-hermes-analysis.md)
- **Claude Code 相关**：[`1-4-claude-code-analysis.md`](1-4-claude-code-analysis.md)
- **mugc_tools 相关**：[`1-5-mugc-tools-analysis.md`](1-5-mugc-tools-analysis.md)

---

**文档状态**：✅ 第一版完成

**下一步**：

- [ ] 补充缺失的 Skill/Tool/Hook/Rules 详细信息（从详细文档提取）
- [ ] 添加交互式索引（如果支持，如 HTML 版本）
