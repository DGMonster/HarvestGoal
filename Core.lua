-- HarvestGoal - Core.lua
-- Dynamic window system with independent frames and slots

local addonName = ...
local HG = _G[addonName]

if not HG then
    HG = {}
    _G[addonName] = HG
end

local L = HG.L or {}

HG.DB_VERSION = 2

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function GetItemIconSafe(itemID)
    if C_Item and C_Item.GetItemIconByID then
        return C_Item.GetItemIconByID(itemID)
    end

    return GetItemIcon(itemID)
end

local function GetDefaultTitle(index)
    local baseTitle = L["TITLE"] or "HarvestGoal"

    if index == 1 then
        return baseTitle
    end

    return baseTitle .. " " .. index
end

local function MakeDefaultSlots(count)
    local slots = {}

    for i = 1, count do
        slots[i] = {
            itemID = nil,
            goal = 0,
        }
    end

    return slots
end

local function MakeDefaultWindowData(index)
    local yOffset = 0 - ((index - 1) * 120)

    return {
        title = GetDefaultTitle(index),
        visible = true,
        locked = false,
        layout = "HORIZONTAL",
        point = {
            anchor = "CENTER",
            relativeTo = "UIParent",
            relativePoint = "CENTER",
            x = 0,
            y = yOffset,
        },
        slotCount = 6,
        slots = MakeDefaultSlots(6),
    }
end

local function EnsureWindowData(windowData, index)
    if not windowData then
        windowData = MakeDefaultWindowData(index)
    end

    windowData.title = windowData.title or GetDefaultTitle(index)
    windowData.visible = windowData.visible ~= false
    windowData.locked = windowData.locked or false
    windowData.layout = windowData.layout or "HORIZONTAL"

    windowData.point = windowData.point or {}
    windowData.point.anchor = windowData.point.anchor or "CENTER"
    windowData.point.relativeTo = windowData.point.relativeTo or "UIParent"
    windowData.point.relativePoint = windowData.point.relativePoint or "CENTER"
    windowData.point.x = windowData.point.x or 0
    windowData.point.y = windowData.point.y or 0

    windowData.slotCount = windowData.slotCount or 6
    windowData.slots = windowData.slots or {}

    for i = 1, windowData.slotCount do
        windowData.slots[i] = windowData.slots[i] or {
            itemID = nil,
            goal = 0,
        }
    end

    while #windowData.slots > windowData.slotCount do
        tremove(windowData.slots)
    end

    return windowData
end

------------------------------------------------------------
-- Database Initialization / Migration
------------------------------------------------------------

local function InitDB()
    HarvestGoalDB = HarvestGoalDB or {}
    HarvestGoalDB.version = HarvestGoalDB.version or 0

    if HarvestGoalDB.version < HG.DB_VERSION then
        HG:RunMigrations(HarvestGoalDB.version)
        HarvestGoalDB.version = HG.DB_VERSION
    end

    HarvestGoalDB.minimap = HarvestGoalDB.minimap or {}
    HarvestGoalDB.minimap.angle = HarvestGoalDB.minimap.angle or 45

    HarvestGoalDB.windows = HarvestGoalDB.windows or {}

    if #HarvestGoalDB.windows == 0 then
        HarvestGoalDB.windows[1] = MakeDefaultWindowData(1)
    end

    for i, windowData in ipairs(HarvestGoalDB.windows) do
        HarvestGoalDB.windows[i] = EnsureWindowData(windowData, i)
    end
end

function HG:RunMigrations(oldVersion)
    HarvestGoalDB.windows = HarvestGoalDB.windows or {}

    if oldVersion < 1 then
        HarvestGoalDB.slotCount = HarvestGoalDB.slotCount or 6
        HarvestGoalDB.slots = HarvestGoalDB.slots or {}
    end

    if oldVersion < 2 then
        if #HarvestGoalDB.windows == 0 then
            local firstWindow = {
                title = L["TITLE"] or "HarvestGoal",
                visible = HarvestGoalDB.visible ~= false,
                locked = HarvestGoalDB.locked or false,
                layout = HarvestGoalDB.layout or "HORIZONTAL",
                point = {
                    anchor = "CENTER",
                    relativeTo = "UIParent",
                    relativePoint = "CENTER",
                    x = 0,
                    y = 0,
                },
                slotCount = HarvestGoalDB.slotCount or math.max(#(HarvestGoalDB.slots or {}), 6),
                slots = {},
            }

            local oldSlots = HarvestGoalDB.slots or {}

            if #oldSlots > 0 then
                for i, slotData in ipairs(oldSlots) do
                    firstWindow.slots[i] = {
                        itemID = slotData.itemID,
                        goal = slotData.goal or 0,
                    }
                end
            else
                firstWindow.slots = MakeDefaultSlots(firstWindow.slotCount)
            end

            while #firstWindow.slots < firstWindow.slotCount do
                tinsert(firstWindow.slots, { itemID = nil, goal = 0 })
            end

            HarvestGoalDB.windows[1] = firstWindow
        end

        if HarvestGoalDB.secondSlots and #HarvestGoalDB.secondSlots > 0 then
            local secondIndex = #HarvestGoalDB.windows + 1

            HarvestGoalDB.windows[secondIndex] = {
                title = (L["TITLE"] or "HarvestGoal") .. " 2",
                visible = HarvestGoalDB.visible ~= false,
                locked = HarvestGoalDB.locked or false,
                layout = HarvestGoalDB.layout or "HORIZONTAL",
                point = {
                    anchor = "CENTER",
                    relativeTo = "UIParent",
                    relativePoint = "CENTER",
                    x = 0,
                    y = -120,
                },
                slotCount = HarvestGoalDB.secondSlotCount or math.max(#HarvestGoalDB.secondSlots, 6),
                slots = {},
            }

            for i, slotData in ipairs(HarvestGoalDB.secondSlots) do
                HarvestGoalDB.windows[secondIndex].slots[i] = {
                    itemID = slotData.itemID,
                    goal = slotData.goal or 0,
                }
            end

            while #HarvestGoalDB.windows[secondIndex].slots < HarvestGoalDB.windows[secondIndex].slotCount do
                tinsert(HarvestGoalDB.windows[secondIndex].slots, { itemID = nil, goal = 0 })
            end
        end
    end
end

------------------------------------------------------------
-- Addon Init
------------------------------------------------------------

function HG:Init()
    InitDB()

    self.windowFrames = self.windowFrames or {}

    self:CreateAllWindowFrames()
    self:CreateEventFrame()

    if self.CreateMinimapButton then
        self:CreateMinimapButton()
    end
end

------------------------------------------------------------
-- Event Frame
------------------------------------------------------------

function HG:CreateEventFrame()
    if self.eventFrame then
        return
    end

    local frame = CreateFrame("Frame")

    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    frame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    frame:SetScript("OnEvent", function()
        HG:UpdateAllWindows()
    end)

    self.eventFrame = frame
end

------------------------------------------------------------
-- Window Position
------------------------------------------------------------

function HG:SaveWindowPosition(frame, windowIndex)
    local windowData = HarvestGoalDB.windows[windowIndex]
    if not windowData then
        return
    end

    local centerX, centerY = frame:GetCenter()
    local parentCenterX, parentCenterY = UIParent:GetCenter()

    if not centerX or not centerY or not parentCenterX or not parentCenterY then
        return
    end

    windowData.point.anchor = "CENTER"
    windowData.point.relativeTo = "UIParent"
    windowData.point.relativePoint = "CENTER"
    windowData.point.x = math.floor(centerX - parentCenterX + 0.5)
    windowData.point.y = math.floor(centerY - parentCenterY + 0.5)
end

function HG:ApplyWindowPosition(frame, windowIndex)
    local windowData = HarvestGoalDB.windows[windowIndex]
    if not windowData or not windowData.point then
        frame:SetPoint("CENTER")
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint(
        windowData.point.anchor or "CENTER",
        UIParent,
        windowData.point.relativePoint or "CENTER",
        windowData.point.x or 0,
        windowData.point.y or 0
    )
end

------------------------------------------------------------
-- Window Creation / Rebuild
------------------------------------------------------------

function HG:CreateAllWindowFrames()
    for i = 1, #HarvestGoalDB.windows do
        self:CreateWindowFrame(i)
    end
end

function HG:CreateWindowFrame(windowIndex)
    local windowData = HarvestGoalDB.windows[windowIndex]
    if not windowData then
        return
    end

    local frame = self.windowFrames[windowIndex]

    if not frame then
        frame = CreateFrame("Frame", "HarvestGoalWindow" .. windowIndex, UIParent, "BackdropTemplate")

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
        frame.title = title

        frame.slots = {}

        frame:SetScript("OnDragStart", function(selfFrame)
            local data = HarvestGoalDB.windows[selfFrame.windowIndex]

            if data and not data.locked then
                selfFrame:StartMoving()
            end
        end)

        frame:SetScript("OnDragStop", function(selfFrame)
            selfFrame:StopMovingOrSizing()
            HG:SaveWindowPosition(selfFrame, selfFrame.windowIndex)
        end)

        frame:SetScript("OnMouseUp", function(selfFrame, mouseButton)
            if mouseButton == "RightButton" then
                HG:OpenMenu(selfFrame, selfFrame.windowIndex)
            end
        end)

        self.windowFrames[windowIndex] = frame
    end

    frame.windowIndex = windowIndex
    frame.title:SetText(windowData.title or GetDefaultTitle(windowIndex))

    self:ApplyWindowPosition(frame, windowIndex)
    self:RebuildWindowSlots(windowIndex)
    self:LayoutWindow(windowIndex)
    self:UpdateWindow(windowIndex)

    if windowData.visible then
        frame:Show()
    else
        frame:Hide()
    end
end

function HG:ReleaseWindowSlots(frame)
    if not frame or not frame.slots then
        return
    end

    for _, slot in ipairs(frame.slots) do
        slot:Hide()
        slot:SetParent(nil)
    end

    wipe(frame.slots)
end

function HG:RebuildWindowSlots(windowIndex)
    local frame = self.windowFrames[windowIndex]
    local windowData = HarvestGoalDB.windows[windowIndex]

    if not frame or not windowData then
        return
    end

    windowData = EnsureWindowData(windowData, windowIndex)
    HarvestGoalDB.windows[windowIndex] = windowData

    self:ReleaseWindowSlots(frame)

    for i = 1, windowData.slotCount do
        local slotData = windowData.slots[i]

        local slot = CreateFrame("Frame", nil, frame, "BackdropTemplate")

        slot:SetSize(48, 48)
        slot:SetFrameLevel(frame:GetFrameLevel() + 5)
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

        slot.windowIndex = windowIndex
        slot.slotIndex = i
        slot.data = slotData

        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetAllPoints()

        slot.countText = slot:CreateFontString(nil, "OVERLAY")
		slot.countText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
		slot.countText:SetPoint("BOTTOM", slot, "BOTTOM", 0, 4)
		slot.countText:SetJustifyH("CENTER")
		slot.countText:SetJustifyV("MIDDLE")
		slot.countText:SetScale(1)

        slot:SetScript("OnMouseUp", function(selfSlot, mouseButton)
            if mouseButton == "LeftButton" then
                local cursorType, itemID = GetCursorInfo()

                if cursorType == "item" then
                    selfSlot.data.itemID = itemID
                    ClearCursor()
                    HG:UpdateWindow(selfSlot.windowIndex)
                end
            elseif mouseButton == "RightButton" then
                if IsShiftKeyDown() then
                    selfSlot.data.itemID = nil
                    selfSlot.data.goal = 0
                    HG:UpdateWindow(selfSlot.windowIndex)
                else
                    HG:PromptGoal(selfSlot)
                end
            end
        end)

        slot:SetScript("OnEnter", function(selfSlot)
            if selfSlot.data and selfSlot.data.itemID then
                GameTooltip:SetOwner(selfSlot, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. selfSlot.data.itemID)
                GameTooltip:Show()
            end
        end)

        slot:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        frame.slots[i] = slot
    end
end

------------------------------------------------------------
-- Window Layout / Update
------------------------------------------------------------

function HG:LayoutWindow(windowIndex)
    local frame = self.windowFrames[windowIndex]
    local windowData = HarvestGoalDB.windows[windowIndex]

    if not frame or not windowData then
        return
    end

    local slotCount = windowData.slotCount or 0
    local layout = windowData.layout or "HORIZONTAL"

    for i, slot in ipairs(frame.slots) do
        slot:ClearAllPoints()

        if layout == "HORIZONTAL" then
            slot:SetPoint("LEFT", frame, "LEFT", 12 + (i - 1) * 60, -8)
        else
            slot:SetPoint("TOP", frame, "TOP", 0, -46 - (i - 1) * 60)
        end
    end

    if layout == "HORIZONTAL" then
        local width = math.max(70, 24 + (slotCount * 60))
        frame:SetSize(width, 76)
    else
        local height = math.max(70, 56 + (slotCount * 60))
        frame:SetSize(88, height)
    end
end

local function FormatCountCompact(value)
    value = tonumber(value) or 0

    if value >= 1000 then
        local formatted = string.format("%.1f", value / 1000)
        formatted = formatted:gsub("%.0$", "") -- entfernt .0
        return formatted .. "k"
    end

    return tostring(value)
end

function HG:UpdateWindow(windowIndex)
    local frame = self.windowFrames[windowIndex]
    local windowData = HarvestGoalDB.windows[windowIndex]

    if not frame or not windowData then
        return
    end

    frame.title:SetText(windowData.title or GetDefaultTitle(windowIndex))

    for _, slot in ipairs(frame.slots) do
        local itemID = slot.data and slot.data.itemID

        if itemID then
            local count = GetItemCount(itemID, true)
            local goal = slot.data.goal or 0
            local color = "|cffffff00"

            if goal > 0 and count >= goal then
                color = "|cff00ff00"
            end

            slot.icon:SetTexture(GetItemIconSafe(itemID))
            local countText = FormatCountCompact(count)
			local goalText = FormatCountCompact(goal)

			slot.countText:SetText(color .. countText .. "|r|cff888888/" .. goalText .. "|r")
        else
            slot.icon:SetTexture(nil)
            slot.countText:SetText("")
        end
    end
end

function HG:UpdateAllWindows()
    for i = 1, #HarvestGoalDB.windows do
        self:UpdateWindow(i)
    end
end

------------------------------------------------------------
-- Window Actions
------------------------------------------------------------

function HG:CreateNewWindow()
    local newIndex = #HarvestGoalDB.windows + 1

    HarvestGoalDB.windows[newIndex] = MakeDefaultWindowData(newIndex)
    HarvestGoalDB.windows[newIndex].point.y = 0 - ((newIndex - 1) * 120)

    self:CreateWindowFrame(newIndex)
end

function HG:ToggleWindow(windowIndex)
    local windowData = HarvestGoalDB.windows[windowIndex]
    local frame = self.windowFrames[windowIndex]

    if not windowData or not frame then
        return
    end

    windowData.visible = not windowData.visible

    if windowData.visible then
        frame:Show()
    else
        frame:Hide()
    end
end

function HG:ShowAllWindows()
    for i, windowData in ipairs(HarvestGoalDB.windows) do
        local frame = self.windowFrames[i]

        if frame then
            windowData.visible = true
            frame:Show()
        end
    end
end

function HG:HideAllWindows()
    for i, windowData in ipairs(HarvestGoalDB.windows) do
        local frame = self.windowFrames[i]

        if frame then
            windowData.visible = false
            frame:Hide()
        end
    end
end

function HG:ResetWindowPosition(windowIndex)
    local frame = self.windowFrames[windowIndex]
    local windowData = HarvestGoalDB.windows[windowIndex]

    if not frame or not windowData then
        return
    end

    windowData.point.anchor = "CENTER"
    windowData.point.relativeTo = "UIParent"
    windowData.point.relativePoint = "CENTER"
    windowData.point.x = 0
    windowData.point.y = 0 - ((windowIndex - 1) * 120)

    self:ApplyWindowPosition(frame, windowIndex)
end

function HG:RenameWindow(windowIndex, newTitle)
    local windowData = HarvestGoalDB.windows[windowIndex]
    local frame = self.windowFrames[windowIndex]

    if not windowData or not frame then
        return
    end

    newTitle = tostring(newTitle or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if newTitle == "" then
        newTitle = GetDefaultTitle(windowIndex)
    end

    windowData.title = newTitle
    frame.title:SetText(newTitle)
end

function HG:AddSlotToWindow(windowIndex)
    local windowData = HarvestGoalDB.windows[windowIndex]
    if not windowData then
        return
    end

    windowData.slotCount = (windowData.slotCount or 0) + 1
    windowData.slots[windowData.slotCount] = {
        itemID = nil,
        goal = 0,
    }

    self:RebuildWindowSlots(windowIndex)
    self:LayoutWindow(windowIndex)
    self:UpdateWindow(windowIndex)
end

function HG:RemoveSlotFromWindow(windowIndex)
    local windowData = HarvestGoalDB.windows[windowIndex]
    if not windowData then
        return
    end

    if (windowData.slotCount or 0) <= 1 then
        return
    end

    windowData.slots[windowData.slotCount] = nil
    windowData.slotCount = windowData.slotCount - 1

    self:RebuildWindowSlots(windowIndex)
    self:LayoutWindow(windowIndex)
    self:UpdateWindow(windowIndex)
end

function HG:DeleteWindow(windowIndex)
    if #HarvestGoalDB.windows <= 1 then
        return
    end

    local frame = self.windowFrames[windowIndex]

    if frame then
        self:ReleaseWindowSlots(frame)
        frame:Hide()
        frame:SetParent(nil)
        self.windowFrames[windowIndex] = nil
    end

    tremove(HarvestGoalDB.windows, windowIndex)

    local oldFrames = self.windowFrames
    self.windowFrames = {}

    for i, oldFrame in ipairs(oldFrames) do
        if oldFrame then
            oldFrame:Hide()
            oldFrame:SetParent(nil)
        end
    end

    for i, windowData in ipairs(HarvestGoalDB.windows) do
        HarvestGoalDB.windows[i] = EnsureWindowData(windowData, i)

        if not windowData.title or windowData.title == "" then
            HarvestGoalDB.windows[i].title = GetDefaultTitle(i)
        end
    end

    self:CreateAllWindowFrames()
    self:UpdateAllWindows()
end

------------------------------------------------------------
-- Slash Commands
------------------------------------------------------------

SLASH_HARVESTGOAL1 = "/hg"
SLASH_HARVESTGOAL2 = "/harvestgoal"

SlashCmdList["HARVESTGOAL"] = function()
    local anyVisible = false

    for i, windowData in ipairs(HarvestGoalDB.windows or {}) do
        local frame = HG.windowFrames and HG.windowFrames[i]

        if frame and frame:IsShown() and windowData.visible then
            anyVisible = true
            break
        end
    end

    if anyVisible then
        HG:HideAllWindows()
    else
        HG:ShowAllWindows()
    end
end

------------------------------------------------------------
-- Context Menu
------------------------------------------------------------

function HG:OpenMenu(anchorFrame, windowIndex)
    if not self.menu then
        local menu = CreateFrame("Frame", "HG_ContextMenu", UIParent, "BackdropTemplate")

        menu:SetFrameStrata("TOOLTIP")
        menu:SetClampedToScreen(true)
        menu:EnableMouse(true)
        menu:SetSize(240, 10)

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
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })

        menu:SetBackdropColor(0, 0, 0, 0.92)

        menu.buttonPool = {}
        menu.dividerPool = {}
        menu.active = {}

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
            for _, widget in ipairs(self.active) do
                widget:Hide()
                widget:ClearAllPoints()

                if widget:GetObjectType() == "Button" then
                    widget:SetScript("OnClick", nil)
                    widget.text:SetText("")
                    tinsert(self.buttonPool, widget)
                else
                    tinsert(self.dividerPool, widget)
                end
            end

            wipe(self.active)
        end

        function menu:AddEntry(text, func)
            local btn = AcquireButton()
            btn.text:SetText(text)

            btn:SetScript("OnClick", function()
                if func then
                    func()
                end
                menu:Hide()
            end)

            tinsert(self.active, btn)
        end

        function menu:AddDivider()
            local line = AcquireDivider()
            tinsert(self.active, line)
        end

        function menu:AddHeader(text)
            local btn = AcquireButton()
            btn.text:SetText("|cffffd100" .. text .. "|r")
            btn:SetScript("OnClick", nil)
            btn:Disable()
            tinsert(self.active, btn)
        end

        function menu:Layout()
            local y = -8

            for _, widget in ipairs(self.active) do
                if widget:GetObjectType() == "Button" then
                    widget:SetPoint("TOPLEFT", 8, y)
                    widget:SetPoint("TOPRIGHT", -8, y)
                    y = y - 18
                else
                    widget:SetPoint("TOPLEFT", 8, y - 4)
                    widget:SetPoint("TOPRIGHT", -8, y - 4)
                    y = y - 10
                end
            end

            self:SetHeight(-y + 6)
            self:SetWidth(240)
        end

        self.menu = menu
    end

    local menu = self.menu
    local windowData = HarvestGoalDB.windows[windowIndex]

    if not windowData then
        return
    end

    menu.anchorFrame = anchorFrame
    menu.windowIndex = windowIndex
    menu:ClearActive()

    local windowTitle = windowData.title or ((L["TITLE"] or "HarvestGoal") .. " " .. windowIndex)

    --------------------------------------------------------
    -- Global
    --------------------------------------------------------

    menu:AddEntry(L["MENU_NEW_WINDOW"] or "New Window", function()
        HG:CreateNewWindow()
    end)

    menu:AddDivider()

    --------------------------------------------------------
    -- Active Window Header
    --------------------------------------------------------

    menu:AddHeader(windowTitle)
    menu:AddDivider()

    --------------------------------------------------------
    -- Window Settings
    --------------------------------------------------------

    menu:AddEntry(L["MENU_RENAME_WINDOW"] or "Rename Window", function()
        HG:PromptRenameWindow(windowIndex)
    end)

    menu:AddEntry(
        windowData.layout == "HORIZONTAL"
            and (L["MENU_VERTICAL"] or "Vertical Layout")
            or (L["MENU_HORIZONTAL"] or "Horizontal Layout"),
        function()
            if windowData.layout == "HORIZONTAL" then
                windowData.layout = "VERTICAL"
            else
                windowData.layout = "HORIZONTAL"
            end

            HG:LayoutWindow(windowIndex)
            HG:UpdateWindow(windowIndex)
        end
    )

    menu:AddEntry(
        windowData.locked and (L["MENU_UNLOCK"] or "Unlock Window") or (L["MENU_LOCK"] or "Lock Window"),
        function()
            windowData.locked = not windowData.locked
        end
    )

    menu:AddDivider()

    --------------------------------------------------------
    -- Slots
    --------------------------------------------------------

    menu:AddEntry(L["MENU_ADD_SLOT"] or "Add Slot", function()
        HG:AddSlotToWindow(windowIndex)
    end)

    menu:AddEntry(L["MENU_REMOVE_SLOT"] or "Remove Slot", function()
        HG:RemoveSlotFromWindow(windowIndex)
    end)

    menu:AddDivider()

    --------------------------------------------------------
    -- Window Actions
    --------------------------------------------------------

    menu:AddEntry(
        windowData.visible and (L["MENU_HIDE_WINDOW"] or "Hide Window") or (L["MENU_SHOW_WINDOW"] or "Show Window"),
        function()
            HG:ToggleWindow(windowIndex)
        end
    )

    menu:AddEntry(L["MENU_RESET"] or "Reset Position", function()
        HG:ResetWindowPosition(windowIndex)
    end)

    if #HarvestGoalDB.windows > 1 then
        menu:AddEntry(L["MENU_DELETE_WINDOW"] or "Delete Window", function()
            HG:DeleteWindow(windowIndex)
        end)
    end

    menu:AddDivider()

    --------------------------------------------------------
    -- Global Actions
    --------------------------------------------------------

    menu:AddEntry(L["MENU_SHOW_ALL_WINDOWS"] or "Show All Windows", function()
        HG:ShowAllWindows()
    end)

    menu:AddEntry(L["MENU_HIDE_ALL_WINDOWS"] or "Hide All Windows", function()
        HG:HideAllWindows()
    end)

    --------------------------------------------------------

    menu:Layout()

    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()

    x = x / scale
    y = y / scale

    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)

    menu.clickCatcher:Show()
    menu:Show()

    menu:SetScript("OnHide", function()
        menu.clickCatcher:Hide()
    end)
end

------------------------------------------------------------
-- Goal Popup
------------------------------------------------------------

StaticPopupDialogs["HG_SET_GOAL"] = {
    text = L["SET_GOAL"] or "Set Goal",
    button1 = OKAY,
    button2 = CANCEL,
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,

    OnShow = function(selfPopup)
        if HG.pendingGoalSlot and HG.pendingGoalSlot.data then
            selfPopup.EditBox:SetText(HG.pendingGoalSlot.data.goal or "")
            selfPopup.EditBox:SetFocus()
            selfPopup.EditBox:HighlightText()
        end
    end,

    OnAccept = function(selfPopup)
        local value = tonumber(selfPopup.EditBox:GetText())

        if value and HG.pendingGoalSlot then
            HG.pendingGoalSlot.data.goal = value
            HG:UpdateWindow(HG.pendingGoalSlot.windowIndex)
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

------------------------------------------------------------
-- Rename Popup
------------------------------------------------------------

StaticPopupDialogs["HG_RENAME_WINDOW"] = {
    text = L["RENAME_WINDOW"] or "Rename Window",
    button1 = OKAY,
    button2 = CANCEL,
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,

    OnShow = function(selfPopup)
        local windowIndex = HG.pendingRenameWindowIndex
        local windowData = windowIndex and HarvestGoalDB.windows[windowIndex]

        if windowData then
            selfPopup.EditBox:SetText(windowData.title or "")
            selfPopup.EditBox:SetFocus()
            selfPopup.EditBox:HighlightText()
        end
    end,

    OnAccept = function(selfPopup)
        local windowIndex = HG.pendingRenameWindowIndex
        local text = selfPopup.EditBox:GetText()

        if windowIndex then
            HG:RenameWindow(windowIndex, text)
        end

        HG.pendingRenameWindowIndex = nil
    end,

    OnHide = function()
        HG.pendingRenameWindowIndex = nil
    end,
}

function HG:PromptRenameWindow(windowIndex)
    self.pendingRenameWindowIndex = windowIndex
    StaticPopup_Show("HG_RENAME_WINDOW")
end
