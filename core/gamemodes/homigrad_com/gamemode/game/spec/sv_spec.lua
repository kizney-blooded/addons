hook.Add("PlayerInitialSpawn","GoToSpectate",function(ply,bool)
    if IsValid(ply) then

        ply.PreferredSpecMode = OBS_MODE_ROAMING
        if kb.RD.state != 1 and kb.RD.current_round != "constract" then
            timer.Simple(0.1,function()
                ply:KillSilent()
                ply:Spectate(ply.PreferredSpecMode)
            end)
        end
    end
end)

hook.Add("PlayerDeath","Specatate",function(ply,inf,att)
    if IsValid(ply) then
        ply.PreferredSpecMode = ply.PreferredSpecMode or OBS_MODE_ROAMING
        
        timer.Simple(0,function()
            if IsValid(ply) then
                ply:Spectate(ply.PreferredSpecMode)
            end
        end)
    end
end)

hook.Add("PlayerButtonDown", "ToggleSpecModeOnR", function(ply, button)
    if not ply:Alive() and button == KEY_R then
        ply.PreferredSpecMode = ply.PreferredSpecMode or OBS_MODE_ROAMING
        
        if ply.PreferredSpecMode == OBS_MODE_ROAMING then
            ply.PreferredSpecMode = OBS_MODE_CHASE
        else
            ply.PreferredSpecMode = OBS_MODE_ROAMING
        end
        
        ply:Spectate(ply.PreferredSpecMode)
    end
end)

-- construct
hook.Add("PlayerDeath", "CustomRespawn_Death", function(victim, inflictor, attacker)
    if kb.RD.current_round == "constract" then 
        if kb.RD.disable_respawn_time and CurTime() >= kb.RD.disable_respawn_time then
            victim:SetNWFloat("RespawnTime", 0)
            victim.NextRespawnTime = nil
            return
        end

        if victim:Team() != 1002 then
            local respawnTime = CurTime() + 30
            victim:SetNWFloat("RespawnTime", respawnTime) 
            victim.NextRespawnTime = respawnTime
        end
    end
end)

hook.Add("PlayerDeathThink", "CustomRespawn_Think", function(ply)
    if kb.RD.current_round == "constract" then

        if ply:Team() == 1002 then
            ply.NextRespawnTime = nil
            ply:SetNWFloat("RespawnTime", 0)
        end 

        if kb.RD.disable_respawn_time and CurTime() >= kb.RD.disable_respawn_time then
            if ply.NextRespawnTime then
                ply.NextRespawnTime = nil
                ply:SetNWFloat("RespawnTime", 0)
            end
            return false
        end

        if ply.NextRespawnTime and CurTime() >= ply.NextRespawnTime then
            --spawn_construct_player(ply)
            ply:Spawn()
            ply.NextRespawnTime = nil
            return true
        end
    end
    
    return false 
end)


local function GetNextAlivePlayer(spectator, direction)
    local alivePlayers = {}
    
    for _, v in ipairs(player.GetAll()) do
        if v:Alive() and v != spectator then
            table.insert(alivePlayers, v)
        end
    end

    if #alivePlayers == 0 then return nil end

    local currentTarget = spectator:GetObserverTarget()
    local currentIndex = 0

    if IsValid(currentTarget) then
        for i, v in ipairs(alivePlayers) do
            if v == currentTarget then
                currentIndex = i
                break
            end
        end
    end

    local nextIndex = currentIndex + direction
    
    if nextIndex > #alivePlayers then 
        nextIndex = 1 
    elseif nextIndex < 1 then 
        nextIndex = #alivePlayers 
    end

    return alivePlayers[nextIndex]
end

hook.Add("PlayerButtonDown", "SpectatorSwitchTarget", function(ply, button)
    if not ply:Alive() and ply:GetObserverMode() == OBS_MODE_CHASE then
        
        if button == MOUSE_LEFT then
            local target = GetNextAlivePlayer(ply, 1)
            if IsValid(target) then
                ply:SpectateEntity(target)
            end
            
        elseif button == MOUSE_RIGHT then
            local target = GetNextAlivePlayer(ply, -1)
            if IsValid(target) then
                ply:SpectateEntity(target)
            end
        end
        
    end
end)