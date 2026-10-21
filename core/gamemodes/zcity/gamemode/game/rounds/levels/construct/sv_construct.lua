function constract.StartRound()
    kb.RD.time_round = CurTime() + 4500
    for _ , ply in player.Iterator() do
        ply:Spawn()

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