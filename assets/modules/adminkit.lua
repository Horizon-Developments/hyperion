local args = ...

local tabs = args.Tabs
-- tabs register or use tabs here.
local Window = args.Window
-- wind ui window used by Hyperion
local WindUI = args.WindUI
-- WindUi 
local assets = args.Assets
-- store files in assets("your folder") (don't forget to run makefolder though)

local utils = args.Utils

tabs.adminkit = Window:Tab({
  Title = "AdminKit",
  Icon = "wrench"
})

local tab = tabs.adminkit
local toggles = {}


tab:Dropdown({
  Title = "Anti join*",
  Desc = "Prevents join* (:",
  Values = { "joinxl", "joinog", "joinvc" },
  Value = {},
  Multi = true,
  Callback = function(selected)
    toggles.antijoin = selected
  end
})









