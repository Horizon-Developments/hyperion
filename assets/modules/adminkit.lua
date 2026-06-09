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

local tab = tabs.adminkit
local toggles = {}


tab:Dropdown({
  Title = "Anti join*",
  Desc = "Prevents join* (:",
  Values = { "joinxl", "joinog", "joinvc" },
  Value = {},
  Multi = true,
  Callback = function(selected)
    toggles.antijoin = selected
  end
})









Players.PlayerAdded:Connect(function(player)
  player.Chatted:Connect(function(msg)
    if msg:lower() == "hello" then
      game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents")
        :WaitForChild("SayMessageRequest"):FireServer("hello", "All")
    end
  end)
end)

for _, player in ipairs(Players:GetPlayers()) do
  if player ~= localplr then
    player.Chatted:Connect(function(msg)
      if msg:lower() == "hello" then
        game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents")
          :WaitForChild("SayMessageRequest"):FireServer("hello", "All")
      end
    end)
  end
end