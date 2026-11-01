util.AddNetworkString("Clan_Invite")
util.AddNetworkString("Clan_Message")
util.AddNetworkString("Clan_Sync")
util.AddNetworkString("Clan_ClearHUD")

Clans = Clans or {}
if file.Exists("clans_data.txt", "DATA") then
    local data = file.Read("clans_data.txt", "DATA")
    Clans = util.JSONToTable(data) or {}
end

PendingInvites = PendingInvites or {}

local function SaveClans()
    file.Write("clans_data.txt", util.TableToJSON(Clans))
end

local function GetMaxMembers(ply)
    if ply:GetUserGroup() == "superadmin" then return 15 end
    if ply:GetUserGroup() == "admin" then return 10 end
    if ply:GetUserGroup() == "vip" then return 7 end
    return 5
end

local function SendClanMsg(ply, msg, color)
    net.Start("Clan_Message")
    net.WriteColor(color or Color(255, 255, 255))
    net.WriteString(msg)
    net.Send(ply)
end

local function FindPlayer(nick)
    for _, v in player.Iterator() do
        if string.find(string.lower(v:Nick()), string.lower(nick), 1, true) then
            return v
        end
    end
    return nil
end

local function SyncClan(clanName)
    local clan = Clans[clanName]
    if not clan then return end

    local playersInClan = {}
    for _, p in ipairs(player.GetAll()) do
        if p:GetNWString("Clan") == clanName then
            table.insert(playersInClan, p)
        end
    end

    net.Start("Clan_Sync")
    net.WriteTable(clan.members)
    net.Send(playersInClan)
end

timer.Simple(0.1, function()
    for _, p in ipairs(player.GetAll()) do
        local found = false
        for clanName, data in pairs(Clans) do
            for _, mem in ipairs(data.members) do
                if mem.steamid == p:SteamID() then
                    p:SetNWString("Clan", clanName)
                    SyncClan(clanName)
                    found = true
                    break
                end
            end
            if found then break end
        end
        
        if not found then
            p:SetNWString("Clan", "")
            net.Start("Clan_ClearHUD")
            net.Send(p)
        end
    end
end)

hook.Add("PlayerSay", "ClanSystem_Commands", function(ply, text)
    local args = string.Explode(" ", text)
    if string.lower(args[1]) ~= "!clan" then return end

    local cmd = args[2] and string.lower(args[2]) or ""
    local myClan = ply:GetNWString("Clan")

    if cmd == "create" then
        local clanName = table.concat(args, " ", 3)
        
        if myClan ~= "" then
            SendClanMsg(ply, "Вы уже состоите в клане!", Color(255, 0, 0))
            return ""
        end
        
        if string.len(clanName) < 2 or string.len(clanName) > 16 then
            SendClanMsg(ply, "Название клана должно быть от 2 до 16 символов!", Color(255, 0, 0))
            return ""
        end

        if Clans[clanName] then
            SendClanMsg(ply, "Клан с таким названием уже существует!", Color(255, 0, 0))
            return ""
        end

        Clans[clanName] = {
            owner = ply:SteamID(),
            members = { { steamid = ply:SteamID(), nick = ply:Nick() } }
        }
        ply:SetNWString("Clan", clanName)
        
        SaveClans()
        
        SendClanMsg(ply, "Успешно создан клан - " .. clanName .. "!", Color(0, 255, 0))
        SyncClan(clanName)

    elseif cmd == "add" then
        local targetNick = table.concat(args, " ", 3)
        if myClan == "" then return "" end
        
        if Clans[myClan].owner ~= ply:SteamID() then
            SendClanMsg(ply, "Только создатель может приглашать в клан!", Color(255, 0, 0))
            return ""
        end

        if #Clans[myClan].members >= GetMaxMembers(ply) then
            SendClanMsg(ply, "Достигнут лимит участников клана!", Color(255, 0, 0))
            return ""
        end

        local target = FindPlayer(targetNick)
        if not IsValid(target) or target == ply then
            SendClanMsg(ply, "Игрок не найден.", Color(255, 0, 0))
            return ""
        end

        if target:GetNWString("Clan") ~= "" then
            SendClanMsg(ply, "Игрок уже в клане.", Color(255, 0, 0))
            return ""
        end

        PendingInvites[target:SteamID()] = { clan = myClan, inviter = ply:Nick() }
        
        net.Start("Clan_Invite")
        net.WriteString(ply:Nick())
        net.WriteString(myClan)
        net.Send(target)
        
        SendClanMsg(ply, "Приглашение отправлено.", Color(0, 255, 0))

    elseif cmd == "accept" then
        local invite = PendingInvites[ply:SteamID()]
        if not invite then return "" end
        
        if ply:GetNWString("Clan") ~= "" then
            SendClanMsg(ply, "Вы уже состоите в клане!", Color(255, 0, 0))
            PendingInvites[ply:SteamID()] = nil
            return ""
        end
        
        local targetClan = invite.clan
        if not Clans[targetClan] then
            SendClanMsg(ply, "Этот клан был удален.", Color(255, 0, 0))
            PendingInvites[ply:SteamID()] = nil
            return ""
        end
        
        table.insert(Clans[targetClan].members, { steamid = ply:SteamID(), nick = ply:Nick() })
        ply:SetNWString("Clan", targetClan)
        PendingInvites[ply:SteamID()] = nil
        
        SaveClans()
        
        SendClanMsg(ply, "Вы успешно присоединились к клану " .. targetClan .. "!", Color(0, 255, 0))
        SyncClan(targetClan)

    elseif cmd == "remove" then
        local targetNick = table.concat(args, " ", 3)
        if myClan == "" or Clans[myClan].owner ~= ply:SteamID() then return "" end

        for i, mem in ipairs(Clans[myClan].members) do
            if string.lower(mem.nick) == string.lower(targetNick) then
                if mem.steamid == ply:SteamID() then
                    SendClanMsg(ply, "Вы не можете удалить сами себя. Используйте !clan quit", Color(255, 0, 0))
                    return ""
                end
                
                local targetPly = player.GetBySteamID(mem.steamid)
                if IsValid(targetPly) then
                    targetPly:SetNWString("Clan", "")
                    net.Start("Clan_ClearHUD")
                    net.Send(targetPly)
                end
                
                table.remove(Clans[myClan].members, i)
                
                SaveClans()
                
                SendClanMsg(ply, "Игрок " .. mem.nick .. " удален из клана.", Color(0, 255, 0))
                SyncClan(myClan)
                return ""
            end
        end

    elseif cmd == "quit" then
        if myClan == "" then
            SendClanMsg(ply, "Вы не состоите в клане.", Color(255, 0, 0))
            return ""
        end

        local clanData = Clans[myClan]
        
        if clanData.owner == ply:SteamID() then
            for _, mem in ipairs(clanData.members) do
                local targetPly = player.GetBySteamID(mem.steamid)
                if IsValid(targetPly) then
                    targetPly:SetNWString("Clan", "")
                    net.Start("Clan_ClearHUD")
                    net.Send(targetPly)
                    
                    if targetPly == ply then
                        SendClanMsg(targetPly, "Вы распустили клан.", Color(0, 255, 0))
                    else
                        SendClanMsg(targetPly, "Ваш клан был распущен создателем.", Color(255, 50, 50))
                    end
                end
            end
            Clans[myClan] = nil
            SaveClans()
        else
            for i, mem in ipairs(clanData.members) do
                if mem.steamid == ply:SteamID() then
                    table.remove(clanData.members, i)
                    break
                end
            end
            ply:SetNWString("Clan", "")
            net.Start("Clan_ClearHUD")
            net.Send(ply)
            SendClanMsg(ply, "Вы покинули клан " .. myClan .. ".", Color(0, 255, 0))
            
            SaveClans()
            SyncClan(myClan)
        end

    elseif cmd == "info" then
        if myClan == "" then
            SendClanMsg(ply, "Вы не состоите в клане.", Color(255, 0, 0))
            return ""
        end
        local membersCount = #Clans[myClan].members
        SendClanMsg(ply, "Информация о клане: " .. myClan .. " | Участников: " .. membersCount, Color(0, 255, 255))
    end

    return ""
end)

hook.Add("PlayerShouldTakeDamage", "Clan_FriendlyFire", function(ply, attacker)
    if IsValid(ply) and IsValid(attacker) and ply:IsPlayer() and attacker:IsPlayer() then
        local clan1 = ply:GetNWString("Clan")
        local clan2 = attacker:GetNWString("Clan")
        
        if clan1 ~= "" and clan1 == clan2 then
            return false
        end
    end
end)

hook.Add("PlayerInitialSpawn", "Clan_SyncOnJoin", function(ply)
    for clanName, data in pairs(Clans) do
        for _, mem in ipairs(data.members) do
            if mem.steamid == ply:SteamID() then
                ply:SetNWString("Clan", clanName)
                timer.Simple(1, function() SyncClan(clanName) end)
                return
            end
        end
    end
end)

hook.Add("PlayerDisconnected", "Clan_ClearInvites", function(ply)
    if PendingInvites[ply:SteamID()] then
        PendingInvites[ply:SteamID()] = nil
    end
end)