if IsValid(main_inventory) then main_inventory:Remove() end
if IsValid(lootbox_frame) then lootbox_frame:Remove() end

main_inventory = nil
lootbox_frame = nil

local blur = Material("pp/blurscreen")
local gradient_down = Material("gui/gradient_up")

local weapon_blacklist = {
    ["wep_jack_gmod_hands"] = true,
    ["weapon_physcannon"] = true,
    ["gmod_tool"] = true
}

function Frame_Inventory()
    if IsValid(main_inventory) then return end

    main_inventory = vgui.Create("DPanel")
    main_inventory:SetSize(ScrW(), ScrH())
    main_inventory:SetPos(0, 0)
    main_inventory:MakePopup()
    main_inventory:SetKeyboardInputEnabled(false)
    
    main_inventory.uiAlpha = 0
    main_inventory:SetAlpha(0)
    main_inventory.isClosing = false

    local modelWidth = 400
    local plyModel = vgui.Create("DModelPanel", main_inventory)
    plyModel:SetSize(modelWidth, ScrH() * 0.9)
    plyModel:SetPos(50, ScrH() * 0.05) 
    plyModel:SetModel(LocalPlayer():GetModel())
    
    if IsValid(plyModel.Entity) then
        plyModel.Entity:SetSkin(LocalPlayer():GetSkin() or 0)
        for _, bg in pairs(LocalPlayer():GetBodyGroups()) do
            plyModel.Entity:SetBodygroup(bg.id, LocalPlayer():GetBodygroup(bg.id))
        end
        
        local mn, mx = plyModel.Entity:GetRenderBounds()
        local size = math.max(math.abs(mn.x) + math.abs(mx.x), math.abs(mn.y) + math.abs(mx.y), math.abs(mn.z) + math.abs(mx.z))
        plyModel:SetFOV(45)
        plyModel:SetCamPos(Vector(size * 0.8, 0, size * 0.55)) 
        plyModel:SetLookAt(Vector(0, 0, (mn.z + mx.z) * 0.5))
    end


    plyModel.LayoutEntity = function() return false end

    plyModel.DrawModel = function(self)
        local alpha = main_inventory:GetAlpha() / 255

        render.SetBlend(alpha)
        
        if IsValid(self.Entity) then
            self.Entity:DrawModel()
        end
        
        render.SetBlend(1)
    end

    local invPanel = vgui.Create("DPanel", main_inventory)
    main_inventory.invPanel = invPanel
    local slotSize = 75
    local spacing = 0
    local cols = 8
    
    local invW = cols * slotSize + (cols - 1) * spacing
    local invH = slotSize
    
    invPanel:SetSize(invW, invH)
    invPanel:SetPos((ScrW() - invW) / 2, ScrH() - invH)
    invPanel.Paint = function() end 

    invPanel.Refresh = function(self)
        self:Clear()

        local weps = LocalPlayer():GetWeapons()
        local valid_weps = {}
        
        for _, wep in ipairs(weps) do
            if IsValid(wep) and not weapon_blacklist[wep:GetClass()] then
                table.insert(valid_weps, wep)
            end
        end

        for i = 1, 8 do
            local slotPanel = vgui.Create("DPanel", self)
            slotPanel:SetSize(slotSize, slotSize)
            slotPanel:SetPos((i - 1) * (slotSize + spacing), 0)
            
            local wep = valid_weps[i]
            
            slotPanel.Paint = function(s, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(39, 39, 39))
                surface.SetDrawColor(73, 73, 73)
                surface.DrawLine(0, 0, w, 0)
                surface.DrawLine(0, 0, 0, h)
                surface.SetDrawColor(15, 15, 15, 255)
                surface.DrawLine(0, h - 1, w, h - 1) 
                surface.DrawLine(w - 1, 0, w - 1, h)
            end

            if IsValid(wep) then
                local btn = vgui.Create("DButton", slotPanel)
                btn:SetSize(slotSize, slotSize)
                btn:SetText("")
                
                local class = wep:GetClass()
                local printName = wep.PrintName or language.GetPhrase(class)
                if printName == class then printName = class end
                
                local rarityColor = kb.GetItemRarityColor(class)

                btn.WepClass = class
                btn:Droppable("Weapon_Item") 

                btn.OnStartDragging = function(self)
                    self:SetPaintedManually(true)
                end

                btn.OnStopDragging = function(self)
                    self:SetPaintedManually(false)
                end

                btn.Paint = function(s, w, h)
                    surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                    surface.SetMaterial(gradient_down)
                    surface.DrawTexturedRect(0, 0, w, h)

                    local sx, sy = s:LocalToScreen(0, -15)
                    if KB_DrawWeaponSelection then
                        KB_DrawWeaponSelection(wep, sx, sy, w, h, 255)
                    end
                    
                    draw.SimpleText(printName, "DermaDefault", w / 2, h - 6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                    
                    surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                    surface.DrawRect(0, h - 3, w, 3)

                    if s:IsHovered() then
                        draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 5))
                    end
                end
                
                btn.DoClick = function() end
            end
        end
    end

    invPanel:Refresh()

    main_inventory:Receiver("Weapon_Item", function(self, panels, isDropped, index, x, y)
        if isDropped then
            local pnl = panels[1]
            if not IsValid(pnl) then return end

            local mx, my = gui.MousePos()
            local ix, iy = invPanel:LocalToScreen(0, 0)
            local iw, ih = invPanel:GetSize()

            if mx < ix or mx > (ix + iw) or my < iy or my > (iy + ih) then
                net.Start("KB_DropWeapon_Action")
                net.WriteString(pnl.WepClass)
                net.SendToServer()
                
                pnl:SetVisible(false) 
                
                timer.Simple(0.1, function()
                    if IsValid(invPanel) then
                        invPanel:Refresh()
                    end
                end)
            end
        end
    end)

    main_inventory.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 180))
    end

    main_inventory.Think = function(self)
        local targetAlpha = self.isClosing and 0 or 255
        self.uiAlpha = Lerp(FrameTime() * 15, self.uiAlpha, targetAlpha)
        self:SetAlpha(self.uiAlpha)

        if self.isClosing and self.uiAlpha < 5 then
            self:Remove()
        end
    end

    main_inventory.OnKeyCodePressed = function(self, key)
        if key == KEY_W or key == KEY_A or key == KEY_S or key == KEY_D then
            if IsValid(lootbox_frame) then
                lootbox_frame:Close()
            end
        end
    end
end

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

    Frame_Inventory()

    if not IsValid(lootbox_frame) then 
        main_inventory:SetKeyboardInputEnabled(true)

        lootbox_frame = vgui.Create("DFrame", main_inventory)
        lootbox_frame:SetSize(frameW, frameH) 
        lootbox_frame:Center()
        lootbox_frame:SetTitle("") 
        lootbox_frame:ShowCloseButton(false)

        lootbox_frame.uiAlpha = 0
        lootbox_frame:SetAlpha(0)
        lootbox_frame.isClosing = false

        lootbox_frame.Close = function(self)
            if self.isClosing then return end
            self.isClosing = true
            LocalPlayer():EmitSound("kb/ui/close_box.wav")

            if IsValid(main_inventory) then
                main_inventory.isClosing = true
            end
        end

        lootbox_frame.Think = function(self)
            local targetAlpha = self.isClosing and 0 or 255
            self.uiAlpha = Lerp(FrameTime() * 10, self.uiAlpha, targetAlpha)
            self:SetAlpha(self.uiAlpha)

            if self.isClosing and self.uiAlpha < 5 then
                self:Remove()
            end
        end

        lootbox_frame.Paint = function(self, w, h)
            local title = IsValid(box_ent) and box_ent.PrintName or "Лутбокс"
            draw.SimpleText(title, "ChatFont", w / 2, paddingTop / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        lootbox_frame.Scroll = vgui.Create("DHorizontalScroller", lootbox_frame)
        lootbox_frame.Scroll:SetSize(contentWidth, btnSize)
        lootbox_frame.Scroll:SetPos((frameW - contentWidth) / 2, paddingTop) 
        lootbox_frame.Scroll:SetOverlap(-gap) 
    else
        lootbox_frame.isClosing = false
        for _, pnl in pairs(lootbox_frame.Scroll.Panels or {}) do
            if IsValid(pnl) then pnl:Remove() end
        end
        lootbox_frame:SetSize(frameW, frameH)
        lootbox_frame:Center()
        lootbox_frame.Scroll:SetSize(contentWidth, btnSize)
        lootbox_frame.Scroll:SetPos((frameW - contentWidth) / 2, paddingTop)
    end

    local remainingItems = 0
    for _, item in pairs(items) do
        if not item.claimed then
            remainingItems = remainingItems + 1
        end
    end

    for index, item in ipairs(items) do
        local slotPanel = vgui.Create("DPanel", lootbox_frame.Scroll)
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
            local target_x = (IsValid(lootbox_frame) and lootbox_frame.isClosing) and centerX or self.TargetX
            
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

                timer.Simple(0.1, function()
                    if IsValid(main_inventory) and IsValid(main_inventory.invPanel) then
                        main_inventory.invPanel:Refresh()
                    end
                end)

                if not LocalPlayer():HasWeapon(item.class) then
                    btn:Remove()
                
                    remainingItems = remainingItems - 1

                    if remainingItems <= 0 then
                        timer.Simple(0.1, function() 
                            if IsValid(lootbox_frame) then
                                lootbox_frame:Close()
                            end
                        end)
                    end
                end
            end
        end

        lootbox_frame.Scroll:AddPanel(slotPanel)
    end
end)