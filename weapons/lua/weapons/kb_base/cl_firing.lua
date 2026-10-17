function SWEP:GetTracerOrigin()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local model = self
    
    if self.WModel and IsValid(self.WModel[1]) then
        model = self.WModel[1]
    end

    local att_id = model:LookupAttachment("1")
    
    if att_id <= 0 then
        att_id = model:LookupAttachment("muzzle")
    end

    if att_id > 0 then
        local att = model:GetAttachment(att_id)
        if att then
            local effectdata = EffectData()
            effectdata:SetOrigin(att.Pos)
            effectdata:SetAngles(att.Ang)
            effectdata:SetEntity(model)
            effectdata:SetAttachment(att_id)
            effectdata:SetScale(math.Rand(3, 6))

            local flashEffects = {
                "CS_MuzzleFlash",
            }
            
            util.Effect(flashEffects[math.random(1, #flashEffects)], effectdata)

            return att.Pos
        end
    end
end