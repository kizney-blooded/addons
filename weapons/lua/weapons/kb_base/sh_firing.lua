function SWEP:GetTracerOrigin()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local model = self
    
    if self.WModel and IsValid(self.WModel[1]) then
        model = self.WModel[1]
    end

    local att_id = model:LookupAttachment("1")
    
    if att_id <= 0 then
        att_id = model:LookupAttachment("muzzle")
    end

    if att_id > 0 then
        local att = model:GetAttachment(att_id)
        if att then
            ParticleEffectAttach("muzzleflash_1", PATTACH_POINT_FOLLOW, model, att_id)

            return att.Pos
        end
    end
end

function SWEP:ShootBullets( damage, num_bullets, aimcone )
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local bullet = {}
    bullet.Num 		= num_bullets
    bullet.Src 		= owner:GetShootPos()
    bullet.Dir 		= owner:GetAimVector()
    bullet.Spread 	= Vector( aimcone, aimcone, 0 )
    bullet.Tracer	= 1
    bullet.TracerName = "Tracer"
    bullet.Force	= 0
    bullet.Damage	= damage
    bullet.AmmoType = "Pistol"
 
    owner:FireBullets( bullet )

    if IsFirstTimePredicted() then
        local recoil = self.RecoilCamShot or 1.5
        local eyeang = owner:EyeAngles()
        
        local pitch_recoil = math.Rand(0.8, 1.2) * recoil
        local yaw_recoil = math.Rand(-0.8, 0.8) * recoil
        
        eyeang.p = math.Clamp(eyeang.p - pitch_recoil, -89, 89)
        eyeang.y = math.NormalizeAngle(eyeang.y + yaw_recoil)
        
        owner:SetEyeAngles(eyeang)

        if CLIENT then
            self:DoCameraShake()
        end
    end
end