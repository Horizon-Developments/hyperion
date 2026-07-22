--WHITELIST
local args = ...
local tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local assets = args.Assets
local Helpers = args.Helpers

 
 
 
 
 
 
local report = function() end

--[[ BACKEND ]]

local Env = {}
local SharedData = {}
local fns = {}
local function bhelper(fn, name)
  Env[name] = {}
  SharedData[name] = {}
  fns[namse] = function(...)
    task.spawn(fn,Env[name],SharedData[name],...)
  end
end

--[[
settings: {
  
  
}
]]
bhelper(function(env,shared,enabled)
  env.enabled = enabled
  if env.thread then return end
  env.thread = task.spawn(function()
    local plrs = Helpers.services.players
    local settings = shared.settings
    Helpers.services.run.Heartbeat:Connect(function()
      if not env.enabled then return end
      for _, player in ipairs(plrs:GetPlayers()) do
        local character = player.Character
        if not character then continue end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        
        if root.AssemblyLinearVelocity.Magnitude > settings.linear or root.AssemblyAngularVelocity.Magnitude > settings.angular then
          report({
            name = "fling detect",
            detected = player,
            reason = "Unusual angular or linear velocity",
          })
        end
      end
    end)
  end)
end, "fling_detect")

bhelper(function(env,shared,enabled)
  
end, "")
bhelper(function(env,shared,enabled)
  
end, "fling_detect")





--[[ FRONTEND ]]











--[=[
tabs.adminkit = Window:AddTab("AdminKit", "wrench")
local leftbox = tabs.adminkit:AddLeftGroupbox("Bkit")
local rightbox = tabs.adminkit:AddRightGroupbox("Enlightened")
local Options = Obsidian.Options
local Toggles = Obsidian.Toggles
local tcs = Helpers.services.textchat
local players = Helpers.services.players
local localplr = players.LocalPlayer
local sound
local fake = function() end
local toggles = {
  antijoin = {},
  bkitw = { whitelisted = {} },
  enliw = { whitelisted = {} },
  agd = {
    enabled = {
      delete = false, build = false, resize = false, paint = false,
      crasher = false, fling = false, spammer = false, signs = false, sound = false,
    },
    delete = fake,
    build  = fake,
    resize = fake,
    fling  = fake,
    signs  = fake,
    paint  = fake,
  }
}

leftbox:AddDropdown("antiJoin", {
  Text = "Anti join*",
  Tooltip = "Prevents join og, vc, xl (:",
  Values = { "joinxl", "joinog", "joinvc" },
  Default = {},
  Multi = true,
  Callback = function(selected)
    toggles.antijoin = selected
  end
})

leftbox:AddDivider()
leftbox:AddLabel({ Text = "Bkit Whitelist: if a non-whitelisted player has bkit, it clearinv's them", DoesWrap = true })
leftbox:AddToggle("adminkit@whitelistEnli.toggle", {
  Text = "Enable",
  Default = false,
  Callback = function(val) toggles.bkitw.enabled = val end
})
toggles.bkitw.add = leftbox:AddDropdown("bkitwWhitelist", {
  Text = "Whitelisted",
  Values = (function()
    local t = {}
    for _, p in ipairs(players:GetPlayers()) do table.insert(t, p.Name) end
    return t
  end)(),
  Default = {},
  Multi = true,
  Callback = function(option)
    local t = {}
    for name in pairs(option) do t[name] = true end
    toggles.bkitw.whitelisted = t
  end
})
leftbox:AddDivider()
leftbox:AddLabel("adminkit@bkit.label", { Text = "", DoesWrap = true })
leftbox:AddButton({
  Text = "Show Bkit",
  Func = function()
    local lines = {}
    for _, plr in pairs(players:GetPlayers()) do
      local char = plr.Character
      if not char then continue end
      local tool = char:FindFirstChildOfClass("Tool")
      if tool and tool.Name ~= "The Arkenstone" and ({
        Build=true, Delete=true, Paint=true, Shape=true, Shovel=true, Sign=true
      })[tool.Name] then
        table.insert(lines, "[" .. plr.DisplayName .. "]")
      end
    end
    Options["adminkit@bkit.label"]:SetText(#lines > 0 and table.concat(lines, "\n") or "None")
  end
})

rightbox:AddLabel({ Text = "Arkenstone Whitelist: if a non-whitelisted player has The Arkenstone, it clearinv's them", DoesWrap = true })
rightbox:AddToggle("adminkit@enli.label", {
  Text = "Enable",
  Default = false,
  Callback = function(val) toggles.enliw.enabled = val end
})
toggles.enliw.add = rightbox:AddDropdown("enliwWhitelist", {
  Text = "Whitelisted",
  Values = (function()
    local t = {}
    for _, p in ipairs(players:GetPlayers()) do table.insert(t, p.Name) end
    return t
  end)(),
  Default = {},
  Multi = true,
  Callback = function(option)
    local t = {}
    for name in pairs(option) do t[name] = true end
    toggles.enliw.whitelisted = t
  end
})
rightbox:AddDivider()
rightbox:AddLabel("enliLabel", { Text = "", DoesWrap = true })
rightbox:AddButton({
  Text = "Show Enlightened",
  Func = function()
    local lines = {}
    for _, plr in pairs(players:GetPlayers()) do
      if plr:GetAttribute("Arken") then
        table.insert(lines, "[" .. plr.DisplayName .. "]")
      end
    end
    Options["adminkit@enli.label"]:SetText(#lines > 0 and table.concat(lines, "\n") or "None")
  end
})
rightbox:AddDivider()
leftbox:AddDivider()

rightbox:AddLabel({ Text = [[
Advanced Grief Detection (AGD)
credit to agar for allowing me to take agarware code.

Detects: delete, build, paint, resize, signs, fling, crasher, disable sound, no animations exploits 

what they do:

these run when delete, build, paint, resize, signs, crasher is on (no way to turn off)
no animations :: player placed a block without animations runs clearinv
disable sound :: player does not have a sound when using tools runs clearinv

build/signs :: player spams or is placing blocks in air it runs delcubes & clearinv
delete :: player deletes someone elses build too often runs delcubes & clearinv
paint :: player paints someone elses build too often runs clearinv
resize :: player resizes on someone elses build too often runs clearinv
crasher :: player placed 5+ blocks on the same location runs delcubes and clearinv
fling :: player has unusual linear/angular velocity runs noclip

Helpers:

player commands (other players can run them)
!hy allow <plr>
Allows the player to bypass griefing protection to their own builds
!hy disallow <plr>
Disallows the player to bypass griefing protection to their own builds

bkit whitelisted
!hy bkit
enli whitelisted 
!hy enli
bypass whitelisted players are only logged if detected

webhook integration:
use a webhook for logs!
]], DoesWrap = true })

rightbox:AddToggle("adminkit@agd.delete", { Text = "Enable AGD Delete", Default = false })
rightbox:AddToggle("adminkit@agd.paint", { Text = "Enable AGD Paint", Default = false })
rightbox:AddToggle("adminkit@agd.build", { Text = "Enable AGD build", Default = false })
rightbox:AddToggle("adminkit@agd.crasher", { Text = "Enable AGD crasher", Default = false })
rightbox:AddToggle("adminkit@agd.fling", { Text = "Enable AGD fling", Default = false })
rightbox:AddToggle("adminkit@agd.ui", { Text = "Enable AGD GUI", Default = false })

leftbox:AddToggle("adminkit@agd.resize", { Text = "Enable AGD resize", Default = false })
leftbox:AddToggle("adminkit@agd.spammer", { Text = "Enable AGD spam", Default = false })
leftbox:AddToggle("adminkit@agd.signs", { Text = "Enable AGD Signs", Default = false })
leftbox:AddToggle("adminkit@agd.sound", { Text = "Enable AGD Disable Sound", Default = true })

local agdUI = {
  Iris = loadstring(game:HttpGet("https://raw.githubusercontent.com/x0581/Iris-Exploit-Bundle/main/bundle.lua"))().Init(),
  logs = {},
  currentMode = "Auto Moderation",
}
agdUI.WindowState = agdUI.Iris.State(true)
agdUI.ModeOptions = { "Auto Moderation", "Manual Moderation", "Logging Only" }

local function agdLog(builder)
  local msg, handler = builder(agdUI.currentMode)
  local entry = {
    msg = os.date("[%H:%M:%S]\n") .. msg,
    mode = agdUI.currentMode,
    response = nil,
  }
  table.insert(agdUI.logs, entry)
  local function await()
    if entry.mode == "Auto Moderation" then
      return true
    elseif entry.mode == "Logging Only" then
      return false
    end
    repeat
      task.wait(0.5)
    until entry.response ~= nil
    return entry.response
  end
  if handler then
    task.spawn(handler, await)
  end
end

agdUI.Iris:Connect(function()
  local Iris = agdUI.Iris
  Iris.Window({ "Advanced Grief Detection GUI" }, { isOpened = agdUI.WindowState })
  Iris.Text({ "Mode: " .. agdUI.currentMode })
  Iris.SameLine()
    for _, option in ipairs(agdUI.ModeOptions) do
      if Iris.SmallButton({ option }).clicked then
        agdUI.currentMode = option
      end
    end
  Iris.End()
  if Iris.Button({ "Clear logs?" }).clicked then
    table.clear(agdUI.logs)
  end
  for _, entry in ipairs(agdUI.logs) do
    Iris.SameLine()
      Iris.Text({ entry.msg })
      if entry.mode == "Manual Moderation" then
        if entry.response == nil then
          if Iris.Button({ "Allow" }).clicked then
            entry.response = true
          end
          if Iris.Button({ "Deny" }).clicked then
            entry.response = false
          end
        elseif entry.response == true then
          Iris.PushConfig({ TextColor = Color3.fromRGB(60, 200, 60) })
          Iris.Text({ "Confirmed" })
          Iris.PopConfig()
        else
          Iris.PushConfig({ TextColor = Color3.fromRGB(200, 60, 60) })
          Iris.Text({ "Denied" })
          Iris.PopConfig()
        end
      end
    Iris.End()
  end
  Iris.End()
end)

Toggles["adminkit@agd.ui"]:OnChanged(function(v) agdUI.WindowState:set(v) end)
Toggles["adminkit@agd.delete"]:OnChanged(function(v) toggles.agd.enabled.delete = v end)
Toggles["adminkit@agd.paint"]:OnChanged(function(v) toggles.agd.enabled.paint = v end)
Toggles["adminkit@agd.build"]:OnChanged(function(v) toggles.agd.enabled.build = v end)
Toggles["adminkit@agd.crasher"]:OnChanged(function(v) toggles.agd.enabled.crasher = v end)
Toggles["adminkit@agd.fling"]:OnChanged(function(v) toggles.agd.enabled.fling = v end)
Toggles["adminkit@agd.resize"]:OnChanged(function(v) toggles.agd.enabled.resize = v end)
Toggles["adminkit@agd.spammer"]:OnChanged(function(v) toggles.agd.enabled.spammer = v end)
Toggles["adminkit@agd.signs"]:OnChanged(function(v) toggles.agd.enabled.signs = v end)
Toggles["adminkit@agd.sound"]:OnChanged(function(v) toggles.agd.enabled.sound = v end)
Toggles["adminkit@agd.crasher"]:OnChanged(function(v) toggles.agd.enabled.crasher = v end)

toggles.agd.delete = function(plr, info) agdLog(makeSimpleHandler("Delete", plr, info)) end
toggles.agd.paint  = function(plr, info) agdLog(makeSimpleHandler("Paint", plr, info)) end
toggles.agd.build  = function(plr, info) agdLog(makeSimpleHandler("Build", plr, info)) end
toggles.agd.resize = function(plr, info) agdLog(makeSimpleHandler("Resize", plr, info)) end
toggles.agd.signs  = function(plr, info) agdLog(makeSimpleHandler("Signs", plr, info)) end
toggles.agd.fling   = function(plr, info) agdLog(makeSimpleHandler("Fling", plr, info)) end
toggles.agd.crasher   = function(plr, info) agdLog(makeSimpleHandler("Crasher", plr, info)) end



do
  local function h(character)
    local hrp = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    local brick = hrp:WaitForChild("Brick", 5)
    if not brick then
      test(player) -- player has Brick script deleted.
      return
    end
    brick.Destroying:Connect(function()
      if newParent == nil then
        if humanoid.Health > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
          local player = players:GetPlayerFromCharacter(character)
          if player then test(player) end
        end
      end
    end)
  end
  for i, GetPlayers in ipairs(game:GetPlayers()) do
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then
        onCharacterAdded(player.Character)
    end
  end
  players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(h)
    if player.Character then h(player.Character) end
  end)
end








local GriefDetector = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local CONFIG = {
	detectDelete  = true,
	detectPaint   = true,
	detectExploit = true,
	detectSpam    = true,
	
	cooldown = 30,
	
	ownerIds = {
		574381128,
		10587072700,
		8308247571,
		10837544781,
	},

	-- Set ["PlayerName"] = true to exclude someone from detection
	whitelistedNames = {},

	-- When false, players who own The Arkenstone item are excluded from detection
	enlightenEnabled = true,

	-- Minimum leaderstats Time value required to be flagged (0 disables the filter)
	timeFilter = 0,

	-- When false, only flags griefing on builds whose owner is currently in the server
	inGameEnabled = true,

	onDelete  = function(player, ownerName) print("[GRIEF] Delete  | " .. player.Name .. " -> " .. ownerName) end,
	onPaint   = function(player, ownerName) print("[GRIEF] Paint   | " .. player.Name .. " -> " .. ownerName) end,
	onExploit = function(player, ownerName, kind) print("[GRIEF] Exploit(" .. kind .. ") | " .. player.Name .. " -> " .. ownerName) end,
	onSpam    = function(player)             print("[GRIEF] Spam    | " .. player.Name) end,
}
--------------------------------------------------------------------------------
-- CONSTANTSr,
--------------------------------------------------------------------------------

local BRICK_SOUND_ID = "rbxassetid://9117183621"
local PAINT_SOUND_ID = "rbxassetid://18473826"
local DELETE_ANIM_ID = "17755760862"

local MAX_DISTANCE       = 30
local SOUND_MIN_NORMAL   = 0.04
local SOUND_MAX_NORMAL   = 0.15
local SOUND_MIN_EXPLOIT  = 0.01
local SOUND_MAX_EXPLOIT  = 0.15
local SLASH_WINDOW       = 0.5
local EXPLOIT_WAIT       = 0.5
local EXPLOIT_SOUND_WAIT = 1.0
local DELCUBE_THRESHOLD  = 4

local GRIEF_COUNT   = 12
local GRIEF_TIME    = 5
local EXPLOIT_COUNT = 40
local EXPLOIT_TIME  = 7
local SPAM_COUNT    = 60
local SPAM_TIME     = 13

--------------------------------------------------------------------------------
-- PER-PLAYER STATE
--------------------------------------------------------------------------------

local playerData = {}

local function getData(uid)
	if not playerData[uid] then
		playerData[uid] = {
			recentDeleteSound     = nil,
			recentPaintSound      = nil,
			recentSlashAnim       = nil,
			deleteTracker         = {},
			deleteCooldown        = nil,
			paintTracker          = {},
			paintCooldown         = nil,
			exploitDeleteTracker  = {},
			exploitDeleteCooldown = nil,
			exploitPaintTracker   = {},
			exploitPaintCooldown  = nil,
			spamTracker           = {},
			spamCooldown          = nil,
		}
	end
	return playerData[uid]
end

local delcubeTracker = {}
local isRunning      = false
local connections    = {}

--------------------------------------------------------------------------------
-- TOGGLE HELPERS
--------------------------------------------------------------------------------

local function isDeleteOn()  return CONFIG.detectDelete  end
local function isPaintOn()   return CONFIG.detectPaint   end
local function isExploitOn() return CONFIG.detectExploit end
local function isSpamOn()    return CONFIG.detectSpam    end

--------------------------------------------------------------------------------
-- PLAYER FILTERS
--------------------------------------------------------------------------------

local function isWhitelisted(player)
	return CONFIG.whitelistedNames[player.Name] == true
end

local function hasArkenstone(player)
	local backpack = player:FindFirstChild("Backpack")
	return backpack and backpack:FindFirstChild("The Arkenstone") ~= nil
end

local function passesEnlightenFilter(player)
	if CONFIG.enlightenEnabled then return true end
	return not hasArkenstone(player)
end

local function passesTimeFilter(player)
	if CONFIG.timeFilter == 0 then return true end
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return true end
	local timeValue = leaderstats:FindFirstChild("Time")
	if not timeValue then return true end
	return timeValue.Value < CONFIG.timeFilter
end

local function passesInGameFilter(ownerName)
	if CONFIG.inGameEnabled then return true end
	return Players:FindFirstChild(ownerName) ~= nil
end

local function passesAllFilters(player, ownerName)
	if isWhitelisted(player)              then return false end
	if not passesEnlightenFilter(player)  then return false end
	if not passesTimeFilter(player)       then return false end
	if not passesInGameFilter(ownerName)  then return false end
	return true
end

--------------------------------------------------------------------------------
-- COUNT TRACKING
-- Timestamps older than `window` are pruned so #list reflects only recent hits.
--------------------------------------------------------------------------------

local function addCount(list, window)
	local now = tick()
	table.insert(list, now)
	for i = #list, 1, -1 do
		if now - list[i] > window then table.remove(list, i) end
	end
	return #list
end

local function resetCount(list)
	table.clear(list)
end

local function isOnCooldown(cooldownExpiry)
	return cooldownExpiry and tick() < cooldownExpiry
end

local function startCooldown(seconds)
	return tick() + seconds
end

--------------------------------------------------------------------------------
-- PLAYER / POSITION UTILS
--------------------------------------------------------------------------------

local function getHRP(player)
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function getDistanceToPos(player, pos)
	local hrp = getHRP(player)
	if not hrp then return math.huge end
	return (hrp.Position - pos).Magnitude
end

local function getDisplayName(player)
	if player.DisplayName ~= player.Name then
		return player.Name .. " / " .. player.DisplayName
	end
	return player.Name
end

local function waitUntil(condFn, timeout)
	local start = tick()
	while tick() - start < timeout do
		if condFn() then return true end
		RunService.Heartbeat:Wait()
	end
	return condFn()
end

--------------------------------------------------------------------------------
-- SOUND / ANIM QUERIES
--------------------------------------------------------------------------------

local function soundDelayInWindow(soundTimestamp, eventTime, minDelay, maxDelay)
	if not soundTimestamp then return false end
	local delay = soundTimestamp - eventTime
	return delay >= minDelay and delay <= maxDelay
end

local function playedDeleteSoundNormally(player, eventTime)
	local t = getData(player.UserId).recentDeleteSound
	return soundDelayInWindow(t, eventTime, SOUND_MIN_NORMAL, SOUND_MAX_NORMAL)
end

local function playedPaintSoundNormally(player, eventTime)
	local t = getData(player.UserId).recentPaintSound
	return soundDelayInWindow(t, eventTime, SOUND_MIN_NORMAL, SOUND_MAX_NORMAL)
end

local function playedDeleteSoundInExploitWindow(player, eventTime)
	local t = getData(player.UserId).recentDeleteSound
	return soundDelayInWindow(t, eventTime, SOUND_MIN_EXPLOIT, SOUND_MAX_EXPLOIT)
end

local function playedPaintSoundInExploitWindow(player, eventTime)
	local t = getData(player.UserId).recentPaintSound
	return soundDelayInWindow(t, eventTime, SOUND_MIN_EXPLOIT, SOUND_MAX_EXPLOIT)
end

local function playedSlashAnimNear(player, eventTime)
	local t = getData(player.UserId).recentSlashAnim
	return t and math.abs(t - eventTime) <= SLASH_WINDOW
end

--------------------------------------------------------------------------------
-- DELCUBE CHECK
-- Delcube tools remove many bricks in rapid succession (<0.05s apart).
-- We track the burst per owner and suppress detection once it hits the threshold.
--------------------------------------------------------------------------------

local function isDelcubeBurst(ownerName, removedAt)
	local entry = delcubeTracker[ownerName]

	if not entry then
		delcubeTracker[ownerName] = {lastTick = removedAt, count = 1}
		return false
	end

	local isBurst = (removedAt - entry.lastTick) < 0.05

	if isBurst then
		entry.count    = entry.count + 1
		entry.lastTick = removedAt
		return entry.count >= DELCUBE_THRESHOLD
	else
		delcubeTracker[ownerName] = {lastTick = removedAt, count = 1}
		return false
	end
end

--------------------------------------------------------------------------------
-- FLAGGING
--------------------------------------------------------------------------------

local function flagDelete(player, ownerName)
	local d = getData(player.UserId)
	if isOnCooldown(d.deleteCooldown) then return end

	local count = addCount(d.deleteTracker, GRIEF_TIME)
	if count < GRIEF_COUNT then return end

	local cooldown = CONFIG.cooldown
	print("[GRIEFLOG] 🚨 " .. getDisplayName(player) .. " | Delete Detection | Cooldown: " .. cooldown)
	CONFIG.onDelete(player, ownerName)
	resetCount(d.deleteTracker)
	d.deleteCooldown = startCooldown(cooldown)
	task.delay(cooldown, function() print("[DELETE] " .. player.Name .. "'s cooldown ended") end)
end

local function flagPaint(player, ownerName)
	local d = getData(player.UserId)
	if isOnCooldown(d.paintCooldown) then return end

	local count = addCount(d.paintTracker, GRIEF_TIME)
	if count < GRIEF_COUNT then return end

	local cooldown = CONFIG.cooldown
	print("[GRIEFLOG] 🚨 " .. getDisplayName(player) .. " | Paint Detection | Cooldown: " .. cooldown)
	CONFIG.onPaint(player, ownerName)
	resetCount(d.paintTracker)
	d.paintCooldown = startCooldown(cooldown)
	task.delay(cooldown, function() print("[PAINT] " .. player.Name .. "'s cooldown ended") end)
end

local function flagExploitDelete(player, ownerName)
	local d = getData(player.UserId)
	if isOnCooldown(d.exploitDeleteCooldown) then return end

	local count = addCount(d.exploitDeleteTracker, EXPLOIT_TIME)
	if count < EXPLOIT_COUNT then return end

	local cooldown = CONFIG.cooldown
	print("[GRIEFLOG] 🚨 " .. getDisplayName(player) .. " | Exploit Delete | Cooldown: " .. cooldown)
	CONFIG.onExploit(player, ownerName, "delete")
	resetCount(d.exploitDeleteTracker)
	d.exploitDeleteCooldown = startCooldown(cooldown)
	task.delay(cooldown, function() print("[EXPLOIT DELETE] " .. player.Name .. "'s cooldown ended") end)
end

local function flagExploitPaint(player, ownerName)
	local d = getData(player.UserId)
	if isOnCooldown(d.exploitPaintCooldown) then return end

	local count = addCount(d.exploitPaintTracker, EXPLOIT_TIME)
	if count < EXPLOIT_COUNT then return end

	local cooldown = CONFIG.cooldown
	print("[GRIEFLOG] 🚨 " .. getDisplayName(player) .. " | Exploit Paint | Cooldown: " .. cooldown)
	CONFIG.onExploit(player, ownerName, "paint")
	resetCount(d.exploitPaintTracker)
	d.exploitPaintCooldown = startCooldown(cooldown)
	task.delay(cooldown, function() print("[EXPLOIT PAINT] " .. player.Name .. "'s cooldown ended") end)
end

local function flagSpam(player)
	local d = getData(player.UserId)
	if isOnCooldown(d.spamCooldown) then return end

	local count = addCount(d.spamTracker, SPAM_TIME)
	if count % 10 == 0 then
		print("[BUILD] " .. player.Name .. " spam | " .. count .. "/" .. SPAM_COUNT)
	end
	if count < SPAM_COUNT then return end

	local cooldown = CONFIG.cooldown
	print("[BUILDGRIEFLOG] 🚨 " .. player.Name .. " placing too fast | Cooldown: " .. cooldown)
	CONFIG.onSpam(player)
	resetCount(d.spamTracker)
	d.spamCooldown = startCooldown(cooldown)
	task.delay(cooldown, function() print("[BUILD] " .. player.Name .. "'s cooldown ended") end)
end

--------------------------------------------------------------------------------
-- DETECTION HELPERS
-- These break out the repeated steps inside handleDelete/Paint and runExploit*.
--------------------------------------------------------------------------------

local function getPlayersInRange(brickPos)
	local inRange = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if getDistanceToPos(player, brickPos) <= MAX_DISTANCE then
			table.insert(inRange, player)
		end
	end
	return inRange
end

-- Waits up to SOUND_MAX_NORMAL for any in-range player to emit the delete sound,
-- then returns whoever did. Returns an empty list if nobody does in time.
local function waitForDeleteSoundPlayers(inRange, eventTime)
	local detected = {}
	waitUntil(function()
		detected = {}
		for _, player in ipairs(inRange) do
			if playedDeleteSoundNormally(player, eventTime) then
				table.insert(detected, player)
			end
		end
		return #detected > 0
	end, SOUND_MAX_NORMAL)
	return detected
end

local function waitForPaintSoundPlayers(inRange, eventTime)
	local detected = {}
	waitUntil(function()
		detected = {}
		for _, player in ipairs(inRange) do
			if playedPaintSoundNormally(player, eventTime) then
				table.insert(detected, player)
			end
		end
		return #detected > 0
	end, SOUND_MAX_NORMAL)
	return detected
end

local function includesOwner(players, ownerName)
	for _, player in ipairs(players) do
		if player.Name == ownerName then return true end
	end
	return false
end

local function flagFilteredPlayers(players, ownerName, flagFn)
	for _, player in ipairs(players) do
		if passesAllFilters(player, ownerName) then
			flagFn(player, ownerName)
		end
	end
end

-- Splits a player list by whether they played the slash/delete animation near the event.
-- Players without the anim are more suspicious — slash anim suggests a legitimate nearby delete.
local function splitBySlashAnim(players, eventTime)
	local withSlash, withoutSlash = {}, {}
	for _, player in ipairs(players) do
		if playedSlashAnimNear(player, eventTime) then
			table.insert(withSlash, player)
		else
			table.insert(withoutSlash, player)
		end
	end
	return withSlash, withoutSlash
end

-- Prefer flagging the no-slash group; only fall back to the slash group if it's all we have.
local function chooseSuspectGroup(withSlash, withoutSlash)
	return #withoutSlash > 0 and withoutSlash or withSlash
end

local function anyonePlayedDeleteSoundInExploitWindow(eventTime)
	for _, player in ipairs(Players:GetPlayers()) do
		if playedDeleteSoundInExploitWindow(player, eventTime) then return true end
	end
	return false
end

local function anyonePlayedPaintSoundInExploitWindow(eventTime)
	for _, player in ipairs(Players:GetPlayers()) do
		if playedPaintSoundInExploitWindow(player, eventTime) then return true end
	end
	return false
end

local function getOutOfRangeDeleteSoundPlayers(brickPos, eventTime)
	local suspects = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if playedDeleteSoundInExploitWindow(player, eventTime)
		and getDistanceToPos(player, brickPos) > MAX_DISTANCE then
			table.insert(suspects, player)
		end
	end
	return suspects
end

local function getOutOfRangePaintSoundPlayers(brickPos, eventTime)
	local suspects = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if playedPaintSoundInExploitWindow(player, eventTime)
		and getDistanceToPos(player, brickPos) > MAX_DISTANCE then
			table.insert(suspects, player)
		end
	end
	return suspects
end

--------------------------------------------------------------------------------
-- EXPLOIT DETECTION
-- Runs when no in-range player caused the event, so someone far away must have.
--------------------------------------------------------------------------------

local function runExploitDelete(ownerName, brickPos, eventTime)
	if not isExploitOn() then return end

	local anySound = waitUntil(function()
		return anyonePlayedDeleteSoundInExploitWindow(eventTime)
	end, EXPLOIT_SOUND_WAIT)
	if not anySound then return end

	local suspects = getOutOfRangeDeleteSoundPlayers(brickPos, eventTime)
	if #suspects == 0 then return end

	task.wait(EXPLOIT_WAIT)

	local withSlash, withoutSlash = splitBySlashAnim(suspects, eventTime)
	local toFlag = chooseSuspectGroup(withSlash, withoutSlash)

	if includesOwner(toFlag, ownerName) then return end
	flagFilteredPlayers(toFlag, ownerName, flagExploitDelete)
end

local function runExploitPaint(ownerName, brickPos, eventTime)
	if not isExploitOn() then return end

	local anySound = waitUntil(function()
		return anyonePlayedPaintSoundInExploitWindow(eventTime)
	end, EXPLOIT_SOUND_WAIT)
	if not anySound then return end

	local suspects = getOutOfRangePaintSoundPlayers(brickPos, eventTime)
	if #suspects == 0 then return end

	task.wait(EXPLOIT_WAIT)

	local withSlash, withoutSlash = splitBySlashAnim(suspects, eventTime)
	local toFlag = chooseSuspectGroup(withSlash, withoutSlash)

	if includesOwner(toFlag, ownerName) then return end
	flagFilteredPlayers(toFlag, ownerName, flagExploitPaint)
end

--------------------------------------------------------------------------------
-- DELETE / PAINT DETECTION
--------------------------------------------------------------------------------

local function handleDelete(brickPos, ownerName, removedAt)
	if isDelcubeBurst(ownerName, removedAt) then return end

	task.spawn(function()
		local inRange = getPlayersInRange(brickPos)

		if #inRange == 0 then
			task.spawn(runExploitDelete, ownerName, brickPos, removedAt)
			return
		end

		local detected = waitForDeleteSoundPlayers(inRange, removedAt)

		if #detected == 0 then
			task.spawn(runExploitDelete, ownerName, brickPos, removedAt)
			return
		end

		if includesOwner(detected, ownerName) then return end

		if isDeleteOn() then
			flagFilteredPlayers(detected, ownerName, flagDelete)
		end
	end)
end

local function handlePaint(brickPos, ownerName, changedAt)
	task.spawn(function()
		local inRange = getPlayersInRange(brickPos)

		if #inRange == 0 then
			task.spawn(runExploitPaint, ownerName, brickPos, changedAt)
			return
		end

		local detected = waitForPaintSoundPlayers(inRange, changedAt)

		if #detected == 0 then
			task.spawn(runExploitPaint, ownerName, brickPos, changedAt)
			return
		end

		if includesOwner(detected, ownerName) then return end

		if isPaintOn() then
			flagFilteredPlayers(detected, ownerName, flagPaint)
		end
	end)
end

--------------------------------------------------------------------------------
-- SOUND TRACKING
--------------------------------------------------------------------------------

-- Detects the start of a new sound play: either fresh start (wasPlaying was false)
-- or a loop-back (time jumped from >0.05 back to <0.05).
local function isSoundStarting(playing, wasPlaying, lastTime, currentTime)
	return playing and (not wasPlaying or (lastTime > 0.05 and currentTime < 0.05))
end

local function trackDeleteSound(player, sound)
	local lastTime, wasPlaying = 0, false
	local c = RunService.Heartbeat:Connect(function()
		if not sound.Parent then return end
		local t = sound.TimePosition
		if isSoundStarting(sound.IsPlaying, wasPlaying, lastTime, t) then
			getData(player.UserId).recentDeleteSound = tick()
		end
		lastTime, wasPlaying = t, sound.IsPlaying
	end)
	table.insert(connections, c)
end

local function trackPaintSound(player, sound)
	local lastTime, wasPlaying = 0, false
	local c = RunService.Heartbeat:Connect(function()
		if not sound.Parent then return end
		local t = sound.TimePosition
		if isSoundStarting(sound.IsPlaying, wasPlaying, lastTime, t) then
			getData(player.UserId).recentPaintSound = tick()
		end
		lastTime, wasPlaying = t, sound.IsPlaying
	end)
	table.insert(connections, c)
end

local function hookHRP(player, hrp)
	local function onDescendantAdded(obj)
		if not obj:IsA("Sound") then return end
		if obj.SoundId == BRICK_SOUND_ID then trackDeleteSound(player, obj)
		elseif obj.SoundId == PAINT_SOUND_ID then trackPaintSound(player, obj)
		end
	end

	for _, obj in pairs(hrp:GetDescendants()) do onDescendantAdded(obj) end
	table.insert(connections, hrp.DescendantAdded:Connect(onDescendantAdded))
end

--------------------------------------------------------------------------------
-- SLASH ANIM TRACKING
--------------------------------------------------------------------------------

local function hookAnim(player)
	local lastTime, wasPlaying = 0, false
	local c = RunService.Heartbeat:Connect(function()
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		local animator = hum:FindFirstChildOfClass("Animator")
		if not animator then return end

		for _, track in pairs(animator:GetPlayingAnimationTracks()) do
			if track.Animation and track.Animation.AnimationId:find(DELETE_ANIM_ID) then
				local t = track.TimePosition
				if isSoundStarting(true, wasPlaying, lastTime, t) then
					getData(player.UserId).recentSlashAnim = tick()
				end
				lastTime, wasPlaying = t, true
				return
			end
		end
		wasPlaying = false
	end)
	table.insert(connections, c)
end

--------------------------------------------------------------------------------
-- WATCHERS
--------------------------------------------------------------------------------

local function watchPlayer(player)
	if player.Character then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then hookHRP(player, hrp) end
	end
	table.insert(connections, player.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		if hrp then hookHRP(player, hrp) end
	end))
	hookAnim(player)
end

local function watchBrick(brick, ownerName)
	if not isPaintOn() and not isExploitOn() then return end

	local function onPaintableChange()
		if not isPaintOn() and not isExploitOn() then return end
		handlePaint(brick.Position, ownerName, tick())
	end

	for _, prop in ipairs({"BrickColor", "Material", "Anchored", "CanCollide"}) do
		table.insert(connections, brick:GetPropertyChangedSignal(prop):Connect(onPaintableChange))
	end

	table.insert(connections, brick.ChildAdded:Connect(function(child)
		if child.Name ~= "Light" and child.Name ~= "Drag" then return end
		onPaintableChange()
	end))
end

local function watchFolder(folder)
	local ownerName = folder.Name

	if isDeleteOn() or isExploitOn() then
		table.insert(connections, folder.ChildRemoved:Connect(function(child)
			if child.Name ~= "Brick" then return end
			if not isDeleteOn() and not isExploitOn() then return end
			handleDelete(child.Position, ownerName, tick())
		end))
	end

	table.insert(connections, folder.ChildAdded:Connect(function(child)
		if child.Name ~= "Brick" then return end
		if isSpamOn() then
			local player = Players:FindFirstChild(ownerName)
			if player and passesAllFilters(player, ownerName) then
				flagSpam(player)
			end
		end
		watchBrick(child, ownerName)
	end))

	for _, child in ipairs(folder:GetChildren()) do
		if child.Name == "Brick" then watchBrick(child, ownerName) end
	end
end

--------------------------------------------------------------------------------
-- START / STOP
--------------------------------------------------------------------------------

function GriefDetector.start()
	if isRunning then return end
	isRunning = true

	local bricksFolder = workspace:WaitForChild("Bricks")

	for _, player in ipairs(Players:GetPlayers()) do watchPlayer(player) end
	table.insert(connections, Players.PlayerAdded:Connect(watchPlayer))
	Players.PlayerRemoving:Connect(function(player) playerData[player.UserId] = nil end)

	for _, folder in ipairs(bricksFolder:GetChildren()) do watchFolder(folder) end
	table.insert(connections, bricksFolder.ChildAdded:Connect(watchFolder))
end

function GriefDetector.stop()
	if not isRunning then return end
	isRunning = false

	for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
	table.clear(connections)
	table.clear(playerData)
	table.clear(delcubeTracker)
end

GriefDetector.start()

return GriefDetector














do
  local function updateWhitelisted()
    task.defer(function()
      local t = {}
      for _, p in ipairs(players:GetPlayers()) do table.insert(t, p.Name) end
      toggles.bkitw.add:SetValues(t)
      toggles.enliw.add:SetValues(t)
    end)
  end
  players.PlayerAdded:Connect(updateWhitelisted)
  players.PlayerRemoving:Connect(updateWhitelisted)
  
  local toolSet = {
    Build=true, Delete=true, Paint=true,
    Shape=true, Shovel=true, Sign=true,
    ["The Arkenstone"]=true
  }
  local cooldowns = {}
  players.PlayerRemoving:Connect(function(plr) cooldowns[plr] = nil end)
  Helpers.services.run.RenderStepped:Connect(function()
    if not toggles.enliw.enabled and not toggles.bkitw.enabled then return end
    for _, player in ipairs(players:GetPlayers()) do
      local char = player.Character
      if not char then continue end
      local tool = char:FindFirstChildOfClass("Tool")
      if not tool or not toolSet[tool.Name] then continue end
      local name = player.Name
      if cooldowns[plr] and tick() - cooldowns[plr] < 0.5 then return end
      cooldowns[plr] = tick()
      if tool.Name == "The Arkenstone" then
        if toggles.enliw.enabled and not toggles.enliw.whitelisted[name] then
          Helpers.cmd("clearinv " .. Helpers.resolveName(name))
        end
      else
        if toggles.bkitw.enabled and not toggles.bkitw.whitelisted[name] then
          Helpers.cmd("clearinv " .. Helpers.resolveName(name))
        end
      end
    end
  end)
end
do
  local cooldowns = {}
  
  players.PlayerRemoving:Connect(function(plr) cooldowns[plr] = nil end)
  
  local last = 0
  Helpers.services.run.Heartbeat:Connect(function()
    if tick() - last < 0.05 then return end
    last = tick()
    for _, plr in ipairs(players:GetPlayers()) do
      if plr == localplr then continue end
      local char = plr.Character
      local root = char and char:FindFirstChild("HumanoidRootPart")
      if not root then cooldowns[plr] = nil; continue end
      local err = n
      if root.AssemblyLinearVelocity.Magnitude > 1000 then
        err = "Unusual linear velocity: " .. root.AssemblyLinearVelocity.Magnitude
      end
      if root.AssemblyAngularVelocity.Magnitude > 200 then
        err = "Unusual angular velocity: " .. root.AssemblyAngularVelocity.Magnitude
      end
      if err then
        if not toggles.agd.enabled.fling then return end
        if cooldowns[plr] and tick() - cooldowns[plr] < 4 then return end
        cooldowns[plr] = tick()
        toggles.agd.fling(plr, err)
      end
    end
  end)
end


Helpers.on("ChatListener", function(msg)
  
  
  
  if not next(toggles.antijoin) then return end
  if not msg.TextSource or msg.TextSource.UserId == localplr.UserId then return end
  local text = msg.Text:lower():gsub("%s+", "")
  for _, v in ipairs(toggles.antijoin) do
    local keyword = v:lower()
    if text:find(keyword, 1, true) then
      local sender = players:GetPlayerByUserId(msg.TextSource.UserId)
      if not sender then return end
      Helpers.cmd("reset " .. Helpers.resolveName(sender.Name))
      break
    end
  end
end)
]=]