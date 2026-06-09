local args = ...

local tabs = args.Tabs
-- tabs register or use tabs here.
local Window = args.Window
-- wind ui window used by Hyperion
local WindUI = args.WindUI
-- WindUi 
local assets = args.Assets
-- store files in assets("your folder") (don't forget to run makefolder though)

tabs.attack = Window:Tab({
  Title = "Attack",
  Icon = "hand-fist"
})

local tab = tabs.attack

local plrs = game:GetService("Players")
local localplr = plrs.LocalPlayer



Tab:Button({
  Title = "Disable bkit",
  Desc = "Perma disables bkit. from pealz",
  Icon = "pen-off",
  Callback = function()
    local ok, err = pcall(function() 
      local char = localplr.Character
      char.Delete.Script.Event:FireServer(
        game:GetService("ReplicatedStorage").Brick,
        char.HumanoidRootPart.Position
      )
    end)
    if (not ok) then
      WindUI:Notify({ Title = "Not successful", Content = "Disabled bkit.", Duration = 3 })
    end
    WindUI:Notify({ Title = "Sucessful!", Content = "Disabled bkit.", Duration = 3 })
  end
})


















