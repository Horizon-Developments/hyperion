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
local save = {
  selected = {},
  filename = ""
}

local SAVE_DIR = assets("Builds")

local cfg = {
  historymax = 300,
  resizewait = 0.4,
  wbs        = false,
  offset     = Vector3.new(0, 0, 0),
}







elements.savedropdown = tab:Dropdown({
  Title     = "Builds",
  Desc      = "Select players builds to save",
  Values    = {},
  Multi     = true,
  AllowNone = true,
  Callback  = function(v)
    save.selected = v
  end
})

local function refresh()
  local t = {}
  for _, p in pairs(workspace.Bricks:GetChildren()) do
    if #p:GetChildren() > 0 then
      table.insert(t, p.Name)
    end
  end
  elements.savedropdown:Refresh(t)
end
refresh()
players.PlayerAdded:Connect(refresh)
players.PlayerRemoving:Connect(refresh)

elements.savebtn = tab:Button({
  Title    = "Save",
  Desc     = "Save selected player(s) build(s)",
  Locked   = false,
  Callback = function()
    elements.savedropdown:Lock()
    elements.saveinput:Lock()
    elements.savebtn:Lock()
    print(pcall(function()
      if save.filename == "" then
        WindUI:Notify({ Title = "Invalid filename", Content = "Set your filename", Duration = 3 })
        return
      end
      if #save.selected == 0 then
        WindUI:Notify({ Title = "No selected players", Content = "Select players", Duration = 3 })
        return
      end

      local instances = {}
      for _, name in pairs(save.selected) do
        local container = workspace.Bricks:FindFirstChild(name)
        if container then
          table.insert(instances, container)
        end
      end

      lib.save(save.filename, instances)

      WindUI:Notify({ Title = "Created successfully", Content = "Its at Hyperion/Builds", Duration = 3 })
    end))
    elements.savebtn:Unlock()
    elements.saveinput:Unlock()
    elements.savedropdown:Unlock()
  end
})

elements.saveinput = tab:Input({
  Title       = "Filename",
  Desc        = "a-z A-Z 0-9 _ only!",
  Value       = "",
  InputIcon   = "file-pen",
  Type        = "Input",
  Placeholder = "Enter text...",
  Callback    = function(input)
    if not input or #input == 0 then return end
    if input:match("^[%w_]+$") == nil then
      WindUI:Notify({ Title = "Invalid file name", Content = "Filenames can only be a-z A-Z 0-9 _", Duration = 3 })
      return
    end
    save.filename = input
  end
})

tab:Divider()
local selected = nil
local last = nil
while task.wait(5) do
  tab:Dropdown({
    Title = "Select",
    Desc = "Select from builds in Hyperion/Builds",
    Values = listfiles(SAVE_DIR),
    Value = listfiles(SAVE_DIR)[1],
    Callback = function(option) 
      selected = option
    end
  })
end
