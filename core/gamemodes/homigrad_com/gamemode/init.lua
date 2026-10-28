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

        ply:StripWeapons()

        if ply:Team() == 1002 then
            ply:SetModel("models/player/gman_high.mdl")
            ply:SetPlayerColor(Vector(0.427,0.427,0.427))
        end

        if kb.RD.current_round == "constract" then

            if ply:Team() == 1002 then
                ply:SetModel("models/player/gman_high.mdl")
                ply:SetPlayerColor(Vector(0.427,0.427,0.427))
            else
                spawn_construct_player(ply)
            end
        end

        ply:RemoveAllAmmo()

        ply:AddEFlags(EFL_NO_DAMAGE_FORCES)

        ply:Give('wep_jack_gmod_hands')
    end
end