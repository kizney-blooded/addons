include("shared.lua")

concommand.Add("kb_offset", function(ply, cmd, args)
    local wep = ply:GetActiveWeapon()
    
    if not IsValid(wep) or not wep.WorldPos or not wep.LWorldPos then
        chat.AddText(Color(255, 50, 50), "Возьмите в руки ваше оружие, чтобы настраивать оффсеты!")
        return
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 350)
    frame:SetTitle("KB Weapon Offset Editor")
    frame:Center()
    frame:MakePopup()

    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)

    local function CreateSliders(parent, offsetTable)
        local panel = vgui.Create("DPanel", parent)
        panel.Paint = function() end

        local function AddSlider(name, min, max, key, isAngle)
            local slider = vgui.Create("DNumSlider", panel)
            slider:Dock(TOP)
            slider:DockMargin(10, 10, 10, 0)
            slider:SetText(name)
            slider:SetMin(min)
            slider:SetMax(max)
            slider:SetDecimals(2)
            
            if isAngle then
                if key == "p" then slider:SetValue(offsetTable.Ang.p)
                elseif key == "y" then slider:SetValue(offsetTable.Ang.y)
                elseif key == "r" then slider:SetValue(offsetTable.Ang.r) end
            else
                if key == "x" then slider:SetValue(offsetTable.Pos.x)
                elseif key == "y" then slider:SetValue(offsetTable.Pos.y)
                elseif key == "z" then slider:SetValue(offsetTable.Pos.z) end
            end

            slider.OnValueChanged = function(self, val)
                if not IsValid(wep) then return end
                if isAngle then
                    if key == "p" then offsetTable.Ang.p = val
                    elseif key == "y" then offsetTable.Ang.y = val
                    elseif key == "r" then offsetTable.Ang.r = val end
                else
                    if key == "x" then offsetTable.Pos.x = val
                    elseif key == "y" then offsetTable.Pos.y = val
                    elseif key == "z" then offsetTable.Pos.z = val end
                end
            end
        end

        AddSlider("Pos X (Вперед/Назад)", -100, 100, "x", false)
        AddSlider("Pos Y (Вправо/Влево)", -100, 100, "y", false)
        AddSlider("Pos Z (Вверх/Вниз)", -100, 100, "z", false)
        AddSlider("Ang Pitch (Наклон)", -180, 180, "p", true)
        AddSlider("Ang Yaw (Поворот)", -180, 180, "y", true)
        AddSlider("Ang Roll (Вращение)", -180, 180, "r", true)

        return panel
    end

    sheet:AddSheet("WorldPos (3rd Person)", CreateSliders(sheet, wep.WorldPos), "icon16/world.png")
    sheet:AddSheet("LWorldPos (1st Person)", CreateSliders(sheet, wep.LWorldPos), "icon16/user.png")

    local printBtn = vgui.Create("DButton", frame)
    printBtn:Dock(BOTTOM)
    printBtn:DockMargin(0, 5, 0, 0)
    printBtn:SetTall(30)
    printBtn:SetText("Print to Console")
    printBtn.DoClick = function()
        if not IsValid(wep) then return end
        
        local wp = wep.WorldPos
        print(string.format("SWEP.WorldPos = { Pos = Vector(%.2f, %.2f, %.2f), Ang = Angle(%.2f, %.2f, %.2f) }", 
            wp.Pos.x, wp.Pos.y, wp.Pos.z, wp.Ang.p, wp.Ang.y, wp.Ang.r))
            
        local lwp = wep.LWorldPos
        print(string.format("SWEP.LWorldPos = { Pos = Vector(%.2f, %.2f, %.2f), Ang = Angle(%.2f, %.2f, %.2f) }", 
            lwp.Pos.x, lwp.Pos.y, lwp.Pos.z, lwp.Ang.p, lwp.Ang.y, lwp.Ang.r))
    end
end)