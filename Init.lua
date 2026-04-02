-- HarvestGoal - Init.lua
-- Handles addon initialization

local addonName = ...
local HG = {}
_G[addonName] = HG

HG.name = addonName
HG.VERSION = @project-version@"

------------------------------------------------------------
-- Localization Table (filled by language files)
------------------------------------------------------------

HG.L = HG.L or {}
local L = HG.L

------------------------------------------------------------
-- SavedVariables
------------------------------------------------------------

HarvestGoalDB = HarvestGoalDB or {}

------------------------------------------------------------
-- Addon Loading
------------------------------------------------------------

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")

loader:SetScript("OnEvent", function(self, event, name)

    if name ~= addonName then
        return
    end

    --------------------------------------------------------
    -- Initialize addon (Core übernimmt alles)
    --------------------------------------------------------

    if HG.Init then
        HG:Init()
    end

    --------------------------------------------------------
    -- Stop listening
    --------------------------------------------------------

    self:UnregisterEvent("ADDON_LOADED")

    --------------------------------------------------------
    -- Load message
    --------------------------------------------------------

    print("|cff3cb371HarvestGoal|r v" .. HG.VERSION .. " loaded.")

end)
