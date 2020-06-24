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

    private constant function SummonCount takes integer level returns integer
        return 5 + 5*level
    endfunction

    private function TargetFilter takes unit target, unit caster returns boolean
        return UnitAlive(target)
    endfunction
    ...
    /*****************************************************************
    *               END OF GLOBAL SPELL CONFIGURATION                *
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

        implement GlobalSpellConfiguration
        implement SpellClonerHeader

        real summonedNodeDuration
        ...

        private method operator component takes nothing returns SpellComponent
            return this
        endmethod

        private method onSpellStart takes nothing returns thistype
            /*
            *   It is important that you only call initSpellConfiguration() once per cast because
            *   sometimes, it is possible that a similar activation abilityId is assigned to multiple
            *   configuration struct, in which case, whenever the ability is cast, onSpellStart() will
            *   run for each configuration struct. Calling initSpellConfiguration(ABIL_ID) will move
            *   its internal configuration struct iterator to the next one in the list of configurations
            *   belonging to <ABIL_ID>. Therefore, we just have to save current configuration struct ID
            *   (The return value) so we can load it in the loop later below.
            *
            *   Note: The 'this' below is useless. You can use an arbitrary instance or even 'thistype(0)'.
            */
            local integer configurationId = this.initSpellConfiguration(GetEventSpellAbilityId())
            local integer count
            local thistype node

            if not <InvalidCastCondition> then
                set count = SummonCount(GetEventSpellLevel())
                if count > 0 then
                    loop
                        exitwhen count == 0

                        set node = SpellComponent.create(...)
                        call node.loadSpellConfiguration(configurationId)

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

            set this.summonedNodeDuration = this.summonedNodeDuration - SPELL_PERIOD
            return this.summonedNodeDuration > 0.00 and <OtherContinueCondition>
        endmethod

        private method onSpellEnd takes nothing returns nothing

            ...

            call this.component.destroy()
        endmethod

        implement SpellEvent
        implement SpellClonerFooter

    endstruct

    /*
    *   This is the module that you will implement into the struct that you wish to
    *   contain the local spell configurations
    */
    module <SpellName>Configuration
        private static method configHandler takes nothing returns nothing
            /*
            *   This configuration setup is run whenever <node>.initSpellConfiguration(ABIL_ID) or
            *   <node>.loadSpellConfiguration(CONFIG_ID)
            */
            local <SpellName> node = SpellCloner.configuredInstance
            ...
            set node.summonedNodeDuration           = summonDuration(GetEventSpellLevel())
            ...
        endmethod

        private static method onInit takes nothing returns nothing
            call <SpellName>.create(thistype.typeid, SPELL_ABILITY_ID, SPELL_EVENT_TYPE, function thistype.configHandler)
        endmethod
    endmodule


endlibrary
//! endnovjass