library SpellEvent /* v2.0.4 https://www.hiveworkshop.com/threads/301895/


    */uses /*

    */Table                             /*  https://www.hiveworkshop.com/threads/188084/

    */optional RegisterPlayerUnitEvent  /*  https://www.hiveworkshop.com/threads/250266/
    */optional ResourcePreloader        /*  https://www.hiveworkshop.com/threads/287358/
    */optional ErrorMessage             /*  https://github.com/nestharus/JASS/blob/master/jass/Systems/ErrorMessage/main.j


    *///! novjass

    /*
        A library that eases and expands the possibilities of custom spells development.

        Core Features:
            1. Two-phase spell event handlers
            2. Manual spell event invocation
            3. Event parameters overriding and event cancelling
            4. Spell development template

            1.) Spell event handlers are grouped into two: generic handlers that runs for every spell, and ability-specific
            handlers. All generic handlers run first. Within them, you can do things such as changing the event parameters
            (caster, target, etc.) as well as preventing the ability-specific handlers from running. The second phase are
            the specific handlers which are for the spell developers to define the mechanics of the spell.

            Note: Generic handlers only run for spells that have existing ability-specific handlers. This is because
            generic handlers are intended as custom-spell modifier, not an ability handler. If you want to catch an event
            that runs for just any ability (including normal OE abilities), you can easily use (in fact, you should) the
            blizzard native events instead.

            2.) You can invoke a spell event to run and define the parameters manually. This removes the need for dummy
            casters in most cases.

            3.) As mentioned in no. 1, within the generic event handlers, you can override the event parameters. The change
            will only affect the ability-specific handlers. You can also stop the ability-specific handlers from running
            (known as event cancelling).

            Note: Event cancelling is currently incompatible with Reforged (Crashes the game).

            4.) This library provides a framework for the flow of spell through the use of modules. This removes from the
            spell developers the additional work of manual spell event registration, spell instance allocation, and other
            minute tasks such as storing and looping through each active spell instance.

    */

    |=========|
    | Credits |
    |=========|
    /*
        - AGD (Author)
        - Bribe, Nestharus (SpellEffectEvent concept)
        - Anitarf (Original SpellEvent Idea)

    */
    |=========|
    | Structs |
    |=========|
    /*

      */struct Spell extends array/*

          */static constant thistype        GENERIC         /*  You can also use this like 'Spell.GENERIC.registerEventHandlers()'

        Event Responses:
          */readonly static integer         abilityId       /*
          */readonly static integer         eventType       /*
          */readonly static integer         orderType       /*
          */readonly static integer         level           /*
          */readonly static player          triggerPlayer   /*
          */readonly static unit            triggerUnit     /*
          */readonly static unit            targetUnit      /*  Fixed a mistake in the native event responses where target is set to caster for 'No-target' abilities based on channel (Is set to null instead)
          */readonly static item            targetItem      /*
          */readonly static destructable    targetDest      /*
          */readonly static widget          target          /*
          */readonly static real            targetX         /*  Returns the x-coordinate of the caster if the spell is a 'No-target' ability
          */readonly static real            targetY         /*  Returns the y-coordinate of the caster if the spell is a 'No-target' ability

        Fields:
          */readonly integer abilId/*
                - Rawcode of the activation ability for the spell

          */boolean handlersDisabled/*
                - (Incompatible with Reforged versions - crashes the game)
                - Value is always reset to false before running the generic spell handlers
                - Set to <true> to increment the internal disabler counter or <false> to decrement counter
                - If counter > 0, the ability-specific handlers won't run

        Methods:

          */static method   operator []                     takes integer abilId                                                           returns Spell/*
                - Returns a Spell instance based on the given activation-ability rawcode which can be used for event handler registrations

          */method          setEventFlag                    takes integer eventType, boolean flag                                           returns nothing/*
          */method          getEventFlag                    takes integer eventType                                                         returns boolean/*
                - Disables/Enables certain event types from running for a Spell (These flags are <true> by default)

          */method          invokeNoTargetEvent             takes integer eventType, integer level, unit caster                             returns nothing/*
          */method          invokePointTargetEvent          takes integer eventType, integer level, unit caster, real targetX, real targetY returns nothing/*
          */method          invokeSingleTargetEvent         takes integer eventType, integer level, unit caster, widget target              returns nothing/*
                - Manually invokes a spell event

          */static method   overrideNoTargetParams          takes integer level, unit caster                                                returns nothing/*
          */static method   overridePointTargetParams       takes integer level, unit caster, real targetX, real targetY                    returns nothing/*
          */static method   overrideSingleTargetParams      takes integer level, unit caster, widget target                                 returns nothing/*
                - Overrides the values of the event response variables (Only effective when called inside a generic event handler)
                - The values are only overriden in the ability-specific spell event handlers

          */method          registerEventHandler            takes integer eventType, code handler                                           returns nothing/*
          */method          unregisterEventHandler          takes integer eventType, code handler                                           returns nothing/*
          */method          clearEventHandlers              takes integer eventType                                                         returns nothing/*
          */method          clearHandlers                   takes nothing                                                                   returns nothing/*
                - Manages ability-specific spell event handlers

          */static method   registerGenericEventHandler     takes integer eventType, code handler                                           returns nothing/*
          */static method   unregisterGenericEventHandler   takes integer eventType, code handler                                           returns nothing/*
          */static method   clearGenericEventHandlers       takes integer eventType                                                         returns nothing/*
          */static method   clearGenericHandlers            takes nothing                                                                   returns nothing/*
                - Manages generic spell event handlers

    */
    |===========|
    | Variables |
    |===========|
    /*
        Spell Event Types

      */constant integer EVENT_SPELL_CAST/*
      */constant integer EVENT_SPELL_CHANNEL/*
      */constant integer EVENT_SPELL_EFFECT/*
      */constant integer EVENT_SPELL_ENDCAST/*
      */constant integer EVENT_SPELL_FINISH/*

        Spell Order Types

      */constant integer SPELL_ORDER_TYPE_SINGLE_TARGET/*
      */constant integer SPELL_ORDER_TYPE_POINT_TARGET/*
      */constant integer SPELL_ORDER_TYPE_NO_TARGET/*

    */
    |===========|
    | Functions |
    |===========|
    /*
        Equivalent functions for the methods above

        (Event Responses)
      */constant function GetEventSpellAbilityId    takes nothing                                                   returns integer/*
      */constant function GetEventSpellEventType    takes nothing                                                   returns integer/*
      */constant function GetEventSpellOrderType    takes nothing                                                   returns integer/*
      */constant function GetEventSpellLevel        takes nothing                                                   returns integer/*
      */constant function GetEventSpellPlayer       takes nothing                                                   returns player/*
      */constant function GetEventSpellCaster       takes nothing                                                   returns unit/*
      */constant function GetEventSpellTargetUnit   takes nothing                                                   returns unit/*
      */constant function GetEventSpellTargetItem   takes nothing                                                   returns item/*
      */constant function GetEventSpellTargetDest   takes nothing                                                   returns destructable/*
      */constant function GetEventSpellTarget       takes nothing                                                   returns widget/*
      */constant function GetEventSpellTargetX      takes nothing                                                   returns real/*
      */constant function GetEventSpellTargetY      takes nothing                                                   returns real/*

      */function SetSpellEventFlag                  takes integer abilId, integer eventType, boolean flag           returns nothing/*
      */function GetSpellEventFlag                  takes integer abilId, integer eventType                         returns boolean/*

      */function SpellCancelEventHandlers           takes boolean cancel                                            returns nothing/*
            - This function is imcompatible with Reforged versions

      */function SpellInvokeNoTargetEvent           takes integer abilId, integer eventType, integer level, unit caster                                returns nothing/*
      */function SpellInvokePointTargetEvent        takes integer abilId, integer eventType, integer level, unit caster, real targetX, real targetY    returns nothing/*
      */function SpellInvokeSingleTargetEvent       takes integer abilId, integer eventType, integer level, unit caster, widget target                 returns nothing/*

      */function SpellOverrideNoTargetParams        takes integer level, unit caster                                returns nothing/*
      */function SpellOverridePointTargetParams     takes integer level, unit caster, real targetX, real targetY    returns nothing/*
      */function SpellOverrideSingleTargetParams    takes integer level, unit caster, widget target                 returns nothing/*

      */function SpellRegisterEventHandler          takes integer abilId, integer eventType, code handler           returns nothing/*
      */function SpellUnregisterEventHandler        takes integer abilId, integer eventType, code handler           returns nothing/*
      */function SpellClearEventHandlers            takes integer abilId, integer eventType                         returns nothing/*
      */function SpellClearHandlers                 takes integer abilId                                            returns nothing/*

      */function SpellRegisterGenericEventHandler   takes integer eventType, code handler                           returns nothing/*
      */function SpellUnregisterGenericEventHandler takes integer eventType, code handler                           returns nothing/*
      */function SpellClearGenericEventHandlers     takes integer eventType                                         returns nothing/*
      */function SpellClearGenericHandlers          takes nothing                                                   returns nothing/*

    */
    |=========|
    | Modules |
    |=========|
    /*
        Automates spell event handler registration at map initialization
        Modules <SpellEvent> and <SpellEventEx> cannot both be implemented in the same struct

      */module SpellEvent/*

            > Uses a single timer (per struct) for all active spell instances. Standard module designed for
              periodic spells with high-frequency timeout (<= 0.5 seconds)

        Fields:

          */readonly thistype prev/*
          */readonly thistype next/*
                - Spell instances links
                - Readonly attribute is only effective outside the implementing struct, though users are
                also not supposed to change these values from inside the struct. But if you insist in
                using this, only do so for manually inserting nodes. Only do it if really needed.

        Public methods:
          */static method registerSpellEvent takes integer abilId, integer eventType returns nothing/*
                - Manually registers an ability rawcode to trigger spell events
                - Can be used for spells that involve more than one activation ability IDs

        Member interfaces:
            - Should be declared above the module implementation

          */interface static integer    SPELL_ABILITY_ID    /*  Ability rawcode
          */interface static integer    SPELL_EVENT_TYPE    /*  Spell event type
          */interface static real       SPELL_PERIOD        /*  Spell periodic actions execution period

          */interface method            onSpellStart    takes nothing   returns thistype/*
                - Runs right after the spell event fires
                - Returning zero or a negative value will not run the periodic operations for that instance
                - You can return a different value or transmute 'this', provided that all your nodes/values
                  comes from the same node/value stack. Also remember to always deallocate what you manually
                  allocated.
                - The value returned will be added to the list of instances that will run onSpellPeriodic().
          */optional interface method   onSpellPeriodic takes nothing   returns boolean/*
                - Runs periodically after the spell event fires until it returns false
          */optional interface method   onSpellEnd      takes nothing   returns nothing/*
                - Runs after method onSpellPeriodic() returns false
                - If onSpellPeriodic() is not present, this will be called after onSpellStart() returns a valid instance


      */module SpellEventEx/*

            > Uses 1 timer for each active spell instance. A module specifically designed for
              periodic spells with low-frequency timeout (> 0.5 seconds) as it does not affect
              the accuracy of the first 'tick' of the periodic operations. Here, you always
              need to manually allocate/deallocate you spell instances.

        Public methods:
          */static method registerSpellEvent takes integer abilId, integer eventType returns nothing/*
                - Manually registers a spell rawcode to trigger spell events
                - Can be used for spells that involves more than one abilityId

        Member interfaces:
            - Should be declared above the module implementation

          */interface static integer    SPELL_ABILITY_ID    /*  Ability rawcode
          */interface static integer    SPELL_EVENT_TYPE    /*  Spell event type
          */interface static real       SPELL_PERIOD        /*  Spell periodic actions execution period

          */interface static method     onSpellStart    takes nothing   returns thistype/*
                - Runs right after the spell event fires
                - User should manually allocate the spell instance and use it as a return value of this method
                - Returning zero or a negative value will not run the periodic operations for that instance
          */optional interface method   onSpellPeriodic takes nothing   returns boolean/*
                - Runs periodically after the spell event fires until it returns false
          */optional interface method   onSpellEnd      takes nothing   returns nothing/*
                - Runs after method onSpellPeriodic() returns false
                - If onSpellPeriodic() is not present, this will be called after onSpellStart() returns a valid instance
                - User must manually deallocate the spell instance inside this method


      */module SpellEventGeneric/*

        Member interfaces:
            - Should be declared above the module implementation

          */optional interface static method    onSpellEvent    takes nothing   returns nothing/*
                - Runs on any generic spell event

          */optional interface static method    onSpellCast     takes nothing   returns nothing/*
          */optional interface static method    onSpellChannel  takes nothing   returns nothing/*
          */optional interface static method    onSpellEffect   takes nothing   returns nothing/*
          */optional interface static method    onSpellEndcast  takes nothing   returns nothing/*
          */optional interface static method    onSpellFinish   takes nothing   returns nothing/*
                - Runs on certain generic spell events


    *///! endnovjass

    /*=================================== SYSTEM CODE ===================================*/

    globals
        constant integer EVENT_SPELL_CAST               = 0x1
        constant integer EVENT_SPELL_CHANNEL            = 0x2
        constant integer EVENT_SPELL_EFFECT             = 0x4
        constant integer EVENT_SPELL_ENDCAST            = 0x8
        constant integer EVENT_SPELL_FINISH             = 0x10

        constant integer SPELL_ORDER_TYPE_SINGLE_TARGET = 0x12
        constant integer SPELL_ORDER_TYPE_POINT_TARGET  = 0x123
        constant integer SPELL_ORDER_TYPE_NO_TARGET     = 0x1234
    endglobals

    globals
        private integer         eventAbilityId          = 0
        private integer         eventEventType          = 0
        private integer         eventOrderType          = 0
        private integer         eventLevel              = 0
        private player          eventTriggerPlayer      = null
        private unit            eventTriggerUnit        = null
        private unit            eventTargetUnit         = null
        private item            eventTargetItem         = null
        private destructable    eventTargetDest         = null
        private real            eventTargetX            = 0.00
        private real            eventTargetY            = 0.00

        private integer         tempOrderType           = 0
        private integer         tempLevel               = 0
        private player          tempTriggerPlayer       = null
        private unit            tempTriggerUnit         = null
        private widget          tempTarget              = null
        private real            tempTargetX             = 0.00
        private real            tempTargetY             = 0.00

        private boolexpr bridgeExpr
        private TableArray table
        private integer array eventTypeId
        private integer array eventIndex
    endglobals

    private keyword Init

    static if DEBUG_MODE then
        private function IsValidEventType takes integer eventType returns boolean
            return eventType > 0 and eventType <= (EVENT_SPELL_CAST + EVENT_SPELL_CHANNEL + EVENT_SPELL_EFFECT + EVENT_SPELL_ENDCAST + EVENT_SPELL_FINISH)
        endfunction

        private function IsEventSingleFlag takes integer eventType returns boolean
            return eventType == EVENT_SPELL_CAST    or/*
                */ eventType == EVENT_SPELL_CHANNEL or/*
                */ eventType == EVENT_SPELL_EFFECT  or/*
                */ eventType == EVENT_SPELL_ENDCAST or/*
                */ eventType == EVENT_SPELL_FINISH
        endfunction

        private function AssertError takes boolean condition, string methodName, string structName, integer instance, string message returns nothing
            static if LIBRARY_ErrorMessage then
                call ThrowError(condition, SCOPE_PREFIX, methodName, structName, instance, message)
            endif
        endfunction
    endif

    /*===================================================================================*/

    private function OnOverrideParams takes nothing returns nothing
        set eventOrderType          = tempOrderType
        set eventLevel              = tempLevel
        set eventTriggerPlayer      = GetOwningPlayer(tempTriggerUnit)
        set eventTriggerUnit        = tempTriggerUnit
        set eventTargetX            = tempTargetX
        set eventTargetY            = tempTargetY

        if tempTarget == null then
            set eventTargetUnit     = null
            set eventTargetItem     = null
            set eventTargetDest     = null
        else
            set table[0].widget[0]  = tempTarget
            set eventTargetUnit     = table[0].unit[0]
            set eventTargetItem     = table[0].item[0]
            set eventTargetDest     = table[0].destructable[0]
            call table[0].handle.remove(0)
        endif

        set tempOrderType           = 0
        set tempLevel               = 0
        set tempTriggerUnit         = null
        set tempTargetX             = 0.00
        set tempTargetY             = 0.00
        set tempTarget              = null
    endfunction

    /*===================================================================================*/

    /*
    *   One Allocator for the whole library. Yes, it would be unlikely for this system to
    *   reach JASS_MAX_ARRAY_SIZE instances of allocated nodes at a single time.
    *
    *   Need to use custom Alloc because of the updated value for JASS_MAX_ARRAY_SIZE.
    *   Credits to MyPad for the allocation algorithm
    */
    private struct Node extends array
        private static thistype array stack
        static method allocate takes nothing returns thistype
            local thistype node = stack[0]
            if stack[node] == 0 then
                debug call AssertError(node == (JASS_MAX_ARRAY_SIZE - 1), "allocate()", "thistype", node, "Overflow")
                set node = node + 1
                set stack[0] = node
            else
                set stack[0] = stack[node]
                set stack[node] = 0
            endif
            return node
        endmethod
        method deallocate takes nothing returns nothing
            debug call AssertError(this == 0, "deallocate()", "thistype", 0, "Null node")
            debug call AssertError(stack[this] > 0, "deallocate()", "thistype", this, "Double-free")
            set stack[this] = stack[0]
            set stack[0] = this
        endmethod
    endstruct

    private module List
        readonly thistype prev
        readonly thistype next

        method makeHead takes nothing returns nothing
            set this.prev = this
            set this.next = this
        endmethod

        method insert takes thistype node returns nothing
            local thistype next = this.next
            set node.prev = this
            set node.next = next
            set next.prev = node
            set this.next = node
        endmethod

        method delete takes nothing returns nothing
            set this.next.prev = this.prev
            set this.prev.next = this.next
            set this.handle = null
            call Node(this).deallocate()
        endmethod
    endmodule

    private struct ConditionList extends array
        triggercondition handle
        implement List
    endstruct

    private struct ExprList extends array
        boolexpr handle
        implement List
        method operator conditionList takes nothing returns ConditionList
            return this
        endmethod
        method operator empty takes nothing returns boolean
            return this.next == this
        endmethod
        method insertExpr takes boolexpr expr returns thistype
            local thistype node = Node.allocate()
            set node.handle = expr
            call this.insert(node)
            return node
        endmethod
    endstruct

    private struct Handler extends array

        readonly trigger trigger

        boolean overrideParams
        integer disablerCounter
        private integer index
        private static ExprList array genericList

        private method operator exprList takes nothing returns ExprList
            return this
        endmethod

        /*
        *   You might think that the process of registering handlers are expensive in performance
        *   due to constant rebuilding of triggerconditions each time, but setting up proper spell
        *   handlers are seldom done (often only once per spell) and a large part of them are done
        *   at map initialization.
        */
        method updateHandlers takes nothing returns nothing
            local ExprList exprNode = genericList[this.index].next
            local ConditionList conditionNode
            call TriggerClearConditions(this.trigger)
            if exprNode != genericList[this.index].prev then
                loop
                    exitwhen exprNode == genericList[this.index]
                    set conditionNode = exprNode.conditionList.next
                    loop
                        exitwhen conditionNode == exprNode.conditionList
                        call TriggerAddCondition(this.trigger, exprNode.handle)
                        set conditionNode = conditionNode.next
                    endloop
                    set exprNode = exprNode.next
                endloop
            endif
            set exprNode = this.exprList.next
            loop
                exitwhen exprNode == this.exprList
                set conditionNode = exprNode.conditionList.next
                loop
                    exitwhen conditionNode == exprNode.conditionList
                    set conditionNode.handle = TriggerAddCondition(this.trigger, exprNode.handle)
                    set conditionNode = conditionNode.next
                endloop
                set exprNode = exprNode.next
            endloop
        endmethod
        /*
        *   This method is registered in position after all the generic handlers and before the
        *   ability-specific handlers. Its position allows it to unlink all the ability-specific
        *   handlers positioned after it or to change the event parameters, should the user choose to
        */
        private static method bridge takes nothing returns nothing
            local integer triggerId = GetHandleId(GetTriggeringTrigger())
            local thistype node = table[0][triggerId]
            local trigger tempTrig
            if node.disablerCounter > 0 then
                if node.exprList.next != node.exprList then
                    set tempTrig = node.trigger
                    set node.trigger = CreateTrigger()
                    set table[0][GetHandleId(node.trigger)] = node
                    call node.updateHandlers()
                    call table[0].remove(triggerId)
                    call TriggerClearConditions(tempTrig)
                    call DestroyTrigger(tempTrig)
                    set tempTrig = null
                endif
                return
            endif
            if node.overrideParams and node.exprList.next != node.exprList then
                call OnOverrideParams()
            endif
        endmethod

        static method registerGeneric takes integer eventIndex, boolexpr expr returns nothing
            local integer exprId = GetHandleId(expr)
            local ExprList exprNode = table[genericList[eventIndex]][exprId]
            local ConditionList conditionNode = Node.allocate()
            if exprNode == 0 then
                set exprNode = genericList[eventIndex].prev.prev.insertExpr(expr)
                call exprNode.conditionList.makeHead()
                set table[genericList[eventIndex]][exprId] = exprNode
            endif
            call exprNode.conditionList.prev.insert(conditionNode)
        endmethod
        static method unregisterGeneric takes integer eventIndex, integer exprId returns nothing
            local ExprList exprNode = table[genericList[eventIndex]][exprId]
            local ConditionList conditionNode = exprNode.conditionList.next
            loop
                exitwhen conditionNode == exprNode.conditionList
                call conditionNode.delete()
                set conditionNode = conditionNode.next
            endloop
            call table[genericList[eventIndex]].remove(exprId)
            call exprNode.delete()
        endmethod
        static method clearGeneric takes integer eventIndex returns nothing
            local ExprList exprNode = genericList[eventIndex].next
            loop
                exitwhen exprNode == genericList[eventIndex].prev
                call unregisterGeneric(eventIndex, GetHandleId(exprNode.handle))
                set exprNode = exprNode.next
            endloop
        endmethod

        method register takes boolexpr expr returns nothing
            local integer exprId = GetHandleId(expr)
            local ExprList exprNode = table[this][exprId]
            local ConditionList conditionNode = Node.allocate()
            if this.exprList.empty then
                set this.trigger = CreateTrigger()
                set table[0][GetHandleId(this.trigger)] = this
            endif
            if exprNode == 0 then
                set exprNode = this.exprList.prev.insertExpr(expr)
                call exprNode.conditionList.makeHead()
                set table[this][exprId] = exprNode
                call exprNode.conditionList.insert(conditionNode)
                call this.updateHandlers()
            else
                call exprNode.conditionList.prev.insert(conditionNode)
                if exprNode.next == this.exprList then
                    set conditionNode.handle = TriggerAddCondition(this.trigger, expr)
                else
                    call this.updateHandlers()
                endif
            endif
        endmethod
        method unregister takes integer exprId returns nothing
            local ExprList exprNode = table[this][exprId]
            local ConditionList conditionNode = exprNode.conditionList.next
            loop
                exitwhen conditionNode == exprNode.conditionList
                call TriggerRemoveCondition(this.trigger, conditionNode.handle)
                call conditionNode.delete()
                set conditionNode = conditionNode.next
            endloop
            call exprNode.delete()
            call table[this].remove(exprId)
            if this.exprList.empty then
                call table[0].remove(GetHandleId(this.trigger))
                call DestroyTrigger(this.trigger)
                set this.trigger = null
            endif
        endmethod
        method clear takes nothing returns nothing
            local ExprList exprNode = this.exprList.next
            loop
                exitwhen exprNode == this.exprList
                call this.unregister(GetHandleId(exprNode.handle))
                set exprNode = exprNode.next
            endloop
        endmethod

        static method create takes integer eventIndex returns thistype
            local thistype node = Node.allocate()
            call ExprList(node).makeHead()
            set node.index = eventIndex
            set node.disablerCounter = 0
            return node
        endmethod
        method destroy takes nothing returns nothing
            call this.clear()
            call Node(this).deallocate()
        endmethod

        debug static method hasGenericExpr takes integer eventIndex, boolexpr expr returns boolean
            debug return table[genericList[eventIndex]][GetHandleId(expr)] != 0
        debug endmethod
        debug method hasExpr takes boolexpr expr returns boolean
            debug return table[this][GetHandleId(expr)] != 0
        debug endmethod

        method operator enabled= takes boolean flag returns nothing
            if flag then
                call EnableTrigger(this.trigger)
            else
                call DisableTrigger(this.trigger)
            endif
        endmethod
        method operator enabled takes nothing returns boolean
            return IsTriggerEnabled(this.trigger)
        endmethod

        private static method initGenericList takes integer eventIndex returns nothing
            local ExprList list = create(eventIndex)
            local ExprList exprNode = list.insertExpr(bridgeExpr)
            call exprNode.conditionList.makeHead()
            call exprNode.conditionList.insert(Node.allocate())
            set genericList[eventIndex] = list
        endmethod

        static method init takes nothing returns nothing
            /*
            *   This bridge boolexpr executes after all the generic spell handlers
            *   before transitioning into the ability-specific spell handlers.
            *   This boolexpr is responsible for disabling the ability-specific handlers
            *   (if requested) as well as implementing the overriding of the event
            *   parameters.
            */
            local code bridgeFunc = function thistype.bridge
            set bridgeExpr = Filter(bridgeFunc)

            call initGenericList(eventIndex[EVENT_SPELL_CAST])
            call initGenericList(eventIndex[EVENT_SPELL_CHANNEL])
            call initGenericList(eventIndex[EVENT_SPELL_EFFECT])
            call initGenericList(eventIndex[EVENT_SPELL_ENDCAST])
            call initGenericList(eventIndex[EVENT_SPELL_FINISH])
        endmethod

    endstruct

    /*===================================================================================*/

    struct Spell extends array

        readonly integer abilId

        private static integer spellCount = 0
        private static Node spellKey
        private static Handler array eventHandler

        static if not LIBRARY_ResourcePreloader then
            private static unit preloadDummy
        endif

        static constant method operator abilityId takes nothing returns integer
            return eventAbilityId
        endmethod
        static constant method operator eventType takes nothing returns integer
            return eventEventType
        endmethod
        static constant method operator orderType takes nothing returns integer
            return eventOrderType
        endmethod
        static constant method operator level takes nothing returns integer
            return eventLevel
        endmethod
        static constant method operator triggerPlayer takes nothing returns player
            return eventTriggerPlayer
        endmethod
        static constant method operator triggerUnit takes nothing returns unit
            return eventTriggerUnit
        endmethod
        static constant method operator targetUnit takes nothing returns unit
            return eventTargetUnit
        endmethod
        static constant method operator targetItem takes nothing returns item
            return eventTargetItem
        endmethod
        static constant method operator targetDest takes nothing returns destructable
            return eventTargetDest
        endmethod
        static constant method operator target takes nothing returns widget
            if eventTargetUnit != null then
                return eventTargetUnit
            elseif eventTargetItem != null then
                return eventTargetItem
            elseif eventTargetDest != null then
                return eventTargetDest
            endif
            return null
        endmethod
        static constant method operator targetX takes nothing returns real
            return eventTargetX
        endmethod
        static constant method operator targetY takes nothing returns real
            return eventTargetY
        endmethod

        static method operator [] takes integer abilId returns thistype
            local thistype this = table[spellKey][abilId]
            local integer offset
            if this == 0 then
                debug call AssertError(spellCount > R2I(JASS_MAX_ARRAY_SIZE/5), "Spell[]", "thistype", 0, "Overflow")
                static if LIBRARY_ResourcePreloader then
                    call PreloadAbility(abilId)
                else
                    if UnitAddAbility(preloadDummy, abilId) then
                        call UnitRemoveAbility(preloadDummy, abilId)
                    endif
                endif
                set spellCount = spellCount + 1
                set thistype(spellCount).abilId = abilId
                set table[spellKey][abilId] = spellCount
                set offset = (spellCount - 1)*5
                set eventHandler[offset + eventIndex[EVENT_SPELL_CAST]]     = Handler.create(eventIndex[EVENT_SPELL_CAST])
                set eventHandler[offset + eventIndex[EVENT_SPELL_CHANNEL]]  = Handler.create(eventIndex[EVENT_SPELL_CHANNEL])
                set eventHandler[offset + eventIndex[EVENT_SPELL_EFFECT]]   = Handler.create(eventIndex[EVENT_SPELL_EFFECT])
                set eventHandler[offset + eventIndex[EVENT_SPELL_ENDCAST]]  = Handler.create(eventIndex[EVENT_SPELL_ENDCAST])
                set eventHandler[offset + eventIndex[EVENT_SPELL_FINISH]]   = Handler.create(eventIndex[EVENT_SPELL_FINISH])
                return spellCount
            endif
            return this
        endmethod

        static method operator GENERIC takes nothing returns thistype
            return thistype[0]
        endmethod

        static method registerGenericEventHandler takes integer eventType, code handler returns nothing
            local boolexpr expr = Filter(handler)
            local integer eventId = 0x10
            local integer node
            if eventType != 0 then
                debug call AssertError(not IsValidEventType(eventType), "registerGenericEventHandler()", "thistype", 0, "Invalid Spell Event Type (" + I2S(eventType) + ")")
                loop
                    exitwhen eventId == 0
                    if eventType >= eventId then
                        set eventType = eventType - eventId
                        call Handler.registerGeneric(eventIndex[eventId], expr)
                        set node = spellCount
                        loop
                            exitwhen node == 0
                            set node = node - 1
                            call eventHandler[node*5 + eventIndex[eventId]].updateHandlers()
                        endloop
                    endif
                    set eventId = eventId/2
                endloop
            endif
            set expr = null
        endmethod
        static method unregisterGenericEventHandler takes integer eventType, code handler returns nothing
            local boolexpr expr = Filter(handler)
            local integer eventId = 0x10
            local integer node
            if eventType != 0 then
                debug call AssertError(not IsValidEventType(eventType), "unregisterGenericEventHandler()", "thistype", 0, "Invalid Spell Event Type (" + I2S(eventType) + ")")
                loop
                    exitwhen eventId == 0
                    if eventType >= eventId then
                        set eventType = eventType - eventId
                        debug call AssertError(not Handler.hasGenericExpr(eventIndex[eventId], expr), "unregisterGenericEventHandler()", "thistype", 0, "EventType(" + I2S(eventType) + "): Code is not registered")
                        call Handler.unregisterGeneric(eventIndex[eventId], GetHandleId(expr))
                        set node = spellCount
                        loop
                            exitwhen node == 0
                            set node = node - 1
                            call eventHandler[node*5 + eventIndex[eventId]].updateHandlers()
                        endloop
                    endif
                    set eventId = eventId/2
                endloop
            endif
            set expr = null
        endmethod
        static method clearGenericEventHandlers takes integer eventType returns nothing
            local integer eventId = 0x10
            local integer node
            if eventType != 0 then
                debug call AssertError(not IsValidEventType(eventType), "clearGenericEventHandlers()", "thistype", 0, "Invalid Spell Event Type (" + I2S(eventType) + ")")
                loop
                    exitwhen eventId == 0
                    if eventType >= eventId then
                        set eventType = eventType - eventId
                        call Handler.clearGeneric(eventIndex[eventId])
                        set node = spellCount
                        loop
                            exitwhen node == 0
                            set node = node - 1
                            call eventHandler[node*5 + eventIndex[eventId]].updateHandlers()
                        endloop
                    endif
                    set eventId = eventId/2
                endloop
            endif
        endmethod
        static method clearGenericHandlers takes nothing returns nothing
            call clearGenericEventHandlers(EVENT_SPELL_CAST + EVENT_SPELL_CHANNEL + EVENT_SPELL_EFFECT + EVENT_SPELL_ENDCAST + EVENT_SPELL_FINISH)
        endmethod

        method registerEventHandler takes integer eventType, code handler returns nothing
            local boolexpr expr = Filter(handler)
            local integer offset = (this - 1)*5
            local integer eventId = 0x10
            if eventType != 0 then
                debug call AssertError((this) < 1 or (this) > spellCount, "registerEventHandler()", "thistype", this, "Invalid Spell instance")
                debug call AssertError(not IsValidEventType(eventType), "registerEventHandler()", "thistype", this, "Invalid Spell Event Type (" + I2S(eventType) + ")")
                if this == GENERIC then
                    call registerGenericEventHandler(eventType, handler)
                else
                    loop
                        exitwhen eventId == 0
                        if eventType >= eventId then
                            set eventType = eventType - eventId
                            call eventHandler[offset + eventIndex[eventId]].register(expr)
                        endif
                        set eventId = eventId/2
                    endloop
                endif
            endif
            set expr = null
        endmethod
        method unregisterEventHandler takes integer eventType, code handler returns nothing
            local boolexpr expr = Filter(handler)
            local integer offset = (this - 1)*5
            local integer eventId = 0x10
            if eventType != 0 then
                debug call AssertError((this) < 1 or (this) > spellCount, "unregisterEventHandler()", "thistype", this, "Invalid Spell instance")
                debug call AssertError(not IsValidEventType(eventType), "unregisterEventHandler()", "thistype", this, "Invalid Spell Event Type (" + I2S(eventType) + ")")
                if this == GENERIC then
                    call unregisterGenericEventHandler(eventType, handler)
                else
                    loop
                        exitwhen eventId == 0
                        if eventType >= eventId then
                            set eventType = eventType - eventId
                            debug call AssertError(not eventHandler[offset + eventIndex[eventId]].hasExpr(expr), "registerEventHandler()", "thistype", this, "EventType(" + I2S(eventType) + "): Code is already unregistered")
                            call eventHandler[offset + eventIndex[eventId]].unregister(GetHandleId(expr))
                        endif
                        set eventId = eventId/2
                    endloop
                endif
            endif
            set expr = null
        endmethod
        method clearEventHandlers takes integer eventType returns nothing
            local integer offset = (this - 1)*5
            local integer eventId = 0x10
            if eventType != 0 then
                debug call AssertError((this) < 1 or (this) > spellCount, "SpellEvent", "clearEventHandlers()", this, "Invalid Spell instance")
                debug call AssertError(not IsValidEventType(eventType), "SpellEvent", "clearEventHandlers()", this, "Invalid Spell Event Type (" + I2S(eventType) + ")")
                if this == GENERIC then
                    call clearGenericEventHandlers(eventType)
                else
                    loop
                        exitwhen eventId == 0
                        if eventType >= eventId then
                            set eventType = eventType - eventId
                            call eventHandler[offset + eventIndex[eventId]].clear()
                        endif
                        set eventId = eventId/2
                    endloop
                endif
            endif
        endmethod
        method clearHandlers takes nothing returns nothing
            debug call AssertError((this) < 1 or (this) > spellCount, "clearHandlers()", "thistype", this, "Invalid Spell instance")
            if this == GENERIC then
                call this.clearGenericHandlers()
            else
                call this.clearEventHandlers(EVENT_SPELL_CAST + EVENT_SPELL_CHANNEL + EVENT_SPELL_EFFECT + EVENT_SPELL_ENDCAST + EVENT_SPELL_FINISH)
            endif
        endmethod

        method setEventFlag takes integer eventType, boolean flag returns nothing
            debug call AssertError(not IsEventSingleFlag(eventType), "setEventFlag()", "thistype", this, "Spell Event Type does not contain a single flag (" + I2S(eventType) + ")")
            set eventHandler[(this - 1)*5 + eventIndex[eventType]].enabled = flag
        endmethod
        method getEventFlag takes integer eventType returns boolean
            debug call AssertError(not IsEventSingleFlag(eventType), "getEventFlag()", "thistype", this, "Spell Event Type does not contain a single flag (" + I2S(eventType) + ")")
            return eventHandler[(this - 1)*5 + eventIndex[eventType]].enabled
        endmethod

        method operator handlersDisabled= takes boolean disabled returns nothing
            local Handler handler
            if eventAbilityId == this.abilId then
                set handler = eventHandler[(this - 1)*5 + eventIndex[eventEventType]]
                if disabled then
                    set handler.disablerCounter = handler.disablerCounter + 1
                else
                    set handler.disablerCounter = handler.disablerCounter - 1
                endif
            endif
        endmethod
        method operator handlersDisabled takes nothing returns boolean
            if eventAbilityId != this.abilId then
                return false
            endif
            return eventHandler[(this - 1)*5 + eventIndex[eventEventType]].disablerCounter > 0
        endmethod

        private static method overrideParams takes integer orderType, integer level, unit triggerUnit, widget target, real targetX, real targetY returns nothing
            if eventAbilityId != 0 then
                set Handler(table[0][GetHandleId(GetTriggeringTrigger())]).overrideParams = true

                set tempOrderType           = orderType
                set tempLevel               = level
                set tempTriggerPlayer       = GetOwningPlayer(triggerUnit)
                set tempTriggerUnit         = triggerUnit
                set tempTargetX             = targetX
                set tempTargetY             = targetY
                set tempTarget              = target
            endif
        endmethod

        static method overrideNoTargetParams takes integer level, unit triggerUnit returns nothing
            call overrideParams(SPELL_ORDER_TYPE_NO_TARGET, level, triggerUnit, null, GetUnitX(triggerUnit), GetUnitY(triggerUnit))
        endmethod
        static method overridePointTargetParams takes integer level, unit triggerUnit, real targetX, real targetY returns nothing
            call overrideParams(SPELL_ORDER_TYPE_POINT_TARGET, level, triggerUnit, null, targetX, targetY)
        endmethod
        static method overrideSingleTargetParams takes integer level, unit triggerUnit, widget target returns nothing
            call overrideParams(SPELL_ORDER_TYPE_SINGLE_TARGET, level, triggerUnit, target, GetWidgetX(target), GetWidgetY(target))
        endmethod

        private static method executeEventHandler takes Handler eventHandler, integer currentId, boolean manualInvoke, integer eventFlag, integer orderType, integer level, unit triggerUnit, widget target, real targetX, real targetY returns nothing

            local integer disablerCounter       = eventHandler.disablerCounter
            local boolean overrideParams        = eventHandler.overrideParams
            local integer prevAbilityId         = eventAbilityId
            local integer prevEventType         = eventEventType
            local integer prevOrderType         = eventOrderType
            local integer prevLevel             = eventLevel
            local player prevTriggerPlayer      = eventTriggerPlayer
            local unit prevTriggerUnit          = eventTriggerUnit
            local real prevTargetX              = eventTargetX
            local real prevTargetY              = eventTargetY
            local unit prevTargetUnit           = eventTargetUnit
            local item prevTargetItem           = eventTargetItem
            local destructable prevTargetDest   = eventTargetDest
            local location tempLoc

            set eventAbilityId                  = currentId

            if manualInvoke then
                set eventEventType              = eventFlag
                set eventOrderType              = orderType
                set eventLevel                  = level
                set eventTriggerPlayer          = GetOwningPlayer(triggerUnit)
                set eventTriggerUnit            = triggerUnit
                set eventTargetX                = targetX
                set eventTargetY                = targetY

                set table[0].widget[0]          = target
                set eventTargetUnit             = table[0].unit[0]
                set eventTargetItem             = table[0].item[0]
                set eventTargetDest             = table[0].destructable[0]
            else
                set eventEventType              = eventTypeId[GetHandleId(GetTriggerEventId())]
                set eventTriggerPlayer          = GetTriggerPlayer()
                set eventTriggerUnit            = GetTriggerUnit()
                set eventLevel                  = GetUnitAbilityLevel(eventTriggerUnit, eventAbilityId)
                set eventTargetUnit             = GetSpellTargetUnit()
                set eventTargetItem             = GetSpellTargetItem()
                set eventTargetDest             = GetSpellTargetDestructable()

                if eventTargetUnit != null then
                    if eventTargetUnit == eventTriggerUnit              and/*
                    */ not (GetSpellTargetX() != 0.)                    and/*
                    */ not (GetSpellTargetY() != 0.)                    then
                    /* Special Case (for no-target spells based on channel) */
                        set eventTargetX        = GetUnitX(eventTriggerUnit)
                        set eventTargetY        = GetUnitY(eventTriggerUnit)
                        set eventTargetUnit     = null
                        set eventOrderType      = SPELL_ORDER_TYPE_NO_TARGET
                    else
                        set eventTargetX        = GetUnitX(eventTargetUnit)
                        set eventTargetY        = GetUnitY(eventTargetUnit)
                        set eventOrderType      = SPELL_ORDER_TYPE_SINGLE_TARGET
                    endif
                elseif eventTargetItem != null then
                    set eventTargetX            = GetItemX(eventTargetItem)
                    set eventTargetY            = GetItemY(eventTargetItem)
                    set eventOrderType          = SPELL_ORDER_TYPE_SINGLE_TARGET
                elseif eventTargetDest != null then
                    set eventTargetX            = GetWidgetX(eventTargetDest)
                    set eventTargetY            = GetWidgetY(eventTargetDest)
                    set eventOrderType          = SPELL_ORDER_TYPE_SINGLE_TARGET
                else
                    set tempLoc = GetSpellTargetLoc()
                    if tempLoc == null then
                    /* Special Case (for some no-target spells) */
                        set eventTargetX        = GetUnitX(eventTriggerUnit)
                        set eventTargetY        = GetUnitY(eventTriggerUnit)
                        set eventOrderType      = SPELL_ORDER_TYPE_NO_TARGET
                    else
                        call RemoveLocation(tempLoc)
                        set tempLoc = null
                        set eventTargetX        = GetSpellTargetX()
                        set eventTargetY        = GetSpellTargetY()
                        set eventOrderType      = SPELL_ORDER_TYPE_POINT_TARGET
                    endif
                endif
            endif

            set eventHandler.disablerCounter    = 0
            set eventHandler.overrideParams     = false
            call TriggerEvaluate(eventHandler.trigger)
            set eventHandler.disablerCounter    = disablerCounter
            set eventHandler.overrideParams     = overrideParams

            set eventAbilityId                  = prevAbilityId
            set eventEventType                  = prevEventType
            set eventOrderType                  = prevOrderType
            set eventLevel                      = prevLevel
            set eventTriggerPlayer              = prevTriggerPlayer
            set eventTriggerUnit                = prevTriggerUnit
            set eventTargetX                    = prevTargetX
            set eventTargetY                    = prevTargetY
            set eventTargetUnit                 = prevTargetUnit
            set eventTargetItem                 = prevTargetItem
            set eventTargetDest                 = prevTargetDest

            set prevTriggerPlayer               = null
            set prevTriggerUnit                 = null
            set prevTargetUnit                  = null
            set prevTargetItem                  = null
            set prevTargetDest                  = null

        endmethod

        private method invokeEvent takes integer eventType, integer orderType, integer level, unit triggerUnit, widget target, real targetX, real targetY returns nothing
            local Handler handler = eventHandler[(this - 1)*5 + eventIndex[eventType]]
            if handler != 0 and handler.enabled then
                call executeEventHandler(handler, this.abilId, true, eventType, orderType, level, triggerUnit, target, targetX, targetY)
            endif
        endmethod

        method invokeNoTargetEvent takes integer eventType, integer level, unit triggerUnit returns nothing
            debug call AssertError(not IsEventSingleFlag(eventType), "executeNoTargetEvent()", "thistype", this, "Spell Event Type does not contain a single flag (" + I2S(eventType) + ")")
            call this.invokeEvent(eventType, SPELL_ORDER_TYPE_NO_TARGET, level, triggerUnit, null, GetUnitX(triggerUnit), GetUnitY(triggerUnit))
        endmethod
        method invokePointTargetEvent takes integer eventType, integer level, unit triggerUnit, real targetX, real targetY returns nothing
            debug call AssertError(not IsEventSingleFlag(eventType), "executePointTargetEvent()", "thistype", this, "Spell Event Type does not contain a single flag (" + I2S(eventType) + ")")
            call this.invokeEvent(eventType, SPELL_ORDER_TYPE_POINT_TARGET, level, triggerUnit, null, targetX, targetY)
        endmethod
        method invokeSingleTargetEvent takes integer eventType, integer level, unit triggerUnit, widget target returns nothing
            debug call AssertError(not IsEventSingleFlag(eventType), "executeSingleTargetEvent()", "thistype", this, "Spell Event Type does not contain a single flag (" + I2S(eventType) + ")")
            call this.invokeEvent(eventType, SPELL_ORDER_TYPE_SINGLE_TARGET, level, triggerUnit, target, GetWidgetX(target), GetWidgetY(target))
        endmethod

        private static method onSpellEvent takes integer eventIndex returns nothing
            local integer id = GetSpellAbilityId()
            local Handler handler = eventHandler[(table[spellKey][id] - 1)*5 + eventIndex]
            if handler != 0 and handler.enabled then
                call executeEventHandler(handler, id, false, 0, 0, 0, null, null, 0.00, 0.00)
            endif
        endmethod

        private static method onSpellCast takes nothing returns nothing
            call onSpellEvent(eventIndex[EVENT_SPELL_CAST])
        endmethod
        private static method onSpellChannel takes nothing returns nothing
            call onSpellEvent(eventIndex[EVENT_SPELL_CHANNEL])
        endmethod
        private static method onSpellEffect takes nothing returns nothing
            call onSpellEvent(eventIndex[EVENT_SPELL_EFFECT])
        endmethod
        private static method onSpellEndcast takes nothing returns nothing
            call onSpellEvent(eventIndex[EVENT_SPELL_ENDCAST])
        endmethod
        private static method onSpellFinish takes nothing returns nothing
            call onSpellEvent(eventIndex[EVENT_SPELL_FINISH])
        endmethod

        private static method registerEvent takes playerunitevent whichEvent, code handler returns nothing
            static if LIBRARY_RegisterPlayerUnitEvent then
                call RegisterAnyPlayerUnitEvent(whichEvent, handler)
            else
                local trigger t = CreateTrigger()
                call TriggerRegisterAnyUnitEventBJ(t, whichEvent)
                call TriggerAddCondition(t, Filter(handler))
                set t = null
            endif
        endmethod

        static if not LIBRARY_ResourcePreloader then
            private static method initPreloadDummy takes nothing returns nothing
                local rect world = GetWorldBounds()
                set preloadDummy = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'hpea', 0.00, 0.00, 0.00)
                call UnitAddAbility(preloadDummy, 'AInv')
                call UnitAddAbility(preloadDummy, 'Avul')
                call UnitRemoveAbility(preloadDummy, 'Amov')
                call SetUnitY(preloadDummy, GetRectMaxY(world) + 1000.00)
                call RemoveRect(world)
                set world = null
            endmethod
        endif

        private static method init takes nothing returns nothing
            set spellKey = Node.allocate()
            set spellCount = spellCount + 1
            set table[spellKey][0] = spellCount

            set eventIndex[EVENT_SPELL_CAST]    = 1
            set eventIndex[EVENT_SPELL_CHANNEL] = 2
            set eventIndex[EVENT_SPELL_EFFECT]  = 3
            set eventIndex[EVENT_SPELL_ENDCAST] = 4
            set eventIndex[EVENT_SPELL_FINISH]  = 5
            set eventTypeId[GetHandleId(EVENT_PLAYER_UNIT_SPELL_CAST)]	    = EVENT_SPELL_CAST
            set eventTypeId[GetHandleId(EVENT_PLAYER_UNIT_SPELL_CHANNEL)]	= EVENT_SPELL_CHANNEL
            set eventTypeId[GetHandleId(EVENT_PLAYER_UNIT_SPELL_EFFECT)]	= EVENT_SPELL_EFFECT
            set eventTypeId[GetHandleId(EVENT_PLAYER_UNIT_SPELL_ENDCAST)]	= EVENT_SPELL_ENDCAST
            set eventTypeId[GetHandleId(EVENT_PLAYER_UNIT_SPELL_FINISH)]	= EVENT_SPELL_FINISH
            call registerEvent(EVENT_PLAYER_UNIT_SPELL_CAST, function thistype.onSpellCast)
            call registerEvent(EVENT_PLAYER_UNIT_SPELL_CHANNEL, function thistype.onSpellChannel)
            call registerEvent(EVENT_PLAYER_UNIT_SPELL_EFFECT, function thistype.onSpellEffect)
            call registerEvent(EVENT_PLAYER_UNIT_SPELL_ENDCAST, function thistype.onSpellEndcast)
            call registerEvent(EVENT_PLAYER_UNIT_SPELL_FINISH, function thistype.onSpellFinish)

            static if not LIBRARY_ResourcePreloader then
                call initPreloadDummy()
            endif
        endmethod
        implement Init

    endstruct

    private module Init
        private static method onInit takes nothing returns nothing
            set table = TableArray[JASS_MAX_ARRAY_SIZE]
            call init()
            call Handler.init()
        endmethod
    endmodule

    /*===================================================================================*/

    constant function GetEventSpellAbilityId takes nothing returns integer
        return Spell.abilityId
    endfunction
    constant function GetEventSpellEventType takes nothing returns integer
        return Spell.eventType
    endfunction
    constant function GetEventSpellOrderType takes nothing returns integer
        return Spell.orderType
    endfunction
    constant function GetEventSpellLevel takes nothing returns integer
        return Spell.level
    endfunction
    constant function GetEventSpellPlayer takes nothing returns player
        return Spell.triggerPlayer
    endfunction
    constant function GetEventSpellCaster takes nothing returns unit
        return Spell.triggerUnit
    endfunction
    constant function GetEventSpellTargetUnit takes nothing returns unit
        return Spell.targetUnit
    endfunction
    constant function GetEventSpellTargetItem takes nothing returns item
        return Spell.targetItem
    endfunction
    constant function GetEventSpellTargetDest takes nothing returns destructable
        return Spell.targetDest
    endfunction
    constant function GetEventSpellTarget takes nothing returns widget
        return Spell.target
    endfunction
    constant function GetEventSpellTargetX takes nothing returns real
        return Spell.targetX
    endfunction
    constant function GetEventSpellTargetY takes nothing returns real
        return Spell.targetY
    endfunction

    function SetSpellEventFlag takes integer abilId, integer eventType, boolean flag returns nothing
        debug call AssertError(not IsEventSingleFlag(eventType), "SetSpellEventFlag()", "", 0, "Spell(" + I2S(abilId) + "): Invalid Spell Event Type (" + I2S(eventType) + ")")
        call Spell[abilId].setEventFlag(eventType, flag)
    endfunction
    function GetSpellEventFlag takes integer abilId, integer eventType returns boolean
        debug call AssertError(not IsEventSingleFlag(eventType), "GetSpellEventFlag()", "", 0, "Spell(" + I2S(abilId) + "): Invalid Spell Event Type (" + I2S(eventType) + ")")
        return Spell[abilId].getEventFlag(eventType)
    endfunction

    function SpellCancelEventHandlers takes boolean cancel returns nothing
        set Spell[GetEventSpellAbilityId()].handlersDisabled = cancel
    endfunction

    function SpellInvokeNoTargetEvent takes integer abilId, integer eventType, integer level, unit caster returns nothing
        call Spell[abilId].invokeNoTargetEvent(eventType, level, caster)
    endfunction
    function SpellInvokePointTargetEvent takes integer abilId, integer eventType, integer level, unit caster, real targetX, real targetY returns nothing
        call Spell[abilId].invokePointTargetEvent(eventType, level, caster, targetX, targetY)
    endfunction
    function SpellInvokeSingleTargetEvent takes integer abilId, integer eventType, integer level, unit caster, widget target returns nothing
        call Spell[abilId].invokeSingleTargetEvent(eventType, level, caster, target)
    endfunction

    function SpellOverrideNoTargetParams takes integer level, unit caster returns nothing
        call Spell.overrideNoTargetParams(level, caster)
    endfunction
    function SpellOverridePointTargetParams takes integer level, unit caster, real targetX, real targetY returns nothing
        call Spell.overridePointTargetParams(level, caster, targetX, targetY)
    endfunction
    function SpellOverrideSingleTargetParams takes integer level, unit caster, widget target returns nothing
        call Spell.overrideSingleTargetParams(level, caster, target)
    endfunction

    function SpellRegisterEventHandler takes integer abilId, integer eventType, code handler returns nothing
        debug call AssertError(eventType != 0 and not IsValidEventType(eventType), "SpellRegisterEventHandler()", "", 0, "Spell(" + I2S(abilId) + "): Invalid Spell Event Type (" + I2S(eventType) + ")")
        call Spell[abilId].registerEventHandler(eventType, handler)
    endfunction
    function SpellUnregisterEventHandler takes integer abilId, integer eventType, code handler returns nothing
        debug call AssertError(eventType != 0 and not IsValidEventType(eventType), "SpellUnregisterEventHandler()", "", 0, "Spell(" + I2S(abilId) + "): Invalid Spell Event Type (" + I2S(eventType) + ")")
        call Spell[abilId].unregisterEventHandler(eventType, handler)
    endfunction
    function SpellClearEventHandlers takes integer abilId, integer eventType returns nothing
        debug call AssertError(eventType != 0 and not IsValidEventType(eventType), "SpellClearEventHandler()", "", 0, "Spell(" + I2S(abilId) + "): Invalid Spell Event Type (" + I2S(eventType) + ")")
        call Spell[abilId].clearEventHandlers(eventType)
    endfunction
    function SpellClearHandlers takes integer abilId returns nothing
        call Spell[abilId].clearHandlers()
    endfunction

    function SpellRegisterGenericEventHandler takes integer eventType, code handler returns nothing
        debug call AssertError(eventType != 0 and not IsValidEventType(eventType), "SpellRegisterGenericEventHandler()", "", 0, "Invalid Spell Event Type (" + I2S(eventType) + ")")
        call Spell.registerGenericEventHandler(eventType, handler)
    endfunction
    function SpellUnregisterGenericEventHandler takes integer eventType, code handler returns nothing
        debug call AssertError(eventType != 0 and not IsValidEventType(eventType), "SpellUnregisterGenericEventHandler()", "", 0, "Invalid Spell Event Type (" + I2S(eventType) + ")")
        call Spell.unregisterGenericEventHandler(eventType, handler)
    endfunction
    function SpellClearGenericEventHandlers takes integer eventType returns nothing
        debug call AssertError(eventType != 0 and not IsValidEventType(eventType), "SpellClearGenericEventHandlers()", "", 0, "Invalid Spell Event Type (" + I2S(eventType) + ")")
        call Spell.clearGenericEventHandlers(eventType)
    endfunction
    function SpellClearGenericHandlers takes nothing returns nothing
        call Spell.clearGenericHandlers()
    endfunction

    /*===================================================================================*/

    private function DestroyTimerEx takes timer whichTimer returns nothing
        call PauseTimer(whichTimer)
        call DestroyTimer(whichTimer)
    endfunction

    private function OnSpellEventEx takes integer node, real period, code callback returns nothing
        local timer periodicTimer
        if node > 0 then
            set periodicTimer = CreateTimer()
            set table[0][GetHandleId(periodicTimer)] = node
            call TimerStart(periodicTimer, period, true, callback)
            set periodicTimer = null
        endif
    endfunction

    private function RegisterSpell takes integer abilId, integer eventType, code onSpellEvent returns nothing
        if abilId != 0 then
            call SpellRegisterEventHandler(abilId, eventType, onSpellEvent)
        endif
    endfunction

    module SpellEvent
        static if thistype.onSpellPeriodic.exists then
            private static method enqueue takes thistype node returns nothing
                local thistype last = thistype(0).prev
                set thistype(0).prev = node
                set last.next = node
                set node.prev = last
                set node.next = 0
            endmethod

            private static method onPeriodic takes nothing returns nothing
                local thistype node = thistype(0).next
                local thistype next
                if node == 0 then
                /*
                *   For some reason, some guy tried to manually remove his node from the supposed
                *   readonly linked-list, without realizing that he ALMOST messed up the system..
                */
                    call DestroyTimerEx(GetExpiredTimer())
                    return
                endif
                loop
                    exitwhen node == 0
                    set next = node.next
                    if not node.onSpellPeriodic() then
                        set node.next.prev = node.prev
                        set node.prev.next = node.next
                        static if thistype.onSpellEnd.exists then
                            call node.onSpellEnd()
                        endif
                        if node.internal then
                            set node.internal = false
                            call Node(node).deallocate()
                        endif
                        if thistype(0).next == 0 then
                            call DestroyTimerEx(GetExpiredTimer())
                        endif
                    endif
                    set node = next
                endloop
            endmethod
        endif

        static if not thistype.onSpellPeriodic.exists and not thistype.onSpellEnd.exists then
            private static method onSpellEvent takes nothing returns nothing
                call thistype(0).onSpellStart()
            endmethod
        else
            readonly thistype prev
            readonly thistype next
            private boolean internal

            private static method onSpellEvent takes nothing returns nothing
                local thistype node = Node.allocate()
                local boolean prevEmpty = thistype(0).next == 0
                local thistype used = node.onSpellStart()
                /*
                *   Add the new node into the list
                */
                if used == node then
                    debug call AssertError(used.next.prev == used, "[internal] onSpellStart()", "thistype", used, "[Node Already Exists] : Make sure your nodes are all from the same stack..")
                    static if thistype.onSpellPeriodic.exists then
                        set used.internal = true
                        call enqueue(used)
                    elseif thistype.onSpellEnd.exists then
                        call used.onSpellEnd()
                        call used.deallocate()
                    endif
                else
                /*
                *   If the user returned a different node than the one he was given,
                *   deallocate the earlier node and replace it with the new node
                *   from the user.
                */
                    call Node(node).deallocate()
                    if used > 0 then
                        debug call AssertError(used.next.prev == used, "[internal] onSpellStart()", "thistype", used, "[Node Already Exists] : Make sure your nodes are all from the same stack..")
                        static if thistype.onSpellPeriodic.exists then
                            call enqueue(used)
                        elseif thistype.onSpellEnd.exists then
                            call used.onSpellEnd()
                        endif
                    endif
                endif
                /*
                *   We need to use this kind of check in case the user returned 0
                *   but manually added some node in the list inside onSpellStart()
                */
                static if thistype.onSpellPeriodic.exists then
                    if prevEmpty and thistype(0).next != 0 then
                        call TimerStart(CreateTimer(), SPELL_PERIOD, true, function thistype.onPeriodic)
                    endif
                endif
            endmethod
        endif

        private static method onInit takes nothing returns nothing
            call RegisterSpell(SPELL_ABILITY_ID, SPELL_EVENT_TYPE, function thistype.onSpellEvent)
            static if thistype.onSpellEventModuleInit.exists then
                call onSpellEventModuleInit()
            endif
        endmethod

        static method registerSpellEvent takes integer abilId, integer eventType returns nothing
            call SpellRegisterEventHandler(abilId, eventType, function thistype.onSpellEvent)
        endmethod
    endmodule

    module SpellEventEx
        static if thistype.onSpellPeriodic.exists then
            private static method onPeriodic takes nothing returns nothing
                local timer expired = GetExpiredTimer()
                local integer handleId = GetHandleId(expired)
                local thistype node = table[0][handleId]
                if not node.onSpellPeriodic() then
                    static if thistype.onSpellEnd.exists then
                        call node.onSpellEnd()
                    endif
                    call table[0].remove(handleId)
                    call DestroyTimerEx(expired)
                endif
                set expired = null
            endmethod
        endif

        private static method onSpellEvent takes nothing returns nothing
            static if thistype.onSpellPeriodic.exists then
                call OnSpellEventEx(onSpellStart(), SPELL_PERIOD, function thistype.onPeriodic)
            elseif thistype.onSpellEnd.exists then
                local thistype node = onSpellStart()
                if node > 0 then
                    call node.onSpellEnd()
                endif
            else
                call onSpellStart()
            endif
        endmethod

        private static method onInit takes nothing returns nothing
            call RegisterSpell(SPELL_ABILITY_ID, SPELL_EVENT_TYPE, function thistype.onSpellEvent)
            static if thistype.onSpellEventModuleInit.exists then
                call onSpellEventModuleInit()
            endif
        endmethod

        static method registerSpellEvent takes integer abilId, integer eventType returns nothing
            call SpellRegisterEventHandler(abilId, eventType, function thistype.onSpellEvent)
        endmethod
    endmodule

    module SpellEventGeneric
        private static method onSpellResponse takes nothing returns nothing
            static if thistype.onSpellEvent.exists then
                call onSpellEvent()
            endif
            static if thistype.onSpellCast.exists then
                if GetEventSpellEventType() == EVENT_SPELL_CAST then
                    call onSpellCast()
                endif
            endif
            static if thistype.onSpellChannel.exists then
                if GetEventSpellEventType() == EVENT_SPELL_CHANNEL then
                    call onSpellChannel()
                endif
            endif
            static if thistype.onSpellEffect.exists then
                if GetEventSpellEventType() == EVENT_SPELL_EFFECT then
                    call onSpellEffect()
                endif
            endif
            static if thistype.onSpellEndcast.exists then
                if GetEventSpellEventType() == EVENT_SPELL_ENDCAST then
                    call onSpellEndcast()
                endif
            endif
            static if thistype.onSpellFinish.exists then
                if GetEventSpellEventType() == EVENT_SPELL_FINISH then
                    call onSpellFinish()
                endif
            endif
        endmethod
        private static method onInit takes nothing returns nothing
            call SpellRegisterGenericEventHandler(EVENT_SPELL_CAST + EVENT_SPELL_CHANNEL + EVENT_SPELL_EFFECT + EVENT_SPELL_ENDCAST + EVENT_SPELL_FINISH, function thistype.onSpellResponse)
            static if thistype.onSpellEventGenericModuleInit.exists then
                call onSpellEventGenericModuleInit()
            endif
        endmethod
    endmodule


endlibrary