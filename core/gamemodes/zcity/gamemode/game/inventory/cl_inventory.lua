if IsValid(LootBoxBG) then LootBoxBG:Remove() end
if IsValid(LootBoxFrame) then LootBoxFrame:Remove() end

LootBoxBG = nil
LootBoxFrame = nil

local blur = Material("pp/blurscreen")

net.Receive("KB_OpenLootBox", function()
    local box_ent = net.ReadEntity()
    local items = net.ReadTable()

    if not IsValid(LootBoxBG) then 
        LootBoxBG = vgui.Create("DPanel")
        LootBoxBG:SetSize(ScrW(), ScrH())
        LootBoxBG:SetPos(0, 0)
        LootBoxBG:MakePopup()
        LootBoxBG.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 180))
        end

        LootBoxBG.OnKeyCodePressed = function(self, key)
            if key == KEY_W or key == KEY_A or key == KEY_S or key == KEY_D then
                LocalPlayer():EmitSound("kb/ui/close_box.wav")
                self:Remove()
            end
        end

        LootBoxFrame = vgui.Create("DFrame", LootBoxBG)
        LootBoxFrame:SetSize(400, 400)
        LootBoxFrame:Center()
        LootBoxFrame:SetTitle("Лутбокс")
        LootBoxFrame:ShowCloseButton(false)

        LootBoxFrame.Scroll = vgui.Create("DScrollPanel", LootBoxFrame)
        LootBoxFrame.Scroll:Dock(FILL)
    else
        LootBoxFrame.Scroll:Clear()
    end

    for index, item in pairs(items) do
        local btn = LootBoxFrame.Scroll:Add("DButton")
        btn:Dock(TOP)
        btn:DockMargin(5, 5, 5, 0)
        btn:SetHeight(50)

        local wep = weapons.GetStored(item.class)
        local printName = (wep and wep.PrintName) and wep.PrintName or language.GetPhrase(item.class)
        
        if printName == item.class then
            printName = item.class 
        end
        
        btn:SetText(printName)
        
        btn.DoClick = function()
            net.Start("KB_ClaimLoot")
                net.WriteEntity(box_ent)
                net.WriteUInt(index, 8) 
            net.SendToServer()
            
            btn:Remove()

            timer.Simple(0, function()
                if IsValid(LootBoxFrame) and IsValid(LootBoxFrame.Scroll) then
                    local canvas = LootBoxFrame.Scroll:GetCanvas()
                    if #canvas:GetChildren() == 0 then
                        if IsValid(LootBoxBG) then
                            LocalPlayer():EmitSound("kb/ui/close_box.wav")
                            LootBoxBG:Remove()
                        end
                    end
                end
            end)
        end
    end
end)