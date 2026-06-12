local args = ...

local Tabs = args.Tabs
local Window = args.Window
local WindUI = args.WindUI
local Helpers = args.Helpers

local tab = Window:Tab({
  Title = "Spammer",
  Icon = "message-square",
})

local spamV = false
local spamW = 0.1
local spamT = {}

tab:Section("Spammer")
tab:Paragraph({
  Title = "spammer (warning)",
  Desc = "do not add ';', input nil to remove a slot"
})

tab:Toggle({
  Title = "spammer",
  Callback = function(v)
    spamV = v
    task.spawn(function()
      pcall(function()
        while spamV do
          if #spamT > 0 then return end
          for i, cmd in ipairs(spamT) do
            task.wait(spamW)
            Helpers.cmd(cmd)
          end
          task.wait(0.1)
        end
      end)
    end)
  end
})

tab:Slider({
  Title = "Delay",
  Range = {0.2, 30},
  Increment = 0.1,
  Default = 0.5,
  Callback = function(val)
    spamW = val
  end
})
tab:Section("Command Slots")
for i = 1, 5 do
  tab:Input({
    Title = "slot " .. i,
    Placeholder = "TextHere",
    Callback = function(v)
      spamT[i] = (v ~= "nil" and v ~= "") and v or nil
    end
  })
end