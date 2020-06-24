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

    private struct SpellComponentList extends array
        method operator component takes nothing returns SpellComponent
            return this
        endmethod

        private static method onRemove takes thistype node returns nothing
            call node.component.destroy()
        endmethod

        private static method allocate takes nothing returns thistype
            return Node.allocate()
        endmethod
        private method deallocate takes nothing returns nothing
            call Node(this).deallocate()
        endmethod

        implement InstantiatedList  // Refer to the LinkedList library's documentation to know the above methods
        // Or you can use your own linked list
    endstruct

    public struct <SpellName> extends array

        implement SpellConfiguration

        unit dummy
        effect spellSfx
        SpellComponentList componentList
        ...

        private method onSpellStart takes nothing returns thistype
            if <InvalidCastCondition> then
                return 0
            endif

            set this.dummy = CreateUnit(...)
            set this.spellSfx = AddSpecialEffectTarget(..., this.dummy, ...)

            ...

            set this.componentList = SpellComponentList.create()

            return this
        endmethod

        private method onSpellPeriodic takes nothing returns boolean
            local thistype node

            ...

            if <CreateComponentCondition> then
                set node = SpellComponent.create(...)

                ...

                call this.componentList.pushBack(node)
            endif

            set node = this.componentList.next
            loop
                exitwhen node == this.componentList

                ...

                if <DestroyComponentCondition> then
                    call node.remove()
                endif

                set node = node.next
            endloop

            ...

            return <ContinuePeriodicCondition>
        endmethod

        private method onSpellEnd takes nothing returns nothing
            // Destroy remaining component nodes
            call this.componentList.destroy() // Calls flush() which in turn calls remove() for each node on the list

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