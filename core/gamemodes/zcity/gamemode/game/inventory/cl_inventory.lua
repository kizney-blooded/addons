if IsValid(LootBoxBG) then LootBoxBG:Remove() end
if IsValid(LootBoxFrame) then LootBoxFrame:Remove() end

LootBoxBG = nil
LootBoxFrame = nil

local blur = Material("pp/blurscreen")

net.Receive("KB_OpenLootBox", function()
    local box_ent = net.ReadEntity()
    local items = net.ReadTable()

    local count = table.Count(items)
    
    local btnSize = 75
    local gap = 1
    local paddingTop = 40
    local paddingBottom = 10
    local paddingSide = 40
    
    local contentWidth = (btnSize * count) + (gap * (count - 1))
    local frameW = math.Clamp(contentWidth + paddingSide, 150, ScrW() - 40) 
    local frameH = paddingTop + btnSize + paddingBottom

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
        LootBoxFrame:SetSize(frameW, frameH) 
        LootBoxFrame:Center()
        LootBoxFrame:SetTitle("") 
        LootBoxFrame:ShowCloseButton(false)

        LootBoxFrame.Paint = function(self, w, h)
            --draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 240))  -- для теста
            draw.SimpleText("Лутбокс", "ChatFont", w / 2, paddingTop / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        LootBoxFrame.Scroll = vgui.Create("DHorizontalScroller", LootBoxFrame)
        LootBoxFrame.Scroll:SetSize(contentWidth, btnSize)
        LootBoxFrame.Scroll:SetPos((frameW - contentWidth) / 2, paddingTop) 
        LootBoxFrame.Scroll:SetOverlap(-gap) 
    else
        for _, pnl in pairs(LootBoxFrame.Scroll.Panels or {}) do
            if IsValid(pnl) then pnl:Remove() end
        end
        LootBoxFrame:SetSize(frameW, frameH)
        LootBoxFrame:Center()
        LootBoxFrame.Scroll:SetSize(contentWidth, btnSize)
        LootBoxFrame.Scroll:SetPos((frameW - contentWidth) / 2, paddingTop)
    end

    for index, item in pairs(items) do
        local btn = vgui.Create("DButton", LootBoxFrame.Scroll)
        btn:SetSize(btnSize, btnSize)

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
                    local remaining = 0
                    for _, pnl in pairs(LootBoxFrame.Scroll.Panels or {}) do
                        if IsValid(pnl) then remaining = remaining + 1 end
                    end
                    
                    if remaining == 0 then
                        if IsValid(LootBoxBG) then
                            LocalPlayer():EmitSound("kb/ui/close_box.wav")
                            LootBoxBG:Remove()
                        end
                    else
                        local newContentW = (btnSize * remaining) + (gap * (remaining - 1))
                        local newFrameW = math.Clamp(newContentW + paddingSide, 150, ScrW() - 40)
                        
                        LootBoxFrame:SetSize(newFrameW, frameH)
                        LootBoxFrame:Center()
                        LootBoxFrame.Scroll:SetSize(newContentW, btnSize)
                        LootBoxFrame.Scroll:SetPos((newFrameW - newContentW) / 2, paddingTop)
                    end
                end
            end)
        end

        LootBoxFrame.Scroll:AddPanel(btn)
    end
end)