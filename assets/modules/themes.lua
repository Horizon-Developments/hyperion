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