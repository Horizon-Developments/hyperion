--[[
loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/loader.lua"))()
]]

if getgenv().hyperion and not (...) then return end
getgenv().hyperion = true
print("[STEP 1]: loader start")

local Api = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/api.lua"))()
print("[STEP 2]: api loaded")

local mainok, mainres = pcall(task.spawn, function()
  local function log(...)
    print("[HYPERION]: ", ...)
  end
  local cloneref = getgenv().cloneref or function(a) return a end
  if not getgenv().cloneref then
    print("[STEP 3]: cloneref not found, using polyfill")
  end
  local http = cloneref(game:GetService("HttpService"))
  local tcs = cloneref(game:GetService("TextChatService"))
  local localplr = cloneref(game:GetService("Players")).LocalPlayer
  local isog = game.PlaceId == 108097274488844
  print("[STEP 4]: services cloned, isog =", isog)

  local function assets(...)
    return table.concat({ "Hyperion", ... }, "/")
  end

  makefolder("Hyperion")
  makefolder(assets("modules"))
  makefolder(assets("modules", "og"))
  makefolder(assets("modules", "normal"))
  makefolder(assets("modules", "both"))
  makefolder(assets("cache"))
  print("[STEP 5]: folders created")

  local Obsidian, ThemeManager, Invite
  do
    local pending = 3
    task.spawn(function()
      print("[STEP 6a]: loading Obsidian...")
      Obsidian = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
      print("[STEP 6a]: Obsidian loaded")
      pending -= 1
    end)
    task.spawn(function()
      print("[STEP 6b]: loading ThemeManager...")
      ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
      print("[STEP 6b]: ThemeManager loaded")
      pending -= 1
    end)
    task.spawn(function()
      print("[STEP 6c]: fetching invite...")
      Invite = game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/main/assets/discord_invite.txt")
      print("[STEP 6c]: invite fetched")
      pending -= 1
    end)
    repeat task.wait() until pending <= 0
    print("[STEP 7]: all parallel fetches done")
  end

  local Helpers = {}
  do
    Helpers.log = log
    Helpers.selfchat = function(msg, noAdded)
      if noAdded then
        tcs.TextChannels.RBXGeneral:DisplaySystemMessage('<font color="rgb(255,0,0)">[HYPERION]: ' .. msg .. '</font>')
      else
        tcs.TextChannels.RBXGeneral:DisplaySystemMessage(msg)
      end
    end
    local pending_chat_check = {}
    local ChatListeners = {}
    local colors = {
      peasant = {hex = "#966766", r = 150, g = 103, b = 102},
      arken = {hex = "#04afec", r = 4, g = 175, b = 236},
      admin = {hex = "#f5cd30", r = 245, g = 205, b = 48},
      spy = {hex = "#ff0000", r = 255, g = 0, b = 0}
    }
    tcs.OnIncomingMessage = function(msg)
      local props = Instance.new("TextChatMessageProperties")
      if not msg.TextSource then
        props.Text = msg.Text
        props.PrefixText = msg.PrefixText
        return props
      end
      task.spawn(function()
        for _, listener in ipairs(ChatListeners) do listener(msg) end
      end)
      if msg.Status ~= Enum.TextChatMessageStatus.Sending and pending_chat_check[msg.Text] == "" then
        pending_chat_check[msg.Text] = msg.Status == Enum.TextChatMessageStatus.Success
      end
      local player = Helpers.services.players:GetPlayerByUserId(msg.TextSource.UserId)
      if not player then return props end
      local cn = ""
      if player.Neutral == true then
        cn = player:GetAttribute("Arken") == true and "arken" or "peasant"
      else
        cn = "admin"
      end
      if string.sub(msg.Text, 1, 1) == ";" then cn = "spy" end
      local color = colors[cn]
      if isog then
        props.PrefixText = "<font color=\""..color.hex.."\"><b>["..player.DisplayName..((cn == "spy" and " (SPY CHAT)") or "").."]: </b></font>"
      else
        props.PrefixText = "<font color=\""..color.hex.."\"><i>("..player.DisplayName..((cn == "spy" and " (SPY CHAT)") or "")..") </i></font>"
      end
      return props
    end
    Helpers.cmd = function(c, checkForSent)
      local tool = localplr.Backpack:FindFirstChild("The Arkenstone")
      if tool then
        tool.Parent = localplr.Character
      elseif not localplr.Character:FindFirstChild("The Arkenstone") then
        local cn = Helpers.services.players.Leaderboard:FindFirstChild("Chosen")
        if (not cn or not cn:FindFirstChild(localplr.Name)) then return end
        log("Skipped command ", c, " due to having no enli or admin")
      end
      local cmd = ";" .. c .. " HYPERION_REBORN"
      tcs.TextChannels.RBXGeneral:SendAsync(cmd)
      if checkForSent then
        pending_chat_check[cmd] = ""
        while pending_chat_check[cmd] == "" do task.wait(0.1) end
        local ref = pending_chat_check[cmd]
        pending_chat_check[cmd] = nil
        return ref
      end
    end
    Helpers.resolveName = function(name)
      return name:gsub("_", ".")
    end
    Helpers.say = function(text, checkForSent)
      tcs.TextChannels.RBXGeneral:SendAsync(text)
      if checkForSent then
        pending_chat_check[text] = ""
        while pending_chat_check[text] == "" do task.wait(0.1) end
        local ref = pending_chat_check[text]
        pending_chat_check[text] = nil
        return ref
      end
    end
    Helpers.on = function(type, func)
      if type == "ChatListener" then
        table.insert(ChatListeners, func)
      else
        error(type .. " is not supported")
      end
    end
    Helpers.services = {
      players = cloneref(game:GetService("Players")),
      workspace = cloneref(game:GetService("Workspace")),
      run = cloneref(game:GetService("RunService")),
      userinput = cloneref(game:GetService("UserInputService")),
      textchat = tcs,
      coregui = cloneref(game:GetService("CoreGui")),
      http = http,
      tween = cloneref(game:GetService("TweenService")),
      replicated = cloneref(game:GetService("ReplicatedStorage")),
      collection = cloneref(game:GetService("CollectionService")),
      sound = cloneref(game:GetService("SoundService")),
      lighting = cloneref(game:GetService("Lighting")),
      debris = cloneref(game:GetService("Debris")),
      teams = cloneref(game:GetService("Teams")),
    }
    print("[STEP 8]: helpers built")
  end

  repeat task.wait() until Obsidian ~= nil
  print("[STEP 9]: Obsidian ready, creating window...")

  local Window = Obsidian:CreateWindow({
    Title = "Hyperion (Reborn)",
    Footer = "by horizonscript in discord",
    Icon = "zap",
    ToggleKeybind = Enum.KeyCode.RightShift,
    Center = true,
    AutoShow = true,
  })
  print("[STEP 10]: window created")

  local tabs = {}
  tabs.info = Window:AddTab("Main", "home")
  tabs.settings = Window:AddTab("Settings", "settings")
  print("[STEP 11]: tabs created")

  local InfoBoxLeft = tabs.info:AddLeftGroupbox("")
  local InfoBoxRight = tabs.info:AddRightGroupbox("")
  InfoBoxLeft:AddLabel({ Text = "Join our Discord for suggestions, updates, and help.", DoesWrap = true })
  InfoBoxRight:AddButton({
    Text = "Copy Invite",
    Func = function()
      if setclipboard then
        setclipboard(Invite)
        Obsidian:Notify({ Title = "Copied!", Description = "Discord link copied to clipboard.", Time = 3 })
      else
        Obsidian:Notify({ Title = "Invite is", Description = Invite, Time = 7 })
      end
    end,
  })
  InfoBoxRight:AddDivider()
  InfoBoxLeft:AddDivider()
  InfoBoxLeft:AddLabel({ Text = "About Hyperion: a modular system. Instead of using a separate script, extend it with plugins. Visit #plugins on our Discord to find and share plugins.", DoesWrap = true })
  InfoBoxLeft:AddDivider()
  InfoBoxLeft:AddLabel({ Text = "Adding a Plugin: place your plugin file in Hyperion/modules/ (located inside your executor's folder).", DoesWrap = true })
  InfoBoxRight:AddLabel({ Text = "Creating your own plugin: full documentation is available on #plugins-dev on our Discord server.", DoesWrap = true })
  InfoBoxRight:AddLabel({ Text = "Credits: areyoumental, pealz, wilson, agarv, raja", DoesWrap = true })
  print("[STEP 12]: info tab populated")

  repeat task.wait() until ThemeManager ~= nil
  print("[STEP 13]: ThemeManager ready, applying theme...")
  
  ThemeManager:SetLibrary(Obsidian)
  ThemeManager:SetDefaultTheme({
    FontColor = Color3.fromHex("#f0f0f0"),
    MainColor = Color3.fromHex("#1a1d26"),
    AccentColor = Color3.fromHex("#e63535"),
    BackgroundColor = Color3.fromHex("#0f1117"),
    OutlineColor = Color3.fromHex("#e63535"),
  })
  ThemeManager:ApplyToTab(tabs.settings)
  ThemeManager:LoadDefault()
  print("[STEP 14]: theme applied")

  local CACHE_PATH = assets("modules", ".sha_cache.json")
  local shaCache = {}
  local ok, data = pcall(function() return http:JSONDecode(readfile(CACHE_PATH)) end)
  if ok and type(data) == "table" then shaCache = data end
  print("[STEP 15]: sha cache loaded, keys =", ok and #(data or {}) or 0)

  local remoteNames = {}
  local listingsRemaining = 3
  local pending = 0

  for _, subdir in ipairs({ "og", "normal", "both" }) do
    task.spawn(function()
      print("[STEP 16]: fetching modules/" .. subdir)
      local fetched, result = pcall(function()
        return http:JSONDecode(game:HttpGet("https://api.github.com/repos/Horizon-Developments/hyperion/contents/modules/" .. subdir))
      end)
      if not fetched then
        print("[STEP 16]: failed to fetch modules/" .. subdir .. ": " .. tostring(result))
        listingsRemaining -= 1
        return
      end
      print("[STEP 16]: modules/" .. subdir .. " returned " .. #result .. " items")
      for _, item in ipairs(result) do
        if item.type ~= "file" then continue end
        local cacheKey = subdir .. "/" .. item.name
        remoteNames[cacheKey] = true
        if shaCache[cacheKey] == item.sha then
          print("[STEP 16]: skipped (cached) " .. cacheKey)
          continue
        end
        pending += 1
        task.spawn(function()
          print("[STEP 17]: downloading " .. cacheKey)
          local dok, derr = pcall(function()
            writefile(assets("modules", subdir, item.name), game:HttpGet(item.download_url))
            shaCache[cacheKey] = item.sha
          end)
          if not dok then
            print("[STEP 17]: failed to download " .. cacheKey .. ": " .. tostring(derr))
          else
            print("[STEP 17]: downloaded " .. cacheKey)
          end
          pending -= 1
        end)
      end
      listingsRemaining -= 1
    end)
  end

  repeat task.wait() until listingsRemaining <= 0
  print("[STEP 18]: all listings fetched")
  repeat task.wait() until pending <= 0
  print("[STEP 19]: all downloads done")

  if next(remoteNames) ~= nil then
    for key in pairs(shaCache) do
      if remoteNames[key] then continue end
      local sub, filename = key:match("^([^/]+)/(.+)$")
      if sub and filename then
        pcall(function() delfile(assets("modules", sub, filename)) end)
      end
      shaCache[key] = nil
      print("[STEP 19]: deleted stale " .. key)
    end
  end
  pcall(function() writefile(CACHE_PATH, http:JSONEncode(shaCache)) end)
  print("[STEP 20]: cache saved")

  local env = { Tabs = tabs, Window = Window, Obsidian = Obsidian, Assets = assets, Helpers = Helpers }

  local moduleFiles = listfiles(assets("modules", isog and "og" or "normal"))
  print("[STEP 21]: loading " .. #moduleFiles .. " normal/og modules")
  for _, file in ipairs(moduleFiles) do
    task.spawn(function()
      print("[STEP 21]: loading module " .. file)
      local fn, ferr = loadstring(readfile(file))
      if not fn then
        print("[STEP 21]: loadstring failed for " .. file .. ": " .. tostring(ferr))
        return
      end
      local s, serr = pcall(fn, env)
      if not s then
        print("[STEP 21]: module error " .. file .. ": " .. tostring(serr))
      else
        print("[STEP 21]: module ok " .. file)
      end
    end)
  end

  local bothFiles = listfiles(assets("modules", "both"))
  print("[STEP 22]: loading " .. #bothFiles .. " both modules")
  for _, file in ipairs(bothFiles) do
    task.spawn(function()
      print("[STEP 22]: loading module " .. file)
      local fn, ferr = loadstring(readfile(file))
      if not fn then
        print("[STEP 22]: loadstring failed for " .. file .. ": " .. tostring(ferr))
        return
      end
      local s, serr = pcall(fn, env)
      if not s then
        print("[STEP 22]: module error " .. file .. ": " .. tostring(serr))
      else
        print("[STEP 22]: module ok " .. file)
      end
    end)
  end

  if isfile(assets(".joined")) then
    Obsidian:Notify({ Title = "Welcome back " .. localplr.DisplayName, Description = "I Appreciate you still using this script (:", Time = 2 })
  else
    writefile(assets(".joined"), "why u reading ts?")
    Obsidian:Notify({ Title = "Welcome " .. localplr.DisplayName, Description = "I Appreciate you using this script (:", Time = 2 })
  end
  print("[STEP 23]: done")
end)

if mainok then
  -- ts safe logging fr
  print("[HYPERION]: loaded")
  Api.Telemetry:LoggingSend("Script loaded!")
  local plrs = game:GetService("Players")
  local lp = plrs.LocalPlayer
  plrs.PlayerRemoving:Connect(function(p)
    if p == lp then
      Api.Telemetry:LoggingSend("Player left")
    end
  end)
else
  print("[HYPERION]: crashed: " .. tostring(mainres))
  Api.Telemetry:CrashReportSend("Loader crashed: " .. tostring(mainres))
  error("[HYPERION]: Failed to load. Error: " .. tostring(mainres))
end