if getgenv().Hyperion then
  return
end
getgenv().Hyperion = true

local HttpService = game:GetService("HttpService")

local function assets(...)
	return table.concat({ "HyperionHub", ... }, "/")
end
local function log(...)
  print("[HYPERION]: ",...)
end

do
  makefolder("HyperionHub")
  makefolder(assets("modules"))
  
  local function createfile(url)
    writefile(assets(url), game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/main/assets/" .. url))
  end
  
  createfile("hyperion_logo.jpg")
  createfile("discord_invite.txt")
  
  local ok, result = pcall(function()
    return HttpService:JSONDecode(game:HttpGet("https://api.github.com/repos/Horizon-Developments/hyperion/contents/assets/modules"))
  end)
  if not ok then
    log("Failed to fetch built-in modules.")
  else
    for i, item in ipairs(result) do
      if item.type == "file" then
        local fn = (function()
          local ok, err = pcall(function()
            writefile(assets("modules", item.name), game:HttpGet(item.download_url))
          end)
          if (not ok) then
            log("Fetching ", item.download_url, " failed. ERR: ", err)
          end
        end)
        if (i ~= #result)  then
          task.spawn(fn)
        else 
          fn()
        end
      end
    end
  end
end



local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
	Title = "Hyperion (Reborn)",
	Icon = "zap",
	Author = "by horizonscript in discord",
	Folder = "HyperionHub",
	Transparent = true,
	BackgroundImageTransparency = 0.42,
	ToggleKey = Enum.KeyCode.RightShift,
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

for _, file in ipairs(listfiles(assets("modules"))) do
  local ok, err = task.spawn(pcall, loadstring(readfile(file)), { Tabs = tabs, Window = Window, WindUI = WindUI }))
  if not ok then
    warn("Failed to execute:", file, err)
  end
end