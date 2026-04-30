# 调试记录 — 2026-04-30 首次验证

## 环境

- 分支：`vacky/dev`
- 配置：默认
- 启动命令：`VACKY_DEBUG=1 hermes`

## 目标

验证 vacky_debug 插件是否正确加载，调试 hook 是否生效。

## 过程

### 步骤 1：检查插件加载

```bash
hermes tools | grep vacky
```

**预期**：看到 `vacky_inspect_state`, `vacky_dump_context`, `vacky_trigger_breakpoint`

### 步骤 2：测试 inspect 工具

```
/vacky_inspect_state agent
```

### 步骤 3：测试 dump 工具

```
/vacky_dump_context label=first_test
```

### 步骤 4：查看调试日志

```bash
hermes logs --level DEBUG | grep vacky
```

## 结果

- [ ] 待验证

## 问题与待办

- [ ] 确认插件 auto-load 是否正常
- [ ] 确认 hook 日志输出位置
