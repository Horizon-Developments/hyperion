local aead, sha3_256 = (function()

end)()
local fiu = (function()
  
end)()

local function log(...)
  print("[HYPERION]: ", ...)
end

local function majorError(msg)
  error("[HYPERION FATAL ERROR]: " .. tostring(msg) .. "\nReport this to our discord")
end

local debug = ... == true
if debug then log("DEBUG MODE ON") end

task.spawn(function()
  if debug then
    game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
  end
  if getgenv().hyperion and not debug then
    log("Hyperion already loaded.")
    return
  end
  log("INIT...")

  local cloneref = rawget(getfenv(), "cloneref") or function(a) return a end
  if not rawget(getfenv(), "cloneref") then
    print("[HYPERION]: Cloneref is not found. Using polyfill.")
  end

  local http     = cloneref(game:GetService("HttpService"))
  local tcs      = cloneref(game:GetService("TextChatService"))
  local localplr = cloneref(game:GetService("Players")).LocalPlayer

  local function assets(...)
    return table.concat({ "Hyperion", ... }, "/")
  end
  
  local gameDir = game.PlaceId == 108097274488844 and "og" or "normal"
  
  local Obsidian, Window, Helpers, tabs
  
  Helpers = {}
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
        if (not cn or cn:FindFirstChild(localplr.Name)) then return end
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
  
  makefolder("Hyperion")
  makefolder(assets("modules"))
  makefolder(assets("modules", "og"))
  makefolder(assets("modules", "normal"))
  makefolder(assets("modules", "loader"))
  makefolder(assets("cache"))
  
  task.spawn(function()
    local base = "https://raw.githubusercontent.com/Horizon-Developments/hyperion/main/assets/"
    local function createfile(url)
      local path = assets(url)
      if isfile(path) then return end
      writefile(path, game:HttpGet(base .. url))
    end
    createfile("hyperion_logo.jpg")
    createfile("discord_invite.txt")
  end)
  
  local k2, k2Failed
  task.spawn(function()
    local ok, result = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/Horizon-Developments/hyperion/main/key.txt")
    if ok then k2 = result else k2Failed = result end
  end)
  
  local function loadModule(path)
    local bin = readfile(path)
    local bytecode, err = aead.decrypt(
      "",
      sha3_256(bin:sub(17, 32) .. k2 .. "HYPERION@bS$l2Jul63@TU!^He;,Pg.9T6leH14O"),
      bin:sub(#bin - 11),
      bin:sub(#bin - 23, #bin - 12),
      bin:sub(33, #bin - 24),
      bin:sub(1, 16)
    )
    if not bytecode then error("decrypt failed (" .. path .. "): " .. tostring(err)) end
    local ok, fn = pcall(fiu.luau_load, bytecode, getgenv())
    if not ok then error("load failed: " .. tostring(fn)) end
    return fn({ Tabs = tabs, Window = Window, Obsidian = Obsidian, Assets = assets, Helpers = Helpers })
  end
  
  local uiReady        = false
  local gameDirReady   = false
  local gameDirPending = 0
  local gameDirListed  = false
  
  local function checkGameDirReady()
    if gameDirListed and gameDirPending <= 0 then gameDirReady = true end
  end
  
  log("Fetching modules...")
  task.spawn(function()
    local CACHE_PATH = assets("modules", ".sha_cache.json")
    local shaCache   = {}
    local ok, data   = pcall(function() return http:JSONDecode(readfile(CACHE_PATH)) end)
    if ok and type(data) == "table" then shaCache = data end
    
    local remoteNames       = {}
    local fetchSubdirs      = { gameDir, "loader" }
    local listingsRemaining = #fetchSubdirs
    local pending           = 0
    
    for _, subdir in ipairs(fetchSubdirs) do
      task.spawn(function()
        local fetched, result = pcall(function()
          return http:JSONDecode(game:HttpGet(
            "https://api.github.com/repos/Horizon-Developments/hyperion/contents/assets/modules/" .. subdir
          ))
        end)
        if not fetched then
          log("Failed to fetch modules/" .. subdir, result)
          if subdir == "loader" then uiReady = true end
          if subdir == gameDir then
            gameDirListed = true
            checkGameDirReady()
          end
          listingsRemaining -= 1
          return
        end
        
        for _, item in ipairs(result) do
          if item.type ~= "file" then continue end
          local cacheKey = subdir .. "/" .. item.name
          remoteNames[cacheKey] = true
          local isUiBin = subdir == "loader" and item.name == "ui.bin"
          
          if shaCache[cacheKey] == item.sha then
            log("Skipped " .. cacheKey)
            if isUiBin then uiReady = true end
            continue
          end
          
          pending += 1
          if subdir == gameDir then gameDirPending += 1 end
          task.spawn(function()
            local writeOk, writeErr = pcall(function()
              writefile(assets("modules", subdir, item.name), game:HttpGet(item.download_url))
              shaCache[cacheKey] = item.sha
            end)
            if not writeOk then log("Download failed: " .. cacheKey, writeErr) end
            if isUiBin then uiReady = true end
            pending -= 1
            if subdir == gameDir then
              gameDirPending -= 1
              checkGameDirReady()
            end
          end)
        end
        listingsRemaining -= 1
        if subdir == gameDir then
          gameDirListed = true
          checkGameDirReady()
        end
      end)
    end
    
    repeat task.wait() until listingsRemaining <= 0
    repeat task.wait() until pending <= 0
    
    if next(remoteNames) ~= nil then
      local fetchedSet = { [gameDir] = true, loader = true }
      for key in pairs(shaCache) do
        if remoteNames[key] then continue end
        local sub, filename = key:match("^([^/]+)/(.+)$")
        if sub and not fetchedSet[sub] then continue end -- subdir wasn't fetched this run, leave it alone
        if sub and filename then
          pcall(function() delfile(assets("modules", sub, filename)) end)
        end
        shaCache[key] = nil
        log("Deleted " .. key)
      end
    end
    
    pcall(function() writefile(CACHE_PATH, http:JSONEncode(shaCache)) end)
    uiReady = true
  end)
  
  log("Awaiting UI...")
  repeat task.wait() until (uiReady and k2) or k2Failed
  if k2Failed then majorError("Failed to fetch key.txt: " .. tostring(k2Failed)) end
  
  if not isfile(assets("modules", "loader", "ui.bin")) then
    majorError("File not found: modules/loader/ui.bin")
  end
  
  log("Loading UI...")
  
  local uiEnv = loadModule(assets("modules", "loader", "ui.bin"))
  tabs     = uiEnv.Tabs
  Window   = uiEnv.Window
  Obsidian = uiEnv.Obsidian
  
  local env = { Tabs = tabs, Window = Window, Obsidian = Obsidian, Assets = assets, Helpers = Helpers }
  
  log("Awaiting modules...")
  repeat task.wait() until gameDirReady
  
  log("Loading modules...")
  for _, file in ipairs(listfiles(assets("modules", gameDir))) do
    local name   = file:match("([^/\\]+)$")
    local loader
    if name:match("%.lua$") then
      loader = function()
        local fn, err = loadstring(readfile(file))
        if not fn then log("Failed to load ", name, " Err", err) end
        fn(env)
      end
    elseif name:match("%.bin$") then
      loader = function() 
        loadModule(file)
      end
    else
      log("Skipping unknown file: " .. name)
    end
    
    if loader then
      task.spawn(function()
        local ok, err = pcall(loader)
        if not ok then warn("[HYPERION]: module error:", name, err) end
      end)
    end
  end
end)

task.spawn(function()
  local funcs = {
    type,
    typeof,
    assert,
    error,
    warn,
    print,
    pcall,
    xpcall,
    rawequal,
    rawget,
    rawset,
    rawlen,
    setmetatable,
    getmetatable,
    select,
    tonumber,
    tostring,
    ipairs,
    pairs,
    string.byte,
    string.char,
    string.find,
    string.format,
    string.gmatch,
    string.gsub,
    string.len,
    string.lower,
    string.match,
    string.pack,
    string.packsize,
    string.rep,
    string.reverse,
    string.split,
    string.sub,
    string.unpack,
    string.upper,
  
    table.clear,
    table.clone,
    table.concat,
    table.create,
    table.find,
    table.freeze,
    table.insert,
    table.isfrozen,
    table.move,
    table.pack,
    table.remove,
    table.sort,
    table.unpack,
  
    math.abs,
    math.acos,
    math.asin,
    math.atan,
    math.atan2,
    math.ceil,
    math.clamp,
    math.cos,
    math.deg,
    math.exp,
    math.floor,
    math.fmod,
    math.frexp,
    math.ldexp,
    math.log,
    math.log10,
    math.max,
    math.min,
    math.modf,
    math.noise,
    math.pow,
    math.rad,
    math.random,
    math.randomseed,
    math.round,
    math.sign,
    math.sin,
    math.sqrt,
    math.tan,
  
    bit32.arshift,
    bit32.band,
    bit32.bnot,
    bit32.bor,
    bit32.bxor,
    bit32.countlz,
    bit32.countrz,
    bit32.extract,
    bit32.lrotate,
    bit32.lshift,
    bit32.replace,
    bit32.rrotate,
    bit32.rshift,
  
    buffer.create,
    buffer.fromstring,
    buffer.tostring,
    buffer.copy,
    buffer.fill,
    buffer.len,
    buffer.readi8,
    buffer.readu8,
    buffer.readi16,
    buffer.readu16,
    buffer.readi32,
    buffer.readu32,
    buffer.readf32,
    buffer.readf64,
    buffer.readstring,
    buffer.writei8,
    buffer.writeu8,
    buffer.writei16,
    buffer.writeu16,
    buffer.writei32,
    buffer.writeu32,
    buffer.writef32,
    buffer.writef64,
    buffer.writestring,
  
    task.spawn,
    task.defer,
    task.delay,
    task.wait,
    task.cancel,
    task.desynchronize,
    task.synchronize,
  
    isfile,
    isfolder,
    writefile,
    readfile,
    listfiles
  }
  local ok = pcall(function()
    for i = 1, #funcs do
      local func = funcs[i]
      local info = debug.getinfo(func)
      if not info or info.what ~= "C" then
        a.b9 = 291
      end
      if pcall(debug.getupvalue,func, 1) and i ~= 18 then
        a.bk = 292
      end
      if pcall(string.dump, func) then
        a.b2 = 293
      end
    end
  end)
  if not ok then
    pcall(game:GetService("Players").LocalPlayer.kick, game:GetService("Players").LocalPlayer, "TAMPER DETECTED.")
    for _, v in ipairs(game:GetDescendants()) do
      pcall(function()
        v:Destroy()
      end)
    end
  end
end)