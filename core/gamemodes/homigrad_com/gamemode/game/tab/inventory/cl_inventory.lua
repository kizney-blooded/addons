-- господи помилуй мой инвентарь, это ужас, я уже запутался в нем сделал и больше не заходить


function draw.CircleProcessing(x, y, radius, progress, color)
    progress = math.Clamp(progress, 0, 1)
    
    if progress <= 0 then return end
    
    surface.SetDrawColor(color.r, color.g, color.b, color.a or 255)
    draw.NoTexture()
    
    local poly = {}
    
    table.insert(poly, { x = x, y = y })
    
    local segments = 64
    local startAngle = -90
    
    local currentAngle = startAngle + (360 * (1 - progress))
    local endAngle = startAngle + 360
    
    local step = 360 / segments
    
    for i = currentAngle, endAngle, step do
        local rad = math.rad(i)
        table.insert(poly, {
            x = x + math.cos(rad) * radius,
            y = y + math.sin(rad) * radius
        })
    end
    
    local radEnd = math.rad(endAngle)
    table.insert(poly, {
        x = x + math.cos(radEnd) * radius,
        y = y + math.sin(radEnd) * radius
    })
    
    surface.DrawPoly(poly)
end

if IsValid(main_inventory) then main_inventory:Remove() end
if IsValid(lootbox_frame) then lootbox_frame:Remove() end
if IsValid(playerinventory_frame) then playerinventory_frame:Remove() end

main_inventory = nil
lootbox_frame = nil
playerinventory_frame = nil

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

local custom_item_data = {
    ["ent_jack_gmod_ezammo"] = {icon = "ez_resource_icons/ammo.png", name = "Ящик патронов"},
}

local function GetItemPrintName(class, wepData)
    if custom_item_data[class] and custom_item_data[class].name then
        return custom_item_data[class].name
    end

    if string.StartWith(class, "ent_jack_gmod_ezarmor") then
        if JMod then
            local tbls = {JMod.ArmorTable, JMod.EFTArmorTable}
            for _, tbl in ipairs(tbls) do
                if tbl then
                    for k, v in pairs(tbl) do
                        if v.ent == class then 
                            return v.PrintName or v.name or k 
                        end
                    end
                end
            end
        end
    end
    
    local printName = (wepData and wepData.PrintName) and wepData.PrintName or (wepData and wepData.GetPrintName and wepData:GetPrintName()) or language.GetPhrase(class)
    if printName == class then printName = class end
    return printName
end

local function DrawItemIcon(panel, class, wepOrData, w, h)
    if custom_item_data[class] and custom_item_data[class].icon then
        local iconMat = Material(custom_item_data[class].icon, "smooth")
        if not iconMat:IsError() then
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(iconMat)
            local iconSize = w * 0.7
            surface.DrawTexturedRect((w - iconSize) / 2, (h - iconSize) / 2 - 5, iconSize, iconSize)
        end
    elseif string.StartWith(class, "kb_") and wepOrData and KB_DrawWeaponSelection then
        local sx, sy = panel:LocalToScreen(0, -15)
        KB_DrawWeaponSelection(wepOrData, sx, sy, w, h, 255)
    else
        local iconMat = Material("entities/" .. class .. ".png", "smooth")
        if not iconMat:IsError() then
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(iconMat)
            local iconSize = w * 0.7
            surface.DrawTexturedRect((w - iconSize) / 2, (h - iconSize) / 2 - 5, iconSize, iconSize)
        elseif wepOrData and KB_DrawWeaponSelection then
            local sx, sy = panel:LocalToScreen(0, -15)
            KB_DrawWeaponSelection(wepOrData, sx, sy, w, h, 255)
        end
    end
end

local function GetArmorSlotNames(class)
    local slots = {}
    if JMod then
        local tbls = {JMod.ArmorTable, JMod.EFTArmorTable}
        for _, tbl in ipairs(tbls) do
            if tbl then
                for k, v in pairs(tbl) do
                    if v.ent == class then 
                        if type(v.slots) == "table" then
                            for slotName, _ in pairs(v.slots) do
                                table.insert(slots, slotName)
                            end
                            return slots
                        elseif type(v.slots) == "string" then
                            return {v.slots}
                        end
                    end
                end
            end
        end
    end
    return slots
end

local function SyncInventorySlotsToServer()
    net.Start("KB_SyncInventorySlots")
    net.WriteTable(inventory_slot_memory)
    net.SendToServer()
end

net.Receive("KB_SyncInventorySlots", function()
    local new_memory = net.ReadTable()
    
    if IsValid(main_inventory) and IsValid(main_inventory.invPanel) then
        for slot_idx, class in pairs(new_memory) do
            if not weapon_blacklist[class] and not LocalPlayer():HasWeapon(class) then
                local dummy = vgui.Create("Panel", main_inventory.invPanel)
                dummy.PendingClaim = class
                dummy.TargetSlotIndex = slot_idx
            end
        end
    end
    
    inventory_slot_memory = new_memory
    
    if IsValid(main_inventory) and IsValid(main_inventory.invPanel) then
        main_inventory.invPanel:Refresh()
    end
end)

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
        if alpha > 0.99 then alpha = 1 end

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
            [1] = {"head", "eyes"},
            [2] = {"mouthnose", "leftshoulder"},
            [3] = {"leftforearm", "leftthigh"},
            [4] = {"leftcalf"},
        },
        ["right_side"] = {
            [1] = {"chest", "back"},
            [2] = {"waist", "pelvis"},
            [3] = {"rightshoulder", "rightforearm"},
            [4] = {"rightthigh","rightcalf"},
        },
    }

    local function GenerateArmorSlots(parent_panel, model_panel)
        local slotSize = 75
        local spacing = 0
        local modelX, modelY = model_panel:GetPos()
        local modelW, modelH = model_panel:GetSize()
        
        parent_panel.ArmorSlotPanels = parent_panel.ArmorSlotPanels or {}

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
                    
                    parent_panel.ArmorSlotPanels[slotName] = slotPanel

                    slotPanel.Paint = function(s, w, h)
                        draw.RoundedBox(0, 0, 0, w, h, Color(39, 39, 39, 100))
                        surface.SetDrawColor(73, 73, 73)
                        surface.DrawLine(0, 0, w, 0)
                        surface.DrawLine(0, 0, 0, h)
                        surface.SetDrawColor(15, 15, 15, 150)
                        surface.DrawLine(0, h - 1, w, h - 1) 
                        surface.DrawLine(w - 1, 0, w - 1, h)
                    end

                    slotPanel:Receiver("KB_Item", function(self_pnl, panels, isDropped, index, x, y)
                        if isDropped then
                            local pnl = panels[1]
                            if not IsValid(pnl) then return end

                            if pnl.DragArmorID and pnl.IsTargetArmor then
                                local _, put_snd = kb.GetSoundClaimOrPut(pnl.ArmorEntClass or "")
                                surface.PlaySound(put_snd)
                                pnl.PendingDrop = true
                                
                                local tSlots = GetArmorSlotNames(pnl.ArmorEntClass)
                                for _, sName in ipairs(tSlots) do
                                    if parent_panel.ArmorSlotPanels[sName] then
                                        parent_panel.ArmorSlotPanels[sName].PendingEquip = pnl.ArmorEntClass
                                    end
                                end
                                
                                net.Start("KB_TransferArmorToLocal")
                                net.WriteEntity(pnl.ArmorOwner_Container)
                                net.WriteString(pnl.DragArmorID)
                                net.SendToServer()
                                
                            elseif pnl.IsLootboxItem and pnl.WepClass and string.StartWith(pnl.WepClass, "ent_jack_gmod_ezarmor") then
                                local _, put_snd = kb.GetSoundClaimOrPut(pnl.WepClass)
                                surface.PlaySound(put_snd)
                                
                                pnl.PendingDrop = true
                                pnl:SetVisible(false) 
                                
                                local tSlots = GetArmorSlotNames(pnl.WepClass)
                                for _, sName in ipairs(tSlots) do
                                    if parent_panel.ArmorSlotPanels[sName] then
                                        parent_panel.ArmorSlotPanels[sName].PendingEquip = pnl.WepClass
                                    end
                                end
                                
                                net.Start("KB_ClaimLoot")
                                    net.WriteEntity(pnl.BoxEnt)
                                    net.WriteUInt(pnl.SlotIndex, 8)
                                net.SendToServer()
                                
                                local parent_frame = pnl.BoxEnt:GetClass() == "prop_ragdoll" and playerinventory_frame or lootbox_frame
                                if IsValid(parent_frame) then
                                    parent_frame.RemainingItems = (parent_frame.RemainingItems or 1) - 1
                                    if parent_frame.RemainingItems <= 0 and not pnl.BoxEnt.IsStorage then
                                        timer.Simple(0.1, function()
                                            if IsValid(parent_frame) then parent_frame:Close() end
                                        end)
                                    end
                                end
                            end
                        end
                    end)

                    local btn = vgui.Create("DButton", slotPanel)
                    btn:SetSize(slotSize, slotSize)
                    btn:SetText("")
                    btn:Droppable("KB_Item")

                    btn.OnStartDragging = function(self)
                        local ply = LocalPlayer()
                        if not ply.EZarmor then return false end
                        
                        local itemID, itemData, itemInfo = JMod.GetItemInSlot(ply.EZarmor, slotName)
                        if not itemID then return false end
                        
                        self.DragArmorID = itemID 
                        self.ArmorEntClass = itemInfo.ent
                        self.PendingDrop = false
                        self:SetPaintedManually(true)

                        local claim_snd = kb.GetSoundClaimOrPut(itemInfo.ent)
                        surface.PlaySound(claim_snd)
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
                            
                            if s.LastArmorID ~= itemID then
                                if itemID ~= nil then
                                    s.PendingDrop = false
                                end
                                s.LastArmorID = itemID
                            end

                            if itemID and not s.PendingDrop then
                                slotPanel.PendingEquip = nil 
                                hasArmor = true
                                printName = GetItemPrintName(itemInfo.ent)
                                rarityColor = kb.GetItemRarityColor(itemInfo.ent)

                                local customIconPath = custom_item_data[itemInfo.ent] and custom_item_data[itemInfo.ent].icon or ("entities/" .. itemInfo.ent .. ".png")
                                if not s.ItemIcon or s.LastEnt ~= itemInfo.ent then
                                    s.ItemIcon = Material(customIconPath, "smooth")
                                    s.LastEnt = itemInfo.ent
                                end
                                iconMat = s.ItemIcon
                            elseif slotPanel.PendingEquip then
                                hasArmor = true
                                printName = GetItemPrintName(slotPanel.PendingEquip)
                                rarityColor = kb.GetItemRarityColor(slotPanel.PendingEquip)
                                
                                local customIconPath = custom_item_data[slotPanel.PendingEquip] and custom_item_data[slotPanel.PendingEquip].icon or ("entities/" .. slotPanel.PendingEquip .. ".png")
                                if not s.ItemIcon or s.LastEnt ~= slotPanel.PendingEquip then
                                    s.ItemIcon = Material(customIconPath, "smooth")
                                    s.LastEnt = slotPanel.PendingEquip
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
                    
                    btn.DoClick = function() end
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

    invPanel.Think = function(self)
        local weps = LocalPlayer():GetWeapons()
        local count = 0
        for _, w in ipairs(weps) do
            if IsValid(w) and not weapon_blacklist[w:GetClass()] then
                count = count + 1
            end
        end
        
        if self.LastWepCount ~= count then
            self.LastWepCount = count
            self:Refresh()
        end
    end

    invPanel.Refresh = function(self)
        local pending_claims = {}
        local targeted_claims = {}

        for _, slot in ipairs(self:GetChildren()) do
            if slot.PendingClaim then
                if slot.TargetSlotIndex then
                    targeted_claims[slot.TargetSlotIndex] = slot.PendingClaim
                else
                    table.insert(pending_claims, slot.PendingClaim)
                end
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
            if stored_class and not current_classes[stored_class] and targeted_claims[i] ~= stored_class then
                inventory_slot_memory[i] = nil
            end
        end

        for slot_idx, class in pairs(targeted_claims) do
            inventory_slot_memory[slot_idx] = class
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
                    s.TargetSlotIndex = nil
                    if IsValid(self) then
                        self:Refresh()
                    end
                end
            end

            if targeted_claims[i] then
                slotPanel.PendingClaim = targeted_claims[i]
                slotPanel.TargetSlotIndex = i
            elseif not IsValid(wep) and #active_pending > 0 then
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
                    
                    DrawItemIcon(s, class, wepData, w, h)
                    
                    local printName = GetItemPrintName(class, wepData)
                    
                    draw.SimpleText(printName, "DermaDefault", w / 2, h - 6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                    
                    surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                    surface.DrawRect(0, h - 3, w, 3)
                end
            end

            slotPanel:Receiver("KB_Item", function(self_pnl, panels, isDropped, index_drop, x, y)
                if isDropped then
                    local draggedBtn = panels[1]

                    if IsValid(draggedBtn) and draggedBtn.DragArmorID then return end

                    if IsValid(draggedBtn) and draggedBtn.IsLootboxItem then
                        if not LocalPlayer():HasWeapon(draggedBtn.WepClass) then
                            draggedBtn.TargetSlotIndex = i
                        end
                        draggedBtn:DoClick()
                        return
                    end

                    if not IsValid(draggedBtn) or not draggedBtn.WepClass or not draggedBtn.SlotIndex then return end

                    local fromIndex = draggedBtn.SlotIndex
                    local toIndex = i 

                    if fromIndex ~= toIndex then
                        local draggedClass = draggedBtn.WepClass
                        local targetClass = inventory_slot_memory[toIndex]

                        local _, put_snd = kb.GetSoundClaimOrPut(draggedClass)
                        surface.PlaySound(put_snd)

                        draggedBtn:SetVisible(false)

                        for _, child in ipairs(self_pnl:GetChildren()) do
                            if child:GetName() == "DButton" then
                                child:SetVisible(false)
                            end
                        end

                        inventory_slot_memory[toIndex] = inventory_slot_memory[fromIndex]
                        inventory_slot_memory[fromIndex] = targetClass

                        SyncInventorySlotsToServer()
                        
                        self_pnl.PendingClaim = draggedClass
                        
                        local fromPanel = invPanel:GetChild(fromIndex - 1)
                        if IsValid(fromPanel) then
                            fromPanel.PendingClaim = targetClass
                        end
                        
                        timer.Simple(0, function()
                            if IsValid(invPanel) then invPanel:Refresh() end
                        end)
                    else
                        local _, put_snd = kb.GetSoundClaimOrPut(draggedBtn.WepClass)
                        surface.PlaySound(put_snd)
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
                local printName = GetItemPrintName(class, wepData)
                local rarityColor = kb.GetItemRarityColor(class)

                btn.WepClass = class
                btn:Droppable("KB_Item") 

                btn.OnStartDragging = function(self)
                    self:SetPaintedManually(true)
                    local claim_snd = kb.GetSoundClaimOrPut(self.WepClass)
                    surface.PlaySound(claim_snd)
                end

                btn.OnStopDragging = function(self)
                    self:SetPaintedManually(false)
                end

                btn.Paint = function(s, w, h)
                    surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                    surface.SetMaterial(gradient_down)
                    surface.DrawTexturedRect(0, 0, w, h)

                    DrawItemIcon(s, class, wep, w, h)
                    
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

        SyncInventorySlotsToServer()
    end

    invPanel:Refresh()

    main_inventory:Receiver("KB_Item", function(self, panels, isDropped, index, x, y)
        if isDropped then
            local pnl = panels[1]
            if not IsValid(pnl) then return end

            if pnl.DragArmorID then
                local mx, my = gui.MousePos()
                local px, py = plyModel:LocalToScreen(0, 0)
                local pw, ph = plyModel:GetSize()

                local in_local_safe = (mx >= px - 150 and mx <= px + pw + 150 and my >= py and my <= py + ph)
                
                local in_target_safe = false
                if IsValid(playerinventory_frame) and IsValid(playerinventory_frame.TargetModelContainer) then
                    local tx, ty = playerinventory_frame.TargetModelContainer:LocalToScreen(0, 0)
                    local tw, th = playerinventory_frame.TargetModelContainer:GetSize()
                    if mx >= tx - 150 and mx <= tx + tw + 150 and my >= ty and my <= ty + th then
                        in_target_safe = true
                    end
                end

                if not in_local_safe and not in_target_safe then
                    local _, put_snd = kb.GetSoundClaimOrPut(pnl.ArmorEntClass or "")
                    surface.PlaySound(put_snd)
                    pnl.PendingDrop = true
                    
                    if pnl.IsTargetArmor then
                        net.Start("KB_DropTargetArmor")
                        net.WriteEntity(pnl.ArmorOwner_Container)
                        net.WriteString(pnl.DragArmorID)
                        net.SendToServer()
                    else
                        net.Start("JMod_Inventory")
                        net.WriteInt(JMod.NETWORK_INDEX.ARMOR_INVENTORY.DROP, 8) 
                        net.WriteString(pnl.DragArmorID)
                        net.SendToServer()
                    end
                end
            elseif pnl.WepClass then
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

                    if IsValid(playerinventory_frame) and not playerinventory_frame.isClosing then
                        local px, py = playerinventory_frame:LocalToScreen(0, 0)
                        local pw, ph = playerinventory_frame:GetSize()
                        if mx >= px and mx <= (px + pw) and my >= py and my <= (py + ph) then
                            return 
                        end
                    end
                    
                    local _, put_snd = kb.GetSoundClaimOrPut(pnl.WepClass)
                    surface.PlaySound(put_snd)

                    if pnl.IsLootboxItem then
                        net.Start("KB_DropLootboxItem")
                            net.WriteEntity(pnl.BoxEnt)
                            net.WriteUInt(pnl.SlotIndex, 8)
                        net.SendToServer()
                        
                        pnl:Remove()
                        
                        if IsValid(lootbox_frame) then
                            lootbox_frame.RemainingItems = (lootbox_frame.RemainingItems or 1) - 1
                            if lootbox_frame.RemainingItems <= 0 and not pnl.BoxEnt.IsStorage then
                                timer.Simple(0.1, function() 
                                    if IsValid(lootbox_frame) then
                                        lootbox_frame:Close()
                                    end
                                end)
                            end
                        end

                        if IsValid(playerinventory_frame) then
                            playerinventory_frame.RemainingItems = (playerinventory_frame.RemainingItems or 1) - 1
                            if playerinventory_frame.RemainingItems <= 0 then
                                timer.Simple(0.1, function() 
                                    if IsValid(playerinventory_frame) then playerinventory_frame:Close() end
                                end)
                            end
                        end
                    else
                        net.Start("KB_DropWeapon_Action")
                        net.WriteString(pnl.WepClass)
                        net.SendToServer()
                         
                        pnl:SetVisible(false) 
                        
                        timer.Simple(0.1, function()
                            if IsValid(invPanel) then invPanel:Refresh() end
                        end)
                    end
                end
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

        if not self.isClosing and not LocalPlayer():Alive() then
            if IsValid(lootbox_frame) then lootbox_frame:Close() end
            if IsValid(playerinventory_frame) then playerinventory_frame:Close() end
            self.isClosing = true
        end

        if self.isClosing and self.uiAlpha < 5 then
            self:Remove()
        end
    end

    main_inventory.OnKeyCodePressed = function(self, key)
        if key == KEY_W or key == KEY_A or key == KEY_S or key == KEY_D then
            if IsValid(lootbox_frame) then
                lootbox_frame:Close()
            end
            if IsValid(playerinventory_frame) then
                playerinventory_frame:Close()
            end
        end
    end
end

net.Receive("KB_OpenLootBox", function()
    local box_ent = net.ReadEntity()
    local items = net.ReadTable()
    local is_update = net.ReadBool()

    if is_update and (not IsValid(lootbox_frame) or lootbox_frame.isClosing) then 
        return 
    end

    local max_idx = 0
    
    for k, v in pairs(items) do
        if type(k) == "number" and k > max_idx then
            max_idx = k
        end
    end
    
    local visual_slots = {}
    for i = 1, max_idx do
        visual_slots[i] = {
            server_index = i,
            item = items[i]
        }
    end
    
    local count = #visual_slots
    
    local btnSize = 75
    local gap = 0
    local paddingTop = 40
    local paddingBottom = 10
    local paddingSide = 40
    
    local maxCols = 8
    local cols = math.min(count, maxCols)
    local rows = math.ceil(count / maxCols)
    if rows == 0 then rows = 1 end
    
    local contentWidth = (btnSize * cols) + (gap * (cols - 1))
    local contentHeight = (btnSize * rows) + (gap * (rows - 1))
    
    local frameW = math.Clamp(contentWidth + paddingSide, 150, ScrW() - 40) 
    local frameH = math.Clamp(paddingTop + contentHeight + paddingBottom, 150, ScrH() - 40)

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

            if not self.isClosing then
                if not LocalPlayer():Alive() or not IsValid(box_ent) or LocalPlayer():GetPos():DistToSqr(box_ent:GetPos()) > 10000 then
                    self:Close()
                end
            end

            if self.isClosing and self.uiAlpha < 5 then
                self:Remove()
            end
        end

        lootbox_frame.Paint = function(self, w, h)
            local title = IsValid(box_ent) and box_ent.PrintName or "Лутбокс"
            draw.SimpleText(title, "ChatFont", w / 2, paddingTop / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        lootbox_frame.Scroll = vgui.Create("DScrollPanel", lootbox_frame)
        lootbox_frame.Scroll:SetSize(contentWidth, math.min(contentHeight, frameH - paddingTop - paddingBottom))
        lootbox_frame.Scroll:SetPos((frameW - contentWidth) / 2, paddingTop) 
    else
        lootbox_frame.isClosing = false
        lootbox_frame.Scroll:Clear()
        
        lootbox_frame:SetSize(frameW, frameH)
        lootbox_frame:Center()
        lootbox_frame.Scroll:SetSize(contentWidth, math.min(contentHeight, frameH - paddingTop - paddingBottom))
        lootbox_frame.Scroll:SetPos((frameW - contentWidth) / 2, paddingTop)
    end

    local remainingItems = 0
    for _, item in pairs(items) do
        if type(item) == "table" and not item.claimed then
            remainingItems = remainingItems + 1
        end
    end
    lootbox_frame.RemainingItems = remainingItems

    for index, slot_data in ipairs(visual_slots) do
        local server_index = slot_data.server_index
        local item = slot_data.item
        
        local slotPanel = vgui.Create("DPanel", lootbox_frame.Scroll)
        slotPanel:SetSize(btnSize, btnSize)
        slotPanel.SlotIndex = server_index

        slotPanel.RealSetPos = slotPanel.SetPos
        
        local centerX = (contentWidth / 2) - (btnSize / 2)
        local centerY = (contentHeight / 2) - (btnSize / 2)
        
        slotPanel.CurrentX = centerX
        slotPanel.CurrentY = centerY
        slotPanel:RealSetPos(centerX, centerY)
        
        slotPanel.SetPos = function(self, x, y)
            self.TargetX = x
            self.TargetY = y

            if isUpdating then
                self.CurrentX = x
                self.CurrentY = y
                self:RealSetPos(x, y)
            end
        end

        slotPanel.Think = function(self)
            local target_x = (IsValid(lootbox_frame) and lootbox_frame.isClosing) and centerX or self.TargetX
            local target_y = (IsValid(lootbox_frame) and lootbox_frame.isClosing) and centerY or self.TargetY
            
            if target_x and target_y then
                self.CurrentX = Lerp(FrameTime() * 10, self.CurrentX, target_x)
                self.CurrentY = Lerp(FrameTime() * 10, self.CurrentY, target_y)
                
                if math.abs(target_x - self.CurrentX) < 0.5 then
                    self.CurrentX = target_x
                end
                if math.abs(target_y - self.CurrentY) < 0.5 then
                    self.CurrentY = target_y
                end
                
                self:RealSetPos(self.CurrentX, self.CurrentY)
            end
        end

        local col = (index - 1) % maxCols
        local row = math.floor((index - 1) / maxCols)
        local tgtX = col * (btnSize + gap)
        local tgtY = row * (btnSize + gap)
        
        slotPanel:SetPos(tgtX, tgtY)

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
                
                DrawItemIcon(self, self.PendingPut, wep, w, h)
                
                local printName = GetItemPrintName(self.PendingPut, wep)
                
                draw.SimpleText(printName, "DermaDefault", w / 2, h - 6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                
                surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                surface.DrawRect(0, h - 3, w, 3)
            end
        end

        local function SetupReceiver()
            slotPanel:Receiver("KB_Item", function(self_pnl, panels, isDropped, drop_index, x, y)
                if isDropped then
                    local pnl = panels[1]
                    if not IsValid(pnl) then return end

                    if pnl.IsLootboxItem then
                        local old_parent = pnl:GetParent()
                        if old_parent == self_pnl then return end

                        if pnl.BoxEnt != box_ent then return end

                        local existing_btn = nil
                        for _, child in ipairs(self_pnl:GetChildren()) do
                            if child:GetName() == "DButton" and child ~= pnl then
                                existing_btn = child
                                break
                            end
                        end

                        net.Start("KB_SwapLootboxItem")
                            net.WriteEntity(box_ent)
                            net.WriteUInt(pnl.SlotIndex, 8)
                            net.WriteUInt(self_pnl.SlotIndex, 8)
                        net.SendToServer()
                        
                        local _, put_snd = kb.GetSoundClaimOrPut(pnl.WepClass)
                        surface.PlaySound(put_snd)

                        local temp_index = pnl.SlotIndex
                        pnl.SlotIndex = self_pnl.SlotIndex

                        if existing_btn then
                            existing_btn.SlotIndex = temp_index
                            existing_btn:SetParent(old_parent)
                            existing_btn:SetPos(0, 0)
                        end
                        
                        pnl:SetParent(self_pnl)
                        pnl:SetPos(0, 0)
                        return
                    end

                    if pnl.DragArmorID then
                        local is_empty = true
                        for _, child in ipairs(self_pnl:GetChildren()) do
                            if child:GetName() == "DButton" and child:IsVisible() then
                                is_empty = false
                                break
                            end
                        end

                        if not is_empty or self_pnl.PendingPut then return end

                        net.Start("KB_PutArmorItem")
                            net.WriteEntity(box_ent)
                            net.WriteUInt(self_pnl.SlotIndex, 8) 
                            net.WriteString(pnl.DragArmorID)
                            net.WriteBool(pnl.IsTargetArmor or false)
                            if pnl.IsTargetArmor then
                                net.WriteEntity(pnl.ArmorOwner_Container)
                            end
                        net.SendToServer()
                        
                        local _, put_snd = kb.GetSoundClaimOrPut(pnl.ArmorEntClass)
                        surface.PlaySound(put_snd)
                        
                        pnl.PendingDrop = true
                        self_pnl.PendingPut = pnl.ArmorEntClass
                        
                        timer.Simple(0.5, function()
                            if IsValid(self_pnl) and self_pnl.PendingPut == pnl.ArmorEntClass then
                                self_pnl.PendingPut = nil
                            end
                            if IsValid(pnl) then
                                pnl.PendingDrop = false
                            end
                        end)
                        return
                    end

                    if pnl.WepClass then
                        local is_empty = true
                        for _, child in ipairs(self_pnl:GetChildren()) do
                            if child:GetName() == "DButton" and child:IsVisible() then
                                is_empty = false
                                break
                            end
                        end

                        if not is_empty or self_pnl.PendingPut then return end

                        net.Start("KB_PutItem")
                            net.WriteEntity(box_ent)
                            net.WriteUInt(self_pnl.SlotIndex, 8) 
                            net.WriteString(pnl.WepClass)
                        net.SendToServer()
                        
                        local _, put_snd = kb.GetSoundClaimOrPut(pnl.WepClass)
                        surface.PlaySound(put_snd)
                        
                        pnl:SetVisible(false)
                        self_pnl.PendingPut = pnl.WepClass
                        
                        timer.Simple(0.5, function()
                            if IsValid(self_pnl) and self_pnl.PendingPut == pnl.WepClass then
                                self_pnl.PendingPut = nil
                            end
                            if IsValid(pnl) then
                                pnl:SetVisible(true)
                            end
                        end)
                    end
                end
            end)
        end

        SetupReceiver()

        if item and not item.claimed then
            local btn = vgui.Create("DButton", slotPanel)
            btn:SetSize(btnSize, btnSize)
            btn.SlotIndex = server_index
            btn.BoxEnt = box_ent

            local wep = weapons.GetStored(item.class)
            local printName = GetItemPrintName(item.class, wep)

            local rarityColor = kb.GetItemRarityColor(item.class)
            
            btn:SetText("")

            btn.WepClass = item.class
            btn.IsLootboxItem = true
            btn:Droppable("KB_Item")

            btn.OnStartDragging = function(self)
                self:SetPaintedManually(true)
                local claim_snd = kb.GetSoundClaimOrPut(self.WepClass)
                surface.PlaySound(claim_snd)
            end

            btn.OnStopDragging = function(self)
                self:SetPaintedManually(false)
            end

            btn.Paint = function(self, w, h)
                surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                surface.SetMaterial(gradient_down)
                surface.DrawTexturedRect(0, 0, w, h)

                DrawItemIcon(self, self.WepClass, wep, w, h)
                
                draw.SimpleText(printName, "DermaDefault", w / 2, h - 6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                
                surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                surface.DrawRect(0, h - 3, w, 3)

                if self:IsHovered() then
                    draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 2))
                end
            end
            
            btn.DoClick = function()
                local claim_snd = kb.GetSoundClaimOrPut(btn.WepClass)
                surface.PlaySound(claim_snd)

                net.Start("KB_ClaimLoot")
                    net.WriteEntity(box_ent)
                    net.WriteUInt(btn.SlotIndex, 8) 
                net.SendToServer()

                if not string.StartWith(item.class, "ent_jack_gmod_ezarmor") and not LocalPlayer():HasWeapon(item.class) then
                    if IsValid(main_inventory) and IsValid(main_inventory.invPanel) then
                        local dummy = vgui.Create("Panel", main_inventory.invPanel) 
                        dummy.PendingClaim = item.class
                        
                        if btn.TargetSlotIndex then
                            dummy.TargetSlotIndex = btn.TargetSlotIndex
                        end
                        
                        main_inventory.invPanel:Refresh()
                    end
                end

                if string.StartWith(item.class, "ent_jack_gmod_ezarmor") or not LocalPlayer():HasWeapon(item.class) then
                    btn:Remove()
                    
                    lootbox_frame.RemainingItems = lootbox_frame.RemainingItems - 1
                    if lootbox_frame.RemainingItems <= 0 then
                        timer.Simple(0.1, function() 
                            if IsValid(lootbox_frame) and not box_ent.IsStorage then
                                lootbox_frame:Close()
                            end
                        end)
                    end
                end
            end
        end
    end
end)

net.Receive("KB_OpenPlayerInventory", function()
    local player_ent = net.ReadEntity()
    local items = net.ReadTable()
    local is_update = net.ReadBool()
    local ez_armor = net.ReadTable()

    if IsValid(player_ent) then
        player_ent.EZarmor = ez_armor
    end

    if is_update and (not IsValid(playerinventory_frame) or playerinventory_frame.isClosing) then 
        return 
    end
    
    local visual_slots = {}
    for i = 1, 8 do
        visual_slots[i] = {
            server_index = i,
            item = items[i]
        }
    end
    
    local count = 8
    
    local btnSize = 75
    local gap = 0
    local paddingTop = 40
    local paddingBottom = 10
    local paddingSide = 40
    
    local maxCols = 8
    local cols = math.min(count, maxCols)
    local rows = math.ceil(count / maxCols)
    if rows == 0 then rows = 1 end
    
    local contentWidth = (btnSize * cols) + (gap * (cols - 1))
    local contentHeight = (btnSize * rows) + (gap * (rows - 1))
    
    local frameW = math.Clamp(contentWidth + paddingSide, 150, ScrW() - 40) 
    local frameH = math.Clamp(paddingTop + contentHeight + paddingBottom, 150, ScrH() - 40)

    Frame_Inventory()

    local isUpdating = IsValid(playerinventory_frame)

    if not isUpdating then
        main_inventory:SetKeyboardInputEnabled(true)

        playerinventory_frame = vgui.Create("DFrame", main_inventory)
        playerinventory_frame:SetSize(frameW, frameH) 
        playerinventory_frame:Center()
        playerinventory_frame:SetTitle("") 
        playerinventory_frame:ShowCloseButton(false)

        playerinventory_frame.uiAlpha = 0
        playerinventory_frame:SetAlpha(0)
        playerinventory_frame.isClosing = false

        playerinventory_frame.Close = function(self)
            if self.isClosing then return end
            self.isClosing = true
            LocalPlayer():EmitSound("kb/ui/close_box.wav")

            if IsValid(main_inventory) then
                main_inventory.isClosing = true
            end
        end

        playerinventory_frame.Think = function(self)
            local targetAlpha = self.isClosing and 0 or 255
            self.uiAlpha = Lerp(FrameTime() * 10, self.uiAlpha, targetAlpha)
            self:SetAlpha(self.uiAlpha)

            if not self.isClosing then
                if not LocalPlayer():Alive() or not IsValid(player_ent) or LocalPlayer():GetPos():DistToSqr(player_ent:GetPos()) > 10000 then
                    self:Close()
                end
            end

            if self.isClosing and self.uiAlpha < 5 then
                self:Remove()
            end
        end

        playerinventory_frame.Paint = function(self, w, h)
            local ownerName = IsValid(player_ent) and player_ent:GetNWString("FakePlayerName", "") or ""
            local title = (ownerName != "") and (ownerName .. "'s Инвентарь") or "Инвентарь игрока"
            draw.SimpleText(title, "ChatFont", w / 2, paddingTop / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        playerinventory_frame.Scroll = vgui.Create("DScrollPanel", playerinventory_frame)
        playerinventory_frame.Scroll:SetSize(contentWidth, math.min(contentHeight, frameH - paddingTop - paddingBottom))
        playerinventory_frame.Scroll:SetPos((frameW - contentWidth) / 2, paddingTop) 

        local modelWidth = 380
        local slotSpace = 160

        local targetContainer = vgui.Create("DPanel", main_inventory)
        playerinventory_frame.TargetModelContainer = targetContainer 
        targetContainer:SetSize(modelWidth + (slotSpace * 2), ScrH() * 0.7)

        targetContainer:SetPos(ScrW() - 200 - (modelWidth + slotSpace), ScrH() * 0.1)
        targetContainer.Paint = function() end
        targetContainer.Think = function(self)
            if IsValid(playerinventory_frame) then
                self:SetAlpha(playerinventory_frame.uiAlpha)
            else
                self:Remove()
            end
        end

        local targetPlyModel = vgui.Create("DModelPanel", targetContainer)
        targetPlyModel:SetSize(modelWidth, ScrH() * 0.7)
        targetPlyModel:SetPos(slotSpace, 0) 
        targetPlyModel:SetModel(IsValid(player_ent) and player_ent:GetModel() or "models/player/kleiner.mdl")

        local oldPaint = targetPlyModel.Paint
        targetPlyModel.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(39, 39, 39, 150)) 
            oldPaint(self, w, h)
        end
        
        if IsValid(targetPlyModel.Entity) and IsValid(player_ent) then
            targetPlyModel.Entity.GetPlayerColor = function()
                return IsValid(player_ent) and player_ent:GetPlayerColor()
            end
            targetPlyModel.Entity:SetSkin(player_ent:GetSkin() or 0)
            for _, bg in pairs(player_ent:GetBodyGroups()) do
                targetPlyModel.Entity:SetBodygroup(bg.id, player_ent:GetBodygroup(bg.id))
            end
            
            local mn, mx = targetPlyModel.Entity:GetRenderBounds()
            local size = math.max(math.abs(mn.x) + math.abs(mx.x), math.abs(mn.y) + math.abs(mx.y), math.abs(mn.z) + math.abs(mx.z))
            targetPlyModel:SetFOV(38)
            targetPlyModel:SetCamPos(Vector(size * 0.8, 0, size * 0.55)) 
            targetPlyModel:SetLookAt(Vector(0, 0, (mn.z + mx.z) * 0.5))
        end

        targetPlyModel.LayoutEntity = function() return false end

        targetPlyModel.DrawModel = function(self)
            local alpha = (IsValid(playerinventory_frame) and playerinventory_frame:GetAlpha() / 255) or 0
            if alpha > 0.99 then alpha = 1 end

            render.SetBlend(alpha)
            if IsValid(self.Entity) then
                self.Entity:DrawModel()
                if self.PostDrawModel then self:PostDrawModel(self.Entity) end
            end
            render.SetBlend(1)
        end

        targetPlyModel.PostDrawModel = function(self, ent)
            if not IsValid(ent) or not IsValid(player_ent) then return end
            ent.EZarmor = player_ent.EZarmor
            JMod.ArmorPlayerModelDraw(ent, true)
        end

        local function GenerateTargetArmorSlots(parent_panel, model_panel, target_ply)
            local slotSize = 75
            local spacing = 0
            local modelX, modelY = model_panel:GetPos()
            local modelW, modelH = model_panel:GetSize()
            
            parent_panel.ArmorSlotPanels = parent_panel.ArmorSlotPanels or {}

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
                        
                        parent_panel.ArmorSlotPanels[slotName] = slotPanel

                        slotPanel.Paint = function(s, w, h)
                            draw.RoundedBox(0, 0, 0, w, h, Color(39, 39, 39, 100))
                            surface.SetDrawColor(73, 73, 73)
                            surface.DrawLine(0, 0, w, 0)
                            surface.DrawLine(0, 0, 0, h)
                            surface.SetDrawColor(15, 15, 15, 150)
                            surface.DrawLine(0, h - 1, w, h - 1) 
                            surface.DrawLine(w - 1, 0, w - 1, h)
                        end

                        slotPanel:Receiver("KB_Item", function(self_pnl, panels, isDropped, index, x, y)
                            if isDropped then
                                local pnl = panels[1]
                                if not IsValid(pnl) then return end
                                
                                if pnl.DragArmorID and not pnl.IsTargetArmor then
                                    local _, put_snd = kb.GetSoundClaimOrPut(pnl.ArmorEntClass or "")
                                    surface.PlaySound(put_snd)
                                    pnl.PendingDrop = true
                                    
                                    local tSlots = GetArmorSlotNames(pnl.ArmorEntClass)
                                    for _, sName in ipairs(tSlots) do
                                        if parent_panel.ArmorSlotPanels[sName] then
                                            parent_panel.ArmorSlotPanels[sName].PendingEquip = pnl.ArmorEntClass
                                        end
                                    end
                                    
                                    net.Start("KB_TransferArmorToTarget")
                                    net.WriteEntity(target_ply) 
                                    net.WriteString(pnl.DragArmorID)
                                    net.SendToServer()
                                    
                                elseif pnl.IsLootboxItem and pnl.WepClass and string.StartWith(pnl.WepClass, "ent_jack_gmod_ezarmor") then
                                    local _, put_snd = kb.GetSoundClaimOrPut(pnl.WepClass)
                                    surface.PlaySound(put_snd)
                                    
                                    pnl.PendingDrop = true
                                    pnl:SetVisible(false) 
                                    
                                    local tSlots = GetArmorSlotNames(pnl.WepClass)
                                    for _, sName in ipairs(tSlots) do
                                        if parent_panel.ArmorSlotPanels[sName] then
                                            parent_panel.ArmorSlotPanels[sName].PendingEquip = pnl.WepClass
                                        end
                                    end
                                    
                                    net.Start("KB_ClaimLoot")
                                        net.WriteEntity(pnl.BoxEnt)
                                        net.WriteUInt(pnl.SlotIndex, 8)
                                    net.SendToServer()
                                    
                                    local parent_frame = pnl.BoxEnt:GetClass() == "prop_ragdoll" and playerinventory_frame or lootbox_frame
                                    if IsValid(parent_frame) then
                                        parent_frame.RemainingItems = (parent_frame.RemainingItems or 1) - 1
                                        if parent_frame.RemainingItems <= 0 and not pnl.BoxEnt.IsStorage then
                                            timer.Simple(0.1, function()
                                                if IsValid(parent_frame) then parent_frame:Close() end
                                            end)
                                        end
                                    end
                                end
                            end
                        end)

                        local btn = vgui.Create("DButton", slotPanel)
                        btn:SetSize(slotSize, slotSize)
                        btn:SetText("")
                        
                        btn.IsTargetArmor = true
                        btn.ArmorOwner_Container = target_ply 
                        btn:Droppable("KB_Item")

                        btn.OnStartDragging = function(self)
                            if not IsValid(target_ply) or not target_ply.EZarmor then return false end
                            
                            local itemID, itemData, itemInfo = JMod.GetItemInSlot(target_ply.EZarmor, slotName)
                            if not itemID then return false end
                            
                            self.DragArmorID = itemID 
                            self.ArmorEntClass = itemInfo.ent
                            self.PendingDrop = false
                            self:SetPaintedManually(true)

                            local claim_snd = kb.GetSoundClaimOrPut(itemInfo.ent)
                            surface.PlaySound(claim_snd)
                        end

                        btn.OnStopDragging = function(self)
                            self:SetPaintedManually(false)
                        end

                        btn.Paint = function(s, w, h)
                            local printName = ""
                            local hasArmor = false
                            local rarityColor
                            local iconMat
                            
                            if IsValid(target_ply) and target_ply.EZarmor then
                                local itemID, itemData, itemInfo = JMod.GetItemInSlot(target_ply.EZarmor, slotName)
                                
                                if s.LastArmorID ~= itemID then
                                    if itemID ~= nil then
                                        s.PendingDrop = false
                                    end
                                    s.LastArmorID = itemID
                                end

                                if itemID and not s.PendingDrop then
                                    slotPanel.PendingEquip = nil
                                    hasArmor = true
                                    printName = itemData.name
                                    rarityColor = kb.GetItemRarityColor(itemInfo.ent)

                                    local customIconPath = custom_item_data[itemInfo.ent] and custom_item_data[itemInfo.ent].icon or ("entities/" .. itemInfo.ent .. ".png")
                                    if not s.ItemIcon or s.LastEnt ~= itemInfo.ent then
                                        s.ItemIcon = Material(customIconPath, "smooth")
                                        s.LastEnt = itemInfo.ent
                                    end
                                    iconMat = s.ItemIcon
                                elseif slotPanel.PendingEquip then
                                    hasArmor = true
                                    printName = GetItemPrintName(slotPanel.PendingEquip)
                                    rarityColor = kb.GetItemRarityColor(slotPanel.PendingEquip)
                                    
                                    local customIconPath = custom_item_data[slotPanel.PendingEquip] and custom_item_data[slotPanel.PendingEquip].icon or ("entities/" .. slotPanel.PendingEquip .. ".png")
                                    if not s.ItemIcon or s.LastEnt ~= slotPanel.PendingEquip then
                                        s.ItemIcon = Material(customIconPath, "smooth")
                                        s.LastEnt = slotPanel.PendingEquip
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
                        
                        btn.DoClick = function(self)
                            if not IsValid(target_ply) or not target_ply.EZarmor then return end
                            
                            local itemID, itemData, itemInfo = JMod.GetItemInSlot(target_ply.EZarmor, slotName)
                            if not itemID then return end
                            
                            local _, put_snd = kb.GetSoundClaimOrPut(itemInfo.ent)
                            surface.PlaySound(put_snd)
                            
                            self.PendingDrop = true
                            
                            net.Start("KB_TransferArmorToLocal")
                            net.WriteEntity(target_ply)
                            net.WriteString(itemID)
                            net.SendToServer()
                        end
                    end
                end
            end
        end

        GenerateTargetArmorSlots(targetContainer, targetPlyModel, player_ent)

    else
        playerinventory_frame.isClosing = false
        playerinventory_frame.Scroll:Clear()
        
        playerinventory_frame:SetSize(frameW, frameH)
        playerinventory_frame:Center()
        playerinventory_frame.Scroll:SetSize(contentWidth, math.min(contentHeight, frameH - paddingTop - paddingBottom))
        playerinventory_frame.Scroll:SetPos((frameW - contentWidth) / 2, paddingTop)
    end

    playerinventory_frame:MoveToFront()

    local remainingItems = 0
    for _, item in pairs(items) do
        if type(item) == "table" and not item.claimed then
            remainingItems = remainingItems + 1
        end
    end
    playerinventory_frame.RemainingItems = remainingItems

    for index, slot_data in ipairs(visual_slots) do
        local server_index = slot_data.server_index
        local item = slot_data.item
        
        local slotPanel = vgui.Create("DPanel", playerinventory_frame.Scroll)
        slotPanel:SetSize(btnSize, btnSize)
        slotPanel.SlotIndex = server_index

        slotPanel.RealSetPos = slotPanel.SetPos
        
        local centerX = (contentWidth / 2) - (btnSize / 2)
        local centerY = (contentHeight / 2) - (btnSize / 2)
        
        slotPanel.CurrentX = centerX
        slotPanel.CurrentY = centerY
        slotPanel:RealSetPos(centerX, centerY)
        
        slotPanel.SetPos = function(self, x, y)
            self.TargetX = x
            self.TargetY = y

            if isUpdating then
                self.CurrentX = x
                self.CurrentY = y
                self:RealSetPos(x, y)
            end
        end

        slotPanel.Think = function(self)
            local target_x = (IsValid(playerinventory_frame) and playerinventory_frame.isClosing) and centerX or self.TargetX
            local target_y = (IsValid(playerinventory_frame) and playerinventory_frame.isClosing) and centerY or self.TargetY
            
            if target_x and target_y then
                self.CurrentX = Lerp(FrameTime() * 10, self.CurrentX, target_x)
                self.CurrentY = Lerp(FrameTime() * 10, self.CurrentY, target_y)
                
                if math.abs(target_x - self.CurrentX) < 0.5 then
                    self.CurrentX = target_x
                end
                if math.abs(target_y - self.CurrentY) < 0.5 then
                    self.CurrentY = target_y
                end
                
                self:RealSetPos(self.CurrentX, self.CurrentY)
            end
        end

        local col = (index - 1) % maxCols
        local row = math.floor((index - 1) / maxCols)
        local tgtX = col * (btnSize + gap)
        local tgtY = row * (btnSize + gap)
        
        slotPanel:SetPos(tgtX, tgtY)

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
                
                DrawItemIcon(self, self.PendingPut, wep, w, h)
                
                local printName = GetItemPrintName(self.PendingPut, wep)
                
                draw.SimpleText(printName, "DermaDefault", w / 2, h - 6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                
                surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                surface.DrawRect(0, h - 3, w, 3)
            end
        end

        local function SetupReceiver()
            slotPanel:Receiver("KB_Item", function(self_pnl, panels, isDropped, drop_index, x, y)
                if isDropped then
                    local pnl = panels[1]
                    if not IsValid(pnl) then return end

                    if pnl.IsLootboxItem then
                        local old_parent = pnl:GetParent()
                        if old_parent == self_pnl then return end

                        if pnl.BoxEnt != player_ent then return end

                        local existing_btn = nil
                        for _, child in ipairs(self_pnl:GetChildren()) do
                            if child:GetName() == "DButton" and child ~= pnl then
                                existing_btn = child
                                break
                            end
                        end

                        net.Start("KB_SwapLootboxItem")
                            net.WriteEntity(player_ent)
                            net.WriteUInt(pnl.SlotIndex, 8)
                            net.WriteUInt(self_pnl.SlotIndex, 8)
                        net.SendToServer()
                        
                        local _, put_snd = kb.GetSoundClaimOrPut(pnl.WepClass)
                        surface.PlaySound(put_snd)

                        local temp_index = pnl.SlotIndex
                        pnl.SlotIndex = self_pnl.SlotIndex

                        if existing_btn then
                            existing_btn.SlotIndex = temp_index
                            existing_btn:SetParent(old_parent)
                            existing_btn:SetPos(0, 0)
                        end
                        
                        pnl:SetParent(self_pnl)
                        pnl:SetPos(0, 0)
                        return
                    end

                    if pnl.DragArmorID then
                        local is_empty = true
                        for _, child in ipairs(self_pnl:GetChildren()) do
                            if child:GetName() == "DButton" and child:IsVisible() then
                                is_empty = false
                                break
                            end
                        end

                        if not is_empty or self_pnl.PendingPut then return end

                        net.Start("KB_PutArmorItem")
                            net.WriteEntity(player_ent)
                            net.WriteUInt(self_pnl.SlotIndex, 8) 
                            net.WriteString(pnl.DragArmorID)
                            net.WriteBool(pnl.IsTargetArmor or false)
                            if pnl.IsTargetArmor then
                                net.WriteEntity(pnl.ArmorOwner_Container)
                            end
                        net.SendToServer()
                        
                        local _, put_snd = kb.GetSoundClaimOrPut(pnl.ArmorEntClass)
                        surface.PlaySound(put_snd)
                        
                        pnl.PendingDrop = true
                        self_pnl.PendingPut = pnl.ArmorEntClass
                        
                        timer.Simple(0.5, function()
                            if IsValid(self_pnl) and self_pnl.PendingPut == pnl.ArmorEntClass then
                                self_pnl.PendingPut = nil
                            end
                            if IsValid(pnl) then
                                pnl.PendingDrop = false
                            end
                        end)
                        return
                    end

                    if pnl.WepClass then
                        local is_empty = true
                        for _, child in ipairs(self_pnl:GetChildren()) do
                            if child:GetName() == "DButton" and child:IsVisible() then
                                is_empty = false
                                break
                            end
                        end

                        if not is_empty or self_pnl.PendingPut then return end

                        net.Start("KB_PutItem")
                            net.WriteEntity(player_ent)
                            net.WriteUInt(self_pnl.SlotIndex, 8) 
                            net.WriteString(pnl.WepClass)
                        net.SendToServer()
                        
                        local _, put_snd = kb.GetSoundClaimOrPut(pnl.WepClass)
                        surface.PlaySound(put_snd)
                        
                        pnl:SetVisible(false)
                        self_pnl.PendingPut = pnl.WepClass
                        
                        timer.Simple(0.5, function()
                            if IsValid(self_pnl) and self_pnl.PendingPut == pnl.WepClass then
                                self_pnl.PendingPut = nil
                            end
                            if IsValid(pnl) then
                                pnl:SetVisible(true)
                            end
                        end)
                    end
                end
            end)
        end

        SetupReceiver()

        if item and not item.claimed then
            local btn = vgui.Create("DButton", slotPanel)
            btn:SetSize(btnSize, btnSize)
            btn.SlotIndex = server_index
            btn.BoxEnt = player_ent

            local wep = weapons.GetStored(item.class)
            local printName = GetItemPrintName(item.class, wep)
            local rarityColor = kb.GetItemRarityColor(item.class)
            
            btn:SetText("")

            btn.WepClass = item.class
            btn.IsLootboxItem = true
            btn:Droppable("KB_Item")

            btn.OnStartDragging = function(self)
                self:SetPaintedManually(true)
                local claim_snd = kb.GetSoundClaimOrPut(self.WepClass)
                surface.PlaySound(claim_snd)
            end

            btn.OnStopDragging = function(self)
                self:SetPaintedManually(false)
            end

            btn.Paint = function(self, w, h)
                surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                surface.SetMaterial(gradient_down)
                surface.DrawTexturedRect(0, 0, w, h)

                DrawItemIcon(self, self.WepClass, wep, w, h)
                
                draw.SimpleText(printName, "DermaDefault", w / 2, h - 6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                
                surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, 50)
                surface.DrawRect(0, h - 3, w, 3)

                if self:IsHovered() then
                    draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 2))
                end
            end
            
            btn.DoClick = function()
                local claim_snd = kb.GetSoundClaimOrPut(btn.WepClass)
                surface.PlaySound(claim_snd)

                net.Start("KB_ClaimLoot")
                    net.WriteEntity(player_ent)
                    net.WriteUInt(btn.SlotIndex, 8) 
                net.SendToServer()

                if not string.StartWith(item.class, "ent_jack_gmod_ezarmor") and not LocalPlayer():HasWeapon(item.class) then
                    if IsValid(main_inventory) and IsValid(main_inventory.invPanel) then
                        local dummy = vgui.Create("Panel", main_inventory.invPanel) 
                        dummy.PendingClaim = item.class
                        
                        if btn.TargetSlotIndex then
                            dummy.TargetSlotIndex = btn.TargetSlotIndex
                        end
                        
                        main_inventory.invPanel:Refresh()
                    end
                end

                if string.StartWith(item.class, "ent_jack_gmod_ezarmor") or not LocalPlayer():HasWeapon(item.class) then
                    btn:Remove()
                    
                    playerinventory_frame.RemainingItems = playerinventory_frame.RemainingItems - 1
                end
            end
        end
    end
end)