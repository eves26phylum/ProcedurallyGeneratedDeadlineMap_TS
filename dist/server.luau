-- bundled with deadline-ts (no, rbxts are modules not supported yet)
function assert(condition, messageIfFalse)
	if not condition then error(messageIfFalse or _VERSION .. " assertion error") end
end
local Shared = shared
local _VERSION = create_instance and _VERSION.." {deadline-ts PRE-RELEASE}" or _VERSION
local unpack = table.unpack
local old_require = require
local __modulesFolder = {}
local __modulesCachedValues = {}
local __runtimeLibPath = {"ReplicatedStorage", "rbxts_include", "RuntimeLib"}
local __OUTPUT_DIR_MARKER = {}
local __robloxTree = {
	["ServerScriptService"] = {
		["TS"] = __OUTPUT_DIR_MARKER
	},
	["StarterPlayer"] = {
		["StarterPlayerScripts"] = {
			["TS"] = __OUTPUT_DIR_MARKER
		}
	},
	["ReplicatedStorage"] = {
		["TS"] = __OUTPUT_DIR_MARKER
	}
}
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
			WaitForChild = function(self, name) return newFakeInstance({name}) end,
			is_fake_instance = true,
		}
		inst.is_fake_instance = true
	end
	return inst
end

local old_game = game
local game
if old_game ~= nil then
	game = old_game
else
	game = {
		GetService = function(self, name)
			local inst = newFakeInstance({name})
			inst.__isService = true
			return inst
		end,
	}
end

local function getRobloxInstancePath(inst)
	local parts = {}
	local current = inst
	while current ~= nil and current.Parent ~= nil do
		table.insert(parts, 1, current.Name)
		current = current.Parent
	end
	return parts
end

local function matchesRuntimeLibPath(pathToCheck)
	if #pathToCheck ~= #__runtimeLibPath then return false end
	for i = 1, #__runtimeLibPath do
		if pathToCheck[i] ~= __runtimeLibPath[i] then return false end
	end
	return true
end

local function resolveModuleRelativeSegs(startModule, ...)
	local varargs = table.pack(...)
	local segCount = varargs.n
	local serviceName = startModule.Name
	local serviceNode = __robloxTree[serviceName]

	if serviceNode == nil then
		local segs = {}
		for i = 1, segCount do segs[i] = varargs[i] end
		return segs
	end

	local currentNode = serviceNode

	for i = 1, segCount do
		local seg = varargs[i]
		local nextNode = currentNode[seg]

		if nextNode == nil then
			local relSegs = {}
			for j = i, segCount do relSegs[#relSegs + 1] = varargs[j] end
			return relSegs
		end

		if nextNode == __OUTPUT_DIR_MARKER then
			local relSegs = {}
			for j = i + 1, segCount do relSegs[#relSegs + 1] = varargs[j] end
			return relSegs
		end

		currentNode = nextNode
	end
	return {}
end

local __customTS = {}
__customTS.Promise = nil

__customTS.import = function(context, startModule, ...)
	local relSegs = resolveModuleRelativeSegs(startModule, ...)

	if #relSegs == 0 then
		error('TS.import: resolved to an empty module path — check your project.json output directory configuration')
	end

	local cacheKey = table.concat(relSegs, '\0')

	if __modulesCachedValues[cacheKey] ~= nil then
		return __modulesCachedValues[cacheKey]
	end

	local node = __modulesFolder
	for _, seg in ipairs(relSegs) do
		node = node[seg]
		if node == nil then
			error('TS.import: module not found at path "' .. table.concat(relSegs, '/') .. '"')
		end
	end

	if type(node) ~= 'function' then
		error('TS.import: resolved path "' .. table.concat(relSegs, '/') .. '" is not a module factory')
	end

	local result = node()
	__modulesCachedValues[cacheKey] = result
	return result
end

__customTS.instanceof = function(obj, class)
	if type(class) == 'table' and type(class.instanceof) == 'function' then
		return class.instanceof(obj)
	end
	if type(obj) == 'table' then
		obj = getmetatable(obj)
		while obj ~= nil do
			if obj == class then return true end
			local mt = getmetatable(obj)
			if mt then
				obj = mt.__index
			else
				obj = nil
			end
		end
	end
	return false
end

__customTS.async = function(callback)
	return function(...)
		local n = select('#', ...)
		local args = {...}
		return __customTS.Promise.new(function(resolve, reject)
			local ok, result = pcall(callback, unpack(args, 1, n))
			if ok then
				resolve(result)
			else
				reject(result)
			end
		end)
	end
end

__customTS.await = function(promise)
	if not __customTS.Promise or not __customTS.Promise.is(promise) then
		return promise
	end
	local status, value = promise:awaitStatus()
	if status == __customTS.Promise.Status.Resolved then
		return value
	elseif status == __customTS.Promise.Status.Rejected then
		error(value, 2)
	else
		error('The awaited Promise was cancelled', 2)
	end
end

local __SIGN = 2 ^ 31
local __COMPLEMENT = 2 ^ 32
local function __bitSign(num)
	if bit32.btest(num, __SIGN) then
		return num - __COMPLEMENT
	else
		return num
	end
end

__customTS.bit_lrsh = function(a, b)
	return __bitSign(bit32.arshift(a, b))
end

__customTS.TRY_RETURN = 1
__customTS.TRY_BREAK = 2
__customTS.TRY_CONTINUE = 3

__customTS.try = function(try, catch, finally)
	local trySuccess, exitTypeOrTryError, returns = pcall(try)
	local exitType, tryError
	if trySuccess then
		exitType = exitTypeOrTryError
	else
		tryError = exitTypeOrTryError
	end
	local catchSuccess = true
	local catchError
	if not trySuccess and catch then
		local newExitType, newReturns
		catchSuccess, newExitType, newReturns = pcall(catch, tryError)
		local resolvedExitType
		if catchSuccess then
			resolvedExitType = newExitType
		else
			catchError = newExitType
		end
		if resolvedExitType then
			exitType, returns = resolvedExitType, newReturns
		end
	end
	if finally then
		local finallyExitType, finallyReturns = finally()
		if finallyExitType then
			exitType, returns = finallyExitType, finallyReturns
		end
	end
	if exitType ~= __customTS.TRY_RETURN and exitType ~= __customTS.TRY_BREAK and exitType ~= __customTS.TRY_CONTINUE then
		if not catchSuccess then
			error(catchError, 2)
		end
		if not trySuccess and not catch then
			error(tryError, 2)
		end
	end
	return exitType, returns
end

__customTS.generator = function(callback)
	local co = coroutine.create(callback)
	return {
		next = function(...)
			if coroutine.status(co) == 'dead' then
				return {done = true}
			end
			local success, value = coroutine.resume(co, ...)
			if success == false then
				error(value, 2)
			end
			return {
				value = value,
				done = coroutine.status(co) == 'dead',
			}
		end,
	}
end

local require = function(moduleRef)
	if type(moduleRef) == 'table' and moduleRef.__path then
		if matchesRuntimeLibPath(moduleRef.__path) then
			return __customTS
		end
	end
	if type(moduleRef) == 'userdata' then
		local instPath = getRobloxInstancePath(moduleRef)
		if matchesRuntimeLibPath(instPath) then
			return __customTS
		end
	end
	return old_require(moduleRef)
end

__modulesFolder["biomes"] = __modulesFolder["biomes"] or {}
__modulesFolder["nuristanHandler"] = __modulesFolder["nuristanHandler"] or {}

__modulesFolder["DepthFirstMazeSearch"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"DepthFirstMazeSearch"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local fisherYatesShuffle = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Util").fisherYatesShuffle
	-- !deadline-ts.customFinishSector_FinishModulesEnd
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
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"EgoMoose"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	-- thanks from EgoMoose
	-- https://github.com/EgoMoose/Articles
	-- saved some time
	-- !deadline-ts.customFinishSector_FinishModulesEnd
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
		local function getRandomWeights()
			local r1 = math.random()
			local r2 = math.random()
			local sqrtR1 = math.sqrt(r1)
			local wA = 1 - sqrtR1
			local wB = sqrtR1 * (1 - r2)
			local wC = r2 * sqrtR1
			return { wA, wB, wC }
		end
		_container.getRandomWeights = getRandomWeights
		local function getPointFromWeights(a, b, c, weights)
			local wA = weights[1]
			local wB = weights[2]
			local wC = weights[3]
			local _exp = a * wA
			local _arg0 = b * wB
			local _arg0_1 = c * wC
			return _exp + _arg0 + _arg0_1
		end
		_container.getPointFromWeights = getPointFromWeights
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

__modulesFolder["PerlinNoise"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"PerlinNoise"})	local newFakeInstance = nil

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
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"ProceduralRoomGeneration"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local mazePassageKey = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "DepthFirstMazeSearch").mazePassageKey
	-- !deadline-ts.customFinishSector_FinishModulesEnd
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
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"Util"})	local newFakeInstance = nil

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

__modulesFolder["adapterToUse"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"adapterToUse"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local isDeadline = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "isDeadline").isDeadline
	local deadlineAdapter = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "deadlineAdapter").deadlineAdapter
	local robloxAdapter = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "robloxAdapter").robloxAdapter
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local adapterToUse = if isDeadline then deadlineAdapter else robloxAdapter
	return {
		adapterToUse = adapterToUse,
	}

end

__modulesFolder["alphabetArray"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"alphabetArray"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local alphabetArray = string.split("abcdefghijklmnopqrstuvwxyz", "")
	return {
		alphabetArray = alphabetArray,
	}

end

__modulesFolder["biome"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"biome"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local biomeExtension = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "biomeExtension").biomeExtension
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local function useBiomeData(yourCell)
		local data = biomeExtension:get(yourCell)
		if not data then
			return nil
		end
		return data
	end
	local function biomeClaimLand(thisBiome, yourCell)
		local data = biomeExtension:get(yourCell)
		if not data then
			return nil
		end
		local _whoClaimedThis = data.whoClaimedThis
		local _name = thisBiome.name
		table.insert(_whoClaimedThis, _name)
	end
	-- If a cell might not have biome data yet but you want to guarantee it does by the time this function exits, getOrInit handles that without a separate has() check followed by a set()
	local function ensureBiomeData(yourCell)
		return biomeExtension:getOrInit(yourCell, function()
			return {
				whoClaimedThis = {},
			}
		end)
	end
	return {
		useBiomeData = useBiomeData,
		biomeClaimLand = biomeClaimLand,
		ensureBiomeData = ensureBiomeData,
	}

end

__modulesFolder["biomeAndStructureRegistrySystem"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"biomeAndStructureRegistrySystem"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local Logger = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "logger").Logger
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local thisLogger = Logger.new("biome_box")
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
			thisLogger:warn(`Registered modifier '{yourObject.name}'.`)
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
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"biomeExtension"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local createCellExtension = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "cellExtension").createCellExtension
	-- !deadline-ts.customFinishSector_FinishModulesEnd
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

__modulesFolder["biomes"]["NuristanBuildings"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"biomes", "NuristanBuildings"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local assign = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Util").assign
	local humanConfig = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "humanConfig").default
	local EgoMoose = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "EgoMoose").EgoMoose
	local ProceduralRoomGrid = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "ProceduralRoomGeneration").ProceduralRoomGrid
	local DepthFirstMazeSearch = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "DepthFirstMazeSearch").DepthFirstMazeSearch
	local fisherYatesShuffle = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Util").fisherYatesShuffle
	local _structure = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "structure")
	local ensureStructureData = _structure.ensureStructureData
	local structureClaimLand = _structure.structureClaimLand
	local useStructureData = _structure.useStructureData
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
	local NuristanBuildings
	do
		NuristanBuildings = setmetatable({}, {
			__tostring = function()
				return "NuristanBuildings"
			end,
		})
		NuristanBuildings.__index = NuristanBuildings
		function NuristanBuildings.new(...)
			local self = setmetatable({}, NuristanBuildings)
			return self:constructor(...) or self
		end
		function NuristanBuildings:constructor(adapterToUse, translateTerrain, config, parent, roomHandlers)
			self.priority = 50
			self.config = config
			self.translateTerrain = translateTerrain
			self.parent = parent
			self.name = "NuristanBuildings"
			self.roomHandlers = roomHandlers(self)
			self.adapter = adapterToUse
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
				for _, handler in self.roomHandlers do
					if handler:tryGenerate(roomCFrame, faceData) then
						break
					end
				end
			end)
		end
		function NuristanBuildings:operateOnThisTriangleInstance(data, trianglePair, verticesForTriangles)
			local middlePos = trianglePair[1].CFrame:Lerp(trianglePair[2].CFrame, 0.5)
			local triangleSurfaceNormal = trianglePair[1].CFrame.RightVector
			local degreesTiltedOfSteepness = math.deg(math.acos(triangleSurfaceNormal:Dot(Vector3.new(0, 1, 0))))
			local isALivableDegree = degreesTiltedOfSteepness < humanConfig.maxLivableSteepness
			if not isALivableDegree then
				return false
			end
			local horizontalReferenceVector = if math.abs(triangleSurfaceNormal.Y) < 0.99 then Vector3.new(0, 1, 0) else Vector3.new(1, 0, 0)
			local houseRightVector = horizontalReferenceVector:Cross(triangleSurfaceNormal).Unit
			local houseBackVector = houseRightVector:Cross(triangleSurfaceNormal).Unit
			local levelHouseCFrame = CFrame.fromMatrix(middlePos.Position, houseRightVector, triangleSurfaceNormal, houseBackVector)
			local randomYawCFrame = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.rad(math.random(0, 360)))
			self:createSingleHouse(levelHouseCFrame * randomYawCFrame, verticesForTriangles)
			return true
		end
		function NuristanBuildings:generate(yourSelf, yourCell)
			if useStructureData(yourCell) then
				return nil
			end
			local placedFirst = self:operateOnThisTriangleInstance(yourCell, yourCell.triangles[1], yourCell.verticesForTriangles[1])
			local placedSecond = self:operateOnThisTriangleInstance(yourCell, yourCell.triangles[2], yourCell.verticesForTriangles[2])
			if not placedFirst and not placedSecond then
				return nil
			end
			ensureStructureData(yourCell)
			structureClaimLand(self, yourCell)
		end
	end
	return {
		ALL_WALL_FACES = ALL_WALL_FACES,
		NuristanBuildings = NuristanBuildings,
	}

end

__modulesFolder["biomes"]["Tree"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"biomes", "Tree"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local EgoMoose = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "EgoMoose").EgoMoose
	local _structure = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "structure")
	local ensureStructureData = _structure.ensureStructureData
	local structureClaimLand = _structure.structureClaimLand
	local useStructureData = _structure.useStructureData
	local assign = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Util").assign
	local Tree
	do
		Tree = setmetatable({}, {
			__tostring = function()
				return "Tree"
			end,
		})
		Tree.__index = Tree
		function Tree.new(...)
			local self = setmetatable({}, Tree)
			return self:constructor(...) or self
		end
		function Tree:constructor(adapterToUse, config, parent)
			self.adapter = adapterToUse
			self.name = "Tree"
			self.priority = 30
			self.config = config
			self.parent = parent
		end
		function Tree:getRandomSurfacePosition(vertices)
			local toXZ = function(v)
				return Vector2.new(v.X, v.Z)
			end
			local randomPoint = EgoMoose.getPointFromWeights(toXZ(vertices[1]), toXZ(vertices[2]), toXZ(vertices[3]), EgoMoose.getRandomWeights())
			local _binding = EgoMoose.getBarycentricHeight(vertices[1], vertices[2], vertices[3], randomPoint)
			local height = _binding[1]
			if height == nil then
				return nil
			end
			return Vector3.new(randomPoint.X, height, randomPoint.Y)
		end
		function Tree:createTree(positionToPlaceAt, thisBranchSize, thisBallSize)
			local cylinder = self.adapter.newInstance("Part")
			self.adapter.setProperty(cylinder, "Anchored", true)
			self.adapter.setProperty(cylinder, "Shape", Enum.PartType.Cylinder)
			self.adapter.setProperty(cylinder, "Size", thisBranchSize)
			local _adapter = self.adapter
			local _exp = CFrame.fromEulerAnglesXYZ(0, 0, math.rad(90))
			local _positionToPlaceAt = positionToPlaceAt
			local _vector3 = Vector3.new(0, thisBranchSize.X / 2, 0)
			local _arg0 = self.config.offset or Vector3.zero
			_adapter.setProperty(cylinder, "CFrame", _exp + (_positionToPlaceAt + _vector3) + _arg0)
			self.adapter.setProperty(cylinder, "Parent", self.parent)
			self.adapter.setProperty(cylinder, "Name", "Branch")
			assign(cylinder, self.config.branch.props, self.adapter.setProperty)
			local leaf = self.adapter.newInstance("Part")
			self.adapter.setProperty(leaf, "Anchored", true)
			self.adapter.setProperty(leaf, "Shape", Enum.PartType.Ball)
			self.adapter.setProperty(leaf, "Size", thisBallSize)
			local _adapter_1 = self.adapter
			local _positionToPlaceAt_1 = positionToPlaceAt
			local _vector3_1 = Vector3.new(0, thisBranchSize.X, 0)
			local _arg0_1 = self.config.offset or Vector3.zero
			_adapter_1.setProperty(leaf, "Position", _positionToPlaceAt_1 + _vector3_1 + _arg0_1)
			self.adapter.setProperty(leaf, "Parent", self.parent)
			assign(leaf, self.config.leaf.props, self.adapter.setProperty)
		end
		function Tree:generate(yourSelf, yourCell)
			if useStructureData(yourCell) then
				return nil
			end
			local branchMaxSize, branchMinSize = self.config.branch.maxSize, self.config.branch.minSize
			for _, triangle in yourCell.verticesForTriangles do
				do
					local i = 0
					local _shouldIncrement = false
					while true do
						if _shouldIncrement then
							i += 1
						else
							_shouldIncrement = true
						end
						if not (i < self.config.treesPerTriangle) then
							break
						end
						local randY = branchMinSize.Y + math.random() * (branchMaxSize.Y - branchMinSize.Y)
						local randX = branchMinSize.X + math.random() * (branchMaxSize.X - branchMinSize.X)
						local thisBranchSize = Vector3.new(randY, randX, randX)
						local randLeafSize = self.config.leaf.minBoxSize + math.random() * (self.config.leaf.maxBoxSize - self.config.leaf.minBoxSize)
						local thisLeafSize = Vector3.new(randLeafSize, randLeafSize, randLeafSize)
						local pos = self:getRandomSurfacePosition(triangle)
						if pos == nil then
							continue
						end
						self:createTree(pos, thisBranchSize, thisLeafSize)
					end
				end
			end
			ensureStructureData(yourCell)
			structureClaimLand(self, yourCell)
		end
	end
	return {
		Tree = Tree,
	}

end

__modulesFolder["biomes"]["nuristanStandardBiome"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"biomes", "nuristanStandardBiome"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local useBiomeData = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "biome").useBiomeData
	local humanConfig = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "humanConfig").default
	local assign = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Util").assign
	local _biome = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "biome")
	local ensureBiomeData = _biome.ensureBiomeData
	local biomeClaimLand = _biome.biomeClaimLand
	local NuristanStandardBiome
	do
		NuristanStandardBiome = setmetatable({}, {
			__tostring = function()
				return "NuristanStandardBiome"
			end,
		})
		NuristanStandardBiome.__index = NuristanStandardBiome
		function NuristanStandardBiome.new(...)
			local self = setmetatable({}, NuristanStandardBiome)
			return self:constructor(...) or self
		end
		function NuristanStandardBiome:constructor(adapterToUse, config, parent)
			self.priority = 100
			self.config = config
			self.parent = parent
			self.name = "nsb"
			self.adapter = adapterToUse
		end
		function NuristanStandardBiome:getColourAndMaterialFromHeight(height)
			if height < humanConfig.grassDeepness then
				return self.config.grass()
			end
			return self.config.desert()
		end
		function NuristanStandardBiome:generate(yourSelf, yourCell)
			if useBiomeData(yourCell) then
				return nil
			end
			local operateOnThisTriangleInstance = function(data, triangle)
				local height = data.data.averageHeight
				local propMap = self:getColourAndMaterialFromHeight(height)
				assign(triangle, propMap, function(a, b, c)
					self.adapter.setProperty(a, b, c)
				end)
			end
			operateOnThisTriangleInstance(yourCell, yourCell.triangles[1][1])
			operateOnThisTriangleInstance(yourCell, yourCell.triangles[1][2])
			operateOnThisTriangleInstance(yourCell, yourCell.triangles[2][1])
			operateOnThisTriangleInstance(yourCell, yourCell.triangles[2][2])
			ensureBiomeData(yourCell)
			biomeClaimLand(self, yourCell)
		end
	end
	return {
		NuristanStandardBiome = NuristanStandardBiome,
	}

end

__modulesFolder["cellExtension"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"cellExtension"})	local newFakeInstance = nil

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
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"createTerrainFromVerticesUsingAdapter"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local assign = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Util").assign
	-- modules go above
	-- !deadline-ts.customFinishSector_FinishModulesEnd
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
			if materialiseTriangle then
				self.customMaterialise = materialiseTriangle
			end
			self.adapter = adapter
			self.operateOnData = operateOnData
			self.EgoMoose = EgoMoose
			self.parent = parent
		end
		function createTerrain:materialiseTriangle(a, b, c)
			if self.customMaterialise then
				return self.customMaterialise(self, a, b, c)
			end
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
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"deadlineAdapter"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	-- let wagesCounter = 0;
	local deadlineAdapter = {}
	do
		local _container = deadlineAdapter
		local function newInstance(className, Parent)
			-- if (wagesCounter > 1000) {
			--     wagesCounter = 0;
			--     task.wait(0.05);
			-- }
			-- wagesCounter++;
			local thisInstance = create_instance(className)
			if Parent then
				thisInstance.Parent = Parent
			end
			return thisInstance
		end
		_container.newInstance = newInstance
		local function setProperty(property, key, value)
			property[key] = value
		end
		_container.setProperty = setProperty
		local function findFirstChild(target, targetName, recursive)
			return target.find_first_child(targetName, recursive)
		end
		_container.findFirstChild = findFirstChild
		local function destroy(target)
			return target.destroy()
		end
		_container.destroy = destroy
		local function addTag(target, tag)
			target.add_tag(tag)
		end
		_container.addTag = addTag
		local function isA(target, whatClass)
			return target.is_a(whatClass)
		end
		_container.isA = isA
		local function playSound(target)
			target.play()
		end
		_container.playSound = playSound
		local function setNetworkOwner(part, player)
			part.set_network_owner(player.name)
		end
		_container.setNetworkOwner = setNetworkOwner
	end
	return {
		deadlineAdapter = deadlineAdapter,
	}

end

__modulesFolder["droneMaterialConfig"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"droneMaterialConfig"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local droneMaterialConfig = {
		selected = {
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(255, 255, 255),
		},
		normal = {
			Material = Enum.Material.Glass,
			Color = Color3.fromRGB(100, 100, 100),
		},
	}
	return {
		droneMaterialConfig = droneMaterialConfig,
	}

end

__modulesFolder["generateId"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"generateId"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local getRandomItemInArray = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "getRandomItemInArray").getRandomItemInArray
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local function generateId(length, charMap)
		local result = ""
		do
			local i = 0
			local _shouldIncrement = false
			while true do
				if _shouldIncrement then
					i += 1
				else
					_shouldIncrement = true
				end
				if not (i < length) then
					break
				end
				result = result .. getRandomItemInArray(charMap)
			end
		end
		return result
	end
	return {
		generateId = generateId,
	}

end

__modulesFolder["getRandomItemInArray"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"getRandomItemInArray"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local function getRandomItemInArray(array)
		return array[math.random(0, #array - 1) + 1]
	end
	return {
		getRandomItemInArray = getRandomItemInArray,
	}

end

__modulesFolder["getRoot"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"getRoot"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local isDeadline = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "isDeadline").isDeadline
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local function getWorldRoot()
		return if isDeadline then get_map_root() else game:GetService("Workspace")
	end
	return {
		getWorldRoot = getWorldRoot,
	}

end

__modulesFolder["humanConfig"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"humanConfig"})	local newFakeInstance = nil

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
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"isDeadline"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local isDeadline = (string.find(_VERSION, "{deadline-ts", 1, true)) ~= nil
	--local _VERSION = _VERSION.." {deadline-ts PRE-RELEASE}"
	return {
		isDeadline = isDeadline,
	}

end

__modulesFolder["logger"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"logger"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local assign = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Util").assign
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local DefaultLogTypes = {
		print = print,
		warn = warn,
		info = info or print,
		error = error,
	}
	local Logger
	do
		Logger = setmetatable({}, {
			__tostring = function()
				return "Logger"
			end,
		})
		Logger.__index = Logger
		function Logger.new(...)
			local self = setmetatable({}, Logger)
			return self:constructor(...) or self
		end
		function Logger:constructor(name, funcs)
			if funcs == nil then
				funcs = {}
			end
			self.name = name
			local funcer = assign({}, DefaultLogTypes)
			self.funcs = assign(funcer, funcs)
		end
		function Logger:useFuncToLogMessage(func, message)
			-- ▼ ReadonlyArray.forEach ▼
			local _callback = function(thisLine, index)
				func(`   {index}. {thisLine}`)
			end
			for _k, _v in message do
				_callback(_v, _k - 1, message)
			end
			-- ▲ ReadonlyArray.forEach ▲
		end
		function Logger:log(...)
			local message = { ... }
			self.funcs.print(`[{self.name}]`)
			local _self = self
			local _exp = self.funcs.print
			local _array = {}
			local _length = #_array
			table.move(message, 1, #message, _length + 1, _array)
			_self:useFuncToLogMessage(_exp, _array)
		end
		function Logger:warn(...)
			local message = { ... }
			self.funcs.warn(`[{self.name}]`)
			local _self = self
			local _exp = self.funcs.warn
			local _array = {}
			local _length = #_array
			table.move(message, 1, #message, _length + 1, _array)
			_self:useFuncToLogMessage(_exp, _array)
		end
		function Logger:error(...)
			local message = { ... }
			self.funcs.error(`[{self.name}]`)
			local _self = self
			local _exp = self.funcs.error
			local _array = {}
			local _length = #_array
			table.move(message, 1, #message, _length + 1, _array)
			_self:useFuncToLogMessage(_exp, _array)
		end
		function Logger:info(...)
			local message = { ... }
			self.funcs.info(`[{self.name}]`)
			local _self = self
			local _exp = self.funcs.info
			local _array = {}
			local _length = #_array
			table.move(message, 1, #message, _length + 1, _array)
			_self:useFuncToLogMessage(_exp, _array)
		end
	end
	return {
		DefaultLogTypes = DefaultLogTypes,
		Logger = Logger,
	}

end

__modulesFolder["nuristanHandler"]["livingRoom"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"nuristanHandler", "livingRoom"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
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
	return {
		LivingRoomHandler = LivingRoomHandler,
	}

end

__modulesFolder["nuristanHandler"]["sniperWindow"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"nuristanHandler", "sniperWindow"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local ALL_WALL_FACES = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "biomes", "NuristanBuildings").ALL_WALL_FACES
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
					local random = math.random()
					if random > 0.5 then
						self.buildings:makeWallWithDoorway(roomCFrame, roomSize, face, {
							doorway = self.sniperWindowDoorway,
						})
						continue
					end
					self.buildings:makeWallWithoutDoorway(roomCFrame, roomSize, face)
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
	return {
		SniperWindowRoomHandler = SniperWindowRoomHandler,
	}

end

__modulesFolder["randomDroneNoise"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"randomDroneNoise"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local random_drone_noise = {
		defender = { "rbxassetid://131625660349459", "rbxassetid://126734205451508", "rbxassetid://112226499298758" },
		attacker = { "rbxassetid://131680050661663", "rbxassetid://130659529431639", "rbxassetid://99988554071618" },
	}
	return {
		random_drone_noise = random_drone_noise,
	}

end

__modulesFolder["restrictedAssets"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"restrictedAssets"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	-- -- CLASS: PROPRIETARY
	local RestrictionChecker
	do
		RestrictionChecker = setmetatable({}, {
			__tostring = function()
				return "RestrictionChecker"
			end,
		})
		RestrictionChecker.__index = RestrictionChecker
		function RestrictionChecker.new(...)
			local self = setmetatable({}, RestrictionChecker)
			return self:constructor(...) or self
		end
		function RestrictionChecker:constructor()
		end
		function RestrictionChecker:isRestricted(instance)
			local message = ""
			local restricted = false
			TS.try(function()
				local _ = instance.Parent
			end, function(e)
				message = tostring(e)
				restricted = true
			end)
			return {
				message = message,
				restricted = restricted,
			}
		end
	end
	local ParentTraverser
	do
		ParentTraverser = setmetatable({}, {
			__tostring = function()
				return "ParentTraverser"
			end,
		})
		ParentTraverser.__index = ParentTraverser
		function ParentTraverser.new(...)
			local self = setmetatable({}, ParentTraverser)
			return self:constructor(...) or self
		end
		function ParentTraverser:constructor(checker)
			self.checker = checker
		end
		function ParentTraverser:traverse(instance, callback)
			if self.checker:isRestricted(instance).restricted then
				return nil
			end
			local parent = instance.Parent
			if not parent then
				return nil
			end
			local result = callback(instance, parent)
			if result ~= nil then
				return result
			end
			return self:traverse(parent, callback)
		end
	end
	local IgnoreFolderFinder
	do
		IgnoreFolderFinder = setmetatable({}, {
			__tostring = function()
				return "IgnoreFolderFinder"
			end,
		})
		IgnoreFolderFinder.__index = IgnoreFolderFinder
		function IgnoreFolderFinder.new(...)
			local self = setmetatable({}, IgnoreFolderFinder)
			return self:constructor(...) or self
		end
		function IgnoreFolderFinder:constructor(traverser, checker)
			self.traverser = traverser
			self.checker = checker
		end
		function IgnoreFolderFinder:getIgnoreFolderUsingTaggedChildren(proprietaryLogic)
			local candidates = {}
			for _, tagString in tags.get_tags() do
				for _1, instance in tags.get_tagged(tagString) do
					local result = self.traverser:traverse(instance, function(inst, parent)
						return proprietaryLogic(self, inst, parent)
					end)
					if not result then
						continue
					end
					local key = result[1]
					local candidate = result[2]
					candidates[key] = candidate
				end
			end
			return candidates
		end
	end
	local checker = RestrictionChecker.new()
	local traverser = ParentTraverser.new(checker)
	local finder = IgnoreFolderFinder.new(traverser, checker)
	local candidates = finder:getIgnoreFolderUsingTaggedChildren(function(finder, instance, parent)
		local result = finder.checker:isRestricted(parent)
		if result.restricted and { string.find(result.message, "is not accessible") } then
			return { parent.Name, parent }
		end
		return nil
	end)
	return {
		candidates = candidates,
	}

end

__modulesFolder["robloxAdapter"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"robloxAdapter"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local _CollectionService = game
	if _CollectionService ~= nil then
		_CollectionService = _CollectionService:GetService("CollectionService")
	end
	local CollectionService = _CollectionService
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
		local function addTag(target, tag)
			if not CollectionService then
				return nil
			end
			CollectionService:AddTag(target, tag)
		end
		_container.addTag = addTag
		local function isA(target, whatClass)
			return target:IsA(whatClass)
		end
		_container.isA = isA
		local function playSound(target)
			target:Play()
		end
		_container.playSound = playSound
		local function setNetworkOwner(part, player)
			part:SetNetworkOwner(player)
		end
		_container.setNetworkOwner = setNetworkOwner
	end
	return {
		robloxAdapter = robloxAdapter,
	}

end

__modulesFolder["selfProp"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"selfProp"})	local newFakeInstance = nil

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

__modulesFolder["spectatorBoxBuilder"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"spectatorBoxBuilder"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local INTERIOR_DIMENSION = 18
	local WALL_THICKNESS = 3
	local EXTERIOR_DIMENSION = INTERIOR_DIMENSION + WALL_THICKNESS * 2
	local INTERIOR_HALF_DIMENSION = INTERIOR_DIMENSION / 2
	local WALL_CENTER_OFFSET = INTERIOR_HALF_DIMENSION + WALL_THICKNESS / 2
	local GLASS_TRANSPARENCY = 0.3
	local GLASS_COLOR = Color3.fromRGB(200, 230, 255)
	local SIGN_WIDTH = 4
	local SIGN_HEIGHT = 2
	local SIGN_DEPTH = 0.2
	local SIGN_TEXT_SIZE = 16
	local SIGN_PIXELS_PER_STUD = 50
	local SIGN_TEXT_COLOR = Color3.new(1, 1, 1)
	local SIGN_SURFACE_COLOR = Color3.fromRGB(102, 102, 110)
	local LIGHT_FIXTURE_SIZE = Vector3.new(1, 0.5, 1)
	local LIGHT_FIXTURE_COLOR = Color3.fromRGB(255, 255, 200)
	local LIGHT_BRIGHTNESS = 1
	local LIGHT_RANGE = 16
	local LIGHT_COLOR = Color3.fromRGB(255, 255, 200)
	-- todo make this a config but whatever it's a preset prefab
	local SpectatorBox
	do
		SpectatorBox = setmetatable({}, {
			__tostring = function()
				return "SpectatorBox"
			end,
		})
		SpectatorBox.__index = SpectatorBox
		function SpectatorBox.new(...)
			local self = setmetatable({}, SpectatorBox)
			return self:constructor(...) or self
		end
		function SpectatorBox:constructor(adapter, centerBoxPosition, parent)
			self.adapter = adapter
			self.boxModel = adapter.newInstance("Folder", parent)
			adapter.setProperty(self.boxModel, "Name", "SpectatorBox")
			self.centerBoxPosition = centerBoxPosition
			self:buildGlassEnclosure(centerBoxPosition)
			local _self = self
			local _centerBoxPosition = centerBoxPosition
			local _vector3 = Vector3.new(0, (WALL_CENTER_OFFSET - WALL_THICKNESS / 2) - SIGN_HEIGHT / 2, 0)
			self.signTextDisplayLabel = _self:buildInteriorSign(_centerBoxPosition + _vector3)
			self:buildCeilingLightFixture(centerBoxPosition)
		end
		function SpectatorBox:setSignText(text)
			self.adapter.setProperty(self.signTextDisplayLabel, "Text", text)
		end
		function SpectatorBox:destroy()
			self.adapter.destroy(self.boxModel)
		end
		function SpectatorBox:buildGlassEnclosure(center)
			local _self = self
			local _exp = Vector3.new(EXTERIOR_DIMENSION, WALL_THICKNESS, EXTERIOR_DIMENSION)
			local _center = center
			local _vector3 = Vector3.new(0, -WALL_CENTER_OFFSET, 0)
			_self:createGlassWall(_exp, _center + _vector3, "Floor")
			local _self_1 = self
			local _exp_1 = Vector3.new(EXTERIOR_DIMENSION, WALL_THICKNESS, EXTERIOR_DIMENSION)
			local _center_1 = center
			local _vector3_1 = Vector3.new(0, WALL_CENTER_OFFSET, 0)
			_self_1:createGlassWall(_exp_1, _center_1 + _vector3_1, "Ceiling")
			local _self_2 = self
			local _exp_2 = Vector3.new(EXTERIOR_DIMENSION, INTERIOR_DIMENSION, WALL_THICKNESS)
			local _center_2 = center
			local _vector3_2 = Vector3.new(0, 0, WALL_CENTER_OFFSET)
			_self_2:createGlassWall(_exp_2, _center_2 + _vector3_2, "FrontWall")
			local _self_3 = self
			local _exp_3 = Vector3.new(EXTERIOR_DIMENSION, INTERIOR_DIMENSION, WALL_THICKNESS)
			local _center_3 = center
			local _vector3_3 = Vector3.new(0, 0, -WALL_CENTER_OFFSET)
			_self_3:createGlassWall(_exp_3, _center_3 + _vector3_3, "BackWall")
			local _self_4 = self
			local _exp_4 = Vector3.new(WALL_THICKNESS, INTERIOR_DIMENSION, EXTERIOR_DIMENSION)
			local _center_4 = center
			local _vector3_4 = Vector3.new(-WALL_CENTER_OFFSET, 0, 0)
			_self_4:createGlassWall(_exp_4, _center_4 + _vector3_4, "LeftWall")
			local _self_5 = self
			local _exp_5 = Vector3.new(WALL_THICKNESS, INTERIOR_DIMENSION, EXTERIOR_DIMENSION)
			local _center_5 = center
			local _vector3_5 = Vector3.new(WALL_CENTER_OFFSET, 0, 0)
			_self_5:createGlassWall(_exp_5, _center_5 + _vector3_5, "RightWall")
		end
		function SpectatorBox:buildInteriorSign(center)
			local interiorSignPart = self.adapter.newInstance("Part", self.boxModel)
			self.adapter.setProperty(interiorSignPart, "Name", "InteriorSign")
			self.adapter.setProperty(interiorSignPart, "Size", Vector3.new(SIGN_WIDTH, SIGN_HEIGHT, SIGN_DEPTH))
			self.adapter.setProperty(interiorSignPart, "CFrame", CFrame.new(center.X, center.Y, center.Z))
			self.adapter.setProperty(interiorSignPart, "Material", Enum.Material.Metal)
			self.adapter.setProperty(interiorSignPart, "Color", SIGN_SURFACE_COLOR)
			self.adapter.setProperty(interiorSignPart, "Anchored", true)
			local signSurfaceGui = self.adapter.newInstance("SurfaceGui", interiorSignPart)
			self.adapter.setProperty(signSurfaceGui, "Face", Enum.NormalId.Back)
			self.adapter.setProperty(signSurfaceGui, "SizingMode", Enum.SurfaceGuiSizingMode.PixelsPerStud)
			self.adapter.setProperty(signSurfaceGui, "PixelsPerStud", SIGN_PIXELS_PER_STUD)
			local signTextDisplayLabel = self.adapter.newInstance("TextLabel", signSurfaceGui)
			self.adapter.setProperty(signTextDisplayLabel, "Size", UDim2.new(1, -8, 1, -8))
			self.adapter.setProperty(signTextDisplayLabel, "Position", UDim2.new(0, 4, 0, 4))
			self.adapter.setProperty(signTextDisplayLabel, "TextSize", SIGN_TEXT_SIZE)
			self.adapter.setProperty(signTextDisplayLabel, "TextWrapped", true)
			self.adapter.setProperty(signTextDisplayLabel, "RichText", false)
			self.adapter.setProperty(signTextDisplayLabel, "Font", Enum.Font.Gotham)
			self.adapter.setProperty(signTextDisplayLabel, "TextColor3", SIGN_TEXT_COLOR)
			self.adapter.setProperty(signTextDisplayLabel, "BackgroundTransparency", 1)
			self.adapter.setProperty(signTextDisplayLabel, "TextYAlignment", Enum.TextYAlignment.Top)
			self.adapter.setProperty(signTextDisplayLabel, "TextXAlignment", Enum.TextXAlignment.Left)
			self.adapter.setProperty(signTextDisplayLabel, "Text", "")
			return signTextDisplayLabel
		end
		function SpectatorBox:buildCeilingLightFixture(center)
			local ceilingLightFixturePart = self.adapter.newInstance("Part", self.boxModel)
			self.adapter.setProperty(ceilingLightFixturePart, "Name", "CeilingLightFixture")
			self.adapter.setProperty(ceilingLightFixturePart, "Size", LIGHT_FIXTURE_SIZE)
			self.adapter.setProperty(ceilingLightFixturePart, "CFrame", CFrame.new(center.X, center.Y + INTERIOR_HALF_DIMENSION - LIGHT_FIXTURE_SIZE.Y / 2, center.Z))
			self.adapter.setProperty(ceilingLightFixturePart, "Material", Enum.Material.Neon)
			self.adapter.setProperty(ceilingLightFixturePart, "Color", LIGHT_FIXTURE_COLOR)
			self.adapter.setProperty(ceilingLightFixturePart, "Anchored", true)
			self.adapter.setProperty(ceilingLightFixturePart, "CastShadow", false)
			local ceilingPointLight = self.adapter.newInstance("PointLight", ceilingLightFixturePart)
			self.adapter.setProperty(ceilingPointLight, "Brightness", LIGHT_BRIGHTNESS)
			self.adapter.setProperty(ceilingPointLight, "Range", LIGHT_RANGE)
			self.adapter.setProperty(ceilingPointLight, "Color", LIGHT_COLOR)
			self.adapter.setProperty(ceilingPointLight, "Enabled", true)
		end
		function SpectatorBox:createGlassWall(wallSize, wallCenterPosition, wallPartName)
			local glassWallPart = self.adapter.newInstance("Part", self.boxModel)
			self.adapter.setProperty(glassWallPart, "Name", wallPartName)
			self.adapter.setProperty(glassWallPart, "Size", wallSize)
			self.adapter.setProperty(glassWallPart, "CFrame", CFrame.new(wallCenterPosition))
			self.adapter.setProperty(glassWallPart, "Material", Enum.Material.Glass)
			self.adapter.setProperty(glassWallPart, "Transparency", GLASS_TRANSPARENCY)
			self.adapter.setProperty(glassWallPart, "Color", GLASS_COLOR)
			self.adapter.setProperty(glassWallPart, "Anchored", true)
			self.adapter.setProperty(glassWallPart, "CastShadow", false)
			self.adapter.addTag(glassWallPart, "glass_invincible")
			return glassWallPart
		end
	end
	return {
		SpectatorBox = SpectatorBox,
	}

end

__modulesFolder["structure"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"structure"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local structureExtension = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "biomeExtension").structureExtension
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local function useStructureData(yourCell)
		local data = structureExtension:get(yourCell)
		if not data then
			return nil
		end
		return data
	end
	local function structureClaimLand(thisBiome, yourCell)
		local data = structureExtension:get(yourCell)
		if not data then
			return nil
		end
		local _whoClaimedThis = data.whoClaimedThis
		local _name = thisBiome.name
		table.insert(_whoClaimedThis, _name)
	end
	-- If a cell might not have biome data yet but you want to guarantee it does by the time this function exits, getOrInit handles that without a separate has() check followed by a set()
	local function ensureStructureData(yourCell)
		return structureExtension:getOrInit(yourCell, function()
			return {
				whoClaimedThis = {},
			}
		end)
	end
	return {
		useStructureData = useStructureData,
		structureClaimLand = structureClaimLand,
		ensureStructureData = ensureStructureData,
	}

end

__modulesFolder["tagsService"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"tagsService"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local _CollectionService = game
	if _CollectionService ~= nil then
		_CollectionService = _CollectionService:GetService("CollectionService")
	end
	local CollectionService = _CollectionService
	local tagsService = {}
	do
		local _container = tagsService
		local function getTags()
			return if CollectionService then CollectionService:GetTags() else tags.get_tags()
		end
		_container.getTags = getTags
		local function getTagged(tag)
			return if CollectionService then CollectionService:GetTagged(tag) else tags.get_tagged(tag)
		end
		_container.getTagged = getTagged
	end
	return {
		tagsService = tagsService,
	}

end

__modulesFolder["terrainProgressInterface"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"terrainProgressInterface"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	return nil

end

__modulesFolder["translateTerrainForStructureBonding"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"translateTerrainForStructureBonding"})	local newFakeInstance = nil

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

__modulesFolder["voicelines"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"voicelines"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local voicelines = {
		defender = { "Good morning, SYNO! We are waiting on %s more SYNO until we deploy. Stay cool, stay frosty.", "Eyes up, SYNO. %s personnel still need to link up for deployment. Remember your objective.", "Listen up. Command sent you here with triple the ammunition compared to a mission in Complex for a reason. We need %s more. Do not waste your rounds." },
		attacker = { "Hold your position. %s of our people still making their way here. We move together.", "%s more. Together, we can do it. They have been bleeding us dry long enough. We finish this.", "Brothers. %s still on route. When they get here, we remind thempoliticians why they should have left us alone." },
	}
	return {
		voicelines = voicelines,
	}

end

__modulesFolder["config"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"config"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local NuristanBuildingsConfig = {
		wallPartProps = {
			Material = Enum.Material.Sand,
			Color = Color3.fromRGB(237, 201, 175),
		},
		doorway = {
			width = 2.5,
			height = 6,
			offsetAlongWall = 0,
			bottomOffset = 0,
		},
		roomProps = {
			RoomSize = Vector3.new(20, 2, 20),
		},
		wall = {
			height = 10,
			thickness = 2,
		},
		roomGeneration = {
			minRooms = 2,
			maxRooms = 10,
			mergeWallChance = 0.3,
		},
		sniperWindowDoorway = {
			width = 5,
			height = 2,
			bottomOffset = 3,
			offsetAlongWall = 0,
		},
	}
	local StandardNuristanConfig = {
		grass = function()
			return {
				Material = Enum.Material.Grass,
				Color = Color3.fromRGB(158, 201, 33),
			}
		end,
		desert = function()
			local secondaryAngs = math.random(-20, 10)
			return {
				Material = Enum.Material.Sand,
				Color = Color3.fromRGB(237 + secondaryAngs, 201 + math.random(0, 20), 175 + secondaryAngs),
			}
		end,
	}
	local TreeConfig = {
		branch = {
			minSize = Vector2.new(4, 12),
			maxSize = Vector2.new(8, 24),
			props = {
				Material = Enum.Material.Wood,
				Color = Color3.fromRGB(71, 38, 8),
			},
		},
		leaf = {
			minBoxSize = 12,
			maxBoxSize = 32,
			props = {
				Material = Enum.Material.Grass,
				CanCollide = false,
				CanQuery = false,
				Transparency = 0.4,
				Color = Color3.fromRGB(36, 107, 51),
			},
		},
		treesPerTriangle = 4,
		offset = Vector3.new(0, -3, 0),
	}
	local PART_SIZE = 100
	local MAP_SIZE = Vector2.new(10000, 10000)
	local RESOLUTION = Vector2.new(math.round(MAP_SIZE.X / PART_SIZE), math.round(MAP_SIZE.Y / PART_SIZE))
	-- export const RESOLUTION = new Vector2(5, 5);
	local ROUGHNESS = 4
	local PARAMS = {
		lacunarity = 4,
		persistence = 0.25,
		octaves = 2,
		exaggeratedness = 20,
		power = 3,
		scale = math.max(RESOLUTION.X, RESOLUTION.Y) / ROUGHNESS,
	}
	local POSITION_OFFSET = Vector3.new(-(MAP_SIZE.X / 2), 0, -(MAP_SIZE.Y / 2))
	return {
		NuristanBuildingsConfig = NuristanBuildingsConfig,
		StandardNuristanConfig = StandardNuristanConfig,
		TreeConfig = TreeConfig,
		PART_SIZE = PART_SIZE,
		MAP_SIZE = MAP_SIZE,
		RESOLUTION = RESOLUTION,
		ROUGHNESS = ROUGHNESS,
		PARAMS = PARAMS,
		POSITION_OFFSET = POSITION_OFFSET,
	}

end

__modulesFolder["connectIngame"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"connectIngame"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local kickStart = TS.import(script, game:GetService("ServerScriptService"), "TS", "ingame").kickStart
	local adapterToUse = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "adapterToUse").adapterToUse
	local getWorldRoot = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "getRoot").getWorldRoot
	local Logger = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "logger").Logger
	local function connectIngameSystemsInALoop(dogRef)
		local Log = Logger.new("in_game_systems_in_a_loop")
		local disconnectAll
		disconnectAll = kickStart(adapterToUse, getWorldRoot(), dogRef, function(team_alive)
			if not disconnectAll then
				return nil
			end
			disconnectAll()
			local _exp = players.get_alive()
			-- ▼ ReadonlyArray.forEach ▼
			local _callback = function(player)
				player.kill()
			end
			for _k, _v in _exp do
				_callback(_v, _k - 1, _exp)
			end
			-- ▲ ReadonlyArray.forEach ▲
			Log:info("someone won", team_alive)
			connectIngameSystemsInALoop(dogRef)
		end)
		Log:info("I am now starting the game cycle.")
	end
	return {
		connectIngameSystemsInALoop = connectIngameSystemsInALoop,
	}

end

__modulesFolder["ingame"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"ingame"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local Logger = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "logger").Logger
	local isDeadline = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "isDeadline").isDeadline
	local SpectatorBox = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "spectatorBoxBuilder").SpectatorBox
	local voicelines = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "voicelines").voicelines
	local random_drone_noise = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "randomDroneNoise").random_drone_noise
	local generateId = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "generateId").generateId
	local alphabetArray = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "alphabetArray").alphabetArray
	local droneMaterialConfig = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "droneMaterialConfig").droneMaterialConfig
	local assign = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Util").assign
	local PingSystem = TS.import(script, game:GetService("ServerScriptService"), "TS", "pingSystem").PingSystem
	local Log = Logger.new("team_spawner")
	local droneNames = {}
	local function createDrone(player, adapterToUse, DroneFolder, random_drone_noise, customProperties)
		local player_name = player.name
		local drone = adapterToUse.newInstance("Part")
		if player.is_bot() then
			adapterToUse.setProperty(drone, "Anchored", true)
			return drone
		end
		local firstPos, secondPos = Vector3.new(-5000, 5000, -5000), Vector3.new(5000, 5000, 5000)
		local raycast_params = query.create_raycast_params()
		local posToHitStartFrom = Vector3.new(math.random(firstPos.X, secondPos.X), math.random(firstPos.Y, secondPos.Y), math.random(firstPos.Z, secondPos.Z))
		local hit = query.raycast(posToHitStartFrom, Vector3.new(0, -15000, 0), raycast_params)
		if not hit then
			Log:error(`Hit was not found when doing drone spawn logic`, `Position from: {posToHitStartFrom}`)
		end
		local generatedName = player_name .. generateId(26, alphabetArray)
		adapterToUse.setProperty(drone, "Size", Vector3.new(1, 0.5, 2))
		-- adapterToUse.setProperty(drone, "Anchored", true);
		adapterToUse.setProperty(drone, "CanCollide", false)
		adapterToUse.setProperty(drone, "Transparency", 0.5)
		adapterToUse.setProperty(drone, "Name", generatedName)
		local _adapterToUse = adapterToUse
		local _result = hit
		if _result ~= nil then
			local _position = _result.position
			local _vector3 = Vector3.new(0, 26, 0)
			_result = _position + _vector3
		end
		local _condition = _result
		if not _condition then
			_condition = Vector3.new(0, 2000, 0)
		end
		_adapterToUse.setProperty(drone, "CFrame", CFrame.new(_condition))
		local _adapterToUse_1 = adapterToUse
		local _result_1 = hit
		if _result_1 ~= nil then
			_result_1 = _result_1.position
		end
		_adapterToUse_1.setProperty(drone, "Position", _result_1)
		-- adapterToUse.setProperty(drone, "Material", Enum.Material.Glass);
		-- adapterToUse.setProperty(drone, "Color", Color3.fromRGB(100, 100, 100));
		local clonedNormal = assign({}, droneMaterialConfig.normal)
		local appliedNormal = assign(clonedNormal, customProperties)
		assign(drone, appliedNormal, adapterToUse.setProperty)
		adapterToUse.addTag(drone, "glass_destructible")
		adapterToUse.setProperty(drone, "Parent", DroneFolder)
		adapterToUse.setNetworkOwner(drone, player)
		droneNames[player_name] = generatedName
		local body_gyro = adapterToUse.newInstance("BodyGyro")
		adapterToUse.setProperty(body_gyro, "MaxTorque", Vector3.new(math.huge, math.huge, math.huge))
		adapterToUse.setProperty(body_gyro, "CFrame", drone.CFrame)
		adapterToUse.setProperty(body_gyro, "Name", "CoolGyro")
		adapterToUse.setProperty(body_gyro, "D", 500)
		adapterToUse.setProperty(body_gyro, "P", 3000)
		adapterToUse.setProperty(body_gyro, "Parent", drone)
		local body_velocity = adapterToUse.newInstance("BodyVelocity")
		adapterToUse.setProperty(body_velocity, "MaxForce", Vector3.new(math.huge, math.huge, math.huge))
		adapterToUse.setProperty(body_velocity, "Velocity", Vector3.new(0, 0, 0))
		adapterToUse.setProperty(body_velocity, "Name", "CoolVelocity")
		adapterToUse.setProperty(body_velocity, "P", 10000)
		adapterToUse.setProperty(body_velocity, "Parent", drone)
		local drone_noise = adapterToUse.newInstance("Sound")
		adapterToUse.setProperty(drone_noise, "Looped", true)
		adapterToUse.setProperty(drone_noise, "SoundId", random_drone_noise[math.random(0, #random_drone_noise - 1) + 1])
		adapterToUse.setProperty(drone_noise, "Volume", 1)
		adapterToUse.setProperty(drone_noise, "RollOffMaxDistance", 74)
		adapterToUse.setProperty(drone_noise, "Parent", drone)
		adapterToUse.playSound(drone_noise)
		player.fire_client("send_drone_info", generatedName)
		return drone
	end
	local function kickStart(adapterToUse, parent, dogRef, onWin)
		if not isDeadline then
			return Log:info("Did not execute because the environment is not Deadline.")
		end
		Log:info("Listening for people spawning.")
		sharedvars.plr_ping_limit_sec = math.huge
		sharedvars.plr_ping_timeout_sec = math.huge
		sharedvars.plr_ping_warning_threshold_ms = math.huge
		sharedvars.ac_airtime_kill = false
		sharedvars.ac_movement = false
		sharedvars.ac_sound_kill = false
		sharedvars.plr_drum_magazines = 3
		sharedvars.plr_magazines = 9
		sharedvars.plr_death_view_shot_location = false
		sharedvars.plr_spare_rounds = 90
		sharedvars.plr_base_weight = 1.7
		sharedvars.sv_gravity = 25.5
		sharedvars.plr_barrel_deviation = 0.25
		sharedvars.plr_movement_damping = 300
		sharedvars.plr_movement_min_stiffness = 20
		sharedvars.plr_movement_max_stiffness = 30
		sharedvars.sv_day_cycle_speed = 1
		map.set_time(math.random(0, 24))
		sharedvars.plr_speed = 0.95
		sharedvars.plr_recoil = 0.5
		sharedvars.ac_sound_kill = false
		sharedvars.ff_field_voicelines = true
		local game_vars = {}
		Shared.game = game_vars
		map.set_time(10)
		local lastSpawns = {
			defender = {},
			attacker = {},
			coordination = 10,
		}
		game_vars.lastSpawns = lastSpawns
		local spectatorBoxes = {
			defender = nil,
			attacker = nil,
		}
		local STARTING_TICKETS = 100
		local ticketsLeft = {
			defender = STARTING_TICKETS,
			attacker = STARTING_TICKETS,
		}
		game_vars.ticketsLeft = ticketsLeft
		local drones = {}
		local playerLoadouts = {}
		local tempState = {
			defender = {},
			attacker = {},
		}
		local pingSystem = PingSystem.new({
			pingCooldownSeconds = 3,
		})
		local DroneFolder = adapterToUse.newInstance("Folder")
		adapterToUse.setProperty(DroneFolder, "Name", "DronesFolder")
		adapterToUse.setProperty(DroneFolder, "Parent", parent)
		local SpectatorFolder = adapterToUse.newInstance("Folder")
		adapterToUse.setProperty(SpectatorFolder, "Name", "SpectatorsFolder")
		adapterToUse.setProperty(SpectatorFolder, "Parent", parent)
		-- const lastSpawnedPos: Partial<Record<PlayerTeam, Vector3>> = {};
		local offset = Vector3.new(0, 3000, 0)
		local firstPos, secondPos = Vector3.new(-3000, 5000, -3000), Vector3.new(3000, 5000, 3000)
		local spawnedAmounts = {}
		local hasWon = false
		local conn_1 = on_player_spawned:Connect(function(name)
			local player = players.get(name)
			if not player or not player.is_alive() then
				return nil
			end
			local spawnedAmount = if spawnedAmounts[player.name] ~= nil then spawnedAmounts[player.name] + 1 else 0
			spawnedAmounts[player.name] = spawnedAmount
			time.wait(1.4)
			if spawnedAmount ~= spawnedAmounts[player.name] then
				return nil
			end
			local team = player.get_team()
			local thisSpectatorBox = spectatorBoxes[team] or SpectatorBox.new(adapterToUse, offset, SpectatorFolder)
			if not spectatorBoxes[team] then
				thisSpectatorBox:setSignText("*singing to myself*")
				local _offset = offset
				local _vector3 = Vector3.new(200, 0, 0)
				offset = _offset + _vector3
				spectatorBoxes[team] = thisSpectatorBox
			end
			local _exp = lastSpawns[team]
			local _name = player.name
			if (table.find(_exp, _name) or 0) - 1 == -1 then
				local _exp_1 = lastSpawns[team]
				local _name_1 = player.name
				table.insert(_exp_1, _name_1)
			end
			player.set_position(spectatorBoxes[team].centerBoxPosition)
			-- player.set_camera_mode("Default");
			local _exp_1 = lastSpawns[team]
			-- ▼ ReadonlyArray.forEach ▼
			local _callback = function(playerName, index)
				local thisPlayer = players.get(playerName)
				if not thisPlayer then
					local _exp_2 = lastSpawns[team]
					local _index = index
					table.remove(_exp_2, _index + 1)
				end
			end
			for _k, _v in _exp_1 do
				_callback(_v, _k - 1, _exp_1)
			end
			-- ▲ ReadonlyArray.forEach ▲
			if drones[player.name] then
				adapterToUse.destroy(drones[player.name])
			end
			local customProps = if ticketsLeft[team] <= 0 then {
				Color = Color3.fromRGB(255, 0, 0),
			} else {}
			local drone = createDrone(player, adapterToUse, DroneFolder, random_drone_noise[team], customProps)
			drones[player.name] = drone
			local thisLoadout = playerLoadouts[player.name] or {
				primary = nil,
				secondary = nil,
				throwable1 = nil,
				throwable2 = nil,
			}
			playerLoadouts[player.name] = thisLoadout
			thisLoadout.primary = player.get_weapon_data_from_character("primary")
			thisLoadout.secondary = player.get_weapon_data_from_character("secondary")
			thisLoadout.throwable1 = player.get_weapon_data_from_character("throwable1")
			thisLoadout.throwable2 = player.get_weapon_data_from_character("throwable2")
			player.set_weapon("primary", "nothing")
			player.set_weapon("secondary", "nothing")
			player.set_weapon("throwable1", "nothing")
			player.set_weapon("throwable2", "nothing")
			player.set_custom_camera_mode("DroneFreecam")
			if ticketsLeft[team] <= 0 then
				local teams_alive = {}
				local _exp_2 = players.get_alive()
				-- ▼ ReadonlyArray.forEach ▼
				local _callback_1 = function(thisPlayer)
					local playerDrone = drones[thisPlayer.name]
					if playerDrone and playerDrone.Parent ~= nil then
						return nil
					end
					local thisTeam = thisPlayer.get_team()
					if (table.find(teams_alive, thisTeam) or 0) - 1 == -1 then
						table.insert(teams_alive, thisTeam)
					end
				end
				for _k, _v in _exp_2 do
					_callback_1(_v, _k - 1, _exp_2)
				end
				-- ▲ ReadonlyArray.forEach ▲
				if hasWon then
					return nil
				end
				if #teams_alive <= 1 then
					hasWon = true
					onWin(teams_alive[1] or "what da hell")
					return nil
				end
				task.defer(function()
					while spawnedAmount == spawnedAmounts[player.name] and drone.Parent ~= nil do
						task.wait(1)
					end
					player.respawn()
				end)
				-- SET FREE CAMERA
				return nil
			end
			task.defer(function()
				while drone.Parent ~= nil do
					task.wait(1)
				end
				if spawnedAmount == spawnedAmounts[player.name] then
					player.set_camera_mode("RecoilCam")
				end
			end)
			local thisVoicelineStr = voicelines[team][math.random(0, #voicelines[team] - 1) + 1]
			local coordAmount = math.min(lastSpawns.coordination, #players.get_all())
			local _condition = tempState[team].voiceline
			if not (_condition ~= "" and _condition) then
				_condition = string.format(`{thisVoicelineStr} | {ticketsLeft[team]} waves left`, `{coordAmount - #lastSpawns[team]}`)
			end
			local teamVoiceline = _condition
			tempState[team].voiceline = teamVoiceline
			thisSpectatorBox:setSignText(teamVoiceline)
			if #lastSpawns[team] < coordAmount then
				return nil
			end
			local raycast_params = query.create_raycast_params()
			local posToHitStartFrom = Vector3.new(math.random(firstPos.X, secondPos.X), math.random(firstPos.Y, secondPos.Y), math.random(firstPos.Z, secondPos.Z))
			-- lastSpawnedPos[team] = hitSpawnPos;
			Log:info(`Registering team spawn for the following members`, unpack(lastSpawns[team]))
			ticketsLeft[team] -= #lastSpawns[team]
			local _exp_2 = lastSpawns[team]
			-- ▼ ReadonlyArray.forEach ▼
			local _callback_1 = function(playerName, index)
				local thisPlayer = players.get(playerName)
				if not thisPlayer then
					return nil
				end
				local _vector3 = Vector3.new(4 * index, 0, 0)
				local hit = query.raycast(posToHitStartFrom + _vector3, Vector3.new(0, -15000, 0), raycast_params)
				if not hit then
					thisSpectatorBox:setSignText("We couldn't find a place to spawn. This is a mapping error, and please report it to the map developers.")
					return Log:warn(`Hit was not found when doing spawn logic`, `Position from: {posToHitStartFrom}`)
				end
				local _position = hit.position
				local _condition_1 = dogRef.current
				if not (_condition_1 ~= 0 and _condition_1 == _condition_1 and _condition_1) then
					_condition_1 = math.huge
				end
				local _vector3_1 = Vector3.new(0, math.min(340, _condition_1), 0)
				local hitSpawnPos = _position + _vector3_1
				if drones[thisPlayer.name] then
					adapterToUse.destroy(drones[thisPlayer.name])
				end
				thisPlayer.set_camera_mode("RecoilCam")
				thisPlayer.set_position(hitSpawnPos)
				task.delay(3, function()
					for i = 0, 19 do
						thisPlayer.set_health(100)
						task.wait(1)
					end
				end)
				if thisPlayer.is_bot() then
					return nil
				end
				local thisPlayerLoadout = playerLoadouts[thisPlayer.name] or {
					primary = nil,
					secondary = nil,
					throwable1 = nil,
					throwable2 = nil,
				}
				local _result = thisPlayerLoadout.primary
				if _result ~= nil then
					_result = _result.client_data
					if _result ~= nil then
						_result = _result.name
					end
				end
				local _condition_2 = _result
				if not (_condition_2 ~= "" and _condition_2) then
					_condition_2 = "nothing"
				end
				local _result_1 = thisPlayerLoadout.primary
				if _result_1 ~= nil then
					_result_1 = _result_1.client_data
					if _result_1 ~= nil then
						_result_1 = _result_1.setup
					end
				end
				local _condition_3 = _result_1
				if not (_condition_3 ~= "" and _condition_3) then
					_condition_3 = "[]"
				end
				thisPlayer.set_weapon("primary", _condition_2, _condition_3)
				local _result_2 = thisPlayerLoadout.secondary
				if _result_2 ~= nil then
					_result_2 = _result_2.client_data
					if _result_2 ~= nil then
						_result_2 = _result_2.name
					end
				end
				local _condition_4 = _result_2
				if not (_condition_4 ~= "" and _condition_4) then
					_condition_4 = "nothing"
				end
				local _result_3 = thisPlayerLoadout.secondary
				if _result_3 ~= nil then
					_result_3 = _result_3.client_data
					if _result_3 ~= nil then
						_result_3 = _result_3.setup
					end
				end
				local _condition_5 = _result_3
				if not (_condition_5 ~= "" and _condition_5) then
					_condition_5 = "[]"
				end
				thisPlayer.set_weapon("secondary", _condition_4, _condition_5)
				local _result_4 = thisPlayerLoadout.throwable1
				if _result_4 ~= nil then
					_result_4 = _result_4.name
				end
				local _condition_6 = _result_4
				if not (_condition_6 ~= "" and _condition_6) then
					_condition_6 = "nothing"
				end
				thisPlayer.set_weapon("throwable1", _condition_6, "[]")
				local _result_5 = thisPlayerLoadout.throwable2
				if _result_5 ~= nil then
					_result_5 = _result_5.name
				end
				local _condition_7 = _result_5
				if not (_condition_7 ~= "" and _condition_7) then
					_condition_7 = "nothing"
				end
				thisPlayer.set_weapon("throwable2", _condition_7, "[]")
				thisPlayer.refill_ammo()
				task.delay(0.1, function()
					thisPlayer.fire_client("reset_velocity")
				end)
			end
			for _k, _v in _exp_2 do
				_callback_1(_v, _k - 1, _exp_2)
			end
			-- ▲ ReadonlyArray.forEach ▲
			lastSpawns[team] = {}
			tempState[team].voiceline = nil
			thisSpectatorBox:setSignText(`Good luck on your mission.`)
			-- Log.info(`Player ${player.name} is arriving`);
			-- Spawn this guy at a spectator box at Y level -200. You must separate spectator boxes for each team. Each wall in a spectator box is 3 studs thick (prevents penetration for rifles). When a spectator box spawns, it will spawn to the left of the last spectator box. Each spectator box is transparent and glass. The inside is filled with no collide water. There is a metal sign bolted to the middle of one of the walls that will say (if defender) `The mission will start when ${playersLeft} more SYNO arrive.`. If they're attacker, they will say `You will protect the homeland! ${playersLeft} players left until you will spawn`. The text resets in the HERE logic.
		end)
		local conn_2 = on_player_died:Connect(function(name)
			local player = players.get(name)
			if not player then
				return nil
			end
			local spawnedAmount = if spawnedAmounts[player.name] ~= nil then spawnedAmounts[player.name] + 1 else 0
			spawnedAmounts[player.name] = spawnedAmount
			local _exp = lastSpawns[player.get_team()]
			local _exp_1 = lastSpawns[player.get_team()]
			local _name = player.name
			local _arg0 = (table.find(_exp_1, _name) or 0) - 1
			table.remove(_exp, _arg0 + 1)
		end)
		local conn_3 = on_player_left:Connect(function(name)
			local player = players.get(name)
			if not player then
				return nil
			end
			local spawnedAmount = if spawnedAmounts[player.name] ~= nil then spawnedAmounts[player.name] + 1 else 0
			spawnedAmounts[player.name] = spawnedAmount
			local _exp = lastSpawns[player.get_team()]
			local _exp_1 = lastSpawns[player.get_team()]
			local _name = player.name
			local _arg0 = (table.find(_exp_1, _name) or 0) - 1
			table.remove(_exp, _arg0 + 1)
		end)
		local conn_4 = on_client_event:Connect(function(playerName, args)
			local player = players.get(playerName)
			if not player then
				return nil
			end
			local eventType = args[1]
			if not (type(eventType) == "string") then
				return player.kick()
			end
			if eventType == "ping_at_position" then
				local pingPosition = args[2]
				if not (type(pingPosition) == "vector") then
					return player.kick()
				end
				if not drones[player.name] or not drones[player.name].Parent then
					return nil
				end
				local _condition = droneNames[player.name]
				if not (_condition ~= "" and _condition) then
					_condition = "fucking dog"
				end
				pingSystem:handlePlayerPing(player, pingPosition, _condition)
			end
		end)
		return function()
			adapterToUse.destroy(DroneFolder)
			adapterToUse.destroy(SpectatorFolder)
			conn_1:Disconnect()
			conn_2:Disconnect()
			conn_3:Disconnect()
			conn_4:Disconnect()
		end
	end
	return {
		createDrone = createDrone,
		kickStart = kickStart,
	}

end

__modulesFolder["initialiseDogRef"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"initialiseDogRef"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local function makeDogRef()
		return {}
	end
	return {
		makeDogRef = makeDogRef,
	}

end

__modulesFolder["initialise_game"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"initialise_game"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local makeDogRef = TS.import(script, game:GetService("ServerScriptService"), "TS", "initialiseDogRef").makeDogRef
	local loadMap = TS.import(script, game:GetService("ServerScriptService"), "TS", "loadMap").loadMap
	local connectIngameSystemsInALoop = TS.import(script, game:GetService("ServerScriptService"), "TS", "connectIngame").connectIngameSystemsInALoop
	local isDeadline = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "isDeadline").isDeadline
	local function initialise_game()
		local dogRef = makeDogRef()
		local terrain_generate_connection
		if isDeadline then
			local _exp = players.get_all()
			-- ▼ ReadonlyArray.forEach ▼
			local _callback = function(player, index)
				player.fire_client("terrain_generate")
			end
			for _k, _v in _exp do
				_callback(_v, _k - 1, _exp)
			end
			-- ▲ ReadonlyArray.forEach ▲
			terrain_generate_connection = on_player_joined:Connect(function(name)
				local player = players.get(name)
				if not player then
					return nil
				end
				player.fire_client("terrain_generate")
			end)
		end
		loadMap(dogRef)
		if isDeadline then
			local _exp = players.get_all()
			-- ▼ ReadonlyArray.forEach ▼
			local _callback = function(player, index)
				player.fire_client("terrain_finished")
			end
			for _k, _v in _exp do
				_callback(_v, _k - 1, _exp)
			end
			-- ▲ ReadonlyArray.forEach ▲
			on_player_joined:Connect(function(name)
				local player = players.get(name)
				if not player then
					return nil
				end
				player.fire_client("terrain_finished")
			end)
			on_player_spawned:Connect(function(name)
				local player = players.get(name)
				if not player then
					return nil
				end
				player.fire_client("disconnect_iris")
			end)
			local _result = terrain_generate_connection
			if _result ~= nil then
				_result:Disconnect()
			end
		end
		connectIngameSystemsInALoop(dogRef)
	end
	return {
		initialise_game = initialise_game,
	}

end

__modulesFolder["loadMap"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"loadMap"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local startMapGenerator = TS.import(script, game:GetService("ServerScriptService"), "TS", "map_generator").startMapGenerator
	local loadPeoplesRepublicOfGermetistan = TS.import(script, game:GetService("ServerScriptService"), "TS", "loadPeoplesRepublicOfGermetistan").loadPeoplesRepublicOfGermetistan
	local isDeadline = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "isDeadline").isDeadline
	local Logger = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "logger").Logger
	local function loadMap(dogRef)
		local Log = Logger.new("load_map")
		Log:info("Loading People's Republic of Germetistan")
		-- heavy operation
		if not isDeadline then
			return nil
		end
		loadPeoplesRepublicOfGermetistan()
		map.set_preset("afghanistan")
		sharedvars.sv_spawning_enabled = false
		chat.set_spawning_disabled_reason("The map is generating. Please be patient.")
		local maxHeight = startMapGenerator()
		dogRef.current = maxHeight + 20
		sharedvars.sv_spawning_enabled = true
	end
	return {
		loadMap = loadMap,
	}

end

__modulesFolder["loadPeoplesRepublicOfGermetistan"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"loadPeoplesRepublicOfGermetistan"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local isDeadline = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "isDeadline").isDeadline
	local function loadPeoplesRepublicOfGermetistan()
		if not isDeadline then
			return nil
		end
		--[[
		 
			    碜ꕗ罬受Ⓛ燣朷脄ﯙㆤፋ뮭䂒䈊唵啕諾࠲雘뱧壚蛯ꢠ䵃쨪畬ばヘ⼤쑎ﱢ鬟蕴荽뮁垦䔢ኈ軅趝㗕ዼ鍖渗꧒ﻨ㨭谉뚝ﯼ⌶ണ답쿧鱳켹콁䡖랺懭㪄﹠梽↻긶뒔첨慿쮒틌虬䙝␳됵໮鵭綶퓰敩描궽跪옖姏괮ⲷ㖶鐚穚撵섆囵땭඲쇙옿똚쁤节ꅵ駡﫠ⱨ쿍巿뎟₴勃퀳ࠝ髽制㢳泯༐穤叇殝묺ờ叓틑阮讻皾哳髧퇕뵳佷ﮫࠑ묻瞵睷泟褖Œ퉿㓩㾗◷뼫뀪飴齌𢡊퐤ﶇ䧺祁ାỘ᷉ꨝ삖﹟ࢋ̩ፐᆠ캤ౖ৖✳㋞艜疷短湿ड嶺潴ꖼ宂搈榺幼덽쾞軮鴯㾵晍ﶺ﫵硲✶蠜굝彟ﾕ⏘֛㘶吢䡒ㆂ㾃䅭⢇朣븩葶샅ꮞ뷋晚柦౸ﶎ慮晰噭ᢜﯤ杷筏锓쑢ꊾ圍즿삦╗ꪊ昩﹠햢ꋙ쏻䇅뷬ퟗສ⻩௧▵꓏㮾꬯뭳璻檄笏龏꿸캚얲ﵨ凩솏﹎ﰓꎢ勺잦仯垧ꘃ캊痖⥗惄稁啞ꤪꭃ诤ܿ﫛䌵舢ᥰ䕜ě겾ᕰ薦ȣ꬏⑽뾋띎忼烹佻⸐謫๵ᵙ輸￾沴ᄎ嶣ﶮ쀾칥ඹ肳䩹춹ꇼ厞峺齷髀쬝✢쓹꟪꣄㰛굓卖㲃蝔鬢䓃쬻䮕鵧䅥嵊敟㔱ᩜ焇硩ಅᓚ㚲剖珹컬Ꞑ絔瓧쪵佮뿵묓篎핯㺼寿痸碿ꩤ쟜闛澡䖲捇힥ﱌ挒讈ᶲṛ谨橙ླྀ众쀋ᖛ麪쯁ﭦ숚룺律꠫袅탅년䚨᠙ᏻᑗ偱ড়м藤犮턩휸䄓꼼쪕ﵕ㟴烉䨓ㅾ蝯⭰裘䞜捞⼋氼ꌺ﬏걔罱醿ꑏ䅾Եꊢቔɤᮬ鞜咒⎗耬쮑ǲᲙ肝눜뤜锡䊆䠥ᧀ㮰곟Ჰ蹂먂깑됲ꏻᢔ蟒㪪᲻硱ꓟ褴ࡕ셺氜嗂ꡘ㳊鴞ୀ핔୚ꄩ華땿Ⲏ딪쾝恒행㊭素꛵쁔黇⣓㌏젤䝋搸遇ä篓껀柸뀰抓쵣폜⦬⏢ḵὃጬꁽ勆񫨤ᚸ流鲛㚁밬䝦턲꓉酿ࢦ곽䣔굝戱뺼邬痂눺辩宔ݢ降쒼㰧웽根꫉讹ٽ䍖ヿ蕙࿍ﭬ믇脔ꌃᡗ噭ṣ⵺摴ᙤ球猘밠㾞⎟芉뀺䜾譖ꌺᦶᝉ刺翅閼꿡貟뼄蘆⦆铡Ȱ겕抸ﲠಿ蟁騠㩞춳ᄋ⫾招栘瞤ⵞ鎬佫曇筏豻ԍ痘ꉣⷉ냙伲改幺蛍冽볗ꇠ豲庳궩힁鼖赥㥋㛵㻆쒳뚓䛹䂄Ⳳ岓뒁싁ᄢ䙽놘⹮鮷ᤌ㔫鑊㬑᱊댍٩婁傔光뗥憸Ջ胨❍㦞ฆ⥮芠ᱠ村⠀ꔨ∰융􎁸赜덂㫠ﺘ蛍㎡툆屁菭䙹⛗놸霷▴䰌䜎⧰喻쇌ᔄ쉈톛飙駐끽넄鬠䄨鏧昕⯯딍픪פּ⊑飰竂ờ䴅쑪ಳ䗱Ꞩ率誣뢐菣⢛崾샄戮犛廏⪚຅⢹㷍夾㲾偎唳텤韷䔘ꡐ궉⧷䒠᛿᳕┠ι檟蚬탙ᘊᤤ䉍᥏隒뛻ސ恲菷멏械黖ఀ䄪꒤ࠕᶤ윅씾虏〚혙엕늮猪鱱骘첺媹瀳喳㉽凹⹼沔לּㄽ덵毸黎Ố䈱ⵡ碏涟忛饞똻㢑铨ᘮⶮ쎜嚦ᕊ⻛萡쒟ꅂᴈ䗭섎欙﹆縜슌灆땦鿺䍏䊯该㖻艐ჳ涞閾綌様鳯愐؅ﻜ죘佒Ꮒ钠ꦡ술̉ன诅ୠ蔸⌎躺ㄿ룰룁မ岌澘㰀咡㗳㸶눥ᱦ좼讒鹀絞겧﵌葎狱汲뒑瀸豄던㩲䊨貓⚡⳯⮆椛챂玓぀㴦௉ປᣵ㵯⦞ㆱ練ᩯᷓᇦ颭겂욁ʦ눩橦輶蝮մ߉竝宙ꄰ盚⭡㥀髌✶쟝泼ϡ行⎑輸ᭃ谬ꭍ凰븉ᥕ鑚呹搓먘ｂ⚷ᰱ释궈藓ᎎ拴䧚ꣂά䟺扡랇밇巸䫘룙ィ⿃浖⤈娩䱣℅烇⒔ԇᚸ듃య䃓ᢖ顈붌뿶츀뱙䆤뻢祖株ਕ㶡ಊ㯒᝷鮢ᇳ劍씭㣟겄⚵Ꮲ堬助팰쏩㈈숸耘⢕娢㖞䓊ᶥᄂ㖪ꑴ㔖麁繉┇ቃ⭱忓胅鳒얿檂Ⴎ瓒ꮳ㕀⧁肰ꭔ剥፳쟹틂༿熆哅찗顸꣇䶑哊憪퉁専絬岫䥣팡鰕㲉╊⛮䥤⨬ࡍષ䑍꫱䬤㍀戉麅賂눋浹ᮼ徿ꛏ淂拜뺐ᚷ斅♑綧亃缂懤᰻꼮淳銴䕙婗⻮뎉藑ℸⲬⒼ╍槍푊尳缜솴枇姸ẇ脖ཊ䚒쑝擦퀼橄ꠅ䋂をЕ㩘ꨄ눳術ͼ䠵뮄ᮙ턧ꖒ㟱꒫騙以㊽鑰챬터愡靈␓䭨⭳睃뱖珆ꈭ뎖㋨汙䆪ẳ獎ꨈ튵螟ꦩ暃蜄彶驉꘿㷂氾銁翀蜭蒢ฒ꥟쏸㫽쮈寱챿ￌ洚
		    
		]]
		load_modfile("eJylV39sU9f1vyTBceNnN4EE+9kxpBNLu61AkkIKVTVVVeeG+r0IMpbYvGdY2obvqKBNQ8oqdWwwcDDYLyTETvximx+FdIN9u4FXpkUiEoiOxY2dNdUS/JNWbhep0v7oOi2MCbad+/wjNvV7DSOy9e6595zP55xzzznPQUhWt7ph7eq6OoT+YGi9IbuuNrSUzKhhf8uS0syGbEZdJDO0NQ7unW19ttTwZWljz629jerGFlnPrS4stzW2lBp6WmS16sbBBtmOVvXzbbVtDbLB2cY/thrAZO+Q4eeCgqF1meH64Cxoz81d/93Qs58gtPf63K1Sw9AzCB2a/VI2OLNs7w8QemRTx2uduzoe3VPT0tH5xou7dr5U89qOmuff6Nrd0dW9c093+6sIEd0duzt3tXd3bN/d3okWAVLSfzTpP5f0DyX380m/K+k/sCrpP5j0n0z6z9Qk/YfhkfQfSfp5QQs+HtgdyaodwJb+XwiLAykTUO6vEaDOpAxWCdYnMzLeglx1t3ftbn8JIfmrb3SlvFuCZAhpul58s33Pno7unS8/tWZN/br69eueeHLd2ic2iBytXV9f/5Uj2AWb9U82NlQiSFIxgj+DQW0oh2cjvimEdsDF3KrdBKuevctmWmfmDHj9jmFuZnBWbRic++Rnd3tPlRPEYqK+727Z+fPfVw311Mm/wKYlV6qK3j5mKf5g1aKi2cP7QcXter3s19cOqi7p3sfn7wvnJbXnDqTPO76rL7tzdLtqhHsPn4+v+M6a54jFsv1oUenBj/5O/BOjovp3x6ZO7+OsV6emA86KddYpV2DEegFVXqkqq0OL5Ac/+ttDNYIiGXBFXAEbrL4VcIWmAiPclKsPJH2/i7dOX/xw+U97LhCLKw51HVn6wuyz//7tfmy0EQ5do/2uwD7OZQ25+JGAs0p5zbmh/FOeXPqfd5rAyx0nIsT54/+n6qjEPButU1NW7t08g4dUmyJEw8s7S5WdZ0FlXUplX+iqNTEaXHEH6qt4aQyFFNo2slJWc/nO7KeQfVR058q1T26/9ePquxN7zt7+1W8+vOPlW/91+O1deL+qZMfcldtvoUWy9R9jR9el/ExjEouI7dMdsh5bjChqWQ94TxfAC+bhFZueqsvB+2bCGrj6+dioK4iF0MWxREaoGBnlLxP7FFdQcQncBDyF5HKu0SnXOEETrzzKlf1VN/RwyUoT7NPYqTF+3yXrFIdv6ZIrcIjYR5xjXi8LbDyjOvsPrFR/cezIkb+kT0F+BTWiohJUAmQbrJec2HdUkiOXgCzLkeXQAfIcmYCdshy5HJUhQobgekglGcA7sKzfHLCOQroCrlHuM7Qyo/sYlIfSOqocu3hxpN+JNAhVwXpsHFXCqFg8yp0eC0DVVAtaoSn6tLV/LI61KuiRz53ocWBS5THViTKtfSCm9cBUnsf0tCjTMw/IJEdLZDiQRwDke9OuwGf4sDDic/cgYpPNY9PcKawj4h41H0MTLOvHoH1Sxtlu3iTi2xa4+cqcmzaBvCxHZtEypMmRfwim2rys/UjUrV1iMb68kKx1wrI6j6lblOnNB2L6CcS8PCfG/Wg5qsmLuQZ9Q1Yw/4VZD837bLvHgRSjAxhX5jD0AVZtHmMteux/ZHQWZHQD47dzGLwgP54jn4KJsDpHPotWozoZthdJ+f9/xZW84hav4YyfvwSGBimG9x6U4QIwrJViuPygDL+HwZog2YQ6Xs2zEQsq/mLb+DDjTWgYd6QtXu2Jk6xPa2bHe0+MewUNddiiY+JxLcnyTbDZTzLeqGU5XnqGzVG9vNeh4IxyXrOtqdeBnxaNZTlLNvXaPD7GxLO2k0b5QIT3RizyXJO0gcLBESJGfbGYLm6btxkMNSuUSjsRHEqzDQZpWkFQlFFJteVhuAVLgOgnTeFtOZ4OBilugqAcYOVQZ1EoAKUo+HIiMMc12/jceI1cs0I64P6Yhs0zodIGXEGD7UZ5JtexuJc3JbRMDEcOKfBVu9lEwcwVBMJI0ZuY2ZnQsH2xBOMDmyBBKOTO6E2T52YVK++1Dev11Sr7RCKRmPB6wh7dTQXEagyz8YhF8aeo+WGKo7iQg+Mom10+wMRiLnKbXs/yLeYF2NIqmg6F4GoouT3NWT48vlBOVTPRZJf3RRioUK2JKfdEoBb/HNUlIB++ap/ZmIas0NkWChkkQk0ZT5aStvvwBAeQYHKD97pPaLCe1gwAQSqkpAgVHaTHBcU+hk8wGtYZxdXioLKu+haccZqYzLpauXAzVbMyfVH5LnxslPs8MT2zdWv4ns4e0EIxLWF4j94MbZ9f25letjs4keoelOjnwhYuLa7DnFamFUroZi7bhCHarsSfoUIdCEXtwQ5rGf5GfhzCjHBGtWaf+kNPQq+L5TW7glAQ822elb7a4H2Madic72EQBgX+3MjYT1ITwpSgqaHCIAMJC6mLxQtghTgjDo66MT+48LjB8d4QGVyMb5j1xDwAVKE18z42siUcZsi8i5KeQH1erKfj2fj4/UzqnIRO6+Jy8WxytJFwOIxEs1g6ckKojJMmoSzvK4btwmkbzEJzkzBAPSYLyQ6bGPU9bymeMbHqWPqwGm8d0+uiEeaYrayC8THGgfSRAqayKWpmjzb1AoduBXQHyXrdW5mhMHbaK2E5QJrMJzbH3Wz8A+H6CCOR+sIbQ4wsq01R8L4JGVWUWlR5AIJkE7oY/0ImtxwxkcqtiIXTE45i9EnaqMIfcUf6YmG3h7wHXfhK2LjZMKMvw+rN8I5tVikIWinhTExjIQVwxySUBQcWuNjFtMMML0DTGJaYSL2Mv/bOALxZQaS+4vpQ96ZoKu2TChU9oQyKO9IXd5uiEfNSjcUtON+shCa1E+LgrlgsUqnTMMPpMgjCOIAYKJVaIjWeRModpRECNaqkdDUWnoF+SSUHEkMrceWIX9OAxZzSxb9qghCudNKrszVAKcGAsKtUUmUTc8f59LXSwuBLDz9xhlTFzBeYeKjHTZFUymGq0kFcAuLAfWxcq0lj0yGcFTyJJUom7klkKiwITQq3RE2q8UskM0BiCZ6F+UiyC215G7xfv6bPbcJi3L6QFrdlhSZRfadOg38CYeT0Uhw7ry5t85K0RVlaVy7us4mF0SE4LKwkvCVNac3USlwzfxzBtGeHWfjnwx6HgRYPSthlRpLEXWTm0DxqRKgFQsLx1DCSBBU6WKoEsjPqfohTA3zhCUg1u4QbmdEnpZI38aSrmhlO5TK9lHDMbNEw2DVhIZdIJBNLaCtz6jp3Q7xWc8aiLbOW2xcy6GxZQaoes3NOqgjStYef4typqWaDhwRfdppJpj89wmw+koF/wIct9jiEog4SqV/D+PeTOv3LiFvxzH//zG0aag==")
		map.set_map("template_map")
	end
	return {
		loadPeoplesRepublicOfGermetistan = loadPeoplesRepublicOfGermetistan,
	}

end

__modulesFolder["map_generator"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"map_generator"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local EgoMoose = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "EgoMoose").EgoMoose
	local createTerrain = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "createTerrainFromVerticesUsingAdapter").createTerrain
	local PerlinNoise = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "PerlinNoise").PerlinNoise
	local biomeBox = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "biomeAndStructureRegistrySystem").biomeBox
	local translateTerrainOrientationForStructureBonding = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "translateTerrainForStructureBonding").translateTerrainOrientationForStructureBonding
	local NuristanBuildings = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "biomes", "NuristanBuildings").NuristanBuildings
	local isDeadline = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "isDeadline").isDeadline
	local Logger = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "logger").Logger
	local Tree = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "biomes", "Tree").Tree
	local NuristanStandardBiome = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "biomes", "nuristanStandardBiome").NuristanStandardBiome
	local SniperWindowRoomHandler = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "nuristanHandler", "sniperWindow").SniperWindowRoomHandler
	local LivingRoomHandler = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "nuristanHandler", "livingRoom").LivingRoomHandler
	local getWorldRoot = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "getRoot").getWorldRoot
	local adapterToUse = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "adapterToUse").adapterToUse
	local assign = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Util").assign
	local _config = TS.import(script, game:GetService("ServerScriptService"), "TS", "config")
	local NuristanBuildingsConfig = _config.NuristanBuildingsConfig
	local StandardNuristanConfig = _config.StandardNuristanConfig
	local TreeConfig = _config.TreeConfig
	local PART_SIZE = _config.PART_SIZE
	local PARAMS = _config.PARAMS
	local RESOLUTION = _config.RESOLUTION
	local POSITION_OFFSET = _config.POSITION_OFFSET
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
	local function startMapGenerator()
		local worldRoot = getWorldRoot()
		local Log = Logger.new("map_generator")
		local workspace = worldRoot
		local offset = Vector2.new(math.random(1, 10e6), math.random(1, 10e6))
		local noiseData = PerlinNoise.new():generate(PARAMS.scale, RESOLUTION, offset, PARAMS.exaggeratedness, PARAMS.lacunarity, PARAMS.persistence, PARAMS.octaves, PARAMS.power)
		local wedgesFolderToDestroy = adapterToUse.findFirstChild(workspace, "Wedges")
		if wedgesFolderToDestroy then
			adapterToUse.destroy(wedgesFolderToDestroy)
		end
		local wedgesFolder = adapterToUse.newInstance("Folder")
		adapterToUse.setProperty(wedgesFolder, "Name", "Wedges")
		adapterToUse.setProperty(wedgesFolder, "Parent", workspace)
		local standardBox = biomeBox.new()
		local translateTerrain = translateTerrainOrientationForStructureBonding.new({
			orientationSubtraction = Vector3.new(0, 0, -90),
		})
		standardBox:registerModifier(NuristanStandardBiome.new(adapterToUse, StandardNuristanConfig, wedgesFolder))
		standardBox:registerModifier(NuristanBuildings.new(adapterToUse, translateTerrain, NuristanBuildingsConfig, wedgesFolder, function(thisThing)
			return { SniperWindowRoomHandler.new(thisThing, thisThing.config.sniperWindowDoorway), LivingRoomHandler.new(thisThing) }
		end))
		standardBox:registerModifier(Tree.new(adapterToUse, TreeConfig, wedgesFolder))
		local CustomTriangleFunc
		do
			CustomTriangleFunc = setmetatable({}, {
				__tostring = function()
					return "CustomTriangleFunc"
				end,
			})
			CustomTriangleFunc.__index = CustomTriangleFunc
			function CustomTriangleFunc.new(...)
				local self = setmetatable({}, CustomTriangleFunc)
				return self:constructor(...) or self
			end
			function CustomTriangleFunc:constructor(adapter, EgoMoose, parent, resolution)
				self.materialise = function(thisThing, a, b, c)
					-- when given to createTerrain, it calls self:materialiseTriangle (our custom function set in its constructor)
					-- then it becomes materialiseTriangle(self, a, b, c)
					-- but roblox-ts for some god forsaken reason does not recognise this
					local _binding = thisThing.EgoMoose.draw3dTriangle(a, b, c)
					local AData = _binding[1]
					local BData = _binding[2]
					local WedgeA = thisThing.adapter.newInstance("WedgePart")
					local WedgeB = thisThing.adapter.newInstance("WedgePart")
					thisThing.adapter.setProperty(WedgeA, "Anchored", true)
					thisThing.adapter.setProperty(WedgeB, "Anchored", true)
					thisThing.adapter.setProperty(WedgeA, "Parent", thisThing.parent)
					thisThing.adapter.setProperty(WedgeB, "Parent", thisThing.parent)
					assign(WedgeA, AData, function(item, key, value)
						return thisThing.adapter.setProperty(item, key, value)
					end)
					assign(WedgeB, BData, function(item, key, value)
						return thisThing.adapter.setProperty(item, key, value)
					end)
					self.count += 1
					if self.count % 1000 == 0 then
						if isDeadline then
							local _exp = players.get_all()
							-- ▼ ReadonlyArray.forEach ▼
							local _callback = function(player, index)
								player.fire_client("biomeLoadingStatus_1", self.count / self.total)
							end
							for _k, _v in _exp do
								_callback(_v, _k - 1, _exp)
							end
							-- ▲ ReadonlyArray.forEach ▲
						end
						task.wait(0.05)
					end
					return { WedgeA, WedgeB }
				end
				self.adapter = adapter
				self.EgoMoose = EgoMoose
				self.parent = parent
				self.resolution = resolution
				self.total = self.resolution.X * self.resolution.Y * 2
				self.count = 0
			end
		end
		local maxHeight = -math.huge
		local function generate()
			-- work on this later
			-- prob some bug because it did work earlier on client, but this code does not work or replicate to client from a server
			local newTriangleFunc = CustomTriangleFunc.new(adapterToUse, EgoMoose, wedgesFolder, RESOLUTION)
			local total = RESOLUTION.X * RESOLUTION.Y
			local count = 0
			local createTerrainDefault = createTerrain.new(function(thisData)
				count += 1
				if count % 250 == 0 then
					if isDeadline then
						local _exp = players.get_all()
						-- ▼ ReadonlyArray.forEach ▼
						local _callback = function(player, index)
							player.fire_client("biomeLoadingStatus_2", count / total)
						end
						for _k, _v in _exp do
							_callback(_v, _k - 1, _exp)
						end
						-- ▲ ReadonlyArray.forEach ▲
					end
					task.wait(0.05)
				end
				local _self = thisData._self
				standardBox:executeAllModifiers(thisData._self, thisData)
				local computedHeight = thisData.data.averageHeightSized * PART_SIZE
				if computedHeight > maxHeight then
					maxHeight = computedHeight
				end
			end, EgoMoose, adapterToUse, wedgesFolder, newTriangleFunc.materialise)
			return createTerrainDefault:createTrianglesFromData(noiseData, RESOLUTION, PART_SIZE, POSITION_OFFSET)
		end
		Log:log("Generating Afghanistan map.")
		generate()
		Log:info("Done.")
		return maxHeight
	end
	return {
		startMapGenerator = startMapGenerator,
	}

end

__modulesFolder["pingSystem"] = function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"pingSystem"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	-- export class RateLimit 
	local PingSystem
	do
		PingSystem = setmetatable({}, {
			__tostring = function()
				return "PingSystem"
			end,
		})
		PingSystem.__index = PingSystem
		function PingSystem.new(...)
			local self = setmetatable({}, PingSystem)
			return self:constructor(...) or self
		end
		function PingSystem:constructor(config)
			self.config = config
			self.lastPingedTimeByPlayerName = {}
		end
		function PingSystem:handlePlayerPing(player, pingPosition, playerDroneName)
			local _condition = self.lastPingedTimeByPlayerName[player.name]
			if _condition == nil then
				_condition = 0
			end
			local lastPingTime = _condition
			if os.time() - lastPingTime < self.config.pingCooldownSeconds then
				return nil
			end
			self.lastPingedTimeByPlayerName[player.name] = os.time()
			local playerTeam = player.get_team()
			local _exp = players.get_all()
			-- ▼ ReadonlyArray.forEach ▼
			local _callback = function(targetPlayer)
				targetPlayer.fire_client("player_ping", playerDroneName)
				if targetPlayer.get_team() ~= playerTeam then
					return nil
				end
				targetPlayer.fire_client("team_ping", pingPosition)
			end
			for _k, _v in _exp do
				_callback(_v, _k - 1, _exp)
			end
			-- ▲ ReadonlyArray.forEach ▲
		end
	end
	-- const player = players.get(playerName);
	-- if (!player) return;
	-- const eventType = args[0];
	-- if (!typeIs(eventType, "string")) return player.kick();
	-- if (eventType === "ping_at_position") {
	--     const pingPosition = args[1];
	--     if (!typeIs(pingPosition, "vector")) return player.kick();
	--     const thisLastPingedTime = lastPingedTime[player.name] || 0;
	--     if (os.time() - thisLastPingedTime < 3) return;
	--     lastPingedTime[player.name] = os.time();
	--     players.get_all().forEach((thisPlayer: Player, index: number) => {
	--         thisPlayer.fire_client("player_ping", droneNames[player.name] || "fucking dog");
	--         if (thisPlayer.get_team() !== player.get_team()) return;
	--         thisPlayer.fire_client("team_ping", pingPosition);
	--     })
	-- }
	return {
		PingSystem = PingSystem,
	}

end

task.defer(function()
	local __modulesFolder = nil
	local __customTS = nil
	local getRobloxInstancePath = nil
	local matchesRuntimeLibPath = nil
	local resolveModuleRelativeSegs = nil
	local __robloxTree = nil
	local __OUTPUT_DIR_MAKER = nil
	local __runtimeLibPath = nil
	local __modulesCachedValues = nil
	local old_require = nil
	local old_game = nil
	local script
	script = newFakeInstance({"main"})	local newFakeInstance = nil

	-- Compiled with roblox-ts v3.0.0-dev-9165cde
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local Logger = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "logger").Logger
	local initialise_game = TS.import(script, game:GetService("ServerScriptService"), "TS", "initialise_game").initialise_game
	local Log = Logger.new("main")
	--connect();
	Shared.should_initialise_game = true
	on_client_event:Connect(function(playerName, args)
		local player = players.get(playerName)
		if not player then
			return nil
		end
		local eventType = args[1]
		if not (type(eventType) == "string") then
			return player.kick()
		end
		if eventType ~= "initialise_game" then
			return nil
		end
		local _value = Shared.should_initialise_game
		if not (_value ~= 0 and _value == _value and _value ~= "" and _value) then
			return player.fire_client("initialise", false)
		end
		Shared.should_initialise_game = false
		player.fire_client("initialise", true)
		local Log = Logger.new("main::initialise_game")
		Log:log(playerName, "has started the initialisation function.")
		initialise_game()
		Log:log("initialise_game has finished")
	end)

end)
