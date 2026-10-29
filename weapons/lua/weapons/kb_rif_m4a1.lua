SWEP.Base = "kb_base"

SWEP.PrintName = "M4A1"
SWEP.Category = "Weapons - Secondary"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/arccw_go/v_rif_m4a1.mdl"

SWEP.HoldType = "rpg"

SWEP.Slot = 2

SWEP.Primary.Automatic = true
SWEP.PrimaryDelay = 0.09

SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Ammo = "AR2"

SWEP.RecoilCamShot = 1.5

SWEP.ReloadTime = 2.3

SWEP.IsRifle = true


SWEP.WorldPos = { Pos = Vector(0.00, 0.00, 0.00), Ang = Angle(30.00, 50.00, 90.00) }
SWEP.LWorldPos = { Pos = Vector(-1.14, -8.71, 0.00), Ang = Angle(0.00, 0.00, 0.00) }
SWEP.SightPos = { Pos = Vector(-5.16, -9.47, 0.70), Ang = Angle(0.00, 0.00, 0.68), FOV = 85.00, Speed = 4.00 }


SWEP.IconPos = {
    Pos = Vector(15, 16, -2),
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
        anim = "shoot2", 
        mult = 1, 
        sounds = {
            { sound = "arccw_go/m4a1/m4a1_01.wav", time = 0 },
            { sound = "arccw_go/m4a1/m4a1_02.wav", time = 0 },
        }
    },
    ["reload"] = {
        anim = "reload",
        mult = 1.2,
        sounds = {
            { sound = "arccw_go/m4a1/m4a1_clipout.wav", time = 0.2 },
            { sound = "arccw_go/m4a1/m4a1_clipin.wav", time = 1.0 },
        }
    }
}