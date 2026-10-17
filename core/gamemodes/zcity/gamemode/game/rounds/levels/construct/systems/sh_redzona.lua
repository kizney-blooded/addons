if CLIENT then
    local zoneActive = false
    local zoneCenter = Vector(0,0,0)
    local initialRadius = 3000
    local targetRadius = 100
    local shrinkSpeed = 15
    local clientStartTime = 0

    local zoneSound = nil

    net.Receive("red_zona_data", function()
        zoneActive = net.ReadBool()
        
        if zoneActive then
            zoneCenter = net.ReadVector()
            initialRadius = net.ReadFloat()
            targetRadius = net.ReadFloat()
            shrinkSpeed = net.ReadFloat()
            
            clientStartTime = CurTime() 

            if zoneSound then zoneSound:Stop() end
            
            zoneSound = CreateSound(LocalPlayer(), "ambient/energy/force_field_loop1.wav")
            zoneSound:PlayEx(0, 50)
        else
            if zoneSound then
                zoneSound:Stop()
                zoneSound = nil
            end
        end
    end)

    hook.Add("Think", "RedZona_SoundLogic", function()
        if not zoneActive or not zoneSound then return end

        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local timePassed = CurTime() - clientStartTime
        local currentRadius = math.max(targetRadius, initialRadius - (shrinkSpeed * timePassed))

        local distToCenter = ply:GetPos():Distance(zoneCenter)
        local distToEdge = math.abs(distToCenter - currentRadius)

        local maxHearDistance = 1500 
        
        local fraction = 1 - math.Clamp(distToEdge / maxHearDistance, 0, 1)

        local targetVolume = fraction
        local targetPitch = 50 + (100 * fraction)

        zoneSound:ChangeVolume(targetVolume, 0)
        zoneSound:ChangePitch(targetPitch, 0)
    end)

    hook.Add("PostDrawTranslucentRenderables", "Render_RedZona", function()
        if not zoneActive then return end

        local timePassed = CurTime() - clientStartTime
        local currentRadius = math.max(targetRadius, initialRadius - (shrinkSpeed * timePassed))

        render.SetColorMaterial()

        local sphereColorIz = Color( 255, 0, 0, 50)
        local sphereColorVn = Color( 255, 0, 0, 50)

        render.CullMode( MATERIAL_CULLMODE_CW )
        render.DrawSphere( zoneCenter, currentRadius, 30, 30, sphereColorVn )

        render.CullMode( MATERIAL_CULLMODE_CCW ) -- если переставялешь то пропадает вся отрисовка (о гарри , кричи мое имя)
        render.DrawSphere( zoneCenter, currentRadius, 30, 30, sphereColorIz )
    end)
end