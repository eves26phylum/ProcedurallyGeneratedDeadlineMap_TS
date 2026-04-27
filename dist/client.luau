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
		-- Root sentinel — WaitForChild still works, Parent stops recursion.
		inst.Parent = {
			__path = {},
			Name = "",
			WaitForChild = function(self, name) return newFakeInstance({ name }) end,
		}
		inst.is_fake_instance = true
	end
	return inst
end

local game = {
	GetService = function(self, name)
		local inst = newFakeInstance({ name })
		inst.__isService = true
		return inst
	end,
}

-- Fake require: only replicates TS.import via path-table traversal.
-- All other TS methods (Promise, async, await, instanceof, …) are NOT
-- replicated — the module body restores old_require after !customFinish
-- for anything that genuinely needs the real RuntimeLib.
local require = function(_ref)
	return {
		import = function(_ctx, startModule, ...)
			-- Walk :WaitForChild() chain to build the target __path.
			-- "TS" segments are node_modules scope artifacts; skip them.
			-- If startModule is a game service, treat it as __modulesFolder root.
			local current = startModule.__isService and newFakeInstance({}) or startModule
			for i = 1, select("#", ...) do
				local seg = select(i, ...)
				if seg ~= "TS" then
					current = current:WaitForChild(seg)
				end
			end

			local pathSegs = current.__path
			local cacheKey = table.concat(pathSegs, "\0")

			-- Return cached value if already loaded.
			if __modulesCachedValues[cacheKey] ~= nil then
				return __modulesCachedValues[cacheKey]
			end

			-- Traverse __modulesFolder by path segments.
			local folder = __modulesFolder
			for _, seg in ipairs(pathSegs) do
				folder = folder[seg]
				if folder == nil then
					error("TS.import: module not found at path \"" .. table.concat(pathSegs, "/") .. "\"")
				end
			end

			-- Call factory, cache, return.
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
	local game = nil
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
				c = a
				a = c
			elseif acd > bcd and acd > abd then
				a = b
				b = a
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
