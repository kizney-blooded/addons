function hmcd.StartRound()
    for _ , ply in player.Iterator() do
        ply:Spawn()
    end
end

function hmcd.LogicRound()
    local alives = 0
    for _ , ply in player.Iterator() do
        if IsValid(ply) and ply:Alive() then
            alives = alives + 1
        end
    end

    if alives == 1 then 
        EndRoundSV("Живые")
    end
end