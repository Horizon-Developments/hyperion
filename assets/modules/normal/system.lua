local args = ...
local Tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local Helpers = args.Helpers

local msg = {}
msg["7033670458"] = "The Hyperion owner has arrived!"
local blacklist = {}

-- TODO: add userids
if blacklist[tostring(Helpers.services.players.LocalPlayer.UserId)] then
  Helpers.say("IM A LOSER")
  Helpers.say("IM A LOSER")
  Helpers.say("IM A LOSER")
  Helpers.say("IM A LOSER")
  task.wait(0.1)
  Helpers.services.players.LocalPlayer:Kick("Blacklisted from hyperion")
end

local function plrAddedFunc(p)
  local i = msg[tostring(p.UserId)]
  if i then
    Helpers.selfchat(i)
  end
end

Helpers.services.players.PlayerAdded:Connect(plrAddedFunc)
for i, v in pairs(Helpers.services.players:GetPlayers()) do
  plrAddedFunc(v)
end