//! novjass
library <SpellName> /*


    */uses /*

    */SpellDevFramework /*

    */

    /*****************************************************************
    *                       SPELL CONFIGURATION                      *
    *****************************************************************/
    private module SpellConfiguration

        static constant integer SPELL_ABILITY_ID    = 'XXXX'

        static constant integer SPELL_EVENT_TYPE    = EVENT_SPELL_EFFECT

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

        private method onSpellStart takes nothing returns thistype
            if <InvalidCastCondition> then
                return 0
            endif

            set this.dummy = CreateUnit(...)
            set this.spellSfx = AddSpecialEffectTarget(..., this.dummy, ...)
            ...

            return this
        endmethod

        private method onSpellPeriodic takes nothing returns boolean

            ...

            return <ContinuePeriodicCondition>
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