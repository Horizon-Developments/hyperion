--[[
  Hyperion
  Copyright (c) 2026 Horizon-Developments
  All rights reserved.
  Repository: https://github.com/Horizon-Developments/hyperion
  License:    https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/LICENSE.md
]]

if getgenv().hyperion_api then
  return getgenv().hyperion_api
end

local lp      = game:GetService("Players").LocalPlayer
local http    = game:GetService("HttpService")
local request = request or http_request or (syn and syn.request)

local ENDPOINTS = {
  test        = "https://hyperion-server.thehyperiondev.workers.dev/test",
  signin      = "https://hyperion-server.thehyperiondev.workers.dev/accounts/signin",
  login       = "https://hyperion-server.thehyperiondev.workers.dev/accounts/login",
  accountTest = "https://hyperion-server.thehyperiondev.workers.dev/accounts/test",
  fileUpload  = "https://hyperion-server.thehyperiondev.workers.dev/file/upload",
  fileDelete  = "https://hyperion-server.thehyperiondev.workers.dev/file/delete",
  fileList    = "https://hyperion-server.thehyperiondev.workers.dev/file/list",
  file        = "https://hyperion-server.thehyperiondev.workers.dev/file/",
  plugins     = "https://hyperion-server.thehyperiondev.workers.dev/plugins",
  crashReport = "https://hyperion-server.thehyperiondev.workers.dev/Telemetry/CrashReport",
  logging     = "https://hyperion-server.thehyperiondev.workers.dev/Telemetry/Logging",
  botStart    = "https://hyperion-server.thehyperiondev.workers.dev/start",
  botConnect  = "wss://hyperion-server.thehyperiondev.workers.dev/connect/",
  adminkit_start = "https://hyperion-server.thehyperiondev.workers.dev/discord/adminkit/start"
}

local password_path = "Hyperion/password.json"

if not isfile(password_path) then
  local function guid()
    return http:GenerateGUID(false):gsub("-", "")
  end
  
  local function makeConstant()
    local parts = {}
    for i = 1, 8 do parts[i] = guid() end
    return table.concat(parts)
  end
  
  writefile(password_path, http:JSONEncode({
    account  = guid(),
    owner    = guid(),
    client   = guid(),
    constant = makeConstant(),
  }))
end

local function playerContext()
  return {
    executor = identifyexecutor and identifyexecutor() or "unsupported",
    hwid     = gethwid         and gethwid()          or "unsupported",
    name     = lp.Name,
    display  = lp.DisplayName,
    userid   = lp.UserId,
    gameid   = game.GameId,
    placeid  = game.PlaceId,
    jobId    = game.JobId,
  }
end

local function extractField(body, field)
  local ok, data = pcall(http.JSONDecode, http, body)
  return (ok and data and data[field]) or nil
end

local function httpError(res)
  return { status = res.StatusCode, message = res.StatusMessage, body = res.Body }
end

local api       = {}
api.Telemetry   = {}
api.Builds      = {}
api.Plugins     = {}
api.Bots        = {}

local Telemetry = api.Telemetry
local Bots      = api.Bots

function Telemetry:CrashReportSend(err)
  local payload = playerContext()
  payload.error = tostring(err)
  
  pcall(request, {
    Url    = ENDPOINTS.crashReport,
    Method = "POST",
    Body   = http:JSONEncode(payload),
  })
end

function Telemetry:LoggingSend(data)
  local payload = playerContext()
  payload.data = tostring(data)
  
  pcall(request, {
    Url    = ENDPOINTS.logging,
    Method = "POST",
    Body   = http:JSONEncode(payload),
  })
end


function Bots:CreateInstance(kind, adminkitdata)
  local credentials = http:JSONDecode(readfile(password_path))
  local key         = credentials.constant

  if kind == "adminkit" then
    local ctx = playerContext()

    local startRes = request({
      Url     = ENDPOINTS.adminkit_start,
      Method  = "POST",
      Headers = { ["Content-Type"] = "application/json" },
      Body    = http:JSONEncode({
        password = adminkitdata.password,
        jobid    = ctx.jobId,
        placeid  = tostring(ctx.placeid),
        name     = ctx.name,
        userid   = tostring(ctx.userid),
        constant = key,
      }),
    })
  
    if startRes.StatusCode ~= 200 then
      return false, "Failed to start adminkit session (HTTP " .. startRes.StatusCode .. ")"
    end

    local startData = http:JSONDecode(startRes.Body)
    if not startData or not startData.url then
      return false, "Server returned malformed /adminkit/start body"
    end

    local ws = WebSocket.connect(startData.url)
    if not ws then
      return false, "WebSocket connection failed"
    end

    local bot = { Authenticated = false, connect_url = startData.url, ws = ws }

    ws.OnMessage:Connect(function(message)
      print("[ADMINKIT] recv:", message)
      local ok, decoded = pcall(http.JSONDecode, http, message)
      if not ok or not decoded then return end
      task.spawn(function()
        local result = adminkitdata.handleModuleCall(decoded.data)
        ws:Send(http:JSONEncode({ Id = decoded.Id, data = result }))
      end)
    end)

    ws:Send(http:JSONEncode({ ok = true }))
    bot.Authenticated = true

    function bot:SendAsync(message)
      task.spawn(function()
        while not self.Authenticated do
          print("[ADMINKIT] waiting for auth…")
          task.wait(0.1)
        end
        self.ws:Send(message)
        print("[ADMINKIT] sent:", message)
      end)
    end

    return true, bot
  end

  -- kind == "bot" (default / legacy)
  local startRes = request({
    Url     = ENDPOINTS.botStart,
    Method  = "POST",
    Headers = { ["Content-Type"] = "application/json" },
    Body    = http:JSONEncode({ constant = key }),
  })

  if startRes.StatusCode ~= 200 then
    return false, "Failed to start bot session (HTTP " .. startRes.StatusCode .. ")"
  end

  local startData = http:JSONDecode(startRes.Body)
  if not startData or not startData.url then
    return false, "Server returned malformed /start body"
  end

  local connectUrl = ENDPOINTS.botConnect .. startData.url
  local ws         = WebSocket.connect(connectUrl)
  
  if not ws then
    return false, "WebSocket connection failed"
  end
  
  local bot = {
    Authenticated = false,
    connect_url   = connectUrl,
    ws            = ws,
  }
  
  ws.OnMessage:Connect(function(message)
    print("[BOT] recv:", message)

    if message == "FS:Authorization" then
      ws:Send("TS:" .. key)
    elseif message == "FS:TYPE" then
      ws:Send("FC:OWNER")
      task.wait(0.7)
      bot.Authenticated = true
    end
  end)
  
  task.wait(0.5)
  ws:Send("TS:OK")
  
  function bot:SendAsync(message)
    task.spawn(function()
      while not self.Authenticated do
        print("[BOT] waiting for auth…")
        task.wait(0.1)
      end
      self.ws:Send(message)
      print("[BOT] sent:", message)
    end)
  end
  
  function bot:GetClientScript()
    return ('loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/bot.lua"))("%s", "%s")'):format(
      self.connect_url, key
    )
  end
  
  return true, bot
end

local function fileAPI(user, password, authType, sessionPath)
  assert(sessionPath, "sessionPath is required")
  
  local function post(url, body, headers)
    return pcall(request, {
      Url     = url,
      Method  = "POST",
      Headers = headers or { ["Content-Type"] = "application/json" },
      Body    = http:JSONEncode(body),
    })
  end
  
  local function loginAndSave()
    local ok, res = post(ENDPOINTS.login, { username = user, password = password })
    if not ok then
      return nil, "Login request failed (network error)"
    end
    if res.StatusCode ~= 200 then
      return nil, httpError(res)
    end
    local token = extractField(res.Body, "token")
    if not token or token == "" then
      return nil, "Server returned empty token"
    end
    writefile(sessionPath, token)
    return token
  end

  local session

  if authType == "signin" then
    local ok, res = post(ENDPOINTS.signin, { username = user, password = password })
    if not ok then
      return nil, "Signin request failed (network error)"
    end
    if res.StatusCode == 409 then
      return nil, "Account already exists"
    end
    if res.StatusCode ~= 200 then
      return nil, httpError(res)
    end

    task.wait(1)
    local token, err = loginAndSave()
    if not token then return nil, err end
    session = token

  else
    local readOk, saved = pcall(readfile, sessionPath)
    local sessionValid  = false

    if readOk and saved and saved ~= "" then
      local ok, res = post(ENDPOINTS.accountTest, { session = saved })
      sessionValid = ok and res and res.StatusCode == 200
    end

    if sessionValid then
      session = saved
    else
      local token, err = loginAndSave()
      if not token then return nil, err end
      session = token
    end
  end

  local function authHeader()
    return { ["Authorization"] = "Bearer " .. session }
  end

  local fileapi   = {}
  fileapi.session = session

  function fileapi:upload(filepath, filename, desc)
    if not filename or #filename < 1 or #filename > 32 or not filename:match("^[A-Za-z0-9]+$") then
      return nil, "Invalid filename: 1-32 alphanumeric characters"
    end
    if desc ~= nil and (#desc > 64 or not desc:match("^[A-Za-z0-9]*$")) then
      return nil, "Invalid description: up to 64 alphanumeric characters"
    end

    local readOk, body = pcall(readfile, filepath)
    if not readOk then
      return nil, "Could not read file: " .. tostring(filepath)
    end

    local ok, res = pcall(request, {
      Url     = ENDPOINTS.fileUpload .. "?name=" .. http:UrlEncode(filename) .. "&desc=" .. http:UrlEncode(desc or ""),
      Method  = "POST",
      Headers = { ["Content-Type"] = "application/octet-stream", ["Authorization"] = "Bearer " .. session },
      Body    = body,
    })

    if not ok          then return nil, "Upload request failed (network)" end
    if not res.Success then return nil, httpError(res) end

    local fileId = extractField(res.Body, "fileId")
    if not fileId then return nil, "Server returned malformed upload response" end

    return fileId
  end

  function fileapi:delete(fileId)
    fileId = tostring(fileId):gsub("%s+", "")
    if not fileId:match("^%d" .. string.rep("%d", 10) .. "$") then
      return nil, "Invalid file ID: must be exactly 11 digits"
    end

    local ok, res = pcall(request, {
      Url     = ENDPOINTS.fileDelete .. "?id=" .. http:UrlEncode(fileId),
      Method  = "POST",
      Headers = authHeader(),
    })

    if not ok          then return nil, "Delete request failed (network)" end
    if not res.Success then return nil, httpError(res) end

    return true
  end

  function fileapi:download(fileId)
    fileId = tostring(fileId):gsub("%s+", "")
    if not fileId:match("^%d" .. string.rep("%d", 10) .. "$") then
      return nil, "Invalid file ID: must be exactly 11 digits"
    end

    local ok, res = pcall(request, {
      Url     = ENDPOINTS.file .. http:UrlEncode(fileId),
      Method  = "GET",
      Headers = authHeader(),
    })

    if not ok                then return nil, "Download request failed (network)" end
    if res.StatusCode == 404 then return nil, "File not found" end
    if not res.Success       then return nil, httpError(res) end

    return res.Body
  end

  function fileapi:list(sort, keyword, userFilter)
    if keyword ~= nil then
      if type(keyword) ~= "string" or not keyword:match("^[A-Za-z0-9]+$") or #keyword > 32 then
        return nil, "Invalid keyword: up to 32 alphanumeric characters"
      end
    else
      local validSorts = { new = true, old = true, trending = true }
      if type(sort) ~= "string" or not validSorts[sort] then
        return nil, "Invalid sort: must be 'new', 'old', or 'trending'"
      end
    end

    if userFilter ~= nil then
      if type(userFilter) ~= "string" or not userFilter:match("^[A-Za-z0-9]+$") or #userFilter > 12 then
        return nil, "Invalid userFilter: up to 12 alphanumeric characters"
      end
    end

    local query = keyword and ("?keyword=" .. http:UrlEncode(keyword))
                          or  ("?sort="    .. http:UrlEncode(sort))
    if userFilter then
      query = query .. "&user=" .. http:UrlEncode(userFilter)
    end

    local ok, res = pcall(request, {
      Url     = ENDPOINTS.fileList .. query,
      Method  = "GET",
      Headers = authHeader(),
    })

    if not ok          then return nil, "List request failed (network)" end
    if not res.Success then return nil, httpError(res) end

    local parseOk, data = pcall(http.JSONDecode, http, res.Body)
    if not parseOk then return nil, "Failed to parse list response" end

    return data
  end

  function fileapi:plugins(search)
    if type(search) ~= "string" or not search:match("^[A-Za-z0-9]+$") or #search < 1 or #search > 16 then
      return nil, "Invalid search: 1-16 alphanumeric characters"
    end

    local ok, res = pcall(request, {
      Url     = ENDPOINTS.plugins .. "?search=" .. http:UrlEncode(search),
      Method  = "GET",
      Headers = authHeader(),
    })

    if not ok                then return nil, "Plugin search failed (network)" end
    if res.StatusCode == 404 then return nil, "No plugins found" end
    if not res.Success       then return nil, httpError(res) end

    local parseOk, data = pcall(http.JSONDecode, http, res.Body)
    if not parseOk then return nil, "Failed to parse plugin response" end

    return data
  end

  return fileapi
end

local function testAPI()
  local ok, res = pcall(request, { Url = ENDPOINTS.test, Method = "GET" })
  return ok and res and res.StatusCode == 200
end

api.fileAPI = fileAPI
api.testAPI = testAPI

getgenv().hyperion_api = api
return api
