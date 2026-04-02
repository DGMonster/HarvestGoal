-- HarvestGoal - Minimap.lua
-- Handles the minimap button, dragging and tooltip

local addonName = ...
local HG = _G[addonName]

local L = HG.L or {}

------------------------------------------------------------
-- Create Minimap Button
------------------------------------------------------------

function HG:CreateMinimapButton()

    if self.minimapButton then return end

    --------------------------------------------------------
    -- DB
    --------------------------------------------------------

    HarvestGoalDB = HarvestGoalDB or {}
    HarvestGoalDB.minimap = HarvestGoalDB.minimap or {}
    HarvestGoalDB.minimap.angle = HarvestGoalDB.minimap.angle or 45

    --------------------------------------------------------
    -- Button
    --------------------------------------------------------

    local btn = CreateFrame("Button", "HarvestGoalMinimapButton", Minimap)

    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(Minimap:GetFrameLevel() + 5)

    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton")

    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    --------------------------------------------------------
    -- Icon
    --------------------------------------------------------

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\HarvestGoal\\Textures\\logo")
    icon:SetAllPoints()
    btn.icon = icon

    --------------------------------------------------------
    -- Mask
    --------------------------------------------------------

    local mask = btn:CreateMaskTexture()
    mask:SetTexture("Interface\\Minimap\\UI-Minimap-Background", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints()
    icon:AddMaskTexture(mask)

    --------------------------------------------------------
    -- Border
    --------------------------------------------------------

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    --------------------------------------------------------
    -- Position
    --------------------------------------------------------

    local function UpdatePosition()

        local angle = math.rad(HarvestGoalDB.minimap.angle or 45)
        local radius = (Minimap:GetWidth() / 2) - 8

        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius

        btn:ClearAllPoints()
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)

    end

    UpdatePosition()

    --------------------------------------------------------
    -- Drag (Shift)
    --------------------------------------------------------

    btn:SetScript("OnDragStart", function(self)

        if not IsShiftKeyDown() then return end

        self:SetScript("OnUpdate", function()

            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()

            px, py = px / scale, py / scale

            local angle = math.deg(math.atan2(py - my, px - mx))

            HarvestGoalDB.minimap.angle = angle
            UpdatePosition()

        end)

    end)

    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    --------------------------------------------------------
    -- Click
    --------------------------------------------------------

    btn:SetScript("OnClick", function(self, mouseButton)

        ----------------------------------------------------
        -- Right Click → Menü (erstes Fenster)
        ----------------------------------------------------

        if mouseButton == "RightButton" then

            if HG.OpenMenu and HG.windowFrames and HG.windowFrames[1] then
                HG:OpenMenu(HG.windowFrames[1])
            end

            return
        end

        ----------------------------------------------------
        -- Left Click → Toggle ALL windows
        ----------------------------------------------------

        if not HG.windowFrames then return end

        local anyVisible = false

        for i, frame in ipairs(HG.windowFrames) do
            if frame:IsShown() then
                anyVisible = true
                break
            end
        end

        for i, frame in ipairs(HG.windowFrames) do

            if anyVisible then
                frame:Hide()
                HarvestGoalDB.windows[i].visible = false
            else
                frame:Show()
                HarvestGoalDB.windows[i].visible = true
            end

        end

    end)

    --------------------------------------------------------
    -- Tooltip
    --------------------------------------------------------

    btn:SetScript("OnEnter", function(self)

        GameTooltip:SetOwner(self, "ANCHOR_LEFT")

        GameTooltip:AddLine(L["TITLE"] or "HarvestGoal")
        GameTooltip:AddLine(L["MINIMAP_LEFT"] or "Left Click: Toggle Windows", 1, 1, 1)
        GameTooltip:AddLine(L["MINIMAP_RIGHT"] or "Right Click: Options", 1, 1, 1)
        GameTooltip:AddLine(L["MINIMAP_DRAG"] or "Shift + Drag: Move", 1, 1, 1)

        GameTooltip:Show()

    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    --------------------------------------------------------

    self.minimapButton = btn

end
