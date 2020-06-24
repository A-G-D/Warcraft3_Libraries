library Event /*


    */uses /*

    */optional Alloc        /*
    */optional Table        /*
    */optional ErrorMessage /*

    *///! novjass

    /*
    *   Author: AGD
    *
    *       A short and concise library for custom event-handlers creation.
    */
    |-----|
    | API |
    |-----|

        struct Event

            readonly static Event triggerInstance   // The current executing Event

            readonly trigger trigger                // The trigger handle of this Event
            readonly integer handlerCount           // The number of handler functions registered
            boolean enabled

            static method create takes nothing returns Event
            method destroy takes nothing returns nothing

            method register takes code handler returns this
            method unregister takes code handler returns this
            method clear takes nothing returns this

            method execute takes nothing returns boolean/*
                - Returns <this.enabled and TriggerEvaluate(this.trigger)>
            

    *///! endnovjass

    static if DEBUG_MODE then
        private function AssertError takes boolean condition, string methodName, string structName, integer node, string message returns nothing
            static if LIBRARY_ErrorMessage then
                call ThrowError(condition, SCOPE_PREFIX, methodName, structName, node, message)
            endif
        endfunction
    endif

    private module HashtableModule
        static if LIBRARY_Table then
            readonly static TableArray table
            static method save takes integer index, integer key, integer value returns nothing
                set table[index][key] = value
            endmethod
            static method load takes integer index, integer key returns integer
                return table[index][key]
            endmethod
            static method remove takes integer index, integer key returns nothing
                call table[index].remove(key)
            endmethod
            static method saveTriggerCondition takes integer index, integer key, triggercondition value returns nothing
                set table[index].triggercondition[key] = value
            endmethod
            static method loadTriggerCondition takes integer index, integer key returns triggercondition
                return table[index].triggercondition[key]
            endmethod
            static method hasHandle takes integer index, integer key returns boolean
                return table[index].handle.has(key)
            endmethod
            static method removeHandle takes integer index, integer key returns nothing
                call table[index].handle.remove(key)
            endmethod
            static method flush takes integer index returns nothing
                call table[index].flush()
            endmethod
            private static method onInit takes nothing returns nothing
                set table = TableArray[JASS_MAX_ARRAY_SIZE]
            endmethod
        else
            readonly static hashtable table = InitHashtable()
            static method save takes integer index, integer key, integer value returns nothing
                call SaveInteger(table, index, key, value)
            endmethod
            static method load takes integer index, integer key returns integer
                return LoadInteger(table, index, key)
            endmethod
            static method remove takes integer index, integer key returns nothing
                call RemoveSavedInteger(table, index, key)
            endmethod
            static method saveTriggerCondition takes integer index, integer key, triggercondition value returns nothing
                call SaveTriggerConditionHandle(table, index, key, value)
            endmethod
            static method loadTriggerCondition takes integer index, integer key returns triggercondition
                return LoadTriggerConditionHandle(table, index, key)
            endmethod
            static method hasHandle takes integer index, integer key returns boolean
                return HaveSavedHandle(table, index, key)
            endmethod
            static method removeHandle takes integer index, integer key returns nothing
                call RemoveSavedHandle(table, index, key)
            endmethod
            static method flush takes integer index returns nothing
                call FlushChildHashtable(table, index)
            endmethod
        endif
    endmodule
    private struct Hashtable extends array
        implement HashtableModule
    endstruct

    private struct Node extends array
        static if LIBRARY_Alloc then
            implement optional Alloc
        else
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
        endif
    endstruct

    struct Event extends array

        readonly trigger trigger
        readonly integer handlerCount

        static method operator triggerInstance takes nothing returns thistype
            return Hashtable.load(0, GetHandleId(GetTriggeringTrigger()))
        endmethod

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

        static method create takes nothing returns thistype
            return Node.allocate()
        endmethod
        method destroy takes nothing returns nothing
            if this.handlerCount > 0 then
                call Hashtable.remove(0, GetHandleId(this.trigger))
                call DestroyTrigger(this.trigger)
                set this.trigger = null
                set this.handlerCount = 0
            endif
            call Node(this).deallocate()
        endmethod

        method register takes code handler returns thistype
            local boolexpr handlerExpr = Filter(handler)
            debug call AssertError(Hashtable.hasHandle(this, GetHandleId(handlerExpr)), "register()", "thistype", this, "Code is already registered")
            if this.handlerCount == 0 then
                set this.trigger = CreateTrigger()
                call Hashtable.save(0, GetHandleId(this.trigger), this)
            endif
            set this.handlerCount = this.handlerCount + 1
            call Hashtable.saveTriggerCondition(this, GetHandleId(handlerExpr), TriggerAddCondition(this.trigger, handlerExpr))
            set handlerExpr = null
            return this
        endmethod
        method unregister takes code handler returns thistype
            local integer handlerId = GetHandleId(Filter(handler))
            debug call AssertError(not Hashtable.hasHandle(this, handlerId), "unregister()", "thistype", this, "Code is not registered")
            set this.handlerCount = this.handlerCount - 1
            if this.handlerCount == 0 then
                call Hashtable.remove(0, GetHandleId(this.trigger))
                call DestroyTrigger(this.trigger)
                set this.trigger = null
            else
                call TriggerRemoveCondition(this.trigger, Hashtable.loadTriggerCondition(this, handlerId))
            endif
            call Hashtable.removeHandle(this, handlerId)
            return this
        endmethod

        method clear takes nothing returns thistype
            if this.handlerCount > 0 then
                call Hashtable.flush(this)
                call DestroyTrigger(this.trigger)
                set this.trigger = null
                set this.handlerCount = 0
            endif
            return this
        endmethod

        method execute takes nothing returns boolean
            return this.enabled and TriggerEvaluate(this.trigger)
        endmethod

    endstruct


endlibrary
