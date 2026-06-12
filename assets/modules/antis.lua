local args = ...
local Window = args.Window
local Tabs = args.Tabs
local WindUI = args.WindUI
local Helpers = args.Helpers

Tabs.antis = Window:Tab({
  Title = "Antis",
  Icon = "lock",
})
local tab = Tabs.antis

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

tab:Toggle({
  Title = "anti drop enli",
  Callback = function(v)
    registerWhile(v, function()
      local ark = workspace:FindFirstChild("The Arkenstone")
      if ark and ark:FindFirstChild("Handle") then
        Helpers.cmd(";debug")
        WindUI:Notify({ Title = "Auto Debug", Content = "debugged, The Arkenstone", Duration = 1 })
      end
    end, "enli")
  end
})

tab:Toggle({
  Title = "anti rctank",
  Callback = function(v)
    registerWhile(v, function()
      if workspace:FindFirstChild("Tank") then
        Helpers.cmd(";debug")
        WindUI:Notify({ Title = "Auto Debug", Content = "debugged, RcTank", Duration = 1 })
      end
    end, "rct")
  end
})

tab:Toggle({
  Title = "anti Heart Attack",
  Callback = function(v)
    registerWhile(v, function()
      if workspace:FindFirstChild("Effect") then
        Helpers.cmd(";debug")
        WindUI:Notify({ Title = "Auto Debug", Content = "debugged, HeartAttack/Effect", Duration = 1 })
      end
    end, "heart")

    WindUI:Notify({ Title = "WARNING", Content = "heart attack is named effect, other gears may trigger this.", Duration = 3 })
  end,
})

tab:Toggle({
  Title = "anti FuseBomb",
  Callback = function(v)
    registerWhile(v, function()
      if workspace:FindFirstChild("FuseBomb") then
        Helpers.cmd(";debug")
        WindUI:Notify({ Title = "Auto Debug", Content = "debugged, FuseBomb", Duration = 1 })
      end
    end, "bomb")
  end,
})

tab:Toggle({
  Title = "anti subspace",
  Callback = function(v)
    registerWhile(v, function()
      if workspace:FindFirstChild("SubspaceTripmine") then
        Helpers.cmd(";debug")
        WindUI:Notify({ Title = "Auto Debug", Content = "debugged, SubSpace", Duration = 1 })
      end
    end, "sptm")
  end,
})

tab:Toggle({
  Title = "anti mines",
  Callback = function(v)
    registerWhile(v, function()
      if workspace:FindFirstChild("Mine") then
        Helpers.cmd(";debug")
        WindUI:Notify({ Title = "Auto Debug", Content = "debugged, TripMine", Duration = 1 })
      end
    end, "mine")
  end,
})

tab:Button({
  Title = "fix vamp sword (humanoid health = 0 method)",
  Callback = function()
    game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)

    local char = localplr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
      hum.Health = 0
    end
  end
})

tab:Toggle({
  Title = "anti flashbang",
  Callback = function(v)
    registerWhile(v, function()
      local gui = localplr:FindFirstChild("PlayerGui")
      local main = gui and gui:FindFirstChild("MainGui")
      local ref = main and main:FindFirstChild("FlashBangEffect")
      if ref then
        ref:Destroy()
      end
    end, "flash")
  end
})

tab:Toggle({
  Title = "anti blind",
  Callback = function(v)
    registerWhile(v, function()
      local gui = localplr:FindFirstChild("PlayerGui")
      local blind = gui and gui:FindFirstChild("Blind")
      if blind then
        blind:Destroy()
      end
    end, "blind")
  end
})

tab:Toggle({
  Title = "anti freeze",
  Callback = function(v)
    registerWhile(v, function()
      local char = localplr.Character
      if char and char:FindFirstChild("Hielo", true) then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
          hum.Health = 0
        end
      end
    end, "freeze")
  end
})
tab:Toggle({
  Title = "anti jail",
  Callback = function(v)
    registerWhile(v, function()
      local char = localplr.Character
      if char and char:FindFirstChild("Jail") then
        
      end
    end, "jail")
  end
})
workspace.darkking56807.Jail:Destroy()