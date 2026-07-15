local args = ...
local Tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local Helpers = args.Helpers
local Assets = args.Assets

local api = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/api.lua"))()

local botInstance = nil

print("BOTTER.LUA", pcall(function()
  Tabs.botting = Window:AddTab("Botting", "bot")
  local lbox = Tabs.botting:AddLeftGroupbox("")
  local rbox = Tabs.botting:AddRightGroupbox("")
  
  lbox:AddLabel([[
Hyperion Special

Tired of logging into your alts just to donate or run commands?
Now you only need to execute once on each bot.

Setup:
Generate a loadstring for ur bots
Copy the generated script into your bots Autoexecute.
Execute it on each bot then done.

commands can be sent through chat using the "hx." prefix or from this tab.

commands:

donate player? time?
Donates to the specified player. If no time is given, it donates all the time.

join
Makes all bots join your current server.
]], true)
  lbox:AddDivider()
  rbox:AddDivider()
  
  rbox:AddButton({
    Text = "Generate Bot URL",
    Func = function()
      local ok, result = api.Bots:CreateInstance()
      if not ok then
        return Obsidian:Notify({
          Title = "Error",
          Description = tostring(result),
          Time = 3,
        })
      end
      
      botInstance = result
      setclipboard(botInstance:GetClientScript())
      Obsidian:Notify({
        Title = "Success!",
        Description = "Script copied to clipboard. Put it in your bots Autoexecute.",
        Time = 4,
      })
    end,
  })

  task.spawn(function()
    local ok, result = api.Bots:CreateInstance()
    if not ok then
      return Obsidian:Notify({
        Title = "Botting",
        Description = "Failed to auto-connect: " .. tostring(result),
        Time = 5,
      })
    end
    botInstance = result
    Obsidian:Notify({
      Title = "Botting",
      Description = "Auto-connected to relay.",
      Time = 5,
    })
  end)
  
  Helpers.on("ChatListener", function(msg)
    if not botInstance or not botInstance.Authenticated then return end
    if not msg.TextSource or msg.TextSource.UserId ~= game:GetService("Players").LocalPlayer.UserId then return end
    if msg.Text:sub(1, 3) ~= "hx." then return end
    botInstance:SendAsync(msg.Text:sub(4))
  end)
end))