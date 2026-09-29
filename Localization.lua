local _, ns = ...

local L = {
    SETTING_TITLE = "FocusClaim Settings",
    RAID_MARKER = "Raid marker",
    MODIFIER_KEY = "Modifier key",
    CALLOUT_CHANNEL = "Callout channel",
    CALLOUT = "My focus {rt%d} %%f",
    CASTBAR_HEADER = "Focus cast bar",
    CASTBAR_ENABLE = "Show while the focus is casting",
    CASTBAR_LOCK = "Lock position",
    CASTBAR_WIDTH = "Width (%d–%d)",
    CASTBAR_HEIGHT = "Height (%d–%d)",
    CASTBAR_PREVIEW = "Drag to move",
    CASTBAR_COLORS = "Cast bar colors",
    CASTBAR_COLOR_GREY = "Uninterruptible",
    CASTBAR_COLOR_GREEN = "Interrupt ready",
    CASTBAR_COLOR_ORANGE = "Interrupt unavailable",
    CASTBAR_COLOR_UNKNOWN = "Unknown / neutral",
    CHANNEL_NONE = "Disabled",
    CHANNEL_PARTY = "Party (/p)",
    CHANNEL_INSTANCE = "Instance (/i)",
    CHANNEL_RAID = "Raid (/ra)",
    MARKERS = {
        "Star", "Circle", "Diamond", "Triangle",
        "Moon", "Square", "Cross", "Skull",
    },
}

local locale = GetLocale()
if locale == "zhCN" then
    L.SETTING_TITLE = "FocusClaim 设置"
    L.RAID_MARKER = "团队标记"
    L.MODIFIER_KEY = "修饰键"
    L.CALLOUT_CHANNEL = "喊话频道"
    L.CALLOUT = "我焦点打断 {rt%d} %%f"
    L.CASTBAR_HEADER = "焦点施法条"
    L.CASTBAR_ENABLE = "焦点施法时显示"
    L.CASTBAR_LOCK = "锁定位置"
    L.CASTBAR_WIDTH = "宽度（%d–%d）"
    L.CASTBAR_HEIGHT = "高度（%d–%d）"
    L.CASTBAR_PREVIEW = "拖动以移动"
    L.CASTBAR_COLORS = "施法条颜色"
    L.CASTBAR_COLOR_GREY = "不可打断"
    L.CASTBAR_COLOR_GREEN = "打断就绪"
    L.CASTBAR_COLOR_ORANGE = "暂不可打断"
    L.CASTBAR_COLOR_UNKNOWN = "未知 / 中性色"
    L.CHANNEL_NONE = "关闭"
    L.CHANNEL_PARTY = "队伍 (/p)"
    L.CHANNEL_INSTANCE = "副本 (/i)"
    L.CHANNEL_RAID = "团队 (/ra)"
    L.MARKERS = {
        "星星", "圆圈", "菱形", "三角",
        "月亮", "方块", "红叉", "骷髅",
    }
elseif locale == "zhTW" then
    L.SETTING_TITLE = "FocusClaim 設定"
    L.RAID_MARKER = "團隊標記"
    L.MODIFIER_KEY = "修飾鍵"
    L.CALLOUT_CHANNEL = "喊話頻道"
    L.CALLOUT = "我焦點打斷 {rt%d} %%f"
    L.CASTBAR_HEADER = "焦點施法條"
    L.CASTBAR_ENABLE = "焦點施法時顯示"
    L.CASTBAR_LOCK = "鎖定位置"
    L.CASTBAR_WIDTH = "寬度（%d–%d）"
    L.CASTBAR_HEIGHT = "高度（%d–%d）"
    L.CASTBAR_PREVIEW = "拖曳以移動"
    L.CASTBAR_COLORS = "施法條顏色"
    L.CASTBAR_COLOR_GREY = "不可打斷"
    L.CASTBAR_COLOR_GREEN = "打斷就緒"
    L.CASTBAR_COLOR_ORANGE = "暫不可打斷"
    L.CASTBAR_COLOR_UNKNOWN = "未知 / 中性色"
    L.CHANNEL_NONE = "關閉"
    L.CHANNEL_PARTY = "隊伍 (/p)"
    L.CHANNEL_INSTANCE = "副本 (/i)"
    L.CHANNEL_RAID = "團隊 (/ra)"
    L.MARKERS = {
        "星星", "圓圈", "菱形", "三角",
        "月亮", "方塊", "紅叉", "骷髏",
    }
end

ns.L = L
