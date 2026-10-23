AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ent_lootboxes"
ENT.PrintName = "Контейнер с едой"
ENT.Category = "Контейнеры"
ENT.Spawnable = true

kb = kb or {}

kb.Food_in_Lootboxes = {
    slots = 3,
    { class = "item_water", chance = 50 },
    { class = "item_bread", chance = 40 },
    { class = "item_canned_food", chance = 10 }
}

ENT.BoxModel = "models/sarma_crates/static_crate_40.mdl"
ENT.BoxSkin = 2
ENT.LootTable = kb.Food_in_Lootboxes
