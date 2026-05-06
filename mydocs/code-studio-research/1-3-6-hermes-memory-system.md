# Hermes Agent 记忆系统详解

> **文档定位**：深入 Hermes Agent 的记忆系统（hermes_state.py + plugins/memory/）。

---

## 一、记忆系统概述

Hermes Agent 的记忆系统在 `hermes_state.py` 和 `plugins/memory/` 目录中实现。

**核心设计理念**：

- **Session DB**：`hermes_state.py` 实现 Session DB（SQLite），存储对话历史，支持 FTS5 搜索

- **Memory 插件**：`plugins/memory/` 目录存放 Memory 插件（honcho, mem0, supermemory, ...），实现跨会话记忆

- **项目文档**：`.hermes/docs/*.md`，项目特定的知识文档

- **记忆注入时机**：Session 启动时注入 Session DB 中的历史对话；按需查询时调用 `query_memory` MCP 工具

---

## 二、Session DB（hermes_state.py）

### 2.1 Session DB 结构

**SQLite 表结构**：

```sql
-- sessions 表：存储 Session 元数据（实际实现，hermes_state.py 第 43-50 行）
CREATE TABLE IF NOT EXISTS sessions (
    session_id TEXT PRIMARY KEY,
    platform TEXT NOT NULL,
    user_id TEXT NOT NULL,
    chat_id TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- messages 表：存储消息历史（实际实现，hermes_state.py 第 52-61 行）
CREATE TABLE IF NOT EXISTS messages (
    message_id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    role TEXT NOT NULL,
    content TEXT,
    tool_call_id TEXT,
    tool_name TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY(session_id) REFERENCES sessions(session_id)
);

-- messages_fts 表：FTS5 虚拟表，用于全文搜索（实际实现，hermes_state.py 第 63-68 行）
CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(
    content,
    content='messages',
    content_rowid='message_id'
);
```text

> **注意**：实际实现使用 `TEXT` 类型存储时间（SQLite 推荐做法），并有 `NOT NULL` 约束和默认值。

### 2.2 Session DB 操作

```python

# hermes_state.py

class SessionDB:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.conn = sqlite3.connect(db_path)
        self.conn.row_factory = sqlite3.Row
        self._create_tables()
    
    def _create_tables(self):
        """Create tables if not exist."""

        # ... (see above SQL)
    
    def create_session(self, session_id: str, platform: str, user_id: str, chat_id: str):
        """Create a new session."""
        self.conn.execute(
            "INSERT INTO sessions (session_id, platform, user_id, chat_id, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            (session_id, platform, user_id, chat_id, now(), now())
        )
        self.conn.commit()
    
    def add_message(self, session_id: str, role: str, content: str, tool_call_id: str = None, tool_name: str = None):
        """Add a message to the session."""
        cursor = self.conn.execute(
            "INSERT INTO messages (session_id, role, content, tool_call_id, tool_name, created_at) VALUES (?, ?, ?, ?, ?, ?)",
            (session_id, role, content, tool_call_id, tool_name, now())
        )
        message_id = cursor.lastrowid
        
        # Update FTS index

        self.conn.execute(
            "INSERT INTO messages_fts (rowid, content) VALUES (?, ?)",
            (message_id, content)
        )
        self.conn.commit()
        return message_id
    
    def search_messages(self, query: str, session_id: str = None) -> list[dict]:
        """Search messages using FTS5."""
        sql = """
            SELECT m.* FROM messages m
            JOIN messages_fts f ON m.message_id = f.rowid
            WHERE messages_fts MATCH ?
        """
        params = [query]
        if session_id:
            sql += " AND m.session_id = ?"
            params.append(session_id)
        
        cursor = self.conn.execute(sql, params)
        return [dict(row) for row in cursor.fetchall()]
```text

---

## 三、Memory 插件（plugins/memory/）

### 3.1 Memory 插件结构

```text
plugins/memory/<plugin-name>/
├── plugin.py          # 插件主文件：实现 MemoryProvider 接口
└── config.yaml        # 插件配置
```text

**MemoryProvider 接口**：

```python

# plugins/memory/memory_provider.py

class MemoryProvider:
    """Interface for memory providers."""
    
    def __init__(self, config: dict):
        self.config = config
    
    def store(self, key: str, value: str):
        """Store a memory."""
        raise NotImplementedError
    
    def retrieve(self, key: str) -> str:
        """Retrieve a memory."""
        raise NotImplementedError
    
    def search(self, query: str) -> list[dict]:
        """Search memories."""
        raise NotImplementedError
```text

### 3.2 内置 Memory 插件（8 个）

Hermes 内置 **8 个 Memory 插件**，存放在 `plugins/memory/` 目录。

| 插件 | 核心能力 | 依赖 |
|------|----------|------|
| **byterover** | 持久化知识树，分层检索（brv CLI） | brv |
| **hindsight** | 长期记忆，知识图谱，实体解析，多策略检索 | hindsight-client |
| **holographic** | 本地 SQLite 事实存储，FTS5 搜索，信任评分，HPR 组合检索 | 无（本地） |
| **honcho** | 跨会话用户建模，对话式 Q&A，语义搜索，持久化结论 | honcho-ai |
| **mem0** | 服务器端 LLM 事实提取，语义搜索，重排序，自动去重 | mem0ai |
| **openviking** | 会话管理记忆，自动提取，分层检索，文件系统式知识浏览 | httpx |
| **retaindb** | 云记忆 API，混合搜索，7 种记忆类型 | requests |
| **supermemory** | 语义长期记忆，profile 召回，语义搜索，显式记忆工具，会话摄取 | supermemory |

#### 3.2.1 byterover

```yaml
# plugins/memory/byterover/plugin.yaml
name: byterover
version: 1.0.0
description: "ByteRover — persistent knowledge tree with tiered retrieval via the brv CLI."
external_dependencies:
  - name: brv
    install: "npm install -g @byterover/brv"
```

**核心功能**：

- 持久化知识树（知识以树状结构组织）

- 分层检索（通过 brv CLI）

- 适合团队协作（知识树可共享）

**使用示例**：

```python
from plugins.memory import load_memory_provider
provider = load_memory_provider("byterover")
provider.store("project/login-flow", "OAuth2 + JWT implementation")
result = provider.search("login")
```

---

#### 3.2.2 hindsight

```yaml
# plugins/memory/hindsight/plugin.yaml
name: hindsight
version: 1.0.0
description: "Hindsight — long-term memory with knowledge graph, entity resolution, and multi-strategy retrieval."
pip_dependencies:
  - "hindsight-client>=0.4.22"
```

**核心功能**：

- 知识图谱（实体关系网络）

- 实体解析（合并相同实体）

- 多策略检索（语义 + 图谱遍历）

---

#### 3.2.3 holographic（本地优先）

```yaml
# plugins/memory/holographic/plugin.yaml
name: holographic
version: 0.1.0
description: "Holographic memory — local SQLite fact store with FTS5 search, trust scoring, and HPR-based compositional retrieval."
hooks:
  - on_session_end  # 会话结束时自动提取记忆
```

**核心功能**：

- 本地 SQLite 存储（无需外部服务）

- FTS5 全文搜索

- 信任评分（记忆可靠性评估）

- HPR（Holographic Pattern Retrieval）组合检索

**适合场景**：隐私敏感项目，无网络环境。

---

#### 3.2.4 honcho（跨会话用户建模）

```yaml
# plugins/memory/honcho/plugin.yaml
name: honcho
version: 1.0.0
description: "Honcho AI-native memory — cross-session user modeling with dialectic Q&A, semantic search, and persistent conclusions."
pip_dependencies:
  - honcho-ai
```

**核心功能**：

- 跨会话用户建模（记住用户偏好、习惯）

- 对话式 Q&A（通过提问完善记忆）

- 持久化结论（重要结论永久保存）

---

#### 3.2.5 mem0（服务器端 LLM 提取）

```yaml
# plugins/memory/mem0/plugin.yaml
name: mem0
version: 1.0.0
description: "Mem0 — server-side LLM fact extraction with semantic search, reranking, and automatic deduplication."
pip_dependencies:
  - mem0ai
```

**核心功能**：

- 服务器端 LLM 事实提取（自动从对话中提取关键信息）

- 语义搜索 + 重排序

- 自动去重（避免重复记忆）

---

#### 3.2.6 openviking（会话管理）

```yaml
# plugins/memory/openviking/plugin.yaml
name: openviking
version: 2.0.0
description: "OpenViking context database — session-managed memory with automatic extraction, tiered retrieval, and filesystem-style knowledge browsing."
pip_dependencies:
  - httpx
```

**核心功能**：

- 会话管理记忆（每个会话独立存储）

- 自动提取（会话结束时自动保存）

- 分层检索（热记忆 → 冷记忆）

- 文件系统式知识浏览（类似文件目录结构）

---

#### 3.2.7 retaindb（云记忆 API）

```yaml
# plugins/memory/retaindb/plugin.yaml
name: retaindb
version: 1.0.0
description: "RetainDB — cloud memory API with hybrid search and 7 memory types."
pip_dependencies:
  - requests
```

**核心功能**：

- 云记忆 API（远程存储）

- 混合搜索（语义 + 关键词 + 时间）

- 7 种记忆类型（fact, procedure, preference, constraint, goal, context, event）

---

#### 3.2.8 supermemory（语义长期记忆）

```yaml
# plugins/memory/supermemory/plugin.yaml
name: supermemory
version: 1.0.0
description: "Supermemory semantic long-term memory with profile recall, semantic search, explicit memory tools, and session ingest."
pip_dependencies:
  - supermemory
```

**核心功能**：

- 语义长期记忆（向量存储）

- Profile 召回（根据用户 profile 召回相关记忆）

- 显式记忆工具（`/memory add`、`/memory search` 命令）

- 会话摄取（批量导入会话历史）

**使用示例**：

```bash
# 通过 CLI 管理记忆
hermes memory add "login flow uses OAuth2"
hermes memory search "authentication"
```

---

## 四、记忆注入时机

Hermes 的记忆注入分为 **2 个时机**：Session 启动时（自动）、对话中（按需）。

### 4.1 Session 启动时注入（自动）

**流程**：

```text
用户发送消息
    ↓
[AIAgent.run_conversation()]
    ↓
[1] 加载 Session DB 历史（如果 session_id 存在）
    - session_db.get_messages(session_id)
    - 返回最近 N 条消息（默认 20 条）
    - 按时间排序（最早的在前）
    ↓
[2] 加载 Memory 插件记忆（如果 skip_memory=False）
    - search_memories(query=user_message)
    - 使用用户消息作为查询（提取关键词）
    - 返回相关记忆（按相关性排序）
    ↓
[3] 注入到 messages
    - Session DB 历史：追加到 messages 末尾（保留对话上下文）
    - Memory 插件记忆：插入到 messages 开头（作为 system message）
    ↓
[4] 发送给 LLM
```

**代码实现**（`run_agent.py`）：

```python
class AIAgent:
    def run_conversation(self, user_message: str, ...):
        messages = []
        
        # [1] 加载 Session DB 历史
        if self.session_id:
            history = session_db.get_messages(
                session_id=self.session_id,
                limit=20  # 最近 20 条
            )
            messages.extend(history)
        
        # [2] 加载 Memory 插件记忆
        if not self.skip_memory:
            memories = search_memories(query=user_message)
            if memories:
                memory_text = "\n".join([m["content"] for m in memories])
                messages.insert(0, {
                    "role": "system",
                    "content": f"Relevant memories:\n{memory_text}"
                })
        
        # [3] 添加当前用户消息
        messages.append({"role": "user", "content": user_message})
        
        # [4] 发送给 LLM
        response = client.chat.completions.create(
            model=self.model,
            messages=messages,
            tools=tool_schemas
        )
        
        return response
```

### 4.2 按需查询（Tool 调用）

**流程**：

```text
LLM 决定调用 query_memory tool
    ↓
[1] 执行 query_memory tool
    - 参数：query（搜索查询）
    - 调用 search_memories(query=query)
    ↓
[2] 返回搜索结果
    - JSON 格式：{"results": [{"content": "...", "score": 0.95}, ...]}
    ↓
[3] LLM 读取搜索结果
    - 结果作为 tool result 消息
    - LLM 可以引用记忆内容
```

**代码实现**（`tools/query_memory.py`）：

```python
def query_memory(query: str, task_id: str = None) -> str:
    """
    Query memory (tool callable by LLM).
    
    Args:
        query: Search query
        task_id: Task ID (optional, for tracking)
    
    Returns:
        JSON string with search results
    """
    try:
        results = search_memories(query=query, limit=5)
        return json.dumps({
            "status": "success",
            "results": results
        })
    except Exception as e:
        return json.dumps({
            "status": "error",
            "message": str(e)
        })
```

### 4.3 记忆存储时机

**自动存储**（某些插件支持）：

- **holographic**：`on_session_end` Hook → 自动提取对话中的事实

- **mem0**：服务器端自动提取（无需显式调用）

**显式存储**（通过 tool 或 CLI）：

```bash
# 通过 CLI 命令
hermes memory add "login flow uses OAuth2"

# 通过 tool（如果插件提供了 store_memory tool）
LLM 调用：store_memory(content="login flow uses OAuth2")
```

---

---

## 五、与 CCGS/Claude Code 的对比

### 5.1 与 CCGS 的对比

| 维度 | CCGS | Hermes Agent |
| ------ | ------- | ------------ |
| **记忆类型** | Agent 记忆（`memory: project/user`） | Session DB + Memory 插件 |
| **记忆存储** | 静态（.claude/docs/*.md） | 动态（Session DB + Memory 插件） |
| **记忆查询** | 无（依赖 LLM 记住） | FTS5 搜索（Session DB） + 向量搜索（Memory 插件） |
| **记忆进化** | 无（静态） | 有（Memory 插件可以更新记忆） |

### 5.2 与 Claude Code 的对比

| 维度 | Claude Code | Hermes Agent |
| ------ | ------------- | ------------ |
| **记忆类型** | 无（依赖对话历史） | Session DB + Memory 插件 |
| **记忆存储** | 对话历史（.claude/ 目录） | Session DB（SQLite） + Memory 插件 |
| **记忆查询** | 无（依赖 LLM 记住） | FTS5 搜索（Session DB） + 向量搜索（Memory 插件） |
| **记忆进化** | 无 | 有（Memory 插件可以更新记忆） |

---

**文档状态**：✅ 第一版完成（从 `1-3-1-hermes-analysis.md` 拆分）

**下一步**：

- [ ] 补充更多 Memory 插件的详细说明（从 `plugins/memory/` 目录提取）

- [ ] 补充记忆注入的详细流程（如何解析记忆，如何注入到 messages）
