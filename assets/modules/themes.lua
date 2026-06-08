local args = ...

local tabs = args.tabs
-- tabs, register or use tabs here.
local Window = args.Window
-- wind ui window used by Hyperion
local WindUI = args.WindUI
-- WindUi 

[code]


tabs.info:Dropdown({
	Title = "Theme",
	Icon = "palette",
	Values = { "Hyperion", "Dark", "Light", "Rose", "Plant", "Indigo", "Sky", "Violet", "Amber" },
	Value = savedTheme,
	Callback = function(value)
		writefile(assets("theme.txt"), value)
		WindUI:SetTheme(value)
	end,
})