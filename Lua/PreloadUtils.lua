--[[ PreloadUtils.lua v1.0.0 https://www.hiveworkshop.com/threads/lua-preloadutils.325644/

	uses:
		- Global Initialization: https://www.hiveworkshop.com/threads/lua-global-initialization.317099/

	API:

		function PreloadUnit(arg)
		function PreloadItem(arg)
		function PreloadAbility(arg)
			- Args: rawcode(s) enclosed in FourCC()

		function PreloadEffect(arg)
		function PreloadSound(arg)
			- Args: string path(s)


	Sample Usage:

		PreloadUnit(FourCC('hfoo'))
		PreloadAbility{ FourCC('A000'), FourCC('A001'), FourCC('A002') }
		PreloadEffect{ path_1, {path_2, path_3}, path_4 }

]]--
do
	local t = {}
	local dummy

	local function OnPreload(callback, arg)
		if type(arg) == 'table' then
			for k, v in pairs(arg) do
				OnPreload(callback, v)
			end
		elseif t[arg] == nil then
			t[arg = 1 -- prevents redundant preloading
			callback(arg)
		end
	end

    local function UnitPreloader(id)
        RemoveUnit(CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), id, 0, 0, 0))
    end
    local function ItemPreloader(id)
        RemoveItem(UnitAddItemById(dummy, id))
    end
    local function AbilityPreloader(id)
        if UnitAddAbility(dummy, id) then UnitRemoveAbility(dummy, id) end
    end
    local function EffectPreloader(path)
        DestroyEffect(AddSpecialEffectTarget(path, dummy, "origin"))
    end
	-- Credits to Silvenon for sound preloading method
    local function SoundPreloader(path)
        local s = CreateSound(path, false, false, false, 10, 10, "")
        SetSoundVolume(s, 0)
        StartSound(s)
        KillSoundWhenDone(s)
    end

    function PreloadUnit(arg)
		OnPreload(UnitPreloader, arg)
    end
    function PreloadItem(arg)
		OnPreload(ItemPreloader, arg)
    end
    function PreloadAbility(arg)
		OnPreload(AbilityPreloader, arg)
    end
    function PreloadEffect(arg)
		OnPreload(EffectPreloader, arg)
    end
    function PreloadSound(arg)
		OnPreload(SoundPreloader, arg)
    end

	-- init
	onGlobalInit(function ()
		dummy = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('hpea'), 0, 0, 0)
		UnitAddAbility(dummy, FourCC('AInv'))
		UnitAddAbility(dummy, FourCC('Avul'))
		UnitRemoveAbility(dummy, FourCC('Amov'))
		SetUnitY(dummy, GetRectMaxY(world) + 1000)
		RemoveRect(world)
	end)
end