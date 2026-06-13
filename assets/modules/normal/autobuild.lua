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


do
  local dropdown = tab:Dropdown({
    Title = "",
    Values = (function()
        local t = {}
        for _, p in ipairs(Players:GetPlayers()) do
            table.insert(t, p.Name)
        end
        return t
    end)(),
    Multi = true,
    AllowNone = true,
    Callback = function() end
})

local function refresh()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(t, p.Name)
    end
    dropdown:Refresh(t)
end

Players.PlayerAdded:Connect(refresh)
Players.PlayerRemoving:Connect(refresh)
  
  
end


















