local UPDATE_VERSION = "v0.02" 
local COOKIE_NAME = "Kizney`s Box " .. UPDATE_VERSION

if IsValid(ActiveMenuFrame) then 
    ActiveMenuFrame:Remove() 
end

ActiveMenuFrame = nil

local function ShowUpdateMenu( forceShow )
    if not forceShow and cookie.GetString(COOKIE_NAME, "0") == "1" then return end

    ActiveMenuFrame = vgui.Create("DFrame")
    ActiveMenuFrame:SetSize(450, 300)
    ActiveMenuFrame:Center()
    ActiveMenuFrame:SetTitle("Обновление | Версия " .. UPDATE_VERSION)
    ActiveMenuFrame:ShowCloseButton(false)
    ActiveMenuFrame:MakePopup()
    
    ActiveMenuFrame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(39, 39, 39))

        surface.SetDrawColor(73, 73, 73)
        surface.DrawLine(0, 0, w, 0)
        surface.DrawLine(0, 0, 0, h)

        surface.SetDrawColor(15, 15, 15, 255)
        surface.DrawLine(0, h - 1, w, h - 1) 
        surface.DrawLine(w - 1, 0, w - 1, h)
    end

    local scroll = vgui.Create("DScrollPanel", ActiveMenuFrame)
    scroll:Dock(FILL)
    scroll:DockMargin(5, 5, 5, 10)
    
    local vbar = scroll:GetVBar()
    vbar.btnUp.Paint = function() end
    vbar.btnDown.Paint = function() end
    vbar.Paint = function() end
    vbar.btnGrip.Paint = function(self, w, h) 
        draw.RoundedBox(0, 0, 0, w, h, Color(73, 73, 73))
    end
    
    local function AddTextInfo(text, color)
        local lbl = scroll:Add("DLabel")
        lbl:Dock(TOP)
        lbl:SetTextColor(color)
        lbl:SetText(text)
        lbl:SetFont("KB.3")
        lbl:SetWrap(true)
        lbl:SetAutoStretchVertical(true)
        lbl:DockMargin(0, 0, 0, 4)
    end

    AddTextInfo("Добро пожаловать. Бета тест сборки.\n", color_white)
    AddTextInfo("Играя на сервере возможно вы найдете какой-нибудь баг. Буду рад если вы сообщите разработчику данного сервера\n", color_white)

    AddTextInfo("Бинды на сервере: \n", color_white)

    AddTextInfo("Падать в регдолл - bind кнопка fake\n", color_white)
    AddTextInfo("Изменения 28.10.26:\n", color_white)

    AddTextInfo("+ Исправил отрисовку TPIK", color_white)
    AddTextInfo("+ Добавил модифицированную очистку сервера", color_white)
    AddTextInfo("+ Добавил крошки при кушание еды", color_white)
    AddTextInfo("+ Эффекты взрывы головы лучше стало", color_white)
    AddTextInfo("+ Добавил пинок (bind кнопка kb_kick)", color_white)

    local bottomPanel = vgui.Create("DPanel", ActiveMenuFrame)
    bottomPanel:Dock(BOTTOM)
    bottomPanel:SetHeight(30)
    bottomPanel.Paint = function() end 

    local checkbox = vgui.Create("DCheckBoxLabel", bottomPanel)
    checkbox:SetText("Больше не показывать")
    checkbox:Dock(LEFT)
    checkbox:SetTextColor(Color(255, 255, 255))
    checkbox:DockMargin(10, 5, 0, 5)
    checkbox:SizeToContents()

    if cookie.GetString(COOKIE_NAME, "0") == "1" then
        checkbox:SetValue(true)
    end

    local closeBtn = vgui.Create("DButton", bottomPanel)
    closeBtn:SetText("Закрыть")
    closeBtn:Dock(RIGHT)
    closeBtn:SetWide(100)
    closeBtn:SetTextColor(Color(255, 255, 255))
    closeBtn.Paint = function(self, w, h)
        local col = self:IsHovered() and Color(80, 80, 80) or Color(60, 60, 60)

        draw.RoundedBox(0, 0, 0, w, h, col)

        surface.SetDrawColor(73, 73, 73)
        surface.DrawLine(0, 0, w, 0)
        surface.DrawLine(0, 0, 0, h)

        surface.SetDrawColor(15, 15, 15, 255)
        surface.DrawLine(0, h - 1, w, h - 1) 
        surface.DrawLine(w - 1, 0, w - 1, h)
    end
    closeBtn.DoClick = function()

        if checkbox:GetChecked() then
            cookie.Set(COOKIE_NAME, "1")
        else
            cookie.Set(COOKIE_NAME, "0")
        end
        ActiveMenuFrame:Close()
    end
end

hook.Add("InitPostEntity", "ShowUpdateMenuOnJoin", function()
    timer.Simple(1, function()
        ShowUpdateMenu(false)
    end)
end)

concommand.Add("testu", function()
    ShowUpdateMenu(true)
end)


hook.Add("HUDPaint","DebugTextKB",function()
    local w , h = ScrW() , ScrH()

    draw.SimpleTextOutlined(COOKIE_NAME,"DebugFixed",w - 90, h / 1.01 , color_white , TEXT_ALIGN_CENTER , TEXT_ALIGN_CENTER, 0.9, color_black)
end)