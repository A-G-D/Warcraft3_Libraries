library UnitMotion /*


    */uses /*

    */ErrorMessage      /*   https://github.com/nestharus/JASS/blob/master/jass/Systems/ErrorMessage/main.j
    */Vector            /*   http://www.wc3c.net/showthread.php?t=87027
    */Table             /*   https://www.hiveworkshop.com/threads/snippet-new-table.188084/
    */UnitIndexer       /*
    */AutoFly           /*
    */Initializer       /*


    *///! novjass

    /*
    Description:

        This system is used to handle if possible, all unit movements, internally. You can use this
        to easily create knockback movements, throws, and jumps whether it be uniform or accelerated
        motion. By default, this system also takes into consideration the units' acceleration due to
        gravity as well as the side effect of gravity, i.e., ground friction. But if you don't need
        these additional features, you can just set their values to 0 in the configuration section
        below.
    */

    |=========|
    | CREDITS |
    |=========|

        Author:
            - AGD

        Dependencies:
            - Anitarf (Vector)
            - Bribe (Table)
            - Nestharus (ErrorMessage)

    |-----|
    | API |
    |-----|

        struct UnitMotion/*

          */static constant real FPS                       /*   Frames per second
          */static constant real FRAME_RATE                /*   Reciprocal of FPS (Refresh rate)
          */static constant real GRAVITY                   /*   Acceleration due to gravity in units per second^2
          */static constant real GROUND_FRICTION           /*   The coefficient of friction of the ground
          */static constant real DEFAULT_UNIT_FRICTION     /*   The default value of unit's coefficient of friction
          */static constant boolean AUTO_REGISTER_UNITS    /*   Determines whether newly entering units in the game are
                                                                automatically added to the system

          */readonly static UnitMotion triggerInstance     /*   Use this to refer to the UnitMotion instance of
                                                                the moving unit inside a motion handler function

          */real x                                         /*   The x-component of the UnitMotion
          */real y                                         /*   The y-component of the UnitMotion
          */real z                                         /*   The z-component of the UnitMotion
          */real coefficientOfFriction                     /*   The coefficient of friction of the unit
          */readonly real friction                         /*   The magnitude of the ground friction vector acting on the unit
          */readonly boolean airborne                      /*   Determines if the unit referred by the UnitMotion instance is airborne
          */readonly boolean freeFalling                   /*   Determines if the unit referred by the UnitMotion instance is free-falling
          */readonly unit unit                             /*   The unit the UnitMotion instance belongs to

          */static method operator [] takes unit whichUnit returns UnitMotion/*
                - Reftrieves the UnitMotion instance corresponding to the input unit

          */method destroy takes nothing returns nothing/*
                - Destroys a UnitMotion instance
                - Only available when AUTO_REGISTER_UNITS == false

          */method addVelocityByVector takes vector whichVector returns this/*
                - Adds a vector to the UnitMotion's velocity vector
          */method addVelocity takes Velocity velocity returns this/*
          */method removeVelocity takes Velocity velocity returns this/*
                - Adds/Removes a Velocity from this UnitMotion instance

          */method addAccelerationByVector takes vector whichVector returns this/*
                - Adds a vector to the UnitMotion's acceleration vector
          */method addAcceleration takes Acceleration acceleration returns this/*
          */method removeAcceleration takes Acceleration acceleration returns this/*
                - Adds/Removes an Acceleration from this UnitMotion instance

          */method addTorqueByVector takes vector axisOfRotation returns this/*
                - Adds a vector to the UnitMotion's torque axis vector
                - The length of the <axisOfRotation> vector determines the magnitude of the torque
          */method addTorqueByVectorEx takes vector axisOfRotation, real radius returns this/*
                - Adds a vector to the UnitMotion's torque axis vector
                - The magnitude added by the vector is equal to the magnitude of the torque necessary to make
                  a circular motion with a radius equal to the input radius
          */method addTorque takes Torque torque returns this/*
          */method removeTorque takes Torque torque returns this/*
                - Adds a centripetal acceleration to the UnitMotion instance

          */method addTorqueIncrement takes vector axisOfRotation, real magnitude returns this/*
                - Adds an increment in the torque's magnitude per period

          */method registerMotionHandler takes boolexpr expr returns this/*
          */method unregisterMotionHandler takes boolexpr expr returns this/*
          */method clearMotionHandlers takes nothing returns this/*
                - Manages boolexprs that runs when the unit moves due to a vector applied
                  to the unit using this system

          */static method registerUnitAddHandler takes boolexpr expr returns nothing/*
          */static method unregisterUnitAddHandler takes boolexpr expr returns nothing/*
          */static method clearUnitAddHandlers takes nothing returns nothing/*
                - Manages boolexprs that runs when a UnitMotion instance is first created for a unit
                - Only available when UnitMotion.AUTO_REGISTER_UNITS == false

          */static method registerRemoveAddHandler takes boolexpr expr returns nothing/*
          */static method unregisterRemoveAddHandler takes boolexpr expr returns nothing/*
          */static method clearUnitRemoveHandlers takes nothing returns nothing/*
                - Manages boolexprs that runs when a UnitMotion instance of a unit is destroyed
                - Only available when UnitMotion.AUTO_REGISTER_UNITS == false


      */struct Velocity/*

          */static method create takes nothing returns Velocity/*
          */method destroy takes nothing returns nothing/*
                - Creates/Destroys a Velocity instance

          */method add takes vector whichVector returns nothing/*
                - Adds a vector to this Velocity's vector


      */struct Acceleration/*

          */static method create takes nothing returns Acceleration/*
          */method destroy takes nothing returns nothing/*
                - Creates/Destroys an Acceleration instance

          */method add takes vector whichVector returns nothing/*
                - Adds a vector to this Acceleration's vector


      */struct Torque/*

          */static method create takes nothing returns Torque/*
          */method destroy takes nothing returns nothing/*
                - Creates/Destroys a Torque instance

          */method add takes vector axisOfRotation returns nothing/*
                - Adds a vector to this Torque's vector
                - The length of the <axisOfRotation> vector determines the magnitude
                  of the torque


    *///! endnovjass

    private keyword List

    struct UnitMotion extends array
        /********************************************************/
        /*                 SYSTEM CONFIGURATION                 */
        /********************************************************/
        /*
        The number of frames per second in which
        the periodic function operates.
        Default Value: 32                                       */
        static constant real FPS                        = 32.00
        /*
        The 'acceleration' due to gravity.
        Default Value: -981.00                                  */
        static constant real GRAVITY                    = -981.00
        /*
        The coefficient of the ground friction.
        Default Value: 0.70                                     */
        static constant real GROUND_FRICTION            = 0.70
        /*
        The default value for the coefficient of
        friction for units. This value is applied
        upon UnitMovement creation.
        Default Value: 0.60                                     */
        static constant real DEFAULT_UNIT_FRICTION      = 0.60
        /*
        Determines if newly created units are
        automatically registered into the
        system.                                                 */
        static constant boolean AUTO_REGISTER_UNITS     = false
        /********************************************************/
        /*                 END OF CONFIGURATION                 */
        /********************************************************/
        /*======================================================*/
        /*   Do not change anything below this line if you're   */
        /*          not so sure on what you're doing.           */
        /*======================================================*/

        private thistype prev
        private thistype next
        private boolean flag
        private integer motionHandlerCount
        private real deltaFriction
        private real unitFriction
        private trigger motionHandlerTrigger
        private vector velocity
        private vector acceleration
        private vector torqueAxis
        private vector torqueIncrement
        private vector timerForce

        readonly static thistype triggerInstance = 0
        readonly static thistype addedInstance = 0
        readonly static thistype removedInstance = 0
        static constant real FRAME_RATE = 1.00/FPS
        private static timer timer = CreateTimer()
        private static group enumerator = CreateGroup()
        private static code periodicCode
        private static TableArray tableArray
        private static TableArray velocityTable
        private static TableArray accelerationTable
        private static TableArray torqueTable

        static if not thistype.AUTO_REGISTER_UNITS then
            private static trigger unitAddHandlerTrigger
            private static trigger unitRemoveHandlerTrigger
            private static integer unitAddHandlerCount = 0
            private static integer unitRemoveHandlerCount = 0
        endif

        private method constructor takes nothing returns nothing
            local thistype last = thistype(0).prev
            set thistype(0).prev = this
            set last.next = this
            set this.prev = last
            set this.next = 0
            set this.velocity = vector.create(0.00, 0.00, 0.00)
            set this.acceleration = vector.create(0.00, 0.00, GRAVITY*FRAME_RATE)
            set this.torqueAxis = vector.create(0.00, 0.00, 0.00)
            set this.torqueIncrement = vector.create(0.00, 0.00, 0.00)
            set this.unitFriction = DEFAULT_UNIT_FRICTION
            set this.deltaFriction = GRAVITY*GROUND_FRICTION*DEFAULT_UNIT_FRICTION*FRAME_RATE
            set this.flag = true
            if this.prev == 0 then
                call TimerStart(timer, FRAME_RATE, true, periodicCode)
            endif
        endmethod

        private method destructor takes nothing returns nothing
            static if not thistype.AUTO_REGISTER_UNITS then
                local thistype prev = removedInstance
                set removedInstance = this
                call TriggerEvaluate(unitRemoveHandlerTrigger)
                set removedInstance = prev
            endif
            call this.velocity.destroy()
            call this.acceleration.destroy()
            call this.torqueAxis.destroy()
            call this.torqueIncrement.destroy()
            call tableArray[this].flush()
            call DestroyTrigger(this.motionHandlerTrigger)
            set this.motionHandlerTrigger = null
            set this.velocity = 0
            set this.acceleration = 0
            set this.torqueAxis = 0
            set this.torqueIncrement = 0
            set this.deltaFriction = 0.00
            set this.unitFriction = 0.00
            set this.motionHandlerCount = 0
            set this.flag = false
            set this.next.prev = this.prev
            set this.prev.next = this.next
            if thistype(0).next == 0 then
                call PauseTimer(timer)
            endif
        endmethod

        static method operator [] takes unit u returns thistype
            static if not thistype.AUTO_REGISTER_UNITS then
                local thistype this = GetUnitId(u)
                local thistype prev
                if not this.flag then
                    call this.constructor()
                    set prev = addedInstance
                    set addedInstance = this
                    call TriggerEvaluate(unitAddHandlerTrigger)
                    set addedInstance = prev
                endif
                return this
            else
                return GetUnitId(u)
            endif
        endmethod

        static if not thistype.AUTO_REGISTER_UNITS then
            method destroy takes nothing returns nothing
                debug call ThrowError(not this.flag, "UnitMotion", "destroy", "thistype", this, "Attempted to destroy an unallocated instance")
                call this.destructor()
            endmethod
        endif

        method operator unit takes nothing returns unit
            debug call ThrowError(not this.flag, "UnitMotion", "unit", "thistype", this, "Attempted to access an unallocated instance field")
            return GetUnitById(this)
        endmethod

        method operator airborne takes nothing returns boolean
            debug call ThrowError(not this.flag, "UnitMotion", "airborne", "thistype", this, "Attempted to access an unallocated instance field")
            return GetUnitFlyHeight(this.unit) > GetUnitDefaultFlyHeight(this.unit) + 10.00
        endmethod

        method operator x= takes real x returns nothing
            debug call ThrowError(not this.flag, "UnitMotion", "x=", "thistype", this, "Attempted to configure an unallocated instance")
            set this.velocity.x = x
        endmethod
        method operator x takes nothing returns real
            debug call ThrowError(not this.flag, "UnitMotion", "x", "thistype", this, "Attempted to access an unallocated instance field")
            return this.velocity.x
        endmethod

        method operator y= takes real y returns nothing
            debug call ThrowError(not this.flag, "UnitMotion", "y=", "thistype", this, "Attempted to configure an unallocated instance.")
            set this.velocity.y = y
        endmethod
        method operator y takes nothing returns real
            debug call ThrowError(not this.flag, "UnitMotion", "y", "thistype", this, "Attempted to access an unallocated instance field.")
            return this.velocity.y
        endmethod

        method operator z= takes real z returns nothing
            debug call ThrowError(not this.flag, "UnitMotion", "z=", "thistype", this, "Attempted to configure an unallocated instance")
            set this.velocity.z = z
        endmethod
        method operator z takes nothing returns real
            debug call ThrowError(not this.flag, "UnitMotion", "z", "thistype", this, "Attempted to access an unallocated instance field")
            return this.velocity.z
        endmethod

        method operator coefficientOfFriction= takes real frictionFactor returns nothing
            debug call ThrowError(not this.flag, "UnitMotion", "coefficientOfFriction=", "thistype", this, "Attempted to configure an unallocated instance")
            set this.unitFriction = frictionFactor
            set this.deltaFriction = RMinBJ(this.acceleration.z*GROUND_FRICTION*frictionFactor, 0.00)
        endmethod
        method operator coefficientOfFriction takes nothing returns real
            debug call ThrowError(not .flag, "UnitMotion", "coefficientOfFriction", "thistype", this, "Attempted to access an unallocated instance field")
            return this.unitFriction
        endmethod

        method operator friction takes nothing returns real
            debug call ThrowError(not .flag, "UnitMotion", "friction", "thistype", this, "Attempted to access an unallocated instance field")
            return this.deltaFriction*FPS
        endmethod

        method operator freeFalling takes nothing returns boolean
            local vector acceleration = this.acceleration
            debug call ThrowError(not this.flag, "UnitMotion", "freeFalling", "thistype", this, "Attempted to use an unallocated instance")
            return this.airborne                           and /*
            */     acceleration.x == 0.00                  and /*
            */     acceleration.y == 0.00                  and /*
            */     acceleration.z == GRAVITY*FRAME_RATE
        endmethod

        private static method addVector takes vector this, vector toAdd returns nothing
            if toAdd < 0 then
                call this.subtract(-toAdd)
            else
                call this.add(toAdd)
            endif
        endmethod

        method addVelocityByVector takes vector whichVector returns thistype
            debug call ThrowError(not this.flag, "UnitMotion", "addVelocityByVector()", "thistype", this, "Attempted to use an unallocated instance")
            debug call ThrowError(whichVector == 0, "UnitMotion", "addVelocityByVector()", "thistype", this, "Attempted to use a null vector instance")
            call addVector(this.velocity, whichVector)
            return this
        endmethod
        method addVelocity takes Velocity velocity returns thistype
            debug call ThrowError(not this.flag, "UnitMotion", "addVelocity()", "thistype", this, "Attempted to use an unallocated instance")
            debug call ThrowError(velocity == 0, "UnitMotion", "addVelocity()", "thistype", this, "Attempted to use a null Velocity instance")
            debug call ThrowError(velocity < 0, "UnitMotion", "addVelocity()", "thistype", this, "Attempted to use an invalid Velocity instance")
            debug call ThrowError(velocityTable[this].has(velocity), "UnitMotion", "addVelocity()", "thistype", this, "Attempted to add an already added Velocity instance")
            call this.velocity.add(velocity)
            set velocityTable[this][velocity] = s__Velocity_references[velocity].insert(this)
            return this
        endmethod
        method removeVelocity takes Velocity velocity returns thistype
            debug call ThrowError(not this.flag, "UnitMotion", "removeVelocity()", "thistype", this, "Attempted to use an unallocated instance")
            debug call ThrowError(velocity == 0, "UnitMotion", "removeVelocity()", "thistype", this, "Attempted to use a null Velocity instance")
            debug call ThrowError(velocity < 0, "UnitMotion", "removeVelocity()", "thistype", this, "Attempted to use an invalid Velocity instance")
            debug call ThrowError(not velocityTable[this].has(velocity), "UnitMotion", "removeVelocity()", "thistype", this, "Attempted to remove an unadded Velocity instance")
            call this.velocity.subtract(velocity)
            call List(velocityTable[this][velocity]).remove()
            call velocityTable[this].remove(velocity)
            return this
        endmethod

        method addAccelerationByVector takes vector whichVector returns thistype
            local vector acceleration = this.acceleration
            debug call ThrowError(not this.flag, "UnitMotion", "addAccelerationByVector()", "thistype", this, "Attempted to use an unallocated instance")
            debug call ThrowError(whichVector == 0, "UnitMotion", "addAccelerationByVector()", "thistype", this, "Attempted to use a null vector instance")
            call whichVector.scale(FRAME_RATE)
            call addVector(acceleration, whichVector)
            call whichVector.scale(FPS)
            set this.deltaFriction = RMinBJ(acceleration.z*GROUND_FRICTION*this.unitFriction, 0.00)
            return this
        endmethod
        method addAcceleration takes Acceleration acceleration returns thistype
            debug call ThrowError(not this.flag, "UnitMotion", "addAcceleration()", "thistype", this, "Attempted to use an unallocated instance")
            debug call ThrowError(acceleration == 0, "UnitMotion", "addAcceleration()", "thistype", this, "Attempted to use a null Acceleration instance")
            debug call ThrowError(acceleration < 0, "UnitMotion", "addAcceleration()", "thistype", this, "Attempted to use an invalid Acceleration instance")
            debug call ThrowError(accelerationTable[this].has(acceleration), "UnitMotion", "addAcceleration()", "thistype", this, "Attempted to add an already added Acceleration instance")
            call this.acceleration.add(acceleration)
            set this.deltaFriction = RMinBJ(this.acceleration.z*GROUND_FRICTION*this.unitFriction, 0.00)
            set accelerationTable[this][acceleration] = s__Acceleration_references[acceleration].insert(this)
            return this
        endmethod
        method removeAcceleration takes Acceleration acceleration returns thistype
            debug call ThrowError(not this.flag, "UnitMotion", "removeAcceleration()", "thistype", this, "Attempted to use an unallocated instance")
            debug call ThrowError(acceleration == 0, "UnitMotion", "removeAcceleration()", "thistype", this, "Attempted to use a null Acceleration instance")
            debug call ThrowError(acceleration < 0, "UnitMotion", "removeAcceleration()", "thistype", this, "Attempted to use an invalid Acceleration instance")
            debug call ThrowError(not accelerationTable[this].has(acceleration), "UnitMotion", "removeAcceleration()", "thistype", this, "Attempted to remove an unadded Acceleration instance")
            call this.acceleration.subtract(acceleration)
            set this.deltaFriction = RMinBJ(this.acceleration.z*GROUND_FRICTION*this.unitFriction, 0.00)
            call List(accelerationTable[this][acceleration]).remove()
            call accelerationTable[this].remove(acceleration)
            return this
        endmethod

        method addTorqueByVector takes vector axis returns thistype
            debug call ThrowError(not this.flag, "UnitMotion", "addTorqueByVector()", "thistype", this, "Attempted to use an unallocated instance")
            debug call ThrowError(axis == 0, "UnitMotion", "addTorqueByVector()", "thistype", this, "Attempted to use a null vector instance")
            call axis.scale(FRAME_RATE)
            call addVector(this.torqueAxis, axis)
            call axis.scale(FPS)
            return this
        endmethod
        method addTorqueByVectorEx takes vector axis, real radius returns thistype
            local real speed = this.velocity.getLength()
            local real length = axis.getLength()
            debug call ThrowError(not this.flag, "UnitMotion", "addTorqueByVectorEx()", "thistype", this, "Attempted to use an unallocated instance")
            debug call ThrowError(axis == 0, "UnitMotion", "addTorqueByVectorEx()", "thistype", this, "Attempted to use a null vector instance")
            debug call ThrowError(radius == 0.00, "UnitMotion", "addTorqueByVectorEx()", "thistype", this, "Attempted to input a zero radius")
            call axis.scale((speed*speed)/(radius*length))
            call addVector(this.torqueAxis, axis)
            call axis.scale((radius*length)/(speed*speed))
            return this
        endmethod
        method addTorque takes Torque torque returns thistype
            debug call ThrowError(not this.flag, "UnitMotion", "addTorque()", "thistype", this, "Attempted to use an unallocated instance")
            debug call ThrowError(torque == 0, "UnitMotion", "addTorque()", "thistype", this, "Attempted to use a null Torque instance")
            debug call ThrowError(torque < 0, "UnitMotion", "addTorque()", "thistype", this, "Attempted to use an invalid Torque instance")
            debug call ThrowError(torqueTable[this].has(torque), "UnitMotion", "addTorque()", "thistype", this, "Attempted to add an already added Torque instance")
            call this.torqueAxis.add(torque)
            set torqueTable[this][torque] = s__Torque_references[torque].insert(this)
            return this
        endmethod
        method removeTorque takes Torque torque returns thistype
            debug call ThrowError(not this.flag, "UnitMotion", "removeTorque()", "thistype", this, "Attempted to use an unallocated instance")
            debug call ThrowError(torque == 0, "UnitMotion", "removeTorque()", "thistype", this, "Attempted to use a null Torque instance")
            debug call ThrowError(torque < 0, "UnitMotion", "removeTorque()", "thistype", this, "Attempted to use an invalid Torque instance")
            debug call ThrowError(torqueTable[this].has(torque), "UnitMotion", "removeTorque()", "thistype", this, "Attempted to remove an unadded Torque instance")
            call this.torqueAxis.subtract(torque)
            call List(torqueTable[this][torque]).remove()
            call torqueTable[this].remove(torque)
            return this
        endmethod

        method addTorqueIncrement takes vector axis, real magnitude returns thistype
            local real length = axis.getLength()
            debug call ThrowError(not this.flag, "UnitMotion", "addTorqueIncrement()", "thistype", this, "Attempted to use an unallocated instance")
            call axis.setLength(FRAME_RATE*magnitude/length)
            call addVector(this.torqueIncrement, axis)
            call axis.setLength(FPS*length/magnitude)
            return this
        endmethod

        method registerMotionHandler takes boolexpr expr returns thistype
            debug call ThrowError(not this.flag, "UnitMotion", "registerMotionHandler()", "thistype", this, "Attempted to use an unallocated instance")
            debug call ThrowError(expr == null, "UnitMotion", "registerMotionHandler()", "thistype", this, "Attemped to register a null boolexpr")
            debug call ThrowError(tableArray[this].handle.has(GetHandleId(expr)), "UnitMotion", "registerHandler()", "thistype", this, "Attemped to register a boolexpr twice")
            if this.motionHandlerCount == 0 then
                set this.motionHandlerTrigger = CreateTrigger()
            endif
            set this.motionHandlerCount = this.motionHandlerCount + 1
            set tableArray[this].triggercondition[GetHandleId(expr)] = TriggerAddCondition(this.motionHandlerTrigger, expr)
            return this
        endmethod
        method unregisterMotionHandler takes boolexpr expr returns thistype
            local integer exprId
            debug call ThrowError(not this.flag, "UnitMotion", "unregisterMotionHandler()", "thistype", this, "Attempted to use an unallocated instance")
            debug call ThrowError(expr == null, "UnitMotion", "unregisterMotionHandler()", "thistype", this, "Attemped to unregister a null boolexpr")
            debug call ThrowError(not tableArray[this].handle.has(GetHandleId(expr)), "UnitMotion", "unregisterHandler()", "thistype", this, "Attemped to unregister a boolexpr twice")
            set this.motionHandlerCount = this.motionHandlerCount - 1
            if this.motionHandlerCount == 0 then
                call tableArray[this].handle.remove(GetHandleId(expr))
                call DestroyTrigger(this.motionHandlerTrigger)
                set this.motionHandlerTrigger = null
            else
                set exprId = GetHandleId(expr)
                call TriggerRemoveCondition(this.motionHandlerTrigger, tableArray[this].triggercondition[exprId])
                call tableArray[this].handle.remove(exprId)
            endif
            return this
        endmethod
        method clearMotionHandlers takes nothing returns thistype
            debug call ThrowError(not this.flag, "UnitMotion", "unit", "thistype", this, "Attempted to use an unallocated instance")
            call tableArray[this].flush()
            call DestroyTrigger(this.motionHandlerTrigger)
            set this.motionHandlerTrigger = null
            set this.motionHandlerCount = 0
            return this
        endmethod

        static if not thistype.AUTO_REGISTER_UNITS then
            static method registerUnitAddHandler takes boolexpr expr returns nothing
                debug call ThrowError(expr == null, "UnitMotion", "registerUnitAddHandler()", "thistype", 0, "Attemped to register a null boolexpr")
                debug call ThrowError(tableArray[0].handle.has(GetHandleId(expr)), "UnitMotion", "registerUnitAddHandler()", "thistype", 0, "Attemped to register a boolexpr twice")
                if unitAddHandlerCount == 0 then
                    set unitAddHandlerTrigger = CreateTrigger()
                endif
                set unitAddHandlerCount = unitAddHandlerCount + 1
                set tableArray[0].triggercondition[GetHandleId(expr)] = TriggerAddCondition(unitAddHandlerTrigger, expr)
            endmethod
            static method unregisterUnitAddHandler takes boolexpr expr returns nothing
                local integer exprId
                debug call ThrowError(expr == null, "UnitMotion", "unregisterUnitAddHandler()", "thistype", 0, "Attemped to unregister a null boolexpr")
                debug call ThrowError(not tableArray[0].handle.has(GetHandleId(expr)), "UnitMotion", "unregisterUnitAddHandler()", "thistype", 0, "Attemped to unregister a boolexpr twice")
                set unitAddHandlerCount = unitAddHandlerCount - 1
                if unitAddHandlerCount == 0 then
                    call tableArray[0].handle.remove(GetHandleId(expr))
                    call DestroyTrigger(unitAddHandlerTrigger)
                    set unitAddHandlerTrigger = null
                else
                    set exprId = GetHandleId(expr)
                    call TriggerRemoveCondition(unitAddHandlerTrigger, tableArray[0].triggercondition[exprId])
                    call tableArray[0].handle.remove(exprId)
                endif
            endmethod
            static method clearUnitAddHandlers takes nothing returns nothing
                call tableArray[0].flush()
                call DestroyTrigger(unitAddHandlerTrigger)
                set unitAddHandlerTrigger = null
                set unitAddHandlerCount = 0
            endmethod

            static method registerUnitRemoveHandler takes boolexpr expr returns nothing
                debug call ThrowError(expr == null, "UnitMotion", "registerUnitRemoveHandler()", "thistype", 0, "Attemped to register a null boolexpr")
                debug call ThrowError(tableArray[8191].handle.has(GetHandleId(expr)), "UnitMotion", "registerUnitRemoveHandler()", "thistype", 0, "Attemped to register a boolexpr twice")
                if unitRemoveHandlerCount == 0 then
                    set unitRemoveHandlerTrigger = CreateTrigger()
                endif
                set unitRemoveHandlerCount = unitRemoveHandlerCount + 1
                set tableArray[8191].triggercondition[GetHandleId(expr)] = TriggerAddCondition(unitRemoveHandlerTrigger, expr)
            endmethod
            static method unregisterUnitRemoveHandler takes boolexpr expr returns nothing
                local integer exprId
                debug call ThrowError(expr == null, "UnitMotion", "unregisterUnitRemoveHandler()", "thistype", 0, "Attemped to unregister a null boolexpr")
                debug call ThrowError(not tableArray[8191].handle.has(GetHandleId(expr)), "UnitMotion", "unregisterUnitRemoveHandler()", "thistype", 0, "Attemped to unregister a boolexpr twice")
                set unitRemoveHandlerCount = unitRemoveHandlerCount - 1
                if unitRemoveHandlerCount == 0 then
                    call tableArray[8191].handle.remove(GetHandleId(expr))
                    call DestroyTrigger(unitRemoveHandlerTrigger)
                    set unitRemoveHandlerTrigger = null
                else
                    set exprId = GetHandleId(expr)
                    call TriggerRemoveCondition(unitRemoveHandlerTrigger, tableArray[8191].triggercondition[exprId])
                    call tableArray[8191].handle.remove(exprId)
                endif
            endmethod
            static method clearUnitRemoveHandlers takes nothing returns nothing
                call tableArray[8191].flush()
                call DestroyTrigger(unitRemoveHandlerTrigger)
                set unitRemoveHandlerTrigger = null
                set unitRemoveHandlerCount = 0
            endmethod
        endif

        private static method vectorNotZero takes vector this returns boolean
            return this.x != 0.00 or/*
                */ this.y != 0.00 or/*
                */ this.z != 0.00
        endmethod

        private static method periodic takes nothing returns nothing
            local thistype this = thistype(0).next
            local thistype prev
            local thistype next
            local unit u
            local real xVel
            local real yVel
            local real unitZ
            local real defaultZ
            local real friction
            local vector velocity
            local vector acceleration
            local vector torqueAxis
            local vector torqueIncrement
            loop
                exitwhen this == 0
                set velocity = this.velocity
                set acceleration = this.acceleration
                if vectorNotZero(acceleration) then
                    call velocity.add(acceleration)
                    set this.deltaFriction = RMinBJ(acceleration.z*GROUND_FRICTION*this.unitFriction, 0.00)
                endif
                if vectorNotZero(velocity) then
                    set u = this.unit
                    set unitZ = GetUnitFlyHeight(u)
                    set defaultZ = GetUnitDefaultFlyHeight(u) + 0.10
                    if unitZ > defaultZ then
                        call SetUnitPropWindow(u, 0.00)
                        call SetUnitTurnSpeed(u, 0.00)
                    else
                        call SetUnitPropWindow(u, GetUnitDefaultPropWindow(u))
                        call SetUnitTurnSpeed(u, GetUnitDefaultTurnSpeed(u))
                        set friction = this.deltaFriction
                        if velocity.z < 0.00 then
                            set velocity.z = 0.00
                        endif
                        if friction < 0.00 then
                            set xVel = velocity.x
                            set yVel = velocity.y
                            if xVel != 0.00 or yVel != 0.00 then
                                if friction*friction > xVel*xVel + yVel*yVel then
                                    set velocity.x = 0.00
                                    set velocity.y = 0.00
                                else
                                    call velocity.setLength(RMaxBJ(velocity.getLength() + friction, 0.00))
                                endif
                            endif
                        endif
                    endif
                    if velocity.x != 0.00 or velocity.y != 0.00 or velocity.z > 0.00 or (unitZ > defaultZ and velocity.z != 0.00) then
                        set torqueAxis = this.torqueAxis
                        set torqueIncrement = this.torqueIncrement
                        if vectorNotZero(torqueIncrement) then
                            call torqueAxis.add(torqueIncrement)
                        endif
                        if vectorNotZero(torqueAxis) then
                            call velocity.rotate(torqueAxis, torqueAxis.getLength()/velocity.getLength())
                        endif
                        call SetUnitX(u, GetUnitX(u) + velocity.x*FRAME_RATE)
                        call SetUnitY(u, GetUnitY(u) + velocity.y*FRAME_RATE)
                        call SetUnitFlyHeight(u, unitZ + velocity.z*FRAME_RATE, 0.00)
                        set triggerInstance = this
                        call TriggerEvaluate(this.motionHandlerTrigger)
                        set triggerInstance = 0
                    endif
                endif
                set this = this.next
            endloop
            set u = null
        endmethod

        static if thistype.AUTO_REGISTER_UNITS then
            private static method onIndex takes nothing returns nothing
                call thistype(GetIndexedUnitId()).constructor()
            endmethod
            private static method onDeindex takes nothing returns nothing
                call thistype(GetIndexedUnitId()).destructor()
            endmethod
        endif

        private static method init takes nothing returns nothing
            static if thistype.AUTO_REGISTER_UNITS then
                call RegisterUnitIndexEvent(function thistype.onIndex)
                call RegisterUnitDeindexEvent(function thistype.onDeindex)
            endif
            set periodicCode = function thistype.periodic
            set tableArray = TableArray[0x2001]
            set velocityTable = TableArray[0x2000]
            set accelerationTable = TableArray[0x2000]
            set torqueTable = TableArray[0x2000]
        endmethod
        implement Initializer

    endstruct

    private struct List extends array
        private static key prevK
        private static key nextK
        private static key dataK

        method operator data takes nothing returns UnitMotion
            return Table(dataK)[this]
        endmethod
        method operator next takes nothing returns thistype
            return Table(nextK)[this]
        endmethod

        method insert takes UnitMotion data returns thistype
            local thistype node = Table.create()
            local thistype last = Table(prevK)[this]
            set Table(prevK)[node] = last
            set Table(nextK)[node] = this
            set Table(prevK)[this] = node
            set Table(nextK)[last] = node
            set Table(dataK)[node] = data
            return node
        endmethod
        method remove takes nothing returns nothing
            local thistype prev = Table(prevK)[this]
            local thistype next = Table(nextK)[this]
            set Table(prevK)[next] = prev
            set Table(nextK)[prev] = next
            call Table(dataK).remove(this)
            call Table(this).destroy()
        endmethod

        method clear takes nothing returns nothing
            local thistype node = this.next
            loop
                exitwhen node == this
                call node.remove()
                set node = node.next
            endloop
        endmethod

        static method create takes nothing returns thistype
            local thistype this = Table.create()
            set Table(prevK)[this] = this
            set Table(nextK)[this] = this
            return this
        endmethod
        method destroy takes nothing returns nothing
            call this.clear()
            call Table(prevK).remove(this)
            call Table(nextK).remove(this)
            call Table(this).destroy()
        endmethod
    endstruct

    private module CommonMembers
        static method create takes nothing returns thistype
            local thistype this = vector.create(0.00, 0.00, 0.00)
            set this.references = List.create()
            return this
        endmethod
        method destroy takes nothing returns nothing
            call this.clearReferences()
            call this.references.destroy()
            call vector(this).destroy()
        endmethod
    endmodule

    struct Velocity extends array
        private List references

        method clearReferences takes nothing returns nothing
            local List node = this.references.next
            loop
                exitwhen node == this
                call node.data.removeVelocity(this)
                set node = node.next
            endloop
        endmethod

        implement CommonMembers

        method add takes vector vec returns nothing
            local List node = this.references.next
            if vec < 0 then
                loop
                    exitwhen node == this.references
                    call s__UnitMotion_velocity[node.data].subtract(-vec)
                    set node = node.next
                endloop
                call vector(this).subtract(-vec)
            else
                loop
                    exitwhen node == this.references
                    call s__UnitMotion_velocity[node.data].add(vec)
                    set node = node.next
                endloop
                call vector(this).add(vec)
            endif
        endmethod
    endstruct

    struct Acceleration extends array
        private List references

        method clearReferences takes nothing returns nothing
            local List node = this.references.next
            loop
                exitwhen node == this
                call node.data.removeAcceleration(this)
                set node = node.next
            endloop
        endmethod

        implement CommonMembers

        method add takes vector vec returns nothing
            local List node = this.references.next
            call vec.scale(UnitMotion.FRAME_RATE)
            if vec < 0 then
                loop
                    exitwhen node == this.references
                    call s__UnitMotion_acceleration[node.data].subtract(-vec)
                    set node.data.coefficientOfFriction = node.data.coefficientOfFriction
                    set node = node.next
                endloop
                call vector(this).subtract(-vec)
            else
                loop
                    exitwhen node == this.references
                    call s__UnitMotion_acceleration[node.data].add(vec)
                    set node.data.coefficientOfFriction = node.data.coefficientOfFriction
                    set node = node.next
                endloop
                call vector(this).add(vec)
            endif
            call vec.scale(UnitMotion.FPS)
        endmethod
    endstruct

    struct Torque extends array
        private List references

        method clearReferences takes nothing returns nothing
            local List node = this.references.next
            loop
                exitwhen node == this
                call node.data.removeTorque(this)
                set node = node.next
            endloop
        endmethod

        implement CommonMembers

        method add takes vector axis returns nothing
            local List node = this.references.next
            call axis.scale(UnitMotion.FRAME_RATE)
            if axis < 0 then
                loop
                    exitwhen node == this.references
                    call s__UnitMotion_torqueAxis[node.data].subtract(-axis)
                    set node = node.next
                endloop
                call vector(this).subtract(-axis)
            else
                loop
                    exitwhen node == this.references
                    call s__UnitMotion_torqueAxis[node.data].add(axis)
                    set node = node.next
                endloop
                call vector(this).add(axis)
            endif
            call axis.scale(UnitMotion.FPS)
        endmethod
    endstruct


endlibrary
