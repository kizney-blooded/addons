util.AddNetworkString("headshot_effect")

kb = kb or {}

kb.hitgroup_hp = {
    [HITGROUP_HEAD] = {hp = 100, effect = 50},
}

local HitGroupDamage = {
    [HITGROUP_STOMACH] = 1.0,
    [HITGROUP_CHEST] = 1.0,
    [HITGROUP_RIGHTARM] = 0.8,
    [HITGROUP_LEFTARM] = 0.8,
    [HITGROUP_RIGHTLEG] = 0.2,
    [HITGROUP_LEFTLEG] = 0.2,
    [HITGROUP_HEAD] = 2,
}

local BoneToHitGroup = {
    ["ValveBiped.Bip01_Head1"] = HITGROUP_HEAD,
    ["ValveBiped.Bip01_Spine"] = HITGROUP_STOMACH,
    ["ValveBiped.Bip01_Spine1"] = HITGROUP_CHEST,
    ["ValveBiped.Bip01_Spine2"] = HITGROUP_CHEST,
    ["ValveBiped.Bip01_Spine4"] = HITGROUP_CHEST,
    ["ValveBiped.Bip01_R_UpperArm"] = HITGROUP_RIGHTARM,
    ["ValveBiped.Bip01_R_Forearm"] = HITGROUP_RIGHTARM,
    ["ValveBiped.Bip01_R_Hand"] = HITGROUP_RIGHTARM,
    ["ValveBiped.Bip01_R_Clavicle"] = HITGROUP_RIGHTARM,
    ["ValveBiped.Bip01_L_UpperArm"] = HITGROUP_LEFTARM,
    ["ValveBiped.Bip01_L_Forearm"] = HITGROUP_LEFTARM,
    ["ValveBiped.Bip01_L_Hand"] = HITGROUP_LEFTARM,
    ["ValveBiped.Bip01_L_Clavicle"] = HITGROUP_LEFTARM,
    ["ValveBiped.Bip01_R_Thigh"] = HITGROUP_RIGHTLEG,
    ["ValveBiped.Bip01_R_Calf"] = HITGROUP_RIGHTLEG,
    ["ValveBiped.Bip01_R_Foot"] = HITGROUP_RIGHTLEG,
    ["ValveBiped.Bip01_L_Thigh"] = HITGROUP_LEFTLEG,
    ["ValveBiped.Bip01_L_Calf"] = HITGROUP_LEFTLEG,
    ["ValveBiped.Bip01_L_Foot"] = HITGROUP_LEFTLEG,
}

local function GetHitGroupData(ent, hitgroup)
    if not ent.kb_hitgroup_hp then
        ent.kb_hitgroup_hp = {}
    end
    
    if not ent.kb_hitgroup_hp[hitgroup] and kb.hitgroup_hp[hitgroup] then
        ent.kb_hitgroup_hp[hitgroup] = {
            hp = kb.hitgroup_hp[hitgroup].hp,
            effect = kb.hitgroup_hp[hitgroup].effect,
            triggered = false
        }
    end
    
    return ent.kb_hitgroup_hp[hitgroup]
end

function do_effect_on_damage(victim, damage, damagePos, hitgroup)
    local hg_data = GetHitGroupData(victim, hitgroup)
    if not hg_data then return end

    hg_data.hp = hg_data.hp - damage

    if hg_data.hp <= hg_data.effect and not hg_data.triggered then
        hg_data.triggered = true

        if hitgroup == HITGROUP_HEAD then
            net.Start("headshot_effect")
            net.WriteEntity(victim)
            net.WriteVector(damagePos)
            net.Broadcast()
        end
    end
end

hook.Add("PlayerSpawn", "ResetHitGroupHP", function(ply)
    ply.kb_hitgroup_hp = nil
end)

hook.Add("ScalePlayerDamage", "HitGroupMultipliers_Player", function(ply, hitgroup, dmginfo)
    if HitGroupDamage[hitgroup] then
        dmginfo:ScaleDamage(HitGroupDamage[hitgroup])
    end

    do_effect_on_damage(ply, dmginfo:GetDamage(), dmginfo:GetDamagePosition(), hitgroup)
end)

hook.Add("ScaleNPCDamage", "HitGroupMultipliers_NPC", function(npc, hitgroup, dmginfo)
    if HitGroupDamage[hitgroup] then
        dmginfo:ScaleDamage(HitGroupDamage[hitgroup])
    end
    
    do_effect_on_damage(npc, dmginfo:GetDamage(), dmginfo:GetDamagePosition(), hitgroup)
end)

function ragdoll_fall_damage(ent, dmginfo)
    if not IsValid(ent) or ent:GetClass() ~= "prop_ragdoll" then return end

    local damage = dmginfo:GetDamage()

    if dmginfo:IsDamageType(DMG_CRUSH) then
        if damage < 10 then return end 
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            if phys:GetVelocity():Length() < 350 then return end
        end
    end

    local damagePos = dmginfo:GetDamagePosition()

    local closestPhysBone = 0
    local closestDist = math.huge

    for i = 0, ent:GetPhysicsObjectCount() - 1 do
        local phys = ent:GetPhysicsObjectNum(i)
        if IsValid(phys) then
            local dist = phys:GetPos():DistToSqr(damagePos)
            if dist < closestDist then
                closestDist = dist
                closestPhysBone = i
            end
        end
    end

    local bone = ent:TranslatePhysBoneToBone(closestPhysBone)
    local boneName = ent:GetBoneName(bone)
    
    if boneName then
        local hitgroup = BoneToHitGroup[boneName]
        
        if hitgroup and HitGroupDamage[hitgroup] then
            damage = damage * HitGroupDamage[hitgroup]
        end

        do_effect_on_damage(ent, damage, damagePos, hitgroup)
    end

    local owner = nil
    for _, ply in player.Iterator() do
        if ply.FakeRagdoll == ent then
            owner = ply
            break
        end
    end

    if IsValid(owner) and owner:Alive() then
        local ply_dmg = DamageInfo()
        ply_dmg:SetDamage(damage) 
        ply_dmg:SetAttacker(dmginfo:GetAttacker() or game.GetWorld())
        ply_dmg:SetInflictor(dmginfo:GetInflictor() or game.GetWorld())
        
        if dmginfo:IsDamageType(DMG_CRUSH) then
            ply_dmg:SetDamageType(DMG_FALL)
        else
            ply_dmg:SetDamageType(DMG_BULLET)
        end

        ply_dmg:SetDamagePosition(owner:GetPos())
        owner:TakeDamageInfo(ply_dmg)
    end
end

hook.Add("EntityTakeDamage", "RagdollFallDamageHook", ragdoll_fall_damage)