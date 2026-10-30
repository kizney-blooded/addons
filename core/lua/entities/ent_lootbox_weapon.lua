AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ent_lootboxes"
ENT.PrintName = "Контейнер с оружием"
ENT.Category = "Контейнеры"
ENT.Spawnable = true

kb = kb or {}

kb.Weapon_in_Lootboxes = {
    slots = 2,
    respawn = 390,
    { class = "ent_jack_gmod_ezammo", chance = 50 },
    { class = "kb_pist_deagle", chance = 30 },

    { class = "kb_pist_fiveseven", chance = 30 },
    { class = "kb_pist_glock17", chance = 30 },
    { class = "kb_rif_ak47", chance = 20 },
    { class = "kb_rif_m4a1", chance = 20 },
    { class = "kb_smg_mp7", chance = 20 },
}

ENT.BoxModel = "models/kali/props/cases/rifle case b.mdl"
ENT.BoxSkin = 0
ENT.LootTable = kb.Weapon_in_Lootboxes
