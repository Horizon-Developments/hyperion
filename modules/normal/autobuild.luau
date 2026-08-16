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
local Tabs     = args.Tabs
local Window   = args.Window
local Obsidian = args.Obsidian
local Assets   = args.Assets
local Helpers  = args.Helpers

Tabs.autobuild = Window:AddTab("Autobuild", "blocks")

local Options = Library.Options
local Main = Tabs.autobuild:AddLeftGroupbox("File")
local Stats = Tabs.autobuild:AddLeftGroupbox("Stats")
local Instance = Tabs.autobuild:AddRightGroupbox("Instance")

local AutoBuildLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/autobuildv2.lua"))(...)
local Path = Assets("BuildsV2")

local Instance = nil;

if not isfile(Path .. "/readme.txt") then
  writefile(Path .. "/readme.txt", [[Files are compressed using Zstandard (Zstd) at compression level 22. To access the JSON data parsed by the auto-build script, decompress the files first.]])
end



local FileList = {}
local Selcted = nil;
local function RefreshFileList()
  for _, FilePath in ipairs(listfiles(Path)) do
    if Path:match("%.([^%.\\/]+)$") ~= "zst" then continue end
    FileList[FilePath:match("([^\\/]+)$")] = FilePath:match("^(.*)%.[^%.]+$")
  end
	
  Options["FileName@autobuild"]:SetValue()
end


Main:AddDropdown("FileName@autobuild", {
  Text = "Select Filename",
  Values = {},
  Default = {},
  Multi = false,
  Callback = function(v)
    Selcted = v
  end
})



Main:AddButton({
  Text = "Load",
  Func = function()
    
  end
})


Main:AddButton({
  Text = "Refresh filelist",
  Func = function()
    RefreshFileList()
  end
})

RefreshFileList()




























local players  = Helpers.services.players
local localplr = players.LocalPlayer
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
  Text = "Builds (select players to save)",
  Values = {},
  Default = {},
  Multi = true,
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
  for _, p in ipairs(workspace.Bricks:GetChildren()) do
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
  Text = "Filename",
  Placeholder = "Enter text...",
  Callback = function(input)
    if not input or #input == 0 then return end
    if input:match("^[%w_]+$") == nil then
      Obsidian:Notify({
        Title = "Invalid file name",
        Description = "Filenames can only be a-z A-Z 0-9 _",
        Time = 3
      })
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
        Obsidian:Notify({
          Title = "Invalid filename",
          Description = "Set your filename",
          Time = 3
        })
        return
      end

      if #save.selected == 0 then
        Obsidian:Notify({
          Title = "No selected players",
          Description = "Select players",
          Time = 3
        })
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

      Obsidian:Notify({
        Title = "Created successfully",
        Description = "Its at Hyperion/Builds",
        Time = 3
      })

      elements.builddropdown:SetValues(getfiles())
    end))

    elements.savebtn:SetDisabled(false)
    elements.saveinput:SetDisabled(false)
    elements.savedropdown:SetDisabled(false)
  end
})

box:AddDivider()

box:AddLabel({
  Text = "Select a build from your Hyperion/Builds folder.",
  DoesWrap = true
})

elements.builddropdown = box:AddDropdown("buildSelect", {
  Text = "Select build",
  Values = getfiles(),
  Default = getfiles()[1],
  Callback = function(option)
    selected.file = option
  end
})

box:AddLabel({
  Text = "Refreshes the build dropdown.",
  DoesWrap = true
})

box:AddButton({
  Text = "Refresh",
  Func = function()
    file_cache = nil
    elements.builddropdown:SetValues(getfiles())
  end
})

box:AddLabel({
  Text = "Deletes the selected build file from disk.",
  DoesWrap = true
})

box:AddButton({
  Text = "Delete selected",
  Func = function()
    if not selected.file then
      Obsidian:Notify({
        Title = "Nothing selected",
        Description = "Select a build first",
        Time = 3
      })
      return
    end

    local file = selected.file

    pcall(delfile, SAVE_DIR .. "/" .. file .. ".json")

    cache_remove(file)
    selected.file = nil

    elements.builddropdown:SetValues(getfiles())

    Obsidian:Notify({
      Title = "Deleted.",
      Description = "Deleted " .. file,
      Time = 3
    })
  end
})

box:AddLabel({
  Text = "Loads the selected build into a new instance.",
  DoesWrap = true
})

box:AddButton({
  Text = "Load selected",
  Func = function()
    local ok, res = pcall(function()
      if not selected.file then
        Obsidian:Notify({
          Title = "Nothing selected",
          Description = "Select a build first",
          Time = 3
        })
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
              Obsidian:Notify({
                Title = "Waiting for " .. tool,
                Description = tool .. " not found on backpack or character. Waiting...",
                Time = 3
              })
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

      Obsidian:Notify({
        Title = "Instance created, click \"Run instance\"",
        Description = "",
        Time = 3
      })
    else
      instance = nil
    end

    Helpers.log(ok, res)
  end
})

box:AddDivider()

box:AddLabel({
  Text = "Starts the loaded build instance.",
  DoesWrap = true
})

instance_elements.run = box:AddButton({
  Text = "Run instance",
  Disabled = true,
  Func = function()
    local ok, res = pcall(function()
      task.spawn(function()
        if not instance:start() then
          Obsidian:Notify({
            Title = "Failed",
            Description = "screenshot /console then send it in #errors (discord) for help",
            Time = 4
          })
        else
          Obsidian:Notify({
            Title = "Successful",
            Description = "Build finished!",
            Time = 3
          })

          set_instance_active(false)
        end
      end)

      Obsidian:Notify({
        Title = "Building...",
        Description = "Please wait until its finished",
        Time = 3
      })
    end)

    if not ok then
      set_instance_active(false)

      Obsidian:Notify({
        Title = "Failed",
        Description = "screenshot /console then send it in #errors (discord) for help",
        Time = 4
      })
    end

    Helpers.log(ok, res)
  end
})

instance_elements.stop = box:AddButton({
  Text = "Stop instance",
  Disabled = true,
  Func = function()
    local ok, res = pcall(function()
      instance:stop()
    end)

    set_instance_active(false)
    Helpers.log(ok, res)
  end
})

instance_elements.skip = box:AddButton({
  Text = "Skip block",
  Disabled = true,
  Func = function()
    local ok, res = pcall(function()
      instance:skip()

      Obsidian:Notify({
        Title = "Successful",
        Description = "Skipped block",
        Time = 3
      })
    end)

    Helpers.log(ok, res)
  end
})

box:AddLabel({
  Text = "Shows fake blocks as a preview (only visible to you).",
  DoesWrap = true
})

instance_elements.show = box:AddToggle("showPreview", {
  Text = "Show preview",
  Default = false,
  Disabled = true,
  Callback = function(b)
    local ok, res = pcall(function()
      instance:show(b)
    end)

    Helpers.log(ok, res)
  end
})

box:AddLabel({
  Text = "Seconds to wait per resize step. Set to 0 for ping-based timing.",
  DoesWrap = true
})

instance_elements.resizewait = box:AddSlider("resizeWait", {
  Text = "Resize wait",
  Min = 0,
  Max = 2,
  Default = 0.2,
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

box:AddLabel({
  Text = "NOTICE: the main autobuild logic is a very modified version of areyoumental's \"Extra_Stuff__UPDATED_\". credits to him",
  DoesWrap = true
})