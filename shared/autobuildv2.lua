--[[
  Hyperion Project
  Copyright (c) 2026 Horizon-Developments
  Repository:
  https://github.com/Horizon-Developments/hyperion
  License:
  https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/LICENSE.md
]]

if getgenv()["autobuildv2@hyperion"] then return  getgenv()["autobuildv2@hyperion"] end
local PlayersService  = game:GetService("Players")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local CoreGuiService    = game:GetService("CoreGui")
local EncodingService   = game:GetService("EncodingService")

local LocalPlayerInstance = PlayersService.LocalPlayer

local function DebugLog(...)
  if not getgenv().DEBUG then return end
  print("[AutoBuild][DEBUG] ",...)
end

local IsUsingLegacyCubesFolderVariant = workspace:FindFirstChild("Cubes") ~= nil
local BlockContainerFolder =
  IsUsingLegacyCubesFolderVariant and workspace:WaitForChild("Cubes") or workspace:WaitForChild("Bricks")
local DefaultGridUnitSizeInStuds = 4
local DefaultBlockColor = Color3.fromRGB(192, 192, 192)

DebugLog("Initializing AutoBuild library. LegacyCubesFolderVariant =", IsUsingLegacyCubesFolderVariant,
  "BlockContainerFolder =", BlockContainerFolder:GetFullName())

local function CompressBlockDataTableToBuffer(blockDataTable)
  local jsonEncodedString = HttpService:JSONEncode(blockDataTable)
  local compressedBuffer = EncodingService:CompressBuffer(
    buffer.fromstring(jsonEncodedString), Enum.CompressionAlgorithm.Zstd, 22)
  DebugLog("CompressBlockDataTableToBuffer: encoded", #jsonEncodedString, "bytes of JSON")
  return buffer.tostring(compressedBuffer)
end

local function DecompressBufferToBlockDataTable(rawCompressedString)
  local decompressedBuffer = EncodingService:DecompressBuffer(
    buffer.fromstring(rawCompressedString), Enum.CompressionAlgorithm.Zstd)
  return HttpService:JSONDecode(buffer.tostring(decompressedBuffer))
end

-- Maps each NormalId face to its outward direction vector and the size-component
-- name ("X"/"Y"/"Z") that axis corresponds to.
local NormalIdToDirectionAndAxisNameMap = {
  [Enum.NormalId.Right]  = { Vector3.new( 1, 0, 0), "X" },
  [Enum.NormalId.Top]    = { Vector3.new( 0, 1, 0), "Y" },
  [Enum.NormalId.Back]   = { Vector3.new( 0, 0, 1), "Z" },
  [Enum.NormalId.Left]   = { Vector3.new(-1, 0, 0), "X" },
  [Enum.NormalId.Bottom] = { Vector3.new( 0,-1, 0), "Y" },
  [Enum.NormalId.Front]  = { Vector3.new( 0, 0,-1), "Z" },
}

local FaceNameToNormalIdEnumMap = {
  Right  = Enum.NormalId.Right,
  Top    = Enum.NormalId.Top,
  Back   = Enum.NormalId.Back,
  Left   = Enum.NormalId.Left,
  Bottom = Enum.NormalId.Bottom,
  Front  = Enum.NormalId.Front,
}

local MaterialEnumToShortNameMap = {
  [Enum.Material.SmoothPlastic] = "smooth",   [Enum.Material.Plastic]      = "plastic",
  [Enum.Material.CeramicTiles]  = "tiles",    [Enum.Material.Brick]        = "bricks",
  [Enum.Material.WoodPlanks]    = "planks",   [Enum.Material.Ice]          = "ice",
  [Enum.Material.Grass]         = "grass",    [Enum.Material.Sand]         = "sand",
  [Enum.Material.Snow]          = "snow",     [Enum.Material.Glass]        = "glass",
  [Enum.Material.Wood]          = "wood",     [Enum.Material.Slate]        = "stone",
  [Enum.Material.Pebble]        = "pebble",   [Enum.Material.Marble]       = "marble",
  [Enum.Material.Granite]       = "granite",  [Enum.Material.DiamondPlate] = "steel",
  [Enum.Material.Metal]         = "metal",    [Enum.Material.Asphalt]      = "asphalt",
  [Enum.Material.Concrete]      = "concrete", [Enum.Material.Pavement]     = "pavement",
  [Enum.Material.Neon]          = "neon",
}
local ShortNameToMaterialEnumMap = {}
for materialEnumValue, shortMaterialName in pairs(MaterialEnumToShortNameMap) do
  ShortNameToMaterialEnumMap[shortMaterialName] = materialEnumValue
end

local currentBuildStepDelaySeconds = 0.235
local smoothedRoundTripTimeMs      = 0
local roundTripTimeVarianceMs      = 0
local hasSeededPingSample          = false
local GENERATION_COUNTER_GLOBAL_KEY = "HyperionAutobuildGen"
local CONNECTION_HANDLE_GLOBAL_KEY  = "HyperionAutoBuildCon"

if getgenv()[CONNECTION_HANDLE_GLOBAL_KEY] then
  DebugLog("Disconnecting previous ChildAdded connection from a prior script generation")
  pcall(function() getgenv()[CONNECTION_HANDLE_GLOBAL_KEY]:Disconnect() end)
  getgenv()[CONNECTION_HANDLE_GLOBAL_KEY] = nil
end

local currentModuleGenerationNumber = (getgenv()[GENERATION_COUNTER_GLOBAL_KEY] or 0) + 1
getgenv()[GENERATION_COUNTER_GLOBAL_KEY] = currentModuleGenerationNumber
DebugLog("This module instance is generation", currentModuleGenerationNumber)

task.spawn(function()
  while getgenv()[GENERATION_COUNTER_GLOBAL_KEY] == currentModuleGenerationNumber do
    local wasPingSampleSuccessful, pingSampleMilliseconds = pcall(function()
      return LocalPlayerInstance:GetNetworkPing() * 1000
    end)
    if wasPingSampleSuccessful then
      if not hasSeededPingSample then
        smoothedRoundTripTimeMs = pingSampleMilliseconds
        roundTripTimeVarianceMs = pingSampleMilliseconds / 2
        hasSeededPingSample     = true
      else
        roundTripTimeVarianceMs = 0.75 * roundTripTimeVarianceMs
          + 0.25 * math.abs(smoothedRoundTripTimeMs - pingSampleMilliseconds)
        smoothedRoundTripTimeMs = 0.875 * smoothedRoundTripTimeMs + 0.125 * pingSampleMilliseconds
      end
      local retransmissionTimeoutMs = smoothedRoundTripTimeMs + 3.9 * roundTripTimeVarianceMs
      currentBuildStepDelaySeconds = math.max(0.051, math.min(0.55, retransmissionTimeoutMs / 1000))
      --DebugLog("Ping sample:", pingSampleMilliseconds, "ms | smoothedRTT:", smoothedRoundTripTimeMs,
       -- "| stepDelay:", currentBuildStepDelaySeconds)
    end
    task.wait(1)
  end
end)

local function SanitizeRawJsonString(inputString)
  if not inputString or inputString == "" then return inputString end
  local sanitizedString = inputString
  sanitizedString = sanitizedString:gsub("^\xEF\xBB\xBF", "")
  sanitizedString = sanitizedString:gsub("\xC2\xA0", " ")
  sanitizedString = sanitizedString:gsub("\xE2\x80[\x8B\x8C\x8D]", "")
  sanitizedString = sanitizedString:gsub("\xE2\x80[\x9C\x9D]", '"')
  sanitizedString = sanitizedString:gsub("\xE2\x80[\x98\x99]", "'")
  sanitizedString = sanitizedString:gsub("[\r\n]+", " "):match("^%s*(.-)%s*$")
  repeat
    local sanitizedStringWithoutTrailingCommas = sanitizedString:gsub(",%s*([%]%}])", "%1")
    if sanitizedStringWithoutTrailingCommas == sanitizedString then break end
    sanitizedString = sanitizedStringWithoutTrailingCommas
  until false
  if sanitizedString:sub(1, 1) == "{" and sanitizedString:sub(-1) == "}" then
    sanitizedString = "[" .. sanitizedString .. "]"
  end
  return sanitizedString
end

local DefaultSessionSettings = {
  offset      = Vector3.zero,
  mult        = 1,
  historymax  = 400,
  resizewait  = 0.2,
  wbs         = false,
  maxtry      = 150,
  maxtrydelay = nil,
}

local function SaveOwnedBlocksToFile(outputFilePath, Instances)
  local sourceFolderList = {}
  for _, instance in ipairs(Instances) do
    if typeof(instance) ~= "Instance" then continue end
    if instance:IsA("Player") then
      local playerBrickFolder = BlockContainerFolder:FindFirstChild(instance.Name)
      if playerBrickFolder then
        table.insert(sourceFolderList, playerBrickFolder)
      end
    elseif instance:IsA("Folder") or instance:IsA("Model") then
      table.insert(sourceFolderList, instance)
    end
  end
  DebugLog("SaveOwnedBlocksToFile: source folder count =", #sourceFolderList)

  local savedBlockDataList = {}
  for _, sourceFolderInstance in ipairs(sourceFolderList) do
    for _, blockPartInstance in ipairs(sourceFolderInstance:GetChildren()) do
      if not blockPartInstance:IsA("BasePart") then continue end

      local blockSize  = blockPartInstance.Size
      local blockColor = blockPartInstance.Color
      local blockDataEntry

      if blockPartInstance:FindFirstChild("Input") then
        local signLabelText = ""
        local inputChildInstance = blockPartInstance:FindFirstChild("Input")
        if inputChildInstance then
          local labelChildInstance = inputChildInstance:FindFirstChild("Label")
          if labelChildInstance then signLabelText = labelChildInstance.Text or "" end
        end
        blockDataEntry = {
          type = "sign",
          p    = { blockPartInstance.CFrame:GetComponents() },
          sid  = inputChildInstance and inputChildInstance.Face and inputChildInstance.Face.Name or "Front",
          txt  = signLabelText:gsub('"', '\\"'),
          c    = { math.round(blockColor.R * 255), math.round(blockColor.G * 255), math.round(blockColor.B * 255) },
          id   = blockPartInstance.Name,
        }
      else
        blockDataEntry = {}
        if (blockPartInstance.CFrame - blockPartInstance.Position) ~= CFrame.new() then
          blockDataEntry.p = { blockPartInstance.CFrame:GetComponents() }
        else
          local cornerPosition = blockPartInstance.Position - blockSize / 2 + Vector3.new(0.5, 0.5, 0.5)
          blockDataEntry.p = { cornerPosition.X, cornerPosition.Y, cornerPosition.Z }
        end
        blockDataEntry.c  = { math.round(blockColor.R * 255), math.round(blockColor.G * 255), math.round(blockColor.B * 255) }
        blockDataEntry.a  = blockPartInstance.Anchored
        blockDataEntry.cc = blockPartInstance.CanCollide
        if blockSize.X ~= DefaultGridUnitSizeInStuds or blockSize.Y ~= DefaultGridUnitSizeInStuds
          or blockSize.Z ~= DefaultGridUnitSizeInStuds then
          if #blockDataEntry.p == 3 then
            blockDataEntry.p[1] = (blockDataEntry.p[1] - blockSize.X / 2) + 0.5
            blockDataEntry.p[2] = (blockDataEntry.p[2] - blockSize.Y / 2) + 0.5
            blockDataEntry.p[3] = (blockDataEntry.p[3] - blockSize.Z / 2) + 0.5
          end
          blockDataEntry.s = { blockSize.X, blockSize.Y, blockSize.Z }
        end
        blockDataEntry.m  = MaterialEnumToShortNameMap[blockPartInstance.Material] or "smooth"
        blockDataEntry.o  = blockPartInstance.Material.Name
        blockDataEntry.sp = {}
        for _, childInstance in ipairs(blockPartInstance:GetChildren()) do
          if childInstance.Name == "Spray" then
            table.insert(blockDataEntry.sp, {
              childInstance.Face.Name,
              childInstance.Image and childInstance.Image.Image or "",
              childInstance.Label and childInstance.Label.Text:gsub('"', '\\"') or "",
            })
          end
        end
      end

      table.insert(savedBlockDataList, blockDataEntry)
    end
  end

  writefile(outputFilePath, CompressBlockDataTableToBuffer(savedBlockDataList))
  DebugLog("SaveOwnedBlocksToFile: wrote", #savedBlockDataList, "blocks to", outputFilePath)
  return #savedBlockDataList
end
local function CreateAutoBuildSession(dataSourcePathOrTable, userProvidedSettingsTable, customFetchFunction,
  isDataSourcePreDecoded, customFetchToolsFunction)
  userProvidedSettingsTable = userProvidedSettingsTable or {}

  local sessionConfiguration = {
    offset      = userProvidedSettingsTable.offset      or DefaultSessionSettings.offset,
    mult        = userProvidedSettingsTable.mult        or DefaultSessionSettings.mult,
    historymax  = userProvidedSettingsTable.historymax  or DefaultSessionSettings.historymax,
    resizewait  = userProvidedSettingsTable.resizewait  or DefaultSessionSettings.resizewait,
    wbs         = (userProvidedSettingsTable.wbs ~= nil) and userProvidedSettingsTable.wbs or DefaultSessionSettings.wbs,
    maxtry      = userProvidedSettingsTable.maxtry      or DefaultSessionSettings.maxtry,
    maxtrydelay = userProvidedSettingsTable.maxtrydelay or DefaultSessionSettings.maxtrydelay,
  }
  DebugLog("CreateAutoBuildSession: configuration =", HttpService:JSONEncode({
    mult = sessionConfiguration.mult, historymax = sessionConfiguration.historymax,
    resizewait = sessionConfiguration.resizewait, wbs = sessionConfiguration.wbs,
    maxtry = sessionConfiguration.maxtry,
  }))

  local asynchronousRemoteWorkerClientList =
    (type(userProvidedSettingsTable.async) == "table") and userProvidedSettingsTable.async or nil
  local isBuildSessionStopped          = false
  local isCurrentBlockSkipRequested    = false
  local wasBlockJustConfirmedBuilt     = false
  local mostRecentlyBuiltBlockInstance = nil
  local currentPreviewPartInstance     = nil
  local recentlyBuiltBlockHistoryList      = {}
  local recentlyBuiltBlockHistoryWriteIndex = 0
  local currentBuildRunGenerationNumber = 0
  local lastKnownBuildStateSnapshot     = nil
  local lastMissingToolWarningTimestamp = 0
  local requiredToolNameList = { "Build", "Paint", "Shape", "Delete" }
  local weightedBuildSpeedPingHistoryList     = {}
  local weightedBuildSpeedPingHistoryIndex    = 0
  local weightedBuildSpeedResizeWaitSeconds   = sessionConfiguration.resizewait
  local weightedBuildSpeedPingSum             = 0
  local weightedBuildSpeedPingSampleCount     = 0

  task.spawn(function()
    while getgenv()[GENERATION_COUNTER_GLOBAL_KEY] == currentModuleGenerationNumber do
      task.wait(1)
      if not sessionConfiguration.wbs then continue end
      local latestPingMilliseconds = -199
      local wasPanelScanSuccessful = pcall(function()
        for _, statsChildInstance in pairs(CoreGuiService.RobloxGui.PerformanceStats:GetChildren()) do
          local statsPanelInstance = statsChildInstance:FindFirstChild("StatsMiniTextPanelClass")
          if statsPanelInstance and statsPanelInstance:FindFirstChild("TitleLabel")
            and statsPanelInstance:FindFirstChild("ValueLabel")
            and statsPanelInstance.TitleLabel.Text == "Ping" then
            local rawValueLabelText = statsPanelInstance.ValueLabel.Text
            local msSuffixIndex = string.find(rawValueLabelText, " ms")
            if msSuffixIndex then
              latestPingMilliseconds = tonumber(string.sub(rawValueLabelText, 1, msSuffixIndex - 1))
            end
          end
        end
      end)
      if not wasPanelScanSuccessful or latestPingMilliseconds == -199 then
        pcall(function() latestPingMilliseconds = LocalPlayerInstance:GetNetworkPing() * 1000 end)
      end
      if latestPingMilliseconds and latestPingMilliseconds > 0 then
        weightedBuildSpeedPingHistoryIndex = (weightedBuildSpeedPingHistoryIndex % 5) + 1
        local pingWeightMultiplier =
          latestPingMilliseconds > 500 and 2.2 or latestPingMilliseconds > 250 and 2.5 or 2.7
        local previousHistoryValue = weightedBuildSpeedPingHistoryList[weightedBuildSpeedPingHistoryIndex]
        if previousHistoryValue then
          weightedBuildSpeedPingSum = weightedBuildSpeedPingSum - previousHistoryValue
        else
          weightedBuildSpeedPingSampleCount = weightedBuildSpeedPingSampleCount + 1
        end
        local newWeightedHistoryValue = latestPingMilliseconds * pingWeightMultiplier
        weightedBuildSpeedPingHistoryList[weightedBuildSpeedPingHistoryIndex] = newWeightedHistoryValue
        weightedBuildSpeedPingSum = weightedBuildSpeedPingSum + newWeightedHistoryValue
        weightedBuildSpeedResizeWaitSeconds = (weightedBuildSpeedPingSum / weightedBuildSpeedPingSampleCount) / 1000
        sessionConfiguration.resizewait = weightedBuildSpeedResizeWaitSeconds
        DebugLog("WBS ping sample:", latestPingMilliseconds, "ms -> resizewait:", sessionConfiguration.resizewait)
      end
    end
  end)

  local POSITION_TOLERANCE_STUDS  = 0.75
  local SIZE_TOLERANCE_STUDS      = 0.75
  local COLOR_TOLERANCE_FRACTION  = 0.02

  local totalBlockCountForCurrentBuild    = 0
  local verifiedBlockCountForCurrentBuild = 0
  local buildStartTimestamp               = 0
  local sessionStatisticsTable = { total = 0, done = 0, elapsed = 0, eta = nil, ping = 0 }

  local function UpdateSessionStatistics()
    sessionStatisticsTable.total = totalBlockCountForCurrentBuild
    sessionStatisticsTable.done  = verifiedBlockCountForCurrentBuild
    sessionStatisticsTable.ping  = math.floor(smoothedRoundTripTimeMs)
    if buildStartTimestamp > 0 then
      sessionStatisticsTable.elapsed = tick() - buildStartTimestamp
      if sessionStatisticsTable.done > 2 and sessionStatisticsTable.total > 0 then
        sessionStatisticsTable.eta = sessionStatisticsTable.elapsed / sessionStatisticsTable.done
          * (sessionStatisticsTable.total - sessionStatisticsTable.done)
      end
    end
  end

  local currentBlockHighlightInstance = Instance.new("Highlight")
  currentBlockHighlightInstance.Parent              = CoreGuiService
  currentBlockHighlightInstance.FillColor           = Color3.fromRGB(0, 200, 255)
  currentBlockHighlightInstance.FillTransparency    = 0.5
  currentBlockHighlightInstance.OutlineColor        = Color3.fromRGB(0, 200, 255)
  currentBlockHighlightInstance.OutlineTransparency = 0

  local function LogMessage(messageText)
    warn("[AutoBuild] " .. tostring(messageText))
  end
  local function GetCurrentStepDelaySeconds()
    return sessionConfiguration.maxtrydelay or currentBuildStepDelaySeconds
  end

  local function SnapPositionToGrid(inputPosition, gridUnitSizeOverride)
    gridUnitSizeOverride = gridUnitSizeOverride or DefaultGridUnitSizeInStuds
    return Vector3.new(
      math.round((inputPosition.X - 2) / gridUnitSizeOverride) * gridUnitSizeOverride + 2,
      math.round((inputPosition.Y - 2) / gridUnitSizeOverride) * gridUnitSizeOverride + 2,
      math.round((inputPosition.Z - 2) / gridUnitSizeOverride) * gridUnitSizeOverride + 2
    )
  end

  local function AreVectorsWithinTolerance(vectorA, vectorB, toleranceStuds)
    return math.abs(vectorA.X - vectorB.X) <= toleranceStuds
       and math.abs(vectorA.Y - vectorB.Y) <= toleranceStuds
       and math.abs(vectorA.Z - vectorB.Z) <= toleranceStuds
  end
  local function AreColorsWithinTolerance(colorA, colorB)
    return math.abs(colorA.R - colorB.R) <= COLOR_TOLERANCE_FRACTION
       and math.abs(colorA.G - colorB.G) <= COLOR_TOLERANCE_FRACTION
       and math.abs(colorA.B - colorB.B) <= COLOR_TOLERANCE_FRACTION
  end
  local function ConvertCornerPositionToCenterPosition(cornerPosition, blockSize)
    if not blockSize then return cornerPosition end
    return Vector3.new(
      cornerPosition.X + blockSize.X / 2 - 0.5,
      cornerPosition.Y + blockSize.Y / 2 - 0.5,
      cornerPosition.Z + blockSize.Z / 2 - 0.5
    )
  end

  local function EquipToolByName(toolName)
    local characterModelInstance = LocalPlayerInstance.Character
    if not characterModelInstance then return nil end
    local toolAlreadyInCharacter = characterModelInstance:FindFirstChild(toolName)
    if toolAlreadyInCharacter and toolAlreadyInCharacter:IsA("Tool") then return toolAlreadyInCharacter end
    local backpackInstance = LocalPlayerInstance:FindFirstChildOfClass("Backpack")
    local toolInBackpack = backpackInstance and backpackInstance:FindFirstChild(toolName)
    if toolInBackpack and toolInBackpack:IsA("Tool") then
      pcall(function()
        if toolInBackpack:FindFirstChild("Script") and toolInBackpack.Script:IsA("LocalScript") then
          toolInBackpack.Script.Disabled = false
        end
        toolInBackpack.Parent = characterModelInstance
      end)
      return characterModelInstance:FindFirstChild(toolName)
    end
    return nil
  end

  local function CloneToolFromWorkspaceIntoBackpack(toolName)
    local backpackInstance = LocalPlayerInstance:FindFirstChildOfClass("Backpack")
    if not backpackInstance or backpackInstance:FindFirstChild(toolName) then return end
    local toolInWorkspace = workspace:FindFirstChild(toolName)
    if toolInWorkspace and toolInWorkspace:IsA("Tool") then
      pcall(function() toolInWorkspace:Clone().Parent = backpackInstance end)
    end
  end

  local function EnsureRequiredToolsAreEquipped(shouldWarnIfMissing)
    local hasBuildToolEquipped = false
    for _, toolName in ipairs(requiredToolNameList) do
      if not EquipToolByName(toolName) then
        CloneToolFromWorkspaceIntoBackpack(toolName)
        EquipToolByName(toolName)
      end
      if toolName == "Build" and LocalPlayerInstance.Character
        and LocalPlayerInstance.Character:FindFirstChild("Build") then
        hasBuildToolEquipped = true
      end
    end
    if not hasBuildToolEquipped and shouldWarnIfMissing then
      local currentClockTime = os.clock()
      if currentClockTime - lastMissingToolWarningTimestamp > 6 then
        lastMissingToolWarningTimestamp = currentClockTime
        LogMessage("Build tool missing. Grant yourself bkit, then retry.")
      end
    end
    DebugLog("EnsureRequiredToolsAreEquipped: hasBuildToolEquipped =", hasBuildToolEquipped)
    return hasBuildToolEquipped
  end

  local function DoesPartMatchExpectedTransform(candidatePartInstance, expectedCenterPosition, expectedSize)
    return candidatePartInstance and candidatePartInstance:IsA("BasePart")
        and AreVectorsWithinTolerance(candidatePartInstance.Position, expectedCenterPosition, POSITION_TOLERANCE_STUDS)
        and AreVectorsWithinTolerance(candidatePartInstance.Size, expectedSize, SIZE_TOLERANCE_STUDS)
  end

  local function FindExistingBlockAtPosition(expectedCenterPosition, expectedSizeOverride)
    if not BlockContainerFolder or not BlockContainerFolder.Parent then return nil end
    local expectedSize = expectedSizeOverride
      or Vector3.new(DefaultGridUnitSizeInStuds, DefaultGridUnitSizeInStuds, DefaultGridUnitSizeInStuds)
    local wasOverlapQuerySuccessful, overlapQueryHitList = pcall(function()
      local overlapParameters = OverlapParams.new()
      overlapParameters.FilterType = Enum.RaycastFilterType.Include
      overlapParameters.FilterDescendantsInstances = { BlockContainerFolder }
      overlapParameters.MaxParts = 30
      return workspace:GetPartBoundsInBox(
        CFrame.new(expectedCenterPosition), expectedSize + Vector3.new(1, 1, 1), overlapParameters)
    end)
    if wasOverlapQuerySuccessful and overlapQueryHitList then
      for _, hitPartInstance in ipairs(overlapQueryHitList) do
        if DoesPartMatchExpectedTransform(hitPartInstance, expectedCenterPosition, expectedSize) then
          return hitPartInstance
        end
      end
      return nil
    end
    for _, descendantPartInstance in ipairs(BlockContainerFolder:GetDescendants()) do
      if DoesPartMatchExpectedTransform(descendantPartInstance, expectedCenterPosition, expectedSize) then
        return descendantPartInstance
      end
    end
    return nil
  end

  local function IsBlockAtPositionVerified(expectedCenterPosition, expectedSize, expectedColor,
    expectedMaterialEnum, expectedAnchoredState, expectedCollideState)
    local matchedPartInstance = FindExistingBlockAtPosition(expectedCenterPosition, expectedSize)
    if not matchedPartInstance then return false end
    if expectedColor and not AreColorsWithinTolerance(matchedPartInstance.Color, expectedColor) then return false end
    if expectedMaterialEnum and matchedPartInstance.Material ~= expectedMaterialEnum then return false end
    if expectedAnchoredState ~= nil and matchedPartInstance.Anchored ~= expectedAnchoredState then return false end
    if expectedCollideState ~= nil and matchedPartInstance.CanCollide ~= expectedCollideState then return false end
    return true
  end

  local function CreatePreviewPartInstance(cornerOrCenterPosition, blockSize, blockColor, blockMaterialEnum,
    transparencyOverride, anchoredOverride, collideOverride, sprayDataList)
    if typeof(cornerOrCenterPosition) == "CFrame" then cornerOrCenterPosition = cornerOrCenterPosition.Position end
    local previewPartInstance = Instance.new("Part")
    currentPreviewPartInstance    = previewPartInstance
    previewPartInstance.Anchored     = anchoredOverride ~= false
    previewPartInstance.CanCollide   = collideOverride or false
    previewPartInstance.CastShadow   = false
    previewPartInstance.CanQuery     = false
    previewPartInstance.Color        = blockColor
    previewPartInstance.Transparency = transparencyOverride or 0.5
    previewPartInstance.Material     = blockMaterialEnum or Enum.Material.SmoothPlastic
    previewPartInstance.Size = blockSize
      or Vector3.new(DefaultGridUnitSizeInStuds, DefaultGridUnitSizeInStuds, DefaultGridUnitSizeInStuds)
    local finalCenterPosition = cornerOrCenterPosition
    if blockSize then
      finalCenterPosition = Vector3.new(
        cornerOrCenterPosition.X + blockSize.X / 2 - 0.5,
        cornerOrCenterPosition.Y + blockSize.Y / 2 - 0.5,
        cornerOrCenterPosition.Z + blockSize.Z / 2 - 0.5
      )
    end
    previewPartInstance.CFrame = CFrame.new(finalCenterPosition)
    if sprayDataList then
      for _, singleSprayData in pairs(sprayDataList) do
        local sprayFaceEnum = Enum.NormalId[singleSprayData[1]]
        local sprayPayloadText = singleSprayData[3] or ""
        local surfaceGuiInstance = Instance.new("SurfaceGui")
        surfaceGuiInstance.Face          = sprayFaceEnum
        surfaceGuiInstance.SizingMode    = Enum.SurfaceGuiSizingMode.PixelsPerStud
        surfaceGuiInstance.PixelsPerStud = 50
        local _, hashCharacterCount = string.gsub(sprayPayloadText, "#", "l")
        if hashCharacterCount == #sprayPayloadText then
          local sprayImageLabelInstance = Instance.new("ImageLabel", surfaceGuiInstance)
          sprayImageLabelInstance.Image = singleSprayData[2]
          sprayImageLabelInstance.BackgroundTransparency = 1
          sprayImageLabelInstance.Size = UDim2.new(1, 0, 1, 0)
        else
          local sprayTextLabelInstance = Instance.new("TextLabel", surfaceGuiInstance)
          sprayTextLabelInstance.Text = sprayPayloadText
          sprayTextLabelInstance.BackgroundTransparency = 1
          sprayTextLabelInstance.TextScaled = true
          sprayTextLabelInstance.TextColor3 = Color3.new(1, 1, 1)
          sprayTextLabelInstance.Font = Enum.Font.FredokaOne
          sprayTextLabelInstance.Size = UDim2.new(1, 0, 1, 0)
        end
        surfaceGuiInstance.Parent = previewPartInstance
      end
    end
    previewPartInstance.Parent = workspace
    return previewPartInstance
  end

  local function FireToolRemoteEvent(toolName, remoteArgumentList)
    pcall(function()
      if customFetchToolsFunction then
        local resolvedRemoteEventOrFunction = customFetchToolsFunction(toolName)
        if resolvedRemoteEventOrFunction == nil then return end
        if typeof(resolvedRemoteEventOrFunction) == "Instance"
          and resolvedRemoteEventOrFunction:IsA("BindableFunction") then
          resolvedRemoteEventOrFunction:Invoke(table.unpack(remoteArgumentList))
        else
          resolvedRemoteEventOrFunction:FireServer(table.unpack(remoteArgumentList))
        end
        return
      end
      local characterModelInstance = LocalPlayerInstance.Character
      if not characterModelInstance then return end
      local toolInstance = characterModelInstance:FindFirstChild(toolName)
      if not toolInstance then
        local backpackInstance = LocalPlayerInstance:FindFirstChildOfClass("Backpack")
        local toolInBackpack = backpackInstance and backpackInstance:FindFirstChild(toolName)
        if toolInBackpack then toolInBackpack.Parent = characterModelInstance end
        toolInstance = characterModelInstance:FindFirstChild(toolName)
      end
      if not toolInstance then return end
      local originalEventBindableFunction = toolInstance:FindFirstChild("origevent")
      if originalEventBindableFunction then
        originalEventBindableFunction:Invoke(table.unpack(remoteArgumentList))
      else
        toolInstance.Script.Event:FireServer(table.unpack(remoteArgumentList))
      end
    end)
  end

  local function FireBuildToolEvent(remoteArgumentList) FireToolRemoteEvent("Build", remoteArgumentList) end
  local function FirePaintToolEvent(remoteArgumentList) FireToolRemoteEvent("Paint", remoteArgumentList) end

  local function HandleNewBlockAddedToHistory(newChildInstance)
    if not newChildInstance:IsA("BasePart") then return end
    mostRecentlyBuiltBlockInstance = newChildInstance
    recentlyBuiltBlockHistoryWriteIndex =
      (recentlyBuiltBlockHistoryWriteIndex % sessionConfiguration.historymax) + 1
    recentlyBuiltBlockHistoryList[recentlyBuiltBlockHistoryWriteIndex] = newChildInstance
    wasBlockJustConfirmedBuilt = true
    DebugLog("HandleNewBlockAddedToHistory: new block at", tostring(newChildInstance.Position),
      "| historyIndex =", recentlyBuiltBlockHistoryWriteIndex)
  end

  do
    if not BlockContainerFolder:FindFirstChild(LocalPlayerInstance.Name) then
      EnsureRequiredToolsAreEquipped(true)
      local probePosition = Vector3.new(6777, 6969, 6777)
      DebugLog("No block folder found for local player yet; probing with a throwaway build at", tostring(probePosition))
      repeat
        FireBuildToolEvent({ workspace.Terrain, Enum.NormalId.Top, probePosition, "normal" })
        task.wait(0.2)
      until BlockContainerFolder:FindFirstChild(LocalPlayerInstance.Name)
        or getgenv()[GENERATION_COUNTER_GLOBAL_KEY] ~= currentModuleGenerationNumber
    end
    local childAddedConnection =
      BlockContainerFolder[LocalPlayerInstance.Name].ChildAdded:Connect(HandleNewBlockAddedToHistory)
    getgenv()[CONNECTION_HANDLE_GLOBAL_KEY] = childAddedConnection
  end

  local currentTeleportTargetPosition = nil
  task.spawn(function()
    while not isBuildSessionStopped or currentTeleportTargetPosition do
      if currentTeleportTargetPosition then
        pcall(function()
          LocalPlayerInstance.Character.HumanoidRootPart.CFrame =
            typeof(currentTeleportTargetPosition) == "CFrame"
              and currentTeleportTargetPosition
              or CFrame.new(currentTeleportTargetPosition)
        end)
      end
      task.wait(0.01)
      if isBuildSessionStopped and not currentTeleportTargetPosition then break end
    end
  end)

  local function RequestTeleportToPosition(targetPositionOrCFrame)
    currentTeleportTargetPosition = targetPositionOrCFrame
    task.wait(0.01)
  end

  local function CancelActiveTeleportRequest()
    currentTeleportTargetPosition = nil
  end

  local function BuildAndConfigureSignBlock(signDataEntry, activeTransform)
    local signCFrame = CFrame.new(table.unpack(signDataEntry.p))
    local signWorldPosition = signCFrame.Position + (activeTransform and activeTransform.offset or Vector3.zero)

    local signNormalIdEnum = FaceNameToNormalIdEnumMap[signDataEntry.sid] or Enum.NormalId.Front
    local signFaceDirection = signCFrame:VectorToWorldSpace(NormalIdToDirectionAndAxisNameMap[signNormalIdEnum][1])
    local playerStandPosition = signWorldPosition + signFaceDirection * 3
    local upVectorForLookAt =
      math.abs(signFaceDirection:Dot(Vector3.yAxis)) > 0.99 and Vector3.zAxis or Vector3.yAxis
    local playerStandCFrame = CFrame.lookAt(playerStandPosition, signWorldPosition, upVectorForLookAt)

    local buildReferencePart, buildReferenceNormalId = workspace.Terrain, Enum.NormalId.Top

    wasBlockJustConfirmedBuilt = false
    mostRecentlyBuiltBlockInstance = nil
    local attemptCount = 0
    repeat
      attemptCount = attemptCount + 1
      RequestTeleportToPosition(playerStandCFrame)
      task.wait(0.3)
      FireToolRemoteEvent("Sign", { buildReferencePart, buildReferenceNormalId,
        Vector3.new(signWorldPosition.X, signWorldPosition.Y - 1, signWorldPosition.Z) })
    until wasBlockJustConfirmedBuilt or isBuildSessionStopped or isCurrentBlockSkipRequested or attemptCount > 10
    CancelActiveTeleportRequest()
    DebugLog("BuildAndConfigureSignBlock: build attempts =", attemptCount, "| built =", wasBlockJustConfirmedBuilt)

    if mostRecentlyBuiltBlockInstance and signDataEntry.txt and signDataEntry.txt ~= "" then
      task.wait(0.3)
      pcall(function()
        mostRecentlyBuiltBlockInstance:WaitForChild("Input"):WaitForChild("Label")
          :WaitForChild("Script"):WaitForChild("Event"):FireServer(signDataEntry.txt)
      end)
    end

    if mostRecentlyBuiltBlockInstance and signDataEntry.c then
      local signColor = Color3.fromRGB(table.unpack(signDataEntry.c))
      local signPaintPosition = mostRecentlyBuiltBlockInstance.Position + mostRecentlyBuiltBlockInstance.Size / 2
      local paintEventArgumentList =
        { mostRecentlyBuiltBlockInstance, Enum.NormalId.Top, signPaintPosition, "color", signColor, "tiles", "" }
      local paintAttemptCount = 0
      repeat
        paintAttemptCount = paintAttemptCount + 1
        FirePaintToolEvent(paintEventArgumentList)
        RequestTeleportToPosition(signWorldPosition)
        task.wait(0.2)
      until not mostRecentlyBuiltBlockInstance or not mostRecentlyBuiltBlockInstance.Parent
          or mostRecentlyBuiltBlockInstance.Color == signColor
          or isBuildSessionStopped or isCurrentBlockSkipRequested or paintAttemptCount > 20
      CancelActiveTeleportRequest()
    end

    wasBlockJustConfirmedBuilt = false
    mostRecentlyBuiltBlockInstance = nil
    isCurrentBlockSkipRequested = false
  end

  local function PlaceSingleBlock(targetCornerPosition, materialShortName, targetColor, requestedSizeMode,
    requestedSizeVector, isFromPremadeSaveFile, originalMaterialEnumName, sprayDataList,
    requestedAnchoredState, requestedCollideState)
    if requestedAnchoredState == nil then requestedAnchoredState = true end
    if requestedCollideState  == nil then requestedCollideState  = true end
    local needsShapeToolResize = false

    pcall(function()
      pcall(function() LocalPlayerInstance.Backpack.Build.Parent = LocalPlayerInstance.Character end)
      local adjacentReuseCandidate, retryCount = false, 0
      mostRecentlyBuiltBlockInstance = nil

      -- Step 1: try to reuse a directly-adjacent block from history instead of
      -- building fresh off the terrain (much faster when chaining blocks).
      if #recentlyBuiltBlockHistoryList > 0 and currentPreviewPartInstance then
        local adjacencyCandidateList = {}
        for historySlotIndex = 1, sessionConfiguration.historymax do
          local historyBlockInstance = recentlyBuiltBlockHistoryList[historySlotIndex]
          if historyBlockInstance == nil or historyBlockInstance.Parent == nil then
            recentlyBuiltBlockHistoryList[historySlotIndex] = nil
            continue
          end
          if currentPreviewPartInstance.Size ~= historyBlockInstance.Size then continue end
          local minimumBlockDimension =
            math.min(historyBlockInstance.Size.X, historyBlockInstance.Size.Y, historyBlockInstance.Size.Z)
          local adjacencyToleranceStuds = historyBlockInstance.Anchored and 0.01
            or math.min(0.75, minimumBlockDimension * 0.25)
          for candidateNormalId, candidateAxisInfo in pairs(NormalIdToDirectionAndAxisNameMap) do
            local candidateAdjacentPosition = historyBlockInstance.Position
              + candidateAxisInfo[1] * historyBlockInstance.Size[candidateAxisInfo[2]]
            local positionDifference = candidateAdjacentPosition - currentPreviewPartInstance.Position
            if positionDifference.X * positionDifference.X + positionDifference.Y * positionDifference.Y
              + positionDifference.Z * positionDifference.Z <= adjacencyToleranceStuds * adjacencyToleranceStuds then
              local adjacencyCandidateEntry = { candidateNormalId, historyBlockInstance,
                historyBlockInstance.Position + candidateAxisInfo[1] * historyBlockInstance.Size[candidateAxisInfo[2]] / 2 }
              table.insert(adjacencyCandidateList, adjacencyCandidateEntry)
              adjacentReuseCandidate = adjacencyCandidateEntry
            end
          end
        end
        if #adjacencyCandidateList > 1 and targetColor and adjacentReuseCandidate
          and adjacentReuseCandidate[2].Color ~= targetColor then
          for _, candidateEntry in pairs(adjacencyCandidateList) do
            if candidateEntry[2].Color == targetColor then adjacentReuseCandidate = candidateEntry end
          end
        end

        if adjacentReuseCandidate and adjacentReuseCandidate[2] and adjacentReuseCandidate[2].Parent then
          DebugLog("PlaceSingleBlock: reusing directly-adjacent history block at",
            tostring(adjacentReuseCandidate[2].Position))
          local originalTargetPosition = targetCornerPosition
          local buildEventArgumentList = { adjacentReuseCandidate[2], adjacentReuseCandidate[1],
            adjacentReuseCandidate[3] or currentPreviewPartInstance.Position, "normal" }
          wasBlockJustConfirmedBuilt = false
          mostRecentlyBuiltBlockInstance = nil
          retryCount = 0
          repeat
            retryCount = retryCount + 1
            FireBuildToolEvent(buildEventArgumentList)
            pcall(function()
              targetCornerPosition = adjacentReuseCandidate[3] or targetCornerPosition
              RequestTeleportToPosition(targetCornerPosition)
            end)
            RunService.Heartbeat:Wait()
          until (wasBlockJustConfirmedBuilt and mostRecentlyBuiltBlockInstance)
              or adjacentReuseCandidate[2] == nil or adjacentReuseCandidate[2].Parent == nil
              or isBuildSessionStopped or isCurrentBlockSkipRequested or retryCount > sessionConfiguration.maxtry
          CancelActiveTeleportRequest()
          if adjacentReuseCandidate[2] == nil or adjacentReuseCandidate[2].Parent == nil
            or retryCount > sessionConfiguration.maxtry then
            adjacentReuseCandidate = false
          else
            if currentPreviewPartInstance then currentPreviewPartInstance:Destroy() end
          end
          targetCornerPosition = originalTargetPosition
        end
      end

      -- Toggle CanCollide on an existing block via the Paint tool's "collide" action,
      -- run fn(), then restore original collision state. Used to pass a temp block
      -- through an obstruction at a step position without leaving world state changed.
      local function TemporarilyDisableCollisionAndRun(obstructingPartInstance, functionToRun)
        if not obstructingPartInstance or not obstructingPartInstance.Parent then return functionToRun() end
        local originalCollideState = obstructingPartInstance.CanCollide
        if originalCollideState == false then return functionToRun() end
        local function SetCollideStateOnPart(targetPartInstance, desiredCollideState)
          pcall(function() LocalPlayerInstance.Backpack.Paint.Parent = LocalPlayerInstance.Character end)
          local collideTogglePaintPosition = targetPartInstance.Position + targetPartInstance.Size / 2
          local collideToggleArgumentList =
            { targetPartInstance, Enum.NormalId.Top, collideTogglePaintPosition, "material", nil, "collide", "" }
          local collideToggleRetryCount = 0
          repeat
            collideToggleRetryCount = collideToggleRetryCount + 1
            if LocalPlayerInstance.Character and not LocalPlayerInstance.Character:FindFirstChild("Paint")
              and LocalPlayerInstance.Backpack:FindFirstChild("Paint") then
              LocalPlayerInstance.Backpack.Paint.Parent = LocalPlayerInstance.Character
            end
            if LocalPlayerInstance.Character and LocalPlayerInstance.Character:FindFirstChild("Paint")
              and targetPartInstance and targetPartInstance.Parent
              and targetPartInstance.CanCollide ~= desiredCollideState then
              FirePaintToolEvent(collideToggleArgumentList)
            end
            task.wait(math.max(0.03, GetCurrentStepDelaySeconds()))
          until not targetPartInstance or not targetPartInstance.Parent
              or targetPartInstance.CanCollide == desiredCollideState
              or isBuildSessionStopped or isCurrentBlockSkipRequested
              or collideToggleRetryCount > sessionConfiguration.maxtry
        end
        SetCollideStateOnPart(obstructingPartInstance, false)
        local wasFunctionSuccessful, functionResult = pcall(functionToRun)
        if obstructingPartInstance and obstructingPartInstance.Parent then
          SetCollideStateOnPart(obstructingPartInstance, true)
        end
        if not wasFunctionSuccessful then return nil end
        return functionResult
      end

      -- Fire a single build step from `fromPartInstance` toward `faceTargetPosition`,
      -- returning the newly built part or nil. If an existing block occupies the
      -- target spot, temporarily disable its collision so the step can pass through it.
      local function BuildSingleHopStepTowardTarget(fromPartInstance, hopNormalId, faceTargetPosition)
        local obstructingPartInstance = FindExistingBlockAtPosition(faceTargetPosition, fromPartInstance.Size)
        local function AttemptSingleHopBuild()
          wasBlockJustConfirmedBuilt = false
          mostRecentlyBuiltBlockInstance = nil
          local hopAttemptCount = 0
          repeat
            hopAttemptCount = hopAttemptCount + 1
            FireBuildToolEvent({ fromPartInstance, hopNormalId, faceTargetPosition, "normal" })
            pcall(function() RequestTeleportToPosition(faceTargetPosition) end)
            RunService.Heartbeat:Wait()
          until (wasBlockJustConfirmedBuilt and mostRecentlyBuiltBlockInstance)
              or fromPartInstance.Parent == nil or isBuildSessionStopped or isCurrentBlockSkipRequested
              or hopAttemptCount > sessionConfiguration.maxtry
          DebugLog("BuildSingleHopStepTowardTarget: attempts =", hopAttemptCount,
            "| succeeded =", wasBlockJustConfirmedBuilt and mostRecentlyBuiltBlockInstance ~= nil)
          return (wasBlockJustConfirmedBuilt and mostRecentlyBuiltBlockInstance) and mostRecentlyBuiltBlockInstance or nil
        end
        if obstructingPartInstance and obstructingPartInstance.Parent then
          return TemporarilyDisableCollisionAndRun(obstructingPartInstance, AttemptSingleHopBuild)
        end
        return AttemptSingleHopBuild()
      end

      -- Delete a temp block via the Delete tool, retrying until the SERVER
      -- confirms removal (temp.Parent == nil). This never calls :Destroy()
      -- locally — a client-side destroy only removes the instance from our
      -- own view; the server still thinks the block exists, so it would
      -- still be solid/visible to everyone else and still poison future
      -- adjacency scans on the server's copy of the world. If the Delete
      -- tool round-trip genuinely can't get a confirmation, the block is
      -- left in place and logged rather than faked away.
      local function DeleteTemporaryHopBlock(temporaryBlockInstance)
        if not temporaryBlockInstance then return end
        local deleteRetryCount = 0
        repeat
          deleteRetryCount = deleteRetryCount + 1
          -- Teleport the player to the block's own position first and give the
          -- server a moment to register proximity before firing the Delete event.
          pcall(function() RequestTeleportToPosition(temporaryBlockInstance.Position) end)
          task.wait(0.2)
          pcall(function()
            if not temporaryBlockInstance or not temporaryBlockInstance.Parent then return end
            if LocalPlayerInstance.Character and not LocalPlayerInstance.Character:FindFirstChild("Delete")
              and LocalPlayerInstance.Backpack:FindFirstChild("Delete") then
              LocalPlayerInstance.Backpack.Delete.Parent = LocalPlayerInstance.Character
            end
            local deleteToolInstance = LocalPlayerInstance.Character:FindFirstChild("Delete")
              or LocalPlayerInstance.Backpack:FindFirstChild("Delete")
            if deleteToolInstance then
              local deleteScriptInstance = deleteToolInstance:FindFirstChild("Script")
              local deleteRemoteEvent = deleteScriptInstance and deleteScriptInstance:FindFirstChild("Event")
              if deleteRemoteEvent then
                deleteRemoteEvent:FireServer(temporaryBlockInstance, temporaryBlockInstance.Position)
              end
            end
          end)
          task.wait(math.max(0.03, GetCurrentStepDelaySeconds()))
        until not temporaryBlockInstance or not temporaryBlockInstance.Parent
            or isBuildSessionStopped or isCurrentBlockSkipRequested
            or deleteRetryCount > sessionConfiguration.maxtry
        CancelActiveTeleportRequest()
        DebugLog("DeleteTemporaryHopBlock: attempts =", deleteRetryCount,
          "| confirmedDeleted =", not (temporaryBlockInstance and temporaryBlockInstance.Parent))
        if temporaryBlockInstance and temporaryBlockInstance.Parent then
          LogMessage("WARNING: temp block at " .. tostring(temporaryBlockInstance.Position)
            .. " could not be confirmed deleted after " .. sessionConfiguration.maxtry .. " tries; left in place.")
        end
      end

      -- Step 2: no direct neighbor found — search history for a block 2 or 3
      -- grid-steps diagonally away and, if found, walk toward the target via
      -- one or two disposable "hop" blocks.
      if adjacentReuseCandidate == false and #recentlyBuiltBlockHistoryList > 0 and currentPreviewPartInstance then
        local diagonalAnchorBlockInstance, hopNormalIdSequence = nil, nil
        local diagonalTargetPosition = currentPreviewPartInstance.Position

        for historySlotIndex = 1, sessionConfiguration.historymax do
          local historyBlockInstance = recentlyBuiltBlockHistoryList[historySlotIndex]
          if historyBlockInstance == nil or historyBlockInstance.Parent == nil then
            recentlyBuiltBlockHistoryList[historySlotIndex] = nil
            continue
          end
          if currentPreviewPartInstance.Size ~= historyBlockInstance.Size then continue end

          -- Diagonal fast-hop math below assumes every block in the chain is a
          -- standard GridUnitSize cube: BuildSingleHopStepTowardTarget always
          -- fires the "normal" build mode, which the server always resolves to
          -- a 4x4x4 (DefaultGridUnitSizeInStuds) cube regardless of the source
          -- part's actual size. If historyBlockInstance (and therefore
          -- currentPreviewPartInstance, since it's already gated equal above)
          -- is not a plain GridUnitSize cube -- e.g. a resized 4x4x40 block --
          -- then using its size for the face offset would either understate the
          -- step (short axis of a long block) or wildly overstate it (hopping
          -- along the long axis itself), landing the temp/real block far from
          -- where the tolerance check below expects it. Rather than trying to
          -- generalize the corner/face-diagonal geometry to arbitrary block
          -- shapes, we just skip the fast-hop route for non-standard sizes and
          -- let this fall through to a normal terrain placement (+ later
          -- Shape-tool resize) instead.
          if historyBlockInstance.Size.X ~= DefaultGridUnitSizeInStuds
            or historyBlockInstance.Size.Y ~= DefaultGridUnitSizeInStuds
            or historyBlockInstance.Size.Z ~= DefaultGridUnitSizeInStuds then
            continue
          end

          local minimumBlockDimension =
            math.min(historyBlockInstance.Size.X, historyBlockInstance.Size.Y, historyBlockInstance.Size.Z)
          local diagonalToleranceStuds = historyBlockInstance.Anchored and 0.01
            or math.min(0.75, minimumBlockDimension * 0.25)
          local positionDelta = diagonalTargetPosition - historyBlockInstance.Position
          local numberOfOffsetAxes =
            (math.abs(positionDelta.X) > diagonalToleranceStuds and 1 or 0)
            + (math.abs(positionDelta.Y) > diagonalToleranceStuds and 1 or 0)
            + (math.abs(positionDelta.Z) > diagonalToleranceStuds and 1 or 0)
          if numberOfOffsetAxes ~= 2 and numberOfOffsetAxes ~= 3 then continue end

          if numberOfOffsetAxes == 2 then
            -- 2-axis face diagonal: one intermediate hop
            for firstHopNormalId, firstHopAxisInfo in pairs(NormalIdToDirectionAndAxisNameMap) do
              local intermediateHopPosition = historyBlockInstance.Position
                + firstHopAxisInfo[1] * historyBlockInstance.Size[firstHopAxisInfo[2]]
              for secondHopNormalId, secondHopAxisInfo in pairs(NormalIdToDirectionAndAxisNameMap) do
                local finalPositionDifference = intermediateHopPosition
                  + secondHopAxisInfo[1] * historyBlockInstance.Size[secondHopAxisInfo[2]] - diagonalTargetPosition
                if finalPositionDifference.X * finalPositionDifference.X
                  + finalPositionDifference.Y * finalPositionDifference.Y
                  + finalPositionDifference.Z * finalPositionDifference.Z < 0.0225 then
                  diagonalAnchorBlockInstance = historyBlockInstance
                  hopNormalIdSequence = { firstHopNormalId, secondHopNormalId }
                  break
                end
              end
              if hopNormalIdSequence then break end
            end
          else
            -- 3-axis corner diagonal: two intermediate hops
            for firstHopNormalId, firstHopAxisInfo in pairs(NormalIdToDirectionAndAxisNameMap) do
              local firstIntermediateHopPosition = historyBlockInstance.Position
                + firstHopAxisInfo[1] * historyBlockInstance.Size[firstHopAxisInfo[2]]
              for secondHopNormalId, secondHopAxisInfo in pairs(NormalIdToDirectionAndAxisNameMap) do
                local secondIntermediateHopPosition = firstIntermediateHopPosition
                  + secondHopAxisInfo[1] * historyBlockInstance.Size[secondHopAxisInfo[2]]
                for thirdHopNormalId, thirdHopAxisInfo in pairs(NormalIdToDirectionAndAxisNameMap) do
                  local finalPositionDifference = secondIntermediateHopPosition
                    + thirdHopAxisInfo[1] * historyBlockInstance.Size[thirdHopAxisInfo[2]] - diagonalTargetPosition
                  if finalPositionDifference.X * finalPositionDifference.X
                    + finalPositionDifference.Y * finalPositionDifference.Y
                    + finalPositionDifference.Z * finalPositionDifference.Z < 0.0225 then
                    diagonalAnchorBlockInstance = historyBlockInstance
                    hopNormalIdSequence = { firstHopNormalId, secondHopNormalId, thirdHopNormalId }
                    break
                  end
                end
                if hopNormalIdSequence then break end
              end
              if hopNormalIdSequence then break end
            end
          end
          if hopNormalIdSequence then break end
        end

        if diagonalAnchorBlockInstance and diagonalAnchorBlockInstance.Parent and hopNormalIdSequence then
          DebugLog("PlaceSingleBlock: attempting diagonal fast-hop with", #hopNormalIdSequence, "hop(s) from",
            tostring(diagonalAnchorBlockInstance.Position))
          local temporaryHopBlockList = {}
          local currentHopSourcePart = diagonalAnchorBlockInstance
          local wasEveryHopSuccessful = true

          for hopIndex = 1, #hopNormalIdSequence do
            local hopNormalId = hopNormalIdSequence[hopIndex]
            local hopFacePosition = currentHopSourcePart.Position
              + NormalIdToDirectionAndAxisNameMap[hopNormalId][1]
                * currentHopSourcePart.Size[NormalIdToDirectionAndAxisNameMap[hopNormalId][2]] / 2
            local isFinalHop = (hopIndex == #hopNormalIdSequence)
            local producedBlockInstance = BuildSingleHopStepTowardTarget(currentHopSourcePart, hopNormalId, hopFacePosition)
            if not producedBlockInstance or isBuildSessionStopped or isCurrentBlockSkipRequested then
              wasEveryHopSuccessful = false
              break
            end
            if not isFinalHop then
              table.insert(temporaryHopBlockList, producedBlockInstance)
            else
              -- final hop produced the real block
              for _, temporaryHopBlockInstance in ipairs(temporaryHopBlockList) do
                DeleteTemporaryHopBlock(temporaryHopBlockInstance)
              end
              adjacentReuseCandidate = { hopNormalId, currentHopSourcePart, hopFacePosition }
              mostRecentlyBuiltBlockInstance = producedBlockInstance
              if currentPreviewPartInstance then currentPreviewPartInstance:Destroy() end
            end
            currentHopSourcePart = producedBlockInstance
          end

          if not wasEveryHopSuccessful then
            for _, temporaryHopBlockInstance in ipairs(temporaryHopBlockList) do
              DeleteTemporaryHopBlock(temporaryHopBlockInstance)
            end
            adjacentReuseCandidate = false
            mostRecentlyBuiltBlockInstance = nil
          end
        end
      end

      -- Step 3: fall back to a plain terrain placement.
      if adjacentReuseCandidate == false then
        DebugLog("PlaceSingleBlock: falling back to terrain placement at", tostring(targetCornerPosition))
        if requestedSizeMode == nil then
          requestedSizeMode = "normal"
          if LocalPlayerInstance.PlayerGui:FindFirstChild("Build")
            and LocalPlayerInstance.PlayerGui.Build:FindFirstChild("Button") then
            requestedSizeMode = LocalPlayerInstance.PlayerGui.Build.Button.Text
          end
          if requestedSizeVector and (requestedSizeVector.X ~= DefaultGridUnitSizeInStuds
            or requestedSizeVector.Y ~= DefaultGridUnitSizeInStuds
            or requestedSizeVector.Z ~= DefaultGridUnitSizeInStuds) then
            requestedSizeMode = "detailed"
          elseif requestedSizeVector then
            requestedSizeMode = "normal"
          end
          if not requestedSizeVector and requestedSizeMode ~= "detailed" and currentPreviewPartInstance
            and currentPreviewPartInstance.Position ~= SnapPositionToGrid(targetCornerPosition, currentPreviewPartInstance.Size.X) then
            requestedSizeMode      = "detailed"
            needsShapeToolResize   = true
            requestedSizeVector    = currentPreviewPartInstance.Size
            targetCornerPosition = Vector3.new(
              targetCornerPosition.X - requestedSizeVector.X / 2 + 0.5,
              targetCornerPosition.Y - requestedSizeVector.Y / 2 + 0.5,
              targetCornerPosition.Z - requestedSizeVector.Z / 2 + 0.5
            )
          end
        end
        local terrainBuildArgumentList =
          { workspace.Terrain, Enum.NormalId.Top, targetCornerPosition, requestedSizeMode or "normal" }
        wasBlockJustConfirmedBuilt = false
        FireBuildToolEvent(terrainBuildArgumentList)
        retryCount = 0
        repeat
          retryCount = retryCount + 1
          if LocalPlayerInstance.Character and not LocalPlayerInstance.Character:FindFirstChild("Build")
            and LocalPlayerInstance.Backpack:FindFirstChild("Build") then
            LocalPlayerInstance.Backpack.Build.Parent = LocalPlayerInstance.Character
          end
          if LocalPlayerInstance.Character:FindFirstChild("Build") then
            FireBuildToolEvent(terrainBuildArgumentList)
          end
          pcall(function() RequestTeleportToPosition(targetCornerPosition + Vector3.new(0, 6, 0)) end)
          RunService.Heartbeat:Wait()
        until (wasBlockJustConfirmedBuilt and mostRecentlyBuiltBlockInstance)
            or isBuildSessionStopped or isCurrentBlockSkipRequested or retryCount > sessionConfiguration.maxtry
        CancelActiveTeleportRequest()
        wasBlockJustConfirmedBuilt = false
        retryCount = 0
      end

      -- Paint color/material.
      if mostRecentlyBuiltBlockInstance and typeof(targetColor) == "Color3"
        and (LocalPlayerInstance.Backpack:FindFirstChild("Paint") or LocalPlayerInstance.Character:FindFirstChild("Paint"))
      then
        local paintTargetPosition = mostRecentlyBuiltBlockInstance.Position + mostRecentlyBuiltBlockInstance.Size / 2
        local paintEventArgumentList =
          { mostRecentlyBuiltBlockInstance, Enum.NormalId.Top, paintTargetPosition, "color", targetColor, "tiles", "" }
        pcall(function() LocalPlayerInstance.Backpack.Paint.Parent = LocalPlayerInstance.Character end)
        if materialShortName then
          paintEventArgumentList[4] = targetColor == nil and "material" or "both \u{1F91D}"
          paintEventArgumentList[6] = materialShortName
        end
        if not mostRecentlyBuiltBlockInstance then
          if currentPreviewPartInstance then currentPreviewPartInstance:Destroy() end
          return
        end
        currentBlockHighlightInstance.Adornee = mostRecentlyBuiltBlockInstance
        retryCount = 0
        pcall(function()
          repeat
            retryCount = retryCount + 1
            if LocalPlayerInstance.Character and not LocalPlayerInstance.Character:FindFirstChild("Paint")
              and LocalPlayerInstance.Backpack:FindFirstChild("Paint") then
              LocalPlayerInstance.Backpack.Paint.Parent = LocalPlayerInstance.Character
            end
            if LocalPlayerInstance.Character and LocalPlayerInstance.Character:FindFirstChild("Paint") then
              FirePaintToolEvent(paintEventArgumentList)
            end
            pcall(function() RequestTeleportToPosition(paintTargetPosition + Vector3.new(0, 6, 0)) end)
            RunService.Heartbeat:Wait()
          until not mostRecentlyBuiltBlockInstance or not mostRecentlyBuiltBlockInstance.Parent
              or mostRecentlyBuiltBlockInstance.Color == targetColor
              or (materialShortName and mostRecentlyBuiltBlockInstance.Material == Enum.Material[originalMaterialEnumName])
              or isBuildSessionStopped or isCurrentBlockSkipRequested or retryCount > 250
        end)
      end

      -- Fix anchored state.
      if mostRecentlyBuiltBlockInstance and LocalPlayerInstance.Character
        and LocalPlayerInstance.Character:FindFirstChild("Paint")
        and mostRecentlyBuiltBlockInstance.Anchored ~= requestedAnchoredState then
        local anchorTogglePosition = mostRecentlyBuiltBlockInstance.Position + mostRecentlyBuiltBlockInstance.Size / 2
        local anchorToggleArgumentList =
          { mostRecentlyBuiltBlockInstance, Enum.NormalId.Top, anchorTogglePosition, "material", nil, "anchor", "" }
        retryCount = 0
        repeat
          retryCount = retryCount + 1
          if LocalPlayerInstance.Character and not LocalPlayerInstance.Character:FindFirstChild("Paint")
            and LocalPlayerInstance.Backpack:FindFirstChild("Paint") then
            LocalPlayerInstance.Backpack.Paint.Parent = LocalPlayerInstance.Character
          end
          if LocalPlayerInstance.Character and LocalPlayerInstance.Character:FindFirstChild("Paint")
            and mostRecentlyBuiltBlockInstance and mostRecentlyBuiltBlockInstance.Anchored ~= requestedAnchoredState then
            FirePaintToolEvent(anchorToggleArgumentList)
          end
          pcall(function() RequestTeleportToPosition(anchorTogglePosition + Vector3.new(0, 8, 0)) end)
          task.wait(0.15)
        until not mostRecentlyBuiltBlockInstance or not mostRecentlyBuiltBlockInstance.Parent
            or mostRecentlyBuiltBlockInstance.Anchored == requestedAnchoredState
            or not LocalPlayerInstance.Character
            or (not LocalPlayerInstance.Character:FindFirstChild("Paint")
              and not LocalPlayerInstance.Backpack:FindFirstChild("Paint"))
            or isBuildSessionStopped or isCurrentBlockSkipRequested or retryCount > 12
      end

      -- Fix collide state.
      if mostRecentlyBuiltBlockInstance and LocalPlayerInstance.Character
        and LocalPlayerInstance.Character:FindFirstChild("Paint")
        and mostRecentlyBuiltBlockInstance.CanCollide ~= requestedCollideState then
        local collideTogglePosition = mostRecentlyBuiltBlockInstance.Position + mostRecentlyBuiltBlockInstance.Size / 2
        local collideToggleArgumentList =
          { mostRecentlyBuiltBlockInstance, Enum.NormalId.Top, collideTogglePosition, "material", nil, "collide", "" }
        retryCount = 0
        repeat
          retryCount = retryCount + 1
          if LocalPlayerInstance.Character and not LocalPlayerInstance.Character:FindFirstChild("Paint")
            and LocalPlayerInstance.Backpack:FindFirstChild("Paint") then
            LocalPlayerInstance.Backpack.Paint.Parent = LocalPlayerInstance.Character
          end
          if LocalPlayerInstance.Character and LocalPlayerInstance.Character:FindFirstChild("Paint")
            and mostRecentlyBuiltBlockInstance and mostRecentlyBuiltBlockInstance.CanCollide ~= requestedCollideState then
            FirePaintToolEvent(collideToggleArgumentList)
          end
          pcall(function() RequestTeleportToPosition(collideTogglePosition + Vector3.new(0, 8, 0)) end)
          task.wait(0.15)
        until not mostRecentlyBuiltBlockInstance or not mostRecentlyBuiltBlockInstance.Parent
            or mostRecentlyBuiltBlockInstance.CanCollide == requestedCollideState
            or not LocalPlayerInstance.Character
            or (not LocalPlayerInstance.Character:FindFirstChild("Paint")
              and not LocalPlayerInstance.Backpack:FindFirstChild("Paint"))
            or isBuildSessionStopped or isCurrentBlockSkipRequested or retryCount > 12
      end

      currentBlockHighlightInstance.Adornee = nil

      -- Apply spray decals.
      if mostRecentlyBuiltBlockInstance
        and (LocalPlayerInstance.Backpack:FindFirstChild("Paint") or LocalPlayerInstance.Character:FindFirstChild("Paint"))
        and sprayDataList then
        local sprayEventArgumentList = { mostRecentlyBuiltBlockInstance, Enum.NormalId.Front,
          mostRecentlyBuiltBlockInstance.Position + Vector3.new(1, 0, 0), "material", nil, "spray", "ha" }
        for _, singleSprayData in pairs(sprayDataList) do
          sprayEventArgumentList[2] = Enum.NormalId[singleSprayData[1]]
          local sprayPayloadText = singleSprayData[3]
          if (not sprayPayloadText or sprayPayloadText == "") and type(singleSprayData[2]) == "string"
            and singleSprayData[2] ~= "" then
            sprayPayloadText = singleSprayData[2]
          end
          sprayEventArgumentList[7] = sprayPayloadText or ""
          if mostRecentlyBuiltBlockInstance
            and (LocalPlayerInstance.Backpack:FindFirstChild("Paint") or LocalPlayerInstance.Character:FindFirstChild("Paint"))
            and not isBuildSessionStopped and not isCurrentBlockSkipRequested then
            pcall(function() LocalPlayerInstance.Backpack.Paint.Parent = LocalPlayerInstance.Character end)
            pcall(function()
              task.wait(0.25)
              FirePaintToolEvent(sprayEventArgumentList)
            end)
          end
        end
      end

      -- Resize via Shape tool if the requested size differs from the grid default.
      if mostRecentlyBuiltBlockInstance
        and ((requestedSizeVector and (requestedSizeVector.X ~= DefaultGridUnitSizeInStuds
          or requestedSizeVector.Y ~= DefaultGridUnitSizeInStuds
          or requestedSizeVector.Z ~= DefaultGridUnitSizeInStuds)) or needsShapeToolResize)
        and (LocalPlayerInstance.Character:FindFirstChild("Shape") or LocalPlayerInstance.Backpack:FindFirstChild("Shape"))
      then
        if not LocalPlayerInstance.Character:FindFirstChild("Shape")
          and LocalPlayerInstance.Backpack:FindFirstChild("Shape") then
          LocalPlayerInstance.Backpack.Shape.Parent = LocalPlayerInstance.Character
        end
        local resizeEventArgumentList = { mostRecentlyBuiltBlockInstance, Enum.NormalId.Right, "", "" }
        local function ResizeSingleAxis(axisComponentName, targetAxisSize)
          if not (mostRecentlyBuiltBlockInstance
            and mostRecentlyBuiltBlockInstance.Size[axisComponentName] ~= targetAxisSize) then
            return
          end
          retryCount = 0
          repeat
            retryCount = retryCount + 1
            local resizeReferencePosition = (mostRecentlyBuiltBlockInstance
              and mostRecentlyBuiltBlockInstance.Position + mostRecentlyBuiltBlockInstance.Size / 2)
              or targetCornerPosition
            resizeEventArgumentList[3] = resizeReferencePosition
            resizeEventArgumentList[4] = nil
            if mostRecentlyBuiltBlockInstance then
              if mostRecentlyBuiltBlockInstance.Size[axisComponentName] > targetAxisSize then
                resizeEventArgumentList[4] = "decrease"
              elseif mostRecentlyBuiltBlockInstance.Size[axisComponentName] < targetAxisSize then
                resizeEventArgumentList[4] = "increase"
              end
            end
            if not LocalPlayerInstance.Character:FindFirstChild("Shape")
              and LocalPlayerInstance.Backpack:FindFirstChild("Shape") then
              LocalPlayerInstance.Backpack.Shape.Parent = LocalPlayerInstance.Character
            end
            if LocalPlayerInstance.Character:FindFirstChild("Shape") then
              pcall(function()
                local shapeOriginalEventBindableFunction =
                  LocalPlayerInstance.Character.Shape:FindFirstChild("origevent")
                if shapeOriginalEventBindableFunction then
                  shapeOriginalEventBindableFunction:Invoke(table.unpack(resizeEventArgumentList))
                else
                  LocalPlayerInstance.Character.Shape.Script.Event:FireServer(table.unpack(resizeEventArgumentList))
                end
              end)
            end
            pcall(function() RequestTeleportToPosition(resizeReferencePosition + Vector3.new(0, 6, 0)) end)
            task.wait(sessionConfiguration.resizewait)
          until resizeEventArgumentList[4] == nil
              or (resizeEventArgumentList[4] == "decrease" and mostRecentlyBuiltBlockInstance
                and mostRecentlyBuiltBlockInstance.Size[axisComponentName] <= 1)
              or (mostRecentlyBuiltBlockInstance
                and mostRecentlyBuiltBlockInstance.Size[axisComponentName] == targetAxisSize)
              or isBuildSessionStopped or isCurrentBlockSkipRequested
              or retryCount > (targetAxisSize * 3) / sessionConfiguration.resizewait
        end
        resizeEventArgumentList[2] = Enum.NormalId.Right; ResizeSingleAxis("X", requestedSizeVector.X)
        resizeEventArgumentList[2] = Enum.NormalId.Top;   ResizeSingleAxis("Y", requestedSizeVector.Y)
        resizeEventArgumentList[2] = Enum.NormalId.Back;  ResizeSingleAxis("Z", requestedSizeVector.Z)
      end
      isCurrentBlockSkipRequested = false
    end)
    if currentPreviewPartInstance then currentPreviewPartInstance:Destroy() end
    mostRecentlyBuiltBlockInstance = nil
  end

  local function ApplyOffsetAndRotationTransform(rawCornerPosition, blockSize, activeTransform)
    if not activeTransform or not activeTransform.enabled then return rawCornerPosition end
    local halfSizeOffset = Vector3.new(blockSize.X / 2 - 0.5, blockSize.Y / 2 - 0.5, blockSize.Z / 2 - 0.5)
    local centerPosition = rawCornerPosition + halfSizeOffset
    centerPosition = (activeTransform.center or Vector3.zero)
      + (activeTransform.rotation or CFrame.identity) * (centerPosition - (activeTransform.center or Vector3.zero))
      + (activeTransform.offset or Vector3.zero)
    return centerPosition - halfSizeOffset
  end

  local function ResolveBlockDataEntryToWorldPlacement(blockDataEntry, activeTransform)
    local rawPositionArray = blockDataEntry and (blockDataEntry.p or blockDataEntry.pos)
    if not rawPositionArray then return nil end
    local rawSizeArray = blockDataEntry.s or blockDataEntry.size
    local resolvedBlockSize = rawSizeArray and Vector3.new(table.unpack(rawSizeArray))
      or Vector3.new(DefaultGridUnitSizeInStuds, DefaultGridUnitSizeInStuds, DefaultGridUnitSizeInStuds)
    local rawWorldPosition =
      Vector3.new(rawPositionArray[1], rawPositionArray[2], rawPositionArray[3]) * sessionConfiguration.mult
    local transformedCornerPosition = ApplyOffsetAndRotationTransform(rawWorldPosition, resolvedBlockSize, activeTransform)
    local resolvedColor = (blockDataEntry.c or blockDataEntry.color)
      and Color3.fromRGB(table.unpack(blockDataEntry.c or blockDataEntry.color)) or DefaultBlockColor
    local resolvedMaterialShortName = blockDataEntry.m or blockDataEntry.mat
    local resolvedOriginalMaterialName = blockDataEntry.o or blockDataEntry.origmat
    local resolvedMaterialEnum = ShortNameToMaterialEnumMap[resolvedMaterialShortName] or Enum.Material.SmoothPlastic
    if not ShortNameToMaterialEnumMap[resolvedMaterialShortName] and resolvedOriginalMaterialName then
      pcall(function() resolvedMaterialEnum = Enum.Material[resolvedOriginalMaterialName] or resolvedMaterialEnum end)
    end
    local resolvedCenterPosition = rawSizeArray
      and ConvertCornerPositionToCenterPosition(transformedCornerPosition, resolvedBlockSize)
      or transformedCornerPosition
    return {
      pos = transformedCornerPosition, size = resolvedBlockSize, color = resolvedColor,
      matName = resolvedMaterialShortName, expectMat = resolvedMaterialEnum, center = resolvedCenterPosition,
      anchored = blockDataEntry.a, collide = blockDataEntry.cc,
    }
  end

  local function PlaceAndVerifySingleBlockEntry(blockDataEntry, activeTransform)
    if blockDataEntry.type == "sign" then
      EnsureRequiredToolsAreEquipped(true)
      BuildAndConfigureSignBlock(blockDataEntry, activeTransform)
      return true -- signs don't verify by position
    end
    local resolvedPlacement = ResolveBlockDataEntryToWorldPlacement(blockDataEntry, activeTransform)
    if not resolvedPlacement then return true end
    if IsBlockAtPositionVerified(resolvedPlacement.center, resolvedPlacement.size, resolvedPlacement.color,
      resolvedPlacement.expectMat, resolvedPlacement.anchored, resolvedPlacement.collide) then
      return true
    end
    EnsureRequiredToolsAreEquipped(true)
    CreatePreviewPartInstance(resolvedPlacement.pos, resolvedPlacement.size, resolvedPlacement.color,
      resolvedPlacement.expectMat)
    PlaceSingleBlock(resolvedPlacement.pos, resolvedPlacement.matName, resolvedPlacement.color, nil,
      resolvedPlacement.size, true, blockDataEntry.o or blockDataEntry.origmat,
      blockDataEntry.sp or blockDataEntry.sprayed, resolvedPlacement.anchored, resolvedPlacement.collide)
    task.wait(math.max(0.03, GetCurrentStepDelaySeconds()))
    return IsBlockAtPositionVerified(resolvedPlacement.center, resolvedPlacement.size, resolvedPlacement.color,
      resolvedPlacement.expectMat, resolvedPlacement.anchored, resolvedPlacement.collide)
  end

  local function SortBlockListByStartingPointAdjacency(unsortedBlockDataList)
    local referenceStartingPosition
    local spawnLocationInstance = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("Spawn")
    if spawnLocationInstance then
      if spawnLocationInstance:IsA("Model") then
        local spawnRootPart = spawnLocationInstance:FindFirstChildOfClass("HumanoidRootPart")
        if spawnRootPart then referenceStartingPosition = spawnRootPart.Position end
      elseif spawnLocationInstance:IsA("BasePart") then
        referenceStartingPosition = spawnLocationInstance.Position
      end
    end
    if not referenceStartingPosition then
      for _, otherPlayerInstance in ipairs(PlayersService:GetPlayers()) do
        if otherPlayerInstance.Character then
          local otherPlayerRootPart = otherPlayerInstance.Character:FindFirstChild("HumanoidRootPart")
          if otherPlayerRootPart then referenceStartingPosition = otherPlayerRootPart.Position; break end
        end
      end
    end
    referenceStartingPosition = referenceStartingPosition or Vector3.new(0, 100, 0)

    local blockCount = #unsortedBlockDataList
    if blockCount <= 1 then return unsortedBlockDataList end
    local blockCenterPositionList, blockSizeList = {}, {}
    for blockIndex, blockDataEntry in ipairs(unsortedBlockDataList) do
      local rawPositionArray = blockDataEntry.p or blockDataEntry.pos
      local blockCenterPosition
      if rawPositionArray then
        blockCenterPosition = Vector3.new(rawPositionArray[1], rawPositionArray[2], rawPositionArray[3])
        local rawSizeArray = blockDataEntry.s or blockDataEntry.size
        if rawSizeArray then
          blockCenterPosition = Vector3.new(
            blockCenterPosition.X + rawSizeArray[1] / 2 - 0.5,
            blockCenterPosition.Y + rawSizeArray[2] / 2 - 0.5,
            blockCenterPosition.Z + rawSizeArray[3] / 2 - 0.5)
        end
        blockSizeList[blockIndex] = rawSizeArray and Vector3.new(rawSizeArray[1], rawSizeArray[2], rawSizeArray[3])
          or Vector3.new(DefaultGridUnitSizeInStuds, DefaultGridUnitSizeInStuds, DefaultGridUnitSizeInStuds)
      else
        blockCenterPosition = Vector3.new(math.huge, math.huge, math.huge)
        blockSizeList[blockIndex] = Vector3.new(DefaultGridUnitSizeInStuds, DefaultGridUnitSizeInStuds, DefaultGridUnitSizeInStuds)
      end
      blockCenterPositionList[blockIndex] = blockCenterPosition
    end

    local spatialCellSizeStuds        = DefaultGridUnitSizeInStuds
    local bigBlockDimensionThreshold  = spatialCellSizeStuds * 4  -- anything larger than this in any axis is "big"
    local spatialCellSearchRadius     = 2                          -- fixed, cheap radius for normal-size blocks

    local function ComputeSpatialCellKey(cellPosition)
      local cellX = math.floor(cellPosition.X / spatialCellSizeStuds)
      local cellY = math.floor(cellPosition.Y / spatialCellSizeStuds)
      local cellZ = math.floor(cellPosition.Z / spatialCellSizeStuds)
      return bit32.bxor(bit32.bxor(cellX * 92837111, cellY * 689287499), cellZ * 283923481)
    end

    local spatialCellBucketMap, oversizedBlockIndexList, isBlockOversizedMap = {}, {}, {}
    for blockIndex = 1, blockCount do
      local largestBlockDimension = math.max(
        blockSizeList[blockIndex].X, blockSizeList[blockIndex].Y, blockSizeList[blockIndex].Z)
      if largestBlockDimension > bigBlockDimensionThreshold then
        oversizedBlockIndexList[#oversizedBlockIndexList + 1] = blockIndex
        isBlockOversizedMap[blockIndex] = true
      else
        local cellKey = ComputeSpatialCellKey(blockCenterPositionList[blockIndex])
        if not spatialCellBucketMap[cellKey] then spatialCellBucketMap[cellKey] = {} end
        table.insert(spatialCellBucketMap[cellKey], blockIndex)
      end
    end

    local mathAbs = math.abs
    local function AreBlocksAdjacent(firstBlockIndex, secondBlockIndex)
      local firstCenter, secondCenter = blockCenterPositionList[firstBlockIndex], blockCenterPositionList[secondBlockIndex]
      local firstSize, secondSize = blockSizeList[firstBlockIndex], blockSizeList[secondBlockIndex]
      return mathAbs(firstCenter.X - secondCenter.X) <= (firstSize.X + secondSize.X) * 0.5 + 0.6
         and mathAbs(firstCenter.Y - secondCenter.Y) <= (firstSize.Y + secondSize.Y) * 0.5 + 0.6
         and mathAbs(firstCenter.Z - secondCenter.Z) <= (firstSize.Z + secondSize.Z) * 0.5 + 0.6
    end

    local function CollectAdjacencyCandidates(blockIndex, outputList)
      if isBlockOversizedMap[blockIndex] then
        for otherBlockIndex = 1, blockCount do
          if otherBlockIndex ~= blockIndex then outputList[#outputList + 1] = otherBlockIndex end
        end
        return
      end
      local basePosition = blockCenterPositionList[blockIndex]
      local baseCellX = math.floor(basePosition.X / spatialCellSizeStuds)
      local baseCellY = math.floor(basePosition.Y / spatialCellSizeStuds)
      local baseCellZ = math.floor(basePosition.Z / spatialCellSizeStuds)
      for cellOffsetX = -spatialCellSearchRadius, spatialCellSearchRadius do
        for cellOffsetY = -spatialCellSearchRadius, spatialCellSearchRadius do
          for cellOffsetZ = -spatialCellSearchRadius, spatialCellSearchRadius do
            local neighboringBucket = spatialCellBucketMap[bit32.bxor(bit32.bxor(
              (baseCellX + cellOffsetX) * 92837111, (baseCellY + cellOffsetY) * 689287499),
              (baseCellZ + cellOffsetZ) * 283923481)]
            if neighboringBucket then
              for _, candidateBlockIndex in ipairs(neighboringBucket) do
                if candidateBlockIndex ~= blockIndex then outputList[#outputList + 1] = candidateBlockIndex end
              end
            end
          end
        end
      end
      for _, oversizedBlockIndex in ipairs(oversizedBlockIndexList) do
        if oversizedBlockIndex ~= blockIndex then outputList[#outputList + 1] = oversizedBlockIndex end
      end
    end

    local visitedBlockIndexMap = {}
    local finalBlockOrderIndexList = {}
    local candidateScratchList = {}
    local distanceToReferenceList = {}
    for blockIndex = 1, blockCount do
      distanceToReferenceList[blockIndex] = (blockCenterPositionList[blockIndex] - referenceStartingPosition).Magnitude
    end

    local blockIndicesSortedByDistance = {}
    for blockIndex = 1, blockCount do blockIndicesSortedByDistance[blockIndex] = blockIndex end
    table.sort(blockIndicesSortedByDistance,
      function(a, b) return distanceToReferenceList[a] < distanceToReferenceList[b] end)
    local nearestUnvisitedSearchCursor = 1

    local function FindNearestUnvisitedBlockIndex()
      while nearestUnvisitedSearchCursor <= blockCount
        and visitedBlockIndexMap[blockIndicesSortedByDistance[nearestUnvisitedSearchCursor]] do
        nearestUnvisitedSearchCursor = nearestUnvisitedSearchCursor + 1
      end
      if nearestUnvisitedSearchCursor > blockCount then return nil end
      return blockIndicesSortedByDistance[nearestUnvisitedSearchCursor]
    end

    while #finalBlockOrderIndexList < blockCount do
      local newRegionSeedBlockIndex = FindNearestUnvisitedBlockIndex()
      if not newRegionSeedBlockIndex then break end

      local breadthFirstQueue = { newRegionSeedBlockIndex }
      visitedBlockIndexMap[newRegionSeedBlockIndex] = true
      local queueReadCursor = 1
      while queueReadCursor <= #breadthFirstQueue do
        local currentBlockIndex = breadthFirstQueue[queueReadCursor]
        queueReadCursor = queueReadCursor + 1
        finalBlockOrderIndexList[#finalBlockOrderIndexList + 1] = currentBlockIndex

        for scratchIndex = #candidateScratchList, 1, -1 do candidateScratchList[scratchIndex] = nil end
        CollectAdjacencyCandidates(currentBlockIndex, candidateScratchList)
        table.sort(candidateScratchList,
          function(a, b) return distanceToReferenceList[a] < distanceToReferenceList[b] end)
        for _, candidateBlockIndex in ipairs(candidateScratchList) do
          if not visitedBlockIndexMap[candidateBlockIndex] and AreBlocksAdjacent(currentBlockIndex, candidateBlockIndex) then
            visitedBlockIndexMap[candidateBlockIndex] = true
            breadthFirstQueue[#breadthFirstQueue + 1] = candidateBlockIndex
          end
        end
      end
    end

    local sortedBlockDataList = {}
    for _, blockIndex in ipairs(finalBlockOrderIndexList) do
      sortedBlockDataList[#sortedBlockDataList + 1] = unsortedBlockDataList[blockIndex]
    end
    DebugLog("SortBlockListByStartingPointAdjacency: sorted", #sortedBlockDataList, "blocks starting near",
      tostring(referenceStartingPosition))
    return sortedBlockDataList
  end

  local function RunFullBuildLoop(blockDataList, activeTransform)
    if type(blockDataList) ~= "table" or #blockDataList == 0 then
      LogMessage("Build data empty.")
      return false
    end
    if not EnsureRequiredToolsAreEquipped(true) then return false end

    currentBuildRunGenerationNumber = currentBuildRunGenerationNumber + 1
    local thisBuildRunGenerationNumber = currentBuildRunGenerationNumber
    lastKnownBuildStateSnapshot = { blocks = blockDataList, transform = activeTransform }

    isBuildSessionStopped = false
    isCurrentBlockSkipRequested = false
    local sortedBlockDataList = SortBlockListByStartingPointAdjacency(blockDataList)
    totalBlockCountForCurrentBuild    = #sortedBlockDataList
    verifiedBlockCountForCurrentBuild = 0
    buildStartTimestamp = tick()
    UpdateSessionStatistics()

    local verifiedBlockIndexMap = {}
    local verifiedBlockCount = 0

    local function HasBuildBeenAborted()
      if getgenv()[GENERATION_COUNTER_GLOBAL_KEY] ~= currentModuleGenerationNumber then isBuildSessionStopped = true end
      return isBuildSessionStopped or currentBuildRunGenerationNumber ~= thisBuildRunGenerationNumber
    end
    local function MarkBlockIndexVerified(blockIndex)
      if not verifiedBlockIndexMap[blockIndex] then
        verifiedBlockIndexMap[blockIndex] = true
        verifiedBlockCount = verifiedBlockCount + 1
        verifiedBlockCountForCurrentBuild = verifiedBlockCount
        UpdateSessionStatistics()
      end
    end

    DebugLog("RunFullBuildLoop: starting first pass over", #sortedBlockDataList, "blocks")
    for blockIndex, blockDataEntry in ipairs(sortedBlockDataList) do
      if HasBuildBeenAborted() then break end
      if blockIndex % 25 == 0 then EnsureRequiredToolsAreEquipped(false) end
      if PlaceAndVerifySingleBlockEntry(blockDataEntry, activeTransform) then MarkBlockIndexVerified(blockIndex) end
      task.wait(math.max(0.03, GetCurrentStepDelaySeconds()))
    end

    local repairPassNumber = 0
    while not HasBuildBeenAborted() and verifiedBlockCount < #sortedBlockDataList and repairPassNumber < 4 do
      repairPassNumber = repairPassNumber + 1
      local repairedBlockCountThisPass = 0
      if sessionConfiguration.wbs then task.wait(1) end
      DebugLog("RunFullBuildLoop: starting repair pass", repairPassNumber)
      for blockIndex, blockDataEntry in ipairs(sortedBlockDataList) do
        if HasBuildBeenAborted() then break end
        if not verifiedBlockIndexMap[blockIndex] then
          if PlaceAndVerifySingleBlockEntry(blockDataEntry, activeTransform) then
            MarkBlockIndexVerified(blockIndex)
            repairedBlockCountThisPass = repairedBlockCountThisPass + 1
          end
          task.wait(math.max(0.03, GetCurrentStepDelaySeconds()))
        end
      end
      if repairedBlockCountThisPass == 0 then break end
    end

    local wasBuildAborted = HasBuildBeenAborted()
    local missingBlockCount = #sortedBlockDataList - verifiedBlockCount
    if currentBuildRunGenerationNumber == thisBuildRunGenerationNumber then
      isBuildSessionStopped = false
      isCurrentBlockSkipRequested = false
    end
    totalBlockCountForCurrentBuild = 0
    verifiedBlockCountForCurrentBuild = 0
    UpdateSessionStatistics()

    if wasBuildAborted then
      LogMessage("Build stopped.")
    elseif missingBlockCount > 0 then
      LogMessage(string.format("Build finished: %d/%d verified (%d need manual attention).",
        verifiedBlockCount, #sortedBlockDataList, missingBlockCount))
    else
      LogMessage(string.format("Build complete: %d/%d blocks.", verifiedBlockCount, #sortedBlockDataList))
    end
    return not wasBuildAborted
  end

  local function LoadBlockDataFromSource()
    if isDataSourcePreDecoded then
      if type(dataSourcePathOrTable) == "table" then return dataSourcePathOrTable, nil end
      return nil, "isData=true but filepath is not a table"
    end
    local rawLoadedString
    if type(customFetchFunction) == "function" then
      rawLoadedString = customFetchFunction(dataSourcePathOrTable)
    elseif type(dataSourcePathOrTable) == "string" and dataSourcePathOrTable:match("^https?://") then
      local wasHttpGetSuccessful, httpGetResult = pcall(function() return game:HttpGet(dataSourcePathOrTable) end)
      if wasHttpGetSuccessful then rawLoadedString = httpGetResult end
    elseif type(dataSourcePathOrTable) == "string" then
      local wasReadFileSuccessful, readFileResult = pcall(function() return readfile(dataSourcePathOrTable) end)
      if wasReadFileSuccessful and readFileResult and readFileResult ~= "" then
        rawLoadedString = readFileResult
      else
        rawLoadedString = dataSourcePathOrTable
      end
    end
    if not rawLoadedString or rawLoadedString == "" then
      return nil, "Could not load: " .. tostring(dataSourcePathOrTable)
    end
    if type(rawLoadedString) ~= "string" then
      return nil, "Expected string, got " .. type(rawLoadedString)
    end
    if rawLoadedString:sub(1, 1) == "{" then
      local wasJsonDecodeSuccessful, jsonDecodeResult =
        pcall(function() return HttpService:JSONDecode(rawLoadedString) end)
      if not wasJsonDecodeSuccessful then
        return nil, "JSON decode failed: " .. tostring(jsonDecodeResult)
      end
      if type(jsonDecodeResult) ~= "table" then return nil, "Decoded JSON is not a table" end
      return jsonDecodeResult, nil
    end
    local wasDecompressSuccessful, decompressResult = pcall(DecompressBufferToBlockDataTable, rawLoadedString)
    if not wasDecompressSuccessful then
      return nil, "Decompress failed: " .. tostring(decompressResult)
    end
    if type(decompressResult) ~= "table" then return nil, "Decompressed data is not a table" end
    return decompressResult, nil
  end

  local function BuildTransformFromSessionConfig()
    if sessionConfiguration.offset == Vector3.zero and sessionConfiguration.mult == 1 then return nil end
    return { enabled = true, center = Vector3.zero, rotation = CFrame.identity, offset = sessionConfiguration.offset }
  end

  local REMOTE_WORKER_SCRIPT_TEMPLATE = [[
--// ts script was generated idk
local hs  = game:GetService("HttpService")
local lib = loadstring(game:HttpGet(%s, true))()
local d   = hs:JSONDecode(%s)
local s   = hs:JSONDecode(%s)
s.offset  = Vector3.new(s.ox or 0, s.oy or 0, s.oz or 0)
s.ox, s.oy, s.oz = nil, nil, nil
lib.build(d, s, nil, true).start()
]]

  local function BuildRemoteWorkerScriptSource(chunkJsonString, settingsJsonString)
    return string.format(REMOTE_WORKER_SCRIPT_TEMPLATE,
      string.format("%q", "https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/autobuildv2.lua"),
      string.format("%q", chunkJsonString),
      string.format("%q", settingsJsonString)
    )
  end

  local function SerializeSessionSettingsToJson()
    return HttpService:JSONEncode({
      mult        = sessionConfiguration.mult,
      historymax  = sessionConfiguration.historymax,
      resizewait  = sessionConfiguration.resizewait,
      wbs         = sessionConfiguration.wbs,
      maxtry      = sessionConfiguration.maxtry,
      maxtrydelay = sessionConfiguration.maxtrydelay,
      ox          = sessionConfiguration.offset.X,
      oy          = sessionConfiguration.offset.Y,
      oz          = sessionConfiguration.offset.Z,
    })
  end

  local autoBuildSessionHandle = {}
  autoBuildSessionHandle.stats = sessionStatisticsTable

  function autoBuildSessionHandle.settings() return sessionConfiguration, DefaultSessionSettings end
  function autoBuildSessionHandle.stop()
    isBuildSessionStopped = true
    isCurrentBlockSkipRequested = true
    currentTeleportTargetPosition = nil
  end
  function autoBuildSessionHandle.skip() isCurrentBlockSkipRequested = true end
  function autoBuildSessionHandle.wbs(newWbsEnabledState) sessionConfiguration.wbs = newWbsEnabledState end
  function autoBuildSessionHandle.resizewait(newResizeWaitSeconds)
    sessionConfiguration.resizewait = newResizeWaitSeconds
  end
  function autoBuildSessionHandle.try(newMaxTryDelaySeconds, newMaxTryCount)
    if newMaxTryDelaySeconds then sessionConfiguration.maxtrydelay = newMaxTryDelaySeconds end
    if newMaxTryCount then sessionConfiguration.maxtry = newMaxTryCount end
  end

  function autoBuildSessionHandle.start()
    isBuildSessionStopped = false
    isCurrentBlockSkipRequested = false
    local loadedBlockDataList, loadErrorMessage = LoadBlockDataFromSource()
    if not loadedBlockDataList then
      LogMessage("Load failed: " .. tostring(loadErrorMessage))
      return false
    end

    if not asynchronousRemoteWorkerClientList then
      return RunFullBuildLoop(loadedBlockDataList, BuildTransformFromSessionConfig())
    end
    if #asynchronousRemoteWorkerClientList <= 0 then
      LogMessage("async: no remote clients, running locally")
      return RunFullBuildLoop(loadedBlockDataList, BuildTransformFromSessionConfig())
    end

    local allSortedBlocksList = SortBlockListByStartingPointAdjacency(loadedBlockDataList)
    local totalBlockCount     = #allSortedBlocksList
    local totalWorkerCount    = #asynchronousRemoteWorkerClientList + 1
    local baseChunkSize       = math.floor(totalBlockCount / totalWorkerCount)
    local extraBlockCount     = totalBlockCount % totalWorkerCount
    local serializedSettingsJson = SerializeSessionSettingsToJson()
    local chunkStartCursor    = 1

    for workerIndex = 1, totalWorkerCount do
      local thisWorkerChunkSize = baseChunkSize + (workerIndex <= extraBlockCount and 1 or 0)
      if thisWorkerChunkSize == 0 then break end
      local workerBlockChunkList = {}
      for chunkSourceIndex = chunkStartCursor, chunkStartCursor + thisWorkerChunkSize - 1 do
        workerBlockChunkList[#workerBlockChunkList + 1] = allSortedBlocksList[chunkSourceIndex]
      end
      chunkStartCursor = chunkStartCursor + thisWorkerChunkSize

      if workerIndex < totalWorkerCount then
        local workerChunkJson = HttpService:JSONEncode(workerBlockChunkList)
        asynchronousRemoteWorkerClientList[workerIndex](
          BuildRemoteWorkerScriptSource(workerChunkJson, serializedSettingsJson))
        LogMessage(string.format("async: sent %d blocks to remote %d/%d",
          thisWorkerChunkSize, workerIndex, #asynchronousRemoteWorkerClientList))
      else
        LogMessage(string.format("async: running %d blocks locally (worker %d/%d)",
          thisWorkerChunkSize, workerIndex, totalWorkerCount))
        return RunFullBuildLoop(workerBlockChunkList, BuildTransformFromSessionConfig())
      end
    end
    return true
  end

  return autoBuildSessionHandle
end

local AutoBuildLibrary = {}

function AutoBuildLibrary.save(outputFilePath, ownerPlayerList)
  return SaveOwnedBlocksToFile(outputFilePath, ownerPlayerList)
end
function AutoBuildLibrary.build(dataSourcePathOrTable, settingsTable, customFetchFunction, isDataSourcePreDecoded,
  customFetchToolsFunction)
  return CreateAutoBuildSession(dataSourcePathOrTable, settingsTable, customFetchFunction, isDataSourcePreDecoded,
    customFetchToolsFunction)
end

getgenv()["autobuildv2@hyperion"] = AutoBuildLibrary

return AutoBuildLibrary