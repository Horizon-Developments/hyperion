local args = ...

local tabs = args.Tabs
local Window = args.Window
local WindUI = args.WindUI
local assets = args.Assets
local Helpers = args.Helpers

tabs.spychat = Window:Tab({
  Title = "Spychat (Fixed)",
  Icon = "hat-glasses"
})

local tab = tabs.spychat
local tcs = Helpers.services.textchat
local spychat = {
  enabled = false,
  antispam = false
}

tab:Toggle({
  Title = "SpyChat",
  Desc = "You can see ; commands.",
  Icon = "hat-glasses",
  Value = false,
  Callback = function(val)
    spychat.enabled = val
  end
})
tab:Toggle({
  Title = "Smart Anti-Spam",
  Desc = "Ignores repeated messages. If someone sends the same message as their previous one it gets skipped.",
  Icon = "brain",
  Value = false,
  Callback = function(val)
    spychat.antispam = val
  end
})

local cache = {}
Helpers.on("ChatListener", function(msg)
  local txt = msg.Text
  if not spychat.enabled or not txt:find(";") then return end
  if spychat.antispam then
    if cache[msg.TextSource.Name] == txt then return end
    cache[msg.TextSource.Name] = txt
  end
  local player = Helpers.services.players:GetPlayerByUserId(msg.TextSource.UserId)
  local char = player and player.Character
  local namePart = char and char:FindFirstChild("Nombre")
  local label = namePart and namePart:FindFirstChild("Text1")
  local color = label and label.TextColor3 or Color3.new(1, 1, 1)
  local hex = string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
  tcs.TextChannels.RBXGeneral:DisplaySystemMessage(
    string.format("<font color='%s'>%s</font>: %s", hex, player and player.DisplayName or msg.TextSource.Name, txt)
  )
end)