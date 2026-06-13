local args = ...

local tabs   = args.Tabs
local Window = args.Window
local WindUI = args.WindUI
local assets = args.Assets
local Helpers = args.Helpers

tabs.autobuild = Window:Tab({
  Title = "Autobuild",
  Icon  = "blocks",
})

local lib      = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/src/autobuild.lua"))(...)
local players  = Helpers.services.players
local localplr = players.LocalPlayer
local tab      = tabs.autobuild
local SAVE_DIR = assets("Builds")

local cfg = {
  historymax = 300,
  resizewait = 0.4,
  wbs        = false,
  offset     = Vector3.new(0, 0, 0),
}
local selectedFile  = nil
local activeBuilder = nil
local showEnabled   = false

local function fetch_tools(toolname)
    local char = localplr.Character
    if not char then return nil end

    local tool
    local elapsed = 10

    while not tool do
        tool = char:FindFirstChild(toolname)
        if not tool then
            local bp = localplr.Backpack:FindFirstChild(toolname)
            if bp then
                bp.Parent = char
                tool = bp
            end
        end

        if not tool then
            if elapsed >= 10 then
                WindUI:Notify({
                    Title    = "Error",
                    Content  = "No " .. toolname .. " found! Waiting for " .. toolname,
                    Duration = 3,
                })
                elapsed = 0
            end
            task.wait(0.5)
            elapsed = elapsed + 0.5
        end
    end

    return tool:FindFirstChild("origevent") or tool:FindFirstChild("Event", true)
end

-- ── Build list ────────────────────────────────────────────────────────────────
local function listBuilds()
    local ok, files = pcall(listfiles, SAVE_DIR .. "/")
    if not ok or type(files) ~= "table" then return {} end
    local names = {}
    for _, path in pairs(files) do
        local name = path:gsub(SAVE_DIR .. "[/\\]", ""):gsub("%.json$", "")
        if name ~= "" then table.insert(names, name) end
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

-- ── Pre-start config ──────────────────────────────────────────────────────────
local maxHistorySlider = tab:Slider({
    Title     = "Max History",
    Range     = {300, 10000},
    Increment = 1,
    Default   = 300,
    Callback  = function(val)
        cfg.historymax = val
    end,
})

-- Always live: works before and during a build
tab:Slider({
    Title     = "Resize Wait (s)",
    Range     = {0.05, 2},
    Increment = 0.05,
    Default   = 0.4,
    Callback  = function(val)
        cfg.resizewait = val
        if activeBuilder then activeBuilder:set_resize(val) end
    end,
})

local wbsToggle = tab:Toggle({
    Title    = "Auto Resize Wait (Ping)",
    Default  = false,
    Callback = function(bool)
        cfg.wbs = bool
        if activeBuilder then activeBuilder:settings().wbs = bool end
    end,
})

local fileDropdown = tab:Dropdown({
    Title    = "Saved Build",
    Options  = listBuilds(),
    Callback = function(val) selectedFile = val end,
})

tab:Button({
    Title    = "↺  Refresh Builds",
    Callback = function()
        fileDropdown:Refresh(listBuilds())
    end,
})

tab:Button({
    Title    = "Set Offset to Position",
    Callback = function()
        local char = localplr.Character
        if not char then return end
        local sp = workspace:FindFirstChild("Spawn")
        local origin = sp and sp.Position or Vector3.new(0, 0, 0)
        cfg.offset = origin + char.HumanoidRootPart.Position
        if activeBuilder then activeBuilder:settings().offset = cfg.offset end
    end,
})

tab:Button({
    Title    = "Reset Offset",
    Callback = function()
        cfg.offset = Vector3.new(0, 0, 0)
        if activeBuilder then activeBuilder:settings().offset = cfg.offset end
    end,
})

tab:Toggle({
    Title    = "Ghost Preview",
    Default  = false,
    Callback = function(bool)
        showEnabled = bool
        if activeBuilder then activeBuilder:show(bool) end
    end,
})

-- ── Build controls ────────────────────────────────────────────────────────────
local startButton, stopButton, skipButton

local function setBuilding(bool)
    if bool then
        maxHistorySlider:Lock()
        fileDropdown:Lock()
        wbsToggle:Lock()
        startButton:Lock()
        stopButton:Unlock()
        skipButton:Unlock()
    else
        maxHistorySlider:Unlock()
        fileDropdown:Unlock()
        wbsToggle:Unlock()
        startButton:Unlock()
        stopButton:Lock()
        skipButton:Lock()
        activeBuilder = nil
    end
end

startButton = tab:Button({
    Title    = "▶  Start",
    Callback = function()
        if not selectedFile then return end
        activeBuilder = lib.build(selectedFile, cfg, fetch_tools)
        if showEnabled then activeBuilder:show(true) end
        setBuilding(true)
        coroutine.wrap(function()
            activeBuilder:start()
            setBuilding(false)  -- fires whether build finished or was stopped
        end)()
    end,
})

stopButton = tab:Button({
    Title    = "■  Stop",
    Callback = function()
        if activeBuilder then
            activeBuilder:stop()
            setBuilding(false)
        end
    end,
})

skipButton = tab:Button({
    Title    = "▷  Skip Block",
    Callback = function()
        if activeBuilder then activeBuilder:skip() end
    end,
})

-- Locked until a build is running
stopButton:Lock()
skipButton:Lock()

-- ── Credits ───────────────────────────────────────────────────────────────────
tab:Paragraph({
    Title = "Credits",
    Desc  = "Credits to areyoumental (areyoumental110 in Discord),\nwe used Extra Stuff's (from areyoumental) source code for this.",
})
