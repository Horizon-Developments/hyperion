local args = ...
local tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local assets = args.Assets
local Helpers = args.Helpers

tabs.adminkit = Window:AddTab("AdminKit", "wrench")
local box = tabs.adminkit:AddLeftGroupbox("AdminKit")

local tcs = Helpers.services.textchat
local players = Helpers.services.players
local localplr = players.LocalPlayer
local toggles = { antijoin = {}, bkitw = { whitelisted = {} }, enliw = { whitelisted = {} } }

box:AddDropdown("antiJoin", {
  Text = "Anti join*",
  Tooltip = "Prevents join og, vc, xl (:",
  Values = { "joinxl", "joinog", "joinvc" },
  Default = {},
  Multi = true,
  Callback = function(selected)
    toggles.antijoin = selected
  end
})

box:AddDivider()
box:AddLabel({ Text = "Bkit Whitelist: if a non-whitelisted player has bkit, it clearinv's them" })
box:AddToggle("bkitwEnabled", {
  Text = "Enable",
  Default = false,
  Callback = function(val)
    toggles.bkitw.enabled = val
  end
})
toggles.bkitw.add = box:AddDropdown("bkitwWhitelist", {
  Text = "Whitelisted",
  Values = (function()
    local t = {}
    for _, player in ipairs(players:GetPlayers()) do
      table.insert(t, player.Name)
    end
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

box:AddDivider()
box:AddLabel({ Text = "Arkenstone Whitelist: if a non-whitelisted player has The Arkenstone, it clearinv's them" })
box:AddToggle("enliwEnabled", {
  Text = "Enable",
  Default = false,
  Callback = function(val)
    toggles.enliw.enabled = val
  end
})
toggles.enliw.add = box:AddDropdown("enliwWhitelist", {
  Text = "Whitelisted",
  Values = (function()
    local t = {}
    for _, player in ipairs(players:GetPlayers()) do
      table.insert(t, player.Name)
    end
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

box:AddDivider()
box:AddButton({
  Text = "Show Enlightened",
  Func = function()
    for _, plr in pairs(Helpers.services.players:GetPlayers()) do
      if plr:GetAttribute("Arken") then
        Obsidian:Notify({ Title = "Enlightened", Description = plr.Name .. " is enlightened", Time = 3 })
      end
    end
  end
})

do
  local function updateWhitelisted()
    task.defer(function()
      local t = {}
      for _, player in ipairs(players:GetPlayers()) do
        table.insert(t, player.Name)
      end
      toggles.bkitw.add:SetValues(t)
      toggles.enliw.add:SetValues(t)
    end)
  end
  players.PlayerAdded:Connect(updateWhitelisted)
  players.PlayerRemoving:Connect(updateWhitelisted)

  local toolSet = {
    Build = true, Delete = true, Paint = true,
    Shape = true, Shovel = true, Sign = true,
    ["The Arkenstone"] = true
  }
  cloneref(game:GetService("RunService")).RenderStepped:Connect(function()
    if not toggles.enliw.enabled and not toggles.bkitw.enabled then return end
    for _, player in ipairs(players:GetPlayers()) do
      local char = player.Character
      if not char then continue end
      local tool = char:FindFirstChildOfClass("Tool")
      if not tool or not toolSet[tool.Name] then continue end
      local name = player.Name
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

Helpers.on("ChatListener", function(msg)
  if not toggles.enliw.enabled and not toggles.bkitw.enabled then return end
  if not msg.TextSource or msg.TextSource.UserId == localplr.UserId then return end
  local text = msg.Text:lower():gsub("%s+", "")
  for _, v in ipairs(toggles.antijoin) do
    local keyword = v:lower()
    if text == keyword or text:sub(1, #keyword) == keyword or text:find(keyword, 1, true) then
      local sender = players:GetPlayerByUserId(msg.TextSource.UserId)
      if not sender then return end
      Helpers.cmd("reset " .. Helpers.resolveName(sender.Name))
      break
    end
  end
end)