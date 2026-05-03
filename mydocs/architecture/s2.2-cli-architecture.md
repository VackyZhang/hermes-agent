# CLI 架构分析

> 分析对象：`cli.py`, `hermes_cli/`

---

## 待填充

阅读源码后在此记录：

1. **入口**：`cli.py` 的 `HermesCLI` 类
2. **配置加载**：`load_cli_config()` 的合并逻辑
3. **命令系统**：`COMMAND_REGISTRY` 和 `process_command()`
4. **皮肤引擎**：`hermes_cli/skin_engine.py`
5. **插件加载**：`hermes_cli/plugins.py` 的 `discover_plugins()`
6. **TUI 模式**：`hermes --tui` 的启动流程

---

## 调试建议

```bash
# 查看所有可用命令
hermes --help

# 查看特定命令的帮助
hermes tools --help
```

---

## 相关文件

- `cli.py` — CLI 主入口
- `hermes_cli/commands.py` — 命令定义
- `hermes_cli/plugins.py` — 插件系统
- `hermes_cli/skin_engine.py` — 主题皮肤
