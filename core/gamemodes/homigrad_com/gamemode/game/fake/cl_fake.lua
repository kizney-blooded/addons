hook.Add("OnEntityCreated", "Ragdoll_Color", function(ent)
    if ent:GetClass() == "prop_ragdoll" then
        ent.GetPlayerColor = function()
            return ent:GetNWVector("PlayerColor", LocalPlayer():GetPlayerColor())
        end
    end
end)