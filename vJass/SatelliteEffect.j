library SatelliteEffect /* v1.0.0 by AGD |  | Patches 1.31+


    */uses /*

    */SpecialEffect         /*  https://www.hiveworkshop.com/threads/325954/
    */LinkedList            /*  https://www.hiveworkshop.com/threads/325635/

    */optional Alloc        /*  https://www.hiveworkshop.com/threads/324937/
    */optional ErrorMessage /*  https://github.com/nestharus/JASS/blob/master/jass/Systems/ErrorMessage/main.j


    *///! novjass

    |-------------|
    | Description |
    |-------------|
    /*
        This library allows you to dock special effects unto other special effects (locking its
        relative position to automatically update based on its parent's orientation).

        'SatelliteEffect' represents a single satellite object. Each satellite is a dockable object
        in itself so you can have a satellite docking unto a satellite, which is also docking
        unto another satellite, and so on. There is no limit to the level of this dock-chaining,
        and there is also no limit to how many satellites a dock can have. However a satellite
        can only be docked into one parent satellite.

        A 'SatelliteEffect' can be created by taking a 'SpecialEffect' object using the create
        method. When destroying a 'SatelliteEffect' object, its base 'SpecialEffect' object is NOT
        automatically destroyed alongside it.

    */
    |-----|
    | API |
    |-----|
    /*
      */struct SatelliteEffect extends array/*

          */static boolean propagateCommand /* Initially <true>. Its purpose is documented in the methods below.

          */readonly SpecialEffect effect   /*
          */readonly SatelliteEffect parent /*  Instance where this satellite is docked

          */readonly real dx                /*  x-offset from parent
          */readonly real dy                /*  y-offset from parent
          */readonly real dz                /*  z-offset from parent
          */readonly real x                 /*
          */readonly real y                 /*
          */readonly real z                 /*
          */readonly real height            /*
          */readonly real yaw               /*
          */readonly real pitch             /*
          */readonly real roll              /*

          */method currentSatellite takes nothing                               returns SatelliteEffect/*
                - Current <SatelliteEffect> pointed by the iterator
          */method resetIterator    takes nothing                               returns nothing/*
          */method moveIterator     takes nothing                               returns boolean/*

          */method dock             takes SatelliteEffect parent                returns nothing/*
          */method undock           takes nothing                               returns nothing/*

          */method addSatellite     takes SatelliteEffect satellite             returns nothing/*
          */method removeSatellite  takes SatelliteEffect satellite             returns nothing/*
          */method clearSatellites  takes nothing                               returns nothing/*

          */method move             takes real x, real y, real z                returns nothing/*
          */method moveRelative     takes real x, real y, real height           returns nothing/*
                - Same to move() but uses height relative to ground as input

          */method orient           takes real yaw, real pitch, real roll       returns nothing/*

          */static method create    takes SpecialEffect sfx                     returns SatelliteEffect/*
          */method destroy          takes nothing                               returns nothing/*


    *///! endnovjass

    /*====================================== SYSTEM CODE ======================================*/

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

    /*=========================================================================================*/

    private struct Node extends array
        static if LIBRARY_Alloc then
            implement optional Alloc
        else
            private static thistype array stack
            debug method operator allocated takes nothing returns boolean
                debug return this > 0 and stack[this] == 0
            debug endmethod
            /*
            *   Credits to MyPad for the algorithm
            */
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

    private struct Vec3D extends array
        readonly real x
        readonly real y
        readonly real z

        method update takes real x, real y, real z returns nothing
            set this.x = x
            set this.y = y
            set this.z = z
        endmethod
        method rotate takes thistype axis, real sin, real cos returns nothing
            local real i = axis.x
            local real j = axis.y
            local real k = axis.z
            local real f = this.x*i + this.y*j + this.z*k
            local real xx = this.x - i*f
            local real xy = this.y - j*f
            local real xz = this.z - k*f

            set this.x = xx*cos + (j*xz - k*xy)*sin + i*f
            set this.y = xy*cos + (k*xx - i*xz)*sin + j*f
            set this.z = xz*cos + (i*xy - j*xx)*sin + k*f
        endmethod
    endstruct

    private struct Orientation extends array
        readonly Vec3D yawAxis
        readonly Vec3D pitchAxis
        readonly Vec3D rollAxis

        method operator satellite takes nothing returns SatelliteEffect
            return this
        endmethod

        method rotate takes Vec3D axis, real sin, real cos returns nothing
            if axis != this.yawAxis then
                call this.yawAxis.rotate(axis, sin, cos)
            endif
            if axis != this.pitchAxis then
                call this.pitchAxis.rotate(axis, sin, cos)
            endif
            if axis != this.rollAxis then
                call this.rollAxis.rotate(axis, sin, cos)
            endif
        endmethod

        static method create takes thistype node returns thistype
            set node.rollAxis   = Node.allocate()
            set node.pitchAxis  = Node.allocate()
            set node.yawAxis    = Node.allocate()

            call node.rollAxis  .update(1, 0, 0)
            call node.pitchAxis .update(0, 1, 0)
            call node.yawAxis   .update(0, 0, 1)

            call node.rotate(node.yawAxis, Sin(node.satellite.effect.yaw), Cos(node.satellite.effect.yaw))
            call node.rotate(node.pitchAxis, Sin(node.satellite.effect.pitch), Cos(node.satellite.effect.pitch))
            call node.rotate(node.rollAxis, Sin(node.satellite.effect.roll), Cos(node.satellite.effect.roll))

            return node
        endmethod
        method destroy takes nothing returns nothing
            call Node(this.yawAxis).deallocate()
            call Node(this.pitchAxis).deallocate()
            call Node(this.rollAxis).deallocate()
        endmethod
    endstruct

    /*
    *   Tree structure
    */
    private struct SatelliteNode extends array
        readonly thistype parent
        readonly thistype child

        readonly Vec3D ds
        readonly Vec3D do

        method operator satellite takes nothing returns SatelliteEffect
            return this
        endmethod

        private static method onInsert takes thistype node returns nothing
            set node.parent = node.next.parent

            set node.ds = Node.allocate()
            set node.do = Node.allocate()

            call node.ds.update(/*
                */node.satellite.effect.x - node.parent.satellite.effect.x, /*
                */node.satellite.effect.y - node.parent.satellite.effect.y, /*
                */node.satellite.effect.z - node.parent.satellite.effect.z  /*
            */)
            call node.do.update(/*
                */node.satellite.effect.yaw - node.parent.satellite.effect.yaw,     /*
                */node.satellite.effect.pitch - node.parent.satellite.effect.pitch, /*
                */node.satellite.effect.roll - node.parent.satellite.effect.roll    /*
            */)
        endmethod

        private static method onRemove takes thistype node returns nothing
            local thistype childNode

            if SatelliteEffect.propagateCommand then
                set childNode = node.child.next
                loop
                    exitwhen childNode == node.child
                    set childNode.next.prev = childNode.prev
                    set childNode.prev.next = childNode.next
                    call onRemove(childNode)
                    set childNode = childNode.next
                endloop
            endif

            set childNode = node.parent.child
            if childNode.next == node and childNode.prev == node then
                set node.parent.child = 0
            endif

            call Node(node.do).deallocate()
            call Node(node.ds).deallocate()

            set node.parent = 0
        endmethod

        implement List

        static method create takes nothing returns thistype
            local thistype node = Node.allocate()
            set node.child = Node.allocate()
            set node.child.parent = node
            call makeHead(node.child)
            return node
        endmethod
        method destroy takes nothing returns nothing
            if this.parent > 0 then
                call remove(this)
            endif
            call this.child.clear()
            set this.child.parent = 0
            call Node(this.child).deallocate()
            call Node(this).deallocate()
        endmethod
    endstruct

    struct SatelliteEffect extends array

        static boolean propagateCommand = true

        readonly SpecialEffect effect

        private SatelliteNode current

        private method operator satelliteTree takes nothing returns SatelliteNode
            return this
        endmethod
        private method operator orientation takes nothing returns Orientation
            return this
        endmethod

        method operator parent takes nothing returns thistype
            return this.satelliteTree.parent
        endmethod

        method operator dx takes nothing returns real
            return this.satelliteTree.ds.x
        endmethod
        method operator dy takes nothing returns real
            return this.satelliteTree.ds.y
        endmethod
        method operator dz takes nothing returns real
            return this.satelliteTree.ds.z
        endmethod

        method operator x takes nothing returns real
            return this.effect.x
        endmethod
        method operator y takes nothing returns real
            return this.effect.y
        endmethod
        method operator z takes nothing returns real
            return this.effect.z
        endmethod
        method operator height takes nothing returns real
            return this.effect.height
        endmethod
        method operator yaw takes nothing returns real
            return this.effect.yaw
        endmethod
        method operator pitch takes nothing returns real
            return this.effect.pitch
        endmethod
        method operator roll takes nothing returns real
            return this.effect.roll
        endmethod

        method currentSatellite takes nothing returns thistype
            debug call AssertError(not Node(this).allocated, "currentSatellite()", "thistype", this, "Invalid node")
            return this.current.satellite
        endmethod

        method resetIterator takes nothing returns nothing
            debug call AssertError(not Node(this).allocated, "resetIterator()", "thistype", this, "Invalid node")
            set this.current = this.satelliteTree.child
        endmethod
        method moveIterator takes nothing returns boolean
            debug call AssertError(not Node(this).allocated, "moveIterator()", "thistype", this, "Invalid node")
            set this.current = this.current.next
            return this.current == this.satelliteTree.child
        endmethod

        method dock takes thistype parent returns nothing
            debug call AssertError(not Node(this).allocated, "dock()", "thistype", this, "Invalid node")
            debug call AssertError(this.parent > 0, "dock()", "thistype", this, "Instance is already docked.")
            call parent.satelliteTree.child.pushBack(this)
        endmethod
        method undock takes nothing returns nothing
            debug call AssertError(not Node(this).allocated, "undock()", "thistype", this, "Invalid node")
            debug call AssertError(this.parent == 0, "undock()", "thistype", this, "Instance is not docked.")
            call SatelliteNode.remove(this.satelliteTree)
        endmethod

        method addSatellite takes thistype satellite returns nothing
            debug call AssertError(not Node(this).allocated, "addSatellite()", "thistype", this, "Invalid node")
            debug call AssertError(satellite.parent > 0, "addSatellite()", "thistype", this, "Satellite[" + I2S(satellite) + "] is already docked (somewhere).")
            call satellite.dock(this)
        endmethod
        method removeSatellite takes thistype satellite returns nothing
            debug call AssertError(not Node(this).allocated, "removeSatellite()", "thistype", this, "Invalid node")
            if satellite.parent == this then
                call satellite.undock()
            endif
        endmethod
        method clearSatellites takes nothing returns nothing
            debug call AssertError(not Node(this).allocated, "clearSatellites()", "thistype", this, "Invalid node")
            call this.satelliteTree.child.clear()
        endmethod

        method move takes real x, real y, real z returns nothing
            local SatelliteNode node = this.satelliteTree.child.next
            debug call AssertError(not Node(this).allocated, "move()", "thistype", this, "Invalid node")
            call this.effect.move(x, y, z)
            loop
                exitwhen node == this.satelliteTree.child
                call node.satellite.move(x + node.ds.x, y + node.ds.y, z + node.ds.z)
                set node = node.next
            endloop
        endmethod
        method moveRelative takes real x, real y, real height returns nothing
            local SatelliteNode node = this.satelliteTree.child.next
            debug call AssertError(not Node(this).allocated, "moveRelative()", "thistype", this, "Invalid node")
            call this.effect.moveRelative(x, y, height)
            loop
                exitwhen node == this.satelliteTree.child
                call node.satellite.moveRelative(x + node.ds.x, y + node.ds.y, height + node.ds.z)
                set node = node.next
            endloop
        endmethod

        method orient takes real yaw, real pitch, real roll returns nothing
            local real sinDeltaYaw      = Sin(yaw - this.yaw)
            local real sinDeltaPitch    = Sin(pitch - this.pitch)
            local real sinDeltaRoll     = Sin(roll - this.roll)
            local real cosDeltaYaw      = Cos(yaw - this.yaw)
            local real cosDeltaPitch    = Cos(pitch - this.pitch)
            local real cosDeltaRoll     = Cos(roll - this.roll)

            local SatelliteNode node = this.satelliteTree.child.next

            debug call AssertError(not Node(this).allocated, "orient()", "thistype", this, "Invalid node")

            call this.effect.setOrientation(yaw, pitch, roll)

            call this.orientation.rotate(this.orientation.yawAxis, sinDeltaYaw, cosDeltaYaw)
            call this.orientation.rotate(this.orientation.pitchAxis, sinDeltaPitch, cosDeltaPitch)
            call this.orientation.rotate(this.orientation.rollAxis, sinDeltaRoll, cosDeltaRoll)

            loop
                exitwhen node == this.satelliteTree.child

                call node.ds.rotate(this.orientation.yawAxis, sinDeltaYaw, cosDeltaYaw)
                call node.ds.rotate(this.orientation.pitchAxis, sinDeltaPitch, cosDeltaPitch)
                call node.ds.rotate(this.orientation.rollAxis, sinDeltaRoll, cosDeltaRoll)

                call node.satellite.orientation.rotate(this.orientation.yawAxis, sinDeltaYaw, cosDeltaYaw)
                call node.satellite.orientation.rotate(this.orientation.pitchAxis, sinDeltaPitch, cosDeltaPitch)
                call node.satellite.orientation.rotate(this.orientation.rollAxis, sinDeltaRoll, cosDeltaRoll)

                call node.satellite.effect.move(this.x + node.ds.x, this.y + node.ds.y, this.z + node.ds.z)
                call node.satellite.orient(yaw + node.do.x, pitch + node.do.y, roll + node.do.z)

                set node = node.next
            endloop
        endmethod

        static method create takes SpecialEffect specialEffect returns thistype
            local thistype node = SatelliteNode.create()
            set node.effect = specialEffect
            call node.resetIterator()
            call Orientation.create(node)
            return node
        endmethod
        method destroy takes nothing returns nothing
            debug call AssertError(not Node(this).allocated, "destroy()", "thistype", this, "Invalid node")
            call this.orientation.destroy()
            call this.satelliteTree.destroy()
        endmethod

    endstruct

endlibrary