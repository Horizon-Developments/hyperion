local args = ...
local tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local assets = args.Assets

tabs.attack = Window:AddTab("Attack", "hand-fist")
local box = tabs.attack:AddLeftGroupbox("Attack")

local plrs = game:GetService("Players")
local localplr = plrs.LocalPlayer

box:AddButton({
  Text = "Disable bkit",
  Tooltip = "Perma disables bkit. from pealz",
  Func = function()
    if not game:GetService("ReplicatedStorage").Brick then
      Obsidian:Notify({ Title = "Successful?", Description = "bkit was already disabled", Time = 3 })
      return
    end

    local ok, err = pcall(function()
      local char = localplr.Character
      char.Delete.Script.Event:FireServer(
        game:GetService("ReplicatedStorage").Brick,
        char.HumanoidRootPart.Position
      )
    end)
    if not ok then
      Obsidian:Notify({ Title = "Not successful", Description = "You do not have delete tool in hand", Time = 3 })
      print("ERR: ", err)
      return
    end
    Obsidian:Notify({ Title = "Successful!", Description = "Disabled bkit.", Time = 3 })
  end
})