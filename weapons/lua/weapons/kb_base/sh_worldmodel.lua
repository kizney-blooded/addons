function SWEP:Initialize()
    self:PlayAnimation("idle")
    self:SetHoldType(self.HoldType)
end

function SWEP:OnRemove()
    if CLIENT and self.WModel and IsValid(self.WModel[1]) then
        self.WModel[1]:Remove()
    end
end

if CLIENT then
    function SWEP:UpdateWorldModelTransform()
        local wm = self:GetWM()
        local owner = self:GetOwner()
        
        if not IsValid(wm) or not IsValid(owner) or not owner:IsPlayer() then return end

        local pos, ang
        
        if GetViewEntity() == owner and owner == LocalPlayer() then
            pos = main_origin or EyePos()
            ang = main_angles or EyeAngles()
            
            local currentFrame = FrameNumber()
            if self.LastSwayFrame ~= currentFrame then
                self.SwayLastAng = self.SwayLastAng or ang
                local swayDiff = ang - self.SwayLastAng
                swayDiff:Normalize()
                
                self.SwayLastAng = LerpAngle(FrameTime() * 15, self.SwayLastAng, ang)
                
                self.LastSwayOffsetAng = Angle(swayDiff.p * 0.2, swayDiff.y * 0.2, 0)
                self.LastSwayFrame = currentFrame
            end
            
            local offsetPos = self.CurrentLPos or self.LWorldPos.Pos
            local offsetAng = self.CurrentLAng or self.LWorldPos.Ang
            
            local finalOffsetAng = offsetAng + (self.LastSwayOffsetAng or angle_zero)
            local pivotPoint = Vector(0, 30, 0) 
            
            pos, ang = self:RotateAroundPoint(pos, ang, pivotPoint, offsetPos, finalOffsetAng)
        else
            local rag = owner:GetNWEntity("FakeRagdoll")
            local isFake = IsValid(rag)
            local target = isFake and rag or owner
            
            local targetBone = isFake and "ValveBiped.Bip01_Head1" or "ValveBiped.Bip01_Spine4"
            local boneid = target:LookupBone(targetBone)
            
            if boneid then
                local matrix = target:GetBoneMatrix(boneid)                
                if matrix then
                    pos = matrix:GetTranslation()
                    ang = matrix:GetAngles()

                    if isFake then
                        local fakePosOffset = Vector(0, -4, -1)
                        local fakeAngOffset = Angle(0, -90, -90)
                        
                        pos = pos + ang:Forward() * fakePosOffset.x + ang:Right() * fakePosOffset.y + ang:Up() * fakePosOffset.z
                        ang:RotateAroundAxis(ang:Up(), fakeAngOffset.y)
                        ang:RotateAroundAxis(ang:Right(), fakeAngOffset.p)
                        ang:RotateAroundAxis(ang:Forward(), fakeAngOffset.r)
                    else
                        local offset = self.WorldPos
                        if offset then
                            pos = pos + ang:Forward() * offset.Pos.x + ang:Right() * offset.Pos.y + ang:Up() * offset.Pos.z
                            ang:RotateAroundAxis(ang:Up(), offset.Ang.y)
                            ang:RotateAroundAxis(ang:Right(), offset.Ang.p)
                            ang:RotateAroundAxis(ang:Forward(), offset.Ang.r)
                        end
                    end
                end
            end
        end

        if pos and ang then
            wm:SetRenderOrigin(pos)
            wm:SetRenderAngles(ang)
            wm:SetPos(pos)
            wm:SetAngles(ang)
            wm:SetupBones()
        end
    end

    function SWEP:DrawWorldModel()
        local wm = self:GetWM()
        local owner = self:GetOwner()

        if IsValid(wm) and IsValid(owner) and owner:IsPlayer() then
            self:UpdateWorldModelTransform()
            wm:DrawModel()
        else
            self:DrawModel()
        end
    end
end