local args = ...
local Tabs = args.Tabs
local Window = args.Window
local Obsidian = args.Obsidian
local Helpers = args.Helpers

local tab = Window:AddTab("Spammer", "message-square")
local box = tab:AddLeftGroupbox("Spammer")

local spamV = false
local spamW = 0.5
local spamT = {}

box:AddLabel({ Text = "Info: do not add ';'" })

box:AddToggle("spammerToggle", {
  Text = "Spammer",
  Default = false,
  Callback = function(v)
    spamV = v
    if not v then return end
    task.spawn(function()
      while spamV do
        local sent = false
        for i = 1, 5 do
          local cmd = spamT[i]
          if cmd then
            sent = true
            Helpers.cmd(cmd)
            task.wait(spamW)
            if not spamV then break end
          end
        end
        if not sent then task.wait(0.1) end
      end
    end)
  end
})

box:AddSlider("spamDelay", {
  Text = "Delay",
  Min = 0.2,
  Max = 30,
  Default = 0.5,
  Rounding = 1,
  Callback = function(val)
    spamW = val
  end
})

box:AddDivider()
box:AddLabel({ Text = "Command Slots" })

for i = 1, 5 do
  box:AddInput("spamSlot" .. i, {
    Text = "Slot " .. i,
    Placeholder = "TextHere",
    Finished = false,
    Callback = function(v)
      spamT[i] = (v ~= "nil" and v ~= "") and v or nil
    end
  })
end
