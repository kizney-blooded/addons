local function bone_control(phys, sec_arrive, pos, angle, max_angular, max_angular_dump, max_speed, max_speed_dump, damp_factor, teleport_dist, deltatime)
    if not IsValid(phys) then return end

    phys:Wake()

    phys:ComputeShadowControl({
        secondstoarrive  = sec_arrive       or 0.3,
        pos              = pos,
        angle            = angle,
        maxangular       = max_angular      or 360 * 3,
        maxangulardamp   = max_angular_dump or 100,
        maxspeed         = max_speed        or 400,
        maxspeeddamp     = max_speed_dump   or 100,
        dampfactor       = damp_factor      or 1,
        teleportdistance = teleport_dist    or 0,
        deltatime        = deltatime or 1,
    })
end

local function get_bone_phys(rag, bone_name)
    local bone = rag:LookupBone(bone_name)
    if not bone then return nil, nil end
    local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
    return phys, bone
end

local function hand_grab(ply, rag, bone_name, key, cache_var)
    local phys, bone = get_bone_phys(rag, bone_name)
    if not IsValid(phys) then return end

    local prefix = string.find(bone_name, "_L_") and "L" or "R"

    if ply:KeyDown(key) then
        if not IsValid(rag[cache_var]) then
            local hit_trace = nil
            
            for i = 1, 3 do
                local tr = util.TraceLine({
                    start = phys:GetPos(),
                    endpos = phys:GetPos() + phys:GetAngles():Right() * 6 + phys:GetAngles():Up() * (i - 2) * 3,
                    filter = {ply, rag},
                    mask = MASK_SOLID
                })
                
                if tr.Hit and not tr.HitSky then
                    hit_trace = tr
                    break
                end
            end

            if hit_trace then
                local target = hit_trace.HitWorld and game.GetWorld() or hit_trace.Entity
                if not IsValid(target) and not hit_trace.HitWorld then return end

                local phys_bone = rag:TranslateBoneToPhysBone(bone)
                local cons = constraint.Weld(rag, target, phys_bone, hit_trace.PhysicsBone or 0, target:IsWorld() and 10000 or 0, false, false)
                rag[cache_var] = cons

                rag:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1, 7) .. ".wav", 55, math.random(95, 105))

                if IsValid(cons) then
                    for i = 1, 4 do
                        local finger_bone = rag:LookupBone("ValveBiped.Bip01_" .. prefix .. "_Finger" .. i .. "1")
                        if finger_bone then
                            rag:ManipulateBoneAngles(finger_bone, Angle(0, -45, 0))
                        end
                    end

                    cons:CallOnRemove("fingersback_" .. prefix, function()
                        if not IsValid(rag) then return end
                        for i = 1, 4 do
                            local finger_bone = rag:LookupBone("ValveBiped.Bip01_" .. prefix .. "_Finger" .. i .. "1")
                            if finger_bone then
                                rag:ManipulateBoneAngles(finger_bone, Angle(0, 0, 0))
                            end
                        end
                    end)
                end
            end
        end
    else
        if IsValid(rag[cache_var]) then
            rag[cache_var]:Remove()
            rag[cache_var] = nil
            
            for i = 1, 4 do
                local finger_bone = rag:LookupBone("ValveBiped.Bip01_" .. prefix .. "_Finger" .. i .. "1")
                if finger_bone then
                    rag:ManipulateBoneAngles(finger_bone, Angle(0, 0, 0))
                end
            end
        end
    end
end

hook.Add("FakeControl", "Control_fake", function(ply, rag)
    if not IsValid(ply) or not IsValid(rag) then return end

    local Head = get_bone_phys(rag, "ValveBiped.Bip01_Head1")

    local Spine2 = get_bone_phys(rag, "ValveBiped.Bip01_Spine2")
    local Spine4 = get_bone_phys(rag, "ValveBiped.Bip01_Spine4")

    local RHand = get_bone_phys(rag, "ValveBiped.Bip01_R_Hand")
    local LHand = get_bone_phys(rag, "ValveBiped.Bip01_L_Hand")

    local LUpperArm = get_bone_phys(rag, "ValveBiped.Bip01_L_UpperArm")
    local LForearm = get_bone_phys(rag, "ValveBiped.Bip01_L_Forearm")
    local RUpperArm = get_bone_phys(rag, "ValveBiped.Bip01_R_UpperArm")
    local RForearm = get_bone_phys(rag, "ValveBiped.Bip01_R_Forearm")


    local angs = ply:EyeAngles()

    if ply:KeyDown(IN_USE) then
        local angs = ply:EyeAngles()
        angs:RotateAroundAxis(angs:Forward(),0)
        angs:RotateAroundAxis(angs:Up(),-90)
        angs:RotateAroundAxis(angs:Right(),90)

        local target_pos = Spine4:GetPos() + (ply:EyeAngles():Forward() * 50) + Vector(0, 0, 0)
        
        bone_control(Spine4, 0.1, target_pos, angs, 20 , 10, 0, 0, 1)

        if IsValid(Head) then
            local head_angs = ply:EyeAngles()
            head_angs:RotateAroundAxis(head_angs:Forward(), 90)
            head_angs:RotateAroundAxis(head_angs:Up(), 90)
            
            bone_control(Head, 0.1, Head:GetPos(), head_angs, 100, 60, 0, 0, 1)
        end
    end

    -- ЛКМ - Левая рука
    if ply:KeyDown(IN_ATTACK) then
        if IsValid(LHand) and IsValid(LUpperArm) and IsValid(LForearm) then
            local ang2 = ply:EyeAngles()
            
            ang2:RotateAroundAxis(ang2:Up(), 10)
            ang2:RotateAroundAxis(ang2:Forward(), -45)
            
            bone_control(LUpperArm, 0.002, LUpperArm:GetPos(), ang2, 600, 450, 0, 0, 1)
            bone_control(LForearm, 0.002, LForearm:GetPos(), ang2, 600, 450, 0, 0, 1)

            ang2:RotateAroundAxis(ang2:Forward(), 135)
            ang2:RotateAroundAxis(ang2:Up(), 20)

            local target_pos = Head:GetPos() + ply:EyeAngles():Forward() * 30 + ply:EyeAngles():Right() * -9

            bone_control(LHand, 0.001, target_pos, ang2, 1200, 450, 500, 50, 1)
        end
    end

    hand_grab(ply, rag, "ValveBiped.Bip01_L_Hand", IN_SPEED, "WeldL")

    -- ПКМ - Правая рука
    if ply:KeyDown(IN_ATTACK2) then
        if IsValid(RHand) and IsValid(RUpperArm) and IsValid(RForearm) then
            local ang2 = ply:EyeAngles()
            
            ang2:RotateAroundAxis(ang2:Forward(), -90)

            bone_control(RUpperArm, 0.001, RUpperArm:GetPos(), ang2, 600, 450, 0, 0, 1)
            bone_control(RForearm, 0.001, RForearm:GetPos(), ang2, 600, 450, 0, 0, 1)

            ang2:RotateAroundAxis(ang2:Forward(), 135)
            ang2:RotateAroundAxis(ang2:Up(), 20)
            
            local target_pos = Head:GetPos() + ply:EyeAngles():Forward() * 30 + ply:EyeAngles():Right() * 9
            bone_control(RHand, 0.001, target_pos, ang2, 1200, 450, 500, 50, 1)
        end
    end

    hand_grab(ply, rag, "ValveBiped.Bip01_R_Hand", IN_WALK, "WeldR")

    if ply:KeyDown(IN_FORWARD) then
        local angles2 = ply:EyeAngles()
        angles2:RotateAroundAxis(angles2:Right(), 30)
        local pull_dir = angles2:Forward()
        
        local time_mult = FrameTime() / 0.015 

        -- Левая рука
        if IsValid(rag.WeldL) then
            local dir_to_hand = (LHand:GetPos() - Spine2:GetPos()):GetNormalized()
            
            local dot_prod = math.max(dir_to_hand:Dot(pull_dir) + 0.5, 0)
            
            local vel_damp = 1 / math.max(Spine2:GetVelocity():Dot(pull_dir) / 15, 1)
            
            local force = pull_dir * 3000 * dot_prod * time_mult * vel_damp
            
            LHand:ApplyForceCenter(-force)
            Spine2:ApplyForceCenter(force)
        end

        -- Правая рука
        if IsValid(rag.WeldR) then
            local dir_to_hand = (RHand:GetPos() - Spine2:GetPos()):GetNormalized()
            
            local dot_prod = math.max(dir_to_hand:Dot(pull_dir) + 0.5, 0)
            local vel_damp = 1 / math.max(Spine2:GetVelocity():Dot(pull_dir) / 15, 1)
            
            local force = pull_dir * 3000 * dot_prod * time_mult * vel_damp
            
            RHand:ApplyForceCenter(-force)
            Spine2:ApplyForceCenter(force)
        end
    end
end)