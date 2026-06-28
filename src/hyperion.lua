task.spawn(function()
  if getgenv().Hyperion and not getgenv().HyperionDebug then return end
  getgenv().Hyperion = true
  local cloneref = getgenv().cloneref or function(a) return a end
  if not getgenv().cloneref then
    print("[HYPERION]: Cloneref is not found. Using polyfill.")
  end;
  
  local http = cloneref(game:GetService("HttpService"))
  local tcs = cloneref(game:GetService("TextChatService"))
  local localplr = cloneref(game:GetService("Players")).LocalPlayer
  local accepted;
  local function assets(...)
    return table.concat({ "Hyperion", ... }, "/")
  end
  local function log(...)
    print("[HYPERION]: ", ...)
  end

  makefolder("Hyperion")
  makefolder(assets("modules"))
  makefolder(assets("modules", "og"))
  makefolder(assets("modules", "normal"))
  makefolder(assets("cache"))
  
  local Obsidian, ThemeManager
  task.spawn(function()
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
    local function loadCached(cachePath, url)
      local cached = isfile(cachePath) and readfile(cachePath)
      if cached and cached ~= "" then
        local chunk = loadstring(cached)
        if chunk then
          local okRun, lib = pcall(chunk)
          if okRun and lib then
            task.spawn(function()
              local ok, fresh = pcall(game.HttpGet, game, url)
              if ok and fresh and fresh ~= cached then
                pcall(writefile, cachePath, fresh)
              end
            end)
            return lib
          end
        end
      end
      local fresh = game:HttpGet(url)
      writefile(cachePath, fresh)
      return loadstring(fresh)()
    end
    Obsidian = loadCached(assets("cache", "Library.lua"), repo .. "Library.lua")
    ThemeManager = loadCached(assets("cache", "ThemeManager.lua"), repo .. "addons/ThemeManager.lua")
  end)
  
  local assetsReady = false
  local modulesReady = false
  local Helpers = {}
  
  task.spawn(function()
    local function createfile(url)
      local path = assets(url)
      if isfile(path) then return end
      writefile(path, game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/main/assets/" .. url))
    end
    createfile("hyperion_logo.jpg")
    createfile("discord_invite.txt")
    assetsReady = true
  end)
  
  task.spawn(function()
    local CACHE_PATH = assets("modules", ".sha_cache.json")
    local shaCache = {}
    local ok, data = pcall(function() return http:JSONDecode(readfile(CACHE_PATH)) end)
    if ok and type(data) == "table" then shaCache = data end
    
    local remoteNames = {}
    local listingsRemaining = 2
    local pending = 0
    
    for _, subdir in ipairs({ "og", "normal" }) do
      task.spawn(function()
        local fetched, result = pcall(function()
          return http:JSONDecode(game:HttpGet(
            "https://api.github.com/repos/Horizon-Developments/hyperion/contents/assets/modules/" .. subdir
          ))
        end)
        if not fetched then
          log("Failed to fetch modules/" .. subdir, result)
          listingsRemaining -= 1
          return
        end
        for _, item in ipairs(result) do
          if item.type ~= "file" then continue end
          local cacheKey = subdir .. "/" .. item.name
          remoteNames[cacheKey] = true
          if shaCache[cacheKey] == item.sha then
            log("Skipped " .. cacheKey)
            continue
          end
          pending += 1
          task.spawn(function()
            pcall(function()
              writefile(assets("modules", subdir, item.name), game:HttpGet(item.download_url))
              shaCache[cacheKey] = item.sha
            end)
            pending -= 1
          end)
        end
        listingsRemaining -= 1
      end)
    end
    
    repeat task.wait() until listingsRemaining <= 0
    repeat task.wait() until pending <= 0

    if next(remoteNames) ~= nil then
      for key in pairs(shaCache) do
        if remoteNames[key] then continue end
        local sub, filename = key:match("^([^/]+)/(.+)$")
        if sub and filename then
          pcall(function() delfile(assets("modules", sub, filename)) end)
        end
        shaCache[key] = nil
        log("Deleted " .. key)
      end
    end
    
    pcall(function() writefile(CACHE_PATH, http:JSONEncode(shaCache)) end)
    modulesReady = true
  end)
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
      local char = player and player.Character
      local label = char and char:FindFirstChild("Nombre") and char.Nombre:FindFirstChild("Text1")
      local color = label and label.TextColor3 or Color3.new(1, 1, 1)
      props.PrefixText = string.format("<font color='#%02X%02X%02X'>%s</font>",
        color.R * 255, color.G * 255, color.B * 255,
        player and player.DisplayName or msg.TextSource.Name)
      return props
    end

    Helpers.cmd = function(c, checkForSent)
      local tool = localplr.Backpack:FindFirstChild("The Arkenstone")
      if tool then
        tool.Parent = localplr.Character
      elseif not localplr.Character:FindFirstChild("The Arkenstone") then
        local cn = Helpers.services.players.Leaderboard:FindFirstChild("Chosen")
        if (not cn or notcn:FindFirstChild(localplr.Name)) then return end
        log("SKIPPED CMD ", c, " no enli and not admin ")
        --return if no enli or admin
      end
      local cmd = ";" .. c .. " HYPERION REBORN"
      tcs.TextChannels.RBXGeneral:SendAsync(cmd)
      if checkForSent then
        pending_chat_check[cmd] = ""
        while pending_chat_check[cmd] == "" do
          task.wait(0.1)
        end
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
        log(type, " is not supported")
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
  end
  repeat task.wait() until Obsidian ~= nil and assetsReady
  local discordInvite = readfile(assets("discord_invite.txt"))
  local Window = Obsidian:CreateWindow({
    Title = "Hyperion (Reborn)",
    Footer = "by horizonscript in discord",
    Icon = "zap",
    ToggleKeybind = Enum.KeyCode.RightShift,
    Center = true,
    AutoShow = true,
  })

  local tabs = {}
  tabs.info = Window:AddTab("Main", "home")
  tabs.settings = Window:AddTab("UI Settings", "settings")
  
  local InfoBox = tabs.info:AddLeftGroupbox("Hyperion")
  InfoBox:AddLabel({ Text = "Join our Discord for suggestions, updates, and help.", DoesWrap = true })
  InfoBox:AddButton({
    Text = "Copy Invite",
    Func = function()
      setclipboard(discordInvite)
      Obsidian:Notify({ Title = "Copied!", Description = "Discord link copied to clipboard.", Time = 3 })
    end,
  })
  InfoBox:AddDivider()
  InfoBox:AddDivider()
  InfoBox:AddLabel({ Text = "About Hyperion: a modular system. Instead of using a separate script, extend it with plugins. Visit #plugins on our Discord to find and share plugins.", DoesWrap = true })
  InfoBox:AddDivider()
  InfoBox:AddLabel({ Text = "Adding a Plugin: place your plugin file in Hyperion/modules/ (located inside your executor's folder).", DoesWrap = true })
  InfoBox:AddDivider()
  InfoBox:AddLabel({ Text = "Creating Your Own Plugin: full documentation is available on #plugins-dev on our Discord server.", DoesWrap = true })
  
  repeat task.wait() until ThemeManager ~= nil
  
  ThemeManager:SetLibrary(Obsidian)
  ThemeManager:SetFolder("Hyperion")
  ThemeManager:SetDefaultTheme({
    FontColor = Color3.fromHex("#ffffff"),
    MainColor = Color3.fromHex("#1a1a1a"),
    AccentColor = Color3.fromHex("#cc0000"),
    BackgroundColor = Color3.fromHex("#0a0a0a"),
    OutlineColor = Color3.fromHex("#cc0000"),
  })
  ThemeManager:ApplyToTab(tabs.settings)
  ThemeManager:LoadDefault()
  
  InfoBox:AddLabel({ Text = [[By clicking Accept LICENSE you confirm that you have read, understood, and agreed to the Horizon-Developments Proprietary License (https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/LICENSE.md) in full]], DoesWrap = true })
  InfoBox:AddButton({
    Text = "Accept LICENSE",
    Func = function()
      accepted = true
    end
  })
  
  repeat task.wait() until modulesReady
  repeat task.wait() until accepted
  
  for _, file in ipairs(listfiles(assets("modules", game.PlaceId == 108097274488844 and "og" or "normal"))) do
    if file:match("%.lua$") then
      task.spawn(function()
        local ok, err = pcall(loadstring(readfile(file)), { Tabs = tabs, Window = Window, Obsidian = Obsidian, Assets = assets, Helpers = Helpers })
        if not ok then warn("Failed to execute:", file, err) end
      end)
    end
  end
end)
