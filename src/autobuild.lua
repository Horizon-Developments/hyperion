local Players = game:GetService("Players")
local localplr = Players.LocalPlayer
local http = game:GetService("HttpService")
local function builder()
	if not http.JSONDecode or not http.JSONEncode then -- solara support because for some reason it doesnt do json
		http = loadstring(game:HttpGet("https://raw.githubusercontent.com/rxi/json.lua/refs/heads/master/json.lua"))()
		http.JSONDecode = function(self,str)
			return http.decode(str)
		end
		http.JSONEncode = function(self,val)
			return http.encode(val)
		end
	end
	
	local mult = 4
	local defaultcolor = Color3.fromRGB(192, 192, 192)
	
	local normalids = {
		[Enum.NormalId.Right]  = {Vector3.new(1, 0, 0), "X"},
		[Enum.NormalId.Top]    = {Vector3.new(0, 1, 0), "Y"},
		[Enum.NormalId.Back]   = {Vector3.new(0, 0, 1), "Z"},
		[Enum.NormalId.Left]   = {Vector3.new(-1, 0, 0), "X"},
		[Enum.NormalId.Bottom] = {Vector3.new(0, -1, 0), "Y"},
		[Enum.NormalId.Front]  = {Vector3.new(0, 0, -1), "Z"}
	}

	local materials = {
		[Enum.Material.SmoothPlastic] = "smooth",
		[Enum.Material.Plastic]       = "plastic",
		[Enum.Material.CeramicTiles]  = "tiles",
		[Enum.Material.Brick]         = "bricks",
		[Enum.Material.WoodPlanks]    = "planks",
		[Enum.Material.Ice]           = "ice",
		[Enum.Material.Grass]         = "grass",
		[Enum.Material.Sand]          = "sand",
		[Enum.Material.Snow]          = "snow",
		[Enum.Material.Glass]         = "glass",
		[Enum.Material.Wood]          = "wood",
		[Enum.Material.Slate]         = "stone",
		[Enum.Material.Pebble]        = "pebble",
		[Enum.Material.Marble]        = "marble",
		[Enum.Material.Granite]       = "granite",
		[Enum.Material.DiamondPlate]  = "steel",
		[Enum.Material.Metal]         = "metal",
		[Enum.Material.Asphalt]       = "asphalt",
		[Enum.Material.Concrete]      = "concrete",
		[Enum.Material.Pavement]      = "pavement",
		[Enum.Material.Neon]          = "neon"
	}

	local swappedmaterials = {}
	for i, v in pairs(materials) do
		swappedmaterials[v] = i
	end

	local function roundnum(num, m)
		return math.round((num - 2) / (m or mult)) * (m or mult) + 2
	end

	local function round(pos, m)
		return Vector3.new(roundnum(pos.X, m), roundnum(pos.Y, m), roundnum(pos.Z, m))
	end

	local function snap(pos, m)
		return pos
	end

	local function fire_tool(tool, ...)
		if not tool then return end
		if tool:FindFirstChild("origevent") then
			return tool.origevent:Invoke(...)
		elseif tool:FindFirstChild("Script") and tool.Script:FindFirstChild("Event") then
			return tool.Script.Event:FireServer(...)
		end
	end

	-- Helper Block Serialization
	local function saveblock(bl)
		local blockdata = {}
		if bl:IsA("BasePart") then
			local pt = {bl.Position.X, bl.Position.Y, bl.Position.Z}
			
			if (bl.CFrame - bl.Position) ~= CFrame.new() then
				blockdata.p = {bl.CFrame:GetComponents()}
			else
				blockdata.p = pt
			end
			
			blockdata.c = {math.round(bl.Color.R * 255), math.round(bl.Color.G * 255), math.round(bl.Color.B * 255)}
			blockdata.a = bl.Anchored
			blockdata.cc = bl.CanCollide
			
			if bl.Size.X ~= mult or bl.Size.Y ~= mult or bl.Size.Z ~= mult then
				blockdata.p[1] = (blockdata.p[1] - (bl.Size.X / 2)) + .5
				blockdata.p[2] = (blockdata.p[2] - (bl.Size.Y / 2)) + .5
				blockdata.p[3] = (blockdata.p[3] - (bl.Size.Z / 2)) + .5
				blockdata.s = {bl.Size.X, bl.Size.Y, bl.Size.Z}
			end
			
			blockdata.m = materials[bl.Material] or "plastic"
			blockdata.o = bl.Material.Name
			blockdata.sp = {}
			
			for _, v in ipairs(bl:GetChildren()) do
				if v.Name == "Spray" then
					table.insert(blockdata.sp, {v.Face.Name, v.Image.Image, string.gsub(v.Label.Text, '"', '\"')})
				end
			end
		end
		return blockdata
	end

	-- Internal Save Function
	local function save_build(file_path, players_list)
		if type(players_list) ~= "table" or #players_list == 0 then
			return
		end
		
		local builddata = {}
		
		for _, player in ipairs(players_list) do
			if typeof(player) == "Instance" and player:IsA("Player") then
				local target_folder = workspace.Bricks:FindFirstChild(player.Name)
				if target_folder then
					for _, v in ipairs(target_folder:GetChildren()) do
						if v:IsA("BasePart") then
							table.insert(builddata, saveblock(v))
						end
					end
				end
			end
		end
		
		if #builddata > 0 then
			local json_str = http:JSONEncode(builddata)
			local base_path = file_path:gsub("%.json$", ""):gsub("%.lz4$", "")
			
			if lz4compress and lz4decompress then
				writefile(base_path .. ".lz4", lz4compress(json_str, 1))
			else
				writefile(base_path .. ".json", json_str)
			end
		end
	end

	-- AutoBuilder Engine Class
	local AutoBuilder = {}
	AutoBuilder.__index = AutoBuilder

	function AutoBuilder:settings(new_settings)
		for k, v in pairs(new_settings) do
			self.opts[k] = v
			if k == "resizewait" then self.resizewait = v end
			if k == "offset" then self.offset = v end
			if k == "historymax" then self.historymax = v end
		end
	end

	function AutoBuilder:stop()
		self.stopped = true
		if self.conn then
			self.conn:Disconnect()
			self.conn = nil
		end
	end

	function AutoBuilder:start()
		self.stopped = false
		local success, file_content = pcall(readfile, self.file_path)
		if not success then return end
		
		local data_str
		if self.file_path:match("%.lz4$") then
			if lz4decompress then
				data_str = lz4decompress(file_content, 1)
			else
				return nil
			end
		else
			data_str = file_content
		end
		
		if type(data_str) ~= "string" then return end
		
		local decode_success, data = pcall(function() return http:JSONDecode(data_str) end)
		if not decode_success or not data then return end
		
		for _, v in ipairs(data) do
			if self.stopped then break end
			
			local posses = (v.p or v.pos)
			local pos = CFrame.new(posses[1], posses[2], posses[3]).Position + self.offset
			
			local mat_str = v.m or v.mat
			local color = Color3.fromRGB(unpack(v.c or v.color))
			local size_data = v.s or v.size
			local bsize_vec = size_data and Vector3.new(unpack(size_data)) or nil
			local texture = swappedmaterials[mat_str]
			
			local origmat = v.o or v.origmat
			local sprays = v.sp or v.sprayed
			local anchored = v.a or v.anchored
			local collide = v.cc or v.collide
			
			self:_buildblock(pos, texture, color, nil, bsize_vec, origmat, sprays, anchored, collide)
		end
	end

	function AutoBuilder:_buildblock(pos, texture, color, bsize, bsizev3, origmat, sprays, anchored, collide)
		task.wait(0.001)
		if anchored == nil then anchored = true end
		if collide == nil then collide = true end
		
		local needsresize = false
		
		if bsize == nil then
			bsize = "normal"
			if bsizev3 ~= nil and (bsizev3.X ~= mult or bsizev3.Y ~= mult or bsizev3.Z ~= mult) then
				bsize = "detailed"
			elseif bsizev3 ~= nil and (bsizev3.X == mult and bsizev3.Y == mult and bsizev3.Z == mult) then
				bsize = "normal"
			end
			
			if bsizev3 == nil and (bsize ~= "detailed") then
				bsize = "detailed"
				needsresize = true
				bsizev3 = Vector3.new(4, 4, 4)
				pos = Vector3.new((pos.X - (bsizev3.X / 2)) + .5, (pos.Y - (bsizev3.Y / 2)) + .5, (pos.Z - (bsizev3.Z / 2)) + .5)
			end
		end
		
		pos = snap(pos)
		self.built = false
		self.childcube = nil
		
		local build_tool = self.fetch_tools("Build")
		fire_tool(build_tool, workspace.Terrain, Enum.NormalId.Top, pos, bsize)
		
		local c = 0
		repeat
			c = c + 1
			build_tool = self.fetch_tools("Build")
			fire_tool(build_tool, workspace.Terrain, Enum.NormalId.Top, pos, bsize)
			if self.opts.tp and localplr.Character and localplr.Character:FindFirstChild("HumanoidRootPart") then
				localplr.Character.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 6, 0))
			end
			task.wait(0.1)
		until (self.built == true and self.childcube) or self.stopped == true or c > 200
		
		self.built = false
		c = 0
		local child = self.childcube
		
		if child and color and (child.Color ~= color or child.Material ~= texture) or texture then
			local ppos = child.Position + child.Size / 2
			local paint_mode = "color"
			if texture ~= nil then
				paint_mode = (color == nil) and "material" or "both \u{1F91D}"
			end
			c = 0
			repeat
				c = c + 1
				local paint_tool = self.fetch_tools("Paint")
				fire_tool(paint_tool, child, Enum.NormalId.Top, ppos, paint_mode, color, texture or "tiles", "")
				if self.opts.tp and localplr.Character and localplr.Character:FindFirstChild("HumanoidRootPart") then
					localplr.Character.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 6, 0))
				end
				task.wait(0.2)
			until not child or not child.Parent or child.Color == color or (texture and child.Material == Enum.Material[origmat]) or self.stopped or c > 200
		end
		
		if child and child.Anchored ~= anchored then
			local ppos = child.Position + child.Size / 2
			c = 0
			repeat
				c = c + 1
				local paint_tool = self.fetch_tools("Paint")
				fire_tool(paint_tool, child, Enum.NormalId.Top, ppos, "material", nil, "anchor", "")
				task.wait(1)
			until not child or not child.Parent or child.Anchored == anchored or self.stopped or c > 20
		end
		
		if child and child.CanCollide ~= collide then
			local ppos = child.Position + child.Size / 2
			c = 0
			repeat
				c = c + 1
				local paint_tool = self.fetch_tools("Paint")
				fire_tool(paint_tool, child, Enum.NormalId.Top, ppos, "material", nil, "collide", "")
				task.wait(1)
			until not child or not child.Parent or child.CanCollide == collide or self.stopped or c > 20
		end
		
		if child and sprays then
			for _, sp in ipairs(sprays) do
				local paint_tool = self.fetch_tools("Paint")
				fire_tool(paint_tool, child, Enum.NormalId[sp[1]], child.Position + Vector3.new(1, 0, 0), "material", nil, "spray", sp[3])
				task.wait(0.5)
			end
		end
		
		if child and bsizev3 and ((bsizev3.X ~= mult or bsizev3.Y ~= mult or bsizev3.Z ~= mult) or needsresize) then
			local shape_tool = self.fetch_tools("Shape")
			local function resize_axis(axis_normal, axis_name, target_size)
				c = 0
				if child and child.Size[axis_name] ~= target_size then
					repeat
						c = c + 1
						local curr_pos = child.Position + child.Size / 2
						local mode = child.Size[axis_name] > target_size and "decrease" or "increase"
						shape_tool = self.fetch_tools("Shape")
						fire_tool(shape_tool, child, axis_normal, curr_pos, mode)
						task.wait(self.resizewait)
					until not child or not child.Parent or child.Size[axis_name] == target_size or (mode == "decrease" and child.Size[axis_name] <= 1) or self.stopped or c > (target_size * 3) / self.resizewait
				end
			end
			resize_axis(Enum.NormalId.Right, "X", bsizev3.X)
			resize_axis(Enum.NormalId.Top, "Y", bsizev3.Y)
			resize_axis(Enum.NormalId.Back, "Z", bsizev3.Z)
		end
		
		self.childcube = nil
	end
	
	local function auto_build(file_path, settings, fetch_tools)
		local self = setmetatable({}, AutoBuilder)
		self.file_path = file_path
		self.opts = settings or {}
		self.fetch_tools = fetch_tools
		self.stopped = false
		
		self.history = {}
		self.historymax = self.opts.historymax or 400
		self.historynum = 0
		self.childcube = nil
		self.built = false
		
		self.resizewait = self.opts.resizewait or 0.4
		self.offset = self.opts.offset or Vector3.zero
		
		local container = workspace.Bricks:FindFirstChild(localplr.Name) or workspace.Bricks
		self.conn = container.ChildAdded:Connect(function(child)
			self.childcube = child
			self.historynum = self.historynum + 1
			if self.historynum > self.historymax then
				self.historynum = 1
			end
			self.history[self.historynum] = child
			self.built = true
		end)
		
		return self
	end
	
	return {
		auto_build = auto_build,
		save_build = save_build
	}
end

return builder