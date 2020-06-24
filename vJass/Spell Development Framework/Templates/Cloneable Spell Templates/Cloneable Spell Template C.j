//! novjass
library <SpellName> /*


    */uses /*

    */SpellDevFramework /*

    */

    /*****************************************************************
    *                   GLOBAL SPELL CONFIGURATION                   *
    *****************************************************************/
    private module GlobalSpellConfiguration

        static constant real SPELL_PERIOD       = 1.00/32.00

        static constant real SFX_DEATH_TIME     = 1.50
        ...

    endmodule

    private function TargetFilter takes unit target, unit caster returns boolean
        return UnitAlive(target)
    endfunction
    ...
    /*****************************************************************
    *               END OF GLOBAL SPELL CONFIGURATION                *
    *****************************************************************/

    /*========================= SPELL CODE =========================*/
    native UnitAlive takes unit u returns boolean

    public struct <SpellName> extends array

        implement GlobalSpellConfiguration

        string staticSfxModel
        string staticSfxAttachPoint
        real spellDuration
        ...

        private method onClonedSpellStart takes nothing returns thistype
            if <InvalidCastCondition> then
                return 0
            endif

            ...

            return this
        endmethod

        private method onClonedSpellPeriodic takes nothing returns boolean

            ...

            set this.spellDuration = this.spellDuration - SPELL_PERIOD
            return this.spellDuration > 0.00 and <OtherContinueCondition>
        endmethod

        private method onClonedSpellEnd takes nothing returns nothing

            ...

        endmethod

        implement SpellCloner

    endstruct

    /*
    *   This is the module that you will implement into the struct that you wish to
    *   contain the local spell configurations
    */
    module <SpellName>Configuration
        private static method configHandler takes nothing returns nothing
            /*
            *   This configuration setup is run automatically by the system before calling
            *   onClonedSpellStart().
            */
            local <SpellName> node = SpellCloner.configuredInstance
            set node.staticSfxModel               = STATIC_SFX_MODEL
            set node.staticSfxAttachPoint         = STATIC_SFX_ATTACHPOINT
            ...
            set node.spellDuration                = spellDuration(GetEventSpellLevel())
            ...
        endmethod

        private static method onInit takes nothing returns nothing
            call <SpellName>.create(thistype.typeid, SPELL_ABILITY_ID, SPELL_EVENT_TYPE, function thistype.configHandler)
        endmethod
    endmodule


endlibrary
//! endnovjass