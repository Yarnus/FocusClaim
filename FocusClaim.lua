local ADDON_NAME, ns = ...

local L = ns.L
local addon = CreateFrame("Frame")
ns.addon = addon

local BUTTON_NAME = ADDON_NAME .. "ClickButton"
local DEFAULTS = {
    modifier = "shift",
    marker = 8,
    channel = "PARTY",
    castBarEnabled = false,
    castBarLocked = true,
    castBarX = 0,
    castBarY = 0,
}

local DEFAULT_CAST_BAR_COLORS = {
    grey = { r = 0.45, g = 0.45, b = 0.45 },
    green = { r = 0.20, g = 0.80, b = 0.32 },
    orange = { r = 0.95, g = 0.42, b = 0.12 },
    unknown = { r = 0.58, g = 0.66, b = 0.72 },
}

local MODIFIERS = {
    { value = "shift", text = "Shift" },
    { value = "alt", text = "Alt" },
    { value = "ctrl", text = "Ctrl" },
}

local CHANNELS = {
    { value = "NONE", text = L.CHANNEL_NONE },
    { value = "PARTY", text = L.CHANNEL_PARTY, command = "p" },
    { value = "INSTANCE", text = L.CHANNEL_INSTANCE, command = "i" },
    { value = "RAID", text = L.CHANNEL_RAID, command = "ra" },
}

local MARKERS = {}
for index = 1, 8 do
    MARKERS[index] = {
        value = index,
        text = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_"
            .. index .. ":16|t " .. L.MARKERS[index],
    }
end

local frameBindings = setmetatable({}, { __mode = "k" })

local function Find(options, value)
    for index = 1, #options do
        if options[index].value == value then
            return options[index]
        end
    end
end

local function IsFiniteNumber(value)
    return type(value) == "number"
        and value == value
        and value > -math.huge
        and value < math.huge
end

local function NormalizeColor(color, fallback)
    if type(color) ~= "table"
        or not IsFiniteNumber(color.r)
        or not IsFiniteNumber(color.g)
        or not IsFiniteNumber(color.b)
        or color.r < 0 or color.r > 1
        or color.g < 0 or color.g > 1
        or color.b < 0 or color.b > 1
    then
        return { r = fallback.r, g = fallback.g, b = fallback.b }
    end
    return { r = color.r, g = color.g, b = color.b }
end

local function NormalizeSettings()
    local settings = type(FocusClaimSettings) == "table" and FocusClaimSettings or {}
    local modifier = Find(MODIFIERS, settings.modifier) and settings.modifier
        or DEFAULTS.modifier
    local marker = settings.marker
    if type(marker) ~= "number"
        or marker < 1
        or marker > 8
        or marker % 1 ~= 0
    then
        marker = DEFAULTS.marker
    end
    local channel = Find(CHANNELS, settings.channel) and settings.channel
        or DEFAULTS.channel
    local colors = type(settings.castBarColors) == "table" and settings.castBarColors or {}
    local x = settings.castBarX
    local y = settings.castBarY
    if not IsFiniteNumber(x) or x < -10000 or x > 10000 then
        x = DEFAULTS.castBarX
    end
    if not IsFiniteNumber(y) or y < -10000 or y > 10000 then
        y = DEFAULTS.castBarY
    end

    FocusClaimSettings = {
        modifier = modifier,
        marker = marker,
        channel = channel,
        castBarEnabled = settings.castBarEnabled == true,
        castBarLocked = settings.castBarLocked ~= false,
        castBarX = x,
        castBarY = y,
        castBarColors = {
            grey = NormalizeColor(colors.grey, DEFAULT_CAST_BAR_COLORS.grey),
            green = NormalizeColor(colors.green, DEFAULT_CAST_BAR_COLORS.green),
            orange = NormalizeColor(colors.orange, DEFAULT_CAST_BAR_COLORS.orange),
            unknown = NormalizeColor(colors.unknown, DEFAULT_CAST_BAR_COLORS.unknown),
        },
    }
end

local function BuildMacro(settings)
    local lines = {
        "/tm [@focus]0",
        "/clearfocus [@mouseover,noexists]",
        "/stopmacro [@mouseover,noexists]",
        "/focus [@mouseover,exists]",
        "/tm [@mouseover]" .. settings.marker,
    }
    local channel = Find(CHANNELS, settings.channel)
    if channel and channel.command then
        lines[#lines + 1] = "/" .. channel.command .. " "
            .. L.CALLOUT:format(settings.marker)
    end
    return table.concat(lines, "\n")
end

local function CompileBindingPlan()
    local settings = FocusClaimSettings
    local modifier = settings.modifier
    return {
        modifier = modifier,
        typeAttribute = modifier .. "-type1",
        macroAttribute = modifier .. "-macrotext1",
        macroText = BuildMacro(settings),
        chord = modifier:upper() .. "-BUTTON1",
    }
end

local function ReadAttribute(frame, key)
    return pcall(frame.GetAttribute, frame, key)
end

local function WriteAttribute(frame, key, value)
    return pcall(frame.SetAttribute, frame, key, value)
end

local function ClearPreviousBinding(frame, previous, plan)
    if not previous or previous.modifier == plan.modifier then
        return true
    end

    local typeOk, actionType = ReadAttribute(frame, previous.typeAttribute)
    local macroOk, macroText = ReadAttribute(frame, previous.macroAttribute)
    if not typeOk or not macroOk then
        return false
    end
    if actionType ~= "macro" or macroText ~= previous.macroText then
        return true
    end

    return WriteAttribute(frame, previous.typeAttribute, nil)
        and WriteAttribute(frame, previous.macroAttribute, nil)
end

local function ApplyPlanToFrame(frame, plan)
    if not ClearPreviousBinding(frame, frameBindings[frame], plan) then
        return false
    end

    local macroOk, currentMacro = ReadAttribute(frame, plan.macroAttribute)
    local typeOk, currentType = ReadAttribute(frame, plan.typeAttribute)
    if not macroOk or not typeOk then
        return false
    end
    local changed = false
    if currentMacro ~= plan.macroText
        and not WriteAttribute(frame, plan.macroAttribute, plan.macroText)
    then
        return false
    elseif currentMacro ~= plan.macroText then
        changed = true
    end
    if currentType ~= "macro"
        and not WriteAttribute(frame, plan.typeAttribute, "macro")
    then
        return false
    elseif currentType ~= "macro" then
        changed = true
    end

    if not changed then
        frameBindings[frame] = plan
        return true
    end

    macroOk, currentMacro = ReadAttribute(frame, plan.macroAttribute)
    typeOk, currentType = ReadAttribute(frame, plan.typeAttribute)
    if not macroOk
        or not typeOk
        or currentMacro ~= plan.macroText
        or currentType ~= "macro"
    then
        return false
    end

    frameBindings[frame] = plan
    return true
end

local function RefreshWorldBinding(plan)
    local previous = addon.worldBinding
    if previous
        and previous.chord == plan.chord
        and previous.macroText == plan.macroText
    then
        return
    end

    local button = addon.focusButton
    if not button then
        button = CreateFrame(
            "CheckButton",
            BUTTON_NAME,
            UIParent,
            "SecureActionButtonTemplate"
        )
        button:RegisterForClicks("AnyDown", "AnyUp")
        addon.focusButton = button
    end

    ClearOverrideBindings(button)
    button:SetAttribute("macrotext1", plan.macroText)
    button:SetAttribute("type1", "macro")
    SetOverrideBindingClick(button, true, plan.chord, BUTTON_NAME)
    addon.worldBinding = plan
end

NormalizeSettings()

function addon:GetSettings()
    return FocusClaimSettings
end

function addon:BuildFocusMacro()
    return BuildMacro(FocusClaimSettings)
end

function addon:RefreshBindings()
    if InCombatLockdown() then
        self.pendingRefresh = true
        return
    end

    local plan = CompileBindingPlan()
    ns.VisitSupportedFrames(function(frame)
        ApplyPlanToFrame(frame, plan)
    end)
    RefreshWorldBinding(plan)
    self.bindingPlan = plan
    self.pendingRefresh = false
end

function addon:QueueRefresh()
    self.pendingRefresh = true
    if InCombatLockdown() or self.refreshQueued then
        return
    end

    self.refreshQueued = true
    C_Timer.After(2, function()
        self.refreshQueued = false
        if not InCombatLockdown() and self.pendingRefresh then
            self:RefreshBindings()
        end
    end)
end

function addon:SettingsChanged()
    if InCombatLockdown() then
        self.pendingRefresh = true
    else
        self:RefreshBindings()
    end
    if self.castBar then
        self.castBar:SettingsChanged()
    end
end

local panel = CreateFrame("Frame", "FocusClaimOptionsPanel", UIParent)
panel.name = "FocusClaim"
local controls = {}
local optionsBuilt = false

local function CreateDropdown(parent, labelText, y, options, setting)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 20, y)
    label:SetText(labelText)

    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", -15, -5)
    UIDropDownMenu_SetWidth(dropdown, 180)
    UIDropDownMenu_Initialize(dropdown, function()
        for index = 1, #options do
            local option = options[index]
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                FocusClaimSettings[setting] = option.value
                UIDropDownMenu_SetText(dropdown, option.text)
                addon:SettingsChanged()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    controls[#controls + 1] = {
        dropdown = dropdown,
        options = options,
        setting = setting,
    }
end

local function BuildOptions()
    if optionsBuilt then
        return
    end
    optionsBuilt = true

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText(L.SETTING_TITLE)
    CreateDropdown(panel, L.RAID_MARKER, -65, MARKERS, "marker")
    CreateDropdown(panel, L.MODIFIER_KEY, -140, MODIFIERS, "modifier")
    CreateDropdown(panel, L.CALLOUT_CHANNEL, -215, CHANNELS, "channel")
    if ns.castBar then
        ns.castBar:BuildOptions(panel, -285)
    end
    if panel.SetHeight then
        panel:SetHeight(585)
    end
end

local function RefreshOptions()
    for index = 1, #controls do
        local control = controls[index]
        local option = Find(control.options, FocusClaimSettings[control.setting])
        UIDropDownMenu_SetText(control.dropdown, option and option.text or "")
    end
    if ns.castBar then
        ns.castBar:RefreshOptions()
    end
end

panel:SetScript("OnShow", function()
    BuildOptions()
    RefreshOptions()
end)

local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)

function addon:OpenOptions()
    Settings.OpenToCategory(category:GetID())
end

SLASH_FOCUSCLAIM1 = "/focusclaim"
SLASH_FOCUSCLAIM2 = "/fc"
SlashCmdList.FOCUSCLAIM = function()
    addon:OpenOptions()
end

local eventHandlers = {
    ADDON_LOADED = function(self, loadedAddon)
        if loadedAddon == ADDON_NAME then
            NormalizeSettings()
        end
        self:QueueRefresh()
    end,
    PLAYER_ENTERING_WORLD = function(self)
        self:QueueRefresh()
    end,
    PLAYER_REGEN_ENABLED = function(self)
        self:QueueRefresh()
    end,
    GROUP_ROSTER_UPDATE = function(self)
        self:QueueRefresh()
    end,
    NAME_PLATE_UNIT_ADDED = function(self, unit)
        if InCombatLockdown() then
            self.pendingRefresh = true
            return
        end
        if not C_NamePlate or type(C_NamePlate.GetNamePlateForUnit) ~= "function" then
            return
        end

        local frame = C_NamePlate.GetNamePlateForUnit(unit)
        if frame and type(frame.GetAttribute) == "function" then
            local plan = self.bindingPlan or CompileBindingPlan()
            ApplyPlanToFrame(frame, plan)
        end
    end,
}

addon:SetScript("OnEvent", function(self, event, ...)
    eventHandlers[event](self, ...)
end)

for event in pairs(eventHandlers) do
    addon:RegisterEvent(event)
end
