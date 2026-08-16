

local AppendLog = "[INSTALL MANAGER]: "

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

local function ExpectValueOrError(Value, _Type, GivenErrMsg)
  if typeof(Value) ~= _Type then
    error(GivenErrMsg or ("Expected '%s' got '%s'"):format(_Type, typeof(Value)), 2)
  end
end

local HttpService = game:GetService("HttpService")

return function(ctx)
  ExpectValueOrError(ctx.ModulesPath, "string")
  ExpectValueOrError(ctx.GithubFolderUrl, "string")
  ExpectValueOrError(ctx.ModuleHandler, "function")
  ExpectValueOrError(ctx.Async, "boolean")
  ExpectValueOrError(ctx.Cache, "boolean")

  pcall(makefolder, ctx.ModulesPath)

  if not isfolder(ctx.ModulesPath) then
    error("Failed to make Modules folder")
  end

  local function ResolveModulePath(...)
    return table.concat({ctx.ModulesPath, ...}, "/")
  end

  local CachePath = ResolveModulePath(".sha_cache.json")
  local ShaCache = {}

  if ctx.Cache then
    local OkCache, CacheData = pcall(function()
      return HttpService:JSONDecode(readfile(CachePath))
    end)
    if OkCache and type(CacheData) == "table" then
      ShaCache = CacheData
      print("SHA cache loaded")
    else
      print("No existing cache found, starting fresh")
    end
  end

  return pcall(function()
    local FailedFiles = {}
    local InstalledFiles = {}  -- fix: was nil

    local RequestData = request({
      Url = ctx.GithubFolderUrl,
      Method = "GET",
      Headers = { ["Accept"] = "application/vnd.github+json" }
    })
    local GithubApiData = HttpService:JSONDecode(RequestData.body or RequestData.Body)

    local function InstallFile(FileData)
      local DownloadUrl = FileData.download_url
      local FileName = FileData.name

      if ctx.Cache and ShaCache[FileName] == FileData.sha then
        print("Skipped (cached):", FileName)
        return
      end

      print("Installing", FileName)

      local OkFetch, DataFetch = pcall(game.HttpGet, game, DownloadUrl)
      if not OkFetch then
        warn("FETCH FAILED! ON FILE:", FileName, "Error:", DataFetch)
        table.insert(FailedFiles, DownloadUrl .. "@Fetch")
        return
      end

      local OkWrite, WriteErr = pcall(writefile, ResolveModulePath(FileName), DataFetch)
      if not OkWrite then
        warn("WRITE FAILED! ON FILE:", FileName, "Error:", WriteErr)  -- fix: was pcall(error,...)
        table.insert(FailedFiles, DownloadUrl .. "@Write")
        return
      end

      table.insert(InstalledFiles, { FileData, DataFetch })

      if ctx.Cache then
        ShaCache[FileName] = FileData.sha
      end
      print("Finished installing", FileName)
    end

    if ctx.Async then
      local ActiveThreads = 0
      for _, FileData in ipairs(GithubApiData) do
        ActiveThreads += 1
        task.spawn(function()
          InstallFile(FileData)
          ActiveThreads -= 1
        end)
      end
      repeat task.wait() until ActiveThreads <= 0
    else
      for _, FileData in ipairs(GithubApiData) do
        InstallFile(FileData)
      end
    end

    if ctx.Cache then
      local OkSave, SaveErr = pcall(writefile, CachePath, HttpService:JSONEncode(ShaCache))
      if not OkSave then
        warn("Failed to save SHA cache:", SaveErr)
      else
        print("SHA cache saved")
      end
    end

    for _, data in ipairs(InstalledFiles) do
      local FileData = data[1]
      local DataFetch = data[2]
      ctx.ModuleHandler(DataFetch, {
        Url = FileData.download_url,  -- fix: was DataFetch.*
        Name = FileData.name
      })
    end

    return FailedFiles
  end)
end