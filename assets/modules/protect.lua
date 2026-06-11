return function(opts)
    local Tabs = opts.Tabs
    local Window = opts.Window
    local WindUI = opts.WindUI
    local Helpers = opts.Helpers
    
    local tab = Window:Tab({
        Title = "Protect",
        Icon = "shield",
    })
    
    local tcs = Helpers.services.textchat
    local chat = tcs.TextChannels.RBXSystem
    local plrs = Helpers.services.players
    local rs = Helpers.services.run
    local localplr = plrs.LocalPlayer
    
    local whitelisted = {}
    local isWhitelist = false
    local IsReset = false
    
    local bomb = false
    local heart = false
    local rc = false
    local enli = false
    local subp = false
    local mines = false
    
    -- Auto debug monitoring
    rs.RenderStepped:Connect(function()
        if bomb and workspace:FindFirstChild("FuseBomb") then
            chat:SendAsync(";debug")
            WindUI:Notify({ Title = "Auto Debug", Content = "debuged, FuseBomb", Duration = 1 })
        end
        if heart and workspace:FindFirstChild("Effect") then
            chat:SendAsync(";debug")
            WindUI:Notify({ Title = "Auto Debug", Content = "debuged, HeartAttack/Effect", Duration = 1 })
        end
        if rc and workspace:FindFirstChild("Tank") then
            chat:SendAsync(";debug")
            WindUI:Notify({ Title = "Auto Debug", Content = "debuged, RcTank", Duration = 1 })
        end
        if enli and workspace:FindFirstChild("The Arkenstone") and workspace["The Arkenstone"]:FindFirstChild("Handle") then
            chat:SendAsync(";debug")
            WindUI:Notify({ Title = "Auto Debug", Content = "debuged, The Arkenstone", Duration = 1 })
        end
        if subp and workspace:FindFirstChild("SubspaceTripmine") then
            chat:SendAsync(";debug")
            WindUI:Notify({ Title = "Auto Debug", Content = "debuged, Subspace", Duration = 1 })
        end
        if mines and workspace:FindFirstChild("Mine") then
            chat:SendAsync(";debug")
            WindUI:Notify({ Title = "Auto Debug", Content = "debuged, Mines", Duration = 1 })
        end
    end)
    
    rs.RenderStepped:Connect(function()
        if workspace:FindFirstChild(localplr.Name) and workspace[localplr.Name]:FindFirstChild("The Arkenstone") and IsReset then
            for _ = 1, 5 do
                chat:SendAsync(";reset me HYPERION")
            end
        end
    end)
    
    tab:Section("Auto debug")
    tab:Toggle({
        Title = "anti drop enli",
        Callback = function(v)
            enli = v
        end,
    })
    
    tab:Toggle({
        Title = "anti rctank",
        Callback = function(v)
            rc = v
        end,
    })
    
    tab:Toggle({
        Title = "anti Heart Attack",
        Callback = function(v)
            heart = v
            WindUI:Notify({ Title = "WARNING", Content = "heart attck is named effect, other gears may trigger this.", Duration = 3 })
        end,
    })
    
    tab:Toggle({
        Title = "anti FuseBomb",
        Callback = function(v)
            bomb = v
        end,
    })
    
    tab:Toggle({
        Title = "anti subspace",
        Callback = function(v)
            subp = v
        end,
    })
    
    tab:Toggle({
        Title = "anti mines",
        Callback = function(v)
            mines = v
        end,
    })
end
