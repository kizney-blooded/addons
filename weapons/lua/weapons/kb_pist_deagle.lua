SWEP.Base = "kb_base"

SWEP.PrintName = "Deagle"
SWEP.Category = "Weapons - Pistols"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/arccw_go/v_pist_deagle.mdl"

SWEP.HoldType = "rpg"

SWEP.Slot = 1

SWEP.Primary.Automatic = false
SWEP.PrimaryDelay = 0.3

SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Ammo = "ar2"

SWEP.RecoilCamShot = 5

SWEP.ReloadTime = 2


SWEP.WorldPos = { Pos = Vector(0.00, 0.00, 0.00), Ang = Angle(30.00, 50.00, 90.00) }
SWEP.LWorldPos = { Pos = Vector(-0.38, -3.41, 0.00), Ang = Angle(0.00, 0.00, 0.00) }
SWEP.SightPos = { Pos = Vector(-3.78, -5.68, 0.58), Ang = Angle(0.00, -0.15, 0.00), FOV = 85.00, Speed = 4.00 }



SWEP.IconPos = {
    Pos = Vector(15, 18, 0),
    Ang = Angle(0, -90, -10),
    FOV = 90
}

SWEP.Animations = {
    ["idle"] = {
        anim = "ready", 
        mult = 1, 
        sounds = {
            { sound = "ttt/holster.wav", time = 0.5 },
            { sound = "ttt/draw.wav", time = 1 },
        }
    },
    ["fire"] = {
        anim = "shoot1", 
        mult = 1, 
        sounds = {
            { sound = "arccw_go/deagle/deagle-1.wav", time = 0 },
        }
    },
    ["reload"] = {
        anim = "reload",
        mult = 0.8,
        sounds = {
            { sound = "arccw_go/deagle/de_clipout.wav", time = 0.2 },
            { sound = "arccw_go/deagle/de_clipin.wav", time = 0.8 },
        }
    }
}