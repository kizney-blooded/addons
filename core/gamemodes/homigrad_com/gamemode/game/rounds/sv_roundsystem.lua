util.AddNetworkString("kb_data")

local player_count

local function Check_Round_State()
    player_count = player.GetCount()

    if player_count <= 1 and kb.RD.state != 0 then
        if kb.RD.next_round != "constract" then
            kb.RD.state = 0
        end
    elseif player_count >= 2 then
        if kb.RD.state == 0 then
            EndRoundSV()
        end
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

function PickRounds()
    local current_map = game.GetMap()

    if string.StartWith(current_map, "de_") or current_map == "rp_truenorth_v1a" or current_map == "rp_downtown_v2_haunted" then
        kb.RD.current_round = "constract"
        kb.RD.next_round = "constract"
    else
        if kb.RD.next_round then
            kb.RD.current_round = kb.RD.next_round
        else
            kb.RD.current_round = table.Random(kb.LevelList)
        end
        
        kb.RD.next_round = table.Random(kb.LevelList)
    end
end

function StartRoundSV()
    game.CleanUpMap(false)
    if kb.RD.state == 1 then return end
    kb.RD.state = 1
    kb.RD.winner = nil

    PickRounds()

    _G[kb.RD.current_round].StartRound()

    RunConsoleCommand("hostname", "KB Server #1 " .. _G[kb.RD.current_round].Name .. " | Быстрый запуск")

    local round_duration = _G[kb.RD.current_round].RoundTime or 300
    kb.RD.time_round = CurTime() + round_duration

    kb.RD.next_round = table.Random(kb.LevelList)

    PrintMessage(3, "Текущий режим - " .. (_G[kb.RD.current_round].Name or kb.RD.current_round))
    PrintMessage(3, "Следующий режим - " .. (_G[kb.RD.next_round].Name or kb.RD.next_round))
    print("Текущий режим - " .. (_G[kb.RD.current_round].Name or kb.RD.current_round))
    print("Следующий режим - " .. (_G[kb.RD.next_round].Name or kb.RD.next_round))

    kb_data()
end

function EndRoundSV(winner)
    if kb.RD.state == 2 then return end
    kb.RD.state = 2
    kb.RD.winner = winner or "Неизвестный"

    if remove_redzona then
        remove_redzona()
    end

    PrintMessage(3, "Раунд закончен.")
    PrintMessage(3, "Победили - " .. kb.RD.winner)

    print("Раунд закончен.")
    print("Победили - " .. kb.RD.winner)

    timer.Simple(3,function()
        if kb.RD.next_round then
            PrintMessage(3, "Загружаем режим - " .. _G[kb.RD.next_round].Name or kb.RD.next_round)
        end
    end)

    timer.Simple(6,function()
        player_count = player.GetCount()

        if player_count >= 2 or kb.RD.next_round == "constract" then
            print(1)
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


-- команды

hook.Add("PlayerSay","RoundCommands",function(ply,text,team)
    if not ply:IsSuperAdmin() then return end
    local args = string.Explode(" ", text)
    local command = string.lower(args[1])

    if command == "!levelend" then
        EndRoundSV("Скип раунда")
        return ""
    end

    if command == "!levelnext" then
        local next_mode = args[2] 
        
        if next_mode then
            kb.RD.next_round = next_mode
            PrintMessage(3, "Следующий режим принудительно изменен на: " .. next_mode)
            kb_data()
        else
            ply:ChatPrint("!levelnext название")
        end
        return ""
    end

    if command == "!bot" then
        local count = tonumber(args[2]) or 1

        for i = 1, count do
            RunConsoleCommand("bot")
        end
        
        ply:ChatPrint("Добавляем ботов: " .. count)
        return ""
    end

    if command == "!kb" then
        local count = tonumber(args[2])
        local bots = player.GetBots()

        if count then
            local kicked = 0
            for _, bot in ipairs(bots) do
                if kicked >= count then break end
                bot:Kick("Удален администратором")
                kicked = kicked + 1
            end
            ply:ChatPrint("Удалено ботов: " .. kicked)
        else
            for _, bot in ipairs(bots) do
                bot:Kick("Массовое удаление ботов")
            end
            ply:ChatPrint("Все боты удалены.")
        end
        return ""
    end
end)

-- console

concommand.Add("levelend", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then 
        return 
    end

    EndRoundSV("Скип раунда")
end)

concommand.Add("levelnext", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then 
        return 
    end

    local next_mode = args[1] 
    
    if next_mode then
        kb.RD.next_round = next_mode
        PrintMessage(3, "Следующий режим принудительно изменен на: " .. next_mode)
        kb_data()
    else
        if IsValid(ply) then
            ply:ChatPrint("Использование: levelnext название")
        else
            print("Использование: levelnext название")
        end
    end
end)

concommand.Add("addbot", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then 
        return 
    end

    local count = tonumber(args[1]) or 1

    for i = 1, count do
        RunConsoleCommand("bot")
    end
    
    if IsValid(ply) then
        ply:ChatPrint("Добавляем ботов: " .. count)
    else
        print("Добавляем ботов: " .. count)
    end
end)

concommand.Add("kb", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then 
        return 
    end

    local count = tonumber(args[1])
    local bots = player.GetBots()

    if count then
        local kicked = 0
        for _, bot in ipairs(bots) do
            if kicked >= count then break end
            bot:Kick("Удален администратором")
            kicked = kicked + 1
        end
        
        if IsValid(ply) then 
            ply:ChatPrint("Удалено ботов: " .. kicked) 
        else 
            print("Удалено ботов: " .. kicked) 
        end
    else
        for _, bot in ipairs(bots) do
            bot:Kick("Массовое удаление ботов")
        end
        
        if IsValid(ply) then 
            ply:ChatPrint("Все боты удалены.") 
        else 
            print("Все боты удалены.") 
        end
    end
end)