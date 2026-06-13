local args = ...

local assets = args.Assets
local Helpers = args.Helpers

local lib = {}

-- ─── Localised globals ────────────────────────────────────────────────────────
local math_round     = math.round
local table_insert   = table.insert
local table_unpack   = table.unpack
local task_wait      = task.wait
local coroutine_wrap = coroutine.wrap
local string_find    = string.find
local string_sub     = string.sub
local string_gsub    = string.gsub
local string_len     = string.len

local localplr = game.Players.LocalPlayer
local http     = game:GetService("HttpService")

-- ─── Constants ────────────────────────────────────────────────────────────────
local SAVE_DIR      = assets("Builds")
local DEFAULT_MULT  = 4
local DEFAULT_HMAX  = 400
local DEFAULT_RW    = 0.4
local DEFAULT_COLOR = Color3.fromRGB(192, 192, 192)

-- ─── File-name validation ────────────────────────────────────────────────────
local BANNED = {
    ['"']  = "''",
    ["*"]  = "\u{2605}",
    [":"]  = ";",
    ["<"]  = "\u{2264}",
    [">"]  = "\u{2265}",
    ["?"]  = "\u{00BF}",
    ["\\"] = "",
    ["|"]  = "I",
    ["/"]  = "\u{2215}",
}

local function validate(name)
    for sym, rep in pairs(BANNED) do
        name = string_gsub(name, sym, rep)
    end
    local s = string_find(name, "%.txt") or string_find(name, "%.json")
    if s then
        local ext = string_sub(name, s)
        name = string_gsub(string_sub(name, 1, s - 1), "%.", "·") .. ext
    else
        name = string_gsub(name, "%.", "·")
    end
    return name
end

-- ─── Material tables ─────────────────────────────────────────────────────────
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

-- ─── Math helpers ─────────────────────────────────────────────────────────────
local function roundnum(num, m)
    return math_round((num - 2) / m) * m + 2
end

local function round(pos, m)
    m = m or DEFAULT_MULT
    return Vector3.new(roundnum(pos.X, m), roundnum(pos.Y, m), roundnum(pos.Z, m))
end

local function snap(pos, m)
    m = m or DEFAULT_MULT
    local _x = math_round(pos.X / m) + 2  -- kept for parity; result unused
    return pos
end

-- ─── Block serialisation ──────────────────────────────────────────────────────
local function saveblock(bl, mult)
    mult = mult or DEFAULT_MULT
    if not bl:IsA("BasePart") then return {} end
    local bd = {}
    if (bl.CFrame - bl.Position) ~= CFrame.new() then
        bd.p = { bl.CFrame:GetComponents() }
    else
        bd.p = { bl.Position.X, bl.Position.Y, bl.Position.Z }
    end
    bd.c  = {
        math_round(bl.Color.R * 255),
        math_round(bl.Color.G * 255),
        math_round(bl.Color.B * 255),
    }
    bd.a  = bl.Anchored
    bd.cc = bl.CanCollide
    if bl.Size.X ~= mult or bl.Size.Y ~= mult or bl.Size.Z ~= mult then
        bd.p[1] = (bd.p[1] - (bl.Size.X / 2)) + .5
        bd.p[2] = (bd.p[2] - (bl.Size.Y / 2)) + .5
        bd.p[3] = (bd.p[3] - (bl.Size.Z / 2)) + .5
        bd.s = { bl.Size.X, bl.Size.Y, bl.Size.Z }
    end
    bd.m  = MATERIALS[bl.Material]
    bd.o  = bl.Material.Name
    bd.sp = {}
    for _, v in pairs(bl:GetChildren()) do
        if v.Name == "Spray" then
            table_insert(bd.sp, {
                v.Face.Name,
                v.Image.Image,
                string_gsub(v.Label.Text, '"', '\\"'),
            })
        end
    end
    return bd
end

-- ─── Preview part (pure — no side effects on oldprt) ─────────────────────────
local function createpartrepl(pos, bsize, col, mat, transp, anch, collide, sprays)
    if typeof(pos) == "Vector3" then pos = CFrame.new(pos) end
    local p = Instance.new("Part")
    p.Anchored   = anch ~= nil and anch or true  -- corrected: avoids false→true coercion
    p.CanCollide = collide or false
    p.CastShadow = false
    p.CanQuery   = false
    p.Color      = col
    p.Transparency = transp or .5
    p.Material   = mat or Enum.Material.Plastic
    if bsize ~= nil then
        pos = CFrame.new(
            (pos.X + (bsize.X / 2)) - .5,
            (pos.Y + (bsize.Y / 2)) - .5,
            (pos.Z + (bsize.Z / 2)) - .5
        ) * pos.Rotation
    end
    p.Size  = bsize or Vector3.new(DEFAULT_MULT, DEFAULT_MULT, DEFAULT_MULT)
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
                img.Image = v[2]
                img.BackgroundTransparency = 1
                img.Size  = UDim2.new(1, 0, 1, 0)
                img.Parent = sui
            else
                local lbl = Instance.new("TextLabel")
                lbl.Text               = txt
                lbl.BackgroundTransparency = 1
                lbl.TextScaled         = true
                lbl.TextColor3         = Color3.fromRGB(255, 255, 255)
                lbl.Font               = Enum.Font.FredokaOne
                lbl.Size               = UDim2.new(1, 0, 1, 0)
                lbl.Parent             = sui
            end
            sui.Parent = p
        end
    end
    p.Parent = workspace
    return p
end

-- ─── Folder bootstrap ────────────────────────────────────────────────────────
do
    pcall(function()
        local files = listfiles("")
        for _, v in pairs(files) do
            if v == SAVE_DIR or v == SAVE_DIR .. "/" then return end
        end
        makefolder(SAVE_DIR)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  lib.save(file_path, players)
--
--  Serialises blocks and writes to TheChosenOneBuilds/<file_path>.json.
--  `players` is an array of Player instances (uses workspace.Bricks[name])
--  or Model/Folder instances captured directly (e.g. workspace.Bricks).
-- ═══════════════════════════════════════════════════════════════════════════════
function lib.save(file_path, players)
    file_path = validate(tostring(file_path))
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
                    table_insert(builddata, saveblock(v, DEFAULT_MULT))
                end
            end
        end
    end
    writefile(SAVE_DIR .. "/" .. file_path .. ".json", http:JSONEncode(builddata))
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  lib.build(file_path, settings, fetch_tools) -> instance
--
--  file_path   string   save file name (no extension)
--  settings    table?   {
--                tp         bool     teleport to each block during build  [true]
--                offset     Vector3  positional offset for every block    [0,0,0]
--                mult       number   block grid size                       [4]
--                historymax number   brick-history ring buffer size        [400]
--                resizewait number   seconds per resize step               [0.4]
--                wbs        bool     auto-tune resizewait from ping        [false]
--              }
--  fetch_tools function(toolname: string) -> RemoteEvent | BindableFunction
--              Called each time a tool event is needed.
--              Tool names used: "Build", "Paint", "Shape"
--
--  Returns instance with :settings(), :start(), :stop(), :destroy()
-- ═══════════════════════════════════════════════════════════════════════════════
function lib.build(file_path, settings, fetch_tools)
    file_path = validate(tostring(file_path))
    settings  = settings or {}

    -- ── Config (mutable via instance:settings()) ─────────────────────────────
    local cfg = {
        offset     = settings.offset     or Vector3.new(0, 0, 0),
        mult       = settings.mult       or DEFAULT_MULT,
        historymax = settings.historymax or DEFAULT_HMAX,
        resizewait = settings.resizewait or DEFAULT_RW,
        wbs        = settings.wbs        or false,
    }
    -- ── Mutable build state ───────────────────────────────────────────────────
    local stopped   = false
    local skipblock = false
    local built     = false
    local novel     = false

    local childcube   = nil
    local oldprt      = nil
    local cubehistory = {}
    local historynum  = 0

    local resizewait = cfg.resizewait  -- kept separate; ping loop may update it
    
    local tp_to_pos = (function()
      local pos;
      task.spawn(function()
        while not stopped and task.wait(0.01) do
          pcall(function() 
            localplr.Character.HumanoidRootPart.CFrame = pos
          end)
        end
      end)
      return function(newpos)
        pos  = CFrame.new(newpos)
        task.wai
      end
    end)()
    
    
    -- ── Highlight (block being painted) ──────────────────────────────────────
    local highlight = Instance.new("Highlight")
    highlight.Parent           = game.CoreGui
    highlight.FillColor        = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = .9

    -- ── Brick-placed tracking ─────────────────────────────────────────────────
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
        -- parity: original silently no-ops when no personal folder exists
        cubechild = workspace.Bricks.ChildAdded:Connect(function() end)
    end

    -- ── Ping-based resize-wait coroutine ──────────────────────────────────────
    local pingRunning = true
    local pinghistory = {}
    local historynum2 = 0
    local ping        = -100

    coroutine_wrap(function()
        while pingRunning do
            task_wait(1)
            if not cfg.wbs then continue end
            local newping = -199
            local ok = pcall(function()
                for _, v in pairs(game:GetService("CoreGui").RobloxGui.PerformanceStats:GetChildren()) do
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
                resizewait = (sum / #pinghistory) / 1000
            end
        end
    end)()

    -- ── Tool event dispatcher ─────────────────────────────────────────────────
    local function fireEvent(toolname, args)
        local event = fetch_tools(toolname)
        if event == nil then return end
        if typeof(event) == "Instance" and event:IsA("BindableFunction") then
            event:Invoke(table_unpack(args))
        else
            event:FireServer(table_unpack(args))
        end
    end

    -- ── buildblock ────────────────────────────────────────────────────────────
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

            -- Optimised path: place adjacent to a history block ──────────────
            if #cubehistory > 0 and oldprt then
                local allooslol = {}
                for i, cc2 in pairs(cubehistory) do
                    if cc2 == nil or cc2.Parent == nil then
                        cubehistory[i] = nil
                        continue
                    elseif oldprt.Size == cc2.Size then
                        for nid, v in pairs(NORMAL_IDS) do
                            local adjPos = cc2.Position + (v[1] * cc2.Size[v[2]])
                            if adjPos == oldprt.Position then
                                oo = { nid, cc2, cc2.Position + (v[1] * cc2.Size[v[2]] / 2) }
                                table_insert(allooslol, { nid, cc2, cc2.Position + (v[1] * cc2.Size[v[2]] / 2) })
                            end
                        end
                    end
                end
                -- prefer history block whose color already matches
                if #allooslol > 1 and color and oo[2].Color ~= color then
                    for _, v in pairs(allooslol) do
                        if v[2].Color == color then oo = v end
                    end
                end

                local origposs = pos
                if oo and oo[2] ~= nil and oo[2].Parent ~= nil then
                    local args = { oo[2], oo[1], oo[3] or oldprt.Position, "normal" }
                    built     = false
                    childcube = nil
                    c         = 0
                    repeat
                        c = c + 1
                        fireEvent("Build", args)
                        pcall(function()
                            novel = true
                            pos   = oo[3] or pos
                            tp_to_pos(pos)
                        end)
                        task_wait(.05)
                    until (built and childcube)
                        or oo[2] == nil or oo[2].Parent == nil
                        or stopped or skipblock or c > 200
                    novel = false
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

                local args = { workspace.Terrain, Enum.NormalId.Top, snap(pos, mult), bsize or "normal" }
                built = false
                pcall(function() fireEvent("Build", args) end)
                c = 0
                repeat
                    c = c + 1
                    fireEvent("Build", args)
                    pcall(function()
                        novel = true
                        tp_to_pos(pos)
                    end)
                    task_wait(.1)
                until (built and childcube) or stopped or skipblock or c > 200
                novel = false
                built = false
                c     = 0
            end

            -- Paint (color + material) ─────────────────────────────────────────
            if (childcube
                    and typeof(color) == "Color3"
                    and (color ~= DEFAULT_COLOR or childcube.Color ~= color or childcube.Material ~= texture)
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
                pcall(function()
                    repeat
                        c = c + 1
                        fireEvent("Paint", args)
                        pcall(function()
                            novel = true
                            tp_to_pos(pos)
                        end)
                        task_wait(.2)
                    until not childcube or not childcube.Parent
                        or childcube.Color == color
                        or (texture and childcube.Material == Enum.Material[origmaterial])
                        or stopped or skipblock or c > 2000
                    novel = false
                end)
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
                    pcall(function()
                        novel = true
                        tp_to_pos(pos)
                    end)
                    task_wait(1)
                until not childcube or not childcube.Parent
                    or childcube.Anchored == anchored
                    or not localplr.Character
                    or stopped or skipblock or c > 20
                novel = false
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
                    pcall(function()
                        novel = true
                        tp_to_pos(pos)
                    end)
                    task_wait(1)
                until not childcube or not childcube.Parent
                    or childcube.CanCollide == collide
                    or not localplr.Character
                    or stopped or skipblock or c > 20
                novel = false
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
                            task_wait(.5)
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
                    local args = { childcube, normalId, "", nil }
                    c = 0
                    repeat
                        c    = c + 1
                        args[4] = nil
                        if childcube then
                            local rPos = childcube.Position + childcube.Size / 2
                            args[3] = rPos
                            if     childcube.Size[axis] > target then args[4] = "decrease"
                            elseif childcube.Size[axis] < target then args[4] = "increase"
                            end
                        end
                        fireEvent("Shape", args)
                        pcall(function()
                            novel = true
                            local rPos = (childcube and childcube.Position + childcube.Size / 2) or pos
                            tp_to_pos(CFrame.new(rPos + Vector3.new(0, 6, 0)))
                        end)
                        task_wait(resizewait)
                    until args[4] == nil
                        or (args[4] == "decrease" and childcube and childcube.Size[axis] <= 1)
                        or (childcube and childcube.Size[axis] == target)
                        or not childcube or not childcube.Parent
                        or stopped or skipblock
                        or c > (target * 3) / resizewait
                    novel = false
                end
                resizeAxis(Enum.NormalId.Right, "X", bsizev3.X)
                resizeAxis(Enum.NormalId.Top,   "Y", bsizev3.Y)
                resizeAxis(Enum.NormalId.Back,  "Z", bsizev3.Z)
            end

            skipblock = false
        end)

        if oldprt then oldprt:Destroy() end
        novel     = false
        childcube = nil
        if not s then print(e) end
    end

    -- ── Public instance ───────────────────────────────────────────────────────
    local instance = {}

    --[[
        Returns the live settings table. Modify fields directly, e.g.:
            instance:settings().tp = false
            instance:settings().wbs = true
    ]]
    function instance:settings()
        return cfg
    end

    -- Halts the running build loop after the current block completes.
    function instance:stop()
        stopped = true
    end

    --[[
        Reads the saved file and replays every block sequentially.
        Blocks until the build finishes or instance:stop() is called.
    ]]
    function instance:start()
        stopped   = false
        skipblock = false

        local path = SAVE_DIR .. "/" .. file_path .. ".json"
        local raw  = readfile(path)
        if not raw then
            warn("[builder] File not found: " .. path)
            return
        end
        local builddata = http:JSONDecode(raw)
        if not builddata then
            warn("[builder] Decode failed: " .. path)
            return
        end

        if oldprt then oldprt:Destroy() end

        for _, v in pairs(builddata) do
            if stopped then break end

            local posses   = v.p or v.pos
            local blockPos = CFrame.new(posses[1], posses[2], posses[3]).Position + cfg.offset
            local blockMat = v.m or v.mat
            local blockCol = Color3.fromRGB(table_unpack(v.c or v.color))
            local blockSz  = (v.s or v.size) and Vector3.new(table_unpack(v.s or v.size)) or nil
            local origmat  = v.o or v.origmat
            local sprays   = v.sp or v.sprayed
            local anchored = v.a ~= nil and v.a or v.anchored
            local collide  = v.cc ~= nil and v.cc or v.collide

            oldprt = createpartrepl(blockPos, blockSz, blockCol, SWAPPED[blockMat])
            buildblock(blockPos, blockMat, blockCol, nil, blockSz, nil, origmat, sprays, anchored, collide)
        end

        stopped = false
    end

    -- Disconnects all listeners and destroys owned instances. Call on unload.
    function instance:destroy()
        stopped     = true
        pingRunning = false
        cubechild:Disconnect()
        highlight:Destroy()
        if oldprt then oldprt:Destroy() end
    end

    return instance
end

return lib