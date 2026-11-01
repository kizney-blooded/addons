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

    local src, dir
    local rag = owner:GetNWEntity("FakeRagdoll")

    if IsValid(rag) then
        local att_id = rag:LookupAttachment("eyes")
        if att_id > 0 then
            src = rag:GetAttachment(att_id).Pos
        --else
            --src = rag:GetPos()
        end
    else
        local eye_att = owner:LookupAttachment("eyes")
        if eye_att > 0 then
            src = owner:GetAttachment(eye_att).Pos
        --else
            --src = owner:GetShootPos()
        end
    end
    
    dir = owner:EyeAngles():Forward()

    local bullet = {}
    bullet.Num 		= num_bullets
    bullet.Src 		= src
    bullet.Dir 		= dir
    bullet.Spread 	= Vector( aimcone, aimcone, 0 )
    bullet.Tracer	= 1
    bullet.TracerName = "Tracer"
    bullet.Force	= 2
    bullet.Damage	= damage
    bullet.AmmoType = self.Primary.Ammo or "pistol"

    bullet.Callback = function(attacker, tr, dmginfo)
        if tr.Hit and IsValid(tr.Entity) then
            if tr.Entity:IsPlayer() or tr.Entity:IsNPC() or tr.Entity:IsNextBot() or tr.Entity:IsRagdoll() then
                local effectdata = EffectData()
                effectdata:SetOrigin(tr.HitPos)
                effectdata:SetNormal(tr.HitNormal)
                effectdata:SetEntity(tr.Entity)
                
                util.Effect("BloodImpact", effectdata)
            end
        end
    end
    
    if IsValid(rag) then
        bullet.IgnoreEntity = rag
    end

    owner:LagCompensation(true)
 
    owner:FireBullets( bullet )

    owner:LagCompensation(false)

    if IsFirstTimePredicted() then
        local recoil = self.RecoilCamShot or 1.5
        
        local pitch_recoil = math.Rand(0.8, 1.2) * recoil
        local yaw_recoil = math.Rand(-0.8, 0.8) * recoil
        
        if CLIENT and owner == LocalPlayer() then
            self.TargetRecoilPitch = (self.TargetRecoilPitch or 0) - pitch_recoil
            self.TargetRecoilYaw = (self.TargetRecoilYaw or 0) + yaw_recoil
        end

        if CLIENT then
            self:DoCameraShake()
        end
    end
end

if CLIENT then
    hook.Add("CreateMove", "KB_HardRecoil_System", function(cmd)
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        local wep = ply:GetActiveWeapon()
        
        if IsValid(wep) and wep.TargetRecoilPitch and wep.TargetRecoilYaw then
            
            local apply_speed = 0.3 
            
            local pitch_step = wep.TargetRecoilPitch * apply_speed
            local yaw_step = wep.TargetRecoilYaw * apply_speed
            
            if math.abs(wep.TargetRecoilPitch) > 0.05 or math.abs(wep.TargetRecoilYaw) > 0.05 then
                local ang = cmd:GetViewAngles()
                
                ang.p = math.Clamp(ang.p + pitch_step, -89, 89)
                ang.y = math.NormalizeAngle(ang.y + yaw_step)
                
                cmd:SetViewAngles(ang)
                
                wep.TargetRecoilPitch = wep.TargetRecoilPitch - pitch_step
                wep.TargetRecoilYaw = wep.TargetRecoilYaw - yaw_step
            else
                wep.TargetRecoilPitch = 0
                wep.TargetRecoilYaw = 0
            end
        end
    end)
end