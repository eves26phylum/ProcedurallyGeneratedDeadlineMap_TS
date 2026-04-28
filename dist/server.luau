-- bundled with deadline-ts (no you cannot use rbxts modules right now)
function assert(condition, messageIfFalse)
    if not condition then error(messageIfFalse or _VERSION.." assertion error") end
end
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
	end
	return {
		assign = assign,
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
		function Biome:constructor()
			self.priority = -1
			self.name = "?"
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
	local EgoMoose = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "EgoMoose").EgoMoose
	local createTerrain = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "createTerrainFromVerticesUsingAdapter").createTerrain
	local robloxAdapter = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "robloxAdapter").robloxAdapter
	local deadlineAdapter = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "deadlineAdapter").deadlineAdapter
	local PerlinNoise = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "PerlinNoise").PerlinNoise
	local biomeBox = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "biomeAndStructureRegistrySystem").biomeBox
	local assign = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "Util").assign
	local Biome = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "biome").Biome
	local humanConfig = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "humanConfig").default
	local translateTerrainOrientationForStructureBonding = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "translateTerrainForStructureBonding").translateTerrainOrientationForStructureBonding
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = old_game
	local old_game = nil
	local __modulesFolder = nil
	local isDeadline = get_map_root ~= nil
	local adapterToUse = if isDeadline then deadlineAdapter else robloxAdapter
	local workspace = if isDeadline then get_map_root() else game:GetService("Workspace")
	local PART_SIZE = 100
	local MAP_SIZE = Vector2.new(10000, 10000)
	local RESOLUTION = Vector2.new(math.round(MAP_SIZE.X / PART_SIZE), math.round(MAP_SIZE.Y / PART_SIZE))
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
	local NuristanStandardBiome
	do
		local super = Biome
		NuristanStandardBiome = setmetatable({}, {
			__tostring = function()
				return "NuristanStandardBiome"
			end,
			__index = super,
		})
		NuristanStandardBiome.__index = NuristanStandardBiome
		function NuristanStandardBiome.new(...)
			local self = setmetatable({}, NuristanStandardBiome)
			return self:constructor(...) or self
		end
		function NuristanStandardBiome:constructor(config)
			super.constructor(self)
			self.priority = 100
			self.config = config
			self.name = "nsb"
		end
		function NuristanStandardBiome:getColourAndMaterialFromHeight(height)
			if height < humanConfig.grassDeepness then
				return self.config.grass()
			end
			return self.config.desert()
		end
		function NuristanStandardBiome:generate(yourSelf, yourCell)
			local operateOnThisTriangleInstance = function(data, triangle)
				local height = data.data.averageHeight
				local propMap = self:getColourAndMaterialFromHeight(height)
				assign(triangle, propMap, function(a, b, c)
					yourSelf.adapter.setProperty(a, b, c)
				end)
			end
			operateOnThisTriangleInstance(yourCell, yourCell.triangles[1][1])
			operateOnThisTriangleInstance(yourCell, yourCell.triangles[1][2])
			operateOnThisTriangleInstance(yourCell, yourCell.triangles[2][1])
			operateOnThisTriangleInstance(yourCell, yourCell.triangles[2][2])
		end
	end
	local translateTerrain = translateTerrainOrientationForStructureBonding.new({
		orientationSubtraction = Vector3.new(0, 0, -90),
	})
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
		function NuristanBuildings:constructor(config)
			super.constructor(self)
			self.priority = 100
			self.config = config
			self.name = "NuristanBuildings"
		end
		function NuristanBuildings:generate(yourSelf, yourCell)
			local operateOnThisTriangleInstance = function(data, triangle)
				-- const height = data.data.averageHeight;
				local translatedOrientationForStructurePlacement = translateTerrain:Translate(triangle.Orientation)
				local degreesTiltedOfSteepness = translateTerrain:GetSteepnessInDegrees(CFrame.fromEulerAnglesXYZ(translatedOrientationForStructurePlacement.X, translatedOrientationForStructurePlacement.Y, translatedOrientationForStructurePlacement.Z))
				local isALivableDegree = degreesTiltedOfSteepness < humanConfig.maxLivableSteepness
				if not isALivableDegree then
					return nil
				end
				triangle.Name = "I'm a building!"
				-- Later: Influence from surrounding triangles to see if they have a nuristan building set on them, and not this triangle already having some sort of other structure
			end
			operateOnThisTriangleInstance(yourCell, yourCell.triangles[1][1])
			operateOnThisTriangleInstance(yourCell, yourCell.triangles[1][2])
			operateOnThisTriangleInstance(yourCell, yourCell.triangles[2][1])
			operateOnThisTriangleInstance(yourCell, yourCell.triangles[2][2])
		end
	end
	local stdnuristanconfig = {
		grass = function()
			return {
				Material = Enum.Material.Grass,
				Color = Color3.fromRGB(43, 219, 84),
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
	standardBox:registerModifier(NuristanStandardBiome.new(stdnuristanconfig))
	standardBox:registerModifier(NuristanBuildings.new({}))
	local createTerrainDefault = createTerrain.new(function(thisData)
		local _self = thisData._self
		standardBox:executeAllModifiers(thisData._self, thisData)
	end, EgoMoose, adapterToUse, wedgesFolder)
	local triangles = createTerrainDefault:createTrianglesFromData(noiseData, RESOLUTION, PART_SIZE, POSITION_OFFSET)

end)
