local args = ...

local assets  = args.Assets
local Helpers = args.Helpers

local lib = {}

local math_round     = math.round
local table_insert   = table.insert
local table_unpack   = table.unpack
local task_wait      = task.wait
local coroutine_wrap = coroutine.wrap
local string_find    = string.find
local string_sub     = string.sub
local string_gsub    = string.gsub
local string_len     = string.len

local localplr = Helpers.services.players.LocalPlayer
local http     = Helpers.services.http
local coregui  = game:GetService("CoreGui")
local MATERIALS = {
    [Enum.Material.SmoothPlastic] = "smooth",
    [Enum.Material.Plastic]       = "plastic",
    [Enum.Material.CeramicTiles]  = "tiles",
    [Enum.Material.Brick]         = "bricks",
    [Enum.Material.WoodPlanks]    = "planks",
    [Enum.Material.Ice]           = "ice",
    [Enum.Material.Grass]         = "grass",
    [Enum.Material.Sand]          = "sand",
    [Enum.Material.Snow]          = "snow",
    [Enum.Material.Glass]         = "glass",
    [Enum.Material.Wood]          = "wood",
    [Enum.Material.Slate]         = "stone",
    [Enum.Material.Pebble]        = "pebble",
    [Enum.Material.Marble]        = "marble",
    [Enum.Material.Granite]       = "granite",
    [Enum.Material.DiamondPlate]  = "steel",
    [Enum.Material.Metal]         = "metal",
    [Enum.Material.Asphalt]       = "asphalt",
    [Enum.Material.Concrete]      = "concrete",
    [Enum.Material.Pavement]      = "pavement",
    [Enum.Material.Neon]          = "neon",
}

local SWAPPED = {}
for mat, name in pairs(MATERIALS) do SWAPPED[name] = mat end

local NORMAL_IDS = {
    [Enum.NormalId.Right]  = { Vector3.new( 1, 0, 0), "X" },
    [Enum.NormalId.Top]    = { Vector3.new( 0, 1, 0), "Y" },
    [Enum.NormalId.Back]   = { Vector3.new( 0, 0, 1), "Z" },
    [Enum.NormalId.Left]   = { Vector3.new(-1, 0, 0), "X" },
    [Enum.NormalId.Bottom] = { Vector3.new( 0,-1, 0), "Y" },
    [Enum.NormalId.Front]  = { Vector3.new( 0, 0,-1), "Z" },
}

local NORMAL_ID_FROM_NAME = {
    Right  = Enum.NormalId.Right,
    Top    = Enum.NormalId.Top,
    Back   = Enum.NormalId.Back,
    Left   = Enum.NormalId.Left,
    Bottom = Enum.NormalId.Bottom,
    Front  = Enum.NormalId.Front,
}

-- ─── Math helpers ─────────────────────────────────────────────────────────────
local function roundnum(num, m)
    return math_round((num - 2) / m) * m + 2
end

local function round(pos, m)
    m = m or 4
    return Vector3.new(roundnum(pos.X, m), roundnum(pos.Y, m), roundnum(pos.Z, m))
end


-- ─── Preview part ─────────────────────────────────────────────────────────────
local function createpartrepl(pos, bsize, col, mat, transp, anch, collide, sprays)
    if typeof(pos) == "Vector3" then pos = CFrame.new(pos) end
    local p = Instance.new("Part")
    p.Anchored     = anch ~= nil and anch or true
    p.CanCollide   = collide or false
    p.CastShadow   = false
    p.CanQuery     = false
    p.Color        = col
    p.Transparency = transp or .5
    p.Material     = mat or Enum.Material.Plastic
    if bsize ~= nil then
        pos = CFrame.new(
            (pos.X + (bsize.X / 2)) - .5,
            (pos.Y + (bsize.Y / 2)) - .5,
            (pos.Z + (bsize.Z / 2)) - .5
        ) * pos.Rotation
    end

    p.Size   = bsize or Vector3.new(4, 4, 4)
    p.CFrame = pos
    if sprays then
        for _, v in pairs(sprays) do
            local sui = Instance.new("SurfaceGui")
            sui.Face          = Enum.NormalId[v[1]]
            sui.SizingMode    = Enum.SurfaceGuiSizingMode.PixelsPerStud
            sui.PixelsPerStud = 50
            local txt       = v[3]
            local _, hashes = string_gsub(txt, "#", "l")
            if hashes == string_len(txt) then
                local img = Instance.new("ImageLabel")
                img.Image                  = v[2]
                img.BackgroundTransparency = 1
                img.Size                   = UDim2.new(1, 0, 1, 0)
                img.Parent                 = sui
            else
                local lbl = Instance.new("TextLabel")
                lbl.Text                   = txt
                lbl.BackgroundTransparency = 1
                lbl.TextScaled             = true
                lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
                lbl.Font                   = Enum.Font.FredokaOne
                lbl.Size                   = UDim2.new(1, 0, 1, 0)
                lbl.Parent                 = sui
            end
            sui.Parent = p
        end
    end
    p.Parent = workspace
    return p
end

-- ─── Folder bootstrap ─────────────────────────────────────────────────────────
do
    pcall(function()
        local files = listfiles("")
        for _, v in pairs(files) do
            if v == assets("Builds") or v == assets("Builds") .. "/" then return end
        end
        makefolder(assets("Builds"))
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  lib.save(file_path, players)
-- ═══════════════════════════════════════════════════════════════════════════════
function lib.save(file_path, players)
    local builddata = {}
    for _, source in pairs(players) do
        local container
        if source:IsA("Player") then
            container = workspace.Bricks:FindFirstChild(source.Name)
        else
            container = source
        end
        if container then
          for _, v in pairs(container:GetChildren()) do
              if v:IsA("BasePart") then
                  local s = v.Size
                  if s.X == 0.5 and s.Y == 2 and s.Z == 0.5 then continue end
                  local bd
                  if v:FindFirstChild("Input") ~= nil then
                      local txt = ""
                      local input = v:FindFirstChild("Input")
                      if input then
                          local label = input:FindFirstChild("Label")
                          if label then
                              txt = label.Text or ""
                          end
                      end
                      bd = {
                          type = "sign",
                          p    = { v.CFrame:GetComponents() },
                          sid  = v.Input.Face.Name,
                          txt  = string_gsub(txt, '"', '\\"'),
                          c    = {
                              math_round(v.Color.R * 255),
                              math_round(v.Color.G * 255),
                              math_round(v.Color.B * 255),
                          },
                          id   = v.Name,
                      }
                  else
                      bd = {}
                      if (v.CFrame - v.Position) ~= CFrame.new() then
                          bd.p = { v.CFrame:GetComponents() }
                      else
                          bd.p = { v.Position.X, v.Position.Y, v.Position.Z }
                      end
                      bd.c  = {
                          math_round(v.Color.R * 255),
                          math_round(v.Color.G * 255),
                          math_round(v.Color.B * 255),
                      }
                      bd.a  = v.Anchored
                      bd.cc = v.CanCollide
                      if v.Size.X ~= 4 or v.Size.Y ~= 4 or v.Size.Z ~= 4 then
                          bd.p[1] = (bd.p[1] - (v.Size.X / 2)) + .5
                          bd.p[2] = (bd.p[2] - (v.Size.Y / 2)) + .5
                          bd.p[3] = (bd.p[3] - (v.Size.Z / 2)) + .5
                          bd.s = { v.Size.X, v.Size.Y, v.Size.Z }
                      end
                      bd.m  = MATERIALS[v.Material]
                      bd.o  = v.Material.Name
                      bd.sp = {}
                      for _, c in pairs(v:GetChildren()) do
                          if c.Name == "Spray" then
                              table_insert(bd.sp, {
                                  c.Face.Name,
                                  c.Image.Image,
                                  string_gsub(c.Label.Text, '"', '\\"'),
                              })
                          end
                      end
                  end
                  if bd ~= nil then
                      table_insert(builddata, bd)
                  end
              end
          end
      end
    end
    writefile(assets("Builds") .. "/" .. file_path .. ".json", http:JSONEncode(builddata))
end

function lib.build(file_path, settings, fetch_tools, isData)
    settings  = settings or {}
    
    local cfg = {
        offset     = settings.offset     or Vector3.new(0, 0, 0),
        mult       = settings.mult       or 4,
        historymax = settings.historymax or 400,
        resizewait = settings.resizewait or 0.4,
        wbs        = settings.wbs        or false,
        maxtry     = settings.maxtry     or 0,
    }

    local delays = {
        maxtrydelay    = settings.maxtrydelay or 0.1, -- delay between maxtry placement attempts
        adj_fire       = 0.05,                        -- adjacent-block placement loop fire rate
        paint          = 0.2,                         -- paint loop fire rate
        anchor_collide = 1,                           -- anchor/collide loop fire rate
        spray          = 0.5,                         -- per-spray wait
        resize         = cfg.resizewait,              -- resize step wait (also dynamic via wbs)
    }

    local stopped   = false
    local skipblock = false
    local built     = false

    local childcube   = nil
    local oldprt      = nil
    local cubehistory = {}
    local historynum  = 0
    local prttable    = nil

    local resizewait = delays.resize

    local tp_to_pos = (function()
        local cf = nil
        task.spawn(function()
            while not stopped and task.wait(0.01) do
                pcall(function()
                    localplr.Character.HumanoidRootPart.CFrame = cf
                end)
            end
        end)
        return function(newcf)
            cf = typeof(newcf) == "CFrame" and newcf or CFrame.new(newcf)
            task.wait(0.01)
        end
    end)()

    local highlight = Instance.new("Highlight")
    highlight.Parent           = coregui
    highlight.FillColor        = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = .9

    local bricksFolder = workspace.Bricks:FindFirstChild(localplr.Name)
    local cubechild
    if bricksFolder then
        cubechild = bricksFolder.ChildAdded:Connect(function(child)
            childcube  = child
            historynum = historynum + 1
            if historynum > cfg.historymax then historynum = 1 end
            cubehistory[historynum] = child
            built = true
        end)
    else
        cubechild = workspace.Bricks.ChildAdded:Connect(function() end)
    end

    local pingRunning = true
    local pinghistory = {}
    local historynum2 = 0
    local ping        = -100

    task.spawn(function()
        while pingRunning do
            task_wait(1)
            if not cfg.wbs then continue end
            local newping = -199
            local ok = pcall(function()
                for _, v in pairs(coregui.RobloxGui.PerformanceStats:GetChildren()) do
                    local panel = v:FindFirstChild("StatsMiniTextPanelClass")
                    if panel
                        and panel:FindFirstChild("TitleLabel")
                        and panel:FindFirstChild("ValueLabel")
                        and panel.TitleLabel.Text == "Ping"
                    then
                        local raw = panel.ValueLabel.Text
                        local ms  = string_find(raw, " ms")
                        if ms then newping = tonumber(string_sub(raw, 1, ms - 1)) end
                    end
                end
            end)
            if not ok then
                newping = localplr:GetNetworkPing() * 1000
            end
            if newping ~= ping then
                ping        = newping
                historynum2 = historynum2 + 1
                if historynum2 > 5 then historynum2 = 1 end
                local multi = 2.7
                if     ping > 500 then multi = 2.2
                elseif ping > 250 then multi = 2.5
                end
                pinghistory[historynum2] = ping * multi
                local sum = 0
                for _, v in pairs(pinghistory) do sum = sum + v end
                resizewait        = (sum / #pinghistory) / 1000
                delays.resize     = resizewait
            end
        end
    end)
    -- ── Tool event dispatcher ──────────────────────────────────────────────────
    local function fireEvent(toolname, eargs)
        local event = fetch_tools(toolname)
        if event == nil then return end
        if typeof(event) == "Instance" and event:IsA("BindableFunction") then
            event:Invoke(table_unpack(eargs))
        else
            event:FireServer(table_unpack(eargs))
        end
    end

    -- ── buildSign ─────────────────────────────────────────────────────────────
    local function buildSign(signData, offset)
        offset = offset or Vector3.new(0, 0, 0)

        local cf  = CFrame.new(table_unpack(signData.p))
        local pos = cf.Position + offset

        local normalId     = NORMAL_ID_FROM_NAME[signData.sid] or Enum.NormalId.Front
        local localFaceDir = NORMAL_IDS[normalId][1]
        local faceDir      = cf:VectorToWorldSpace(localFaceDir)

        local standPos    = pos + faceDir * 3
        local up          = math.abs(faceDir:Dot(Vector3.yAxis)) > 0.99
                            and Vector3.zAxis or Vector3.yAxis
        local standCFrame = CFrame.lookAt(standPos, pos, up)

        local searchPos = pos + (-faceDir * 4)

        local ref       = workspace.Terrain
        local refNormal = Enum.NormalId.Top

        local bFolder = workspace:FindFirstChild("Bricks")
        if bFolder then
            for _, plrFolder in pairs(bFolder:GetChildren()) do
                for _, brick in pairs(plrFolder:GetChildren()) do
                    local s = brick.Size
                    if brick:IsA("BasePart") and not s.X == 0.5 and s.Y == 2 and s.Z == 0.5 and not brick:FindFirstChild("Input") ~= nil
                        and (brick.Position - searchPos).Magnitude < 4
                    then
                        ref       = brick
                        refNormal = normalId
                        break
                    end
                end
                if ref ~= workspace.Terrain then break end
            end
        end

        built     = false
        childcube = nil
        local c   = 0

        repeat
            c = c + 1
            tp_to_pos(standCFrame)
            task_wait(0.3)
            fireEvent("Sign", { ref, refNormal, Vector3.new(pos.X, pos.Y - 1, pos.Z) })
        until built or stopped or skipblock or c > 10 



        if childcube and signData.txt and signData.txt ~= "" then
            task_wait(0.3)
            pcall(function()
                childcube:WaitForChild("Input"):WaitForChild("Label"):WaitForChild("Script"):WaitForChild("Event"):FireServer(signData.txt)
            end)
        end

        if childcube and signData.c then
            local color    = Color3.fromRGB(table_unpack(signData.c))
            local paintPos = childcube.Position + childcube.Size / 2
            local eargs    = { childcube, Enum.NormalId.Top, paintPos, "color", color, "tiles", "" }
            local pc       = 0
            repeat
                pc = pc + 1
                fireEvent("Paint", eargs)
                tp_to_pos(pos)
                task_wait(0.2)
            until not childcube or not childcube.Parent
                or childcube.Color == color
                or stopped or skipblock or pc > 20
        end

        built     = false
        childcube = nil
        skipblock = false
    end

    -- ── buildblock ─────────────────────────────────────────────────────────────
    local function buildblock(pos, texture, color, bsize, bsizev3, premadebuild, origmaterial, sprays, anchored, collide)
        task_wait(0.001)
        if anchored == nil then anchored = true end
        if collide  == nil then collide  = true end

        local mult        = cfg.mult
        local needsresize = false

        local s, e = pcall(function()
            local oo = false
            local c  = 0
            childcube = nil

            -- Optimised path: place adjacent to a history block ────────────────
            if #cubehistory > 0 and oldprt then
                local allooslol = {}
                for i, cc2 in pairs(cubehistory) do
                    if cc2 == nil or cc2.Parent == nil then
                        cubehistory[i] = nil
                        continue
                    end
                    for nid, v in pairs(NORMAL_IDS) do
                        -- face center of cc2 in this direction
                        local faceCenter = cc2.Position + v[1] * (cc2.Size[v[2]] / 2)
                        -- expected center of the block touching that face
                        local adjCenter  = faceCenter + v[1] * (oldprt.Size[v[2]] / 2)
                        if adjCenter == oldprt.Position then
                            local entry = { nid, cc2, faceCenter }
                            oo = entry
                            table_insert(allooslol, entry)
                        end
                    end
                end
                if #allooslol > 1 and color and oo[2].Color ~= color then
                    for _, v in pairs(allooslol) do
                        if v[2].Color == color then oo = v end
                    end
                end

                local origposs = pos
                if oo and oo[2] ~= nil and oo[2].Parent ~= nil then
                    local args = { oo[2], oo[1], oo[3] or oldprt.Position, "detailed" }
                    built     = false
                    childcube = nil
                    c         = 0
                    repeat
                        c = c + 1
                        fireEvent("Build", args)
                        pos = oo[3] or pos
                        tp_to_pos(pos)
                        task_wait(delays.adj_fire)
                    until (built and childcube)
                        or oo[2] == nil or oo[2].Parent == nil
                        or stopped or skipblock or c > 10
                    if oo[2] == nil or oo[2].Parent == nil or c > 200 then
                        oo = false
                    else
                        if oldprt then oldprt:Destroy() end
                    end
                end
                pos = origposs
            end

            -- Standard placement ──────────────────────────────────────────────
            if oo == false then
                if bsize == nil then
                    bsize = "normal"
                    if localplr.PlayerGui:FindFirstChild("Build")
                        and localplr.PlayerGui.Build:FindFirstChild("Button")
                    then
                        bsize = localplr.PlayerGui.Build.Button.Text
                    end
                    if bsizev3 ~= nil and (bsizev3.X ~= mult or bsizev3.Y ~= mult or bsizev3.Z ~= mult) then
                        bsize = "detailed"
                    elseif bsizev3 ~= nil and bsizev3.X == mult and bsizev3.Y == mult and bsizev3.Z == mult then
                        bsize = "normal"
                    end
                    if bsizev3 == nil and bsize ~= "detailed" and oldprt and oldprt.Position ~= round(pos) then
                        bsize       = "detailed"
                        needsresize = true
                        bsizev3     = Vector3.new(4, 4, 4)
                        pos = Vector3.new(
                            (pos.X - (bsizev3.X / 2)) + .5,
                            (pos.Y - (bsizev3.Y / 2)) + .5,
                            (pos.Z - (bsizev3.Z / 2)) + .5
                        )
                    end
                end

                local args = { workspace.Terrain, Enum.NormalId.Top, pos, bsize or "normal" }
                local tries = 0
                repeat
                    tries = tries + 1
                    built = false
                    pcall(function() fireEvent("Build", args) end)
                    c = 0
                    repeat
                        c = c + 1
                        fireEvent("Build", args)
                        tp_to_pos(pos)
                        task_wait(.1)
                    until (built and childcube) or stopped or skipblock or c > 10
                    built = false
                    c     = 0
                    if not childcube and cfg.maxtry > 0 and tries < cfg.maxtry and not stopped and not skipblock then
                        task_wait(delays.maxtrydelay)
                    end
                until childcube or stopped or skipblock
                    or cfg.maxtry == 0 or tries >= cfg.maxtry
            end

            -- Paint (color + material) ─────────────────────────────────────────
            if (childcube
                    and typeof(color) == "Color3"
                    and (color ~= Color3.fromRGB(192, 192, 192) or childcube.Color ~= color or childcube.Material ~= texture)
                ) or texture
            then
                local paintPos = (childcube and childcube.Position + childcube.Size / 2) or pos
                local args = { childcube, Enum.NormalId.Top, paintPos, "color", color or nil, "tiles", "" }
                task_wait()
                if texture ~= nil then
                    args[4] = color ~= nil and "both \u{1F91D}" or "material"
                    args[6] = texture
                end
                if not childcube then
                    if oldprt then oldprt:Destroy() end
                    return
                end
                highlight.Adornee = childcube
                c = 0
                repeat
                    c = c + 1
                    fireEvent("Paint", args)
                    tp_to_pos(pos)
                    task_wait(delays.paint)
                until (childcube and childcube.Color == color)
                    or (texture and childcube.Material == Enum.Material[origmaterial])
                    or stopped or skipblock or c > 30
            end

            -- Anchor ───────────────────────────────────────────────────────────
            if childcube and localplr.Character and childcube.Anchored ~= anchored then
                local aPos = (childcube.Position + childcube.Size / 2)
                local args = { childcube, Enum.NormalId.Top, aPos or childcube.Position + Vector3.new(1, 0, 0), "material", nil, "anchor", "" }
                c = 0
                repeat
                    c = c + 1
                    if childcube and childcube.Anchored ~= anchored then
                        fireEvent("Paint", args)
                    end
                    tp_to_pos(pos)
                    task_wait(delays.anchor_collide)
                until not childcube or not childcube.Parent
                    or childcube.Anchored == anchored
                    or not localplr.Character
                    or stopped or skipblock or c > 20
            end

            -- Collide ──────────────────────────────────────────────────────────
            if childcube and localplr.Character and childcube.CanCollide ~= collide then
                local cPos = (childcube.Position + childcube.Size / 2)
                local args = { childcube, Enum.NormalId.Top, cPos or childcube.Position + Vector3.new(1, 0, 0), "material", nil, "collide", "" }
                c = 0
                repeat
                    c = c + 1
                    if childcube and childcube.CanCollide ~= collide then
                        fireEvent("Paint", args)
                    end
                    tp_to_pos(pos)
                    task_wait(delays.anchor_collide)
                until not childcube or not childcube.Parent
                    or childcube.CanCollide == collide
                    or not localplr.Character
                    or stopped or skipblock or c > 20
            end

            highlight.Adornee = nil

            -- Sprays ───────────────────────────────────────────────────────────
            if childcube and sprays ~= nil then
                local args = {
                    childcube,
                    Enum.NormalId.Front,
                    childcube.Position + Vector3.new(1, 0, 0),
                    "material", nil, "spray", "ha",
                }
                for _, v in pairs(sprays) do
                    args[2] = Enum.NormalId[v[1]]
                    args[7] = v[3]
                    if childcube and not stopped and not skipblock then
                        pcall(function()
                            task_wait(delays.spray)
                            fireEvent("Paint", args)
                        end)
                    end
                end
            end

            -- Resize ───────────────────────────────────────────────────────────
            if childcube and (
                (bsizev3 ~= nil and (bsizev3.X ~= mult or bsizev3.Y ~= mult or bsizev3.Z ~= mult))
                or needsresize
            ) then
                local function resizeAxis(normalId, axis, target)
                    if not (childcube and childcube.Size[axis] ~= target) then return end
                    local faceDir2 = NORMAL_IDS[normalId][1]
                    local args = { childcube, normalId, "", nil }
                    c = 0
                    repeat
                        c       = c + 1
                        args[4] = nil
                        if childcube then
                            local rPos = childcube.Position + childcube.Size / 2
                            args[3] = rPos
                            if     childcube.Size[axis] > target then args[4] = "decrease"
                            elseif childcube.Size[axis] < target then args[4] = "increase"
                            end
                        end
                        fireEvent("Shape", args)
                        local rPos = (childcube and childcube.Position + childcube.Size / 2) or pos
                        tp_to_pos(CFrame.new(rPos + Vector3.new(0, 6, 0)))
                        task_wait(resizewait)
                    until args[4] == nil
                        or (args[4] == "decrease" and childcube and childcube.Size[axis] <= 1)
                        or (childcube and childcube.Size[axis] == target)
                        or not childcube or not childcube.Parent
                        or stopped or skipblock
                        or c > (target * 3) / resizewait
                end
                resizeAxis(Enum.NormalId.Right, "X", bsizev3.X)
                resizeAxis(Enum.NormalId.Top,   "Y", bsizev3.Y)
                resizeAxis(Enum.NormalId.Back,  "Z", bsizev3.Z)
            end

            skipblock = false
        end)

        if oldprt then oldprt:Destroy() end
        childcube = nil
        if not s then print(e) end
    end

    -- ── Public instance ───────────────────────────────────────────────────────
    local instance = {}

    function instance:settings()
        return cfg, delays
    end

    function instance:stop()
        stopped     = true
        pingRunning = false
        cubechild:Disconnect()
        highlight:Destroy()
        if oldprt then oldprt:Destroy() end
        if prttable then
            for _, p in pairs(prttable) do
                if p and p.Parent then p:Destroy() end
            end
            prttable = nil
        end
    end

    function instance:skip()
        skipblock = true
    end

    function instance:wbs(v)        cfg.wbs        = v end
    function instance:resizewait(v) cfg.resizewait = v ; resizewait = v ; delays.resize = v end
    function instance:try(delay, max)
        delays.maxtrydelay = delay
        cfg.maxtry         = max
    end

    function instance:start()
        stopped   = false
        skipblock = false
        
        local raw  =  isData and file_path or readfile(assets("Builds") .. "/" .. file_path .. ".json")
        
        if not raw then
            warn("[builder] File not found: " .. file_path)
            return
        end
        local builddata = http:JSONDecode(raw)
        if not builddata then
            warn("[builder] Decode failed: " .. file_path)
            return
        end

        if oldprt then oldprt:Destroy() end

        for _, v in pairs(builddata) do
            if stopped then break end

            local ok, err = pcall(function()
                if v.type == "sign" then
                    buildSign(v, cfg.offset)
                    return
                end

                local posses = v.p or v.pos
                local blockPos
                if #posses == 12 then
                    blockPos = CFrame.new(table_unpack(posses)).Position + cfg.offset
                else
                    blockPos = CFrame.new(posses[1], posses[2], posses[3]).Position + cfg.offset
                end

                local blockMat = v.m or v.mat
                local blockCol = Color3.fromRGB(table_unpack(v.c or v.color))
                local blockSz  = (v.s or v.size) and Vector3.new(table_unpack(v.s or v.size)) or nil
                local origmat  = v.o or v.origmat
                local sprays   = v.sp or v.sprayed
                local anchored = v.a ~= nil and v.a or v.anchored
                local collide  = v.cc ~= nil and v.cc or v.collide

                oldprt = createpartrepl(blockPos, blockSz, blockCol, SWAPPED[blockMat])
                buildblock(blockPos, blockMat, blockCol, nil, blockSz, nil, origmat, sprays, anchored, collide)
            end)
            if not ok then print(err) end
        end

        self:stop()
        return self
    end

    function instance:show(bool)
        if prttable then
            for _, p in pairs(prttable) do
                if p and p.Parent then p:Destroy() end
            end
            prttable = nil
        end
        if not bool then return self end

        local path = assets("Builds") .. "/" .. file_path .. ".json"
        local raw  = readfile(path)
        if not raw then
            warn("[builder] show: file not found: " .. path)
            return self
        end
        local builddata = http:JSONDecode(raw)
        if not builddata then
            warn("[builder] show: decode failed: " .. path)
            return self
        end

        local parts = {}
        for _, v in pairs(builddata) do
            if v.type == "sign" then continue end

            local posses = v.p or v.pos
            local blockPos
            if #posses == 12 then
                blockPos = CFrame.new(table_unpack(posses)).Position + cfg.offset
            else
                blockPos = CFrame.new(posses[1], posses[2], posses[3]).Position + cfg.offset
            end

            local blockCol = Color3.fromRGB(table_unpack(v.c or v.color))
            local blockMat = v.m or v.mat
            local blockSz  = (v.s or v.size) and Vector3.new(table_unpack(v.s or v.size)) or nil
            local sprays   = v.sp or v.sprayed

            local part = createpartrepl(blockPos, blockSz, blockCol, SWAPPED[blockMat], 0.5, true, false, sprays)
            table_insert(parts, part)
        end
        prttable = parts
        return self
    end

    return instance
end

return lib