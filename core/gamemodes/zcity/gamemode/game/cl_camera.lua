local vec0 = Vector(0,0,0)
local vec1 = Vector(1,1,1)

local smooth_angle = Angle(0,0,0)

local eyes

hook.Add( "CalcView", "MyCalcView", function( ply, pos, angles, fov )

    if ply:Alive() then

        local rag = ply:GetNWEntity("FakeRagdoll")
        local target = IsValid(rag) and rag or ply

        local get_eyes = target:LookupAttachment("eyes")
        eyes = target:GetAttachment(get_eyes)

        if GetViewEntity() != ply then return end
        
    end

    local ft = FrameTime()
    
    local punch = ply:GetViewPunchAngles()
    
    local base_angles = angles - punch
    
    smooth_angle = LerpAngle(ft * 15, smooth_angle, base_angles)
    
    local result_angle = smooth_angle + punch

    local set_origin = ply:Alive() and eyes and eyes.Pos or pos
    local set_fov = 100

    local wep = ply:GetActiveWeapon()
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
}


hook.Add( "HUDShouldDraw", "HideHUD", function( name )if ( hide[ name ] ) then return false end end )