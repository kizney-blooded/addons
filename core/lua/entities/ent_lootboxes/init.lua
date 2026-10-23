AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("KB_OpenLootBox")

function ENT:Initialize()
    self:SetModel(self.BoxModel or "models/sarma_crates/static_crate_40.mdl")
    self:SetSkin(self.BoxSkin or 0)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    self.Inventory = {}
    
    local my_loot = self.LootTable or kb.Item_in_Lootboxes
    
    local total_chance = 0
    for _, item in ipairs(my_loot) do
        total_chance = total_chance + item.chance
    end

    local slots_count = my_loot.slots or 3
    
    for i = 1, slots_count do
        local random_val = math.random(1, total_chance)
        local current_sum = 0
        local selected_class = ""

        for _, item in ipairs(my_loot) do
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