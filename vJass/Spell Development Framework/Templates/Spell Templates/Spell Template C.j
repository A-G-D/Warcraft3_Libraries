//! novjass
library <SpellName> /*


    */uses /*

    */SpellDevFramework /*
    */UnitDex           /*

    */

    /*****************************************************************
    *                       SPELL CONFIGURATION                      *
    *****************************************************************/
    private module SpellConfiguration

        static constant integer SPELL_ABILITY_ID    = 'XXXX'

        static constant integer SPELL_EVENT_TYPE    = EVENT_SPELL_CHANNEL + EVENT_SPELL_ENDCAST

        static constant real SPELL_PERIOD           = 1.00/32.00

        static constant real SFX_DEATH_TIME         = 1.50
        ...

    endmodule

    private function TargetFilter takes unit target, unit caster returns boolean
        return UnitAlive(target)
    endfunction
    ...
    /*****************************************************************
    *                   END OF SPELL CONFIGURATION                   *
    *****************************************************************/

    /*========================= SPELL CODE =========================*/
    native UnitAlive takes unit u returns boolean

    public struct <SpellName> extends array

        implement SpellConfiguration

        unit dummy
        effect spellSfx
        ...
        boolean channelEnded

        private method onSpellStart takes nothing returns thistype
            if <InvalidCastCondition> then
                return 0
            endif

            if GetEventSpellEventType() == EVENT_SPELL_ENDCAST then
                set this = GetUnitId(GetEventSpellCaster())
                set this.channelEnded = true
                return 0
            endif

            set this = GetUnitId(GetEventSpellCaster())
            set this.channelEnded = false

            set this.dummy = CreateUnit(...)
            set this.spellSfx = AddSpecialEffectTarget(..., this.dummy, ...)
            ...

            return this
        endmethod

        private method onSpellPeriodic takes nothing returns boolean

            ...

            if not <ContinuePeriodicCondition> then
            /*
            *   If it is time to end the spell, instead of manually returning false,
            *   we order the caster to "stop" to set this.channelEnded to 'true'
            *
            *   Note: For seamless manipulation of channeling ability, I suggest using
            *   an ability based on CHANNEL then be sure to set its 'Follow through
            *   time' field into a really high value such as <99999> and set the
            *   'Disable other abilities' to false.
            */
                call IssueImmediateOrderById(GetUnitById(this), STOP_ORDER_ID)
            endif
            return not this.channelEnded
        endmethod

        private method onSpellEnd takes nothing returns nothing
            call DestroyEffect(this.spellSfx)
            call UnitApplyTimedLife(this.dummy, 'BTLF', SFX_DEATH_TIME)

            ...

            set this.spellSfx = null
            set this.dummy = null
        endmethod

        implement SpellEvent

    endstruct


endlibrary
//! endnovjass