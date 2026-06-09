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









local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local localplr = Players.LocalPlayer

TextChatService.MessageReceived:Connect(function(msg)
  if msg.TextSource and msg.TextSource.UserId ~= localplr.UserId then
    if msg.Text:lower() == "hello" then
      TextChatService.TextChannels.RBXGeneral:SendAsync("hello")
    end
  end
end)