# Gateway 消息网关分析

> 分析对象：`gateway/`, `gateway/platforms/`

---

## 待填充

阅读源码后在此记录：

1. **架构**：Gateway 的整体流程
2. **Session**：`gateway/session.py` 的会话管理
3. **平台适配**：`gateway/platforms/` 各平台的适配器模式
4. **消息路由**： incoming message → platform adapter → agent → reply
5. **Hook 系统**：`gateway/builtin_hooks/` 和 pre_gateway_dispatch

---

## 相关文件

- `gateway/run.py` — Gateway 主入口
- `gateway/session.py` — 会话管理
- `gateway/platforms/` — 各平台适配器
