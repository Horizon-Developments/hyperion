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

tabs.plugins = Window:AddTab("Plugins", "blocks")
local box = tabs.plugins:AddLeftGroupbox("Plugins")
local client = getgenv().hyperion_client
local search = nil
local dropdown = nil
local searchtbl = {}
local _busy = {}

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

box:AddLabel({ Text = "This tab allows you to download plugins from our discord server ingame!\nSign in before using.", DoesWrap = true })
box:AddDivider()
box:AddLabel({ Text = "Download Plugins (60/hr limit)", DoesWrap = true })
box:AddLabel({ Text = "Search: 1-16 alphanumeric only", DoesWrap = true })

box:AddInput("plugins.Search", {
  Text        = "Search input",
  Placeholder = "Search plugins...",
  Callback    = function(v) search = v end
})

box:AddButton({
  Text = "Search",
  Func = busy("plugins.SearchBtn", function()
    if not search or search == "" then
      Obsidian:Notify({ Title = "Error", Description = "Enter a search term first.", Time = 3 })
      return
    end

    local res, err = client:plugins(search)
    if not res then
      Obsidian:Notify({ Title = "Search Failed", Description = tostring(err), Time = 4 })
      return
    end

    if #res == 0 then
      Obsidian:Notify({ Title = "No Results", Description = "No plugins found for: " .. search, Time = 3 })
      return
    end

    searchtbl = {}
    local titles = {}
    for i, v in ipairs(res) do
      local key = v.title .. " (@" .. v.username .. ")"
      searchtbl[key] = v
      titles[i] = key
    end

    dropdown:SetValues(titles)
    Obsidian:Notify({ Title = "Found!", Description = #res .. " plugin(s) found.", Time = 3 })
  end, "Search already in progress...")
})

dropdown = box:AddDropdown("plugins.dropdown", {
  Values     = {},
  Default    = 1,
  Multi      = false,
  Text       = "Select Plugin",
  Tooltip    = "Select a plugin to execute",
  Searchable = true,
  Callback   = function(val)
    if not val or val == "" then return end
    local dat = searchtbl[val]
    if not dat then
      Obsidian:Notify({ Title = "Error", Description = "Plugin data not found.", Time = 3 })
      return
    end

    local ok, content = pcall(game.HttpGet, game, dat.url)
    if not ok or not content or content == "" then
      Obsidian:Notify({ Title = "Download Failed", Description = "Could not fetch plugin.", Time = 4 })
      return
    end

    local writeOk, writeErr = pcall(writefile, assets("modules", dat.filename), content)
    if not writeOk then
      Helpers.log("PLUGINS@WRITEFILE", writeErr)
    end

    Obsidian:Notify(writeOk
      and { Title = "Loading...",          Description = dat.title .. " by @" .. dat.username, Time = 3 }
      or  { Title = "Failed to writefile", Description = dat.title .. " by @" .. dat.username, Time = 3 }
    )

    local fn, loadErr = loadstring(content)
    if not fn then
      Helpers.log("PLUGINS@LOADSTRING", loadErr)
      Obsidian:Notify({ Title = "Parse Failed", Description = "Error is logged in console", Time = 4 })
      return
    end
    
    local execOk, execErr = pcall(fn, args)
    if not execOk then
      Helpers.log("PLUGINS@EXECUTE " .. dat.filename, execErr)
      Obsidian:Notify({ Title = "Execute Failed", Description = "Error is logged in console", Time = 4 })
      return
    end
    
    Obsidian:Notify({ Title = "Plugin Loaded", Description = dat.title .. " by @" .. dat.username, Time = 3 })
  end,
  Disabled = false,
  Visible  = true,
})