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

    private struct Node extends array
        implement Alloc
    endstruct

    private struct SpellComponent extends array

        ...

        static method create takes ... returns thistype
            local thistype node = Node.allocate()
            ...
            return node
        endmethod
        method destroy takes nothing returns nothing
            ...
            call Node(this).deallocate()
        endmethod

    endstruct

    public struct <SpellName> extends array

        implement SpellConfiguration

        unit dummy
        effect spellSfx
        boolean primaryNode
        ...

        private method operator component takes nothing returns SpellComponent
            return this
        endmethod

        private method onSpellStart takes nothing returns thistype
            if <InvalidCastCondition> then
                return 0
            endif

            set this = Node.allocate()
            set this.dummy = CreateUnit(...)
            set this.spellSfx = AddSpecialEffectTarget(..., this.dummy, ...)
            ...
            set this.primaryNode = true

            return this
        endmethod

        private method onSpellPeriodic takes nothing returns boolean
            local thistype node

            ...

            if this.primaryNode then
                if <CreateComponentCondition> then
                    set node = SpellComponent.create(...)
                    set thistype(0).prev = node
                    set thistype(0).prev.next = node
                    set node.prev = thistype(0).prev
                    set node.next = 0
                    set node.primaryNode = false
                endif

                ...

                return <ContinuePeriodicCondition>
            else

                ...

                /*
                *   No longer need to manually remove component node from list - it
                *   will automatically be removed upon returning false
                */
                return <DestroyComponentCondition>
            endif

        endmethod

        private method onSpellEnd takes nothing returns nothing
            if this.primaryNode then
                set this.primaryNode = false

                call DestroyEffect(this.spellSfx)
                call UnitApplyTimedLife(this.dummy, 'BTLF', SFX_DEATH_TIME)

                ...

                set this.spellSfx = null
                set this.dummy = null

                call Node(this).deallocate()
            else

                call this.component.destroy()
            endif
        endmethod

        implement SpellEvent

    endstruct


endlibrary
//! endnovjass