kb = kb or {}

kb.RarityColors = {
    [1] = Color(148,148,148),
    [2] = Color(51,255,0),
    [3] = Color(62,200,255),
    [4] = Color(140,0,255),
    [5] = Color(255,0,0),
    [6] = Color(255,238,0),
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
    elseif string.StartWith(class, "ent_jack_") then
        rarity = 3
    elseif string.StartWith(class, "kb_") then
        rarity = 4
    end

    return kb.RarityColors[rarity] or kb.RarityColors[1]
end

function kb.GetSoundClaimOrPut(class)
    if string.StartWith(class, "kb_") then
        local claim_sound = "physics/weapon_impact_soft" .. math.random(1,3) .. ".wav" 
        local put_sound = "physics/weapon_impact_hard" .. math.random(1,3) .. ".wav" 
        
        return claim_sound, put_sound
    end

    if string.StartWith(class, "food_") then
        local claim_sound = "plastic/plastic_box_impact_soft" .. math.random(1,3) .. ".wav" 
        local put_sound = "plastic/plastic_box_impact_soft" .. math.random(1,3) .. ".wav" 
        
        return claim_sound, put_sound
    end
    
    local default_claim = "plastic/plastic_box_impact_soft" .. math.random(1,3) .. ".wav" 
    local default_put = "plastic/plastic_box_impact_soft" .. math.random(1,3) .. ".wav" 
    
    return default_claim, default_put
end