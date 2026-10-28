KB_WeaponSelectionModels = KB_WeaponSelectionModels or {}

function KB_DrawWeaponSelection(wep, x, y, wide, tall, alpha)
    local mdlPath = wep.WorldModel
    if not mdlPath or mdlPath == "" then return end

    local mdl = KB_WeaponSelectionModels[mdlPath]
    
    if not IsValid(mdl) then
        mdl = ClientsideModel(mdlPath, RENDERGROUP_OTHER)
        if not IsValid(mdl) then return end
        
        mdl:SetNoDraw(true)
        KB_WeaponSelectionModels[mdlPath] = mdl
    end

    local iconData = wep.IconPos or {}
    local mPos = iconData.Pos or Vector(0, 0, 0)
    local mAng = iconData.Ang or Angle(0, 0, 0)
    local fov = iconData.FOV or 50

    local camPos = Vector(0, 0, 0)
    local camAng = Angle(0, 0, 0)

    cam.Start3D(camPos, camAng, fov, x, y, wide, tall, 1, 500)
        
        render.SuppressEngineLighting(true)
        render.SetLightingOrigin(Vector(0, 0, 0))
        render.ResetModelLighting(1, 1, 1)
        
        render.SetModelLighting(BOX_TOP, 1, 1, 1)
        render.SetModelLighting(BOX_FRONT, 1, 1, 1)
        
        --render.SetColorModulation(1, 1, 1)
        --render.SetBlend(alpha / 255)

        mdl:SetPos(mPos)
        mdl:SetAngles(mAng)
        mdl:DrawModel()

        --render.SetBlend(1)
        render.SuppressEngineLighting(false)
        
    cam.End3D()
end

if CLIENT then
    concommand.Add("kb_icon", function(ply, cmd, args)
        local wep = ply:GetActiveWeapon()
        
        if not IsValid(wep) then
            return
        end

        if not wep.IconPos then
            wep.IconPos = { Pos = Vector(0,0,0), Ang = Angle(0,0,0), FOV = 50 }
        end

        local frame = vgui.Create("DFrame")
        frame:SetSize(800, 450)
        frame:SetTitle("KB Weapon Icon Editor")
        frame:Center()
        frame:MakePopup()

        local previewPanel = vgui.Create("DPanel", frame)
        previewPanel:Dock(RIGHT)
        previewPanel:SetWide(400)
        previewPanel.Paint = function(self, w, h)
            surface.SetDrawColor(40, 40, 40, 50)
            surface.DrawRect(0, 0, w, h)
            
            local screenX, screenY = self:LocalToScreen(0, 0)
            
            if IsValid(wep) and KB_DrawWeaponSelection then
                KB_DrawWeaponSelection(wep, screenX, screenY, w, h, 255)
            else
                draw.SimpleText("Оружие пропало", "DermaDefault", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        local sheet = vgui.Create("DPropertySheet", frame)
        sheet:Dock(FILL)

        local function CreateSliders(parent, offsetTable)
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
                    slider:SetValue(offsetTable[key] or 50)
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

            AddSlider("Pos X (Вперед/Назад)", -150, 150, "x", false)
            AddSlider("Pos Y (Вправо/Влево)", -150, 150, "y", false)
            AddSlider("Pos Z (Вверх/Вниз)", -150, 150, "z", false)
            AddSlider("Ang Pitch (Наклон)", -180, 180, "p", true)
            AddSlider("Ang Yaw (Поворот)", -180, 180, "y", true)
            AddSlider("Ang Roll (Вращение)", -180, 180, "r", true)
            AddSlider("FOV (Отдаление камеры)", 10, 120, "FOV", false, true)

            return panel
        end

        local pnlIcon = CreateSliders(sheet, wep.IconPos)
        sheet:AddSheet("IconPos (Inventory)", pnlIcon, "icon16/picture.png")

        local printBtn = vgui.Create("DButton", frame)
        printBtn:Dock(BOTTOM)
        printBtn:DockMargin(0, 5, 0, 0)
        printBtn:SetTall(30)
        printBtn:SetText("Print to Console")
        printBtn.DoClick = function()
            if not IsValid(wep) then return end
            
            local ip = wep.IconPos
            print(string.format("SWEP.IconPos = { Pos = Vector(%.2f, %.2f, %.2f), Ang = Angle(%.2f, %.2f, %.2f), FOV = %.2f }", 
                ip.Pos.x, ip.Pos.y, ip.Pos.z, ip.Ang.p, ip.Ang.y, ip.Ang.r, ip.FOV or 50))
        end
    end)
end