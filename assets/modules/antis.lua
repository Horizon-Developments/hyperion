local Window = opts.Window
local Tabs = opts.Tabs
local WindUI = opts.WindUI
local Helpers = opts.Helpers

local tab = Window:Tab({
  Title = "Antis",
  Icon = "lock",
})

local plrs = Helpers.services.players
local localplr = plrs.LocalPlayer

local antiflashbang = false
local antiblind = false
local antifreeze = false

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
    antiflashbang = v
  end
})

tab:Toggle({
  Title = "anti blind",
  Callback = function(v)
    antiblind = v
  end
})

tab:Toggle({
  Title = "anti freeze",
  Callback = function(v)
    antifreeze = v
  end
})
local bomb = false
    local heart = false
    local rc = false
    local enli = false
    local subp = false
    local mines = false
    
tab:Toggle({
  Title = "anti drop enli",
  Callback = function(v)
    enli = v
  end,
})
tab:Toggle({
  Title = "anti rctank",
  Callback = function(v)
    rc = v
  end,
})
tab:Toggle({
  Title = "anti Heart Attack",
  Callback = function(v)
    heart = v
    WindUI:Notify({ Title = "WARNING", Content = "heart attck is named effect, other gears may trigger this.", Duration = 3 })
        end,
    })
    
    tab:Toggle({
        Title = "anti FuseBomb",
        Callback = function(v)
            bomb = v
        end,
    })
    
    tab:Toggle({
        Title = "anti subspace",
        Callback = function(v)
            subp = v
        end,
    })
    
    tab:Toggle({
        Title = "anti mines",
        Callback = function(v)
            mines = v
        end,
    })
  
  
cloneref(game:GetService("RunService")).RenderStepped:Connect(function()
  if antifreeze and localplr.Character:FindFirstChild("Hielo", true) then
    localplr.Character:FindFirstChildOfClass("Humanoid").Health = 0
  end
end)
cloneref(game:GetService("RunService")).RenderStepped:Connect(function()
  if antiblind and localplr:FindFirstChild("PlayerGui"):FindFirstChild("Blind") then
    localplr.PlayerGui.Blind:Destroy()
  end
end)
cloneref(game:GetService("RunService")).RenderStepped:Connect(function()
  local ref = localplr.PlayerGui.MainGui:FindFirstChild("FlashBangEffect")
  if antiflashbang and ref then
    ref:Destroy()
  end
end)