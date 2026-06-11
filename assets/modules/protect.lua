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
    
    
end
