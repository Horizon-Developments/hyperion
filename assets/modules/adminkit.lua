local args = ...

local tabs = args.Tabs
-- tabs register or use tabs here.
local Window = args.Window
-- wind ui window used by Hyperion
local WindUI = args.WindUI
-- WindUi 
local assets = args.Assets
-- store files in assets("your folder") (don't forget to run makefolder though)



tabs.adminkit = Window:Tab({
  Title = "AdminKit",
  Icon = "wrench"
})

local plrs = game:GetService("Players")
local tcs = game:GetService("TextChatService")
local localplr = plrs.LocalPlayer
local tab = tabs.adminkit
local toggles = {}
local function cmd(c)
  tcs.TextChannels.RBXGeneral:SendAsync(";"..c.." [HYPERION REBORN]")
end

toggles.antijoin = {}

tab:Dropdown({
  Title = "Anti join*",
  Desc = "Prevents join og, vc, xl (:",
  Values = { "joinxl", "joinog", "joinvc" },
  Value = {},
  Multi = true,
  Callback = function(selected)
    toggles.antijoin = selected
  end
})

tcs.MessageReceived:Connect(function(msg)
  if not msg.TextSource or msg.TextSource.UserId == localplr.UserId then return end
  local text = msg.Text:lower():gsub("%s+", "")
  for _, v in ipairs(toggles.antijoin) do
    local keyword = v:lower()
    if text == keyword or text:sub(1, #keyword) == keyword or text:find(keyword, 1, true) then
      cmd("reset " .. msg.TextSource.Name)
      break
    end
  end
end)