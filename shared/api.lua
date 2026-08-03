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

math.randomseed(tick() * 1000 % 2^31) 


local function dbg(msg)
  if getgenv().DEBUG then
    print("[DEBUG]: " .. msg)
  end
end

local plrs = game:GetService("Players")
local lp      = plrs.LocalPlayer
local http    = game:GetService("HttpService")
local request = request or http_request or (syn and syn.request)

--// all api urls used
local ENDPOINTS = {
  test        = "https://hyperion-server.hyperion-cf.workers.dev/test",
  signin      = "https://hyperion-server.hyperion-cf.workers.dev/accounts/signin",
  login       = "https://hyperion-server.hyperion-cf.workers.dev/accounts/login",
  accountTest = "https://hyperion-server.hyperion-cf.workers.dev/accounts/test",
  fileUpload  = "https://hyperion-server.hyperion-cf.workers.dev/file/upload",
  fileDelete  = "https://hyperion-server.hyperion-cf.workers.dev/file/delete",
  fileList    = "https://hyperion-server.hyperion-cf.workers.dev/file/list",
  file        = "https://hyperion-server.hyperion-cf.workers.dev/file/",
  plugins     = "https://hyperion-server.hyperion-cf.workers.dev/plugins",
  crashReport = "https://hyperion-server.hyperion-cf.workers.dev/Telemetry/CrashReport",
  logging     = "https://hyperion-server.hyperion-cf.workers.dev/Telemetry/Logging",
  adminkit_start  = "https://hyperion-server.hyperion-cf.workers.dev/discord/adminkit/start",
  adminkit_invite = "https://hyperion-server.hyperion-cf.workers.dev/discord/adminkit/invite",
  generate        = "https://hyperion-server.hyperion-cf.workers.dev/key/generate",
  keyRedeem       = "https://hyperion-server.hyperion-cf.workers.dev/key/redeem/"
}

local password_path        = "Hyperion/password.json"
local ADMINKIT_TOKEN_PATH  = "Hyperion/adminkit_token.json"
local AUTH_WAIT_TIMEOUT    = 15

if not isfile(password_path) then
  dbg("no password file found so we're making one now")

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
  dbg("Password file written")
else
  dbg("Skipped password file")
end

local function playerContext()
  dbg("building player context now")
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

local function loadCredentials()
  return http:JSONDecode(readfile(password_path))
end

local function saveCredentials(creds)
  writefile(password_path, http:JSONEncode(creds))
end

-- Adminkit token persistence.
-- The JWT returned by /key/redeem is valid for 24h. We cache it so that
-- toggling the bot off/on (or crashing and restarting) within the same day
-- never triggers /key/generate again — which has a hard 7-day cooldown.
local function loadAdminkitToken()
  local ok, raw = pcall(readfile, ADMINKIT_TOKEN_PATH)
  if not ok or not raw or raw == "" then return nil end
  local parseOk, data = pcall(http.JSONDecode, http, raw)
  return (parseOk and data) or nil
end

local function saveAdminkitToken(token)
  -- exp is stored in seconds (tick()-based). The server sets exp = now + 24h;
  -- we subtract 120s so we never hand an about-to-expire token to the server.
  local exp = tick() + 86400 - 120
  local ok = pcall(writefile, ADMINKIT_TOKEN_PATH, http:JSONEncode({
    token = token,
    exp   = exp,
  }))
  if ok then
    dbg("adminkit token saved, expires in ~23h58m")
  else
    dbg("failed to save adminkit token to disk")
  end
end

local function deleteAdminkitToken()
  pcall(delfile, ADMINKIT_TOKEN_PATH)
  dbg("adminkit token deleted from disk")
end

local function isAdminkitTokenValid(data)
  return type(data)        == "table"
     and type(data.token)  == "string"
     and data.token        ~= ""
     and type(data.exp)    == "number"
     and tick()            <  data.exp
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
  dbg("sending crash report.")
  local payload = playerContext()
  payload.error = tostring(err)
  
  pcall(request, {
    Url    = ENDPOINTS.crashReport,
    Method = "POST",
    Body   = http:JSONEncode(payload),
  })
end

function Telemetry:LoggingSend(data)
  dbg("sending logging payload now")
  local payload = playerContext()
  
  pcall(request, {
    Url    = ENDPOINTS.logging,
    Method = "POST",
    Body   = tostring(data),
  })
end

local function requestStart(body)
  dbg("sending adminkit start request to server, type=" .. tostring(body.type))
  local res = request({
    Url     = ENDPOINTS.adminkit_start,
    Method  = "POST",
    Headers = { ["Content-Type"] = "application/json" },
    Body    = http:JSONEncode(body),
  })

  if res.StatusCode ~= 200 then
    dbg("start request came back bad status code " .. tostring(res.StatusCode))
    return nil, "Failed to start session (HTTP " .. res.StatusCode .. ")"
  end

  local data = http:JSONDecode(res.Body)
  if not data or not data.url then
    dbg("start body was busted no url in it")
    return nil, "Server returned malformed /adminkit/start body"
  end

  dbg("start request came back ok, url=" .. data.url)
  return data
end

-- Fetches a fresh JWT by generating a one-time code and immediately redeeming it.
-- Returns token (string) on success, or nil + error string on failure.
local function generateAndRedeemToken()
  dbg("generating a new one-time code now")
  local codeOk, codeRes = pcall(request, {
    Url     = ENDPOINTS.generate,
    Method  = "POST",
    Headers = { ["Content-Type"] = "application/json" },
    Body    = http:JSONEncode({ userId = tostring(lp.UserId) }),
  })
  if not codeOk then
    dbg("generate request had a network error")
    return nil, "Generate request failed (network error)"
  end
  if codeRes.StatusCode == 429 then
    dbg("generate hit the 7-day cooldown")
    return nil, "Code generation is on cooldown (7-day limit). Use the saved token or wait."
  end
  if codeRes.StatusCode ~= 200 then
    dbg("generate came back with bad status " .. tostring(codeRes.StatusCode))
    return nil, "Failed to generate code (HTTP " .. codeRes.StatusCode .. ")"
  end
  local code = extractField(codeRes.Body, "code")
  if not code or code == "" then
    dbg("generate response missing code field")
    return nil, "Server returned malformed generate response"
  end
  dbg("got code, redeeming it for a JWT now")

  -- Exchange the one-time code for a signed JWT. This is the token the server
  -- actually validates in /adminkit/start (via verifySessionToken) and that the
  -- Discord user pastes into /login.
  local redeemOk, redeemRes = pcall(request, {
    Url     = ENDPOINTS.keyRedeem .. http:UrlEncode(code),
    Method  = "POST",
    Headers = { ["Content-Type"] = "application/json" },
  })
  if not redeemOk then
    dbg("redeem request had a network error")
    return nil, "Redeem request failed (network error)"
  end
  if redeemRes.StatusCode ~= 200 then
    dbg("redeem came back with bad status " .. tostring(redeemRes.StatusCode))
    return nil, "Failed to redeem code (HTTP " .. redeemRes.StatusCode .. ")"
  end
  local token = extractField(redeemRes.Body, "token")
  if not token or token == "" then
    dbg("redeem response missing token field")
    return nil, "Server returned malformed redeem response"
  end

  dbg("got JWT token, saving to disk for reuse")
  saveAdminkitToken(token)
  return token
end

local function connectAdminkit(adminkitdata, key, ctx)
  -- Try to reuse the cached JWT so we never hit the 7-day generate cooldown
  -- on reconnects within the same 24h window.
  local token
  local saved = loadAdminkitToken()
  if isAdminkitTokenValid(saved) then
    dbg("found valid cached adminkit token, skipping generate+redeem")
    token = saved.token
  else
    dbg("no valid cached token found, generating a fresh one")
    local err
    token, err = generateAndRedeemToken()
    if not token then return false, err end
  end

  local startData, err = requestStart({
    type     = "admin",
    token    = token,
    jobid    = ctx.jobId,
    placeid  = tostring(ctx.placeid),
    name     = ctx.name,
    userid   = tostring(ctx.userid),
    constant = key,
  })

  -- 401 means the server rejected the token — most likely the SessionDO was
  -- killed by its 1-hour idle alarm after the previous disconnect. Wipe the
  -- stale token from disk and get a fresh one (if still within the 7-day window).
  if not startData and type(err) == "string" and err:find("401") then
    dbg("server rejected cached token (401), wiping it and regenerating")
    deleteAdminkitToken()
    local newErr
    token, newErr = generateAndRedeemToken()
    if not token then return false, newErr end
    startData, err = requestStart({
      type     = "admin",
      token    = token,
      jobid    = ctx.jobId,
      placeid  = tostring(ctx.placeid),
      name     = ctx.name,
      userid   = tostring(ctx.userid),
      constant = key,
    })
  end

  if not startData then return false, err end

  dbg("connecting the websocket now")
  local ws = WebSocket.connect(startData.url)
  if not ws then
    dbg("websocket connect failed")
    return false, "WebSocket connection failed"
  end
  dbg("websocket connected good")

  local bot = {
    Authenticated               = false,
    WebhookCommunicationEnabled = false,
    connect_url                 = startData.url,
    ws                          = ws,
    redeemCode                  = token,  -- JWT: paste this into /login in Discord
    pendingQueries              = {},     -- Id -> callback, for our own client-initiated requests
  }

  function bot:GetRedeemCode()
    return self.redeemCode
  end

  ws.OnMessage:Connect(function(message)
    dbg("[ADMINKIT] recv: " .. tostring(message))
    local ok, decoded = pcall(http.JSONDecode, http, message)
    if not ok or not decoded then
      dbg("recv message wasnt json we just drop it")
      return
    end

    task.spawn(function()
      local pendingCallback = bot.pendingQueries[decoded.Id]
      if pendingCallback then
        bot.pendingQueries[decoded.Id] = nil
        pendingCallback(decoded.data)
        return
      end

      if type(decoded.data) == "table" and decoded.data.webhook_communication_enabled then
        dbg("server says webhook communication is now enabled")
        bot.WebhookCommunicationEnabled = true
        return
      end
      
      if type(decoded.data) == "table" and decoded.data.modules == true then
        dbg("got module discovery probe replying with module map")
        local moduleMap = adminkitdata.getModuleMap and adminkitdata.getModuleMap() or {}
        ws:Send(http:JSONEncode({ Id = decoded.Id, data = moduleMap }))
        return
      end

      if type(decoded.data) == "table" and type(decoded.data.module_run) == "table" then
        dbg("got a module_run call handling it now")
        local run  = decoded.data.module_run
        local name = run.name
        local args = type(run.args) == "table" and run.args or {}
        dbg("module_run name=" .. tostring(name) .. " args=" .. #args)
        if not adminkitdata.handleModuleCall then
          dbg("handleModuleCall is nil, dropping module_run")
          ws:Send(http:JSONEncode({ Id = decoded.Id, data = { ok = false, error = "no handler" } }))
          return
        end
        local result = adminkitdata.handleModuleCall(name, args)
        ws:Send(http:JSONEncode({ Id = decoded.Id, data = result }))
        dbg("module_run result sent back")
        return
      end

      dbg("unrecognised message shape, dropping")
    end)
  end)

  local sendOk = pcall(function() ws:Send(http:JSONEncode({ ok = true })) end)
  if sendOk then
    dbg("sent the ok true handshake thing")
    bot.Authenticated = true
    dbg("bot marked as authenticated now")
  else
    dbg("failed to send ok true handshake, not marking authenticated")
  end

  if ws.OnClose then
    ws.OnClose:Connect(function()
      dbg("[ADMINKIT] websocket closed")
      bot.Authenticated = false
      bot.Connected = false
    end)
  end
  bot.Connected = true

  function bot:Disconnect()
    dbg("[ADMINKIT] disconnecting, sending TS:CLOSE")
    pcall(function() self.ws:Send("TS:CLOSE") end)
    self.Authenticated = false
    self.Connected = false
  end

  function bot:SendMessageAsync(message)
    task.spawn(function()
      local waited = 0
      while not self.Authenticated do
        if self.Connected == false then
          dbg("[ADMINKIT] socket closed while waiting for auth, dropping message")
          return
        end
        dbg("[ADMINKIT] waiting for auth…")
        task.wait(0.1)
        waited = waited + 0.1
        if waited >= AUTH_WAIT_TIMEOUT then
          dbg("[ADMINKIT] gave up waiting for auth, dropping message")
          return
        end
      end
      self.ws:Send(message)
      dbg("[ADMINKIT] sent: " .. tostring(message))
    end)
  end

  -- Fires { Id, is_webhook_communication_enabled = true } and waits for the
  -- { Id, data: bool } reply.
  function bot:IsWebhookCommunicationEnabledAsync(callback)
    local id = http:GenerateGUID(false)
    self.pendingQueries[id] = callback
    self:SendMessageAsync(http:JSONEncode({ Id = id, is_webhook_communication_enabled = true }))
  end

  -- Fires { Id, webhook_communication_send = payload } and waits for the
  -- correlated { Id, data: { ok } } reply.
  function bot:SendToWebhookAsync(payload, callback)
    local id = http:GenerateGUID(false)
    if callback then self.pendingQueries[id] = callback end
    self:SendMessageAsync(http:JSONEncode({ Id = id, webhook_communication_send = payload }))
  end
  function bot:IsConnected()
    return self.Connected == true
  end
  return true, bot
end

local function connectRelay(key)
  local startData, err = requestStart({ type = "relay", constant = key })
  if not startData then return false, err end

  dbg("connecting relay websocket now")
  local ws = WebSocket.connect(startData.url)
  if not ws then
    dbg("relay websocket connect failed")
    return false, "WebSocket connection failed"
  end
  dbg("relay websocket connected good")

  local bot = { Authenticated = false, connect_url = startData.url, ws = ws }

  ws.OnMessage:Connect(function(message)
    dbg("[BOT] recv: " .. tostring(message))

    if message == "FS:Authorization" then
      dbg("got auth request sending key back now")
      ws:Send("TS:" .. key)
    elseif message == "FS:TYPE" then
      dbg("got type request sending owner back")
      ws:Send("FC:OWNER")
      bot.Authenticated = true
      dbg("relay bot marked authenticated now")
    end
  end)

  local function sendHello()
    ws:Send("TS:OK")
    dbg("sent ts ok to relay bot")
  end

  if ws.OnOpen then
    ws.OnOpen:Connect(sendHello)
  else
    sendHello()
  end

  if ws.OnClose then
    ws.OnClose:Connect(function()
      dbg("[BOT] websocket closed")
      bot.Authenticated = false
      bot.Connected = false
    end)
  end
  bot.Connected = true

  function bot:SendAsync(message)
    task.spawn(function()
      local waited = 0
      while not self.Authenticated do
        if self.Connected == false then
          dbg("[BOT] socket closed while waiting for auth, dropping message")
          return
        end
        dbg("[BOT] waiting for auth…")
        task.wait(0.1)
        waited = waited + 0.1
        if waited >= AUTH_WAIT_TIMEOUT then
          dbg("[BOT] gave up waiting for auth, dropping message")
          return
        end
      end
      self.ws:Send(message)
      dbg("[BOT] sent: " .. tostring(message))
    end)
  end

  function bot:GetClientScript()
    return ('loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/bot.lua"))("%s", "%s")'):format(
      self.connect_url, key
    )
  end
  
  function bot:IsConnected()
  return self.Connected == true
  end
  
  return true, bot
end

function Bots:CreateInstance(kind, adminkitdata)
  local credentials = loadCredentials()
  local key         = credentials.constant
  dbg("read credentials file got the constant now")

  if kind == "adminkit" then
    dbg("kind is adminkit so we go this path")
    return connectAdminkit(adminkitdata, key, playerContext())
  end

  dbg("kind is not adminkit so going relay path")
  return connectRelay(key)
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
    dbg("trying login and save now")
    local ok, res = post(ENDPOINTS.login, { username = user, password = password })
    if not ok then
      dbg("login request had a network error")
      return nil, "Login request failed (network error)"
    end
    if res.StatusCode ~= 200 then
      dbg("login came back with bad status " .. tostring(res.StatusCode))
      return nil, httpError(res)
    end
    local token = extractField(res.Body, "token")
    if not token or token == "" then
      dbg("server sent us empty token thats bad")
      return nil, "Server returned empty token"
    end
    writefile(sessionPath, token)
    dbg("login worked wrote the token to session file")
    return token
  end

  local session

  if authType == "signin" then
    dbg("authtype is signin so signing up first")
    local ok, res = post(ENDPOINTS.signin, { username = user, password = password })
    if not ok then
      dbg("signin request had a network error")
      return nil, "Signin request failed (network error)"
    end
    if res.StatusCode == 409 then
      dbg("account already exist cant signin again")
      return nil, "Account already exists"
    end
    if res.StatusCode ~= 200 then
      dbg("signin came back with bad status " .. tostring(res.StatusCode))
      return nil, httpError(res)
    end

    task.wait(1)
    local token, err = loginAndSave()
    if not token then return nil, err end
    session = token

  else
    dbg("authtype not signin so trying saved session first")
    local readOk, saved = pcall(readfile, sessionPath)
    local sessionValid  = false

    if readOk and saved and saved ~= "" then
      dbg("found a saved session testing it now")
      local ok, res = post(ENDPOINTS.accountTest, { session = saved })
      sessionValid = ok and res and res.StatusCode == 200
    end

    if sessionValid then
      dbg("saved session still good using that")
      session = saved
    else
      dbg("saved session no good or missing doing fresh login")
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
    dbg("upload called checking filename now")
    if not filename or #filename < 1 or #filename > 32 or not filename:match("^[A-Za-z0-9]+$") then
      dbg("filename check failed")
      return nil, "Invalid filename: 1-32 alphanumeric characters"
    end
    if desc ~= nil and (#desc > 64 or not desc:match("^[A-Za-z0-9]*$")) then
      dbg("desc check failed")
      return nil, "Invalid description: up to 64 alphanumeric characters"
    end

    local readOk, body = pcall(readfile, filepath)
    if not readOk then
      dbg("couldnt read the file off disk")
      return nil, "Could not read file: " .. tostring(filepath)
    end

    dbg("sending upload request now")
    local ok, res = pcall(request, {
      Url     = ENDPOINTS.fileUpload .. "?name=" .. http:UrlEncode(filename) .. "&desc=" .. http:UrlEncode(desc or ""),
      Method  = "POST",
      Headers = { ["Content-Type"] = "application/octet-stream", ["Authorization"] = "Bearer " .. session },
      Body    = body,
    })

    if not ok          then dbg("upload request had network problem") return nil, "Upload request failed (network)" end
    if not res.Success then dbg("upload request came back not success") return nil, httpError(res) end

    local fileId = extractField(res.Body, "fileId")
    if not fileId then
      dbg("server response missing fileId thats bad")
      return nil, "Server returned malformed upload response"
    end

    dbg("upload worked got fileId back")
    return fileId
  end

  function fileapi:delete(fileId)
    fileId = tostring(fileId):gsub("%s+", "")
    if not fileId:match("^%d" .. string.rep("%d", 10) .. "$") then
      dbg("fileId format check failed on delete")
      return nil, "Invalid file ID: must be exactly 11 digits"
    end

    dbg("sending delete request now")
    local ok, res = pcall(request, {
      Url     = ENDPOINTS.fileDelete .. "?id=" .. http:UrlEncode(fileId),
      Method  = "POST",
      Headers = authHeader(),
    })

    if not ok          then dbg("delete request network problem") return nil, "Delete request failed (network)" end
    if not res.Success then dbg("delete request not success") return nil, httpError(res) end

    dbg("delete worked fine")
    return true
  end

  function fileapi:download(fileId)
    fileId = tostring(fileId):gsub("%s+", "")
    if not fileId:match("^%d" .. string.rep("%d", 10) .. "$") then
      dbg("fileId format check failed on download")
      return nil, "Invalid file ID: must be exactly 11 digits"
    end

    dbg("sending download request now")
    local ok, res = pcall(request, {
      Url     = ENDPOINTS.file .. http:UrlEncode(fileId),
      Method  = "GET",
      Headers = authHeader(),
    })

    if not ok                then dbg("download request network problem") return nil, "Download request failed (network)" end
    if res.StatusCode == 404 then dbg("download got 404 file not found") return nil, "File not found" end
    if not res.Success       then dbg("download not success") return nil, httpError(res) end

    dbg("download worked fine")
    return res.Body
  end

  function fileapi:list(sort, keyword, userFilter)
    dbg("list called checking params now")
    if keyword ~= nil then
      if type(keyword) ~= "string" or not keyword:match("^[A-Za-z0-9]+$") or #keyword > 32 then
        dbg("keyword check failed")
        return nil, "Invalid keyword: up to 32 alphanumeric characters"
      end
    else
      local validSorts = { new = true, old = true, trending = true }
      if type(sort) ~= "string" or not validSorts[sort] then
        dbg("sort check failed")
        return nil, "Invalid sort: must be 'new', 'old', or 'trending'"
      end
    end

    if userFilter ~= nil then
      if type(userFilter) ~= "string" or not userFilter:match("^[A-Za-z0-9]+$") or #userFilter > 12 then
        dbg("userFilter check failed")
        return nil, "Invalid userFilter: up to 12 alphanumeric characters"
      end
    end

    local query = keyword and ("?keyword=" .. http:UrlEncode(keyword))
                          or  ("?sort="    .. http:UrlEncode(sort))
    if userFilter then
      query = query .. "&user=" .. http:UrlEncode(userFilter)
    end

    dbg("sending list request now")
    local ok, res = pcall(request, {
      Url     = ENDPOINTS.fileList .. query,
      Method  = "GET",
      Headers = authHeader(),
    })

    if not ok          then dbg("list request network problem") return nil, "List request failed (network)" end
    if not res.Success then dbg("list request not success") return nil, httpError(res) end

    local parseOk, data = pcall(http.JSONDecode, http, res.Body)
    if not parseOk then
      dbg("couldnt parse the list response json")
      return nil, "Failed to parse list response"
    end

    dbg("list worked fine got data back")
    return data
  end

  function fileapi:plugins(search)
    dbg("plugin search called")
    if type(search) ~= "string" or not search:match("^[A-Za-z0-9]+$") or #search < 1 or #search > 16 then
      dbg("search param check failed")
      return nil, "Invalid search: 1-16 alphanumeric characters"
    end

    dbg("sending plugin search request now")
    local ok, res = pcall(request, {
      Url     = ENDPOINTS.plugins .. "?search=" .. http:UrlEncode(search),
      Method  = "GET",
      Headers = authHeader(),
    })

    if not ok                then dbg("plugin search network problem") return nil, "Plugin search failed (network)" end
    if res.StatusCode == 404 then dbg("plugin search got 404 nothing found") return nil, "No plugins found" end
    if not res.Success       then dbg("plugin search not success") return nil, httpError(res) end

    local parseOk, data = pcall(http.JSONDecode, http, res.Body)
    if not parseOk then
      dbg("couldnt parse plugin response json")
      return nil, "Failed to parse plugin response"
    end

    dbg("plugin search worked fine")
    return data
  end

  return fileapi
end

local function testAPI()
  dbg("testAPI called pinging test endpoint")
  local ok, res = pcall(request, { Url = ENDPOINTS.test, Method = "GET" })
  local result = ok and res and res.StatusCode == 200
  dbg("testAPI result is " .. tostring(result))
  return result
end

api.fileAPI = fileAPI
api.testAPI = testAPI

api.ENDPOINTS = ENDPOINTS

getgenv().hyperion_api = api
return api
