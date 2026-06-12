local args = ...
local Tabs = args.Tabs
local Window = args.Window
local WindUI = args.WindUI
local Helpers = args.Helpers
local Assets = args.Assets

local tab = Window:Tab({
  Title = "Events",
  Icon = "calendar",
})

local path = Assets("OnPlayerJoinList.json")
local tcs = Helpers.services.textchat
local chat = tcs.TextChannels.RBXGeneral
local plrs = Helpers.services.players
local localplr = plrs.LocalPlayer
local toggles = {}
local list = {}
local ddList

if isfile(path) then
  local ok, res = pcall(function() return Helpers.services.http:JSONDecode(readfile(path)) end)
  if ok then
    for _, name in ipairs(res) do
      list[name] = true
    end
  else
    Helpers.log("ERR OnPlayerJoinList.json FAILED. ERR:"..res)
  end
end

local function getNames()
  local t = {}
  for name in pairs(list) do table.insert(t, name) end
  return t
end

local function save()
  local ok, res = pcall(function() writefile(path, Helpers.services.http:JSONEncode(getNames())) end)
  if not ok then Helpers.log("ERR OnPlayerJoinList.json SAVE FAILED. ERR:"..res) end
end

tab:Paragraph({
  Title = "Info",
  Desc = [[
Tree:
1. OnListJoin
2. OnFriendsJoin
3. onRandomsJoin
example: if player is in 1 it will not run 2/3,
OnListJoin saves dropdown info,
if you type {name} it will be replaced to the players username.
]]
})

tab:Section("On Player Join")
tab:Input({
  Title = "On Friends Join",
  Placeholder = "",
  Callback = function(v)
    toggles.OnFriendsJoin = v
  end
})
tab:Input({
  Title = "On Randoms Join",
  Placeholder = "",
  Callback = function(v)
    toggles.OnRandomsJoin = v
  end
})
tab:Input({
  Title = "On List Join",
  Placeholder = "",
  Callback = function(v)
    toggles.OnListJoin = v
  end
})
tab:Input({
  Title = "Add to list",
  Placeholder = "",
  Callback = function(v)
    if list[v] then return end
    list[v] = true
    ddList:Refresh(getNames())
    save()
  end
})
ddList = tab:Dropdown({
  Title = "List",
  Desc = "Select on a name to remove it.",
  Values = getNames(),
  Value = nil,
  Multi = true,
  AllowNone = true,
  Callback = function(option)
    list[option] = nil
    ddList:Refresh(getNames())
    save()
  end
})

plrs.PlayerAdded:Connect(function(player)
  local name = player.Name
  if toggles.OnListJoin and list[name] then
    Helpers.cmd(toggles.OnListJoin:gsub("{name}", Helpers.resolveName(name)))
  elseif toggles.OnFriendsJoin and player:IsFriendsWith(localplr.UserId) then
    Helpers.cmd(toggles.OnFriendsJoin:gsub("{name}", Helpers.resolveName(name)))
  elseif toggles.OnRandomsJoin then
    Helpers.cmd(toggles.OnRandomsJoin:gsub("{name}", Helpers.resolveName(name)))
  end
end)