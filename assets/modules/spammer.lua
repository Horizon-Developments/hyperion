return function(opts)
    local Tabs = opts.Tabs
    local Window = opts.Window
    local WindUI = opts.WindUI
    local Helpers = opts.Helpers
    
    local tab = Window:Tab({
        Title = "Spammer",
        Icon = "message-square",
    })
    
    local tcs = Helpers.services.textchat
    local chat = tcs.TextChannels.RBXGeneral
    
    local spamV = false
    local spamW = 0.1
    local spamT = {}
    
    tab:Section("Spammer")
    tab:Paragraph({
        Title = "spammer (warning)",
        Desc = "do not add ';' i have already added it auto, if you add it ';' it will not work , input nil to remove a slot"
    })
    
    tab:Toggle({
        Title = "spammer",
        Callback = function(v)
            spamV = v
            task.spawn(function()
                pcall(function()
                    while spamV do
                        if #spamT > 0 then
                            for i, cmd in ipairs(spamT) do
                                task.wait(spamW)
                                if cmd then
                                    chat:SendAsync(";" .. cmd .. " #HYPERION#SPAMMER#")
                                end
                            end
                        end
                        task.wait(0.01)
                    end
                end)
            end)
        end
    })
    
    tab:Slider({
        Title = "Delay",
        Range = {0.2, 99999999},
        Increment = 0.001,
        Default = 0.1,
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
end
