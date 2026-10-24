constract.RoundTime = 10800

function spawn_construct_player(ply)
    --ply:Spawn()

    --ply:SetTeam(1)

    ply:Give("weapon_physgun")
    ply:Give('gmod_tool')

    ply:SetPlayerColor(Vector(math.random(1,255)/255,math.random(1,255)/255,math.random(1,255)/255))
end

function constract.StartRound()
    kb.RD.disable_respawn_time = CurTime() + 8900
    kb.RD.redzona_started = false
    for _ , ply in player.Iterator() do
        ply:Spawn()
        spawn_construct_player(ply)
    end

    spawn_lootboxes()
end

function constract.LogicRound()
    if kb.RD.disable_respawn_time and CurTime() >= kb.RD.disable_respawn_time then
        if not kb.RD.redzona_started then
            kb.RD.redzona_started = true
            create_redzona()
        end

        local alives = 0
        for _ , ply in player.Iterator() do
            if IsValid(ply) and ply:Alive() then
                alives = alives + 1
            end
        end

        if alives == 1 then 
            EndRoundSV("Выживший")
        end
    end
end