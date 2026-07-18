--[[
  Hyperion Project
  Copyright (c) 2026 Horizon-Developments
  All rights reserved.
  Repository:
  https://github.com/Horizon-Developments/hyperion
  License:
  https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/LICENSE.md
]]

local args     = ...
local tabs     = args.Tabs
local Window   = args.Window
local Obsidian = args.Obsidian
local assets   = args.Assets
local Helpers  = args.Helpers

tabs.autobuild = Window:AddTab("Autobuild", "blocks")
local box = tabs.autobuild:AddLeftGroupbox("Autobuild")

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/autobuild.lua"))(...)

local players  = Helpers.services.players
local localplr = players.LocalPlayer
local tab      = tabs.autobuild
local elements = {}
local instance
local instance_elements = {}

local save     = { selected = {}, filename = "" }
local selected = { file = nil }
local SAVE_DIR = assets("Builds")

local cfg = {
  historymax = 300,
  resizewait = 0.4,
  wbs        = false,
  offset     = Vector3.new(0, 0, 0),
}

local file_cache = nil

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
    if v == name then
      table.remove(file_cache, i)
      return
    end
  end
end

local function set_instance_active(active)
  for _, el in pairs(instance_elements) do
    el:SetDisabled(not active)
  end
end

elements.savedropdown = box:AddDropdown("saveDropdown", {
  Text     = "Builds (select players to save)",
  Values   = {},
  Default  = {},
  Multi    = true,
  Callback = function(v)
    save.selected = {}
    for name, sel in pairs(v) do
      if sel then
        table.insert(save.selected, name)
      end
    end
  end
})

local function refresh()
  local t = {}
  for _, p in pairs(workspace.Bricks:GetChildren()) do
    if #p:GetChildren() > 0 then
      table.insert(t, p.Name)
    end
  end
  elements.savedropdown:SetValues(t)
end

refresh()
workspace.Bricks.ChildAdded:Connect(refresh)
workspace.Bricks.ChildRemoved:Connect(refresh)

box:AddLabel({ Text = "Refreshes the player list dropdown.", DoesWrap = true })
box:AddButton({
  Text = "Refresh",
  Func = function()
    refresh()
  end
})

box:AddLabel({ Text = "Filename: a-z A-Z 0-9 _ only.", DoesWrap = true })
elements.saveinput = box:AddInput("saveFilename", {
  Text        = "Filename",
  Placeholder = "Enter text...",
  Callback    = function(input)
    if not input or #input == 0 then return end
    if input:match("^[%w_]+$") == nil then
      Obsidian:Notify({ Title = "Invalid file name", Description = "Filenames can only be a-z A-Z 0-9 _", Time = 3 })
      return
    end
    save.filename = input
  end
})

box:AddLabel({ Text = "Saves the selected player(s) build(s) to disk.", DoesWrap = true })
elements.savebtn = box:AddButton({
  Text = "Save",
  Func = function()
    elements.savedropdown:SetDisabled(true)
    elements.saveinput:SetDisabled(true)
    elements.savebtn:SetDisabled(true)
    print(pcall(function()
      if save.filename == "" then
        Obsidian:Notify({ Title = "Invalid filename", Description = "Set your filename", Time = 3 })
        return
      end
      if #save.selected == 0 then
        Obsidian:Notify({ Title = "No selected players", Description = "Select players", Time = 3 })
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
      cache_add(save.filename)
      Obsidian:Notify({ Title = "Created successfully", Description = "Its at Hyperion/Builds", Time = 3 })
      elements.builddropdown:SetValues(getfiles())
    end))
    elements.savebtn:SetDisabled(false)
    elements.saveinput:SetDisabled(false)
    elements.savedropdown:SetDisabled(false)
  end
})

box:AddDivider()

box:AddLabel({ Text = "Select a build from your Hyperion/Builds folder.", DoesWrap = true })
elements.builddropdown = box:AddDropdown("buildSelect", {
  Text     = "Select build",
  Values   = getfiles(),
  Default  = getfiles()[1],
  Callback = function(option)
    selected.file = option
  end
})

box:AddLabel({ Text = "Refreshes the build dropdown.", DoesWrap = true })
box:AddButton({
  Text = "Refresh",
  Func = function()
    file_cache = nil
    elements.builddropdown:SetValues(getfiles())
  end
})

box:AddLabel({ Text = "Deletes the selected build file from disk.", DoesWrap = true })
box:AddButton({
  Text = "Delete selected",
  Func = function()
    if not selected.file then
      Obsidian:Notify({ Title = "Nothing selected", Description = "Select a build first", Time = 3 })
      return
    end
    local file = selected.file
    pcall(delfile, SAVE_DIR .. "/" .. file .. ".json")
    cache_remove(file)
    selected.file = nil
    elements.builddropdown:SetValues(getfiles())
    Obsidian:Notify({ Title = "Deleted.", Description = "Deleted " .. file, Time = 3 })
  end
})

box:AddLabel({ Text = "Loads the selected build into a new instance.", DoesWrap = true })
box:AddButton({
  Text = "Load selected",
  Func = function()
    local ok, res = pcall(function()
      if not selected.file then
        Obsidian:Notify({ Title = "Nothing selected", Description = "Select a build first", Time = 3 })
        return
      end
      instance = lib.build(selected.file, cfg, function(tool)
        local result
        local t = 0
        repeat
          result = localplr.Backpack:FindFirstChild(tool, true)
            or (localplr.Character and localplr.Character:FindFirstChild(tool, true))
          if not result then
            t = t + 0.5
            if t >= 5 then
              t = 0
              Obsidian:Notify({ Title = "Waiting for " .. tool, Description = tool .. " not found on backpack or character. Waiting...", Time = 3 })
            end
            task.wait(0.5)
          end
        until result
        localplr.Character.Humanoid:EquipTool(result)
        return result:FindFirstChild("Event", true)
      end)
    end)
    if ok then
      set_instance_active(true)
      Obsidian:Notify({ Title = 'Instance created, click "Run instance"', Description = "", Time = 3 })
    else
      instance = nil
    end
    Helpers.log(ok, res)
  end
})

box:AddDivider()

box:AddLabel({ Text = "Starts the loaded build instance.", DoesWrap = true })
instance_elements.run = box:AddButton({
  Text     = "Run instance",
  Disabled = true,
  Func     = function()
    local ok, res = pcall(function()
      task.spawn(function()
        if not instance:start() then
          Obsidian:Notify({ Title = "Failed", Description = "screenshot /console then send it in #errors (discord) for help", Time = 4 })
        else
          Obsidian:Notify({ Title = "Successful", Description = "Build finished!", Time = 3 })
          set_instance_active(false)
        end
      end)
      Obsidian:Notify({ Title = "Building...", Description = "Please wait until its finished", Time = 3 })
    end)
    if not ok then
      set_instance_active(false)
      Obsidian:Notify({ Title = "Failed", Description = "screenshot /console then send it in #errors (discord) for help", Time = 4 })
    end
    Helpers.log(ok, res)
  end
})

instance_elements.stop = box:AddButton({
  Text     = "Stop instance",
  Disabled = true,
  Func     = function()
    local ok, res = pcall(function() instance:stop() end)
    set_instance_active(false)
    Helpers.log(ok, res)
  end
})

instance_elements.skip = box:AddButton({
  Text     = "Skip block",
  Disabled = true,
  Func     = function()
    local ok, res = pcall(function()
      instance:skip()
      Obsidian:Notify({ Title = "Successful", Description = "Skipped block", Time = 3 })
    end)
    Helpers.log(ok, res)
  end
})

box:AddLabel({ Text = "Shows fake blocks as a preview (only visible to you).", DoesWrap = true })
instance_elements.show = box:AddToggle("showPreview", {
  Text     = "Show preview",
  Default  = false,
  Disabled = true,
  Callback = function(b)
    local ok, res = pcall(function() instance:show(b) end)
    Helpers.log(ok, res)
  end
})

box:AddLabel({ Text = "Seconds to wait per resize step. Set to 0 for ping-based timing.", DoesWrap = true })
instance_elements.resizewait = box:AddSlider("resizeWait", {
  Text     = "Resize wait",
  Min      = 0,
  Max      = 2,
  Default  = 0.2,
  Rounding = 1,
  Disabled = true,
  Callback = function(val)
    local ok, res = pcall(function()
      if val ~= 0 then
        instance:wbs(false)
        instance:set_resize(val)
      else
        instance:wbs(true)
      end
    end)
    Helpers.log(ok, res)
  end
})

box:AddLabel({ Text = "NOTICE: the main autobuild logic is a very modified version of areyoumental's \"Extra_Stuff__UPDATED_\". credits to him", DoesWrap = true })

box:AddDivider()

box:AddLabel({ Text = "upload, search, and download cloud builds.\nLogin or signup before using any of these.\nThe API is strict, don't spam signups.", DoesWrap = true })

local file     = { desc = "", name = "" }
local cloud    = { sort = "new", keyword = "", result = nil, result_map = {} }
local cloud_el = {}
local _busy    = {}
repeat task.wait(0.1) until getgenv().hyperion_client 
local client = getgenv().hyperion_client 

local function fmterr(err)
  if type(err) == "table" then return "HTTP " .. (err.status or "?") end
  return tostring(err or "Unknown error")
end

local function busy(flag, func, busymsg)
  return function(...)
    if _busy[flag] then
      Obsidian:Notify({ Title = "Busy!", Description = busymsg or "Wait.", Time = 3 })
      return
    end
    _busy[flag] = true
    pcall(func, ...)
    _busy[flag] = false
  end
end

box:AddDivider()

box:AddLabel({ Text = "Upload selected build (10/hr limit)", DoesWrap = true })

box:AddLabel({ Text = "Upload name: a-z A-Z 0-9 only, max 32, no underscores.", DoesWrap = true })
box:AddInput("cloudUploadName", {
  Text        = "Name",
  Placeholder = "Upload name...",
  Callback    = function(v) file.name = v end
})

box:AddLabel({ Text = "Description: a-z A-Z 0-9 only, max 64 characters.", DoesWrap = true })
box:AddInput("cloudUploadDesc", {
  Text        = "Description",
  Placeholder = "Description...",
  Callback    = function(v) file.desc = v end
})

box:AddLabel({ Text = "Uploads the build currently selected on the left panel.", DoesWrap = true })
box:AddButton({
  Text = "Upload selected build",
  Func = busy("upload", function()
    if not selected.file then
      Obsidian:Notify({ Title = "No build selected", Description = "Select a build on the left first", Time = 3 })
      return
    end
    local name = (file.name ~= "" and file.name) or selected.file
    if not name:match("^[A-Za-z0-9]+$") or #name > 32 then
      Obsidian:Notify({ Title = "Invalid name", Description = "Alphanumeric only, max 32, no underscores", Time = 4 })
      return
    end
    local desc = file.desc ~= "" and file.desc or nil
    local id, err = client:upload(SAVE_DIR .. "/" .. selected.file .. ".json", name, desc)
    if not id then
      Obsidian:Notify({ Title = "Upload failed", Description = fmterr(err), Time = 4 })
      return
    end
    Obsidian:Notify({ Title = "Uploaded", Description = "ID: " .. id, Time = 4 })
  end)
})

box:AddDivider()

box:AddLabel({ Text = "Search & download cloud builds (120/hr limit)", DoesWrap = true })

box:AddLabel({ Text = "Keyword search. if set, overrides the sort option below.", DoesWrap = true })
box:AddInput("cloudKeyword", {
  Text        = "Keyword",
  Placeholder = "Leave empty to sort instead...",
  Callback    = function(v) cloud.keyword = v end
})

box:AddLabel({ Text = "Sort order used when no keyword is set.", DoesWrap = true })
box:AddDropdown("cloudSort", {
  Text     = "Sort",
  Values   = { "new", "old", "trending" },
  Default  = "new",
  Callback = function(v) cloud.sort = v end
})

box:AddLabel({ Text = "Search cloud builds.", DoesWrap = true })
box:AddButton({
  Text = "Search",
  Func = busy("search", function()
    local kw = cloud.keyword ~= "" and cloud.keyword or nil
    local data, err = client:list(not kw and cloud.sort or nil, kw)
    if not data then
      Obsidian:Notify({ Title = "Search failed", Description = fmterr(err), Time = 4 })
      return
    end
    cloud.result_map = {}
    local labels = {}
    for _, f in ipairs(data) do
      local label = f.fileid
        .. (f.desc ~= "" and (" - " .. f.desc) or "")
        .. " [" .. f.user .. "]"
      cloud.result_map[label] = f.fileid
      table.insert(labels, label)
    end
    cloud_el.results:SetValues(labels)
    cloud_el.results:SetDisabled(false)
    cloud_el.download:SetDisabled(false)
    Obsidian:Notify({ Title = #data .. " result(s) found", Time = 2 })
  end)
})

box:AddLabel({ Text = "Pick a result from the search above to download.", DoesWrap = true })
cloud_el.results = box:AddDropdown("cloudResults", {
  Text     = "Results",
  Values   = {},
  Disabled = true,
  Callback = function(v) cloud.result = v end
})

box:AddLabel({ Text = "Saves the selected result to your local builds folder.", DoesWrap = true })
cloud_el.download = box:AddButton({
  Text     = "Download to builds",
  Disabled = true,
  Func     = busy("download", function()
    local fileid = cloud.result_map[cloud.result]
    if not fileid then
      Obsidian:Notify({ Title = "Nothing selected", Description = "Search and pick a result first", Time = 3 })
      return
    end
    local data, err = client:download(fileid)
    if not data then
      Obsidian:Notify({ Title = "Download failed", Description = fmterr(err), Time = 4 })
      return
    end
    writefile(SAVE_DIR .. "/" .. fileid .. ".json", data)
    cache_add(fileid)
    elements.builddropdown:SetValues(getfiles())
    Obsidian:Notify({ Title = "Downloaded", Description = "Saved as " .. fileid, Time = 3 })
  end)
})