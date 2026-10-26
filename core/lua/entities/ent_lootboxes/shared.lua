ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Обычный Контейнер"
ENT.Category = "Контейнеры"
ENT.Spawnable = true

kb = kb or {}

kb.Item_in_Lootboxes = {
    slots = 5,
    respawn = 290,
    { class = "kb_rif_ak47", chance = 50 },
    { class = "kb_pist_fiveseven", chance = 50 },
    { class = "weapon_frag", chance = 5 },
    { class = "ent_jack_gmod_ezarmor_eaimbss", chance = 60},
}

ENT.BoxModel = "models/sarma_crates/static_crate_40.mdl"
ENT.BoxSkin = 0
ENT.LootTable = kb.Item_in_Lootboxes