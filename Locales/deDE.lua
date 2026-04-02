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
L["TITLE_SECOND"] = "HarvestGoal 2"

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
L["SET_GOAL"] = "Ziel festlegen"

L["TITLE"] = "HarvestGoal"
L["SET_GOAL"] = "Ziel festlegen"
L["RENAME_WINDOW"] = "Fenster umbenennen"

L["MENU_HORIZONTAL"] = "Horizontal"
L["MENU_VERTICAL"] = "Vertikal"
L["MENU_LOCK"] = "Fenster sperren"
L["MENU_UNLOCK"] = "Fenster entsperren"
L["MENU_RESET"] = "Position zurücksetzen"

L["MENU_NEW_WINDOW"] = "Neues Fenster erstellen"
L["MENU_RENAME_WINDOW"] = "Fenster umbenennen"
L["MENU_HIDE_WINDOW"] = "Fenster ausblenden"
L["MENU_SHOW_WINDOW"] = "Fenster einblenden"
L["MENU_SHOW_ALL_WINDOWS"] = "Alle Fenster einblenden"
L["MENU_HIDE_ALL_WINDOWS"] = "Alle Fenster ausblenden"
L["MENU_DELETE_WINDOW"] = "Fenster löschen"

L["MENU_ADD_SLOT"] = "Slot hinzufügen"
L["MENU_REMOVE_SLOT"] = "Slot entfernen"
