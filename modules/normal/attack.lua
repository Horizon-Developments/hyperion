local args = ...
local tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local assets = args.Assets
local Helpers = args.Helpers

tabs.attack = Window:AddTab("Attack", "hand-fist")
local rbox = tabs.attack:AddLeftGroupbox("")
local lbox = tabs.attack:AddRightGroupbox("")
local plrs = Helpers.services.players
local localplr = plrs.LocalPlayer


local SharedData = {}
--[[
START BACKEND
]]
local Events = {}
local function bhelper(fn, name)
  Events[name] = {}
  SharedData[name] = {}
  return function(...)
    task.spawn(fn,Events[name],SharedData[name],...)
  end
end
local function fetchtools(tool, tbl, tblv)
  local result
  local t = 0
  repeat
    if tbl and not tbl[tblv] then
      return nil
    end
    result = localplr.Backpack:FindFirstChild(tool, true) or (localplr.Character and localplr.Character:FindFirstChild(tool, true))
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
  if tbl and not tbl[tblv] then
    return nil
  end
  localplr.Character.Humanoid:EquipTool(result)
  return result:FindFirstChild("Event", true)
end


local delete_aura = bhelper(function(c, d, e)
  d.deleted = 0
  if c.con then
    c.con:Disconnect()
    c.con = nil
  end
  if not e then return end
  c.con = workspace.Bricks.DescendantRemoving:Connect(function(obj)
    if obj.Name == "Brick" then
      d.deleted += 1
    end
  end)
  while c.con do
    local parts = {}
    for _, child in ipairs(workspace.Bricks:GetChildren()) do
      if child:IsA("BasePart") and child.Name == "Brick" then
        table.insert(parts, child)
      else
        for _, obj in ipairs(child:GetChildren()) do
          if obj:IsA("BasePart") and obj.Name == "Brick" then
            table.insert(parts, obj)
            if #parts >= 30 then break end
          end
        end
      end
      if #parts >= 30 then break end
    end

    if #parts == 0 then task.wait() continue end

    task.spawn(function()
      for _, part in ipairs(parts) do
        if not part:FindFirstChildOfClass("Highlight") then
          local highlight = Instance.new("Highlight")
          highlight.Adornee = part
          highlight.FillColor = Color3.fromRGB(255, 0, 0)
          highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
          highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
          highlight.Parent = part
        end
      end
    end)

    local tool = fetchtools("Delete", c, "con")
    if not tool then break end
    local hrp = localplr.Character and localplr.Character.HumanoidRootPart
    if not hrp then task.wait() continue end
    for _, part in ipairs(parts) do
      if part and part.Parent then
        task.spawn(function()
          tool:FireServer(part, hrp.Position)
        end)
      end
    end
    task.wait(0.02)
  end
end, "delete_aura")


local function paint_aura_fixmsg(msg)
  local advertisements = {
    [[Join <font color="#FF0000">Hyperion</font> <font color="#FFD700">Reborn</font>]],
    [[Join Now! <font color="#FF0000">xbkVzSxDBy</font>]],
    [[<font color="#FF0000">Hyperion</font> <font color="#FFD700">Reborn</font>]]
  }
  msg = math.random() < 0.7 and msg or advertisements[math.random(#advertisements)]
  local tags = {}
  msg = msg:gsub("<font.-</font>", function(tag)
    tags[#tags + 1] = tag
    return "\1" .. #tags .. "\1"
  end)
  msg = msg:gsub(".", function(c)
    return math.random() < 0.1 and ("<b>" .. c .. "</b>") or c
  end)
  msg = msg:gsub("\1(%d+)\1", function(i)
    return tags[tonumber(i)]
  end)
  return msg
end

local paint_aura = bhelper(function(c, d, e)
  d.sprayed = 0
  if c.con then
    c.con = nil
  end
  if not e then return end
  c.con = true
  local function randomNormalId()
    local ids = {
      Enum.NormalId.Top,
      Enum.NormalId.Bottom,
      Enum.NormalId.Left,
      Enum.NormalId.Right,
      Enum.NormalId.Front,
      Enum.NormalId.Back
    }
    return ids[math.random(#ids)]
  end
  
  while c.con do
    local parts = {}
    for _, child in ipairs(workspace.Bricks:GetChildren()) do
      if child:IsA("BasePart") and child.Name == "Brick" then
        table.insert(parts, child)
      else
        for _, obj in ipairs(child:GetChildren()) do
          if obj:IsA("BasePart") and obj.Name == "Brick" then
            table.insert(parts, obj)
            if #parts >= 30 then break end
          end
        end
      end
      if #parts >= 30 then break end
    end
    
    if #parts == 0 then task.wait() continue end
    
    task.spawn(function()
      for _, part in ipairs(parts) do
        if not part:FindFirstChildOfClass("Highlight") then
          local highlight = Instance.new("Highlight")
          highlight.Adornee = part
          highlight.FillColor = Color3.fromRGB(255, 0, 0)
          highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
          highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
          highlight.Parent = part
        end
      end
    end)

    local tool = fetchtools("Paint", c, "con")
    if not tool then break end
    local hrp = localplr.Character and localplr.Character.HumanoidRootPart
    if not hrp then task.wait() continue end
    for _, part in ipairs(parts) do
      if part and part.Parent then
        d.sprayed += 1
        tool:FireServer(
          part,
          randomNormalId(),
          hrp.Position, 
          "material",
          Color3.new(0.29411765933037, 0.59215688705444, 0.29411765933037),
          "spary",
          d.Message or paint_aura_fixmsg(d.Message)
        )
        task.wait(0.2)
      end
    end
    task.wait(0.1)
  end
end, "paint_aura")

--[[
START FRONTEND
]]
lbox:AddToggle("delete_aura", {
  Text = "Delete Abuser",
  Default = false,
  Callback = delete_aura
})
rbox:AddToggle("paint_aura", {
  Text = "Spray Abuser",
  Default = false,
  Callback = paint_aura
})

rbox:AddInput("paint_aura_msg", {
  Text        = "Spray txt",
  Placeholder = "Raided by hyperion reborn",
  Callback    = function(v) SharedData["paint_aura"].Message = v end
})

