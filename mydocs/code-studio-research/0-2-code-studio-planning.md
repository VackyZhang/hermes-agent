# CodeStudio 规划（二）

> **关联文档**：
> - 问题、目标与学习规划：见 [0-1-problems-and-goals.md](./0-1-problems-and-goals.md)
> - 假设与决策：见 [0-3-hypotheses-and-decisions.md](./0-3-hypotheses-and-decisions.md)
> - 行动清单：见 [0-4-action-plan.md](./0-4-action-plan.md)
> - 更新日志：见 [0-5-update-log.md](./0-5-update-log.md)

---

## 一、当前思考（基于 5 个工具的分析）

### 1.1 知识系统：

- ✅ 学习 CodeStudio：N+M 架构，治理驱动开发
- ✅ 学习 CCGS：用 `.claude/docs/*.md` 存放静态知识
- ✅ 学习 CCGS：用 Skill 封装工作流
- ✅ 学习 Hermes Agent：用 Memory 插件管理记忆
- ✅ 学习 mugc_tools：用 OpenSpec 管理上下文
- ⚠️ 问题：静态知识不会进化，需要从实践中学习
- 💡 方向：实现 `trace → evidence → knowledge → injection` 闭环

### 1.2 流程确认：

- ✅ 学习 CCGS：用 Director Gates 做流程确认
- ✅ 学习 CodeStudio：用 GD-1/2 做治理约束
- ⚠️ 问题：Gates 是软性的，Agent 可以不遵守
- 💡 方向：实现形式化门禁（JSON Schema 验证 + 自动化检查）

### 1.3 多 CLI 支持：

- ✅ 学习：CCGS 只支持 Claude Code
- ✅ 学习：Hermes Agent 支持多 Provider
- 💡 方向：设计统一的 Agent 抽象层，支持多 CLI

### 1.4 Agent 系统：

- ✅ 学习 CCGS：49 个 Agent，三层结构
- ✅ 学习 Hermes Agent：AIAgent 核心循环
- ✅ 学习 Claude Code：27 种 Hook 事件
- 💡 方向：形式化 Agent 系统（CAP-5 Router）

### 1.5 Tool 系统：

- ✅ 学习 Hermes Agent：Registry 模式，自动发现
- ✅ 学习 Claude Code：原生工具 + 外部工具
- 💡 方向：通过 MCP 协议接入（通用）

### 1.6 Hook 系统：

- ✅ 学习 Hermes Agent：14 种事件（Pre/Post/Notification/Session-stop）
- ✅ 学习 Claude Code：27 种事件（更细粒度）
- 💡 方向：治理导向的 Hook（CAP-4 Interceptor）

### 1.7 Skill 系统：

- ✅ 学习 CCGS：72 个 Skill，Slash 命令实现
- ✅ 学习 Hermes Agent：内置 + optional-skills
- ✅ 学习 Claude Code：注入机制
- 💡 方向：Skill 即治理单元（GD-2）

---

## 二、如何让 AI 独立完成服务器开发？

> 基于 5 个工具的分析 + AI 自己的理解，探索 CodeStudio 的发展方向。

### 2.1 核心问题

**目标**：让 AI（Claude Code / CodeBuddy CLI）能**独立完成**线上服务器的开发、Review、Debug。

**当前瓶颈**：
1. **知识缺失**：AI 不知道项目上下文（架构、部署流程、常见 bug）
2. **流程无强制**：AI 可能跳过关键步骤（如"部署前必须跑 staging"）
3. **验证能力弱**：AI 能写代码，但无法验证在生产环境是否真的 work
4. **安全风险**：AI 可能做出破坏性操作（误删数据库、错误配置）

---

### 2.2 从 5 个工具中学到的

| 工具 | 贡献 | 局限性 |
|------|----------|----------|
| **CCGS** | ✅ 结构化工作流（7 个阶段）<br>✅ Director Gates（质量门禁） | ❌ Gates 是软性的（Agent 可以不遵守）<br>❌ 静态知识（不会从实践学习） |
| **Claude Code** | ✅ 27 种 Hook 事件（最细粒度）<br>✅ 原生工具 + 外部工具 | ❌ 无内置知识管理<br>❌ 无流程强制执行 |
| **Hermes Agent** | ✅ Memory 插件系统（8 个）<br>✅ Session DB（历史管理） | ❌ 无治理框架<br>❌ 无流程强制执行 |
| **mugc_tools** | ✅ OpenSpec（上下文管理）<br>✅ 服务器开发特化工具 | ❌ 限于特定场景<br>❌ 无形式化门禁 |
| **CodeStudio** | ✅ N+M 架构（解耦）<br>✅ GD 治理（形式化约束）<br>✅ Evidence Chain（闭环） | ⏳ 未实现（需要验证） |

---

### 2.3 CodeStudio 的 3 个核心能力

#### 能力 1：知识系统（Knowledge System）

**目标**：让 AI 能快速获取项目背景知识，不重复劳动。

**设计方向**：
```
trace → evidence → knowledge → injection
   ↓          ↓           ↓            ↓
操作记录   →  提炼知识  →  结构化存储  →  注入上下文
```

**具体实现**：
- **静态知识**（项目架构、部署流程）：`.md` 文档 + OpenSpec
- **动态知识**（常见 bug、调试经验）：从实践中提炼（Evidence Chain）
- **注入机制**：自动注入相关上下文（类似 Claude Code 的 Skill 注入）

**参考**：
- ✅ CCGS：`.claude/docs/*.md`
- ✅ mugc_tools：OpenSpec
- ✅ Hermes Agent：Memory 插件

---

#### 能力 2：流程确认（Process Enforcement）

**目标**：确保关键流程（如生产部署）符合规范，**强制**而非**建议**。

**设计方向**：
```
GD-1（治理定义）→ GD-2（治理实例）→ Enforcer（执行）
   ↓                    ↓                    ↓
定义约束           实例化约束        强制执行约束
```

**具体实现**：
- **形式化 Gates**：JSON Schema 验证（而非 CCGS 的自由文本）
- **自动化检查**：Pre-tool Hook 检查（如"部署前必须跑 staging"）
- **证据收集**：收集操作证据（如"staging 测试通过截图"）
- **人工审批**：高风险操作需要人工确认

**参考**：
- ✅ CCGS：Director Gates（但软性）
- ✅ CodeStudio：GD-1/2（形式化）
- ✅ Claude Code：Pre-tool Hook（但无 Governance 层）

---

#### 能力 3：安全机制（Safety Mechanisms）

**目标**：防止 AI 做出破坏性操作，提供回滚能力。

**设计方向**：
```
Sandbox → Dry-run → Checkpoint → Audit Log
   ↓          ↓          ↓            ↓
隔离环境    预演操作    创建还原点    记录所有操作
```

**具体实现**：
- **沙箱执行**：在 staging 环境先跑（Claude Code 有类似机制）
- **Dry-run 模式**：显示"会做什么"，不实际执行
- **Checkpoint/Restore**：操作前创建还原点（类似 Docker commit）
- **审计日志**：所有操作记录到 Session DB（Hermes Agent 有类似机制）

**参考**：
- ✅ Claude Code：Dry-run 模式
- ✅ Hermes Agent：Session DB
- ❌ CCGS：无安全机制

---

### 2.4 CodeStudio 的差异化定位

| 维度 | Claude Code | CodeStudio |
|------|-------------|-------------|
| **定位** | 通用 Coding Agent | 服务器开发特化 Agent |
| **知识管理** | 静态（.claude/ 目录） | 动态（Evidence Chain） |
| **流程强制** | 无（依赖用户配置 Hook） | 有（GD 治理框架） |
| **安全机制** | 基础（Dry-run） | 增强（Sandbox + Checkpoint） |
| **多 CLI 支持** | ❌ 只支持 Anthropic API | ✅ 支持多 Provider |

---

## 三、核心问题深度思考（基于实践观察）

> 本节记录我们在 CodeStudio 实现过程中的深度思考，从"让AI写代码"到"让AI做系统工程"的跃迁。

---

### 3.1 问题 1：知识全生命周期管理

**核心矛盾**：知识对目标实现非常重要，但如何管理知识的全生命周期？

#### 3.1.1 知识的 5 个生命周期阶段

| 阶段 | 问题 | 当前状态 | 需要解决 |
|------|------|----------|----------|
| **初始化** | 知识从哪来？如何保证初始质量？ | ❌ 无系统化管理 | 需要知识引导框架 |
| **组织** | 如何组织？如何检索？如何保证一致性？ | ❌ 无标准化格式 | 需要知识分类和索引 |
| **注入** | 何时注入？如何注入？注入多少？ | ❌ 无智能注入策略 | 需要相关性匹配算法 |
| **更新** | 如何识别过时知识？如何修正？ | ❌ 无更新机制 | 需要证据链驱动更新 |
| **废弃** | 何时废弃？如何避免误删？ | ❌ 无废弃策略 | 需要知识生命周期策略 |

#### 3.1.2 知识初始化策略

**问题**：第一批知识从哪来？

**选项 1**：人工编写（像 CCGS 的 `.claude/docs/*.md`）
- ✅ 高质量（人类专家编写）
- ✅ 可控（人类审核）
- ❌ 成本高（需要大量时间）
- ❌ 覆盖不全（不可能覆盖所有场景）

**选项 2**：从现有文档自动提取（像 mugc_tools 的 OpenSpec）
- ✅ 低成本（利用现有文档）
- ✅ 覆盖全（所有文档都能用）
- ❌ 质量参差不齐（依赖现有文档质量）
- ❌ 需要后处理（格式化、结构化）

**选项 3**：从实践中提炼（Evidence Chain）
- ✅ 高质量（经过实践验证）
- ✅ 持续进化（自动更新）
- ❌ 冷启动问题（一开始没有实践数据）
- ❌ 需要提炼算法（如何从 trace 中提取知识）

**我的建议**：**三阶段初始化**
1. **阶段 1（冷启动）**：人工编写核心知识（项目架构、部署流程、常见 bug）
2. **阶段 2（积累期）**：从现有文档自动提取（OpenSpec、API 文档）
3. **阶段 3（进化期）**：从实践中提炼（Evidence Chain 自动更新）

---

#### 3.1.3 知识组织策略

**问题**：知识如何组织，才能高效检索和复用？

**维度 1：知识分类**

| 知识类型 | 格式 | 更新频率 | 注入策略 |
|----------|------|----------|----------|
| **静态知识**（项目架构、部署流程） | `.md` 文档 | 低（月度） | 启动时注入 |
| **动态知识**（常见 bug、调试经验） | Evidence Chain | 高（每日） | 按需注入 |
| **流程知识**（GD 治理规则） | JSON Schema | 中（周度） | 流程触发时注入 |
| **上下文知识**（当前任务背景） | 工作记忆 | 实时 | 每次对话注入 |

**维度 2：知识索引**

**问题**：如何快速找到相关知识？

**方案 1**：关键词匹配（像 CCGS）
- ✅ 简单
- ❌ 不准确（同义词、相关词）

**方案 2**：语义搜索（Embedding + Vector DB）
- ✅ 准确（语义相关）
- ❌ 复杂（需要 Embedding 模型）

**方案 3**：混合（关键词 + 语义）
- ✅ 兼顾简单性和准确性
- ❌ 需要设计融合策略

**我的建议**：**方案 3**（混合）
- 静态知识：关键词匹配（简单场景）
- 动态知识：语义搜索（复杂场景）

---

#### 3.1.4 知识注入策略

**问题**：何时注入？如何注入？注入多少？

**核心矛盾**：
- 注入太少 → AI 缺乏上下文，效率低
- 注入太多 → 上下文溢出，成本高

**注入策略设计**

| 触发时机 | 注入内容 | 注入量 | 实现方式 |
|----------|----------|--------|----------|
| **会话启动** | 项目架构、Agent 角色定义 | 多（~2000 tokens） | System Prompt |
| **任务开始** | 任务相关背景（OpenSpec） | 中（~1000 tokens） | User Message |
| **工具调用前** | 工具使用指南 | 少（~500 tokens） | Tool Description |
| **错误发生时** | 相关调试经验（Evidence） | 少（~500 tokens） | User Message |
| **流程门禁前** | GD 治理规则 | 少（~300 tokens） | System Prompt |

**智能注入（未来方向）**：
- 基于任务描述，自动匹配相关知识（RAG）
- 基于历史对话，自动压缩旧知识（Summarization）

---

#### 3.1.5 知识更新策略

**问题**：如何识别过时知识？如何修正？

**过时知识的特征**：
1. **时间特征**：最后一次验证时间 > 阈值（如 30 天）
2. **冲突特征**：新知识（from Evidence Chain）与旧知识冲突
3. **失效特征**：按照旧知识操作，但失败了

**更新流程设计**：
```
检测过时 → 标记可疑 → 人工审核 → 更新或废弃
   ↓          ↓           ↓            ↓
自动检测   打标签     人类专家    更新知识库
```

**Evidence Chain 驱动更新**：
- 每次实践（成功或失败）都生成 Evidence
- Evidence 积累到一定阈值 → 触发知识更新
- 更新后的知识 → 注入到下次实践

---

#### 3.1.6 知识废弃策略

**问题**：何时废弃？如何避免误删？

**废弃条件**：
1. **过期**：最后一次验证时间 > 90 天，且无人引用
2. **冲突**：与新知识冲突，且新知识有更高置信度
3. **失效**：按照该知识操作，连续失败 3 次

**废弃流程**：
```
检测废弃条件 → 标记废弃 → 观察期（7天） → 永久删除
   ↓              ↓            ↓        |
自动检测      打标签      观察是否有人引用  人工干预
```

**安全机制**：
- 废弃的知识不直接删除，而是移到"知识回收站"
- 回收站保留 30 天，期间可以恢复
- 30 天后自动永久删除

---

#### 3.1.7 知识分类框架重构（基于实践观察）

> **核心洞察**：知识不是均质的，不同类型的知识需要不同的处理方式。

**问题背景**：

在实现 CodeStudio 的过程中，我们发现：
- ✅ AI 需要知道如何编译和重启 letsgo_server（固定流程）
- ✅ AI 需要知道如何新增活动类型（需要理解系统设计）
- ❌ 如果都存为"知识文档"，AI 无法直接执行固定流程（需要先读取文档，再执行步骤）
- ❌ 如果都封装为 Skill，上下文知识（如"如何新增活动类型"）又不适合自动化（因为需要理解系统设计，做决策）

**知识分类框架（初步）**：

| 知识类型 | 本质 | 示例 | 应该存为 | 触发方式 |
|---------|------|------|----------|----------|
| **程序性知识**（Procedural） | 固定流程、可自动化 | 编译、重启、部署 | ✅ **Skill**（代码） | 任务触发 |
| **上下文知识**（Contextual） | 任务背景、设计思想 | 如何新增活动类型 | ✅ **Knowledge**（文档） | 上下文注入 |
| **架构性知识**（Architectural） | 系统结构、模块关系 | 项目架构图、依赖关系 | ✅ **Knowledge**（文档） | 会话启动注入 |
| **经验性知识**（Empirical） | 从实践中学习 | 常见 bug、解决方案 | ✅ **Evidence Chain** | 错误时注入 |

**示例分析**：

##### 示例 1：编译和重启 letsgo_server

**本质**：固定流程，步骤不变，可自动化

**如果存为 Knowledge（文档）**：
- ❌ AI 需要先读取文档，再执行步骤（效率低）
- ❌ 文档可能被误读（理解错误）
- ❌ 无法保证执行一致性（每次可能读漏步骤）

**存为 Skill（代码）**：
- ✅ AI 直接调用 `compile_and_restart_server()`，无需读取文档
- ✅ 流程固定，不会出错
- ✅ 可复用，所有需要编译重启的任务都能用

```python
# ~/.hermes/skills/letsgo-server/compile_and_restart.py
def compile_and_restart_server():
    """编译并重启 letsgo_server"""
    # 1. 编译
    run_command("cd /path/to/letsgo_server && make")
    
    # 2. 重启
    run_command("systemctl restart letsgo_server")
    
    # 3. 验证
    check_server_health()
    
    return "Server compiled and restarted successfully"
```

##### 示例 2：在 letsgo_server 中新增活动类型

**本质**：上下文知识，需要理解系统设计、代码结构、设计思想

**如果封装为 Skill**：
- ❌ "新增活动类型"不是固定流程，而是需要**理解系统设计**后做决策
- ❌ 每次新增的活动类型可能不同（登录活动、充值活动、对战活动...）
- ❌ 需要 AI 理解：活动系统的设计模式、数据库表结构、API 接口、前端交互等

**存为 Knowledge（文档）**：
- ✅ 文档可以详细描述活动系统的设计模式
- ✅ AI 可以基于文档做决策（而非盲目执行固定流程）
- ✅ 可以包含示例和最佳实践

```
knowledge_base/
├── letsgo_server/
│   ├── architecture.md          # 系统架构
│   ├── activity_system.md       # 活动系统设计
│   ├── how-to-add-activity.md  # 如何新增活动类型
│   └── common_pitfalls.md      # 常见坑点
```

**注入时机**：
- 当用户说"帮我新增一个XX活动"时，注入 `activity_system.md` + `how-to-add-activity.md`

---

**待解决问题**：
1. ❓ 如何自动识别"程序性知识"和"上下文知识"？（避免人工分类）
2. ❓ 当知识类型变化时（如某个任务从"需要决策"变为"固定流程"），如何迁移？（Knowledge → Skill）
3. ❓ 如何保证 Skill 和 Knowledge 的一致性？（如 Skill 更新了，相关 Knowledge 是否也要更新？）

**状态**：📝 初步分析，待实践验证

---

### 3.2 问题 2：Harness Engineering 模式

**核心思想**：不是直接让 AI 写代码，而是构建一套"工程化框架"（Harness），AI 在框架内工作，框架强制规范、约束、验证。

**类比**：
- ❌ **错误方式**：让 AI 直接开车（无规则、无轨道、无验证）
- ✅ **正确方式**：构建自动驾驶系统（有轨道、有规则、有验证）

---

#### 3.2.1 Harness Engineering 的核心组件

| 组件 | 作用 | 实现方式 |
|------|------|----------|
| **规范层** | 定义"应该做什么" | GD-1 治理定义（JSON Schema） |
| **约束层** | 强制"必须做什么" | GD-2 治理实例 + Enforcer |
| **验证层** | 验证"是否做对了" | Evidence Collection + 自动化测试 |
| **反馈层** | 反馈"做得如何" | Evidence Chain + 知识更新 |

---

#### 3.2.2 如何实现 Harness Engineering？

**步骤 1：定义规范层（GD-1）**

**目标**：用形式化语言定义"应该做什么"。

**示例**：定义"生产部署"规范
```json
{
  "gd_id": "GD-1-deploy-production",
  "name": "生产部署规范",
  "version": "1.0.0",
  "rules": [
    {
      "rule_id": "rule-1",
      "description": "部署前必须在 staging 环境验证通过",
      "validation": {
        "type": "evidence",
        "evidence_type": "staging_test_result",
        "required": true
      }
    },
    {
      "rule_id": "rule-2",
      "description": "必须有回滚方案",
      "validation": {
        "type": "file_exists",
        "file_path": "rollback_plan.md"
      }
    }
  ]
}
```

---

**步骤 2：实例化约束层（GD-2）**

**目标**：将规范实例化为具体项目的约束。

**示例**：为 `letsgo_server` 实例化"生产部署"约束
```json
{
  "gd_id": "GD-2-deploy-production-letsgo",
  "gd_1_id": "GD-1-deploy-production",
  "project": "letsgo_server",
  "instances": [
    {
      "rule_id": "rule-1",
      "evidence_source": {
        "type": "ci_cd",
        "platform": "blueking",
        "pipeline": "letsgo_server_staging"
      }
    }
  ]
}
```

---

**步骤 3：实现验证层（Enforcer）**

**目标**：在关键节点自动验证约束。

**示例**：Pre-tool Hook 验证"生产部署"约束
```python
def pre_deploy_hook(deploy_args):
    # 1. 加载 GD-2 约束
    constraints = load_gd_constraints("GD-2-deploy-production-letsgo")
    
    # 2. 验证 rule-1（staging 测试通过）
    if not check_evidence("staging_test_result"):
        return {
            "allow": False,
            "reason": "Staging 测试未通过，禁止部署"
        }
    
    # 3. 验证 rule-2（回滚方案存在）
    if not os.path.exists("rollback_plan.md"):
        return {
            "allow": False,
            "reason": "缺少回滚方案"
        }
    
    # 4. 所有约束通过
    return {"allow": True}
```

---

**步骤 4：实现反馈层（Evidence Chain）**

**目标**：收集操作证据，用于知识更新和流程改进。

**示例**：部署后收集证据
```python
def post_deploy_hook(deploy_result):
    # 1. 收集证据
    evidence = {
        "type": "production_deploy_result",
        "timestamp": datetime.now().isoformat(),
        "success": deploy_result["success"],
        "error_message": deploy_result.get("error"),
        "staging_evidence_id": deploy_result["staging_evidence_id"]
    }
    
    # 2. 存储到 Evidence Chain
    evidence_id = store_evidence(evidence)
    
    # 3. 触发知识更新（如果部署失败）
    if not deploy_result["success"]:
        trigger_knowledge_update(evidence)
    
    return evidence_id
```

---

#### 3.2.3 Harness Engineering 的优势

| 对比维度 | 直接让 AI 写代码 | Harness Engineering |
|----------|------------------|---------------------|
| **规范性** | ❌ 无规范，AI 随意写 | ✅ 有规范，AI 按规范写 |
| **约束性** | ❌ 无约束，AI 可能跳过关键步骤 | ✅ 有约束，强制关键步骤 |
| **验证性** | ❌ 无验证，依赖人工 Review | ✅ 有验证，自动验证 |
| **进化性** | ❌ 无反馈，无法进化 | ✅ 有反馈，持续进化 |

---

### 3.3 问题 3：AI 的系统思维注入

**核心问题**：我们在实践中发现，AI 在后续问题排查、问题修复时，具有严重的**局部性**：

| 问题 | 表现 | 根本原因 |
|------|------|----------|
| **缺乏全局依赖分析** | 只修改 A，没同步修改 B | AI 缺乏系统视图（System View） |
| **缺乏深层根因分析** | 只从表面修改问题，不修根源 | AI 缺乏根因分析框架 |
| **缺乏架构演进思维** | 不知道何时需要复用、何时需要底层系统优化 | AI 缺乏架构原则（Principles） |

---

#### 3.3.1 解决方案 1：系统视图（System View）注入

**目标**：让 AI 在修改代码前，先理解系统全貌。

**实现方式**：

**1. 系统架构图自动生成**
- 工具：用 `pydeps`（Python）、`dependency-cruiser`（JS）自动生成依赖图
- 注入时机：修改代码前，先注入相关模块的依赖图

**2. 影响面分析工具**
- 工具：让 AI 先运行"影响面分析"（like `grep -r "function_name" .`）
- 注入时机：修改代码前，先注入影响面分析结果

**3. 系统视图注入 Prompt**
```
⚠️ 在修改代码前，你必须：
1. 运行影响面分析：grep -r "{function_name}" .
2. 检查所有调用方，确认是否需要同步修改
3. 检查所有被调用方，确认是否有副作用
4. 如果有疑问，先提问，不要盲目修改

系统架构图：
{architecture_diagram}

当前模块依赖：
{module_dependencies}
```

---

#### 3.3.2 解决方案 2：根因分析框架注入

**目标**：让 AI 在修复 bug 时，先做根因分析，而不是盲目修复。

**实现方式**：

**1. 强制根因分析流程**

在 Bug 修复前，强制 AI 回答以下问题：
```
🔍 根因分析（必须回答，否则不允许修复）：
1. 这个问题的表象是什么？（错误日志、用户反馈）
2. 可能的根因有哪些？（至少列出 3 个）
3. 如何验证每个根因？（实验设计）
4. 哪个根因最可能？（基于证据判断）
5. 修复根因后，是否会引起其他问题？（影响面分析）
```

**2. 根因分析模板注入**

```python
def inject_root_cause_analysis_template():
    return """
🔍 你现在需要修复一个 bug。在提交修复前，必须完成根因分析：

## 根因分析模板
### 1. 问题表象
- 错误日志：{error_log}
- 复现步骤：{reproduce_steps}

### 2. 可能的根因（至少 3 个）
- 根因 1：{hypothesis_1}（可能性：高/中/低）
- 根因 2：{hypothesis_2}（可能性：高/中/低）
- 根因 3：{hypothesis_3}（可能性：高/中/低）

### 3. 验证实验
- 实验 1：{experiment_1}（验证根因 1）
- 实验 2：{experiment_2}（验证根因 2）

### 4. 根因结论
- 确认根因：{confirmed_root_cause}
- 证据：{evidence}

### 5. 修复方案
- 修复方案：{fix_plan}
- 影响面分析：{impact_analysis}
- 回归测试：{regression_test_plan}

⚠️ 未完成根因分析前，不允许提交修复！
"""
```

**3. 验证机制**
- Pre-commit Hook 检查：是否包含根因分析文档
- Code Review 检查：修复是否针对根因，还是表象

---

#### 3.3.3 解决方案 3：架构原则（Principles）注入

**目标**：让 AI 在做架构决策时，遵循架构原则，而不是随意决策。

**实现方式**：

**1. 架构原则库**

为 `letsgo_server` 定义架构原则：
```markdown
## letsgo_server 架构原则

### 原则 1：复用优先
- **定义**：如果有现成的模块/函数，优先复用，而不是重新实现
- **例外**：如果现有模块设计不合理，先重构，再复用
- **验证**：修改代码前，先搜索是否有现成模块

### 原则 2：底层优化优先
- **定义**：如果性能瓶颈在底层，优先优化底层，而不是在应用层打补丁
- **例外**：如果底层优化成本太高，可以先在应用层临时解决，但必须创建 Tech Debt 卡片
- **验证**：性能问题出现时，先用 profiling 工具找到瓶颈

### 原则 3：系统思考
- **定义**：任何修改，都要思考对系统其他部分的影响
- **例外**：无例外，这是强制原则
- **验证**：修改代码前，必须完成影响面分析

### 原则 4：Tech Debt 管理
- **定义**：任何临时方案，都必须创建 Tech Debt 卡片，并设定还款计划
- **例外**：无例外
- **验证**：代码中出现 `HACK`、`TEMP`、`WORKAROUND` 时，必须有对应的 Tech Debt ID
```

**2. 架构原则注入 Prompt**
```
⚠️ 你现在需要做架构决策。在提交代码前，必须遵循以下架构原则：

{architecture_principles}

⚠️ 如果你的修改违反某个原则，必须在 Commit Message 中说明原因！
```

**3. 架构决策记录（ADR）自动生成**
- 如果 AI 的修改涉及架构变更，自动生成 ADR（Architecture Decision Record）
- ADR 包含：决策背景、决策内容、决策理由、替代方案、后果

---

#### 3.3.4 解决方案 4：系统思维训练（System Thinking Training）

**目标**：通过实践，训练 AI 的系统思维。

**实现方式**：

**1. 系统思维案例库**
- 收集"好案例"（有系统思维的决策）和"坏案例"（局部优化的决策）
- 注入到 AI 的上下文中，作为参考

**2. 反思机制（Reflection Mechanism）**
- 每次修改后，强制 AI 反思：
  ```
  🤔 反思（必须回答）：
  1. 我的修改是否有系统思维？还是局部优化？
  2. 我的修改是否遵循了架构原则？
  3. 如果重新做一遍，我会怎么做？
  ```

**3. 人类反馈循环**
- 人类 Review 时，标注"有系统思维"或"局部优化"
- 反馈给 AI，用于更新知识库

---

### 3.4 问题 4：CodeStudio 不仅仅是 Coding，还包括系统设计、系统优化、整体迭代

**核心认知**：CodeStudio 不是"AI 代码生成器"，而是"AI 系统工程助手"。

---

#### 3.4.1 CodeStudio 的能力金字塔

```
                    ┌─────────────────┐
                    │  系统演进能力   │  ← 最高层：架构演进、技术债管理
                    └─────────────────┘
                   ┌───────────────────┐
                   │  系统优化能力     │  ← 第三层：性能优化、稳定性优化
                   └───────────────────┘
                  ┌─────────────────────┐
                  │  系统设计能力       │  ← 第二层：架构设计、模块设计
                  └─────────────────────┘
                 ┌───────────────────────┐
                 │  代码生成能力         │  ← 第一层（基础）：代码生成、Bug 修复
                 └───────────────────────┘
```

---

#### 3.4.2 如何让 AI 具备系统演进能力？

**1. 技术债管理**
- 工具：自动检测代码中的 `HACK`、`TEMP`、`WORKAROUND`
- 流程：自动创建 Tech Debt 卡片，并设定还款计划
- 注入：在每次迭代规划时，注入 Tech Debt 列表

**2. 架构演进规划**
- 工具：自动生成架构图，对比"当前架构"和"目标架构"
- 流程：在每次大版本发布前，做架构演进规划
- 注入：在架构演进任务时，注入架构演进原则

**3. 系统思考训练**
- 工具：系统思维案例库 + 反思机制
- 流程：每次修改后，强制反思
- 注入：在复杂任务时，注入系统思考框架

---

#### 3.4.3 CodeStudio 的终极目标

**不是**：让 AI 替代人类做系统工程（不可能）
**而是**：让 AI 成为人类系统工程师的"超级助手"：
- 人类负责：架构决策、系统设计、关键代码 Review
- AI 负责：代码生成、Bug 修复、影响面分析、根因分析、技术债管理

**分工原则**：
- AI 做"重复性、规则性、分析性"工作
- 人类做"创造性、判断性、决策性"工作

---

## 四、开放问题（需要验证）

> 本节专注于需要实践验证的具体问题。设计决策记录见 [0-3-hypotheses-and-decisions.md](./0-3-hypotheses-and-decisions.md)。

### 4.1 Q1：知识系统如何设计？

**选项 1**：静态知识（.md 文档）
- ✅ 简单，易于 humans 编写
- ❌ 不会进化，可能过时

**选项 2**：动态知识（Evidence Chain）
- ✅ 从实践中学习，持续改进
- ❌ 复杂，需要设计提炼算法

**选项 3**：混合（静态 + 动态）
- ✅ 兼顾简单性和进化能力
- ❌ 需要设计融合机制

**我的建议**：**选项 3**（混合）
- 静态知识：项目架构、部署流程（稳定，不常变）
- 动态知识：常见 bug、调试经验（易变，需持续更新）

---

### 4.2 Q2：流程强制如何实现？

**选项 1**：软性 Gates（像 CCGS）
- ✅ 简单，易于实现
- ❌ Agent 可以不遵守

**选项 2**：形式化 Gates（JSON Schema 验证）
- ✅ 可自动化验证
- ❌ 需要设计 Schema

**选项 3**：Hook + Governance（像 CodeStudio 设计的）
- ✅ 强制执行，可自动化
- ❌ 复杂，需要设计 Enforcer

**我的建议**：**选项 3**（Hook + Governance）
- Pre-tool Hook 检查 Gates 状态
- Enforcer 强制执行（exit code ≠ 0 → 阻断操作）
- Evidence 收集（证明 Gates 已通过）

---

### 4.3 Q3：如何验证 AI 的输出？

**选项 1**：人工验证（像现在）
- ✅ 安全
- ❌ 慢，成本高

**选项 2**：自动化测试（Unit + Integration + E2E）
- ✅ 快速，可重复
- ❌ 需要写测试（可能 AI 也要写）

**选项 3**：金丝雀发布（Canary Deployment）
- ✅ 真实流量验证
- ❌ 需要基础设施支持

**我的建议**：**选项 2 + 选项 3**（混合）
- 自动化测试：覆盖核心路径
- 金丝雀发布：小流量验证
- 自动回滚：失败 → 自动回滚

---

**文档状态**：📝 持续更新

**下一步**：
- [ ] 查看假设与决策：[0-3-hypotheses-and-decisions.md](./0-3-hypotheses-and-decisions.md)
- [ ] 查看行动清单：[0-4-action-plan.md](./0-4-action-plan.md)
