util.AddNetworkString("KB_SyncRagdollArmor")

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
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetNoTarget(true)

    local wep = self:GetActiveWeapon()
    if IsValid(wep) then
        wep:SetNoDraw(true)
        wep:DrawShadow(false)
    end

    rag:Spawn()

    if IsValid(rag) then
        self.FakeRagdoll = rag
        self:SetNWEntity("FakeRagdoll", rag)

        rag:SetNWString("FakePlayerName", self:Nick())

        rag.FakePlayer = self

        --print(rag.FakePlayer)

        local bullseye = ents.Create("npc_bullseye")
        local bodyphy = rag:GetPhysicsObjectNum(10)
        if IsValid(bullseye) then
            bullseye:SetPos(bodyphy:GetPos()+bodyphy:GetAngles():Right()*7)
            bullseye:SetMoveType( MOVETYPE_OBSERVER )
			bullseye:SetParent(rag,rag:LookupAttachment("eyes"))
            bullseye:SetHealth(999999)
            bullseye:Spawn()
            bullseye:Activate()
            bullseye:SetNotSolid(true)

            
            self.FakeBullseye = bullseye

            for _, ent in ipairs(ents.GetAll()) do
                if ent:IsNPC() then
                    ent:AddEntityRelationship(bullseye, D_HT, 0)
                end
            end
        end

        rag:AddCallback("PhysicsCollide", function(ent, data)
            hook.Run("Ragdoll Collide", ent, data)
        end)
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

    rag.FakePlayer = nil

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
    self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    self:SetMoveType(MOVETYPE_WALK)
    self:SetNoTarget(false)

    local wep = self:GetActiveWeapon()
    if IsValid(wep) then
        wep:SetNoDraw(false)
        wep:DrawShadow(true)
    end

    self:SetNWEntity("FakeRagdoll", NULL)
end


hook.Add("Think", "RagdollControl", function()
    for ply in pairs(ActiveFakes) do
        if IsValid(ply) and IsValid(ply.FakeRagdoll) then

            ply:SetPos(ply.FakeRagdoll:GetPos())
            
            hook.Run("FakeControl", ply, ply.FakeRagdoll)
        else
            ActiveFakes[ply] = nil
        end
    end
end)

concommand.Add("fake",function(ply)
    if not ply:Alive() then return end

    ply.FakeCooldown = ply.FakeCooldown or 0
    if CurTime() < ply.FakeCooldown then return end

    local rag = ply.FakeRagdoll
    if not IsValid(rag) then
        ply:create_fake()
        ply.FakeCooldown = CurTime() + 1.2
    else
        local tr = util.TraceLine({
            start = rag:GetPos(),
            endpos = rag:GetPos() - Vector(0, 0, 50),
            filter = {ply, rag}
        })

        if tr.Hit then
            ply:exit_fake()
            ply.FakeCooldown = CurTime() + 1.2
        end
    end
end)

hook.Add("PreCleanupMap", "WakeUpFakesOnCleanup", function()
    for ply in pairs(ActiveFakes) do
        if IsValid(ply) and IsValid(ply.FakeRagdoll) then
            ply:exit_fake()
        end
    end
end)


hook.Add("OnPhysgunPickup","Auto_Fake",function(ply,ent)
    if ent:IsPlayer() and not IsValid(ply.FakeRagdoll) then
        ent:create_fake()
        ply:DropObject()
    end
end)

local weapon_blacklist = {
    ["wep_jack_gmod_hands"] = true,
    ["weapon_physcannon"] = true,
    ["gmod_tool"] = true,
    ["weapon_physgun"] = true,
}


hook.Add("DoPlayerDeath","DeathFake",function(ply,inf,att)

    if not IsValid(ply.FakeRagdoll) then
        ply:create_fake()
    end

    if IsValid(ply.FakeBullseye) then
        ply.FakeBullseye:Remove()
        ply.FakeBullseye = nil
    end

    if IsValid(ply.FakeRagdoll) then
        local inv = {}
        for _, wep in ipairs(ply:GetWeapons()) do
            if not weapon_blacklist[wep:GetClass()] then
                table.insert(inv, {
                    class = wep:GetClass(), 
                    claimed = false, 
                    clip1 = wep:Clip1(), 
                    clip2 = wep:Clip2()
                })
            end
        end
        ply.FakeRagdoll.Inventory = inv

        if ply.EZarmor then
            ply.FakeRagdoll.EZarmor = table.FullCopy(ply.EZarmor)
        else
            ply.FakeRagdoll.EZarmor = {}
        end
        
        ply.FakeRagdoll.FakePlayer = nil

        local deadRagdoll = ply.FakeRagdoll

        timer.Simple(0.1, function()
            if IsValid(deadRagdoll) then
                net.Start("KB_SyncRagdollArmor")
                net.WriteEntity(deadRagdoll)
                net.WriteTable(deadRagdoll.EZarmor)
                net.Broadcast()
            end
        end)
    end

    if IsValid(ply.FakeRagdoll) then
        ply.FakeRagdoll.FakePlayer = nil
    end

    ActiveFakes[ply] = nil

    ply:SetNWEntity("FakeRagdoll", NULL)
    ply.FakeRagdoll = nil
end)

hook.Add("PlayerTick", "KB_DetectPlayerImpact", function(ply, mv)
    if not ply:Alive() or IsValid(ply.FakeRagdoll) or ply:GetMoveType() == MOVETYPE_NOCLIP or ply:GetMoveType() == MOVETYPE_LADDER then 
        return 
    end

    if not ply:IsOnGround() and ply:GetVelocity():Length() > 500 then
        ply:create_fake()
    end
end)