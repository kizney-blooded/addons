hook.Add("PlayerInitialSpawn","GoToSpectate",function(ply,bool)
    if IsValid(ply) then
        timer.Simple(0.1,function()
            ply:KillSilent()
            ply:Spectate(OBS_MODE_ROAMING)
        end)
    end
end)

hook.Add("PlayerDeath","Specatate",function(ply,inf,att)
    if IsValid(ply) then
        timer.Simple(0,function()
            ply:Spectate(OBS_MODE_ROAMING)
        end)
    end
end)

hook.Add("PlayerDeathThink","DisablePlayerDeathThink",function(ply)
    return false
end)