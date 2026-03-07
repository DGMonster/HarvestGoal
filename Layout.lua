-- HarvestGoal - Layout.lua
-- Handles frame resizing and slot layout adjustments

local addonName = ...
local HG = _G[addonName]

local L = HG.L or {}

------------------------------------------------------------
-- Apply Layout
------------------------------------------------------------

function HG:ApplyLayout()

    if not self.frame then
        return
    end

    local layout = HarvestGoalDB.layout or "HORIZONTAL"
    local slotCount = (self.slots and #self.slots) or 0

    --------------------------------------------------------
    -- Horizontal Layout
    --------------------------------------------------------

    if layout == "HORIZONTAL" then

        -- Frame width based on slot count
        local width = 20 + (slotCount * 50)
        local height = 80

        self.frame:SetSize(width, height)

    --------------------------------------------------------
    -- Vertical Layout
    --------------------------------------------------------

    else

        -- Frame height based on slot count
        local height = 60 + (slotCount * 60)

        ----------------------------------------------------
        -- Dynamic width based on title size
        ----------------------------------------------------

        local titleWidth = 0

        if self.frame.title then
            titleWidth = self.frame.title:GetStringWidth() + 20
        end

        -- Minimum width so slots never clip
        local minWidth = 70

        local width = math.max(minWidth, titleWidth)

        self.frame:SetSize(width, height)

    end

    --------------------------------------------------------
    -- Reapply Slot Layout
    --------------------------------------------------------

    if self.slots then
        self:LayoutSlots()
    end

end
