local _, ns = ...

local addon = ns.addon
local L = ns.L
local BAR_TEXTURE = "Interface\\Buttons\\WHITE8X8"

local INTERRUPTS = {
    DEATHKNIGHT = { 47528 },
    WARRIOR = { 6552 },
    WARLOCK = { 19647, 89766, 119910, 1276467, 132409 },
    SHAMAN = { 57994 },
    ROGUE = { 1766 },
    PRIEST = { 15487 },
    PALADIN = { 31935, 96231 },
    MONK = { 116705 },
    MAGE = { 2139 },
    HUNTER = { 187707, 147362 },
    EVOKER = { 351338 },
    DRUID = { 38675, 78675, 106839 },
    DEMONHUNTER = { 183752 },
}

local COLOR_KEYS = { "grey", "green", "orange", "unknown" }
local COLOR_LABELS = {
    grey = L.CASTBAR_COLOR_GREY,
    green = L.CASTBAR_COLOR_GREEN,
    orange = L.CASTBAR_COLOR_ORANGE,
    unknown = L.CASTBAR_COLOR_UNKNOWN,
}

local function GetSettings()
    return addon:GetSettings()
end

local function IsSecret(value)
    return type(issecretvalue) == "function" and issecretvalue(value)
end

local function BooleanValue(value)
    if IsSecret(value) then
        return "secret", value
    end
    if type(value) == "boolean" then
        return "plain", value
    end
    return "unknown"
end

local function EvaluateBoolean(value, falseValue, trueValue)
    local curve = C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean
    if curve then
        return curve(value, falseValue, trueValue)
    end
    local kind, plainValue = BooleanValue(value)
    if kind == "plain" then
        if plainValue then
            return trueValue
        end
        return falseValue
    end
end

local function GetClassToken()
    if UnitClassBase then
        return UnitClassBase("player")
    end
    if UnitClass then
        local _, classToken = UnitClass("player")
        return classToken
    end
end

local function FindKnownSpellBank(spellID)
    if C_SpellBook and C_SpellBook.IsSpellKnownOrInSpellBook then
        local banks = Enum and Enum.SpellBookSpellBank
        if banks and banks.Pet
            and C_SpellBook.IsSpellKnownOrInSpellBook(spellID, banks.Pet)
        then
            return "pet"
        end
        if C_SpellBook.IsSpellKnownOrInSpellBook(spellID) then
            return "player"
        end
    elseif IsSpellKnown and IsSpellKnown(spellID) then
        return "player"
    end
end

local function FindInterruptSpell()
    local spells = INTERRUPTS[GetClassToken()]
    if not spells then
        return nil
    end

    local petSpell, playerSpell
    for index = 1, #spells do
        local spellID = spells[index]
        local bank = FindKnownSpellBank(spellID)
        if bank == "pet" then
            petSpell = spellID
        elseif bank == "player" then
            playerSpell = spellID
        end
    end
    return petSpell or playerSpell
end

local function GetRange(spellID)
    if not (C_Spell and C_Spell.IsSpellInRange) then
        return "unknown"
    end
    local result = C_Spell.IsSpellInRange(spellID, "focus")
    local kind, value = BooleanValue(result)
    if kind == "secret" then
        return kind, value
    elseif kind == "plain" then
        return kind, value
    end
    return "unknown"
end

local function GetCooldown(spellID)
    if not (C_Spell and C_Spell.GetSpellCooldownDuration) then
        return nil
    end
    local duration = C_Spell.GetSpellCooldownDuration(spellID)
    if duration and duration.IsZero and duration.GetRemainingDuration then
        return duration
    end
end

local function GetSpellUsability(spellID)
    if not (C_Spell and C_Spell.IsSpellUsable) then
        return "unknown"
    end
    local usable = C_Spell.IsSpellUsable(spellID)
    local kind = BooleanValue(usable)
    if kind == "plain" or kind == "secret" then
        return kind, usable
    end
    return "unknown"
end

local function ColorFromCooldown(settings, cooldown)
    if not cooldown then
        return settings.castBarColors.unknown
    end
    local ready = cooldown:IsZero()
    local values = {}
    local curve = C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean
    if not curve and BooleanValue(ready) ~= "plain" then
        return settings.castBarColors.unknown
    end
    for _, component in ipairs({ "r", "g", "b" }) do
        values[component] = EvaluateBoolean(
            ready,
            settings.castBarColors.orange[component],
            settings.castBarColors.green[component]
        )
    end
    return values
end

local function ColorForInterrupt(settings, spellID)
    local rangeKind, inRange = GetRange(spellID)
    if rangeKind == "unknown" then
        return settings.castBarColors.unknown, rangeKind
    end
    local cooldown = GetCooldown(spellID)
    if not cooldown then
        return settings.castBarColors.unknown, rangeKind
    end
    local usabilityKind, usable = GetSpellUsability(spellID)
    if usabilityKind == "unknown"
        or usabilityKind == "secret" and not (C_CurveUtil
            and C_CurveUtil.EvaluateColorValueFromBoolean)
    then
        return settings.castBarColors.unknown, "unknown"
    end
    if rangeKind == "plain" and not inRange then
        return settings.castBarColors.orange, rangeKind, cooldown
    end

    local readyColor = ColorFromCooldown(settings, cooldown)
    local values = {}
    local curve = C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean
    for _, component in ipairs({ "r", "g", "b" }) do
        local usableColor = EvaluateBoolean(
            usable,
            settings.castBarColors.orange[component],
            readyColor[component]
        )
        if rangeKind == "secret" then
            if not curve then
                return settings.castBarColors.unknown, "unknown"
            end
            values[component] = curve(
                inRange,
                settings.castBarColors.orange[component],
                usableColor
            )
        else
            values[component] = usableColor
        end
    end
    return values, rangeKind, cooldown, inRange
end

local function SetTint(texture, color)
    texture:SetVertexColor(color.r, color.g, color.b, 1)
end

local frame = CreateFrame("StatusBar", "FocusClaimFocusCastBar", UIParent)
frame:SetSize(GetSettings().castBarWidth, GetSettings().castBarHeight)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetStatusBarTexture(BAR_TEXTURE)
frame:SetMinMaxValues(0, 1)
frame:SetValue(0)
frame:SetFrameStrata("HIGH")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:Hide()

local barTexture = frame:GetStatusBarTexture()
local background = frame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints(frame)
background:SetColorTexture(0.04, 0.04, 0.04, 0.9)

local iconFrame = CreateFrame("Frame", nil, frame)
iconFrame:SetSize(GetSettings().castBarHeight, GetSettings().castBarHeight)
iconFrame:SetPoint("RIGHT", frame, "LEFT", 0, 0)
local icon = iconFrame:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints(iconFrame)

local readySegment = frame:CreateTexture(nil, "ARTWORK", nil, 1)
readySegment:SetTexture(BAR_TEXTURE)
readySegment:SetAlpha(0)
local uninterruptibleHost = CreateFrame("Frame", nil, frame)
uninterruptibleHost:SetAllPoints(frame)
uninterruptibleHost:SetAlpha(0)
local uninterruptibleOverlay = uninterruptibleHost:CreateTexture(nil, "ARTWORK", nil, 2)
uninterruptibleOverlay:SetAllPoints(uninterruptibleHost)
uninterruptibleOverlay:SetTexture(BAR_TEXTURE)
local textLayer = CreateFrame("Frame", nil, frame)
textLayer:SetAllPoints(frame)
local timeText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
timeText:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
timeText:SetWidth(42)
timeText:SetJustifyH("RIGHT")
local previewText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
previewText:SetPoint("CENTER", frame, "CENTER")
previewText:SetJustifyH("CENTER")
previewText:SetText("")
local nameText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
nameText:SetPoint("LEFT", frame, "LEFT", 6, 0)
nameText:SetPoint("RIGHT", timeText, "LEFT", -4, 0)
nameText:SetJustifyH("LEFT")
nameText:SetWordWrap(false)

local positioner = CreateFrame("StatusBar", nil, frame)
positioner:SetAllPoints(frame)
positioner:SetStatusBarTexture(BAR_TEXTURE)
positioner:SetAlpha(0)
local marker = CreateFrame("StatusBar", nil, frame)
marker:SetSize(GetSettings().castBarWidth, GetSettings().castBarHeight)
marker:SetStatusBarTexture(BAR_TEXTURE)
marker:SetAlpha(0)

local eventFrame = CreateFrame("Frame")
local barManager = {
    frame = frame,
    iconFrame = iconFrame,
    eventFrame = eventFrame,
    activeKind = nil,
    interruptSpell = nil,
    positioner = positioner,
    marker = marker,
    readySegment = readySegment,
    uninterruptibleOverlay = uninterruptibleOverlay,
    uninterruptibleHost = uninterruptibleHost,
    barTexture = barTexture,
    nameText = nameText,
    timeText = timeText,
    previewText = previewText,
    optionControls = {},
}
addon.castBar = barManager
ns.castBar = barManager

local function ApplyPosition()
    local settings = GetSettings()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", settings.castBarX, settings.castBarY)
end

local function ApplySize()
    local settings = GetSettings()
    frame:SetSize(settings.castBarWidth, settings.castBarHeight)
    iconFrame:SetSize(settings.castBarHeight, settings.castBarHeight)
    marker:SetSize(settings.castBarWidth, settings.castBarHeight)
end

local function ApplyLock()
    local locked = GetSettings().castBarLocked
    frame:SetMovable(true)
    frame:EnableMouse(not locked)
end

local function StopCast()
    barManager.activeKind = nil
    frame:SetScript("OnUpdate", nil)
    nameText:SetText("")
    timeText:SetText("")
    readySegment:SetAlpha(0)
    uninterruptibleHost:SetAlpha(0)
    if GetSettings().castBarEnabled and not GetSettings().castBarLocked then
        frame:SetMinMaxValues(0, 1)
        frame:SetValue(1)
        SetTint(barTexture, GetSettings().castBarColors.unknown)
        iconFrame:Hide()
        previewText:SetText(L.CASTBAR_PREVIEW)
        frame:Show()
    else
        iconFrame:Hide()
        previewText:SetText("")
        frame:Hide()
    end
end

local function GetCastDuration(kind)
    if kind == "channel" then
        return UnitChannelDuration and UnitChannelDuration("focus")
    elseif kind == "empowered" then
        return (UnitEmpoweredChannelDuration
            and UnitEmpoweredChannelDuration("focus", true))
            or (UnitChannelDuration and UnitChannelDuration("focus"))
    end
    return UnitCastingDuration and UnitCastingDuration("focus")
end

local function ReadCastDetails(kind)
    if kind == "channel" or kind == "empowered" then
        if UnitChannelInfo then
            local name, _, texture, _, _, _, notInterruptible = UnitChannelInfo("focus")
            return name, texture, notInterruptible
        end
    elseif UnitCastingInfo then
        local name, _, texture, _, _, _, _, notInterruptible = UnitCastingInfo("focus")
        return name, texture, notInterruptible
    end
end

local function GetBooleanAlpha(value, falseAlpha, trueAlpha)
    local kind = BooleanValue(value)
    if kind == "secret" and not (C_CurveUtil
        and C_CurveUtil.EvaluateColorValueFromBoolean)
    then
        return nil, false
    end
    if kind == "unknown" then
        return nil, false
    end
    return EvaluateBoolean(value, falseAlpha, trueAlpha), true
end

local function ApplyUninterruptibleTint(notInterruptible)
    local kind, value = BooleanValue(notInterruptible)
    if kind == "secret" then
        SetTint(uninterruptibleOverlay, GetSettings().castBarColors.grey)
        if uninterruptibleHost.SetAlphaFromBoolean then
            uninterruptibleHost:SetAlphaFromBoolean(value, 1, 0)
            return true
        end
        local alpha, canEvaluate = GetBooleanAlpha(value, 0, 1)
        if canEvaluate then
            uninterruptibleHost:SetAlpha(alpha)
            return true
        end
        uninterruptibleHost:SetAlpha(0)
        return false
    elseif kind == "plain" then
        SetTint(uninterruptibleOverlay, GetSettings().castBarColors.grey)
        uninterruptibleHost:SetAlpha(value and 1 or 0)
        return true
    end
    uninterruptibleHost:SetAlpha(0)
    return false
end

local function ConfigureDirection(kind)
    local reverse = kind == "channel"
    local fillStyle = Enum and Enum.StatusBarFillStyle
    if fillStyle and positioner.SetFillStyle then
        positioner:SetFillStyle(reverse and fillStyle.Reverse or fillStyle.Standard)
        marker:SetFillStyle(reverse and fillStyle.Reverse or fillStyle.Standard)
    elseif positioner.SetReverseFill then
        positioner:SetReverseFill(reverse)
        marker:SetReverseFill(reverse)
    end

    local positionTexture = positioner:GetStatusBarTexture()
    local markerTexture = marker:GetStatusBarTexture()
    if not (positionTexture and markerTexture) then
        readySegment:ClearAllPoints()
        return
    end
    marker:ClearAllPoints()
    readySegment:ClearAllPoints()
    -- If the cooldown ends after the cast, crossed anchors collapse the ready window.
    if reverse then
        marker:SetPoint("RIGHT", positionTexture, "LEFT")
        readySegment:SetPoint("LEFT", frame, "LEFT", 0, 0)
        readySegment:SetPoint("RIGHT", markerTexture, "LEFT")
    else
        marker:SetPoint("LEFT", positionTexture, "RIGHT")
        readySegment:SetPoint("LEFT", markerTexture, "RIGHT")
        readySegment:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    end
    readySegment:SetPoint("TOP", frame, "TOP", 0, 0)
    readySegment:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
end

local function HideReadySegment()
    readySegment:SetAlpha(0)
end

local function UpdateReadySegment(duration, cooldown, rangeKind, inRange, notInterruptible)
    SetTint(readySegment, GetSettings().castBarColors.green)
    if not (duration and duration.GetTotalDuration and duration.GetElapsedDuration
        and cooldown and cooldown.GetRemainingDuration
        and positioner.SetMinMaxValues and positioner.SetValue
        and marker.SetMinMaxValues and marker.SetValue
    ) then
        HideReadySegment()
        return
    end
    local rangeBooleanKind = rangeKind
    if rangeBooleanKind == "unknown" or rangeBooleanKind == "plain" and not inRange then
        HideReadySegment()
        return
    end
    local kickProtectedKind = BooleanValue(notInterruptible)
    if kickProtectedKind == "unknown" then
        HideReadySegment()
        return
    end

    local total = duration:GetTotalDuration()
    positioner:SetMinMaxValues(0, total)
    positioner:SetValue(duration:GetElapsedDuration())
    marker:SetMinMaxValues(0, total)
    marker:SetValue(cooldown:GetRemainingDuration())

    local offCooldown = cooldown:IsZero()
    local alpha, canEvaluate = GetBooleanAlpha(offCooldown, 1, 0)
    if not canEvaluate then
        HideReadySegment()
        return
    end
    if rangeBooleanKind == "secret" then
        alpha, canEvaluate = GetBooleanAlpha(inRange, 0, alpha)
        if not canEvaluate then
            HideReadySegment()
            return
        end
    end
    alpha, canEvaluate = GetBooleanAlpha(notInterruptible, alpha, 0)
    if not canEvaluate then
        HideReadySegment()
        return
    end
    readySegment:SetAlpha(alpha)
end

local function ApplyInterruptTint(duration, notInterruptible, interruptionKnown)
    local settings = GetSettings()
    if not interruptionKnown or not barManager.interruptSpell then
        SetTint(barTexture, settings.castBarColors.unknown)
        HideReadySegment()
        return
    end

    local color, rangeKind, cooldown, inRange = ColorForInterrupt(
        settings,
        barManager.interruptSpell
    )
    SetTint(barTexture, color)
    if not cooldown then
        HideReadySegment()
        return
    end
    UpdateReadySegment(duration, cooldown, rangeKind, inRange, notInterruptible)
end

local function UpdateActiveCast(configureTimer)
    local kind = barManager.activeKind
    if not kind then
        return
    end
    local duration = GetCastDuration(kind)
    if duration then
        if configureTimer then
            if frame.SetTimerDuration and Enum and Enum.StatusBarTimerDirection then
                frame:SetReverseFill(false)
                local direction = kind == "channel"
                    and Enum.StatusBarTimerDirection.RemainingTime
                    or Enum.StatusBarTimerDirection.ElapsedTime
                frame:SetTimerDuration(duration, nil, direction)
            end
            ConfigureDirection(kind)
        end
        if duration.GetRemainingDuration then
            timeText:SetFormattedText("%.1f", duration:GetRemainingDuration())
        else
            timeText:SetText("")
        end
    else
        timeText:SetText("")
    end

    local name, texture, notInterruptible = ReadCastDetails(kind)
    nameText:SetText(name)
    icon:SetTexture(texture)
    local interruptionKind = BooleanValue(notInterruptible)
    local interruptionKnown = ApplyUninterruptibleTint(notInterruptible)
        and interruptionKind ~= "unknown"
    ApplyInterruptTint(duration, notInterruptible, interruptionKnown)
end

local function InstallOnUpdate()
    local sinceUpdate = 0
    frame:SetScript("OnUpdate", function(_, elapsed)
        if not GetSettings().castBarEnabled or not barManager.activeKind then
            StopCast()
            return
        end
        sinceUpdate = sinceUpdate + elapsed
        if sinceUpdate < 0.1 then
            return
        end
        sinceUpdate = 0
        UpdateActiveCast(false)
    end)
end

local function StartCast(kind)
    if not GetSettings().castBarEnabled then
        return
    end
    barManager.activeKind = kind
    barManager.interruptSpell = FindInterruptSpell()
    iconFrame:Show()
    previewText:SetText("")
    frame:Show()
    InstallOnUpdate()
    UpdateActiveCast(true)
end

local function FindCurrentCast()
    local empowered = UnitEmpoweredChannelDuration
        and UnitEmpoweredChannelDuration("focus", true)
    if empowered then
        return "empowered"
    end
    local channel = UnitChannelDuration and UnitChannelDuration("focus")
    if channel then
        return "channel"
    end
    local cast = UnitCastingDuration and UnitCastingDuration("focus")
    if cast then
        return "cast"
    end
end

local function RefreshCurrentCast()
    if not GetSettings().castBarEnabled then
        StopCast()
        return
    end
    local kind = FindCurrentCast()
    if not kind then
        StopCast()
        return
    end
    StartCast(kind)
end

local function RefreshActiveCast()
    if not GetSettings().castBarEnabled or not barManager.activeKind then
        return
    end
    barManager.interruptSpell = FindInterruptSpell()
    UpdateActiveCast(false)
end

function barManager:SettingsChanged()
    ApplyLock()
    ApplySize()
    ApplyPosition()
    if GetSettings().castBarEnabled then
        RefreshCurrentCast()
    else
        StopCast()
    end
end

function barManager:OptionChanged(setting)
    if setting == "castBarEnabled" then
        if GetSettings().castBarEnabled then
            RefreshCurrentCast()
        else
            StopCast()
        end
    elseif setting == "castBarLocked" then
        ApplyLock()
        if not self.activeKind then
            StopCast()
        end
    end
end

function barManager:SizeChanged()
    ApplySize()
    if self.activeKind then
        UpdateActiveCast(true)
    end
end

function barManager:ColorsChanged()
    if self.activeKind then
        UpdateActiveCast(false)
    end
end

function barManager:BuildOptions(parent, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 20, y)
    header:SetText(L.CASTBAR_HEADER)

    local function CreateCheck(setting, labelText, offset)
        local check = CreateFrame("CheckButton", nil, parent,
            "InterfaceOptionsCheckButtonTemplate")
        check:SetPoint("TOPLEFT", 16, y - offset)
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", check, "RIGHT", 0, 0)
        label:SetText(labelText)
        check:SetScript("OnClick", function(self)
            GetSettings()[setting] = not not self:GetChecked()
            barManager:OptionChanged(setting)
        end)
        self.optionControls[setting] = { check = check }
    end

    CreateCheck("castBarEnabled", L.CASTBAR_ENABLE, 30)
    CreateCheck("castBarLocked", L.CASTBAR_LOCK, 58)

    local function CreateSizeInput(setting, labelText, offset)
        local limits = ns.castBarSizeLimits[setting]
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("TOPLEFT", 20, y - offset)
        label:SetText(labelText:format(limits.min, limits.max))
        local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        input:SetSize(60, 24)
        input:SetPoint("LEFT", label, "RIGHT", 12, 0)
        input:SetAutoFocus(false)
        input:SetNumeric(true)
        input:SetMaxLetters(3)
        input:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)
        input:SetScript("OnEscapePressed", function(self)
            self:SetText(tostring(GetSettings()[setting]))
            self:ClearFocus()
        end)
        input:SetScript("OnEditFocusLost", function(self)
            local value = tonumber(self:GetText())
            if value and value >= limits.min and value <= limits.max and value % 1 == 0 then
                if GetSettings()[setting] ~= value then
                    GetSettings()[setting] = value
                    barManager:SizeChanged()
                end
            end
            self:SetText(tostring(GetSettings()[setting]))
        end)
        self.optionControls[setting] = { input = input }
    end

    CreateSizeInput("castBarWidth", L.CASTBAR_WIDTH, 94)
    CreateSizeInput("castBarHeight", L.CASTBAR_HEIGHT, 126)

    local colorsHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorsHeader:SetPoint("TOPLEFT", 20, y - 162)
    colorsHeader:SetText(L.CASTBAR_COLORS)
    for index = 1, #COLOR_KEYS do
        local key = COLOR_KEYS[index]
        local rowY = y - 188 - (index - 1) * 34
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("TOPLEFT", 20, rowY)
        label:SetText(COLOR_LABELS[key])
        local button = CreateFrame("Button", nil, parent)
        button:SetSize(32, 18)
        button:SetPoint("TOPLEFT", 250, rowY + 2)
        button.swatch = button:CreateTexture(nil, "ARTWORK")
        button.swatch:SetAllPoints(button)
        button:SetScript("OnClick", function()
            self:OpenColorPicker(key, button.swatch)
        end)
        self.optionControls["color:" .. key] = {
            button = button,
            swatch = button.swatch,
            key = key,
        }
    end
end

function barManager:RefreshOptions()
    local settings = GetSettings()
    for setting, control in pairs(self.optionControls) do
        if control.check then
            control.check:SetChecked(settings[setting])
        elseif control.input then
            control.input:SetText(tostring(settings[setting]))
        elseif control.swatch then
            local color = settings.castBarColors[control.key]
            control.swatch:SetColorTexture(color.r, color.g, color.b, 1)
        end
    end
end

function barManager:OpenColorPicker(key, swatch)
    if not (ColorPickerFrame and (ColorPickerFrame.SetupColorPickerAndShow
        or ColorPickerFrame.SetColorRGB))
    then
        return
    end
    local current = GetSettings().castBarColors[key]
    local previous = { r = current.r, g = current.g, b = current.b }
    local function ApplyColor(r, g, b)
        if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
            return
        end
        GetSettings().castBarColors[key] = { r = r, g = g, b = b }
        swatch:SetColorTexture(r, g, b, 1)
        barManager:ColorsChanged()
    end
    local function ReadPickerColor()
        if ColorPickerFrame.GetColorRGB then
            ApplyColor(ColorPickerFrame:GetColorRGB())
        end
    end
    local function CancelColor(values)
        local color = values or previous
        ApplyColor(color.r or color[1], color.g or color[2], color.b or color[3])
    end
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = current.r,
            g = current.g,
            b = current.b,
            hasOpacity = false,
            swatchFunc = ReadPickerColor,
            cancelFunc = CancelColor,
        })
    else
        ColorPickerFrame.func = ReadPickerColor
        ColorPickerFrame.cancelFunc = CancelColor
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.previousValues = { current.r, current.g, current.b }
        ColorPickerFrame:SetColorRGB(current.r, current.g, current.b)
        ColorPickerFrame:Show()
    end
end

frame:SetScript("OnDragStart", function(self)
    if not GetSettings().castBarLocked then
        self:StartMoving()
    end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local x, y = self:GetCenter()
    local parentX, parentY = UIParent:GetCenter()
    if x and y and parentX and parentY then
        local settings = GetSettings()
        settings.castBarX = x - parentX
        settings.castBarY = y - parentY
        ApplyPosition()
    end
end)

local CAST_EVENTS = {
    UNIT_SPELLCAST_START = "cast",
    UNIT_SPELLCAST_DELAYED = "cast",
    UNIT_SPELLCAST_CHANNEL_START = "channel",
    UNIT_SPELLCAST_CHANNEL_UPDATE = "channel",
    UNIT_SPELLCAST_EMPOWER_START = "empowered",
    UNIT_SPELLCAST_EMPOWER_UPDATE = "empowered",
}
local STOP_EVENTS = {
    UNIT_SPELLCAST_STOP = true,
    UNIT_SPELLCAST_FAILED = true,
    UNIT_SPELLCAST_INTERRUPTED = true,
    UNIT_SPELLCAST_CHANNEL_STOP = true,
    UNIT_SPELLCAST_EMPOWER_STOP = true,
}
local REFRESH_EVENTS = {
    UNIT_SPELLCAST_INTERRUPTIBLE = true,
    UNIT_SPELLCAST_NOT_INTERRUPTIBLE = true,
}
local UNIT_EVENTS = {}
for event in pairs(CAST_EVENTS) do UNIT_EVENTS[event] = true end
for event in pairs(STOP_EVENTS) do UNIT_EVENTS[event] = true end
for event in pairs(REFRESH_EVENTS) do UNIT_EVENTS[event] = true end

local function HandleEvent(_, event, ...)
    local firstArg = ...
    if event == "ADDON_LOADED" then
        if firstArg == "FocusClaim" then
            barManager:SettingsChanged()
        end
        return
    end
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_FOCUS_CHANGED" then
        RefreshCurrentCast()
        return
    end
    if event == "UNIT_PET" then
        if firstArg ~= "player" or not GetSettings().castBarEnabled then
            return
        end
        barManager.interruptSpell = FindInterruptSpell()
        RefreshActiveCast()
        return
    end
    if event == "SPELLS_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED"
        or event == "PLAYER_TALENT_UPDATE"
    then
        if GetSettings().castBarEnabled then
            barManager.interruptSpell = FindInterruptSpell()
            RefreshActiveCast()
        end
        return
    end
    if event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_USABLE" then
        if GetSettings().castBarEnabled then
            RefreshActiveCast()
        end
        return
    end
    if UNIT_EVENTS[event] then
        if not GetSettings().castBarEnabled then
            return
        end
        if firstArg ~= "focus" then
            return
        end
        if CAST_EVENTS[event] then
            StartCast(CAST_EVENTS[event])
        elseif STOP_EVENTS[event] then
            StopCast()
        else
            RefreshActiveCast()
        end
    end
end

eventFrame:SetScript("OnEvent", HandleEvent)
local events = {
    "ADDON_LOADED",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_FOCUS_CHANGED",
    "SPELLS_CHANGED",
    "PLAYER_SPECIALIZATION_CHANGED",
    "PLAYER_TALENT_UPDATE",
    "UNIT_PET",
    "SPELL_UPDATE_COOLDOWN",
    "SPELL_UPDATE_USABLE",
}
for index = 1, #events do
    pcall(eventFrame.RegisterEvent, eventFrame, events[index])
end
for event in pairs(UNIT_EVENTS) do
    if eventFrame.RegisterUnitEvent then
        pcall(eventFrame.RegisterUnitEvent, eventFrame, event, "focus")
    else
        pcall(eventFrame.RegisterEvent, eventFrame, event)
    end
end

ApplyLock()
ApplyPosition()
if GetSettings().castBarEnabled then
    RefreshCurrentCast()
end
