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
local elements = {}
local selected = {}
local SAVE_DIR = assets("Builds")

local cfg = {
  historymax = 300,
  resizewait = 0.4,
  wbs        = false,
  offset     = Vector3.new(0, 0, 0),
}

tab:Divider()

elements.buildsdropdown = tab:Dropdown({
  Title = "Builds",
  Desc = "Select players builds to save"
  Values = {},
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
  elements.buildsdropdown:Refresh(t)
end
refresh()
players.PlayerAdded:Connect(refresh)
players.PlayerRemoving:Connect(refresh)

elements.buildbtn = Tab:Button({
  Title = "Save",
  Desc = "Save selected player(s) build(s)",
  Locked = false,
  Callback = function()
    elements.buildbtn:Lock()
    elements.buildsdropdown:Lock()
    print(pcall(function()
      lib.save(file_path
    end))
    elements.buildbtn:Unlock()
    elements.buildsdropdown:Unlock()
  end
})

local Input = Tab:Input({
  Title = "Input",
  Desc = "Input Description",
  Value = "Default value",
  InputIcon = "bird",
  Type = "Input", -- or "Textarea"
  Placeholder = "Enter text...",
  Callback = function(input) 
      print("text entered: " .. input)
  end
})
















