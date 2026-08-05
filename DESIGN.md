# FocusClaim 设计

## 行为边界

- 快捷键由可选修饰键和固定左键组成。
- 鼠标指向任意存在的单位时，设置焦点并覆盖为所选团队标记。
- 鼠标没有指向单位时，移除当前焦点标记、清除焦点并停止后续标记和喊话。
- 切换焦点时，先移除旧焦点标记，再将所选标记应用到新焦点。
- 喊话只包含本地化的固定文本和团队标记图标。
- FocusClaim 优先占用所选点击组合，不保存或恢复原绑定。

## 宏模型

运行时只生成一条短 `macrotext`。以简体中文、骷髅和队伍频道为例：

```text
/tm [@focus]0
/clearfocus [@mouseover,noexists]
/stopmacro [@mouseover,noexists]
/focus [@mouseover,exists]
/tm [@mouseover]8
/p 我焦点{rt8}
```

关闭喊话时省略最后一行。切换标记会同时更新 `/tm` 和喊话中的图标；切换频道或客户端语言只更新最后一行。

插件不创建真实角色宏，因此没有宏槽、宏名称、所有权、迁移、回读验证或宏长度状态。

## 绑定模型

同一条宏写入：

- 一个隐藏的 `SecureActionButtonTemplate`，通过覆盖绑定处理世界单位和空白区域
- 支持的单位框上的 `{modifier}-type1` 与 `{modifier}-macrotext1`

兼容范围由统一的框架访问模块维护：暴雪框架和姓名板、DandersFrames、EllesmereUI、Enhance QoL、UUF 单位框及其队伍/团队框。

进入世界、脱战、队伍变化或插件加载后请求统一刷新；两秒窗口内的多个请求只执行一次。姓名板在脱战外即时绑定，战斗中出现的姓名板在脱战刷新时补齐。

每次刷新先把当前设置编译为一份绑定计划，再由框架访问模块枚举并去重有效框架。运行时使用弱引用按框架记录上一次成功写入的计划，因此：

- 未变化的安全属性只读取、不重复写入
- 修饰键变化时，只清理由 FocusClaim 仍然持有的旧属性
- 池化后重新出现的框架按自己的历史记录清理，不依赖全局快照
- 单个第三方框架读写失败不会中断其他框架

设置页的控件只在首次打开时创建，不增加登录阶段的界面对象数量。

## 配置模型

`FocusClaimSettings` 是按角色保存的唯一配置，只包含：

- `modifier`: `shift / alt / ctrl`
- `marker`: `1-8`
- `channel`: `NONE / PARTY / INSTANCE / RAID`

FocusClaim 不读取或迁移其他插件的配置。

## 文件职责

- `Localization.lua`: 三种客户端语言的界面文本、标记名称和固定喊话
- `FrameProviders.lua`: 通过单一访问接口隐藏受支持框架的发现、索引规则和去重
- `FocusClaim.lua`: 配置规范化、绑定计划、安全属性所有权、刷新调度和延迟设置页
- `tests/run.lua`: 可在 LuaJIT 中运行的行为回归测试
