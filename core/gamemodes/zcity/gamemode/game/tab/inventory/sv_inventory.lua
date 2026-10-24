util.AddNetworkString("KB_ClaimLoot")
util.AddNetworkString("KB_PutItem")

util.AddNetworkString("KB_DropWeapon_Action")
util.AddNetworkString("KB_DropLootboxItem")


util.AddNetworkString("KB_SwapLootboxItem")

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
            
            if IsValid(wep) then
                print(item.clip1)
                if item.clip1 ~= nil then
                    wep:SetClip1(item.clip1)
                elseif item.ammo_taken then
                    wep:SetClip1(0)
                end

                print(item.clip2)
                
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
        
        if not has_items_left and not box_ent.IsStorage then
            box_ent:Remove()
        end
    end
end)

net.Receive("KB_PutItem", function(len, ply)
    local box_ent = net.ReadEntity()
    local item_index = net.ReadUInt(8)
    local wep_class = net.ReadString()

    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(box_ent) or not box_ent.Inventory then return end
    
    if ply:GetPos():DistToSqr(box_ent:GetPos()) > 40000 then return end

    if box_ent.Inventory[item_index] then
        local item = box_ent.Inventory[item_index]
        
        if item.claimed and ply:HasWeapon(wep_class) then
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
            
            net.Start("KB_OpenLootBox")
                net.WriteEntity(box_ent)
                net.WriteTable(box_ent.Inventory)
            net.Send(ply)
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

    if item_from and item_to then
        box_ent.Inventory[from_index] = item_to
        box_ent.Inventory[to_index] = item_from
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
        
        if not has_items_left then
            box_ent:Remove()
        end
    end
end)