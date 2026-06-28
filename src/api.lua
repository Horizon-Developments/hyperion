--[[
  Hyperion Project
  Copyright (c) 2026 Horizon-Developments
  All rights reserved.
  Repository:
  https://github.com/Horizon-Developments/hyperion
  License:
  https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/LICENSE.md
]]
local http = game:GetService("HttpService")

local workerUrl = "https://hyperion-server.thehyperiondev.workers.dev"

local function testAPI()
  local ok, res = pcall(request, {
    Url = workerUrl .. "/test",
    Method = "GET"
  })
  return ok and res and res.StatusCode
end
--[[
Ask horizonscript (in discord) if you wanna use my api for ur own script idk
ts api very vibe coded
]]
local function API(user, password, _type, path)
  if not path then
    return nil, "path is required"
  end

  local api = {}
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

  function api:upload(filepath, filename, desc)
    local nameOk = filename and #filename >= 1 and #filename <= 32 and filename:match("^[A-Za-z0-9]+$")
    local descOk = desc == nil or (#desc <= 64 and desc:match("^[A-Za-z0-9]*$"))
    if not nameOk then return nil, "Invalid filename: 1-32 alphanumeric" end
    if not descOk then return nil, "Invalid description: up to 64 alphanumeric" end

    local body
    local ok2 = pcall(function()
      body = readfile(filepath)
    end)
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

  function api:delete(fileid)
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

  function api:download(fileid)
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

  function api:list(sort, keyword, userfilter)
    -- keyword takes priority over sort when provided
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

    local url = workerUrl .. "/file/list"
    if keyword ~= nil then
      url = url .. "?keyword=" .. http:UrlEncode(keyword)
    else
      url = url .. "?sort=" .. http:UrlEncode(sort)
    end
    if userfilter ~= nil then
      url = url .. "&user=" .. http:UrlEncode(userfilter)
    end

    local ok, res = pcall(request, {
      Url = url,
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

  function api:plugins(search)
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

  api.session = session

  return api
end

local function fakeAPI(warnfn)
  local api = {}
  function api:upload() warnfn() end
  function api:delete() warnfn() end
  function api:download() warnfn() end
  function api:list() warnfn() end
  function api:plugins() warnfn() end
  api.session = ""
  return api
end

return {
  API = API,
  testAPI = testAPI,
  fakeAPI = fakeAPI
}