hook.Add("SetupMove", "Stamina_Organism", function(ply, mv, cmd)
    local walkSpeed = 115
    local runSpeed = 300
    local jumpPower = 200

    local wep = ply:GetActiveWeapon()
    local isAiming = false
    
    if IsValid(wep) and (wep.SightPos or wep.ForceAim) then
        isAiming = mv:KeyDown(IN_ATTACK2) or wep.ForceAim
    end

    if isAiming then
        walkSpeed = 65
    end

    ply:SetWalkSpeed(walkSpeed)
    ply:SetRunSpeed(runSpeed)
    ply:SetJumpPower(jumpPower)
end)