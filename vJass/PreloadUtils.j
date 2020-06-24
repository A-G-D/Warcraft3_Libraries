library PreloadUtils /* v1.4b


    */uses /*

    */BJObjectId            /*   http://www.hiveworkshop.com/threads/bjobjectid.287128/
    */optional Table        /*   http://www.hiveworkshop.com/threads/snippet-new-table.188084/
    */optional UnitRecycler /*   http://www.hiveworkshop.com/threads/snippet-unit-recycler.286701/

    *///! novjass

    |================|
    | Written by AGD |
    |================|

        [CREDITS]
/*          IcemanBo - for suggesting further improvements
            Silvenon - for the sound preloading method                            */


        |-----|
        | API |
        |-----|

            function PreloadUnit takes integer rawcode returns nothing/*
                - Assigns a certain type of unit to be preloaded

          */function PreloadItem takes integer rawcode returns nothing/*
                - Assigns a certain type of item to be preloaded

          */function PreloadAbility takes integer rawcode returns nothing/*
                - Assigns a certain type of ability to be preloaded

          */function PreloadEffect takes string modelPath returns nothing/*
                - Assigns a certain type of effect to be preloaded

          */function PreloadSound takes string soundPath returns nothing/*
                - Assigns a certain type of sound to be preloaded


          */function PreloadUnitEx takes integer start, integer end returns nothing/*
                - Assigns a range of unit rawcodes to be preloaded

          */function PreloadItemEx takes integer start, integer end returns nothing/*
                - Assigns a range of item rawcodes to be preloaded

          */function PreloadAbilityEx takes integer start, integer end returns nothing/*
                - Assigns a range of ability rawcodes to be preloaded


    *///! endnovjass

    /*========================================================================================================*/
    /*            Do not try to change below this line if you're not so sure on what you're doing.            */
    /*========================================================================================================*/

    private keyword S


    static if DEBUG_MODE then
        private function Debug takes string msg returns nothing
            call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 60, "|CFFFFCC00[Resource Preloader]|R  " + msg)
        endfunction
    endif

    /*============================================== TextMacros ==============================================*/

    //! textmacro PRELOAD_TYPE takes NAME, ARG, TYPE, INDEX, I
    function Preload$NAME$ takes $ARG$ what returns nothing
        static if LIBRARY_Table then
            if not S.tb[$I$].boolean[$INDEX$] then
                set S.tb[$I$].boolean[$INDEX$] = true
                call Do$NAME$Preload(what)
            debug else
                debug call Debug("|CFFFF0000Operation Cancelled :|R Entered $TYPE$ data was already preloaded")
            endif
        else
            if not LoadBoolean(S.tb, $I$, $INDEX$) then
                call SaveBoolean(S.tb, $I$, $INDEX$, true)
                call Do$NAME$Preload(what)
            debug else
                debug call Debug("|CFFFF0000Operation Cancelled :|R Entered $TYPE$ data was already preloaded")
            endif
        endif
    endfunction
    //! endtextmacro

    //! textmacro RANGED_PRELOAD_TYPE takes NAME
    function Preload$NAME$Ex takes integer start, integer end returns nothing
        local BJObjectId this = BJObjectId(start)
        local BJObjectId last = BJObjectId(end)
        loop
            call Preload$NAME$(this)
            exitwhen this == last
            if this > last then
                set this = this.minus_1()
            else
                set this = this.plus_1()
            endif
        endloop
    endfunction
    //! endtextmacro

    /*========================================================================================================*/

    private function DoUnitPreload takes integer id returns nothing
        static if LIBRARY_UnitRecycler then
            call RecycleUnitEx(CreateUnit(Player(15), id, 0, 0, 270))
        else
            call RemoveUnit(CreateUnit(Player(15), id, 0, 0, 0))
        endif
    endfunction

    private function DoItemPreload takes integer id returns nothing
        call RemoveItem(UnitAddItemById(S.dummy, id))
    endfunction

    private function DoAbilityPreload takes integer id returns nothing
        if UnitAddAbility(S.dummy, id) and UnitRemoveAbility(S.dummy, id) then
        endif
    endfunction

    private function DoEffectPreload takes string path returns nothing
        call DestroyEffect(AddSpecialEffectTarget(path, S.dummy, "origin"))
    endfunction

    private function DoSoundPreload takes string path returns nothing
        local sound s = CreateSound(path, false, false, false, 10, 10, "")
        call SetSoundVolume(s, 0)
        call StartSound(s)
        call KillSoundWhenDone(s)
        set s = null
    endfunction

    //! runtextmacro PRELOAD_TYPE("Unit", "integer", "unit", "what", "0")
    //! runtextmacro PRELOAD_TYPE("Item", "integer", "item", "what", "1")
    //! runtextmacro PRELOAD_TYPE("Ability", "integer", "ability", "what", "2")
    //! runtextmacro PRELOAD_TYPE("Effect", "string", "effect", "StringHash(what)", "3")
    //! runtextmacro PRELOAD_TYPE("Sound", "string", "sound", "StringHash(what)", "4")

    //! runtextmacro RANGED_PRELOAD_TYPE("Unit")
    //! runtextmacro RANGED_PRELOAD_TYPE("Item")
    //! runtextmacro RANGED_PRELOAD_TYPE("Ability")

    /*========================================================================================================*/

    private module Init
        private static method onInit takes nothing returns nothing
            local rect world = GetWorldBounds()
            static if LIBRARY_Table then
                set tb = TableArray[5]
            endif
            set dummy = CreateUnit(Player(15), 'hpea', 0, 0, 0)
            call UnitAddAbility(dummy, 'AInv')
            call UnitAddAbility(dummy, 'Avul')
            call UnitRemoveAbility(dummy, 'Amov')
            call SetUnitY(dummy, GetRectMaxY(world) + 1000)
            call RemoveRect(world)
            set world = null
        endmethod
    endmodule

    private struct S extends array
        static if LIBRARY_Table then
            static TableArray tb
        else
            static hashtable tb = InitHashtable()
        endif
        static unit dummy
        implement Init
    endstruct


endlibrary


library ResourcePreloader requires PreloadUtils
endlibrary
