local kb = kb or {}

kb.RD = kb.RD or {}

net.Receive("kb_data",function()
    kb.RD = net.ReadTable()
end)

hook.Add("HUDPaint","TimerRound",function()

    local w, h = ScrW() , ScrH()

    if kb.RD.current_round == "constract" then 
        draw.SimpleText("Зона начнет сужаться через - 00:00","ChatFont", w / 2 , h /1.05 , color_white, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER)
    else
        draw.SimpleText("Раунд закончится через - 00:00","ChatFont", w / 2 , h /1.05 , color_white, TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER)
    end
end)