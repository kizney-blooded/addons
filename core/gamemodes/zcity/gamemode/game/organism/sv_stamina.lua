hook.Add("SetupMove", "Stamina_Organism", function(ply, mv, cmd)
    local hp = ply:Health()
    local walkSpeed, runSpeed, jumpPower
    
    if hp > 60 then
        walkSpeed = 115
        runSpeed = 300
        jumpPower = 200
    elseif hp > 40 then
        walkSpeed = 85
        runSpeed = 250
        jumpPower = 150
    elseif hp > 20 then
        walkSpeed = 55
        runSpeed = 150
        jumpPower = 100
    else
        walkSpeed = 35
        runSpeed = 80
        jumpPower = 60
    end

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