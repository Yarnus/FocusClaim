local _, ns = ...

local L = {
    SETTING_TITLE = "FocusClaim Settings",
    RAID_MARKER = "Raid marker",
    MODIFIER_KEY = "Modifier key",
    CALLOUT_CHANNEL = "Callout channel",
    CALLOUT = "My focus {rt%d} %%f",
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
