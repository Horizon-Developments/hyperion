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

elements.savedropdown = tab:Dropdown({
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
  elements.savedropdown:Refresh(t)
end
refresh()
players.PlayerAdded:Connect(refresh)
players.PlayerRemoving:Connect(refresh)

elements.savebtn = tab:Button({
  Title = "Save",
  Desc = "Save selected player(s) build(s)",
  Locked = false,
  Callback = function()
    elements.savedropdown:Lock()
    elements.saveinput:Lock()
    elements.savebtn:Lock()
    print(pcall(function()
      
    end))
    elements.savebtn:Unlock()
    elements.saveinput:Unlock()
    elements.savedropdown:Unlock()
  end
})

elements.saveinput = tab:Input({
  Title = "Filename",
  Desc = "a-z A-Z 0-9 _ only!",
  Value = nil,
  InputIcon = "file-pen",
  Type = "Input",
  Placeholder = "Enter text...",
  Callback = function(input) 
    if (not input or #input == 0) then return end
    if (input:match("^[%w_]+$") ~= nil) then
      WindUI:Notify({ Title = "Invaild file name", Content = "Filenames can only be a-z A-Z 0-9 _", Duration = 3 })
      return
    end
    
    
    
    
  end
})
















