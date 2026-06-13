local args = ...

local tabs = args.Tabs
local Window = args.Window
local WindUI = args.WindUI
local assets = args.Assets
local Helpers = args.Helpers

tabs.adminkit = Window:Tab({
  Title = "AdminKit",
  Icon = "wrench"
})

local autobuild = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/src/autobuild.lua"))(...)
local players = Helpers.services.players
local tcs = Helpers.services.textchat
local localplr = players.LocalPlayer
local tab = tabs.adminkit











