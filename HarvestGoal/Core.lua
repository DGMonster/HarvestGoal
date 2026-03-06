-- HarvestGoal - Core.lua

local addonName = ...
local HG = _G[addonName]

if not HG then
    HG = {}
    _G[addonName] = HG
end
HG.DB_VERSION = 1

-- ----------------------------
-- DB Defaults / Init
-- ----------------------------
local function InitDB()

    HarvestGoalDB = HarvestGoalDB or {}

    -- Datenbank Version
    HarvestGoalDB.version = HarvestGoalDB.version or 0

    -- Migrationen ausführen
    if HarvestGoalDB.version < HG.DB_VERSION then
        HG:RunMigrations(HarvestGoalDB.version)
        HarvestGoalDB.version = HG.DB_VERSION
    end

    -- Defaults
    HarvestGoalDB.visible = HarvestGoalDB.visible or false
    HarvestGoalDB.locked  = HarvestGoalDB.locked or false
    HarvestGoalDB.layout  = HarvestGoalDB.layout or "HORIZONTAL"

    HarvestGoalDB.minimap = HarvestGoalDB.minimap or {}
    HarvestGoalDB.minimap.angle = HarvestGoalDB.minimap.angle or 45

    HarvestGoalDB.slotCount = HarvestGoalDB.slotCount or 5
    HarvestGoalDB.slots = HarvestGoalDB.slots or {}

end

-- ----------------------------
-- Init
-- ----------------------------
function HG:Init()
	function HG:RunMigrations(oldVersion)

    -- Beispiel Migration 0 -> 1
    if oldVersion < 1 then

        -- Slot Count hinzufügen
        HarvestGoalDB.slotCount = HarvestGoalDB.slotCount or 5

        -- Falls Slots fehlen
        HarvestGoalDB.slots = HarvestGoalDB.slots or {}

    end

end
    InitDB()

    self:CreateMainFrame()

    if self.ApplyLayout then
        self:ApplyLayout()
    end

    if self.CreateMinimapButton then
        self:CreateMinimapButton()
    end

    if HarvestGoalDB.visible then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end

-- ----------------------------
-- Main Frame
-- ----------------------------
function HG:CreateMainFrame()
    if self.frame then return end

    local frame = CreateFrame("Frame", "HarvestGoalFrame", UIParent, "BackdropTemplate")
    frame:SetSize(300, 50)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)

    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    title:SetText("HarvestGoal")
    frame.title = title

    frame:SetScript("OnDragStart", function(selfFrame)
        if not HarvestGoalDB.locked then
            selfFrame:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
    end)

    -- Rechtsklick-Menü
    frame:SetScript("OnMouseUp", function(selfFrame, mouseButton)
        if mouseButton == "RightButton" then
            HG:OpenMenu(selfFrame)
        end
    end)

    -- Events
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    frame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    frame:SetScript("OnEvent", function()
        if HG.UpdateSlots then
            HG:UpdateSlots()
        end
    end)

    frame:Hide()
    self.frame = frame

    self:CreateSlots()
end

-- ----------------------------
-- Slash Commands
-- ----------------------------
SLASH_HARVESTGOAL1 = "/hg"
SLASH_HARVESTGOAL2 = "/harvestgoal"

SlashCmdList["HARVESTGOAL"] = function()
    if not HG.frame then return end

    if HG.frame:IsShown() then
        HG.frame:Hide()
        HarvestGoalDB.visible = false
    else
        HG.frame:Show()
        HarvestGoalDB.visible = true
    end
end

-- ----------------------------
-- Context Menu (Simple custom menu; no EasyMenu)
-- Stable pooling (Buttons/Dividers getrennt)
-- ----------------------------
function HG:OpenMenu(anchor)
    if not self.menu then
        local menu = CreateFrame("Frame", "HG_ContextMenu", UIParent, "BackdropTemplate")
        menu:SetFrameStrata("TOOLTIP")
        menu:SetClampedToScreen(true)
        menu:EnableMouse(true)
        menu:SetSize(180, 10)
		-- Click catcher (schließt Menü wenn woanders geklickt wird)
		local clickCatcher = CreateFrame("Frame", nil, UIParent)
		clickCatcher:SetAllPoints(UIParent)
		clickCatcher:EnableMouse(true)
		clickCatcher:SetFrameStrata("FULLSCREEN_DIALOG")
		clickCatcher:Hide()

clickCatcher:SetScript("OnMouseDown", function()
    menu:Hide()
end)

menu.clickCatcher = clickCatcher

        menu:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        menu:SetBackdropColor(0, 0, 0, 0.92)

        menu.buttonPool  = {} -- nur Buttons
        menu.dividerPool = {} -- nur Divider (Textures)
        menu.active      = {} -- aktive Widgets pro Öffnen

        local function AcquireButton()
            local btn = tremove(menu.buttonPool)
            if btn then
                btn:Show()
                return btn
            end

            btn = CreateFrame("Button", nil, menu)
            btn:SetHeight(18)
            btn:SetNormalFontObject("GameFontNormalSmall")

            btn:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
            local hl = btn:GetHighlightTexture()
            hl:SetBlendMode("ADD")

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn.text:SetPoint("LEFT", 10, 0)
            btn.text:SetJustifyH("LEFT")

            return btn
        end

        local function AcquireDivider()
            local line = tremove(menu.dividerPool)
            if line then
                line:Show()
                return line
            end

            line = menu:CreateTexture(nil, "ARTWORK")
            line:SetHeight(1)
            line:SetColorTexture(1, 1, 1, 0.12)
            return line
        end

        function menu:ClearActive()
            for _, w in ipairs(self.active) do
                w:Hide()
                w:ClearAllPoints()

                if w.GetObjectType and w:GetObjectType() == "Button" then
                    w:SetScript("OnClick", nil)
                    w.text:SetText("")
                    tinsert(self.buttonPool, w)
                else
                    tinsert(self.dividerPool, w)
                end
            end

            wipe(self.active)
        end

        function menu:AddEntry(text, func)
            local btn = AcquireButton()
            btn.text:SetText(text)

            btn:SetScript("OnClick", function()
                if func then func() end
                menu:Hide()
            end)

            tinsert(self.active, btn)
            return btn
        end

        function menu:AddDivider()
            local line = AcquireDivider()
            tinsert(self.active, line)
            return line
        end

        function menu:Layout()
            local y = -8

            for _, w in ipairs(self.active) do
                w:ClearAllPoints()

                if w.GetObjectType and w:GetObjectType() == "Button" then
                    w:SetPoint("TOPLEFT", 8, y)
                    w:SetPoint("TOPRIGHT", -8, y)
                    y = y - 18
                else
                    w:SetPoint("TOPLEFT", 8, y - 4)
                    w:SetPoint("TOPRIGHT", -8, y - 4)
                    y = y - 10
                end
            end

            self:SetHeight(-y + 6)
            self:SetWidth(180)
        end

        -- Klick irgendwo -> Menü zu
        menu:SetScript("OnMouseDown", function() menu:Hide() end)

        self.menu = menu
    end

    local menu = self.menu
    menu:ClearActive()

    -- Build entries
    menu:AddEntry("Horizontal", function()
        HarvestGoalDB.layout = "HORIZONTAL"
        if HG.ApplyLayout then HG:ApplyLayout() end
        if HG.LayoutSlots then HG:LayoutSlots() end
    end)

    menu:AddEntry("Vertikal", function()
        HarvestGoalDB.layout = "VERTICAL"
        if HG.ApplyLayout then HG:ApplyLayout() end
        if HG.LayoutSlots then HG:LayoutSlots() end
    end)

    menu:AddDivider()

    menu:AddEntry(HarvestGoalDB.locked and "Fenster entsperren" or "Fenster sperren", function()
        HarvestGoalDB.locked = not HarvestGoalDB.locked
    end)

    menu:AddEntry("Position zurücksetzen", function()
        if HG.frame then
            HG.frame:ClearAllPoints()
            HG.frame:SetPoint("CENTER")
        end
    end)

    menu:Layout()

    -- Position at cursor
    menu:ClearAllPoints()
    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    x, y = x / scale, y / scale
    menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)

    menu.clickCatcher:Show()
	menu:Show()
	menu:SetScript("OnHide", function()
    menu.clickCatcher:Hide()
 end)
end

-- ----------------------------
-- Slots
-- ----------------------------
function HG:CreateSlots()
    self.slots = {}

    -- Wenn DB leer ist, mach wenigstens 5 Slots
    if #HarvestGoalDB.slots == 0 then
        for i = 1, 5 do
            HarvestGoalDB.slots[i] = { itemID = nil, goal = 0 }
        end
    end

    for i, data in ipairs(HarvestGoalDB.slots) do
        local slot = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
        slot:SetSize(40, 40)
        slot:SetFrameLevel(self.frame:GetFrameLevel() + 5)
        slot:EnableMouse(true)

        slot:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        slot:SetBackdropColor(0.1, 0.1, 0.1, 1)

        slot.index = i
        slot.data  = data

        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetAllPoints()

        slot.countText = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        slot.countText:SetPoint("TOP", slot, "BOTTOM", 0, -2)

        slot:SetScript("OnMouseUp", function(selfSlot, mouseButton)
            if mouseButton == "LeftButton" then
                local cursorType, itemID = GetCursorInfo()
                if cursorType == "item" then
                    selfSlot.data.itemID = itemID
                    ClearCursor()
                    HG:UpdateSlots()
                end

            elseif mouseButton == "RightButton" then
                if IsShiftKeyDown() then
                    selfSlot.data.itemID = nil
                    selfSlot.data.goal = 0
                    HG:UpdateSlots()
                else
                    HG:PromptGoal(selfSlot)
                end
            end
        end)

        slot:SetScript("OnEnter", function(selfSlot)
            if selfSlot.data.itemID then
                GameTooltip:SetOwner(selfSlot, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. selfSlot.data.itemID)
                GameTooltip:Show()
            end
        end)

        slot:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        self.slots[i] = slot
    end

    self:LayoutSlots()
    self:UpdateSlots()
end

function HG:LayoutSlots()
    if not self.slots then return end

    for i, slot in ipairs(self.slots) do
        slot:ClearAllPoints()

        if HarvestGoalDB.layout == "HORIZONTAL" then
            slot:SetPoint("LEFT", self.frame, "LEFT", 10 + (i - 1) * 50, 0)
        else
            slot:SetPoint("TOP", self.frame, "TOP", 0, -40 - (i - 1) * 60)
        end
    end
end

function HG:UpdateSlots()
    if not self.slots then return end

    for _, slot in ipairs(self.slots) do
        local itemID = slot.data.itemID

        if itemID then
            local count = GetItemCount(itemID, true)
            local goal  = slot.data.goal or 0

            local color = "|cffffff00"
            if goal > 0 and count >= goal then
                color = "|cff00ff00"
            end

            slot.icon:SetTexture(C_Item.GetItemIconByID(itemID))
            slot.countText:SetText(
                color .. count .. "|r" ..
                " / " ..
                "|cff888888" .. goal .. "|r"
            )
        else
            slot.icon:SetTexture(nil)
            slot.countText:SetText("")
        end
    end
end

-- ----------------------------
-- Goal Popup (defined once)
-- ----------------------------
StaticPopupDialogs["HG_SET_GOAL"] = StaticPopupDialogs["HG_SET_GOAL"] or {
    text = "Set Goal",
    button1 = "OK",
    button2 = "Cancel",
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnAccept = function(selfPopup)
        local value = tonumber(selfPopup.EditBox:GetText())
        if value and HG.pendingGoalSlot and HG.pendingGoalSlot.data then
            HG.pendingGoalSlot.data.goal = value
            HG:UpdateSlots()
        end
        HG.pendingGoalSlot = nil
    end,
    OnHide = function()
        HG.pendingGoalSlot = nil
    end,
}

function HG:PromptGoal(slot)
    self.pendingGoalSlot = slot
    StaticPopup_Show("HG_SET_GOAL")
end