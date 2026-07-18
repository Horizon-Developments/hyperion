local args = ...
local Window = args.Window
local Tabs = args.Tabs
local Obsidian = args.Obsidian
local Helpers = args.Helpers

Tabs.antis = Window:AddTab("Antis", "lock")
local lbox = Tabs.antis:AddLeftGroupbox("")
local rbox = Tabs.antis:AddRightGroupbox("")

local plrs = Helpers.services.players
local localplr = plrs.LocalPlayer
local registered = {}

local function registerWhile(tog, fun, id)
  if tog then
    if registered[id] then return end
    registered[id] = true
    task.spawn(function()
      while registered[id] do
        pcall(fun)
        task.wait(0.05)
      end
    end)
    return
  end
  registered[id] = nil
end

lbox:AddButton({
  Text = "Fix vamp sword",
  Func = function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
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

do
local x;
plrs.LocalPlayer.CharacterAdded:Connect(function(c)
  if not x then return end
  local b = workspace.Bricks:FindFirstChildWhichIsA("BasePart")
  if b then
    c:WaitForChild("HumanoidRootPart").CFrame = b.CFrame
  end
end)
rbox:AddToggle("antiVoid", {
  Text = "Anti void spawn",
  Default = false,
  Callback = function(v)
    x=v
  end
})
end

lbox:AddToggle("antiFlash", {
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

rbox:AddToggle("antiBlind", {
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

lbox:AddToggle("antiFreeze", {
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

rbox:AddToggle("antiJail", {
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

lbox:AddToggle("antiFog", {
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

rbox:AddToggle("antiColorless", {
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

lbox:AddToggle("antiMyopic", {
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

rbox:AddToggle("antiInvis", {
  Text = "Anti invis",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      local char = localplr.Character or localplr.CharacterAdded:Wait()
      if char:WaitForChild("Head").Transparency == 1 then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
          hum.Health = 0
        end
      end
    end, "invis")
  end
})

lbox:AddToggle("KeepTools", {
  Text = "KeepTools (warning, it drops items when you die, people can use grabtools)",
  Default = false,
  Callback = function(v)
    registerWhile(v, function()
      local char = localplr.Character
      if not char then return end
      local hum = char:FindFirstChildOfClass("Humanoid")
      if hum and hum.Health <= 0 then
        for _, tool in ipairs(char:GetChildren()) do
          if tool:IsA("Tool") then
            tool.Parent = workspace
          end
        end
        for _, tool in ipairs(localplr.Backpack:GetChildren()) do
          if tool:IsA("Tool") then
            tool.Parent = workspace
          end
         end
      end
    end, "KeepTools")
  end
})


local GrabtoolsRbxSignal;
lbox:AddToggle("Grabtools", {
  Text = "Grabtools",
  Default = false,
  Callback = function(v)
    if GrabtoolsRbxSignal then
      GrabtoolsRbxSignal:Disconnect()
      GrabtoolsRbxSignal = nil
    end
    if v then
      GrabtoolsRbxSignal = workspace.ChildAdded:Connect(function(obj)
        if obj:IsA("Tool") then
          obj.Parent = localplr.Backpack
        end
      end)
    end
  end
})

rbox:AddDivider()
lbox:AddDivider()
rbox:AddLabel({ Text = "WARNING: these need enli." })

rbox:AddToggle("antiDropEnli", {
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

lbox:AddToggle("antiRcTank", {
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

rbox:AddToggle("antiHeartAttack", {
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

lbox:AddToggle("antiFuseBomb", {
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

rbox:AddToggle("antiSubspace", {
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

lbox:AddToggle("antiMines", {
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