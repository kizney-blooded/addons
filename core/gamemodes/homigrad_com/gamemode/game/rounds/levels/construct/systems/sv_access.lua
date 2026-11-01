local great_tools = {
    ['light'] = true,
    ['remover'] = true,
    ['colour'] = true,
    ['material'] = true,
    ['keypad_willox'] = true,
    ['fading_door'] = true,
} -- разрешённые инструменты

local valid = {
    ["superadmin"] = true,
}

hook.Add('CanTool', 'fghd3281721fh198fu129fh1298f', function(ply, _, tool)
    if not great_tools[tool] and not valid[ply:GetUserGroup()] then
        return false
    end
end)

if (!SERVER) then return; end

local function notify(text)
	for k,v in player.Iterator() do
		v:PrintMessage(HUD_PRINTTALK, text);
	end
end

hook.Add("PhysgunPickup", "ZGPropKilLPickup", function(ply, ent)
	local class = ent:GetClass()
    
    if class != "prop_physics" and class != "con_lootbox" and class != "ent_jack_sleepingbag" and class != "con_shkaf" then 
        return 
    end

    local owner = ent:CPPIGetOwner()
    if owner ~= ply then 
        local isSameClan = false
        if IsValid(owner) and owner:IsPlayer() then
            local ownerClan = owner:GetNWString("Clan", "")
            local plyClan = ply:GetNWString("Clan", "")
            if ownerClan ~= "" and ownerClan == plyClan then
                isSameClan = true
            end
        end
        
        if not isSameClan then return false end
    end
	
	ent.oldColor = ent:GetColor();
	ent.oldMat = ent:GetMaterial();
	
	ent:SetColor(Color(ent.oldColor.r, ent.oldColor.g, ent.oldColor.b, 100));
	ent:SetCollisionGroup(COLLISION_GROUP_WORLD);
end)

hook.Add("PhysgunDrop", "ZGPropKilLDrop", function(ply, ent)	
end)

local function freezeReal(ent)

	if (timer.Exists(ent:EntIndex().."_waitForPlayersToLeaveToFreezeReal")) then
		timer.Destroy(ent:EntIndex().."_waitForPlayersToLeaveToFreezeReal");
	end
	
	ent:SetColor(Color(ent.oldColor.r, ent.oldColor.g, ent.oldColor.b, 255));
	ent:SetMaterial(ent.oldMat);
	ent:SetCollisionGroup(COLLISION_GROUP_NONE);
	
end

local function waitForPlayersToLeave(ent)
	timer.Create(ent:EntIndex().."_waitForPlayersToLeaveToFreezeReal", 1, 0, function()
		local min = ent:LocalToWorld(ent:OBBMins());
		local max = ent:LocalToWorld(ent:OBBMaxs());
		local entities = ents.FindInBox(min, max);
		for k,v in ipairs(entities) do
			if (v:IsPlayer()) then
				return;
			end
		end
		
		freezeReal(ent);
	end)
end

hook.Add("OnPhysgunFreeze", "ZGPropKillFreeze", function(weap, physobj, ent, ply)
	local class = ent:GetClass()
    
    if class != "prop_physics" and class != "con_lootbox" and class != "ent_jack_sleepingbag" and class != "con_shkaf" then 
        return 
    end
	
	local min = ent:LocalToWorld(ent:OBBMins());
	local max = ent:LocalToWorld(ent:OBBMaxs());
	local foundEnts = ents.FindInBox(min, max);
	
	for k,v in ipairs(foundEnts) do
		if (v:IsPlayer()) then
			waitForPlayersToLeave(ent);
			return;
		end
	end	
	
	freezeReal(ent);
end)

hook.Add("OnEntityCreated", "ZGPropKillSpawnProp", function(ent)
	local class = ent:GetClass()
    
   	if class != "prop_physics" and class != "con_lootbox" and class != "ent_jack_sleepingbag" and class != "con_shkaf" then 
        return 
    end
	
	ent.oldColor = ent.oldColor or ent:GetColor();
	ent.oldMat = ent.oldMat or ent:GetMaterial();
	
	ent:SetRenderMode(RENDERMODE_TRANSALPHA);
	ent:SetColor(Color(ent.oldColor.r, ent.oldColor.g, ent.oldColor.b, 100));
	ent:SetCollisionGroup(COLLISION_GROUP_WORLD);
end)


-- шкаф


local function PreventSpawning(ply)
    if ply:IsSuperAdmin() then return end

    if not IsValid(ply.MyShkaf) then
        ply:ChatPrint("Сначала поставьте шкаф для размещения предметов!")
        return false
    end
end
hook.Add("PlayerSpawnProp", "Shkaf_PreventProp", PreventSpawning)
hook.Add("PlayerSpawnVehicle", "Shkaf_PreventVehicle", PreventSpawning)
hook.Add("PlayerSpawnNPC", "Shkaf_PreventNPC", PreventSpawning)
hook.Add("PlayerSpawnSWEP", "Shkaf_PreventSWEP", PreventSpawning)
hook.Add("PlayerSpawnSENT", "Shkaf_PreventSENT", function(ply, class)
    if ply:IsSuperAdmin() then return end

    if class == "con_shkaf" then
        if IsValid(ply.MyShkaf) then
            ply:ChatPrint("Вы можете поставить только один шкаф!")
            return false
        end

        local tr = ply:GetEyeTrace()
        local spawnPos = tr.HitPos
        local entTable = scripted_ents.Get("con_shkaf")
        local radius = (entTable and entTable.RadiusZona) or 1500
        local minDistance = radius * 2
        
        for _, ent in ipairs(ents.FindByClass("con_shkaf")) do
            if IsValid(ent) and ent.ShkafOwner ~= ply then
                local isSameClan = false
                if IsValid(ent.ShkafOwner) then
                    local ownerClan = ent.ShkafOwner:GetNWString("Clan", "")
                    local plyClan = ply:GetNWString("Clan", "")
                    if ownerClan ~= "" and ownerClan == plyClan then
                        isSameClan = true
                    end
                end

                if not isSameClan and ent:GetPos():DistToSqr(spawnPos) < (minDistance ^ 2) then
                    ply:ChatPrint("Эта территория пересекается с чужой приватной зоной!")
                    return false
                end
            end
        end
        return
    end
    
    local prevent = PreventSpawning(ply)
    if prevent == false then return false end

    if class == "con_lootbox" then
        local count = 0
        for _, ent in ipairs(ents.FindByClass("con_lootbox")) do
            if ent.ShkafOwner == ply then
                count = count + 1
            end
        end
        
        if count >= 6 then
            ply:ChatPrint("Вы достигли лимита: максимум 6 хранилищ!")
            return false
        end
    end
end)

hook.Add("PlayerSpawnedSENT", "Shkaf_RegisterOwner", function(ply, ent)
    if ent:GetClass() == "con_shkaf" then
        if IsValid(ply.MyShkaf) then
            ply.MyShkaf:Remove()
        end
        ply.MyShkaf = ent
        ent.ShkafOwner = ply
        ent.ShkafOwnerID = ply:SteamID()
        
    end
end)

hook.Add("PlayerInitialSpawn", "Shkaf_RestoreOwner", function(ply)
    for _, ent in ipairs(ents.FindByClass("con_shkaf")) do
        if ent.ShkafOwnerID == ply:SteamID() then
            ply.MyShkaf = ent
            ent.ShkafOwner = ply
            break
        end
    end
end)

local function CheckSpawnedItem(ply, ent)
    if ply:IsSuperAdmin() then return end
    
    if not IsValid(ply.MyShkaf) then
        ent:Remove()
        return
    end

    local radius = ply.MyShkaf.RadiusZona or 1500 
    
    if ent:GetPos():DistToSqr(ply.MyShkaf:GetPos()) > (radius ^ 2) then
        ent:Remove()
        ply:ChatPrint("Предмет удален: спавн вне приватной зоны шкафа!")
        return
    end

    ent.ShkafZoneProp = true
    ent.ShkafOwner = ply
end

hook.Add("PlayerSpawnedProp", "Shkaf_CheckPropSpawn", function(ply, model, ent) CheckSpawnedItem(ply, ent) end)
hook.Add("PlayerSpawnedVehicle", "Shkaf_CheckVehicleSpawn", function(ply, ent) CheckSpawnedItem(ply, ent) end)
hook.Add("PlayerSpawnedNPC", "Shkaf_CheckNPCSpawn", function(ply, ent) CheckSpawnedItem(ply, ent) end)
hook.Add("PlayerSpawnedSENT", "Shkaf_CheckSENTSpawn", function(ply, ent)
    if ent:GetClass() ~= "con_shkaf" then 
        CheckSpawnedItem(ply, ent) 
    end
end)

timer.Create("Shkaf_ZoneEnforcer", 1, 0, function()
    local shkafs = ents.FindByClass("con_shkaf")

    for _, ent in ipairs(ents.GetAll()) do
        if ent.ShkafZoneProp and IsValid(ent.ShkafOwner) then
            local shkaf = ent.ShkafOwner.MyShkaf
            
            if not IsValid(shkaf) then
                ent:Remove()
            else
                local radius = shkaf.RadiusZona or 1500
                if ent:GetPos():DistToSqr(shkaf:GetPos()) > (radius ^ 2) then
                    ent:Remove()
                    if IsValid(ent.ShkafOwner) then
                        ent.ShkafOwner:ChatPrint("Предмет удален: вынесен за пределы зоны!")
                    end
                end
            end
        end
    end

    for i = 1, #shkafs do
        local myShkaf = shkafs[i]
        if not IsValid(myShkaf) then continue end

        local radius1 = myShkaf.RadiusZona or 1500
        local minDistance = radius1 * 2

        for j = 1, #shkafs do
            if i == j then continue end
            
            local otherShkaf = shkafs[j]
            if not IsValid(otherShkaf) then continue end

            if myShkaf.ShkafOwner ~= otherShkaf.ShkafOwner then
                local isSameClan = false
                if IsValid(myShkaf.ShkafOwner) and IsValid(otherShkaf.ShkafOwner) then
                    local clan1 = myShkaf.ShkafOwner:GetNWString("Clan", "")
                    local clan2 = otherShkaf.ShkafOwner:GetNWString("Clan", "")
                    if clan1 ~= "" and clan1 == clan2 then
                        isSameClan = true
                    end
                end

                if not isSameClan and myShkaf:GetPos():DistToSqr(otherShkaf:GetPos()) < (minDistance ^ 2) then
                    local phys = myShkaf:GetPhysicsObject()
                    print(phys)
                    if IsValid(phys) and not phys:IsAsleep() or myShkaf:IsPlayerHolding() then
                        myShkaf:Remove()
                        local owner = myShkaf.ShkafOwner
                        if IsValid(owner) then
                            owner:ChatPrint("Ваш шкаф был удален: вы перенесли его в чужую приватную зону!")
                        end
                        break
                    end
                end
            end
        end
    end
end)