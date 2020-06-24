//! novjass
/*
    This folder contains templates for spell-making using the various components of the SpellDevFramework Library.
    Multiple templates are given to accomodate the varying design categories of spells.

    |==================================================================================|
    | These are six (6) templates provided for making spells using the SpellEvent ONLY |
    |==================================================================================|

    Spell Template A:
        - In this template, we used the simplest form of spell as an example. The spell has no periodic operations
        and immediately performs its effects after cast.

    Spell Template B:
        - Uses the most common form of spell that we usually see in public spell resource submissions. The spell
        has a setup section (onSpellStart), periodic section (onSpellPeriodic), and a cleanup section (onSpellEnd).
        The spell has no child components and can easily be described using a single node that is created  after a
        spell is cast.

    Spell Template C:
        - This features a spell similar to that in Spell Template B but with the additional characteristic of being
        a channeled spell. The template showcases how it can easily accomodate channeling spells and the way it
        allows the developer to easily make the method of invoking the spell (in this case, thru channeling)
        configurable by the end users.

    Spell Template D:
        - The featured spell is another common format seen in public submissions. The spell has child components
        (could be one or more levels) that together, make up the overall characteristic of the spell. When the
        primary node (the spell instance) expires, all existing/remaining children nodes are destroyed alongside
        it.

    Spell Template E:
        - The featured spell is a bit similar to the one in Spell Template D. However, there are times when we want
        the children nodes to outlive the primary node. We can usually see this in spells that involve summoning
        a separate entity that in turn summons sub-entities over time. For example, a Turret summoning spell. The
        summoned Turret will periodically launch missiles towards enemy units within a certain radius. When the
        Turret expires, we don't want the remaining missiles still travelling to disappear also. Therefore, the
        missiles themselves need to be totally independent from their parent/primary node.

    Spell Template F:
        - The featured spell is not so common but still warrants a template :D. It usually has no significant
        operations concerning its primary node except that it creates multiple child components at the time of cast.
        Its components are usually the ones that provide the overall effect of the spell themselves. Due to this,
        we can easily disregard the primary node (not include it to the list for which the periodic operations run)
        and let its children do all the work.

    |================================================================================================|
    | These are three (3) templates provided for making spells using BOTH SpellEvent AND SpellCloner |
    |================================================================================================|

    Cloneable Spell Template A:
        - Here it feature a spell similar to that in Spell Template B, but using SpellCloner. The method of cloning
        applied here can also be applied to other spells featured in Spell Templates A-E.

    Cloneable Spell Template B:
        - Featured spell is similar to that used in Spell Template F, but using SpellCloner.

    Cloneable Spell Template C:
        - Featured spell is similar to that used in Cloneable Spell Template A, but only uses the 'SpellCloner'
        module unlike the usual 'SpellClonerHeader' + 'SpellClonerFooter' + 'SpellEvent' combination. This method
        also provides better automation when it comes to running the spells configuration setup.

*/
//! endnovjass