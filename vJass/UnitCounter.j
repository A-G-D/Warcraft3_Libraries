library UnitCounter /*


    */uses /*

    */UnitIndexer /*
    */Table       /*


    *///! novjass

    |-----|
    | API |
    |-----|
    /*

      */integer UnitCount.TOTAL         /*      - Contains the total number of indexed units
      */integer array UnitCount         /*      - Use unittype rawcode as array index (Array index: (-)(2^32) ~ (+)(2^32 - 1))
                                                - Contains the total number of indexed units for a specific unit-type
      */integer array UnitCount.PLAYER  /*      - Use player id as array index (Array index: 0 ~ 15)
                                                - Contains the total number of indexed units owned by a specific player
      */integer array UnitCount.RACE    /*      - Use unit race as array index (Array index: RACE_HUMAN, RACE_NIGHTELF, RACE_ORC, RACE_UNDEAD, RACE_DEMON, RACE_OTHER)
                                                - Contains the total number of indexed units belonging to a specific race

    *///! endnovjass


    private struct Race extends array

        static integer array unitCount

        method operator [] takes race whichRace returns integer
            return unitCount[GetHandleId(whichRace)]
        endmethod

    endstruct

    struct UnitCount extends array

        readonly static integer TOTAL = 0
        readonly static integer array PLAYER

        private static key table

        static method operator [] takes integer unitTypeId returns integer
            return Table(table)[unitTypeId]
        endmethod
        static method operator RACE takes nothing returns Race
            return 0
        endmethod

        private static method update takes integer toAdd returns nothing
            local integer ownerId = GetPlayerId(GetOwningPlayer(UnitIndexer.triggerUnit))
            local integer raceId = GetHandleId(GetUnitRace(UnitIndexer.triggerUnit))
            local integer unitTypeId = GetUnitTypeId(UnitIndexer.triggerUnit)
            set PLAYER[ownerId] = PLAYER[ownerId] + toAdd
            set Race.unitCount[raceId] = Race.unitCount[raceId] + toAdd
            set Table(table)[unitTypeId] = Table(table)[unitTypeId] + toAdd
            set TOTAL = TOTAL + toAdd
        endmethod

        private static method onIndex takes nothing returns nothing
            call update(1)
        endmethod
        private static method onDeindex takes nothing returns nothing
            call update(-1)
        endmethod
        implement UnitIndexerEvents

    endstruct


endlibrary
