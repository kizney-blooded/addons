hook.Add("HUDPaint","DebugTextKB",function()
    local w , h = ScrW() , ScrH()

    draw.SimpleTextOutlined("kizney`s box 124 commits","DebugFixed",w - 105, h / 1.01 , color_white , TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER, 0.9, color_black)
end)