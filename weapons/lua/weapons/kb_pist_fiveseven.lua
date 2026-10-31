SWEP.Base = "kb_base"

SWEP.PrintName = "Five-Seven"
SWEP.Category = "Weapons - Pistols"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/arccw_go/v_pist_fiveseven.mdl"

SWEP.HoldType = "rpg"

SWEP.Slot = 1

SWEP.Primary.Automatic = false
SWEP.PrimaryDelay = 0.09

SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Ammo = "Pistol"

SWEP.RecoilCamShot = 1.5

SWEP.ReloadTime = 2.0


SWEP.WorldPos = { Pos = Vector(0.00, 0.00, 0.00), Ang = Angle(30.00, 50.00, 90.00) }
SWEP.LWorldPos = { Pos = Vector(-0.38, -3.41, 0.00), Ang = Angle(0.00, 0.00, 0.00) }
SWEP.SightPos = { Pos = Vector(-2.78, -4.92, 0.90), Ang = Angle(0.00, 0.00, 0.00), FOV = 85.00, Speed = 15.00 }


SWEP.IconPos = {
    Pos = Vector(15, 18, 1),
    Ang = Angle(0, -90, -10),
    FOV = 70
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
        anim = "shoot", 
        mult = 1, 
        sounds = {
            { sound = "arccw_go/fiveseven/fiveseven_01.wav", time = 0 },
        }
    },
    ["reload"] = {
        anim = "reload",
        mult = 1,
        sounds = {
            { sound = "arccw_go/fiveseven/fiveseven_clipout.wav", time = 0.2 },
            { sound = "arccw_go/fiveseven/fiveseven_clipin.wav", time = 0.8 },
        }
    }
}