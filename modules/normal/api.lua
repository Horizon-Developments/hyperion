local client = getgenv()[".hyperion_client"]

local args     = ...
local tabs     = args.Tabs
local Window   = args.Window
local Obsidian = args.Obsidian
local assets   = args.Assets
local Helpers  = args.Helpers

local fakeAPI, testAPI, API = (function(a)
  return a.fakeAPI, a.testAPI, a.API
end)(loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/src/api.lua"))())

local user = {
  password = nil,
  username = nil,
}

tabs.autobuild = Window:AddTab("Connect to server", "server")
local box = tabs.autobuild:AddLeftGroupbox("Connect to server")

if not testAPI() then
  box:AddLabel({ Text = "API IS DOWN.", DoesWrap = true })
  return
end

local function fmterr(err)
  if type(err) == "table" then return "HTTP " .. (err.status or "?") end
  return tostring(err or "Unknown error")
end

local _busy = {}
local function busy(flag, func)
  return function(...)
    if _busy[flag] then
      Obsidian:Notify({ Title = "Busy!", Description = "Wait.", Time = 3 })
      return
    end
    _busy[flag] = true
    pcall(func, ...)
    task.wait(0.5)
    _busy[flag] = false
  end
end

local function setClient(c)
  getgenv()[".hyperion_client"] = c
end

-- proxy table so other scripts holding a reference always hit the current client
getgenv().hyperion_client = setmetatable({}, {
  __index = function(_, k)
    return getgenv()[".hyperion_client"][k]
  end
})

setClient(fakeAPI(function()
  Obsidian:Notify({ Title = "Sign in/up first", Time = 3 })
end))

box:AddLabel({ Text = "Username: a-z A-Z 0-9 only, max 12 characters.", DoesWrap = true })
box:AddInput("api.username", {
  Text        = "Username",
  Placeholder = "Enter username...",
  Callback    = function(v) user.username = v end
})

box:AddLabel({ Text = "Password: a-z A-Z 0-9 only, max 32 characters.", DoesWrap = true })
box:AddInput("api.password", {
  Text        = "Password",
  Placeholder = "Enter password...",
  Callback    = function(v) user.password = v end
})

box:AddLabel({ Text = "Login to an existing account.", DoesWrap = true })
box:AddButton({
  Text = "Login",
  Func = busy("auth", function()
    local client, err = API(user.username, user.password, "login", assets(".SESSION"))
    if client then
      setClient(client)
      Obsidian:Notify({ Title = "Logged in", Time = 3 })
    else
      Obsidian:Notify({ Title = "Login failed", Description = fmterr(err), Time = 6 })
    end
  end)
})

box:AddLabel({ Text = "Create a new account then login.", DoesWrap = true })
box:AddButton({
  Text = "Signup & Login",
  Func = busy("auth", function()
    local client, err = API(user.username, user.password, "signin", assets(".SESSION"))
    if client then
      setClient(client)
      Obsidian:Notify({ Title = "Account created & logged in", Time = 3 })
    else
      Obsidian:Notify({ Title = "Signup failed", Description = fmterr(err), Time = 6 })
    end
  end)
})