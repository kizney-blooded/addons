if IsValid(LootBoxBG) then LootBoxBG:Remove() end
if IsValid(LootBoxFrame) then LootBoxFrame:Remove() end

LootBoxBG = nil
LootBoxFrame = nil

local blur = Material("pp/blurscreen")
local gradient_down = Material("gui/gradient_up")

net.Receive("KB_OpenLootBox", function()
    local box_ent = net.ReadEntity()
    local items = net.ReadTable()

    local count = table.Count(items)
    
    local btnSize = 75
    local gap = 0
    local paddingTop = 40
    local paddingBottom = 10
    local paddingSide = 40
    
    local contentWidth = (btnSize * count) + (gap * (count - 1))
    local frameW = math.Clamp(contentWidth + paddingSide, 150, ScrW() - 40) 
    local frameH = paddingTop + btnSize + paddingBottom

    if not IsValid(LootBoxBG) then 
        LootBoxBG = vgui.Create("DPanel")
        LootBoxBG:SetSize(ScrW(), ScrH())
        LootBoxBG:SetPos(0, 0)
        LootBoxBG:MakePopup()
        
        LootBoxBG.uiAlpha = 0
        LootBoxBG:SetAlpha(0)
        LootBoxBG.isClosing = false

        LootBoxBG.Close = function(self)
            if self.isClosing then return end
            self.isClosing = true
            LocalPlayer():EmitSound("kb/ui/close_box.wav")
        end

        LootBoxBG.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 180))
        end

        LootBoxBG.Think = function(self)
            local targetAlpha = self.isClosing and 0 or 255
            self.uiAlpha = Lerp(FrameTime() * 10, self.uiAlpha, targetAlpha)
            self:SetAlpha(self.uiAlpha)

            if self.isClosing and self.uiAlpha < 5 then
                self:Remove()
            end
        end

        LootBoxBG.OnKeyCodePressed = function(self, key)
            if key == KEY_W or key == KEY_A or key == KEY_S or key == KEY_D then
                self:Close()
            end
        end

        LootBoxFrame = vgui.Create("DFrame", LootBoxBG)
        LootBoxFrame:SetSize(frameW, frameH) 
        LootBoxFrame:Center()
        LootBoxFrame:SetTitle("") 
        LootBoxFrame:ShowCloseButton(false)

        LootBoxFrame.Paint = function(self, w, h)
            local title = IsValid(box_ent) and box_ent.PrintName or "Лутбокс"
            draw.SimpleText(title, "ChatFont", w / 2, paddingTop / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        LootBoxFrame.Scroll = vgui.Create("DHorizontalScroller", LootBoxFrame)
        LootBoxFrame.Scroll:SetSize(contentWidth, btnSize)
        LootBoxFrame.Scroll:SetPos((frameW - contentWidth) / 2, paddingTop) 
        LootBoxFrame.Scroll:SetOverlap(-gap) 
    else
        LootBoxBG.isClosing = false
        for _, pnl in pairs(LootBoxFrame.Scroll.Panels or {}) do
            if IsValid(pnl) then pnl:Remove() end
        end
        LootBoxFrame:SetSize(frameW, frameH)
        LootBoxFrame:Center()
        LootBoxFrame.Scroll:SetSize(contentWidth, btnSize)
        LootBoxFrame.Scroll:SetPos((frameW - contentWidth) / 2, paddingTop)
    end

    local remainingItems = 0
    for _, item in pairs(items) do
        if not item.claimed then
            remainingItems = remainingItems + 1
        end
    end

    for index, item in ipairs(items) do
        local slotPanel = vgui.Create("DPanel", LootBoxFrame.Scroll)
        slotPanel:SetSize(btnSize, btnSize)

        slotPanel.RealSetPos = slotPanel.SetPos
        
        local centerX = (contentWidth / 2) - (btnSize / 2)
        slotPanel.CurrentX = centerX
        slotPanel:RealSetPos(centerX, 0)
        
        slotPanel.SetPos = function(self, x, y)
            self.TargetX = x
            self.TargetY = y
        end

        slotPanel.Think = function(self)
            local target_x = LootBoxBG.isClosing and centerX or self.TargetX
            
            if target_x and self.TargetY then
                self.CurrentX = Lerp(FrameTime() * 10, self.CurrentX, target_x)
                
                if math.abs(target_x - self.CurrentX) < 0.5 then
                    self.CurrentX = target_x
                end
                
                self:RealSetPos(self.CurrentX, self.TargetY)
            end
        end

        slotPanel.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(39, 39, 39))

            surface.SetDrawColor(73, 73, 73)
            surface.DrawLine(0, 0, w, 0)
            surface.DrawLine(0, 0, 0, h)

            surface.SetDrawColor(15, 15, 15, 255)
            surface.DrawLine(0, h - 1, w, h - 1) 
            surface.DrawLine(w - 1, 0, w - 1, h)
        end

        if not item.claimed then
            local btn = vgui.Create("DButton", slotPanel)
            btn:SetSize(btnSize, btnSize)

            local wep = weapons.GetStored(item.class)
            local printName = (wep and wep.PrintName) and wep.PrintName or language.GetPhrase(item.class)
            
            if printName == item.class then
                printName = item.class 
            end

            local rarityColor = kb.GetItemRarityColor(item.class)
            
            btn:SetText("")

            btn.Paint = function(self, w, h)
                surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                surface.SetMaterial(gradient_down)
                surface.DrawTexturedRect(0, 0, w, h)

                if wep then
                    local sx, sy = self:LocalToScreen(0, -15)
                    KB_DrawWeaponSelection(wep, sx, sy, w, h, 255)
                end
                
                draw.SimpleText(printName, "DermaDefault", w / 2, h - 6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                
                surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                surface.DrawRect(0, h - 3, w, 3)

                if self:IsHovered() then
                    draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 1))
                end
            end
            
            btn.DoClick = function()
                net.Start("KB_ClaimLoot")
                    net.WriteEntity(box_ent)
                    net.WriteUInt(index, 8) 
                net.SendToServer()

                if LocalPlayer():HasWeapon(item.class) then
                    --btn:SetEnabled(false)
                else
                    btn:Remove()
                
                    remainingItems = remainingItems - 1

                    if remainingItems <= 0 then
                        timer.Simple(0.1, function() 
                            if IsValid(LootBoxBG) then
                                LootBoxBG:Close()
                            end
                        end)
                    end
                end
            end
        end

        LootBoxFrame.Scroll:AddPanel(slotPanel)
    end
end)