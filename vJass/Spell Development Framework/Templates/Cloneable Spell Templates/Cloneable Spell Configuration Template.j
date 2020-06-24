//! novjass
library <SpellName>ConfigurationModule /*


    */uses /*

    */SpellDevFramework /*
    */<SpellName>


    /*
    *   Configuration struct and its members are better to be public (Just use public keyword
    *   on struct for less collision). This would allow spell modifier systems running on
    *   generic spell events to be able to modify spells freely.
    */
    public struct Configuration1 extends array

        static constant integer SPELL_ABILITY_ID            = 'A000'
        static constant integer SPELL_EVENT_TYPE            = EVENT_SPELL_EFFECT
        static constant string STATIC_SFX_MODEL             = ""
        static constant string STATIC_SFX_ATTACHPOINT       = "origin"
        ...

        static method spellDuration takes integer level returns real
            return 10.00 + 0.00*level
        endmethod
        ...

        implement <SpellName>Configuration
    endstruct

    public struct Configuration2 extends array
        /*
        *   Activation ability ids can even be similar, in which case a single cast would
        *   activate two (or more) spells
        */
        static constant integer SPELL_ABILITY_ID            = 'A001'
        static constant integer SPELL_EVENT_TYPE            = EVENT_SPELL_EFFECT
        static constant string STATIC_SFX_MODEL             = ""
        static constant string STATIC_SFX_ATTACHPOINT       = "origin"
        ...

        static method spellDuration takes integer level returns real
            return 5.00 + 1.00*level
        endmethod
        ...

        implement <SpellName>Configuration
    endstruct

    ...


endlibrary
//! endnovjass