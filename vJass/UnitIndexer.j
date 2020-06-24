library UnitIndexer /*


    */uses /*

    */AllocList     /*
    */OrderEvent    /*
    */Process       /*
    */MapBounds     /*
    */Initializer   /*

    *///! novjass

    |============|
    | Struct API |
    |============|
    /*
      */struct UnitIndexer/*

          */static boolean enabled                  /*  Boolean flag determining if the system is enabled or not
          */readonly static thistype triggerIndex   /*  The index given/removed to/from the newly indexed/deindexed unit
          */readonly static unit triggerUnit        /*  The newly indexed/deindexed unit
          */readonly static integer unitCount       /*  The current total number of indexed unit

          */readonly thistype prev                  /*  The prev member in the UnitIndexer index list
          */readonly thistype next                  /*  The next member in the UnitIndexer index list
          */readonly unit unit                      /*  The unit corresponding to the UnitIndexer instance

          */static method U2I takes unit u returns integer/*
          */static method I2U takes integer index returns unit/*
            - Unit to unit index typecaster and vice-versa

          */static method registerIndexEvent takes code c returns nothing/*
          */static method unregisterIndexEvent takes code c returns nothing/*
            - Registers/unregisters a unit index event

          */static method registerDeindexEvent takes code c returns nothing/*
          */static method unregisterDeindexEvent takes code c returns nothing/*
            - Registers/unregisters a unit deindex event

          */static method indexUnit takes unit u, boolean fireEvents returns boolean/*
          */static method deindexUnit takes unit u, boolean fireEvents returns boolean/*
            - Manually indexes/deindexes a unit and returns a boolean value depending
              on the success of the operation

    */
    |==============|
    | Function API |
    |==============|
    /*
      */constant function GetIndexedUnit takes nothing returns unit/*
        - The newly indexed/deindexed unit
      */constant function GetIndexedUnitId takes nothing returns integer/*
        - The index given/removed to/from the newly indexed/deindexed unit
      */constant function IsUnitIndexerEnabled takes nothing returns boolean/*
        - Determines if the system is enabled or not
      */function GetUnitId takes unit u returns integer/*
        - Retrieves the unit index of the input unit
      */function GetUnitById takes integer index returns unit/*
        - Retrieves the unit corresponding to a certain unit index
      */function GetIndexedUnitCount takes nothing returns integer/*
        - Retrieves the total number of currently indexed unit in the map

      */function RegisterUnitIndexEvent takes code c returns nothing/*
      */function UnregisterUnitIndexEvent takes code c returns nothing/*
        - Registers/unregisters a unit index event

      */function RegisterUnitDeindexEvent takes code c returns nothing/*
      */function UnregisterUnitDeindexEvent takes code c returns nothing/*
        - Registers/unregisters a unit deindex event

      */function UnitIndexerEnable takes nothing returns nothing/*
      */function UnitIndexerDisable takes nothing returns nothing/*
        - Enables/Disables the unit indexer

    */
    |=========|
    | Modules |
    |=========|
    /*
      */module UnitIndexerEvents/*
        - implement this module below your static methods onIndex() and/or onDeindex()

    *///! endnovjass
    /*=============================== Configuration ===============================*/

    private module IndexerFilterConfig
        static method filter takes unit u returns boolean
            //if IsUnitIllusion(u) then
            //    return false
            //endif
            return GetUnitAbilityLevel(u, 'Aloc') == 0
        endmethod
    endmodule

    /*=========================== End of Configuration ============================*/

    private struct Index extends array
        implement AllocList
    endstruct

    struct UnitIndexer extends array

        /* Rawcode of the ability used to detect removed units */
        private static constant integer UNIT_SENTINEL = 'uDex'

        private static Process onIndex
        private static Process onDeindex
        static boolean enabled = false
        readonly static thistype triggerIndex = 0
        readonly static unit triggerUnit = null
        readonly unit unit

        method operator prev takes nothing returns thistype
            return Index(this).prev
        endmethod
        method operator next takes nothing returns thistype
            return Index(this).next
        endmethod

        static method U2I takes unit u returns integer
            return GetUnitUserData(u)
        endmethod
        static method I2U takes integer index returns unit
            return thistype(index).unit
        endmethod

        static method registerIndexEvent takes code c returns nothing
            call onIndex.register(c)
        endmethod
        static method unregisterIndexEvent takes code c returns nothing
            call onIndex.unregister(c)
        endmethod

        static method registerDeindexEvent takes code c returns nothing
            call onDeindex.register(c)
        endmethod
        static method unregisterDeindexEvent takes code c returns nothing
            call onDeindex.unregister(c)
        endmethod

        static method operator unitCount takes nothing returns integer
            local integer count = 0
            local thistype this = thistype(0).next
            loop
                exitwhen this == 0
                set count = count + 1
                set this = this.next
            endloop
            return count
        endmethod

        private static method forFilter takes unit u returns boolean
            static if thistype.filter.exists then
                return filter(u)
            else
                return true
            endif
        endmethod

        static method indexUnit takes unit u, boolean fireEvents returns boolean
            local integer prevIndex
            local unit prevUnit
            if GetUnitUserData(u) == 0 and forFilter(u) then
                set prevIndex = triggerIndex
                set prevUnit = triggerUnit
                set triggerIndex = Index.allocate()
                set triggerUnit = u
                set triggerIndex.unit = triggerUnit
                call SetUnitUserData(u, triggerIndex)
                call UnitAddAbility(u, UNIT_SENTINEL)
                call UnitMakeAbilityPermanent(u, true, UNIT_SENTINEL)
                call onIndex.execute()
                set triggerIndex = prevIndex
                set triggerUnit = prevUnit
                set prevUnit = null
                return true
            endif
            return false
        endmethod

        static method deindexUnit takes unit u, boolean fireEvents returns boolean
            local thistype this = GetUnitUserData(u)
            local integer prevIndex
            local unit prevUnit
            if this != 0 then
                set prevIndex = triggerIndex
                set prevUnit = triggerUnit
                set triggerIndex = this
                set triggerUnit = u
                call onDeindex.execute()
                call Index(this).deallocate()
                set this.unit = null
                call UnitRemoveAbility(u, UNIT_SENTINEL)
                call SetUnitUserData(u, 0)
                set triggerIndex = prevIndex
                set triggerUnit = prevUnit
                set prevUnit = null
                return true
            endif
            return false
        endmethod

        private static method onEnter takes nothing returns nothing
            if enabled and indexUnit(GetFilterUnit(), true) then
            endif
        endmethod

        private static method onLeave takes nothing returns nothing
            local unit u = GetTriggerUnit()
            if enabled and GetUnitAbilityLevel(u, UNIT_SENTINEL) > 0 and deindexUnit(u, true) then
            endif
            set u = null
        endmethod

        private static method onInit takes nothing returns nothing
            local unit u
            local group enumerator = CreateGroup()
            call GroupEnumUnitsInRect(enumerator, WorldBounds.rect, null)
            loop
                set u = FirstOfGroup(enumerator)
                exitwhen u == null
                call GroupRemoveUnit(enumerator, u)
                if enabled and GetUnitUserData(u) == 0 and indexUnit(u, true) then
                endif
            endloop
            call DestroyGroup(enumerator)
            set enumerator = null
        endmethod

        private static method init takes nothing returns nothing
            local code onEnter = function thistype.onEnter
            local integer i = 16
            call TriggerRegisterEnterRegion(CreateTrigger(), WorldBounds.region, Filter(onEnter))
            call RegisterOrderEvent(852056, function thistype.onLeave)
            loop
                set i = i - 1
                call SetPlayerAbilityAvailable(Player(i), UNIT_SENTINEL, false)
                exitwhen i == 0
            endloop
            set onIndex = Process.create()
            set onDeindex = Process.create()
            // Enable the unit indexer
            set enabled = true
        endmethod

        implement Initializer

    endstruct

    /*========================= Wrapper Functions =========================*/

    constant function GetIndexedUnit takes nothing returns unit
        return UnitIndexer.triggerUnit
    endfunction

    constant function GetIndexedUnitId takes nothing returns integer
        return UnitIndexer.triggerIndex
    endfunction

    function GetUnitId takes unit u returns integer
        return UnitIndexer.U2I(u)
    endfunction

    function GetUnitById takes integer index returns unit
        return UnitIndexer.I2U(index)
    endfunction

    function GetIndexedUnitCount takes nothing returns integer
        return UnitIndexer.unitCount
    endfunction

    function RegisterUnitIndexEvent takes code c returns nothing
        call UnitIndexer.registerIndexEvent(c)
    endfunction

    function RegisterUnitDeindexEvent takes code c returns nothing
        call UnitIndexer.registerDeindexEvent(c)
    endfunction

    function UnregisterUnitIndexEvent takes code c returns nothing
        call UnitIndexer.unregisterIndexEvent(c)
    endfunction

    function UnregisterUnitDeindexEvent takes code c returns nothing
        call UnitIndexer.unregisterDeindexEvent(c)
    endfunction

    constant function IsUnitIndexerEnabled takes nothing returns boolean
        return UnitIndexer.enabled
    endfunction

    function UnitIndexerEnable takes nothing returns nothing
        set UnitIndexer.enabled = true
    endfunction

    function UnitIndexerDisable takes nothing returns nothing
        set UnitIndexer.enabled = false
    endfunction

    /*=========================== Public Module ===========================*/

    module UnitIndexerEvents
        static if thistype.onIndex.exists and thistype.onDeindex.exists then
            private static method onInit takes nothing returns nothing
                call UnitIndexer.registerIndexEvent(function thistype.onIndex)
                call UnitIndexer.registerDeindexEvent(function thistype.onDeindex)
            endmethod
        elseif thistype.onIndex.exists then
            private static method onInit takes nothing returns nothing
                call UnitIndexer.registerIndexEvent(function thistype.onIndex)
            endmethod
        elseif thistype.onDeindex.exists then
            private static method onInit takes nothing returns nothing
                call UnitIndexer.registerDeindexEvent(function thistype.onDeindex)
            endmethod
        endif
    endmodule


endlibrary
