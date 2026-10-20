SWEP.Base = "weapon_base"

SWEP.PrintName = "KB Weapon base"
SWEP.Category = "Weapons - Secondary"
SWEP.Spawnable = false
SWEP.AdminOnly = false

--SWEP.Slot = 2
SWEP.SupportTPIK = true
SWEP.DrawWeaponInfoBox = false


--[[SWEP.HoldType = "rpg"

SWEP.WorldModel = "models/weapons/arccw_go/v_rif_ak47.mdl"

SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Ammo = "ar2"

SWEP.ReloadTime = 2.0

SWEP.RecoilCamShot = 1.5

SWEP.WorldPos = { Pos = Vector(0.00, 0.00, 0.00), Ang = Angle(30.00, 50.00, 90.00) }
SWEP.LWorldPos = { Pos = Vector(-1.14, -8.71, 0.00), Ang = Angle(0.00, 0.00, 0.00) }
SWEP.SightPos = { Pos = Vector(-5.05, -5.05, 1.05), Ang = Angle(0.00, 0.00, 0.00), FOV = 85.00, Speed = 4.00 }

SWEP.IconPos = {
    Pos = Vector(15, 18, -2),
    Ang = Angle(0, -90, -10),
    FOV = 135
}

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
    },
    ["reload"] = {
        anim = "ak47_reload",
        mult = 1,
        sounds = {
            { sound = "arccw_go/ak47/ak47_clipout.wav", time = 0.2 },
            { sound = "arccw_go/ak47/ak47_clipin.wav", time = 1.0 },
        }
    }
}

SWEP.Primary.Automatic = true
SWEP.PrimaryDelay = 0.09--]]

function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
    KB_DrawWeaponSelection(self, x, y, wide, tall, alpha)
end

include("sh_worldmodel.lua")
include("sh_firing.lua")

function SWEP:Deploy()
    self:PlayAnimation("idle")
    return true
end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()

    if self:Clip1() <= 0 then
        self:EmitSound("Weapon_Pistol.Empty")
        self:SetNextPrimaryFire(CurTime() + 0.2)
        return
    end
    
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

function SWEP:Reload()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if self:Clip1() >= self.Primary.ClipSize or owner:GetAmmoCount(self.Primary.Ammo) <= 0 then return end
    
    if self:GetNextPrimaryFire() > CurTime() then return end

    self:PlayAnimation("reload")

    self:SetNextPrimaryFire(CurTime() + self.ReloadTime)
    
    timer.Simple(self.ReloadTime * 0.8, function()
        if IsValid(self) and IsValid(owner) and owner:GetActiveWeapon() == self then
            local ammoNeeded = self.Primary.ClipSize - self:Clip1()
            local ammoAvailable = owner:GetAmmoCount(self.Primary.Ammo)
            
            local ammoToLoad = math.min(ammoNeeded, ammoAvailable)
            
            self:SetClip1(self:Clip1() + ammoToLoad)
            owner:RemoveAmmo(ammoToLoad, self.Primary.Ammo)
        end
    end)
end