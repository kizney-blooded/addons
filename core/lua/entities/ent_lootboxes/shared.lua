ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Обычный Контейнер"
ENT.Category = "Контейнеры"
ENT.Spawnable = true

kb = kb or {}

kb.Item_in_Lootboxes = {
    slots = 5,
    respawn = 290,

    { class = "ent_jack_gmod_ezarmor_eaimbss", chance = 5 },
    { class = "ent_jack_gmod_ezarmor_rbavaf", chance = 8 },
    { class = "ent_jack_gmod_ezarmor_dufflebag", chance = 20 },
    { class = "ent_jack_gmod_ezarmor_gruppa99t30m", chance = 12 },
    { class = "ent_jack_gmod_ezarmor_gruppa99t30b", chance = 12 },
    
    { class = "ent_jack_gmod_ezarmor_deathknight", chance = 10 },
    { class = "ent_jack_gmod_ezarmor_weldingkill", chance = 15 },
    { class = "ent_jack_gmod_ezarmor_faceless", chance = 10 },
    { class = "ent_jack_gmod_ezarmor_hockeybrawler", chance = 15 },
    { class = "ent_jack_gmod_ezarmor_spookyskull", chance = 10 },
    
    { class = "food_apple", chance = 45 },
    { class = "food_lays", chance = 35 },
    { class = "food_sok", chance = 35 },
    { class = "food_milk", chance = 30 },
    { class = "food_burger", chance = 20 },

    { class = "weapon_hg_metalpipe", chance = 35 },
    { class = "weapon_hg_wrench", chance = 30 },
    { class = "weapon_hg_crowbar", chance = 25 },
    { class = "weapon_hg_shovel", chance = 25 },
    { class = "weapon_hg_kitknife", chance = 25 },
    { class = "weapon_hg_hatchet", chance = 20 },
    { class = "weapon_hg_metalbat", chance = 15 },
    { class = "weapon_hg_fireaxe", chance = 10 },
    { class = "weapon_hg_fubar", chance = 10 },


}

ENT.BoxModel = "models/sarma_crates/static_crate_40.mdl"
ENT.BoxSkin = 0
--ENT.LootTable = kb.Item_in_Lootboxes