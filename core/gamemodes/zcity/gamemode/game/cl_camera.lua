local smooth_angle = Angle(0,0,0)

hook.Add( "CalcView", "MyCalcView", function( ply, pos, angles, fov )

    local get_eyes = ply:LookupAttachment("eyes")
    local eyes = ply:GetAttachment(get_eyes)

    local ft = FrameTime()

    smooth_angle = LerpAngle(ft * 15, smooth_angle , angles)

	local view = {
		origin = eyes.Pos,
		angles = smooth_angle,
		fov = fov,
		drawviewer = true
	}

	return view
end )

local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
    ["CHudCrosshair"] = true,
}

hook.Add( "HUDShouldDraw", "HideHUD", function( name )if ( hide[ name ] ) then return false end end )