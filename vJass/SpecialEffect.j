library SpecialEffect /* v1.2.1 by AGD | https://www.hiveworkshop.com/threads/specialeffect.325954/


    */uses /*

    */LinkedList            /*  https://www.hiveworkshop.com/threads/325635/ | Should use atleast v1.3.0

    */optional Table        /*  https://www.hiveworkshop.com/threads/188084/
    */optional Alloc        /*  https://www.hiveworkshop.com/threads/324937/
    */optional ErrorMessage /*  https://github.com/nestharus/JASS/blob/master/jass/Systems/ErrorMessage/main.j


    *///! novjass

    |-----|
    | API |
    |-----|
    /*

      */struct SpecialEffect extends array/*

          */readonly real x     /*
          */readonly real y     /*
          */readonly real z     /*  Absolute height
          */readonly real height/*  Height relative to the ground
          */readonly real yaw   /*
          */readonly real pitch /*
          */readonly real roll  /*

          */method currentHandle            takes nothing                               returns effect/*
                - Current <effect> handle pointed by the iterator
          */method resetIterator            takes nothing                               returns nothing/*
          */method moveIterator             takes nothing                               returns boolean/*
                - Use these iterator methods together with 'currentHandle()' if you need to traverse
                  each <effect> handle
                - moveIterator() returns true when it moves past the last element of the list
                  (resetIterator() is automatically called when this happens)
                - Sample Usage:
                    local SpecialEffect sfx = this.specialEffect
                    loop
                        exitwhen sfx.moveIterator()
                        call BlzSetSpecialEffectAlpha(sfx.currentHandle(), 0xAA)
                    endloop

          */method killModel                takes string model, real deathTime          returns nothing/*
                - Kills a specific model, playing its death animation
          */method kill                     takes real deathTime, boolean destroyAfter  returns nothing/*
                - Kills all models, playing their death animation and destroys this SpecialEffect
                  instance if <destroyAfter> is true

          */method addModel                 takes string model                          returns effect/*
                - You can't add an already attached model
          */method removeModel              takes string model                          returns nothing/*
          */method clearModels              takes nothing                               returns nothing/*
                - removeModel() and clearModels() instantly vanishes the attached models without
                  playing their death animation

          */method getHandle                takes string model                          returns effect/*
                - For random access (Uses linear search actually)

          */method move                     takes real x, real y, real z                returns nothing/*
          */method moveRelative             takes real x, real y, real height           returns nothing/*
                - Keeps the offset between the actual position of the <effect> handles and the
                  origin coordinates of this SpecialEffect instance
          */method setPosition              takes real x, real y, real z                returns nothing/*
          */method setPositionRelative      takes real x, real y, real height           returns nothing/*
                - Sets the actual position of all <effect> handles
          */method setOrientation           takes real yaw, real pitch, real roll       returns nothing/*

          */method setVisibility            takes player whichPlayer, boolean visible   returns nothing/*
                - Toggles the visibility flag locally for a player

          */static method create            takes real x, real y, real z                returns SpecialEffect/*
          */static method createRelative    takes real x, real y, real height           returns SpecialEffect/*
                - Constructors
          */method destroy                  takes nothing                               returns nothing/*
                - Calls clearModels() and destroys this SpecialEffect instance
                - Dying instances are also immediately vanished by this method


    *///! endnovjass

    globals
        /*
        *   Special effects that need to be instantly vanished are moved to this coordinates before destroyed
        */
        private constant real HIDDEN_PLACE_X        = 0.00
        private constant real HIDDEN_PLACE_Y        = 10000.00

        private location loc = Location(0.00, 0.00)
    endglobals

    /*========================================== SYSTEM CODE ==========================================*/

    static if DEBUG_MODE then
        private function AssertError takes boolean condition, string methodName, string structName, integer node, string message returns nothing
            static if LIBRARY_ErrorMessage then
                call ThrowError(condition, SCOPE_PREFIX, methodName, structName, node, message)
            else
                if condition then
                    call BJDebugMsg("[Library: " + SCOPE_PREFIX + "] [Struct: " + structName + "] [Method: " + methodName + "] [Instance: " + I2S(node) + "] : |cffff0000" + message + "|r")
                endif
            endif
        endfunction
    endif

    public function GetTerrainZ takes real x, real y returns real
        call MoveLocation(loc, x, y)
        return GetLocationZ(loc)
    endfunction

    /*
    *   Allocator for the whole lib
    */
    private struct Node extends array
        static if LIBRARY_Alloc then
            implement optional Alloc
        else
            /*
            *   Algorithm by MyPad
            */
            private static thistype array stack
            debug method operator allocated takes nothing returns boolean
                debug return this > 0 and stack[this] == 0
            debug endmethod
            static method allocate takes nothing returns thistype
                local thistype node = stack[0]
                if stack[node] == 0 then
                    debug call AssertError(node == JASS_MAX_ARRAY_SIZE - 2, "allocate()", "thistype", node, "Overflow")
                    set node = node + 1
                    set stack[0] = node
                else
                    set stack[0] = stack[node]
                    set stack[node] = 0
                endif
                return node
            endmethod
            method deallocate takes nothing returns nothing
                debug call AssertError(not this.allocated, "deallocate()", "thistype", this, "Double-free")
                set stack[this] = stack[0]
                set stack[0] = this
            endmethod
        endif
    endstruct

    private function VanishEffect takes effect e returns nothing
        call BlzSetSpecialEffectX(e, HIDDEN_PLACE_X)
        call BlzSetSpecialEffectY(e, HIDDEN_PLACE_Y)
        call DestroyEffect(e)
    endfunction

    /*
    *   List of <effect>s
    */
    private struct EffectHandle extends array
        readonly effect effect
        SpecialEffect parent
        string model
        real dx
        real dy
        real dz

        private static method onInsert takes thistype node returns nothing
            local SpecialEffect parent = node.parent
            set node.effect = AddSpecialEffect(node.model, HIDDEN_PLACE_X, HIDDEN_PLACE_Y)
            call BlzSetSpecialEffectPosition(node.effect, parent.x, parent.y, parent.z)
            call BlzSetSpecialEffectOrientation(node.effect, parent.yaw, parent.pitch, parent.roll)
        endmethod

        private static method onRemove takes thistype node returns nothing
            call VanishEffect(node.effect)
            set node.effect = null
            set node.model = null
            call Node(node).deallocate()
        endmethod

        private static method allocate takes nothing returns thistype
            return Node.allocate()
        endmethod
        private method deallocate takes nothing returns nothing
            call Node(this).deallocate()
        endmethod

        implement InstantiatedList
        implement LinkedListEx

        method getIndex takes string model returns thistype
            local thistype node = this.next
            loop
                exitwhen node == this or node.model == model
                set node = node.next
            endloop
            return node
        endmethod
    endstruct

    private struct DelayedCleanupList extends array
        EffectHandle effectHandle

        private static method onRemove takes thistype node returns nothing
            if EffectHandle.isLinked(node.effectHandle) then
                call EffectHandle.remove(node.effectHandle)
            endif
            call Node(node).deallocate()
        endmethod

        implement List
    endstruct

    /*
    *   Effect is a cluster of <effect>s that can easily be controlled as a single object
    */
    struct SpecialEffect extends array
        readonly real x
        readonly real y
        readonly real z
        readonly real height
        readonly real yaw
        readonly real pitch
        readonly real roll

        private boolean hidden
        private boolean wantDestroy
        private EffectHandle current
        private EffectHandle killed
        private thistype instance

        static if LIBRARY_Table then
            private static key table
        else
            private static hashtable table = InitHashtable()
        endif

        private method startTimer takes real timeout, code callback returns nothing
            local timer t = CreateTimer()

            static if LIBRARY_Table then
                set Table(table)[GetHandleId(t)] = this
            else
                call SaveInteger(table, 0, GetHandleId(t), this)
            endif

            call TimerStart(t, timeout, false, callback)
            set t = null
        endmethod

        private static method releaseTimer takes nothing returns thistype
            local timer t = GetExpiredTimer()
            local integer id = GetHandleId(t)

            static if LIBRARY_Table then
                local thistype node = Table(table)[id]
                call Table(table).remove(id)
            else
                local thistype node = LoadInteger(table, 0, id)
                call RemoveSavedInteger(table, 0, id)
            endif

            call DestroyTimer(t)
            set t = null

            return node
        endmethod

        private method operator handle takes nothing returns EffectHandle
            return this
        endmethod

        method currentHandle takes nothing returns effect
            return this.current.effect
        endmethod

        method resetIterator takes nothing returns nothing
            set this.current = this.handle
        endmethod
        method moveIterator takes nothing returns boolean
            set this.current = this.current.next
            return this.current == this.handle
        endmethod

        private static method onSetOrientation takes EffectHandle list, real yaw, real pitch, real roll returns nothing
            local EffectHandle node = list.next
            loop
                exitwhen node == list
                call BlzSetSpecialEffectOrientation(node.effect, yaw, pitch, roll)
                set node = node.next
            endloop
        endmethod
        private static method onSetPosition takes EffectHandle list, real x, real y, real z returns nothing
            local EffectHandle node = list.next
            loop
                exitwhen node == list
                call BlzSetSpecialEffectPosition(node.effect, x, y, z)
                set node = node.next
            endloop
        endmethod
        private static method onMove takes EffectHandle list, real dx, real dy, real dz returns nothing
            local EffectHandle node = list.next
            loop
                exitwhen node == list
                call BlzSetSpecialEffectPosition(node.effect, BlzGetLocalSpecialEffectX(node.effect) + dx, BlzGetLocalSpecialEffectY(node.effect) + dy, BlzGetLocalSpecialEffectZ(node.effect) + dz)
                set node = node.next
            endloop
        endmethod
        private method onSetVisibility takes EffectHandle list, player whichPlayer, boolean visible returns nothing
            local EffectHandle node = list.next
            loop
                exitwhen node == list
                if visible then
                    call BlzSetSpecialEffectPosition(node.effect, this.x + node.dx, this.y + node.dy, this.z + node.dz)
                else
                    set node.dx = BlzGetLocalSpecialEffectX(node.effect) - this.x
                    set node.dy = BlzGetLocalSpecialEffectY(node.effect) - this.y
                    set node.dz = BlzGetLocalSpecialEffectZ(node.effect) - this.z
                    call BlzSetSpecialEffectX(node.effect, HIDDEN_PLACE_X)
                    call BlzSetSpecialEffectY(node.effect, HIDDEN_PLACE_Y)
                endif
                set node = node.next
            endloop
        endmethod

        private method updatePosition takes real x, real y, real z, real height returns nothing
            set this.x = x
            set this.y = y
            set this.z = z
            set this.height = height
        endmethod

        method setOrientation takes real yaw, real pitch, real roll returns nothing
            debug call AssertError(not Node(this).allocated, "setOrientation()", "thistype", this, "Invalid node")
            call onSetOrientation(this.handle, yaw, pitch, roll)
            call onSetOrientation(this.killed, yaw, pitch, roll)
            set this.yaw = yaw
            set this.pitch = pitch
            set this.roll = roll
        endmethod

        private method setPositionEx takes real x, real y, real z, real height returns nothing
            call onSetPosition(this.handle, x, y, z)
            call onSetPosition(this.killed, x, y, z)
            call this.updatePosition(x, y, z, height)
        endmethod
        method setPosition takes real x, real y, real z returns nothing
            debug call AssertError(not Node(this).allocated, "setPosition()", "thistype", this, "Invalid node")
            call this.setPositionEx(x, y, z, z - GetTerrainZ(x, y))
        endmethod
        method setPositionRelative takes real x, real y, real height returns nothing
            debug call AssertError(not Node(this).allocated, "setPositionRelative()", "thistype", this, "Invalid node")
            call this.setPositionEx(x, y, height + GetTerrainZ(x, y), height)
        endmethod

        private method moveEx takes real x, real y, real z, real height returns nothing
            call onMove(this.handle, x - this.x, y - this.y, z - this.z)
            call onMove(this.killed, x - this.x, y - this.y, z - this.z)
            call this.updatePosition(x, y, z, height)
        endmethod
        method move takes real x, real y, real z returns nothing
            debug call AssertError(not Node(this).allocated, "move()", "thistype", this, "Invalid node")
            call this.moveEx(x, y, z, z - GetTerrainZ(x, y))
        endmethod
        method moveRelative takes real x, real y, real height returns nothing
            debug call AssertError(not Node(this).allocated, "moveRelative()", "thistype", this, "Invalid node")
            call this.moveEx(x, y, height + GetTerrainZ(x, y), height)
        endmethod

        method setVisibility takes player whichPlayer, boolean visible returns nothing
            debug call AssertError(not Node(this).allocated, "setVisibility()", "thistype", this, "Invalid node")
            if whichPlayer == GetLocalPlayer() and this.hidden == visible then
                call this.onSetVisibility(this.handle, whichPlayer, visible)
                call this.onSetVisibility(this.killed, whichPlayer, visible)
                set this.hidden = not visible
            endif
        endmethod

        method getHandle takes string model returns effect
            debug call AssertError(not Node(this).allocated, "getHandle()", "thistype", this, "Invalid node")
            return this.handle.getIndex(model).effect
        endmethod

        method addModel takes string model returns effect
            local EffectHandle node
            debug call AssertError(not Node(this).allocated, "addModel()", "thistype", this, "Invalid node")
            if this.getHandle(model) == null then
                set node = Node.allocate()
                set node.parent = this.handle
                set node.model = model
                call this.handle.pushBack(node)
                return node.effect
            endif
            return null
        endmethod
        method removeModel takes string model returns nothing
            local EffectHandle node = this.handle.getIndex(model)
            debug call AssertError(not Node(this).allocated, "removeModel()", "thistype", this, "Invalid node")
            if node != this.handle then
                call EffectHandle.remove(node)
            endif
        endmethod
        method clearModels takes nothing returns nothing
            debug call AssertError(not Node(this).allocated, "clearModels()", "thistype", this, "Invalid node")
            call this.killed.flush()
            call this.handle.flush()
        endmethod

        private static method createEx takes real x, real y, real z, real height returns thistype
            local thistype node     = EffectHandle.create()
            set node.killed         = EffectHandle.create()
            set node.yaw            = 0
            set node.pitch          = 0
            set node.roll           = 0
            set node.hidden         = false
            call node.updatePosition(x, y, z, height)
            call node.resetIterator()
            return node
        endmethod

        static method create takes real x, real y, real z returns thistype
            return createEx(x, y, z, z - GetTerrainZ(x, y))
        endmethod
        static method createRelative takes real x, real y, real height returns thistype
            return createEx(x, y, height + GetTerrainZ(x, y), height)
        endmethod

        method destroy takes nothing returns nothing
            debug call AssertError(not Node(this).allocated, "destroy()", "thistype", this, "Invalid node")
            call this.killed.destroy()
            call this.handle.destroy()
        endmethod

        private static method onExpireKill takes nothing returns nothing
            local thistype node = releaseTimer()
            if EffectHandle.isLinked(node.instance) then
                call EffectHandle.remove(node.instance)
            endif
            call Node(node).deallocate()
        endmethod
        private static method onExpireClear takes nothing returns nothing
            local DelayedCleanupList list = releaseTimer()
            local thistype node = thistype(list).instance
            set thistype(list).instance = 0
            if node.wantDestroy then
                set node.wantDestroy = false
                call node.destroy()
            endif
            call list.flush()
            call Node(list).deallocate()
        endmethod

        method killModel takes string model, real deathTime returns nothing
            local thistype node
            local thistype instance = this.handle.getIndex(model)
            debug call AssertError(not Node(this).allocated, "killModel()", "thistype", this, "Invalid node")
            if instance != this.handle then
                set node = Node.allocate()
                set node.instance = instance
                if instance.handle == this.current then
                    set this.current = this.current.next
                endif
                call EffectHandle.move(this.killed.prev, instance.handle)
                call BlzPlaySpecialEffect(instance.handle.effect, ANIM_TYPE_DEATH)
                call node.startTimer(deathTime, function thistype.onExpireKill)
            endif
        endmethod

        method kill takes real deathTime, boolean wantDestroy returns nothing
            local DelayedCleanupList list
            local DelayedCleanupList temp
            local thistype node
            local thistype next

            debug call AssertError(not Node(this).allocated, "kill()", "thistype", this, "Invalid node")

            if not this.handle.empty then
                set list = Node.allocate()
                set thistype(list).instance = this
                call DelayedCleanupList.makeHead(list)

                set node = this.handle.next
                loop
                    exitwhen node == this.handle
                    set next = node.handle.next
                    set temp = Node.allocate()
                    set temp.effectHandle = node
                    call list.pushBack(temp)
                    call EffectHandle.move(this.killed.prev, node)
                    call BlzPlaySpecialEffect(node.handle.effect, ANIM_TYPE_DEATH)
                    set node = next
                endloop

                call this.resetIterator()
                call thistype(list).startTimer(deathTime, function thistype.onExpireClear)
            endif
        endmethod
    endstruct


endlibrary