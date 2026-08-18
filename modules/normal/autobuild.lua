--[[
  Hyperion Project
  Copyright (c) 2026 Horizon-Developments
  Repository:
  https://github.com/Horizon-Developments/hyperion
  License:
  https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/LICENSE.md
]]

local args     = ...
local Tabs     = args.Tabs
local Window   = args.Window
local Obsidian = args.Obsidian
local Assets   = args.Assets
local Helpers  = args.Helpers

Tabs.autobuild = Window:AddTab("Autobuild", "blocks")

local Options = Obsidian.Options
local Main        = Tabs.autobuild:AddLeftGroupbox("File")
local SaveBox     = Tabs.autobuild:AddLeftGroupbox("Save")
local StatsBox    = Tabs.autobuild:AddLeftGroupbox("Stats")
local InstanceBox = Tabs.autobuild:AddRightGroupbox("Instance")
local AsyncBox    = Tabs.autobuild:AddRightGroupbox("Async Bot")

local AutoBuildLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/autobuildv2.lua"))(...)
local HyperionAPI  = loadstring(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/shared/api.lua"))()
local Path = Assets("BuildsV2")

local BuildInstance

if not isfile(Path .. "/readme.txt") then
	writefile(Path .. "/readme.txt", [[Files are compressed using Zstandard (Zstd) at compression level 22. To access the JSON data parsed by the auto-build script, decompress the files first.]])
end

InstanceBox:SetVisible(false)

local lastNotify = {}

local function Notify(id, data)
	local now = os.clock()
	local last = lastNotify[id]

	if last and now - last < 2 then
		return
	end

	lastNotify[id] = now
	Obsidian:Notify(data)
end

Notify("clipboard", {
	Title = "Copied",
	Description = "Script copied to clipboard.",
	Time = 3,
})

local botInstance

AsyncBox:AddLabel("Adds a relay bot that helps build by taking a share of the block list.", true)

AsyncBox:AddButton("GenerateBotURL@autobuild", {
	Text = "Generate Bot URL",
	Func = function()
		if botInstance then
			setclipboard(botInstance:GetClientScript())
			Notify("bot_clipboard", {
				Title = "Copied",
				Description = "Script copied to clipboard.",
				Time = 3,
			})
			return
		end

		Notify("bot_create_wait", {
			Title = "Wait",
			Description = "Calling API to make a connection...",
			Time = 3,
		})

		local ok, result = HyperionAPI.Bots:CreateInstance()
		if not ok then
			Obsidian:Notify({
				Title = "Error",
				Description = tostring(result),
				Time = 3,
			})
			return
		end

		botInstance = result
		setclipboard(botInstance:GetClientScript())

		Obsidian:Notify({
			Title = "Success",
			Description = "Script copied to clipboard. Put it in your bot's Autoexecute.",
			Time = 4,
		})
	end,
})

local FileList = {}
local Selected

local function RefreshFileList()
	FileList = {}

	for _, FilePath in ipairs(listfiles(Path)) do
		if FilePath:match("%.([^%.\\/]+)$") ~= nil then
			continue
		end

		table.insert(FileList, FilePath)
	end

	if Selected and not table.find(FileList, Selected.Path) then
		Selected = nil
	end

	Options["FileName@autobuild"]:SetValues(FileList)
	Options["FileName@autobuild"]:SetValue(Selected and Selected.Path or nil)
end

Main:AddDropdown("FileName@autobuild", {
	Values = {},
	Text = "File",

	FormatDisplayValue = function(Value)
		local name = Value:match("([^\\/]+)$")
		return name:match("^(.*)%.[^%.]+$") or name
	end,

	Callback = function(Value)
		if Value then
			local name = Value:match("([^\\/]+)$")

			Selected = {
				Path = Value,
				Name = name:match("^(.*)%.[^%.]+$") or name,
			}
		else
			Selected = nil
		end
	end,
})

Main:AddButton("Load@autobuild", {
	Text = "Load",

	Func = function()
		if not Selected then
			Obsidian:Notify({
				Title = "No file selected",
				Description = "Select a file first.",
				Time = 3,
			})
			return
		end

		local asyncCallbacks = {}

		if botInstance
			and botInstance.Authenticated
			and botInstance:IsConnected()
		then
			table.insert(asyncCallbacks, function(script)
				botInstance:SendAsync(script)
			end)
		end

		local ok, result = pcall(function()
			return AutoBuildLib.build(Selected.Path, {
				async = asyncCallbacks,
			})
		end)

		if not ok then
			Obsidian:Notify({
				Title = "Load failed",
				Description = tostring(result),
				Time = 6,
			})
			return
		end

		BuildInstance = result
		InstanceBox:SetVisible(true)

		Obsidian:Notify({
			Title = "Instance loaded",
			Description = Selected.Name .. " is ready to run.",
			Time = 3,
		})
	end,
})

Main:AddButton("RefreshFileList@autobuild", {
	Text = "Refresh file list",

	Func = function()
		RefreshFileList()
	end,
})

RefreshFileList()

local SaveSelectedNames = {}
local SaveFilename = ""

local function RefreshSaveDropdown()
	local Folders = {}
	local Bricks = workspace:FindFirstChild("Bricks")

	if not Bricks then
		Options["SavePlayers@autobuild"]:SetValues({})
		return
	end

	for _, Folder in ipairs(Bricks:GetChildren()) do
		if (Folder:IsA("Folder") or Folder:IsA("Model"))
			and #Folder:GetChildren() ~= 0
		then
			table.insert(Folders, Folder.Name)
		end
	end

	table.insert(Folders, "Bricks (save private server build)")

	Options["SavePlayers@autobuild"]:SetValues(Folders)
end

SaveBox:AddDropdown("SavePlayers@autobuild", {
	Text = "Builds (select Folders to save)",
	Values = {},
	Default = {},
	Multi = true,

	Callback = function(Value)
		SaveSelectedNames = {}

		for name, selected in pairs(Value) do
			if selected then
				table.insert(SaveSelectedNames, name)
			end
		end
	end,
})

SaveBox:AddLabel("Refreshes the player list dropdown.", true)

SaveBox:AddButton("RefreshSave@autobuild", {
	Text = "Refresh",

	Func = function()
		RefreshSaveDropdown()
	end,
})

RefreshSaveDropdown()

SaveBox:AddLabel("Filename: a-z A-Z 0-9 _ only.", true)

SaveBox:AddInput("SaveFilename@autobuild", {
	Text = "Filename",
	Placeholder = "",
	ClearTextOnFocus = false,
	Finished = true,

	Callback = function(Value)
		SaveFilename = Value
	end,
})

local IsSaving = false

SaveBox:AddButton("SaveButton@autobuild", {
	Text = "Save",

	Func = function()
		if IsSaving then
			return
		end

		IsSaving = true

		local ok, err = pcall(function()
			if not SaveFilename or SaveFilename == "" then
				Obsidian:Notify({
					Title = "Invalid filename",
					Description = "Set your filename.",
					Time = 3,
				})
				return
			end

			if not SaveFilename:match("^[%w_]+$") then
				Obsidian:Notify({
					Title = "Invalid filename",
					Description = "Filenames can only be a-z A-Z 0-9 _.",
					Time = 3,
				})
				return
			end

			if #SaveSelectedNames == 0 then
				Obsidian:Notify({
					Title = "No selected folders",
					Description = "Select folders.",
					Time = 3,
				})
				return
			end

			local Bricks = workspace:FindFirstChild("Bricks")

			if not Bricks then
				Obsidian:Notify({
					Title = "Save failed",
					Description = "workspace.Bricks was not found.",
					Time = 4,
				})
				return
			end

			local Folders = {}
			local PrivateServerSelected = false

			for _, name in ipairs(SaveSelectedNames) do
				if name == "Bricks (save private server build)" then
					PrivateServerSelected = true
					break
				end
			end

			if PrivateServerSelected then
				table.insert(Folders, Bricks)
			else
				for _, name in ipairs(SaveSelectedNames) do
					local Folder = Bricks:FindFirstChild(name)

					if Folder
						and (Folder:IsA("Folder") or Folder:IsA("Model"))
						and #Folder:GetChildren() ~= 0
					then
						table.insert(Folders, Folder)
					end
				end
			end

			if #Folders == 0 then
				Obsidian:Notify({
					Title = "No valid folders",
					Description = "The selected folders no longer exist or are empty.",
					Time = 3,
				})
				return
			end

			local outputPath = Assets("BuildsV2", SaveFilename)

			local blockCount = AutoBuildLib.save(outputPath, Folders)

			Obsidian:Notify({
				Title = "Created successfully",
				Description = string.format("Saved %d block(s)", blockCount),
				Time = 3,
			})

			RefreshFileList()
		end)

		if not ok then
			Obsidian:Notify({
				Title = "Save failed",
				Description = tostring(err),
				Time = 8,
			})
		end

		task.wait(0.5)
		IsSaving = false
	end,
})

InstanceBox:AddButton("RunInstance@autobuild", {
	Text = "Run instance",

	Func = function()
		if not BuildInstance then
			Obsidian:Notify({
				Title = "No instance loaded",
				Description = "Load a file first.",
				Time = 3,
			})
			return
		end

		Notify("building", {
			Title = "Building...",
			Description = "Build is now running.",
			Time = 3,
		})

		task.spawn(function()
			local ok, res = pcall(function()
				BuildInstance.start()
			end)

			if ok then
				Obsidian:Notify({
					Title = "Build done",
					Description = "Build completed successfully.",
					Time = 3,
				})
			else
				Obsidian:Notify({
					Title = "Build failed",
					Description = tostring(res),
					Time = 8,
				})
			end

			Helpers.log(ok, res)
		end)
	end,
}):AddButton("Stop@autobuild", {
	Text = "Stop",

	Func = function()
		if not BuildInstance then
			return
		end

		local ok, err = pcall(BuildInstance.stop)

		if not ok then
			Obsidian:Notify({
				Title = "Stop failed",
				Description = tostring(err),
				Time = 5,
			})
			return
		end

		Obsidian:Notify({
			Title = "Stopped",
			Description = "Build has been stopped.",
			Time = 3,
		})
	end,
})

InstanceBox:AddLabel("Skips the block currently being attempted and moves to the next one.", true)

InstanceBox:AddButton("SkipBlock@autobuild", {
	Text = "Skip block",

	Func = function()
		if not BuildInstance then
			return
		end

		local ok, err = pcall(BuildInstance.skip)

		if not ok then
			Obsidian:Notify({
				Title = "Skip failed",
				Description = tostring(err),
				Time = 5,
			})
			return
		end

		Obsidian:Notify({
			Title = "Autobuild",
			Description = "Skipped current block.",
			Time = 1.5,
		})
	end,
})

InstanceBox:AddDivider()

InstanceBox:AddLabel("Fires the place remote before setting block properties.", true)

InstanceBox:AddToggle("WaitBeforeSet@autobuild", {
	Text = "Wait before set",
	Default = false,

	Callback = function(v)
		if not BuildInstance then
			return
		end

		BuildInstance.wbs(v)

		Obsidian:Notify({
			Title = "Autobuild",
			Description = "Wait before set: " .. tostring(v),
			Time = 1.5,
		})
	end,
})

InstanceBox:AddLabel("How long to wait (seconds) after resizing a block before continuing.", true)

InstanceBox:AddSlider("ResizeWait@autobuild", {
	Text = "Resize wait",
	Default = 0.2,
	Min = 0,
	Max = 1,
	Rounding = 2,

	Callback = function(v)
		if not BuildInstance then
			return
		end

		BuildInstance.resizewait(v)

		Notify("resize_wait", {
			Title = "Autobuild",
			Description = "Resize wait: " .. tostring(v),
			Time = 1.5,
		})
	end,
})

InstanceBox:AddLabel("Maximum number of placement attempts per block before giving up.", true)

InstanceBox:AddSlider("MaxTries@autobuild", {
	Text = "Max tries",
	Default = 150,
	Min = 1,
	Max = 500,
	Rounding = 0,

	Callback = function(v)
		if not BuildInstance then
			return
		end

		BuildInstance.try(nil, v)

		Notify("max_tries", {
			Title = "Autobuild",
			Description = "Max tries: " .. tostring(v),
			Time = 1.5,
		})
	end,
})

InstanceBox:AddLabel("Delay between each placement attempt. Set to 0 to let autobuild decide based on ping.", true)

InstanceBox:AddSlider("TryDelay@autobuild", {
	Text = "Try delay (0 = auto)",
	Default = 0,
	Min = 0,
	Max = 1,
	Rounding = 3,

	Callback = function(v)
		if not BuildInstance then
			return
		end

		local delay = v == 0 and nil or v

		BuildInstance.try(delay, nil)

		Notify("try_delay", {
			Title = "Autobuild",
			Description = "Try delay: " .. (delay and tostring(v) or "auto"),
			Time = 1.5,
		})
	end,
})

local StatsLabels = {
	progress = StatsBox:AddLabel("Progress:", true),
	elapsed  = StatsBox:AddLabel("Elapsed:", true),
	eta      = StatsBox:AddLabel("ETA:", true),
	ping     = StatsBox:AddLabel("Ping:", true),
}

local RunService = game:GetService("RunService")
local statsAccumulator = 0

RunService.RenderStepped:Connect(function(deltaTime)
	if not BuildInstance then
		return
	end

	statsAccumulator += deltaTime

	if statsAccumulator < 0.1 then
		return
	end

	statsAccumulator = 0

	local s = BuildInstance.stats

	if not s then
		return
	end

	StatsLabels.progress:SetText(
		string.format("Progress: %d / %d", s.done or 0, s.total or 0)
	)

	StatsLabels.elapsed:SetText(
		string.format("Elapsed: %.1fs", s.elapsed or 0)
	)

	StatsLabels.eta:SetText(
		s.eta and string.format("ETA: %.1fs", s.eta) or "ETA:"
	)

	StatsLabels.ping:SetText(
		string.format("Ping: %dms", s.ping or 0)
	)
end)