-- autobuildv2.lua

-- ── Services ─────────────────────────────────────────────────────────────────
local PlayersService      = game:GetService("Players")
local RunService          = game:GetService("RunService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local HttpService         = game:GetService("HttpService")
local CoreGui             = game:GetService("CoreGui")

local LocalPlayer = PlayersService.LocalPlayer

local EncodingService = game:GetService("EncodingService")

local function Compress(Data)
  local Json = HttpService:JSONEncode(Data)
  local JsonBuffer = buffer.fromstring(Json)
  local CompressedBuffer = EncodingService:CompressBuffer(
    JsonBuffer,
    Enum.CompressionAlgorithm.Zstd,
    22
  )
  return buffer.tostring(CompressedBuffer)
end

local function Decompress(CompressedData)
  local CompressedBuffer = buffer.fromstring(CompressedData)
  local DecompressedBuffer = EncodingService:DecompressBuffer(
    CompressedBuffer,
    Enum.CompressionAlgorithm.Zstd
  )
  local Json = buffer.tostring(DecompressedBuffer)
  return HttpService:JSONDecode(Json)
end

local IsOldGameVariant     = workspace:FindFirstChild("Cubes") ~= nil
local BlockContainerFolder = IsOldGameVariant
    and workspace:WaitForChild("Cubes")
    or  workspace:WaitForChild("Bricks")
local BlockInstanceName    = IsOldGameVariant and "Cube" or "Brick"

local GridUnitSize      = 4
local DefaultBlockColor = Color3.fromRGB(192, 192, 192)

local NormalIdToAxisMap = {}
NormalIdToAxisMap[Enum.NormalId.Right]  = { Vector3.new(1,  0,  0), "X" }
NormalIdToAxisMap[Enum.NormalId.Top]    = { Vector3.new(0,  1,  0), "Y" }
NormalIdToAxisMap[Enum.NormalId.Back]   = { Vector3.new(0,  0,  1), "Z" }
NormalIdToAxisMap[Enum.NormalId.Left]   = { Vector3.new(-1, 0,  0), "X" }
NormalIdToAxisMap[Enum.NormalId.Bottom] = { Vector3.new(0, -1,  0), "Y" }
NormalIdToAxisMap[Enum.NormalId.Front]  = { Vector3.new(0,  0, -1), "Z" }

local MaterialEnumToNameMap = {}
MaterialEnumToNameMap[Enum.Material.SmoothPlastic] = "smooth"
MaterialEnumToNameMap[Enum.Material.Plastic]       = "plastic"
MaterialEnumToNameMap[Enum.Material.CeramicTiles]  = "tiles"
MaterialEnumToNameMap[Enum.Material.Brick]         = "bricks"
MaterialEnumToNameMap[Enum.Material.WoodPlanks]    = "planks"
MaterialEnumToNameMap[Enum.Material.Ice]           = "ice"
MaterialEnumToNameMap[Enum.Material.Grass]         = "grass"
MaterialEnumToNameMap[Enum.Material.Sand]          = "sand"
MaterialEnumToNameMap[Enum.Material.Snow]          = "snow"
MaterialEnumToNameMap[Enum.Material.Glass]         = "glass"
MaterialEnumToNameMap[Enum.Material.Wood]          = "wood"
MaterialEnumToNameMap[Enum.Material.Slate]         = "stone"
MaterialEnumToNameMap[Enum.Material.Pebble]        = "pebble"
MaterialEnumToNameMap[Enum.Material.Marble]        = "marble"
MaterialEnumToNameMap[Enum.Material.Granite]       = "granite"
MaterialEnumToNameMap[Enum.Material.DiamondPlate]  = "steel"
MaterialEnumToNameMap[Enum.Material.Metal]         = "metal"
MaterialEnumToNameMap[Enum.Material.Asphalt]       = "asphalt"
MaterialEnumToNameMap[Enum.Material.Concrete]      = "concrete"
MaterialEnumToNameMap[Enum.Material.Pavement]      = "pavement"
MaterialEnumToNameMap[Enum.Material.Neon]          = "neon"

local MaterialNameToEnumMap = {}
for MaterialEnum, MaterialName in pairs(MaterialEnumToNameMap) do MaterialNameToEnumMap[MaterialName] = MaterialEnum end

local buildDelay                   = 0.235
local autoPingOptimizeEnabled      = true
local currentPingMilliseconds      = 0
local pingExponentialMovingAverage = 0
local pingHasBeenSampled           = false

local GENKEY  = "HyperionAutobuildGen"
local CONNKEY = "HyperionAutoBuildCon"

if getgenv()[CONNKEY] then
  pcall(function() getgenv()[CONNKEY]:Disconnect() end)
  getgenv()[CONNKEY] = nil
end

local moduleGen = (getgenv()[GENKEY] or 0) + 1
getgenv()[GENKEY] = moduleGen

task.spawn(function()
  while getgenv()[GENKEY] == moduleGen do
    pcall(function() currentPingMilliseconds = LocalPlayer:GetNetworkPing() * 1000 end)
    if not pingHasBeenSampled then
      pingExponentialMovingAverage = currentPingMilliseconds
      pingHasBeenSampled = true
    else
      pingExponentialMovingAverage = pingExponentialMovingAverage * 0.7 + currentPingMilliseconds * 0.3
    end
    if autoPingOptimizeEnabled then
      local CurrentPing = pingExponentialMovingAverage
      if     CurrentPing > 400 then buildDelay = 0.50
      elseif CurrentPing > 280 then buildDelay = 0.35
      elseif CurrentPing > 180 then buildDelay = 0.22
      elseif CurrentPing > 100 then buildDelay = 0.12
      else                          buildDelay = math.max(CurrentPing / 1000 + 0.007, 0.051)
      end
    end
    task.wait(1)
  end
end)

-- ── JSON helpers ──────────────────────────────────────────────────────────────
local function SanitizeJsonString(RawJsonString)
  if not RawJsonString or RawJsonString == "" then return RawJsonString end
  RawJsonString = RawJsonString:gsub("^\xEF\xBB\xBF", "")
  RawJsonString = RawJsonString:gsub("\xC2\xA0", " ")
  RawJsonString = RawJsonString:gsub("\xE2\x80\x8B", ""):gsub("\xE2\x80\x8C", ""):gsub("\xE2\x80\x8D", "")
  RawJsonString = RawJsonString:gsub("\xE2\x80[\x9C\x9D]", '"')
  RawJsonString = RawJsonString:gsub("\xE2\x80[\x98\x99]", "'")
  RawJsonString = RawJsonString:gsub("\r\n", " "):gsub("\r", " "):gsub("\n", " ")
  RawJsonString = RawJsonString:match("^%s*(.-)%s*$")
  if RawJsonString == "" then return RawJsonString end
  repeat
    local SanitizedOnce = RawJsonString:gsub(",%s*([%]%}])", "%1")
    if SanitizedOnce == RawJsonString then break end
    RawJsonString = SanitizedOnce
  until false
  if RawJsonString:sub(1,1) == "{" and RawJsonString:sub(-1) == "}" then RawJsonString = "[" .. RawJsonString .. "]" end
  return RawJsonString
end

-- ── DEFAULTS ──────────────────────────────────────────────────────────────────
local DEFAULTS = {
  offset      = Vector3.zero,
  mult        = 1,
  historymax  = 400,
  resizewait  = 0.2,
  wbs         = false,
  maxtry      = 150,
  maxtrydelay = nil,
}

-- ── lib.save ──────────────────────────────────────────────────────────────────
local function SaveBlocksToFile(FilePath, PlayerList)
  local AcceptedPlayerNameSet = {}
  for _, PlayerInstance in ipairs(PlayerList) do
    if typeof(PlayerInstance) == "Instance" and PlayerInstance:IsA("Player") then
      AcceptedPlayerNameSet[PlayerInstance.Name] = true
    end
  end

  local SerializedBlockList = {}
  for _, BlockPart in ipairs(BlockContainerFolder:GetDescendants()) do
    if not BlockPart:IsA("BasePart") then continue end
    local OwnerFolder = BlockPart.Parent
    if OwnerFolder and AcceptedPlayerNameSet[OwnerFolder.Name] then
      local BlockColor    = BlockPart.Color
      local BlockSize     = BlockPart.Size
      local BlockPosition = BlockPart.Position - BlockSize / 2 + Vector3.new(0.5, 0.5, 0.5)
      local MaterialName  = MaterialEnumToNameMap[BlockPart.Material] or "smooth"
      table.insert(SerializedBlockList, {
        p  = { BlockPosition.X, BlockPosition.Y, BlockPosition.Z },
        s  = { BlockSize.X, BlockSize.Y, BlockSize.Z },
        c  = { math.round(BlockColor.R * 255), math.round(BlockColor.G * 255), math.round(BlockColor.B * 255) },
        m  = MaterialName,
        a  = BlockPart.Anchored,
        cc = BlockPart.CanCollide,
      })
    end
  end

  writefile(FilePath, Compress(SerializedBlockList))
  return #SerializedBlockList
end

-- ── lib.build ─────────────────────────────────────────────────────────────────
local function CreateBuildSession(FilePath, SessionSettingsTable, FetchToolsFunction, IsPreDecodedData)
  SessionSettingsTable = SessionSettingsTable or {}

  local SessionSettings = {
    offset      = SessionSettingsTable.offset      or DEFAULTS.offset,
    mult        = SessionSettingsTable.mult        or DEFAULTS.mult,
    historymax  = SessionSettingsTable.historymax  or DEFAULTS.historymax,
    resizewait  = SessionSettingsTable.resizewait  or DEFAULTS.resizewait,
    wbs         = (SessionSettingsTable.wbs ~= nil) and SessionSettingsTable.wbs or DEFAULTS.wbs,
    maxtry      = SessionSettingsTable.maxtry      or DEFAULTS.maxtry,
    maxtrydelay = SessionSettingsTable.maxtrydelay or DEFAULTS.maxtrydelay,
  }

  -- async: array of functions, each fires a script to one remote client
  -- e.g. { client1.exec, client2.exec }
  local AsyncConfiguration = (type(SessionSettingsTable.async) == "table") and SessionSettingsTable.async or nil

  local TeleportPlayerToBlock     = true
  local PaintEvenWhenDefaultColor = false

  local IsBuildStopped         = false
  local ShouldSkipCurrentBlock = false
  local BlockHasBeenBuilt      = false
  local MostRecentlyBuiltBlock  = nil
  local PreviousPreviewPart     = nil
  local BuiltBlockHistoryRingBuffer  = {}
  local BuiltBlockHistoryWriteIndex  = 0

  local CurrentRunGenerationId         = 0
  local LastBuildState                 = nil
  local LastBuildToolMissingNotifyTime = 0
  local BuildToolNamesList             = { "Build", "Paint", "Shape", "Delete" }

  local PositionVerificationTolerance = 0.75
  local SizeVerificationTolerance     = 0.75
  local ColorVerificationTolerance    = 0.02

  local TotalBlocksInCurrentBuild = 0
  local NumberOfBlocksVerified    = 0
  local BuildStartTimestamp       = 0

  -- ── Stats ─────────────────────────────────────────────────────────────────
  local Stats = { total = 0, done = 0, elapsed = 0, eta = nil, ping = 0 }

  local function UpdateStats()
    Stats.total = TotalBlocksInCurrentBuild
    Stats.done  = NumberOfBlocksVerified
    Stats.ping  = math.floor(pingExponentialMovingAverage)
    if BuildStartTimestamp > 0 then
      Stats.elapsed = tick() - BuildStartTimestamp
      if Stats.done > 2 and Stats.total > 0 then
        Stats.eta = Stats.elapsed / Stats.done * (Stats.total - Stats.done)
      end
    end
  end

  -- ── Highlight ─────────────────────────────────────────────────────────────
  local BlockHighlight = Instance.new("Highlight")
  BlockHighlight.Parent              = CoreGui
  BlockHighlight.FillColor           = Color3.fromRGB(0, 200, 255)
  BlockHighlight.FillTransparency    = 0.5
  BlockHighlight.OutlineColor        = Color3.fromRGB(0, 200, 255)
  BlockHighlight.OutlineTransparency = 0

  -- ── Block listener ────────────────────────────────────────────────────────
  local BlockAddedListenerConnection
  local function OnNewBlockAddedToContainer(NewChildInstance)
    if not NewChildInstance:IsA("BasePart") then return end
    MostRecentlyBuiltBlock = NewChildInstance
    BuiltBlockHistoryWriteIndex = BuiltBlockHistoryWriteIndex + 1
    if BuiltBlockHistoryWriteIndex > SessionSettings.historymax then BuiltBlockHistoryWriteIndex = 1 end
    BuiltBlockHistoryRingBuffer[BuiltBlockHistoryWriteIndex] = NewChildInstance
    BlockHasBeenBuilt = true
  end

  if BlockContainerFolder:FindFirstChild(LocalPlayer.Name) then
    BlockAddedListenerConnection = BlockContainerFolder[LocalPlayer.Name].ChildAdded:Connect(OnNewBlockAddedToContainer)
  else
    BlockAddedListenerConnection = BlockContainerFolder.DescendantAdded:Connect(OnNewBlockAddedToContainer)
  end
  getgenv()[CONNKEY] = BlockAddedListenerConnection

  -- ── Helpers ───────────────────────────────────────────────────────────────
  local function NotifyUser(MessageText)
    warn("[AutoBuild] " .. tostring(MessageText))
  end

  local function SnapPositionToGrid(WorldPosition, GridMultiple)
    GridMultiple = GridMultiple or GridUnitSize
    return Vector3.new(
      math.round((WorldPosition.X - 2) / GridMultiple) * GridMultiple + 2,
      math.round((WorldPosition.Y - 2) / GridMultiple) * GridMultiple + 2,
      math.round((WorldPosition.Z - 2) / GridMultiple) * GridMultiple + 2
    )
  end
  local SnapToGrid = SnapPositionToGrid

  local function GetCurrentBuildDelay() return SessionSettings.maxtrydelay or buildDelay end

  -- ── Tool management ───────────────────────────────────────────────────────
  local function EquipToolFromBackpackByName(ToolName)
    local PlayerCharacter = LocalPlayer.Character
    if not PlayerCharacter then return nil end
    local AlreadyEquipped = PlayerCharacter:FindFirstChild(ToolName)
    if AlreadyEquipped and AlreadyEquipped:IsA("Tool") then return AlreadyEquipped end
    local PlayerBackpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local BackpackTool   = PlayerBackpack and PlayerBackpack:FindFirstChild(ToolName)
    if BackpackTool and BackpackTool:IsA("Tool") then
      pcall(function()
        if BackpackTool:FindFirstChild("Script") and BackpackTool.Script:IsA("LocalScript") then
          BackpackTool.Script.Disabled = false
        end
      end)
      pcall(function() BackpackTool.Parent = PlayerCharacter end)
      return PlayerCharacter:FindFirstChild(ToolName)
    end
    return nil
  end

  local function GrabToolFromWorkspaceIntoBackpack(ToolName)
    local PlayerBackpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not PlayerBackpack or PlayerBackpack:FindFirstChild(ToolName) then return end
    local WorkspaceTool = workspace:FindFirstChild(ToolName)
    if WorkspaceTool and WorkspaceTool:IsA("Tool") then
      pcall(function() WorkspaceTool:Clone().Parent = PlayerBackpack end)
    end
  end

  local function EnsureAllBuildToolsAreEquipped(ShouldNotifyIfMissing)
    local HasBuildTool = false
    for _, ToolName in ipairs(BuildToolNamesList) do
      if not EquipToolFromBackpackByName(ToolName) then GrabToolFromWorkspaceIntoBackpack(ToolName); EquipToolFromBackpackByName(ToolName) end
      if ToolName == "Build" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Build") then
        HasBuildTool = true
      end
    end
    if not HasBuildTool and ShouldNotifyIfMissing then
      local CurrentTime = os.clock()
      if CurrentTime - LastBuildToolMissingNotifyTime > 6 then
        LastBuildToolMissingNotifyTime = CurrentTime
        NotifyUser("Build tool missing. Grant yourself bkit, then retry.")
      end
    end
    return HasBuildTool
  end

  -- ── Verification helpers ──────────────────────────────────────────────────
  local function AreVectorsWithinTolerance(VectorA, VectorB, Tolerance)
    return math.abs(VectorA.X-VectorB.X) <= Tolerance
        and math.abs(VectorA.Y-VectorB.Y) <= Tolerance
        and math.abs(VectorA.Z-VectorB.Z) <= Tolerance
  end
  local function AreColorsWithinTolerance(ColorA, ColorB)
    return math.abs(ColorA.R-ColorB.R) <= ColorVerificationTolerance
        and math.abs(ColorA.G-ColorB.G) <= ColorVerificationTolerance
        and math.abs(ColorA.B-ColorB.B) <= ColorVerificationTolerance
  end
  local function ComputeBlockCenterPosition(RawCornerPosition, BlockSize)
    if not BlockSize then return RawCornerPosition end
    return Vector3.new(
      RawCornerPosition.X + BlockSize.X/2 - 0.5,
      RawCornerPosition.Y + BlockSize.Y/2 - 0.5,
      RawCornerPosition.Z + BlockSize.Z/2 - 0.5
    )
  end
  local function DoesPartMatchExpectedPositionAndSize(CandidatePart, ExpectedCenter, ExpectedSize)
    return CandidatePart and CandidatePart:IsA("BasePart")
        and AreVectorsWithinTolerance(CandidatePart.Position, ExpectedCenter, PositionVerificationTolerance)
        and AreVectorsWithinTolerance(CandidatePart.Size,     ExpectedSize,   SizeVerificationTolerance)
  end

  local function FindExistingBlockAtPosition(CenterPosition, ExpectedBlockSize)
    if not BlockContainerFolder or not BlockContainerFolder.Parent then return nil end
    local SearchSize = ExpectedBlockSize or Vector3.new(GridUnitSize, GridUnitSize, GridUnitSize)
    local OverlapSucceeded, OverlapHits = pcall(function()
      local OverlapParameters = OverlapParams.new()
      OverlapParameters.FilterType = Enum.RaycastFilterType.Include
      OverlapParameters.FilterDescendantsInstances = { BlockContainerFolder }
      OverlapParameters.MaxParts = 30
      return workspace:GetPartBoundsInBox(CFrame.new(CenterPosition), Vector3.new(1,1,1), OverlapParameters)
    end)
    if OverlapSucceeded and OverlapHits then
      for _, CandidatePart in ipairs(OverlapHits) do
        if DoesPartMatchExpectedPositionAndSize(CandidatePart, CenterPosition, SearchSize) then return CandidatePart end
      end
    end
    for _, CandidatePart in ipairs(BlockContainerFolder:GetDescendants()) do
      if DoesPartMatchExpectedPositionAndSize(CandidatePart, CenterPosition, SearchSize) then return CandidatePart end
    end
    return nil
  end

  local function IsBlockVerifiedAtPosition(CenterPosition, ExpectedSize, ExpectedColor, ExpectedMaterial, ExpectedAnchored, ExpectedCanCollide)
    local FoundPart = FindExistingBlockAtPosition(CenterPosition, ExpectedSize)
    if not FoundPart then return false end
    if ExpectedColor    and not AreColorsWithinTolerance(FoundPart.Color, ExpectedColor) then return false end
    if ExpectedMaterial and FoundPart.Material ~= ExpectedMaterial                       then return false end
    if ExpectedAnchored   ~= nil and FoundPart.Anchored   ~= ExpectedAnchored            then return false end
    if ExpectedCanCollide ~= nil and FoundPart.CanCollide ~= ExpectedCanCollide           then return false end
    return true
  end

  -- ── Preview part ──────────────────────────────────────────────────────────
  local function CreatePreviewReplacementPart(PlacementPosition, BlockSize, BlockColor, BlockMaterial, Transparency, IsAnchored, CanCollide, SpraysData)
    if typeof(PlacementPosition) == "CFrame" then PlacementPosition = PlacementPosition.Position end
    local PreviewPart = Instance.new("Part")
    PreviousPreviewPart      = PreviewPart
    PreviewPart.Anchored     = IsAnchored ~= false
    PreviewPart.CanCollide   = CanCollide or false
    PreviewPart.CastShadow   = false
    PreviewPart.CanQuery     = false
    PreviewPart.Color        = BlockColor
    PreviewPart.Transparency = Transparency or 0.5
    PreviewPart.Material     = BlockMaterial or Enum.Material.SmoothPlastic
    if BlockSize then
      PlacementPosition = Vector3.new(
        (PlacementPosition.X + BlockSize.X/2) - 0.5,
        (PlacementPosition.Y + BlockSize.Y/2) - 0.5,
        (PlacementPosition.Z + BlockSize.Z/2) - 0.5
      )
    end
    PreviewPart.Size   = BlockSize or Vector3.new(GridUnitSize, GridUnitSize, GridUnitSize)
    PreviewPart.CFrame = CFrame.new(PlacementPosition)
    if SpraysData then
      for _, SprayEntry in pairs(SpraysData) do
        local FaceNormalId = Enum.NormalId[SprayEntry[1]]
        local SprayPayload = SprayEntry[3] or ""
        local SpraySurfaceGui = Instance.new("SurfaceGui")
        SpraySurfaceGui.Face          = FaceNormalId
        SpraySurfaceGui.SizingMode    = Enum.SurfaceGuiSizingMode.PixelsPerStud
        SpraySurfaceGui.PixelsPerStud = 50
        local _, HashCount = string.gsub(SprayPayload, "#", "l")
        if HashCount == #SprayPayload then
          local SprayImageLabel = Instance.new("ImageLabel", SpraySurfaceGui)
          SprayImageLabel.Image = SprayEntry[2]; SprayImageLabel.BackgroundTransparency = 1
          SprayImageLabel.Size  = UDim2.new(1,0,1,0)
        else
          local SprayTextLabel = Instance.new("TextLabel", SpraySurfaceGui)
          SprayTextLabel.Text = SprayPayload; SprayTextLabel.BackgroundTransparency = 1
          SprayTextLabel.TextScaled = true; SprayTextLabel.TextColor3 = Color3.new(1,1,1)
          SprayTextLabel.Font = Enum.Font.FredokaOne; SprayTextLabel.Size = UDim2.new(1,0,1,0)
        end
        SpraySurfaceGui.Parent = PreviewPart
      end
    end
    PreviewPart.Parent = workspace
    return PreviewPart
  end

  -- ── Main block placer ─────────────────────────────────────────────────────
  local function PlaceAndConfigureBlock(PlacementPosition, TextureMaterialName, DesiredColor, BlockSizeMode, BlockSizeVector, IsPremadeBlock, OriginalMaterialName, SpraysData, ShouldBeAnchored, ShouldHaveCollision)
    if ShouldBeAnchored    == nil then ShouldBeAnchored    = true end
    if ShouldHaveCollision == nil then ShouldHaveCollision = true end
    local NeedsResizeAfterPlacement = false
    pcall(function()
      pcall(function() LocalPlayer.Backpack.Build.Parent = LocalPlayer.Character end)
      local AdjacentBlockFound, RetryCount = false, 0
      MostRecentlyBuiltBlock = nil

      -- Adjacency-chain attempt
      if #BuiltBlockHistoryRingBuffer > 0 and PreviousPreviewPart then
        local AdjacentCandidateList = {}
        for HistoryIndex, HistoryBlock in pairs(BuiltBlockHistoryRingBuffer) do
          if HistoryBlock == nil or HistoryBlock.Parent == nil then BuiltBlockHistoryRingBuffer[HistoryIndex] = nil; continue end
          if PreviousPreviewPart.Size == HistoryBlock.Size then
            for NormalId, AxisData in pairs(NormalIdToAxisMap) do
              local AdjacentPosition = HistoryBlock.Position + (AxisData[1] * HistoryBlock.Size[AxisData[2]])
              if AdjacentPosition == PreviousPreviewPart.Position then
                AdjacentBlockFound = { NormalId, HistoryBlock, HistoryBlock.Position + (AxisData[1] * HistoryBlock.Size[AxisData[2]] / 2) }
                table.insert(AdjacentCandidateList, AdjacentBlockFound)
              end
            end
          end
        end
        if #AdjacentCandidateList > 1 and DesiredColor and AdjacentBlockFound and AdjacentBlockFound[2] and AdjacentBlockFound[2].Color ~= DesiredColor then
          for _, CandidateEntry in pairs(AdjacentCandidateList) do
            if CandidateEntry[2].Color == DesiredColor then AdjacentBlockFound = CandidateEntry end
          end
        end
        if AdjacentBlockFound and AdjacentBlockFound[2] ~= nil and AdjacentBlockFound[2].Parent ~= nil then
          local OriginalPlacementPosition = PlacementPosition
          local PlacementArguments = { AdjacentBlockFound[2], AdjacentBlockFound[1], AdjacentBlockFound[3] or PreviousPreviewPart.Position, "normal" }
          BlockHasBeenBuilt = false; MostRecentlyBuiltBlock = nil; RetryCount = 0
          repeat
            RetryCount = RetryCount + 1
            if LocalPlayer.Character:FindFirstChild("Build") then
              pcall(function()
                local OriginalEventBinding = LocalPlayer.Character.Build:FindFirstChild("origevent")
                if OriginalEventBinding then OriginalEventBinding:Invoke(table.unpack(PlacementArguments))
                else LocalPlayer.Character.Build.Script.Event:FireServer(table.unpack(PlacementArguments)) end
              end)
            else
              pcall(function() LocalPlayer.Backpack.Build.Parent = LocalPlayer.Character end)
            end
            pcall(function()
              PlacementPosition = AdjacentBlockFound[3] or PlacementPosition
              if TeleportPlayerToBlock then LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(PlacementPosition) end
            end)
            RunService.Heartbeat:Wait()
          until (BlockHasBeenBuilt and MostRecentlyBuiltBlock) or AdjacentBlockFound[2] == nil or AdjacentBlockFound[2].Parent == nil
              or IsBuildStopped or ShouldSkipCurrentBlock or RetryCount > SessionSettings.maxtry
          if AdjacentBlockFound[2] == nil or AdjacentBlockFound[2].Parent == nil or RetryCount > SessionSettings.maxtry then
            AdjacentBlockFound = false
          else
            if PreviousPreviewPart then PreviousPreviewPart:Destroy() end
          end
          PlacementPosition = OriginalPlacementPosition
        end
      end

      -- Diagonal-bridge path
      if AdjacentBlockFound == false and #BuiltBlockHistoryRingBuffer > 0 and PreviousPreviewPart then
        local DiagonalNeighbour  = nil
        local BridgeNormalId     = nil
        local BridgeHistoryBlock = nil

        for HistoryIndex, HistoryBlock in pairs(BuiltBlockHistoryRingBuffer) do
          if HistoryBlock == nil or HistoryBlock.Parent == nil then BuiltBlockHistoryRingBuffer[HistoryIndex] = nil; continue end
          if PreviousPreviewPart.Size ~= HistoryBlock.Size then continue end
          local Delta = PreviousPreviewPart.Position - HistoryBlock.Position
          local AxesOff = 0
          if math.abs(Delta.X) > 0.01 then AxesOff = AxesOff + 1 end
          if math.abs(Delta.Y) > 0.01 then AxesOff = AxesOff + 1 end
          if math.abs(Delta.Z) > 0.01 then AxesOff = AxesOff + 1 end
          if AxesOff == 2 then
            for NormalId, AxisData in pairs(NormalIdToAxisMap) do
              local TPos   = HistoryBlock.Position + (AxisData[1] * HistoryBlock.Size[AxisData[2]])
              local TDelta = PreviousPreviewPart.Position - TPos
              local TAxesOff = 0
              if math.abs(TDelta.X) > 0.01 then TAxesOff = TAxesOff + 1 end
              if math.abs(TDelta.Y) > 0.01 then TAxesOff = TAxesOff + 1 end
              if math.abs(TDelta.Z) > 0.01 then TAxesOff = TAxesOff + 1 end
              if TAxesOff == 1 then
                DiagonalNeighbour = HistoryBlock; BridgeNormalId = NormalId; BridgeHistoryBlock = HistoryBlock; break
              end
            end
          end
          if DiagonalNeighbour then break end
        end

        if DiagonalNeighbour and BridgeNormalId and BridgeHistoryBlock and BridgeHistoryBlock.Parent then
          local AxisData        = NormalIdToAxisMap[BridgeNormalId]
          local BridgeFaceCenter = BridgeHistoryBlock.Position + (AxisData[1] * BridgeHistoryBlock.Size[AxisData[2]] / 2)
          local TempBlock        = nil
          local TPlacementArgs   = { BridgeHistoryBlock, BridgeNormalId, BridgeFaceCenter, "normal" }
          BlockHasBeenBuilt = false; MostRecentlyBuiltBlock = nil; RetryCount = 0
          repeat
            RetryCount = RetryCount + 1
            if LocalPlayer.Character:FindFirstChild("Build") then
              pcall(function()
                local OriginalEventBinding = LocalPlayer.Character.Build:FindFirstChild("origevent")
                if OriginalEventBinding then OriginalEventBinding:Invoke(table.unpack(TPlacementArgs))
                else LocalPlayer.Character.Build.Script.Event:FireServer(table.unpack(TPlacementArgs)) end
              end)
            else
              pcall(function() LocalPlayer.Backpack.Build.Parent = LocalPlayer.Character end)
            end
            pcall(function()
              if TeleportPlayerToBlock then LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(BridgeFaceCenter) end
            end)
            RunService.Heartbeat:Wait()
          until (BlockHasBeenBuilt and MostRecentlyBuiltBlock) or BridgeHistoryBlock.Parent == nil
              or IsBuildStopped or ShouldSkipCurrentBlock or RetryCount > SessionSettings.maxtry

          if BlockHasBeenBuilt and MostRecentlyBuiltBlock and BridgeHistoryBlock.Parent ~= nil
              and not IsBuildStopped and not ShouldSkipCurrentBlock then
            TempBlock = MostRecentlyBuiltBlock
            local RealNormalId, RealFaceCenter
            for NId, AData in pairs(NormalIdToAxisMap) do
              local CandPos = TempBlock.Position + (AData[1] * TempBlock.Size[AData[2]])
              if math.abs((CandPos - PreviousPreviewPart.Position).Magnitude) < 0.15 then
                RealNormalId   = NId
                RealFaceCenter = TempBlock.Position + (AData[1] * TempBlock.Size[AData[2]] / 2)
                break
              end
            end
            if RealNormalId then
              local RealPlacementArgs = { TempBlock, RealNormalId, RealFaceCenter, "normal" }
              BlockHasBeenBuilt = false; MostRecentlyBuiltBlock = nil; RetryCount = 0
              repeat
                RetryCount = RetryCount + 1
                if LocalPlayer.Character:FindFirstChild("Build") then
                  pcall(function()
                    local OriginalEventBinding = LocalPlayer.Character.Build:FindFirstChild("origevent")
                    if OriginalEventBinding then OriginalEventBinding:Invoke(table.unpack(RealPlacementArgs))
                    else LocalPlayer.Character.Build.Script.Event:FireServer(table.unpack(RealPlacementArgs)) end
                  end)
                else
                  pcall(function() LocalPlayer.Backpack.Build.Parent = LocalPlayer.Character end)
                end
                pcall(function()
                  if TeleportPlayerToBlock then LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(RealFaceCenter) end
                end)
                RunService.Heartbeat:Wait()
              until (BlockHasBeenBuilt and MostRecentlyBuiltBlock) or TempBlock.Parent == nil
                  or IsBuildStopped or ShouldSkipCurrentBlock or RetryCount > SessionSettings.maxtry
              if BlockHasBeenBuilt and MostRecentlyBuiltBlock and not IsBuildStopped and not ShouldSkipCurrentBlock
                  and RetryCount <= SessionSettings.maxtry then
                local RealBlock = MostRecentlyBuiltBlock
                pcall(function()
                  local DeleteTool = LocalPlayer.Character:FindFirstChild("Delete") or LocalPlayer.Backpack:FindFirstChild("Delete")
                  if DeleteTool then
                    local DelEventBind = DeleteTool:FindFirstChild("origevent")
                    if DelEventBind then DelEventBind:Invoke(TempBlock, Enum.NormalId.Top, TempBlock.Position, "")
                    elseif DeleteTool:FindFirstChild("Script") then DeleteTool.Script.Event:FireServer(TempBlock, Enum.NormalId.Top, TempBlock.Position, "")
                    else TempBlock:Destroy() end
                  else
                    TempBlock:Destroy()
                  end
                end)
                AdjacentBlockFound = { RealNormalId, TempBlock, RealFaceCenter }
                MostRecentlyBuiltBlock = RealBlock
                if PreviousPreviewPart then PreviousPreviewPart:Destroy() end
              else
                pcall(function() TempBlock:Destroy() end)
                AdjacentBlockFound = false; MostRecentlyBuiltBlock = nil
              end
            else
              pcall(function() TempBlock:Destroy() end)
              AdjacentBlockFound = false; MostRecentlyBuiltBlock = nil
            end
          else
            AdjacentBlockFound = false; MostRecentlyBuiltBlock = nil
          end
        end
      end

      -- Fresh-place fallback
      if AdjacentBlockFound == false then
        if BlockSizeMode == nil then
          BlockSizeMode = "normal"
          if LocalPlayer.PlayerGui:FindFirstChild("Build") and LocalPlayer.PlayerGui.Build:FindFirstChild("Button") then
            BlockSizeMode = LocalPlayer.PlayerGui.Build.Button.Text
          end
          if BlockSizeVector and (BlockSizeVector.X ~= GridUnitSize or BlockSizeVector.Y ~= GridUnitSize or BlockSizeVector.Z ~= GridUnitSize) then
            BlockSizeMode = "detailed"
          elseif BlockSizeVector then
            BlockSizeMode = "normal"
          end
          if not BlockSizeVector and BlockSizeMode ~= "detailed" and PreviousPreviewPart and PreviousPreviewPart.Position ~= SnapPositionToGrid(PlacementPosition) then
            BlockSizeMode = "detailed"; NeedsResizeAfterPlacement = true
            BlockSizeVector = Vector3.new(4, 4, 4)
            PlacementPosition = Vector3.new(
              (PlacementPosition.X - BlockSizeVector.X/2) + 0.5,
              (PlacementPosition.Y - BlockSizeVector.Y/2) + 0.5,
              (PlacementPosition.Z - BlockSizeVector.Z/2) + 0.5
            )
          end
        end
        PlacementPosition = SnapToGrid(PlacementPosition)
        local PlacementArguments = { workspace.Terrain, Enum.NormalId.Top, PlacementPosition, BlockSizeMode or "normal" }
        BlockHasBeenBuilt = false
        pcall(function()
          local OriginalEventBinding = LocalPlayer.Character.Build:FindFirstChild("origevent")
          if OriginalEventBinding then OriginalEventBinding:Invoke(table.unpack(PlacementArguments))
          else LocalPlayer.Character.Build.Script.Event:FireServer(table.unpack(PlacementArguments)) end
        end)
        RetryCount = 0
        repeat
          RetryCount = RetryCount + 1
          if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("Build") and LocalPlayer.Backpack:FindFirstChild("Build") then
            LocalPlayer.Backpack.Build.Parent = LocalPlayer.Character
          end
          if LocalPlayer.Character:FindFirstChild("Build") then
            pcall(function()
              local OriginalEventBinding = LocalPlayer.Character.Build:FindFirstChild("origevent")
              if OriginalEventBinding then OriginalEventBinding:Invoke(table.unpack(PlacementArguments))
              else LocalPlayer.Character.Build.Script.Event:FireServer(table.unpack(PlacementArguments)) end
            end)
          end
          pcall(function()
            if TeleportPlayerToBlock then
              LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(PlacementPosition + Vector3.new(0,6,0))
            end
          end)
          RunService.Heartbeat:Wait()
        until (BlockHasBeenBuilt and MostRecentlyBuiltBlock) or IsBuildStopped or ShouldSkipCurrentBlock or RetryCount > SessionSettings.maxtry
        BlockHasBeenBuilt = false; RetryCount = 0
      end

      -- Paint / material
      if MostRecentlyBuiltBlock and typeof(DesiredColor) == "Color3"
        and (DesiredColor ~= DefaultBlockColor or MostRecentlyBuiltBlock.Color ~= DesiredColor or MostRecentlyBuiltBlock.Material ~= TextureMaterialName)
        and (LocalPlayer.Backpack:FindFirstChild("Paint") or LocalPlayer.Character:FindFirstChild("Paint"))
        and ((PaintEvenWhenDefaultColor and IsPremadeBlock ~= nil) or not PaintEvenWhenDefaultColor or TextureMaterialName)
      then
        local PaintTargetPosition = MostRecentlyBuiltBlock.Position + MostRecentlyBuiltBlock.Size / 2
        local PaintArguments = { MostRecentlyBuiltBlock, Enum.NormalId.Top, PaintTargetPosition, "color", DesiredColor, "tiles", "" }
        pcall(function() LocalPlayer.Backpack.Paint.Parent = LocalPlayer.Character end)
        if TextureMaterialName then
          PaintArguments[4] = DesiredColor == nil and "material" or "both \u{1F91D}"
          PaintArguments[6] = TextureMaterialName
        end
        if not MostRecentlyBuiltBlock then if PreviousPreviewPart then PreviousPreviewPart:Destroy() end; return end
        BlockHighlight.Adornee = MostRecentlyBuiltBlock; RetryCount = 0
        pcall(function()
          repeat
            RetryCount = RetryCount + 1
            if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("Paint") and LocalPlayer.Backpack:FindFirstChild("Paint") then
              LocalPlayer.Backpack.Paint.Parent = LocalPlayer.Character
            end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Paint") then
              pcall(function()
                local OriginalEventBinding = LocalPlayer.Character.Paint:FindFirstChild("origevent")
                if OriginalEventBinding then OriginalEventBinding:Invoke(table.unpack(PaintArguments))
                else LocalPlayer.Character.Paint.Script.Event:FireServer(table.unpack(PaintArguments)) end
              end)
            end
            pcall(function()
              if TeleportPlayerToBlock then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(PaintTargetPosition + Vector3.new(0,6,0))
              end
            end)
            RunService.Heartbeat:Wait()
          until not MostRecentlyBuiltBlock or not MostRecentlyBuiltBlock.Parent
              or MostRecentlyBuiltBlock.Color == DesiredColor
              or (TextureMaterialName and MostRecentlyBuiltBlock.Material == Enum.Material[OriginalMaterialName])
              or IsBuildStopped or ShouldSkipCurrentBlock or RetryCount > 250
        end)
      end

      -- Anchor toggle
      if MostRecentlyBuiltBlock and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Paint")
        and MostRecentlyBuiltBlock.Anchored ~= ShouldBeAnchored then
        local AnchorTogglePosition = MostRecentlyBuiltBlock.Position + MostRecentlyBuiltBlock.Size / 2
        local AnchorArguments = { MostRecentlyBuiltBlock, Enum.NormalId.Top, AnchorTogglePosition, "material", nil, "anchor", "" }
        RetryCount = 0
        repeat
          RetryCount = RetryCount + 1
          if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("Paint") and LocalPlayer.Backpack:FindFirstChild("Paint") then
            LocalPlayer.Backpack.Paint.Parent = LocalPlayer.Character
          end
          if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Paint")
            and MostRecentlyBuiltBlock and MostRecentlyBuiltBlock.Anchored ~= ShouldBeAnchored then
            pcall(function()
              local OriginalEventBinding = LocalPlayer.Character.Paint:FindFirstChild("origevent")
              if OriginalEventBinding then OriginalEventBinding:Invoke(table.unpack(AnchorArguments))
              else LocalPlayer.Character.Paint.Script.Event:FireServer(table.unpack(AnchorArguments)) end
            end)
          end
          pcall(function()
            if TeleportPlayerToBlock then LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(AnchorTogglePosition + Vector3.new(0,8,0)) end
          end)
          task.wait(0.15)
        until not MostRecentlyBuiltBlock or not MostRecentlyBuiltBlock.Parent or MostRecentlyBuiltBlock.Anchored == ShouldBeAnchored
            or not LocalPlayer.Character
            or (not LocalPlayer.Character:FindFirstChild("Paint") and not LocalPlayer.Backpack:FindFirstChild("Paint"))
            or IsBuildStopped or ShouldSkipCurrentBlock or RetryCount > 12
      end

      -- Collide toggle
      if MostRecentlyBuiltBlock and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Paint")
        and MostRecentlyBuiltBlock.CanCollide ~= ShouldHaveCollision then
        local CollideTogglePosition = MostRecentlyBuiltBlock.Position + MostRecentlyBuiltBlock.Size / 2
        local CollideArguments = { MostRecentlyBuiltBlock, Enum.NormalId.Top, CollideTogglePosition, "material", nil, "collide", "" }
        RetryCount = 0
        repeat
          RetryCount = RetryCount + 1
          if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("Paint") and LocalPlayer.Backpack:FindFirstChild("Paint") then
            LocalPlayer.Backpack.Paint.Parent = LocalPlayer.Character
          end
          if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Paint")
            and MostRecentlyBuiltBlock and MostRecentlyBuiltBlock.CanCollide ~= ShouldHaveCollision then
            pcall(function()
              local OriginalEventBinding = LocalPlayer.Character.Paint:FindFirstChild("origevent")
              if OriginalEventBinding then OriginalEventBinding:Invoke(table.unpack(CollideArguments))
              else LocalPlayer.Character.Paint.Script.Event:FireServer(table.unpack(CollideArguments)) end
            end)
          end
          pcall(function()
            if TeleportPlayerToBlock then LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(CollideTogglePosition + Vector3.new(0,8,0)) end
          end)
          task.wait(0.15)
        until not MostRecentlyBuiltBlock or not MostRecentlyBuiltBlock.Parent or MostRecentlyBuiltBlock.CanCollide == ShouldHaveCollision
            or not LocalPlayer.Character
            or (not LocalPlayer.Character:FindFirstChild("Paint") and not LocalPlayer.Backpack:FindFirstChild("Paint"))
            or IsBuildStopped or ShouldSkipCurrentBlock or RetryCount > 12
      end

      BlockHighlight.Adornee = nil

      -- Sprays
      if MostRecentlyBuiltBlock and (LocalPlayer.Backpack:FindFirstChild("Paint") or LocalPlayer.Character:FindFirstChild("Paint"))
        and SpraysData ~= nil then
        local SprayArguments = { MostRecentlyBuiltBlock, Enum.NormalId.Front, MostRecentlyBuiltBlock.Position + Vector3.new(1,0,0), "material", nil, "spray", "ha" }
        for _, SprayEntry in pairs(SpraysData) do
          SprayArguments[2] = Enum.NormalId[SprayEntry[1]]
          local SprayPayload = SprayEntry[3]
          if (not SprayPayload or SprayPayload == "") and type(SprayEntry[2]) == "string" and SprayEntry[2] ~= "" then
            SprayPayload = SprayEntry[2]
          end
          SprayArguments[7] = SprayPayload or ""
          if MostRecentlyBuiltBlock and (LocalPlayer.Backpack:FindFirstChild("Paint") or LocalPlayer.Character:FindFirstChild("Paint"))
            and not IsBuildStopped and not ShouldSkipCurrentBlock then
            pcall(function() LocalPlayer.Backpack.Paint.Parent = LocalPlayer.Character end)
            pcall(function()
              task.wait(0.25)
              local OriginalEventBinding = LocalPlayer.Character.Paint:FindFirstChild("origevent")
              if OriginalEventBinding then OriginalEventBinding:Invoke(table.unpack(SprayArguments))
              else LocalPlayer.Character.Paint.Script.Event:FireServer(table.unpack(SprayArguments)) end
            end)
          end
        end
      end

      -- Resize (Shape tool)
      if MostRecentlyBuiltBlock
        and ((BlockSizeVector and (BlockSizeVector.X ~= GridUnitSize or BlockSizeVector.Y ~= GridUnitSize or BlockSizeVector.Z ~= GridUnitSize)) or NeedsResizeAfterPlacement)
        and (LocalPlayer.Character:FindFirstChild("Shape") or LocalPlayer.Backpack:FindFirstChild("Shape"))
      then
        if not LocalPlayer.Character:FindFirstChild("Shape") and LocalPlayer.Backpack:FindFirstChild("Shape") then
          LocalPlayer.Backpack.Shape.Parent = LocalPlayer.Character
        end
        local ResizeArguments = { MostRecentlyBuiltBlock, Enum.NormalId.Right, "", "" }
        local function ResizeSingleAxisToTarget(AxisName, TargetSize)
          if not (MostRecentlyBuiltBlock and MostRecentlyBuiltBlock.Size[AxisName] ~= TargetSize) then return end
          RetryCount = 0
          repeat
            RetryCount = RetryCount + 1
            local ResizeTargetPosition = (MostRecentlyBuiltBlock and MostRecentlyBuiltBlock.Position + MostRecentlyBuiltBlock.Size / 2) or PlacementPosition
            ResizeArguments[3] = ResizeTargetPosition; ResizeArguments[4] = nil
            if MostRecentlyBuiltBlock then
              if   MostRecentlyBuiltBlock.Size[AxisName] > TargetSize then ResizeArguments[4] = "decrease"
              elseif MostRecentlyBuiltBlock.Size[AxisName] < TargetSize then ResizeArguments[4] = "increase" end
            end
            if not LocalPlayer.Character:FindFirstChild("Shape") and LocalPlayer.Backpack:FindFirstChild("Shape") then
              LocalPlayer.Backpack.Shape.Parent = LocalPlayer.Character
            end
            if LocalPlayer.Character:FindFirstChild("Shape") then
              pcall(function()
                local OriginalEventBinding = LocalPlayer.Character.Shape:FindFirstChild("origevent")
                if OriginalEventBinding then OriginalEventBinding:Invoke(table.unpack(ResizeArguments))
                else LocalPlayer.Character.Shape.Script.Event:FireServer(table.unpack(ResizeArguments)) end
              end)
            end
            pcall(function()
              if TeleportPlayerToBlock then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(ResizeTargetPosition + Vector3.new(0,6,0))
              end
            end)
            task.wait(SessionSettings.resizewait)
          until ResizeArguments[4] == nil
              or (ResizeArguments[4] == "decrease" and MostRecentlyBuiltBlock and MostRecentlyBuiltBlock.Size[AxisName] <= 1)
              or (MostRecentlyBuiltBlock and MostRecentlyBuiltBlock.Size[AxisName] == TargetSize)
              or IsBuildStopped or ShouldSkipCurrentBlock
              or not MostRecentlyBuiltBlock or not MostRecentlyBuiltBlock.Parent
              or RetryCount > (TargetSize * 3) / SessionSettings.resizewait
        end
        ResizeArguments[2] = Enum.NormalId.Right; ResizeSingleAxisToTarget("X", BlockSizeVector.X)
        ResizeArguments[2] = Enum.NormalId.Top;   ResizeSingleAxisToTarget("Y", BlockSizeVector.Y)
        ResizeArguments[2] = Enum.NormalId.Back;  ResizeSingleAxisToTarget("Z", BlockSizeVector.Z)
      end
      ShouldSkipCurrentBlock = false
    end)
    if PreviousPreviewPart then PreviousPreviewPart:Destroy() end
    MostRecentlyBuiltBlock = nil
  end

  -- ── Transform / resolve helpers ───────────────────────────────────────────
  local function ApplyTransformToBlockPosition(RawBlockPosition, BlockSize, TransformConfig)
    if not TransformConfig or not TransformConfig.enabled then return RawBlockPosition end
    local HalfSizeOffset    = Vector3.new(BlockSize.X/2-0.5, BlockSize.Y/2-0.5, BlockSize.Z/2-0.5)
    local TransformCenter   = TransformConfig.center   or Vector3.zero
    local TransformRotation = TransformConfig.rotation or CFrame.identity
    local TransformOffset   = TransformConfig.offset   or Vector3.zero
    local OriginalCenter    = RawBlockPosition + HalfSizeOffset
    local TransformedCenter = TransformCenter + (TransformRotation * (OriginalCenter - TransformCenter)) + TransformOffset
    return TransformedCenter - HalfSizeOffset
  end

  local function ResolveBlockDataToPlacementParameters(BlockDataEntry, TransformConfig)
    local PositionArray = BlockDataEntry and (BlockDataEntry.p or BlockDataEntry.pos); if not PositionArray then return nil end
    local SizeArray     = BlockDataEntry.s or BlockDataEntry.size
    local ResolvedSize  = SizeArray and Vector3.new(table.unpack(SizeArray)) or Vector3.new(GridUnitSize, GridUnitSize, GridUnitSize)
    local RawPosition         = Vector3.new(PositionArray[1], PositionArray[2], PositionArray[3]) * SessionSettings.mult
    local TransformedPosition = ApplyTransformToBlockPosition(RawPosition, ResolvedSize, TransformConfig)
    local ResolvedColor        = (BlockDataEntry.c or BlockDataEntry.color) and Color3.fromRGB(table.unpack(BlockDataEntry.c or BlockDataEntry.color)) or DefaultBlockColor
    local ResolvedMaterialName = BlockDataEntry.m or BlockDataEntry.mat
    local OriginalMaterialName = BlockDataEntry.o or BlockDataEntry.origmat
    local ResolvedMaterialEnum = MaterialNameToEnumMap[ResolvedMaterialName] or Enum.Material.SmoothPlastic
    if not MaterialNameToEnumMap[ResolvedMaterialName] and OriginalMaterialName then
      pcall(function() ResolvedMaterialEnum = Enum.Material[OriginalMaterialName] or ResolvedMaterialEnum end)
    end
    local ResolvedAnchored   = BlockDataEntry.a
    local ResolvedCanCollide = BlockDataEntry.cc
    local ResolvedCenter     = SizeArray and ComputeBlockCenterPosition(TransformedPosition, ResolvedSize) or TransformedPosition
    return { pos=TransformedPosition, size=ResolvedSize, color=ResolvedColor, matName=ResolvedMaterialName, expectMat=ResolvedMaterialEnum,
             center=ResolvedCenter, anchored=ResolvedAnchored, collide=ResolvedCanCollide }
  end

  local function PlaceBlockAndVerifySuccess(BlockDataEntry, TransformConfig)
    local ResolvedParameters = ResolveBlockDataToPlacementParameters(BlockDataEntry, TransformConfig)
    if not ResolvedParameters then return true end
    if IsBlockVerifiedAtPosition(ResolvedParameters.center, ResolvedParameters.size, ResolvedParameters.color, ResolvedParameters.expectMat, ResolvedParameters.anchored, ResolvedParameters.collide) then return true end
    EnsureAllBuildToolsAreEquipped(true)
    CreatePreviewReplacementPart(ResolvedParameters.pos, ResolvedParameters.size, ResolvedParameters.color, ResolvedParameters.expectMat)
    PlaceAndConfigureBlock(ResolvedParameters.pos, ResolvedParameters.matName, ResolvedParameters.color, nil, ResolvedParameters.size, true, BlockDataEntry.o or BlockDataEntry.origmat, BlockDataEntry.sp or BlockDataEntry.sprayed, ResolvedParameters.anchored, ResolvedParameters.collide)
    task.wait(math.max(0.03, GetCurrentBuildDelay()))
    return IsBlockVerifiedAtPosition(ResolvedParameters.center, ResolvedParameters.size, ResolvedParameters.color, ResolvedParameters.expectMat, ResolvedParameters.anchored, ResolvedParameters.collide)
  end

  -- ── Sort by distance from spawn ───────────────────────────────────────────
  local function SortBlockListByDistanceFromSpawn(BlockList)
    local SpawnReferencePosition
    local SpawnLocationInstance = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("Spawn")
    if SpawnLocationInstance then
      if SpawnLocationInstance:IsA("Model") then
        local SpawnRootPart = SpawnLocationInstance:FindFirstChildOfClass("HumanoidRootPart")
        if SpawnRootPart then SpawnReferencePosition = SpawnRootPart.Position end
      elseif SpawnLocationInstance:IsA("BasePart") then
        SpawnReferencePosition = SpawnLocationInstance.Position
      end
    end
    if not SpawnReferencePosition then
      for _, PlayerInstance in ipairs(PlayersService:GetPlayers()) do
        if PlayerInstance.Character then
          local CharacterRootPart = PlayerInstance.Character:FindFirstChild("HumanoidRootPart")
          if CharacterRootPart then SpawnReferencePosition = CharacterRootPart.Position; break end
        end
      end
    end
    SpawnReferencePosition = SpawnReferencePosition or Vector3.new(0, 100, 0)
    for _, BlockEntry in ipairs(BlockList) do
      local PositionArray = BlockEntry.p or BlockEntry.pos
      if PositionArray then
        local BlockWorldPosition = Vector3.new(PositionArray[1], PositionArray[2], PositionArray[3])
        local SizeArray = BlockEntry.s or BlockEntry.size
        if SizeArray then BlockWorldPosition = Vector3.new(BlockWorldPosition.X+SizeArray[1]/2-0.5, BlockWorldPosition.Y+SizeArray[2]/2-0.5, BlockWorldPosition.Z+SizeArray[3]/2-0.5) end
        BlockEntry.dist = (BlockWorldPosition - SpawnReferencePosition).Magnitude
      else
        BlockEntry.dist = math.huge
      end
    end
    table.sort(BlockList, function(BlockA, BlockB) return BlockA.dist < BlockB.dist end)
    for _, BlockEntry in ipairs(BlockList) do BlockEntry.dist = nil end
    return BlockList
  end

  -- ── Core build loop ───────────────────────────────────────────────────────
  local function ExecuteBuildLoop(BuildBlockData, TransformConfig)
    if type(BuildBlockData) ~= "table" or #BuildBlockData == 0 then
      NotifyUser("Build data invalid or empty."); return false
    end
    if not EnsureAllBuildToolsAreEquipped(true) then return false end

    CurrentRunGenerationId = CurrentRunGenerationId + 1
    local ThisRunGenerationId = CurrentRunGenerationId
    LastBuildState = { blocks = BuildBlockData, transform = TransformConfig }

    IsBuildStopped = false; ShouldSkipCurrentBlock = false
    local SortedBlockList = SortBlockListByDistanceFromSpawn(BuildBlockData)
    TotalBlocksInCurrentBuild = #SortedBlockList
    NumberOfBlocksVerified    = 0
    BuildStartTimestamp       = tick()
    UpdateStats()

    task.spawn(function()
      local VerifiedBlockIndexSet = {}; local VerifiedCount = 0

      local function IsBuildAborted()
        if getgenv()[GENKEY] ~= moduleGen then IsBuildStopped = true end
        return IsBuildStopped or CurrentRunGenerationId ~= ThisRunGenerationId
      end
      local function MarkBlockAsVerified(BlockIndex)
        if not VerifiedBlockIndexSet[BlockIndex] then
          VerifiedBlockIndexSet[BlockIndex] = true; VerifiedCount = VerifiedCount + 1
          NumberOfBlocksVerified = VerifiedCount; UpdateStats()
        end
      end

      for BlockIndex, BlockEntry in ipairs(SortedBlockList) do
        if IsBuildAborted() then break end
        if BlockIndex % 25 == 0 then EnsureAllBuildToolsAreEquipped(false) end
        if PlaceBlockAndVerifySuccess(BlockEntry, TransformConfig) then MarkBlockAsVerified(BlockIndex) end
        task.wait(math.max(0.03, GetCurrentBuildDelay()))
      end

      local RepairPassNumber = 0
      while not IsBuildAborted() and VerifiedCount < #SortedBlockList and RepairPassNumber < 4 do
        RepairPassNumber = RepairPassNumber + 1
        local BlocksRepairedThisPass = 0
        if SessionSettings.wbs then task.wait(1) end
        for BlockIndex, BlockEntry in ipairs(SortedBlockList) do
          if IsBuildAborted() then break end
          if not VerifiedBlockIndexSet[BlockIndex] then
            if PlaceBlockAndVerifySuccess(BlockEntry, TransformConfig) then MarkBlockAsVerified(BlockIndex); BlocksRepairedThisPass = BlocksRepairedThisPass + 1 end
            task.wait(math.max(0.03, GetCurrentBuildDelay()))
          end
        end
        if BlocksRepairedThisPass == 0 then break end
      end

      local BuildWasAborted       = IsBuildAborted()
      local NumberOfMissingBlocks = #SortedBlockList - VerifiedCount
      if CurrentRunGenerationId == ThisRunGenerationId then IsBuildStopped = false; ShouldSkipCurrentBlock = false end
      TotalBlocksInCurrentBuild = 0; NumberOfBlocksVerified = 0; UpdateStats()

      if BuildWasAborted then
        NotifyUser("Build stopped.")
      elseif NumberOfMissingBlocks > 0 then
        NotifyUser(string.format("Build finished: %d/%d verified (%d need manual attention).", VerifiedCount, #SortedBlockList, NumberOfMissingBlocks))
      else
        NotifyUser(string.format("Build complete: %d/%d blocks.", VerifiedCount, #SortedBlockList))
      end
    end)

    return true
  end

  -- ── Data loading ──────────────────────────────────────────────────────────
  local function LoadBuildDataFromSource()
    if IsPreDecodedData then
      if type(FilePath) == "table" then return FilePath, nil end
      return nil, "isData=true but filepath is not a table"
    end
    local RawData
    if type(FetchToolsFunction) == "function" then
      RawData = FetchToolsFunction(FilePath)
    elseif type(FilePath) == "string" and FilePath:match("^https?://") then
      local FetchSucceeded, FetchResult = pcall(function() return game:HttpGet(FilePath) end)
      if FetchSucceeded then RawData = FetchResult end
    elseif type(FilePath) == "string" then
      local ReadSucceeded, ReadResult = pcall(function() return readfile(FilePath) end)
      if ReadSucceeded and ReadResult and ReadResult ~= "" then RawData = ReadResult else RawData = FilePath end
    end
    if not RawData or RawData == "" then return nil, "Could not load data from: " .. tostring(FilePath) end
    if type(RawData) ~= "string" then return nil, "Expected string data, got " .. type(RawData) end
    if RawData:sub(1, 1) == "{" then
      local JsonSucceeded, JsonResult = pcall(function() return HttpService:JSONDecode(RawData) end)
      if not JsonSucceeded then return nil, "Could not decode JSON: " .. tostring(JsonResult) end
      if type(JsonResult) ~= "table" then return nil, "Decoded JSON is not a table" end
      return JsonResult, nil
    end
    local DecompressSucceeded, DecompressedData = pcall(Decompress, RawData)
    if not DecompressSucceeded then return nil, "Could not decompress data: " .. tostring(DecompressedData) end
    if type(DecompressedData) ~= "table" then return nil, "Decompressed data is not a table" end
    return DecompressedData, nil
  end

  -- ── Build transform from session settings ─────────────────────────────────
  local function BuildTransformFromSessionSettings()
    if SessionSettings.offset == Vector3.zero and SessionSettings.mult == 1 then return nil end
    return { enabled = true, center = Vector3.zero, rotation = CFrame.identity, offset = SessionSettings.offset }
  end

  -- ── Async: generate a fully self-contained script for one remote client ───
  local RemoteClientScriptTemplate = [[
local hs  = game:GetService("HttpService")
local lib = loadstring(game:HttpGet(%s, true))()
local d   = hs:JSONDecode(%s)
local s   = hs:JSONDecode(%s)
s.offset  = Vector3.new(s.ox or 0, s.oy or 0, s.oz or 0)
s.ox, s.oy, s.oz = nil, nil, nil
lib.build(d, s, nil, true).start()
]]

  local function BuildRemoteClientScript(ChunkJson, SettingsJson)
    return string.format(
      RemoteClientScriptTemplate,
      string.format("%q", "https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/autobuildv2.lua"),
      string.format("%q", ChunkJson),
      string.format("%q", SettingsJson)
    )
  end

  local function SerializeSessionSettingsForRemote()
    return HttpService:JSONEncode({
      mult        = SessionSettings.mult,
      historymax  = SessionSettings.historymax,
      resizewait  = SessionSettings.resizewait,
      wbs         = SessionSettings.wbs,
      maxtry      = SessionSettings.maxtry,
      maxtrydelay = SessionSettings.maxtrydelay,
      ox          = SessionSettings.offset.X,
      oy          = SessionSettings.offset.Y,
      oz          = SessionSettings.offset.Z,
    })
  end

  -- ── Session handle ────────────────────────────────────────────────────────
  local BuildSession = {}

  BuildSession.stats = Stats

  function BuildSession.settings()
    return SessionSettings, DEFAULTS
  end

  function BuildSession.stop()
    IsBuildStopped = true; ShouldSkipCurrentBlock = true
  end

  function BuildSession.skip()
    ShouldSkipCurrentBlock = true
  end

  function BuildSession.wbs(NewValue)
    SessionSettings.wbs = NewValue
  end

  function BuildSession.resizewait(NewValue)
    SessionSettings.resizewait = NewValue
  end

  function BuildSession.try(NewDelay, NewMax)
    if NewDelay then SessionSettings.maxtrydelay = NewDelay end
    if NewMax   then SessionSettings.maxtry      = NewMax   end
  end

  function BuildSession.start()
    IsBuildStopped = false; ShouldSkipCurrentBlock = false

    local LoadedData, LoadError = LoadBuildDataFromSource()
    if not LoadedData then
      warn("[AutoBuild] Load failed: " .. tostring(LoadError)); return nil
    end

    if not AsyncConfiguration then
      ExecuteBuildLoop(LoadedData, BuildTransformFromSessionSettings())
      return nil
    end

    if #AsyncConfiguration <= 0 then
      warn("[AutoBuild] async: no remote clients, running locally")
      ExecuteBuildLoop(LoadedData, BuildTransformFromSessionSettings())
      return nil
    end

    local AllSortedBlocks      = SortBlockListByDistanceFromSpawn(LoadedData)
    local TotalBlockCount      = #AllSortedBlocks
    local TotalWorkerCount     = #AsyncConfiguration + 1
    local BaseBlocksPerWorker  = math.floor(TotalBlockCount / TotalWorkerCount)
    local ExtraBlocksRemainder = TotalBlockCount % TotalWorkerCount
    local SerializedSettings   = SerializeSessionSettingsForRemote()
    local BlockCursor          = 1

    for WorkerIndex = 1, TotalWorkerCount do
      local WorkerBlockCount = BaseBlocksPerWorker + (WorkerIndex <= ExtraBlocksRemainder and 1 or 0)
      if WorkerBlockCount == 0 then break end

      local WorkerBlockChunk = {}
      for ChunkIndex = BlockCursor, BlockCursor + WorkerBlockCount - 1 do
        WorkerBlockChunk[#WorkerBlockChunk + 1] = AllSortedBlocks[ChunkIndex]
      end
      BlockCursor = BlockCursor + WorkerBlockCount

      if WorkerIndex < TotalWorkerCount then
        local WorkerChunkJson = HttpService:JSONEncode(WorkerBlockChunk)
        AsyncConfiguration[WorkerIndex](BuildRemoteClientScript(WorkerChunkJson, SerializedSettings))
        NotifyUser(string.format("async: sent %d blocks to remote %d/%d", WorkerBlockCount, WorkerIndex, #AsyncConfiguration))
      else
        NotifyUser(string.format("async: running %d blocks locally (worker %d/%d)", WorkerBlockCount, TotalWorkerCount, TotalWorkerCount))
        ExecuteBuildLoop(WorkerBlockChunk, BuildTransformFromSessionSettings())
      end
    end

    return nil
  end

  return BuildSession
end

-- ── Public lib ────────────────────────────────────────────────────────────────
local lib = {}

function lib.save(filepath, players)
  return SaveBlocksToFile(filepath, players)
end

function lib.build(filepath, settings, fetchtools, isData)
  return CreateBuildSession(filepath, settings, fetchtools, isData)
end

return lib


--[[
  Quick-start:

    local lib  = loadstring(...)()
    local sess = lib.build("https://example.com/mymap.zstd")
    sess.try(nil, 200)
    sess.start()
    -- poll: sess.stats.total, .done, .elapsed, .eta, .ping

    local sess2 = lib.build("https://example.com/mymap.zstd", {
      async = {
        myAsync.clients[1].exec,
        myAsync.clients[2].exec,
      }
    })
    sess2.start()

    lib.save("mymap.zstd", { game.Players.LocalPlayer })
--]]