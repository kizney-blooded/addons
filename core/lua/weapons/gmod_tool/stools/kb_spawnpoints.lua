TOOL.Category = "Kizney Box"
TOOL.Name = "Расставление точек"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add("tool.kb_spawnpoints.name", "Расставление точек")
    language.Add("tool.kb_spawnpoints.desc", "Создает точки спавна для различных зон (например, Красная Зона)")
    language.Add("tool.kb_spawnpoints.0", "ЛКМ: Установить точку")
end

TOOL.ClientConVar["zonetype"] = "red_zone"

function TOOL:LeftClick(trace)
    if not trace.Hit then return false end
    
    if CLIENT then
        local hitPos = trace.HitPos
        local zoneType = self:GetClientInfo("zonetype")

        local frame = vgui.Create("DFrame")
        frame:SetSize(300, 150)
        frame:Center()
        frame:SetTitle("Настройка зоны")
        frame:MakePopup()

        local label = vgui.Create("DLabel", frame)
        label:SetPos(10, 30)
        label:SetText("Радиус (по умолчанию 3000):")
        label:SizeToContents()

        local radiusEntry = vgui.Create("DTextEntry", frame)
        radiusEntry:SetPos(10, 50)
        radiusEntry:SetSize(280, 25)
        radiusEntry:SetNumeric(true)
        radiusEntry:SetText("3000")

        local btn = vgui.Create("DButton", frame)
        btn:SetPos(10, 90)
        btn:SetSize(280, 30)
        btn:SetText("Создать")
        btn.DoClick = function()
            local radius = tonumber(radiusEntry:GetValue()) or 3000
            
            net.Start("kb_spawnpoints_create")
                net.WriteString(zoneType)
                net.WriteVector(hitPos)
                net.WriteFloat(radius)
            net.SendToServer()
            
            frame:Close()
        end
    end

    return true
end

function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", { description = "Выберите тип зоны и нажмите ЛКМ для установки." })
    
    local combo = panel:ComboBox("Тип зоны", "kb_spawnpoints_zonetype")
    combo:AddChoice("Красная Зона", "red_zone")
end

if SERVER then
    util.AddNetworkString("kb_spawnpoints_create")

    net.Receive("kb_spawnpoints_create", function(len, ply)
        if not ply:IsSuperAdmin() then return end

        local zType = net.ReadString()
        local pos = net.ReadVector()
        local radius = net.ReadFloat()

        local mapName = game.GetMap()
        local dirPath = "kb_spawnpoints/" .. mapName
        local filePath = dirPath .. "/log.json"

        if not file.Exists(dirPath, "DATA") then
            file.CreateDir(dirPath)
        end

        local data = {}
        if file.Exists(filePath, "DATA") then
            local rawData = file.Read(filePath, "DATA")
            data = util.JSONToTable(rawData) or {}
        end

        table.insert(data, {
            type = zType,
            pos = pos,
            radius = radius
        })

        file.Write(filePath, util.TableToJSON(data, true))
    end)
end