library SpellEventGUI /* v1.0.2


    */uses /*

    */SpellEvent                /*  https://www.hiveworkshop.com/threads/301895/
    */Table                     /*  https://www.hiveworkshop.com/threads/188084/

    */optional ErrorMessage     /*  https://github.com/nestharus/JASS/blob/master/jass/Systems/ErrorMessage/main.j


    *///! novjass

    |=========|
    | CREDITS |
    |=========|
    /*
        - AGD (Author)
        - Bribe (SpellSystem GUI, some features of which I adapted into this GUI Plugin)

    *///! endnovjass

    /*=============================================================================================*/

    native UnitAlive takes unit u returns boolean

    globals
        private constant integer    STOP_ORDER_ID = 851972

        private integer array       nodeAbilityId
        private integer array       nodeEventType
        private integer array       nodeOrderType
        private integer array       nodeLevel
        private player array        nodeTriggerPlayer
        private unit array          nodeTriggerUnit
        private real array          nodeTargetX
        private real array          nodeTargetY
        private location array      nodeTargetPoint
        private unit array          nodeTargetUnit
        private item array          nodeTargetItem
        private destructable array  nodeTargetDest
        private integer array       filterInstance
        private integer array       eventIndex

        private location staticLocation = Location(0.00, 0.00)
        private group enumGroup = CreateGroup()
        private integer prevEnumCount = 0
    endglobals

    private function ResolveFilterFlag takes boolean state, boolean allowTrue, boolean allowFalse returns boolean
        return (not state or allowTrue) and (state or allowFalse)
    endfunction

    private function GetTarget takes nothing returns widget
        if udg_SPELL__TargetUnit != null then
            return udg_SPELL__TargetUnit
        elseif udg_SPELL__TargetItem != null then
            return udg_SPELL__TargetItem
        elseif udg_SPELL__TargetDest != null then
            return udg_SPELL__TargetDest
        endif
        return null
    endfunction

    private function GetLevel takes nothing returns integer
        if udg_SPELL__Level == 0 then
            return R2I(udg_SPELL__RealLevel)
        endif
        return udg_SPELL__Level
    endfunction

    private function InitEventParams takes integer abilityId, integer eventType, integer orderType, integer level, player triggerPlayer, unit triggerUnit, real targetX, real targetY, location targetPoint, unit targetUnit, item targetItem, destructable targetDest returns nothing
        call MoveLocation(targetPoint, targetX, targetY)
        set udg_SPELL__Ability          = abilityId
        set udg_SPELL__EventType        = eventType
        set udg_SPELL__OrderType        = orderType
        set udg_SPELL__Level            = level
        set udg_SPELL__RealLevel        = level
        set udg_SPELL__TriggerPlayer    = triggerPlayer
        set udg_SPELL__TriggerUnit      = triggerUnit
        set udg_SPELL__TargetPoint      = targetPoint
        set udg_SPELL__TargetUnit       = targetUnit
        set udg_SPELL__TargetItem       = targetItem
        set udg_SPELL__TargetDest       = targetDest
    endfunction

    private function LoadEventParams takes integer node returns nothing
        call InitEventParams(/*
            */nodeAbilityId[node], /*
            */nodeEventType[node], /*
            */nodeOrderType[node], /*
            */nodeLevel[node], /*
            */nodeTriggerPlayer[node], /*
            */nodeTriggerUnit[node], /*
            */nodeTargetX[node], /*
            */nodeTargetY[node], /*
            */nodeTargetPoint[node], /*
            */nodeTargetUnit[node], /*
            */nodeTargetItem[node], /*
            */nodeTargetDest[node])
    endfunction

    private function SaveEventParams takes integer node returns nothing
        set nodeAbilityId[node]         = udg_SPELL__Ability
        set nodeEventType[node]         = udg_SPELL__EventType
        set nodeOrderType[node]         = udg_SPELL__OrderType
        set nodeLevel[node]             = udg_SPELL__Level
        set nodeTriggerPlayer[node]     = udg_SPELL__TriggerPlayer
        set nodeTriggerUnit[node]       = udg_SPELL__TriggerUnit
        set nodeTargetX[node]           = GetLocationX(udg_SPELL__TargetPoint)
        set nodeTargetY[node]           = GetLocationY(udg_SPELL__TargetPoint)
        set nodeTargetPoint[node]       = udg_SPELL__TargetPoint
        set nodeTargetUnit[node]        = udg_SPELL__TargetUnit
        set nodeTargetItem[node]        = udg_SPELL__TargetItem
        set nodeTargetDest[node]        = udg_SPELL__TargetDest
    endfunction

    private function EvaluateHandler takes trigger handlerTrigger returns nothing
        if IsTriggerEnabled(handlerTrigger) and TriggerEvaluate(handlerTrigger) then
            call TriggerExecute(handlerTrigger)
        endif
    endfunction

    private struct HandlerList extends array

        readonly thistype current
        readonly thistype prev
        readonly thistype next

        readonly trigger onStartTrigger
        readonly trigger onPeriodTrigger
        readonly trigger onEndTrigger

        boolean enemyFlag
        boolean allyFlag
        boolean deadFlag
        boolean livingFlag
        boolean magicImmuneFlag
        boolean mechanicalFlag
        boolean structureFlag
        boolean flyingFlag
        boolean heroFlag
        boolean nonHeroFlag

        private static thistype node = 0

        method nextNode takes nothing returns nothing
            set this.current = this.current.next
        endmethod

		static method create takes nothing returns thistype
			set node = node + 1
			set node.prev = node
			set node.next = node
			set node.current = node
			return node
		endmethod

		method pushBack takes trigger onStart, trigger onPeriod, trigger onEnd returns thistype
			local thistype next = this.next
            set node = node + 1
			set node.prev = this
			set node.next = next
			set next.prev = node
			set this.next = node
            set node.onStartTrigger = onStart
            set node.onPeriodTrigger = onPeriod
            set node.onEndTrigger = onEnd
            return node
		endmethod

    endstruct

    private struct SpellEventGUI extends array
        /*
        *   Default spell period: value will be set by the GUI configuration
        */
        private static real SPELL_PERIOD

        private static constant integer SPELL_ABILITY_ID    = 0
        private static constant integer SPELL_EVENT_TYPE    = 0

        private HandlerList spellHandler
        private boolean channelEnded

        private static HandlerList array handlerList
        private static key table

        private method onSpellStart takes nothing returns thistype
            local integer casterId
            local thistype prevNode = udg_SPELL__Index
            local HandlerList list = handlerList[Spell[GetEventSpellAbilityId()]*5 + eventIndex[GetEventSpellEventType()]]
            call list.nextNode()

            call SaveEventParams(prevNode)
            call InitEventParams(/*
                */GetEventSpellAbilityId(), /*
                */GetEventSpellEventType(), /*
                */GetEventSpellOrderType(), /*
                */GetEventSpellLevel(), /*
                */GetEventSpellPlayer(), /*
                */GetEventSpellCaster(), /*
                */GetEventSpellTargetX(), /*
                */GetEventSpellTargetY(), /*
                */staticLocation, /*
                */GetEventSpellTargetUnit(), /*
                */GetEventSpellTargetItem(), /*
                */GetEventSpellTargetDest())

            set udg_SPELL__Index = this

            call EvaluateHandler(list.current.onStartTrigger)

            set this = udg_SPELL__Index
            set udg_SPELL__Index = prevNode
            if this > 0 then
                set this.spellHandler = list.current
                call SaveEventParams(this)
            endif

            if list.current.next == list then
                call list.nextNode()
            endif

            if GetEventSpellEventType() == EVENT_SPELL_CHANNEL then
                set Table(table)[GetHandleId(GetEventSpellCaster())] = this
                set this.channelEnded = false

            elseif GetEventSpellEventType() == EVENT_SPELL_ENDCAST then
                set casterId = GetHandleId(GetEventSpellCaster())
                set prevNode = Table(table)[casterId]
                call Table(table).remove(casterId)

                if prevNode != 0 then
                    set prevNode.channelEnded = true

                    call LoadEventParams(prevNode)

                    return 0
                endif
            endif

            call LoadEventParams(prevNode)

            return this
        endmethod

        private method onSpellPeriodic takes nothing returns boolean
            local boolean continue
            local boolean prevExitFlag = udg_SPELL__ExitPeriodic
            local thistype prevNode = udg_SPELL__Index

            call SaveEventParams(prevNode)
            call LoadEventParams(this)

            set udg_SPELL__ExitPeriodic = false
            set udg_SPELL__Index = this

            call EvaluateHandler(this.spellHandler.onPeriodTrigger)

            set continue = not udg_SPELL__ExitPeriodic
            set udg_SPELL__ExitPeriodic = prevExitFlag
            set udg_SPELL__Index = prevNode

            call LoadEventParams(prevNode)

            if not continue then
                if nodeEventType[this] != EVENT_SPELL_CHANNEL then
                    return false
                endif
                call IssueImmediateOrderById(nodeTriggerUnit[this], STOP_ORDER_ID)
            endif
            return not this.channelEnded
        endmethod

        private method onSpellEnd takes nothing returns nothing
            local thistype prevNode = udg_SPELL__Index

            call SaveEventParams(prevNode)
            call LoadEventParams(this)

            set udg_SPELL__Index = this

            call EvaluateHandler(this.spellHandler.onEndTrigger)

            set udg_SPELL__Index = prevNode

            set nodeTargetPoint[this]   = null
            set nodeTargetUnit[this]    = null
            set nodeTargetItem[this]    = null
            set nodeTargetDest[this]    = null
            set nodeTriggerUnit[this]   = null
            set this.spellHandler = 0

            call LoadEventParams(prevNode)
        endmethod

        implement SpellEvent

        private static method registerSpell takes nothing returns nothing
            local Spell spell = Spell[udg_SPELL__Ability]
            local integer eventType = udg_SPELL__EventType
            local integer eventId = 0x10
            local integer index
            local HandlerList node

            if eventType == EVENT_SPELL_CHANNEL then
                set eventType = eventType + EVENT_SPELL_ENDCAST
            endif

            loop
                exitwhen eventId == 0
                if eventType >= eventId then
                    set eventType = eventType - eventId
                    set index = spell*5 + eventIndex[eventId]
                    if handlerList[index] == 0 then
                        set handlerList[index] = HandlerList.create()
                    endif
                    set node = handlerList[index].pushBack(udg_SPELL__OnStartTrigger, udg_SPELL__OnPeriodTrigger, udg_SPELL__OnEndTrigger)
                    set node.enemyFlag          = udg_SPELL__EnemyFilterFlag
                    set node.allyFlag           = udg_SPELL__AllyFilterFlag
                    set node.deadFlag           = udg_SPELL__DeadFilterFlag
                    set node.livingFlag         = udg_SPELL__LivingFilterFlag
                    set node.magicImmuneFlag    = udg_SPELL__MagicImmuneFilterFlag
                    set node.mechanicalFlag     = udg_SPELL__MechanicalFilterFlag
                    set node.structureFlag      = udg_SPELL__StructureFilterFlag
                    set node.flyingFlag         = udg_SPELL__FlyingFilterFlag
                    set node.heroFlag           = udg_SPELL__HeroFilterFlag
                    set node.nonHeroFlag        = udg_SPELL__NonHeroFilterFlag

                    call registerSpellEvent(udg_SPELL__Ability, eventId)
                endif
                set eventId = eventId/2
            endloop
        endmethod

        private static method onSpellInvoke takes nothing returns nothing
            local widget target

            if udg_SPELL__OrderType == udg_SPELL__ORDER_NO_TARGET then
                call SpellInvokeNoTargetEvent(udg_SPELL__Ability, udg_SPELL__EventType, GetLevel(), udg_SPELL__TriggerUnit)

            elseif udg_SPELL__OrderType == udg_SPELL__ORDER_POINT_TARGET then
                call SpellInvokePointTargetEvent(udg_SPELL__Ability, udg_SPELL__EventType, GetLevel(), udg_SPELL__TriggerUnit, GetLocationX(udg_SPELL__TargetPoint), GetLocationY(udg_SPELL__TargetPoint))

            elseif udg_SPELL__OrderType == udg_SPELL__ORDER_SINGLE_TARGET then
                set target = GetTarget()

                if target != null then
                    call SpellInvokeSingleTargetEvent(udg_SPELL__Ability, udg_SPELL__EventType, GetLevel(), udg_SPELL__TriggerUnit, target)
                    set target = null
                endif
            endif
        endmethod

        private static method onOverrideParams takes nothing returns nothing
            local widget target

            if udg_SPELL__OrderType == udg_SPELL__ORDER_NO_TARGET then
                call SpellOverrideNoTargetParams(GetLevel(), udg_SPELL__TriggerUnit)

            elseif udg_SPELL__OrderType == udg_SPELL__ORDER_POINT_TARGET then
                call SpellOverridePointTargetParams(GetLevel(), udg_SPELL__TriggerUnit, GetLocationX(udg_SPELL__TargetPoint), GetLocationY(udg_SPELL__TargetPoint))

            elseif udg_SPELL__OrderType == udg_SPELL__ORDER_SINGLE_TARGET then
                set target = GetTarget()

                if target != null then
                    call SpellOverrideSingleTargetParams(GetLevel(), udg_SPELL__TriggerUnit, target)
                    set target = null
                endif
            endif
        endmethod

        private static method onEnumTargets takes nothing returns nothing
            local HandlerList node = thistype(udg_SPELL__Index).spellHandler
            local integer count = 0
            local integer currentCount
            local unit u
            if node.structureFlag then
                call GroupEnumUnitsInRangeOfLoc(enumGroup, udg_SPELL__TargetPoint, udg_SPELL__EnumRange + 197.00, null)
            else
                call GroupEnumUnitsInRangeOfLoc(enumGroup, udg_SPELL__TargetPoint, udg_SPELL__EnumRange + 64.00, null)
            endif
            loop
                set u = FirstOfGroup(enumGroup)
                exitwhen u == null
                call GroupRemoveUnit(enumGroup, u)
                if (ResolveFilterFlag(IsUnitEnemy(u, udg_SPELL__TriggerPlayer), node.enemyFlag, node.allyFlag)) and/*
                */ (ResolveFilterFlag(IsUnitType(u, UNIT_TYPE_HERO), node.heroFlag, node.nonHeroFlag)) and/*
                */ (ResolveFilterFlag(UnitAlive(u), node.livingFlag, node.deadFlag)) and/*
                */ (node.magicImmuneFlag or not IsUnitType(u, UNIT_TYPE_MAGIC_IMMUNE)) and/*
                */ (node.mechanicalFlag or not IsUnitType(u, UNIT_TYPE_MECHANICAL)) and/*
                */ (node.structureFlag or not IsUnitType(u, UNIT_TYPE_STRUCTURE)) and/*
                */ (node.flyingFlag or not IsUnitType(u, UNIT_TYPE_FLYING)) then
                    set count = count + 1
                    set udg_SPELL__EnumedTargets[count] = u
                    if count == udg_SPELL__EnumCount then
                        exitwhen true
                    endif
                endif
            endloop
            set udg_SPELL__EnumCount = count
            if count < prevEnumCount then
                /*
                *   Free unused references
                */
                loop
                    exitwhen count == prevEnumCount
                    set count = count + 1
                    set udg_SPELL__EnumedTargets[count] = null
                endloop
            endif
            set prevEnumCount = udg_SPELL__EnumCount
        endmethod

        private static method onSpellEvent takes nothing returns nothing
            local thistype prevNode         = udg_SPELL__Index
            local integer abilityId         = udg_SPELL__Ability
            local integer eventType         = udg_SPELL__EventType
            local integer orderType         = udg_SPELL__OrderType
            local integer level             = udg_SPELL__Level
            local player triggerPlayer      = udg_SPELL__TriggerPlayer
            local unit triggerUnit          = udg_SPELL__TriggerUnit
            local location targetPoint      = udg_SPELL__TargetPoint
            local unit targetUnit           = udg_SPELL__TargetUnit
            local item targetItem           = udg_SPELL__TargetItem
            local destructable targetDest   = udg_SPELL__TargetDest
            local real targetX              = GetLocationX(udg_SPELL__TargetPoint)
            local real targetY              = GetLocationY(udg_SPELL__TargetPoint)

            call InitEventParams(/*
                */GetEventSpellAbilityId(), /*
                */GetEventSpellEventType(), /*
                */GetEventSpellOrderType(), /*
                */GetEventSpellLevel(), /*
                */GetEventSpellPlayer(), /*
                */GetEventSpellCaster(), /*
                */GetEventSpellTargetX(), /*
                */GetEventSpellTargetY(), /*
                */staticLocation, /*
                */GetEventSpellTargetUnit(), /*
                */GetEventSpellTargetItem(), /*
                */GetEventSpellTargetDest())

            set udg_SPELL__Index     = 0

            set udg_SPELL__Event    = 0.00
            set udg_SPELL__Event    = I2R(eventIndex[GetEventSpellEventType()])
            set udg_SPELL__Event    = 0.00

            set udg_SPELL__Index     = prevNode

            call InitEventParams(/*
                */abilityId, /*
                */eventType, /*
                */orderType, /*
                */level, /*
                */triggerPlayer, /*
                */triggerUnit, /*
                */targetX, /*
                */targetY, /*
                */targetPoint, /*
                */targetUnit, /*
                */targetItem, /*
                */targetDest)

            set triggerUnit                 = null
            set targetPoint                 = null
            set targetUnit                  = null
            set targetItem                  = null
            set targetDest                  = null
        endmethod

        implement SpellEventGeneric

        /*=================================================================================*/

        static method initTriggers takes nothing returns nothing
            set udg_SPELL__RegisterHandler = CreateTrigger()
            call TriggerAddAction(udg_SPELL__RegisterHandler, function thistype.registerSpell)

            set udg_SPELL__InvokeEvent = CreateTrigger()
            call TriggerAddAction(udg_SPELL__InvokeEvent, function thistype.onSpellInvoke)

            set udg_SPELL__OverrideParams = CreateTrigger()
            call TriggerAddAction(udg_SPELL__OverrideParams, function thistype.onOverrideParams)

            set udg_SPELL__EnumerateTargetsInRange = CreateTrigger()
            call TriggerAddAction(udg_SPELL__EnumerateTargetsInRange, function thistype.onEnumTargets)
        endmethod

        static method initConfiguration takes nothing returns nothing
            set SPELL_PERIOD                        = 1.00/udg_SPELL__FRAME_RATE
            set udg_SPELL__PERIOD                   = SPELL_PERIOD

            set udg_SPELL__EVENT_CAST               = EVENT_SPELL_CAST
            set udg_SPELL__EVENT_CHANNEL            = EVENT_SPELL_CHANNEL
            set udg_SPELL__EVENT_EFFECT             = EVENT_SPELL_EFFECT
            set udg_SPELL__EVENT_ENDCAST            = EVENT_SPELL_EFFECT
            set udg_SPELL__EVENT_FINISH             = EVENT_SPELL_FINISH

            set udg_SPELL__ORDER_NO_TARGET          = SPELL_ORDER_TYPE_NO_TARGET
            set udg_SPELL__ORDER_POINT_TARGET       = SPELL_ORDER_TYPE_POINT_TARGET
            set udg_SPELL__ORDER_SINGLE_TARGET      = SPELL_ORDER_TYPE_SINGLE_TARGET

            set eventIndex[EVENT_SPELL_CAST]        = 1
            set eventIndex[EVENT_SPELL_CHANNEL]     = 2
            set eventIndex[EVENT_SPELL_EFFECT]      = 3
            set eventIndex[EVENT_SPELL_ENDCAST]     = 4
            set eventIndex[EVENT_SPELL_FINISH]      = 5
        endmethod

    endstruct

    static if DEBUG_MODE and LIBRARY_ErrorMessage then
        private function OnRemoveLocation takes location whichLocation returns nothing
            call ThrowError(whichLocation == staticLocation, SCOPE_PREFIX, "native RemoveLocation()", "", 0, "Destroyed a system-generated handle")
        endfunction

        hook RemoveLocation OnRemoveLocation
    endif

    public function Initialize takes nothing returns nothing
        call SpellEventGUI.initTriggers()
        call SpellEventGUI.initConfiguration()
        set udg_SPELL__InitializationEvent = 1.00
        set udg_SPELL__InitializationEvent = 0.00
    endfunction


endlibrary