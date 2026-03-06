local addonName = ...
local HG = _G[addonName]

function HG:CreateMinimapButton()
    if self.minimapButton then
        return
    end

    -- Sicherstellen, dass DB-Tabellen existieren
    HarvestGoalDB = HarvestGoalDB or {}
    HarvestGoalDB.minimap = HarvestGoalDB.minimap or {}
    HarvestGoalDB.minimap.angle = HarvestGoalDB.minimap.angle or 45

    local btn = CreateFrame("Button", "HarvestGoalMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\HarvestGoal\\Textures\\logo")
    icon:SetAllPoints()
    btn.icon = icon

    -- Kreis-Maske
    local mask = btn:CreateMaskTexture()
    mask:SetTexture("Interface\\Minimap\\UI-Minimap-Background", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints()
    icon:AddMaskTexture(mask)

    -- Goldener Ring
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    -- Position berechnen
    local function UpdatePosition()
        local angle = math.rad(HarvestGoalDB.minimap.angle or 45)
        local radius = (Minimap:GetWidth() / 2) - 8

        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius

        btn:ClearAllPoints()
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    UpdatePosition()

    -- Drag (nur mit Shift)
    btn:SetScript("OnDragStart", function(self)
        if not IsShiftKeyDown() then
            return
        end

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

    -- Klicks
    btn:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            if HG.OpenMenu then
                HG:OpenMenu(HG.frame)
            end
            return
        end

        if HG.frame and HG.frame:IsShown() then
            HG.frame:Hide()
            HarvestGoalDB.visible = false
        elseif HG.frame then
            HG.frame:Show()
            HarvestGoalDB.visible = true
        end
    end)

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("HarvestGoal")
        GameTooltip:AddLine("Left Click: Toggle Window", 1, 1, 1)
        GameTooltip:AddLine("Right Click: Options", 1, 1, 1)
        GameTooltip:AddLine("Shift + Drag: Move", 1, 1, 1)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.minimapButton = btn
end