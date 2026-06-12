local args = ...
local Window = args.Window
local Tabs = args.Tabs
local WindUI = args.WindUI
local Helpers = args.Helpers

local tab = Window:Tab({
  Title = "Antis",
  Icon = "lock",
})

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

tab:Section("Auto debug")
tab:Toggle({
  Title = "anti drop enli",
  Callback = function(v)
    registerWhile(v, function() 
      if workspace:FindFirstChild("The Arkenstone") and workspace["The Arkenstone"]:FindFirstChild("Handle") then
        Helpers.cmd(";debug")
        WindUI:Notify({ Title = "Auto Debug", Content = "debuged, The Arkenstone", Duration = 1 })
      end
    end, "enli")
  end
})
tab:Toggle({
  Title = "anti rctank",
  Callback = function(v)
    registerWhile(v, function() 
      workspace:FindFirstChild("Tank") then
        Helpers.cmd(";debug")
        WindUI:Notify({ Title = "Auto Debug", Content = "debuged, RcTank", Duration = 1 })
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
        WindUI:Notify({ Title = "Auto Debug", Content = "debuged, HeartAttack/Effect", Duration = 1 })
      end
    end, "heart")
    WindUI:Notify({ Title = "WARNING", Content = "heart attck is named effect, other gears may trigger this.", Duration = 3 })
  end,
})
tab:Toggle({
  Title = "anti FuseBomb",
  Callback = function(v)
    registerWhile(v, function() 
      if workspace:FindFirstChild("FuseBomb") then
        Helpers.cmd(";debug")
        WindUI:Notify({ Title = "Auto Debug", Content = "debuged, FuseBomb", Duration = 1 })
      end
    end, "bomb")
  end,
})
tab:Toggle({
  Title = "anti subspace",
  Callback = function(v)
  Callback = function(v)
    registerWhile(v, function() 
      if workspace:FindFirstChild("SubspaceTripmine") then
        Helpers.cmd(";debug")
        WindUI:Notify({ Title = "Auto Debug", Content = "debuged, SubSpace", Duration = 1 })
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
        WindUI:Notify({ Title = "Auto Debug", Content = "debuged, TripMine", Duration = 1 })
      end
    end, "mine")
  end,
})

tab:Button({
  Title = "fix vamp sword (humanoid health = 0 method)",
  Callback = function(v)
    game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    localplr.Character.Humanoid.Health = 0
  end
})

tab:Button({
  Title = "anti flashbang",
  Callback = function(v)
    registerWhile(v, function()
      local ref = localplr.PlayerGui.MainGui:FindFirstChild("FlashBangEffect")
      if ref then
        ref:Destroy()
      end
    end, "")
  end
})

tab:Toggle({
  Title = "anti blind",
  Callback = function(v)
    registerWhile(v, function()
      if localplr:FindFirstChild("PlayerGui"):FindFirstChild("Blind") then
        localplr.PlayerGui.Blind:Destroy()
      end
    end, "blind")
  end
})

tab:Toggle({
  Title = "anti freeze",
  Callback = function(v)
    registerWhile(v, function()
      if localplr.Character:FindFirstChild("Hielo", true) then
        localplr.Character:FindFirstChildOfClass("Humanoid").Health = 0
      end
    end, "freeze")
  end
})