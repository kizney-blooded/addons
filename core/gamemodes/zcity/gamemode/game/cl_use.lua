local DRAW_DISTANCE = 90

local blacklist = {
    ["prop_physics"] = true,
    ["player"] = true,
    ["prop_ragdoll"] = true,
}

local ent_names = {
    ["func_door"] = "Открыть",
    ["func_door_rotating"] = "Открыть",
    ["prop_door_rotating"] = "Открыть",
}

local function GetAimedEntity()
    local ply = LocalPlayer()
    if not IsValid(ply) then return nil end

    local startPos = main_origin
    local angles = main_angles
    local aimVector = angles:Forward()

    local tr = util.TraceLine({
        start = startPos,
        endpos = startPos + (aimVector * DRAW_DISTANCE),
        filter = { ply, ply:GetNWEntity("FakeRagdoll") }
    })

    local ent = tr.Entity

    --print(ent)

    if not IsValid(ent) or blacklist[ent:GetClass()] or string.StartWith(ent:GetClass(), "prop_vehicle") or string.StartWith(ent:GetClass(), "gtav_") then return nil end

    return ent
end

hook.Add("PreDrawHalos", "HoverEntity_Halo", function()
    local ent = GetAimedEntity()
    if IsValid(ent) then
        halo.Add({ent}, color_white, 2, 2, 1, true, true)
    end
end)

local textAlpha = 0
local lastDisplayName = ""

hook.Add("HUDPaint", "HoverEntity_Text", function()
    local ent = GetAimedEntity()
    local targetAlpha = 0
    local displayName = nil

    if IsValid(ent) then
        local class = ent:GetClass()
        displayName = ent_names[class]

        if not displayName then
            if ent:IsWeapon() and ent.GetPrintName then
                displayName = ent:GetPrintName()
            end

            if not displayName or displayName == "" then
                displayName = ent.PrintName
            end
        end

        if displayName and displayName ~= "" then
            targetAlpha = 255
            lastDisplayName = displayName
        end
    end

    textAlpha = Lerp(FrameTime() * 10, textAlpha, targetAlpha)

    if textAlpha > 1 and lastDisplayName ~= "" then
        local x = ScrW() / 2
        local y = (ScrH() / 2) + 40
        
        local textColor = Color(255, 255, 255, textAlpha)
        local outlineColor = Color(0, 0, 0, textAlpha)

        draw.SimpleText(
            lastDisplayName, 
            "ChatFont", 
            x, 
            y, 
            textColor, 
            TEXT_ALIGN_CENTER, 
            TEXT_ALIGN_CENTER, 
            1, 
            outlineColor
        )
    end
end)