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
local Main        = Tabs.autobuild:AddLeftGroupbox("File")
local SaveBox     = Tabs.autobuild:AddLeftGroupbox("Save")
local StatsBox    = Tabs.autobuild:AddLeftGroupbox("Stats")
local InstanceBox = Tabs.autobuild:AddRightGroupbox("Instance")

local AutoBuildLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/autobuildv2.lua"))(...)
local Path = Assets("BuildsV2")

local Instance = nil

if not isfile(Path .. "/readme.txt") then
  writefile(Path .. "/readme.txt", [[Files are compressed using Zstandard (Zstd) at compression level 22. To access the JSON data parsed by the auto-build script, decompress the files first.]])
end

InstanceBox:SetVisible(false)

-- ── File list ─────────────────────────────────────────────────────────────────

local FileList = {}
local Selected = nil

local function RefreshFileList()
  FileList = {}

  for _, FilePath in ipairs(listfiles(Path)) do
    if FilePath:match("%.([^%.\\/]+)$") ~= "zst" then continue end
    table.insert(FileList, FilePath)
  end

  if Selected ~= nil and not table.find(FileList, Selected.Path) then
    Selected = nil
  end

  Options["FileName@autobuild"]:SetValues(FileList)
  Options["FileName@autobuild"]:SetValue(Selected and Selected.Path or nil)
end

-- ── File groupbox ─────────────────────────────────────────────────────────────

Main:AddDropdown("FileName@autobuild", {
  Values = {},
  Text   = "File",
  FormatDisplayValue = function(Value)
    return Value:match("([^\\/]+)$"):match("^(.*)%.[^%.]+$")
  end,
  Callback = function(Value)
    if Value then
      Selected = {
        Path = Value,
        Name = Value:match("([^\\/]+)$"):match("^(.*)%.[^%.]+$"),
      }
    else
      Selected = nil
    end
  end,
})

Main:AddButton({
  Text = "Load",
  Func = function()
    if Selected == nil then
      Obsidian:Notify({ Title = "No file selected", Description = "Select a file first.", Time = 3 })
      return
    end

    Instance = AutoBuildLib.build(Selected.Path)
    InstanceBox:SetVisible(true)

    Obsidian:Notify({ Title = "Instance loaded", Description = Selected.Name .. " is ready to run.", Time = 3 })
  end,
})

Main:AddButton({
  Text = "Refresh file list",
  Func = function()
    RefreshFileList()
  end,
})

-- ── Save groupbox ────────────────────────────────────────────────────────────

local SaveSelectedPlayers = {}
local SaveFilename = ""

SaveBox:AddLabel("Select the player(s) whose builds you want to save.", true)

SaveBox:AddDropdown("SavePlayers@autobuild", {
  SpecialType = "Player",
  ExcludeLocalPlayer = false,
  Multi = true,
  Text = "Players",
  Callback = function(Value)
    SaveSelectedPlayers = {}
    for name, selected in pairs(Value) do
      if selected then
        local plr = game:GetService("Players"):FindFirstChild(name)
        if plr then table.insert(SaveSelectedPlayers, plr) end
      end
    end
  end,
})

SaveBox:AddLabel("Filename: a-z A-Z 0-9 _ only.", true)

SaveBox:AddInput("SaveFilename@autobuild", {
  Text = "Filename",
  Placeholder = "my_build",
  ClearTextOnFocus = false,
  Finished = true,
  Callback = function(Value)
    SaveFilename = Value
  end,
})

SaveBox:AddButton({
  Text = "Save",
  Func = function()
    if not SaveFilename or SaveFilename == "" then
      Obsidian:Notify({ Title = "Invalid filename", Description = "Set a filename first.", Time = 3 })
      return
    end
    if not SaveFilename:match("^[%w_]+$") then
      Obsidian:Notify({ Title = "Invalid filename", Description = "Filenames can only be a-z A-Z 0-9 _", Time = 3 })
      return
    end
    if #SaveSelectedPlayers == 0 then
      Obsidian:Notify({ Title = "No players selected", Description = "Select at least one player.", Time = 3 })
      return
    end

    local FullPath = Path .. "/" .. SaveFilename .. ".zst"

    local ok, blockCount = pcall(function()
      return AutoBuildLib.save(FullPath, SaveSelectedPlayers)
    end)

    if ok then
      Obsidian:Notify({
        Title = "Saved",
        Description = string.format("Saved %d block(s) to %s.zst", blockCount, SaveFilename),
        Time = 3,
      })
      RefreshFileList()
    else
      Obsidian:Notify({ Title = "Save failed", Description = tostring(blockCount), Time = 6 })
    end
  end,
})

RefreshFileList()

-- ── Instance groupbox ─────────────────────────────────────────────────────────

InstanceBox:AddButton({
  Text = "Run instance",
  Func = function()
    if Instance == nil then
      Obsidian:Notify({ Title = "No instance loaded", Description = "Load a file first.", Time = 3 })
      return
    end

    local ok, res = pcall(function()
      task.spawn(function()
        Instance.start()
        Obsidian:Notify({ Title = "Build done", Description = "Build completed successfully.", Time = 3 })
      end)
    end)

    if ok then
      Obsidian:Notify({ Title = "Building...", Description = "Build is now running.", Time = 3 })
    else
      Obsidian:Notify({ Title = "Failed to start", Description = tostring(res), Time = 8 })
    end

    Helpers.log(ok, res)
  end,
}):AddButton({
  Text = "Stop",
  Func = function()
    if Instance == nil then return end
    Instance.stop()
    Obsidian:Notify({ Title = "Stopped", Description = "Build has been stopped.", Time = 3 })
  end,
})

InstanceBox:AddLabel("Skips the block currently being attempted and moves to the next one.", true)
InstanceBox:AddButton({
  Text = "Skip block",
  Func = function()
    if Instance == nil then return end
    Instance.skip()
    Obsidian:Notify({ Title = "Autobuild", Description = "Skipped current block.", Time = 1.5 })
  end,
})

InstanceBox:AddDivider()

InstanceBox:AddLabel("Fires the place remote before setting block properties.", true)
InstanceBox:AddToggle("WaitBeforeSet@autobuild", {
  Text    = "Wait before set",
  Default = false,
  Callback = function(v)
    if Instance == nil then return end
    Instance.wbs(v)
    Obsidian:Notify({ Title = "Autobuild", Description = "Wait before set: " .. tostring(v), Time = 1.5 })
  end,
})

InstanceBox:AddLabel("How long to wait (seconds) after resizing a block before continuing.", true)
InstanceBox:AddSlider("ResizeWait@autobuild", {
  Text     = "Resize wait",
  Default  = 0.2,
  Min      = 0,
  Max      = 1,
  Rounding = 2,
  Callback = function(v)
    if Instance == nil then return end
    Instance.resizewait(v)
    Obsidian:Notify({ Title = "Autobuild", Description = "Resize wait: " .. v, Time = 1.5 })
  end,
})

InstanceBox:AddLabel("Maximum number of placement attempts per block before giving up.", true)
InstanceBox:AddSlider("MaxTries@autobuild", {
  Text     = "Max tries",
  Default  = 150,
  Min      = 1,
  Max      = 500,
  Rounding = 0,
  Callback = function(v)
    if Instance == nil then return end
    Instance.try(nil, v)
    Obsidian:Notify({ Title = "Autobuild", Description = "Max tries: " .. v, Time = 1.5 })
  end,
})

InstanceBox:AddLabel("Delay between each placement attempt. Set to 0 to let autobuild decide based on ping.", true)
InstanceBox:AddSlider("TryDelay@autobuild", {
  Text     = "Try delay (0 = auto)",
  Default  = 0,
  Min      = 0,
  Max      = 1,
  Rounding = 3,
  Callback = function(v)
    if Instance == nil then return end
    local delay = v == 0 and nil or v
    Instance.try(delay, nil)
    Obsidian:Notify({ Title = "Autobuild", Description = "Try delay: " .. (delay and tostring(v) or "auto"), Time = 1.5 })
  end,
})

local StatsLabels = {
    progress = StatsBox:AddLabel("Progress:", true),
    elapsed  = StatsBox:AddLabel("Elapsed:", true),
    eta      = StatsBox:AddLabel("ETA:", true),
    ping     = StatsBox:AddLabel("Ping:", true),
}

game:GetService("RunService").RenderStepped:Connect(function()
    if Instance == nil then return end

    local s = Instance.stats

    StatsLabels.progress:SetText(string.format("Progress: %d / %d", s.done, s.total))
    StatsLabels.elapsed:SetText(string.format("Elapsed: %.1fs", s.elapsed))
    StatsLabels.eta:SetText(s.eta and string.format("ETA: %.1fs", s.eta) or "ETA:")
    StatsLabels.ping:SetText(string.format("Ping: %dms", s.ping))
end)