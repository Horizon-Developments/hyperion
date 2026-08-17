
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local HttpService     = game:GetService("HttpService")
local CoreGui         = game:GetService("CoreGui")
local EncodingService = game:GetService("EncodingService")

local LocalPlayer = Players.LocalPlayer

local IsOldVariant   = workspace:FindFirstChild("Cubes") ~= nil
local BlockFolder    = IsOldVariant and workspace:WaitForChild("Cubes") or workspace:WaitForChild("Bricks")
local GridUnitSize   = 4
local DefaultColor   = Color3.fromRGB(192, 192, 192)

local function Compress(data)
  local json = HttpService:JSONEncode(data)
  local compressed = EncodingService:CompressBuffer(buffer.fromstring(json), Enum.CompressionAlgorithm.Zstd, 22)
  return buffer.tostring(compressed)
end

local function Decompress(raw)
  local decompressed = EncodingService:DecompressBuffer(buffer.fromstring(raw), Enum.CompressionAlgorithm.Zstd)
  return HttpService:JSONDecode(buffer.tostring(decompressed))
end

local AxisMap = {
  [Enum.NormalId.Right]  = { Vector3.new( 1, 0, 0), "X" },
  [Enum.NormalId.Top]    = { Vector3.new( 0, 1, 0), "Y" },
  [Enum.NormalId.Back]   = { Vector3.new( 0, 0, 1), "Z" },
  [Enum.NormalId.Left]   = { Vector3.new(-1, 0, 0), "X" },
  [Enum.NormalId.Bottom] = { Vector3.new( 0,-1, 0), "Y" },
  [Enum.NormalId.Front]  = { Vector3.new( 0, 0,-1), "Z" },
}

local NormalIdFromName = {
  Right  = Enum.NormalId.Right,
  Top    = Enum.NormalId.Top,
  Back   = Enum.NormalId.Back,
  Left   = Enum.NormalId.Left,
  Bottom = Enum.NormalId.Bottom,
  Front  = Enum.NormalId.Front,
}

local MatToName = {
  [Enum.Material.SmoothPlastic] = "smooth",   [Enum.Material.Plastic]      = "plastic",
  [Enum.Material.CeramicTiles]  = "tiles",    [Enum.Material.Brick]        = "bricks",
  [Enum.Material.WoodPlanks]    = "planks",   [Enum.Material.Ice]          = "ice",
  [Enum.Material.Grass]         = "grass",    [Enum.Material.Sand]         = "sand",
  [Enum.Material.Snow]          = "snow",     [Enum.Material.Glass]        = "glass",
  [Enum.Material.Wood]          = "wood",     [Enum.Material.Slate]        = "stone",
  [Enum.Material.Pebble]        = "pebble",   [Enum.Material.Marble]       = "marble",
  [Enum.Material.Granite]       = "granite",  [Enum.Material.DiamondPlate] = "steel",
  [Enum.Material.Metal]         = "metal",    [Enum.Material.Asphalt]      = "asphalt",
  [Enum.Material.Concrete]      = "concrete", [Enum.Material.Pavement]     = "pavement",
  [Enum.Material.Neon]          = "neon",
}
local NameToMat = {}
for mat, name in pairs(MatToName) do NameToMat[name] = mat end

local buildDelay   = 0.235
local pingSRTT     = 0
local pingRTTVAR   = 0
local pingSeeded   = false
local GENKEY       = "HyperionAutobuildGen"
local CONNKEY      = "HyperionAutoBuildCon"

if getgenv()[CONNKEY] then
  pcall(function() getgenv()[CONNKEY]:Disconnect() end)
  getgenv()[CONNKEY] = nil
end

local moduleGen = (getgenv()[GENKEY] or 0) + 1
getgenv()[GENKEY] = moduleGen

task.spawn(function()
  while getgenv()[GENKEY] == moduleGen do
    local ok, sample = pcall(function() return LocalPlayer:GetNetworkPing() * 1000 end)
    if ok then
      if not pingSeeded then
        pingSRTT   = sample
        pingRTTVAR = sample / 2
        pingSeeded = true
      else
        pingRTTVAR = 0.75 * pingRTTVAR + 0.25 * math.abs(pingSRTT - sample)
        pingSRTT   = 0.875 * pingSRTT  + 0.125 * sample
      end
      local rto  = pingSRTT + 3.9 * pingRTTVAR
      buildDelay = math.max(0.051, math.min(0.55, rto / 1000))
    end
    task.wait(1)
  end
end)

local function SanitizeJson(s)
  if not s or s == "" then return s end
  s = s:gsub("^\xEF\xBB\xBF", "")
  s = s:gsub("\xC2\xA0", " ")
  s = s:gsub("\xE2\x80[\x8B\x8C\x8D]", "")
  s = s:gsub("\xE2\x80[\x9C\x9D]", '"')
  s = s:gsub("\xE2\x80[\x98\x99]", "'")
  s = s:gsub("[\r\n]+", " "):match("^%s*(.-)%s*$")
  repeat
    local s2 = s:gsub(",%s*([%]%}])", "%1")
    if s2 == s then break end
    s = s2
  until false
  if s:sub(1,1) == "{" and s:sub(-1) == "}" then s = "[" .. s .. "]" end
  return s
end

local DEFAULTS = {
  offset      = Vector3.zero,
  mult        = 1,
  historymax  = 400,
  resizewait  = 0.2,
  wbs         = false,
  maxtry      = 150,
  maxtrydelay = nil,
}

local function SaveBlocks(filePath, playerList)
  local accepted = {}
  for _, p in ipairs(playerList) do
    if typeof(p) == "Instance" and p:IsA("Player") then accepted[p.Name] = true end
  end

  local blocks = {}
  for _, part in ipairs(BlockFolder:GetDescendants()) do
    if not part:IsA("BasePart") then continue end
    if not (part.Parent and accepted[part.Parent.Name]) then continue end

    local sz = part.Size
    local c  = part.Color
    local bd
    if part:FindFirstChild("Input") then
      local txt   = ""
      local label = part:FindFirstChildWhichIsA("GuiObject", true) -- fallback
      local input = part:FindFirstChild("Input")
      if input then
        local lbl = input:FindFirstChild("Label")
        if lbl then txt = lbl.Text or "" end
      end
      bd = {
        type = "sign",
        p    = { part.CFrame:GetComponents() },
        sid  = input and input.Face and input.Face.Name or "Front",
        txt  = txt:gsub('"', '\\"'),
        c    = { math.round(c.R*255), math.round(c.G*255), math.round(c.B*255) },
        id   = part.Name,
      }
    else
      bd = {}
      if (part.CFrame - part.Position) ~= CFrame.new() then
        bd.p = { part.CFrame:GetComponents() }
      else
        local pos = part.Position - sz / 2 + Vector3.new(0.5, 0.5, 0.5)
        bd.p = { pos.X, pos.Y, pos.Z }
      end
      bd.c  = { math.round(c.R*255), math.round(c.G*255), math.round(c.B*255) }
      bd.a  = part.Anchored
      bd.cc = part.CanCollide
      if sz.X ~= GridUnitSize or sz.Y ~= GridUnitSize or sz.Z ~= GridUnitSize then
        if #bd.p == 3 then
          bd.p[1] = (bd.p[1] - sz.X/2) + 0.5
          bd.p[2] = (bd.p[2] - sz.Y/2) + 0.5
          bd.p[3] = (bd.p[3] - sz.Z/2) + 0.5
        end
        bd.s = { sz.X, sz.Y, sz.Z }
      end
      bd.m  = MatToName[part.Material] or "smooth"
      bd.o  = part.Material.Name
      bd.sp = {}
      for _, child in ipairs(part:GetChildren()) do
        if child.Name == "Spray" then
          table.insert(bd.sp, {
            child.Face.Name,
            child.Image and child.Image.Image or "",
            child.Label and child.Label.Text:gsub('"', '\\"') or "",
          })
        end
      end
    end

    table.insert(blocks, bd)
  end

  writefile(filePath, Compress(blocks))
  return #blocks
end

local function CreateSession(filePath, settingsTable, fetchFn, isPreDecoded, fetchTools)
  settingsTable = settingsTable or {}

  local cfg = {
    offset      = settingsTable.offset      or DEFAULTS.offset,
    mult        = settingsTable.mult        or DEFAULTS.mult,
    historymax  = settingsTable.historymax  or DEFAULTS.historymax,
    resizewait  = settingsTable.resizewait  or DEFAULTS.resizewait,
    wbs         = (settingsTable.wbs ~= nil) and settingsTable.wbs or DEFAULTS.wbs,
    maxtry      = settingsTable.maxtry      or DEFAULTS.maxtry,
    maxtrydelay = settingsTable.maxtrydelay or DEFAULTS.maxtrydelay,
  }

  local asyncClients = (type(settingsTable.async) == "table") and settingsTable.async or nil
  local stopped, skip, built, recentBlock, previewPart = false, false, false, nil, nil
  local history, historyIdx = {}, 0
  local runGen, lastState, lastToolWarnTime = 0, nil, 0
  local toolNames = { "Build", "Paint", "Shape", "Delete" }
  local wbsPingHistory, wbsPingIdx, wbsResizewait, wbsSum, wbsCount = {}, 0, cfg.resizewait, 0, 0
  task.spawn(function()
    while getgenv()[GENKEY] == moduleGen do
      task.wait(1)
      if not cfg.wbs then continue end
      local newPing = -199
      local ok = pcall(function()
        for _, v in pairs(CoreGui.RobloxGui.PerformanceStats:GetChildren()) do
          local panel = v:FindFirstChild("StatsMiniTextPanelClass")
          if panel and panel:FindFirstChild("TitleLabel") and panel:FindFirstChild("ValueLabel")
            and panel.TitleLabel.Text == "Ping" then
            local raw = panel.ValueLabel.Text
            local ms  = string.find(raw, " ms")
            if ms then newPing = tonumber(string.sub(raw, 1, ms - 1)) end
          end
        end
      end)
      if not ok or newPing == -199 then
        pcall(function() newPing = LocalPlayer:GetNetworkPing() * 1000 end)
      end
      if newPing and newPing > 0 then
        wbsPingIdx = (wbsPingIdx % 5) + 1
        local multi = newPing > 500 and 2.2 or newPing > 250 and 2.5 or 2.7
        local old = wbsPingHistory[wbsPingIdx]
        if old then wbsSum = wbsSum - old else wbsCount = wbsCount + 1 end
        local new = newPing * multi
        wbsPingHistory[wbsPingIdx] = new
        wbsSum = wbsSum + new
        wbsResizewait  = (wbsSum / wbsCount) / 1000
        cfg.resizewait = wbsResizewait
      end
    end
  end)

  local POS_TOL   = 0.75
  local SIZE_TOL  = 0.75
  local COLOR_TOL = 0.02

  local totalBlocks, verifiedBlocks, buildStart = 0, 0, 0
  local stats = { total = 0, done = 0, elapsed = 0, eta = nil, ping = 0 }

  local function updateStats()
    stats.total = totalBlocks
    stats.done  = verifiedBlocks
    stats.ping  = math.floor(pingSRTT)
    if buildStart > 0 then
      stats.elapsed = tick() - buildStart
      if stats.done > 2 and stats.total > 0 then
        stats.eta = stats.elapsed / stats.done * (stats.total - stats.done)
      end
    end
  end
  local highlight = Instance.new("Highlight")
  highlight.Parent              = CoreGui
  highlight.FillColor           = Color3.fromRGB(0, 200, 255)
  highlight.FillTransparency    = 0.5
  highlight.OutlineColor        = Color3.fromRGB(0, 200, 255)
  highlight.OutlineTransparency = 0
  local function log(msg) warn("[AutoBuild] " .. tostring(msg)) end
  local function delay() return cfg.maxtrydelay or buildDelay end

  local function snapToGrid(pos, mult)
    mult = mult or GridUnitSize
    return Vector3.new(
      math.round((pos.X - 2) / mult) * mult + 2,
      math.round((pos.Y - 2) / mult) * mult + 2,
      math.round((pos.Z - 2) / mult) * mult + 2
    )
  end

  local function vecClose(a, b, tol)
    return math.abs(a.X-b.X) <= tol and math.abs(a.Y-b.Y) <= tol and math.abs(a.Z-b.Z) <= tol
  end
  local function colorClose(a, b)
    return math.abs(a.R-b.R) <= COLOR_TOL and math.abs(a.G-b.G) <= COLOR_TOL and math.abs(a.B-b.B) <= COLOR_TOL
  end
  local function cornerToCenter(corner, sz)
    if not sz then return corner end
    return Vector3.new(corner.X + sz.X/2 - 0.5, corner.Y + sz.Y/2 - 0.5, corner.Z + sz.Z/2 - 0.5)
  end
  local function equipTool(name)
    local char = LocalPlayer.Character
    if not char then return nil end
    local inChar = char:FindFirstChild(name)
    if inChar and inChar:IsA("Tool") then return inChar end
    local bp   = LocalPlayer:FindFirstChildOfClass("Backpack")
    local tool = bp and bp:FindFirstChild(name)
    if tool and tool:IsA("Tool") then
      pcall(function()
        if tool:FindFirstChild("Script") and tool.Script:IsA("LocalScript") then
          tool.Script.Disabled = false
        end
        tool.Parent = char
      end)
      return char:FindFirstChild(name)
    end
    return nil
  end

  local function grabToolFromWorkspace(name)
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not bp or bp:FindFirstChild(name) then return end
    local t = workspace:FindFirstChild(name)
    if t and t:IsA("Tool") then pcall(function() t:Clone().Parent = bp end) end
  end

  local function ensureTools(warn_missing)
    local hasBuild = false
    for _, name in ipairs(toolNames) do
      if not equipTool(name) then grabToolFromWorkspace(name); equipTool(name) end
      if name == "Build" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Build") then
        hasBuild = true
      end
    end
    if not hasBuild and warn_missing then
      local now = os.clock()
      if now - lastToolWarnTime > 6 then
        lastToolWarnTime = now
        log("Build tool missing. Grant yourself bkit, then retry.")
      end
    end
    return hasBuild
  end
  local function partMatches(part, center, sz)
    return part and part:IsA("BasePart")
        and vecClose(part.Position, center, POS_TOL)
        and vecClose(part.Size,     sz,     SIZE_TOL)
  end

  local function findBlock(center, sz)
    if not BlockFolder or not BlockFolder.Parent then return nil end
    local searchSz = sz or Vector3.new(GridUnitSize, GridUnitSize, GridUnitSize)
    local ok, hits = pcall(function()
      local p = OverlapParams.new()
      p.FilterType = Enum.RaycastFilterType.Include
      p.FilterDescendantsInstances = { BlockFolder }
      p.MaxParts = 30
      return workspace:GetPartBoundsInBox(CFrame.new(center), searchSz + Vector3.new(1,1,1), p)
    end)
    if ok and hits then
      for _, part in ipairs(hits) do
        if partMatches(part, center, searchSz) then return part end
      end
      return nil
    end
    for _, part in ipairs(BlockFolder:GetDescendants()) do
      if partMatches(part, center, searchSz) then return part end
    end
    return nil
  end

  local function blockVerified(center, sz, color, mat, anchored, collide)
    local part = findBlock(center, sz)
    if not part then return false end
    if color    and not colorClose(part.Color, color)     then return false end
    if mat      and part.Material ~= mat                  then return false end
    if anchored ~= nil and part.Anchored   ~= anchored    then return false end
    if collide  ~= nil and part.CanCollide ~= collide     then return false end
    return true
  end
  local function makePreview(pos, sz, color, mat, transp, anchored, collide, sprays)
    if typeof(pos) == "CFrame" then pos = pos.Position end
    local p = Instance.new("Part")
    previewPart      = p
    p.Anchored       = anchored ~= false
    p.CanCollide     = collide or false
    p.CastShadow     = false
    p.CanQuery       = false
    p.Color          = color
    p.Transparency   = transp or 0.5
    p.Material       = mat or Enum.Material.SmoothPlastic
    p.Size           = sz or Vector3.new(GridUnitSize, GridUnitSize, GridUnitSize)
    if sz then
      pos = Vector3.new(pos.X + sz.X/2 - 0.5, pos.Y + sz.Y/2 - 0.5, pos.Z + sz.Z/2 - 0.5)
    end
    p.CFrame = CFrame.new(pos)
    if sprays then
      for _, spray in pairs(sprays) do
        local face    = Enum.NormalId[spray[1]]
        local payload = spray[3] or ""
        local gui     = Instance.new("SurfaceGui")
        gui.Face          = face
        gui.SizingMode    = Enum.SurfaceGuiSizingMode.PixelsPerStud
        gui.PixelsPerStud = 50
        local _, hashCount = string.gsub(payload, "#", "l")
        if hashCount == #payload then
          local img = Instance.new("ImageLabel", gui)
          img.Image = spray[2]; img.BackgroundTransparency = 1; img.Size = UDim2.new(1,0,1,0)
        else
          local lbl = Instance.new("TextLabel", gui)
          lbl.Text = payload; lbl.BackgroundTransparency = 1; lbl.TextScaled = true
          lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = Enum.Font.FredokaOne; lbl.Size = UDim2.new(1,0,1,0)
        end
        gui.Parent = p
      end
    end
    p.Parent = workspace
    return p
  end
  local function fireEvent(toolName, args)
    pcall(function()
      if fetchTools then
        local event = fetchTools(toolName)
        if event == nil then return end
        if typeof(event) == "Instance" and event:IsA("BindableFunction") then
          event:Invoke(table.unpack(args))
        else
          event:FireServer(table.unpack(args))
        end
        return
      end
      local char = LocalPlayer.Character
      if not char then return end
      local tool = char:FindFirstChild(toolName)
      if not tool then
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        local bt = bp and bp:FindFirstChild(toolName)
        if bt then bt.Parent = char end
        tool = char:FindFirstChild(toolName)
      end
      if not tool then return end
      local bind = tool:FindFirstChild("origevent")
      if bind then bind:Invoke(table.unpack(args))
      else tool.Script.Event:FireServer(table.unpack(args)) end
    end)
  end

  local function fireBuild(args) fireEvent("Build", args) end
  local function firePaint(args) fireEvent("Paint", args) end
  local function onBlockAdded(child)
    if not child:IsA("BasePart") then return end
    recentBlock = child
    historyIdx  = (historyIdx % cfg.historymax) + 1
    history[historyIdx] = child
    built = true
  end

  do
    if not BlockFolder:FindFirstChild(LocalPlayer.Name) then
      ensureTools(true)
      local probe = Vector3.new(6777, 6969, 6777)
      repeat
        fireBuild({ workspace.Terrain, Enum.NormalId.Top, probe, "normal" })
        task.wait(0.2)
      until BlockFolder:FindFirstChild(LocalPlayer.Name) or getgenv()[GENKEY] ~= moduleGen
    end
    local conn = BlockFolder[LocalPlayer.Name].ChildAdded:Connect(onBlockAdded)
    getgenv()[CONNKEY] = conn
  end
  local tpTarget = nil
  task.spawn(function()
    while not stopped or tpTarget do
      if tpTarget then
        pcall(function()
          LocalPlayer.Character.HumanoidRootPart.CFrame =
            typeof(tpTarget) == "CFrame" and tpTarget or CFrame.new(tpTarget)
        end)
      end
      task.wait(0.01)
      if stopped and not tpTarget then break end
    end
  end)

  local function teleportTo(pos)
    tpTarget = pos
    task.wait(0.01)
  end

  local function stopTeleport()
    tpTarget = nil
  end
  local function buildSign(signData, xform)
    local cf  = CFrame.new(table.unpack(signData.p))
    local pos = cf.Position + (xform and xform.offset or Vector3.zero)

    local normalId    = NormalIdFromName[signData.sid] or Enum.NormalId.Front
    local faceDir     = cf:VectorToWorldSpace(AxisMap[normalId][1])
    local standPos    = pos + faceDir * 3
    local up          = math.abs(faceDir:Dot(Vector3.yAxis)) > 0.99 and Vector3.zAxis or Vector3.yAxis
    local standCFrame = CFrame.lookAt(standPos, pos, up)
    local searchPos   = pos - faceDir * 4

    local ref, refNormal = workspace.Terrain, Enum.NormalId.Top

    built = false; recentBlock = nil
    local tries = 0
    repeat
      tries = tries + 1
      teleportTo(standCFrame)
      task.wait(0.3)
      fireEvent("Sign", { ref, refNormal, Vector3.new(pos.X, pos.Y - 1, pos.Z) })
    until built or stopped or skip or tries > 10
    stopTeleport()

    if recentBlock and signData.txt and signData.txt ~= "" then
      task.wait(0.3)
      pcall(function()
        recentBlock:WaitForChild("Input"):WaitForChild("Label"):WaitForChild("Script"):WaitForChild("Event"):FireServer(signData.txt)
      end)
    end

    if recentBlock and signData.c then
      local color    = Color3.fromRGB(table.unpack(signData.c))
      local paintPos = recentBlock.Position + recentBlock.Size / 2
      local eargs    = { recentBlock, Enum.NormalId.Top, paintPos, "color", color, "tiles", "" }
      local pc = 0
      repeat
        pc = pc + 1
        firePaint(eargs)
        teleportTo(pos)
        task.wait(0.2)
      until not recentBlock or not recentBlock.Parent
          or recentBlock.Color == color
          or stopped or skip or pc > 20
      stopTeleport()
    end

    built = false; recentBlock = nil; skip = false
  end
  local function placeBlock(pos, matName, color, sizeMode, sizeVec, isPremade, origMat, sprays, anchored, collide)
    if anchored == nil then anchored = true end
    if collide  == nil then collide  = true end
    local needsResize = false

    pcall(function()
      pcall(function() LocalPlayer.Backpack.Build.Parent = LocalPlayer.Character end)
      local adjFound, retries = false, 0
      recentBlock = nil
      if #history > 0 and previewPart then
        local candidates = {}
        for idx = 1, cfg.historymax do
          local hb = history[idx]
          if hb == nil or hb.Parent == nil then history[idx] = nil; continue end
          if previewPart.Size ~= hb.Size then continue end
          local minDim = math.min(hb.Size.X, hb.Size.Y, hb.Size.Z)
          local tol = hb.Anchored and 0.01 or math.min(0.75, minDim * 0.25)
          for nid, ax in pairs(AxisMap) do
            local adjPos = hb.Position + ax[1] * hb.Size[ax[2]]
            local diff = adjPos - previewPart.Position
            if diff.X*diff.X + diff.Y*diff.Y + diff.Z*diff.Z <= tol*tol then
              local entry = { nid, hb, hb.Position + ax[1] * hb.Size[ax[2]] / 2 }
              table.insert(candidates, entry)
              adjFound = entry
            end
          end
        end
        if #candidates > 1 and color and adjFound and adjFound[2].Color ~= color then
          for _, c in pairs(candidates) do
            if c[2].Color == color then adjFound = c end
          end
        end

        if adjFound and adjFound[2] and adjFound[2].Parent then
          local origPos = pos
          local args    = { adjFound[2], adjFound[1], adjFound[3] or previewPart.Position, "normal" }
          built = false; recentBlock = nil; retries = 0
          repeat
            retries = retries + 1
            fireBuild(args)
            pcall(function()
              pos = adjFound[3] or pos
              teleportTo(pos)
            end)
            RunService.Heartbeat:Wait()
          until (built and recentBlock) or adjFound[2] == nil or adjFound[2].Parent == nil
              or stopped or skip or retries > cfg.maxtry
          stopTeleport()
          if adjFound[2] == nil or adjFound[2].Parent == nil or retries > cfg.maxtry then
            adjFound = false
          else
            if previewPart then previewPart:Destroy() end
          end
          pos = origPos
        end
      end
      -- Toggle CanCollide on an existing block via the Paint tool's "collide" action,
      -- run fn(), then restore original collision state. Used to pass a temp block
      -- through an obstruction at a step position without leaving world state changed.
      local function withNoCollide(obstruct, fn)
        if not obstruct or not obstruct.Parent then return fn() end
        local origCollide = obstruct.CanCollide
        if origCollide == false then return fn() end
        local function setCollide(target, value)
          pcall(function() LocalPlayer.Backpack.Paint.Parent = LocalPlayer.Character end)
          local cp   = target.Position + target.Size / 2
          local args = { target, Enum.NormalId.Top, cp, "material", nil, "collide", "" }
          local r = 0
          repeat
            r = r + 1
            if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("Paint")
              and LocalPlayer.Backpack:FindFirstChild("Paint") then
              LocalPlayer.Backpack.Paint.Parent = LocalPlayer.Character
            end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Paint")
              and target and target.Parent and target.CanCollide ~= value then
              firePaint(args)
            end
            task.wait(math.max(0.03, delay()))
          until not target or not target.Parent or target.CanCollide == value
              or stopped or skip or r > cfg.maxtry
        end
        setCollide(obstruct, false)
        local ok, result = pcall(fn)
        if obstruct and obstruct.Parent then setCollide(obstruct, true) end
        if not ok then return nil end
        return result
      end

      -- Fire a single build step from `fromPart` toward `facePos`, returning the
      -- newly built part or nil. If an existing block occupies the target spot,
      -- temporarily disable its collision so the step can pass through it.
      local function stepBuild(fromPart, nid, facePos)
        local obstruct = findBlock(facePos, fromPart.Size)
        local function attempt()
          built = false; recentBlock = nil
          local r = 0
          repeat
            r = r + 1
            fireBuild({ fromPart, nid, facePos, "normal" })
            pcall(function() teleportTo(facePos) end)
            RunService.Heartbeat:Wait()
          until (built and recentBlock) or fromPart.Parent == nil or stopped or skip or r > cfg.maxtry
          return (built and recentBlock) and recentBlock or nil
        end
        if obstruct and obstruct.Parent then
          return withNoCollide(obstruct, attempt)
        end
        return attempt()
      end

      -- Delete a temp block via the Delete tool, retrying until the SERVER
      -- confirms removal (temp.Parent == nil). This never calls :Destroy()
      -- locally — a client-side destroy only removes the instance from our
      -- own view; the server still thinks the block exists, so it would
      -- still be solid/visible to everyone else and still poison future
      -- adjacency scans on the server's copy of the world. If the Delete
      -- tool round-trip genuinely can't get a confirmation, the block is
      -- left in place and logged rather than faked away.
      local function deleteTemp(temp)
        if not temp then return end
        local r = 0
        repeat
          r = r + 1
          pcall(function()
            if not temp or not temp.Parent then return end
            if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("Delete")
              and LocalPlayer.Backpack:FindFirstChild("Delete") then
              LocalPlayer.Backpack.Delete.Parent = LocalPlayer.Character
            end
            local del = LocalPlayer.Character:FindFirstChild("Delete") or LocalPlayer.Backpack:FindFirstChild("Delete")
            if del then
              local bind = del:FindFirstChild("origevent")
              if bind then bind:Invoke(temp, Enum.NormalId.Top, temp.Position, "")
              elseif del:FindFirstChild("Script") then del.Script.Event:FireServer(temp, Enum.NormalId.Top, temp.Position, "")
              end
            end
          end)
          task.wait(math.max(0.03, delay()))
        until not temp or not temp.Parent or stopped or skip or r > cfg.maxtry
        if temp and temp.Parent then
          log("WARNING: temp block at " .. tostring(temp.Position) .. " could not be confirmed deleted after " .. cfg.maxtry .. " tries; left in place.")
        end
      end

      if adjFound == false and #history > 0 and previewPart then
        local nb, hops = nil, nil
        local tgt = previewPart.Position

        for idx = 1, cfg.historymax do
          local hb = history[idx]
          if hb == nil or hb.Parent == nil then history[idx] = nil; continue end
          if previewPart.Size ~= hb.Size then continue end
          local minDim = math.min(hb.Size.X, hb.Size.Y, hb.Size.Z)
          local tol = hb.Anchored and 0.01 or math.min(0.75, minDim * 0.25)
          local d = tgt - hb.Position
          local off = (math.abs(d.X)>tol and 1 or 0)+(math.abs(d.Y)>tol and 1 or 0)+(math.abs(d.Z)>tol and 1 or 0)
          if off ~= 2 and off ~= 3 then continue end

          if off == 2 then
            -- 2-axis face diagonal: one intermediate hop
            for nid1, ax1 in pairs(AxisMap) do
              local mid = hb.Position + ax1[1] * hb.Size[ax1[2]]
              for nid2, ax2 in pairs(AxisMap) do
                local diff = mid + ax2[1] * hb.Size[ax2[2]] - tgt
                if diff.X*diff.X + diff.Y*diff.Y + diff.Z*diff.Z < 0.0225 then
                  nb = hb; hops = { nid1, nid2 }; break
                end
              end
              if hops then break end
            end
          else
            -- 3-axis corner diagonal: two intermediate hops
            for nid1, ax1 in pairs(AxisMap) do
              local mid1 = hb.Position + ax1[1] * hb.Size[ax1[2]]
              for nid2, ax2 in pairs(AxisMap) do
                local mid2 = mid1 + ax2[1] * hb.Size[ax2[2]]
                for nid3, ax3 in pairs(AxisMap) do
                  local diff = mid2 + ax3[1] * hb.Size[ax3[2]] - tgt
                  if diff.X*diff.X + diff.Y*diff.Y + diff.Z*diff.Z < 0.0225 then
                    nb = hb; hops = { nid1, nid2, nid3 }; break
                  end
                end
                if hops then break end
              end
              if hops then break end
            end
          end
          if hops then break end
        end

        if nb and nb.Parent and hops then
          local temps = {}
          local cur   = nb
          local okAll = true

          for i = 1, #hops do
            local nid  = hops[i]
            local face = cur.Position + AxisMap[nid][1] * cur.Size[AxisMap[nid][2]] / 2
            local isLast = (i == #hops)
            local produced = stepBuild(cur, nid, face)
            if not produced or stopped or skip then
              okAll = false
              break
            end
            if not isLast then
              table.insert(temps, produced)
            else
              -- final hop produced the real block
              for _, t in ipairs(temps) do deleteTemp(t) end
              adjFound    = { nid, cur, face }
              recentBlock = produced
              if previewPart then previewPart:Destroy() end
            end
            cur = produced
          end

          if not okAll then
            for _, t in ipairs(temps) do deleteTemp(t) end
            adjFound = false; recentBlock = nil
          end
        end
      end
      if adjFound == false then
        if sizeMode == nil then
          sizeMode = "normal"
          if LocalPlayer.PlayerGui:FindFirstChild("Build") and LocalPlayer.PlayerGui.Build:FindFirstChild("Button") then
            sizeMode = LocalPlayer.PlayerGui.Build.Button.Text
          end
          if sizeVec and (sizeVec.X ~= GridUnitSize or sizeVec.Y ~= GridUnitSize or sizeVec.Z ~= GridUnitSize) then
            sizeMode = "detailed"
          elseif sizeVec then
            sizeMode = "normal"
          end
          if not sizeVec and sizeMode ~= "detailed" and previewPart
            and previewPart.Position ~= snapToGrid(pos, previewPart.Size.X) then
            sizeMode   = "detailed"
            needsResize = true
            sizeVec    = previewPart.Size
            pos = Vector3.new(
              pos.X - sizeVec.X/2 + 0.5,
              pos.Y - sizeVec.Y/2 + 0.5,
              pos.Z - sizeVec.Z/2 + 0.5
            )
          end
        end
        local args = { workspace.Terrain, Enum.NormalId.Top, pos, sizeMode or "normal" }
        built = false
        fireBuild(args)
        retries = 0
        repeat
          retries = retries + 1
          if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("Build")
            and LocalPlayer.Backpack:FindFirstChild("Build") then
            LocalPlayer.Backpack.Build.Parent = LocalPlayer.Character
          end
          if LocalPlayer.Character:FindFirstChild("Build") then fireBuild(args) end
          pcall(function() teleportTo(pos + Vector3.new(0, 6, 0)) end)
          RunService.Heartbeat:Wait()
        until (built and recentBlock) or stopped or skip or retries > cfg.maxtry
        stopTeleport()
        built = false; retries = 0
      end
      if recentBlock and typeof(color) == "Color3"
        and (LocalPlayer.Backpack:FindFirstChild("Paint") or LocalPlayer.Character:FindFirstChild("Paint"))
      then
        local paintPos  = recentBlock.Position + recentBlock.Size / 2
        local paintArgs = { recentBlock, Enum.NormalId.Top, paintPos, "color", color, "tiles", "" }
        pcall(function() LocalPlayer.Backpack.Paint.Parent = LocalPlayer.Character end)
        if matName then
          paintArgs[4] = color == nil and "material" or "both \u{1F91D}"
          paintArgs[6] = matName
        end
        if not recentBlock then if previewPart then previewPart:Destroy() end; return end
        highlight.Adornee = recentBlock; retries = 0
        pcall(function()
          repeat
            retries = retries + 1
            if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("Paint")
              and LocalPlayer.Backpack:FindFirstChild("Paint") then
              LocalPlayer.Backpack.Paint.Parent = LocalPlayer.Character
            end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Paint") then
              firePaint(paintArgs)
            end
            pcall(function() teleportTo(paintPos + Vector3.new(0, 6, 0)) end)
            RunService.Heartbeat:Wait()
          until not recentBlock or not recentBlock.Parent
              or recentBlock.Color == color
              or (matName and recentBlock.Material == Enum.Material[origMat])
              or stopped or skip or retries > 250
        end)
      end
      if recentBlock and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Paint")
        and recentBlock.Anchored ~= anchored then
        local ap   = recentBlock.Position + recentBlock.Size / 2
        local args = { recentBlock, Enum.NormalId.Top, ap, "material", nil, "anchor", "" }
        retries = 0
        repeat
          retries = retries + 1
          if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("Paint")
            and LocalPlayer.Backpack:FindFirstChild("Paint") then
            LocalPlayer.Backpack.Paint.Parent = LocalPlayer.Character
          end
          if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Paint")
            and recentBlock and recentBlock.Anchored ~= anchored then
            firePaint(args)
          end
          pcall(function() teleportTo(ap + Vector3.new(0, 8, 0)) end)
          task.wait(0.15)
        until not recentBlock or not recentBlock.Parent or recentBlock.Anchored == anchored
            or not LocalPlayer.Character
            or (not LocalPlayer.Character:FindFirstChild("Paint") and not LocalPlayer.Backpack:FindFirstChild("Paint"))
            or stopped or skip or retries > 12
      end
      if recentBlock and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Paint")
        and recentBlock.CanCollide ~= collide then
        local cp   = recentBlock.Position + recentBlock.Size / 2
        local args = { recentBlock, Enum.NormalId.Top, cp, "material", nil, "collide", "" }
        retries = 0
        repeat
          retries = retries + 1
          if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("Paint")
            and LocalPlayer.Backpack:FindFirstChild("Paint") then
            LocalPlayer.Backpack.Paint.Parent = LocalPlayer.Character
          end
          if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Paint")
            and recentBlock and recentBlock.CanCollide ~= collide then
            firePaint(args)
          end
          pcall(function() teleportTo(cp + Vector3.new(0, 8, 0)) end)
          task.wait(0.15)
        until not recentBlock or not recentBlock.Parent or recentBlock.CanCollide == collide
            or not LocalPlayer.Character
            or (not LocalPlayer.Character:FindFirstChild("Paint") and not LocalPlayer.Backpack:FindFirstChild("Paint"))
            or stopped or skip or retries > 12
      end

      highlight.Adornee = nil
      if recentBlock and (LocalPlayer.Backpack:FindFirstChild("Paint") or LocalPlayer.Character:FindFirstChild("Paint"))
        and sprays then
        local sprayArgs = { recentBlock, Enum.NormalId.Front, recentBlock.Position + Vector3.new(1,0,0), "material", nil, "spray", "ha" }
        for _, s in pairs(sprays) do
          sprayArgs[2] = Enum.NormalId[s[1]]
          local payload = s[3]
          if (not payload or payload == "") and type(s[2]) == "string" and s[2] ~= "" then payload = s[2] end
          sprayArgs[7] = payload or ""
          if recentBlock and (LocalPlayer.Backpack:FindFirstChild("Paint") or LocalPlayer.Character:FindFirstChild("Paint"))
            and not stopped and not skip then
            pcall(function() LocalPlayer.Backpack.Paint.Parent = LocalPlayer.Character end)
            pcall(function()
              task.wait(0.25)
              firePaint(sprayArgs)
            end)
          end
        end
      end
      if recentBlock
        and ((sizeVec and (sizeVec.X ~= GridUnitSize or sizeVec.Y ~= GridUnitSize or sizeVec.Z ~= GridUnitSize)) or needsResize)
        and (LocalPlayer.Character:FindFirstChild("Shape") or LocalPlayer.Backpack:FindFirstChild("Shape"))
      then
        if not LocalPlayer.Character:FindFirstChild("Shape") and LocalPlayer.Backpack:FindFirstChild("Shape") then
          LocalPlayer.Backpack.Shape.Parent = LocalPlayer.Character
        end
        local resizeArgs = { recentBlock, Enum.NormalId.Right, "", "" }
        local function resizeAxis(axisName, target)
          if not (recentBlock and recentBlock.Size[axisName] ~= target) then return end
          retries = 0
          repeat
            retries = retries + 1
            local rpos = (recentBlock and recentBlock.Position + recentBlock.Size / 2) or pos
            resizeArgs[3] = rpos; resizeArgs[4] = nil
            if recentBlock then
              if   recentBlock.Size[axisName] > target then resizeArgs[4] = "decrease"
              elseif recentBlock.Size[axisName] < target then resizeArgs[4] = "increase" end
            end
            if not LocalPlayer.Character:FindFirstChild("Shape") and LocalPlayer.Backpack:FindFirstChild("Shape") then
              LocalPlayer.Backpack.Shape.Parent = LocalPlayer.Character
            end
            if LocalPlayer.Character:FindFirstChild("Shape") then
              pcall(function()
                local bind = LocalPlayer.Character.Shape:FindFirstChild("origevent")
                if bind then bind:Invoke(table.unpack(resizeArgs))
                else LocalPlayer.Character.Shape.Script.Event:FireServer(table.unpack(resizeArgs)) end
              end)
            end
            pcall(function() teleportTo(rpos + Vector3.new(0, 6, 0)) end)
            task.wait(cfg.resizewait)
          until resizeArgs[4] == nil
              or (resizeArgs[4] == "decrease" and recentBlock and recentBlock.Size[axisName] <= 1)
              or (recentBlock and recentBlock.Size[axisName] == target)
              or stopped or skip
              or retries > (target * 3) / cfg.resizewait
        end
        resizeArgs[2] = Enum.NormalId.Right; resizeAxis("X", sizeVec.X)
        resizeArgs[2] = Enum.NormalId.Top;   resizeAxis("Y", sizeVec.Y)
        resizeArgs[2] = Enum.NormalId.Back;  resizeAxis("Z", sizeVec.Z)
      end
      skip = false
    end)
    if previewPart then previewPart:Destroy() end
    recentBlock = nil
  end
  local function applyTransform(rawPos, sz, xform)
    if not xform or not xform.enabled then return rawPos end
    local half  = Vector3.new(sz.X/2-0.5, sz.Y/2-0.5, sz.Z/2-0.5)
    local center = rawPos + half
    center = (xform.center or Vector3.zero)
           + (xform.rotation or CFrame.identity) * (center - (xform.center or Vector3.zero))
           + (xform.offset   or Vector3.zero)
    return center - half
  end

  local function resolveBlock(entry, xform)
    local posArr = entry and (entry.p or entry.pos); if not posArr then return nil end
    local szArr  = entry.s or entry.size
    local sz     = szArr and Vector3.new(table.unpack(szArr)) or Vector3.new(GridUnitSize, GridUnitSize, GridUnitSize)
    local raw    = Vector3.new(posArr[1], posArr[2], posArr[3]) * cfg.mult
    local tpos   = applyTransform(raw, sz, xform)
    local color  = (entry.c or entry.color) and Color3.fromRGB(table.unpack(entry.c or entry.color)) or DefaultColor
    local mname  = entry.m or entry.mat
    local omat   = entry.o or entry.origmat
    local menum  = NameToMat[mname] or Enum.Material.SmoothPlastic
    if not NameToMat[mname] and omat then
      pcall(function() menum = Enum.Material[omat] or menum end)
    end
    local center = szArr and cornerToCenter(tpos, sz) or tpos
    return {
      pos = tpos, size = sz, color = color, matName = mname,
      expectMat = menum, center = center,
      anchored = entry.a, collide = entry.cc,
    }
  end

  local function placeAndVerify(entry, xform)
    if entry.type == "sign" then
      ensureTools(true)
      buildSign(entry, xform)
      return true -- signs don't verify by position
    end
    local r = resolveBlock(entry, xform)
    if not r then return true end
    if blockVerified(r.center, r.size, r.color, r.expectMat, r.anchored, r.collide) then return true end
    ensureTools(true)
    makePreview(r.pos, r.size, r.color, r.expectMat)
    placeBlock(r.pos, r.matName, r.color, nil, r.size, true, entry.o or entry.origmat,
               entry.sp or entry.sprayed, r.anchored, r.collide)
    task.wait(math.max(0.03, delay()))
    return blockVerified(r.center, r.size, r.color, r.expectMat, r.anchored, r.collide)
  end
  local function sortByAdjacency(blocks)
    local ref
    local spawn = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("Spawn")
    if spawn then
      if spawn:IsA("Model") then
        local root = spawn:FindFirstChildOfClass("HumanoidRootPart")
        if root then ref = root.Position end
      elseif spawn:IsA("BasePart") then
        ref = spawn.Position
      end
    end
    if not ref then
      for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
          local root = p.Character:FindFirstChild("HumanoidRootPart")
          if root then ref = root.Position; break end
        end
      end
    end
    ref = ref or Vector3.new(0, 100, 0)

    local n = #blocks
    if n <= 1 then return blocks end
    local centers, sizes = {}, {}
    for i, b in ipairs(blocks) do
      local pa = b.p or b.pos
      local bp
      if pa then
        bp = Vector3.new(pa[1], pa[2], pa[3])
        local sa = b.s or b.size
        if sa then bp = Vector3.new(bp.X+sa[1]/2-0.5, bp.Y+sa[2]/2-0.5, bp.Z+sa[3]/2-0.5) end
        sizes[i] = sa and Vector3.new(sa[1], sa[2], sa[3]) or Vector3.new(GridUnitSize, GridUnitSize, GridUnitSize)
      else
        bp = Vector3.new(math.huge, math.huge, math.huge)
        sizes[i] = Vector3.new(GridUnitSize, GridUnitSize, GridUnitSize)
      end
      centers[i] = bp
    end
    local cellSize   = GridUnitSize
    local bigThresh  = cellSize * 4  -- anything larger than this in any axis is "big"
    local cellRadius = 2             -- fixed, cheap radius for normal-size blocks
    local function cellKey(pos)
      local x = math.floor(pos.X / cellSize)
      local y = math.floor(pos.Y / cellSize)
      local z = math.floor(pos.Z / cellSize)
      return bit32.bxor(bit32.bxor(x * 92837111, y * 689287499), z * 283923481)
    end
    local buckets, bigList, isBig = {}, {}, {}
    for i = 1, n do
      local maxDim = math.max(sizes[i].X, sizes[i].Y, sizes[i].Z)
      if maxDim > bigThresh then
        bigList[#bigList+1] = i
        isBig[i] = true
      else
        local key = cellKey(centers[i])
        if not buckets[key] then buckets[key] = {} end
        table.insert(buckets[key], i)
      end
    end
    local abs = math.abs
    local function isAdjacent(i, j)
      local ci, cj = centers[i], centers[j]
      local si, sj = sizes[i], sizes[j]
      return abs(ci.X-cj.X) <= (si.X+sj.X)*0.5 + 0.6
         and abs(ci.Y-cj.Y) <= (si.Y+sj.Y)*0.5 + 0.6
         and abs(ci.Z-cj.Z) <= (si.Z+sj.Z)*0.5 + 0.6
    end
    local function candidates(i, out)
      if isBig[i] then
        for j = 1, n do
          if j ~= i then out[#out+1] = j end
        end
        return
      end
      local base = centers[i]
      local bx, by, bz = math.floor(base.X/cellSize), math.floor(base.Y/cellSize), math.floor(base.Z/cellSize)
      for dx = -cellRadius, cellRadius do
        for dy = -cellRadius, cellRadius do
          for dz = -cellRadius, cellRadius do
            local bucket = buckets[bit32.bxor(bit32.bxor((bx+dx)*92837111,(by+dy)*689287499),(bz+dz)*283923481)]
            if bucket then
              for _, j in ipairs(bucket) do
                if j ~= i then out[#out+1] = j end
              end
            end
          end
        end
      end
      for _, j in ipairs(bigList) do
        if j ~= i then out[#out+1] = j end
      end
    end

    local visited = {}
    local order = {}
    local scratch = {}
    local distToRef = {}
    for i = 1, n do distToRef[i] = (centers[i] - ref).Magnitude end

    local byDist = {}
    for i = 1, n do byDist[i] = i end
    table.sort(byDist, function(a, b) return distToRef[a] < distToRef[b] end)
    local byDistCursor = 1

    local function nearestUnvisitedTo()
      while byDistCursor <= n and visited[byDist[byDistCursor]] do
        byDistCursor = byDistCursor + 1
      end
      if byDistCursor > n then return nil end
      return byDist[byDistCursor]
    end
    while #order < n do
      local seed = nearestUnvisitedTo()
      if not seed then break end

      local queue = { seed }
      visited[seed] = true
      local qi = 1
      while qi <= #queue do
        local cur = queue[qi]; qi = qi + 1
        order[#order+1] = cur

        for k = #scratch, 1, -1 do scratch[k] = nil end
        candidates(cur, scratch)
        table.sort(scratch, function(a, b) return distToRef[a] < distToRef[b] end)
        for _, j in ipairs(scratch) do
          if not visited[j] and isAdjacent(cur, j) then
            visited[j] = true
            queue[#queue+1] = j
          end
        end
      end
    end

    local result = {}
    for _, i in ipairs(order) do result[#result+1] = blocks[i] end
    return result
  end
  local function buildLoop(data, xform)
    if type(data) ~= "table" or #data == 0 then log("Build data empty."); return false end
    if not ensureTools(true) then return false end

    runGen = runGen + 1
    local thisGen = runGen
    lastState = { blocks = data, transform = xform }

    stopped = false; skip = false
    local sorted = sortByAdjacency(data)
    totalBlocks   = #sorted
    verifiedBlocks = 0
    buildStart    = tick()
    updateStats()

    local verified = {}; local count = 0

    local function aborted()
      if getgenv()[GENKEY] ~= moduleGen then stopped = true end
      return stopped or runGen ~= thisGen
    end
    local function markVerified(i)
      if not verified[i] then
        verified[i] = true; count = count + 1
        verifiedBlocks = count; updateStats()
      end
    end

    for i, entry in ipairs(sorted) do
      if aborted() then break end
      if i % 25 == 0 then ensureTools(false) end
      if placeAndVerify(entry, xform) then markVerified(i) end
      task.wait(math.max(0.03, delay()))
    end

    local pass = 0
    while not aborted() and count < #sorted and pass < 4 do
      pass = pass + 1
      local repaired = 0
      if cfg.wbs then task.wait(1) end
      for i, entry in ipairs(sorted) do
        if aborted() then break end
        if not verified[i] then
          if placeAndVerify(entry, xform) then markVerified(i); repaired = repaired + 1 end
          task.wait(math.max(0.03, delay()))
        end
      end
      if repaired == 0 then break end
    end

    local wasAborted = aborted()
    local missing    = #sorted - count
    if runGen == thisGen then stopped = false; skip = false end
    totalBlocks = 0; verifiedBlocks = 0; updateStats()

    if wasAborted then
      log("Build stopped.")
    elseif missing > 0 then
      log(string.format("Build finished: %d/%d verified (%d need manual attention).", count, #sorted, missing))
    else
      log(string.format("Build complete: %d/%d blocks.", count, #sorted))
    end
    return not wasAborted
  end
  local function loadData()
    if isPreDecoded then
      if type(filePath) == "table" then return filePath, nil end
      return nil, "isData=true but filepath is not a table"
    end
    local raw
    if type(fetchFn) == "function" then
      raw = fetchFn(filePath)
    elseif type(filePath) == "string" and filePath:match("^https?://") then
      local ok, res = pcall(function() return game:HttpGet(filePath) end)
      if ok then raw = res end
    elseif type(filePath) == "string" then
      local ok, res = pcall(function() return readfile(filePath) end)
      if ok and res and res ~= "" then raw = res else raw = filePath end
    end
    if not raw or raw == "" then return nil, "Could not load: " .. tostring(filePath) end
    if type(raw) ~= "string" then return nil, "Expected string, got " .. type(raw) end
    if raw:sub(1,1) == "{" then
      local ok, res = pcall(function() return HttpService:JSONDecode(raw) end)
      if not ok then return nil, "JSON decode failed: " .. tostring(res) end
      if type(res) ~= "table" then return nil, "Decoded JSON is not a table" end
      return res, nil
    end
    local ok, res = pcall(Decompress, raw)
    if not ok then return nil, "Decompress failed: " .. tostring(res) end
    if type(res) ~= "table" then return nil, "Decompressed data is not a table" end
    return res, nil
  end

  local function makeXform()
    if cfg.offset == Vector3.zero and cfg.mult == 1 then return nil end
    return { enabled = true, center = Vector3.zero, rotation = CFrame.identity, offset = cfg.offset }
  end
  local remoteTemplate = [[
local hs  = game:GetService("HttpService")
local lib = loadstring(game:HttpGet(%s, true))()
local d   = hs:JSONDecode(%s)
local s   = hs:JSONDecode(%s)
s.offset  = Vector3.new(s.ox or 0, s.oy or 0, s.oz or 0)
s.ox, s.oy, s.oz = nil, nil, nil
lib.build(d, s, nil, true).start()
]]

  local function buildRemoteScript(chunkJson, settingsJson)
    return string.format(remoteTemplate,
      string.format("%q", "https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/autobuildv2.lua"),
      string.format("%q", chunkJson),
      string.format("%q", settingsJson)
    )
  end

  local function serializeSettings()
    return HttpService:JSONEncode({
      mult        = cfg.mult,
      historymax  = cfg.historymax,
      resizewait  = cfg.resizewait,
      wbs         = cfg.wbs,
      maxtry      = cfg.maxtry,
      maxtrydelay = cfg.maxtrydelay,
      ox          = cfg.offset.X,
      oy          = cfg.offset.Y,
      oz          = cfg.offset.Z,
    })
  end
  local session = {}
  session.stats = stats

  function session.settings() return cfg, DEFAULTS end
  function session.stop()        stopped = true; skip = true; tpTarget = nil end
  function session.skip()        skip = true end
  function session.wbs(v)        cfg.wbs = v end
  function session.resizewait(v) cfg.resizewait = v end
  function session.try(d, m)
    if d then cfg.maxtrydelay = d end
    if m then cfg.maxtry      = m end
  end

  function session.start()
    stopped = false; skip = false
    local data, err = loadData()
    if not data then log("Load failed: " .. tostring(err)); return false end

    if not asyncClients then
      return buildLoop(data, makeXform())
    end
    if #asyncClients <= 0 then
      log("async: no remote clients, running locally")
      return buildLoop(data, makeXform())
    end

    local allBlocks   = sortByAdjacency(data)
    local total       = #allBlocks
    local workers     = #asyncClients + 1
    local base        = math.floor(total / workers)
    local extra       = total % workers
    local settings    = serializeSettings()
    local cursor      = 1

    for w = 1, workers do
      local count = base + (w <= extra and 1 or 0)
      if count == 0 then break end
      local chunk = {}
      for i = cursor, cursor + count - 1 do chunk[#chunk+1] = allBlocks[i] end
      cursor = cursor + count

      if w < workers then
        local chunkJson = HttpService:JSONEncode(chunk)
        asyncClients[w](buildRemoteScript(chunkJson, settings))
        log(string.format("async: sent %d blocks to remote %d/%d", count, w, #asyncClients))
      else
        log(string.format("async: running %d blocks locally (worker %d/%d)", count, workers, workers))
        return buildLoop(chunk, makeXform())
      end
    end
    return true
  end

  return session
end

local lib = {}

function lib.save(filepath, players)  return SaveBlocks(filepath, players) end
function lib.build(filepath, settings, fetchfn, isdata, fetchtools) return CreateSession(filepath, settings, fetchfn, isdata, fetchtools) end

return lib