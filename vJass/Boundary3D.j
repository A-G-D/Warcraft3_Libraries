library Boundary3D /* v1.0.0 (Alpha).


    */uses /*

    */optional Alloc        /*
    */optional ErrorMessage /*


    *///! novjass

    |-----|
    | API |
    |-----|

        struct Boundary/*

        Nested Structs:

          */struct Sphere               extends Boundary
                static method create takes real ox, real oy, real oz, real r returns Sphere/*

          */struct Cube                 extends Boundary
                static method create takes real ox, real oy, real oz, real r returns Cube/*
              */static method createEx takes real ox, real oy, real oz, real s returns Cube/*

          */struct Ellipsoid.Normal     extends Boundary
                static method create takes real ox, real oy, real oz, real a, real b, real c returns Ellipsoid.Normal/*

          */struct Ellipsoid.Oblique    extends Boundary
                static method create takes real ox, real oy, real oz, real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk, real a, real b, real c returns Ellipsoid.Oblique/*

          */struct Prism.Normal         extends Boundary
                static method create takes real ox, real oy, real oz, real a, real b, real c returns Prism.Normal/*
              */static method createEx takes real minX, real minY, real minZ, real maxX, real maxY, real maxZ returns Prism.Normal/*

          */struct Prism.Oblique        extends Boundary
                static method create takes real ox, real oy, real oz, real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk, real a, real b, real c returns Prism.Oblique/*

          */struct Cone.Normal          extends Boundary
                static method create takes real ox, real oy, real oz, real a, real b, real h returns Cone.Normal/*
              */static method createEx takes real ox, real oy, real r, real minZ, real maxZ returns Cone.Normal/*

          */struct Cone.Oblique         extends Boundary
                static method create takes real ox, real oy, real oz, real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk, real r, real h returns Cone.Oblique/*

          */struct Cylinder.Normal      extends Boundary
                static method create takes real ox, real oy, real oz, real a, real b, real h returns Cylinder.Normal/*
              */static method createEx takes real ox, real oy, real r, real minZ, real maxZ returns Cylinder.Normal/*

          */struct Cylinder.Oblique     extends Boundary/*
              */static method create takes real ox, real oy, real oz, real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk, real r, real h returns Cylinder.Oblique/*

        Fields:

          */debug string typeName/*
                - The name of the shape of the Boundary

        Methods:

          */method destroy takes nothing returns nothing/*
                - Destructor

          */method contains takes real x, real y, real z returns boolean/*
                - Check if a position vector (x, y, z) is inside the Boundary instance

          */method move takes real x, real y, real z returns this/*
                - Moves the position of origin of the Boundary

          */method scale takes real a, real b, real c returns this/*
                - Scales the size of the dimensions of the Boundary in its local x, y, & z axes by a factor of a, b, & c
                  respectively

          */method rotate takes real i, real j, real k, real radians returns this/*
                - Rotates the local coordinates of the Boundary about the vector<i, j, k> by a certain amount in radians
                - Useful wrapper for .orient()

          */method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns this/*
                - Changes the direction as well as the scale of the x, y, & z axes on the Boundary's local coordinate system

          */method castTo takes integer boundaryTypeId returns this/*
                - Typecasts the Boundary into a different type

        Operators:

          */static method operator [] takes Boundary bounds returns Boundary/*
                - Copy constructor

    */
    |--------------|
    | Sample Usage |
    |--------------|

        local Boundary bounds = Boundary.Cone.Normal.create(x, y, z, coneRadius, coneHeight)

        debug call BJDebugMsg(bounds.typeName) // Displays "Cone"
        call GroupEnumUnitsInRange(enumGroup, x, y, coneRadius, null)
        loop
            set u = FirstOfGroup(enumGroup)
            exitwhen u == null
            call GroupRemoveUnit(enumGroup, u)
            /*
            *   Damage units inside cone
            */
            if bounds.contains(GetUnitX(u), GetUnitY(u), BlzGetLocalUnitZ(u)) then
                call UnitDamageTarget(source, u, coneDamage, true, false, ATTACK_TYPE_HERO, DAMAGE_TYPE_NORMAL, null)
            endif
        endloop

        call bounds.castTo(Boundary.Sphere.TYPE_ID) // transforms into a Sphere with a radius equal to <coneRadius>

        debug call BJDebugMsg(bounds.typeName) // Displays "Sphere"
        call GroupEnumUnitsInRange(enumGroup, x, y, radius, null)
        loop
            set u = FirstOfGroup(enumGroup)
            exitwhen u == null
            call GroupRemoveUnit(enumGroup, u)
            /*
            *   Damage units inside sphere
            */
            if bounds.contains(GetUnitX(u), GetUnitY(u), BlzGetLocalUnitZ(u)) then
                call UnitDamageTarget(source, u, sphereDamage, true, false, ATTACK_TYPE_HERO, DAMAGE_TYPE_NORMAL, null)
            endif
        endloop

        call bounds.destroy()

    //! endnovjass

    /*============================= END OF DOCUMENTATION ==============================*/

    private keyword RotatedEllipsoid
    private keyword RotatedPrism
    private keyword RotatedCone
    private keyword RotatedCylinder

    private keyword Ellipsoid
    private keyword Sphere
    private keyword Prism
    private keyword Cube
    private keyword Cone
    private keyword Cylinder

    private keyword Vector

    globals
        private integer array boundaryType
        private integer array boundaryShapeType

        private real dx
        private real dy
        private real dz
        private real rx
        private real ry
        private real rz
        private real r
        private Vector v
        private Vector w
    endglobals

    static if DEBUG_MODE then
        private function AssertError takes boolean condition, string methodName, string objectName, integer node, string message returns nothing
            static if LIBRARY_ErrorMessage then
                call ThrowError(condition, SCOPE_PREFIX, methodName, objectName, node, message)
            else
                if condition then
                    call BJDebugMsg("[Library: " + SCOPE_PREFIX + "] [Struct: " + objectName + "] [Method: " + methodName + "] [Instance: " + I2S(node) + "] : |cffff0000" + message + "|r")
                endif
            endif
        endfunction
    endif

    /*=================================================================================*/

    private struct Node extends array
        static if LIBRARY_Alloc then
            implement optional Alloc
        else
            private static thistype array stack

            static method allocate takes nothing returns thistype
                local thistype node = stack[0]
                if stack[node] == 0 then
                    debug call AssertError(node == (JASS_MAX_ARRAY_SIZE - 1), "allocate()", "thistype", node, "Overflow")
                    set node = node + 1
                    set stack[0] = node
                else
                    set stack[0] = stack[node]
                    set stack[node] = 0
                endif
                return node
            endmethod
            method deallocate takes nothing returns nothing
                debug call AssertError(this == 0, "deallocate()", "thistype", 0, "Null node")
                debug call AssertError(stack[this] > 0, "deallocate()", "thistype", this, "Double-free")
                set stack[this] = stack[0]
                set stack[0] = this
            endmethod
        endif
    endstruct

    /*=================================================================================*/

    private struct Vector extends array
        real x
        real y
        real z

        method getLength takes nothing returns real
            return SquareRoot(this.x*this.x + this.y*this.y + this.z*this.z)
        endmethod

        method adjust takes real x, real y, real z returns nothing
            set this.x = x
            set this.y = y
            set this.z = z
        endmethod
        method scale takes real a, real b, real c returns nothing
            set this.x = this.x*a
            set this.y = this.y*b
            set this.z = this.z*c
        endmethod

        static method create takes real x, real y, real z returns thistype
            local thistype node = Node.allocate()
            call node.adjust(x, y, z)
            return node
        endmethod
        method destroy takes nothing returns nothing
            call Node(this).deallocate()
        endmethod
    endstruct

    /*
    *   Space represents a bounded region in 3D space
    */
    private struct Space extends array
        /*
        *   vectors x(x, y, z), y(x, y, z), & z(x, y, z) are the orientation axes of the bounded space
        *       with their default values at x(1, 0, 0), y(0, 1, 0), & z(0, 0, 1) - similar to the game map axes
        *   vector o(x, y, z) represents the position of origin
        *   vector s(a, b, c) represents the distance of boundary from origin of the bounded space in the
        *       axes x, y, z respectively (see https://upload.wikimedia.org/wikipedia/commons/thumb/3/33/Ellipsoide.svg/800px-Ellipsoide.svg.png )
        */
        Vector s
        Vector x
        Vector y
        Vector z

        method operator o takes nothing returns Vector
            return this
        endmethod

        /*
        *   Checks if the orientation axes of the bounded space are equivalent to an oblique coordinate system
        */
        method isOblique takes nothing returns boolean
            set v = this.x
            set w = this.y
            if not (v.x*w.x + v.y*w.y + v.z*v.z == 0.00) then
                return true
            endif

            set w = this.z
            if not (v.x*w.x + v.y*w.y + v.z*v.z == 0.00) then
                return true
            endif

            set v = this.y
            return not (v.x*w.x + v.y*w.y + v.z*v.z == 0.00)
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.x.adjust(xi, xj, xk)
            call this.y.adjust(yi, yj, yk)
            call this.z.adjust(zi, zj, zk)

            set rx = 1.00/this.x.getLength()
            set ry = 1.00/this.y.getLength()
            set rz = 1.00/this.z.getLength()
            set v = this.s
            call v.adjust(v.x/rx, v.y/ry, v.z/rz)

            call this.x.scale(rx, rx, rx)
            call this.y.scale(ry, ry, ry)
            call this.z.scale(rz, rz, rz)
        endmethod

        static method create takes real oi, real oj, real ok, real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk, real a, real b, real c returns thistype
            local thistype node = Vector.create(oi, oj, ok)
            set node.x = Vector.create(xi, xj, xk)
            set node.y = Vector.create(yi, yj, yk)
            set node.z = Vector.create(zi, zj, zk)
            set node.s = Vector.create(a, b, c)
            return node
        endmethod
        method destroy takes nothing returns nothing
            call this.s.destroy()
            call this.x.destroy()
            call this.y.destroy()
            call this.z.destroy()
            call this.o.destroy()
        endmethod
    endstruct

    private module SpaceFields
        method operator space takes nothing returns Space
            return this
        endmethod
    endmodule

    /*=================================================================================*/

    //! textmacro BOUNDARY_SHAPE_VARIANT takes SHAPE_TYPE
        static method operator Normal takes nothing returns $SHAPE_TYPE$
            return 0
        endmethod
        static method operator Oblique takes nothing returns Oblique$SHAPE_TYPE$
            return 0
        endmethod
    //! endtextmacro

    /*=================================================================================*/

    private function CalculateProjections takes nothing returns nothing
        set rx = v.x + w.x
        set ry = v.y + w.y
        set rz = v.z + w.z
        set r = (dx*rx + dy*ry + dz*rz)/rx*rx + ry*ry + rz*rz

        set rx = dx - r*rx
        set ry = dy - r*ry
        set rz = dz - r*rz
    endfunction

    private struct ObliqueEllipsoid extends array
        implement SpaceFields

        method updateType takes nothing returns nothing
            if not this.space.isOblique() then
                if this.space.x.x == 1.00 and this.space.y.y == 1.00 then
                    set v = this.space.s

                    if v.x == v.y and v.y == v.z then
                        set boundaryType[this] = boundaryShapeType[Sphere.typeid]
                    else
                        set boundaryType[this] = boundaryShapeType[Ellipsoid.typeid]
                    endif
                else
                    set boundaryType[this] = boundaryShapeType[RotatedEllipsoid.typeid]
                endif
            endif
        endmethod

        method contains takes real x, real y, real z returns boolean
            set dx = x - this.space.o.x
            set dy = y - this.space.o.y
            set dz = z - this.space.o.z

            set v = this.space.x
            set w = this.space.y

            call CalculateProjections()

            set v = this.space.z
            set z = rx/v.x + ry/v.y + rz/v.z

            set v = this.space.x
            set w = this.space.z

            call CalculateProjections()

            set v = this.space.y
            set y = rx/v.x + ry/v.y + rz/v.z

            set v = this.space.y
            set w = this.space.z

            call CalculateProjections()

            set v = this.space.x
            set x = rx/v.x + ry/v.y + rz/v.z

            set v = this.space.s
            return (x*x)/(v.x*v.x) + (y*y)/(v.y*v.y) + (z*z)/(v.z*v.z) <= 1.00
        endmethod

        method scale takes real a, real b, real c returns nothing
            call this.space.s.scale(a, b, c)
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.space.orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            call this.updateType()
        endmethod

        static method create takes real x, real y, real z, real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk, real a, real b, real c returns thistype
            local thistype node = Space.create(x, y, z, xi, xj, xk, yi, yj, yk, zi, zj, zk, a, b, c)

            set boundaryType[node] = boundaryShapeType[thistype.typeid]

            return node
        endmethod
    endstruct

    private struct ObliquePrism extends array
        implement SpaceFields

        method updateType takes nothing returns nothing
            if not this.space.isOblique() then
                if this.space.x.x == 1.00 and this.space.y.y == 1.00 then
                    set v = this.space.s

                    if v.x == v.y and v.y == v.z then
                        set boundaryType[this] = boundaryShapeType[Cube.typeid]
                    else
                        set boundaryType[this] = boundaryShapeType[Prism.typeid]
                    endif
                else
                    set boundaryType[this] = boundaryShapeType[RotatedPrism.typeid]
                endif
            endif
        endmethod

        method contains takes real x, real y, real z returns boolean
            set dx = x - this.space.o.x
            set dy = y - this.space.o.y
            set dz = z - this.space.o.z

            set v = this.space.x
            set w = this.space.y

            call CalculateProjections()

            set v = this.space.z
            set r = this.space.s.z*(v.x*rx + v.y*ry + v.z*rz)

            if rx*rx + ry*ry + rz*rz <= r*r then
                set v = this.space.x
                set w = this.space.z

                call CalculateProjections()

                set v = this.space.y
                set r = this.space.s.y*(v.x*rx + v.y*ry + v.z*rz)

                if rx*rx + ry*ry + rz*rz <= r*r then
                    set v = this.space.y
                    set w = this.space.z

                    call CalculateProjections()

                    set v = this.space.x
                    set r = this.space.s.x*(v.x*rx + v.y*ry + v.z*rz)

                    return rx*rx + ry*ry + rz*rz <= r*r
                endif

                return false
            endif

            return false
        endmethod

        method scale takes real a, real b, real c returns nothing
            call this.space.s.scale(a, b, c)
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.space.orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            call this.updateType()
        endmethod

        static method create takes real x, real y, real z, real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk, real a, real b, real c returns thistype
            local thistype node = Space.create(x, y, z, xi, xj, xk, yi, yj, yk, zi, zj, zk, a, b, c)

            set boundaryType[node] = boundaryShapeType[thistype.typeid]

            return node
        endmethod
    endstruct

    private struct ObliqueCone extends array
        implement SpaceFields

        method updateType takes nothing returns nothing
            if not this.space.isOblique() then
                if this.space.x.x == 1.00 and this.space.y.y == 1.00 then
                    set boundaryType[this] = boundaryShapeType[Cone.typeid]
                else
                    set boundaryType[this] = boundaryShapeType[RotatedCone.typeid]
                endif
            endif
        endmethod

        method contains takes real x, real y, real z returns boolean
            set dx = x - this.space.o.x
            set dy = y - this.space.o.y
            set dz = z - this.space.o.z

            set v = this.space.x
            set w = this.space.y

            call CalculateProjections()

            set v = this.space.z
            set r = 1.00 - (rx/v.x + ry/v.y + rz/v.z)/this.space.s.z

            if r >= 0.00 and r <= 1.00 then
                set v = this.space.y
                set w = this.space.z

                call CalculateProjections()

                set v = this.space.x
                set x = rx/v.x + ry/v.y + rz/v.z

                set v = this.space.x
                set w = this.space.z

                call CalculateProjections()

                set v = this.space.y
                set y = rx/v.x + ry/v.y + rz/v.z

                set v = this.space.s
                return (x*x)/(v.x*v.x) + (y*y)/(v.y*v.y) <= r*r
            endif

            return false
        endmethod

        method scale takes real a, real b, real c returns nothing
            call this.space.s.scale(a, b, c)
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.space.orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            call this.updateType()
        endmethod

        static method create takes real x, real y, real z, real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk, real a, real b, real h returns thistype
            local thistype node = Space.create(x, y, z, xi, xj, xk, yi, yj, yk, zi, zj, zk, a, b, h)

            set boundaryType[node] = boundaryShapeType[thistype.typeid]

            return node
        endmethod
    endstruct

    private struct ObliqueCylinder extends array
        implement SpaceFields

        method updateType takes nothing returns nothing
            if not this.space.isOblique() then
                if this.space.x.x == 1.00 and this.space.y.y == 1.00 then
                    set boundaryType[this] = boundaryShapeType[Cylinder.typeid]
                else
                    set boundaryType[this] = boundaryShapeType[RotatedCylinder.typeid]
                endif
            endif
        endmethod

        method contains takes real x, real y, real z returns boolean
            set dx = x - this.space.o.x
            set dy = y - this.space.o.y
            set dz = z - this.space.o.z

            set v = this.space.x
            set w = this.space.y

            call CalculateProjections()

            set v = this.space.z
            set z = rx/v.x + ry/v.y + rz/v.z
            set r = this.space.s.z

            if z*z <= r*r then
                set v = this.space.y
                set w = this.space.z

                call CalculateProjections()

                set v = this.space.x
                set x = rx/v.x + ry/v.y + rz/v.z

                set v = this.space.x
                set w = this.space.z

                call CalculateProjections()

                set v = this.space.y
                set y = rx/v.x + ry/v.y + rz/v.z

                set v = this.space.s
                return (x*x)/(v.x*v.x) + (y*y)/(v.y*v.y) <= 1.00
            endif

            return false
        endmethod

        method scale takes real a, real b, real c returns nothing
            call this.space.s.scale(a, b, c)
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.space.orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            call this.updateType()
        endmethod

        static method create takes real x, real y, real z, real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk, real a, real b, real h returns thistype
            local thistype node = Space.create(x, y, z, xi, xj, xk, yi, yj, yk, zi, zj, zk, a, b, h)

            set boundaryType[node] = boundaryShapeType[thistype.typeid]

            return node
        endmethod
    endstruct

    /*=================================================================================*/

    private struct RotatedEllipsoid extends array
        implement SpaceFields

        method updateType takes nothing returns nothing
            if this.space.isOblique() then
                set boundaryType[this] = boundaryShapeType[ObliqueEllipsoid.typeid]

            elseif this.space.x.x == 1.00 and this.space.y.y == 1.00 then
                set v = this.space.s

                if v.x == v.y and v.y == v.z then
                    set boundaryType[this] = boundaryShapeType[Sphere.typeid]
                else
                    set boundaryType[this] = boundaryShapeType[Ellipsoid.typeid]
                endif
            endif
        endmethod

        method contains takes real x, real y, real z returns boolean
            set rx = x - this.space.o.x
            set ry = y - this.space.o.y
            set rz = z - this.space.o.z

            set v = this.space.x
            set dx = rx*v.x + ry*v.y + rz*v.z
            set v = this.space.y
            set dy = rx*v.x + ry*v.y + rz*v.z
            set v = this.space.z
            set dz = rx*v.x + ry*v.y + rz*v.z

            set v = this.space.s
            return (dx*dx)/(v.x*v.x) + (dy*dy)/(v.y*v.y) + (dz*dz)/(v.z*v.z) <= 1.00
        endmethod

        method scale takes real a, real b, real c returns nothing
            call this.space.s.scale(a, b, c)
            call this.updateType()
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.space.orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            call this.updateType()
        endmethod
    endstruct

    private struct RotatedPrism extends array
        implement SpaceFields

        method updateType takes nothing returns nothing
            if this.space.isOblique() then
                set boundaryType[this] = boundaryShapeType[ObliquePrism.typeid]

            elseif this.space.x.x == 1.00 and this.space.y.y == 1.00 then
                set v = this.space.s

                if v.x == v.y and v.y == v.z then
                    set boundaryType[this] = boundaryShapeType[Cube.typeid]
                else
                    set boundaryType[this] = boundaryShapeType[Prism.typeid]
                endif
            endif
        endmethod

        method contains takes real x, real y, real z returns boolean
            set x = x - this.space.o.x
            set y = y - this.space.o.y
            set z = z - this.space.o.z

            set v = this.space.z
            set dz = x*v.x + y*v.y + z*v.z
            set rz = this.space.s.z

            if dz*dz <= rz*rz then
                set v = this.space.y
                set dy = x*v.x + y*v.y + z*v.z
                set ry = this.space.s.y

                if dy*dy <= ry*ry then
                    set v = this.space.x
                    set dx = x*v.x + y*v.y + z*v.z
                    set rx = this.space.s.x

                    return dx*dx < rx*rx
                endif

                return false
            endif

            return false
        endmethod

        method scale takes real a, real b, real c returns nothing
            call this.space.s.scale(a, b, c)
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.space.orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            call this.updateType()
        endmethod
    endstruct

    private struct RotatedCone extends array
        implement SpaceFields

        method updateType takes nothing returns nothing
            if this.space.isOblique() then
                set boundaryType[this] = boundaryShapeType[ObliqueCone.typeid]

            elseif this.space.x.x == 1.00 and this.space.y.y == 1.00 then
                set boundaryType[this] = boundaryShapeType[Cone.typeid]
            endif
        endmethod

        method contains takes real x, real y, real z returns boolean
            set x = x - this.space.o.x
            set y = y - this.space.o.y
            set z = z - this.space.o.z

            set v = this.space.z
            set rz = 1.00 - (x*v.x + y*v.y + z*v.z)/this.space.s.z

            if rz >= 0.00 and rz <= 1.00 then
                set v = this.space.x
                set dx = x*v.x + y*v.y + z*v.z
                set v = this.space.y
                set dy = x*v.x + y*v.y + z*v.z

                set v = this.space.s
                return (dx*dx)/(v.x*v.x) + (dy*dy)/(v.y*v.y) <= rz*rz
            endif

            return false
        endmethod

        method scale takes real a, real b, real c returns nothing
            call this.space.s.scale(a, b, c)
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.space.orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            call this.updateType()
        endmethod
    endstruct

    private struct RotatedCylinder extends array
        implement SpaceFields

        method updateType takes nothing returns nothing
            if this.space.isOblique() then
                set boundaryType[this] = boundaryShapeType[ObliqueCylinder.typeid]

            elseif this.space.x.x == 1.00 and this.space.y.y == 1.00 then
                set boundaryType[this] = boundaryShapeType[Cylinder.typeid]
            endif
        endmethod

        method contains takes real x, real y, real z returns boolean
            set x = x - this.space.o.x
            set y = y - this.space.o.y
            set z = z - this.space.o.z

            set v = this.space.z
            set dz = x*v.x + y*v.y + z*v.z
            set rz = this.space.s.z

            if dz*dz <= rz*rz then
                set v = this.space.x
                set dx = x*v.x + y*v.y + z*v.z
                set v = this.space.y
                set dy = x*v.x + y*v.y + z*v.z

                set v = this.space.s
                return (dx*dx)/(v.x*v.x) + (dy*dy)/(v.y*v.y) <= 1.00
            endif

            return false
        endmethod

        method scale takes real a, real b, real c returns nothing
            call this.space.s.scale(a, b, c)
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.space.orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            call this.updateType()
        endmethod
    endstruct

    /*=================================================================================*/

    private struct Ellipsoid extends array
        //! runtextmacro BOUNDARY_SHAPE_VARIANT("Ellipsoid")

        implement SpaceFields

        method updateType takes nothing returns nothing
            if this.space.isOblique() then
                set boundaryType[this] = boundaryShapeType[ObliqueEllipsoid.typeid]
            else
                set v = this.space.s

                if v.x == v.y and v.y == v.z then
                    set boundaryType[this] = boundaryShapeType[Sphere.typeid]
                elseif not (this.space.x.x == 1.00 and this.space.y.y == 1.00) then
                    set boundaryType[this] = boundaryShapeType[RotatedEllipsoid.typeid]
                endif
            endif
        endmethod

        method contains takes real x, real y, real z returns boolean
            set dx = x - this.space.o.x
            set dy = y - this.space.o.y
            set dz = z - this.space.o.z
            set v = this.space.s

            return (dx*dx)/(v.x*v.x) + (dy*dy)/(v.y*v.y) + (dz*dz)/(v.z*v.z) <= 1.00
        endmethod

        method scale takes real a, real b, real c returns nothing
            call this.space.s.scale(a, b, c)
            call this.updateType()
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.space.orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            call this.updateType()
        endmethod

        static method create takes real x, real y, real z, real a, real b, real c returns thistype
            local thistype node = Space.create(x, y, z, 1.00, 0.00, 0.00, 0.00, 1.00, 0.00, 0.00, 0.00, 1.00, a, b, c)

            set boundaryType[node] = boundaryShapeType[thistype.typeid]

            return node
        endmethod
    endstruct

    private struct Sphere extends array
        implement SpaceFields

        method updateType takes nothing returns nothing
            if this.space.isOblique() then
                set boundaryType[this] = boundaryShapeType[ObliqueEllipsoid.typeid]
            else
                set v = this.space.s

                if v.x != v.y or v.y != v.z then
                    if this.space.x.x == 1.00 and this.space.y.y == 1.00 then
                        set boundaryType[this] = boundaryShapeType[Ellipsoid.typeid]
                    else
                        set boundaryType[this] = boundaryShapeType[RotatedEllipsoid.typeid]
                    endif
                endif
            endif
        endmethod

        method contains takes real x, real y, real z returns boolean
            set dx = x - this.space.o.x
            set dy = y - this.space.o.y
            set dz = z - this.space.o.z
            set r = this.space.s.x

            return dx*dx + dy*dy + dz*dz <= r*r
        endmethod

        method scale takes real a, real b, real c returns nothing
            call this.space.s.scale(a, b, c)
            call this.updateType()
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.space.orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            call this.updateType()
        endmethod

        static method create takes real x, real y, real z, real r returns thistype
            local thistype node = Space.create(x, y, z, 1.00, 0.00, 0.00, 0.00, 1.00, 0.00, 0.00, 0.00, 1.00, r, r, r)

            set boundaryType[node] = boundaryShapeType[thistype.typeid]

            return node
        endmethod
    endstruct

    private struct Prism extends array
        //! runtextmacro BOUNDARY_SHAPE_VARIANT("Prism")

        implement SpaceFields

        method updateType takes nothing returns nothing
            if this.space.isOblique() then
                set boundaryType[this] = boundaryShapeType[ObliquePrism.typeid]

            elseif this.space.x.x == 1.00 and this.space.y.y == 1.00 then
                set v = this.space.s

                if v.x == v.y and v.y == v.z then
                    set boundaryType[this] = boundaryShapeType[Cube.typeid]
                endif
            else
                set boundaryType[this] = boundaryShapeType[RotatedPrism.typeid]
            endif
        endmethod

        method contains takes real x, real y, real z returns boolean
            set v = this.space.s

            return z >= (this.space.o.z - v.z) and/*
                */ z <= (this.space.o.z + v.z) and/*
                */ y >= (this.space.o.y - v.y) and/*
                */ y <= (this.space.o.y + v.y) and/*
                */ x >= (this.space.o.x - v.x) and/*
                */ x <= (this.space.o.x + v.x)
        endmethod

        method scale takes real a, real b, real c returns nothing
            call this.space.s.scale(a, b, c)
            call this.updateType()
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.space.orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            call this.updateType()
        endmethod

        static method create takes real x, real y, real z, real a, real b, real c returns thistype
            local thistype node = Space.create(x, y, z, 1.00, 0.00, 0.00, 0.00, 1.00, 0.00, 0.00, 0.00, 1.00, a, b, c)

            set boundaryType[node] = boundaryShapeType[thistype.typeid]

            return node
        endmethod
        static method createEx takes real minX, real minY, real minZ, real maxX, real maxY, real maxZ returns thistype
            return create((minX + maxX)*0.5, (minY + maxY)*0.5, (minZ + maxZ)*0.5, (maxX - minX)*0.5, (maxY - minY)*0.5, (maxZ - minZ)*0.5)
        endmethod
    endstruct

    private struct Cube extends array
        //! runtextmacro BOUNDARY_SHAPE_VARIANT("Prism")

        implement SpaceFields

        method updateType takes nothing returns nothing
            if this.space.isOblique() then
                set boundaryType[this] = boundaryShapeType[ObliquePrism.typeid]

            elseif this.space.x.x == 1.00 and this.space.y.y == 1.00 then
                set v = this.space.s

                if v.x != v.y or v.y != v.z then
                    set boundaryType[this] = boundaryShapeType[Prism.typeid]
                endif
            else
                set boundaryType[this] = boundaryShapeType[RotatedPrism.typeid]
            endif
        endmethod

        method contains takes real x, real y, real z returns boolean
            set r = this.space.s.x

            return z >= (this.space.o.z - r) and/*
                */ z <= (this.space.o.z + r) and/*
                */ y >= (this.space.o.y - r) and/*
                */ y <= (this.space.o.y + r) and/*
                */ x >= (this.space.o.x - r) and/*
                */ x <= (this.space.o.x + r)
        endmethod

        method scale takes real a, real b, real c returns nothing
            call this.space.s.scale(a, b, c)
            call this.updateType()
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.space.orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            call this.updateType()
        endmethod

        static method create takes real x, real y, real z, real r returns thistype
            local thistype node = Space.create(x, y, z, 1.00, 0.00, 0.00, 0.00, 1.00, 0.00, 0.00, 0.00, 1.00, r, r, r)

            set boundaryType[node] = boundaryShapeType[thistype.typeid]

            return node
        endmethod
        static method createEx takes real x, real y, real z, real s returns thistype
            return create(x, y, z, 0.5*s)
        endmethod
    endstruct

    private struct Cone extends array
        //! runtextmacro BOUNDARY_SHAPE_VARIANT("Cone")

        implement SpaceFields

        method updateType takes nothing returns nothing
            if this.space.isOblique() then
                set boundaryType[this] = boundaryShapeType[ObliqueCone.typeid]
            elseif not (this.space.x.x == 1.00 and this.space.y.y == 1.00) then
                set boundaryType[this] = boundaryShapeType[RotatedCone.typeid]
            endif
        endmethod

        method contains takes real x, real y, real z returns boolean
            set v = this.space.s
            set rz = 1.00 - (z - this.space.o.z)/v.z

            if rz >= 0.00 and rz <= 1.00 then
                set dx = x - this.space.o.x
                set dy = y - this.space.o.y

                return (dx*dx)/(v.x*v.x) + (dy*dy)/(v.y*v.y) <= rz*rz
            endif

            return false
        endmethod

        method scale takes real a, real b, real c returns nothing
            call this.space.s.scale(a, b, c)
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.space.orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            call this.updateType()
        endmethod

        static method create takes real x, real y, real z, real a, real b, real h returns thistype
            local thistype node = Space.create(x, y, z, 1.00, 0.00, 0.00, 0.00, 1.00, 0.00, 0.00, 0.00, 1.00, a, b, h)

            set boundaryType[node] = boundaryShapeType[thistype.typeid]

            return node
        endmethod
        static method createEx takes real x, real y, real r, real minZ, real maxZ returns thistype
            return create(x, y, (minZ + maxZ)*0.5, r, r, maxZ - minZ)
        endmethod
    endstruct

    private struct Cylinder extends array
        //! runtextmacro BOUNDARY_SHAPE_VARIANT("Cylinder")

        implement SpaceFields

        method updateType takes nothing returns nothing
            if this.space.isOblique() then
                set boundaryType[this] = boundaryShapeType[ObliqueCylinder.typeid]
            elseif not (this.space.x.x == 1.00 and this.space.y.y == 1.00) then
                set boundaryType[this] = boundaryShapeType[RotatedCylinder.typeid]
            endif
        endmethod

        method contains takes real x, real y, real z returns boolean
            set v = this.space.s

            if z >= (this.space.o.z - v.z) and z <= (this.space.o.z + v.z) then
                set dx = x - this.space.o.x
                set dy = y - this.space.o.y

                return (dx*dx)/(v.x*v.x) + (dy*dy)/(v.y*v.y) <= 1.00
            endif

            return false
        endmethod

        method scale takes real a, real b, real c returns nothing
            call this.space.s.scale(a, b, c)
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns nothing
            call this.space.orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            call this.updateType()
        endmethod

        static method create takes real x, real y, real z, real a, real b, real h returns thistype
            local thistype node = Space.create(x, y, z, 1.00, 0.00, 0.00, 0.00, 1.00, 0.00, 0.00, 0.00, 1.00, a, b, h)

            set boundaryType[node] = boundaryShapeType[thistype.typeid]

            return node
        endmethod
        static method createEx takes real x, real y, real z, real r, real minZ, real maxZ returns thistype
            return create(x, y, (minZ + maxZ)*0.5, r, r, maxZ - minZ)
        endmethod
    endstruct

    /*=================================================================================*/

        //! textmacro BOUNDARY_OPERATION_TREE takes CALLTYPE, CALLBACK, DEFAULT
            local integer id = boundaryType[this]

            if id > 6 then
                if id > 10 then
                    if id > 12 then
                        if id > 13 then
                            $CALLTYPE$ Cylinder(this).$CALLBACK$//14
                        else
                            $CALLTYPE$ Cone(this).$CALLBACK$//13
                        endif
                    else
                        if id > 11 then
                            $CALLTYPE$ Cube(this).$CALLBACK$//12
                        else
                            $CALLTYPE$ Prism(this).$CALLBACK$//11
                        endif
                    endif
                else
                    if id > 8 then
                        if id > 9 then
                            $CALLTYPE$ Sphere(this).$CALLBACK$//10
                        else
                            $CALLTYPE$ Ellipsoid(this).$CALLBACK$//9
                        endif
                    else
                        if id > 7 then
                            $CALLTYPE$ RotatedCylinder(this).$CALLBACK$//8
                        else
                            $CALLTYPE$ RotatedCone(this).$CALLBACK$//7
                        endif
                    endif
                endif
            else
                if id > 2 then
                    if id > 4 then
                        if id > 5 then
                            $CALLTYPE$ RotatedPrism(this).$CALLBACK$//6
                        else
                            $CALLTYPE$ RotatedEllipsoid(this).$CALLBACK$//5
                        endif
                    else
                        if id > 3 then
                            $CALLTYPE$ ObliqueCylinder(this).$CALLBACK$//4
                        else
                            $CALLTYPE$ ObliqueCone(this).$CALLBACK$//3
                        endif
                    endif
                elseif id > 1 then
                    $CALLTYPE$ ObliquePrism(this).$CALLBACK$//2
                else
                    $CALLTYPE$ ObliqueEllipsoid(this).$CALLBACK$//1
                endif
            endif

            return $DEFAULT$
        //! endtextmacro

    /*=================================================================================*/

    private module Init
        private static method onInit takes nothing returns nothing
            call onScopeInit()
        endmethod
    endmodule

    struct Boundary extends array

        debug private static string array boundaryTypeString
        debug private static integer array boundaryShapeType

        //! textmacro BOUNDARY_SHAPE_TYPE takes TYPE
        static method operator $TYPE$ takes nothing returns $TYPE$
            return 0
        endmethod
        //! endtextmacro

        //! runtextmacro BOUNDARY_SHAPE_TYPE("Ellipsoid")
        //! runtextmacro BOUNDARY_SHAPE_TYPE("Sphere")
        //! runtextmacro BOUNDARY_SHAPE_TYPE("Prism")
        //! runtextmacro BOUNDARY_SHAPE_TYPE("Cube")
        //! runtextmacro BOUNDARY_SHAPE_TYPE("Cone")
        //! runtextmacro BOUNDARY_SHAPE_TYPE("Cylinder")

        debug method operator typeName takes nothing returns string
            debug return boundaryTypeString[boundaryType[this]]
        debug endmethod

        method contains takes real x, real y, real z returns boolean
            //! runtextmacro BOUNDARY_OPERATION_TREE("return", "contains(x, y, z)", "false")
        endmethod

        method castTo takes integer boundaryTypeId returns thistype
            debug local boolean b = boundaryTypeId == Ellipsoid.typeid or/*
                                */  boundaryTypeId == Prism.typeid     or/*
                                */  boundaryTypeId == Cone.typeid      or/*
                                */  boundaryTypeId == Cylinder.typeid
            debug call AssertError(not b, "castTo()", this.typeName, this, "Invalid Cast")

            if boundaryTypeId == Ellipsoid.typeid then
                call Ellipsoid(this).updateType()
            elseif boundaryTypeId == Prism.typeid then
                call Prism(this).updateType()
            elseif boundaryTypeId == Cone.typeid then
                call Cone(this).updateType()
            elseif boundaryTypeId == Cylinder.typeid then
                call Cylinder(this).updateType()
            endif

            return this
        endmethod

        method move takes real x, real y, real z returns thistype
            call Space(this).o.adjust(x, y, z)
            return this
        endmethod

        method scale takes real a, real b, real c returns thistype
            //! runtextmacro BOUNDARY_OPERATION_TREE("call", "scale(a, b, c)", "this")
        endmethod

        method orient takes real xi, real xj, real xk, real yi, real yj, real yk, real zi, real zj, real zk returns thistype
            //! runtextmacro BOUNDARY_OPERATION_TREE("call", "orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)", "this")
        endmethod

        private static method rotateVector takes real i, real j, real k, real sin, real cos returns nothing
            local real f
            set r = i*i + j*j + k*k
            set f = (v.x*i + v.y*j + v.z*k)/r
            set rx = i*f
            set ry = j*f
            set rz = k*f
            set dx = v.x - rx
            set dy = v.y - ry
            set dz = v.z - rz
            set r = SquareRoot(r)
            call v.adjust(dx*cos + ((j*dz - k*dy)/r)*sin + rx, /*
                        */dy*cos + ((k*dx - i*dz)/r)*sin + ry, /*
                        */dz*cos + ((i*dy - j*dx)/r)*sin + rz)
        endmethod

        method rotate takes real i, real j, real k, real rad returns thistype
            local real sin
            local real cos
            local Vector vx
            local Vector vy
            local Vector vz
            set r = i*i + j*j + k*k
            debug call AssertError(r == 0.00, "rotate()", this.typeName, this, "The axis vector is zero")
            set sin = Sin(rad)
            set cos = Cos(rad)
            set v = Space(this).x
            set vx = Vector.create(v.x, v.y, v.z)
            set v = Space(this).y
            set vy = Vector.create(v.x, v.y, v.z)
            set v = Space(this).z
            set vz = Vector.create(v.x, v.y, v.z)
            set v = vx
            call rotateVector(i, j, k, sin, cos)
            set v = vy
            call rotateVector(i, j, k, sin, cos)
            set v = vz
            call rotateVector(i, j, k, sin, cos)
            call this.orient(vx.x, vx.y, vx.z, vy.x, vy.y, vy.z, vz.x, vz.y, vz.z)
            call vx.destroy()
            call vy.destroy()
            call vz.destroy()
            return this
        endmethod

        method destroy takes nothing returns nothing
            call Space(this).destroy()
        endmethod

        private static method onScopeInit takes nothing returns nothing
            static if DEBUG_MODE then
                set boundaryTypeString[ObliqueEllipsoid.typeid]     = "Oblique Ellipsoid"
                set boundaryTypeString[ObliquePrism.typeid]         = "Oblique Prism"
                set boundaryTypeString[ObliqueCone.typeid]          = "Oblique Cone"
                set boundaryTypeString[ObliqueCylinder.typeid]      = "Oblique Cylinder"

                set boundaryTypeString[RotatedEllipsoid.typeid]     = "Rotated Ellipsoid"
                set boundaryTypeString[RotatedPrism.typeid]         = "Rotated Prism"
                set boundaryTypeString[RotatedCone.typeid]          = "Rotated Cone"
                set boundaryTypeString[RotatedCylinder.typeid]      = "Rotated Cylinder"

                set boundaryTypeString[Ellipsoid.typeid]            = "Ellipsoid"
                set boundaryTypeString[Sphere.typeid]               = "Sphere"
                set boundaryTypeString[Prism.typeid]                = "Prism"
                set boundaryTypeString[Cube.typeid]                 = "Cube"
                set boundaryTypeString[Cone.typeid]                 = "Cone"
                set boundaryTypeString[Cylinder.typeid]             = "Cylinder"
            endif

            set boundaryShapeType[ObliqueEllipsoid.typeid]          = 1
            set boundaryShapeType[ObliquePrism.typeid]              = 2
            set boundaryShapeType[ObliqueCone.typeid]               = 3
            set boundaryShapeType[ObliqueCylinder.typeid]           = 4

            set boundaryShapeType[RotatedEllipsoid.typeid]          = 5
            set boundaryShapeType[RotatedPrism.typeid]              = 6
            set boundaryShapeType[RotatedCone.typeid]               = 7
            set boundaryShapeType[RotatedCylinder.typeid]           = 8

            set boundaryShapeType[Ellipsoid.typeid]                 = 9
            set boundaryShapeType[Sphere.typeid]                    = 10
            set boundaryShapeType[Prism.typeid]                     = 11
            set boundaryShapeType[Cube.typeid]                      = 12
            set boundaryShapeType[Cone.typeid]                      = 13
            set boundaryShapeType[Cylinder.typeid]                  = 14
        endmethod
        implement Init

    endstruct


endlibrary