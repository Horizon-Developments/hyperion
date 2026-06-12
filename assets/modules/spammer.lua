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
local spamW = 0.5
local spamT = {}

tab:Paragraph({
  Title = "Info",
  Desc = "do not add ';', input nil to remove a slot"
})

tab:Toggle({
  Title = "spammer",
  Callback = function(v)
    spamV = v

    if not v then
      return
    end

    task.spawn(function()
      while spamV do
        local sent = false

        for i = 1, 5 do
          local cmd = spamT[i]
          if cmd then
            sent = true
            Helpers.cmd(cmd)
            task.wait(spamW)

            if not spamV then
              break
            end
          end
        end

        if not sent then
          task.wait(0.1)
        end
      end
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