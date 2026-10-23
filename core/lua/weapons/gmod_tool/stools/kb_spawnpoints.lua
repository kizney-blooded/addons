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
    -- по остальному принципу буду делать остлаьное:)
    KB_SPAWNPOINTS_CLIENT = KB_SPAWNPOINTS_CLIENT or { 
        random = {}, 
        blue = {}, 
        red = {}, 
        redzona = {}, 
        lootboxes = {},
        food_lootboxes = {} 
    }
end

if SERVER then
    util.AddNetworkString("kb_spawnpoints_update")
    util.AddNetworkString("kb_create_redzona")

    KB_SPAWNPOINTS = KB_SPAWNPOINTS or { 
        random = {}, 
        blue = {}, 
        red = {}, 
        redzona = {}, 
        lootboxes = {},
        food_lootboxes = {} 
    }

    KB_SPAWN_ENTITIES = KB_SPAWN_ENTITIES or { 
        random = {}, 
        blue = {}, 
        red = {}, 
        redzona = {}, 
        lootboxes = {},
        food_lootboxes = {} 
    }

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

        KB_SPAWN_ENTITIES = { 
            random = {}, 
            blue = {}, 
            red = {}, 
            redzona = {}, 
            lootboxes = {},
            food_lootboxes = {} 
        }

        for sType, points in pairs(KB_SPAWNPOINTS) do
            if sType == "redzona" or sType == "lootboxes" or sType == "food_lootboxes" then continue end
            for _, pos in ipairs(points) do
                local ent = ents.Create("info_target")
                ent:SetPos(pos)
                ent:Spawn()
                table.insert(KB_SPAWN_ENTITIES[sType], ent)
            end
        end

        KB_SPAWNPOINTS.random = KB_SPAWNPOINTS.random or {}
        KB_SPAWNPOINTS.blue = KB_SPAWNPOINTS.blue or {}
        KB_SPAWNPOINTS.red = KB_SPAWNPOINTS.red or {}
        KB_SPAWNPOINTS.redzona = KB_SPAWNPOINTS.redzona or {}
        KB_SPAWNPOINTS.lootboxes = KB_SPAWNPOINTS.lootboxes or {}
        KB_SPAWNPOINTS.food_lootboxes = KB_SPAWNPOINTS.food_lootboxes or {}
        
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
                KB_SPAWNPOINTS = util.JSONToTable(data) or { 
                    random = {}, 
                    blue = {}, 
                    red = {}, 
                    redzona = {}, 
                    lootboxes = {},
                    food_lootboxes = {} 
                }
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

    hook.Add("PostCleanupMap", "KB_RestoreSpawnpoints", function()
        KB_LoadSpawnpoints()
    end)

    hook.Add("PlayerInitialSpawn", "KB_SyncSpawnpoints", function(ply)
        net.Start("kb_spawnpoints_update")
        net.WriteTable(KB_SPAWNPOINTS)
        net.Send(ply)
    end)

    net.Receive("kb_create_redzona", function(len, ply)
        local pos = net.ReadVector()
        local radius = net.ReadFloat()

        KB_SPAWNPOINTS["redzona"] = {}
        table.insert(KB_SPAWNPOINTS["redzona"], {pos = pos, radius = radius})
        KB_SaveSpawnpoints()
    end)

    KB_LoadSpawnpoints()

    function spawn_lootboxes()
        if KB_SPAWNPOINTS["lootboxes"] then
            for _, pos in ipairs(KB_SPAWNPOINTS["lootboxes"]) do
                local ent = ents.Create("ent_lootboxes")
                if IsValid(ent) then
                    ent:SetPos(pos)
                    ent:Spawn()
                end
            end
        end

        if KB_SPAWNPOINTS["food_lootboxes"] then
            for _, pos in ipairs(KB_SPAWNPOINTS["food_lootboxes"]) do
                local ent = ents.Create("ent_lootbox_food")
                if IsValid(ent) then
                    ent:SetPos(pos)
                    ent:Spawn()
                end
            end
        end
    end
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
            red = Color(255, 50, 50, 150),

            redzona = Color(255, 0, 0, 50),

            lootboxes = Color(12, 75, 15, 150),
            food_lootboxes = Color(255, 224, 157)
        }

        render.SetColorMaterial()
        for sType, points in pairs(KB_SPAWNPOINTS_CLIENT) do
            local fillCol = colors[sType] or colors["random"]
            
            for _, data in ipairs(points) do
                if sType == "redzona" then
                    render.CullMode( MATERIAL_CULLMODE_CW )
                    render.DrawSphere( data.pos, data.radius, 30, 30, fillCol )
                    render.CullMode( MATERIAL_CULLMODE_CCW )
                    render.DrawSphere( data.pos, data.radius, 30, 30, fillCol )
                elseif sType == "lootboxes" or sType == "food_lootboxes" then
                    local boxMins = Vector(-20, -20, 0) 
                    local boxMaxs = Vector(20, 20, 40) 
                    
                    render.DrawBox(data, Angle(0,0,0), boxMins, boxMaxs, fillCol)
                    render.DrawWireframeBox(data, Angle(0,0,0), boxMins, boxMaxs, color_white, true)
                else
                    local plyMins = Vector(-16, -16, 0)
                    local plyMaxs = Vector(16, 16, 80)
                    
                    render.DrawBox(data, Angle(0,0,0), plyMins, plyMaxs, fillCol)
                    render.DrawWireframeBox(data, Angle(0,0,0), plyMins, plyMaxs, color_white, true)
                end
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
            for _, data in ipairs(points) do
                local pos = (sType == "redzona") and data.pos or data
                local screen = pos:ToScreen()
                
                if screen.visible then
                    local txt = string.upper(sType)
                    if sType == "redzona" then txt = txt .. " (R: " .. data.radius .. ")" end
                    draw.SimpleText(txt, "DermaDefaultBold", screen.x, screen.y - 15, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
        end
    end)
end

function TOOL:LeftClick(trace)
    local spawnType = self:GetClientInfo("type")
    if spawnType ~= "random" and spawnType ~= "blue" and spawnType ~= "red" and spawnType ~= "redzona" and spawnType ~= "lootboxes" and spawnType ~= "food_lootboxes" then
        spawnType = "random"
    end

    if spawnType == "redzona" then
        if CLIENT then
            local hitPos = trace.HitPos
            
            local frame = vgui.Create("DFrame")
            frame:SetSize(300, 150)
            frame:Center()
            frame:SetTitle("Радиус Красной Зоны")
            frame:MakePopup()

            local label = vgui.Create("DLabel", frame)
            label:SetPos(10, 30)
            label:SetSize(280, 20)
            label:SetText("Введите радиус красной зоны:")

            local entry = vgui.Create("DTextEntry", frame)
            entry:SetPos(10, 60)
            entry:SetSize(280, 25)
            entry:SetNumeric(true)
            entry:SetValue("3000")

            local btn = vgui.Create("DButton", frame)
            btn:SetPos(10, 100)
            btn:SetSize(280, 30)
            btn:SetText("Создать")
            btn.DoClick = function()
                local radius = tonumber(entry:GetValue()) or 3000
                net.Start("kb_create_redzona")
                    net.WriteVector(hitPos)
                    net.WriteFloat(radius)
                net.SendToServer()
                frame:Close()
            end
        end
        return true
    end

    if CLIENT then return true end

    if not KB_SPAWNPOINTS[spawnType] then
        KB_SPAWNPOINTS[spawnType] = {}
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
        for i, data in ipairs(points) do
            local pos = (sType == "redzona") and data.pos or data
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
        Description = "Настройка кастомных точек для режимов, команд и энтити."
    })

    local combo = vgui.Create("DComboBox")
    local comboEnts = vgui.Create("DComboBox")

    CPanel:Help("Точки игроков и зон:")
    combo:SetSortItems(false)
    combo:SetValue("Выберите тип точки...")

    combo:AddChoice("Рандомный", "random")
    combo:AddChoice("Синие (Команда 1)", "blue")
    combo:AddChoice("Красные (Команда 2)", "red")
    combo:AddChoice("Красная зона", "redzona")

    combo.OnSelect = function(self, index, value, data)
        RunConsoleCommand("kb_spawnpoints_type", data)
        comboEnts:SetValue("Выберите энтити...")
    end
    CPanel:AddItem(combo)

    CPanel:Help("Точки спавна энтити:")
    comboEnts:SetSortItems(false)
    comboEnts:SetValue("Выберите энтити...")

    comboEnts:AddChoice("Обычный контейнер (ent_lootboxes)", "lootboxes")
    comboEnts:AddChoice("Еда (ent_lootbox_food)", "food_lootboxes")

    comboEnts.OnSelect = function(self, index, value, data)
        RunConsoleCommand("kb_spawnpoints_type", data)
        combo:SetValue("Выберите тип точки...")
    end
    CPanel:AddItem(comboEnts)
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
            local free_pool = {}
            local check_radius = 64

            for _, spawnEnt in ipairs(pool) do
                if IsValid(spawnEnt) then
                    local is_free = true
                    local nearby_ents = ents.FindInSphere(spawnEnt:GetPos(), check_radius)
                    
                    for _, ent in ipairs(nearby_ents) do
                        if ent:IsPlayer() and ent:Alive() and ent ~= ply then
                            is_free = false
                            break
                        end
                    end

                    if is_free then
                        table.insert(free_pool, spawnEnt)
                    end
                end
            end

            local final_pool = (#free_pool > 0) and free_pool or pool
            local selectedEnt = final_pool[math.random(1, #final_pool)]
            
            if IsValid(selectedEnt) then
                return selectedEnt
            end
        end

    end)
end