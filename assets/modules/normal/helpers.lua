local args = ...
local Window = args.Window
local Tabs = args.Tabs
local Helpers = args.Helpers

Tabs.helpers = Window:AddTab("Helpers", "help-circle")
local box = Tabs.helpers:AddLeftGroupbox("Helpers")
