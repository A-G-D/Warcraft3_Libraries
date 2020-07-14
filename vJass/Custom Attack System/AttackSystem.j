library RangedAttackProjectile /* v1.2.0 by AGD


    */uses /*

    */DamageEngine                      /*
    */Missile                           /*  https://www.hiveworkshop.com/threads/265370/
    */Table                             /*  https://www.hiveworkshop.com/threads/188084/
    */LinkedList                        /*  https://www.hiveworkshop.com/threads/325635/
    */UnitDex                           /*  https://www.hiveworkshop.com/threads/248209/
    */GetClosestWidget                  /*  https://www.hiveworkshop.com/threads/204217/
    */ImageStruct                       /*  https://www.hiveworkshop.com/threads/271099/

    */optional RegisterPlayerUnitEvent  /*  https://www.hiveworkshop.com/threads/250266/
    */optional ErrorMessage             /*  https://github.com/nestharus/JASS/tree/master/jass/Systems/ErrorMessage/main.j/


    [Resource Thread] :     https://www.hiveworkshop.com/threads/307417/


    *///! novjass

    |-------------|
    | Description |
    |-------------|
    /*
        A fully functional alternative attack system made to closely mimic the behavior of the
        default Warcraft 3 attack system. Below are some pros and cons of this system compared
        to the game's default attack system:

        Pros:
            - All fields can be changed dynamically (range, acquisition range, projectile speed, etc.)
            - Full control over the lauched attacks' stats (damage, attacktype, damagetype, Missile,
              etc., which is OP :D)
            - Events for the various phases in the attacking process
            - Can retrieve the 'raw', unaltered damage of an attack
            - Attacks can have negative damage amount, in which case, the target will be healed
            - Projectiles of ranged attacks can have > 1 special effects attached

        Cons:
            - The synchronization of the unit's attack animation and the attack release is not as
              flawless as the default attack system
            - Retrieving the current order of an actively attacking unit does not return "attack"
              nor "channel" (which is the order of the dummy attack ability used)
            - You need to manually set the units' attack cooldown

        Known Issues:
            - Ethereal units, by the time they lose their ethereal status, will only auto-attack/
              auto-acquire targets after the next order given to them is finished

        Common practical issues that can easily be solved using this system:
            - Custom Evasion
            - Custom Critical Strike / Bash (without redundantly triggering a damage event)
            - Easily configuring a split shot and bounce (like Moon Glaive) attacks
            - Combination of split shot and bounce attacks (Ex: Three projectiles, each bouncing twice
              per attack)
            - Differentiation between melee and ranged attacks

    */

    |-----------|
    | Importing |
    |-----------|
    /*
        1. Install all the required libraries listed above
        2. Paste this library into your map
        3. Read the API documentation and configure the system settings below (Important!)

    */

    |-----|
    | API |
    |-----|
    /*
        Attack Event Types

      */constant integer EVENT_ATTACK_MISSILE_LAUNCH/*
        - Fires when a ranged unit releases its projectile (the event EVENT_ATTACK_FINISH fires before this one)
      */constant integer EVENT_ATTACK_MISSILE_IMPACT/*
        - Fires when a projectile impacts the target (Including those bounce targets)
      */constant integer EVENT_ATTACK_MISSILE_BOUNCE/*
        - Fires when a projectile bounces off a unit (the event EVENT_ATTACK_MISSILE_IMPACT fires before this one)
      */constant integer EVENT_ATTACK_MISSILE_DESTROY/*
        - Fires when an attack instance is destroyed, whether explicitly or implicitly

      */struct CustomAttack extends array/*

          */readonly static CustomAttack triggerInstance/*  Event response
          */readonly static Attack triggerAttack        /*  Event response

          */readonly unit unit                          /*  The unit corresponding to this CustomAttack instance
          */readonly widget target                      /*  The current target widget
          */readonly unit targetUnit                    /*  The current target unit
          */readonly item targetItem                    /*  The current target item
          */readonly destructable targetDestructable    /*  The current target destructable
          */readonly real targetX                       /*  The x-coordinate of the current target point
          */readonly real targetY                       /*  The y-coordinate of the current target point
          */boolean enabled                             /*  Determines if the unit's attack is enabled
          */boolean melee                               /*  Determines if the unit's attacks are melee
          */boolean showShadow                          /*  Determines if the unit's attacks' missiles' shadow is visible
          */integer maxTargets                          /*  The maximum number of targets when attacking (for split-shot)
          */integer maxBounces                          /*  The maximum number of bounces the unit's attacks
          */real acquisitionRange                       /*  The target acquisition range
          */real range                                  /*  The attack range
          */real bounceRange                            /*  The projectile bounce range
          */real cooldown                               /*  The attack cooldown in seconds (cooldown countdown starts after EVENT_ATTACK_FINISH fires)
          */real damagePoint                            /*  The attack damage point in seconds
          */real launchX                                /*  The x-offset of the projectile launch location on the unit's rotating coordinate system
          */real launchY                                /*  The y-offset of the projectile launch location on the unit's rotating coordinate system
          */real launchZ                                /*  The z-offset of the projectile launch location from the unit's origin
          */real impactZ                                /*  The z-offset of the projectile impact location from the target's origin
          */real arc                                    /*  The launch angle of a projectile from the ground (in radians)
          */real speed                                  /*  The speed of the projectile
          */real minSpeed                               /*  The minimum speed of a projectile
          */real maxSpeed                               /*  The maximum speed of a projectile
          */real acceleration                           /*  The acceleration of a projectile
          */real scale                                  /*  The scale of the projectile
          */real minDamage                              /*  The low-bound of the attack damage
          */real maxDamage                              /*  The high-bound of the attack damage
          */attacktype attacktype                       /*  The unit's attacktype
          */damagetype damagetype                       /*  The unit's damagetype
          */weapontype weapontype                       /*  The unit's weapontype
          */string model                                /*  The model of the projectile

          */static method   operator []             takes unit whichUnit                            returns CustomAttack/*
            - Returns the CustomAttack instance of a unit

          */static method   isUnitRegistered        takes unit whichUnit                            returns boolean/*

          */static method   register                takes unit whichUnit                            returns nothing/*
          */static method   unregister              takes unit whichUnit                            returns nothing/*
            - Registers/Unregisters a unit to/from the system

          */static method   registerEventHandler    takes integer whichEvent, code handlerFunc      returns nothing/*
          */static method   unregisterEventHandler  takes integer whichEvent, code handlerFunc      returns nothing/*
          */static method   clearEventHandlers      takes integer whichEvent                        returns nothing/*
            - Event handler methods

          */method          addAttackSfx            takes string model                              returns this/*
          */method          removeAttackSfx         takes string model                              returns this/*
          */method          clearAttackSfx          takes nothing                                   returns this/*
            - Allows you to dynamically add as many number of special effects as you like to the projectile of a ranged attacker


      */struct Attack extends array/*

          */readonly boolean flag                       /*  Returns false if this Attack is destroyed/inactive
          */readonly boolean main                       /*  Determines if this is an attack to the main target (Returns false for the Attacks for other split-shot targets)
          */readonly boolean landed                     /*  Determines if the Attack's target successfully passes the filter condition at the time the Attack impacts the target
          */readonly boolean melee                      /*  Determines if this is a melee Attack
          */readonly boolean ranged                     /*  Determines if this is a ranged Attack
          */readonly integer currentBounces             /*  The current number of bounces of the projectile
          */readonly real x                             /*  The current x-coordinate
          */readonly real y                             /*  The current y-coordinate
          */readonly real z                             /*  The current z-coordinate (absolute)
          */readonly unit source                        /*  The source unit of this Attack
          */widget target                               /*  The target widget of this Attack
          */unit targetUnit                             /*  The target unit of this Attack
          */item targetItem                             /*  The target item of this Attack
          */destructable targetDestructable             /*  The target destructable of this Attack
          */real targetX                                /*  The target x-coordinate (You can only edit this value if target == null)
          */real targetY                                /*  The target y-coordinate (You can only edit this value if target == null)
          */real targetZ                                /*  The target z-coordinate (absolute) (You can only edit this value if target == null)
          */real damage                                 /*  The raw damage amount of this Attack
          */integer maxBounces                          /*  The maximum number of projectile bounces
          */real bounceRange                            /*  The projectile bounce range
          */real speed                                  /*  The projectile speed of a ranged Attack
          */real minSpeed                               /*  The minimum possible speed
          */real maxSpeed                               /*  The maximum possible speed
          */real acceleration                           /*  The acceleration of a ranged Attack
          */real scale                                  /*  The scale value of a ranged Attack
          */real arc                                    /*  The arcing movement of a ranged Attack
          */attacktype attacktype                       /*  The attacktype
          */damagetype damagetype                       /*  The damagetype
          */weapontype weapontype                       /*  The weapontype
          */boolean showShadow                          /*  Determines if an Attack's shadow is visible

          */static method   create      takes unit source, widget target, boolean isMainAttack, boolean fireEvent   returns Attack/*
            - Manually allocate an Attack without the need to check for the source unit's attack cooldown and range limitations
            - Also works for units' whose custom attacks are disabled
            - Does not play the source unit's attack animation nor interrupts the unit's current order
          */method          destroy     takes nothing                                                               returns nothing/*
            - Force destroys an Attack

          */method          addSfx      takes string model                                                          returns this/*
          */method          removeSfx   takes string model                                                          returns this/*
          */method          clearSfx    takes nothing                                                               returns this/*
            - Adds/Removes a model to/from a ranged Attack


        Wrapper Functions

          */function GetEventAttackDamage               takes nothing                                       returns real/*
          */function GetEventAttackSource               takes nothing                                       returns unit/*
          */function GetEventAttackTarget               takes nothing                                       returns widget/*
          */function GetEventAttackMaxBounces           takes nothing                                       returns integer/*
          */function GetEventAttackCurrentBounces       takes nothing                                       returns integer/*
          */function GetEventAttackTargetUnit           takes nothing                                       returns unit/*
          */function GetEventAttackTargetItem           takes nothing                                       returns item/*
          */function GetEventAttackTargetDestructable   takes nothing                                       returns destructable/*
          */function GetEventAttackTargetX              takes nothing                                       returns real/*
          */function GetEventAttackTargetY              takes nothing                                       returns real/*
          */function GetEventAttackTargetZ              takes nothing                                       returns real/*
          */function GetEventAttackMissileSpeed         takes nothing                                       returns real/*
          */function GetEventAttackMissileAcceleration  takes nothing                                       returns real/*
          */function GetEventAttackMissileScale         takes nothing                                       returns real/*
          */function GetEventAttackMissileArc           takes nothing                                       returns real/*
          */function GetEventAttackType                 takes nothing                                       returns attacktype/*
          */function GetEventDamageType                 takes nothing                                       returns damagetype/*
          */function GetEventWeaponType                 takes nothing                                       returns weapontype/*
          */function IsEventAttackMelee                 takes nothing                                       returns boolean/*
          */function IsEventAttackRanged                takes nothing                                       returns boolean/*
          */function IsEventAttackMain                  takes nothing                                       returns boolean/*

          */function DestroyEventAttack                 takes nothing                                       returns nothing/*
          */function SetEventAttackDamage               takes real damage                                   returns nothing/*
          */function SetEventAttackTarget               takes widget target                                 returns nothing/*
          */function SetEventAttackTargetUnit           takes unit target                                   returns nothing/*
          */function SetEventAttackTargetItem           takes item target                                   returns nothing/*
          */function SetEventAttackTargetDestructable   takes destructable target                           returns nothing/*
          */function SetEventAttackTargetX              takes real targetX                                  returns nothing/*
          */function SetEventAttackTargetY              takes real targetY                                  returns nothing/*
          */function SetEventAttackTargetZ              takes real targetZ                                  returns nothing/*
          */function SetEventAttackMissileSpeed         takes real speed                                    returns nothing/*
          */function SetEventAttackMissileMinSpeed      takes real speed                                    returns nothing/*
          */function SetEventAttackMissileMaxSpeed      takes real speed                                    returns nothing/*
          */function SetEventAttackMissileAcceleration  takes real acceleration                             returns nothing/*
          */function SetEventAttackMissileScale         takes real scale                                    returns nothing/*
          */function SetEventAttackMissileArc           takes real arc                                      returns nothing/*
          */function SetEventAttackType                 takes attacktype whichAttackType                    returns nothing/*
          */function SetEventDamageType                 takes damagetype whichDamageType                    returns nothing/*
          */function SetEventWeaponType                 takes weapontype whichWeaponType                    returns nothing/*

          */function GetUnitAttackDamageMin             takes unit whichUnit                                returns real/*
          */function GetUnitAttackDamageMax             takes unit whichUnit                                returns real/*
          */function GetUnitAttackType                  takes unit whichUnit                                returns attacktype/*
          */function GetUnitDamageType                  takes unit whichUnit                                returns damagetype/*
          */function GetUnitWeaponType                  takes unit whichUnit                                returns weapontype/*
          */function GetUnitAttackModel                 takes unit whichUnit                                returns string/*
          */function GetUnitAttackDamagePoint           takes unit whichUnit                                returns real/*
          */function GetUnitAttackCooldown              takes unit whichUnit                                returns real/*
          */function GetUnitAttackRange                 takes unit whichUnit                                returns real/*
          */function GetUnitAttackAcquireRange          takes unit whichUnit                                returns real/*
          */function GetUnitAttackMissileSpeed          takes unit whichUnit                                returns real/*
          */function GetUnitAttackMissileMinSpeed       takes unit whichUnit                                returns real/*
          */function GetUnitAttackMissileMaxSpeed       takes unit whichUnit                                returns real/*
          */function GetUnitAttackLaunchX               takes unit whichUnit                                returns real/*
          */function GetUnitAttackLaunchY               takes unit whichUnit                                returns real/*
          */function GetUnitAttackLaunchZ               takes unit whichUnit                                returns real/*
          */function GetUnitAttackImpactZ               takes unit whichUnit                                returns real/*
          */function GetUnitAttackMaxTargets            takes unit whichUnit                                returns integer/*
          */function GetUnitAttackMaxBounces            takes unit whichUnit                                returns integer/*
          */function GetUnitAttackTarget                takes unit whichUnit                                returns widget/*
          */function GetUnitAttackTargetUnit            takes unit whichUnit                                returns unit/*
          */function GetUnitAttackTargetItem            takes unit whichUnit                                returns item/*
          */function GetUnitAttackTargetDestructable    takes unit whichUnit                                returns destructable/*
          */function IsUnitAttackShadowVisible          takes unit whichUnit                                returns boolean/*
          */function IsUnitAttackMelee                  takes unit whichUnit                                returns boolean/*
          */function IsUnitAttackRanged                 takes unit whichUnit                                returns boolean/*

          */function SetUnitAttackDamageMin             takes unit whichUnit, real amount                   returns nothing/*
          */function SetUnitAttackDamageMax             takes unit whichUnit, real amount                   returns nothing/*
          */function SetUnitAttackType                  takes unit whichUnit, attacktype whichAttackType    returns nothing/*
          */function SetUnitDamageType                  takes unit whichUnit, damagetype whichDamageType    returns nothing/*
          */function SetUnitWeaponType                  takes unit whichUnit, weapontype whichWeaponType    returns nothing/*
          */function SetUnitAttackModel                 takes unit whichUnit, string modelPath              returns nothing/*
          */function SetUnitAttackDamagePoint           takes unit whichUnit, real damagePoint              returns nothing/*
          */function SetUnitAttackCooldown              takes unit whichUnit, real cooldown                 returns nothing/*
          */function SetUnitAttackRange                 takes unit whichUnit, real range                    returns nothing/*
          */function SetUnitAttackAcquireRange          takes unit whichUnit, real acquireRange             returns nothing/*
          */function SetUnitAttackMissileSpeed          takes unit whichUnit, real missileSpeed             returns nothing/*
          */function SetUnitAttackMissileMinSpeed       takes unit whichUnit, real missileSpeed             returns nothing/*
          */function SetUnitAttackMissileMaxSpeed       takes unit whichUnit, real missileSpeed             returns nothing/*
          */function SetUnitAttackLaunchX               takes unit whichUnit, real launchX                  returns nothing/*
          */function SetUnitAttackLaunchY               takes unit whichUnit, real launchY                  returns nothing/*
          */function SetUnitAttackLaunchZ               takes unit whichUnit, real launchZ                  returns nothing/*
          */function SetUnitAttackImpactZ               takes unit whichUnit, real impactZ                  returns nothing/*
          */function SetUnitAttackMaxTargets            takes unit whichUnit, integer maxTargets            returns nothing/*
          */function SetUnitAttackMaxBounces            takes unit whichUnit, integer maxBounces            returns nothing/*
          */function SetUnitAttackShadowVisible         takes unit whichUnit, boolean visible               returns nothing/*
          */function SetUnitAttackMelee                 takes unit whichUnit                                returns nothing/*
          */function SetUnitAttackRanged                takes unit whichUnit                                returns nothing/*
          */function UnitAddAttackEffect                takes unit whichUnit, string model                  returns nothing/*
          */function UnitRemoveAttackEffect             takes unit whichUnit, string model                  returns nothing/*
          */function UnitClearAttackEffect              takes unit whichUnit                                returns nothing/*

          */function UnitCustomAttackEnable             takes unit whichUnit                                returns nothing/*
          */function UnitCustomAttackDisable            takes unit whichUnit                                returns nothing/*
          */function IsUnitCustomAttackEnabled          takes unit whichUnit                                returns boolean/*

          */function RegisterAttackEventHandler         takes integer whichEvent, code handler              returns nothing/*
          */function UnregisterAttackEventHandler       takes integer whichEvent, code handler              returns nothing/*

          */function UnitCustomAttackRegister           takes unit whichUnit                                returns nothing/*
          */function UnitCustomAttackUnregister         takes unit whichUnit                                returns nothing/*
          */function IsUnitCustomAttackRegistered       takes unit whichUnit                                returns boolean/*


    *///! endnovjass

    /*==============================================================================*/
    /*                             SYSTEM CONFIGURATION                             */
    /*==============================================================================*/
    private module SystemConstants
        /*
        *   The image path for the attack missiles' shadow
        */
        static constant string MISSILE_SHADOW                   = "ReplaceableTextures\\Shadows\\Shadow.blp"
        /*
        *   The diameter of the attack missiles' shadow
        */
        static constant real MISSILE_SHADOW_SIZE                = 70.00
        /*
        *   The attack missiles' alpha value
        */
        static constant integer MISSILE_SHADOW_ALPHA            = 0x60
        /*
        *   The attack missiles' red value
        */
        static constant integer MISSILE_SHADOW_RED              = 0xFF
        /*
        *   The attack missiles' green value
        */
        static constant integer MISSILE_SHADOW_GREEN            = 0xFF
        /*
        *   The attack missiles' blue value
        */
        static constant integer MISSILE_SHADOW_BLUE             = 0xFF
    endmodule
    /*
    *   This set of values are automatically applied when a unit is registered to the system
    *   This module is optional and you can delete it if you don't need it
    */
    private module SystemDefaults
        set this.melee                                  = true
        set this.showShadow                             = false
        set this.maxTargets                             = 1
        set this.maxBounces                             = 0
        set this.acquisitionRange                       = 1000.00
        set this.range                                  = 600.00
        set this.bounceRange                            = 500.00
        set this.cooldown                               = 1.00
        set this.damagePoint                            = 0.35
        set this.launchX                                = 0.00
        set this.launchY                                = 20.00
        set this.launchZ                                = 60.00
        set this.impactZ                                = 60.00
        set this.arc                                    = 0.00
        set this.speed                                  = 1000000.00
        set this.minSpeed                               = 0.00
        set this.maxSpeed                               = 1000000.00
        set this.acceleration                           = 0.00
        set this.scale                                  = 1.00
        set this.model                                  = ""
        set this.attacktype                             = ATTACK_TYPE_HERO
        set this.damagetype                             = DAMAGE_TYPE_NORMAL
        set this.weapontype                             = WEAPON_TYPE_WHOKNOWS
        set this.minDamage                              = 0.00
        set this.maxDamage                              = 0.00
    endmodule
    /*
    *   This value is used to set the animation scale of an attacking unit.
    *   Ideally, this value should vary for different unit types so you might
    *   want to store those values into a hashtable/Table and make this function
    *   work this those values.
    *
    *   Example: return animationTable[GetUnitTypeId(this.unit)]/Pow(this.damagePoint, 1.00/1.18)
    */
    private function GetAttackAnimationScale takes CustomAttack this returns real
        return 0.35/Pow(this.damagePoint, 1.00/1.18)    // Be careful when changing this
    endfunction
    /*==============================================================================*/
    /*                         END OF SYSTEM CONFIGURATION                          */
    /*==============================================================================*/


    /*================================ System Code =================================*/
    native UnitAlive takes unit u returns boolean

    globals

        constant integer EVENT_ATTACK_START             = 0xABC + 0xAB*0
        constant integer EVENT_ATTACK_FINISH            = 0xABC + 0xAB*1
        constant integer EVENT_ATTACK_MISSILE_LAUNCH    = 0xABC + 0xAB*2
        constant integer EVENT_ATTACK_MISSILE_IMPACT    = 0xABC + 0xAB*3
        constant integer EVENT_ATTACK_MISSILE_BOUNCE    = 0xABC + 0xAB*4
        constant integer EVENT_ATTACK_DESTROY           = 0xABC + 0xAB*5

		private timer missileTimer                      = CreateTimer()
        private CustomAttack eventInstance              = 0
        private Attack eventAttack                      = 0
        private TableArray sfxTable
        private key KEY
        private timer tempTimer
        private code onPeriodCode
        private unit tempUnit
        private item tempItem
        private destructable tempDest
        private integer array sfxCount
        private boolean array doFireEvent
        private unit dummyUnit

    endglobals

    private keyword Initializer
    private keyword Node

    static if DEBUG_MODE then
        private function DebugError takes boolean condition, string methodName, string objectName, integer object, string message returns nothing
            static if LIBRARY_ErrorMessage then
                call ThrowError(condition, SCOPE_PREFIX, methodName, objectName, object, message)
            else
                if condition then
                    call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 60, "[" + SCOPE_PREFIX + "] ERROR: " + message)
                    call PauseGame(true)
                    if 1/0 == 0 then
                    endif
                endif
            endif
        endfunction

        private function DebugWarning takes boolean condition, string methodName, string objectName, integer object, string message returns nothing
            static if LIBRARY_ErrorMessage then
                call ThrowWarning(condition, SCOPE_PREFIX, methodName, objectName, object, message)
            else
                if condition then
                    call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 60, "[" + SCOPE_PREFIX + "] WARNING: " + message)
                endif
            endif
        endfunction
    endif

    private function GetUnitZ takes unit u returns real
        return Missile_GetLocZ(GetUnitX(u), GetUnitY(u)) + GetUnitFlyHeight(u)
    endfunction

    private function GetWidgetCollision takes widget w returns real
        local integer index
        set Table(KEY).widget[0] = w
        set index = GetUnitId(Table(KEY).unit[0])
        call Table(KEY).handle.remove(0)
        return BlzGetUnitCollisionSize(GetUnitById(index))
    endfunction

    private function WidgetToUnit takes widget w returns unit
        set Table(KEY).widget[0] = w
        return Table(KEY).unit[0]
    endfunction

    private function IsWidgetRemoved takes widget w returns boolean
        set Table(KEY).widget[0] = w
        set tempUnit = Table(KEY).unit[0]
        set tempItem = Table(KEY).item[0]
        set tempDest = Table(KEY).destructable[0]
        call Table(KEY).handle.remove(0)
        if tempUnit != null then
            return GetUnitTypeId(tempUnit) == 0
        elseif tempItem != null then
            return GetItemTypeId(tempItem) == 0
        elseif tempDest != null then
            return GetDestructableTypeId(tempDest) == 0
        endif
        return true
    endfunction

    private function DealDamage takes Attack attack, widget target, boolean ranged returns nothing
        local unit u = attack.source
        local boolean sourceRemoved = GetUnitTypeId(u) == 0
        local player prevOwner
        /*
        *   If the original source unit was removed, set the source to another valid unit. Otherwise, no damage will be dealt.
        */
        if sourceRemoved then
            set u = dummyUnit
            set prevOwner = GetOwningPlayer(u)
            call SetUnitOwner(u, Player(AttackData(attack).ownerId), false)
        endif
        if attack.damage < 0.00 then
            call SetWidgetLife(target, GetWidgetLife(target) - attack.damage + 0.001)
            /*
            *   If the damage is negative, it's still needed to deal damage to the target to maintain the desired
            *   behavior of an attacked target (ex: units with 'build' ability should retreat from the attacker)
            */
            call UnitDamageTarget(u, target, 0.001, true, ranged, attack.attacktype, attack.damagetype, attack.weapontype)
        else
            call UnitDamageTarget(u, target, attack.damage, true, ranged, attack.attacktype, attack.damagetype, attack.weapontype)
        endif
        if sourceRemoved then
            call SetUnitOwner(u, prevOwner, false)
            set prevOwner = null
        endif
        set u = null
    endfunction

    /*
    *   Event triggers are only created when there are handlers registered to the event.
    */
    private struct EventHandler extends array

        private static TableArray table
        private integer handlerCount
        private trigger handlerTrigger
        debug private string eventName

        static method operator [] takes thistype this returns trigger
            return thistype((this - 0xABC)/0xAB).handlerTrigger
        endmethod

        method register takes code c returns nothing
            local boolexpr expr = Filter(c)
            set this = (this - 0xABC)/0xAB
            debug call DebugError((this) < 0 or (this) > 5, "AttackSystem", "registerEventHandler()", "null", this, "Invalid input event type")
            debug call DebugError(c == null, "AttackSystem", "registerEventHandler()", this.eventName, 0, "Attempted to register a null code")
            debug call DebugError(table[this].handle.has(GetHandleId(expr)), "AttackSystem", "registerEventHandler()", this.eventName, 0, "Attemped to register a code twice")
            if this.handlerCount == 0 then
                set this.handlerTrigger = CreateTrigger()
            endif
            set this.handlerCount = this.handlerCount + 1
            set table[this].triggercondition[GetHandleId(expr)] = TriggerAddCondition(this.handlerTrigger, expr)
            set expr = null
        endmethod
        method unregister takes code c returns nothing
            local boolexpr expr = Filter(c)
            local integer exprId
            set this = (this - 0xABC)/0xAB
            debug call DebugError((this) < 0 or (this) > 5, "AttackSystem", "unregisterEventHandler()", "null", this, "Invalid input event type")
            debug call DebugError(c == null, "AttackSystem", "unregisterEventHandler()", this.eventName, 0, "Attempted to unregister a null code")
            debug call DebugError(not table[this].handle.has(GetHandleId(expr)), "AttackSystem", "unregisterEventHandler()", this.eventName, 0, "Attemped to unregister a code twice")
            set this.handlerCount = this.handlerCount - 1
            if this.handlerCount == 0 then
                call table[this].handle.remove(GetHandleId(expr))
                call DestroyTrigger(this.handlerTrigger)
                set this.handlerTrigger = null
            else
                set exprId = GetHandleId(expr)
                call TriggerRemoveCondition(this.handlerTrigger, table[this].triggercondition[exprId])
                call table[this].handle.remove(exprId)
            endif
            set expr = null
        endmethod
        method clear takes nothing returns nothing
            set this = (this - 0xABC)/0xAB
            debug call DebugError((this) < 0 or (this) > 5, "AttackSystem", "clearEventHandlers()", "null", this, "Invalid input event type")
            call DestroyTrigger(this.handlerTrigger)
            call table[this].flush()
            set this.handlerTrigger = null
            set this.handlerCount = 0
        endmethod

        static method init takes nothing returns nothing
            set table = TableArray[6]
            debug set thistype(0).eventName = "EVENT_ATTACK_START"
            debug set thistype(1).eventName = "EVENT_ATTACK_FINISH"
            debug set thistype(2).eventName = "EVENT_ATTACK_MISSILE_LAUNCH"
            debug set thistype(3).eventName = "EVENT_ATTACK_MISSILE_IMPACT"
            debug set thistype(4).eventName = "EVENT_ATTACK_MISSILE_BOUNCE"
            debug set thistype(5).eventName = "EVENT_ATTACK_DESTROY"
        endmethod

    endstruct

    private function FireHandler takes integer eventType, CustomAttack instance, Attack attack returns nothing
        local Attack prevAttack = eventAttack
        local CustomAttack prevInstance = eventInstance
        set eventInstance = instance
        set eventAttack = attack
        call TriggerEvaluate(EventHandler[eventType])
        set eventAttack = prevAttack
        set eventInstance = prevInstance
    endfunction

    private struct AttackData extends array

        static TableArray table
        boolean flag
        boolean main
        boolean landed
        unit source
        unit targetUnit
        item targetItem
        destructable targetDest
        integer currentBounces
        real minSpeed
        real maxSpeed
		integer ownerId
        Image shadow
        boolean shadowFlag

        method operator missile takes nothing returns Missile
            return this
        endmethod

        method operator target takes nothing returns widget
            if this.targetUnit != null then
                return this.targetUnit
            elseif this.targetItem != null then
                return this.targetItem
            elseif this.targetDest != null then
                return this.targetDest
            endif
            return null
        endmethod
        method operator target= takes widget whichWidget returns nothing
            if whichWidget == null then
                set this.targetUnit = null
                set this.targetItem = null
                set this.targetDestructable = null
            else
                set Table(KEY).widget[0] = whichWidget
                set this.targetUnit = Table(KEY).unit[0]
                set this.targetItem = Table(KEY).item[0]
                set this.targetDestructable = Table(KEY).destructable[0]
                call Table(KEY).handle.remove(0)
            endif
        endmethod

        static method create takes real x, real y, real z, real scale, real arc, widget target returns thistype
            local thistype this = Missile.createXYZ(x, y, z, GetWidgetX(target), GetWidgetY(target), GetWidgetHeight(target))
            set this.missile.scale = scale
            set this.missile.arc = arc
            set this.target = target
            call launch(this.missile)
            return this
        endmethod

        method destroy takes nothing returns nothing
            call FireHandler(EVENT_ATTACK_MISSILE_DESTROY, GetUnitId(this.source), this)
            if this.shadow != 0 then
                call this.shadow.destroy()
                set this.shadow = 0
            endif
            set this.shadowFlag = false
            call this.missile.destroy()
            set this.source = null
            set this.targetUnit = null
            set this.targetItem = null
            set this.targetDestructable = null
        endmethod

        private static method onRemove takes Missile missile returns boolean
            call missile.instance.destroy()
            return false
        endmethod

        private static method onFinish takes Missile missile returns boolean
            local Attack prevAttack = triggerAttack
            local thistype prevInstance = triggerInstance
            local thistype attack = instance[missile]
            local widget target = attack.target
            set attack.landed = target != null
            set eventInstance = thistype[attack.source]
            set eventAttack = attack
            call TriggerEvaluate(EventHandler[EVENT_ATTACK_MISSILE_IMPACT])
            set target = attack.target
            if attack.landed and target != null then
                call DealDamage(attack, target, true)
            endif
            set target = null
            if attack.targetUnit != null and attack.landed and attack.currentBounces < Attack(attack).maxBounces then
                set attack.currentBounces = attack.currentBounces + 1
                set filterUnit = attack.targetUnit
                set attack.targetUnit = thistype[attack.source].getClosestTargetInRange(attack.x, attack.y, Attack(attack).bounceRange)
                set filterUnit = null
                if attack.targetUnit != null then
                    set attack.targetX = GetUnitX(attack.targetUnit)
                    set attack.targetY = GetUnitY(attack.targetUnit)
                    set attack.targetZ = GetUnitZ(attack.targetUnit)
                    call attack.missile.impact.move(GetUnitX(attack.targetUnit), GetUnitY(attack.targetUnit), GetUnitZ(attack.targetUnit))
                    call attack.missile.boounce()
                    call TriggerEvaluate(EventHandler[EVENT_ATTACK_MISSILE_BOUNCE])
                    set eventAttack = prevAttack
                    set eventInstance = prevInstance
                    return false
                endif
            endif
            set eventAttack = prevAttack
            set eventInstance = prevInstance
            return true
        endmethod

        private static method onPeriod takes Missile missile returns boolean
            local real x = GetWidgetX(target)
            local real y = GetWidgetY(target)
            call missile.impact.move(x, y, Missile_GetLocZ(x, y) + GetWidgetHeight(target))
            call missile.bounce()
        endmethod

        implement MissileStruct

        static method init takes nothing returns nothing
            set table = TableArray[JASS_MAX_ARRAY_SIZE - 1]
        endmethod

    endstruct

    /*
    *   An Attack's data is set by the time it is launched. By that time, it becomes
    *   independent from the stats of its source unit.
    */
    struct AttackMissile extends array

        real damage
        real bounceRange
        integer maxBounces
        attacktype attacktype
        damagetype damagetype
        weapontype weapontype

        private method operator data takes nothing returns AttackData
            return this
        endmethod

        method operator missile takes nothing returns Missile
            return this.data.missile
        endmethod

        method operator flag takes nothing returns boolean
            return this.data.flag
        endmethod

        method operator main takes nothing returns boolean
            return this.data.main
        endmethod

        method operator landed takes nothing returns boolean
            return this.data.landed
        endmethod

        method operator targetX= takes real x returns nothing
            if this.data.target == null then
                set this.data.targetX = x
            endif
        endmethod
        method operator targetX takes nothing returns real
            return this.data.targetX
        endmethod

        method operator targetY= takes real y returns nothing
            if this.data.target == null then
                set this.data.targetY = y
            endif
        endmethod
        method operator targetY takes nothing returns real
            return this.data.targetY
        endmethod

        method operator targetZ= takes real z returns nothing
            if this.data.target == null then
                set this.data.targetZ = z
            endif
        endmethod
        method operator targetZ takes nothing returns real
            return this.data.targetZ
        endmethod

        method operator source takes nothing returns unit
            return this.data.source
        endmethod

        method operator targetUnit= takes unit whichUnit returns nothing
            set this.data.targetUnit = whichUnit
        endmethod
        method operator targetUnit takes nothing returns unit
            return this.data.targetUnit
        endmethod

        method operator targetItem= takes item whichItem returns nothing
            set this.data.targetItem = whichItem
        endmethod
        method operator targetItem takes nothing returns item
            return this.data.targetItem
        endmethod

        method operator targetDest= takes destructable whichDestructable returns nothing
            set this.data.targetDest = whichDestructable
        endmethod
        method operator targetDest takes nothing returns destructable
            return this.data.targetDest
        endmethod

        method operator target= takes widget whichWidget returns nothing
            set this.data.target = whichWidget
        endmethod
        method operator target takes nothing returns widget
            return this.data.target
        endmethod

        method operator speed= takes real value returns nothing
            set this.data.missile.minSpeed = value
        endmethod
        method operator speed takes nothing returns real
            return this.data.missile.minSpeed
        endmethod

        method operator minSpeed= takes real value returns nothing
            set this.data.minSpeed = value
        endmethod
        method operator minSpeed takes nothing returns real
            return this.data.minSpeed
        endmethod

        method operator maxSpeed= takes real value returns nothing
            set this.data.maxSpeed = value
        endmethod
        method operator maxSpeed takes nothing returns real
            return this.data.maxSpeed
        endmethod

        method operator acceleration= takes real value returns nothing
            set this.data.missile.acceleration = value
        endmethod
        method operator acceleration takes nothing returns real
            return this.data.missile.acceleration
        endmethod

        method operator scale= takes real scale returns nothing
            set this.data.missile.scale = scale
        endmethod
        method operator scale takes nothing returns real
            return this.data.missile.scale
        endmethod

        method operator arc= takes real value returns nothing
            set Node(this).missile.arc = value
        endmethod
        method operator arc takes nothing returns real
            return Node(this).missile.arc
        endmethod

        method operator currentBounces takes nothing returns integer
            return Node(this).currentBounces
        endmethod

        method operator showShadow= takes boolean show returns nothing
            if show then
                if not Node(this).shadowFlag and Node.table[this][0] > 0 then
                    set Node(this).shadow = Image.create(CustomAttack.MISSILE_SHADOW, CustomAttack.MISSILE_SHADOW_SIZE, CustomAttack.MISSILE_SHADOW_SIZE, this.x - CustomAttack.MISSILE_SHADOW_SIZE*0.50, this.y - CustomAttack.MISSILE_SHADOW_SIZE*0.50, 0.00, IMAGE_TYPE_INDICATOR, true)
                    call Node(this).shadow.wrap(true)
                    call SetImageColor(Node(this).shadow.img, CustomAttack.MISSILE_SHADOW_RED, CustomAttack.MISSILE_SHADOW_GREEN, CustomAttack.MISSILE_SHADOW_BLUE, CustomAttack.MISSILE_SHADOW_ALPHA)
                endif
            elseif Node(this).shadowFlag and Node(this).shadow != 0 then
                call Node(this).shadow.destroy()
                set Node(this).shadow = 0
            endif
            set Node(this).shadowFlag = show
        endmethod
        method operator showShadow takes nothing returns boolean
            return Node(this).shadowFlag
        endmethod

        method setColor takes integer alpha, integer red, integer green, integer blue returns nothing
            local SpecialEffect sfx = this.data.missile.effect
            loop
                exitwhen sfx.moveIterator()
                call BlzSetSpecialEffectAlpha(sfx.currentHandle(), alpha)
                call BlzSetSpecialEffectColor(sfx.currentHandle(), red, green, blue)
            endloop
        endmethod

        method setTimeScale takes real value returns nothing
            local SpecialEffect sfx = AttackData(this).missile.effect
            loop
                exitwhen sfx.moveIterator()
                call BlzSetSpecialEffectTimeScale(Node.table[this].effect[index], value)
            endloop
        endmethod

        static method create takes unit source, widget target, boolean mainAttack, boolean fireEvent returns thistype
            local CustomAttack instance = GetUnitId(source)
            local real deltaAngle = bj_PI/2.00 - GetUnitFacing(source)*bj_DEGTORAD
            local integer count = 0
            local boolean success = true
            local Node attack
            set Table(KEY).widget[0] = target
            set tempUnit = Table(KEY).unit[0]
            set tempItem = Table(KEY).item[0]
            set tempDest = Table(KEY).destructable[0]
            if tempUnit != null then
                set attack = Node.create(true, GetUnitX(source) + instance.launchX*Cos(deltaAngle) + instance.launchY*Sin(deltaAngle), GetUnitY(source) + instance.launchY*Cos(deltaAngle) - instance.launchX*Sin(deltaAngle), BlzGetLocalUnitZ(source) + instance.launchZ, instance.scale, instance.arc, tempUnit)
                set attack.targetUnit = tempUnit
            elseif tempItem != null then
                set attack = Node.create(true, GetUnitX(source) + instance.launchX*Cos(deltaAngle) + instance.launchY*Sin(deltaAngle), GetUnitY(source) + instance.launchY*Cos(deltaAngle) - instance.launchX*Sin(deltaAngle), BlzGetLocalUnitZ(source) + instance.launchZ, instance.scale, instance.arc, tempItem)
                set attack.targetItem = tempItem
            elseif tempDest != null then
                set attack = Node.create(true, GetUnitX(source) + instance.launchX*Cos(deltaAngle) + instance.launchY*Sin(deltaAngle), GetUnitY(source) + instance.launchY*Cos(deltaAngle) - instance.launchX*Sin(deltaAngle), BlzGetLocalUnitZ(source) + instance.launchZ, instance.scale, instance.arc, tempDest)
                set attack.targetDest = tempDest
            else
                set success = false
            endif
            if success then
                set attack.main = mainAttack
                set Attack(attack).showShadow   = instance.showShadow
                set attack.ownerId              = GetPlayerId(GetOwningPlayer(source))
                set attack.source               = source
                set attack.currentBounces       = 0
                set Attack(attack).damage       = GetRandomReal(instance.minDamage, instance.maxDamage)
                set Attack(attack).bounceRange  = instance.bounceRange
                set Attack(attack).maxBounces   = instance.maxBounces
                set Attack(attack).attacktype   = instance.attacktype
                set Attack(attack).damagetype   = instance.damagetype
                set Attack(attack).weapontype   = instance.weapontype
                set attack.speed                = instance.speed
                set attack.minSpeed             = instance.minSpeed
                set attack.maxSpeed             = instance.maxSpeed
                set attack.acceleration         = instance.acceleration
                call attack.addSfx(instance.model)
                set count = sfxCount[instance]
                loop
                    exitwhen count == 0
                    call attack.addSfx(sfxTable[instance].string[count])
                    set count = count - 1
                endloop
                if fireEvent then
                    if mainAttack then
                        call FireHandler(EVENT_ATTACK_FINISH, instance, attack)
                    endif
                    call FireHandler(EVENT_ATTACK_MISSILE_LAUNCH, instance, attack)
                endif
            endif
            return attack
        endmethod
        method destroy takes nothing returns nothing
            debug call DebugError(Node(this).flag, "AttackSystem", "destroy()", "thistype", 0, "Double-free")
            call Node(this).destroy()
        endmethod

    endstruct

    /*
    *   Main system struct
    */
    struct CustomAttack extends array

        implement SystemConstants

        private static group ENUM_GROUP = CreateGroup()
        private static real maxCollision = 0.00
        private boolean registered
        boolean melee
        boolean showShadow
        integer maxTargets
        integer maxBounces
        real bounceRange
        real acquisitionRange
        real range
        real cooldown
        real damagePoint
        real launchX
        real launchY
        real launchZ
        real impactZ
        real arc
        real speed
        real minSpeed
        real maxSpeed
        real acceleration
        real scale
		real minDamage
		real maxDamage
        attacktype attacktype
        damagetype damagetype
        weapontype weapontype
        string model

        static method operator triggerInstance takes nothing returns thistype
            return eventInstance
        endmethod
        static method operator triggerAttack takes nothing returns Attack
            return eventAttack
        endmethod

        static method operator [] takes unit u returns thistype
            return GetUnitId(u)
        endmethod

        static method isUnitRegistered takes unit u returns boolean
            return thistype[u].registered
        endmethod

        method operator unit takes nothing returns unit
            return GetUnitById(this)
        endmethod

        private method getClosestTargetInRange takes real x, real y, real radius returns unit
            local unit closest
            local unit attacker = GetUnitById(this)
            call GroupEnumUnitsInRange(ENUM_GROUP, x, y, radius + maxCollision, null)
            set radius = radius + BlzGetUnitCollisionSize(attacker)*0.50
            loop
                set closest = GetClosestUnitInGroup(x, y, ENUM_GROUP)
                exitwhen closest == null
                call GroupRemoveUnit(ENUM_GROUP, closest)
                if closest != attacker and closest != filterUnit and IsUnitInRangeXY(closest, x, y, radius) and IsUnitEnemy(closest, GetOwningPlayer(attacker)) and TargetUnitFilter(attacker, closest) then
                    set this = GetUnitId(closest)
                    call GroupClear(ENUM_GROUP)
                    set closest = null
                    set attacker = null
                    return GetUnitById(this)
                endif
            endloop
            set attacker = null
            return null
        endmethod

        private method launchProjectile takes unit targetUnit, item targetItem, destructable targetDest, boolean isMainAttack returns nothing
            local unit attacker = GetUnitById(this)
            local real deltaAngle = bj_PI/2.00 - GetUnitFacing(attacker)*bj_DEGTORAD
            local integer count
            local real x
            local real y
            local AttackData attack
            if targetUnit != null then
                set attack = AttackData.create(true, GetUnitX(attacker) + this.launchX*Cos(deltaAngle) + this.launchY*Sin(deltaAngle), GetUnitY(attacker) + this.launchY*Cos(deltaAngle) - this.launchX*Sin(deltaAngle), BlzGetLocalUnitZ(attacker) + this.launchZ, this.scale, this.arc, targetUnit)
                set attack.targetUnit = targetUnit
            elseif targetItem != null then
                set attack = AttackData.create(true, GetUnitX(attacker) + this.launchX*Cos(deltaAngle) + this.launchY*Sin(deltaAngle), GetUnitY(attacker) + this.launchY*Cos(deltaAngle) - this.launchX*Sin(deltaAngle), BlzGetLocalUnitZ(attacker) + this.launchZ, this.scale, this.arc, targetItem)
                set attack.targetItem = targetItem
            elseif targetDest != null then
                set attack = AttackData.create(true, GetUnitX(attacker) + this.launchX*Cos(deltaAngle) + this.launchY*Sin(deltaAngle), GetUnitY(attacker) + this.launchY*Cos(deltaAngle) - this.launchX*Sin(deltaAngle), BlzGetLocalUnitZ(attacker) + this.launchZ, this.scale, this.arc, targetDest)
                set attack.targetDest = targetDest
            endif
            set attack.main = isMainAttack
            set Attack(attack).showShadow = this.showShadow
            set attack.source = attacker
            set attack.currentBounces = 0
            set Attack(attack).damage = GetRandomReal(this.minDamage, this.maxDamage)
            set Attack(attack).bounceRange = this.bounceRange
            set Attack(attack).maxBounces = this.maxBounces
            set Attack(attack).attacktype = this.attacktype
            set Attack(attack).damagetype = this.damagetype
            set Attack(attack).weapontype = this.weapontype
            set attack.speed = this.speed
            set attack.minSpeed = this.minSpeed
            set attack.maxSpeed = this.maxSpeed
            set attack.acceleration = this.acceleration
            call attack.addModel(this.model)
            set count = sfxCount[this]
            loop
                exitwhen count == 0
                call attack.missile.addModel(sfxTable[this].string[count])
                set count = count - 1
            endloop
            call FireHandler(EVENT_ATTACK_MISSILE_LAUNCH, this, attack)
            set attacker = null
        endmethod

        private static method onAttackMissileLaunch takes nothing returns nothing
            local thistype this = Table(KEY)[GetHandleId(expired)]
            local unit attacker = GetUnitById(this)
            local integer count = this.maxTargets
            local real range = BlzGetUnitWeaponRealField(attacker, UNIT_WEAPON_RF_ATTACK_RANGE, 0)
            local unit picked
            local real damage
            local real x
            local real y
            local thistype prevInstance
            local Node prevAttack
            if count > 0 then
                call this.launchProjectile(this.targetUnit, this.targetItem, this.targetDestructable, true) then
                call FireHandler(EVENT_ATTACK_FINISH, this, 0)
                set count = count - 1
                if count > 0 then
                    set x = GetUnitX(attacker)
                    set y = GetUnitY(attacker)
                    call GroupEnumUnitsInRange(ENUM_GROUP, x, y, range + BlzGetUnitCollisionSize(attacker) + maxCollision, null)
                    loop
                        set picked = GetClosestUnitInGroup(x, y, ENUM_GROUP)
                        exitwhen picked == null or count == 0
                        call GroupRemoveUnit(ENUM_GROUP, picked)
                        if picked != attacker and picked != this.targetUnit and IsUnitInRange(attacker, picked, range) and IsUnitEnemy(picked, GetOwningPlayer(attacker)) then
                            set count = count - 1
                            call this.launchProjectile(picked, null, null, false)
                        endif
                    endloop
                    if picked != null then
                        call GroupClear(ENUM_GROUP)
                        set picked = null
                    endif
                endif
            endif
            set attacker = null
        endmethod

        method addAttackModel takes string model returns thistype
            local integer key = StringHash(model)
            if not sfxTable[this].has(key) then
                set sfxCount[this] = sfxCount[this] + 1
                set sfxTable[this].string[sfxCount[this]] = model
                set sfxTable[this][key] = sfxCount[this]
            debug else
                debug call DebugWarning(true, "AttackSystem", "addAttackSfx()", "thistype", this, "The specified model string was already added [" + model + "]")
            endif
            return this
        endmethod
        method removeAttackModel takes string model returns thistype
            local integer key = StringHash(model)
            local integer index = sfxTable[this][key]
            if index > 0 then
                set sfxTable[this].string[index] = sfxTable[this].string[sfxCount[this]]
                call sfxTable[this].string.remove(sfxCount[this])
                call sfxTable[this].remove(key)
                set sfxCount[this] = sfxCount[this] - 1
            debug else
                debug call DebugWarning(true, "AttackSystem", "removeAttackSfx()", "thistype", this, "The specified model string was not yet added [" + model + "]")
            endif
            return this
        endmethod
        method clearAttackModels takes nothing returns thistype
            set sfxCount[this] = 0
            call sfxTable[this].flush()
            return this
        endmethod

        method operator enabled takes nothing returns boolean
            return <>
        endmethod
        method operator enabled= takes boolean flag returns nothing
            if this.registered then
                if flag then
                    if not this.enabled then
                        call BlzUnitDisableAbility(this.unit, ATTACK_ABIL_ID, false, false)
                    endif
                elseif this.enabled then
                    call BlzUnitDisableAbility(this.unit, ATTACK_ABIL_ID, true, false)
                endif
            endif
        endmethod

        static method register takes unit u returns boolean
            local thistype this = GetUnitId(u)
            if not this.registered then
                call BlzUnitDisableAbility(u, 'Aatk', true, true)
                call UnitAddAbility(u, ATTACK_ABIL_ID)
                call BlzUnitDisableAbility(u, ATTACK_ABIL_ID, true, false)
                set this.registered = true
                set this.enabled = true
                implement optional SystemDefaults
                return true
            endif
            return false
        endmethod
        static method unregister takes unit u returns boolean
            local thistype this = GetUnitId(u)
            if this.registered then
                set this.registered = false
                if this.enabled then
                    call UnitRemoveAbility(u, ATTACK_ABIL_ID)
                endif
                call BlzUnitDisableAbility(u, 'Aatk', false, false)
                call this.clearAttackSfx()
                set this.targetUnit = null
                set this.targetItem = null
                set this.targetDestructable = null
                set this.melee = false
                set this.maxTargets = 0
                set this.maxBounces = 0
                set this.acquisitionRange = 0.00
                set this.range = 0.00
                set this.bounceRange = 0.00
                set this.cooldown = 0.00
                set this.damagePoint = 0.00
                set this.launchX = 0.00
                set this.launchY = 0.00
                set this.launchZ = 0.00
                set this.impactZ = 0.00
                set this.arc = 0.00
                set this.speed = 0.00
                set this.minSpeed = 0.00
                set this.maxSpeed = 0.00
                set this.acceleration = 0.00
                set this.scale = 0.00
                set this.minDamage = 0.00
                set this.maxDamage = 0.00
                set this.attacktype = null
                set this.damagetype = null
                set this.weapontype = null
                set this.model = ""
                return true
            endif
            return false
        endmethod

        static method registerEventHandler takes EventHandler eventHandler, code handlerFunc returns nothing
            call eventHandler.register(handlerFunc)
        endmethod
        static method unregisterEventHandler takes EventHandler eventHandler, code handlerFunc returns nothing
            call eventHandler.unregister(handlerFunc)
        endmethod
        static method clearEventHandlers takes EventHandler eventHandler returns nothing
            call eventHandler.clear()
        endmethod

        private static method onIndex takes nothing returns nothing
            set maxCollision = RMaxBJ(BlzGetUnitCollisionSize(GetIndexedUnit()), maxCollision)
        endmethod
        private static method onDeindex takes nothing returns nothing
            call unregister(GetIndexedUnit())
        endmethod

        private static method init takes nothing returns nothing
            local code onIndex = function thistype.onIndex
            local code onDeindex = function thistype.onDeindex
            call OnUnitIndex(onIndex)
            call OnUnitDeindex(onDeindex)
            call TriggerRegisterDamageEngineEx(DamageTrigger[function thistype.onAttackMissileLaunch], "udg_DamageEvent", 1.00, DamageEngine_FILTER_RANGED)
            set dummyUnit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'ncop', 0.00, 0.00, 0.00)
            call SetUnitVertexColor(dummyUnit, 0, 0, 0, 0)
            call UnitRemoveAbility(dummyUnit, 'Amov')
            call UnitRemoveAbility(dummyUnit, 'Aatk')
            call UnitAddAbility(dummyUnit, 'Aloc')
        endmethod
        implement Initializer

    endstruct

    private module Initializer
        private static method onInit takes nothing returns nothing
            set sfxTable = TableArray[JASS_MAX_ARRAY_SIZE - 1]
            call EventHandler.init()
            call Node.init()
            call CustomAttack.init()
        endmethod
    endmodule

    /*
    *   Wrapper Functions
    */
    function GetEventAttackDamage takes nothing returns real
        return CustomAttack.triggerAttack.damage
    endfunction
    function GetEventAttackSource takes nothing returns unit
        return CustomAttack.triggerAttack.source
    endfunction
    function GetEventAttackTarget takes nothing returns widget
        return CustomAttack.triggerAttack.target
    endfunction
    function GetEventAttackMaxBounces takes nothing returns integer
        return CustomAttack.triggerAttack.maxBounces
    endfunction
    function GetEventAttackCurrentBounces takes nothing returns integer
        return CustomAttack.triggerAttack.currentBounces
    endfunction
    function GetEventAttackTargetUnit takes nothing returns unit
        return CustomAttack.triggerAttack.targetUnit
    endfunction
    function GetEventAttackTargetItem takes nothing returns item
        return CustomAttack.triggerAttack.targetItem
    endfunction
    function GetEventAttackTargetDestructable takes nothing returns destructable
        return CustomAttack.triggerAttack.targetDestructable
    endfunction
    function GetEventAttackTargetX takes nothing returns real
        return CustomAttack.triggerAttack.targetX
    endfunction
    function GetEventAttackTargetY takes nothing returns real
        return CustomAttack.triggerAttack.targetY
    endfunction
    function GetEventAttackTargetZ takes nothing returns real
        return CustomAttack.triggerAttack.targetZ
    endfunction
    function GetEventAttackMissileSpeed takes nothing returns real
        return CustomAttack.triggerAttack.speed
    endfunction
    function GetEventAttackMissileMinSpeed takes nothing returns real
        return CustomAttack.triggerAttack.minSpeed
    endfunction
    function GetEventAttackMissileMaxSpeed takes nothing returns real
        return CustomAttack.triggerAttack.maxSpeed
    endfunction
    function GetEventAttackMissileAcceleration takes nothing returns real
        return CustomAttack.triggerAttack.acceleration
    endfunction
    function GetEventAttackMissileScale takes nothing returns real
        return CustomAttack.triggerAttack.scale
    endfunction
    function GetEventAttackMissileArc takes nothing returns real
        return CustomAttack.triggerAttack.arc
    endfunction
    function GetEventAttackType takes nothing returns attacktype
        return CustomAttack.triggerAttack.attacktype
    endfunction
    function GetEventDamageType takes nothing returns damagetype
        return CustomAttack.triggerAttack.damagetype
    endfunction
    function GetEventWeaponType takes nothing returns weapontype
        return CustomAttack.triggerAttack.weapontype
    endfunction
    function IsEventAttackMelee takes nothing returns boolean
        return CustomAttack.triggerAttack.melee
    endfunction
    function IsEventAttackRanged takes nothing returns boolean
        return CustomAttack.triggerAttack.ranged
    endfunction
    function IsEventAttackMain takes nothing returns boolean
        return CustomAttack.triggerAttack.main
    endfunction

    function DestroyEventAttack takes nothing returns nothing
        call CustomAttack.triggerAttack.destroy()
    endfunction
    function SetEventAttackDamage takes real damage returns nothing
        set CustomAttack.triggerAttack.damage = damage
    endfunction
    function SetEventAttackTarget takes widget target returns nothing
        set CustomAttack.triggerAttack.target = target
    endfunction
    function SetEventAttackTargetUnit takes unit target returns nothing
        set CustomAttack.triggerAttack.targetUnit = target
    endfunction
    function SetEventAttackTargetItem takes item target returns nothing
        set CustomAttack.triggerAttack.targetItem = target
    endfunction
    function SetEventAttackTargetDestructable takes destructable target returns nothing
        set CustomAttack.triggerAttack.targetDestructable = target
    endfunction
    function SetEventAttackTargetX takes real x returns nothing
        set CustomAttack.triggerAttack.targetX = x
    endfunction
    function SetEventAttackTargetY takes real y returns nothing
        set CustomAttack.triggerAttack.targetY = y
    endfunction
    function SetEventAttackTargetZ takes real z returns nothing
        set CustomAttack.triggerAttack.targetZ = z
    endfunction
    function SetEventAttackMissileSpeed takes real speed returns nothing
        set CustomAttack.triggerAttack.speed = speed
    endfunction
    function SetEventAttackMissileMinSpeed takes real speed returns nothing
        set CustomAttack.triggerAttack.minSpeed = speed
    endfunction
    function SetEventAttackMissileMaxSpeed takes real speed returns nothing
        set CustomAttack.triggerAttack.maxSpeed = speed
    endfunction
    function SetEventAttackMissileAcceleration takes real acceleration returns nothing
        set CustomAttack.triggerAttack.acceleration = acceleration
    endfunction
    function SetEventAttackMissileScale takes real scale returns nothing
        set CustomAttack.triggerAttack.scale = scale
    endfunction
    function SetEventAttackMissileArc takes real arc returns nothing
        set CustomAttack.triggerAttack.arc = arc
    endfunction
    function SetEventAttackType takes attacktype whichAttackType returns nothing
        set CustomAttack.triggerAttack.attacktype = whichAttackType
    endfunction
    function SetEventDamageType takes damagetype whichDamageType returns nothing
        set CustomAttack.triggerAttack.damagetype = whichDamageType
    endfunction
    function SetEventWeaponType takes weapontype whichWeaponType returns nothing
        set CustomAttack.triggerAttack.weapontype = whichWeaponType
    endfunction

    function GetUnitAttackDamage takes unit whichUnit returns real
        local CustomAttack unitAttack = CustomAttack[whichUnit]
        return (unitAttack.minDamage + unitAttack.maxDamage)*0.50
    endfunction
    function GetUnitAttackType takes unit whichUnit returns attacktype
        return CustomAttack[whichUnit].attacktype
    endfunction
    function GetUnitDamageType takes unit whichUnit returns damagetype
        return CustomAttack[whichUnit].damagetype
    endfunction
    function GetUnitWeaponType takes unit whichUnit returns weapontype
        return CustomAttack[whichUnit].weapontype
    endfunction
    function GetUnitAttackModel takes unit whichUnit returns string
        return CustomAttack[whichUnit].model
    endfunction
    function GetUnitAttackDamagePoint takes unit whichUnit returns real
        return CustomAttack[whichUnit].damagePoint
    endfunction
    function GetUnitAttackCooldown takes unit whichUnit returns real
        return CustomAttack[whichUnit].cooldown
    endfunction
    function GetUnitAttackRange takes unit whichUnit returns real
        return CustomAttack[whichUnit].range
    endfunction
    function GetUnitAttackAcquireRange takes unit whichUnit returns real
        return CustomAttack[whichUnit].acquisitionRange
    endfunction
    function GetUnitAttackMissileSpeed takes unit whichUnit returns real
        return CustomAttack[whichUnit].speed
    endfunction
    function GetUnitAttackMissileMinSpeed takes unit whichUnit returns real
        return CustomAttack[whichUnit].minSpeed
    endfunction
    function GetUnitAttackMissileMaxSpeed takes unit whichUnit returns real
        return CustomAttack[whichUnit].maxSpeed
    endfunction
    function GetUnitAttackLaunchX takes unit whichUnit returns real
        return CustomAttack[whichUnit].launchX
    endfunction
    function GetUnitAttackLaunchY takes unit whichUnit returns real
        return CustomAttack[whichUnit].launchY
    endfunction
    function GetUnitAttackLaunchZ takes unit whichUnit returns real
        return CustomAttack[whichUnit].launchZ
    endfunction
    function GetUnitAttackImpactZ takes unit whichUnit returns real
        return CustomAttack[whichUnit].impactZ
    endfunction
    function GetUnitAttackMaxTargets takes unit whichUnit returns integer
        return CustomAttack[whichUnit].maxTargets
    endfunction
    function GetUnitAttackMaxBounces takes unit whichUnit returns integer
        return CustomAttack[whichUnit].maxBounces
    endfunction
    function GetUnitAttackTarget takes unit whichUnit returns widget
        return CustomAttack[whichUnit].target
    endfunction
    function GetUnitAttackTargetUnit takes unit whichUnit returns unit
        return CustomAttack[whichUnit].targetUnit
    endfunction
    function GetUnitAttackTargetItem takes unit whichUnit returns item
        return CustomAttack[whichUnit].targetItem
    endfunction
    function GetUnitAttackTargetDestructable takes unit whichUnit returns destructable
        return CustomAttack[whichUnit].targetDestructable
    endfunction
    function IsUnitAttackShadowVisible takes unit whichUnit returns boolean
        return CustomAttack[whichUnit].showShadow
    endfunction
    function IsUnitAttackMelee takes unit whichUnit returns boolean
        return CustomAttack[whichUnit].melee
    endfunction
    function IsUnitAttackRanged takes unit whichUnit returns boolean
        return not CustomAttack[whichUnit].melee
    endfunction

    function SetUnitAttackDamageMin takes unit whichUnit, real amount returns nothing
        set CustomAttack[whichUnit].minDamage = amount
    endfunction
    function SetUnitAttackDamageMax takes unit whichUnit, real amount returns nothing
        set CustomAttack[whichUnit].maxDamage = amount
    endfunction
    function SetUnitAttackType takes unit whichUnit, attacktype whichAttackType returns nothing
        set CustomAttack[whichUnit].attacktype = whichAttackType
    endfunction
    function SetUnitDamageType takes unit whichUnit, damagetype whichDamageType returns nothing
        set CustomAttack[whichUnit].damagetype = whichDamageType
    endfunction
    function SetUnitWeaponType takes unit whichUnit, weapontype whichWeaponType returns nothing
        set CustomAttack[whichUnit].weapontype = whichWeaponType
    endfunction
    function SetUnitAttackModel takes unit whichUnit, string modelPath returns nothing
        set CustomAttack[whichUnit].model = modelPath
    endfunction
    function SetUnitAttackDamagePoint takes unit whichUnit, real damagePoint returns nothing
        set CustomAttack[whichUnit].damagePoint = damagePoint
    endfunction
    function SetUnitAttackCooldown takes unit whichUnit, real cooldown returns nothing
        set CustomAttack[whichUnit].cooldown = cooldown
    endfunction
    function SetUnitAttackRange takes unit whichUnit, real range returns nothing
        set CustomAttack[whichUnit].range = range
    endfunction
    function SetUnitAttackAcquireRange takes unit whichUnit, real acquireRange returns nothing
        set CustomAttack[whichUnit].acquisitionRange = acquireRange
    endfunction
    function SetUnitAttackMissileSpeed takes unit whichUnit, real missileSpeed returns nothing
        set CustomAttack[whichUnit].speed = missileSpeed
    endfunction
    function SetUnitAttackMissileMinSpeed takes unit whichUnit, real missileSpeed returns nothing
        set CustomAttack[whichUnit].minSpeed = missileSpeed
    endfunction
    function SetUnitAttackMissileMaxSpeed takes unit whichUnit, real missileSpeed returns nothing
        set CustomAttack[whichUnit].maxSpeed = missileSpeed
    endfunction
    function SetUnitAttackLaunchX takes unit whichUnit, real launchX returns nothing
        set CustomAttack[whichUnit].launchX = launchX
    endfunction
    function SetUnitAttackLaunchY takes unit whichUnit, real launchY returns nothing
        set CustomAttack[whichUnit].launchY = launchY
    endfunction
    function SetUnitAttackLaunchZ takes unit whichUnit, real launchZ returns nothing
        set CustomAttack[whichUnit].launchZ = launchZ
    endfunction
    function SetUnitAttackImpactZ takes unit whichUnit, real impactZ returns nothing
        set CustomAttack[whichUnit].impactZ = impactZ
    endfunction
    function SetUnitAttackMaxTargets takes unit whichUnit, integer maxTargets returns nothing
        set CustomAttack[whichUnit].maxTargets = maxTargets
    endfunction
    function SetUnitAttackMaxBounces takes unit whichUnit, integer maxBounces returns nothing
        set CustomAttack[whichUnit].maxBounces = maxBounces
    endfunction
    function SetUnitAttackShadowVisible takes unit whichUnit, boolean visible returns nothing
        set CustomAttack[whichUnit].showShadow = visible
    endfunction
    function SetUnitAttackMelee takes unit whichUnit returns nothing
        set CustomAttack[whichUnit].melee = true
    endfunction
    function SetUnitAttackRanged takes unit whichUnit returns nothing
        set CustomAttack[whichUnit].melee = false
    endfunction
    function UnitAddAttackEffect takes unit whichUnit, string model returns nothing
        call CustomAttack[whichUnit].addAttackSfx(model)
    endfunction
    function UnitRemoveAttackEffect takes unit whichUnit, string model returns nothing
        call CustomAttack[whichUnit].removeAttackSfx(model)
    endfunction
    function UnitClearAttackEffect takes unit whichUnit returns nothing
        call CustomAttack[whichUnit].clearAttackSfx()
    endfunction

    function RegisterAttackEventHandler takes integer whichEvent, code handler returns nothing
        call CustomAttack.registerEventHandler(whichEvent, handler)
    endfunction
    function UnregisterAttackEventHandler takes integer whichEvent, code handler returns nothing
        call CustomAttack.unregisterEventHandler(whichEvent, handler)
    endfunction

    function UnitCustomAttackEnable takes unit whichUnit returns nothing
        set CustomAttack[whichUnit].enabled = true
    endfunction
    function UnitCustomAttackDisable takes unit whichUnit returns nothing
        set CustomAttack[whichUnit].enabled = false
    endfunction
    function IsUnitCustomAttackEnabled takes unit whichUnit returns boolean
        return CustomAttack[whichUnit].enabled
    endfunction

    function UnitCustomAttackRegister takes unit whichUnit returns nothing
        call CustomAttack.register(whichUnit)
    endfunction
    function UnitCustomAttackUnregister takes unit whichUnit returns nothing
        call CustomAttack.unregister(whichUnit)
    endfunction
    function IsUnitCustomAttackRegistered takes unit whichUnit returns boolean
        return CustomAttack.isUnitRegistered(whichUnit)
    endfunction


endlibrary 