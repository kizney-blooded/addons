local vec0 = Vector(0,0,0)
local vec1 = Vector(1,1,1)

local smooth_angle = Angle(0,0,0)

hook.Add( "CalcView", "MyCalcView", function( ply, pos, angles, fov )

	local rag = ply:GetNWEntity("FakeRagdoll")
	local target = IsValid(rag) and rag or ply

    local get_eyes = target:LookupAttachment("eyes")
    local eyes = target:GetAttachment(get_eyes)

	if GetViewEntity() != ply then return end


    local ft = FrameTime()
    smooth_angle = LerpAngle(ft * 15, smooth_angle , angles)

	local view = {
		origin = eyes.Pos,
		angles = smooth_angle,
		fov = 100,
		drawviewer = true,
		znear = 1
	}

	return view
end )

local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
    ["CHudCrosshair"] = true,
}


hook.Add( "HUDShouldDraw", "HideHUD", function( name )if ( hide[ name ] ) then return false end end )

hook.Add("Think","HideHead",function()
	local ply = LocalPlayer()
	
	local rag = ply:GetNWEntity("FakeRagdoll")

	local target = IsValid(rag) and rag or ply

	local head = target:LookupBone("ValveBiped.Bip01_Head1")

	if GetViewEntity() != ply then
		target:ManipulateBoneScale(head,vec1)
	else
		target:ManipulateBoneScale(head,vec0)
	end
end)