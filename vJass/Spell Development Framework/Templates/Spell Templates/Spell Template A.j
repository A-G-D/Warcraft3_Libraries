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

        effect spellSfx
        ...

        private static method onSpellStart takes nothing returns thistype
            local thistype node

            if <InvalidCastCondition> then
                return 0 // Does not run onSpellEnd()
            endif

            set node = ...
            set node.spellSfx = AddSpecialEffectTarget(...)

            ...

            return node
        endmethod

        private method onSpellEnd takes nothing returns nothing
            call DestroyEffect(this.spellSfx)

            ...

            set this.spellSfx = null
        endmethod

        implement SpellEventEx

    endstruct


endlibrary
//! endnovjass