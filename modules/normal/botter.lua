local args     = ...
local Tabs     = args.Tabs
local Window   = args.Window
local Obsidian = args.Obsidian
local Helpers  = args.Helpers
local Assets   = args.Assets

local botInstance
local fn, api = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/api.lua"))


if not fn then
  return warn(api)
end

Tabs.botting = Window:AddTab("Botting", "bot")
local lbox = Tabs.botting:AddLeftGroupbox("")
local rbox = Tabs.botting:AddRightGroupbox("")

lbox:AddLabel([[
Tired of logging into your alts just to donate or run commands?
Now you only need to execute once on each bot.

Setup:
1. Click Generate Bot URL below.
2. Copy the generated script into your bots Autoexecute or run.
Thats it, easy and simple

Commands can be sent via chat using the "hx." prefix.

Example:
hx.join

Tip:
use @ if you want to use Name only filtering (not DisplayName): @JohnDoe
]], true)

lbox:AddDivider()
rbox:AddDivider()

rbox:AddButton("botter@cmds.btn", {
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
  local ok, result = api.Bots:CreateInstance()
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
    Description = "Script copied to clipboard. Put it in your bots Autoexecute.",
    Time        = 4,
  })
 end
})
lbox:AddLabel("botter@cmds.label", {
  Text = "",
  DoesWrap = true,
})
lbox:AddInput("botter@cmds.input", {
  ClearTextOnFocus = false,
  Finished = true,
  Text = "Enter a command (if you cant use chat)",
  Default = "donate horizon",
})
--<UI END>
local commands = {}

local path = Assets("BotModules")
makefolder(path)

local function findPlayer(query)
  if not query then return end
  query = query:lower():gsub("%.", "_")
  local queryLen = #query
  local matches = {}
  for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
    if query:sub(1, 1) == "@" then
      if player.Name:lower():sub(1, queryLen - 1) == query:sub(2) then
        table.insert(matches, player)
      end
    else
      if player.Name:lower():sub(1, queryLen) == query
        or player.DisplayName:lower():sub(1, queryLen) == query then
        table.insert(matches, player)
      end
    end
  end
  if #matches == 1 then return matches[1] end
  return nil
end
local function safeUser(n)
  return n:lower():gsub("bt_c", "bt"):gsub("btc", "bt"):gsub("fat_[^_.]*", "fa"):gsub("fat", "fa"):gsub("btc_[^_.]*", "bt"):gsub("_", ".")
end
do
local system = {
  Name = "System",
  Description = "Built-in commands",
  Commands = {}
}
local cmds = system.Commands

table.insert(cmds, {
  Name = "donate",
  Description = "Donates time to a player (or yourself)",
  Aliases = { "d" },
  Function = function(args)
    local target = args[1] and findPlayer(safeUser(args[1])) or localplr
    if not target then return end
    local amount = tonumber(args[2])
    return ([[
      local plrs = game:GetService("Players")
      if not plrs:FindFirstChild("%s") then return end
      game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(";donate %s " .. %s)
    ]]):format(
      safeUser(target.Name),
      target.Name,
      amount or [[plrs.LocalPlayer:WaitForChild("leaderstats"):WaitForChild("Time").Value]]
    )
  end
})
table.insert(cmds, {
  Name = "join",
  Description = "Make all clients join you",
  Aliases = { "j"},
  Function = function(args)
    return ([[
game:GetService("TeleportService"):TeleportToPlaceInstance(
  %d,
  "%s",
  game:GetService("Players").LocalPlayer
)
    ]]):format(game.PlaceId, game.JobId);
  end
})
table.insert(cmds, {
  Name = "say",
  Description = "Makes all clients say the message",
  Aliases = { "s" },
  Function = function(args)
    return ([[
game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync("%q")
    ]]):format(table.concat(args, " "))
  end
})
table.insert(cmds, {
  Name = "tpAll",
  Description = "",
  Aliases = { "tp" },
  Function = function(args)
    local p = workspace:WaitForChild(localplr.Name):GetPivot().Position
    return ([[
local p = game:GetService("Players").LocalPlayer
(p.Character or p.CharacterAdded:Wait()):PivotTo(CFrame.new(%d, %d, %d))
    ]]):format(p.X, p.Y, p.Z)
  end
})


table.insert(commands, system); end



do
  local cmdLabelText = "if a command has an argument which contains cmd? it is optional\n"
  for _, modulepath in listfiles(path) do
    local ok, dat = pcall(function()
      local module = loadstring(readfile(modulepath))()
      assert(typeof(module.Name) == "string", "[BOT]: Name isnt a string")
      assert(typeof(module.Description) == "string", "[BOT]: Description isnt a string")
      assert(typeof(module.Commands) == "table", "[BOT]: Commands isnt a table")
      assert(#module.Commands > 0)
      for commandName, command in pairs(module.Commands) do
        assert(type(command) == "table", ("[BOT]: Command '%s' isn't a table"):format(commandName))
        assert(type(command.Name) == "string", ("[BOT]: Command '%s' Name isn't a string"):format(commandName))
        assert(type(command.Description) == "string", ("[BOT]: Command '%s' Description isn't a string"):format(commandName))
        assert(type(command.Aliases) == "table" or command.Aliases == nil, ("[BOT]: Command '%s' Aliases isn't a table or nil"):format(commandName))
        assert(type(command.Function) == "function", ("[BOT]: Command '%s' Function isn't a function"):format(commandName))
      end
      return module
    end)
    if ok then
      local info = ("%s\n (%s)\n\n"):format(dat.Name, dat.Description)
      for _, cmdDat in ipairs(dat.Commands) do
        local aliases = (cmdDat.Aliases and #cmdDat.Aliases > 0)
          and "(" .. table.concat(cmdDat.Aliases, ",") .. ")"
          or ""
        info ..= ("  %s %s\n  %s\n\n"):format(cmdDat.Name, aliases, cmdDat.Description)
      end
      cmdLabelText ..= info .. "\n"
      table.insert(commands, dat)
    else
      print(dat)
    end
  end
  Obsidian.Labels["botter@cmds.label"]:SetText(cmdLabelText)
end

local function handleCmd(msg)
  if not botInstance or not botInstance.Authenticated then
    return Obsidian:Notify({
      Title       = "Error",
      Description = "Websocket is not ready, wait please!",
      Time        = 2,
    })
  end
  task.spawn(function()
    msg = msg:gsub("%s+$", "")
    local parts = {}
    for w in string.gmatch(msg, "[^ ]+") do
      table.insert(parts, w)
    end
    local fn
    for _, plugin in ipairs(commands) do
      for _, cmd in ipairs(plugin.Commands) do
        if cmd.Name == parts[1] or table.find(cmd.Aliases or {}, parts[1]) then
          fn = cmd.Function
          break
        end
      end
      if fn then break end
    end
    if not fn then
      return Obsidian:Notify({
        Title       = "Error",
        Description = "Command does not exist",
        Time        = 2,
      })
    end
    table.remove(parts, 1)
    local ok, res = pcall(fn, parts)
    if not ok then
      warn(res)
      return Obsidian:Notify({
        Title       = "Error",
        Description = "Command crashed! Logs in console",
        Time        = 2,
      })
    end
    if not res then return end
    botInstance:SendAsync(res)
  end)
end

Helpers.on("ChatListener", function(msg)
  if not msg.TextSource or msg.TextSource.UserId ~= game:GetService("Players").LocalPlayer.UserId then return end
  if msg.Text:sub(1, 3) ~= "hx." then return end
  handleCmd(msg.Text:gsub("^hx%.",""))
end)

Obsidian.Options["botter@cmds.input"]:OnChanged(handleCmd)