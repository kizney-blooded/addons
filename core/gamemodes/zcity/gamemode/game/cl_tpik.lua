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

    if !self.NoTPIKVMPos and self.ActivePos then 
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

    if !IsValid(owner) or !owner:IsPlayer() then return false end

    local should = (lp != owner) and (tpik_enabled and tpik_others) or tpik_enabled

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

function SWEP:DoTPIK(isdepth, target_ent)
    local wpn = LocalPlayer():GetActiveWeapon()

    if wpn.DrawWorldModel then
        wpn:DrawWorldModel()
    end

    local wm = self:GetWM()
    if !IsValid(wm) then return end

    if wm:GetPos():IsZero() and self.wmnormalpos then
        wm:SetPos(self.wmnormalpos)
        wm:SetAngles(self.wmnormalang)
    else
        self.wmnormalpos = wm:GetPos()
        self.wmnormalang = wm:GetAngles()
    end

    if !self:ShouldTPIK() then
        if cachelastcycle > 0 then wm:SetCycle(0) cachelastcycle = 0 end
        return
    end

    local ply = self:GetOwner()
    if !IsValid(ply) then return end
    
    local target = IsValid(target_ent) and target_ent or ply

    local isLocal = (ply == LocalPlayer())
    local tpikdelay = isLocal and 0 or (1 / math.Clamp(tpik_framerate_notyou, 5, 150))
    local shouldfulltpik = isLocal or (self.LastTPIKTime + tpikdelay <= CurTime())
    local tpikTweenAlpha = isLocal and 1 or TPIKIKTweenAlpha(1 / tpikdelay)

    local nolefthand = false
    local htype = self.GetHoldType and self:GetHoldType() or "normal"

    if !self.TPIKforcelefthand and (htype == "slam" or htype == "magic" or htype == "pistol" or htype == "normal" or self.TPIKnolefthand) then
        nolefthand = true
    end

    target:SetRenderMode(RENDERMODE_TRANSALPHA)

    if shouldfulltpik or (self.StillWaiting and self:StillWaiting()) then
        wm:SetupBones()

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

    target:SetupBones()

    local bones = nolefthand and kb.RHIKHandBones or kb.TPIKBones
    local ply_spine_index = GetCachedBoneIndex(target, "ValveBiped.Bip01_Spine4")
    if !ply_spine_index then return end
    
    local ply_spine_matrix = entityGetBoneMatrix(target, ply_spine_index)
    local wmpos = ply_spine_matrix:GetTranslation()

    for _, bone in ipairs(bones) do
        local wm_boneindex = GetCachedBoneIndex(wm, bone)
        if !wm_boneindex then continue end
        local wm_bonematrix = entityGetBoneMatrix(wm, wm_boneindex)
        if !wm_bonematrix then continue end

        local ply_boneindex = GetCachedBoneIndex(target, bone)
        if !ply_boneindex then continue end
        local ply_bonematrix = entityGetBoneMatrix(target, ply_boneindex)
        if !ply_bonematrix then continue end

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

    local ply_l_upperarm_index = GetCachedBoneIndex(target, "ValveBiped.Bip01_L_UpperArm")
    local ply_r_upperarm_index = GetCachedBoneIndex(target, "ValveBiped.Bip01_R_UpperArm")
    local ply_l_forearm_index = GetCachedBoneIndex(target, "ValveBiped.Bip01_L_Forearm")
    local ply_r_forearm_index = GetCachedBoneIndex(target, "ValveBiped.Bip01_R_Forearm")
    local ply_l_hand_index = GetCachedBoneIndex(target, "ValveBiped.Bip01_L_Hand")
    local ply_r_hand_index = GetCachedBoneIndex(target, "ValveBiped.Bip01_R_Hand")

    if !ply_l_upperarm_index or !ply_r_upperarm_index or !ply_l_forearm_index or !ply_r_forearm_index or !ply_l_hand_index or !ply_r_hand_index then return end

    -- Right Hand
    local ply_r_upperarm_matrix = entityGetBoneMatrix(target, ply_r_upperarm_index)
    local ply_r_forearm_matrix = entityGetBoneMatrix(target, ply_r_forearm_index)
    local ply_r_hand_matrix = entityGetBoneMatrix(target, ply_r_hand_index)

    local limblength = target:BoneLength(ply_l_forearm_index)
    if !limblength or limblength == 0 then limblength = 12 end

    local ply_r_upperarm_pos, ply_r_forearm_pos, ply_r_upperarm_angle, ply_r_forearm_angle
    local eyeahg = ply:EyeAngles()

    if htype == "passive" or htype == "normal" then 
        eyeahg.y = eyeahg.y - (ply:GetPoseParameter("aim_yaw") or 0) * 160 + 80 or 0
    end

    if shouldfulltpik or !(self.TPIKCache.r_upperarm_pos and self.TPIKCache.r_forearm_pos and self.TPIKCache.ply_r_upperarm_angle and self.TPIKCache.ply_r_forearm_angle) then
        ply_r_upperarm_pos, ply_r_forearm_pos, ply_r_upperarm_angle, ply_r_forearm_angle = self:Solve2PartIK(
            ply_r_upperarm_matrix:GetTranslation(), ply_r_hand_matrix:GetTranslation(), limblength, limblength, -1.3, eyeahg)
        self.LastTPIKTime = CurTime()

        self.TPIKCache.r_upperarm_pos, self.TPIKCache.ply_r_upperarm_angle = WorldToLocal(ply_r_upperarm_pos, ply_r_upperarm_angle, ply_r_upperarm_matrix:GetTranslation(), ply_r_upperarm_matrix:GetAngles())
        self.TPIKCache.r_forearm_pos, self.TPIKCache.ply_r_forearm_angle = WorldToLocal(ply_r_forearm_pos, ply_r_forearm_angle, ply_r_upperarm_matrix:GetTranslation(), ply_r_upperarm_matrix:GetAngles())
    end

    local rUpperPos = TPIKTweenVec(self, "r_upperarm_pos", self.TPIKCache.r_upperarm_pos, tpikTweenAlpha)
    local rUpperAng = TPIKTweenAng(self, "r_upperarm_ang", self.TPIKCache.ply_r_upperarm_angle, tpikTweenAlpha)
    local rForePos = TPIKTweenVec(self, "r_forearm_pos", self.TPIKCache.r_forearm_pos, tpikTweenAlpha)
    local rForeAng = TPIKTweenAng(self, "r_forearm_ang", self.TPIKCache.ply_r_forearm_angle, tpikTweenAlpha)

    ply_r_upperarm_pos, ply_r_upperarm_angle = LocalToWorld(rUpperPos, rUpperAng, ply_r_upperarm_matrix:GetTranslation(), ply_r_upperarm_matrix:GetAngles())
    ply_r_forearm_pos, ply_r_forearm_angle = LocalToWorld(rForePos, rForeAng, ply_r_upperarm_matrix:GetTranslation(), ply_r_upperarm_matrix:GetAngles())

    ply_r_upperarm_matrix:SetAngles(ply_r_upperarm_angle)
    ply_r_forearm_matrix:SetTranslation(ply_r_upperarm_pos)
    ply_r_forearm_matrix:SetAngles(ply_r_forearm_angle)
    ply_r_hand_matrix:SetTranslation(ply_r_forearm_pos) 

    bone_apply_matrix(target, ply_r_upperarm_index, ply_r_upperarm_matrix, ply_r_forearm_index)
    bone_apply_matrix(target, ply_r_forearm_index, ply_r_forearm_matrix, ply_r_hand_index)
    bone_apply_matrix(target, ply_r_hand_index, ply_r_hand_matrix)

    if nolefthand then return end

    -- Left Hand
    local ply_l_upperarm_matrix = entityGetBoneMatrix(target, ply_l_upperarm_index)
    local ply_l_forearm_matrix = entityGetBoneMatrix(target, ply_l_forearm_index)
    local ply_l_hand_matrix = entityGetBoneMatrix(target, ply_l_hand_index)

    local ply_l_upperarm_pos, ply_l_forearm_pos, ply_l_upperarm_angle, ply_l_forearm_angle

    if shouldfulltpik or !(self.TPIKCache.l_upperarm_pos and self.TPIKCache.l_forearm_pos and self.TPIKCache.ply_l_upperarm_angle and self.TPIKCache.ply_l_forearm_angle) then
        ply_l_upperarm_pos, ply_l_forearm_pos, ply_l_upperarm_angle, ply_l_forearm_angle = self:Solve2PartIK(
            ply_l_upperarm_matrix:GetTranslation(), ply_l_hand_matrix:GetTranslation(), limblength, limblength, 1, eyeahg)
        
        self.LastTPIKTime = CurTime()
        self.TPIKCache.l_upperarm_pos, self.TPIKCache.ply_l_upperarm_angle = WorldToLocal(ply_l_upperarm_pos, ply_l_upperarm_angle, ply_l_upperarm_matrix:GetTranslation(), ply_l_upperarm_matrix:GetAngles())
        self.TPIKCache.l_forearm_pos, self.TPIKCache.ply_l_forearm_angle = WorldToLocal(ply_l_forearm_pos, ply_l_forearm_angle, ply_l_upperarm_matrix:GetTranslation(), ply_l_upperarm_matrix:GetAngles())
    end

    local lUpperPos = TPIKTweenVec(self, "l_upperarm_pos", self.TPIKCache.l_upperarm_pos, tpikTweenAlpha)
    local lUpperAng = TPIKTweenAng(self, "l_upperarm_ang", self.TPIKCache.ply_l_upperarm_angle, tpikTweenAlpha)
    local lForePos = TPIKTweenVec(self, "l_forearm_pos", self.TPIKCache.l_forearm_pos, tpikTweenAlpha)
    local lForeAng = TPIKTweenAng(self, "l_forearm_ang", self.TPIKCache.ply_l_forearm_angle, tpikTweenAlpha)

    ply_l_upperarm_pos, ply_l_upperarm_angle = LocalToWorld(lUpperPos, lUpperAng, ply_l_upperarm_matrix:GetTranslation(), ply_l_upperarm_matrix:GetAngles())
    ply_l_forearm_pos, ply_l_forearm_angle = LocalToWorld(lForePos, lForeAng, ply_l_upperarm_matrix:GetTranslation(), ply_l_upperarm_matrix:GetAngles())

    ply_l_upperarm_matrix:SetAngles(ply_l_upperarm_angle)
    ply_l_forearm_matrix:SetTranslation(ply_l_upperarm_pos)
    ply_l_forearm_matrix:SetAngles(ply_l_forearm_angle)
    ply_l_hand_matrix:SetTranslation(ply_l_forearm_pos)

    bone_apply_matrix(target, ply_l_upperarm_index, ply_l_upperarm_matrix, ply_l_forearm_index)
    bone_apply_matrix(target, ply_l_forearm_index, ply_l_forearm_matrix, ply_l_hand_index)
    bone_apply_matrix(target, ply_l_hand_index, ply_l_hand_matrix)
end

hook.Add("PrePlayerDraw", "kb_TPIK_Draw", function(ply, flags)
    if ply then
        local tick = FrameNumber()
        if ply.kb_LastTPIKTick != tick or flags != 0 then
            ply.kb_LastTPIKTick = tick

            local wpn = ply:GetActiveWeapon()
            if IsValid(wpn) and wpn.DoTPIK then
                ply:InvalidateBoneCache()
                wpn:DoTPIK(flags == 134217729)
            end
        end
    end
end)

hook.Add("PreDrawOpaqueRenderables", "kb_TPIK_Ragdoll_Draw", function(isDrawingDepth, isDrawSkybox)
    if isDrawSkybox then return end

    for _, ply in player.Iterator() do
        local rag = ply:GetNWEntity("FakeRagdoll")
        
        if IsValid(rag) or (ply:GetNoDraw() and ply:Alive()) then
            local wpn = ply:GetActiveWeapon()
            if IsValid(wpn) then

                if wpn.DoTPIK then
                    local target = IsValid(rag) and rag or ply
                    target:InvalidateBoneCache()
                    wpn:DoTPIK(isDrawingDepth, target)
                end
            end
        end
    end
end)