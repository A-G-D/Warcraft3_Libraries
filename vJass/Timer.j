library Timer /*


    */uses /*

    */Initializer  /*
    */ErrorMessage /*


    *///! novjass

    Credits:

        - AGD (Author)
        - Vexorian (For the TimerUtils where I got my inspiration of making my own version of the system)
        - Wieltol (For the nice idea of encapsullating timers)

    |=====|
    | API |
    |=====|

        struct Timer/*

          */static Timer new        /* Retrieves a new Timer
          */static Timer expired    /* Retrieves the expired Timer
          */Timer data              /* Retrieves the Timer custom data
          */real timeout            /* Retrieves the Timer timeout
          */real elapsed            /* Retrieves the Timer elapsed time
          */real remaining          /* Retrieves the Timer remaining time

          */static method operator [] takes integer data returns Timer/*
                - Retrives a new Timer with a custom data initialized
                  to <data>

          */method start takes real timeout, boolean periodic, code handlerFunction returns nothing/*
                - Starts a Timer instance, running <handlerFunction> after <timeout> seconds periodically
                  or not depending on the <periodic> boolean value

          */method free takes nothing returns Timer/*
                - Frees and stops a Timer instance and returns the Timer data

          */method stop takes nothing returns nothing/*
                - Stops a Timer instance

          */method pause takes nothing returns nothing/*
                - Pauses a Timer instance

          */method resume takes nothing returns nothing/*
                - Resumes a Timer instance

    *///! endnovjass

    globals
    /*  The total number of timers in the stack
        Maximum allowed value: 8190
        Suggested value range: 250 to 500        */
        private integer MAX_TIMER_COUNT = 256
    endglobals

    struct Timer extends array

        private static integer startHandle
        private static thistype alloc
        private timer timers
        private thistype recycler
        thistype data

        static method operator new takes nothing returns thistype
            debug call ThrowError(thistype(0).recycler == 0, "Timer", "new", "thistype", 0, "Attempted to allocate more than " + I2S(MAX_TIMER_COUNT) + " Timer instances")
            set alloc = thistype(0).recycler
            set thistype(0).recycler = alloc.recycler
            debug set alloc.recycler = -1
            return alloc
        endmethod

        static method operator [] takes integer data returns thistype
            set new.data = data
            return alloc
        endmethod

        method free takes nothing returns thistype
            local thistype data = this.data
            debug call ThrowError(this.recycler != -1, "Timer", "free()", "thistype", this, "Attempted to double free Timer")
            set this.recycler = thistype(0).recycler
            set thistype(0).recycler = this
            call PauseTimer(this.timers)
            set this.data = 0
            return data
        endmethod

        method start takes real timeout, boolean periodic, code c returns nothing
            debug call ThrowError(this.recycler != -1, "Timer", "start()", "thistype", this, "Attempted to start freed Timer")
            call TimerStart(this.timers, timeout, periodic, c)
        endmethod

        method stop takes nothing returns nothing
            debug call ThrowError(this.recycler != -1, "Timer", "stop()", "thistype", this, "Attempted to stop freed Timer")
            call TimerStart(this.timers, 0, false, null)
        endmethod

        method pause takes nothing returns nothing
            debug call ThrowError(this.recycler != -1, "Timer", "pause()", "thistype", this, "Attempted to pause freed Timer")
            call PauseTimer(this.timers)
        endmethod

        method resume takes nothing returns nothing
            debug call ThrowError(this.recycler != -1, "Timer", "resume()", "thistype", this, "Attempted to resume free Timer")
            call ResumeTimer(this.timers)
        endmethod

        method operator elapsed takes nothing returns real
            return TimerGetElapsed(this.timers)
        endmethod

        method operator remaining takes nothing returns real
            return TimerGetRemaining(this.timers)
        endmethod

        method operator timeout takes nothing returns real
            return TimerGetTimeout(this.timers)
        endmethod

        static method operator expired takes nothing returns thistype
            return GetHandleId(GetExpiredTimer()) - startHandle
        endmethod

        private static method init takes nothing returns nothing
            set alloc = thistype(1)
            set MAX_TIMER_COUNT = IMinBJ(8190, MAX_TIMER_COUNT)
            set thistype(1).timers = CreateTimer()
            set startHandle = GetHandleId(thistype(1).timers) - 1
            set thistype(0).recycler = 1
            set thistype(1).recycler = 2
            set thistype(MAX_TIMER_COUNT).recycler = 0
            loop
                set alloc = alloc + 1
                set alloc.timers = CreateTimer()
                exitwhen alloc == MAX_TIMER_COUNT
                set alloc.recycler = alloc + 1
            endloop
            debug call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 10, "|CFFFFCC00[Timer] : |RTimerStruct ready! (" + I2S(alloc) + " Timers available in stock)")
        endmethod
        implement Initializer

    endstruct


endlibrary
