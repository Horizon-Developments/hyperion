local args = ...

local tabs = args.Tabs
-- tabs register or use tabs here.
local Window = args.Window
-- wind ui window used by Hyperion
local WindUI = args.WindUI
-- WindUi 
local assets = args.Assets
-- store files in assets("your folder") (don't forget to run makefolder though)

tabs.adminkit = Window:Tab({
  Title = "AdminKit",
  Icon = "wrench"
})

local tab = tabs.adminkit

tab:Dropdown({
  Title = "Anti join*",
  Desc = "Prevents join* ",
  Values = { "Anti JoinXL", "Option B", "Option C" },
  Value = {},
  Multi = true,
  Callback = function(value)
    print(value) -- table of selected values
  end
})









