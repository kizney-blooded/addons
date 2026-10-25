JMod.ArmorTableOffsetCache = {}
function JMod.CopyArmorTableForModel(plyMdl)
	JMod.ArmorTableOffsetCache = JMod.ArmorTableOffsetCache or {}
	if plyMdl and JMod.LuaConfig and JMod.LuaConfig.ArmorOffsets and JMod.LuaConfig.ArmorOffsets[plyMdl] then
		JMod.ArmorTableOffsetCache[plyMdl] = {}
		for k, v in pairs(JMod.LuaConfig.ArmorOffsets[plyMdl]) do
			JMod.ArmorTableOffsetCache[plyMdl][k] = table.Merge(table.FullCopy(JMod.ArmorTable[k]), v)
		end
	end
end

function JMod.CopyAllArmorOffsets()
	if JMod.LuaConfig and JMod.LuaConfig.ArmorOffsets and JMod.LuaConfig.ArmorOffsets then
		for k, v in pairs(JMod.LuaConfig.ArmorOffsets) do
			JMod.CopyArmorTableForModel(k)
		end
	end
end

function JMod.ArmorPlayerModelDraw(ply, nomerge)
	if not IsValid(ply) or not ply.EZarmor then return end
	if not ply.EZarmorModels then ply.EZarmorModels = {} end

	local isClient = ply == LocalPlayer() and GetViewEntity() == ply

	local targetEnt = ply
	local fakeRag = ply:GetNWEntity("FakeRagdoll")
	if IsValid(fakeRag) then
		targetEnt = fakeRag
	end

	if not JMod.ArmorTableOffsetCache or table.IsEmpty(JMod.ArmorTableOffsetCache) then
		JMod.CopyAllArmorOffsets()
	end

	local plyMdl = targetEnt:GetModel() or ply:GetModel()

	if not JMod.ArmorTableOffsetCache[plyMdl] then
		JMod.CopyArmorTableForModel(plyMdl)
	end

	local plyboneedit = {}

	for id, armorData in pairs(ply.EZarmor.items) do
		local ArmorInfo = JMod.ArmorTableOffsetCache[plyMdl] and JMod.ArmorTableOffsetCache[plyMdl][armorData.name] or JMod.ArmorTable[armorData.name]

		if not ArmorInfo then continue end
		if armorData.tgl and ArmorInfo.tgl then
			ArmorInfo = table.Merge(table.FullCopy(ArmorInfo), ArmorInfo.tgl)
			for k, v in pairs(ArmorInfo.tgl) do
				if type(v) == "table" and #table.GetKeys(v) == 0 then
					ArmorInfo[k] = {}
				end
			end
		end

		if isClient and ArmorInfo.bon == "ValveBiped.Bip01_Head1" and targetEnt == ply then 
			continue 
		end

		if IsValid(ply.EZarmorModels[id]) then
			local Mdl = ply.EZarmorModels[id]
			local MdlName = string.lower(Mdl:GetModel())

			if Mdl.EZArmor_CurrentParent ~= targetEnt then
				if ArmorInfo.merge and not(nomerge) then
					Mdl:SetParent(targetEnt, 0)
					Mdl:AddEffects(EF_BONEMERGE)
					Mdl:AddEffects(EF_BONEMERGE_FASTCULL)
				else
					Mdl:SetParent(targetEnt)
				end
				Mdl.EZArmor_CurrentParent = targetEnt
			end

			if MdlName == ArmorInfo.mdl and ArmorInfo.bon then
				local Index = targetEnt:LookupBone(ArmorInfo.bon)

				if Index then
					local Matric = targetEnt:GetBoneMatrix(Index)
					if Matric then
						local Pos, Ang = Matric:GetTranslation(), Matric:GetAngles()

						if Pos and Ang then
							if not(ArmorInfo.merge) or nomerge then
								local Right, Forward, Up = Ang:Right(), Ang:Forward(), Ang:Up()
								Pos = Pos + Right * ArmorInfo.pos.x + Forward * ArmorInfo.pos.y + Up * ArmorInfo.pos.z
								Ang:RotateAroundAxis(Right, ArmorInfo.ang.p)
								Ang:RotateAroundAxis(Up, ArmorInfo.ang.y)
								Ang:RotateAroundAxis(Forward, ArmorInfo.ang.r)
								Mdl:SetRenderOrigin(Pos)
								Mdl:SetRenderAngles(Ang)
								local Mat = Matrix()
								Mat:Scale(ArmorInfo.siz)
								Mdl:EnableMatrix("RenderMultiply", Mat)
							else
								Mdl:SetupBones()
								for i = 0, Mdl:GetBoneCount() do
									Mdl:ManipulateBoneScale(i, ArmorInfo.siz)
								end
							end
							if ArmorInfo.bdg then
								for k, v in pairs(ArmorInfo.bdg) do
									Mdl:SetBodygroup(k, v)
								end
							end

							if ArmorInfo.skin then
								Mdl:SetSkin(ArmorInfo.skin)
							end

							local OldR, OldG, OldB = render.GetColorModulation()
							local Colr = armorData.col
							if (not(ArmorInfo.merge) or nomerge) then
								render.SetColorModulation(Colr.r / 255, Colr.g / 255, Colr.b / 255)
							else
								Mdl:SetColor(Color(Colr.r, Colr.g, Colr.b))
							end

							local NoDraw = hook.Run("JMod_ArmorModelDraw", ply, Mdl, armorData, ArmorInfo)

							if not(NoDraw) and (not(ArmorInfo.merge) or nomerge) then
								Mdl:DrawModel()
							end
							render.SetColorModulation(OldR, OldG, OldB)
						end
					end

					if ArmorInfo.bonsiz then
						ply.EZarmorboneedited = true
						plyboneedit[Index] = ArmorInfo.bonsiz
					end
				end
			else
				ply.EZarmorModels[id]:Remove()
				ply.EZarmorModels[id] = nil
			end
		else
			local Mdl = ClientsideModel(ArmorInfo.mdl)
			Mdl:SetModel(ArmorInfo.mdl)
			Mdl:SetMaterial(ArmorInfo.mat or "")
			Mdl:SetMoveType(MOVETYPE_NONE)
			if ArmorInfo.merge and not(nomerge) then
				Mdl:SetParent(targetEnt, 0)
				Mdl:AddEffects(EF_BONEMERGE)
				Mdl:AddEffects(EF_BONEMERGE_FASTCULL)
			else
				Mdl:SetPos(targetEnt:GetPos())
				Mdl:SetParent(targetEnt)
				Mdl:SetNoDraw(true)
			end
			Mdl.EZArmor_CurrentParent = targetEnt
			ply.EZarmorModels[id] = Mdl
		end
	end
	if ply.EZarmorboneedited then
		local edited = false
		for k = 1, targetEnt:GetBoneCount() do
			if targetEnt:GetManipulateBoneScale(k) ~= (plyboneedit[k] or Vector(1, 1, 1)) then
				targetEnt:ManipulateBoneScale(k, plyboneedit[k] or Vector(1, 1, 1))
			end
			if targetEnt:GetManipulateBoneScale(k) ~= Vector(1, 1, 1) then
				edited = true
			end
		end
		if not edited then
			ply.EZarmorboneedited = false
		end
	end
end

hook.Add("JMod_ArmorModelDraw", "JMod_NoDrawArmorSweps", function(ply, Mdl, ArmorData, ArmorInfo) 
	if ArmorInfo.eff and ArmorInfo.eff.weapon then
		if IsValid(ply) and ply:IsPlayer() then
			local wep = ply:GetActiveWeapon()
			if IsValid(wep) and (wep:GetClass() == ArmorInfo.eff.weapon) and not(IsValid(JMod.GetPlayerHeldEntity(ply))) then
				if ArmorInfo.merge then
					Mdl:SetNoDraw(true)
				else
					return true
				end
			elseif ArmorInfo.merge then
				Mdl:SetNoDraw(false)
			end
		end
	end
end)

hook.Add("PostPlayerDraw", "JMOD_ArmorPlayerDraw", function(ply)
	if not IsValid(ply) then return end
	JMod.ArmorPlayerModelDraw(ply)
end)

hook.Add("PostDrawOpaqueRenderables", "JMOD_ArmorRagdollDraw", function(bDepth, bSkybox)
	if bDepth or bSkybox then return end

	for _, ply in player.Iterator() do
		if IsValid(ply) and IsValid(ply:GetNWEntity("FakeRagdoll")) then
			JMod.ArmorPlayerModelDraw(ply)
		end
	end

	if JMod.ArmorRagdolls then
		for rag, _ in pairs(JMod.ArmorRagdolls) do
			if IsValid(rag) then
				JMod.ArmorPlayerModelDraw(rag)
			else
				JMod.ArmorRagdolls[rag] = nil
			end
		end
	end
end)

net.Receive("JMod_EZarmorSync", function()
	local ply = net.ReadEntity()
	local IsDamageUpdate = net.ReadBool()
	if IsDamageUpdate then
		local ArmorID = net.ReadString()
		local NewDurability = net.ReadFloat()
		if not ply.EZarmor then ply.EZarmor = table.FullCopy(JMod.DEFAULT_ARMOR) end
		for id, armorData in pairs(ply.EZarmor.items) do
			if ArmorID == id then
				armorData.dur = NewDurability
				return
			end
		end
	else
		ply.EZarmor = net.ReadTable()
	end

	if ply.EZarmorModels then
		for k, v in pairs(ply.EZarmorModels) do
			local NoMatch = true
			for id, armorData in pairs(ply.EZarmor.items) do
				if k == id then
					NoMatch = false 
					break
				end
			end
			if NoMatch then
				v:Remove()
				v = nil
				ply.EZarmorModels[k] = nil
			end
		end
	end
end)

JMod.ArmorRagdolls = JMod.ArmorRagdolls or {}

net.Receive("KB_SyncRagdollArmor", function()
	local rag = net.ReadEntity()
	local armor = net.ReadTable()
	
	if IsValid(rag) then
		rag.EZarmor = armor
		JMod.ArmorRagdolls[rag] = true
		
		if rag.EZarmorModels then
			for k, v in pairs(rag.EZarmorModels) do
				local NoMatch = true
				if rag.EZarmor and rag.EZarmor.items then
					for id, armorData in pairs(rag.EZarmor.items) do
						if k == id then
							NoMatch = false 
							break
						end
					end
				end
				if NoMatch then
					if IsValid(v) then v:Remove() end
					rag.EZarmorModels[k] = nil
				end
			end
		end
	end
end)

hook.Add("EntityRemoved", "JMod_ArmorRagdollCleanup", function(ent)
	if ent.EZarmorModels then
		for k, v in pairs(ent.EZarmorModels) do
			if IsValid(v) then v:Remove() end
		end
	end
	if JMod.ArmorRagdolls and JMod.ArmorRagdolls[ent] then
		JMod.ArmorRagdolls[ent] = nil
	end
end)

concommand.Add("jmod_debug_countclientsidemodels", function()
	print("Entity count : ")
	local entite = {}
	local i = 0

	for k, v in pairs(ents.FindByClass("*C_BaseFlex")) do
		if v:GetModel() == nil then continue end
		if entite[v:GetModel()] == nil then
			entite[v:GetModel()] = 0
		end
		entite[v:GetModel()] = entite[v:GetModel()] + 1
		i = i + 1
	end

	print(i)
	print("-")
	print("- CLIENTSIDE STUFF START :")
	print("-")
	for k, v in pairs(entite) do
		print(v .. " : " .. k)
	end
	print("-")
	print("- CLIENTSIDE STUFF END ...")
	print("-")
end, nil, "Poluxtobee's CS model debug")