<!--
状态：draft
阶段：Phase 6
最后更新：2026-04-30
-->

# 06-plugin-system.md

## 1. 概述

Hermes 的插件系统允许通过 `register(ctx)` 函数注册自定义工具和生命周期 Hook，实现零侵入式扩展。

## 2. 架构图

```
hermes 启动
    → discover_plugins()
        → 扫描 plugins/ 目录
            → 读取 plugin.yaml 清单
                → 导入 __init__.py
                    → 调用 register(ctx)
                        → ctx.register_tool()     → tools.registry
                        → ctx.register_hook()     → PluginManager._hooks
```

## 3. 核心类/函数

### 3.1 PluginManager
| 方法 | 说明 |
|------|------|
| discover_plugins() | 扫描并加载所有插件 |
| _load_plugin() | 加载单个插件 |
| invoke_hook() | 触发指定 hook |

### 3.2 PluginContext
| 方法 | 说明 |
|------|------|
| register_tool() | 注册工具到全局 registry |
| register_hook() | 注册生命周期回调 |

## 4. 数据流

1. hermes 启动时调用 `discover_plugins()`
2. 扫描 `plugins/`、`~/.hermes/plugins/` 等目录
3. 读取 `plugin.yaml` 获取元数据
4. 导入 `__init__.py`，调用 `register(ctx)`
5. 插件通过 `ctx` 注册工具和 hook

## 5. 关键代码路径

```python
# plugins/vacky_debug/__init__.py
def register(ctx) -> None:
    ctx.register_tool(name="vacky_inspect_state", ...)
    ctx.register_hook("pre_tool_call", on_pre_tool_call)
```

## 6. 调试观察点

| 观察点 | 文件 | 调试方式 |
|--------|------|---------|
| 插件加载 | hermes_cli/plugins.py | 日志观察 |
| 工具注册 | tools/registry.py | 打印 registry._tools |
| Hook 触发 | 各 hook 点 | vacky_debug hook |

## 7. 与其他模块的关系

- 上游：hermes 启动流程
- 下游：tools/registry, agent 循环

## 8. 疑问与待办

- [ ] 插件加载顺序是否可配置？
- [ ] 用户插件如何覆盖 bundled 插件？
