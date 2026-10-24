util.AddNetworkString("KB_SyncInventorySlots")

util.AddNetworkString("KB_OpenPlayerInventory")
util.AddNetworkString("KB_OpenLootBox")

util.AddNetworkString("KB_ClaimLoot")
util.AddNetworkString("KB_PutItem")

util.AddNetworkString("KB_DropWeapon_Action")
util.AddNetworkString("KB_DropLootboxItem")

util.AddNetworkString("KB_SwapLootboxItem")


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
        
        if ply:HasWeapon(item.class) then
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