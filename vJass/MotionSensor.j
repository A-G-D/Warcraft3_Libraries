library MotionSensor /* v1.3


    */uses /*

    */UnitDex             /*  http://www.hiveworkshop.com/threads/system-unitdex-unit-indexer.248209
    */optional TimerUtils /*  http://www.wc3c.net/showthread.php?t=101322
    */optional GroupUtils /*  http://www.wc3c.net/showthread.php?t=104464

*///! novjass

     _____________
    |             |
    | Author: AGD |
    |_____________|

/*      This simple system allows you to check if the current motion
        a unit is stationary or in motion (This includes triggered
        motion). You can also use this to get the instantaneous speed
        of a unit and its direction of motion. This also allows you to
        detect a change in motion event i.e. when either a unit in
        motion stops or a stationary unit moves. Furthermore, the system
        includes many other utilities regarding unit motion.                */


    |==============|
    |  Struct API  |
    |==============|
 
        struct Sensor

            readonly boolean flag                /* Checks if the Sensor instance is registered */
            readonly boolean moving              /* Checks if it is moving or not */
            readonly real speed                  /* The instantaneous speed */
            readonly real direction              /* The direction of motion */
            readonly real deltaX                 /* X component of the instantaneous speed */
            readonly real deltaY                 /* Y component of the instantaneous speed */
            readonly real prevX                  /* The previous x-coordinate */
            readonly real prevY                  /* The previous y-coordinate */
            readonly static unit triggerUnit     /* The motion changing unit */
            readonly static real newMotionState  /* The current motion state of the motion changing unit */

            static method operator [] takes unit u returns Sensor/*
                - Returns a Sensor instance based on the unit parameter

          */static method operator []= takes unit u, boolean flag returns nothing/*
                - Registers/Unregisters a unit to the system

          */static method operator enabled= takes boolean flag returns nothing/*
                - Enables/Disables the Motion Sensor

          */static method operator enabled takes nothing returns boolean/*
                - Checks if the Motion Sensor is enabled or disabled

          */static method addMotionChangeEvent takes code c returns triggercondition/*
                - Adds a code to run during a motion change event

          */static method addOnMoveEvent takes code c returns triggercondition/*
                - Adds a code to run when a unit stops moving

          */static method addOnStopEvent takes code c returns triggercondition/*
                - Adds a code to run when a stationary unit moves

          */static method removeMotionChangeEvent takes triggercondition tc returns nothing/*
                - Removes a code from the motion change event

          */static method removeOnMoveEvent takes triggercondition tc returns nothing/*
                - Removes a code from the on move event

          */static method removeOnStopEvent takes triggercondition tc returns nothing/*
                - Removes a code from the on stop event                              */


    |================|
    |  Function API  |
    |================|

/*      All these functions inline when DEBUG_MODE is OFF except for
        RegisterEvent functions which was done intentionally to allow
        users to pass code that returns nothing                         */

        function GetInstantaneousSpeed takes unit u returns real/*
            - Returns the instantaneous speed of a unit

      */function GetUnitDeltaX takes unit u returns real/*
            - Returns the x-component of a unit's instantaneous velocity

      */function GetUnitDeltaY takes unit u returns real/*
            - Returns the y-component of a unit's instantaneous velocity

      */function GetMotionDirection takes unit u returns real/*
            - Returns the current direction of a unit's motion

      */function IsUnitMoving takes unit u returns boolean/*
            - Checks if a unit is currently moving or not

      */function IsUnitSensored takes unit u returns boolean/*
            - Checks if a unit is registered to the system or not

      */function RegisterMotionChangeEvent takes code c returns triggercondition
        function RemoveMotionChangeEvent takes triggercondition tc returns nothing/*
            - Registers a code to run upon a motion change event / Unregisters it

      */function RegisterOnMoveEvent takes code c returns triggercondition
        function RemoveOnMoveEvent takes triggercondition tc returns nothing/*
            - Registers a code to run when a stationary unit moves / Unregisters it

      */function RegisterOnStopEvent takes code c returns triggercondition/*
        function RemoveOnStopEvent takes triggercondition tc returns nothing
            - Registers a code to run when a unit in motion stops / Unregisters it

      */function SensorAddUnit takes unit u returns nothing
        function SensorRemoveUnit takes unit u returns nothing/*
            - Registers a unit to the system / Unregisters it

      */function GetNewMotionState takes nothing returns real/*
            - Refers to the current motion of the motion changing unit

      */function GetMotionChangingUnit takes nothing returns unit/*
            - Refers to the motion changing unit

      */function MotionSensorEnable takes nothing returns nothing
        function MotionSensorDisable takes nothing returns nothing/*
            - Switches the motion sensor ON/OFF

      */function IsSensorEnabled takes nothing returns boolean/*
            - Checks if the system is enabled of disabled     */


    |===========|
    | Constants |
    |===========|

        Groups:
        group SENSOR_GROUP_MOVING
        group SENSOR_GROUP_STATIONARY

/*      You can use these groups to easily loop among moving/stationary
        units like so:                                                     */

        loop
            set u = FirstOfGroup(SENSOR_GROUP_MOVING)
            exitwhen u == null
            call GroupRemoveUnit(SENSOR_GROUP_MOVING, u)
            call GroupAddUnit(tempGroup, u)
            // ...Do stuffs...
        endloop
        set forSwap = SENSOR_GROUP_MOVING
        set SENSOR_GROUP_MOVING = tempGroup
        set tempGroup = forSwap
        // Note: Do not destroy these groups nor set them to something
        //       else without setting back to the original before the
        //       thread execution finishes

        Reals:
        real MOTION_STATE_MOVING
        real MOTION_STATE_STATIONARY

/*      You can use these constants to check what is the new motion state
        of the event like so:                                              */

        if GetNewMotionState() == MOTION_STATE_MOVING then
            call KillUnit(GetMotionChangingUnit())
        elseif GetNewMotionState() == MOTION_STATE_STATIONARY then
            call RemoveUnit(GetMotionChangingUnit())
        endif

//! endnovjass
    /*=========================== Configuration ===========================*/

    globals

/*      Unit position check interval (Values greater than 0.03
        causes a bit of inaccuracy in the given instantaneous
        speed of a unit. As the value lowers, the accuracy
        increases at the cost of performance.)
*/      private constant real TIMEOUT                   = 0.03

/*      Set to true if you want the system to automatically
        register units upon entering the map. Set to false if
        you want to manually register units.
*/      private constant boolean AUTO_REGISTER_UNITS    = true

    endglobals

    /*======================= End of Configuration ========================*/
    /*   Do not change anything below this line if you're not so sure on   */
    /*                         what you're doing.                          */
    /*=====================================================================*/
    private keyword Init

    globals
        constant real MOTION_STATE_MOVING          = 1.00
        constant real MOTION_STATE_STATIONARY      = 2.00
        group SENSOR_GROUP_MOVING                  = CreateGroup()
        group SENSOR_GROUP_STATIONARY              = CreateGroup()
    endglobals

    struct Sensor extends array

        readonly boolean flag
        readonly boolean moving
        readonly real speed
        readonly real direction
        readonly real deltaX
        readonly real deltaY
        readonly real prevX
        readonly real prevY
        readonly static unit movingUnit
        readonly static unit triggerUnit
        readonly static real newMotionState

        private static boolean isEnabled
        private static boolean prevState
        private static real tempX
        private static real tempY
        private static real unitX
        private static real unitY
        private static thistype uDex
        private static timer tempTimer
        private static unit tempUnit
        private static real motionEvent
        private static trigger array trig
        private static group forSwap
        private static group sensorGroup = CreateGroup()

        static if not LIBRARY_GroupUtils then
            private static group ENUM_GROUP = CreateGroup()
        endif

        debug private static method debug takes string msg returns nothing
            debug call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 30, "|CFFFFCC00[Motion Sensor]|R " + msg)
        debug endmethod

        private static method iterate takes nothing returns nothing
            loop
                set tempUnit = FirstOfGroup(sensorGroup)
                exitwhen tempUnit == null
                call GroupRemoveUnit(sensorGroup, tempUnit)
                call GroupAddUnit(ENUM_GROUP, tempUnit)
                set uDex = GetUnitId(tempUnit)
                set prevState = uDex.moving
                set unitX = GetUnitX(tempUnit)
                set unitY = GetUnitY(tempUnit)
                set tempX = unitX - uDex.prevX
                set tempY = unitY - uDex.prevY
                set uDex.prevX = unitX
                set uDex.prevY = unitY
                set uDex.deltaX = tempX
                set uDex.deltaY = tempY
                set uDex.speed = SquareRoot(tempX*tempX + tempY*tempY)/TIMEOUT
                set uDex.direction = bj_RADTODEG*Atan2(tempY, tempX)
                set uDex.moving = uDex.speed > 0.00
                if prevState != uDex.moving then
                    set triggerUnit = tempUnit
                    set newMotionState = 0.00
                    if uDex.moving then
                        set newMotionState = MOTION_STATE_MOVING
                        call GroupRemoveUnit(SENSOR_GROUP_STATIONARY, tempUnit)
                        call GroupAddUnit(SENSOR_GROUP_MOVING, tempUnit)
                    else
                        set newMotionState = MOTION_STATE_STATIONARY
                        call GroupRemoveUnit(SENSOR_GROUP_MOVING, tempUnit)
                        call GroupAddUnit(SENSOR_GROUP_STATIONARY, tempUnit)
                    endif
                    set motionEvent = 0.00
                    set motionEvent = 1.00
                    set motionEvent = 0.00
                    set newMotionState = 0.00
                endif
            endloop
            set forSwap = sensorGroup
            set sensorGroup = ENUM_GROUP
            set ENUM_GROUP = forSwap
        endmethod

        static method operator enabled takes nothing returns boolean
            return isEnabled
        endmethod

        static method operator enabled= takes boolean flag returns nothing
            set isEnabled = flag
            if flag then
                debug call debug("Motion sensor is turned ON")
                call TimerStart(tempTimer, TIMEOUT, true, function thistype.iterate)
            else
                debug call debug("Motion sensor is turned OFF")
                call PauseTimer(tempTimer)
            endif
        endmethod

        static method operator [] takes unit u returns thistype
            debug if not thistype(GetUnitId(u)).flag then
                debug call debug("|CFFFF0000Operator [] error: Attempt to use an unregistered instance|R")
                debug return 0
            debug endif
            return GetUnitId(u)
        endmethod

        static method operator []= takes unit u, boolean flag returns nothing
            if u != null then
                set uDex = GetUnitId(u)
                if flag then
                    debug if uDex.flag then
                        debug call debug("|CFFFF0000Operator []= error: Attempt to double register an instance|R")
                        debug return
                    debug endif
                    /* Enable the Sensor iterator again when the sensorGroup is not anymore empty */
                    if enabled and FirstOfGroup(sensorGroup) == null then
                        call TimerStart(tempTimer, TIMEOUT, true, function thistype.iterate)
                    endif
                    call GroupAddUnit(sensorGroup, u)
                    call GroupAddUnit(SENSOR_GROUP_STATIONARY, u)
                    /* Initialize prevX and prevY for the newly registered unit to
                       prevent it from causing a motion change event false positive */
                    set uDex.prevX = GetUnitX(u)
                    set uDex.prevY = GetUnitY(u)
                else
                    debug if not uDex.flag then
                        debug call debug("|CFFFF0000Operator []= error: Attempt unregister an already unregistered instance|R")
                        debug return
                    debug endif
                    call GroupRemoveUnit(sensorGroup, u)
                    if IsUnitInGroup(u, SENSOR_GROUP_MOVING) then
                        call GroupRemoveUnit(SENSOR_GROUP_MOVING, u)
                    else
                        call GroupRemoveUnit(SENSOR_GROUP_STATIONARY, u)
                    endif
                    /* If sensorGroup is empty, stop iterating */
                    if enabled and FirstOfGroup(sensorGroup) == null then
                        call PauseTimer(tempTimer)
                    endif
                    set uDex.moving = false
                    set uDex.deltaX = 0.00
                    set uDex.deltaY = 0.00
                    set uDex.prevX = 0.00
                    set uDex.prevY = 0.00
                    set uDex.speed = 0.00
                    set uDex.direction = 0.00
                endif
                set uDex.flag = flag
            debug else
                debug call debug("|CFFFF0000Operator []= error: Attempt to register a null unit|R")
            endif
        endmethod

        static method addMotionChangeEvent takes code c returns triggercondition
            return TriggerAddCondition(trig[0], Filter(c))
        endmethod

        static method addOnMoveEvent takes code c returns triggercondition
            return TriggerAddCondition(trig[1], Filter(c))
        endmethod

        static method addOnStopEvent takes code c returns triggercondition
            return TriggerAddCondition(trig[2], Filter(c))
        endmethod

        static method removeMotionChangeEvent takes triggercondition tc returns nothing
            call TriggerRemoveCondition(trig[0], tc)
        endmethod

        static method removeOnMoveEvent takes triggercondition tc returns nothing
            call TriggerRemoveCondition(trig[1], tc)
        endmethod

        static method removeOnStopEvent takes triggercondition tc returns nothing
            call TriggerRemoveCondition(trig[2], tc)
        endmethod

        static if AUTO_REGISTER_UNITS then
            private static method addUnit takes nothing returns nothing
                set thistype[GetIndexedUnit()] = true
            endmethod
        endif

        private static method removeUnit takes nothing returns nothing
            set thistype[GetIndexedUnit()] = false
        endmethod

        implement Init

    endstruct

    private module Init
        private static method onInit takes nothing returns nothing
            local code add = function thistype.addUnit
            local code remove = function thistype.removeUnit
            static if LIBRARY_TimerUtils then
                set tempTimer = NewTimer()
            else
                set tempTimer = CreateTimer()
            endif
            static if AUTO_REGISTER_UNITS then
                call OnUnitIndex(add)
            endif
            call OnUnitDeindex(remove)
            /* Turn on Sensor */
            set enabled = true
            set trig[0] = CreateTrigger()
            set trig[1] = CreateTrigger()
            set trig[2] = CreateTrigger()
            call TriggerRegisterVariableEvent(trig[0], "s__Sensor_motionEvent", EQUAL, 1.00)
            call TriggerRegisterVariableEvent(trig[1], "s__Sensor_newMotionState", EQUAL, MOTION_STATE_MOVING)
            call TriggerRegisterVariableEvent(trig[2], "s__Sensor_newMotionState", EQUAL, MOTION_STATE_STATIONARY)
        endmethod
    endmodule

    /*===================================================================================================*/

    function RegisterMotionChangeEvent takes code c returns triggercondition
        return Sensor.addMotionChangeEvent(c)
        return null
    endfunction

    function RegisterOnMoveEvent takes code c returns triggercondition
        return Sensor.addOnMoveEvent(c)
        return null
    endfunction

    function RegisterOnStopEvent takes code c returns triggercondition
        return Sensor.addOnStopEvent(c)
        return null
    endfunction

    function RemoveMotionChangeEvent takes triggercondition tc returns nothing
        call Sensor.removeMotionChangeEvent(tc)
    endfunction

    function RemoveOnMoveEvent takes triggercondition tc returns nothing
        call Sensor.removeOnMoveEvent(tc)
    endfunction

    function RemoveOnStopEvent takes triggercondition tc returns nothing
        call Sensor.removeOnStopEvent(tc)
    endfunction

    function SensorAddUnit takes unit u returns nothing
        set Sensor[u] = true
    endfunction

    function SensorRemoveUnit takes unit u returns nothing
        set Sensor[u] = false
    endfunction

    function GetMotionChangingUnit takes nothing returns unit
        return Sensor.triggerUnit
    endfunction

    function GetNewMotionState takes nothing returns real
        return Sensor.newMotionState
    endfunction

    function GetInstantaneousSpeed takes unit u returns real
        return Sensor[u].speed
    endfunction

    function GetUnitDeltaX takes unit u returns real
        return Sensor[u].deltaX
    endfunction

    function GetUnitDeltaY takes unit u returns real
        return Sensor[u].deltaY
    endfunction

    function GetUnitPreviousX takes unit u returns real
        return Sensor[u].prevX
    endfunction

    function GetUnitPreviousY takes unit u returns real
        return Sensor[u].prevY
    endfunction

    function GetMotionDirection takes unit u returns real
        return Sensor[u].direction
    endfunction

    function IsUnitMoving takes unit u returns boolean
        return Sensor[u].moving
    endfunction

    function IsUnitSensored takes unit u returns boolean
        return Sensor[u].flag
    endfunction

    function MotionSensorEnable takes nothing returns nothing
        set Sensor.enabled = true
    endfunction

    function MotionSensorDisable takes nothing returns nothing
        set Sensor.enabled = false
    endfunction

    function IsSensorEnabled takes nothing returns boolean
        return Sensor.enabled
    endfunction


endlibrary
