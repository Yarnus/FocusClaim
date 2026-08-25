local failures = 0
local tests = 0

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ")
            .. ": expected " .. tostring(expected)
            .. ", got " .. tostring(actual), 2)
    end
end

local function assertContains(actual, expected, message)
    if type(actual) ~= "string" or not actual:find(expected, 1, true) then
        error((message or "text not found")
            .. ": expected " .. tostring(expected)
            .. " in " .. tostring(actual), 2)
    end
end

local function assertNotContains(actual, expected, message)
    if type(actual) == "string" and actual:find(expected, 1, true) then
        error((message or "unexpected text found")
            .. ": did not expect " .. tostring(expected)
            .. " in " .. tostring(actual), 2)
    end
end

local function test(name, callback)
    tests = tests + 1
    local ok, err = pcall(callback)
    if ok then
        print("ok " .. tests .. " - " .. name)
    else
        failures = failures + 1
        print("not ok " .. tests .. " - " .. name)
        print("  " .. tostring(err))
    end
end

local globalsToClear = {
    "FocusClaimClickButton",
    "FocusClaimOptionsPanel",
    "FocusClaimMarkerDropdown",
    "FocusClaimModifierDropdown",
    "FocusClaimChannelDropdown",
    "PlayerFrame",
    "PartyMemberFrame5",
    "Boss5TargetFrame",
    "TargetFrame",
    "UUF_Target",
    "UUF_Boss10",
    "EQOLUFTargetFrame",
    "EQOLUFBoss5Frame",
    "EllesmereUIUnitFrames_Target",
    "EllesmereUIUnitFrames_Boss5",
    "DandersFrames",
    "ERFGroupHeader1",
    "ERFGroupHeader8",
    "ERFFlatHeader",
    "ERFPartyHeader",
    "ERFPartySelfButton",
}

local function newFrame()
    local frame = {
        attributes = {},
        events = {},
        scripts = {},
    }

    function frame:SetAttribute(key, value)
        self.setAttributeCalls = (self.setAttributeCalls or 0) + 1
        self.attributes[key] = value
    end

    function frame:GetAttribute(key)
        self.getAttributeCalls = (self.getAttributeCalls or 0) + 1
        return self.attributes[key]
    end

    function frame:SetScript(name, callback)
        self.scripts[name] = callback
    end

    function frame:RegisterEvent(event)
        self.events[event] = true
    end

    function frame:RegisterForClicks(...)
        self.registeredClicks = { ... }
    end

    function frame:SetPoint(...) self.point = { ... } end

    function frame:CreateFontString()
        local fontString = {}
        function fontString:SetPoint(...) self.point = { ... } end
        function fontString:SetText(text) self.text = text end
        return fontString
    end

    return frame
end

local function loadAddon(locale, settings)
    for index = 1, #globalsToClear do
        _G[globalsToClear[index]] = nil
    end

    local environment = {
        createdFrames = {},
        dropdownButtons = {},
        inCombat = false,
        openedCategory = nil,
        override = nil,
        timers = {},
    }

    function environment:RunTimers()
        local timers = self.timers
        self.timers = {}
        for index = 1, #timers do
            timers[index].callback()
        end
    end

    FocusClaimSettings = settings
    UIParent = {}
    SlashCmdList = {}

    GetLocale = function()
        return locale or "enUS"
    end
    InCombatLockdown = function()
        return environment.inCombat
    end
    CreateFrame = function(_, name)
        local frame = newFrame()
        environment.createdFrames[#environment.createdFrames + 1] = frame
        if name then
            _G[name] = frame
        end
        return frame
    end
    ClearOverrideBindings = function(owner)
        environment.clearedOverrideOwner = owner
        environment.override = nil
    end
    SetOverrideBindingClick = function(owner, priority, chord, buttonName)
        environment.override = {
            owner = owner,
            priority = priority,
            chord = chord,
            buttonName = buttonName,
        }
    end
    C_Timer = {
        After = function(delay, callback)
            environment.timers[#environment.timers + 1] = {
                delay = delay,
                callback = callback,
            }
        end,
    }
    C_NamePlate = {
        GetNamePlates = function()
            return environment.nameplates or {}
        end,
        GetNamePlateForUnit = function(unit)
            return environment.nameplateUnits and environment.nameplateUnits[unit]
        end,
    }

    UIDropDownMenu_SetWidth = function(dropdown, width)
        dropdown.width = width
    end
    UIDropDownMenu_Initialize = function(dropdown, callback)
        dropdown.initialize = callback
    end
    UIDropDownMenu_SetText = function(dropdown, text)
        dropdown.text = text
    end
    UIDropDownMenu_CreateInfo = function()
        return {}
    end
    UIDropDownMenu_AddButton = function(info)
        environment.dropdownButtons[#environment.dropdownButtons + 1] = info
    end

    local category = {
        GetID = function()
            return 42
        end,
    }
    Settings = {
        RegisterCanvasLayoutCategory = function()
            return category
        end,
        RegisterAddOnCategory = function() end,
        OpenToCategory = function(id)
            environment.openedCategory = id
        end,
    }

    local namespace = {}
    assert(loadfile("Localization.lua"))("FocusClaim", namespace)
    assert(loadfile("FrameProviders.lua"))("FocusClaim", namespace)
    assert(loadfile("FocusClaim.lua"))("FocusClaim", namespace)
    environment.addon = namespace.addon
    environment.L = namespace.L
    return environment
end

test("new settings use three defaults", function()
    local environment = loadAddon("enUS")
    local settings = environment.addon:GetSettings()

    assertEqual(settings.modifier, "shift")
    assertEqual(settings.marker, 8)
    assertEqual(settings.channel, "PARTY")
    assertEqual(settings.enabled, nil)
end)

test("invalid settings return to supported defaults", function()
    local environment = loadAddon("enUS", {
        modifier = "meta",
        marker = 9,
        channel = "YELL",
        enabled = true,
    })
    local settings = environment.addon:GetSettings()

    assertEqual(settings.modifier, "shift")
    assertEqual(settings.marker, 8)
    assertEqual(settings.channel, "PARTY")
    assertEqual(settings.enabled, nil)
end)

test("saved settings are normalized when FocusClaim finishes loading", function()
    local environment = loadAddon("enUS")
    FocusClaimSettings = {
        modifier = "meta",
        marker = 0,
        channel = "YELL",
        enabled = true,
    }

    environment.addon.scripts.OnEvent(
        environment.addon,
        "ADDON_LOADED",
        "FocusClaim"
    )
    local settings = environment.addon:GetSettings()

    assertEqual(settings.modifier, "shift")
    assertEqual(settings.marker, 8)
    assertEqual(settings.channel, "PARTY")
    assertEqual(settings.enabled, nil)
end)

test("the default macro has the fixed compact structure", function()
    local environment = loadAddon("enUS")
    local macroText = environment.addon:BuildFocusMacro()
    local expected = table.concat({
        "/tm [@focus]0",
        "/clearfocus [@mouseover,noexists]",
        "/stopmacro [@mouseover,noexists]",
        "/focus [@mouseover,exists]",
        "/tm [@mouseover]8",
        "/p My focus {rt8} %f",
    }, "\n")

    assertEqual(macroText, expected)
    assertEqual(#macroText < 255, true)
end)

test("the four channel settings only change the final line", function()
    local environment = loadAddon("enUS")
    local addon = environment.addon
    local settings = addon:GetSettings()

    settings.channel = "NONE"
    assertNotContains(addon:BuildFocusMacro(), "My focus")
    settings.channel = "PARTY"
    assertContains(addon:BuildFocusMacro(), "/p My focus {rt8} %f")
    settings.channel = "INSTANCE"
    assertContains(addon:BuildFocusMacro(), "/i My focus {rt8} %f")
    settings.channel = "RAID"
    assertContains(addon:BuildFocusMacro(), "/ra My focus {rt8} %f")
end)

test("Simplified Chinese callout includes the focus unit name", function()
    local environment = loadAddon("zhCN")

    assertContains(
        environment.addon:BuildFocusMacro(),
        "/p 我焦点打断 {rt8} %f"
    )
end)

test("Traditional Chinese callout includes the focus unit name", function()
    local environment = loadAddon("zhTW")

    assertContains(
        environment.addon:BuildFocusMacro(),
        "/p 我焦點打斷 {rt8} %f"
    )
end)

test("a unit frame receives direct macrotext on the configured chord", function()
    local environment = loadAddon("enUS")
    local frame = newFrame()
    frame.attributes["shift-type1"] = "spell"
    TargetFrame = frame

    environment.addon:RefreshBindings()

    assertEqual(frame.attributes["shift-type1"], "macro")
    assertEqual(frame.attributes["shift-macrotext1"], environment.addon:BuildFocusMacro())
end)

test("changing modifier removes the old FocusClaim chord", function()
    local environment = loadAddon("enUS")
    local frame = newFrame()
    TargetFrame = frame

    environment.addon:RefreshBindings()
    environment.addon:GetSettings().modifier = "alt"
    environment.addon:RefreshBindings()

    assertEqual(frame.attributes["shift-type1"], nil)
    assertEqual(frame.attributes["shift-macrotext1"], nil)
    assertEqual(frame.attributes["alt-type1"], "macro")
    assertEqual(environment.override.chord, "ALT-BUTTON1")
    assertEqual(environment.override.priority, true)
end)

test("changing modifier preserves a chord claimed by another addon", function()
    local environment = loadAddon("enUS")
    local frame = newFrame()
    TargetFrame = frame

    environment.addon:RefreshBindings()
    frame.attributes["shift-type1"] = "spell"
    frame.attributes["shift-macrotext1"] = nil
    environment.addon:GetSettings().modifier = "alt"
    environment.addon:RefreshBindings()

    assertEqual(frame.attributes["shift-type1"], "spell")
    assertEqual(frame.attributes["alt-type1"], "macro")
end)

test("initialization covers every supported frame family", function()
    local environment = loadAddon("enUS")
    local frames = {
        newFrame(), newFrame(), newFrame(), newFrame(), newFrame(),
        newFrame(), newFrame(), newFrame(), newFrame(), newFrame(),
        newFrame(), newFrame(), newFrame(), newFrame(), newFrame(),
        newFrame(), newFrame(),
    }
    PlayerFrame = frames[1]
    PartyMemberFrame5 = frames[2]
    Boss5TargetFrame = frames[3]
    UUF_Target = frames[4]
    UUF_Boss10 = frames[5]
    EQOLUFTargetFrame = frames[6]
    EQOLUFBoss5Frame = frames[7]
    EllesmereUIUnitFrames_Target = frames[8]
    EllesmereUIUnitFrames_Boss5 = frames[9]
    DandersFrames = {
        playerFrame = frames[10],
        partyFrames = { [4] = frames[11] },
        raidFrames = { [40] = frames[12] },
    }
    environment.nameplates = { frames[13] }
    ERFGroupHeader8 = { [5] = frames[14] }
    ERFFlatHeader = { [40] = frames[15] }
    ERFPartyHeader = { [5] = frames[16] }
    ERFPartySelfButton = frames[17]

    environment.addon:RefreshBindings()

    for index = 1, #frames do
        assertEqual(frames[index].attributes["shift-type1"], "macro", "frame " .. index)
    end
end)

test("repeated refreshes do not rewrite unchanged frame attributes", function()
    local environment = loadAddon("enUS")
    local frame = newFrame()
    TargetFrame = frame

    environment.addon:RefreshBindings()
    local firstRefreshWrites = frame.setAttributeCalls
    local firstRefreshReads = frame.getAttributeCalls
    environment.addon:RefreshBindings()

    assertEqual(firstRefreshWrites, 2)
    assertEqual(frame.setAttributeCalls, firstRefreshWrites)
    assertEqual(frame.getAttributeCalls - firstRefreshReads, 2)
end)

test("frame providers deduplicate frames discovered through multiple sources", function()
    local environment = loadAddon("enUS")
    local frame = newFrame()
    PlayerFrame = frame
    environment.nameplates = { frame }

    environment.addon:RefreshBindings()

    assertEqual(frame.setAttributeCalls, 2)
end)

test("a pooled nameplate clears its own previous modifier", function()
    local environment = loadAddon("enUS")
    local plate = newFrame()
    environment.nameplateUnits = { nameplate1 = plate }

    environment.addon.scripts.OnEvent(
        environment.addon,
        "NAME_PLATE_UNIT_ADDED",
        "nameplate1"
    )
    environment.nameplateUnits = nil
    environment.addon:GetSettings().modifier = "alt"
    environment.addon:RefreshBindings()
    environment.nameplateUnits = { nameplate2 = plate }
    environment.addon.scripts.OnEvent(
        environment.addon,
        "NAME_PLATE_UNIT_ADDED",
        "nameplate2"
    )

    assertEqual(plate.attributes["shift-type1"], nil)
    assertEqual(plate.attributes["shift-macrotext1"], nil)
    assertEqual(plate.attributes["alt-type1"], "macro")
end)

test("a nameplate added out of combat is bound immediately", function()
    local environment = loadAddon("enUS")
    local plate = newFrame()
    environment.nameplateUnits = { nameplate1 = plate }

    environment.addon.scripts.OnEvent(
        environment.addon,
        "NAME_PLATE_UNIT_ADDED",
        "nameplate1"
    )

    assertEqual(plate.attributes["shift-type1"], "macro")
end)

test("nameplates skipped in combat are bound after combat", function()
    local environment = loadAddon("enUS")
    local plate = newFrame()
    environment.nameplateUnits = { nameplate1 = plate }
    environment.nameplates = { plate }
    environment.inCombat = true

    environment.addon.scripts.OnEvent(
        environment.addon,
        "NAME_PLATE_UNIT_ADDED",
        "nameplate1"
    )
    assertEqual(plate.attributes["shift-type1"], nil)

    environment.inCombat = false
    environment.addon.scripts.OnEvent(environment.addon, "PLAYER_REGEN_ENABLED")
    assertEqual(#environment.timers, 1)
    assertEqual(environment.timers[1].delay, 2)
    environment:RunTimers()

    assertEqual(plate.attributes["shift-type1"], "macro")
end)

test("refresh events share one delayed refresh", function()
    local environment = loadAddon("enUS")
    local frame = newFrame()
    TargetFrame = frame

    environment.addon.scripts.OnEvent(environment.addon, "ADDON_LOADED", "Example")
    environment.addon.scripts.OnEvent(environment.addon, "PLAYER_ENTERING_WORLD")
    environment.addon.scripts.OnEvent(environment.addon, "GROUP_ROSTER_UPDATE")

    assertEqual(#environment.timers, 1)
    assertEqual(frame.attributes["shift-type1"], nil)
    environment:RunTimers()
    assertEqual(frame.attributes["shift-type1"], "macro")
end)

test("a frame from a delayed addon is discovered after it loads", function()
    local environment = loadAddon("enUS")
    local frame = newFrame()
    UUF_Boss10 = frame

    environment.addon.scripts.OnEvent(environment.addon, "ADDON_LOADED", "Example")
    environment:RunTimers()

    assertEqual(frame.attributes["shift-type1"], "macro")
end)

test("the options controls are created only when first shown", function()
    local environment = loadAddon("enUS")
    local initialFrames = #environment.createdFrames

    FocusClaimOptionsPanel.scripts.OnShow(FocusClaimOptionsPanel)
    local builtFrames = #environment.createdFrames
    FocusClaimOptionsPanel.scripts.OnShow(FocusClaimOptionsPanel)

    assertEqual(initialFrames, 2)
    assertEqual(builtFrames, 5)
    assertEqual(#environment.createdFrames, builtFrames)
end)

test("slash command only opens the settings category", function()
    local environment = loadAddon("enUS")

    SlashCmdList.FOCUSCLAIM("status")

    assertEqual(environment.openedCategory, 42)
end)

print("1.." .. tests)
if failures > 0 then
    os.exit(1)
end
