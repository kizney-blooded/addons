hook.Add("PlayerInitialSpawn","GoToSpectate",function(ply,bool)
    if IsValid(ply) then

        ply.PreferredSpecMode = OBS_MODE_ROAMING

        timer.Simple(0.1,function()
            ply:KillSilent()
            ply:Spectate(ply.PreferredSpecMode)
        end)
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

        local respawnTime = CurTime() + 30
        victim:SetNWFloat("RespawnTime", respawnTime) 
        victim.NextRespawnTime = respawnTime
    end
end)

hook.Add("PlayerDeathThink", "CustomRespawn_Think", function(ply)
    if kb.RD.current_round == "constract" then 
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