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

    private constant function SummonCount takes integer level returns integer
        return 5 + 5*level
    endfunction

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

        ...

        private method operator component takes nothing returns SpellComponent
            return this
        endmethod

        private method onSpellStart takes nothing returns thistype
            local integer count
            local thistype node

            if not <InvalidCastCondition> then
                set count = SummonCount(GetEventSpellLevel())
                if count > 0 then
                    loop
                        exitwhen count == 0

                        set node = SpellComponent.create(...)

                        ...

                        set thistype(0).prev = node
                        set thistype(0).prev.next = node
                        set node.prev = thistype(0).prev
                        set node.next = 0

                        set count = count - 1
                    endloop

                    ...
                endif
            endif

            return 0
        endmethod

        private method onSpellPeriodic takes nothing returns boolean

            ...

            /*
            *   Again, no need to manually remove the component node, it will
            *   automatically be removed from the list when returning false.
            */
            return <ContinuePeriodicCondition>
        endmethod

        private method onSpellEnd takes nothing returns nothing

            ...

            call this.component.destroy()
        endmethod

        implement SpellEvent

    endstruct


endlibrary
//! endnovjass