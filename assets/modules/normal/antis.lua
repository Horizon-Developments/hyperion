local args = ...
local Window = args.Window
local Tabs = args.Tabs
local Obsidian = args.Obsidian
local Helpers = args.Helpers

Tabs.antis = Window:AddTab("Antis", "lock")
local box = Tabs.antis:AddLeftGroupbox("Antis")

local plrs = Helpers.services.players
local localplr = plrs.LocalPlayer
local registered = {}

local function registerWhile(tog, fun, id)
  if tog then
    if registered[id] then return end
    registered[id] = true
    task.spawn(function()
      while registered[id] do
        fun()
        task.wait(0.1)
      end
    end)
    return
  end
  registered[id] = nil
end

box:AddButton({
  Text = "Fix vamp sword",
  Func = function()
    workspace.CurrentCamera:remove()
    task.wait(.1)
    repeat task.wait() until localplr.Character ~= nil
    workspace.CurrentCamera.CameraSubject = localplr.Character:FindFirstChildWhichIsA("Humanoid")
    workspace.CurrentCamera.CameraType = "Custom"
    localplr.CameraMinZoomDistance = 0.5
    localplr.CameraMaxZoomDistance = 400
    localplr.CameraMode = "Classic"
    localplr.Character.Head.Anchored = false
  end
})

box:AddToggle("antiFlash", {
  Text = "Anti flashbang",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      local gui = localplr:FindFirstChild("PlayerGui")
      local main = gui and gui:FindFirstChild("MainGui")
      local ref = main and main:FindFirstChild("FlashBangEffect")
      if ref then ref:Destroy() end
    end, "flash")
  end
})

box:AddToggle("antiBlind", {
  Text = "Anti blind",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      local gui = localplr:FindFirstChild("PlayerGui")
      local blind = gui and gui:FindFirstChild("Blind")
      if blind then blind:Destroy() end
    end, "blind")
  end
})

box:AddToggle("antiFreeze", {
  Text = "Anti freeze",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      local char = localplr.Character
      if char and char:FindFirstChild("Hielo", true) then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
      end
    end, "freeze")
  end
})

box:AddToggle("antiJail", {
  Text = "Anti jail",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      local char = localplr.Character
      local jail = char and char:FindFirstChild("Jail")
      if jail then jail:Destroy() end
    end, "jail")
  end
})

box:AddToggle("antiFog", {
  Text = "Anti fog",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      if game.Lighting then
        game.Lighting.Fog.Density = 0
      end
    end, "fog")
  end
})

box:AddToggle("antiColorless", {
  Text = "Anti colorless",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      if game.Lighting then
        game.Lighting.RGB.Enabled = false
      end
    end, "colorless")
  end
})

box:AddToggle("antiMyopic", {
  Text = "Anti myopic",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      if game.Lighting then
        game.Lighting.Blur.Enabled = false
      end
    end, "myopic")
  end
})

box:AddToggle("antiInvis", {
  Text = "Anti invis jail",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      local char = localplr:WaitForChild("Character")
      if char:WaitForChild("Head").Transparency == 1 then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
      end
    end, "invisjail")
  end
})

box:AddDivider()
box:AddLabel({ Text = "WARNING: these need enli." })

box:AddToggle("antiDropEnli", {
  Text = "Anti drop enli",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      local ark = workspace:FindFirstChild("The Arkenstone")
      if ark and ark:FindFirstChild("Handle") then
        Helpers.cmd("debug")
        Obsidian:Notify({ Title = "Auto Debug", Description = "debugged, The Arkenstone", Time = 1 })
      end
    end, "enli")
  end
})

box:AddToggle("antiRcTank", {
  Text = "Anti rctank",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      if workspace:FindFirstChild("Tank") then
        Helpers.cmd("debug")
        Obsidian:Notify({ Title = "Auto Debug", Description = "debugged, RcTank", Time = 1 })
      end
    end, "rct")
  end
})

box:AddToggle("antiHeartAttack", {
  Text = "Anti Heart Attack",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      if workspace:FindFirstChild("Effect") then
        Helpers.cmd("debug")
        Obsidian:Notify({ Title = "Auto Debug", Description = "debugged, HeartAttack/Effect", Time = 1 })
      end
    end, "heart")
    Obsidian:Notify({ Title = "WARNING", Description = "heart attack is named effect, other gears may trigger this.", Time = 3 })
  end
})

box:AddToggle("antiFuseBomb", {
  Text = "Anti FuseBomb",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      if workspace:FindFirstChild("FuseBomb") then
        Helpers.cmd("debug")
        Obsidian:Notify({ Title = "Auto Debug", Description = "debugged, FuseBomb", Time = 1 })
      end
    end, "bomb")
  end
})

box:AddToggle("antiSubspace", {
  Text = "Anti subspace",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      if workspace:FindFirstChild("SubspaceTripmine") then
        Helpers.cmd(";debug")
        Obsidian:Notify({ Title = "Auto Debug", Description = "debugged, SubSpace", Time = 1 })
      end
    end, "sptm")
  end
})

box:AddToggle("antiMines", {
  Text = "Anti mines",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      if workspace:FindFirstChild("Mine") then
        Helpers.cmd("debug")
        Obsidian:Notify({ Title = "Auto Debug", Description = "debugged, TripMine", Time = 1 })
      end
    end, "mine")
  end
})