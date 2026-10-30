hook.Add("CalcMainActivity", "Stamina_RunFastAnimation", function(ply, velocity)
    if not ply:Alive() or ply:InVehicle() or not ply:IsOnGround() or ply:WaterLevel() >= 2 then 
        return 
    end
    if not IsValid(ply:GetActiveWeapon()) then return end
    if ply:GetActiveWeapon():GetHoldType() != "normal" or ply:GetActiveWeapon():GetHoldType() == NULL then return end

    local speed = velocity:Length2D()
    local walkSpeed = ply:GetWalkSpeed()

    if speed > walkSpeed + 30 then
        return ACT_HL2MP_RUN_FAST, -1
    end
end)