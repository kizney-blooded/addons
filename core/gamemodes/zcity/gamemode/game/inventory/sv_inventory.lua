util.AddNetworkString("KB_ClaimLoot")

net.Receive("KB_ClaimLoot", function(len, ply)
    local box_ent = net.ReadEntity()
    local item_index = net.ReadUInt(8)

    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(box_ent) or box_ent:GetClass() ~= "ent_lootboxes" then return end
    
    if ply:GetPos():DistToSqr(box_ent:GetPos()) > 40000 then return end

    if box_ent.Inventory and box_ent.Inventory[item_index] then
        local item = box_ent.Inventory[item_index]
        
        if item.claimed then return end
        
        if ply:HasWeapon(item.class) then
            if not item.ammo_taken then
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
            
            if item.ammo_taken and IsValid(wep) then
                wep:SetClip1(0)
                
                if wep:GetSecondaryAmmoType() ~= -1 then
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
        
        if not has_items_left then
            box_ent:Remove()
        end
    end
end)