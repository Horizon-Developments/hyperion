--[[
  Hyperion Project
  Copyright (c) 2026 Horizon-Developments
  All rights reserved.
  Repository:
  https://github.com/Horizon-Developments/hyperion
  License:
  https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/LICENSE.md
]]


if getgenv().hyperion_api then
  return getgenv().hyperion_api
end

local api = {}
api.Telemetry = {}
api.Builds = {}
api.Plugins = {}
api.Bots = {}
local Telemetry = api.Telemetry
local Builds = api.Builds
local Plugins = api.Plugins
local Bots = api.Bots

local lp = game:GetService("Players").LocalPlayer
local http = game:GetService("HttpService")
local request = request or http_request or (syn and syn.request)

local url = "https://hyperion-server.thehyperiondev.workers.dev"
local bot = "https://hyperion-bot-server.onrender.com"

if not isfile("Hyperion/c.pswd") then
  local function randomPass()
    return http:GenerateGUID(false):gsub("-", "")
  end
  
  writefile("Hyperion/c.pswd", http:JSONEncode({
    account = randomPass(),
    owner   = randomPass(),
    client  = randomPass()
  }))
end

function Telemetry:CrashReportSend(err)
  pcall(request, {
    Url = url .. "/Telemetry/CrashReport",
    Method = "POST",
    Body = http:JSONEncode({
      executor = identifyexecutor and identifyexecutor() or "Does not support identifyexecutor",
      hwid = gethwid and gethwid() or "Does not support gethwid",
      name = lp.Name,
      display = lp.DisplayName,
      userid = lp.UserId,
      gameid = game.GameId,
      placeid = game.PlaceId,
      error = tostring(err)
    })
  })
end

function Telemetry:LoggingSend(data)
  pcall(request, {
    Url = url .. "/Telemetry/Logging",
    Method = "POST",
    Body = http:JSONEncode({
      executor = identifyexecutor and identifyexecutor() or "Does not support identifyexecutor",
      hwid = gethwid and gethwid() or "Does not support gethwid",
      name = lp.Name,
      display = lp.DisplayName,
      userid = lp.UserId,
      gameid = game.GameId,
      placeid = game.PlaceId,
      JobId = game.JobId,
      data = tostring(data)
    })
  })
end

function Bots:CreateInstance()
  local passwords = http:JSONDecode(readfile("Hyperion/c.pswd"))
  local user = "H_" .. lp.UserId
  request({
    Url = bot .. "/accounts/signup",
    Method = "POST",
    Headers = {
      ["username"] = user,
      ["password"] = passwords.account
    }
  })
  local res = request({
    Url = bot .. "/start",
    Method = "POST",
    Headers = {
      ["credentials_username"] = user,
      ["credentials_password"] = passwords.account,
      ["owner_password"] = passwords.owner,
      ["client_password"] = passwords.client,
    }
  })
  if res.StatusCode ~= 200 then
    return false, res.Body or "Error SC: " .. res.StatusCode
  end
  if not res.Body then
    return false, "Server returned invalid body"
  end
  local urls = http:JSONDecode(res.Body)
  if not urls or not urls.owner_url or not urls.client_url then
    return false, "Server returned malformed body"
  end
  local botApi = {}
  botApi.Authenticated = false
  botApi.ws = WebSocket.connect(urls.owner_url)
  botApi.client_url = urls.client_url
  botApi.owner_url = urls.owner_url
  botApi.ws.OnMessage:Connect(function(message)
    if message == "Authorization" then
      botApi.ws:Send('{"owner_password":"' .. passwords.owner .. '"}')
      task.wait(0.5)
      botApi.Authenticated = true
    end
  end)
  function botApi:SendAsync(m)
    task.spawn(function()
      repeat task.wait() until self.Authenticated
      self.ws:Send(m)
    end)
  end
  function botApi:GetClientScript()
    return ('loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/bot.lua"))("%s", "%s")'):format(self.client_url, passwords.client)
  end
  return botApi
end

local workerUrl = url
local function testAPI()
  local ok, res = pcall(request, {
    Url = workerUrl .. "/test",
    Method = "GET"
  })
  return ok and res and res.StatusCode
end

local function fileAPI(user, password, _type, path)
  if not path then
    return nil, "path is required"
  end

  local fileapi = {}
  local session

  if _type == "signin" then
    local ok, signinRes = pcall(request, {
      Url = workerUrl .. "/accounts/signin",
      Method = "POST",
      Headers = {["Content-Type"] = "application/json"},
      Body = http:JSONEncode({
        username = user,
        password = password
      })
    })
    if not ok then
      print("[HYPERION]: Signin ERR ", signinRes)
      return nil, "Request failed. logged in console"
    end
    if signinRes.StatusCode == 409 then
      return nil, "Account already exists."
    end
    if signinRes.StatusCode ~= 200 then
      return nil, {
        status = signinRes.StatusCode,
        body = signinRes.Body,
        message = signinRes.StatusMessage
      }
    end
    task.wait(1)

    local ok2, loginRes = pcall(request, {
      Url = workerUrl .. "/accounts/login",
      Method = "POST",
      Headers = {["Content-Type"] = "application/json"},
      Body = http:JSONEncode({
        username = user,
        password = password
      })
    })
    if not ok2 then
      return nil, "Signed up but login request failed (network error)"
    end
    if loginRes.StatusCode ~= 200 then
      return nil, {
        status = loginRes.StatusCode,
        body = loginRes.Body,
        message = loginRes.StatusMessage
      }
    end
    session = loginRes.Body:gsub("%s+$", "")
    if not session or session == "" then
      return nil, "Signed up but server returned empty token"
    end
    writefile(path, session)
  else
    local readOk, savedSession = pcall(readfile, path)
    local useOld = false

    if readOk and savedSession and savedSession ~= "" then
      local oktest, res = pcall(request, {
        Url = workerUrl .. "/accounts/test",
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = http:JSONEncode({ session = savedSession })
      })
      useOld = oktest and res and res.StatusCode == 200
    end

    if useOld then
      session = savedSession
    else
      local ok, loginRes = pcall(request, {
        Url = workerUrl .. "/accounts/login",
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = http:JSONEncode({
          username = user,
          password = password
        })
      })
      if not ok then
        return nil, "Login request failed (network error)"
      end
      if loginRes.StatusCode ~= 200 then
        return nil, {
          status = loginRes.StatusCode,
          body = loginRes.Body,
          message = loginRes.StatusMessage
        }
      end
      session = loginRes.Body:gsub("%s+$", "")
      if not session or session == "" then
        return nil, "Server returned empty token"
      end
      writefile(path, session)
    end
  end

  function fileapi:upload(filepath, filename, desc)
    local nameOk = filename and #filename >= 1 and #filename <= 32 and filename:match("^[A-Za-z0-9]+$")
    local descOk = desc == nil or (#desc <= 64 and desc:match("^[A-Za-z0-9]*$"))
    if not nameOk then return nil, "Invalid filename: 1-32 alphanumeric" end
    if not descOk then return nil, "Invalid description: up to 64 alphanumeric" end

    local body
    local ok2 = pcall(function() body = readfile(filepath) end)
    if not ok2 then return nil, "Could not read file" end

    local ok, res = pcall(request, {
      Url = workerUrl .. "/file/upload"
        .. "?name=" .. http:UrlEncode(filename)
        .. "&desc=" .. http:UrlEncode(desc or ""),
      Method = "POST",
      Headers = {
        ["Content-Type"] = "application/octet-stream",
        ["Authorization"] = "Bearer " .. session
      },
      Body = body
    })

    if not ok then return nil, "Upload request failed (network)" end
    if not res.Success then
      return nil, { status = res.StatusCode, message = res.StatusMessage, body = res.Body }
    end
    return res.Body:gsub("%s+$", ""), nil
  end

  function fileapi:delete(fileid)
    fileid = tostring(fileid):gsub("%s+$", "")
    if not fileid:match("^" .. string.rep("%d", 11) .. "$") then
      return nil, "Invalid file ID: must be 11 digits"
    end
    local ok, res = pcall(request, {
      Url = workerUrl .. "/file/delete?id=" .. http:UrlEncode(fileid),
      Method = "POST",
      Headers = {["Authorization"] = "Bearer " .. session}
    })
    if not ok then return nil, "Delete request failed (network)" end
    if not res.Success then
      return nil, { status = res.StatusCode, message = res.StatusMessage, body = res.Body }
    end
    return true
  end

  function fileapi:download(fileid)
    fileid = tostring(fileid):gsub("%s+$", "")
    if not fileid:match("^" .. string.rep("%d", 11) .. "$") then
      return nil, "Invalid file ID"
    end
    local ok, res = pcall(request, {
      Url = workerUrl .. "/file/" .. http:UrlEncode(fileid),
      Method = "GET",
      Headers = {["Authorization"] = "Bearer " .. session}
    })
    if not ok then return nil, "Download request failed (network)" end
    if res.StatusCode == 404 then return nil, "File not found" end
    if not res.Success then return nil, "Download failed: " .. res.StatusMessage end
    return res.Body, nil
  end

  function fileapi:list(sort, keyword, userfilter)
    if keyword ~= nil then
      if type(keyword) ~= "string" or not keyword:match("^[A-Za-z0-9]+$") or #keyword > 32 then
        return nil, "Invalid keyword: up to 32 alphanumeric"
      end
    else
      if type(sort) ~= "string" then return nil, "Invalid sort: must be string" end
      local valid = { new = true, old = true, trending = true }
      if not valid[sort] then return nil, "Invalid sort: new/old/trending" end
    end
    if userfilter ~= nil then
      if type(userfilter) ~= "string" or not userfilter:match("^[A-Za-z0-9]+$") or #userfilter > 12 then
        return nil, "Invalid user filter: up to 12 alphanumeric"
      end
    end
    local listUrl = workerUrl .. "/file/list"
    if keyword ~= nil then
      listUrl = listUrl .. "?keyword=" .. http:UrlEncode(keyword)
    else
      listUrl = listUrl .. "?sort=" .. http:UrlEncode(sort)
    end
    if userfilter ~= nil then
      listUrl = listUrl .. "&user=" .. http:UrlEncode(userfilter)
    end
    local ok, res = pcall(request, {
      Url = listUrl,
      Method = "GET",
      Headers = {["Authorization"] = "Bearer " .. session}
    })
    if not ok then return nil, "List request failed (network)" end
    if not res.Success then
      return nil, { status = res.StatusCode, message = res.StatusMessage }
    end
    local ok2, data = pcall(function() return http:JSONDecode(res.Body) end)
    if not ok2 then return nil, "Failed to parse response: " .. res.Body end
    return data, nil
  end

  function fileapi:plugins(search)
    if type(search) ~= "string" or not search:match("^[A-Za-z0-9]+$") or #search < 1 or #search > 16 then
      return nil, "Invalid search: 1-16 alphanumeric"
    end
    local ok, res = pcall(request, {
      Url = workerUrl .. "/plugins?search=" .. http:UrlEncode(search),
      Method = "GET",
      Headers = {["Authorization"] = "Bearer " .. session}
    })
    if not ok then return nil, "Plugin search failed (network)" end
    if res.StatusCode == 404 then return nil, "No plugins found" end
    if not res.Success then
      return nil, { status = res.StatusCode, message = res.StatusMessage }
    end
    local ok2, data = pcall(function() return http:JSONDecode(res.Body) end)
    if not ok2 then return nil, "Failed to parse response: " .. res.Body end
    return data, nil
  end
  fileapi.session = session
  return fileapi
end

local function fakeAPI(warnfn)
  local fakeapi = {}
  function fakeapi:upload() warnfn() end
  function fakeapi:delete() warnfn() end
  function fakeapi:download() warnfn() end
  function fakeapi:list() warnfn() end
  function fakeapi:plugins() warnfn() end
  fakeapi.session = ""
  return fakeapi
end

api.fileAPI = fileAPI
api.testAPI = testAPI
api.fakeAPI = fakeAPI


getgenv().hyperion_api = api
return api