if CLIENT then
    --[[hook.Add("OnContextMenuOpen", "BlockContextMenuForNonAdmins", function()
        if not LocalPlayer():IsSuperAdmin() then
            return false
        end
    end)--]]

    hook.Add("CanProperty", "BlockProperties123", function(ply, property, ent)
        if not ply:IsSuperAdmin() then
            return false
        end
    end)

    hook.Add("CanDrive", "BlockDrive123", function(ply, ent)
        if not ply:IsSuperAdmin() then
            return false
        end
    end)
end

if SERVER then
    hook.Add("CanProperty", "BlockProperties321", function(ply, property, ent)
        if not ply:IsSuperAdmin() then
            return false
        end
    end)

    hook.Add("CanDrive", "BlockDrive321", function(ply, ent)
        if not ply:IsSuperAdmin() then
            return false
        end
    end)
end