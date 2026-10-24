AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ent_lootboxes"
ENT.PrintName = "Хранилище"
ENT.Category = "Констракт"
ENT.Spawnable = true

ENT.IsStorage = true

ENT.BoxModel = "models/sarma_crates/static_crate_40.mdl"
ENT.BoxSkin = 0


if not SERVER then return end
function ENT:Initialize()
    self:SetModel(self.BoxModel)
    self:SetSkin(self.BoxSkin)
    
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    self.Inventory = {}
    
    for i = 1, 16 do
        table.insert(self.Inventory, { class = "", claimed = true })
    end

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end