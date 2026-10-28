kb = kb or {}

kb.LHIKHandBones = {
    "ValveBiped.Bip01_L_Wrist", "ValveBiped.Bip01_L_Ulna", "ValveBiped.Bip01_L_Hand",
    "ValveBiped.Bip01_L_Finger4", "ValveBiped.Bip01_L_Finger41", "ValveBiped.Bip01_L_Finger42",
    "ValveBiped.Bip01_L_Finger3", "ValveBiped.Bip01_L_Finger31", "ValveBiped.Bip01_L_Finger32",
    "ValveBiped.Bip01_L_Finger2", "ValveBiped.Bip01_L_Finger21", "ValveBiped.Bip01_L_Finger22",
    "ValveBiped.Bip01_L_Finger1", "ValveBiped.Bip01_L_Finger11", "ValveBiped.Bip01_L_Finger12",
    "ValveBiped.Bip01_L_Finger0", "ValveBiped.Bip01_L_Finger01", "ValveBiped.Bip01_L_Finger02"
}

kb.RHIKHandBones = {
    "ValveBiped.Bip01_R_Wrist", "ValveBiped.Bip01_R_Ulna", "ValveBiped.Bip01_R_Hand",
    "ValveBiped.Bip01_R_Finger4", "ValveBiped.Bip01_R_Finger41", "ValveBiped.Bip01_R_Finger42",
    "ValveBiped.Bip01_R_Finger3", "ValveBiped.Bip01_R_Finger31", "ValveBiped.Bip01_R_Finger32",
    "ValveBiped.Bip01_R_Finger2", "ValveBiped.Bip01_R_Finger21", "ValveBiped.Bip01_R_Finger22",
    "ValveBiped.Bip01_R_Finger1", "ValveBiped.Bip01_R_Finger11", "ValveBiped.Bip01_R_Finger12",
    "ValveBiped.Bip01_R_Finger0", "ValveBiped.Bip01_R_Finger01", "ValveBiped.Bip01_R_Finger02"
}

kb.TPIKBones = {
    "ValveBiped.Bip01_L_Hand",
    "ValveBiped.Bip01_L_Finger4", "ValveBiped.Bip01_L_Finger41", "ValveBiped.Bip01_L_Finger42",
    "ValveBiped.Bip01_L_Finger3", "ValveBiped.Bip01_L_Finger31", "ValveBiped.Bip01_L_Finger32",
    "ValveBiped.Bip01_L_Finger2", "ValveBiped.Bip01_L_Finger21", "ValveBiped.Bip01_L_Finger22",
    "ValveBiped.Bip01_L_Finger1", "ValveBiped.Bip01_L_Finger11", "ValveBiped.Bip01_L_Finger12",
    "ValveBiped.Bip01_L_Finger0", "ValveBiped.Bip01_L_Finger01", "ValveBiped.Bip01_L_Finger02",
    "ValveBiped.Bip01_R_Hand",
    "ValveBiped.Bip01_R_Finger4", "ValveBiped.Bip01_R_Finger41", "ValveBiped.Bip01_R_Finger42",
    "ValveBiped.Bip01_R_Finger3", "ValveBiped.Bip01_R_Finger31", "ValveBiped.Bip01_R_Finger32",
    "ValveBiped.Bip01_R_Finger2", "ValveBiped.Bip01_R_Finger21", "ValveBiped.Bip01_R_Finger22",
    "ValveBiped.Bip01_R_Finger1", "ValveBiped.Bip01_R_Finger11", "ValveBiped.Bip01_R_Finger12",
    "ValveBiped.Bip01_R_Finger0", "ValveBiped.Bip01_R_Finger01", "ValveBiped.Bip01_R_Finger02"
}

local SWEP = FindMetaTable("Weapon")

function SWEP:GetWM()
    return self.WModel and self.WModel[1] or NULL
end

function SWEP:GetVM()
    local owner = self:GetOwner()
    if !IsValid(owner) or !owner:IsPlayer() then return nil end
    return owner:GetViewModel()
end

if SERVER then
    util.AddNetworkString("KB_PlayAnim")
end


if CLIENT then
    net.Receive("KB_PlayAnim", function()
        local wep = net.ReadEntity()
        local anim = net.ReadString()
        
        if IsValid(wep) and wep.PlayAnimation then
            wep:PlayAnimation(anim)
        end
    end)
end

function SWEP:PlayAnimation(animName)
    if not self.Animations or not self.Animations[animName] then return end

    if SERVER then
        net.Start("KB_PlayAnim")
        net.WriteEntity(self)
        net.WriteString(animName)
        
        local owner = self:GetOwner()
        if IsValid(owner) and owner:IsPlayer() then
            net.SendOmit(owner)
        else
            net.Broadcast()
        end
        return
    end

    local isOwner = (IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer())
    if CLIENT and isOwner and not IsFirstTimePredicted() then return end

    local animData = self.Animations[animName]
    local mult = animData.mult or 1
    local wm = self:GetWM()
    
    if IsValid(wm) then
        local seq = wm:LookupSequence(animData.anim)
        if seq and seq >= 0 then
            self.CurrentTPIKAnim = seq
            
            self.AnimStartTime = UnPredictedCurTime()
            self.AnimDuration = wm:SequenceDuration(seq)
            self.AnimMult = mult
            
            wm:SetSequence(seq)
            wm:SetCycle(0)
            wm:SetPlaybackRate(mult)
        end
    end

    if CLIENT and (not isOwner or IsFirstTimePredicted()) then
        if animData.sounds then
            for _, sndData in ipairs(animData.sounds) do
                local delay = sndData.time / mult
                timer.Simple(delay, function()
                    if IsValid(self) then
                        self:EmitSound(sndData.sound)
                    end
                end)
            end
        end
    end
end

function SWEP:GetSequenceCycle()
    if not self.AnimStartTime or not self.AnimDuration or self.AnimDuration <= 0 then 
        return 0 
    end
    
    local current_time = CLIENT and UnPredictedCurTime() or CurTime()
    local elapsed = (current_time - self.AnimStartTime) * (self.AnimMult or 1)
    
    local cycle = elapsed / self.AnimDuration
    
    return math.min(cycle, 1)
end

function SWEP:Solve2PartIK(start_p, end_p, length0, length1, sign, angs)
    local length2 = (start_p - end_p):Length()
    local cosAngle0 = math.Clamp(((length2 * length2) + (length0 * length0) - (length1 * length1)) / (2 * length2 * length0), -1, 1)
    local angle0 = -math.deg(math.acos(cosAngle0))
    local cosAngle1 = math.Clamp(((length1 * length1) + (length0 * length0) - (length2 * length2)) / (2 * length1 * length0), -1, 1)
    local angle1 = -math.deg(math.acos(cosAngle1))

    local diff = end_p - start_p
    diff:Normalize()

    local angle2 = math.deg(math.atan2(-math.sqrt(diff.x * diff.x + diff.y * diff.y), diff.z)) - 90
    local angle3 = -math.deg(math.atan2(diff.x, diff.y)) - 90
    angle3 = math.NormalizeAngle(angle3)

    local axis = diff * 1
    axis:Normalize()
    
    local torsoang = vector_up:Angle()
    local Joint0 = Angle(angle0 + angle2, angle3, 0)
    local asdot = -vector_up:Dot(torsoang:Up())
    local diffa2 = 90 + (sign > 0 and -30 or 30)
    local torsoright = angs.y + 120 * sign
    
    Joint0:RotateAroundAxis(Joint0:Forward(), diffa2)
    Joint0:RotateAroundAxis(axis, angle3 - torsoright)
    local ang1 = -(-Joint0)
    local Joint0_F = start_p + Joint0:Forward() * length0

    local Joint1 = Angle(angle0 + angle2 + 180 + angle1, angle3, 0)
    Joint1:RotateAroundAxis(Joint1:Forward(), diffa2)
    Joint1:RotateAroundAxis(axis, angle3 - torsoright)
    local ang2 = -(-Joint1)
    local Joint1_F = Joint0_F + Joint1:Forward() * length1

    return Joint0_F, Joint1_F, ang1, ang2
end

function SWEP:RotateAroundPoint(pos, ang, point, offset, offset_ang)
    local v = Vector(0, 0, 0)
    v = v + (point.x * ang:Right())
    v = v + (point.y * ang:Forward())
    v = v + (point.z * ang:Up())

    local newang = Angle()
    newang:Set(ang)

    newang:RotateAroundAxis(ang:Right(), offset_ang.p)
    newang:RotateAroundAxis(ang:Forward(), offset_ang.r)
    newang:RotateAroundAxis(ang:Up(), offset_ang.y)

    v = v + newang:Right() * offset.x
    v = v + newang:Forward() * offset.y
    v = v + newang:Up() * offset.z

    -- v:Rotate(offset_ang)

    v = v - (point.x * newang:Right())
    v = v - (point.y * newang:Forward())
    v = v - (point.z * newang:Up())

    pos = v + pos

    return pos, newang
end

function SWEP:RotateAroundPoint2(pos, ang, point, offset, offset_ang)

    local mat = Matrix()
    mat:SetTranslation(pos)
    mat:SetAngles(ang)
    mat:Translate(point)

    local rot_mat = Matrix()
    rot_mat:SetAngles(offset_ang)
    rot_mat:Invert()

    mat:Mul(rot_mat)

    mat:Translate(-point)

    mat:Translate(offset)

    return mat:GetTranslation(), mat:GetAngles()
end