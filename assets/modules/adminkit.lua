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



local plrs = game:GetService("Players")
local tcs = game:GetService("TextChatService")
local localplr = plrs.LocalPlayer

tcs.MessageReceived:Connect(function(msg)
  if msg.TextSource and msg.TextSource.UserId ~= localplr.UserId then
    if msg.Text:lower() == "hello" then
      tcs.TextChannels.RBXGeneral:SendAsync("hello")
    end
  end
end)