# 工具系统分析

> 分析对象：`tools/`, `model_tools.py`, `toolsets.py`

---

## 待填充

阅读源码后在此记录：

1. **注册机制**：`tools/registry.py` 如何工作
2. **自动发现**：`tools/*.py` 如何被扫描加载
3. **工具定义**：`registry.register()` 的 schema 格式
4. **调用分发**：`handle_function_call()` 的路由逻辑
5. **工具集**：`_HERMES_CORE_TOOLS` 的组织方式
6. **插件工具**：`plugins/` 中的工具如何注册

---

## 调试建议

```bash
# 查看所有已注册工具
hermes tools

# 使用 vacky_debug 插件观察工具调用
VACKY_DEBUG=1 hermes
```

---

## 相关文件

- `tools/registry.py` — 注册中心
- `model_tools.py` — 工具调用处理
- `toolsets.py` — 工具集定义
- `plugins/vacky_debug/tools.py` — 自定义调试工具示例
