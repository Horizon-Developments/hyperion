local args = ...
local Tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local Helpers = args.Helpers
local Assets = args.Assets

local Options = Obsidian.Options
local Toggles = Obsidian.Toggles

local HttpService = game:GetService("HttpService")
local saveFile = Assets(".saved_clipboard")
local path = Assets(".join_toggle")

-- Single combined tab
Tabs.main = Window:AddTab("Clipboard", "clipboard")

local joinBox  = Tabs.main:AddLeftGroupbox("Auto Join")
local clipBox  = Tabs.main:AddRightGroupbox("Saved Clipboard")

-- ── AUTO JOIN ──────────────────────────────────────────────────────────────────

if isfile(path) then
  local _type = readfile(path)
  if ({ xl = true, og = true, vc = true })[_type] then
    local gui = Instance.new("ScreenGui")
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = (gethui and gethui()) or Helpers.services.coregui or Helpers.services.players.LocalPlayer:WaitForChild("PlayerGui")

    local blur = Instance.new("BlurEffect")
    blur.Size = 24
    blur.Parent = Helpers.services.lighting

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bg.BackgroundTransparency = 1
    bg.BorderSizePixel = 0
    bg.Parent = gui

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 0.1)
    text.Position = UDim2.fromScale(0, 0.3)
    text.BackgroundTransparency = 1
    text.Text = ""
    text.TextColor3 = Color3.fromRGB(255, 0, 0)
    text.TextScaled = true
    text.Font = Enum.Font.FredokaOne
    text.Parent = bg

    local button = Instance.new("TextButton")
    button.Size = UDim2.fromScale(0.3, 0.1)
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.Position = UDim2.fromScale(0.5, 0.6)
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = "Cancel"
    button.TextScaled = true
    button.Font = Enum.Font.FredokaOne
    button.BorderSizePixel = 0
    button.Parent = bg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button

    local function uihandler()
      text:Destroy()
      button:Destroy()
      blur:Destroy()
      gui:Destroy()
    end

    local canceled = false
    button.MouseButton1Click:Connect(function()
      canceled = true
      uihandler()
    end)

    task.spawn(function()
      local dots = { ".", "..", "..." }
      local last = 0
      for i = 20, 0, -1 do
        if canceled then return end
        if last == 3 then last = 0 end
        button.Text = "Joining " .. _type .. dots[last + 1]
        last = last + 1
        task.wait(0.2 + math.random(5, 12) / 90)
      end

      if canceled then return end

      game:GetService("TeleportService"):Teleport(
        _type == "xl" and 12943245078 or
        _type == "vc" and 12943247001 or
        _type == "og" and 108097274488844
      )
      uihandler()
    end)
  end
end

joinBox:AddLabel({ Text = "Automatically joins selected when executing the script", DoesWrap = true })
joinBox:AddDropdown("join.dropdown", {
  Values     = { "og", "xl", "vc", "none" },
  Default    = (function()
    if isfile(path) then
      local ok, dat = pcall(readfile, path)
      return ok and dat or nil
    end
  end)(),
  Multi      = false,
  Text       = "",
  Searchable = false,
  Callback   = function(val)
    if val ~= "none" then
      writefile(path, val)
    else
      pcall(delfile, path)
    end
    Obsidian:Notify({ Title = "Set value!", Description = "This will take effect once hyperion is loaded again", Time = 3 })
  end,
  Disabled = false,
  Visible  = true,
})

-- ── CLIPBOARD ─────────────────────────────────────────────────────────────────

local inputText = ""
local saveName  = ""
local saves     = {}

local function saveData()
  local ok, encoded = pcall(HttpService.JSONEncode, HttpService, saves)
  if not ok then return end
  pcall(writefile, saveFile, encoded)
end

local function loadData()
  local ok, raw = pcall(readfile, saveFile)
  if not ok or not raw or raw == "" then return end
  local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
  if not ok2 or not data then return end
  saves = data
end

local function refreshDropdown()
  local names = {}
  for name in pairs(saves) do table.insert(names, name) end
  Options["clipboard@select.dropdown"]:SetValues(names)
end

loadData()

clipBox:AddInput("clipboard@text.input", {
  Text = "Input text to save",
  ClearTextOnFocus = false,
  Finished = false,
  Callback = function(v) inputText = v end,
})

clipBox:AddInput("clipboard@name.input", {
  Text = "Name of save",
  ClearTextOnFocus = false,
  Finished = false,
  Callback = function(v) saveName = v end,
})

clipBox:AddButton("clipboard@save.button", {
  Text = "Save",
  Func = function()
    if saveName == "" then return end
    saves[saveName] = inputText
    saveData()
    refreshDropdown()
  end,
})

clipBox:AddDropdown("clipboard@select.dropdown", {
  Values     = {},
  Default    = 1,
  Multi      = false,
  Text       = "Select save",
  Searchable = true,
})

clipBox:AddButton("clipboard@copy.button", {
  Text = "Copy selected",
  Func = function()
    local selected = Options["clipboard@select.dropdown"].Value
    if not selected or not saves[selected] then return end
    setclipboard(saves[selected])
  end,
})

clipBox:AddButton("clipboard@delete.button", {
  Text = "Delete selected",
  Func = function()
    local selected = Options["clipboard@select.dropdown"].Value
    if not selected or not saves[selected] then return end
    saves[selected] = nil
    saveData()
    refreshDropdown()
  end,
})

refreshDropdown()