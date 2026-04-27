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
	end
	return inst
end

local game = {
	GetService = function(self, name)
		return newFakeInstance({ name })
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
			local current = startModule
			for i = 1, select("#", ...) do
				current = current:WaitForChild(select(i, ...))
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

__modulesFolder["fat"] = __modulesFolder["fat"] or {}
__modulesFolder["fat"]["fat"] = __modulesFolder["fat"]["fat"] or {}

__modulesFolder["fat"]["fat"]["module"] = function()
	local script
	script = newFakeInstance({"fat", "fat", "module"})
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = nil
	local __modulesFolder = nil
	--!customFinish
	-- Compiled with roblox-ts v3.0.0
	local function makeHello(name)
		return `Hello from {name}!`
	end
	return {
		makeHello = makeHello,
	}

end

do
	local script
	script = newFakeInstance({"fat", "main"})
	-- Compiled with roblox-ts v3.0.0
	local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
	local makeHello = TS.import(script, script.Parent, "fat", "module").makeHello
	-- !deadline-ts.customFinishSector_FinishModulesEnd
	local require = old_require
	local old_require = nil
	local newFakeInstance = nil
	local game = nil
	local __modulesFolder = nil
	print(makeHello("main.client.ts"))
	-- class A {
	--     constructor(get_head_cframe: () => CFrame) {
	--     }
	--     update() {
	--     }
	--     input = new Vector3();
	--     rot_x = 0;
	--     rot_y = 0;
	--     min_roll = 0;
	--     max_roll = 0;
	-- }
	-- register_camera_mode("a", A)
	-- players.get("flanker2000Y2K")?.get_weapon_data_from_character("primary").client_data.name
	-- on_server_event.Connect((args)=> {
	-- })
	-- on_player_joined.Connect((name) => {
	-- })
	-- new Promise(() => {});

end
