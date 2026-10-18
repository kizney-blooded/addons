function SWEP:calcview_sight(ply, pos, ang, fov)
    if not self.SightPos or not self.LWorldPos then return pos, ang, fov end

    local isAiming = ply:KeyDown(IN_ATTACK2) or self.ForceAim
    local speed = self.SightPos.Speed or 15
    local ft = FrameTime()

    if not self.CurrentLPos then self.CurrentLPos = Vector(self.LWorldPos.Pos) end
    if not self.CurrentLAng then self.CurrentLAng = Angle(self.LWorldPos.Ang) end
    if not self.CurrentFOV then self.CurrentFOV = fov end

    local targetPos = isAiming and self.SightPos.Pos or self.LWorldPos.Pos
    local targetAng = isAiming and self.SightPos.Ang or self.LWorldPos.Ang
    local targetFOV = isAiming and self.SightPos.FOV or fov

    self.CurrentLPos = LerpVector(ft * speed, self.CurrentLPos, targetPos)
    self.CurrentLAng = LerpAngle(ft * speed, self.CurrentLAng, targetAng)
    self.CurrentFOV = Lerp(ft * speed, self.CurrentFOV, targetFOV)

    return pos, ang, self.CurrentFOV
end