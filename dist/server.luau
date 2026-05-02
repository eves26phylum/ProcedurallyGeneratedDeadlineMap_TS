-- bundled with deadline-ts (no you cannot use rbxts modules right now)
function assert(condition, messageIfFalse)
    if not condition then error(messageIfFalse or _VERSION.." assertion error") end
end
local function dot_wrap(obj)
    if obj == nil then return nil end
    local proxy = {}
    for k, v in pairs(obj) do
        if type(v) == "function" then
            proxy[k] = function(_, ...) return v(...) end
        else
            proxy[k] = v
        end
    end
    return proxy
end

local function dot_wrap_array(arr)
	if arr == nil then return nil end
	local result = {}
	for i, v in ipairs(arr) do
		result[i] = dot_wrap(v)
	end
	return result
end

local _players = players
players = {
	get = function(name) return dot_wrap(_players.get(name)) end,
	get_all = function() return dot_wrap_array(_players.get_all()) end,
	get_alive = function() return dot_wrap_array(_players.get_alive()) end,
	get_by_userid = function(id) return dot_wrap(_players.get_by_userid(id)) end,
	reset_ragdolls = function() return _players.reset_ragdolls() end,
}

local _tags = tags
tags = {
	get_tags = function() return _tags.get_tags() end,
	get_tagged = function(tag) return dot_wrap_array(_tags.get_tagged(tag)) end,
	get_all_tagged = function(tag) return dot_wrap_array(_tags.get_all_tagged(tag)) end,
}

local _query = query
query = {
	create_raycast_params = function() return dot_wrap(_query.create_raycast_params()) end,
	raycast = function(origin, direction, params) return _query.raycast(origin, direction, params) end,
}

local _create_instance = create_instance
create_instance = function(className, parent) return dot_wrap(_create_instance(className, parent)) end
local old_require = require
local __modulesFolder = {}
local __modulesCachedValues = {}

local function newFakeInstance(pathSegs)
	pathSegs = pathSegs or {}
	local inst = {}
	inst.__path = pathSegs
	inst.Name = pathSegs[#pathSegs] or ""
	inst.WaitForChild = function(self, name)
		local newPath = {}
		for i = 1, #pathSegs do newPath[i] = pathSegs[i] end
		newPath[#newPath + 1] = name
		return newFakeInstance(newPath)
	end
	if #pathSegs > 1 then
		local parentSegs = {}
		for i = 1, #pathSegs - 1 do parentSegs[i] = pathSegs[i] end
		inst.Parent = newFakeInstance(parentSegs)
	else
		inst.Parent = {
			__path = {},
			Name = "",
			WaitForChild = function(self, name) return newFakeInstance({ name }) end,
		}
		inst.is_fake_instance = true
	end
	return inst
end
local old_game = game
local game = {
	GetService = function(self, name)
		local inst = newFakeInstance({ name })
		inst.__isService = true
		return inst
	end,
}

local require = function(_ref)
	return {
		import = function(_ctx, startModule, ...)
			local current = startModule.__isService and newFakeInstance({}) or startModule
			for i = 1, select("#", ...) do
				local seg = select(i, ...)
				if seg ~= "TS" then
					current = current:WaitForChild(seg)
				end
			end

			local pathSegs = current.__path
			local cacheKey = table.concat(pathSegs, "\0")

			if __modulesCachedValues[cacheKey] ~= nil then
				return __modulesCachedValues[cacheKey]
			end

			local folder = __modulesFolder
			for _, seg in ipairs(pathSegs) do
				folder = folder[seg]
				if folder == nil then
					error("TS.import: module not found at path \"" .. table.concat(pathSegs, "/") .. "\"")
				end
			end

			local result = folder()
			__modulesCachedValues[cacheKey] = result
			return result
		end,
	}
end

__modulesFolder["DepthFirstMazeSearch"] = function()
	local script
	script = newFakeInstance({"DepthFirstMazeSearch"})
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local fisherYatesShuffle = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Util").fisherYatesShuffle
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	-- The comment above is required for deadline-ts to parse this code correctly. You place the comment above this comment to define the end of all import statements.
	local function mazePassageKey(firstColumn, firstRow, secondColumn, secondRow)
		if firstColumn < secondColumn or (firstColumn == secondColumn and firstRow < secondRow) then
			return `{firstColumn},{firstRow}|{secondColumn},{secondRow}`
		end
		return `{secondColumn},{secondRow}|{firstColumn},{firstRow}`
	end
	local function cellKey(gridColumn, gridRow)
		return `{gridColumn},{gridRow}`
	end
	local DepthFirstMazeSearch
	do
		DepthFirstMazeSearch = setmetatable({}, {
			__tostring = function()
				return "DepthFirstMazeSearch"
			end,
		})
		DepthFirstMazeSearch.__index = DepthFirstMazeSearch
		function DepthFirstMazeSearch.new(...)
			local self = setmetatable({}, DepthFirstMazeSearch)
			return self:constructor(...) or self
		end
		function DepthFirstMazeSearch:constructor(shuffleFunction)
			if shuffleFunction == nil then
				shuffleFunction = fisherYatesShuffle
			end
			self.shuffleFunction = shuffleFunction
		end
		function DepthFirstMazeSearch:generatePassages(hasRoom, startColumn, startRow)
			local visitedCells = {}
			local passages = {}
			self:search(hasRoom, startColumn, startRow, visitedCells, passages)
			return passages
		end
		function DepthFirstMazeSearch:search(hasRoom, gridColumn, gridRow, visitedCells, passages)
			local adjacencyDeltas = { { 0, -1 }, { 0, 1 }, { 1, 0 }, { -1, 0 } }
			local _visitedCells = visitedCells
			local _arg0 = cellKey(gridColumn, gridRow)
			_visitedCells[_arg0] = true
			for _, _binding in self.shuffleFunction(adjacencyDeltas) do
				local gridColumnDelta = _binding[1]
				local gridRowDelta = _binding[2]
				local neighborColumn = gridColumn + gridColumnDelta
				local neighborRow = gridRow + gridRowDelta
				if not hasRoom(neighborColumn, neighborRow) then
					continue
				end
				local _visitedCells_1 = visitedCells
				local _arg0_1 = cellKey(neighborColumn, neighborRow)
				if _visitedCells_1[_arg0_1] ~= nil then
					continue
				end
				local _passages = passages
				local _arg0_2 = mazePassageKey(gridColumn, gridRow, neighborColumn, neighborRow)
				_passages[_arg0_2] = true
				self:search(hasRoom, neighborColumn, neighborRow, visitedCells, passages)
			end
		end
	end
	return {
		mazePassageKey = mazePassageKey,
		DepthFirstMazeSearch = DepthFirstMazeSearch,
	}

end

__modulesFolder["EgoMoose"] = function()
	local script
	script = newFakeInstance({"EgoMoose"})
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	-- thanks from EgoMoose
	-- https://github.com/EgoMoose/Articles
	-- saved some time
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	local EgoMoose = {}
	do
		local _container = EgoMoose
		local function draw3dTriangle(a, b, c)
			local _b = b
			local _a = a
			local ab = _b - _a
			local _c = c
			local _a_1 = a
			local ac = _c - _a_1
			local _c_1 = c
			local _b_1 = b
			local bc = _c_1 - _b_1
			local abd = ab:Dot(ab)
			local acd = ac:Dot(ac)
			local bcd = bc:Dot(bc)
			if abd > acd and abd > bcd then
				c, a = a, c
			elseif acd > bcd and acd > abd then
				a, b = b, a
			end
			local _b_2 = b
			local _a_2 = a
			ab = _b_2 - _a_2
			local _c_2 = c
			local _a_3 = a
			ac = _c_2 - _a_3
			local _c_3 = c
			local _b_3 = b
			bc = _c_3 - _b_3
			local right = ac:Cross(ab).Unit
			local up = bc:Cross(right).Unit
			local back = bc.Unit
			local height = math.abs(ab:Dot(up))
			local _object = {
				Size = Vector3.new(0, height, math.abs(ab:Dot(back))),
			}
			local _left = "CFrame"
			local _a_4 = a
			local _b_4 = b
			_object[_left] = CFrame.fromMatrix((_a_4 + _b_4) / 2, right, up, back)
			local _object_1 = {
				Size = Vector3.new(0, height, math.abs(ac:Dot(back))),
			}
			local _left_1 = "CFrame"
			local _a_5 = a
			local _c_4 = c
			_object_1[_left_1] = CFrame.fromMatrix((_a_5 + _c_4) / 2, right * (-1), up, back * (-1))
			return { _object, _object_1 }
		end
		_container.draw3dTriangle = draw3dTriangle
		local function getBarycentricHeight(vertexA, vertexB, vertexC, samplePoint)
			local projectedDenominator = (vertexB.Z - vertexC.Z) * (vertexA.X - vertexC.X) + (vertexC.X - vertexB.X) * (vertexA.Z - vertexC.Z)
			if projectedDenominator == 0 then
				return { nil, 0, 0, 0 }
			end
			local weightA = ((vertexB.Z - vertexC.Z) * (samplePoint.X - vertexC.X) + (vertexC.X - vertexB.X) * (samplePoint.Y - vertexC.Z)) / projectedDenominator
			local weightB = ((vertexC.Z - vertexA.Z) * (samplePoint.X - vertexC.X) + (vertexA.X - vertexC.X) * (samplePoint.Y - vertexC.Z)) / projectedDenominator
			local weightC = 1 - weightA - weightB
			local interpolatedHeight = weightA * vertexA.Y + weightB * vertexB.Y + weightC * vertexC.Y
			return { interpolatedHeight, weightA, weightB, weightC }
		end
		_container.getBarycentricHeight = getBarycentricHeight
	end
	return {
		EgoMoose = EgoMoose,
	}

end

__modulesFolder["NuristanBuildings"] = function()
	local script
	script = newFakeInstance({"NuristanBuildings"})
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local Biome = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "biome").Biome
	local assign = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Util").assign
	local humanConfig = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "humanConfig").default
	local EgoMoose = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "EgoMoose").EgoMoose
	local ProceduralRoomGrid = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "ProceduralRoomGeneration").ProceduralRoomGrid
	local DepthFirstMazeSearch = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "DepthFirstMazeSearch").DepthFirstMazeSearch
	local fisherYatesShuffle = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Util").fisherYatesShuffle
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	-- The comment above is required for deadline-ts to parse this code correctly. You place the comment above this comment to define the end of all import statements.
	-- If you want to write on this program, you will follow the following Terms of Service. Failure to obey with the ToS is an illegal action and can lead to severe consequences.
	-- Here is the Gigachad Terms of Service 2000 Iteration 0
	--[[
		 Terms of Service
	
		SECTION 1 - DO NOT BE LAZY:
		- Make things extensible and modular as possible, then think about you can extend this in the future. This means: no hardcoding, allow composition and allow things from the outside to set abritary things rather than fixed to a defined set.
		- Never abbreviate variable names. EVER: They must be readable in English, and understandable. Include all details and context inside that variable name. More details is better. Utilise camelCase.
		- NEVER. EVER. USE. ALIGNMENT SPACES—They're ugly, ignored by beautifiers, and no one ever uses them.
		Examples of this bad practice:
		const abanana = dog;
		const ba      = dog2;
		const fucku   = fuckingdog;
		Examples of a good practice:
		const abanana = dog;
		const ba = dog2;
		const fucku = fuckingdog;
		- Always do the best implementation you can. Never skip out on things or do simpler versions. This is very important. If you do become lazy and do a worse implementation, problems in the future can happen because of that.
	
		SECTION 2 - CONSISTENCY AND CODE STYLE:
		- Use existing code style and don't add weird spaces between stuff like assigment statements.
		- Embrace never-nesting practices—Use early guard clauses and remember continue statement exists.
		- Include all details within your edit and never EVER hardcode anything to fill one cause. Other things from outside must be able to edit your cause in a different way to the extend I could add 50 dogs on top of a simple metal reflective box object and turn the box into a polygon that flashes rainbow every two seconds before turning into a yellow dog as an example.
		- Split concerns across multiple things—Don't make one thing handle it all—Allow for us to retrieve all values from data instead of just stealing one value and running away—This is for extensibility in the future. 
		Example of bad practice:
		const ax = (DogArrayData as {dogNameTag: string} & number[])[0];
		Example of good practice:
		const customDogArray: dogArrayType = DogArrayData;
		const firstElementInDogArray = customDogArray[0];
		- Inheritance is mostly outdated—so unless you're directly touching TypeScript stuff (like classes) or something, a pattern of composition is preferred unless you are forced to use it.
		- A space around each side of an arithmetic operator is generally advised.
	
		SECTION 3 - TYPESCRIPT BEST PRACTICES:
		- If possible, never use `as` statements in TypeScript—This is considered terrible practice.
		- Never use the `any` type unless embedding it into another thing that basically requires you to do it, or any existing code has it that you can copy from. Example: assign statement. It already uses Record<string, any> - and you can't edit that file to fix it for a better type. Then, you would use Record<string, any>.
		- If there is a more suitable type available—use it. Example: Record<string, unknown> could lead to errors when trying to do {dog: new Vector3()}; A better practice would to usePartial<InstanceProperties<BasePart>> or InstanceProperties<BasePart> depending on the context.
	
		SECTION 4 - COMMON SENSE AND BEST PRACTICES:
		- If something you suspect might be wrong—don't adapt your code on that. Do not build on mistakes; Do not make your code based on that mistake—Spot that it's a mistake and if you have been granted permission to edit that part, edit to fix. Otherwise, just inform us.
		- Don't truncate things—ugly.
		- Don't add comments that point the obvious. Unless you're explaining some nuanced thing or detail, maybe an algorithm — Just don't.
		- Don't use outdated APIs or versions—Always refer to newer alternatives rather than using deprecated things in new code.
		- If you can avoid an else statement using stuff like lookup tables or continue statement, do it.
	
		By editing on this file, you agree to the terms of conditions. Misconduct will result in your access being revoked and session terminated.
	
		Think of it like this:
		┌─────────────────────────────────────────────┐
		│             Visual Studio Code              │
		├─────────────────────────────────────────────┤
		│ This code is ass. Session Terminated.       │
		│                                             │
		│ [I WILL FIX THIS]                           │
		└─────────────────────────────────────────────┘
	
	]]
	local ALL_WALL_FACES = { "north", "south", "east", "west" }
	local faceAxisConfigMap = {
		north = {
			faceLocalOffset = function(plateSize, thickness)
				return -(plateSize.Z / 2 - thickness / 2)
			end,
			wallLength = function(plateSize)
				return plateSize.X
			end,
			buildLocalCFrame = function(lengthAxisLocalPos, localHeightCenter, faceLocalOffset)
				return CFrame.new(lengthAxisLocalPos, localHeightCenter, faceLocalOffset)
			end,
			buildSegmentSize = function(segmentLength, segmentHeight, thickness)
				return Vector3.new(segmentLength, segmentHeight, thickness)
			end,
		},
		south = {
			faceLocalOffset = function(plateSize, thickness)
				return plateSize.Z / 2 - thickness / 2
			end,
			wallLength = function(plateSize)
				return plateSize.X
			end,
			buildLocalCFrame = function(lengthAxisLocalPos, localHeightCenter, faceLocalOffset)
				return CFrame.new(lengthAxisLocalPos, localHeightCenter, faceLocalOffset)
			end,
			buildSegmentSize = function(segmentLength, segmentHeight, thickness)
				return Vector3.new(segmentLength, segmentHeight, thickness)
			end,
		},
		east = {
			faceLocalOffset = function(plateSize, thickness)
				return plateSize.X / 2 - thickness / 2
			end,
			wallLength = function(plateSize)
				return plateSize.Z
			end,
			buildLocalCFrame = function(lengthAxisLocalPos, localHeightCenter, faceLocalOffset)
				return CFrame.new(faceLocalOffset, localHeightCenter, lengthAxisLocalPos)
			end,
			buildSegmentSize = function(segmentLength, segmentHeight, thickness)
				return Vector3.new(thickness, segmentHeight, segmentLength)
			end,
		},
		west = {
			faceLocalOffset = function(plateSize, thickness)
				return -(plateSize.X / 2 - thickness / 2)
			end,
			wallLength = function(plateSize)
				return plateSize.Z
			end,
			buildLocalCFrame = function(lengthAxisLocalPos, localHeightCenter, faceLocalOffset)
				return CFrame.new(faceLocalOffset, localHeightCenter, lengthAxisLocalPos)
			end,
			buildSegmentSize = function(segmentLength, segmentHeight, thickness)
				return Vector3.new(thickness, segmentHeight, segmentLength)
			end,
		},
	}
	local function computeSolidWallFaceGeometry(plateSize, wallConfig, face)
		local faceConfig = faceAxisConfigMap[face]
		local faceOffset = faceConfig.faceLocalOffset(plateSize, wallConfig.thickness)
		local wallLength = faceConfig.wallLength(plateSize)
		local localHeightCenter = wallConfig.height / 2
		return { {
			localCFrame = faceConfig.buildLocalCFrame(0, localHeightCenter, faceOffset),
			size = faceConfig.buildSegmentSize(wallLength, wallConfig.height, wallConfig.thickness),
		} }
	end
	local function computeDoorwayWallFaceGeometry(plateSize, wallConfig, doorwayData, face)
		local faceConfig = faceAxisConfigMap[face]
		local faceOffset = faceConfig.faceLocalOffset(plateSize, wallConfig.thickness)
		local wallLength = faceConfig.wallLength(plateSize)
		local sillHeight = doorwayData.bottomOffset
		local leftSegmentWidth = (wallLength - doorwayData.width) / 2 + doorwayData.offsetAlongWall
		local rightSegmentWidth = (wallLength - doorwayData.width) / 2 - doorwayData.offsetAlongWall
		local headerHeight = wallConfig.height - doorwayData.height - sillHeight
		local leftSegmentLengthCenter = -(wallLength / 2) + leftSegmentWidth / 2
		local rightSegmentLengthCenter = wallLength / 2 - rightSegmentWidth / 2
		local segments = { {
			localCFrame = faceConfig.buildLocalCFrame(leftSegmentLengthCenter, wallConfig.height / 2, faceOffset),
			size = faceConfig.buildSegmentSize(leftSegmentWidth, wallConfig.height, wallConfig.thickness),
		}, {
			localCFrame = faceConfig.buildLocalCFrame(rightSegmentLengthCenter, wallConfig.height / 2, faceOffset),
			size = faceConfig.buildSegmentSize(rightSegmentWidth, wallConfig.height, wallConfig.thickness),
		} }
		if headerHeight > 0 then
			local headerLocalHeightCenter = sillHeight + doorwayData.height + headerHeight / 2
			local _arg0 = {
				localCFrame = faceConfig.buildLocalCFrame(doorwayData.offsetAlongWall, headerLocalHeightCenter, faceOffset),
				size = faceConfig.buildSegmentSize(doorwayData.width, headerHeight, wallConfig.thickness),
			}
			table.insert(segments, _arg0)
		end
		if sillHeight > 0 then
			local _arg0 = {
				localCFrame = faceConfig.buildLocalCFrame(doorwayData.offsetAlongWall, sillHeight / 2, faceOffset),
				size = faceConfig.buildSegmentSize(doorwayData.width, sillHeight, wallConfig.thickness),
			}
			table.insert(segments, _arg0)
		end
		return segments
	end
	local function instantiateWallSegments(plateCFrame, segments, partProps, parent, adapter)
		for _, segment in segments do
			local _plateCFrame = plateCFrame
			local _localCFrame = segment.localCFrame
			local worldCFrame = _plateCFrame * _localCFrame
			local wallPart = adapter.newInstance("Part")
			adapter.setProperty(wallPart, "CFrame", worldCFrame)
			adapter.setProperty(wallPart, "Size", segment.size)
			adapter.setProperty(wallPart, "Anchored", true)
			assign(wallPart, partProps, adapter.setProperty)
			adapter.setProperty(wallPart, "Parent", parent)
		end
	end
	local SniperWindowRoomHandler
	do
		SniperWindowRoomHandler = setmetatable({}, {
			__tostring = function()
				return "SniperWindowRoomHandler"
			end,
		})
		SniperWindowRoomHandler.__index = SniperWindowRoomHandler
		function SniperWindowRoomHandler.new(...)
			local self = setmetatable({}, SniperWindowRoomHandler)
			return self:constructor(...) or self
		end
		function SniperWindowRoomHandler:constructor(buildings, sniperWindowDoorway)
			self.priority = 10
			self.buildings = buildings
			self.sniperWindowDoorway = sniperWindowDoorway
		end
		function SniperWindowRoomHandler:hasExteriorFace(faceData)
			for _, face in ALL_WALL_FACES do
				if faceData[face].state == "exteriorWall" then
					return true
				end
			end
			return false
		end
		function SniperWindowRoomHandler:tryGenerate(roomCFrame, faceData)
			if not SniperWindowRoomHandler:hasExteriorFace(faceData) then
				return false
			end
			local roomSize = self.buildings.config.roomProps.RoomSize
			self.buildings:instantiateRoomShell(roomCFrame)
			for _, face in ALL_WALL_FACES do
				local faceDatum = faceData[face]
				if faceDatum.state == "empty" then
					continue
				end
				if faceDatum.state == "exteriorWall" then
					self.buildings:makeWallWithDoorway(roomCFrame, roomSize, face, {
						doorway = self.sniperWindowDoorway,
					})
					continue
				end
				if faceDatum.state == "doorway" then
					self.buildings:makeWallWithDoorway(roomCFrame, roomSize, face)
					continue
				end
				self.buildings:makeWallWithoutDoorway(roomCFrame, roomSize, face)
			end
			return true
		end
	end
	local LivingRoomHandler
	do
		LivingRoomHandler = setmetatable({}, {
			__tostring = function()
				return "LivingRoomHandler"
			end,
		})
		LivingRoomHandler.__index = LivingRoomHandler
		function LivingRoomHandler.new(...)
			local self = setmetatable({}, LivingRoomHandler)
			return self:constructor(...) or self
		end
		function LivingRoomHandler:constructor(buildings)
			self.priority = 0
			self.buildings = buildings
		end
		function LivingRoomHandler:tryGenerate(roomCFrame, faceData)
			self.buildings:createStandardRoom(roomCFrame, faceData)
			return true
		end
	end
	local NuristanBuildings
	do
		local super = Biome
		NuristanBuildings = setmetatable({}, {
			__tostring = function()
				return "NuristanBuildings"
			end,
			__index = super,
		})
		NuristanBuildings.__index = NuristanBuildings
		function NuristanBuildings.new(...)
			local self = setmetatable({}, NuristanBuildings)
			return self:constructor(...) or self
		end
		function NuristanBuildings:constructor(adapterToUse, translateTerrain, config, parent)
			super.constructor(self, adapterToUse)
			self.priority = 100
			self.config = config
			self.translateTerrain = translateTerrain
			self.parent = parent
			self.name = "NuristanBuildings"
		end
		function NuristanBuildings:mergeConfig(overrides)
			local _object = table.clone(self.config)
			setmetatable(_object, nil)
			local merged = _object
			assign(merged, overrides)
			return merged
		end
		function NuristanBuildings:makeWallWithoutDoorway(roomPlateCFrame, roomPlateSize, face, configOverrides)
			local resolvedConfig = if configOverrides ~= nil then self:mergeConfig(configOverrides) else self.config
			local segments = computeSolidWallFaceGeometry(roomPlateSize, resolvedConfig.wall, face)
			instantiateWallSegments(roomPlateCFrame, segments, resolvedConfig.wallPartProps, self.parent, self.adapter)
		end
		function NuristanBuildings:makeWallWithDoorway(roomPlateCFrame, roomPlateSize, face, configOverrides)
			local resolvedConfig = if configOverrides ~= nil then self:mergeConfig(configOverrides) else self.config
			local segments = computeDoorwayWallFaceGeometry(roomPlateSize, resolvedConfig.wall, resolvedConfig.doorway, face)
			instantiateWallSegments(roomPlateCFrame, segments, resolvedConfig.wallPartProps, self.parent, self.adapter)
		end
		function NuristanBuildings:instantiateRoomShell(roomCFrame, configOverrides)
			local resolvedConfig = if configOverrides ~= nil then self:mergeConfig(configOverrides) else self.config
			local roomSize = resolvedConfig.roomProps.RoomSize
			local roomPlate = self.adapter.newInstance("Part")
			self.adapter.setProperty(roomPlate, "CFrame", roomCFrame)
			self.adapter.setProperty(roomPlate, "Size", roomSize)
			self.adapter.setProperty(roomPlate, "Anchored", true)
			assign(roomPlate, resolvedConfig.wallPartProps, self.adapter.setProperty)
			self.adapter.setProperty(roomPlate, "Parent", self.parent)
			local roomRoof = self.adapter.newInstance("Part")
			local _adapter = self.adapter
			local _roomCFrame = roomCFrame
			local _upVector = roomCFrame.UpVector
			local _height = resolvedConfig.wall.height
			local _upVector_1 = roomCFrame.UpVector
			local _arg0 = roomSize.Y / 2
			_adapter.setProperty(roomRoof, "CFrame", _roomCFrame + (_upVector * _height + (_upVector_1 * _arg0)))
			self.adapter.setProperty(roomRoof, "Size", roomSize)
			self.adapter.setProperty(roomRoof, "Name", "RoomRoof")
			self.adapter.setProperty(roomRoof, "Anchored", true)
			assign(roomRoof, resolvedConfig.wallPartProps, self.adapter.setProperty)
			self.adapter.setProperty(roomRoof, "Parent", self.parent)
		end
		function NuristanBuildings:createStandardRoom(roomCFrame, faceData, configOverrides)
			self:instantiateRoomShell(roomCFrame, configOverrides)
			local resolvedConfig = if configOverrides ~= nil then self:mergeConfig(configOverrides) else self.config
			local roomSize = resolvedConfig.roomProps.RoomSize
			for _, face in ALL_WALL_FACES do
				local faceDatum = faceData[face]
				if faceDatum.state == "empty" then
					continue
				end
				if faceDatum.state == "doorway" then
					self:makeWallWithDoorway(roomCFrame, roomSize, face, configOverrides)
					continue
				end
				self:makeWallWithoutDoorway(roomCFrame, roomSize, face, configOverrides)
			end
		end
		function NuristanBuildings:createSingleHouse(houseCFrame, vertices)
			local registeredRoomTypeNames = { "LivingRoom" }
			local proceduralGrid = ProceduralRoomGrid.new(self.config.roomGeneration, registeredRoomTypeNames, DepthFirstMazeSearch.new(fisherYatesShuffle), fisherYatesShuffle)
			local roomHandlers = { SniperWindowRoomHandler.new(self, self.config.sniperWindowDoorway), LivingRoomHandler.new(self) }
			local entranceHeightResult = EgoMoose.getBarycentricHeight(vertices[1], vertices[2], vertices[3], Vector2.new(houseCFrame.X, houseCFrame.Z))
			if entranceHeightResult[1] == nil then
				return nil
			end
			local _rotation = houseCFrame.Rotation
			local _vector3 = Vector3.new(houseCFrame.Position.X, 0, houseCFrame.Position.Z)
			local baseCFrame = _rotation + _vector3
			local _vector3_1 = Vector3.new(0, entranceHeightResult[1], 0)
			local entranceCFrame = baseCFrame + _vector3_1
			local roomSize = self.config.roomProps.RoomSize
			proceduralGrid:forEachRoom(function(gridColumn, gridRow, faceData)
				local _cFrame = CFrame.new(roomSize.X * gridColumn, 0, roomSize.Z * gridRow)
				local roomCFrame = entranceCFrame * _cFrame
				for _, handler in roomHandlers do
					if handler:tryGenerate(roomCFrame, faceData) then
						break
					end
				end
			end)
		end
		function NuristanBuildings:operateOnThisTriangleInstance(data, trianglePair, verticesForTriangles)
			local orientation = trianglePair[1].Orientation
			local middlePos = trianglePair[1].CFrame:Lerp(trianglePair[2].CFrame, 0.5)
			local translatedOrientationForStructurePlacement = self.translateTerrain:Translate(orientation)
			local degreesTiltedOfSteepness = self.translateTerrain:GetSteepnessInDegrees(CFrame.fromEulerAnglesXYZ(math.rad(translatedOrientationForStructurePlacement.X), math.rad(translatedOrientationForStructurePlacement.Y), math.rad(translatedOrientationForStructurePlacement.Z)))
			local isALivableDegree = degreesTiltedOfSteepness < humanConfig.maxLivableSteepness
			if not isALivableDegree then
				return nil
			end
			-- const part = this.adapter.newInstance("Part");
			-- this.adapter.setProperty(part, "CFrame", middlePos);
			-- this.adapter.setProperty(part, "Orientation", translatedOrientationForStructurePlacement);
			-- this.adapter.setProperty(part, "Parent", this.parent);
			local rotationalCFrame = CFrame.fromEulerAnglesXYZ(math.rad(translatedOrientationForStructurePlacement.X), math.rad(translatedOrientationForStructurePlacement.Y + math.random(0, 360)), math.rad(translatedOrientationForStructurePlacement.Z))
			local _self = self
			local _position = middlePos.Position
			_self:createSingleHouse(rotationalCFrame + _position, verticesForTriangles)
		end
		function NuristanBuildings:generate(yourSelf, yourCell)
			self:operateOnThisTriangleInstance(yourCell, yourCell.triangles[1], yourCell.verticesForTriangles[1])
			self:operateOnThisTriangleInstance(yourCell, yourCell.triangles[2], yourCell.verticesForTriangles[2])
		end
	end
	return {
		NuristanBuildings = NuristanBuildings,
	}

end

__modulesFolder["PerlinNoise"] = function()
	local script
	script = newFakeInstance({"PerlinNoise"})
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local function FUCKROBLOX(a)
		-- fuck roblox basically fucks roblox and also avoids integer noise
		if math.floor(a) == a then
			return a + 0.001
		end
		return a
	end
	local PerlinNoise
	do
		PerlinNoise = setmetatable({}, {
			__tostring = function()
				return "PerlinNoise"
			end,
		})
		PerlinNoise.__index = PerlinNoise
		function PerlinNoise.new(...)
			local self = setmetatable({}, PerlinNoise)
			return self:constructor(...) or self
		end
		function PerlinNoise:constructor()
		end
		function PerlinNoise:generate(scale, resolution, offset, exaggeratedness, lacunarity, persistence, octaves, POWER)
			local resolvedOffset = offset or Vector2.new(0, 0)
			local noiseMap = {}
			local minRaw = math.huge
			local maxRaw = -math.huge
			do
				local x = 0
				local _shouldIncrement = false
				while true do
					if _shouldIncrement then
						x += 1
					else
						_shouldIncrement = true
					end
					if not (x <= resolution.X) then
						break
					end
					do
						local y = 0
						local _shouldIncrement_1 = false
						while true do
							if _shouldIncrement_1 then
								y += 1
							else
								_shouldIncrement_1 = true
							end
							if not (y <= resolution.Y) then
								break
							end
							local offsetX = x + resolvedOffset.X
							local offsetY = y + resolvedOffset.Y
							local frequency = 1
							local amplitude = 1
							local noiseHeight = 0
							do
								local i = 0
								local _shouldIncrement_2 = false
								while true do
									if _shouldIncrement_2 then
										i += 1
									else
										_shouldIncrement_2 = true
									end
									if not (i < octaves) then
										break
									end
									local sampleX = (offsetX / scale) * frequency
									local sampleY = (offsetY / scale) * frequency
									local computedNoise = math.noise(FUCKROBLOX(sampleX), FUCKROBLOX(sampleY))
									local clampedNoise = computedNoise / 2 + 0.5
									noiseHeight += clampedNoise * amplitude
									amplitude *= persistence
									frequency *= lacunarity
								end
							end
							local endHeight = (noiseHeight ^ POWER) * exaggeratedness
							if endHeight < minRaw then
								minRaw = endHeight
							end
							if endHeight > maxRaw then
								maxRaw = endHeight
							end
							table.insert(noiseMap, endHeight)
						end
					end
				end
			end
			return noiseMap
		end
	end
	return {
		PerlinNoise = PerlinNoise,
	}

end

__modulesFolder["ProceduralRoomGeneration"] = function()
	local script
	script = newFakeInstance({"ProceduralRoomGeneration"})
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local mazePassageKey = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "DepthFirstMazeSearch").mazePassageKey
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	-- The comment above is required for deadline-ts to parse this code correctly. You place the comment above this comment to define the end of all import statements.
	local EXIT_ROOM_CELL_TYPE = "__exitRoom__"
	local ProceduralRoomGrid
	do
		ProceduralRoomGrid = setmetatable({}, {
			__tostring = function()
				return "ProceduralRoomGrid"
			end,
		})
		ProceduralRoomGrid.__index = ProceduralRoomGrid
		function ProceduralRoomGrid.new(...)
			local self = setmetatable({}, ProceduralRoomGrid)
			return self:constructor(...) or self
		end
		function ProceduralRoomGrid:constructor(generationConfig, registeredRoomTypeNames, mazeStrategy, shuffleFunction)
			self.shuffleFunction = shuffleFunction
			self.roomGrid = self:buildRoomGrid(generationConfig, registeredRoomTypeNames)
			local passages = mazeStrategy:generatePassages(function(gridColumn, gridRow)
				return self:hasRoom(gridColumn, gridRow)
			end, 0, 0)
			local mergedWalls = self:generateMergedWalls(passages, generationConfig.mergeWallChance)
			self.roomFaceDataMap = self:computeAllRoomFaceData(passages, mergedWalls)
		end
		function ProceduralRoomGrid:hasRoomInGrid(roomGrid, gridColumn, gridRow)
			local _result = roomGrid[gridColumn + 1]
			if _result ~= nil then
				_result = _result[gridRow + 1]
			end
			return not not (_result ~= "" and _result)
		end
		function ProceduralRoomGrid:hasRoom(gridColumn, gridRow)
			return ProceduralRoomGrid:hasRoomInGrid(self.roomGrid, gridColumn, gridRow)
		end
		function ProceduralRoomGrid:forEachRoom(callback)
			for gridColumn = 0, #self.roomGrid - 1 do
				local roomRow = self.roomGrid[gridColumn + 1]
				if not roomRow then
					continue
				end
				for gridRow = 0, #roomRow - 1 do
					if not self:hasRoom(gridColumn, gridRow) then
						continue
					end
					local _roomFaceDataMap = self.roomFaceDataMap
					local _arg0 = `{gridColumn},{gridRow}`
					local faceData = _roomFaceDataMap[_arg0]
					if not faceData then
						continue
					end
					callback(gridColumn, gridRow, faceData, self.roomGrid[gridColumn + 1][gridRow + 1])
				end
			end
		end
		function ProceduralRoomGrid:buildRoomGrid(generationConfig, registeredRoomTypeNames)
			local roomGrid = {}
			local targetRoomCount = generationConfig.minRooms + math.floor(math.random() * (generationConfig.maxRooms - generationConfig.minRooms + 1))
			roomGrid[1] = {}
			roomGrid[1][1] = EXIT_ROOM_CELL_TYPE
			local occupiedCells = { { 0, 0 } }
			local growthDirections = { { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } }
			while #occupiedCells < targetRoomCount do
				local _binding = occupiedCells[math.floor(math.random() * #occupiedCells) + 1]
				local sourceColumn = _binding[1]
				local sourceRow = _binding[2]
				local _binding_1 = self.shuffleFunction(growthDirections)[1]
				local gridColumnDelta = _binding_1[1]
				local gridRowDelta = _binding_1[2]
				local neighborColumn = sourceColumn + gridColumnDelta
				local neighborRow = sourceRow + gridRowDelta
				if neighborColumn < 0 or neighborRow < 0 then
					continue
				end
				if ProceduralRoomGrid:hasRoomInGrid(roomGrid, neighborColumn, neighborRow) then
					continue
				end
				if not roomGrid[neighborColumn + 1] then
					roomGrid[neighborColumn + 1] = {}
				end
				local assignedRoomType = registeredRoomTypeNames[math.floor(math.random() * #registeredRoomTypeNames) + 1]
				roomGrid[neighborColumn + 1][neighborRow + 1] = assignedRoomType
				local _arg0 = { neighborColumn, neighborRow }
				table.insert(occupiedCells, _arg0)
			end
			return roomGrid
		end
		function ProceduralRoomGrid:collectMergedWallsForCell(passages, mergedWalls, mergeWallChance, gridColumn, gridRow)
			local mergeCheckDirections = { { 0, 1 }, { 1, 0 } }
			for _, _binding in mergeCheckDirections do
				local gridColumnDelta = _binding[1]
				local gridRowDelta = _binding[2]
				local neighborColumn = gridColumn + gridColumnDelta
				local neighborRow = gridRow + gridRowDelta
				if not self:hasRoom(neighborColumn, neighborRow) then
					continue
				end
				local sharedWallKey = mazePassageKey(gridColumn, gridRow, neighborColumn, neighborRow)
				if passages[sharedWallKey] ~= nil then
					continue
				end
				if math.random() >= mergeWallChance then
					continue
				end
				mergedWalls[sharedWallKey] = true
			end
		end
		function ProceduralRoomGrid:generateMergedWalls(passages, mergeWallChance)
			local mergedWalls = {}
			for gridColumn = 0, #self.roomGrid - 1 do
				local roomRow = self.roomGrid[gridColumn + 1]
				if not roomRow then
					continue
				end
				for gridRow = 0, #roomRow - 1 do
					if not self:hasRoom(gridColumn, gridRow) then
						continue
					end
					self:collectMergedWallsForCell(passages, mergedWalls, mergeWallChance, gridColumn, gridRow)
				end
			end
			return mergedWalls
		end
		function ProceduralRoomGrid:computeSingleFaceData(passages, mergedWalls, gridColumn, gridRow, gridColumnDelta, gridRowDelta, thisFace)
			local neighborColumn = gridColumn + gridColumnDelta
			local neighborRow = gridRow + gridRowDelta
			local neighborExists = self:hasRoom(neighborColumn, neighborRow)
			local sharedWallKey = mazePassageKey(gridColumn, gridRow, neighborColumn, neighborRow)
			if neighborExists and mergedWalls[sharedWallKey] ~= nil then
				return {
					state = "empty",
				}
			end
			if neighborExists and passages[sharedWallKey] ~= nil then
				return {
					state = "doorway",
				}
			end
			if neighborExists then
				return {
					state = "interiorWall",
				}
			end
			if self.roomGrid[gridColumn + 1][gridRow + 1] == EXIT_ROOM_CELL_TYPE and thisFace == "north" then
				return {
					state = "doorway",
				}
			end
			return {
				state = "exteriorWall",
			}
		end
		function ProceduralRoomGrid:computeFaceDataForCell(passages, mergedWalls, gridColumn, gridRow)
			return {
				north = self:computeSingleFaceData(passages, mergedWalls, gridColumn, gridRow, 0, -1, "north"),
				south = self:computeSingleFaceData(passages, mergedWalls, gridColumn, gridRow, 0, 1, "south"),
				east = self:computeSingleFaceData(passages, mergedWalls, gridColumn, gridRow, 1, 0, "east"),
				west = self:computeSingleFaceData(passages, mergedWalls, gridColumn, gridRow, -1, 0, "west"),
			}
		end
		function ProceduralRoomGrid:computeAllRoomFaceData(passages, mergedWalls)
			local allRoomFaceData = {}
			for gridColumn = 0, #self.roomGrid - 1 do
				local roomRow = self.roomGrid[gridColumn + 1]
				if roomRow == nil then
					continue
				end
				for gridRow = 0, #roomRow - 1 do
					if not self:hasRoom(gridColumn, gridRow) then
						continue
					end
					local _arg0 = `{gridColumn},{gridRow}`
					local _arg1 = self:computeFaceDataForCell(passages, mergedWalls, gridColumn, gridRow)
					allRoomFaceData[_arg0] = _arg1
				end
			end
			return allRoomFaceData
		end
	end
	return {
		ProceduralRoomGrid = ProceduralRoomGrid,
	}

end

__modulesFolder["Util"] = function()
	local script
	script = newFakeInstance({"Util"})
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local function assign(a, b, optionalFunc)
		if optionalFunc == nil then
			optionalFunc = function(a, index, value)
				a[index] = value
			end
		end
		local _a = a
		assert(_a, "A is missing")
		local _b = b
		assert(_b, "B is missing")
		for index, value in pairs(b) do
			optionalFunc(a, index, value)
		end
		return a
	end
	local function fisherYatesShuffle(inputArray)
		local _array = {}
		local _length = #_array
		table.move(inputArray, 1, #inputArray, _length + 1, _array)
		local result = _array
		for currentIndex = #result - 1, 1, -1 do
			local randomSwapIndex = math.floor(math.random() * (currentIndex + 1))
			local elementAtCurrentIndex = result[currentIndex + 1]
			result[currentIndex + 1] = result[randomSwapIndex + 1]
			result[randomSwapIndex + 1] = elementAtCurrentIndex
		end
		return result
	end
	return {
		assign = assign,
		fisherYatesShuffle = fisherYatesShuffle,
	}

end

__modulesFolder["biome"] = function()
	local script
	script = newFakeInstance({"biome"})
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local biomeExtension = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "biomeExtension").biomeExtension
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	local Biome
	do
		Biome = setmetatable({}, {
			__tostring = function()
				return "Biome"
			end,
		})
		Biome.__index = Biome
		function Biome.new(...)
			local self = setmetatable({}, Biome)
			return self:constructor(...) or self
		end
		function Biome:constructor(adapter)
			self.priority = -1
			self.name = "?"
			self.adapter = adapter
		end
	end
	local function useBiomeData(yourCell)
		local data = biomeExtension:get(yourCell)
		if not data then
			return nil
		end
		return data
	end
	local defaultValue = {
		whoClaimedThis = {},
		claimed = 0,
	}
	local function structureClaimLand(thisBiome, yourCell)
		local data = biomeExtension:get(yourCell)
		if not data then
			return nil
		end
		data.claimed += 1
		local _whoClaimedThis = data.whoClaimedThis
		local _name = thisBiome.name
		table.insert(_whoClaimedThis, _name)
	end
	-- If a cell might not have biome data yet but you want to guarantee it does by the time this function exits, getOrInit handles that without a separate has() check followed by a set()
	local function ensureBiomeData(yourCell)
		return biomeExtension:getOrInit(yourCell, function()
			return defaultValue
		end)
	end
	return {
		useBiomeData = useBiomeData,
		structureClaimLand = structureClaimLand,
		ensureBiomeData = ensureBiomeData,
		Biome = Biome,
	}

end

__modulesFolder["biomeAndStructureRegistrySystem"] = function()
	local script
	script = newFakeInstance({"biomeAndStructureRegistrySystem"})
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	local biomeBox
	do
		biomeBox = setmetatable({}, {
			__tostring = function()
				return "biomeBox"
			end,
		})
		biomeBox.__index = biomeBox
		function biomeBox.new(...)
			local self = setmetatable({}, biomeBox)
			return self:constructor(...) or self
		end
		function biomeBox:constructor()
			self.modifiers = {}
		end
		function biomeBox:executeAllModifiers(yourSelf, yourCell)
			local _exp = self.modifiers
			-- ▼ ReadonlyArray.forEach ▼
			local _callback = function(modifier, index)
				modifier:generate(yourSelf, yourCell)
			end
			for _k, _v in _exp do
				_callback(_v, _k - 1, _exp)
			end
			-- ▲ ReadonlyArray.forEach ▲
		end
		function biomeBox:registerModifier(yourObject)
			local _modifiers = self.modifiers
			local _yourObject = yourObject
			table.insert(_modifiers, _yourObject)
			table.sort(self.modifiers, function(a, b)
				return a.priority > b.priority
			end)
		end
	end
	return {
		biomeBox = biomeBox,
	}

end

__modulesFolder["biomeExtension"] = function()
	local script
	script = newFakeInstance({"biomeExtension"})
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local createCellExtension = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "cellExtension").createCellExtension
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	local biomeExtension = createCellExtension()
	local structureExtension = createCellExtension()
	-- idk structure data goes here
	-- omg typescript is so new to me wtf is a weak map ohh okay i understand oh my gosh im stuck in a pizza traffic
	-- export const structureExtension = createCellExtension<WedgeCell, StructureData>();
	return {
		biomeExtension = biomeExtension,
		structureExtension = structureExtension,
	}

end

__modulesFolder["cellExtension"] = function()
	local script
	script = newFakeInstance({"cellExtension"})
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local function createCellExtension()
		local store = setmetatable({}, {
			__mode = "k",
		})
		return {
			get = function(self, cell)
				local _cell = cell
				return store[_cell]
			end,
			set = function(self, cell, data)
				local _cell = cell
				local _data = data
				store[_cell] = _data
			end,
			has = function(self, cell)
				local _cell = cell
				return store[_cell] ~= nil
			end,
			delete = function(self, cell)
				local _cell = cell
				-- ▼ Map.delete ▼
				local _valueExisted = store[_cell] ~= nil
				store[_cell] = nil
				-- ▲ Map.delete ▲
				return _valueExisted
			end,
			getOrInit = function(self, cell, init)
				local _cell = cell
				if not (store[_cell] ~= nil) then
					local _cell_1 = cell
					local _arg1 = init()
					store[_cell_1] = _arg1
				end
				local _cell_1 = cell
				return store[_cell_1]
			end,
		}
	end
	return {
		createCellExtension = createCellExtension,
	}

end

__modulesFolder["createTerrainFromVerticesUsingAdapter"] = function()
	local script
	script = newFakeInstance({"createTerrainFromVerticesUsingAdapter"})
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local assign = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Util").assign
	-- modules go above
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	local createTerrain
	do
		createTerrain = setmetatable({}, {
			__tostring = function()
				return "createTerrain"
			end,
		})
		createTerrain.__index = createTerrain
		function createTerrain.new(...)
			local self = setmetatable({}, createTerrain)
			return self:constructor(...) or self
		end
		function createTerrain:constructor(operateOnData, EgoMoose, adapter, parent, materialiseTriangle)
			self.materialiseTriangle = materialiseTriangle or self.materialiseTriangle
			self.adapter = adapter
			self.operateOnData = operateOnData
			self.EgoMoose = EgoMoose
			self.parent = parent
		end
		function createTerrain:materialiseTriangle(a, b, c)
			local _binding = self.EgoMoose.draw3dTriangle(a, b, c)
			local AData = _binding[1]
			local BData = _binding[2]
			local WedgeA = self.adapter.newInstance("WedgePart")
			local WedgeB = self.adapter.newInstance("WedgePart")
			self.adapter.setProperty(WedgeA, "Anchored", true)
			self.adapter.setProperty(WedgeB, "Anchored", true)
			self.adapter.setProperty(WedgeA, "Parent", self.parent)
			self.adapter.setProperty(WedgeB, "Parent", self.parent)
			assign(WedgeA, AData, function(item, key, value)
				self.adapter.setProperty(item, key, value)
			end)
			assign(WedgeB, BData, function(item, key, value)
				self.adapter.setProperty(item, key, value)
			end)
			return { WedgeA, WedgeB }
		end
		function createTerrain:createTrianglesFromData(data, resolution, partSize, offsetVector3)
			local getFromXY = function(x, y)
				return data[x * (resolution.Y + 1) + y + 1]
			end
			local multiplyVectorByPartSize = function(x, y, h)
				return Vector3.new(x * partSize, h * partSize, y * partSize)
			end
			local minSize = math.huge
			local maxSize = -math.huge
			do
				local x = 0
				local _shouldIncrement = false
				while true do
					if _shouldIncrement then
						x += 1
					else
						_shouldIncrement = true
					end
					if not (x < resolution.X) then
						break
					end
					do
						local y = 0
						local _shouldIncrement_1 = false
						while true do
							if _shouldIncrement_1 then
								y += 1
							else
								_shouldIncrement_1 = true
							end
							if not (y < resolution.Y) then
								break
							end
							local val = getFromXY(x, y)
							if val < minSize then
								minSize = val
							end
							if val > maxSize then
								maxSize = val
							end
						end
					end
				end
			end
			local minSizeVector3 = Vector3.new(0, minSize * partSize, 0)
			local wedges = {}
			do
				local x = 0
				local _shouldIncrement = false
				while true do
					if _shouldIncrement then
						x += 1
					else
						_shouldIncrement = true
					end
					if not (x < resolution.X) then
						break
					end
					do
						local y = 0
						local _shouldIncrement_1 = false
						while true do
							if _shouldIncrement_1 then
								y += 1
							else
								_shouldIncrement_1 = true
							end
							if not (y < resolution.Y) then
								break
							end
							local topLeftOffset = Vector2.new(0, 0)
							local topRightOffset = Vector2.new(1, 0)
							local bottomLeftOffset = Vector2.new(0, 1)
							local bottomRightOffset = Vector2.new(1, 1)
							local tLTotalH = getFromXY(x + topLeftOffset.X, y + topLeftOffset.Y)
							local tRTotalH = getFromXY(x + topRightOffset.X, y + topRightOffset.Y)
							local bLTotalH = getFromXY(x + bottomLeftOffset.X, y + bottomLeftOffset.Y)
							local bRTotalH = getFromXY(x + bottomRightOffset.X, y + bottomRightOffset.Y)
							local _exp = multiplyVectorByPartSize(x + topLeftOffset.X, y + topLeftOffset.Y, tLTotalH)
							local _offsetVector3 = offsetVector3
							local topLeft = _exp + _offsetVector3 - minSizeVector3
							local _exp_1 = multiplyVectorByPartSize(x + topRightOffset.X, y + topRightOffset.Y, tRTotalH)
							local _offsetVector3_1 = offsetVector3
							local topRight = _exp_1 + _offsetVector3_1 - minSizeVector3
							local _exp_2 = multiplyVectorByPartSize(x + bottomLeftOffset.X, y + bottomLeftOffset.Y, bLTotalH)
							local _offsetVector3_2 = offsetVector3
							local bottomLeft = _exp_2 + _offsetVector3_2 - minSizeVector3
							local _exp_3 = multiplyVectorByPartSize(x + bottomRightOffset.X, y + bottomRightOffset.Y, bRTotalH)
							local _offsetVector3_3 = offsetVector3
							local bottomRight = _exp_3 + _offsetVector3_3 - minSizeVector3
							if not wedges[x] then
								wedges[x] = {}
							end
							local cell = {
								triangles = { self:materialiseTriangle(topLeft, topRight, bottomLeft), self:materialiseTriangle(topRight, bottomRight, bottomLeft) },
								data = {
									vertices = { topLeft, topRight, bottomLeft, bottomRight },
									averageHeight = getFromXY(x, y) / maxSize,
									averageHeightSized = getFromXY(x, y),
									x = x,
									y = y,
								},
								verticesForTriangles = { { topLeft, topRight, bottomLeft }, { topRight, bottomRight, bottomLeft } },
								_self = self,
							}
							wedges[x][y] = cell
						end
					end
				end
			end
			do
				local x = 0
				local _shouldIncrement = false
				while true do
					if _shouldIncrement then
						x += 1
					else
						_shouldIncrement = true
					end
					if not (x < resolution.X) then
						break
					end
					do
						local y = 0
						local _shouldIncrement_1 = false
						while true do
							if _shouldIncrement_1 then
								y += 1
							else
								_shouldIncrement_1 = true
							end
							if not (y < resolution.Y) then
								break
							end
							if not self.operateOnData then
								continue
							end
							self.operateOnData(wedges[x][y])
						end
					end
				end
			end
			return wedges
		end
	end
	return {
		createTerrain = createTerrain,
	}

end

__modulesFolder["deadlineAdapter"] = function()
	local script
	script = newFakeInstance({"deadlineAdapter"})
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local deadlineAdapter = {}
	do
		local _container = deadlineAdapter
		local function newInstance(className, Parent)
			task.wait()
			return create_instance(className, Parent)
		end
		_container.newInstance = newInstance
		local function setProperty(property, key, value)
			property[key] = value
		end
		_container.setProperty = setProperty
		local function findFirstChild(target, targetName, recursive)
			return target:find_first_child(targetName, recursive)
		end
		_container.findFirstChild = findFirstChild
		local function destroy(target)
			return target:destroy()
		end
		_container.destroy = destroy
	end
	return {
		deadlineAdapter = deadlineAdapter,
	}

end

__modulesFolder["humanConfig"] = function()
	local script
	script = newFakeInstance({"humanConfig"})
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local default = {
		maxLivableSteepness = 15,
		grassDeepness = 0.1,
	}
	return {
		default = default,
	}

end

__modulesFolder["isDeadline"] = function()
	local script
	script = newFakeInstance({"isDeadline"})
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local isDeadline = get_map_root ~= nil
	return {
		isDeadline = isDeadline,
	}

end

__modulesFolder["robloxAdapter"] = function()
	local script
	script = newFakeInstance({"robloxAdapter"})
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local robloxAdapter = {}
	do
		local _container = robloxAdapter
		local function newInstance(className, Parent)
			return Instance.new(className, Parent)
		end
		_container.newInstance = newInstance
		local function setProperty(property, key, value)
			property[key] = value
		end
		_container.setProperty = setProperty
		local function findFirstChild(target, targetName, recursive)
			return target:FindFirstChild(targetName, recursive)
		end
		_container.findFirstChild = findFirstChild
		local function destroy(target)
			return target:Destroy()
		end
		_container.destroy = destroy
	end
	return {
		robloxAdapter = robloxAdapter,
	}

end

__modulesFolder["selfProp"] = function()
	local script
	script = newFakeInstance({"selfProp"})
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local function returnFunctionWithIdentity(func, _self)
		local _func = func
		assert(_func, "Function is missing")
		local __self = _self
		assert(__self ~= 0 and __self == __self and __self ~= "" and __self, "_self is missing")
		return function(...)
			local args = { ... }
			return func(_self, unpack(args))
		end
	end
	return {
		returnFunctionWithIdentity = returnFunctionWithIdentity,
	}

end

__modulesFolder["translateTerrainForStructureBonding"] = function()
	local script
	script = newFakeInstance({"translateTerrainForStructureBonding"})
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	-- local translateTerrainOrientationForStructureBonding = {
	--     orientationSubtraction = Vector3.new(0, 0, -90)
	-- }
	-- -- the maximum degree a person could live in is 15°
	-- --[[
	-- NOTES:
	-- -- Priority order for each structure
	-- (trees are default structure that generate at last priority)
	-- Buildings are first, and generate on any incline less than 15°
	-- So after the building does not generate on that triangle (it can occupy multiple triangles if needed), the tree generates
	-- A position map of already generated structures on what triangle also exists
	-- ]]
	-- function translateTerrainOrientationForStructureBonding:Translate(targetTriangle)
	--     local orientation = targetTriangle.Orientation
	-- 	return Vector3.new(orientation.X, orientation.Y, orientation.Z) + self.orientationSubtraction
	-- end
	-- function translateTerrainOrientationForStructureBonding:GetSteepnessInDegrees(targetCFrame)
	--     local angle = math.acos(targetCFrame.UpVector:Dot(Vector3.new(0, 1, 0)))
	--     return math.deg(angle)
	-- end
	-- return translateTerrainOrientationForStructureBonding
	local translateTerrainOrientationForStructureBonding
	do
		translateTerrainOrientationForStructureBonding = setmetatable({}, {
			__tostring = function()
				return "translateTerrainOrientationForStructureBonding"
			end,
		})
		translateTerrainOrientationForStructureBonding.__index = translateTerrainOrientationForStructureBonding
		function translateTerrainOrientationForStructureBonding.new(...)
			local self = setmetatable({}, translateTerrainOrientationForStructureBonding)
			return self:constructor(...) or self
		end
		function translateTerrainOrientationForStructureBonding:constructor(config)
			self.config = config
		end
		function translateTerrainOrientationForStructureBonding:Translate(targetTriangleOrientation)
			local _vector3 = Vector3.new(targetTriangleOrientation.X, targetTriangleOrientation.Y, targetTriangleOrientation.Z)
			local _orientationSubtraction = self.config.orientationSubtraction
			return _vector3 + _orientationSubtraction
		end
		function translateTerrainOrientationForStructureBonding:GetSteepnessInDegrees(targetCFrame)
			local angle = math.acos(targetCFrame.UpVector:Dot(Vector3.new(0, 1, 0)))
			return math.deg(angle)
		end
	end
	return {
		translateTerrainOrientationForStructureBonding = translateTerrainOrientationForStructureBonding,
	}

end

task.defer(function()
	local script
	script = newFakeInstance({"main"})
	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local isDeadline = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "isDeadline").isDeadline
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	-- The comment above is required for deadline-ts to parse this code correctly. You place the comment above this comment to define the end of all import statements.
	-- If you want to write on this program, you will follow the following Terms of Service. Failure to obey with the ToS is an illegal action and can lead to severe consequences.
	-- Here is the Gigachad Terms of Service 2000 Iteration 0
	--[[
		 Terms of Service
	
		SECTION 1 - DO NOT BE LAZY:
		- Make things extensible and modular as possible, then think about you can extend this in the future. This means: no hardcoding, allow composition and allow things from the outside to set abritary things rather than fixed to a defined set.
		- Never abbreviate variable names. EVER: They must be readable in English, and understandable. Include all details and context inside that variable name. More details is better. Utilise camelCase.
		- NEVER. EVER. USE. ALIGNMENT SPACES—They're ugly, ignored by beautifiers, and no one ever uses them.
		Examples of this bad practice:
		const abanana = dog;
		const ba      = dog2;
		const fucku   = fuckingdog;
		Examples of a good practice:
		const abanana = dog;
		const ba = dog2;
		const fucku = fuckingdog;
		- Always do the best implementation you can. Never skip out on things or do simpler versions. This is very important. If you do become lazy and do a worse implementation, problems in the future can happen because of that.
	
		SECTION 2 - CONSISTENCY AND CODE STYLE:
		- Use existing code style and don't add weird spaces between stuff like assigment statements.
		- Embrace never-nesting practices—Use early guard clauses and remember continue statement exists.
		- Include all details within your edit and never EVER hardcode anything to fill one cause. Other things from outside must be able to edit your cause in a different way to the extend I could add 50 dogs on top of a simple metal reflective box object and turn the box into a polygon that flashes rainbow every two seconds before turning into a yellow dog as an example.
		- Split concerns across multiple things—Don't make one thing handle it all—Allow for us to retrieve all values from data instead of just stealing one value and running away—This is for extensibility in the future. 
		Example of bad practice:
		const ax = (DogArrayData as {dogNameTag: string} & number[])[0];
		Example of good practice:
		const customDogArray: dogArrayType = DogArrayData;
		const firstElementInDogArray = customDogArray[0];
		- Inheritance is mostly outdated—so unless you're directly touching TypeScript stuff (like classes) or something, a pattern of composition is preferred unless you are forced to use it.
		- A space around each side of an arithmetic operator is generally advised.
	
		SECTION 3 - TYPESCRIPT BEST PRACTICES:
		- If possible, never use `as` statements in TypeScript—This is considered terrible practice.
		- Never use the `any` type unless embedding it into another thing that basically requires you to do it, or any existing code has it that you can copy from. Example: assign statement. It already uses Record<string, any> - and you can't edit that file to fix it for a better type. Then, you would use Record<string, any>.
		- If there is a more suitable type available—use it. Example: Record<string, unknown> could lead to errors when trying to do {dog: new Vector3()}; A better practice would to usePartial<InstanceProperties<BasePart>> or InstanceProperties<BasePart> depending on the context.
	
		SECTION 4 - COMMON SENSE AND BEST PRACTICES:
		- If something you suspect might be wrong—don't adapt your code on that. Do not build on mistakes; Do not make your code based on that mistake—Spot that it's a mistake and if you have been granted permission to edit that part, edit to fix. Otherwise, just inform us.
		- Don't truncate things—ugly.
		- Don't add comments that point the obvious. Unless you're explaining some nuanced thing or detail, maybe an algorithm — Just don't.
		- Don't use outdated APIs or versions—Always refer to newer alternatives rather than using deprecated things in new code.
		- If you can avoid an else statement using stuff like lookup tables or continue statement, do it.
	
		By editing on this file, you agree to the terms of conditions. Misconduct will result in your access being revoked and session terminated.
	
		Think of it like this:
		┌─────────────────────────────────────────────┐
		│             Visual Studio Code              │
		├─────────────────────────────────────────────┤
		│ This code is ass. Session Terminated.       │
		│                                             │
		│ [I WILL FIX THIS]                           │
		└─────────────────────────────────────────────┘
	
	]]
	if isDeadline then
		load_modfile("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")
		map.set_map("template_map")
		sharedvars.plr_ping_limit_sec = math.huge
		sharedvars.plr_ping_timeout_sec = math.huge
		sharedvars.plr_ping_warning_threshold_ms = math.huge
		sharedvars.ac_airtime_kill = false
		sharedvars.sv_gravity = 20
		map.set_time(10)
		local lastSpawns = {
			defender = 0,
			attacker = 0,
			coordination = 10,
		}
		local lastSpawnedPos = {}
		local firstPos, secondPos = Vector3.new(-5000, 5000, -5000), Vector3.new(5000, 5000, 5000)
		on_player_spawned:Connect(function(name)
			time.wait(1.4)
			local player = players.get(name)
			if not player then
				return nil
			end
			local team = player:get_team()
			lastSpawns[team] += 1
			if (lastSpawns[team] > lastSpawns.coordination) or (not lastSpawnedPos[team]) then
				lastSpawns[team] = 0
				local raycast_params = query.create_raycast_params()
				local hit = query.raycast(Vector3.new(math.random(firstPos.X, secondPos.X), math.random(firstPos.Y, secondPos.Y), math.random(firstPos.Z, secondPos.Z)), Vector3.new(0, -15000, 0), raycast_params)
				if not hit then
					return warn("Hit was not found when doing spawn logic")
				end
				local _position = hit.position
				local _vector3 = Vector3.new(0, 6, 0)
				lastSpawnedPos[team] = _position + _vector3
			end
			player:set_position(lastSpawnedPos[team])
			task.wait(1)
			player:set_health(100)
		end)
		local seed = os.time()
		local function generateForClient(playerToGenerateFor, seed)
			playerToGenerateFor:fire_client("generateTerrain", seed)
		end
		local _exp = players.get_all()
		-- ▼ ReadonlyArray.forEach ▼
		local _callback = function(thisPlayer, index)
			generateForClient(thisPlayer, seed)
		end
		for _k, _v in _exp do
			_callback(_v, _k - 1, _exp)
		end
		-- ▲ ReadonlyArray.forEach ▲
		on_player_joined:Connect(function(name)
			local thisPlayer = players.get(name)
			if not thisPlayer then
				return nil
			end
			generateForClient(thisPlayer, seed)
		end)
	end

end)
