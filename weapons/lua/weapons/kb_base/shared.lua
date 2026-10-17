SWEP.Base = "weapon_base"

SWEP.PrintName = "KB Weapon base"
SWEP.Category = "Weapons - Secondary"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.HoldType = "rpg"

SWEP.WorldModel = "models/weapons/arccw_go/v_rif_ak47.mdl"

SWEP.SupportTPIK = true

SWEP.WorldPos = { Pos = Vector(0, 0, 0), Ang = Angle(30, 50, 90) }
SWEP.LWorldPos = { Pos = Vector(-9, -1, 0), Ang = Angle(0, 0, 0) }

SWEP.Animations = {
    ["idle"] = {
        anim = "ak47_draw", 
        mult = 1, 
        sounds = {
            { sound = "ttt/holster.wav", time = 0.5 },
            { sound = "ttt/draw.wav", time = 1 },
        }
    },
    ["fire"] = {
        anim = "ak47_fire1", 
        mult = 1, 
        sounds = {
            { sound = "arccw_go/ak47/ak47-1.wav", time = 0 },
        }
    }
}

SWEP.Primary.Automatic = true
SWEP.PrimaryDelay = 0.09

function SWEP:Initialize()
    self:PlayAnimation("idle")
    self:SetHoldType(self.HoldType)
    
    if CLIENT and self.ClientInitialize then
        self:ClientInitialize()
    end
end

function SWEP:Deploy()
    self:PlayAnimation("idle")
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

function SWEP:PrimaryAttack()
    self:PlayAnimation("fire")
    self:TakePrimaryAmmo(1)

    self:ShootBullets()

    self:SetNextPrimaryFire(CurTime() + self.PrimaryDelay)
end

function SWEP:SecondaryAttack()
end

function SWEP:OnRemove()
    if CLIENT and self.ClientOnRemove then
        self:ClientOnRemove()
    end
end