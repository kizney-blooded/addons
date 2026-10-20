ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Обычный Контейнер"
ENT.Category = "Контейнеры"
ENT.Spawnable = true

kb = kb or {}

kb.Item_in_Lootboxes = {
    slots = 5,
    { class = "kb_rif_ak47", chance = 50 },
    { class = "kb_pist_fiveseven", chance = 50 },
    { class = "weapon_frag", chance = 5 }
}