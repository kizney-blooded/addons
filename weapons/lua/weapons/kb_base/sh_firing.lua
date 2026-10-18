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
    local bullet = {}
    bullet.Num 		= num_bullets
    bullet.Src 		= self.Owner:GetShootPos()
    bullet.Dir 		= self.Owner:GetAimVector()
    bullet.Spread 	= Vector( aimcone, aimcone, 0 )
    bullet.Tracer	= 1
    bullet.TracerName = "Tracer"
    bullet.Force	= 1
    bullet.Damage	= damage
    bullet.AmmoType = "Pistol"
 
    self.Owner:FireBullets( bullet )
end