# FocusClaim

[English](README.md) | 简体中文

FocusClaim 是一个轻量的 WoW 正式服插件，用于将鼠标指向单位设置为焦点、添加团队标记并向队伍宣布焦点。

## 功能

- 使用 `Shift / Alt / Ctrl + 左键` 将任意鼠标指向单位设置为焦点
- 在空白处使用相同快捷键移除当前焦点标记并清除焦点
- 将所选团队标记移动到新焦点
- 向队伍、副本或团队频道发送 `我焦点{rtN}`
- 可以关闭喊话，同时保留焦点和标记行为
- 支持暴雪原生单位框和姓名板、DandersFrames、EllesmereUI、Enhance QoL 和 UUF 的单位框、队伍框与团队框

FocusClaim 会优先占用所选修饰键与左键组合。支持的单位框上如果已有相同组合的点击施法，该绑定会被覆盖。

## 使用

输入 `/fc` 或 `/focusclaim` 打开设置页。设置页只包含：

- 团队标记 `1-8`
- 修饰键 `Shift / Alt / Ctrl`
- 喊话频道 `关闭 / 队伍 / 副本 / 团队`

新角色默认使用 `Shift + 左键`、骷髅标记和队伍频道。配置按角色保存在 `FocusClaimSettings` 中。

## 设计

FocusClaim 将一条短宏直接写入安全按钮和支持的单位框，不再创建或管理角色宏。

多个刷新请求会自动合并，重复发现的框架会去重，安全属性只在绑定计划变化时重写。设置控件仅在首次打开设置页时创建。

简体中文默认宏为：

```text
/tm [@focus]0
/clearfocus [@mouseover,noexists]
/stopmacro [@mouseover,noexists]
/focus [@mouseover,exists]
/tm [@mouseover]8
/p 我焦点{rt8}
```

战斗中修改的设置会在脱战后生效。

## 开发

使用 `luajit tests/run.lua` 运行 Lua 回归测试。
