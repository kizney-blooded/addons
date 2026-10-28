AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ent_lootboxes"
ENT.PrintName = "Шкаф"
ENT.Category = "Констракт"
ENT.Spawnable = true

ENT.IsStorage = true

ENT.IsZona = true
ENT.RadiusZona = 450

ENT.BoxModel = "models/props_c17/FurnitureDresser001a.mdl"
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
    
    for i = 1, 4 do
        table.insert(self.Inventory, { class = "", claimed = true })
    end

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end