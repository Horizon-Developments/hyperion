--[[
  Hyperion Project
  Copyright (c) 2026 Horizon-Developments
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
print("j", Obsidian, Window, Tabs, Assets, Helpers)
Tabs.autobuild = Window:AddTab("Autobuild", "blocks")

local Options = Obsidian.Options
local Main        = Tabs.autobuild:AddLeftGroupbox("File")
local SaveBox     = Tabs.autobuild:AddLeftGroupbox("Save")
local StatsBox    = Tabs.autobuild:AddLeftGroupbox("Stats")
local InstanceBox = Tabs.autobuild:AddRightGroupbox("Instance")
local AsyncBox    = Tabs.autobuild:AddRightGroupbox("Async Bot")

local AutoBuildLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/autobuildv2.lua"))(...)
local HyperionAPI  = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/api.lua"))()
local Path = Assets("BuildsV2")

local Instance = nil

if not isfile(Path .. "/readme.txt") then
  writefile(Path .. "/readme.txt", [[Files are compressed using Zstandard (Zstd) at compression level 22. To access the JSON data parsed by the auto-build script, decompress the files first.]])
end

InstanceBox:SetVisible(false)

-- ── Async bot ─────────────────────────────────────────────────────────────────

local botInstance

AsyncBox:AddLabel("Adds a relay bot that helps build by taking a share of the block list.", true)

AsyncBox:AddButton("GenerateBotURL@autobuild", {
  Text = "Generate Bot URL",
  Func = function()
    if botInstance then
      setclipboard(botInstance:GetClientScript())
      return Obsidian:Notify({
        Title       = "Copied",
        Description = "Script copied to clipboard.",
        Time        = 3,
      })
    end

    local ok, result = HyperionAPI.Bots:CreateInstance()
    if not ok then
      return Obsidian:Notify({
        Title       = "Error",
        Description = tostring(result),
        Time        = 3,
      })
    end

    botInstance = result
    setclipboard(botInstance:GetClientScript())
    Obsidian:Notify({
      Title       = "Success",
      Description = "Script copied to clipboard. Put it in your bot's Autoexecute.",
      Time        = 4,
    })
  end,
})

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

Main:AddButton("Load@autobuild", {
  Text = "Load",
  Func = function()
    if Selected == nil then
      Obsidian:Notify({ Title = "No file selected", Description = "Select a file first.", Time = 3 })
      return
    end

    local asyncCallbacks = {}
    if botInstance and botInstance.Authenticated and botInstance:IsConnected() then
      table.insert(asyncCallbacks, function(script)
        botInstance:SendAsync(script)
      end)
    end

    Instance = AutoBuildLib.build(Selected.Path, { async = asyncCallbacks })
    InstanceBox:SetVisible(true)

    Obsidian:Notify({ Title = "Instance loaded", Description = Selected.Name .. " is ready to run.", Time = 3 })
  end,
})

Main:AddButton("RefreshFileList@autobuild", {
  Text = "Refresh file list",
  Func = function()
    RefreshFileList()
  end,
})

RefreshFileList()

-- ── Save groupbox ────────────────────────────────────────────────────────────

local SaveSelectedNames = {}
local SaveFilename = ""

local function RefreshSaveDropdown()
  local Names = {}
  for _, Player in ipairs(game:GetService("Players"):GetPlayers()) do
    table.insert(Names, Player.Name)
  end
  Options["SavePlayers@autobuild"]:SetValues(Names)
end

SaveBox:AddDropdown("SavePlayers@autobuild", {
  Text     = "Builds (select players to save)",
  Values   = {},
  Default  = {},
  Multi    = true,
  Callback = function(Value)
    SaveSelectedNames = {}
    for name, selected in pairs(Value) do
      if selected then table.insert(SaveSelectedNames, name) end
    end
  end,
})

SaveBox:AddLabel("Refreshes the player list dropdown.", true)
SaveBox:AddButton("RefreshSave@autobuild", {
  Text = "Refresh",
  Func = function()
    RefreshSaveDropdown()
  end,
})

RefreshSaveDropdown()

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

SaveBox:AddButton("SaveButton@autobuild", {
  Text = "Save",
  Func = function()
    Options["SavePlayers@autobuild"]:SetDisabled(true)
    Options["SaveFilename@autobuild"]:SetDisabled(true)
    Options["SaveButton@autobuild"]:SetDisabled(true)

    pcall(function()
      if not SaveFilename or SaveFilename == "" then
        Obsidian:Notify({ Title = "Invalid filename", Description = "Set your filename", Time = 3 })
        return
      end
      if not SaveFilename:match("^[%w_]+$") then
        Obsidian:Notify({ Title = "Invalid filename", Description = "Filenames can only be a-z A-Z 0-9 _", Time = 3 })
        return
      end
      if #SaveSelectedNames == 0 then
        Obsidian:Notify({ Title = "No selected players", Description = "Select players", Time = 3 })
        return
      end

      local Players = {}
      for _, name in ipairs(SaveSelectedNames) do
        local plr = game:GetService("Players"):FindFirstChild(name)
        if plr then table.insert(Players, plr) end
      end

      local blockCount = AutoBuildLib.save(Path .. "/" .. SaveFilename .. ".zst", Players)
      Obsidian:Notify({ Title = "Created successfully", Description = string.format("Saved %d block(s)", blockCount), Time = 3 })
      RefreshFileList()
    end)

    Options["SaveButton@autobuild"]:SetDisabled(false)
    Options["SaveFilename@autobuild"]:SetDisabled(false)
    Options["SavePlayers@autobuild"]:SetDisabled(false)
  end,
})

-- ── Instance groupbox ─────────────────────────────────────────────────────────

InstanceBox:AddButton("RunInstance@autobuild", {
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
}):AddButton("Stop@autobuild", {
  Text = "Stop",
  Func = function()
    if Instance == nil then return end
    Instance.stop()
    Obsidian:Notify({ Title = "Stopped", Description = "Build has been stopped.", Time = 3 })
  end,
})

InstanceBox:AddLabel("Skips the block currently being attempted and moves to the next one.", true)
InstanceBox:AddButton("SkipBlock@autobuild", {
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