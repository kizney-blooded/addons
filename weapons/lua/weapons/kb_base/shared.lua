SWEP.Base = "weapon_base"

SWEP.PrintName = "KB Weapon base"
SWEP.Category = "Weapons - Secondary"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.HoldType = "rpg"

SWEP.WorldModel = "models/weapons/arccw_go/v_rif_ak47.mdl"

SWEP.SupportTPIK = true

SWEP.DrawWeaponInfoBox = false

SWEP.Slot = 2

SWEP.RecoilCamShot = 1.5

SWEP.WorldPos = { Pos = Vector(0.00, 0.00, 0.00), Ang = Angle(30.00, 50.00, 90.00) }
SWEP.LWorldPos = { Pos = Vector(-1.14, -8.71, 0.00), Ang = Angle(0.00, 0.00, 0.00) }
SWEP.SightPos = { Pos = Vector(-5.05, -5.05, 1.05), Ang = Angle(0.00, 0.00, 0.00), FOV = 85.00, Speed = 4.00 }

SWEP.IconPos = {
    Pos = Vector(15, 18, -2),
    Ang = Angle(0, -90, -10),
    FOV = 135
}


function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
    KB_DrawWeaponSelection(self, x, y, wide, tall, alpha)
end


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

include("sh_worldmodel.lua")
include("sh_firing.lua")

function SWEP:Deploy()
    self:PlayAnimation("idle")
    return true
end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()
    
    if IsValid(owner) and owner:IsPlayer() then
        local vel = owner:GetVelocity():Length2D()
        local isSprinting = owner:KeyDown(IN_SPEED) and vel > owner:GetWalkSpeed()
        
        if isSprinting then return end
    end

    self:PlayAnimation("fire")
    self:TakePrimaryAmmo(1)

    self:ShootBullets(30, 0, 0)

    self:SetNextPrimaryFire(CurTime() + self.PrimaryDelay)
end

function SWEP:SecondaryAttack()
end