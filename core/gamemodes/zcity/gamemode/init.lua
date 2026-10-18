include("shared.lua")

function GM:PlayerInitialSpawn(ply,bool)
    if IsValid(ply) then
        timer.Simple(0,function()
            ply:SetModel("models/player/Group01/male_05.mdl")
        end)
    end
end

function GM:PlayerSpawn(ply,bool)
    if IsValid(ply) then
        ply:UnSpectate()

        ply:AddEFlags(EFL_NO_DAMAGE_FORCES)

        ply:Give('wep_jack_gmod_hands')
    end
end