kb = kb or {}

kb.LevelList = {}

kb.RD = kb.RD or {
    state = 0,
    
    current_round = nil,
    next_round = nil,

    time_round = nil,

    disable_respawn_time = nil,

    winner = nil,
}

function kb_data(ply)

    net.Start("kb_data")
        net.WriteTable(kb.RD)

    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

function CreateLevel(name)
    table.insert(kb.LevelList, name)
end
