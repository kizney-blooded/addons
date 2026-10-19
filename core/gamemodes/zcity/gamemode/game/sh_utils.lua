KB_WeaponSelectionModels = KB_WeaponSelectionModels or {}

function KB_DrawWeaponSelection(wep, x, y, wide, tall, alpha)
    local mdlPath = wep.WorldModel
    if not mdlPath or mdlPath == "" then return end

    local mdl = KB_WeaponSelectionModels[mdlPath]
    
    if not IsValid(mdl) then
        mdl = ClientsideModel(mdlPath, RENDERGROUP_OTHER)
        if not IsValid(mdl) then return end
        
        mdl:SetNoDraw(true)
        KB_WeaponSelectionModels[mdlPath] = mdl
    end

    local iconData = wep.IconPos or {}
    local mPos = iconData.Pos or Vector(0, 0, 0)
    local mAng = iconData.Ang or Angle(0, 0, 0)
    local fov = iconData.FOV or 50

    local camPos = Vector(0, 0, 0)
    local camAng = Angle(0, 0, 0)

    cam.Start3D(camPos, camAng, fov, x, y, wide, tall, 1, 500)
        
        render.SuppressEngineLighting(true)
        render.SetLightingOrigin(Vector(0, 0, 0))
        render.ResetModelLighting(1, 1, 1)
        
        render.SetModelLighting(BOX_TOP, 1, 1, 1)
        render.SetModelLighting(BOX_FRONT, 1, 1, 1)
        
        --render.SetColorModulation(1, 1, 1)
        --render.SetBlend(alpha / 255)

        mdl:SetPos(mPos)
        mdl:SetAngles(mAng)
        mdl:DrawModel()

        --render.SetBlend(1)
        render.SuppressEngineLighting(false)
        
    cam.End3D()
end