-- HarvestGoal - Layout.lua

local addonName = ...
local HG = _G[addonName]

function HG:ApplyLayout()
    if not self.frame then return end

    local layout = HarvestGoalDB.layout
    local slotCount = self.slots and #self.slots or 0

    if layout == "HORIZONTAL" then

        local width = 20 + (slotCount * 50)
        self.frame:SetSize(width, 80)

    else -- VERTICAL

        local height = 60 + (slotCount * 60)

        -- Breite dynamisch anhand Titel bestimmen
        local titleWidth = 0
        if self.frame.title then
            titleWidth = self.frame.title:GetStringWidth() + 20
        end

        local minWidth = 70
        local width = math.max(minWidth, titleWidth)

        self.frame:SetSize(width, height)
    end

    if self.slots then
        self:LayoutSlots()
    end
end