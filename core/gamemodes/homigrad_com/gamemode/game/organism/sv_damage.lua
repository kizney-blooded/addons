kb = kb or {}

kb.BoneHitGroups = {
    ["ValveBiped.Bip01_Pelvis"] = HITGROUP_STOMACH,
    ["ValveBiped.Bip01_Spine"] = HITGROUP_STOMACH,
    ["ValveBiped.Bip01_Spine1"] = HITGROUP_CHEST,
    ["ValveBiped.Bip01_Spine2"] = HITGROUP_CHEST,
    ["ValveBiped.Bip01_Spine3"] = HITGROUP_CHEST,
    ["ValveBiped.Bip01_Spine4"] = HITGROUP_CHEST,
    ["ValveBiped.Bip01_L_Clavicle"] = HITGROUP_CHEST,
    ["ValveBiped.Bip01_L_UpperArm"] = HITGROUP_LEFTARM,
    ["ValveBiped.Bip01_L_Forearm"] = HITGROUP_LEFTARM,
    ["ValveBiped.Bip01_L_Hand"] = HITGROUP_LEFTARM,
    ["ValveBiped.Bip01_R_Clavicle"] = HITGROUP_CHEST,
    ["ValveBiped.Bip01_R_UpperArm"] = HITGROUP_RIGHTARM,
    ["ValveBiped.Bip01_R_Forearm"] = HITGROUP_RIGHTARM,
    ["ValveBiped.Bip01_R_Hand"] = HITGROUP_RIGHTARM,
    ["ValveBiped.Bip01_Neck1"] = HITGROUP_HEAD,
    ["ValveBiped.Bip01_Head1"] = HITGROUP_HEAD,
    ["ValveBiped.Bip01_L_Thigh"] = HITGROUP_LEFTLEG,
    ["ValveBiped.Bip01_L_Calf"] = HITGROUP_LEFTLEG,
    ["ValveBiped.Bip01_L_Foot"] = HITGROUP_LEFTLEG,
    ["ValveBiped.Bip01_L_Toe0"] = HITGROUP_LEFTLEG,
    ["ValveBiped.Bip01_R_Thigh"] = HITGROUP_RIGHTLEG,
    ["ValveBiped.Bip01_R_Calf"] = HITGROUP_RIGHTLEG,
    ["ValveBiped.Bip01_R_Foot"] = HITGROUP_RIGHTLEG,
    ["ValveBiped.Bip01_R_Toe0"] = HITGROUP_RIGHTLEG
}

kb.HitGroupDamage = {
    [HITGROUP_STOMACH] = 1.0,
    [HITGROUP_CHEST] = 1.0,
    [HITGROUP_GENERIC] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTLEG] = 1,
    [HITGROUP_LEFTLEG] = 1,
    [HITGROUP_HEAD] = 2,
}

kb.HitGroupHP = {
    [HITGROUP_HEAD] = {hp = 100, effect = 50},
}

util.AddNetworkString("headshot_effect")

function otrub_system(ply, damage, hitgroup)
    if not IsValid(ply) then return end
    
    if damage > (ply:GetMaxHealth() / 2) then
        if not IsValid(ply.FakeRagdoll) then
            ply:create_fake()
        end
        ply:SetNWBool("Otrub", true)
        
        local timerName = "OtrubTimer_" .. ply:SteamID64()
        timer.Create(timerName, 10, 1, function()
            if IsValid(ply) then
                ply:SetNWBool("Otrub", false)
            end
        end)
    end
end

function trip_system(ply, damage, hitgroup)
    if not IsValid(ply) or not ply:Alive() then return end
    
    ply.NextFallTime = ply.NextFallTime or 0
    if CurTime() < ply.NextFallTime then return end
    
    if IsValid(ply.FakeRagdoll) then return end
    
    local should_fall = false
    
    if damage > 40 then
        should_fall = true
    end
    
    if (hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG) and damage >= 15 then
        should_fall = true
    end
    
    if should_fall then
        ply:create_fake()
        
        ply.NextFallTime = CurTime() + 3
    end
end

local function process_hitgroup_damage(ent, hitgroup, damage, pos)
    if not ent.HitGroupHP or not ent.HitGroupHP[hitgroup] then return end
    
    local old_hp = ent.HitGroupHP[hitgroup].hp
    local trigger = ent.HitGroupHP[hitgroup].effect
    
    ent.HitGroupHP[hitgroup].hp = math.max(0, old_hp - damage)
    
    if hitgroup == HITGROUP_HEAD and old_hp > trigger and ent.HitGroupHP[hitgroup].hp <= trigger then
        net.Start("headshot_effect")
            net.WriteVector(pos)
        net.Broadcast() 
    end
end

hook.Add("ScalePlayerDamage", "KB_HitGroupScale", function(ply, hitgroup, dmginfo)

    local attacker = dmginfo:GetAttacker()
    if ply:HasGodMode() or hook.Run("PlayerShouldTakeDamage", ply, attacker) == false then
        return
    end

    local scale = kb.HitGroupDamage[hitgroup]
    if scale then
        dmginfo:ScaleDamage(scale)
    end
    
    local final_damage = dmginfo:GetDamage()
    process_hitgroup_damage(ply, hitgroup, final_damage, dmginfo:GetDamagePosition())
    
    return false
end)

hook.Add( "ScaleNPCDamage", "ScaleNPCDamageExample", function( npc, hitgroup, dmginfo )
    local scale = kb.HitGroupDamage[hitgroup]
    if scale then
        dmginfo:ScaleDamage(scale)
    end
    
    local final_damage = dmginfo:GetDamage()
    process_hitgroup_damage(npc, hitgroup, final_damage, dmginfo:GetDamagePosition())
    
    return false
end)

local min_speed = 350 
local dmg_mult = 0.65  
local cd = 0.5       

hook.Add("Ragdoll Collide", "RagdollDamage", function(rag, data)
    local ply = rag.FakePlayer
    if ply == data.HitEntity or rag == data.HitEntity then return end
    

    rag.NextDamageTime = rag.NextDamageTime or 0
    if CurTime() < rag.NextDamageTime then return end

    local relVel = data.OurOldVelocity - data.TheirOldVelocity
    local impactSpeed = math.abs(relVel:Dot(data.HitNormal))

    local boneMass = 10
    local damageMultiplier = 1.0
    local current_hitgroup = HITGROUP_GENERIC

    if IsValid(data.PhysObject) then
        boneMass = data.PhysObject:GetMass()
        
        for i = 0, rag:GetPhysicsObjectCount() - 1 do
            if rag:GetPhysicsObjectNum(i) == data.PhysObject then
                local boneIndex = rag:TranslatePhysBoneToBone(i)
                if boneIndex then
                    local boneName = rag:GetBoneName(boneIndex)
                    if boneName then
                        local hitgroup = kb.BoneHitGroups[boneName]
                        if hitgroup and kb.HitGroupDamage[hitgroup] then
                            damageMultiplier = kb.HitGroupDamage[hitgroup]
                            current_hitgroup = hitgroup
                        end
                    end
                end
                break
            end
        end
    end

    local massModifier = math.Clamp(boneMass / 15, 0.1, 1)
    local finalSpeed = impactSpeed * massModifier

    if finalSpeed > 350 then -- min_speed
        local damageAmount = (finalSpeed - 350) * 0.65 * damageMultiplier -- dmg_mult
        
        if damageAmount > 1 then

            local attacker = IsValid(data.HitEntity) and data.HitEntity or game.GetWorld()
            if IsValid(ply) then
                if ply:HasGodMode() or hook.Run("PlayerShouldTakeDamage", ply, attacker) == false then
                    return
                end
            end
            
            local effectdata = EffectData()
            effectdata:SetOrigin(data.HitPos)
            effectdata:SetNormal(data.HitNormal)
            effectdata:SetScale(1)
            effectdata:SetColor(0)
            util.Effect("BloodImpact", effectdata)

            util.Decal("Blood", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)

            rag.NextDamageTime = CurTime() + 0.5 -- cd
            rag:EmitSound("Flesh.ImpactHard")
            
            process_hitgroup_damage(rag, current_hitgroup, damageAmount, data.HitPos)

            if IsValid(ply) and ply:Alive() then
                local dmginfo = DamageInfo()
                dmginfo:SetDamage(damageAmount)
                
                if IsValid(data.HitEntity) then
                    dmginfo:SetAttacker(data.HitEntity)
                    dmginfo:SetInflictor(data.HitEntity)
                else
                    dmginfo:SetAttacker(game.GetWorld())
                    dmginfo:SetInflictor(game.GetWorld())
                end
                
                dmginfo:SetDamageType(DMG_CRUSH)
                
                ply:TakeDamageInfo(dmginfo)
                otrub_system(ply, damageAmount, current_hitgroup)
            end
        end
    end
end)

hook.Add("EntityTakeDamage", "Ragdoll_Damage_From_Player", function(ent, dmginfo)
    local attacker = dmginfo:GetAttacker()

    if IsValid(ent) and IsValid(ent.FakePlayer) then
        if ent.FakePlayer:HasGodMode() or hook.Run("PlayerShouldTakeDamage", ent.FakePlayer, attacker) == false then
            return true
        end
    end

    if IsValid(attacker) and attacker:IsNPC() then
        
        dmginfo:ScaleDamage(2) 
        
    end

    if IsValid(ent) and ent.HitGroupHP then
        if dmginfo:IsDamageType(DMG_CRUSH) or dmginfo:IsDamageType(DMG_FALL) then
            return
        end

        local dmgPos = dmginfo:GetDamagePosition()
        local scale = 1.0
        local current_hitgroup = HITGROUP_GENERIC
        
        if not dmgPos:IsZero() then
            local closestPhysBone = -1
            local closestDist = math.huge

            for i = 0, ent:GetPhysicsObjectCount() - 1 do
                local phys = ent:GetPhysicsObjectNum(i)
                if IsValid(phys) then
                    local dist = phys:GetPos():DistToSqr(dmgPos)
                    if dist < closestDist then
                        closestDist = dist
                        closestPhysBone = i
                    end
                end
            end

            if closestPhysBone >= 0 then
                local boneIndex = ent:TranslatePhysBoneToBone(closestPhysBone)
                if boneIndex then
                    local boneName = ent:GetBoneName(boneIndex)
                    if boneName then
                        local hitgroup = kb.BoneHitGroups[boneName]
                        if hitgroup and kb.HitGroupDamage[hitgroup] then
                            scale = kb.HitGroupDamage[hitgroup]
                            current_hitgroup = hitgroup
                        end
                    end
                end
            end
        end

        dmginfo:ScaleDamage(scale)
        
        process_hitgroup_damage(ent, current_hitgroup, dmginfo:GetDamage(), dmgPos)

        if IsValid(ent.FakePlayer) and ent.FakePlayer:Alive() then
            ent.FakePlayer:TakeDamageInfo(dmginfo)
        end
    end
end)


hook.Add("DoPlayerDeath","ResetOrganismV2",function(ply,att,dmg)
    if IsValid(ply) then
        ply:SetNWBool("Otrub", false)
    end
end)


hook.Add("PlayerSpawn","ResetOrganism",function(ply,bool)
    if IsValid(ply) then
        ply:SetNWBool("Otrub", false)
        ply.HitGroupHP = table.Copy(kb.HitGroupHP)
    end
end)

hook.Add("OnEntityCreated", "KB_InitEntitiesHP", function(ent)
    timer.Simple(0, function()
        if IsValid(ent) and (ent:GetClass() == "prop_ragdoll" or ent:IsNPC()) then
            if not ent.HitGroupHP then
                ent.HitGroupHP = table.Copy(kb.HitGroupHP)
            end
        end
    end)
end)