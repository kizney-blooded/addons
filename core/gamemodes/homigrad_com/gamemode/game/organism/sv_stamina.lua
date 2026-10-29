hook.Add("PlayerSpawn", "Stamina_Init", function(ply)
    ply.Stamina = 100
    ply.NextStaminaTick = CurTime()
    ply.CurrentRunSpeed = 0
end)

local walkSpeed, runSpeed, jumpPower
local hp

hook.Add("SetupMove", "Stamina_Organism", function(ply, mv, cmd)
    if not ply.Stamina then ply.Stamina = 100 end

    hp = ply:Health()
    
    if hp > 60 then
        walkSpeed = 115
        runSpeed = 350
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

    local isMoving = mv:GetForwardSpeed() ~= 0 or mv:GetSideSpeed() ~= 0
    local isRunning = mv:KeyDown(IN_SPEED) and isMoving and ply:IsOnGround()

    if IsFirstTimePredicted() then
        ply.NextStaminaTick = ply.NextStaminaTick or 0

        if isRunning then
            if CurTime() > ply.NextStaminaTick then
                ply.Stamina = math.max(0, ply.Stamina - 1)
                ply.NextStaminaTick = CurTime() + 0.3
            end
        else
            if CurTime() > ply.NextStaminaTick and ply.Stamina < 100 then
                ply.Stamina = math.min(100, ply.Stamina + 1)
                ply.NextStaminaTick = CurTime() + 0.2
            end
        end
    end

    local staminaMult = math.Clamp(math.Remap(ply.Stamina, 0, 50, 0.1, 1.0), 0.1, 1.0)
    local targetRunSpeed = runSpeed * staminaMult

    ply.CurrentRunSpeed = ply.CurrentRunSpeed or walkSpeed
    local accelRate = 250

    local ft = FrameTime()

    if isRunning then
        ply.CurrentRunSpeed = math.Approach(ply.CurrentRunSpeed, targetRunSpeed, accelRate * ft)
    else
        ply.CurrentRunSpeed = walkSpeed
    end

    ply:SetWalkSpeed(walkSpeed)
    ply:SetRunSpeed(ply.CurrentRunSpeed)
    ply:SetJumpPower(jumpPower)
end)