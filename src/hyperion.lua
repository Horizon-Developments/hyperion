task.spawn(function()
  if getgenv().Hyperion then
    return
  end
  getgenv().Hyperion = true
  
  local HttpService = game:GetService("HttpService")
  
  local function assets(...)
  	return table.concat({ "Hyperion", ... }, "/")
  end
  local function log(...)
    print("[HYPERION]: ",...)
  end
  
  do
    makefolder("Hyperion")
    makefolder(assets("modules"))
    
    local function createfile(url)
      writefile(assets(url), game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/main/assets/" .. url))
    end
    
    createfile("hyperion_logo.jpg")
    createfile("discord_invite.txt")
    
    local CACHE_PATH = assets("modules", ".sha_cache.json")
    
    local shaCache = {}
    local cacheOk, cacheData = pcall(function()
      return HttpService:JSONDecode(readfile(CACHE_PATH))
    end)
    if cacheOk and type(cacheData) == "table" then
      shaCache = cacheData
    end
    
    local ok, result = pcall(function()
      return HttpService:JSONDecode(game:HttpGet("https://api.github.com/repos/Horizon-Developments/hyperion/contents/assets/modules"))
    end)
    
    if not ok then
      print(result)
      log("Failed to fetch built-in modules.")
    else
      local remoteNames = {}
      local pending = 0
      
      for _, item in ipairs(result) do
        if item.type == "file" then
          remoteNames[item.name] = true
          if shaCache[item.name] == item.sha then
            log("Skipped " .. item.name)
          else
            pending += 1
            task.spawn(function()
              pcall(function()
                writefile(assets("modules", item.name), game:HttpGet(item.download_url))
                shaCache[item.name] = item.sha
              end)
              pending -= 1
            end)
          end
        end
      end
      
      repeat task.wait(0.2) until pending <= 0
      
      for name in pairs(shaCache) do
        if not remoteNames[name] then
          pcall(function() delfile(assets("modules", name)) end)
          shaCache[name] = nil
          log("Deleted " .. name)
        end
      end
      
      pcall(function()
        writefile(CACHE_PATH, HttpService:JSONEncode(shaCache))
      end)
    end
  end
  
  
  
  local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
  
  WindUI:AddTheme({
  	Name = "Hyperion",
  	Accent = Color3.fromHex("#cc0000"),
  	Background = Color3.fromHex("#0a0a0a"),
  	Outline = Color3.fromHex("#cc0000"),
  	Text = Color3.fromHex("#ffffff"),
  	Placeholder = Color3.fromHex("#666666"),
  	Button = Color3.fromHex("#1a1a1a"),
  	Icon = Color3.fromHex("#cc0000"),
  })
  
  local savedTheme = isfile(assets("theme.txt")) and readfile(assets("theme.txt")) or "Hyperion"
  
  local Window = WindUI:CreateWindow({
  	Title = "Hyperion (Reborn)",
  	Icon = "zap",
  	Author = "by horizonscript in discord",
  	Folder = "Hyperion",
  	Transparent = true,
  	BackgroundImageTransparency = 0.42,
  	ToggleKey = Enum.KeyCode.RightShift,
  	Theme = savedTheme
  })
  
  local tabs = {}
  
  tabs.info = Window:Tab({
  	Title = "Main",
  	Icon = "home",
  })
  
  tabs.info:Paragraph({
    Title = "Hyperion Hub",
    Desc = "Join our Discord for suggestions, updates, and help.",
    Image = getcustomasset(assets("hyperion_logo.jpg")),
    Buttons = {
      {
        Icon = "copy",
        Title = "Copy Invite",
        Callback = function()
          setclipboard(readfile(assets("discord_invite.txt")))
          WindUI:Notify({ Title = "Copied!", Content = "Discord link copied to clipboard.", Duration = 3 })
        end,
      }
    },
  })
  tabs.info:Paragraph({
      Title = "About Hyperion",
      Icon = "layers",
      Desc = "Hyperion is a modular system. Instead of using a separate script, you can extend it with plugins. Visit the #plugins channel on our Discord to find and share plugins.",
  })
  tabs.info:Paragraph({
      Title = "Adding a Plugin",
      Icon = "folder-plus",
      Desc = "Place your plugin file in HyperionHub/modules/ (located inside your executor's folder.)",
  })
  tabs.info:Paragraph({
      Title = "Creating Your Own Plugin",
      Icon = "code-2",
      Desc = "Full documentation is available on #plugins-dev (our Discord server.)",
  })
  
  
  tabs.info:Dropdown({
  	Title = "Theme",
  	Icon = "palette",
  	Values = { "Hyperion", "Dark", "Light", "Rose", "Plant", "Indigo", "Sky", "Violet", "Amber" },
  	Value = savedTheme,
  	Callback = function(value)
  		writefile(assets("theme.txt"), value)
  		WindUI:SetTheme(value)
  	end
  })
  
  for _, file in ipairs(listfiles(assets("modules"))) do
    local ok, err = pcall(loadstring(readfile(file)), { Tabs = tabs, Window = Window, WindUI = WindUI })
    if not ok then
      warn("Failed to execute:", file, err)
    end
  end
end)