hook.Add("PlayerSay","SpecialCommands",function(ply,text,team)
    local command = string.lower(text)

    if command == "!res" or command == "!куы" or command == "!respawn" or command == "!куызфцт" then

        local pos = ply:GetPos()
        local ang = ply:GetAngles()
        local eye_ang = ply:EyeAngles()
        
        ply:Spawn()

        ply:SetPos(pos)
        ply:SetAngles(ang)
        ply:SetEyeAngles(eye_ang)


    end
end)