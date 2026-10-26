AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ent_lootboxes"
ENT.PrintName = "Контейнер с ближнем оружием"
ENT.Category = "Контейнеры"
ENT.Spawnable = true

kb = kb or {}

kb.Melee_in_Lootboxes = {
    slots = 2,
    respawn = 290,
    { class = "weapon_hg_crowbar", chance = 50 },
    { class = "weapon_hg_fireaxe", chance = 40 },
    { class = "weapon_hg_fubar", chance = 40 },
    { class = "weapon_hg_hatchet", chance = 40 },
    { class = "weapon_hg_kitknife", chance = 40 },
    { class = "weapon_hg_metalbat", chance = 40 },
    { class = "weapon_hg_metalpipe", chance = 40 },
    { class = "weapon_hg_shovel", chance = 40 },
    { class = "weapon_hg_wrench", chance = 40 },
}

ENT.BoxModel = "models/sarma_crates/static_crate_40.mdl"
ENT.BoxSkin = 3
ENT.LootTable = kb.Melee_in_Lootboxes
