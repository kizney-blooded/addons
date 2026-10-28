hook.Add( "PlayerCanHearPlayersVoice", "Maximum Range", function( listener, talker )
    if not IsValid(listener) or not IsValid(talker) then return end
    if listener == talker then return end

    if not talker:Alive() then
        if listener:Alive() and listener:Team() != 1002 then
            return false, false
        end
    end
    local max_distance = 1500
    local distance_sqr = listener:GetPos():DistToSqr( talker:GetPos() )

    if distance_sqr > (max_distance * max_distance) then
        return false, false
    else
        return true, true
    end
end )

hook.Add( "PlayerCanSeePlayersChat", "Proximity_Text", function( text, teamOnly, listener, talker )
    if not IsValid(listener) or not IsValid(talker) then return end
    if listener == talker then return true end

    if not talker:Alive() then
        if listener:Alive() and listener:Team() != 1002 then
            return false
        end
    end
    local max_distance = 1000
    local distance_sqr = listener:GetPos():DistToSqr( talker:GetPos() )

    if distance_sqr > (max_distance * max_distance) then
        return false
    else
        return true
    end
end )