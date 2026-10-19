AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("KB_OpenLootBox")

function ENT:Initialize()
    self:SetModel("models/sarma_crates/static_crate_40.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    self.Inventory = {}
    
    local total_chance = 0
    for _, item in ipairs(kb.Item_in_Lootboxes) do
        total_chance = total_chance + item.chance
    end

    for i = 1, 3 do
        local random_val = math.random(1, total_chance)
        local current_sum = 0
        local selected_class = ""

        for _, item in ipairs(kb.Item_in_Lootboxes) do
            current_sum = current_sum + item.chance
            if random_val <= current_sum then
                selected_class = item.class
                break
            end
        end

        table.insert(self.Inventory, { class = selected_class })
    end

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if (self.NextUse or 0) > CurTime() then return end
    self.NextUse = CurTime() + 0.1

    activator:EmitSound("kb/ui/open_box.wav")

    net.Start("KB_OpenLootBox")
        net.WriteEntity(self)
        net.WriteTable(self.Inventory)
    net.Send(activator)
end