--[[ getunittypecollisionsize.lua v1.0.0


	Description:

		Get default collision type of a unit type


	Requirements:

		- None


	API:

		function GetUnitTypeCollisionSize(unitTypeId) -> number

]]--
do
	local t = {}

	local function GetCollisionSize(unitTypeId)
		local u = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), unitTypeId, 0.00, 0.00, 0.00)
		local m = BlzGetUnitCollisionSize(u)
		t[unitTypeId] = m
		RemoveUnit(u)
		return m
	end

	function GetUnitTypeCollisionSize(unitTypeId)
		return t[unitId] or GetCollisionSize(unitTypeId)
	end

end