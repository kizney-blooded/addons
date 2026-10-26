if IsValid(teamFrame) then
    teamFrame:Remove()
end

teamFrame = nil

local function OpenTeamMenu()

    teamFrame = vgui.Create("DFrame")
    teamFrame:SetSize(300, 150)
    teamFrame:Center()
    teamFrame:SetTitle("Выбор команды")
    teamFrame:MakePopup()
    teamFrame:SetDraggable(false)

    --teamFrame:SetAlpha(0)
    --teamFrame:AlphaTo(255, 0.5, 0)

    local btnPlayers = vgui.Create("DButton", teamFrame)
    btnPlayers:SetText("Игроки")
    btnPlayers:Dock(TOP)
    btnPlayers:DockMargin(10, 10, 10, 5)
    btnPlayers:SetTall(35)
    btnPlayers.DoClick = function()
        net.Start("ChangePlayerTeam")
            net.WriteUInt(1, 16)
        net.SendToServer()
        
        teamFrame:Close()
    end

    local btnSpecs = vgui.Create("DButton", teamFrame)
    btnSpecs:SetText("Наблюдатели")
    btnSpecs:Dock(TOP)
    btnSpecs:DockMargin(10, 5, 10, 10)
    btnSpecs:SetTall(35)
    btnSpecs.DoClick = function()
        net.Start("ChangePlayerTeam")
            net.WriteUInt(1002, 16)
        net.SendToServer()
        
        teamFrame:Close()
    end
end

hook.Add("PlayerButtonDown", "OpenTeamMenuOnF3", function(ply, button)
    if IsFirstTimePredicted() and button == KEY_F3 then
        if IsValid(teamFrame) then
            --teamFrame:AlphaTo(0, 0.2, 0, function()
                if IsValid(teamFrame) then teamFrame:Remove() end
            --end)
        else
            OpenTeamMenu()
        end
    end
end)