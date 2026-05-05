# CodeStudio N+M 多 Agent 适配架构详解

> **⚠️ 重要说明**：本文档描述 CodeStudio 的**设计方案**，当前系统**尚未实现**。
>
> **文档定位**：深入 CodeStudio 的 N+M 多 Agent 适配架构。

---

## 一、N+M 架构模型

**问题**：第一版 CodeStudio 以 Claude Code 为唯一 pilot，若继续为每个 Agent 完整复制上下文内容生成逻辑，将出现：

- **N × M 代码重复**：N 个 catalog 能力 × M 个 Agent = M 份内容拷贝
- **一致性风险**：不同 Agent 看到不同版本的约束 / 技能文本
- **维护成本线性增长**：新增 Agent 需完整实现渲染器

**N+M 架构模型**：

```text
┌─────────────────────────────────────────────────────────┐
│                    catalog/（N=1，共用）                  │
│  constraints/*.md + skills/*/SKILL.md + flows/*.md       │
│  projects/<proj>/input.md + knowledge/*.md               │
└─────────────────────┬───────────────────────────────────┘
                      │ 标准数据（dict list）
                      ▼
┌─────────────────────────────────────────────────────────┐
│              harness/api/server.py（CodeStudioServer）         │
│  MCP 工具：session_start / report_intent /              │
│           record_evidence / query_constraint / ...       │
│  读取 catalog/，向 Agent L3 提供按需查询能力             │
└─────────────────────┬───────────────────────────────────┘
                      │ 标准内容块（project_input / constraints / skills / knowledge）
                      ▼
┌──────────┬──────────┬──────────┬──────────┐  M 个薄适配层
│ claude-  │ codebuddy│  codex   │  gemini  │  harness/adapters/<agent>/
│ code     │          │（规划中）│（规划中）│  renderer.py：格式翻译
│          │          │          │          │  hooks.py：hook handler
└────┬─────┴────┬─────┴──────────┴──────────┘
     │          │
     ▼          ▼
install/       install/
claude-code/   codebuddy/
  CLAUDE.md      CODEBUDDY.md
  settings.json  config.toml
  hooks/         hooks/
```text

---

## 二、职责边界

| 层 | 代码位置 | 职责 | 不做什么 |
| ------ | ---------- | ------ | ---------- |
| **N 层（catalog）** | `catalog/`, `projects/` | 定义约束 / 技能 / 知识的**内容** | 不关心 Agent 格式 |
| **N 层（API server）** | `harness/api/server.py` | 将 catalog 内容通过 MCP 暴露给 Agent | 不输出 Agent 配置文件 |
| **M 层（renderer）** | `harness/adapters/<agent>/renderer.py` | 读取 catalog，**格式翻译**为 Agent 所需文件 | 不定义约束 / 技能内容 |
| **M 层（hooks）** | `harness/adapters/<agent>/hooks.py` | 处理 Agent hook 事件（PreToolUse / PostToolUse / Stop） | 不包含业务逻辑，委托给 CAP |

---

## 三、M 层适配示例

### 3.1 Claude Code 适配（harness/adapters/claude-code/）

**renderer.py**：

```python

# harness/adapters/claude-code/renderer.py

def render_constraints(constraints: list[dict]) -> str:
    """将 catalog constraints 翻译为 Claude Code 格式（CLAUDE.md）"""
    lines = ["# Constraints\n"]
    for c in constraints:
        lines.append(f"## {c['name']}")
        lines.append(c['description'])
        lines.append("")
    return "\n".join(lines)

def render_skills(skills: list[dict]) -> dict[str, str]:
    """将 catalog skills 翻译为 Claude Code 格式（.claude/skills/*/SKILL.md）"""
    result = {}
    for s in skills:
        path = f".claude/skills/{s['name']}/SKILL.md"
        content = f"---\nname: {s['name']}\n---\n\n{s['content']}"
        result[path] = content
    return result
```text

**hooks.py**：

```python

# harness/adapters/claude-code/hooks.py

def handle_pre_tool_use(tool_name: str, tool_params: dict) -> dict:
    """处理 PreToolUse Hook 事件"""

    # 委托给 CAP-2 Enforcer

    from harness.caps.enforcer import check_constraint
    result = check_constraint(tool_name, tool_params)
    return result
```text

### 3.2 CodeBuddy 适配（harness/adapters/codebuddy/）

**renderer.py**：

```python

# harness/adapters/codebuddy/renderer.py

def render_constraints(constraints: list[dict]) -> str:
    """将 catalog constraints 翻译为 CodeBuddy 格式（CODEBUDDY.md）"""

    # 类似 Claude Code，但格式不同

    ...

def render_skills(skills: list[dict]) -> dict[str, str]:
    """将 catalog skills 翻译为 CodeBuddy 格式（.codebuddy/skills/*/SKILL.md）"""

    # 类似 Claude Code，但路径不同

    ...
```text

---

## 四、N+M 架构的优势

| 优势 | 说明 |
| ------ | ------ |
| **避免 N×M 重复** | catalog 内容生成逻辑只需维护一份（在 N 层） |
| **一致性保证** | 所有 Agent 看到相同版本的约束 / 技能文本（来自同一个 catalog） |
| **维护成本低** | 新增 Agent 只需实现薄适配层（renderer.py + hooks.py） |
| **灵活性强** | 可以轻松支持新 Agent（只需添加 M 层适配） |

**与 CCGS 的对比**：

| 维度 | CCGS | CodeStudio |
| ------ | ------- | ------------ |
| **Agent 定义** | 49 个 .md 文件（每个 Agent 一份拷贝） | N+M 架构（catalog 共用，M 层适配） |
| **一致性** | 不同 Agent 可能看到不同版本的约束 / 技能 | 所有 Agent 看到相同版本（来自同一个 catalog） |
| **维护成本** | 修改约束 / 技能需更新 49 个文件 | 修改约束 / 技能只需更新 catalog（自动同步到所有 Agent） |

---

**文档状态**：✅ 第一版完成（从 `1-1-code-studio-analysis.md` 拆分）

**下一步**：

- [ ] 补充更多 M 层适配示例（Codex、Gemini、...）
- [ ] 补充 renderer.py 的单元测试
