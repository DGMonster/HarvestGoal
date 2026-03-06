-- HarvestGoal - Init.lua

local addonName = ...
local HG = {}
_G[addonName] = HG

HG.name = addonName

HarvestGoalDB = HarvestGoalDB or {}

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

local function CopyDefaults(src, dst)
    if type(src) ~= "table" then return end
    if type(dst) ~= "table" then dst = {} end

    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end

    return dst
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then return end

    HarvestGoalDB = CopyDefaults(defaults, HarvestGoalDB)

    if HG.Init then
        HG:Init()
    end

    print("|cff3cb371HarvestGoal|r loaded.")
end)