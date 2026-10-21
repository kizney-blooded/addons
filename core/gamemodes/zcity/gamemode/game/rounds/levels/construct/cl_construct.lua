hook.Add("HUDPaint", "hud_constract", function()
    if kb.RD.current_round != "constract" then return end
    local ply = LocalPlayer()

    if not IsValid(ply) or ply:Alive() then return end

    local w , h = ScrW() , ScrH()

    local targetTime = ply:GetNWFloat("RespawnTime", 0)
    if targetTime == 0 then return end

    local timeLeft = math.max(0, math.ceil(targetTime - CurTime()))

    if timeLeft == 0 then return end

    draw.SimpleText(
        "До возрождения осталось - " .. timeLeft .. " секунд",
        "ChatFont",
        w / 2,
        h / 1.1,
        color_white,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER
    )
end)