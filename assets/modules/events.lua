return function(opts)
    local Tabs = opts.Tabs
    local Window = opts.Window
    local WindUI = opts.WindUI
    local Helpers = opts.Helpers
    
    local tab = Window:Tab({
        Title = "Events",
        Icon = "calendar",
    })
    
    local tcs = Helpers.services.textchat
    local chat = tcs.TextChannels.RBXGeneral
    local plrs = Helpers.services.players
    local localplr = plrs.LocalPlayer
    
    local OnJoinedAge = 0
    local OnJoinedV = false
    local OnJoinedT = {}
    local OnJoinedB = {"f<〪xลq"}
    
    tab:Section("On Player Join")
    tab:Paragraph({
        Title = "On Player Join",
        Desc = "Executes a command when a player joins. Format: ';[command] PlayerName'"
    })
    
    tab:Toggle({
        Title = "toggle",
        Callback = function(v)
            OnJoinedV = v
        end
    })
    
    plrs.PlayerAdded:Connect(function(plr)
        task.wait(2)
        if plr.AccountAge >= OnJoinedAge then
            if not next(OnJoinedB) then return end
            for i, v in ipairs(OnJoinedB) do
                if string.find(plr.Name, v) then return end
            end
            
            if OnJoinedV then
                for i, v in ipairs(OnJoinedT) do
                    task.wait(0.1)
                    chat:SendAsync(";" .. v .. " " .. plr.Name:split("_")[1])
                end
            end
        end
    end)
    
    tab:Section("Command Slots")
    for i = 1, 5 do
        tab:Input({
            Title = "slot " .. i,
            Placeholder = "TextHere",
            Callback = function(v)
                if v ~= "" then
                    OnJoinedT[i] = v
                else
                    OnJoinedT[i] = nil
                end
            end
        })
    end
    
    tab:Section("Blacklisted Keywords")
    tab:Paragraph({
        Title = "Blacklisted Keywords",
        Desc = "If a player has a blacklisted keyword, the script will not execute the commands."
    })
    
    tab:Input({
        Title = "Insert Keywords",
        Placeholder = " ",
        Callback = function(v)
            if v ~= "" then
                table.insert(OnJoinedB, v:lower())
                WindUI:Notify({ Title = "added.", Content = "", Duration = 2 })
            end
        end
    })
    
    tab:Input({
        Title = "remove keywords",
        Placeholder = "no msg = not found",
        Callback = function(val)
            for i, v in ipairs(OnJoinedB) do
                if string.find(v, val:lower()) then
                    table.remove(OnJoinedB, i)
                    WindUI:Notify({ Title = "removed", Content = "keyword " .. v, Duration = 2 })
                    break
                end
            end
        end
    })
    
    tab:Section("Account Age Filter")
    tab:Input({
        Title = "age needed to run (days, 0 default)",
        Placeholder = "anti alts",
        Callback = function(v)
            OnJoinedAge = tonumber(v) or 0
        end
    })
end
