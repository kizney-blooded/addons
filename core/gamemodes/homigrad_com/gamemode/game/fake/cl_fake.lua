hook.Add("OnEntityCreated", "Ragdoll_Color", function(ent)
    if ent:GetClass() == "prop_ragdoll" then
        ent.GetPlayerColor = function()
            return ent:GetNWVector("PlayerColor", LocalPlayer():GetPlayerColor())
        end
    end
end)

net.Receive("KB_SyncRagdollDecals", function()
    local ply_id = net.ReadUInt(16)
    local rag_id = net.ReadUInt(16)

    timer.Create("KB_SnatchDecals_" .. rag_id, 0.1, 20, function()
        local ply = Entity(ply_id)
        local rag = Entity(rag_id)

        if IsValid(ply) and IsValid(rag) then
            rag:SnatchModelInstance(ply)
            
            timer.Remove("KB_SnatchDecals_" .. rag_id)
        end
    end)
end)