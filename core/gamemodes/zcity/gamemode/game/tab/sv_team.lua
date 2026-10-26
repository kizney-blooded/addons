util.AddNetworkString("ChangePlayerTeam")

net.Receive("ChangePlayerTeam", function(len, ply)
    --if (ply.NextTeamChange or 0) > CurTime() then return end
    --ply.NextTeamChange = CurTime() + 1 

    local teamID = net.ReadUInt(16)

    if teamID == 1 then
        ply:ChatPrint("Ты стал игроком.")
        ply:SetTeam(1)
        if ply:Alive() then
            ply:Kill()
        end
    elseif teamID == 1002 then
        ply:ChatPrint("Ты стал наблюдателем.")
        ply:SetTeam(1002)
        if ply:Alive() then
            ply:Kill()
        end
    end
end)