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

local aflash = false
local ablind = false
local afreeze = false

tab:Section("Vamp Sword")
tab:Button({
    Title = "fix vamp sword (humanoid health = 0 method)",
    Callback = function(v)
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
        localplr.Character.Humanoid.Health = 0
    end
})

tab:Section("Flashbang")
tab:Button({
    Title = "anti flashbang",
    Callback = function(v)
        aflash = not aflash
        task.spawn(function()
            while aflash do
                task.wait(0.1)
                pcall(function()
                    localplr.PlayerGui.MainGui:FindFirstChild("FlashBangEffect"):Destroy()
                end)
            end
        end)
    end
})
tab:Section("Blind")
tab:Toggle({
    Title = "anti blind",
    Callback = function(v)
        ablind = v
        task.spawn(function()
            while ablind do
                task.wait(0.1)
                if localplr:FindFirstChild("PlayerGui"):FindFirstChild("Blind") then
                    localplr.PlayerGui.Blind:Destroy()
                end
            end
        end)
    end
})

tab:Section("Freeze")
tab:Toggle({
    Title = "anti freeze",
    Callback = function(v)
        afreeze = v
    end
})
cloneref(game:GetService("RunService")).RenderStepped:Connect(function()
  if antifreeze and localplr.Character:FindFirstChild("Hielo", true) then
    localplr.Character:FindFirstChildOfClass("Humanoid").Health = 0
  end
end)
cloneref(game:GetService("RunService")).RenderStepped:Connect(function()
  if antifreeze and localplr.Character:FindFirstChild("Hielo", true) then
    localplr.Character:FindFirstChildOfClass("Humanoid").Health = 0
  end
end)