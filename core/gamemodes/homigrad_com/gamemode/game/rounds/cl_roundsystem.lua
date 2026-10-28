local kb = kb or {}

kb.RD = kb.RD or {}

net.Receive("kb_data",function()
    kb.RD = net.ReadTable()
end)

local gu = Material("vgui/gradient-u")

hook.Add("HUDPaint","RoundStateHUD",function()
    local w, h = ScrW() , ScrH()

    if kb.RD.state == 0 then
        surface.SetMaterial(gu)
        surface.SetDrawColor(255,0,0)
        surface.DrawTexturedRect(w / 2.365 , 0 , 300, 40)
        draw.SimpleText("Нужно минимум 2 игрока","KB.2",w / 2 , 26.5 , color_black , TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER)
        draw.SimpleText("Нужно минимум 2 игрока","KB.2",w / 2 , 25 , color_white , TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER)
    end
end)

hook.Add("HUDPaint","TimerRound",function()
    if kb.RD.state != 1 then return end
    local w, h = ScrW() , ScrH()
    local time_left = 0
    local respawn_time_left = 0

    if kb.RD.time_round then
        time_left = math.max(0, kb.RD.time_round - CurTime())
    end
    
    if kb.RD.disable_respawn_time then
        respawn_time_left = math.max(0, kb.RD.disable_respawn_time - CurTime())
    end

    local t = string.FormattedTime(time_left)
    local formatted_time = string.format("%02i:%02i:%02i", t.h, t.m, t.s)
    
    local rt = string.FormattedTime(respawn_time_left)
    local formatted_respawn_time = string.format("%02i:%02i:%02i", rt.h, rt.m, rt.s)

    if kb.RD.current_round == "constract" then 
        draw.SimpleText("Раунд закончится через -  " .. formatted_time, "ChatFont", w / 2 , h /1.05 , color_white, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER)
        
        if respawn_time_left > 0 then
            draw.SimpleText("Респавн отключится через - " .. formatted_respawn_time, "ChatFont", w / 2 , h /1.02 , color_white, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER)
        end
    else
        draw.SimpleText("Раунд закончится через - " .. formatted_time, "ChatFont", w / 2 , h /1.05 , color_white, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER)
    end
end)