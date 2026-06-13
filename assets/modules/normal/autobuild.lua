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
local instance
local instance_elements = {}

local save = {
  selected = {},
  filename = ""
}

local selected = {
  file = nil
}

local SAVE_DIR = assets("Builds")

local cfg = {
  historymax = 300,
  resizewait = 0.4,
  wbs        = false,
  offset     = Vector3.new(0, 0, 0),
}

-- ── file list cache ──────────────────────────────────────────────────────────
-- Populated lazily on first use; updated incrementally on save/delete.
-- Only re-scanned from disk when the user hits Refresh explicitly.

local file_cache = nil  -- nil = dirty, table = valid

local function stripname(fullpath)
  local name = fullpath:match("([^/\\]+)$") or fullpath
  return name:match("^(.+)%.[^.]+$") or name
end

local function getfiles()
  if not file_cache then
    file_cache = {}
    for _, f in ipairs(listfiles(SAVE_DIR)) do
      table.insert(file_cache, stripname(f))
    end
  end
  return file_cache
end

local function cache_add(name)
  getfiles()
  for _, v in ipairs(file_cache) do
    if v == name then return end
  end
  table.insert(file_cache, name)
end

local function cache_remove(name)
  if not file_cache then return end
  for i, v in ipairs(file_cache) do
    if v == name then table.remove(file_cache, i); return end
  end
end
-- ─────────────────────────────────────────────────────────────────────────────

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

      lib.save(save.filename, instances)  -- one disk write
      cache_add(save.filename)            -- update list in memory

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

elements.builddropdown = tab:Dropdown({
  Title    = "Select",
  Desc     = "Select from builds in Hyperion/Builds",
  Values   = getfiles(),  -- one listfiles() call at startup
  Value    = getfiles()[1],
  Callback = function(option)
    selected.file = option
    -- no Refresh here; cache is already current
  end
})

tab:Button({
  Title    = "Refresh",
  Desc     = "Refreshes the selected dropdown",
  Locked   = false,
  Callback = function()
    file_cache = nil                                      -- force re-scan
    elements.builddropdown:Refresh(getfiles())           -- one listfiles()
  end
})

tab:Button({
  Title    = "Delete selected",
  Desc     = "Deletes file",
  Locked   = false,
  Callback = function()
    if not selected.file then
      WindUI:Notify({ Title = "Nothing selected", Content = "Select a build first", Duration = 3 })
      return
    end
    local file = selected.file
    pcall(delfile, SAVE_DIR .. "/" .. file .. ".json")  -- one disk delete
    cache_remove(file)                                   -- update list in memory
    selected.file = nil
    elements.builddropdown:Refresh(getfiles())           -- no IO, uses cache
    WindUI:Notify({ Title = "Deleted.", Content = "Deleted " .. file, Duration = 3 })
  end
})

tab:Button({
  Title    = "Load selected",
  Desc     = "Loads file",
  Locked   = false,
  Callback = function()
    local ok, res = pcall(function()
      for _, v in pairs(instance_elements) do
        v:Unlock()
      end
      if not selected.file then
        WindUI:Notify({ Title = "Nothing selected", Content = "Select a build first", Duration = 3 })
        return
      end
      instance = lib.build(selected.file, cfg, function(tool)
        local result
        local t = 0
        repeat
          result = localplr.Backpack:FindFirstChild(tool, true)
              or localplr.Character:FindFirstChild(tool, true)
          if not result then
            t = t + 0.5
            if t >= 5 then
              t = 0
              WindUI:Notify({
                Title   = "Waiting for " .. tool,
                Content = tool .. " not found on backpack or character. Waiting...",
                Duration = 3,
              })
            end
            task.wait(0.5)
          end
        until result
        return result:FindFirstChild("Event", true)
      end)
    end)
    if not ok then instance = nil end
    Helpers.log(ok, res)
  end
})

tab:Divider()

instance_elements.run = tab:Button({
  Title    = "Run instance",
  Desc     = "auto build",
  Locked   = false,
  Callback = function()
    local ok, res = pcall(function()
      task.spawn(function()
        if not instance:start() then
          WindUI:Notify({ Title = "Failed", Content = "screenshot /console then send it in #errors (discord) for help", Duration = 4 })
        else
          WindUI:Notify({ Title = "Successful", Content = "Build finished!", Duration = 3 })
        end
      end)
      WindUI:Notify({ Title = "Building...", Content = "Please wait until its finished", Duration = 3 })
    end)
    if not ok then
      WindUI:Notify({ Title = "Failed", Content = "screenshot /console then send it in #errors (discord) for help", Duration = 4 })
    end
    Helpers.log(ok, res)
    for _, v in pairs(instance_elements) do
      v:Lock()
    end
  end
})

instance_elements.stop = tab:Button({
  Title    = "Stop instance",
  Locked   = false,
  Callback = function()
    local ok, res = pcall(function()
      instance:stop()
    end)
    Helpers.log(ok, res)
  end
})

instance_elements.skip = tab:Button({
  Title    = "Skip block",
  Locked   = false,
  Callback = function()
    local ok, res = pcall(function()
      instance:skip()
    end)
    Helpers.log(ok, res)
  end
})

instance_elements.show = tab:Toggle({
  Title = "Show preview",
  Desc = "Shows fake blocks for preview (only you can see)",
  Icon = "bird",
  Type = "Checkbox",
  Value = false,
  Callback = function(b)
    local ok, res = pcall(function()
      instance:show(b)
    end)
    Helpers.log(ok, res)
  end
})

instance_elements.resizewait = tab:Slider({
  Title = "Resize wait",
  Desc  = "how many s wait per resize (0 = ping based)",
  Step  = 0.1,
  Value = {
    Min     = 0,
    Max     = 2,
    Default = 0.2,
  },
  Callback = function(val)
    local ok, res = pcall(function()
      instance:set_resize(val)
    end)
    Helpers.log(ok, res)
  end
})

for _, v in pairs(instance_elements) do
  v:Lock()
end