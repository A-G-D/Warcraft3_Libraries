library SpellDevFramework /* https://www.hiveworkshop.com/threads/spell-development-framework-vjass-gui-v1-0-0.325448/


    */uses /*


    [FRAMEWORK CORE]
    The core of the spell development framework contains three components namely, SpellEvent, SpellEventGUI,
    and SpellCloner. SpellEvent and SpellCloner go hand in hand in creating an organized template for spell
    development in vJass.
    Below are VERY brief overview of the purpose of each component. A more intensive description of each one can
    be found on the header of each listed library.

    */SpellEvent                /*  https://www.hiveworkshop.com/threads/301895/
        SpellEvent handles and automates common spell-related tasks such as spell indexing and event registration.
        It further provides useful advanced features such as manual event invocation, event parameters overriding,
        and event cancelling. It also provides event response variables/functions that are intuitive to use and
        recursion-safe.

    */SpellCloner               /*  https://www.hiveworkshop.com/threads/324157/
        SpellCloner provides a framework for ensuring the maintainability of custom spells. It divides the
        custom spell into two sections namely, the spell mechanics, and the spell configuration. This provides
        convenience in updating the code for the spell mechanics without touching the configuration section.
        The spell configuration section can also contain more than one set of spell configurations - which is
        cool.

    */optional SpellEventGUI    /*
        The SpellEventGUI in itself is a framework specifically made for GUI developers. It is built upon the
        SpellEvent library, from which it derives many of its functionalities. It also provides utilities for
        other spell-related tasks that are not so convenient in GUI such as filtered unit-group enumeration.
        It also automatically handles channeling abilities interruption/finish for the spell developer unlike
        in its vJass counterpart where freedom in usage is given more priority over total automation.


    [UTILITY COMPONENTS]
    These components are included as they are almost always used in spell making. You can use your other libraries
    in place of these ones if you're already using similar ones. It does not matter if the API doesn't match as
    these components are not utilized internally by the framework core. They are purely for the user.

    */Alloc                     /*  https://www.hiveworkshop.com/threads/324937/
        Allocator module - compatible for recent patches with the updated JASS_MAX_ARRAY_SIZE
        You can also use any other Alloc if you prefer but be sure to update it to adapt to JASS_MAX_ARRAY_SIZE

    */LinkedList                /*  https://www.hiveworkshop.com/threads/325635/
        Library providing linked-list modules in different flavors


    [List of External Library Requirements]
        Required:
            > Table
            https://www.hiveworkshop.com/threads/188084/
        Optional:
            > RegisterPlayerUnitEvent
            https://www.hiveworkshop.com/threads/250266/
            > ResourcePreloader
            https://www.hiveworkshop.com/threads/287358/
            > ErrorMessage
            https://github.com/nestharus/JASS/blob/master/jass/Systems/ErrorMessage/main.j

*/
endlibrary