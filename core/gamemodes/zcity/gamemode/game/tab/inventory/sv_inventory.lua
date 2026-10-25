util.AddNetworkString("KB_SyncInventorySlots")

util.AddNetworkString("KB_OpenPlayerInventory")
util.AddNetworkString("KB_OpenLootBox")

util.AddNetworkString("KB_ClaimLoot")
util.AddNetworkString("KB_PutItem")
util.AddNetworkString("KB_PutArmorItem")

util.AddNetworkString("KB_DropWeapon_Action")
util.AddNetworkString("KB_DropLootboxItem")

util.AddNetworkString("KB_SwapLootboxItem")

util.AddNetworkString("KB_TransferArmorToLocal")
util.AddNetworkString("KB_TransferArmorToTarget")
util.AddNetworkString("KB_DropTargetArmor")

net.Receive("KB_SyncInventorySlots", function(len, ply)
    if not IsValid(ply) then return end
    ply.InventorySlotMemory = net.ReadTable()
end)

local weapon_blacklist = {
    ["wep_jack_gmod_hands"] = true,
    ["weapon_physcannon"] = true,
    ["gmod_tool"] = true,
    ["weapon_physgun"] = true,
}

local function SyncRagdollArmorGlobally(ent)
    if IsValid(ent) and ent:GetClass() == "prop_ragdoll" then
        net.Start("KB_SyncRagdollArmor")
        net.WriteEntity(ent)
        net.WriteTable(ent.EZarmor or {})
        net.Broadcast()
    end
end

local function SafeRemoveArmor(ent, armorID)
    if ent:IsPlayer() then
        return JMod.RemoveArmorByID(ent, armorID, false)
    else
        local Info = ent.EZarmor and ent.EZarmor.items and ent.EZarmor.items[armorID]
        if not Info then return end
        local Specs = JMod.ArmorTable[Info.name]
        
        local dropped = ents.Create(Specs.ent)
        dropped:SetPos(ent:GetPos() + Vector(0,0,20))
        dropped:SetAngles(AngleRand())
        dropped.Durability = Info.dur
        if Info.chrg then dropped.ArmorCharges = table.FullCopy(Info.chrg) end
        dropped.EZID = armorID
        dropped:SetColor(Info.col)
        dropped:Spawn()
        dropped:Activate()
        
        ent.EZarmor.items[armorID] = nil
        return dropped
    end
end

local function SafeEquipArmor(ent, dropped_ent)
    if ent:IsPlayer() then
        JMod.EZ_Equip_Armor(ent, dropped_ent)
    else
        local NewArmorName = dropped_ent.ArmorName
        local NewArmorSpecs = JMod.ArmorTable[NewArmorName]
        local NewArmorID = dropped_ent.EZID
        
        ent.EZarmor = ent.EZarmor or table.FullCopy(JMod.DEFAULT_ARMOR)
        ent.EZarmor.items[NewArmorID] = {
            name = NewArmorName,
            dur = dropped_ent.Durability or NewArmorSpecs.dur,
            col = dropped_ent:GetColor(),
            chrg = dropped_ent.ArmorCharges,
            id = NewArmorID,
            tgl = false
        }
        dropped_ent:Remove()
    end
end

hook.Add("PlayerButtonDown", "Check_inventory_players123", function(ply, btn)
    if btn == KEY_E then
        local tr = ply:GetEyeTrace()
        local ent = tr.Entity
        
        if IsValid(ent) and ent:GetClass() == "prop_ragdoll" and ply:GetPos():DistToSqr(ent:GetPos()) < 10000 then
            if not ent.Inventory then
                local inv = {}
                
                if IsValid(ent.FakePlayer) then
                    local slot_memory = ent.FakePlayer.InventorySlotMemory or {}
                    local weps = ent.FakePlayer:GetWeapons()
                    local remaining_weps = {}

                    for _, wep in ipairs(weps) do
                        if not weapon_blacklist[wep:GetClass()] then
                            remaining_weps[wep:GetClass()] = wep
                        end
                    end

                    for i = 1, 8 do
                        local cls = slot_memory[i]
                        if cls and remaining_weps[cls] then
                            local wep = remaining_weps[cls]
                            inv[i] = {
                                class = cls, 
                                claimed = false, 
                                ammo_taken = true,
                                clip1 = wep:Clip1(), 
                                clip2 = wep:Clip2()
                            }
                            remaining_weps[cls] = nil
                        end
                    end

                    for cls, wep in pairs(remaining_weps) do
                        for i = 1, 8 do
                            if not inv[i] then
                                inv[i] = {
                                    class = cls, 
                                    claimed = false, 
                                    ammo_taken = true,
                                    clip1 = wep:Clip1(), 
                                    clip2 = wep:Clip2()
                                }
                                break
                            end
                        end
                    end
                    
                    ent.Inventory = inv
                end
            end

            if ent.Inventory then
                net.Start("KB_OpenPlayerInventory")
                net.WriteEntity(ent)
                net.WriteTable(ent.Inventory)
                net.WriteBool(false)
                net.WriteTable(ent.EZarmor or (IsValid(ent.FakePlayer) and ent.FakePlayer.EZarmor) or {})
                net.Send(ply)
            end
        end
    end
end)

net.Receive("KB_ClaimLoot", function(len, ply)
    local box_ent = net.ReadEntity()
    local item_index = net.ReadUInt(8)

    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(box_ent) then return end
    if ply:GetPos():DistToSqr(box_ent:GetPos()) > 40000 then return end

    if box_ent.Inventory and box_ent.Inventory[item_index] then
        local item = box_ent.Inventory[item_index]
        if item.claimed then return end

        local is_food = string.StartWith(item.class, "food_")
        local is_armor = string.StartWith(item.class, "ent_jack_gmod_ezarmor")
        
        if is_armor then
            item.claimed = true

            local armor_ent = ents.Create(item.class)
            if IsValid(armor_ent) then
                armor_ent:SetPos(ply:GetPos())
                armor_ent:Spawn()
                armor_ent:Activate()
                
                if JMod and JMod.EZ_Equip_Armor then
                    JMod.EZ_Equip_Armor(ply, armor_ent)
                else
                    armor_ent:Remove() 
                end
            end

            if IsValid(box_ent.FakePlayer) then
                if box_ent.FakePlayer.InventorySlotMemory then
                    for k, v in pairs(box_ent.FakePlayer.InventorySlotMemory) do
                        if v == item.class then
                            box_ent.FakePlayer.InventorySlotMemory[k] = nil
                        end
                    end
                end
                net.Start("KB_SyncInventorySlots")
                net.WriteTable(box_ent.FakePlayer.InventorySlotMemory or {})
                net.Send(box_ent.FakePlayer)
            end

        elseif ply:HasWeapon(item.class) then
            if not item.ammo_taken and not is_food then
                local wep = ply:GetWeapon(item.class)
                if IsValid(wep) then
                    local ammo_type = wep:GetPrimaryAmmoType()
                    if ammo_type ~= -1 then
                        local ammo_amount = wep:GetMaxClip1()
                        if ammo_amount <= 0 then ammo_amount = 30 end
                        ply:GiveAmmo(ammo_amount, ammo_type)
                    end
                end
                item.ammo_taken = true
            end
        else
            local wep = ply:Give(item.class, item.ammo_taken or false)
            item.claimed = true

            if IsValid(box_ent.FakePlayer) and box_ent.FakePlayer:HasWeapon(item.class) then
                box_ent.FakePlayer:StripWeapon(item.class)
                
                if box_ent.FakePlayer.InventorySlotMemory then
                    for k, v in pairs(box_ent.FakePlayer.InventorySlotMemory) do
                        if v == item.class then
                            box_ent.FakePlayer.InventorySlotMemory[k] = nil
                        end
                    end
                end
                
                net.Start("KB_SyncInventorySlots")
                net.WriteTable(box_ent.FakePlayer.InventorySlotMemory or {})
                net.Send(box_ent.FakePlayer)
            end
            
            if IsValid(wep) then
                if item.clip1 ~= nil then
                    wep:SetClip1(item.clip1)
                elseif item.ammo_taken then
                    wep:SetClip1(0)
                end
                
                if item.clip2 ~= nil then
                    wep:SetClip2(item.clip2)
                elseif item.ammo_taken and wep:GetSecondaryAmmoType() ~= -1 then
                    wep:SetClip2(0)
                end
            end
        end
        
        local has_items_left = false
        for i = 1, #box_ent.Inventory do
            if not box_ent.Inventory[i].claimed then
                has_items_left = true
                break
            end
        end
        
        if not has_items_left and not box_ent.IsStorage and box_ent:GetClass() ~= "prop_ragdoll" then
            box_ent:Remove()
        else
            local viewers = {}
            for _, p in player.Iterator() do
                if p:GetPos():DistToSqr(box_ent:GetPos()) <= 40000 then
                    table.insert(viewers, p)
                end
            end

            if box_ent:GetClass() == "prop_ragdoll" then
                net.Start("KB_OpenPlayerInventory")
                net.WriteEntity(box_ent)
                net.WriteTable(box_ent.Inventory)
                net.WriteBool(true)
                net.WriteTable(box_ent.EZarmor or (IsValid(box_ent.FakePlayer) and box_ent.FakePlayer.EZarmor) or {})
                net.Send(viewers)
            else
                net.Start("KB_OpenLootBox")
                net.WriteEntity(box_ent)
                net.WriteTable(box_ent.Inventory)
                net.WriteBool(true)
                net.Send(viewers)
            end
        end
    end
end)

net.Receive("KB_PutItem", function(len, ply)
    local box_ent = net.ReadEntity()
    local item_index = net.ReadUInt(8)
    local wep_class = net.ReadString()

    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(box_ent) then return end
    
    box_ent.Inventory = box_ent.Inventory or {}
    if ply:GetPos():DistToSqr(box_ent:GetPos()) > 40000 then return end

    local item = box_ent.Inventory[item_index]
    if item and not item.claimed then return end
    
    if ply:HasWeapon(wep_class) then
        local wep = ply:GetWeapon(wep_class)
        local clip1, clip2 = 0, 0
        
        if IsValid(wep) then
            clip1 = wep:Clip1()
            clip2 = wep:Clip2()
        end
        
        ply:StripWeapon(wep_class)
        
        box_ent.Inventory[item_index] = {
            class = wep_class,
            claimed = false,
            ammo_taken = true,
            clip1 = clip1,
            clip2 = clip2
        }
        
        if IsValid(box_ent.FakePlayer) and box_ent.FakePlayer:Alive() then
            local target_ply = box_ent.FakePlayer
            
            local new_wep = target_ply:Give(wep_class, true)
            if IsValid(new_wep) then
                new_wep:SetClip1(clip1)
                new_wep:SetClip2(clip2)
            end
            
            target_ply.InventorySlotMemory = target_ply.InventorySlotMemory or {}
            target_ply.InventorySlotMemory[item_index] = wep_class
            
            net.Start("KB_SyncInventorySlots")
            net.WriteTable(target_ply.InventorySlotMemory)
            net.Send(target_ply)
        end
        
        local viewers = {}
        for _, p in player.Iterator() do
            if p:GetPos():DistToSqr(box_ent:GetPos()) <= 40000 then
                table.insert(viewers, p)
            end
        end

        if box_ent:GetClass() == "prop_ragdoll" then
            net.Start("KB_OpenPlayerInventory")
                net.WriteEntity(box_ent)
                net.WriteTable(box_ent.Inventory)
                net.WriteBool(true)
                net.WriteTable(box_ent.EZarmor or (IsValid(box_ent.FakePlayer) and box_ent.FakePlayer.EZarmor) or {})
            net.Send(viewers)
        else
            net.Start("KB_OpenLootBox")
                net.WriteEntity(box_ent)
                net.WriteTable(box_ent.Inventory)
                net.WriteBool(true)
            net.Send(viewers)
        end
    end
end)

net.Receive("KB_PutArmorItem", function(len, ply)
    local box_ent = net.ReadEntity()
    local item_index = net.ReadUInt(8)
    local armorID = net.ReadString()
    local is_target = net.ReadBool()
    local target_ent = is_target and net.ReadEntity() or nil

    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(box_ent) then return end
    if ply:GetPos():DistToSqr(box_ent:GetPos()) > 40000 then return end
    
    box_ent.Inventory = box_ent.Inventory or {}
    local item = box_ent.Inventory[item_index]
    if item and not item.claimed then return end 

    local actual_target = ply
    if is_target and IsValid(target_ent) then
        actual_target = target_ent
        if target_ent:GetClass() == "prop_ragdoll" and IsValid(target_ent.FakePlayer) then
            actual_target = target_ent.FakePlayer
        end
    end
    
    if actual_target.EZarmor and actual_target.EZarmor.items and actual_target.EZarmor.items[armorID] then
        local dropped_ent = SafeRemoveArmor(actual_target, armorID)
        if IsValid(dropped_ent) then
            local wep_class = dropped_ent:GetClass()
            dropped_ent:Remove() 
            
            box_ent.Inventory[item_index] = {
                class = wep_class,
                claimed = false,
                ammo_taken = true,
                clip1 = 0,
                clip2 = 0
            }
            
            local viewers = {}
            for _, p in player.Iterator() do
                if p:GetPos():DistToSqr(box_ent:GetPos()) <= 40000 then
                    table.insert(viewers, p)
                end
            end

            SyncRagdollArmorGlobally(actual_target)

            if box_ent:GetClass() == "prop_ragdoll" then
                net.Start("KB_OpenPlayerInventory")
                net.WriteEntity(box_ent)
                net.WriteTable(box_ent.Inventory)
                net.WriteBool(true)
                net.WriteTable(box_ent.EZarmor or (IsValid(box_ent.FakePlayer) and box_ent.FakePlayer.EZarmor) or {})
                net.Send(viewers)
            else
                net.Start("KB_OpenLootBox")
                net.WriteEntity(box_ent)
                net.WriteTable(box_ent.Inventory)
                net.WriteBool(true)
                net.Send(viewers)
            end
        end
    end
end)

net.Receive("KB_SwapLootboxItem", function(len, ply)
    local box_ent = net.ReadEntity()
    local from_index = net.ReadUInt(8)
    local to_index = net.ReadUInt(8)

    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(box_ent) or not box_ent.Inventory then return end
    if ply:GetPos():DistToSqr(box_ent:GetPos()) > 40000 then return end

    local item_from = box_ent.Inventory[from_index]
    local item_to = box_ent.Inventory[to_index]

    if item_from or item_to then
        box_ent.Inventory[from_index] = item_to
        box_ent.Inventory[to_index] = item_from

        if IsValid(box_ent.FakePlayer) then
            local target_ply = box_ent.FakePlayer
            target_ply.InventorySlotMemory = target_ply.InventorySlotMemory or {}
            
            local class_from = item_from and item_from.class or nil
            local class_to = item_to and item_to.class or nil

            target_ply.InventorySlotMemory[from_index] = class_to
            target_ply.InventorySlotMemory[to_index] = class_from

            net.Start("KB_SyncInventorySlots")
            net.WriteTable(target_ply.InventorySlotMemory)
            net.Send(target_ply)
        end

        local viewers = {}
        for _, p in player.Iterator() do
            if p:GetPos():DistToSqr(box_ent:GetPos()) <= 40000 then
                table.insert(viewers, p)
            end
        end

        if box_ent:GetClass() == "prop_ragdoll" then
            net.Start("KB_OpenPlayerInventory")
            net.WriteEntity(box_ent)
            net.WriteTable(box_ent.Inventory)
            net.WriteBool(true)
            net.WriteTable(box_ent.EZarmor or (IsValid(box_ent.FakePlayer) and box_ent.FakePlayer.EZarmor) or {})
            net.Send(viewers)
        else
            net.Start("KB_OpenLootBox")
            net.WriteEntity(box_ent)
            net.WriteTable(box_ent.Inventory)
            net.WriteBool(true)
            net.Send(viewers)
        end
    end
end)

local blacklist = {
    ["wep_jack_gmod_hands"] = true
}

local function DropWeapon(ply, wpn)
	if not IsValid(wpn) then return end
	if (blacklist[wpn:GetClass()] or wpn.AdminOnly) then return end
	ply:DropWeapon(wpn)
end

concommand.Add("+drop", function(ply) DropWeapon(ply, ply:GetActiveWeapon()) end)
concommand.Add("-drop", function(ply) end)

net.Receive("KB_DropWeapon_Action", function(len, ply)
    local wep_class = net.ReadString()
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local wep = ply:GetWeapon(wep_class)
    if IsValid(wep) then
        DropWeapon(ply, wep)
    end
end)

net.Receive("KB_DropLootboxItem", function(len, ply)
    local box_ent = net.ReadEntity()
    local item_index = net.ReadUInt(8)

    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(box_ent) or not box_ent.Inventory then return end
    if ply:GetPos():DistToSqr(box_ent:GetPos()) > 40000 then return end

    if box_ent.Inventory[item_index] then
        local item = box_ent.Inventory[item_index]
        if item.claimed then return end
        
        if IsValid(box_ent.FakePlayer) and box_ent.FakePlayer:HasWeapon(item.class) then
            box_ent.FakePlayer:StripWeapon(item.class)
            
            if box_ent.FakePlayer.InventorySlotMemory then
                for k, v in pairs(box_ent.FakePlayer.InventorySlotMemory) do
                    if v == item.class then
                        box_ent.FakePlayer.InventorySlotMemory[k] = nil
                    end
                end
            end
            
            net.Start("KB_SyncInventorySlots")
            net.WriteTable(box_ent.FakePlayer.InventorySlotMemory or {})
            net.Send(box_ent.FakePlayer)
        end

        item.claimed = true
        
        local wep = ents.Create(item.class)
        if IsValid(wep) then
            local aim_vec = ply:GetAimVector()
            local drop_pos = ply:GetShootPos() + aim_vec * 30 
            
            wep:SetPos(drop_pos)
            wep:SetAngles(ply:EyeAngles())
            wep:Spawn()
            wep:Activate()
            
            local phys = wep:GetPhysicsObject()
            if IsValid(phys) then
                phys:Wake()
                phys:SetVelocity(aim_vec * 200 + Vector(0, 0, 50)) 
            end
        end
        
        local has_items_left = false
        for i = 1, #box_ent.Inventory do
            if not box_ent.Inventory[i].claimed then
                has_items_left = true
                break
            end
        end
        
        if not has_items_left and not box_ent.IsStorage and box_ent:GetClass() ~= "prop_ragdoll" then
            box_ent:Remove()
        else
            local viewers = {}
            for _, p in player.Iterator() do
                if p:GetPos():DistToSqr(box_ent:GetPos()) <= 40000 then
                    table.insert(viewers, p)
                end
            end

            if box_ent:GetClass() == "prop_ragdoll" then
                net.Start("KB_OpenPlayerInventory")
                net.WriteEntity(box_ent)
                net.WriteTable(box_ent.Inventory)
                net.WriteBool(true)
                net.WriteTable(box_ent.EZarmor or (IsValid(box_ent.FakePlayer) and box_ent.FakePlayer.EZarmor) or {})
                net.Send(viewers)
            else
                net.Start("KB_OpenLootBox")
                net.WriteEntity(box_ent)
                net.WriteTable(box_ent.Inventory)
                net.WriteBool(true)
                net.Send(viewers)
            end
        end
    end
end)

local function SyncTargetArmorViewers(target_ent)
    local viewers = {}
    for _, p in player.Iterator() do
        if p:GetPos():DistToSqr(target_ent:GetPos()) <= 40000 then
            table.insert(viewers, p)
        end
    end
    if target_ent:GetClass() == "prop_ragdoll" then
        net.Start("KB_OpenPlayerInventory")
        net.WriteEntity(target_ent)
        net.WriteTable(target_ent.Inventory or {})
        net.WriteBool(true)
        net.WriteTable(target_ent.EZarmor or (IsValid(target_ent.FakePlayer) and target_ent.FakePlayer.EZarmor) or {})
        net.Send(viewers)
    end
end

net.Receive("KB_TransferArmorToLocal", function(len, ply)
    local target_ent = net.ReadEntity()
    local armorID = net.ReadString()
    if not IsValid(ply) or not ply:IsPlayer() or not IsValid(target_ent) then return end
    if ply:GetPos():DistToSqr(target_ent:GetPos()) > 40000 then return end
    
    local actual_target = target_ent
    if target_ent:GetClass() == "prop_ragdoll" and IsValid(target_ent.FakePlayer) then actual_target = target_ent.FakePlayer end
    
    if actual_target.EZarmor and actual_target.EZarmor.items and actual_target.EZarmor.items[armorID] then
        local dropped_ent = SafeRemoveArmor(actual_target, armorID)
        if IsValid(dropped_ent) then
            JMod.EZ_Equip_Armor(ply, dropped_ent)
        end
        SyncRagdollArmorGlobally(actual_target)
        SyncTargetArmorViewers(target_ent)
    end
end)

net.Receive("KB_TransferArmorToTarget", function(len, ply)
    local target_ent = net.ReadEntity()
    local armorID = net.ReadString()
    if not IsValid(ply) or not ply:IsPlayer() or not IsValid(target_ent) then return end
    if ply:GetPos():DistToSqr(target_ent:GetPos()) > 40000 then return end
    
    local actual_target = target_ent
    if target_ent:GetClass() == "prop_ragdoll" and IsValid(target_ent.FakePlayer) then actual_target = target_ent.FakePlayer end
    
    if ply.EZarmor and ply.EZarmor.items and ply.EZarmor.items[armorID] then
        local dropped_ent = JMod.RemoveArmorByID(ply, armorID, false)
        if IsValid(dropped_ent) then
            SafeEquipArmor(actual_target, dropped_ent)
        end
        SyncRagdollArmorGlobally(actual_target)
        SyncTargetArmorViewers(target_ent)
    end
end)

net.Receive("KB_DropTargetArmor", function(len, ply)
    local target_ent = net.ReadEntity()
    local armorID = net.ReadString()
    if not IsValid(ply) or not ply:IsPlayer() or not IsValid(target_ent) then return end
    if ply:GetPos():DistToSqr(target_ent:GetPos()) > 40000 then return end
    
    local actual_target = target_ent
    if target_ent:GetClass() == "prop_ragdoll" and IsValid(target_ent.FakePlayer) then actual_target = target_ent.FakePlayer end
    
    if actual_target.EZarmor and actual_target.EZarmor.items and actual_target.EZarmor.items[armorID] then
        local dropped_ent = SafeRemoveArmor(actual_target, armorID)
        if IsValid(dropped_ent) then
            dropped_ent:SetPos(ply:GetShootPos() + ply:GetAimVector() * 30)
            local phys = dropped_ent:GetPhysicsObject()
            if IsValid(phys) then phys:SetVelocity(ply:GetAimVector() * 200) end
        end
        SyncRagdollArmorGlobally(actual_target)
        SyncTargetArmorViewers(target_ent)
    end
end)