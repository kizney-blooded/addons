local textAlpha = 0
local lastPlayerName = ""
local lastPlayerColor = color_white

hook.Add("HUDPaint", "player_targetid", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not ply:Alive() then return end

    local w , h = ScrW(), ScrH()

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    local targetAlpha = 0

    local is_player = IsValid(ent) and ent:IsPlayer()
    local is_fake = IsValid(ent) and ent:GetClass() == "prop_ragdoll" and ent:GetNWString("FakePlayerName", "") != ""

    if is_fake and ent == ply:GetNWEntity("FakeRagdoll") then
        is_fake = false
    end

    if (is_player or is_fake) and tr.StartPos:Distance(tr.HitPos) <= 65 then
        targetAlpha = 255
        
        lastPlayerName = is_player and ent:Nick() or ent:GetNWString("FakePlayerName")

        local pColor = is_player and ent:GetPlayerColor() or ent:GetNWVector("PlayerColor")
        lastPlayerColor = Color(pColor.x * 255, pColor.y * 255, pColor.z * 255)
    end

    textAlpha = Lerp(FrameTime() * 10, textAlpha, targetAlpha)

    if textAlpha > 1 then
        local drawColor = Color(lastPlayerColor.r, lastPlayerColor.g, lastPlayerColor.b, textAlpha)
        local drawColor_shadow = Color(0,0,0, textAlpha)

        draw.SimpleText(
            lastPlayerName, 
            "HudDefault", 
            w / 2, 
            h / 2 + 52,
            drawColor_shadow, 
            TEXT_ALIGN_CENTER, 
            TEXT_ALIGN_CENTER
        )
        
        draw.SimpleText(
            lastPlayerName, 
            "HudDefault", 
            w / 2, 
            h / 2 + 50,
            drawColor, 
            TEXT_ALIGN_CENTER, 
            TEXT_ALIGN_CENTER
        )
    end
end)