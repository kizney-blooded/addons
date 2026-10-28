SWEP.Base = "weapon_base"

SWEP.PrintName = "Food Base"
SWEP.Category = "Weapons - Food"

SWEP.Spawnable = false
SWEP.AdminOnly = false

SWEP.HoldType = "slam"

SWEP.WorldModel = "models/foodnhouseholditems/chipslays5.mdl"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"

--SWEP.CroshkaColor = Color(255, 200, 100)

--[[SWEP.IconPos = { Pos = Vector(8.16, 0.00, -3.00), Ang = Angle(90.00, 78.37, -97.96), FOV = 130.00 }

SWEP.WMPos = Vector(5, 2, 0) 
SWEP.WMAng = Angle(90, -45, 90)

SWEP.TargetArmAngle = Angle(0, -60, -40) 
SWEP.LerpSpeed = 10

SWEP.Primary.ClipSize       = 3
SWEP.Primary.DefaultClip    = 3
SWEP.Primary.Automatic      = true
SWEP.Primary.Ammo           = "none"

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"

SWEP.SoundUse = {
    "kb/eat1.wav",
    "kb/eat2.wav",
    "kb/eat3.wav",
}--]]

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "IsEating")
end

function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
    KB_DrawWeaponSelection(self, x, y, wide, tall, alpha)
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    if CLIENT then
        self.CurrentArmAngle = Angle(0, 0, 0)
    end
end

function SWEP:PrimaryAttack()
    if self:Clip1() <= 0 then
        self:SetNextPrimaryFire(CurTime() + 0.2)
        return
    end

    self:SetNextPrimaryFire(CurTime() + 1)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self:TakePrimaryAmmo(1)

    if SERVER then
        local maxHP = owner:GetMaxHealth()
        local currentHP = owner:Health()
        owner:SetHealth(math.min(currentHP + 25, maxHP))
    end

    if self.SoundUse and #self.SoundUse > 0 then
        local randomSound = self.SoundUse[math.random(#self.SoundUse)]
        self:EmitSound(randomSound)
    end

    if IsFirstTimePredicted() then
        local pitch = math.Rand(-5, -2)
        local yaw = math.Rand(-3, 3)
        local roll = math.Rand(-1, 1)
        owner:ViewPunch(Angle(pitch, yaw, roll))
        
        local effectdata = EffectData()
        local pos = owner:GetShootPos() + owner:GetAimVector() * 15
        effectdata:SetOrigin(pos)
        
        local col = self.CroshkaColor or Color(255, 255, 255)
        effectdata:SetStart(Vector(col.r, col.g, col.b))
        
        util.Effect("EatCrumbsEffect", effectdata)
    end

    if SERVER and self:Clip1() <= 0 then
        self:ResetBoneAngles()
        self:Remove()
    end
end

function SWEP:Think()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self:SetIsEating(owner:KeyDown(IN_ATTACK))
end

function SWEP:ResetBoneAngles()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local bone = owner:LookupBone("ValveBiped.Bip01_R_Forearm")
    if bone then
        owner:ManipulateBoneAngles(bone, Angle(0, 0, 0))
    end
    if CLIENT then
        self.CurrentArmAngle = Angle(0, 0, 0)
    end
end

function SWEP:Holster()
    self:ResetBoneAngles()
    return true
end

function SWEP:OnRemove()
    self:ResetBoneAngles()
end

hook.Add("PlayerDeath","RemoveAngles",function(ply,inf,att)
    if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon().ResetBoneAngles then
        ply:GetActiveWeapon():ResetBoneAngles()
    end
end)

function SWEP:DrawWorldModel()
    local owner = self:GetOwner()

    if IsValid(owner) then
        local forearmBone = owner:LookupBone("ValveBiped.Bip01_R_Forearm")
        if forearmBone then
            self.CurrentArmAngle = self.CurrentArmAngle or Angle(0, 0, 0)
            
            local targetAngle = self:GetIsEating() and self.TargetArmAngle or Angle(0, 0, 0)
            self.CurrentArmAngle = LerpAngle(FrameTime() * self.LerpSpeed, self.CurrentArmAngle, targetAngle)
            
            owner:ManipulateBoneAngles(forearmBone, self.CurrentArmAngle)
        end

        local handBone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
        if handBone then
            local matrix = owner:GetBoneMatrix(handBone)
            if matrix then
                local pos = matrix:GetTranslation()
                local ang = matrix:GetAngles()

                pos = pos + ang:Forward() * self.WMPos.x + ang:Right() * self.WMPos.y + ang:Up() * self.WMPos.z

                ang:RotateAroundAxis(ang:Up(), self.WMAng.yaw)
                ang:RotateAroundAxis(ang:Right(), self.WMAng.pitch)
                ang:RotateAroundAxis(ang:Forward(), self.WMAng.roll)

                self:SetRenderOrigin(pos)
                self:SetRenderAngles(ang)
                self:DrawModel()
                return
            end
        end
    end

    self:SetRenderOrigin(nil)
    self:SetRenderAngles(nil)
    self:DrawModel()
end

if CLIENT then
    local EFFECT = {}
    
    function EFFECT:Init(data)
        local pos = data:GetOrigin()
        local color = data:GetStart()
        
        local emitter = ParticleEmitter(pos)
        if not IsValid(emitter) then return end
        
        for i = 1, math.random(3, 5) do
            local part = emitter:Add("particle/particle_smokegrenade", pos + VectorRand() * 2)
            if part then
                part:SetVelocity(Vector(math.Rand(-15, 15), math.Rand(-15, 15), math.Rand(-20, -50)))
                part:SetDieTime(math.Rand(1.5, 3))
                part:SetStartAlpha(255)
                part:SetEndAlpha(255)
                part:SetStartSize(math.Rand(2, 3))
                part:SetEndSize(1)
                part:SetColor(color.x, color.y, color.z)
                part:SetGravity(Vector(0, 0, -250))
                part:SetCollide(true)
                part:SetBounce(0.3)
            end
        end
        
        emitter:Finish()
    end
    
    function EFFECT:Think() return false end
    function EFFECT:Render() end
    
    effects.Register(EFFECT, "EatCrumbsEffect")
end