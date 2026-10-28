local current_alpha = 0
local fade_speed = 100
local dsp_applied = false

hook.Add("Think", "Otrub_DSP_Effect", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if ply:Alive() and ply:GetNWBool("Otrub") then
        if not dsp_applied then
            ply:SetDSP(21)
            dsp_applied = true
        end
    else

        if dsp_applied then
            ply:SetDSP(0)
            dsp_applied = false
        end
    end
end)

--[[concommand.Add("set_dsp", function(ply, cmd, args)
    if not args[1] then
        return
    end

    local dsp_id = tonumber(args[1])

    if not dsp_id then
        return
    end

    if IsValid(ply) then
        ply:SetDSP(dsp_id)
        print(dsp_id)
    end
end)--]]

hook.Add("HUDPaint", "Otrub_ScreenDarken", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not ply:Alive() then
        return
    end

    if ply:GetNWBool("Otrub") then
        current_alpha = 255
    else
        if current_alpha > 0 then
            current_alpha = math.Approach(current_alpha, 0, FrameTime() * fade_speed)
        end
    end

    if current_alpha > 0 then
        surface.SetDrawColor(0, 0, 0, current_alpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
end)

net.Receive("headshot_effect", function()
    local pos = net.ReadVector()
    
    sound.Play("kb/organism/headshot" .. math.random(1,2) .. ".wav", pos, 80, 100, 1)

    local emitter = ParticleEmitter(pos)
    if not IsValid(emitter) then return end

    local effectdata = EffectData()
    effectdata:SetOrigin(pos)
    effectdata:SetScale(1)
    effectdata:SetColor(0)
    util.Effect("BloodImpact", effectdata)

    for i = 1, 20 do
        local particle = emitter:Add("decals/blood" .. math.random(1,6), pos)
        
        if particle then
            local velocity = VectorRand() * math.random(150, 400)
            velocity.z = math.Rand(100, 300) 
            
            particle:SetVelocity(velocity)
            particle:SetDieTime(math.Rand(0.8, 1.5))
            particle:SetStartAlpha(255)
            particle:SetEndAlpha(0)
            particle:SetStartSize(math.Rand(1, 2))
            particle:SetEndSize(math.Rand(10, 20))
            particle:SetRoll(math.Rand(0, 360)) 
            particle:SetRollDelta(math.Rand(-5, 5))
            particle:SetColor(130, 0, 0)
            
            particle:SetGravity(Vector(0, 0, -900))
            particle:SetCollide(true)
            particle:SetBounce(0)

            particle:SetCollideCallback(function(prt, hitpos, hitnormal)
                util.Decal("Blood", hitpos + hitnormal, hitpos - hitnormal * 10)
                sound.Play("physics/flesh/flesh_bloody_impact_hard1.wav", hitpos, 65, math.random(90, 110))
                
                prt:SetDieTime(0) 
            end)
        end
    end

    emitter:Finish()
end)