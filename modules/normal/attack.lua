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
START FE
]]
local pbox = tabs.attack:AddLeftGroupbox("Paint")
local cbox = tabs.attack:AddLeftGroupbox("Crasher")
local dbox = tabs.attack:AddRightGroupbox("Delete")
local sbox = tabs.attack:AddRightGroupbox("Stats")

dbox:AddToggle("delete_aura@attack.lua", {
  Text = "Delete Aura",
  Default = false
})

pbox:AddToggle("paint_aura@attack.lua", {
  Text = "Spray Aura",
  Default = false
})
pbox:AddInput("paint_msg@attack.lua", {
  Text        = "Spray txt",
  Placeholder = "ez"
})
pbox:AddToggle("paint_unanchor@attack.lua", {
  Text     = "anti crash",
  Default  = false,
  Disabled = false
})
pbox:AddToggle("paint_toxic@attack.lua", {
  Text     = "anti crash",
  Default  = false,
  Disabled = false
})

cbox:AddButton("crasher_init@attack.lua",{
  Text = "setup crasher"
})

cbox:AddToggle("crasher_start@attack.lua", {
  Text     = "start crasher",
  Default  = false,
  Disabled = false
})

cbox:AddLabel({ Text = "Downside, blocks in the same position are locally removed.", DoesWrap = true })

cbox:AddToggle("anticrash@attack.lua", {
  Text     = "anti crash",
  Default  = false,
  Disabled = false,
})

sbox:AddLabel("stats@attack.lua", {
  Text = " ",
  DoesWrap = true,
})
--[[
START BE
]]

local stats = {}
Helpers.services.run.RenderStepped:Connect(function()
  local text = ""
  for _, e in ipairs(stats) do
    text ..= e.name .. ": " .. e.value .. (e.on and " (on)" or " (off)") .. "\n"
  end
  Obsidian.Labels["stats@attack.lua"]:SetText(text)
end)

local Env = {}
local Shared = {}
local Funcs = {}

local function register(fn, name)
  Env[name] = {}
  Shared[name] = {}
  Funcs[name] = function(...)
    task.spawn(fn,Env[name],Shared[name],...)
  end
end

register(function(env, shared, enabled)
  
end,"delete_aura@attack.lua")

register(function(env, shared, enabled)
  
  
end,"")
















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
      local hl = v:FindFirstChild("HyperionHL")
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
  
  while env.loop and task.wait(0.1) do
    local parts = env.pick(30)
    local tool = fetchtool("Delete", env, "loop")
    if not tool then break end   -- FIX: prevent nil tool error when toggled off
    
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
      task.wait(0.05)
      shared.deleted += 1
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
      local hl = v:FindFirstChild("HyperionHL")
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
  while env.loop  do
    local parts = env.pick(30)
    local tool = fetchtool("Paint", env, "loop")
    if not tool then break end   -- FIX: prevent nil tool error when toggled off
    
    -- FIX: default message to avoid nil errors in fix_msg
    local msg = shared.Message or "Raided by hyperion reborn"
    
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
        env.fix_msg(msg)
      )
      shared.sprayed += 1
      task.wait(0.05 + math.random(-30, 30) / 1000)
      local hl = part:FindFirstChild("HyperionHL")
      if hl then hl:Destroy() end
    end
  end
end, "paint_aura")

Env["paint_aura"]["fix_msg"] = function(msg)
  msg = msg or ""
  local advertisements = {
    [[Join Hyperion Reborn!]],
    [[Join Now! \240\159\145\137 xbkVzSxDBy \240\159\145\136]],
    [[Use Hyperion Reborn!]]
  }
  msg = math.random() < 0.6 and msg or advertisements[math.random(#advertisements)]
  if tonumber(msg) then --// isA image
    return msg
  end
  local tags = {}
  return msg:gsub("<font.-</font>", function(tag)
    tags[#tags + 1] = tag
    return "\1" .. #tags .. "\1"
  end):gsub(".", function(c)
    return math.random() < 0.1 and ("<b>" .. c .. "</b>") or c
  end):gsub("\1(%d+)\1", function(i)
    return tags[tonumber(i)]
  end) .. " " .. (function()
    local l = "qwertyuiopsdhjklzxvbnm"
    local _1 = math.random(#l)
    local _2 = math.random(#l)
    local _3 = math.random(#l)
    return l:sub(_1, _1) .. l:sub(_2, _2) .. (math.random() > 0.2 and l:sub(_3,_3) or "")
  end)()
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
    local tool = fetchtool("Paint", (function()
      local c = {}
      return c
      task.delay(3, function()
        c.d = true
      end)
    end)(), "d")
    if not tool then
      break
    end
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
      for i = 1, 25 do
        tool:FireServer(
          brick,
          side[1],
          side[2],
          "both \240\159\164\157",
          Color3.new(0, 0, 0),
          "spray",
          table.concat((function(t)local c="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?" for i=1,math.random(70,80) do local r=math.random(1,#c)t[i]=c:sub(r,r) end return t end)({}))
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
