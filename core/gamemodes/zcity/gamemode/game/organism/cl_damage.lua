net.Receive("headshot_effect", function()
    local victim = net.ReadEntity()
    local damagePos = net.ReadVector()

    local effectdata = EffectData()
    effectdata:SetOrigin(damagePos)
    effectdata:SetScale(2)
    util.Effect("BloodImpact", effectdata, true, true)

    if IsValid(victim) then
        victim:EmitSound("kb/organism/headshot" .. math.random(1, 2) .. ".wav", 75, 100, 1, CHAN_AUTO)
    end
end)