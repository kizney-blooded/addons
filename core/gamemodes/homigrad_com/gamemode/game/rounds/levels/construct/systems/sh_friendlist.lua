if CLIENT then
    ClanMembers = ClanMembers or {}

    net.Receive("Clan_Message", function()
        local col = net.ReadColor()
        local msg = net.ReadString()
        chat.AddText(col, msg)
    end)

    net.Receive("Clan_Invite", function()
        local inviter = net.ReadString()
        local clanName = net.ReadString()
        chat.AddText(Color(0, 255, 0), "Вас приглашает " .. inviter .. " в клан " .. clanName .. ", напишите !clan accept чтобы присоединится к клану")
    end)

    ClanHUDPanel = ClanHUDPanel or nil

    function UpdateClanHUD()
        if IsValid(ClanHUDPanel) then
            ClanHUDPanel:Remove()
        end
        
        if not ClanMembers or #ClanMembers == 0 then return end
        
        ClanHUDPanel = vgui.Create("DPanel")
        
        surface.SetFont("ChatFont")
        local padding = 10
        local lineSpacing = 5
        local maxW = 0
        local totalH = padding * 2
        
        for i = 1, #ClanMembers do
            local tw, th = surface.GetTextSize(ClanMembers[i].nick)
            if tw > maxW then maxW = tw end
            totalH = totalH + th + lineSpacing
        end
        totalH = totalH - lineSpacing
        
        ClanHUDPanel:SetSize(maxW + (padding * 2), totalH)
        ClanHUDPanel:SetPos(20, ScrH() - 20 - totalH)
        
        ClanHUDPanel:SetPaintBackground(false)
        
        ClanHUDPanel.Paint = function(self, w, h)
            local currentY = padding
            for i = 1, #ClanMembers do
                local mem = ClanMembers[i]
                local p = player.GetBySteamID(mem.steamid)
                
                local col = Color(150, 150, 150)
                if IsValid(p) then
                    if p:Alive() then
                        col = Color(0, 255, 0)
                    else
                        col = Color(255, 0, 0)
                    end
                end
                
                draw.SimpleText(mem.nick, "ChatFont", padding, currentY, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                
                local _, th = surface.GetTextSize(mem.nick)
                currentY = currentY + th + lineSpacing
            end
        end
    end

    net.Receive("Clan_Sync", function()
        ClanMembers = net.ReadTable()
        UpdateClanHUD()
    end)

    net.Receive("Clan_ClearHUD", function()
        ClanMembers = {}
        if IsValid(ClanHUDPanel) then
            ClanHUDPanel:Remove()
        end
    end)

    timer.Simple(0.1, function()
        UpdateClanHUD()
    end)
end

hook.Add("HUDPaint", "DrawClanMembers", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    for _, target in player.Iterator() do
        if target ~= ply and target:Alive() then
            local inClan = false
            
            if ClanMembers then
                local targetSID = target:SteamID()
                for i = 1, #ClanMembers do
                    if ClanMembers[i].steamid == targetSID then
                        inClan = true
                        break
                    end
                end
            end

            if inClan then
                local pos = target:GetPos()
                local screenPos = (pos - Vector(0, 0, 5)):ToScreen()

                if screenPos.visible then
                    local dist = ply:GetPos():Distance(pos)

                    local fadeStart = 350
                    local fadeEnd = 650

                    local fraction = math.Clamp((dist - fadeStart) / (fadeEnd - fadeStart), 0, 1)
                    
                    local textAlpha = 255 * (1 - fraction)
                    local dotAlpha = 255 * fraction

                    if dotAlpha > 0 then
                        surface.SetDrawColor(0, 255, 0, dotAlpha)
                        surface.DrawRect(screenPos.x - 2, screenPos.y - 2, 4, 4)
                    end

                    if textAlpha > 0 then
                        draw.SimpleText(
                            target:Nick(), 
                            "ChatFont", 
                            screenPos.x, 
                            screenPos.y, 
                            Color(0, 255, 0, textAlpha), 
                            TEXT_ALIGN_CENTER, 
                            TEXT_ALIGN_TOP
                        )
                    end
                end
            end
        end
    end
end)