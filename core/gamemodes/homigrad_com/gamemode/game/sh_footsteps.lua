if SERVER then AddCSLuaFile() end

local basePath = "kb/footsteps/"

local footstepSounds = {
    [MAT_CONCRETE] = {prefix = "concrete_ct_", count = 17},
    [MAT_DIRT]     = {prefix = "dirt_", count = 14},
    [MAT_WOOD]     = {prefix = "wood_", count = 15},
    [MAT_GRASS]    = {prefix = "grass_", count = 13},
    [MAT_GLASS]    = {prefix = "glass_", count = 13},
    [MAT_GRATE]    = {prefix = "metal_grate_", count = 15},
    [MAT_METAL]    = {prefix = "metal_solid_", count = 50},
    [MAT_SAND]     = {prefix = "sand_", count = 12},
    [MAT_SNOW]     = {prefix = "snow_", count = 12},
    [MAT_TILE]     = {prefix = "tile_", count = 14},
    [MAT_SLOSH]    = {prefix = "mud_", count = 9}
}

hook.Add("PlayerFootstep", "Custom_CSGO_Footsteps", function(ply, pos, foot, sound, volume, rf)
    local tr = util.TraceLine({
        start = pos,
        endpos = pos - Vector(0, 0, 10),
        filter = ply
    })

    local mat = tr.MatType
    local soundData = footstepSounds[mat] or footstepSounds[MAT_CONCRETE]

    local randNum = math.random(1, soundData.count)
    local numStr = string.format("%02d", randNum)
    
    local customSound = basePath .. soundData.prefix .. numStr .. ".wav"

    if SERVER then
        ply:EmitSound(customSound, 75, math.random(95, 105), volume)
    end

    return true
end)

local landSounds = {
    [MAT_CONCRETE] = {prefix = "land_concrete_", count = 1},
    [MAT_DIRT]     = {prefix = "land_dirt_", count = 5},
    [MAT_WOOD]     = {prefix = "land_wood_", count = 3},
    [MAT_GRASS]    = {prefix = "land_grass_", count = 5},
    [MAT_METAL]    = {prefix = "land_metal_solid_", count = 6},
    [MAT_SAND]     = {prefix = "land_sand_", count = 6},
    [MAT_SNOW]     = {prefix = "land_snow_", count = 6},
    [MAT_TILE]     = {prefix = "land_tile_", count = 5}
}

hook.Add("OnPlayerHitGround", "Custom_CSGO_Landing", function(ply, inWater, onFloater, speed)
    if inWater or speed < 150 then return end

    local tr = util.TraceLine({
        start = ply:GetPos(),
        endpos = ply:GetPos() - Vector(0, 0, 20),
        filter = ply
    })

    local mat = tr.MatType
    local soundData = landSounds[mat] or landSounds[MAT_CONCRETE]

    local randNum = math.random(1, soundData.count)
    local numStr = string.format("%02d", randNum)
    local customSound = basePath .. soundData.prefix .. numStr .. ".wav"

    local volume = math.Clamp(speed / 500, 0.5, 1)
    
    if SERVER then
        ply:EmitSound(customSound, 75, math.random(95, 105), volume)
    end
    
    return true
end)