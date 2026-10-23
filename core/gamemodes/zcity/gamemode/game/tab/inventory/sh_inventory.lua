kb = kb or {}

kb.RarityColors = {
    [1] = Color(148,148,148),
    [2] = Color(51,255,0),
    [3] = Color(140,0,255),
    [4] = Color(255,0,0),
    [5] = Color(255,238,0),
}

kb.RarityItems = {
    ["weapon_pistol"] = 5,
}

function kb.GetItemRarityColor(class)
    local rarity = 1

    if kb.RarityItems[class] then
        rarity = kb.RarityItems[class]
    elseif string.StartWith(class, "food_") then
        rarity = 2
    elseif string.StartWith(class, "kb_") then
        rarity = 3
    end

    return kb.RarityColors[rarity] or kb.RarityColors[1]
end