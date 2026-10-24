local wh_enabled = false
local next_toggle = 0

hook.Add("PlayerButtonDown", "ToggleSpecWH", function(ply, button)
    if ply == LocalPlayer() and button == KEY_LALT then
        if not ply:Alive() and ply:GetObserverMode() == OBS_MODE_ROAMING then
            if CurTime() > next_toggle then
                wh_enabled = not wh_enabled
                next_toggle = CurTime() + 0.1
            end
        end
    end
end)

hook.Add("HUDPaint", "DrawSpecWH", function()
    local ply = LocalPlayer()
    
    if not wh_enabled or not IsValid(ply) then return end
    if ply:Alive() or ply:GetObserverMode() != OBS_MODE_ROAMING then return end

    for _, target in ipairs(player.GetAll()) do
        if target ~= ply and target:Alive() then
            local pos = target:GetPos()
            local screenPos = (pos - Vector(0, 0, 5)):ToScreen()

            if screenPos.visible then
                local hp = target:Health()
                local nameColor = Color(255, 0, 0)

                if hp > 70 then
                    nameColor = Color(0, 255, 0)
                elseif hp > 30 then
                    nameColor = Color(255, 127, 0)
                end

                draw.SimpleText(
                    target:Nick(), 
                    "TargetID", 
                    screenPos.x, 
                    screenPos.y, 
                    nameColor, 
                    TEXT_ALIGN_CENTER, 
                    TEXT_ALIGN_TOP
                )
            end
        end
    end
end)