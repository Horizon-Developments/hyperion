local args = ...

local tabs = args.Tabs
local Window = args.Window
local WindUI = args.WindUI
local assets = args.Assets
local Helpers = args.Helpers

tabs.adminkit = Window:Tab({
  Title = "AdminKit",
  Icon = "wrench"
})

local tab = tabs.adminkit
local tcs = Helpers.services.textchat
local localplr = Helpers.services.players.LocalPlayer
local toggles = { antijoin = {} }


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
tab:Divider()
tab:Paragraph({
  Title = "Bkit W5çhitelist",
  Icon = "toolbox",
  Desc = ""
})
tab:Button({
  Title = "Enable",
    Desc = "",
    Locked = false,
    Callback = function()
        -- ...
    end
})



Helpers.on("ChatListener", function(msg)
  if not msg.TextSource or msg.TextSource.UserId == localplr.UserId then return end
  local text = msg.Text:lower():gsub("%s+", "")
  for _, v in ipairs(toggles.antijoin) do
    local keyword = v:lower()
    if text == keyword or text:sub(1, #keyword) == keyword or text:find(keyword, 1, true) then
      Helpers.cmd("reset " .. msg.TextSource.Name)
      break
    end
  end
end)