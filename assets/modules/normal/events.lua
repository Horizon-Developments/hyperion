local args = ...
local Tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local Helpers = args.Helpers
local Assets = args.Assets

Tabs.events = Window:AddTab("Events", "calendar")
local box = Tabs.events:AddLeftGroupbox("Events")

local path = Assets("OnPlayerJoinList.json")
local plrs = Helpers.services.players
local localplr = plrs.LocalPlayer
local toggles = {}
local enabled = {}
local list = {}
local atldd
local ddList

if isfile(path) then
  local ok, res = pcall(function() return Helpers.services.http:JSONDecode(readfile(path)) end)
  if ok then
    for _, name in ipairs(res) do
      list[name] = true
    end
  else
    Helpers.log("ERR OnPlayerJoinList.json FAILED. ERR:" .. res)
  end
end

local function getNames()
  local t = {}
  for name in pairs(list) do table.insert(t, name) end
  return t
end

local function getIngamePlayers()
  local t = {}
  for _, p in ipairs(plrs:GetPlayers()) do
    if p ~= localplr then
      table.insert(t, p.Name)
    end
  end
  return t
end

local function save()
  local ok, res = pcall(function() writefile(path, Helpers.services.http:JSONEncode(getNames())) end)
  if not ok then Helpers.log("ERR OnPlayerJoinList.json SAVE FAILED. ERR:" .. res) end
end

box:AddLabel({ Text = "Tree:\n1. OnListJoin\n2. OnFriendsJoin\n3. onRandomsJoin\nexample: if player is in 1 it will not run 2/3,\nOnListJoin saves dropdown info,\nif you type {name} it will be replaced to the players username.", DoesWrap = true })

box:AddInput("onFriendsJoinMsg", {
  Text = "On Friends Join",
  Placeholder = "",
  Callback = function(v) toggles.OnFriendsJoin = v end
})
box:AddToggle("onFriendsJoinEnabled", {
  Text = "Friends",
  Default = false,
  Callback = function(v) enabled.OnFriendsJoin = v end
})
box:AddDivider()
box:AddInput("onRandomsJoinMsg", {
  Text = "On Randoms Join",
  Placeholder = "",
  Callback = function(v) toggles.OnRandomsJoin = v end
})
box:AddToggle("onRandomsJoinEnabled", {
  Text = "Randoms",
  Default = false,
  Callback = function(v) enabled.OnRandomsJoin = v end
})
box:AddDivider()
box:AddInput("onListJoinMsg", {
  Text = "On List Join",
  Placeholder = "",
  Callback = function(v) toggles.OnListJoin = v end
})
box:AddToggle("onListJoinEnabled", {
  Text = "List",
  Default = false,
  Callback = function(v) enabled.OnListJoin = v end
})
box:AddDivider()
box:AddInput("addToList", {
  Text = "Add to list (username)",
  Placeholder = "",
  Finished = false,
  Callback = function(v)
    if v == "" or list[v] then return end
    list[v] = true
    atldd:SetValues(getIngamePlayers())
    ddList:SetValues(getNames())
    save()
  end
})

atldd = box:AddDropdown("joinListIngame", {
  Text = "Add to list (ingame player)",
  Values = getIngamePlayers(),
  Default = nil,
  Multi = false,
  Callback = function(name)
    if not name or name == "" or list[name] then return end
    list[name] = true
    ddList:SetValues(getNames())
    save()
  end
})

ddList = box:AddDropdown("joinList", {
  Text = "List (select to remove)",
  Values = getNames(),
  Default = nil,
  Multi = true,
  Callback = function(option)
    list[option] = nil
    ddList:SetValues(getNames())
    save()
  end
})

plrs.PlayerAdded:Connect(function(player)
  atldd:SetValues(getIngamePlayers())
  local name = player.Name
  if enabled.OnListJoin and toggles.OnListJoin and toggles.OnListJoin ~= "" and list[name] then
    Helpers.cmd(toggles.OnListJoin:gsub("{name}", Helpers.resolveName(name)))
  elseif enabled.OnFriendsJoin and toggles.OnFriendsJoin and toggles.OnFriendsJoin ~= "" and player:IsFriendsWith(localplr.UserId) then
    Helpers.cmd(toggles.OnFriendsJoin:gsub("{name}", Helpers.resolveName(name)))
  elseif enabled.OnRandomsJoin and toggles.OnRandomsJoin and toggles.OnRandomsJoin ~= "" then
    Helpers.cmd(toggles.OnRandomsJoin:gsub("{name}", Helpers.resolveName(name)))
  end
end)

plrs.PlayerRemoving:Connect(function()
  atldd:SetValues(getIngamePlayers())
end)