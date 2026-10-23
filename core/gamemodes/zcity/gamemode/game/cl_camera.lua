local vec0 = Vector(0,0,0)
local vec1 = Vector(1,1,1)

local smooth_angle = Angle(0,0,0)

local eyes


local blacklist_weps = {
    ["weapon_physgun"] = true,
    ["gmod_tool"] = true,
}

hook.Add( "CalcView", "MyCalcView", function( ply, pos, angles, fov )

    local set_fov = 100

    if ply:Alive() then

        local rag = ply:GetNWEntity("FakeRagdoll")
        local target = IsValid(rag) and rag or ply

        local get_eyes = target:LookupAttachment("eyes")
        eyes = target:GetAttachment(get_eyes)

        if GetViewEntity() != ply then
            local view = {
                origin = pos,
                angles = angles,
                fov = set_fov,
                drawviewer = true,
                znear = 1
            } 
            return view 
        end
        
    end

    local ft = FrameTime()
    
    local punch = ply:GetViewPunchAngles()
    
    local base_angles = angles - punch
    
    smooth_angle = LerpAngle(ft * 15, smooth_angle, base_angles)
    
    local result_angle = smooth_angle + punch

    local set_origin = ply:Alive() and eyes and eyes.Pos or pos

    local wep = ply:GetActiveWeapon()

    if IsValid(wep) and blacklist_weps[wep:GetClass()] then 
        local view = {
            origin = pos,
            angles = angles,
            fov = set_fov,
            drawviewer = false,
            znear = 1
        } 
        return view
    end

    if IsValid(wep) and wep.calcview_sight then
        set_origin, result_angle, set_fov = wep:calcview_sight(ply, set_origin, result_angle, set_fov)
    end
 
    local view = {
        origin = set_origin,
        angles = result_angle,
        fov = set_fov,
        drawviewer = true,
        znear = 1
    }

    main_origin = view.origin
    main_angles = view.angles
    main_fov = view.fov

    return view
end )

hook.Add("Think","HideHead",function()
	local ply = LocalPlayer()

	if not ply:Alive() then return end
	
	local rag = ply:GetNWEntity("FakeRagdoll")

	local target = IsValid(rag) and rag or ply

	local head = target:LookupBone("ValveBiped.Bip01_Head1")

	if GetViewEntity() != ply then
		target:ManipulateBoneScale(head,vec1)
	else
		target:ManipulateBoneScale(head,vec0)
	end
end)

local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
    ["CHudCrosshair"] = true,
    
    ["CHudSecondaryAmmo"] = true,
    ["CHudAmmo"] = true,
}


hook.Add( "HUDShouldDraw", "HideHUD", function( name )if ( hide[ name ] ) then return false end end )

hook.Add("InputMouseApply", "asdasd2", function(cmd, x, y, angle)
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then 
        angle[3] = 0
		cmd:SetViewAngles(angle)
        return 
    end
	
	local follow = ply:GetNWEntity("FakeRagdoll")
    
	if not IsValid(follow) then
		angle[3] = 0
		cmd:SetViewAngles(angle)
		return
	end

	local att = follow:GetAttachment(follow:LookupAttachment("eyes"))
	if not att or not istable(att) then return end

	local angRad = math.rad(angle[3])
	local newX = x * math.cos(angRad) - y * math.sin(angRad)
	local newY = x * math.sin(angRad) + y * math.cos(angRad)

	angle.pitch = math.Clamp(angle.pitch + newY / 50, -180, 180)
	angle.yaw = angle.yaw - newX / 50

	if math.abs(angle.pitch) > 89 then
		angle.roll = angle.roll + 180
		angle.yaw = angle.yaw + 180
		angle.pitch = 89 * angle.pitch / math.abs(angle.pitch)
	end

	cmd:SetViewAngles(angle)

	return true
end)