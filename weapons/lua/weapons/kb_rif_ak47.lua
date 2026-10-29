SWEP.Base = "kb_base"

SWEP.PrintName = "AK-47"
SWEP.Category = "Weapons - Secondary"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/arccw_go/v_rif_ak47.mdl"

SWEP.HoldType = "rpg"

SWEP.Slot = 2

SWEP.Primary.Automatic = true
SWEP.PrimaryDelay = 0.09

SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Ammo = "AR2"

SWEP.RecoilCamShot = 1.5

SWEP.ReloadTime = 2.0

SWEP.IsRifle = true


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
        anim = "ak47_ready", 
        mult = 1, 
        sounds = {
            { sound = "arccw_go/ak47/ak47_draw.wav", time = 0 },
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