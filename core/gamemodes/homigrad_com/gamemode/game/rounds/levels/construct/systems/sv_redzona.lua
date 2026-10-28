util.AddNetworkString("red_zona_data")

local red_zona = {
    state = false,
    center = Vector(0,0,0),
    initial_radius = 3000,
    target_radius = 100,
    speed = 15,
    start_time = 0
}

concommand.Add("startzona", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    if IsValid(ply) then
        red_zona.center = ply:GetPos()
    else
        red_zona.center = Vector(0,0,0)
    end

    red_zona.initial_radius = 3000
    red_zona.state = true
    red_zona.start_time = CurTime()

    net.Start("red_zona_data")
        net.WriteBool(red_zona.state)
        net.WriteVector(red_zona.center)
        net.WriteFloat(red_zona.initial_radius)
        net.WriteFloat(red_zona.target_radius)
        net.WriteFloat(red_zona.speed)
    net.Broadcast()

    PrintMessage(HUD_PRINTTALK, "Красная зона запущена")
end)

function create_redzona()
    if not KB_SPAWNPOINTS or not KB_SPAWNPOINTS.redzona or #KB_SPAWNPOINTS.redzona == 0 then
        return 
    end

    local zoneData = KB_SPAWNPOINTS.redzona[1]

    red_zona.center = zoneData.pos
    red_zona.initial_radius = zoneData.radius
    red_zona.state = true
    red_zona.start_time = CurTime()

    net.Start("red_zona_data")
        net.WriteBool(red_zona.state)
        net.WriteVector(red_zona.center)
        net.WriteFloat(red_zona.initial_radius)
        net.WriteFloat(red_zona.target_radius)
        net.WriteFloat(red_zona.speed)
    net.Broadcast()

    PrintMessage(HUD_PRINTTALK, "Красная зона запущена! Бегите в центр.")
end

function remove_redzona()
    if not red_zona.state then return end

    red_zona.state = false 

    net.Start("red_zona_data")
        net.WriteBool(red_zona.state) 
    net.Broadcast()
end

hook.Add("PlayerInitialSpawn", "RedZona_Sync_NewPlayers", function(ply)
    if red_zona.state then
        local time_passed = CurTime() - red_zona.start_time
        local current_radius = math.max(red_zona.target_radius, red_zona.initial_radius - (red_zona.speed * time_passed))
        
        net.Start("red_zona_data")
            net.WriteBool(red_zona.state)
            net.WriteVector(red_zona.center)
            net.WriteFloat(current_radius)
            net.WriteFloat(red_zona.target_radius)
            net.WriteFloat(red_zona.speed)
        net.Send(ply)
    end
end)

timer.Create("RedZona_DamageLogic", 1, 0, function()
    if not red_zona.state then return end

    local time_passed = CurTime() - red_zona.start_time
    local current_radius = math.max(red_zona.target_radius, red_zona.initial_radius - (red_zona.speed * time_passed))

    for _, ply in player.Iterator() do
        if ply:Alive() then
            local dist = ply:GetPos():Distance(red_zona.center)
            
            if dist > current_radius then
                local diff = dist - current_radius
                
                local damageAmount = math.max(5, math.floor(diff / 50))
                
                local dinfo = DamageInfo()
                dinfo:SetDamage(damageAmount)
                dinfo:SetDamageType(DMG_RADIATION)
                dinfo:SetAttacker(game.GetWorld())
                dinfo:SetInflictor(game.GetWorld())
                
                ply:TakeDamageInfo(dinfo)
            end
        end
    end
end)