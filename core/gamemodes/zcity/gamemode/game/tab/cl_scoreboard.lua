local CustomScoreboard
local isBoardOpen = false
local animSpeed = 15

local holdTime = 0.25
local isHolding = false
local isOtherWindowOpen = false

local function CreateScoreboard()
    if IsValid(CustomScoreboard) then return end

    local w , h = ScrW(), ScrH()
    local pnlW = w * 0.6
    local pnlH = h * 0.6

    CustomScoreboard = vgui.Create("DPanel")
    CustomScoreboard:SetSize(pnlW, pnlH)
    CustomScoreboard.CurrentY = h
    CustomScoreboard:SetPos(w / 2 - pnlW / 2, CustomScoreboard.CurrentY)
    
    CustomScoreboard.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(30, 30, 30, 240))
        draw.RoundedBox(0, 0, 0, w, 40, Color(45, 45, 45, 255))
    end

    CustomScoreboard.Think = function(self)
        local targetY = isBoardOpen and (h / 2 - pnlH / 2) or h
        self.CurrentY = Lerp(FrameTime() * animSpeed, self.CurrentY, targetY)
        self:SetPos(w / 2 - pnlW / 2, self.CurrentY)

        if not isBoardOpen and (self.CurrentY >= h - 1) then
            self:SetVisible(false)
        end
    end
end

hook.Add("ScoreboardShow", "CustomScoreboard_Open", function()
    isHolding = true

    timer.Create("TabHoldTimer", holdTime, 1, function()
        if isHolding then
            isOtherWindowOpen = true
            
            if Frame_Inventory then
                Frame_Inventory()
            end
        end
    end)
    
    return true
end)

hook.Add("ScoreboardHide", "CustomScoreboard_Close", function()
    isHolding = false

    if timer.Exists("TabHoldTimer") then
        timer.Remove("TabHoldTimer")
        
        if not IsValid(CustomScoreboard) then
            CreateScoreboard()
        end
        
        isBoardOpen = not isBoardOpen
        
        if isBoardOpen then
            CustomScoreboard:SetVisible(true)
            gui.EnableScreenClicker(true)
        else
            gui.EnableScreenClicker(false)
        end
        
    elseif isOtherWindowOpen then
        isOtherWindowOpen = false
        
        if IsValid(lootbox_frame) then
            lootbox_frame:Close()
        elseif IsValid(main_inventory) then
            main_inventory.isClosing = true
        end
        
        if not isBoardOpen then
            gui.EnableScreenClicker(false)
        end
    end

    return true
end)