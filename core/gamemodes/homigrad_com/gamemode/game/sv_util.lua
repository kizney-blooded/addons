local bodyPartMass = {
    ["head"] = 100,   -- Heavier head
    ["spine"] = 300,  -- Much heavier spine
    ["pelvis"] = 200, -- Heavier pelvis
    ["arm"] = 80,     -- Heavier arms
    ["leg"] = 160,    -- Heavier legs
    ["hand"] = 24,    -- Heavier hands
    ["foot"] = 40     -- Heavier feet
}

local jointLimits = {
    ["shoulder"] = {pitch = 180, yaw = 90, roll = 90},
    ["elbow"]    = {pitch = 150, yaw = 10, roll = 10},
    ["knee"]     = {pitch = 150, yaw = 15, roll = 15},
    ["ankle"]    = {pitch = 50,  yaw = 20, roll = 20},
    ["spine"]    = {pitch = 105,  yaw = 55, roll = 45}
}
local RagmodEnabled
for k, v in pairs(engine.GetAddons()) do
    if v.wsid == "2817879135" and v.mounted == true then
        RagmodEnabled = true
        require("ragmod") 
        break
    end
end

local function CreateJoint(ragdoll, bone1, bone2, limits)
    local bone1Phys = ragdoll:GetPhysicsObjectNum(bone1)
    local bone2Phys = ragdoll:GetPhysicsObjectNum(bone2)

    if not IsValid(bone1Phys) or not IsValid(bone2Phys) then return end

    if constraint and constraint.AdvBallsocket then
        constraint.AdvBallsocket(
            ragdoll, bone1,
            ragdoll, bone2,
            0, 0, 0,
            -limits.pitch, limits.pitch,
            -limits.yaw, limits.yaw,
            -limits.roll, limits.roll,
            0.05, 0.05
        )
    else
        print("[ERROR] constraint.BallsocketAdvanced is unavailable.")
    end
end

hook.Add("CreateEntityRagdoll", "HeavyRagdollPhysics", function(entity, ragdoll)
    
    if not IsValid(ragdoll) then return end

    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local phys = ragdoll:GetPhysicsObjectNum(i)
        if IsValid(phys) then
            local boneName = ragdoll:GetBoneName(ragdoll:TranslatePhysBoneToBone(i)):lower()
            local mass = bodyPartMass["spine"]

            if string.find(boneName, "head") then
                mass = bodyPartMass["head"]
            elseif string.find(boneName, "pelvis") then
                mass = bodyPartMass["pelvis"]
            elseif string.find(boneName, "arm") then
                mass = bodyPartMass["arm"]
            elseif string.find(boneName, "leg") then
                mass = bodyPartMass["leg"]
            elseif string.find(boneName, "hand") then
                mass = bodyPartMass["hand"]
            elseif string.find(boneName, "foot") then
                mass = bodyPartMass["foot"]
            end

            phys:SetMass(mass)
            phys:SetMaterial("default")
            phys:SetDamping(0,0)
        end
    end

    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local boneParent = ragdoll:GetBoneParent(i)
        if boneParent and boneParent >= 0 then
            local boneName = ragdoll:GetBoneName(ragdoll:TranslatePhysBoneToBone(i)):lower()
            local limits = jointLimits["spine"]

            if string.find(boneName, "shoulder") then
                limits = jointLimits["shoulder"]
            elseif string.find(boneName, "elbow") then
                limits = jointLimits["elbow"]
            elseif string.find(boneName, "knee") then
                limits = jointLimits["knee"]
            elseif string.find(boneName, "ankle") then
                limits = jointLimits["ankle"]
            end

            CreateJoint(ragdoll, boneParent, i, limits)
        end
    end
end)

hook.Add( "OnNPCDropItem", "RemoveNPCDrops", function( npc, item )
    timer.Simple(0.5,function()
        item:Remove()
    end)
end )