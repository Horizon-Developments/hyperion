local args = ...
local tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local assets = args.Assets
local Helpers = args.Helpers

tabs.attack = Window:AddTab("Attack", "hand-fist")
local plrs = Helpers.services.players
local localplr = plrs.LocalPlayer

--[[
START BACKEND
]]
local Env = {}
local SharedData = {}


local function bhelper(fn, name)
  Env[name] = {}
  SharedData[name] = {}
  return function(...)
    task.spawn(fn,Env[name],SharedData[name],...)
  end
end

local function fetchtool(tool, tbl, tblv)
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



local delete_aura = bhelper(function(env, shared, enabled)
  shared.deleted = 0
  if env.loop then
    env.loop = nil
  end
  if env.Highlighted then
    for _, v in ipairs(env.Highlighted) do
      local hl = v["HyperionHL"]
      if hl then hl:Destroy() end
    end
  end
  env.Highlighted = {}
  if not env.pick then
    local pool = {}
    local brickIndex = {}
    local function addBrick(brick)
      local i = #pool + 1
      pool[i] = brick
      brickIndex[brick] = i
    end
    local function removeBrick(brick)
      local i = brickIndex[brick]
      if not i then return end
      local last = pool[#pool]
      pool[i] = last
      pool[#pool] = nil
      brickIndex[last] = i
      brickIndex[brick] = nil
    end
    local function watchFolder(folder)
      for _, brick in ipairs(folder:GetChildren()) do
        addBrick(brick)
      end
      folder.ChildAdded:Connect(addBrick)
      folder.ChildRemoved:Connect(removeBrick)
    end
    for _, child in ipairs(workspace.Bricks:GetChildren()) do
      if child:IsA("BasePart") then
        addBrick(child)
      elseif child:IsA("Folder") then
        watchFolder(child)
      end
    end
    workspace.Bricks.ChildAdded:Connect(function(child)
      if child:IsA("Folder") then
        watchFolder(child)
      end
    end)
    workspace.Bricks.ChildRemoved:Connect(function(child)
      if child:IsA("BasePart") then
        removeBrick(child)
      end
    end)

    env.pick = function(k)
      local n = #pool
      k = math.min(k, n)
      if k == n then
        return table.move(pool, 1, n, 1, table.create(n))
      end
      local out = table.create(k)
      local seen = {}
      local count = 0
      while count < k do
        local i = math.random(n)
        if not seen[i] then
          seen[i] = true
          count += 1
          out[count] = pool[i]
        end
      end
      return out
    end
  end
  
  env.loop = enabled
  
  while env.loop and task.wait(0.05) do
    local parts = env.pick(30)
    local tool = fetchtool("Delete", env, "loop")
    
    for _, part in ipairs(parts) do
      local highlight = Instance.new("Highlight")
      highlight.Name = "HyperionHL"
      highlight.Adornee = part
      highlight.FillColor = Color3.fromRGB(255, 0, 0)
      highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
      highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
      highlight.Parent = part
      table.insert(env.Highlighted, part)
    end
    
    for _, part in ipairs(parts) do
      tool:FireServer(part, (localplr.Character or localplr.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart").Position)
      task.wait(0.1)
      shared.deleted += 1
    end

    local remaining = #parts
    if remaining > 0 then
      local completed = Instance.new("BindableEvent")
      for _, part in ipairs(parts) do
        if not part.Parent then
          remaining -= 1
        else
          part.Destroying:Connect(function()
            remaining -= 1
            if remaining == 0 then
              completed:Fire()
            end
          end)
        end
      end
      if remaining > 0 then
        local timeoutThread = task.delay(2, function()
          completed:Fire()
        end)
        completed.Event:Wait()
        task.cancel(timeoutThread)
      end
      completed:Destroy()
    end
  end
end, "delete_aura")


local paint_aura = bhelper(function(env, shared, enabled)
  shared.sprayed = 0
  if env.loop then
    env.loop = nil
  end
  if env.Highlighted then
    for _, v in ipairs(env.Highlighted) do
      local hl = v["HyperionHL"]
      if hl then hl:Destroy() end
    end
  end
  
  env.Highlighted = {}
  if not env.pick then
    local pool = {}
    local brickIndex = {}
    local function addBrick(brick)
      local i = #pool + 1
      pool[i] = brick
      brickIndex[brick] = i
    end
    local function removeBrick(brick)
      local i = brickIndex[brick]
      if not i then return end
      local last = pool[#pool]
      pool[i] = last
      pool[#pool] = nil
      brickIndex[last] = i
      brickIndex[brick] = nil
    end
    local function watchFolder(folder)
      for _, brick in ipairs(folder:GetChildren()) do
        addBrick(brick)
      end
      folder.ChildAdded:Connect(addBrick)
      folder.ChildRemoved:Connect(removeBrick)
    end
    for _, child in ipairs(workspace.Bricks:GetChildren()) do
      if child:IsA("BasePart") then
        addBrick(child)
      elseif child:IsA("Folder") then
        watchFolder(child)
      end
    end
    workspace.Bricks.ChildAdded:Connect(function(child)
      if child:IsA("Folder") then
        watchFolder(child)
      end
    end)
    workspace.Bricks.ChildRemoved:Connect(function(child)
      if child:IsA("BasePart") then
        removeBrick(child)
      end
    end)

    env.pick = function(k)
      local n = #pool
      k = math.min(k, n)
      if k == n then
        return table.move(pool, 1, n, 1, table.create(n))
      end
      local out = table.create(k)
      local seen = {}
      local count = 0
      while count < k do
        local i = math.random(n)
        if not seen[i] then
          seen[i] = true
          count += 1
          out[count] = pool[i]
        end
      end
      return out
    end
  end
  
  env.loop = enabled
  local id = {
      Enum.NormalId.Top,
      Enum.NormalId.Bottom,
      Enum.NormalId.Front,
      Enum.NormalId.Back,
      Enum.NormalId.Left,
      Enum.NormalId.Right,
  }
  while env.loop and task.wait(0.05) do
    local parts = env.pick(30)
    local tool = fetchtool("Paint", env, "loop")
    
    for _, part in ipairs(parts) do
      local highlight = Instance.new("Highlight")
      highlight.Name = "HyperionHL"
      highlight.Adornee = part
      highlight.FillColor = Color3.fromRGB(255, 0, 0)
      highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
      highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
      highlight.Parent = part
      table.insert(env.Highlighted, part)
    end
    
    for _, part in ipairs(parts) do
      tool:FireServer(
        part,
        id[math.random(#id)],
        (localplr.Character or localplr.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart").Position,
        "both \240\159\164\157",
        Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255)),
        "spray",
        env.fix_msg(shared.Message)
      )
      shared.sprayed += 1
      task.wait(0.1)
      local hl = part["HyperionHL"]
      if hl then hl:Destroy() end
    end
  end
end, "paint_aura")

Env["paint_aura"]["fix_msg"] = function(msg)
  local advertisements = {
    [[Join <font color="#FF0000">Hyperion</font> <font color="#FFD700">Reborn</font>]],
    [[Join Now! <font color="#FF0000">xbkVzSxDBy</font>]],
    [[<font color="#FF0000">Hyperion</font> <font color="#FFD700">Reborn</font>]]
  }
  msg = math.random() < 0.6 and msg or advertisements[math.random(#advertisements)]
  if tonumber(msg) then --// isA image
    return msg
  end
  
  
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
      local t = fetchtool("Build", c, "thread")
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
    local tool = fetchtool("Paint")
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
        task.wait(0.1)
      end
      task.wait(0.1)
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
  Text = "Blocks painted: 0\nBlocks Deleted: 0\nBlocks placed: 0\n",
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
