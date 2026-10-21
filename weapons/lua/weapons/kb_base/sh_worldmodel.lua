function SWEP:Initialize()
    self:PlayAnimation("idle")
    self:SetHoldType(self.HoldType)
    if CLIENT then
        local wm = ClientsideModel(self.WorldModel)
        wm:SetNoDraw(true)
        wm.slottbl = {}
        self.WModel = { wm } 
    end
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
            local target = IsValid(rag) and rag or owner
            
            local boneid = target:LookupBone("ValveBiped.Bip01_Spine4")
            if boneid then
                target:SetupBones()
                local matrix = target:GetBoneMatrix(boneid)
                if matrix then
                    pos = matrix:GetTranslation()
                    ang = matrix:GetAngles()

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