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
    function SWEP:DrawWorldModel()
        local wm = self:GetWM()
        local owner = self:GetOwner()
        
        if IsValid(wm) then
            if IsValid(owner) and owner:IsPlayer() then
                local pos, ang
                
                if GetViewEntity() == owner and owner == LocalPlayer() then
                    pos = main_origin or EyePos()
                    ang = main_angles or EyeAngles()
                    
                    local offsetPos = self.CurrentLPos or self.LWorldPos.Pos
                    local offsetAng = self.CurrentLAng or self.LWorldPos.Ang
                    
                    pos = pos + ang:Forward() * offsetPos.x + ang:Right() * offsetPos.y + ang:Up() * offsetPos.z
                    ang:RotateAroundAxis(ang:Up(), offsetAng.y)
                    ang:RotateAroundAxis(ang:Right(), offsetAng.p)
                    ang:RotateAroundAxis(ang:Forward(), offsetAng.r)
                else
                    local boneid = owner:LookupBone("ValveBiped.Bip01_Spine4")
                    if boneid then
                        local matrix = owner:GetBoneMatrix(boneid)
                        if matrix then
                            pos = matrix:GetTranslation()
                            ang = matrix:GetAngles()

                            local offset = self.WorldPos
                            pos = pos + ang:Forward() * offset.Pos.x + ang:Right() * offset.Pos.y + ang:Up() * offset.Pos.z
                            ang:RotateAroundAxis(ang:Up(), offset.Ang.y)
                            ang:RotateAroundAxis(ang:Right(), offset.Ang.p)
                            ang:RotateAroundAxis(ang:Forward(), offset.Ang.r)
                        end
                    end
                end

                if pos and ang then
                    wm:SetRenderOrigin(pos)
                    wm:SetRenderAngles(ang)
                    wm:SetPos(pos)
                    wm:SetAngles(ang)

                    wm:SetupBones() -- чито
                end
            end
            
            wm:DrawModel()
        else
            self:DrawModel()
        end
    end
end