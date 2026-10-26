ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Обычный Контейнер"
ENT.Category = "Контейнеры"
ENT.Spawnable = true

kb = kb or {}

kb.Item_in_Lootboxes = {
    slots = 5,
    respawn = 290,
    { class = "ent_jack_gmod_ezarmor_eaimbss", chance = 50 },
    { class = "ent_jack_gmod_ezarmor_rbavaf", chance = 50 },
    { class = "ent_jack_gmod_ezarmor_dufflebag", chance = 50 },
    { class = "ent_jack_gmod_ezarmor_gruppa99t30m", chance = 60},
    { class = "ent_jack_gmod_ezarmor_gruppa99t30b", chance = 60},
    { class = "ent_jack_gmod_ezarmor_deathknight", chance = 60},
    { class = "ent_jack_gmod_ezarmor_weldingkill", chance = 60},
    { class = "ent_jack_gmod_ezarmor_faceless", chance = 60},
    { class = "ent_jack_gmod_ezarmor_hockeybrawler", chance = 60},
    { class = "ent_jack_gmod_ezarmor_spookyskull", chance = 60},
    { class = "food_apple", chance = 30},
    { class = "food_burger", chance = 30},
    { class = "food_lays", chance = 30},


}

ENT.BoxModel = "models/sarma_crates/static_crate_40.mdl"
ENT.BoxSkin = 0
--ENT.LootTable = kb.Item_in_Lootboxes