library AutoFly uses UnitIndexer /* Credits to Azlier for the original idea */

    private struct AutoFly extends array
        private static method onIndex takes nothing returns boolean
            return UnitAddAbility(UnitIndexer.triggerUnit, 'Arav') and UnitRemoveAbility(UnitIndexer.triggerUnit, 'Arav')
        endmethod
        implement UnitIndexerEvents
    endstruct

endlibrary
