hook.Add("SetupMove", "Stamina_Organism", function(ply, mv, cmd)
    local walkSpeed = 115
    local runSpeed = 300
    local jumpPower = 200

    local wep = ply:GetActiveWeapon()
    
    local isAiming = mv:KeyDown(IN_ATTACK2)
    
    if IsValid(wep) and wep.ForceAim then
        isAiming = true
    end

    if isAiming and IsValid(wep) then
        walkSpeed = 65
        runSpeed = 65
    end

    ply:SetWalkSpeed(walkSpeed)
    ply:SetRunSpeed(runSpeed)
    ply:SetJumpPower(jumpPower)

    if isAiming then
        mv:SetMaxClientSpeed(walkSpeed)
    end
end)