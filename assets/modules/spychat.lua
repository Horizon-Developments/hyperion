local args = ...

local tabs = args.Tabs
-- tabs register or use tabs here.
local Window = args.Window
-- wind ui window used by Hyperion
local WindUI = args.WindUI
-- WindUi 
local assets = args.Assets
-- store files in assets("your folder") (don't forget to run makefolder though)

tabs.spychat = Window:Tab({
  Title = "Spychat (Fixed)",
  Icon = "hat-glasses"
})

local plrs = game:GetService("Players")
local tcs = game:GetService("TextChatService")
local localplr = plrs.LocalPlayer
local tab = tabs.spychat
local toggles = {}

tab:Toggle({
  Title = "Spychat",
  Desc = "Toggle Description",
  Icon = "bird",
  Type = "Checkbox",
  Value = false,
  Callback = function(val) 
    
    
    
    
    
    
    
  end
})
local tcmp = Instance.new("TextChatMessageProperties")
tcs.OnIncomingMessage = function(m) 
  
  
  
  
  
  return tcmp
end