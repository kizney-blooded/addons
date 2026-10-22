TOOL.Category = "Kizney Box"
TOOL.Name = "Расставление точек"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["type"] = "random"

if CLIENT then
    language.Add("tool.kb_spawnpoints.name", "Расставление точек")
    language.Add("tool.kb_spawnpoints.desc", "Создает точки спавна для Kizney Box")
    language.Add("tool.kb_spawnpoints.left", "ЛКМ: Установить точку")
    language.Add("tool.kb_spawnpoints.right", "ПКМ: Удалить ближайшую точку")
    
    KB_SPAWNPOINTS_CLIENT = KB_SPAWNPOINTS_CLIENT or { random = {}, blue = {}, red = {} }
end

if SERVER then
    util.AddNetworkString("kb_spawnpoints_update")

    KB_SPAWNPOINTS = KB_SPAWNPOINTS or { random = {}, blue = {}, red = {} }
    KB_SPAWN_ENTITIES = KB_SPAWN_ENTITIES or { random = {}, blue = {}, red = {} }

    local function GetDirPath()
        return "data_spawnpoints/" .. game.GetMap()
    end

    local function GetFilePath()
        return GetDirPath() .. "/log.json"
    end

    local function RefreshSpawnEntities()
        for k, entsList in pairs(KB_SPAWN_ENTITIES) do
            for _, ent in ipairs(entsList) do
                if IsValid(ent) then ent:Remove() end
            end
        end
        KB_SPAWN_ENTITIES = { random = {}, blue = {}, red = {} }

        for sType, points in pairs(KB_SPAWNPOINTS) do
            for _, pos in ipairs(points) do
                local ent = ents.Create("info_target")
                ent:SetPos(pos)
                ent:Spawn()
                table.insert(KB_SPAWN_ENTITIES[sType], ent)
            end
        end
        
        net.Start("kb_spawnpoints_update")
        net.WriteTable(KB_SPAWNPOINTS)
        net.Broadcast()
    end

    function KB_LoadSpawnpoints()
        local dir = GetDirPath()
        if not file.Exists(dir, "DATA") then
            file.CreateDir(dir)
        end

        local f = GetFilePath()
        if file.Exists(f, "DATA") then
            local data = file.Read(f, "DATA")
            if data then
                KB_SPAWNPOINTS = util.JSONToTable(data) or { random = {}, blue = {}, red = {} }
            end
        end
        RefreshSpawnEntities()
    end

    function KB_SaveSpawnpoints()
        local dir = GetDirPath()
        if not file.Exists(dir, "DATA") then
            file.CreateDir(dir)
        end
        file.Write(GetFilePath(), util.TableToJSON(KB_SPAWNPOINTS, true))
        RefreshSpawnEntities()
    end

    hook.Add("InitPostEntity", "KB_InitSpawnpoints", KB_LoadSpawnpoints)
    
    hook.Add("PlayerInitialSpawn", "KB_SyncSpawnpoints", function(ply)
        net.Start("kb_spawnpoints_update")
        net.WriteTable(KB_SPAWNPOINTS)
        net.Send(ply)
    end)
    
    KB_LoadSpawnpoints()
end

if CLIENT then
    net.Receive("kb_spawnpoints_update", function()
        KB_SPAWNPOINTS_CLIENT = net.ReadTable()
    end)

    hook.Add("PostDrawTranslucentRenderables", "KB_DrawSpawnpoints3D", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "gmod_tool" then return end
        if GetConVar("gmod_toolmode"):GetString() ~= "kb_spawnpoints" then return end

        local colors = {
            random = Color(255, 255, 255, 150),
            blue = Color(50, 150, 255, 150),
            red = Color(255, 50, 50, 150)
        }
        
        local wire_colors = {
            random = Color(255, 255, 255, 255),
            blue = Color(50, 150, 255, 255),
            red = Color(255, 50, 50, 255)
        }

        render.SetColorMaterial()
        for sType, points in pairs(KB_SPAWNPOINTS_CLIENT) do
            local fillCol = colors[sType] or colors["random"]
            local wireCol = wire_colors[sType] or wire_colors["random"]
            
            for _, pos in ipairs(points) do
                render.DrawSphere(pos, 10, 16, 16, fillCol)
                --render.DrawWireframeSphere(pos, 10, 16, 16, wireCol)
            end
        end
    end)

    hook.Add("HUDPaint", "KB_DrawSpawnpointsText", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "gmod_tool" then return end
        if GetConVar("gmod_toolmode"):GetString() ~= "kb_spawnpoints" then return end

        for sType, points in pairs(KB_SPAWNPOINTS_CLIENT) do
            for _, pos in ipairs(points) do
                local screen = pos:ToScreen()
                if screen.visible then
                    draw.SimpleText(string.upper(sType), "DermaDefaultBold", screen.x, screen.y - 15, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
        end
    end)
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local spawnType = self:GetClientInfo("type")
    if spawnType ~= "random" and spawnType ~= "blue" and spawnType ~= "red" then
        spawnType = "random"
    end

    table.insert(KB_SPAWNPOINTS[spawnType], trace.HitPos)
    KB_SaveSpawnpoints()

    self:GetOwner():ChatPrint("[Kizney Box] Точка типа '" .. spawnType .. "' успешно создана и сохранена!")
    return true
end

function TOOL:RightClick(trace)
    if CLIENT then return true end
    
    local targetPos = trace.HitPos
    local nearestType = nil
    local nearestIdx = nil
    local minDist = 10000 -- (100^2)

    for sType, points in pairs(KB_SPAWNPOINTS) do
        for i, pos in ipairs(points) do
            local dist = pos:DistToSqr(targetPos)
            if dist < minDist then
                minDist = dist
                nearestType = sType
                nearestIdx = i
            end
        end
    end

    if nearestType and nearestIdx then
        table.remove(KB_SPAWNPOINTS[nearestType], nearestIdx)
        KB_SaveSpawnpoints()
        self:GetOwner():ChatPrint("[Kizney Box] Ближайшая точка (" .. nearestType .. ") удалена.")
    else
        self:GetOwner():ChatPrint("[Kizney Box] Поблизости нет точек для удаления.")
    end

    return true
end

function TOOL.BuildCPanel(CPanel)
    CPanel:AddControl("Header", {
        Text = "Точки Спавна",
        Description = "Настройка кастомных точек для режимов и команд."
    })

    local combo = vgui.Create("DComboBox")
    combo:SetSortItems(false)
    combo:SetValue("Выберите тип точки...")
    
    combo:AddChoice("Рандомный", "random")
    combo:AddChoice("Синие (Команда 1)", "blue")
    combo:AddChoice("Красные (Команда 2)", "red")

    combo.OnSelect = function(self, index, value, data)
        RunConsoleCommand("kb_spawnpoints_type", data)
    end

    CPanel:AddItem(combo)
end

if SERVER then
    hook.Add("PlayerSelectSpawn", "KB_PlayerSelectSpawn", function(ply, transition)
        if transition then return end

        local pool = {}

        if kb and kb.RD and kb.RD.current_round == "hmcd" then
            pool = KB_SPAWN_ENTITIES["random"]
        else
            local teamID = ply:Team()
            if teamID == 1 then
                pool = KB_SPAWN_ENTITIES["blue"]
            elseif teamID == 2 then
                pool = KB_SPAWN_ENTITIES["red"]
            else
                pool = KB_SPAWN_ENTITIES["random"]
            end
        end

        if pool and #pool > 0 then
            local selectedEnt = pool[math.random(1, #pool)]
            if IsValid(selectedEnt) then
                return selectedEnt
            end
        end
        
    end)
end