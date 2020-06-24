library CodeArray /*


    */requires /*

    */Typecast      /*
    */Table         /*
    */Initializer   /*

    |=====|
    | API |
    |=====|

        //! runtextmacro GLOBAL_CODE_ARRAY("PRIVACY", "NAME")
            - Declares a global code array

        //! runtextmacro GLOBAL_CODE_TABLE("PRIVACY", "NAME")
            - Declares a global code Table

    */
    //! textmacro GLOBAL_CODE_ARRAY takes PRIVACY, NAME
    $PRIVACY$ struct $NAME$ extends array

        private integer codes
        private static force tempForce

        static method operator [] takes thistype this returns code
            return I2C(.codes)
        endmethod

        static method operator []= takes thistype this, code c returns nothing
            set .codes = C2I(c)
        endmethod

        method run takes nothing returns nothing
            call ForForce(tempForce, I2C(.codes))
        endmethod

        private static method init takes nothing returns nothing
            set tempForce = bj_FORCE_PLAYER[0]
        endmethod

        implement Initializer

    endstruct
    //! endtextmacro

    //! textmacro GLOBAL_CODE_TABLE takes PRIVACY, NAME
    $PRIVACY$ struct $NAME$ extends array

        private static Table codes
        private static force tempForce

        static method operator [] takes integer index returns code
            return I2C(codes[index])
        endmethod

        static method operator []= takes integer index, code c returns nothing
            set codes[index] = C2I(c)
        endmethod

        method run takes nothing returns nothing
            call ForForce(tempForce, I2C(codes[this]))
        endmethod

        private static method init takes nothing returns nothing
            set codes = Table.create()
            set tempForce = bj_FORCE_PLAYER[0]
        endmethod

        implement Initializer

    endstruct
    //! endtextmacro


endlibrary
