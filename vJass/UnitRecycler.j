library UnitRecycler /* v1.3b


    |=============|
    | Author: AGD |
    |=============|

    */requires /*

    */ReviveUnit                        /*  http://www.hiveworkshop.com/threads/snippet-reviveunit.186696/
    */UnitDex                           /*  http://www.hiveworkshop.com/threads/system-unitdex-unit-indexer.248209/
    */optional Table                    /*  http://www.hiveworkshop.com/threads/snippet-new-table.188084/
    */optional TimerUtils               /*  http://www.wc3c.net/showthread.php?t=101322
    */optional RegisterPlayerUnitEvent  /*  http://www.hiveworkshop.com/threads/snippet-registerevent-pack.250266/


    This system is important because CreateUnit() is one of the most processor-intensive function in
    the game and there are reports that even after they are removed, they still leave some bit of memory
    consumption (0.04 KB) on the RAM. Therefore it would be very helpful if you can minimize unit
    creation or so. This system also allows you to recycle dead units to avoid permanent 0.04 KB memory
    leak for each future CreateUnit() call.                                                                 */

//! novjass

    [Credits]
        Aniki - For suggesting ideas on further improvements


    |-----|
    | API |
    |-----|

        function GetRecycledUnit takes player owner, integer rawCode, real x, real y, real facing returns unit/*
            - Returns unit of specified ID from the stock of recycled units. If there's none in the stock that
              matched the specified unit's rawcode, it will create a new unit instead
            - Returns null if the rawcode's unit-type is a hero or non-existent

      */function GetRecycledUnitEx takes player owner, integer rawCode, real x, real y, real facing returns unit/*
            - Works similar to GetRecycledUnit() except that if the input rawcode's unit-type is a hero, it will
              be created via CreateUnit() instead
            - You can use this as an alternative to CreateUnit()

      */function RecycleUnit takes unit u returns boolean/*
            - Recycles the specified unit and returns a boolean value depending on the success of the operation
            - Does nothing to hero units

      */function RecycleUnitEx takes unit u returns boolean/*
            - Works similar to RecycleUnit() except that if <u> is not recyclable, it will be removed via
              RemoveUnit() instead
            - You can use this as an alternative to RemoveUnit()

      */function RecycleUnitDelayed takes unit u, real delay returns nothing/*
            - Recycles the specified unit after <delay> seconds

      */function RecycleUnitDelayedEx takes unit u, real delay returns nothing/*
            - Works similar to RecycleUnitDelayed() except that it calls RecycleUnitEx() instead of RecycleUnit()

      */function UnitAddToStock takes integer rawCode returns boolean/*
            - Creates a unit of type ID and adds it to the stock of recycled units then returns a boolean value
              depending on the success of the operation

*///! endnovjass

    //CONFIGURATION SECTION


    globals

/*      The owner of the stocked/recycled units
*/      private constant player OWNER               = Player(15)

/*      Determines if dead units will be automatically recycled
        after a delay designated by the <constant function
        DeathTime below>
*/      private constant boolean AUTO_RECYCLE_DEAD  = true

/*      Error debug message prefix
*/      private constant string ERROR_PREFIX        = "|CFFFF0000Operation Failed: "

    endglobals

    /* The delay before dead units will be recycled in case AUTO_RECYCLE_DEAD == true */
    static if AUTO_RECYCLE_DEAD then
        private constant function DeathTime takes unit u returns real
            /*if <condition> then
                  return someValue
              elseif <condition> then
                  return someValue
              endif                 */
            return 8.00
        endfunction
    endif

    /* When recycling a unit back to the stock, these resets will be applied to the
       unit. You can add more actions to this or you can delete this textmacro if you
       don't need it.                                                                       */
        //! textmacro_once UNIT_RECYCLER_RESET
            call SetUnitScale(u, 1, 0, 0)
            call SetUnitVertexColor(u, 255, 255, 255, 255)
            call SetUnitFlyHeight(u, GetUnitDefaultFlyHeight(u), 0)
        //! endtextmacro


    //END OF CONFIGURATION

    /*==== Do not do changes below this line if you're not so sure on what you're doing ====*/
    native UnitAlive takes unit u returns boolean

    globals
        private keyword S
        private integer count = 0
        private real unitCampX
        private real unitCampY
        private integer array stack
        private boolean array stacked
    endglobals

    private function GetIndex takes integer rawCode returns integer
        static if LIBRARY_Table then
            local integer i = S.table.integer[rawCode]
            if i == 0 then
                set count = count + 1
                set S.table.integer[rawCode] = count
                set i = count
            endif
        else
            local integer i = LoadInteger(S.hash, -1, rawCode)
            if i == 0 then
                set count = count + 1
                call SaveInteger(S.hash, -1, rawCode, count)
                set i = count
            endif
        endif
        return i
    endfunction

    static if DEBUG_MODE then
        private function Debug takes string msg returns nothing
            call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 60, "|CFFFFCC00[Unit Recycler]|R " + msg)
        endfunction
    endif

    function GetRecycledUnit takes player owner, integer rawCode, real x, real y, real facing returns unit
        local integer i
        if not IsHeroUnitId(rawCode) then
            set i = GetIndex(rawCode)
            if stack[i] == 0 then
                set bj_lastCreatedUnit = CreateUnit(owner, rawCode, x, y, facing)
                debug call Debug(GetUnitName(bj_lastCreatedUnit) + " stock is empty, creating new " + GetUnitName(bj_lastCreatedUnit))
            else
                static if LIBRARY_Table then
                    set bj_lastCreatedUnit = S.hash[i].unit[stack[i]]
                else
                    set bj_lastCreatedUnit = LoadUnitHandle(S.hash, i, stack[i])
                endif
                set stacked[GetUnitId(bj_lastCreatedUnit)] = false
                call PauseUnit(bj_lastCreatedUnit, false)
                call SetUnitOwner(bj_lastCreatedUnit, owner, true)
                call SetUnitPosition(bj_lastCreatedUnit, x, y)
                call SetUnitFacing(bj_lastCreatedUnit, facing)
                set stack[i] = stack[i] - 1
                debug call Debug("Retrieving " + GetUnitName(bj_lastCreatedUnit) + " from stock")
            endif
            debug if bj_lastCreatedUnit == null then
                debug call Debug(ERROR_PREFIX + "Specified unit-type does not exist")
            debug endif
        else
            debug call Debug(ERROR_PREFIX + "Attemp to retrieve a hero unit")
            return null
        endif
        return bj_lastCreatedUnit
    endfunction

    function GetRecycledUnitEx takes player owner, integer rawCode, real x, real y, real facing returns unit
        if not IsHeroUnitId(rawCode) then
            return GetRecycledUnit(owner, rawCode, x, y, facing)
        endif
        debug call Debug("Cannot retrieve a hero unit, creating new unit")
        return CreateUnit(owner, rawCode, x, y, facing)
    endfunction

    function RecycleUnit takes unit u returns boolean
        local integer rawCode = GetUnitTypeId(u)
        local integer uDex = GetUnitId(u)
        local integer i
        if not IsHeroUnitId(rawCode) and not stacked[uDex] and u != null then
            set i = GetIndex(rawCode)
            if not UnitAlive(u) and not ReviveUnit(u) then
                debug call Debug(ERROR_PREFIX + "Unable to recycle unit: Unable to revive dead unit")
                return false
            endif
            set stacked[uDex] = true
            call PauseUnit(u, true)
            call SetUnitOwner(u, OWNER, true)
            call SetUnitX(u, unitCampX)
            call SetUnitY(u, unitCampY)
            call SetUnitFacing(u, 270)
            call SetWidgetLife(u, GetUnitState(u, UNIT_STATE_MAX_LIFE))
            call SetUnitState(u, UNIT_STATE_MANA, GetUnitState(u, UNIT_STATE_MAX_MANA))
            //! runtextmacro optional UNIT_RECYCLER_RESET()
            set stack[i] = stack[i] + 1
            static if LIBRARY_Table then
                set S.hash[i].unit[stack[i]] = u
            else
                call SaveUnitHandle(S.hash, i, stack[i], u)
            endif
            debug call Debug("Successfully recycled " + GetUnitName(u))
            return true
        debug else
            debug if stacked[uDex] then
                debug call Debug(ERROR_PREFIX + "Attempt to recycle an already recycled unit")
            debug elseif u == null then
                debug call Debug(ERROR_PREFIX + "Attempt to recycle a null unit")
            debug else
                debug call Debug(ERROR_PREFIX + "Attempt to recycle a hero unit")
            debug endif
        endif
        return false
    endfunction

    function RecycleUnitEx takes unit u returns boolean
        if not RecycleUnit(u) then
            call RemoveUnit(u)
            debug call Debug("Cannot recycle the specified unit, removing unit")
            return false
        endif
        return true
    endfunction

    //! textmacro DELAYED_RECYCLE_TYPE takes EX
    private function RecycleTimer$EX$ takes nothing returns nothing
        local timer t = GetExpiredTimer()
        static if LIBRARY_TimerUtils then
            call RecycleUnit$EX$(GetUnitById(GetTimerData(t)))
            call ReleaseTimer(t)
        else
            local integer key = GetHandleId(t)
            static if LIBRARY_Table then
                call RecycleUnit$EX$(S.hash[0].unit[key])
                call S.hash[0].remove(key)
            else
                call RecycleUnit$EX$(LoadUnitHandle(S.hash, 0, key))
                call RemoveSavedHandle(S.hash, 0, key)
            endif
            call DestroyTimer(t)
        endif
        set t = null
    endfunction

    function RecycleUnitDelayed$EX$ takes unit u, real delay returns nothing
        static if LIBRARY_TimerUtils then
            call TimerStart(NewTimerEx(GetUnitId(u)), delay, false, function RecycleTimer$EX$)
        else
            local timer t = CreateTimer()
            static if LIBRARY_Table then
                set S.hash[0].unit[GetHandleId(t)] = u
            else
                call SaveUnitHandle(S.hash, 0, GetHandleId(t), u)
            endif
            call TimerStart(t, delay, false, function RecycleTimer$EX$)
            set t = null
        endif
    endfunction
    //! endtextmacro

    //! runtextmacro DELAYED_RECYCLE_TYPE("")
    //! runtextmacro DELAYED_RECYCLE_TYPE("Ex")

    function UnitAddToStock takes integer rawCode returns boolean
        local unit u
        local integer i
        if not IsHeroUnitId(rawCode) then
            set u = CreateUnit(OWNER, rawCode, unitCampX, unitCampY, 270)
            if u != null then
                set i = GetIndex(rawCode)
                call SetUnitX(u, unitCampX)
                call SetUnitY(u, unitCampY)
                call PauseUnit(u, true)
                set stacked[GetUnitId(u)] = true
                set stack[i] = stack[i] + 1
                static if LIBRARY_Table then
                    set S.hash[i].unit[stack[i]] = u
                else
                    call SaveUnitHandle(S.hash, i, stack[i], u)
                endif
                debug call Debug("Adding " + GetUnitName(u) + " to stock")
                return true
            debug else
                debug call Debug(ERROR_PREFIX + "Attemp to stock a null unit")
            endif
            set u = null
        debug else
            debug call Debug(ERROR_PREFIX + "Attemp to stock a hero unit")
        endif
        return false
    endfunction

    static if AUTO_RECYCLE_DEAD then
        private function OnDeath takes nothing returns nothing
            local unit u = GetTriggerUnit()
            if not IsUnitType(u, UNIT_TYPE_HERO) and not IsUnitType(u, UNIT_TYPE_STRUCTURE) then
                call RecycleUnitDelayed(u, DeathTime(u))
            endif
            set u = null
        endfunction
    endif

    private module Init

        static if LIBRARY_Table then
            static TableArray hash
            static Table table
        else
            static hashtable hash = InitHashtable()
        endif

        private static method onInit takes nothing returns nothing
            local rect bounds = GetWorldBounds()
            static if AUTO_RECYCLE_DEAD then
                static if LIBRARY_RegisterPlayerUnitEvent then
                    static if RPUE_VERSION_NEW then
                        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_DEATH, function OnDeath)
                    else
                        call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_DEATH, function OnDeath)
                    endif
                else
                    local trigger t = CreateTrigger()
                    local code c = function OnDeath
                    local integer i = 16
                    loop
                        set i = i - 1
                        call TriggerRegisterPlayerUnitEvent(t, Player(i), EVENT_PLAYER_UNIT_DEATH, null)
                        exitwhen i == 0
                    endloop
                    call TriggerAddCondition(t, Filter(c))
                endif
            endif
            static if LIBRARY_Table then
                set hash = TableArray[0x2000]
                set table = Table.create()
            endif
            // Hides recycled units at the top of the map beyond reach of the camera
            set unitCampX = 0.00
            set unitCampY = GetRectMaxY(bounds) + 1000.00
            call RemoveRect(bounds)
            set bounds = null
        endmethod

    endmodule

    private struct S extends array
        implement Init
    endstruct


endlibrary
