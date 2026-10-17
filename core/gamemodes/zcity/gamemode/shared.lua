AddCSLuaFile()

DeriveGamemode("sandbox")

GM.Name = "ZCITY KAKAHA 123"
GM.Author = "Kizney Blooded"

include("includer.lua")

inc("zcity/gamemode/game")

function GM:PlayerLoadout(ply) return false end

function GM:PlayerFootstep(ply,pos,foot,snd,volume,filter)
    if IsValid(ply:GetNWEntity("FakeRagdoll")) then return true end
    return false
end