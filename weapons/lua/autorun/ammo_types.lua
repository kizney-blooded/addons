-- Ammo Types Registration
-- Add this to your init.lua or autorun/ammo_types.lua

if SERVER then
    -- Pistol ammo
    AddAmmoType("pistol", nil, nil, "pistol", 0, 0, "bullet_generic")
    
    -- AR2 ammo (for rifles like M4, AK, etc.)
    AddAmmoType("ar2", nil, nil, "ar2", 0, 0, "bullet_generic")
    
    -- Sniper ammo
    AddAmmoType("sniper", nil, nil, "sniper", 0, 0, "bullet_generic")
    
    -- Shotgun ammo
    AddAmmoType("buckshot", nil, nil, "buckshot", 0, 0, "bullet_generic")
    
    -- SMG ammo
    AddAmmoType("smg1", nil, nil, "smg1", 0, 0, "bullet_generic")
    
    -- grenades
    AddAmmoType("grenade", nil, nil, "grenade", 0, 0, "bullet_generic")
    
    -- melee (no ammo consumption)
    AddAmmoType("melee", nil, nil, "melee", 0, 0, "bullet_generic")
end