hook.Add("SetupMove","Stamina_Organism",function(ply,mv,cmd)
    ply:SetWalkSpeed(115)
    ply:SetRunSpeed(300)
    ply:SetJumpPower(200)

    return true
end)