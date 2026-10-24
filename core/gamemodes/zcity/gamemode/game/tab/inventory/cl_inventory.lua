if IsValid(main_inventory) then main_inventory:Remove() end
if IsValid(lootbox_frame) then lootbox_frame:Remove() end

main_inventory = nil
lootbox_frame = nil

local blur = Material("pp/blurscreen")
local gradient_down = Material("gui/gradient_up")

local weapon_blacklist = {
    ["wep_jack_gmod_hands"] = true,
    ["weapon_physcannon"] = true,
    ["gmod_tool"] = true,
    ["weapon_physgun"] = true,
}

local color_white_for_hui = Color(255,255,255,5)

inventory_slot_memory = inventory_slot_memory or {}

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

    local modelWidth = 380
    local plyModel = vgui.Create("DModelPanel", main_inventory)
    plyModel:SetSize(modelWidth, ScrH() * 0.7)
    plyModel:SetPos(200, ScrH() * 0.1) 
    plyModel:SetModel(LocalPlayer():GetModel())

    local oldPaint = plyModel.Paint
    plyModel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(39, 39, 39, 150)) 
        
        oldPaint(self, w, h)
    end
    
    if IsValid(plyModel.Entity) then
        plyModel.Entity.GetPlayerColor = function()
            return LocalPlayer():GetPlayerColor()
        end

        plyModel.Entity:SetSkin(LocalPlayer():GetSkin() or 0)
        for _, bg in pairs(LocalPlayer():GetBodyGroups()) do
            plyModel.Entity:SetBodygroup(bg.id, LocalPlayer():GetBodygroup(bg.id))
        end
        
        local mn, mx = plyModel.Entity:GetRenderBounds()
        local size = math.max(math.abs(mn.x) + math.abs(mx.x), math.abs(mn.y) + math.abs(mx.y), math.abs(mn.z) + math.abs(mx.z))
        plyModel:SetFOV(38)
        plyModel:SetCamPos(Vector(size * 0.8, 0, size * 0.55)) 
        plyModel:SetLookAt(Vector(0, 0, (mn.z + mx.z) * 0.5))
    end


    plyModel.LayoutEntity = function() return false end


    plyModel.DrawModel = function(self)
        local alpha = main_inventory:GetAlpha() / 255
        -- ахамбля
        if alpha > 0.99 then 
            alpha = 1 
        end

        render.SetBlend(alpha)
        
        if IsValid(self.Entity) then
            self.Entity:DrawModel()
            
            if self.PostDrawModel then
                self:PostDrawModel(self.Entity)
            end
        end
        
        render.SetBlend(1)
    end

    plyModel.PostDrawModel = function(self, ent)
        if not IsValid(ent) then return end
        ent.EZarmor = LocalPlayer().EZarmor
        JMod.ArmorPlayerModelDraw(ent, true)
    end

    kb.PositionArmorSlots = {
        ["left_side"] = {
            [1] = {"head", "head"},
            [2] = {"chest", "chest"}
        },
        ["right_side"] = {
            [1] = {"eyes", "mouthnose"},
            [2] = {"pelvis", "back"}
        },
    }

    local function GenerateArmorSlots(parent_panel, model_panel)
        local slotSize = 75
        local spacing = 0
        
        local modelX, modelY = model_panel:GetPos()
        local modelW, modelH = model_panel:GetSize()
        
        for side, rows in pairs(kb.PositionArmorSlots) do
            for rowIndex, slots in pairs(rows) do
                for colIndex, slotName in ipairs(slots) do
                    local posX, posY
                    
                    posY = modelY + ((rowIndex - 1) * (slotSize + spacing))
                    
                    if side == "left_side" then
                        posX = modelX - (colIndex * (slotSize + spacing))
                    elseif side == "right_side" then
                        posX = modelX + modelW + ((colIndex - 1) * (slotSize + spacing))
                    end
                    
                    local slotPanel = vgui.Create("DPanel", parent_panel)
                    slotPanel:SetSize(slotSize, slotSize)
                    slotPanel:SetPos(posX, posY)
                    
                    slotPanel.Paint = function(s, w, h)
                        draw.RoundedBox(0, 0, 0, w, h, Color(39, 39, 39, 100))
                        surface.SetDrawColor(73, 73, 73)
                        surface.DrawLine(0, 0, w, 0)
                        surface.DrawLine(0, 0, 0, h)
                        surface.SetDrawColor(15, 15, 15, 150)
                        surface.DrawLine(0, h - 1, w, h - 1) 
                        surface.DrawLine(w - 1, 0, w - 1, h)
                    end

                    local btn = vgui.Create("DButton", slotPanel)
                    btn:SetSize(slotSize, slotSize)
                    btn:SetText("")

                    btn:Droppable("Armor_Item")

                    btn.OnStartDragging = function(self)
                        local ply = LocalPlayer()
                        if not ply.EZarmor then return false end
                        
                        local itemID = JMod.GetItemInSlot(ply.EZarmor, slotName)
                        if not itemID then return false end
                        
                        self.DragArmorID = itemID 
                        self.PendingDrop = false
                        self:SetPaintedManually(true)
                    end

                    btn.OnStopDragging = function(self)
                        self:SetPaintedManually(false)
                    end
                    
                    btn.Paint = function(s, w, h)
                        local ply = LocalPlayer()
                        
                        local printName = ""
                        local hasArmor = false

                        local rarityColor

                        local iconMat
                        
                        if ply.EZarmor then
                            local itemID, itemData, itemInfo = JMod.GetItemInSlot(ply.EZarmor, slotName)


                            if itemID and not s.PendingDrop then
                                hasArmor = true
                                printName = itemData.name
                                rarityColor = kb.GetItemRarityColor(itemInfo.ent)

                                if not s.ItemIcon or s.LastEnt ~= itemInfo.ent then
                                    s.ItemIcon = Material("entities/" .. itemInfo.ent .. ".png", "smooth")
                                    s.LastEnt = itemInfo.ent
                                end
                                iconMat = s.ItemIcon
                            end
                        end

                        if hasArmor then
                            surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                            surface.SetMaterial(gradient_down)
                            surface.DrawTexturedRect(0, 0, w, h)

                            if iconMat and not iconMat:IsError() then
                                surface.SetDrawColor(255, 255, 255, 255)
                                surface.SetMaterial(iconMat)
                                local iconSize = w * 0.7
                                surface.DrawTexturedRect((w - iconSize) / 2, (h - iconSize) / 2 - 5, iconSize, iconSize)
                            end

                            draw.SimpleText(printName, "DermaDefault", w / 2, h - 6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                        
                            surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, hasArmor and 200 or 50)
                            surface.DrawRect(0, h - 3, w, 3)
                        end
                        

                        if s:IsHovered() then
                            draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 2))
                        end
                    end
                    
                    btn.DoClick = function()
                    end
                end
            end
        end
    end

    GenerateArmorSlots(main_inventory, plyModel)

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

        local pending_claims = {}
        for _, slot in ipairs(self:GetChildren()) do -- получение-детей
            if slot.PendingClaim then
                table.insert(pending_claims, slot.PendingClaim)
            end
        end

        self:Clear()

        local weps = LocalPlayer():GetWeapons()
        local current_classes = {}
        
        for _, wep in ipairs(weps) do
            if IsValid(wep) and not weapon_blacklist[wep:GetClass()] then
                current_classes[wep:GetClass()] = wep
            end
        end

        for i = 1, 8 do
            local stored_class = inventory_slot_memory[i]
            if stored_class and not current_classes[stored_class] then
                inventory_slot_memory[i] = nil
            end
        end

        for class, wep in pairs(current_classes) do
            local is_stored = false
            for i = 1, 8 do
                if inventory_slot_memory[i] == class then
                    is_stored = true
                    break
                end
            end
            
            if not is_stored then
                for i = 1, 8 do
                    if not inventory_slot_memory[i] then
                        inventory_slot_memory[i] = class
                        break
                    end
                end
            end
        end

        local active_pending = {}
        local real_classes = {}
        
        for _, class in pairs(inventory_slot_memory) do
            real_classes[class] = true
        end

        for _, class in ipairs(pending_claims) do
            if not real_classes[class] then
                table.insert(active_pending, class)
            end
        end

        for i = 1, 8 do
            local slotPanel = vgui.Create("DPanel", self)
            slotPanel:SetSize(slotSize, slotSize)
            slotPanel:SetPos((i - 1) * (slotSize + spacing), 0)
            
            local wep_class = inventory_slot_memory[i]
            local wep = wep_class and current_classes[wep_class] or nil

            slotPanel.Think = function(s)
                if s.PendingClaim and LocalPlayer():HasWeapon(s.PendingClaim) then
                    s.PendingClaim = nil
                    if IsValid(self) then
                        self:Refresh()
                    end
                end
            end

            if not IsValid(wep) and #active_pending > 0 then
                slotPanel.PendingClaim = table.remove(active_pending, 1)
            end
            
            slotPanel.Paint = function(s, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(39, 39, 39))
                surface.SetDrawColor(73, 73, 73)
                surface.DrawLine(0, 0, w, 0)
                surface.DrawLine(0, 0, 0, h)
                surface.SetDrawColor(15, 15, 15, 255)
                surface.DrawLine(0, h - 1, w, h - 1) 
                surface.DrawLine(w - 1, 0, w - 1, h)

                if s:IsHovered() then
                    draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 2))
                end

                if s.PendingClaim then
                    local class = s.PendingClaim
                    local rarityColor = kb.GetItemRarityColor(class)
                    
                    surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                    surface.SetMaterial(gradient_down)
                    surface.DrawTexturedRect(0, 0, w, h)

                    local wepData = weapons.GetStored(class)
                    if wepData then
                        local sx, sy = s:LocalToScreen(0, -15)
                        KB_DrawWeaponSelection(wepData, sx, sy, w, h, 255)
                    end
                    
                    local printName = (wepData and wepData.PrintName) and wepData.PrintName or language.GetPhrase(class)
                    if printName == class then printName = class end
                    
                    draw.SimpleText(printName, "DermaDefault", w / 2, h - 6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                    
                    surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                    surface.DrawRect(0, h - 3, w, 3)
                end
            end

            slotPanel:Receiver("Weapon_Item", function(self_pnl, panels, isDropped, index_drop, x, y)
                if isDropped then
                    local draggedBtn = panels[1]
                    if not IsValid(draggedBtn) or not draggedBtn.WepClass or not draggedBtn.SlotIndex then return end

                    local fromIndex = draggedBtn.SlotIndex
                    local toIndex = i 

                    if fromIndex ~= toIndex then
                        local draggedClass = draggedBtn.WepClass
                        local targetClass = inventory_slot_memory[toIndex]

                        draggedBtn:SetVisible(false)

                        for _, child in ipairs(self_pnl:GetChildren()) do
                            if child:GetName() == "DButton" then
                                child:SetVisible(false)
                            end
                        end

                        inventory_slot_memory[toIndex] = inventory_slot_memory[fromIndex]
                        inventory_slot_memory[fromIndex] = targetClass
                        
                        self_pnl.PendingClaim = draggedClass
                        
                        local fromPanel = invPanel:GetChild(fromIndex - 1)
                        if IsValid(fromPanel) then
                            fromPanel.PendingClaim = targetClass
                        end
                        
                        timer.Simple(0, function()
                            if IsValid(invPanel) then invPanel:Refresh() end
                        end)
                    end
                end
            end)

            if IsValid(wep) then
                local btn = vgui.Create("DButton", slotPanel)
                btn:SetSize(slotSize, slotSize)
                btn:SetText("")

                btn.SlotIndex = i
                
                local class = wep:GetClass()
                local wepData = weapons.GetStored(class)
                
                local printName = (wepData and wepData.PrintName) and wepData.PrintName or (wep.GetPrintName and wep:GetPrintName()) or language.GetPhrase(class)
                
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
                        draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 2))
                    end
                end
                
                btn.DoClick = function() end
            end
        end
    end

    invPanel:Refresh()

    main_inventory:Receiver("Armor_Item", function(self, panels, isDropped, index, x, y)
        if isDropped then
            local pnl = panels[1]
            if not IsValid(pnl) or not pnl.DragArmorID then return end

            local mx, my = gui.MousePos()
            local px, py = plyModel:LocalToScreen(0, 0)
            local pw, ph = plyModel:GetSize()

            local safeX_min = px - 150
            local safeX_max = px + pw + 150
            local safeY_min = py
            local safeY_max = py + ph

            if mx < safeX_min or mx > safeX_max or my < safeY_min or my > safeY_max then
                
                pnl.PendingDrop = true -- вот это хитро
                
                net.Start("JMod_Inventory")
                net.WriteInt(JMod.NETWORK_INDEX.ARMOR_INVENTORY.DROP, 8) 
                net.WriteString(pnl.DragArmorID)
                net.SendToServer()
            end
        end
    end)

    main_inventory:Receiver("Weapon_Item", function(self, panels, isDropped, index, x, y)
        if isDropped then
            local pnl = panels[1]
            if not IsValid(pnl) then return end

            local mx, my = gui.MousePos()
            local ix, iy = invPanel:LocalToScreen(0, 0)
            local iw, ih = invPanel:GetSize()

            if mx < ix or mx > (ix + iw) or my < iy or my > (iy + ih) then

                if IsValid(lootbox_frame) and not lootbox_frame.isClosing then
                    local lx, ly = lootbox_frame:LocalToScreen(0, 0)
                    local lw, lh = lootbox_frame:GetSize()
                    if mx >= lx and mx <= (lx + lw) and my >= ly and my <= (ly + lh) then
                        return 
                    end
                end

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
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 220))
        draw.SimpleText("KIZNEY BOX", "KB.1", w / 2 , h / 2, color_white_for_hui, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

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

    local isUpdating = IsValid(lootbox_frame)

    if not isUpdating then
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

            if isUpdating then
                self.CurrentX = x
                self:RealSetPos(x, y)
            end
            
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

            if self:IsHovered() then
                draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 2))
            end

            if self.PendingPut then
                local rarityColor = kb.GetItemRarityColor(self.PendingPut)
                
                surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                surface.SetMaterial(gradient_down)
                surface.DrawTexturedRect(0, 0, w, h)

                local wep = weapons.GetStored(self.PendingPut)
                if wep then
                    local sx, sy = self:LocalToScreen(0, -15)
                    KB_DrawWeaponSelection(wep, sx, sy, w, h, 255)
                end
                
                local printName = (wep and wep.PrintName) and wep.PrintName or language.GetPhrase(self.PendingPut)
                if printName == self.PendingPut then printName = self.PendingPut end
                
                draw.SimpleText(printName, "DermaDefault", w / 2, h - 6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                
                surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                surface.DrawRect(0, h - 3, w, 3)
            end
        end

        local function SetupReceiver()
            slotPanel:Receiver("Weapon_Item", function(self, panels, isDropped, drop_index, x, y)
                if isDropped then
                    local pnl = panels[1]
                    if not IsValid(pnl) or not pnl.WepClass then return end

                    net.Start("KB_PutItem")
                        net.WriteEntity(box_ent)
                        net.WriteUInt(index, 8) 
                        net.WriteString(pnl.WepClass)
                    net.SendToServer()
                    
                    pnl:SetVisible(false)

                    self.PendingPut = pnl.WepClass
                end
            end)
        end

        if item.claimed then
            SetupReceiver()
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
                    draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 2))
                end
            end
            
            btn.DoClick = function()
                net.Start("KB_ClaimLoot")
                    net.WriteEntity(box_ent)
                    net.WriteUInt(index, 8) 
                net.SendToServer()

                if IsValid(main_inventory) and IsValid(main_inventory.invPanel) then
                    local dummy = vgui.Create("Panel", main_inventory.invPanel) -- я гений
                    dummy.PendingClaim = item.class
                    
                    main_inventory.invPanel:Refresh()
                end

                if not LocalPlayer():HasWeapon(item.class) then
                    btn:Remove()

                    item.claimed = true 
                    SetupReceiver()
                
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