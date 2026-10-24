if IsValid(CustomScoreboard) then 
    CustomScoreboard:Remove()
end

CustomScoreboard = nil

local isBoardOpen = false
local animSpeed = 0.3

local holdTime = 0.25
local isHolding = false
local isOtherWindowOpen = false

local color_white_for_hui = Color(255,255,255,5)

local function CreateScoreboard()
    if IsValid(CustomScoreboard) then return end

    local w, h = ScrW(), ScrH()
    local pnlW = w * 0.6
    local pnlH = h * 0.6

    CustomScoreboard = vgui.Create("DPanel")
    CustomScoreboard:SetSize(pnlW, pnlH)
    CustomScoreboard:Center()
    CustomScoreboard:SetAlpha(0)
    CustomScoreboard:SetVisible(false)

    local tickrate = math.Round(1 / engine.TickInterval())

    local trColor = Color(255, 0, 0)
    if tickrate > 50 then
        trColor = Color(0, 255, 0)
    elseif tickrate > 30 then
        trColor = Color(255, 150, 0)
    end
    
    CustomScoreboard.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(30, 30, 30, 240))
        
        draw.SimpleText("Кол-во игроков: " .. player.GetCount(), "ChatFont", 10, 20, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        draw.SimpleText("KIZNEY BOX", "KB.1", w / 2 , h / 2, color_white_for_hui, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        draw.SimpleText(
            "Тикрейт сервера - " .. tickrate, 
            "ChatFont", 
            w - 10, 
            h - 10, 
            trColor, 
            TEXT_ALIGN_RIGHT,
            TEXT_ALIGN_BOTTOM
        )
    end

    local scrollPanel = vgui.Create("DScrollPanel", CustomScoreboard)
    scrollPanel:Dock(FILL)
    scrollPanel:DockMargin(10, 50, 10, 10)

    CustomScoreboard.UpdatePlayers = function()
        scrollPanel:Clear()

        for _, ply in player.Iterator() do
            local plyRow = scrollPanel:Add("DButton")
            plyRow:SetText("")
            plyRow:Dock(TOP)
            plyRow:DockMargin(0, 0, 0, 5)
            plyRow:SetTall(35)

            plyRow.DoClick = function()
                if not IsValid(ply) then return end

                local menu = DermaMenu()

                menu:AddOption("Скопировать SteamID", function()
                    SetClipboardText(ply:SteamID())
                    chat.AddText(color_white, "SteamID скопирован: ", ply:SteamID())
                end)

                menu:AddOption("Перейти в профиль", function()
                    ply:ShowProfile()
                end)

                menu:Open()
            end

            plyRow.Paint = function(self, pw, ph)
                draw.RoundedBox(0, 0, 0, pw, ph, Color(39, 39, 39, 255))
                surface.SetDrawColor(73, 73, 73)
                surface.DrawLine(0, 0, pw, 0)
                surface.DrawLine(0, 0, 0, ph)
                surface.SetDrawColor(15, 15, 15, 150)
                surface.DrawLine(0, ph - 1, pw, ph - 1) 
                surface.DrawLine(pw - 1, 0, pw - 1, ph)

                if not IsValid(ply) then return end

                draw.SimpleText(ply:Nick(), "ChatFont", 15, ph / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                draw.SimpleText(ply:GetUserGroup(), "ChatFont", pw / 2, ph / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                draw.SimpleText(ply:Ping() .. " ms", "ChatFont", pw - 15, ph / 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

                if self:IsHovered() then
                    draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 2))
                end
            end
        end
    end
end

hook.Add("ScoreboardShow", "CustomScoreboard_Open", function()
    isHolding = true

    CreateScoreboard()
    CustomScoreboard:UpdatePlayers()

    timer.Create("TabHoldTimer", holdTime, 1, function()
        if isHolding then
            isOtherWindowOpen = true
            
            if LocalPlayer():Alive() and Frame_Inventory then
                Frame_Inventory()
            end
        end
    end)
    
    return true
end)

hook.Add("ScoreboardHide", "CustomScoreboard_Close", function()
    isHolding = false

    if timer.Exists("TabHoldTimer") then
        timer.Remove("TabHoldTimer")
        
        if not IsValid(CustomScoreboard) then
            CreateScoreboard()
        end
        
        isBoardOpen = not isBoardOpen
        
        local w , h = ScrW(), ScrH()
        local pnlW = w * 0.6
        local pnlH = h * 0.6

        if isBoardOpen then
            CustomScoreboard:SetVisible(true)
            CustomScoreboard:MoveTo(w / 2 - pnlW / 2, h / 2 - pnlH / 2, animSpeed, 0, -1)
            CustomScoreboard:AlphaTo(255, animSpeed, 0)
            
            gui.EnableScreenClicker(true)
        else
            CustomScoreboard:MoveTo(w / 2 - pnlW / 2, h, animSpeed, 0, -1, function()
                if IsValid(CustomScoreboard) and not isBoardOpen then
                    CustomScoreboard:SetVisible(false)
                end
            end)
            CustomScoreboard:AlphaTo(0, animSpeed, 0)
            
            gui.EnableScreenClicker(false)
        end
        
    elseif isOtherWindowOpen then
        isOtherWindowOpen = false
        
        if IsValid(lootbox_frame) then
            lootbox_frame:Close()
        elseif IsValid(main_inventory) then
            main_inventory.isClosing = true
        end
        
        if not isBoardOpen then
            gui.EnableScreenClicker(false)
        end
    end

    return true
end)