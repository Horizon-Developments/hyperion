local args = ...

local tabs = args.Tabs
local Window = args.Window
local WindUI = args.WindUI
local assets = args.Assets
local Helpers = args.Helpers

tabs.autobuild = Window:Tab({
  Title = "Autobuild",
  Icon = "blocks"
})

--// Main logic here.
local autobuild = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/src/autobuild.lua"))(...)
local players = Helpers.services.players
local tcs = Helpers.services.textchat
local localplr = players.LocalPlayer
local tab = tabs.autobuild

tabs.info:Paragraph({ Title = "Credits", Icon = "layers", Desc = "Hyperion is a modular system. Instead of using a separate script, you can extend it with plugins. Visit the #plugins channel on our Discord to find and share plugins." })