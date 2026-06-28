local args = ...
local Window = args.Window
local Tabs = args.Tabs
local Obsidian = args.Obsidian
local Helpers = args.Helpers
local assets = args.Assets

Tabs.plugins = Window:AddTab("Auto Join", "blocks")
local box = Tabs.plugins:AddLeftGroupbox("Auto Join")

local function joinfn(_type)
  if not ({ xl = true, og = true, vc = true })[_type] then return end
  local gui = Instance.new("ScreenGui")
  gui.IgnoreGuiInset = true
  gui.ResetOnSpawn = false
  gui.Parent = (gethui and gethui()) or Helpers.services..coregui or Helpers.services..players.LocalPlayer:WaitForChild("PlayerGui")
  
  local blur = Instance.new("BlurEffect")
  blur.Size = 24
  blur.Parent = Helpers.services..lighting
  
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

local path = assets(".join_toggle")

box:AddLabel({ Text = "Automatically joins selected when executing the script", DoesWrap = true })
dropdown = box:AddDropdown("join.dropdown", {
  Values     = {
    "og",
    "xl",
    "vc"
  },
  Default    = (function()
    if isfile(path) then
      local ok,dat = pcall(readfile,path)
      return ok and dat or nil
    end
    return
  end)(),
  Multi      = false,
  Text       = "",
  Searchable = false,
  Callback   = function(val)
    if val ~= nil then
      writefile(path, val)
    else
      pcall(delfile,path)
    end
    Obsidian:Notify({ Title = "Set value!", Description = "This will take effect once hyperion is loaded again", Time = 3 })
  end,
  Disabled = false,
  Visible  = true,
})


if isfile(path) then joinfn(readfile(path)) end