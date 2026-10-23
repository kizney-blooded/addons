AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ent_lootboxes"
ENT.PrintName = "Контейнер с едой"
ENT.Category = "Контейнеры"
ENT.Spawnable = true

kb = kb or {}

kb.Food_in_Lootboxes = {
    slots = 3,
    { class = "food_lays", chance = 50 },
    { class = "food_milk", chance = 40 },
    { class = "food_sok", chance = 40 },
    { class = "food_burger", chance = 40 },
    { class = "food_apple", chance = 40 },
}

ENT.BoxModel = "models/sarma_crates/static_crate_40.mdl"
ENT.BoxSkin = 2
ENT.LootTable = kb.Food_in_Lootboxes
