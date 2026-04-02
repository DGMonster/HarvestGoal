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

L["MINIMAP_LEFT"]  = "Linksklick: Alle Fenster anzeigen oder verbergen"
L["MINIMAP_RIGHT"] = "Rechtsklick: Optionen"
L["MINIMAP_DRAG"]  = "Shift + Ziehen: Bewegen"

------------------------------------------------------------
-- Kontextmenü
------------------------------------------------------------

L["MENU_NEW_WINDOW"]       = "Neues Fenster erstellen"
L["MENU_RENAME_WINDOW"]    = "Fenster umbenennen"

L["MENU_HORIZONTAL"]       = "Horizontales Layout"
L["MENU_VERTICAL"]         = "Vertikales Layout"

L["MENU_LOCK"]             = "Fenster sperren"
L["MENU_UNLOCK"]           = "Fenster entsperren"

L["MENU_ADD_SLOT"]         = "Slot hinzufügen"
L["MENU_REMOVE_SLOT"]      = "Slot entfernen"

L["MENU_HIDE_WINDOW"]      = "Fenster ausblenden"
L["MENU_SHOW_WINDOW"]      = "Fenster einblenden"
L["MENU_DELETE_WINDOW"]    = "Fenster löschen"

L["MENU_SHOW_ALL_WINDOWS"] = "Alle Fenster einblenden"
L["MENU_HIDE_ALL_WINDOWS"] = "Alle Fenster ausblenden"

L["MENU_RESET"]            = "Position zurücksetzen"

------------------------------------------------------------
-- Popups
------------------------------------------------------------

L["GOAL_SET"]      = "Ziel festlegen"
L["RENAME_WINDOW"] = "Fenster umbenennen"
