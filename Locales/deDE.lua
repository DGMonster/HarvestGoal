-- HarvestGoal - German Localization

if GetLocale() ~= "deDE" then
    return
end

local addonName = ...
local HG = _G[addonName]

HG.L = HG.L or {}
local L = HG.L

------------------------------------------------------------
-- Allgemein
------------------------------------------------------------

L["TITLE"] = "HarvestGoal"

------------------------------------------------------------
-- Minimap Tooltip
------------------------------------------------------------

L["MINIMAP_LEFT"]  = "Linksklick: Fenster anzeigen oder verbergen"
L["MINIMAP_RIGHT"] = "Rechtsklick: Optionen"
L["MINIMAP_DRAG"]  = "Shift + Ziehen: Bewegen"

------------------------------------------------------------
-- Kontextmenü
------------------------------------------------------------

L["MENU_HORIZONTAL"] = "Horizontales Layout"
L["MENU_VERTICAL"]   = "Vertikales Layout"

L["MENU_LOCK"]   = "Fenster sperren"
L["MENU_UNLOCK"] = "Fenster entsperren"

L["MENU_RESET"] = "Position zurücksetzen"

------------------------------------------------------------
-- Ziel Eingabe
------------------------------------------------------------

L["GOAL_SET"] = "Ziel festlegen"
