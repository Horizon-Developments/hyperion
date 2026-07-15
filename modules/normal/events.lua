local args = ...
local Tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local Helpers = args.Helpers
local Assets = args.Assets

local Options = Obsidian.Options
local Toggles = Obsidian.Toggles
Tabs.events = Window:AddTab("Events", "calendar")
local box = Tabs.events:AddLeftGroupbox("Events")

local plrs = Helpers.services.players
local localplr = plrs.LocalPlayer
local MarketplaceService = game:GetService("MarketplaceService")

do
  local saveFile = Assets(".events.save.json")
  local HttpService = game:GetService("HttpService")

  local script = ""
  local whitelist = {}
  local blacklist = {}
  local playerCache = {}

  local function saveData()
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, {
      whitelist = whitelist,
      blacklist = blacklist,
    })
    if not ok then return end
    pcall(writefile, saveFile, encoded)
  end

  local function loadData()
    local ok, raw = pcall(readfile, saveFile)
    if not ok or not raw or raw == "" then return end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok2 or not data then return end
    whitelist = data.whitelist or {}
    blacklist = data.blacklist or {}
  end

  local function refreshWhitelist()
    local names = {}
    for name in pairs(whitelist) do table.insert(names, name) end
    Options["events@script.whitelist.dropdown"]:SetValues(names)
  end

  local function refreshBlacklist()
    local names = {}
    for name in pairs(blacklist) do table.insert(names, name) end
    Options["events@script.blacklist.dropdown"]:SetValues(names)
  end

  loadData()

  box:AddInput("events@script.input", {
    Text = "Script",
    Placeholder = "",
    ClearTextOnFocus = false,
    Finished = true,
    Callback = function(v)
      script = v
      Options["events@script.label"]:SetText(v)
    end
  })

  box:AddLabel("events@script.label", {
    Text = "",
    DoesWrap = true,
  })

  box:AddLabel({ Text = [[
booleans
isFriend() = is a friend of you?
whitelisted() = is in whitelist? (true if disabled)
blacklisted() = is in blacklist? (false if disabled)
hasPlus() = has roblox plus?
hasUgc() = has ugc item?
hasEI() = has expensive item?
isBacon() = has bacon accessory?

vars
Age(): number = account age
Time(): number = time
Name(): string = name of player
Display(): string = display name

system:
Cmd(cmd: string)
Say(msg: string)
Type(): join | leave
SelfChat(msg: string)

example:
while task.wait(0.5) do
  if Time() > 500 then
    Cmd("bkit "..Name())
    return
  end
end
]], DoesWrap = true })
  
  box:AddToggle("events@script.join.toggle", {
    Text = "Run when player joins",
    Default = false,
    Visible = true,
  })

  box:AddToggle("events@script.leave.toggle", {
    Text = "Run when player leaves",
    Default = false,
    Visible = true,
  })
  
  box:AddInput("events@script.whitelist.input", {
    Text = "Add to whitelist",
    Placeholder = "",
    ClearTextOnFocus = true,
    Finished = true,
    Callback = function(v)
      if v == "" then return end
      whitelist[v] = true
      saveData()
      refreshWhitelist()
    end
  })

  box:AddDropdown("events@script.whitelist.add.dropdown", {
    SpecialType = "Player",
    ExcludeLocalPlayer = true,
    Text = "Add to whitelist",
    Callback = function(value)
      if not value or value == "" then return end
      whitelist[value] = true
      saveData()
      refreshWhitelist()
      Options["events@script.whitelist.add.dropdown"]:SetValue(nil)
    end
  })

  box:AddDropdown("events@script.whitelist.dropdown", {
    Values = {},
    Default = 1,
    Multi = false,
    Text = "Whitelisted (select to remove)",
    Searchable = true,
    Callback = function(value)
      whitelist[value] = nil
      saveData()
      refreshWhitelist()
    end
  })

  -- Blacklist
  box:AddDropdown("events@script.blacklist.add.dropdown", {
    SpecialType = "Player",
    ExcludeLocalPlayer = true,
    Text = "Add to blacklist",
    Callback = function(value)
      if not value or value == "" then return end
      blacklist[value] = true
      saveData()
      refreshBlacklist()
      Options["events@script.blacklist.add.dropdown"]:SetValue(nil)
    end
  })

  box:AddDropdown("events@script.blacklist.dropdown", {
    Values = {},
    Default = 1,
    Multi = false,
    Text = "Blacklisted (select to remove)",
    Searchable = true,
    Callback = function(value)
      blacklist[value] = nil
      saveData()
      refreshBlacklist()
    end
  })

  refreshWhitelist()
  refreshBlacklist()

  local function runScript(player, _type)
    local cache = playerCache[player.UserId] or {}
    local env = {}
    
    function env.Type()        return _type end
    function env.isFriend()    return player:IsFriendsWith(localplr.UserId) end
    function env.whitelisted() return whitelist[player.Name] ~= nil end
    function env.blacklisted() return blacklist[player.Name] ~= nil end
    function env.hasPlus()     return player.MembershipType == Enum.MembershipType.Premium end
    function env.hasUgc()      return cache.hasUgc end
    function env.hasEI()       return cache.hasExpensiveItem end
    function env.isBacon()     return cache.isBacon end
    function env.Age()         return player.AccountAge end
    function env.Name()        return player.Name:lower():gsub("bt_c", "bt"):gsub("btc", "bt"):gsub("fat_[^_.]*", "fa"):gsub("fat", "fa"):gsub("btc_[^_.]*", "bt"):gsub("_", ".") end
    function env.Display()     return player.DisplayName end
    do
      local time = player:WaitForChild("leaderstats"):WaitForChild("Time")
      function env.Time()
        return tonumber(time.Value)
      end
    end
    env.Cmd = Helpers.cmd
    env.Say = Helpers.say
    env.SelfChat = Helpers.selfchat
    local fn, err = loadstring(script)
    if not fn then
      warn("[EVENTS] Failed to load script: ", err)
      return
    end

    setfenv(fn, setmetatable({}, {
      __index = function(_, key)
        local v = env[key]
        if v ~= nil then return v end
        return getgenv()[key]
      end,
      __newindex = getgenv()
    }))
    pcall(fn)
  end

  plrs.PlayerAdded:Connect(function(player)
    task.spawn(function()
      local ok, desc = pcall(function()
        return plrs:GetHumanoidDescriptionFromUserId(player.UserId)
      end)

      local isBacon = false
      local hasExpensiveItem = false
      local hasUgc = false

      if ok and desc then
        for id in desc.HairAccessory:gmatch("%d+") do
          local n = tonumber(id)
          if n == 63690008 or n == 62724852 then
            isBacon = true
            break
          end
        end

        for _, field in {"HairAccessory","FaceAccessory","NeckAccessory","ShouldersAccessory","FrontAccessory","BackAccessory","WaistAccessory","Shirt","Pants"} do
          for id in tostring(desc[field]):gmatch("%d+") do
            local s, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, tonumber(id))
            if s and info then
              if info.PriceInRobux and info.PriceInRobux >= 1000 then
                hasExpensiveItem = true
              end
              if info.Creator and info.Creator.CreatorType == "User" then
                hasUgc = true
              end
            end
          end
          if hasExpensiveItem and hasUgc then break end
        end
      end

      playerCache[player.UserId] = {
        isBacon          = isBacon,
        hasExpensiveItem = hasExpensiveItem,
        hasUgc           = hasUgc,
      }

      if Toggles["events@script.join.toggle"].Value then
        runScript(player, "join")
      end
    end)
  end)

  plrs.PlayerRemoving:Connect(function(player)
    if Toggles["events@script.leave.toggle"].Value then
      runScript(player, "leave")
    end
    playerCache[player.UserId] = nil
  end)
end