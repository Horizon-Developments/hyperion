task.spawn(function()
  --if getgenv().Hyperion then return end
  getgenv().Hyperion = true

  local HttpService = cloneref(game:GetService("HttpService"))
  local tcs = cloneref(game:GetService("TextChatService"))

  local function assets(...)
    return table.concat({ "Hyperion", ... }, "/")
  end
  local function log(...)
    print("[HYPERION]: ", ...)
  end

  do
    makefolder("Hyperion")
    makefolder(assets("modules"))

    local function createfile(url)
      writefile(assets(url), game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/main/assets/" .. url))
    end

    createfile("hyperion_logo.jpg")
    createfile("discord_invite.txt")

    local CACHE_PATH = assets("modules", ".sha_cache.json")
    local shaCache = {}
    local cacheOk, cacheData = pcall(function()
      return HttpService:JSONDecode(readfile(CACHE_PATH))
    end)
    if cacheOk and type(cacheData) == "table" then
      shaCache = cacheData
    end

    local ok, result = pcall(function()
      return HttpService:JSONDecode(game:HttpGet("https://api.github.com/repos/Horizon-Developments/hyperion/contents/assets/modules"))
    end)

    if not ok then
      log("Failed to fetch built-in modules.", result)
    else
      local remoteNames = {}
      local pending = 0

      for _, item in ipairs(result) do
        if item.type == "file" then
          remoteNames[item.name] = true
          if shaCache[item.name] == item.sha then
            log("Skipped " .. item.name)
          else
            pending += 1
            task.spawn(function()
              pcall(function()
                writefile(assets("modules", item.name), game:HttpGet(item.download_url))
                shaCache[item.name] = item.sha
              end)
              pending -= 1
            end)
          end
        end
      end

      repeat task.wait(0.2) until pending <= 0

      for name in pairs(shaCache) do
        if not remoteNames[name] then
          pcall(function() delfile(assets("modules", name)) end)
          shaCache[name] = nil
          log("Deleted " .. name)
        end
      end

      pcall(function()
        writefile(CACHE_PATH, HttpService:JSONEncode(shaCache))
      end)
    end
  end

  local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

  WindUI:AddTheme({
    Name = "Hyperion",
    Accent = Color3.fromHex("#cc0000"),
    Background = Color3.fromHex("#0a0a0a"),
    Outline = Color3.fromHex("#cc0000"),
    Text = Color3.fromHex("#ffffff"),
    Placeholder = Color3.fromHex("#666666"),
    Button = Color3.fromHex("#1a1a1a"),
    Icon = Color3.fromHex("#cc0000"),
  })

  local savedTheme = isfile(assets("theme.txt")) and readfile(assets("theme.txt")) or "Hyperion"
  local discordInvite = readfile(assets("discord_invite.txt"))
  local Window = WindUI:CreateWindow({
    Title = "Hyperion (Reborn)",
    Icon = "zap",
    Author = "by horizonscript in discord",
    Folder = "Hyperion",
    Transparent = true,
    BackgroundImageTransparency = 0.42,
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = savedTheme
  })

  local tabs = {}

  tabs.info = Window:Tab({
    Title = "Main",
    Icon = "home",
  })

  tabs.info:Paragraph({
    Title = "Hyperion",
    Desc = "Join our Discord for suggestions, updates, and help.",
    Image = getcustomasset(assets("hyperion_logo.jpg")),
    Buttons = {
      {
        Icon = "copy",
        Title = "Copy Invite",
        Callback = function()
          setclipboard(discordInvite)
          WindUI:Notify({ Title = "Copied!", Content = "Discord link copied to clipboard.", Duration = 3 })
        end,
      }
    },
  })
  tabs.info:Paragraph({
    Title = "About Hyperion",
    Icon = "layers",
    Desc = "Hyperion is a modular system. Instead of using a separate script, you can extend it with plugins. Visit the #plugins channel on our Discord to find and share plugins.",
  })
  tabs.info:Paragraph({
    Title = "Adding a Plugin",
    Icon = "folder-plus",
    Desc = "Place your plugin file in Hyperion/modules/ (located inside your executor's folder.)",
  })
  tabs.info:Paragraph({
    Title = "Creating Your Own Plugin",
    Icon = "code-2",
    Desc = "Full documentation is available on #plugins-dev (our Discord server.)",
  })

  tabs.info:Dropdown({
    Title = "Theme",
    Icon = "palette",
    Values = { "Hyperion", "Dark", "Light", "Rose", "Plant", "Indigo", "Sky", "Violet", "Amber" },
    Value = savedTheme,
    Callback = function(value)
      writefile(assets("theme.txt"), value)
      WindUI:SetTheme(value)
    end
  })

  local Helpers = {}
  do
    Helpers.log = log
    Helpers.selfchat = function(msg, noAdded)
      if (noAdded) then
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
        for _, listener in ipairs(ChatListeners) do
          listener(msg)
        end
      end)
      if msg.Status ~= Enum.TextChatMessageStatus.Sending and pending_chat_check[msg.Text] == "" then
        pending_chat_check[msg.Text] = msg.Status == Enum.TextChatMessageStatus.Success
      end
      if (msg.Text:find(";")) then
        props.Text = "" -- hide.
        return props
      end
      local player = Helpers.services.players:GetPlayerByUserId(msg.TextSource.UserId)
      local char = player and player.Character
      local namePart = char and char:FindFirstChild("Nombre")
      local label = namePart and namePart:FindFirstChild("Text1")
      local color = label and label.TextColor3 or Color3.new(1, 1, 1)
      local hex = string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
      props.PrefixText = string.format("<font color='%s'>%s</font>", hex, player and player.DisplayName or msg.TextSource.Name)
      return props
    end

    Helpers.cmd = function(c, checkForSent)
      local Players = game:GetService("Players")
local player = Players:FindFirstChild("darkking56807")
local char = player and player.Character or workspace:FindFirstChild("darkking56807")
local label = char and char:FindFirstChild("Tiempo") and char.Tiempo:FindFirstChild("Text1")
if label and label.Text:find("🤐") then
    print("contains 🤐")
else
    print("does not contain 🤐")
end
      local cmd = ";" .. c .. " " .. discordInvite:gsub("https://discord.gg/", "")
      tcs.TextChannels.RBXGeneral:SendAsync(cmd)
      if checkForSent then
        pending_chat_check[cmd] = ""
        while pending_chat_check[cmd] == "" do task.wait(0.1) end
        local ref = pending_chat_check[cmd]
        pending_chat_check[cmd] = nil
        return ref
      end
    end

    Helpers.say = function(cmd, checkForSent)
      tcs.TextChannels.RBXGeneral:SendAsync(cmd)
      if checkForSent then
        pending_chat_check[cmd] = ""
        while pending_chat_check[cmd] == "" do task.wait(0.1) end
        local ref = pending_chat_check[cmd]
        pending_chat_check[cmd] = nil
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
      http = HttpService,
      tween = cloneref(game:GetService("TweenService")),
      replicated = cloneref(game:GetService("ReplicatedStorage")),
      collection = cloneref(game:GetService("CollectionService")),
      sound = cloneref(game:GetService("SoundService")),
      lighting = cloneref(game:GetService("Lighting")),
      debris = cloneref(game:GetService("Debris")),
      teams = cloneref(game:GetService("Teams")),
    }
  end
  
  for _, file in ipairs(listfiles(assets("modules"))) do
    if file:match("%.lua$") then
      local ok, err = pcall(loadstring(readfile(file)), { Tabs = tabs, Window = Window, WindUI = WindUI, Assets = assets, Helpers = Helpers })
      if not ok then
        warn("Failed to execute:", file, err)
      end
    end
  end
end)