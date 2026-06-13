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
local builder = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/src/autobuild.lua"))(...)
local players = Helpers.services.players
local tcs = Helpers.services.textchat
local localplr = players.LocalPlayer
local tab = tabs.autobuild

tab:Paragraph({
  Title = "Credits",
  Desc = "Credits to areyoumental (areyoumental110 in Discord),\nwe used Extra Stuff's (from areyoumental) source code for this."
})

tab:Input({
  Title = "Max history",
  Placeholder = "300-30000",
  Callback = function(v)
    toggles.OnFriendsJoin = v
  end
})










local builder = lib.build("my_build", {
    tp = true,
    offset = Vector3.new(0, 0, 0),
    mult = 4,
    historymax = 400,
    resizewait = 0.4,
    wbs = false
}, function(toolname)
    return get_tool(toolname)
end)







