constract.RoundTime = 120

function constract.StartRound()
    kb.RD.disable_respawn_time = CurTime() + 60
    for _ , ply in player.Iterator() do
        ply:Spawn()

        --ply:SetTeam(1)

        ply:SetPlayerColor(Vector(math.random(1,255)/255,math.random(1,255)/255,math.random(1,255)/255))
    end
end

function constract.LogicRound()
    --[[local alives = 0
    for _ , ply in player.Iterator() do
        if IsValid(ply) and ply:Alive() then
            alives = alives + 1
        end
    end

    if alives == 1 then 
        EndRoundSV("Выживший")
    end--]]
end