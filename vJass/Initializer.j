library Initializer


    //! novjass

    Author: AGD

    |=====|
    | API |
    |=====|

        |---------|
        | Modules |
        |---------|

        module Initializer/*
            - Looks for 'static method init' and calls it on map initialization
            - Looks for 'static method initEx' and starts a timer to run it after
              0.00 seconds on map initialization                                    */

        |------------|
        | Textmacros |
        |------------|

        //! runtextmacro INITIALIZER()
        //! runtextmacro END_INITIALIZER()
        /*  - Actions put between these textmacros are run on map initialization    */

    //! endnovjass

    module Initializer

        static if thistype.initEx.exists then
            private static method timerInit takes nothing returns nothing
                call initEx()
                call DestroyTimer(GetExpiredTimer())
            endmethod
        endif

        static if thistype.init.exists and thistype.initEx.exists then
            private static method onInit takes nothing returns nothing
                call init()
                call TimerStart(CreateTimer(), 0.00, false, function thistype.timerInit)
            endmethod
        elseif thistype.init.exists then
            private static method onInit takes nothing returns nothing
                call init()
            endmethod
        elseif thistype.initEx.exists then
            private static method onInit takes nothing returns nothing
                call TimerStart(CreateTimer(), 0.00, false, function thistype.timerInit)
            endmethod
        endif

    endmodule

    //! textmacro INITIALIZER
    private module InitializerModule
        private static method onInit takes nothing returns nothing
    //! endtextmacro

    //! textmacro END_INITIALIZER
        endmethod
    endmodule
    private struct InitializerStruct extends array
        implement InitializerModule
    endstruct
    //! endtextmacro


endlibrary
