hook.Add("PlayerFootstep", "Weapon_Step_Sync", function(ply, pos, foot, sound, volume, rf)
    if ply ~= LocalPlayer() then return end
    
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep.calc_movement_weapon then
        wep.StepImpulse = -1.5 
    end
end)

function SWEP:calc_movement_weapon(ply, isAiming)
    if not IsValid(ply) then return Vector(0,0,0), Angle(0,0,0) end

    local vel = ply:GetVelocity():Length2D()
    local maxSpeed = ply:GetWalkSpeed()
    local ct = CurTime()
    local ft = FrameTime()

    self.MovementPos = self.MovementPos or Vector(0, 0, 0)
    self.MovementAng = self.MovementAng or Angle(0, 0, 0)
    
    self.StepImpulse = self.StepImpulse or 0
    
    self.StepImpulse = Lerp(ft * 15, self.StepImpulse, 0)

    local speedRatio = math.Clamp(vel / maxSpeed, 0, 2)
    local isSprinting = ply:KeyDown(IN_SPEED) and vel > maxSpeed and not isAiming

    local breathMult = isAiming and 0.1 or 1.0
    local walkMult = isAiming and 0.1 or 1.0

    local idleBobP = math.sin(ct * 1.5) * 0.15 * breathMult
    local idleBobY = math.cos(ct * 1.2) * 0.15 * breathMult
    local idlePos = Vector(idleBobY, 0, idleBobP)
    local idleAng = Angle(idleBobP, idleBobY, 0)

    self.BobTime = (self.BobTime or 0) + ft * (vel * 0.025 + 1)
    
    local walkPos = Vector(
        math.sin(self.BobTime) * 0.6 * speedRatio, 
        -speedRatio * 1.5, 
        0 
    ) * walkMult
    
    local walkAng = Angle(
        math.cos(self.BobTime * 2) * 1.5 * speedRatio, 
        math.sin(self.BobTime) * 1.0 * speedRatio, 
        math.sin(self.BobTime) * 3.5 * speedRatio
    ) * walkMult

    if isSprinting then
        walkPos.y = walkPos.y - 2.5
        walkAng.p = walkAng.p - -12
    end

    local targetPos = idlePos + walkPos
    local targetAng = idleAng + walkAng

    self.MovementPos = LerpVector(ft * 8, self.MovementPos, targetPos)
    self.MovementAng = LerpAngle(ft * 8, self.MovementAng, targetAng)

    local finalPos = self.MovementPos + Vector(0, 0, self.StepImpulse * speedRatio * walkMult)

    return finalPos, self.MovementAng
end

function SWEP:calcview_sight(ply, pos, ang, fov)
    if not self.SightPos or not self.LWorldPos then return pos, ang, fov end

    local vel = ply:GetVelocity():Length2D()
    local isSprinting = ply:KeyDown(IN_SPEED) and vel > ply:GetWalkSpeed()

    local isAiming = (ply:KeyDown(IN_ATTACK2) or self.ForceAim) and not isSprinting
    
    local speed = self.SightPos.Speed or 15
    local ft = FrameTime()

    if not self.CurrentLPos then self.CurrentLPos = Vector(self.LWorldPos.Pos) end
    if not self.CurrentLAng then self.CurrentLAng = Angle(self.LWorldPos.Ang) end
    if not self.CurrentFOV then self.CurrentFOV = fov end

    local moveOffsetPos, moveOffsetAng = self:calc_movement_weapon(ply, isAiming)

    local targetPos = (isAiming and self.SightPos.Pos or self.LWorldPos.Pos) + moveOffsetPos
    local targetAng = (isAiming and self.SightPos.Ang or self.LWorldPos.Ang) + moveOffsetAng
    local targetFOV = isAiming and self.SightPos.FOV or fov

    self.CurrentLPos = LerpVector(ft * speed, self.CurrentLPos, targetPos)
    self.CurrentLAng = LerpAngle(ft * speed, self.CurrentLAng, targetAng)
    self.CurrentFOV = Lerp(ft * speed, self.CurrentFOV, targetFOV)

    return pos, ang, self.CurrentFOV
end

function SWEP:DoCameraShake()
    local owner = self:GetOwner()
    if not IsValid(owner) or owner ~= LocalPlayer() then return end

    local recoil = self.RecoilCamShot or 1.5

    util.ScreenShake(Vector(0,0,0), recoil * 1.5, recoil * 10, 0.25, 0)

    local punchAngle = Angle(
        math.Rand(-recoil, -recoil * 0.5), 
        math.Rand(-recoil * 0.5, recoil * 0.5), 
        math.Rand(-recoil * 0.2, recoil * 0.2)
    )
    
    owner:ViewPunch(punchAngle)
end