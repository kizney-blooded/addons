util.AddNetworkString("KB_ClaimLoot")

net.Receive("KB_ClaimLoot", function(len, ply)
    local box_ent = net.ReadEntity()
    local item_index = net.ReadUInt(8)

    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(box_ent) or box_ent:GetClass() ~= "ent_lootboxes" then return end
    
    if ply:GetPos():DistToSqr(box_ent:GetPos()) > 40000 then return end

    if box_ent.Inventory and box_ent.Inventory[item_index] then
        local item = box_ent.Inventory[item_index]
        
        ply:Give(item.class)
        ply:ChatPrint("Вы забрали: " .. item.name)
        
        table.remove(box_ent.Inventory, item_index)
        
        if #box_ent.Inventory == 0 then
            box_ent:Remove()
        end
    end
end)