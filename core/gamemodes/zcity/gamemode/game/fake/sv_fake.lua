local playermeta = FindMetaTable("Player")

playermeta.CreateRagdoll = function() return false end


function playermeta.create_fake(ply)
    local rag = ents.Create("prop_ragdoll")

    rag:SetPos(ply:GetPos())
    rag:SetAngles(ply:GetAngles())
    rag:SetModel(ply:GetModel())

    ply.FakeRagdoll = rag

    rag:Spawn()
    rag:Activate()
end

function playermeta.exit_fake(ply)
    local rag = ply.FakeRagdoll

    rag:Remove()
end

concommand.Add("fake",function(ply)
    local rag = ply.FakeRagdoll
    if not IsValid(rag) then
        ply:create_fake(ply)
    else
        ply:exit_fake(ply)
    end
end)