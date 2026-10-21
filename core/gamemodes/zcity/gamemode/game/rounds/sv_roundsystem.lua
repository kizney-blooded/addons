util.AddNetworkString("kb_data")

local player_count

local function Check_Round_State()
    player_count = player.GetCount()

    print(player_count)

    if player_count <= 1 and kb.RD.state != 0 then
        kb.RD.state = 0
    elseif player_count >= 2 then
        EndRoundSV()
    end

    kb_data()
end

hook.Add("PlayerInitialSpawn","JoinPlayer",function(ply,bool)

    if IsValid(ply) then
        kb_data(ply)

        Check_Round_State()
    end
end)

hook.Add("PlayerDisconnected","LeftPlayer",function(ply)
    timer.Simple(0.1,function()
        Check_Round_State()
    end)
end)

function StartRoundSV()
    if kb.RD.state == 1 then return end
    kb.RD.state = 1
    kb.RD.winner = nil

    if kb.RD.next_round then
        kb.RD.current_round = kb.RD.next_round
    else
        kb.RD.current_round = table.Random(kb.LevelList)
    end

    _G[kb.RD.current_round].StartRound()

    local round_duration = _G[kb.RD.current_round].RoundTime or 300
    kb.RD.time_round = CurTime() + round_duration

    kb.RD.next_round = table.Random(kb.LevelList)

    PrintMessage(3, "Текущий режим - " .. _G[kb.RD.current_round].Name or kb.RD.current_round)
    PrintMessage(3, "Следующий режим - " .. _G[kb.RD.next_round].Name or kb.RD.next_round)

    kb_data()
end

function EndRoundSV(winner)
    if kb.RD.state == 2 then return end
    kb.RD.state = 2
    kb.RD.winner = winner or "Неизвестный"

    PrintMessage(3, "Раунд закончен.")
    PrintMessage(3, "Победили - " .. kb.RD.winner)

    timer.Simple(3,function()
        if kb.RD.next_round then
            PrintMessage(3, "Загружаем режим - " .. _G[kb.RD.next_round].Name or kb.RD.next_round)
        end
    end)

    timer.Simple(6,function()
        player_count = player.GetCount()

        if player_count >= 2 then
            StartRoundSV()
        else
            Check_Round_State()
        end

    end)

    kb_data()
end

local function LogicRoundSV()
    if kb.RD.state != 1 then return end

    if kb.RD.time_round and CurTime() >= kb.RD.time_round then
        EndRoundSV("Время вышло")
        return
    end

    --if current_round and _G[current_round].LogicRound() then
        _G[kb.RD.current_round].LogicRound()
    --end
end

hook.Add("Think","Logic", LogicRoundSV)