--[[
task.spawn(loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/loader.lua"))())
]]
if typeof(_G.getgenv) ~= "function" then
  _G.getgenv = function() return _G end
end

if getgenv().hyperion and not getgenv().DEBUG then return end
getgenv().hyperion = true

local AppendLog = "[HYPERION]: "

local _error = error
local _warn = warn
local _print = print

local function error(Text, ErrorLevel)
  _error(AppendLog .. Text, (ErrorLevel or 1) + 1)
end
local function warn(...)
  _warn(AppendLog, ...)
end
local function print(...)
  _print(AppendLog, ...)
end

print("Loader start")

local CloneRef = getgenv().cloneref or function(a) return a end

if not getgenv().cloneref then
  print("cloneref not found, using polyfill")
end

local Api              = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/api.lua"))()
local ModulesInstaller;


do
	local ModulesInstallerOk;
	ModulesInstallerOk, ModulesInstaller = pcall(loadstring, ModulesInstaller)

	if not ModulesInstallerOk then
		error("Install manager loadstring failed: " .. tostring(ModulesInstaller))
	end

	ModulesInstaller = ModulesInstaller()
end
print("Shared modules loaded")



local HttpService = CloneRef(game:GetService("HttpService"))
local TextChat    = CloneRef(game:GetService("TextChatService"))
local Players     = CloneRef(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer
local IsOg        = game.PlaceId == 108097274488844
print("Services cloned, IsOg = ", IsOg)

local function Assets(...)
  return table.concat({"Hyperion", ...}, "/")
end

do
  local Folders = {
    Assets(),
    Assets("modules"),
    Assets("modules", "og"),
    Assets("modules", "normal"),
    Assets("modules", "both"),
    Assets("cache"),
  }
  for _, Folder in ipairs(Folders) do
    pcall(makefolder, Folder)
  end
end
print("Folders created")

local Obsidian, ThemeManager, Invite
do
  local Pending = 3
  task.spawn(function()
    print("Loading Obsidian...")
    Obsidian = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
    print("Obsidian loaded")
    Pending -= 1
  end)
  task.spawn(function()
    print("Loading ThemeManager...")
    ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
    print("ThemeManager loaded")
    Pending -= 1
  end)
  task.spawn(function()
    print("Fetching invite...")
    Invite = game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/main/assets/discord_invite.txt")
    print("Invite fetched")
    Pending -= 1
  end)
  repeat task.wait() until Pending <= 0
  print("Parallel fetches done")
end

local Helpers = {}
do
  local ChatListeners = {}
  local PendingChatCheck = {}

  local Colors = {
    peasant = { Hex = "#966766" },
    arken   = { Hex = "#04afec" },
    admin   = { Hex = "#f5cd30" },
    spy     = { Hex = "#ff0000" },
  }

  Helpers.Log = function(...)
    print(...)
  end
  Helpers.SelfChat = function(Msg, NoAdded)
    if NoAdded then
      TextChat.TextChannels.RBXGeneral:DisplaySystemMessage('<font color="rgb(255,0,0)">[HYPERION]: ' .. Msg .. '</font>')
    else
      TextChat.TextChannels.RBXGeneral:DisplaySystemMessage(Msg)
    end
  end
  Helpers.On = function(Type, Func)
    if Type == "ChatListener" then
      table.insert(ChatListeners, Func)
    else
      error(Type .. " is not a supported event type")
    end
  end
  Helpers.ResolveName = function(Name)
    return Name:gsub("_", ".")
  end
  Helpers.Say = function(Text, CheckForSent)
    TextChat.TextChannels.RBXGeneral:SendAsync(Text)
    if not CheckForSent then return end
    PendingChatCheck[Text] = ""
    while PendingChatCheck[Text] == "" do task.wait(0.1) end
    local Ref = PendingChatCheck[Text]
    PendingChatCheck[Text] = nil
    return Ref
  end
  
  Helpers.Cmd = function(Cmd, CheckForSent)
    local Tool = LocalPlayer.Backpack:FindFirstChild("The Arkenstone")
    if Tool then
      Tool.Parent = LocalPlayer.Character
    elseif not LocalPlayer.Character:FindFirstChild("The Arkenstone") then
      local Chosen = Helpers.Services.Players.Leaderboard:FindFirstChild("Chosen")
      if not Chosen or not Chosen:FindFirstChild(LocalPlayer.Name) then return end
      print("Skipped command", Cmd, "due to having no enli or admin")
    end
    local FullCmd = ";" .. Cmd .. " HYPERION_REBORN"
    return Helpers.Say(FullCmd, CheckForSent)
  end

  TextChat.OnIncomingMessage = function(Msg)
    local Props = Instance.new("TextChatMessageProperties")
    if not Msg.TextSource then
      Props.Text = Msg.Text
      Props.PrefixText = Msg.PrefixText
      return Props
    end

    task.spawn(function()
      for _, Listener in ipairs(ChatListeners) do Listener(Msg) end
    end)

    if Msg.Status ~= Enum.TextChatMessageStatus.Sending and PendingChatCheck[Msg.Text] == "" then
      PendingChatCheck[Msg.Text] = Msg.Status == Enum.TextChatMessageStatus.Success
    end

    local Player = Players:GetPlayerByUserId(Msg.TextSource.UserId)
    if not Player then return Props end

    local ColorName
    if Player.Neutral then
      ColorName = Player:GetAttribute("Arken") == true and "arken" or "peasant"
    else
      ColorName = "admin"
    end
    if string.sub(Msg.Text, 1, 1) == ";" then ColorName = "spy" end

    local HexColor = Colors[ColorName].Hex
    local IsSpy = ColorName == "spy" and " (SPY CHAT)" or ""

    if IsOg then
      Props.PrefixText = ('<font color="%s"><b>[%s%s]: </b></font>'):format(HexColor, Player.DisplayName, IsSpy)
    else
      Props.PrefixText = ('<font color="%s"><i>(%s%s) </i></font>'):format(HexColor, Player.DisplayName, IsSpy)
    end

    return Props
  end

  Helpers.Services = {
    Players    = Players,
    Workspace  = CloneRef(game:GetService("Workspace")),
    Run        = CloneRef(game:GetService("RunService")),
    UserInput  = CloneRef(game:GetService("UserInputService")),
    TextChat   = TextChat,
    CoreGui    = CloneRef(game:GetService("CoreGui")),
    Http       = HttpService,
    Tween      = CloneRef(game:GetService("TweenService")),
    Replicated = CloneRef(game:GetService("ReplicatedStorage")),
    Collection = CloneRef(game:GetService("CollectionService")),
    Sound      = CloneRef(game:GetService("SoundService")),
    Lighting   = CloneRef(game:GetService("Lighting")),
    Debris     = CloneRef(game:GetService("Debris")),
    Teams      = CloneRef(game:GetService("Teams")),
  }
  print("Helpers built")
end

repeat task.wait() until Obsidian ~= nil
print("Obsidian ready, creating window...")

local Window = Obsidian:CreateWindow({
  Title = "Hyperion (Reborn)",
  Footer = "by horizonscript in discord",
  Icon = "zap",
  ToggleKeybind = Enum.KeyCode.RightShift,
  Center = true,
  AutoShow = true,
})

print("Window created")

local Tabs = {}
Tabs.Info     = Window:AddTab("Main", "home")
Tabs.Settings = Window:AddTab("Settings", "settings")
print("Tabs created")

local InfoBoxLeft  = Tabs.Info:AddLeftGroupbox("")
local InfoBoxRight = Tabs.Info:AddRightGroupbox("")

if not (isfile and isfolder and writefile and readfile and makefolder and listfiles and delfile and delfolder) then
  InfoBoxLeft:AddLabel({
    Text = "Your executor is TRASH. Use an executor which has the Files API.",
    DoesWrap = true
  })
  return
end

InfoBoxLeft:AddLabel({ Text = "Read our EULA at\n" .. game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/LICENSE.md"), DoesWrap = true })

local EulaPath = Assets(".eula")
if not isfile(EulaPath) then
  local Accepted = false
  InfoBoxLeft:AddButton({ Text = "Accept EULA once",    Func = function() Accepted = true end })
  InfoBoxLeft:AddButton({ Text = "Accept EULA (saves)", Func = function() Accepted = true; writefile(EulaPath, "") end })
  repeat task.wait(0.1) until Accepted
end

InfoBoxLeft:AddLabel({ Text = "Join our Discord for suggestions, updates, and help.", DoesWrap = true })
InfoBoxRight:AddButton({
  Text = "Copy Invite",
  Func = function()
    if setclipboard then
      setclipboard(Invite)
      Obsidian:Notify({ Title = "Copied!", Description = "Discord link copied to clipboard.", Time = 3 })
    else
      Obsidian:Notify({ Title = "Invite is", Description = Invite, Time = 7 })
    end
  end,
})

InfoBoxRight:AddDivider()
InfoBoxLeft:AddDivider()
InfoBoxLeft:AddLabel({ Text = "About Hyperion: a modular system. Instead of using a separate script, extend it with plugins. Visit #plugins on our Discord to find and share plugins.", DoesWrap = true })
InfoBoxLeft:AddDivider()
InfoBoxLeft:AddLabel({ Text = "Adding a Plugin: place your plugin file in Hyperion/modules/ (located inside your executor's folder).", DoesWrap = true })
InfoBoxRight:AddLabel({ Text = "Creating your own plugin: full documentation is available on #plugins-dev on our Discord server.", DoesWrap = true })
InfoBoxRight:AddLabel({ Text = "Credits: areyoumental, pealz, wilson, agarv, raja", DoesWrap = true })
print("Info tab populated")

repeat task.wait() until ThemeManager ~= nil
print("ThemeManager ready, applying theme...")

ThemeManager:SetLibrary(Obsidian)
ThemeManager:SetDefaultTheme({
  FontColor       = Color3.fromHex("#f0f0f0"),
  MainColor       = Color3.fromHex("#1a1d26"),
  AccentColor     = Color3.fromHex("#e63535"),
  BackgroundColor = Color3.fromHex("#0f1117"),
  OutlineColor    = Color3.fromHex("#e63535"),
})
ThemeManager:ApplyToTab(Tabs.Settings)
ThemeManager:LoadDefault()
print("Theme applied")

-- Install all module subdirectories
local InstallPending = 3
for _, Subdir in ipairs({"og", "normal", "both"}) do
  task.spawn(function()
    print("Installing modules:", Subdir)
    local OkInstall, FailedFiles = ModulesInstaller({
      ModulesPath      = Assets("modules", Subdir),
      GithubFolderUrl  = "https://api.github.com/repos/Horizon-Developments/hyperion/contents/modules/" .. Subdir,
      ModuleHandler    = function() end, --// ignore this
      Async            = true,
      Cache            = true,
    })
    if not OkInstall then
      warn("Installer failed for", Subdir, "-", tostring(FailedFiles))
    elseif #FailedFiles > 0 then
      warn("Some files failed in", Subdir, "-", #FailedFiles, "failed")
    else
      print("All modules installed for", Subdir)
    end
    InstallPending -= 1
  end)
end
repeat task.wait() until InstallPending <= 0
print("All modules installed")

local Env = { Tabs = Tabs, Window = Window, Obsidian = Obsidian, Assets = Assets, Helpers = Helpers }

local function LoadModuleFiles(Subdir)
  local Files = listfiles(Assets("modules", Subdir))
  print("Loading", #Files, "modules from:", Subdir)
  for _, File in ipairs(Files) do
    task.spawn(function()
      print("Loading module:", File)
      local Fn, FnErr = loadstring(readfile(File))
      if not Fn then
        warn("loadstring failed:", File, "-", tostring(FnErr))
        return
      end
      local OkRun, RunErr = pcall(Fn, Env)
      if not OkRun then
        warn("Module error:", File, "-", tostring(RunErr))
      else
        print("Module loaded:", File)
      end
    end)
  end
end

LoadModuleFiles(IsOg and "og" or "normal")
LoadModuleFiles("both")

if isfile(Assets(".joined")) then
  Obsidian:Notify({ Title = "Welcome back " .. LocalPlayer.DisplayName, Description = "I Appreciate you still using this script (:", Time = 2 })
else
  writefile(Assets(".joined"), "why u reading ts?")
  Obsidian:Notify({ Title = "Welcome " .. LocalPlayer.DisplayName, Description = "I Appreciate you using this script (:", Time = 2 })
end
print("Done")

print("Loaded")
Api.Telemetry:LoggingSend("Script loaded!")

Players.PlayerRemoving:Connect(function(Player)
  if Player == LocalPlayer then
    Api.Telemetry:LoggingSend("Player left")
  end
end)