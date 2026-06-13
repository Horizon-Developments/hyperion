local args = ...

local tabs   = args.Tabs
local Window = args.Window
local WindUI = args.WindUI
local assets = args.Assets
local Helpers = args.Helpers

tabs.autobuild = Window:Tab({
    Title = "Autobuild",
    Icon  = "blocks",
})

local lib      = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/src/autobuild.lua"))(...)
local players  = Helpers.services.players
local localplr = players.LocalPlayer
local tab      = tabs.autobuild
local SAVE_DIR = assets("Builds")

local cfg = {
  historymax = 300,
  resizewait = 0.4,
  wbs        = false,
  offset     = Vector3.new(0, 0, 0),
}

tab:Divider()
local selected = {}

do
  local dropdown = tab:Dropdown({
    Title = "Builds",
    Desc = "Select players builds to save"
    Values = (function()
      local t = {}
      for _, p in ipairs(players:GetPlayers()) do
        table.insert(t, p.Name)
      end
      return t
    end)(),
    Multi = true,
    AllowNone = true,
    Callback = function(v) 
      selected = v
    end
  })
  local function refresh()
    local t = {}
    for _, p in ipairs(players:GetPlayers()) do
      table.insert(t, p.Name)
    end
    dropdown:Refresh(t)
  end
  players.PlayerAdded:Connect(refresh)
  players.PlayerRemoving:Connect(refresh)
end


















