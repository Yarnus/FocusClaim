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
    "FocusClaimFocusCastBar",
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

local function newTexture()
    local texture = {}
    function texture:SetPoint(...)
        self.point = { ... }
        self.points = self.points or {}
        self.points[#self.points + 1] = { ... }
    end
    function texture:SetAllPoints(...) self.allPoints = { ... } end
    function texture:ClearAllPoints() self.points = {} end
    function texture:SetSize(width, height) self.width, self.height = width, height end
    function texture:SetTexture(value) self.texture = value end
    function texture:SetColorTexture(...) self.color = { ... } end
    function texture:SetVertexColor(...) self.vertexColor = { ... } end
    function texture:SetAlpha(value) self.alpha = value end
    function texture:SetAlphaFromBoolean(value, trueAlpha, falseAlpha)
        if issecretvalue and issecretvalue(value) then value = value.value end
        if value then
            self.alpha = trueAlpha
        else
            self.alpha = falseAlpha
        end
    end
    return texture
end

local function newFontString()
    local fontString = {}
    function fontString:SetPoint(...) self.point = { ... } end
    function fontString:SetText(text) self.text = text end
    function fontString:SetFormattedText(format, ...)
        self.text = string.format(format, ...)
    end
    function fontString:SetWidth(width) self.width = width end
    function fontString:SetJustifyH(value) self.justify = value end
    function fontString:SetWordWrap(value) self.wordWrap = value end
    return fontString
end

local function newFrame(frameType)
    local frame = {
        attributes = {},
        events = {},
        scripts = {},
        frameType = frameType,
        shown = true,
        moving = false,
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

    function frame:RegisterUnitEvent(event, unit)
        self.events[event] = unit
    end

    function frame:RegisterForClicks(...)
        self.registeredClicks = { ... }
    end

    function frame:RegisterForDrag(...) self.registeredDrag = { ... } end
    function frame:SetPoint(...) self.point = { ... } end
    function frame:ClearAllPoints() self.point = nil end
    function frame:SetAllPoints(...) self.allPoints = { ... } end
    function frame:SetSize(width, height) self.width, self.height = width, height end
    function frame:SetWidth(width) self.width = width end
    function frame:SetHeight(height) self.height = height end
    function frame:GetWidth() return self.width or 0 end
    function frame:GetHeight() return self.height or 0 end
    function frame:SetMovable(value) self.movable = value end
    function frame:EnableMouse(value) self.mouseEnabled = value end
    function frame:SetFrameStrata(value) self.strata = value end
    function frame:SetClampedToScreen(value) self.clamped = value end
    function frame:StartMoving() self.moving = true end
    function frame:StopMovingOrSizing() self.moving = false end
    function frame:GetCenter()
        if self.center then return self.center[1], self.center[2] end
        if self.point then
            local count = #self.point
            return self.point[count - 1], self.point[count]
        end
        return 0, 0
    end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    function frame:IsShown() return self.shown end
    function frame:SetAlpha(value) self.alpha = value end
    function frame:SetAlphaFromBoolean(value, trueAlpha, falseAlpha)
        if issecretvalue and issecretvalue(value) then value = value.value end
        if value then
            self.alpha = trueAlpha
        else
            self.alpha = falseAlpha
        end
    end
    function frame:SetStatusBarTexture(texture)
        self.statusBarTexture = newTexture()
        self.statusBarTexture.texture = texture
        return self.statusBarTexture
    end
    function frame:GetStatusBarTexture()
        if not self.statusBarTexture then
            self.statusBarTexture = newTexture()
        end
        return self.statusBarTexture
    end
    function frame:SetMinMaxValues(minimum, maximum)
        self.minimum, self.maximum = minimum, maximum
    end
    function frame:SetValue(value) self.value = value end
    function frame:SetTimerDuration(duration, interpolation, direction)
        self.timerDuration = duration
        self.timerDirection = direction
    end
    function frame:SetReverseFill(value) self.reverseFill = value end
    function frame:SetFillStyle(value) self.fillStyle = value end
    function frame:SetChecked(value) self.checked = value end
    function frame:GetChecked() return self.checked end
    function frame:CreateTexture()
        local texture = newTexture()
        self.textures = self.textures or {}
        self.textures[#self.textures + 1] = texture
        return texture
    end
    function frame:CreateFontString()
        local fontString = newFontString()
        self.fontStrings = self.fontStrings or {}
        self.fontStrings[#self.fontStrings + 1] = fontString
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
        class = "ROGUE",
        knownSpells = {},
        range = true,
        usable = true,
        cooldownDuration = nil,
        castInfo = nil,
    }

    function environment:RunTimers()
        local timers = self.timers
        self.timers = {}
        for index = 1, #timers do
            timers[index].callback()
        end
    end

    FocusClaimSettings = settings
    UIParent = {
        GetCenter = function() return 0, 0 end,
    }
    SlashCmdList = {}
    Enum = {
        SpellBookSpellBank = { Pet = "PET" },
        StatusBarTimerDirection = {
            ElapsedTime = "ELAPSED",
            RemainingTime = "REMAINING",
        },
        StatusBarFillStyle = { Standard = "STANDARD", Reverse = "REVERSE" },
    }
    issecretvalue = function(value)
        return type(value) == "table" and value.secret == true
    end
    UnitClassBase = function() return environment.class end
    C_SpellBook = {
        IsSpellKnownOrInSpellBook = function(spellID, bank)
            local known = environment.knownSpells[spellID]
            if bank == "PET" then
                return known == "pet"
            end
            return known == "player" or known == true
        end,
    }
    C_CurveUtil = {
        EvaluateColorValueFromBoolean = function(value, falseValue, trueValue)
            if issecretvalue(value) then value = value.value end
            if value then return trueValue end
            return falseValue
        end,
    }
    C_Spell = {
        IsSpellInRange = function()
            return environment.range
        end,
        IsSpellUsable = function()
            return environment.usable
        end,
        GetSpellCooldownDuration = function()
            return environment.cooldownDuration
        end,
    }
    local function CastDetails(kind)
        local cast = environment.castInfo
        if not cast or cast.kind ~= kind then return end
        if kind == "channel" or kind == "empowered" then
            return cast.name, nil, cast.icon, nil, nil, nil, cast.notInterruptible
        end
        return cast.name, nil, cast.icon, nil, nil, nil, nil, cast.notInterruptible
    end
    UnitChannelDuration = function()
        local cast = environment.castInfo
        return cast and cast.kind == "channel" and cast.duration
    end
    UnitEmpoweredChannelDuration = function()
        local cast = environment.castInfo
        return cast and cast.kind == "empowered" and cast.duration
    end
    UnitCastingDuration = function()
        local cast = environment.castInfo
        return cast and cast.kind == "cast" and cast.duration
    end
    UnitChannelInfo = function()
        local cast = environment.castInfo
        if cast and cast.kind == "channel" then
            return CastDetails("channel")
        elseif cast and cast.kind == "empowered" then
            return CastDetails("empowered")
        end
    end
    UnitCastingInfo = function() return CastDetails("cast") end
    ColorPickerFrame = {
        SetupColorPickerAndShow = function(self, info)
            environment.colorPicker = info
        end,
        GetColorRGB = function()
            return unpack(environment.pickerColor or { 0.1, 0.2, 0.3 })
        end,
    }

    GetLocale = function()
        return locale or "enUS"
    end
    InCombatLockdown = function()
        return environment.inCombat
    end
    CreateFrame = function(frameType, name)
        local frame = newFrame(frameType)
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
    assert(loadfile("CastBar.lua"))("FocusClaim", namespace)
    environment.addon = namespace.addon
    environment.L = namespace.L
    environment.castBar = namespace.castBar
    return environment
end

local function newDuration(total, elapsed, remaining)
    return {
        GetTotalDuration = function() return total end,
        GetElapsedDuration = function() return elapsed end,
        GetRemainingDuration = function() return remaining end,
    }
end

local function newCooldown(ready, remaining)
    return {
        IsZero = function() return ready end,
        GetRemainingDuration = function() return remaining end,
    }
end

local function castEvent(environment, event, ...)
    environment.castBar.eventFrame.scripts.OnEvent(
        environment.castBar.eventFrame,
        event,
        ...
    )
end

test("new settings preserve existing defaults and add a safe cast-bar default", function()
    local environment = loadAddon("enUS")
    local settings = environment.addon:GetSettings()

    assertEqual(settings.modifier, "shift")
    assertEqual(settings.marker, 8)
    assertEqual(settings.channel, "PARTY")
    assertEqual(settings.castBarEnabled, false)
    assertEqual(settings.castBarLocked, true)
    assertEqual(settings.castBarX, 0)
    assertEqual(settings.castBarY, 0)
    assertEqual(settings.castBarColors.grey.r, 0.45)
    assertEqual(settings.castBarColors.green.g, 0.8)
    assertEqual(settings.castBarColors.orange.r, 0.95)
    assertEqual(settings.castBarColors.unknown.b, 0.72)
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
    assertEqual(settings.castBarEnabled, false)
    assertEqual(settings.castBarLocked, true)
    assertEqual(settings.castBarX, 0)
    assertEqual(settings.castBarY, 0)
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
    assertEqual(settings.castBarEnabled, false)
    assertEqual(settings.castBarLocked, true)
    assertEqual(settings.castBarColors.grey.r, 0.45)
    assertEqual(settings.enabled, nil)
end)

test("invalid cast-bar colors and coordinates normalize to safe defaults", function()
    local environment = loadAddon("enUS", {
        castBarX = 10001,
        castBarY = 12,
        castBarEnabled = true,
        castBarLocked = false,
        castBarColors = {
            grey = { r = 2, g = 0, b = 0 },
            green = { r = 0.1, g = 0.2, b = 0.3 },
            orange = "invalid",
            unknown = { r = 0, g = 0 / 0, b = 0 },
        },
    })
    local settings = environment.addon:GetSettings()

    assertEqual(settings.castBarEnabled, true)
    assertEqual(settings.castBarLocked, false)
    assertEqual(settings.castBarX, 0)
    assertEqual(settings.castBarY, 12)
    assertEqual(settings.castBarColors.grey.r, 0.45)
    assertEqual(settings.castBarColors.green.r, 0.1)
    assertEqual(settings.castBarColors.orange.g, 0.42)
    assertEqual(settings.castBarColors.unknown.b, 0.72)
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

test("cast bar is opt-in and settings changes preserve its character position", function()
    local environment = loadAddon("enUS")
    local manager = environment.castBar
    local settings = environment.addon:GetSettings()

    environment.castInfo = {
        kind = "cast",
        name = "Shadowstep",
        icon = "spell-icon",
        notInterruptible = false,
        duration = newDuration(4, 1, 3),
    }
    environment.knownSpells[1766] = "player"
    environment.cooldownDuration = newCooldown(true, 0)
    castEvent(environment, "UNIT_SPELLCAST_START", "focus", "cast-1")
    assertEqual(manager.frame:IsShown(), false)
    assertEqual(manager.frame.scripts.OnUpdate, nil)

    settings.castBarEnabled = true
    environment.addon:SettingsChanged()
    assertEqual(manager.frame:IsShown(), true)
    assertEqual(manager.frame.timerDirection, "ELAPSED")
    assertEqual(manager.frame.timerDuration, environment.castInfo.duration)
    assertEqual(manager.nameText.text, "Shadowstep")
    assertEqual(manager.timeText.text, "3.0")
    assertEqual(manager.barTexture.vertexColor[2], settings.castBarColors.green.g)

    manager.frame.center = { 48, -92 }
    manager.frame.scripts.OnDragStart(manager.frame)
    assertEqual(manager.frame.moving, false)
    settings.castBarLocked = false
    environment.addon:SettingsChanged()
    manager.frame.scripts.OnDragStart(manager.frame)
    assertEqual(manager.frame.moving, true)
    manager.frame.scripts.OnDragStop(manager.frame)
    assertEqual(settings.castBarX, 48)
    assertEqual(settings.castBarY, -92)
    assertEqual(manager.frame:IsShown(), true)

    castEvent(environment, "UNIT_SPELLCAST_STOP", "focus", "cast-1")
    assertEqual(manager.frame:IsShown(), true)
    assertEqual(manager.previewText.text, environment.L.CASTBAR_PREVIEW)
    assertEqual(manager.frame.scripts.OnUpdate, nil)
end)

test("idle unlocked cast bars preview, drag, and restore their saved position", function()
    local settings = {
        castBarEnabled = true,
        castBarLocked = true,
        castBarX = 12,
        castBarY = -34,
    }
    local environment = loadAddon("enUS", settings)
    settings = environment.addon:GetSettings()
    local manager = environment.castBar

    assertEqual(manager.frame:IsShown(), false)
    assertEqual(manager.previewText.text, "")
    settings.castBarLocked = false
    environment.addon:SettingsChanged()
    assertEqual(manager.frame:IsShown(), true)
    assertEqual(manager.previewText.text, environment.L.CASTBAR_PREVIEW)
    assertEqual(manager.frame.mouseEnabled, true)

    manager.frame.center = { 48, -92 }
    manager.frame.scripts.OnDragStart(manager.frame)
    assertEqual(manager.frame.moving, true)
    manager.frame.scripts.OnDragStop(manager.frame)
    assertEqual(settings.castBarX, 48)
    assertEqual(settings.castBarY, -92)

    settings.castBarLocked = true
    environment.addon:SettingsChanged()
    assertEqual(manager.frame:IsShown(), false)
    assertEqual(manager.frame.mouseEnabled, false)

    local reloaded = loadAddon("enUS", settings)
    assertEqual(reloaded.castBar.frame.point[4], 48)
    assertEqual(reloaded.castBar.frame.point[5], -92)
    assertEqual(reloaded.castBar.frame:IsShown(), false)
    settings = reloaded.addon:GetSettings()
    settings.castBarLocked = false
    reloaded.addon:SettingsChanged()
    assertEqual(reloaded.castBar.frame:IsShown(), true)
    assertEqual(reloaded.castBar.frame.point[4], 48)
    assertEqual(reloaded.castBar.frame.point[5], -92)
end)

test("cooldown states color the cast and mark its remaining-time boundary", function()
    local environment = loadAddon("enUS", { castBarEnabled = true })
    local manager = environment.castBar
    environment.knownSpells[1766] = "player"
    environment.cooldownDuration = newCooldown(true, 0)
    environment.castInfo = {
        kind = "cast",
        name = "Kickable cast",
        icon = "spell-icon",
        notInterruptible = false,
        duration = newDuration(4, 1, 3),
    }

    castEvent(environment, "UNIT_SPELLCAST_START", "focus", "cast-2")
    assertEqual(manager.barTexture.vertexColor[2], 0.8)
    assertEqual(manager.readySegment.alpha, 0)

    environment.cooldownDuration = newCooldown(false, 2)
    castEvent(environment, "SPELL_UPDATE_COOLDOWN")
    assertEqual(manager.barTexture.vertexColor[1], 0.95)
    assertEqual(manager.readySegment.alpha, 1)
    assertEqual(manager.readySegment.vertexColor[2], 0.8)
    assertEqual(manager.positioner.value, 1)
    assertEqual(manager.marker.value, 2)
    assertEqual(manager.readySegment.points[1][2], manager.marker:GetStatusBarTexture())

    environment.cooldownDuration = newCooldown(false, 4)
    castEvent(environment, "SPELL_UPDATE_COOLDOWN")
    assertEqual(manager.marker.value, 4)
    assertEqual(manager.readySegment.points[2][2], manager.frame)
end)

test("unusable and unknown interrupts never go green, without hiding the cooldown window", function()
    local environment = loadAddon("enUS", { castBarEnabled = true })
    local manager = environment.castBar
    local colors = environment.addon:GetSettings().castBarColors
    environment.knownSpells[1766] = "player"
    environment.usable = false
    environment.cooldownDuration = newCooldown(true, 0)
    environment.castInfo = {
        kind = "cast",
        name = "Unusable interrupt",
        icon = "spell-icon",
        notInterruptible = false,
        duration = newDuration(4, 1, 3),
    }

    castEvent(environment, "UNIT_SPELLCAST_START", "focus", "cast-unusable")
    assertEqual(manager.barTexture.vertexColor[1], colors.orange.r)
    assertEqual(manager.readySegment.alpha, 0)

    -- IsSpellUsable can include the current cooldown in its false result. The
    -- cooldown duration still predicts the future ready window independently.
    environment.cooldownDuration = newCooldown(false, 2)
    castEvent(environment, "SPELL_UPDATE_COOLDOWN")
    assertEqual(manager.barTexture.vertexColor[1], colors.orange.r)
    assertEqual(manager.readySegment.alpha, 1)

    environment.usable = nil
    castEvent(environment, "SPELL_UPDATE_USABLE")
    assertEqual(manager.barTexture.vertexColor[1], colors.unknown.r)
    assertEqual(manager.readySegment.alpha, 0)

    local isSpellUsable = C_Spell.IsSpellUsable
    C_Spell.IsSpellUsable = nil
    castEvent(environment, "SPELL_UPDATE_USABLE")
    assertEqual(manager.barTexture.vertexColor[1], colors.unknown.r)
    C_Spell.IsSpellUsable = isSpellUsable

    environment.usable = true
    environment.cooldownDuration = newCooldown(true, 0)
    castEvent(environment, "SPELL_UPDATE_USABLE")
    assertEqual(manager.barTexture.vertexColor[2], colors.green.g)
end)

test("secret interrupt usability uses the native safe color path", function()
    local environment = loadAddon("enUS", { castBarEnabled = true })
    local manager = environment.castBar
    local colors = environment.addon:GetSettings().castBarColors
    local function secret(value)
        return { secret = true, value = value }
    end
    environment.knownSpells[1766] = "player"
    environment.cooldownDuration = newCooldown(true, 0)
    environment.castInfo = {
        kind = "cast",
        name = "Secret usability",
        icon = "spell-icon",
        notInterruptible = false,
        duration = newDuration(4, 1, 3),
    }
    environment.usable = secret(false)
    castEvent(environment, "UNIT_SPELLCAST_START", "focus", "cast-secret-usable")
    assertEqual(manager.barTexture.vertexColor[1], colors.orange.r)

    environment.usable = secret(true)
    castEvent(environment, "SPELL_UPDATE_USABLE")
    assertEqual(manager.barTexture.vertexColor[2], colors.green.g)
end)

test("uninterruptible, out-of-range, and unknown states never show a green promise", function()
    local environment = loadAddon("enUS", { castBarEnabled = true })
    local manager = environment.castBar
    environment.knownSpells[1766] = "player"
    environment.cooldownDuration = newCooldown(true, 0)
    environment.castInfo = {
        kind = "cast",
        name = "Protected cast",
        icon = "spell-icon",
        notInterruptible = true,
        duration = newDuration(4, 1, 3),
    }
    castEvent(environment, "UNIT_SPELLCAST_START", "focus", "cast-3")
    assertEqual(manager.uninterruptibleHost.alpha, 1)
    assertEqual(manager.uninterruptibleOverlay.vertexColor[1], 0.45)

    environment.castInfo.notInterruptible = false
    environment.range = false
    castEvent(environment, "SPELL_UPDATE_USABLE")
    assertEqual(manager.barTexture.vertexColor[1], 0.95)
    assertEqual(manager.readySegment.alpha, 0)

    environment.range = nil
    castEvent(environment, "SPELL_UPDATE_USABLE")
    assertEqual(manager.barTexture.vertexColor[1], 0.58)
    assertEqual(manager.barTexture.vertexColor[3], 0.72)

    environment.range = true
    environment.cooldownDuration = nil
    castEvent(environment, "SPELL_UPDATE_COOLDOWN")
    assertEqual(manager.barTexture.vertexColor[1], 0.58)

    environment.cooldownDuration = newCooldown(true, 0)
    environment.knownSpells = {}
    castEvent(environment, "SPELLS_CHANGED")
    assertEqual(manager.interruptSpell, nil)
    assertEqual(manager.barTexture.vertexColor[1], 0.58)
end)

test("secret cooldown, range, and interruptibility values use native safe color lanes", function()
    local environment = loadAddon("enUS", { castBarEnabled = true })
    local manager = environment.castBar
    local function secret(value)
        return { secret = true, value = value }
    end
    environment.knownSpells[1766] = "player"
    environment.range = secret(true)
    environment.cooldownDuration = newCooldown(secret(false), 2)
    environment.castInfo = {
        kind = "cast",
        name = "Secret-state cast",
        icon = "spell-icon",
        notInterruptible = secret(false),
        duration = newDuration(4, 1, 3),
    }

    castEvent(environment, "UNIT_SPELLCAST_START", "focus", "cast-secret")
    assertEqual(manager.barTexture.vertexColor[1], 0.95)
    assertEqual(manager.readySegment.alpha, 1)
    assertEqual(manager.uninterruptibleHost.alpha, 0)

    environment.range = secret(false)
    environment.cooldownDuration = newCooldown(secret(true), 0)
    environment.castInfo.notInterruptible = secret(true)
    castEvent(environment, "SPELL_UPDATE_USABLE")
    assertEqual(manager.barTexture.vertexColor[1], 0.95)
    assertEqual(manager.readySegment.alpha, 0)
    assertEqual(manager.uninterruptibleHost.alpha, 1)
    assertEqual(manager.uninterruptibleOverlay.vertexColor[1], 0.45)
end)

test("pet and specialization interrupt changes refresh the active cast", function()
    local environment = loadAddon("enUS", { castBarEnabled = true })
    local manager = environment.castBar
    environment.class = "WARLOCK"
    environment.knownSpells[19647] = "player"
    environment.knownSpells[119910] = "pet"
    environment.cooldownDuration = newCooldown(false, 2)
    environment.castInfo = {
        kind = "cast",
        name = "Pet kick cast",
        icon = "spell-icon",
        notInterruptible = false,
        duration = newDuration(4, 1, 3),
    }
    castEvent(environment, "UNIT_SPELLCAST_START", "focus", "cast-4")
    assertEqual(manager.interruptSpell, 119910)

    environment.class = "MAGE"
    environment.knownSpells = { [2139] = "player" }
    castEvent(environment, "PLAYER_SPECIALIZATION_CHANGED", "player")
    assertEqual(manager.interruptSpell, 2139)
    environment.class = "WARLOCK"
    environment.knownSpells = { [89766] = "pet" }
    castEvent(environment, "UNIT_PET", "player")
    assertEqual(manager.interruptSpell, 89766)
end)

test("legacy spellbook fallback uses the global known-spell API", function()
    local environment = loadAddon("enUS", { castBarEnabled = true })
    C_SpellBook = nil
    IsSpellKnown = function(spellID)
        return spellID == 2139
    end
    environment.class = "MAGE"
    environment.cooldownDuration = newCooldown(true, 0)
    environment.castInfo = {
        kind = "cast",
        name = "Legacy lookup",
        icon = "spell-icon",
        notInterruptible = false,
        duration = newDuration(3, 1, 2),
    }
    castEvent(environment, "UNIT_SPELLCAST_START", "focus", "cast-legacy")
    assertEqual(environment.castBar.interruptSpell, 2139)
end)

test("channel bars use reversed remaining-time progress and stop cleanly", function()
    local environment = loadAddon("enUS", { castBarEnabled = true })
    local manager = environment.castBar
    environment.castInfo = {
        kind = "channel",
        name = "Channel",
        icon = "channel-icon",
        notInterruptible = false,
        duration = newDuration(6, 2, 4),
    }
    castEvent(environment, "UNIT_SPELLCAST_CHANNEL_START", "focus", "channel-1")

    assertEqual(manager.frame:IsShown(), true)
    assertEqual(manager.frame.timerDirection, "REMAINING")
    assertEqual(manager.marker.fillStyle, "REVERSE")
    assertEqual(manager.nameText.text, "Channel")
    assertEqual(manager.timeText.text, "4.0")

    castEvent(environment, "UNIT_SPELLCAST_CHANNEL_STOP", "focus", "channel-1")
    assertEqual(manager.frame:IsShown(), false)
end)

test("cast-bar color controls are localized and editable", function()
    local environment = loadAddon("zhCN")
    FocusClaimOptionsPanel.scripts.OnShow(FocusClaimOptionsPanel)
    assertEqual(environment.L.CASTBAR_ENABLE, "焦点施法时显示")

    local control = environment.castBar.optionControls["color:green"]
    environment.pickerColor = { 0.3, 0.4, 0.5 }
    environment.castBar:OpenColorPicker("green", control.swatch)
    environment.colorPicker.swatchFunc()
    local color = environment.addon:GetSettings().castBarColors.green
    assertEqual(color.r, 0.3)
    assertEqual(color.g, 0.4)
    assertEqual(color.b, 0.5)
    assertEqual(control.swatch.color[2], 0.4)
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

    assertEqual(initialFrames, 9)
    assertEqual(builtFrames, 18)
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
