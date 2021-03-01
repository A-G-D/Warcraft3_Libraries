--[[ mapbounds.lua v1.0.0 |


	Description:

		Nestharus's WorldBounds ported into Lua, with few simple but useful
		additions. Aside from providing map boundary data thru variables,
		also provides premade functions for checking whether a coordinate
		is inside map boundaries, getting a random coordinate within
		map boundaries, and getting a bounded coordinate value.


	Requirements:

		- None

]]--
--[[

	API:

		Prefixes:
			MapBounds
			- Refers to initial playable map bounds
			WorldBounds
			- Refers to world bounds

		Variables:
			number: <Prefix>.centerX
			number: <Prefix>.centerY
			number: <Prefix>.minX
			number: <Prefix>.minY
			number: <Prefix>.maxX
			number: <Prefix>.maxY
			rect: <Prefix>.rect
			region: <Prefix>.region
			- These variables are intended to be READONLY

		Functions:
			function <Prefix>:getRandomX() -> number
			function <Prefix>:getRandomY() -> number
			- Returns a random coordinate inside the bounds

			function <Prefix>:getBoundedX(number: x, number: margin=0.00) -> number
			function <Prefix>:getBoundedY(number: y, number: margin=0.00) -> number
			- Returns a coordinate that is inside the bounds

			function <Prefix>:containsX(number: x) -> boolean
			function <Prefix>:containsY(number: y) -> boolean
			- Checks if the bounds contain the input coordinate

]]--
MapBounds = setmetatable({}, {})
WorldBounds = setmetatable({}, getmetatable(MapBounds))

do

	local mt = getmetatable(MapBounds)
	mt.__index = mt

    function mt:getRandomX() return GetRandomReal(self.minX, self.maxX) end
    function mt:getRandomY() return GetRandomReal(self.minY, self.maxY) end

	local function GetBoundedValue(bounds, v, minV, maxV, margin)
		margin = margin or 0.00

		if v < (bounds[minV] + margin) then
			return bounds[minV] + margin
		elseif v > (bounds[maxV] - margin) then
			return bounds[maxV] - margin
		end

		return v
	end

	function mt:getBoundedX(x, margin)
		return GetBoundedValue(self, x, "minX", "maxX", margin)
	end
	function mt:getBoundedY(y, margin)
		return GetBoundedValue(self, y, "minY", "maxY", margin)
	end

	function mt:containsX(x) return self:getBoundedX(x) == x end
	function mt:containsY(y) return self:getBoundedY(y) == y end

	local function InitData(bounds)
		bounds.region = CreateRegion()
		bounds.minX = GetRectMinX(bounds.rect)
		bounds.minY = GetRectMinY(bounds.rect)
		bounds.maxX = GetRectMaxX(bounds.rect)
		bounds.maxY = GetRectMaxY(bounds.rect)
		bounds.centerX = (bounds.minX + bounds.maxX)/2.00
		bounds.centerY = (bounds.minY + bounds.maxY)/2.00
		RegionAddRect(bounds.region, bounds.rect)
	end

	local oldInit = InitGlobals
	function InitGlobals()
		oldInit()

		MapBounds.rect = bj_mapInitialPlayableArea
		WorldBounds.rect = GetWorldBounds()

		InitData(MapBounds)
		InitData(WorldBounds)
	end

end