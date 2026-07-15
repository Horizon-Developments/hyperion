--WHITELIST
--[[
  Hyperion Project
  Copyright (c) 2026 Horizon-Developments
  All rights reserved.
  Repository:
  https://github.com/Horizon-Developments/hyperion
  License:
  https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/LICENSE.md
]]
local args = ...
local Tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local Helpers = args.Helpers
local plrs = Helpers.services.players

--[[
local whitelist = {
  [8718371620] = "2299a8c95fa0f4cc5d4a8a9ce26dd5ad3da238cc85b79c2213b1256adfbd1213", -- wilson
  [4941339651] = "0005c647816528e6b9f65dbcf379be69de81192c6557febd134538abc207d701" -- me
}
if whitelist[plrs:GetUserIdFromNameAsync(plrs.LocalPlayer.Name)] and whitelist[plrs:GetUserIdFromNameAsync(plrs.LocalPlayer.Name)] == gethwid() then else
  return
end
]]


Tabs.plugins = Window:AddTab("Crasher", "blocks")
local box = Tabs.plugins:AddLeftGroupbox("Crasher")
local localplr = Helpers.services.players.LocalPlayer
local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/src/autobuild.lua"))(...)
local brick = nil
local toggle = false
local withSpray = true

local function toghelper(fn)
  local tog = false
  local env = {}
  return function(b)
    tog = b
    fn(tog, env)
  end
end

local function fetchtools(tool)
  local result
  local t = 0

  repeat
    result = localplr.Backpack:FindFirstChild(tool, true)
      or (localplr.Character and localplr.Character:FindFirstChild(tool, true))

    if not result then
      t = t + 0.5
      if t >= 5 then
        t = 0
        Obsidian:Notify({
          Title = "Waiting for " .. tool,
          Description = tool .. " not found on backpack or character. Waiting...",
          Time = 3
        })
      end
      task.wait(0.5)
    end
  until result

  localplr.Character.Humanoid:EquipTool(result)
  return result:FindFirstChild("Event", true)
end

box:AddToggle("crasher.spray", {
  Text     = "with spray",
  Default  = true,
  Callback = function(b)
    withSpray = b
  end
})

box:AddButton({
  Text = "setup crasher",
  Func = function()
    local data = {
      {
        a = true,
        p = {
          math.floor(localplr.Character.HumanoidRootPart.Position.X),
          math.floor(localplr.Character.HumanoidRootPart.Position.Y),
          math.floor(localplr.Character.HumanoidRootPart.Position.Z),
        },
        cc = false,
        m = "glass",
        sp = withSpray and {
          { "Front",  "", "龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘", 0 },
          { "Right",  "", "龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘", 0 },
          { "Top",    "", "龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘", 0 },
          { "Left",   "", "龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘", 0 },
          { "Back",   "", "龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘", 0 },
          { "Bottom", "", "龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘龘", 0 },
        } or nil,
        o = "Glass",
        c = { 0, 0, 255 },
      }
    }

    local waiter

    task.spawn(function()
      waiter = workspace.Bricks:WaitForChild(localplr.Name).ChildAdded:Wait()
    end)

    task.wait(0.05)
    lib.build(game:GetService("HttpService"):JSONEncode(data), {}, fetchtools, true):start()

    repeat task.wait() until waiter
    brick = waiter

    Obsidian:Notify({
      Title = "Done.",
      Description = "turn on start crasher",
      Time = 3
    })
  end
})

box:AddToggle("crasher.toggle", {
  Text     = "start crasher",
  Default  = false,
  Disabled = false,
  Callback = function(b)
    toggle = b
    if not toggle then return end
    if brick == nil or brick.Parent == nil then
      Obsidian:Notify({
        Title = "Brick not found",
        Description = "Click start crasher",
        Time = 3
      })
      return
    end
    local event = fetchtools("Build")
    while toggle and task.wait() do
      event:FireServer(brick, Enum.NormalId.Top, brick.Position - Vector3.new(0, 4, 0), "normal")
    end
  end
})

box:AddDivider()
box:AddLabel({ Text = "Downside, all new blocks and blocks in the same poit2ion are locally removed.", DoesWrap = true })
local floor = math.floor
local bricks = workspace.Bricks
box:AddToggle("crasher.anticrash", {
  Text     = "anti crash",
  Default  = false,
  Disabled = false,
  Callback = toghelper(function(b, e)
    if e.conn then
      e.conn:Disconnect()
      e.conn = nil
    end

    if e.removeConn then
      e.removeConn:Disconnect()
      e.removeConn = nil
    end
    if not b then return end
    if not e.seen then e.seen = setmetatable({}, { __mode = "v" }) end
    local seen = e.seen
    local function key(pos)
      return floor(pos.X).."."..floor(pos.Y).."."..floor(pos.Z)
    end
    for _, instance in ipairs(bricks:GetDescendants()) do
      if instance:IsA("BasePart") then
        local k = key(instance.Position)
        local existing = seen[k]
        if existing and existing ~= instance and existing:IsDescendantOf(bricks) then
          instance:Destroy()
        else
          seen[k] = instance
        end
      end
    end
    
    e.conn = bricks.DescendantAdded:Connect(function(instance)
      if not instance:IsA("BasePart") then return end
      local k = key(instance.Position)
      if seen[k] and seen[k] ~= instance and seen[k]:IsDescendantOf(bricks) then
        instance:Destroy()
      else
        seen[k] = instance
      end
    end)
    
    e.removeConn = bricks.DescendantRemoving:Connect(function(instance)
      if not instance:IsA("BasePart") then
        return
      end
      local k = key(instance.Position)
      if seen[k] == instance then
        seen[k] = nil
      end
    end)
  end)
})