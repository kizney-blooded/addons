include("shared.lua")
include("cl_camera.lua")

concommand.Add("kb_offset", function(ply, cmd, args)
    local wep = ply:GetActiveWeapon()
    
    if not IsValid(wep) or not wep.WorldPos or not wep.LWorldPos then
        return
    end

    if not wep.SightPos then
        wep.SightPos = { Pos = Vector(0,0,0), Ang = Angle(0,0,0), FOV = 60, Speed = 15 }
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 400)
    frame:SetTitle("KB Weapon Offset Editor")
    frame:Center()
    frame:MakePopup()
    
    frame.OnClose = function()
        if IsValid(wep) then wep.ForceAim = false end
    end

    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)

    local function CreateSliders(parent, offsetTable, isSight)
        local panel = vgui.Create("DPanel", parent)
        panel.Paint = function() end

        local function AddSlider(name, min, max, key, isAngle, isSpecial)
            local slider = vgui.Create("DNumSlider", panel)
            slider:Dock(TOP)
            slider:DockMargin(10, 10, 10, 0)
            slider:SetText(name)
            slider:SetMin(min)
            slider:SetMax(max)
            slider:SetDecimals(2)
            
            if isSpecial then
                slider:SetValue(offsetTable[key] or 0)
            elseif isAngle then
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
                if isSpecial then
                    offsetTable[key] = val
                elseif isAngle then
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
        
        if isSight then
            AddSlider("FOV (Зум)", 10, 120, "FOV", false, true)
            AddSlider("Speed (Скорость входа)", 1, 50, "Speed", false, true)
        end

        return panel
    end

    local pnlWorld = CreateSliders(sheet, wep.WorldPos)
    local pnlLocal = CreateSliders(sheet, wep.LWorldPos)
    local pnlSight = CreateSliders(sheet, wep.SightPos, true)

    sheet:AddSheet("WorldPos (3rd Person)", pnlWorld, "icon16/world.png")
    sheet:AddSheet("LWorldPos (1st Person)", pnlLocal, "icon16/user.png")
    sheet:AddSheet("SightPos (Aiming)", pnlSight, "icon16/zoom.png")

    sheet.OnActiveTabChanged = function(self, old, new)
        if not IsValid(wep) then return end
        
        if IsValid(new) and new:GetPanel() == pnlSight then
            wep.ForceAim = true
        else
            wep.ForceAim = false
        end
    end

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
            
        local sp = wep.SightPos
        print(string.format("SWEP.SightPos = { Pos = Vector(%.2f, %.2f, %.2f), Ang = Angle(%.2f, %.2f, %.2f), FOV = %.2f, Speed = %.2f }", 
            sp.Pos.x, sp.Pos.y, sp.Pos.z, sp.Ang.p, sp.Ang.y, sp.Ang.r, sp.FOV, sp.Speed))
    end
end)