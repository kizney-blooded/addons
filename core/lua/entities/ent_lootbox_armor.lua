AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ent_lootboxes"
ENT.PrintName = "Контейнер с броней"
ENT.Category = "Контейнеры"
ENT.Spawnable = true

kb = kb or {}

kb.Weapon_in_Lootboxes = {
    slots = 2,
    respawn = 390,
    { class = "ent_jack_gmod_ezarmor_maska", chance = 20 },
    { class = "ent_jack_gmod_ezarmor_balmask", chance = 40 },
    { class = "ent_jack_gmod_ezarmor_slcalf", chance = 40 },
    { class = "ent_jack_gmod_ezarmor_srcalf", chance = 40 },
    { class = "ent_jack_gmod_ezarmor_slforearm", chance = 40 },
    { class = "ent_jack_gmod_ezarmor_srforearm", chance = 40 },
    { class = "ent_jack_gmod_ezarmor_mhtorso", chance = 20 },
    { class = "ent_jack_gmod_ezarmor_llthigh", chance = 40 },
    { class = "ent_jack_gmod_ezarmor_lrthigh", chance = 40 },
    { class = "ent_jack_gmod_ezarmor_hlshoulder", chance = 40 },
    { class = "ent_jack_gmod_ezarmor_hrshoulder", chance = 40 },
    { class = "weapon_hg_sleagehammer", chance = 20 },

}

ENT.BoxModel = "models/sarma_crates/static_crate_48.mdl"
ENT.BoxSkin = 0
ENT.LootTable = kb.Weapon_in_Lootboxes
