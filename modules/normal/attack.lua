local args = ...
local tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local assets = args.Assets
local Helpers = args.Helpers

tabs.attack = Window:AddTab("Attack", "hand-fist")
local plrs = Helpers.services.players
local localplr = plrs.LocalPlayer
local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/autobuild.lua"))(...)

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
        tool:FireServer(part, hrp.Position)
      end
    end
    task.wait(0.02)
  end
  for _, obj in ipairs(workspace.Bricks:GetDescendants()) do
    if (obj.Parent.Parent == workspace.Bricks or obj.Parent == workspace.Bricks) and obj:IsA("Highlight") and highlight.FillColor == Color3.fromRGB(255, 0, 0) then
      obj:Destroy()
    end
  end
end, "delete_aura")


local function paint_aura_fixmsg(msg)
  local advertisements = {
    [[Join <font color="#FF0000">Hyperion</font> <font color="#FFD700">Reborn</font>]],
    [[Join Now! <font color="#FF0000">xbkVzSxDBy</font>]],
    [[<font color="#FF0000">Hyperion</font> <font color="#FFD700">Reborn</font>]]
  }
  msg = math.random() < 0.6 and msg or advertisements[math.random(#advertisements)]
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
  if not d.Message then d.Message = "" end
  c.con = true
  local ids = {
    Enum.NormalId.Top,
    Enum.NormalId.Bottom,
    Enum.NormalId.Left,
    Enum.NormalId.Right,
    Enum.NormalId.Front,
    Enum.NormalId.Back
  }
  
  
  while c.con and task.wait(0.1) do
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
          ids[math.random(#ids)],
          hrp.Position, 
          "both \240\159\164\157",
          Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255)),
          "spray",
          paint_aura_fixmsg(d.Message)
        )
        task.wait(0.02)
      end
    end
  end
  for _, obj in ipairs(workspace.Bricks:GetDescendants()) do
    if (obj.Parent.Parent == workspace.Bricks or obj.Parent == workspace.Bricks) and obj:IsA("Highlight") and highlight.FillColor == Color3.fromRGB(255, 0, 0) then
      obj:Destroy()
    end
  end
end, "paint_aura")

local crasher_start = bhelper(function(c, d, e)
  d.Placed = 0
  if c.anticrash then
    c.anticrash:Disconnect()
    c.anticrash = nil
  end
  if c.thread then
    task.cancel(c.thread)
    c.thread = nil
  end
  if not e then
    c.seen = nil
    return
  end
  if not SharedData["crasher_init"] or not SharedData["crasher_init"].Brick or not SharedData["crasher_init"].Brick.Parent then
    return Obsidian:Notify({
      Title = "Setup crasher.",
      Description = "Cannot continue",
      Time = 3
    })
  end
  c.thread = task.spawn(function()
    while task.wait() do
      local b = SharedData["crasher_init"].Brick
      local t = fetchtools("Build", c, "thread")
      if not t then
        return
      end
      t:FireServer(
        b,
        Enum.NormalId.Top,
        b.Position + Vector3.new(0, 1, 0),
        "detailed"
      )
    end
  end)
  local _floor  = math.floor
  local _rawget = rawget
  local _rawset = rawset
  local folder  = workspace.Bricks:WaitForChild(localplr.Name)
  c.seen = setmetatable({}, { __mode = "v" })
  local seen = c.seen
  local children = folder:GetChildren()
  for i = 1, #children do
    local inst = children[i]
    if inst.Name == "Brick" then
      local pos = inst.Position
      local k = _floor(pos.X) .. "." .. _floor(pos.Y) .. "." .. _floor(pos.Z)
      if _rawget(seen, k) then
        inst:Destroy()
      else
        _rawset(seen, k, inst)
      end
    end
  end
  c.anticrash = folder.ChildAdded:Connect(function(inst)
    if inst.Name ~= "Brick" then
      return
    end
    d.Placed += 1
    local pos = inst.Position
    local k = _floor(pos.X) .. "." .. _floor(pos.Y) .. "." .. _floor(pos.Z)
    local existing = _rawget(seen, k)
    if existing then
      if not existing:IsDescendantOf(folder) then
        _rawset(seen, k, inst)
      elseif existing ~= inst then
        inst:Destroy()
      end
    else
      _rawset(seen, k, inst)
    end
  end)
end, "crasher_start")

local crasher_anti = bhelper(function(c, d, e)
  if c.anticrash then
    c.anticrash:Disconnect()
    c.anticrash = nil
  end
  if not e then
    c.seen = nil
    return
  end
  
  local _floor  = math.floor
  local _rawget = rawget
  local _rawset = rawset
  local folder  = workspace.Bricks:WaitForChild(localplr.Name)
  
  if not c.seen then
    c.seen = setmetatable({}, { __mode = "v" })
  end
  local seen = c.seen
  c.anticrash = folder.ChildAdded:Connect(function(inst)
    if inst.Name ~= "Brick" then return end
    local pos = inst.Position
    local k = _floor(pos.X) .. "." .. _floor(pos.Y) .. "." .. _floor(pos.Z)
    local existing = _rawget(seen, k)
    if existing then
      if not existing:IsDescendantOf(folder) then
        _rawset(seen, k, inst)
      elseif existing ~= inst then
        inst:Destroy()
      end
    else
      _rawset(seen, k, inst)
    end
  end)
  local children = folder:GetChildren()
  for i = 1, #children do
    local inst = children[i]
    if inst.Name == "Brick" then
      local pos = inst.Position
      local k = _floor(pos.X) .. "." .. _floor(pos.Y) .. "." .. _floor(pos.Z)
      if _rawget(seen, k) then
        inst:Destroy()
      else
        _rawset(seen, k, inst)
      end
    end
  end
end, "crasher_anti")

local crasher_init = bhelper(function(c, d)
  d.Brick = nil
  local tool = localplr.Backpack:FindFirstChild("Build", true)
    or (localplr.Character and localplr.Character:FindFirstChild("Build", true))
  local event = tool and tool:FindFirstChild("Event", true)
  if not event then
    return Obsidian:Notify({
      Title = "No build tool found.",
      Description = "Build not found on backpack or character.",
      Time = 3
    })
  end
  local character = localplr.Character or localplr.CharacterAdded:Wait()
  local hrp = character:WaitForChild("HumanoidRootPart")
  local folder = workspace.Bricks:WaitForChild(localplr.Name)
  local conn
  conn = folder.ChildAdded:Connect(function(brick)
    if brick.Name ~= "Brick" then return end
    local tool = fetchtools("Paint")
    tool:FireServer(
      brick,
      Enum.NormalId.Top,
      hrp.Position,
      "material",
      Color3.fromRGB(224, 224, 112),
      "collide",
      ""
    )
    task.wait(0.3)
    tool:FireServer(
      brick,
      Enum.NormalId.Top,
      hrp.Position,
      "both \240\159\164\157",
      Color3.new(0, 0, 0),
      "neon",
      ""
    )
    task.wait(0.3)
    local sides = {
      {Enum.NormalId.Top,    brick.Position + brick.CFrame.UpVector * brick.Size.Y / 2},
      {Enum.NormalId.Bottom, brick.Position - brick.CFrame.UpVector * brick.Size.Y / 2},
      {Enum.NormalId.Front,  brick.Position + brick.CFrame.LookVector * brick.Size.Z / 2},
      {Enum.NormalId.Back,   brick.Position - brick.CFrame.LookVector * brick.Size.Z / 2},
      {Enum.NormalId.Left,   brick.Position - brick.CFrame.RightVector * brick.Size.X / 2},
      {Enum.NormalId.Right,  brick.Position + brick.CFrame.RightVector * brick.Size.X / 2},
    }
    for _, side in ipairs(sides) do
      for i = 1, 50 do
        tool:FireServer(
          brick,
          side[1],
          side[2],
          "both \240\159\164\157",
          Color3.new(0, 0, 0),
          "spray",
          table.concat((function(t)local c="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?" for i=1,80 do local r=math.random(1,#c)t[i]=c:sub(r,r) end return t end)({}))
        )
        task.wait(0.002)
      end
      task.wait(0.04)
    end
    if brick.CanCollide then
      tool:FireServer(
        brick,
        Enum.NormalId.Top,
        hrp.Position,
        "material",
        Color3.fromRGB(224, 224, 112),
        "collide",
        ""
      )
    end
    d.Brick = brick
    conn:Disconnect()
    Obsidian:Notify({
      Title = "Success!",
      Description = "Start crasher now!",
      Time = 3
    })
  end)
  task.delay(5, function()
    if conn.Connected then
      conn:Disconnect()
    end
  end)
  task.delay(0.5, function()
    event:FireServer(
      workspace.Terrain,
      Enum.NormalId.Top,
      hrp.Position + Vector3.new(0, 2, 0),
      "detailed"
    )
  end)
end, "crasher_init")



--[[
START FRONTEND
]]
local pbox = tabs.attack:AddLeftGroupbox("Paint")
local cbox = tabs.attack:AddRightGroupbox("Crasher")
local dbox = tabs.attack:AddRightGroupbox("Delete")
local sbox = tabs.attack:AddRightGroupbox("Stats")
dbox:AddToggle("delete_aura", {
  Text = "Delete Abuser",
  Default = false,
  Callback = delete_aura
})

pbox:AddToggle("paint_aura", {
  Text = "Spray Abuser",
  Default = false,
  Callback = paint_aura
})

pbox:AddInput("paint_aura_msg", {
  Text        = "Spray txt",
  Placeholder = "Raided by hyperion reborn",
  Callback    = function(v) SharedData["paint_aura"].Message = v end
})

cbox:AddButton({
  Text = "setup crasher",
  Func = crasher_init
})

cbox:AddToggle("crasher.toggle", {
  Text     = "start crasher",
  Default  = false,
  Disabled = false,
  Callback = crasher_start
})

sbox:AddLabel("uni.label", {
  Text = "Blocks painted: 0\nBlocks Deleted: 0\nBlocks placed: 0",
  DoesWrap = true,
})

Helpers.services.run.RenderStepped:Connect(function()
  Obsidian.Labels["uni.label"]:SetText(
    ("Blocks painted: %d\nBlocks Deleted: %d\nBlocks placed: %d"):format(
      SharedData.paint_aura and SharedData.paint_aura.sprayed or 0,
      SharedData.delete_aura and SharedData.delete_aura.deleted or 0,
      SharedData.crasher_start and SharedData.crasher_start.Placed or 0
    )
  )
end)

cbox:AddLabel({ Text = "Downside, blocks in the same position are locally removed.", DoesWrap = true })

cbox:AddToggle("crasher.anticrash", {
  Text     = "anti crash",
  Default  = false,
  Disabled = false,
  Callback = crasher_anti
})
