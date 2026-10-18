local playermeta = FindMetaTable("Player")

playermeta.CreateRagdoll = function() return false end

local ActiveFakes = ActiveFakes or {}

local IdealMassPlayer = {
	["ValveBiped.Bip01_Pelvis"] = 12.775918006897,
	["ValveBiped.Bip01_Spine1"] = 24.36336517334,
	["ValveBiped.Bip01_Spine2"] = 24.36336517334,
	["ValveBiped.Bip01_R_UpperArm"] = 3.4941370487213,
	["ValveBiped.Bip01_L_UpperArm"] = 3.441034078598,
	["ValveBiped.Bip01_L_Forearm"] = 1.7655730247498,
	["ValveBiped.Bip01_L_Hand"] = 1.0779889822006,
	["ValveBiped.Bip01_R_Forearm"] = 1.7567429542542,
	["ValveBiped.Bip01_R_Hand"] = 1.0214320421219,
	["ValveBiped.Bip01_R_Thigh"] = 10.212161064148,
	["ValveBiped.Bip01_R_Calf"] = 4.9580898284912,
	["ValveBiped.Bip01_Head1"] = 5.169750213623,
	["ValveBiped.Bip01_L_Thigh"] = 10.213202476501,
	["ValveBiped.Bip01_L_Calf"] = 4.9809679985046,
	["ValveBiped.Bip01_L_Foot"] = 2.3848159313202,
	["ValveBiped.Bip01_R_Foot"] = 2.3848159313202
}

function playermeta:create_fake(vel)
    local rag = ents.Create("prop_ragdoll")

    rag:SetPos(self:GetPos())
    rag:SetAngles(self:GetAngles())
    rag:SetModel(self:GetModel())

    rag:SetNWVector("PlayerColor", self:GetPlayerColor())

    rag:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    rag:AddEFlags(EFL_NO_DAMAGE_FORCES)

    self:SetNoDraw(true)
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)

    rag:Spawn()

    if IsValid(rag) then
        self.FakeRagdoll = rag
        self:SetNWEntity("FakeRagdoll", rag)
    end

    rag:Activate()


    ActiveFakes[self] = true

    local vel = self:GetVelocity() * (vel or 1)

	for i = 0, rag:GetPhysicsObjectCount() - 1 do
		local physobj = rag:GetPhysicsObjectNum( i )
		local ragbonename = rag:GetBoneName(rag:TranslatePhysBoneToBone(i))

        physobj:SetMass(IdealMassPlayer[ragbonename] or 4)

		local bone = self:LookupBone(ragbonename)
		if bone then
			local bonemat = self:GetBoneMatrix(bone)
			if bonemat then
				local bonepos = bonemat:GetTranslation()
				local boneang = bonemat:GetAngles()
				physobj:SetPos( bonepos, true )
				physobj:SetAngles( boneang )

				physobj:SetVelocity( vel )
			end
		end
        
        physobj:Wake()
	end
end

function playermeta:exit_fake()
    local rag = self.FakeRagdoll

    ActiveFakes[self] = nil

    if IsValid(rag) then
        local rag_pos = rag:GetPos()
        local rag_ang = rag:GetAngles()

        rag:Remove()

        self:SetLocalVelocity(Vector(0, 0, 0))
        self:SetPos(rag_pos)
        self:SetAngles(rag_ang)
    end

    self.FakeRagdoll = nil
    self:SetNoDraw(false)
    self:SetSolid(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_WALK)

    self:SetNWEntity("FakeRagdoll", NULL)
end


hook.Add("Think", "RagdollControl", function()
    for ply in pairs(ActiveFakes) do
        if IsValid(ply) and IsValid(ply.FakeRagdoll) then
            hook.Run("FakeControl", ply, ply.FakeRagdoll)
        else
            ActiveFakes[ply] = nil
        end
    end
end)

concommand.Add("fake",function(ply)
    local rag = ply.FakeRagdoll
    if not ply:Alive() then return end
    if not IsValid(rag) then
        ply:create_fake()
    else
        ply:exit_fake()
    end
end)


hook.Add("PlayerDeath","DeathFake",function(ply,inf,att)
    if not IsValid(ply.FakeRagdoll) then
        ply:create_fake()
    end

    ply:SetNWEntity("FakeRagdoll", NULL)
    ply.FakeRagdoll = nil
end)