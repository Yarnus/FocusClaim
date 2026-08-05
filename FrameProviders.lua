local _, ns = ...

local globalFrameNames = {
    "PlayerFrame",
    "PetFrame",
    "TargetFrame",
    "TargetFrameToT",
    "FocusFrame",
    "UUF_Player",
    "UUF_Pet",
    "UUF_Target",
    "UUF_TargetTarget",
    "UUF_Focus",
    "UUF_FocusTarget",
    "EQOLUFPlayerFrame",
    "EQOLUFTargetFrame",
    "EQOLUFToTFrame",
    "EQOLUFFocusFrame",
    "EllesmereUIUnitFrames_Player",
    "EllesmereUIUnitFrames_Target",
    "EllesmereUIUnitFrames_Focus",
    "EllesmereUIUnitFrames_Pet",
    "EllesmereUIUnitFrames_TargetTarget",
    "EllesmereUIUnitFrames_FocusTarget",
}

local function AddSeries(prefix, first, last, suffix)
    suffix = suffix or ""
    for index = first, last do
        globalFrameNames[#globalFrameNames + 1] = prefix .. index .. suffix
    end
end

AddSeries("PartyMemberFrame", 1, 5)
AddSeries("Boss", 1, 5, "TargetFrame")
AddSeries("UUF_Boss", 1, 10)
AddSeries("EQOLUFBoss", 1, 5, "Frame")
AddSeries("EllesmereUIUnitFrames_Boss", 1, 5)

local function VisitGlobals(visit)
    for index = 1, #globalFrameNames do
        visit(_G[globalFrameNames[index]])
    end
end

local function VisitNameplates(visit)
    if not C_NamePlate or type(C_NamePlate.GetNamePlates) ~= "function" then
        return
    end
    for _, frame in pairs(C_NamePlate.GetNamePlates()) do
        visit(frame)
    end
end

local function VisitDandersFrames(visit)
    local frames = _G.DandersFrames
    if not frames then
        return
    end

    visit(frames.playerFrame)
    for index = 1, 4 do
        visit(frames.partyFrames and frames.partyFrames[index])
    end
    for index = 1, 40 do
        visit(frames.raidFrames and frames.raidFrames[index])
    end
end

local function VisitEllesmereGroups(visit)
    for group = 1, 8 do
        local header = _G["ERFGroupHeader" .. group]
        if header then
            for index = 1, 5 do
                visit(header[index])
            end
        end
    end

    local flatHeader = _G.ERFFlatHeader
    if flatHeader then
        for index = 1, 40 do
            visit(flatHeader[index])
        end
    end

    local partyHeader = _G.ERFPartyHeader
    if partyHeader then
        for index = 1, 5 do
            visit(partyHeader[index])
        end
    end
    visit(_G.ERFPartySelfButton)
end

local providers = {
    VisitGlobals,
    VisitNameplates,
    VisitDandersFrames,
    VisitEllesmereGroups,
}

function ns.VisitSupportedFrames(visitor)
    local seen = {}
    local function visit(frame)
        if frame
            and not seen[frame]
            and type(frame.SetAttribute) == "function"
            and type(frame.GetAttribute) == "function"
        then
            seen[frame] = true
            visitor(frame)
        end
    end

    for index = 1, #providers do
        providers[index](visit)
    end
end
