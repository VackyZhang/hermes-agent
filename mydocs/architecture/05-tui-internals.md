# TUI 前后端架构分析

> 分析对象：`ui-tui/`, `tui_gateway/`

---

## 待填充

阅读源码后在此记录：

1. **进程模型**：Ink (Node) ↔ Python (JSON-RPC over stdio)
2. **消息流**：用户输入 → app.tsx → gatewayClient → server.py → AIAgent
3. **组件结构**：`app.tsx`, `messageLine.tsx`, `thinking.tsx`, `prompts.tsx`
4. **主题系统**：`theme.ts` + 皮肤数据
5. **Slash 命令**：本地处理 vs `slash.exec` → `_SlashWorker`

---

## 调试建议

```bash
cd ui-tui
npm run dev    # watch 模式
```

---

## 相关文件

- `ui-tui/src/app.tsx` — Ink 主组件
- `ui-tui/src/gatewayClient.ts` — JSON-RPC 客户端
- `tui_gateway/server.py` — Python JSON-RPC 后端
