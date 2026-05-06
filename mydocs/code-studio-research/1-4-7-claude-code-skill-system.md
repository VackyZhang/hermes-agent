# Claude Code Skill 系统详解
> **文档定位**：深入 Claude Code 的 Skill 系统（3 种来源、14 个内置 Skill）。

---

## 一、Skill 系统概述
Claude Code 的 Skill 系统在 `skills/` 目录中实现。

**核心设计理念**：

- **Skill 来源**：bundled / user-defined / plugin
- **Skill 注册**：bundled Skills 在 `skills/bundledSkills.ts` 中注册；user-defined Skills 在 `.claude/commands/` 目录；plugin Skills 在插件初始化时注册
- **Skill 执行**：读取 Skill 定义，按工作流执行

---

## 二、Skill 来源（3 种）
### 2.1 bundled（内置 Skill）
**说明**：Claude Code 内置的 Skill，在 `skills/bundledSkills.ts` 中注册。

**注册示例**：

```typescript
// skills/bundledSkills.ts
import { registerBundledSkill } from './skillRegistry';

export function registerAllBundledSkills() {
  registerBundledSkill({
    name: 'debug',
    description: '调试代码',
    whenToUse: 'When user asks to debug code',
    argumentHint: '[problem description]',
    // ...
  });
  
  registerBundledSkill({
    name: 'verify',
    description: '验证代码',
    whenToUse: 'When user asks to verify code',
    // ...
  });
  
  // ...
}
```text

### 2.2 user-defined（用户定义 Skill）
**说明**：用户定义的 Skill，存放在 `.claude/commands/` 目录，Markdown 文件。

**示例**：

```markdown
<!-- .claude/commands/my-skill.md -->

# My Skill

## Workflow

1. Step 1

2. Step 2

3. ...

## Output Format

...
```text

### 2.3 plugin（插件 Skill）
**说明**：插件定义的 Skill，插件在初始化时调用 `registerPluginSkill()` 注册。

**注册示例**：

```typescript
// plugins/my-plugin/index.ts
import { registerPluginSkill } from '../../skills/skillRegistry';

export function activate(context: PluginContext) {
  registerPluginSkill({
    name: 'my-plugin-skill',
    description: 'My plugin skill',
    whenToUse: 'When user asks to use my plugin',
    // ...
  });
}
```text

---

## 三、Skill Frontmatter（元数据）
| 字段 | 类型 | 说明 |
| ------ | ------ | ------ |
| `name` | string | Skill 名称（必须唯一） |
| `description` | string | Skill 描述（用于 LLM 选择） |
| `whenToUse` | string | 何时使用此 Skill（用于 LLM 自动选择） |
| `argumentHint` | string | 参数提示（显示给用户） |
| `allowedTools` | string[] | 此 Skill 允许使用的工具（白名单） |
| `disableModelInvocation` | boolean | 是否禁用 LLM 调用（纯脚本 Skill） |
| `userInvocable` | boolean | 是否允许用户通过 slash 命令调用（默认 true） |
| `hooks` | HookMatcher[] | 此 Skill 关联的 Hook（Skill 级 Hook） |
| `context` | 'inline' | 'fork' | Skill 执行上下文（inline=当前会话，fork=子 Agent） |
| `agent` | string | 指定子 Agent 名称（当 context='fork' 时） |
| `isEnabled` | () => boolean | 是否启用此 Skill（运行时判断） |
| `isHidden` | boolean | 是否隐藏此 Skill（不显示在帮助中） |

---

## 四、Skill 触发方式（3 种）
### 4.1 slash 命令
**触发方式**：用户通过 `/skill-name` 手动触发。

**示例**：

```text
User: /debug "login failed"
```text

### 4.2 LLM 自动选择
**触发方式**：当 Skill 的 `whenToUse` 匹配时，LLM 自动调用 Skill。

**示例**：

```text
User: Can you review my code?
→ Claude Code 自动调用 /review Skill
```text

### 4.3 Hook 触发
**触发方式**：通过 Hook 系统触发 Skill（例如，`PostToolUse` Hook 触发 `verify` Skill）。

**示例**：

```text
PostToolUse Hook 调用 type: "agent" 触发子 Agent 验证
→ 子 Agent 执行 /verify Skill
```text

---

## 五、内置 Skill 列表（14 个）
| Skill 名称 | 说明 | 触发命令 |
| ----------- | ------ | ---------- |
| `batch` | 批量处理文件 | `/batch` |
| `claudeApi` | 调用 Claude API | `/claude-api` |
| `claudeInChrome` | 在 Chrome 中调试 | `/claude-in-chrome` |
| `debug` | 调试代码 | `/debug` |
| `keybindings` | 查看快捷键绑定 | `/keybindings` |
| `loop` | 循环执行命令 | `/loop` |
| `loremIpsum` | 生成测试文本 | `/lorem-ipsum` |
| `remember` | 记住信息 | `/remember` |
| `scheduleRemoteAgents` | 调度远程 Agent | `/schedule-remote-agents` |
| `simplify` | 简化代码 | `/simplify` |
| `skillify` | 将工作流转换为 Skill | `/skillify` |
| `stuck` | 当 Agent 卡住时使用 | `/stuck` |
| `updateConfig` | 更新配置 | `/update-config` |
| `verify` | 验证代码 | `/verify` |

---

## 六、与 CCGS/Hermes Agent 的对比
### 6.1 与 CCGS 的对比
| 维度 | CCGS | Claude Code |
| ------ | ------- | ------------- |
| **Skill 定义** | Markdown 文件（.claude/skills/*.md） | TypeScript 函数（skills/*.ts） |
| **Skill 发现** | 手动配置（.claude/settings.json） | 自动注册（bundledSkills.ts / plugins） |
| **Skill 执行** | Claude Code 内置执行器 | TypeScript 函数调用 |
| **Skill 来源** | 用户定义（.claude/commands/） | bundled / user-defined / plugin |

### 6.2 与 Hermes Agent 的对比
| 维度 | Claude Code | Hermes Agent |
| ------ | ------------- | -------------- |
| **Skill 定义** | TypeScript 函数（skills/*.ts） | Markdown 文件（skills/<name>/SKILL.md） |
| **Skill 发现** | 自动注册（bundledSkills.ts / plugins） | 自动发现（skills/ 目录） |
| **Skill 执行** | TypeScript 函数调用 | Python 函数调用 |
| **Skill 来源** | bundled / user-defined / plugin | 内置（skills/ 目录） |

---

**文档状态**：✅ 第一版完成（从 `1-4-1-claude-code-analysis.md` 拆分）

**下一步**：

- [ ] 补充更多内置 Skill 的详细说明（从 `skills/` 目录提取）
- [ ] 补充 Skill 执行的详细流程（如何解析 Skill 定义，如何执行工作流）
