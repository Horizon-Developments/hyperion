return function(opts)
    local Tabs = opts.Tabs
    local Window = opts.Window
    local WindUI = opts.WindUI
    local Helpers = opts.Helpers
    
    local tab = Window:Tab({
        Title = "Abuser",
        Icon = "zap",
    })
    
    local tcs = Helpers.services.textchat
    local chat = tcs.TextChannels.RBXSystem
    local chatG = tcs.TextChannels.RBXGeneral
    local plrs = Helpers.services.players
    local localplr = plrs.LocalPlayer
    
    local sa = false
    local cmdsOnce = {";delcubes a", ";fog nan", ";delclones a", ";maptide nan", ";oof a", ";mapsize 0", ";seatide nan", ";seasize nan", ";oof a", ";colorless", ";myopic o", ";fog nan"}
    local cmds = {";reset me", ";clearinv o", ";reset me", ";freeze o", ";reset me", ";blind o", ";reset me", ";mute o", ";reset me", ";reset me"}
    
    local hyp = {"f<〪xลq", "p<บvŗ", "x<ɱqf", "g<ỵp〪", "ค<f〪gศ", "ทf<ⴭบ", "q<gxร", "p<vxf", "ล<gf<ɱ", "gx<f〪p", "p<xv〪", "hx<fg", "v<ลb〪q", "f<qล<x", "b<f〪p<q"}
    local hyp1 = {"x<gpv", "ร<f〪pq", "f<qgx", "pv<fg", "g<xb〪p", "v<pg<x", "x<pv〪", "p<ลg<x", "qf<ⴭร", "f<gv<q", "gx<vf", "vf<xล", "รx<pg", "g<ลf<q", "xb〪<fp"}
    local hypW = {"ŗ<ล<ἱ<ɗ<e<ɗ b<〪ỵ h<ỵ<p<e<ŗ<ἱ<о<ท", " g<et〪 h<ỵ<p<e<ŗ<ἱ<о<ท ล<t〪 ร<с〪<ŗ<ἱ<p<t<〪b<〪ӏ<о<x", " #ј<о<ἱ<ท h<ỵ<p<e<ŗ<ἱ<о<ท"}
    
    local aura = {
        istrue = false,
        build = false,
        delete = false
    }
    
    tab:Section("Server Abuser")
    tab:Paragraph({
        Title = "Server abuser (info)",
        Desc = "you need The ArkenStone for this, removed lag server because it is not effective."
    })
    
    tab:Toggle({
        Title = "server abuser",
        Callback = function(v)
            sa = v
            if sa then
                for i = 1, #cmdsOnce do
                    task.wait(0.05)
                    chat:SendAsync(cmdsOnce[i] .. " HYPERION")
                end
                task.spawn(function()
                    while sa do
                        for i = 1, #cmds do
                            task.wait(0.05)
                            chat:SendAsync(cmds[i])
                        end
                    end
                end)
            end
        end
    })
    
    tab:Section("Advertise")
    tab:Paragraph({
        Title = "advertise (info)",
        Desc = "pls advertise hyperion"
    })
    
    tab:Button({
        Title = "advertise hyperion",
        Callback = function()
            if not sa then
                hypW[1] = "#ј<о<ἱ<ท h<ỵ<p<e<ŗ<ἱ<о<ท"
            elseif sa then
                hypW[1] = "ŗ<ล<ἱ<ɗ<e<ɗ b<〪ỵ h<ỵ<p<e<ŗ<ἱ<о<ท"
            end
            for i = 1, #hypW do
                task.wait(0.3 + math.random(0.1, 0.5))
                chatG:SendAsync(";[" .. hyp[math.random(#hyp)] .. hyp1[math.random(#hyp1)] .. "]" .. hypW[i])
            end
        end
    })
    
    tab:Section("Flashbang")
    tab:Paragraph({
        Title = "flashbang (info)",
        Desc = "makes screen white, may not work."
    })
    
    tab:Button({
        Title = "flashbang glitch",
        Callback = function()
            chat:SendAsync(";flashbang")
            task.wait(2)
            for _,v in pairs(localplr.Backpack:GetChildren()) do 
                if v.Name=="Flashbang" then
                    v.Parent=localplr.Character
                    task.wait(0.1)
                    v:Activate() 
                    break 
                end
            end
            task.wait(2)
            task.spawn(function()
                while not localplr:WaitForChild("PlayerGui"):WaitForChild("GuiMain"):FindFirstChild("FlashBangEffect") do
                    task.wait()
                end
                chat:SendAsync(";debug")
            end)
        end
    })
    
    tab:Section("Lag Everyone")
    tab:Paragraph({
        Title = "lag everyone",
        Desc = "lags everyone (you too). do not oof/clearinv the target, this takes a while and spams gears so you cant do cmds temp"
    })
    
    tab:Section("Abuse Player")
    tab:Paragraph({
        Title = "abuse plr",
        Desc = "freezes, jails.. etc"
    })
    
    tab:Input({
        Title = "plrName",
        Placeholder = "plrName",
        Callback = function(v)
            local abuseplr = {"freeze", "jail", "glitch", "mute", "noclip"}
            for _, val in ipairs(abuseplr) do
                chat:SendAsync(";" .. val .. " " .. v)
                task.wait(0.2)
            end
        end
    })
    
    tab:Section("Auto Grief")
    tab:Paragraph({
        Title = "auto greif (info)",
        Desc = "teleports under a player (5 studs under) and greifs (delete, build or both)"
    })
    
    tab:Toggle({
        Title = "auto greif [beta]",
        Callback = function(v)
            aura.istrue = v
            
            local build = localplr.Backpack:FindFirstChild("Build") or localplr.Character:FindFirstChild("Build")
            task.spawn(function()
                while aura.build and aura.istrue and task.wait(0.1) do
                    if build and aura.build then
                        build.Script.Event:FireServer(workspace.Terrain, Enum.NormalId.Top, localplr.Character.HumanoidRootPart.Position)
                    end
                end
            end)
            
            task.spawn(function()
                while aura.istrue do
                    localplr.Character.HumanoidRootPart.Anchored = false
                    for _, plr in ipairs(plrs:GetPlayers()) do
                        for _, part in ipairs(localplr.Character:GetChildren()) do
                            if part:IsA("BasePart") then
                                game:GetService("TweenService"):Create(part, TweenInfo.new(1), {Position = plr.Character.HumanoidRootPart.Position - Vector3.new(0, 5, 0)}):Play()
                            end
                        end
                    end
                    localplr.Character.HumanoidRootPart.Anchored = true
                    task.wait(3)
                    localplr.Character.HumanoidRootPart.Anchored = false
                end
            end)
            
            task.spawn(function()
                while aura.delete and aura.istrue and task.wait(0.1) do
                    for _,v in ipairs(workspace:GetDescendants()) do
                        if v:IsA("BasePart") and (v.Position - localplr.Character.HumanoidRootPart.Position).Magnitude < 30 then
                            v:Destroy()
                        end
                    end
                end
            end)
        end
    })
    
    tab:Toggle({
        Title = "build aura",
        Callback = function(v)
            aura.build = v
        end
    })
    
    tab:Toggle({
        Title = "delete aura",
        Callback = function(v)
            aura.delete = v
        end
    })
end
