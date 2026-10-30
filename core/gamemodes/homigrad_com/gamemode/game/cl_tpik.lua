-- https://steamcommunity.com/sharedfiles/filedetails/?id=2910505837 arc9 base хола амига
local FrameNumber = FrameNumber
local tpik_enabled = true
local tpik_others = true
local tpik_framerate_you = 60
local tpik_framerate_notyou = 20

local ENTITY = FindMetaTable("Entity")
local SWEP = FindMetaTable("Weapon")
local entityGetBoneMatrix = ENTITY.GetBoneMatrix
local entitySetBoneMatrix = ENTITY.SetBoneMatrix

local TPIKBoneIndexCache = setmetatable({}, { __mode = "k" })

local function GetCachedBoneIndex(ent, boneName)
    if not IsValid(ent) or not boneName then return nil end
    local mdl = ent:GetModel() or ""
    local cache = TPIKBoneIndexCache[ent]
    if not cache or cache.mdl ~= mdl then
        cache = { mdl = mdl, bones = {} }
        TPIKBoneIndexCache[ent] = cache
    end

    local cached = cache.bones[boneName]
    if cached ~= nil then return cached ~= false and cached or nil end

    local idx = ent:LookupBone(boneName)
    cache.bones[boneName] = idx or false
    return idx
end

local cached_children = {}

local function recursive_get_children(ent, bone, bones, endbone)
    local bone = isstring(bone) and GetCachedBoneIndex(ent, bone) or bone
    if not bone or isstring(bone) or bone == -1 then return end

    local children = ent:GetChildBones(bone)
    if children and #children > 0 then
        local id
        for i = 1, #children do
            id = children[i]
            if id == endbone then continue end
            recursive_get_children(ent, id, bones, endbone)
            table.insert(bones, id)
        end
    end
end

local function get_children(ent, bone, endbone)
    local mdl = ent:GetModel() or ""
    local modelCache = cached_children[mdl]
    if not modelCache then
        modelCache = {}
        cached_children[mdl] = modelCache
    end

    local key = tostring(bone) .. ":" .. tostring(endbone or "")
    local cached = modelCache[key]
    if cached then return cached end

    local bones = {}
    recursive_get_children(ent, bone, bones, endbone)
    modelCache[key] = bones
    return bones
end

local function bone_apply_matrix(ent, bone, new_matrix, endbone)
    local bone = isstring(bone) and ent:LookupBone(bone) or bone
    if not bone or isstring(bone) or bone == -1 then return end

    local matrix = entityGetBoneMatrix(ent, bone)
    if not matrix then return end
    local inv_matrix = matrix:GetInverse()
    if not inv_matrix then return end

    local children = get_children(ent, bone, endbone)
    local translate = (new_matrix * inv_matrix)
    
    for i = 1, #children do
        local id = children[i]
        local mat = entityGetBoneMatrix(ent, id)
        if not mat then continue end
        local moved = translate * mat
        entitySetBoneMatrix(ent, id, moved)
        ent:SetBonePosition(id, moved:GetTranslation(), moved:GetAngles())
    end

    entitySetBoneMatrix(ent, bone, new_matrix)
    ent:SetBonePosition(bone, new_matrix:GetTranslation(), new_matrix:GetAngles())
end

local function SetTPIKOffset(self, wm, owner, lp)
    local pos = Vector(self.WorldModelOffset and (self.WorldModelOffset.TPIKPos or self.WorldModelOffset.Pos) or vector_origin)
    local ang = Angle(self.WorldModelOffset and (self.WorldModelOffset.TPIKAng or self.WorldModelOffset.Ang) or angle_zero)

    if not self.NoTPIKVMPos and self.ActivePos then 
        local apos = Vector(self.ActivePos.y, -self.ActivePos.x, self.ActivePos.z) * Vector(-1, -1, 1)
        pos:Sub(apos)
    end

    wm.slottbl.Pos = pos
    wm.slottbl.Ang = ang
end

function SWEP:ShouldTPIK()
    if not self.SupportTPIK then return false end
    local owner = self:GetOwner()
    local lp = LocalPlayer()

    if not IsValid(owner) or not owner:IsPlayer() then return false end

    local should = (lp ~= owner) and (tpik_enabled and tpik_others) or tpik_enabled

    local wm = self:GetWM()
    if IsValid(wm) and wm.slottbl then
        if should then
            SetTPIKOffset(self, wm, owner, lp)
        else
            wm.slottbl.Pos = self.WorldModelOffset and self.WorldModelOffset.Pos or vector_origin
            wm.slottbl.Ang = self.WorldModelOffset and self.WorldModelOffset.Ang or angle_zero
        end
    end

    return should
end

SWEP.TPIKCache = {}
SWEP.LastTPIKTime = 0
local cachelastcycle = 0

local function TPIKIKTweenAlpha(speed)
    speed = math.Clamp(speed * 1.5, 1, 60)
    return math.Clamp(1 - math.exp(-speed * RealFrameTime()), 0, 1)
end

local TPIK_EPS = 0.0001
local function TPIKVecAlmostEqual(a, b) return a and b and math.abs(a.x - b.x) <= TPIK_EPS and math.abs(a.y - b.y) <= TPIK_EPS and math.abs(a.z - b.z) <= TPIK_EPS end
local function TPIKAngAlmostEqual(a, b) return a and b and math.abs(a.p - b.p) <= TPIK_EPS and math.abs(a.y - b.y) <= TPIK_EPS and math.abs(a.r - b.r) <= TPIK_EPS end
local function TPIKCopyVec(dst, src) dst.x, dst.y, dst.z = src.x, src.y, src.z return dst end
local function TPIKCopyAng(dst, src) dst.p, dst.y, dst.r = src.p, src.y, src.r return dst end

local function TPIKTweenVec(self, key, target, alpha)
    local cache = self.TPIKIKTweenCache or {}
    self.TPIKIKTweenCache = cache
    local current = cache[key]

    if not current then
        cache[key] = Vector(target.x, target.y, target.z)
        return cache[key]
    end

    if TPIKVecAlmostEqual(current, target) then return current end
    if alpha >= 1 then return TPIKCopyVec(current, target) end

    current.x = current.x + (target.x - current.x) * alpha
    current.y = current.y + (target.y - current.y) * alpha
    current.z = current.z + (target.z - current.z) * alpha
    return current
end

local function TPIKTweenAng(self, key, target, alpha)
    if not target then return target end
    local cache = self.TPIKIKTweenCache or {}
    self.TPIKIKTweenCache = cache
    local current = cache[key]

    if not current then
        cache[key] = Angle(target.p, target.y, target.r)
        return cache[key]
    end

    if TPIKAngAlmostEqual(current, target) then return current end
    if alpha >= 1 then return TPIKCopyAng(current, target) end

    current.p = current.p + math.AngleDifference(target.p, current.p) * alpha
    current.y = current.y + math.AngleDifference(target.y, current.y) * alpha
    current.r = current.r + math.AngleDifference(target.r, current.r) * alpha
    return current
end

local function ProcessHandIK(self, target, limblength, eyeahg, shouldfulltpik, tpikTweenAlpha, isLeft)
    local prefix = isLeft and "l" or "r"
    local boneStr = isLeft and "ValveBiped.Bip01_L_" or "ValveBiped.Bip01_R_"
    
    local upperarm_index = GetCachedBoneIndex(target, boneStr .. "UpperArm")
    local forearm_index = GetCachedBoneIndex(target, boneStr .. "Forearm")
    local hand_index = GetCachedBoneIndex(target, boneStr .. "Hand")

    if not (upperarm_index and forearm_index and hand_index) then return end

    local upperarm_matrix = entityGetBoneMatrix(target, upperarm_index)
    local forearm_matrix = entityGetBoneMatrix(target, forearm_index)
    local hand_matrix = entityGetBoneMatrix(target, hand_index)

    if not (upperarm_matrix and forearm_matrix and hand_matrix) then return end

    local upperarm_pos, forearm_pos, upperarm_angle, forearm_angle
    local sign = isLeft and 1 or -1.3

    if shouldfulltpik or not (self.TPIKCache[prefix.."_upperarm_pos"] and self.TPIKCache[prefix.."_forearm_pos"] and self.TPIKCache["ply_"..prefix.."_upperarm_angle"] and self.TPIKCache["ply_"..prefix.."_forearm_angle"]) then
        upperarm_pos, forearm_pos, upperarm_angle, forearm_angle = self:Solve2PartIK(
            upperarm_matrix:GetTranslation(), hand_matrix:GetTranslation(), limblength, limblength, sign, eyeahg)
        
        self.LastTPIKTime = CurTime()
        self.TPIKCache[prefix.."_upperarm_pos"], self.TPIKCache["ply_"..prefix.."_upperarm_angle"] = WorldToLocal(upperarm_pos, upperarm_angle, upperarm_matrix:GetTranslation(), upperarm_matrix:GetAngles())
        self.TPIKCache[prefix.."_forearm_pos"], self.TPIKCache["ply_"..prefix.."_forearm_angle"] = WorldToLocal(forearm_pos, forearm_angle, upperarm_matrix:GetTranslation(), upperarm_matrix:GetAngles())
    end

    local tUpperPos = TPIKTweenVec(self, prefix.."_upperarm_pos", self.TPIKCache[prefix.."_upperarm_pos"], tpikTweenAlpha)
    local tUpperAng = TPIKTweenAng(self, prefix.."_upperarm_ang", self.TPIKCache["ply_"..prefix.."_upperarm_angle"], tpikTweenAlpha)
    local tForePos = TPIKTweenVec(self, prefix.."_forearm_pos", self.TPIKCache[prefix.."_forearm_pos"], tpikTweenAlpha)
    local tForeAng = TPIKTweenAng(self, prefix.."_forearm_ang", self.TPIKCache["ply_"..prefix.."_forearm_angle"], tpikTweenAlpha)

    upperarm_pos, upperarm_angle = LocalToWorld(tUpperPos, tUpperAng, upperarm_matrix:GetTranslation(), upperarm_matrix:GetAngles())
    forearm_pos, forearm_angle = LocalToWorld(tForePos, tForeAng, upperarm_matrix:GetTranslation(), upperarm_matrix:GetAngles())

    upperarm_matrix:SetAngles(upperarm_angle)
    forearm_matrix:SetTranslation(upperarm_pos)
    forearm_matrix:SetAngles(forearm_angle)
    hand_matrix:SetTranslation(forearm_pos) 

    bone_apply_matrix(target, upperarm_index, upperarm_matrix, forearm_index)
    bone_apply_matrix(target, forearm_index, forearm_matrix, hand_index)
    bone_apply_matrix(target, hand_index, hand_matrix)
end

function SWEP:DoTPIK(isdepth, target_ent)
    local wm = self:GetWM()
    if not IsValid(wm) then return end

    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    
    local target = IsValid(target_ent) and target_ent or ply

    wm:SetupBones()
    target:SetupBones()

    if self.UpdateWorldModelTransform then
        self:UpdateWorldModelTransform()
    end

    if wm:GetPos():IsZero() and self.wmnormalpos then
        wm:SetPos(self.wmnormalpos)
        wm:SetAngles(self.wmnormalang)
    else
        self.wmnormalpos = wm:GetPos()
        self.wmnormalang = wm:GetAngles()
    end

    if not self:ShouldTPIK() then
        if cachelastcycle > 0 then wm:SetCycle(0) cachelastcycle = 0 end
        return
    end

    local isLocal = (ply == LocalPlayer())
    local tpikdelay = isLocal and 0 or (1 / math.Clamp(tpik_framerate_notyou, 5, 150))
    local shouldfulltpik = isLocal or (self.LastTPIKTime + tpikdelay <= CurTime())
    local tpikTweenAlpha = isLocal and 1 or TPIKIKTweenAlpha(1 / tpikdelay)

    local nolefthand = false
    local htype = self.GetHoldType and self:GetHoldType() or "normal"

    if not self.TPIKforcelefthand and (htype == "slam" or htype == "magic" or htype == "pistol" or htype == "normal" or self.TPIKnolefthand) then
        nolefthand = true
    end

    target:SetRenderMode(RENDERMODE_TRANSALPHA)

    if shouldfulltpik or (self.StillWaiting and self:StillWaiting()) then

        local time = self.GetSequenceCycle and self:GetSequenceCycle() or 0
        local seqCache = self.TPIKSequenceCache
        local wmModel = wm:GetModel() or ""
        
        if not seqCache or seqCache.model ~= wmModel then
            seqCache = { model = wmModel, idle = wm:LookupSequence("idle") }
            self.TPIKSequenceCache = seqCache
        end

        wm:SetSequence(self.CurrentTPIKAnim or seqCache.idle or 0)
        wm:SetCycle(time)
        cachelastcycle = time
        wm:InvalidateBoneCache()
    end

    local bones = nolefthand and kb.RHIKHandBones or kb.TPIKBones
    local ply_spine_index = GetCachedBoneIndex(target, "ValveBiped.Bip01_Spine4")
    if not ply_spine_index then return end
    
    local ply_spine_matrix = entityGetBoneMatrix(target, ply_spine_index)
    if not ply_spine_matrix then return end
    local wmpos = ply_spine_matrix:GetTranslation()

    for _, bone in ipairs(bones) do
        local wm_boneindex = GetCachedBoneIndex(wm, bone)
        if not wm_boneindex then continue end
        local wm_bonematrix = entityGetBoneMatrix(wm, wm_boneindex)
        if not wm_bonematrix then continue end

        local ply_boneindex = GetCachedBoneIndex(target, bone)
        if not ply_boneindex then continue end
        local ply_bonematrix = entityGetBoneMatrix(target, ply_boneindex)
        if not ply_bonematrix then continue end

        local bonepos = wm_bonematrix:GetTranslation()
        local boneang = wm_bonematrix:GetAngles()

        bonepos.x = math.Clamp(bonepos.x, wmpos.x - 38, wmpos.x + 38)
        bonepos.y = math.Clamp(bonepos.y, wmpos.y - 38, wmpos.y + 38)
        bonepos.z = math.Clamp(bonepos.z, wmpos.z - 38, wmpos.z + 38)

        ply_bonematrix:SetTranslation(bonepos)
        ply_bonematrix:SetAngles(boneang)
        entitySetBoneMatrix(target, ply_boneindex, ply_bonematrix)
        target:SetBonePosition(ply_boneindex, bonepos, boneang)
    end

    local ply_l_forearm_index = GetCachedBoneIndex(target, "ValveBiped.Bip01_L_Forearm")
    if not ply_l_forearm_index then return end
    
    local limblength = target:BoneLength(ply_l_forearm_index)
    if not limblength or limblength == 0 then limblength = 12 end

    local eyeahg = ply:EyeAngles()
    if htype == "passive" or htype == "normal" then 
        eyeahg.y = eyeahg.y - (ply:GetPoseParameter("aim_yaw") or 0) * 160 + 80 or 0
    end

    ProcessHandIK(self, target, limblength, eyeahg, shouldfulltpik, tpikTweenAlpha, false)

    if nolefthand then return end

    ProcessHandIK(self, target, limblength, eyeahg, shouldfulltpik, tpikTweenAlpha, true)
    -- я гений
    local l_hand = GetCachedBoneIndex(target, "ValveBiped.Bip01_L_Hand")
    local l_att = GetCachedBoneIndex(target, "ValveBiped.Anim_Attachment_LH")
    if l_hand and l_att then
        local mat = entityGetBoneMatrix(target, l_hand)
        if mat then
            entitySetBoneMatrix(target, l_att, mat)
            target:SetBonePosition(l_att, mat:GetTranslation(), mat:GetAngles())
        end
    end

    local r_hand = GetCachedBoneIndex(target, "ValveBiped.Bip01_R_Hand")
    local r_att = GetCachedBoneIndex(target, "ValveBiped.Anim_Attachment_RH")
    if r_hand and r_att then
        local mat = entityGetBoneMatrix(target, r_hand)
        if mat then
            entitySetBoneMatrix(target, r_att, mat)
            target:SetBonePosition(r_att, mat:GetTranslation(), mat:GetAngles())
        end
    end
end

hook.Add("PrePlayerDraw", "kb_TPIK_Draw", function(ply, flags)
    if ply then
        local tick = FrameNumber()
        if ply.kb_LastTPIKTick ~= tick or flags ~= 0 then
            ply.kb_LastTPIKTick = tick

            local wpn = ply:GetActiveWeapon()
            if IsValid(wpn) and wpn.DoTPIK then
                wpn:DoTPIK(flags == 134217729)
            end
        end
    end
end)

hook.Add("PreDrawOpaqueRenderables", "kb_TPIK_Ragdoll_Draw", function(isDrawingDepth, isDrawSkybox)
    if isDrawSkybox then return end

    for _, ply in player.Iterator() do
        local rag = ply:GetNWEntity("FakeRagdoll")

        if ply:GetNWBool("Otrub") then return end
        
        if IsValid(rag) or (ply:GetNoDraw() and ply:Alive()) then
            local wpn = ply:GetActiveWeapon()
            if IsValid(wpn) and wpn.DoTPIK then
                local target = IsValid(rag) and rag or ply
                wpn:DoTPIK(isDrawingDepth, target)

                if wpn.GetWM then
                    local wm = wpn:GetWM()
                    if IsValid(wm) then
                        wm:DrawModel()
                    end
                else
                    wpn:DrawModel()
                end
            end
        end
    end
end)