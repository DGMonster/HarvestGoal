-- HarvestGoal - Init.lua
-- Handles addon initialization, database defaults and event startup

local addonName = ...
local HG = {}
_G[addonName] = HG

HG.name = addonName
HG.VERSION = "@project-version@"

------------------------------------------------------------
-- Localization Table (will be filled by language files)
------------------------------------------------------------

HG.L = HG.L or {}
local L = HG.L

------------------------------------------------------------
-- SavedVariables
------------------------------------------------------------

HarvestGoalDB = HarvestGoalDB or {}

------------------------------------------------------------
-- Default Settings
------------------------------------------------------------

local defaults = {
    locked = false,
    layout = "HORIZONTAL",
    visible = true,

    slots = {
        { itemID = nil, goal = 0 },
        { itemID = nil, goal = 0 },
        { itemID = nil, goal = 0 },
        { itemID = nil, goal = 0 },
        { itemID = nil, goal = 0 },
        { itemID = nil, goal = 0 },
    },

    minimap = {
        angle = 45,
        hide = false,
    }
}

------------------------------------------------------------
-- Utility: Copy default values into SavedVariables
------------------------------------------------------------

local function CopyDefaults(source, target)

    if type(source) ~= "table" then
        return target
    end

    target = target or {}

    for key, value in pairs(source) do
        if type(value) == "table" then
            target[key] = CopyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end

    return target
end

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
    -- Apply default settings
    --------------------------------------------------------

    HarvestGoalDB = CopyDefaults(defaults, HarvestGoalDB)

    --------------------------------------------------------
    -- Initialize addon
    --------------------------------------------------------

    if HG.Init then
        HG:Init()
    end

    --------------------------------------------------------
    -- Stop listening after initialization
    --------------------------------------------------------

    self:UnregisterEvent("ADDON_LOADED")

    --------------------------------------------------------
    -- Load message
    --------------------------------------------------------

    print("|cff3cb371HarvestGoal|r v" .. HG.VERSION .. " loaded.")

end)
