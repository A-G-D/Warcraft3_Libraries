--[[ Boundary3D.lua


    API:


        Constructors:

            function <type>()                       (ox, oy, oz, xi, xj, xk, yi, yj, yk, zi, zj, zk, a, b, c)   returns Boundary
                - Generic constructor - can construct any shape (Example: Boundary.Ellipsoid.Cylinder.Normal(...) )

            function Boundary.Sphere.new            (ox, oy, oz, r)                                             returns Boundary

            function Boundary.Ellipsoid.Normal.new  (ox, oy, oz, a, b, c)                                       returns Boundary

            function Boundary.Ellipsoid.Oblique.new (ox, oy, oz, xi, xj, xk, yi, yj, yk, zi, zj, zk, a, b, c)   returns Boundary

            function Boundary.Prism.Normal.new      (ox, oy, oz, a, b, c)                                       returns Boundary
            function Boundary.Prism.Normal.newEx    (minX, minY, minZ, maxX, maxY, maxZ)                        returns Boundary

            function Boundary.Prism.Oblique.new     (ox, oy, oz, xi, xj, xk, yi, yj, yk, zi, zj, zk, a, b, c)   returns Boundary

            function Boundary.Cone.Normal.new       (ox, oy, oz, a, b, h)                                       returns Boundary
            function Boundary.Cone.Normal.newEx     (ox, oy, r, minZ, maxZ)                                     returns Boundary

            function Boundary.Cone.Oblique.new      (ox, oy, oz, xi, xj, xk, yi, yj, yk, zi, zj, zk, a, b, h)   returns Boundary

            function Boundary.Cylinder.Normal.new   (ox, oy, oz, a, b, h)                                       returns Boundary
            function Boundary.Cylinder.Normal.newEx (ox, oy, r, minZ, maxZ)                                     returns Boundary

            function Boundary.Cylinder.Oblique.new  (ox, oy, oz, xi, xj, xk, yi, yj, yk, zi, zj, zk, a, b, h)   returns Boundary

                Arguments:

                    - ox, oy, oz:
                        > Position/Origin

                    - xi, xj, xk:
                        > Local x-axis vector of the bounded space (could be oblique (non-perpendicular) to the Local y and z axes)

                    - yi, yj, yk:
                        > Local y-axis vector of the bounded space (could be oblique (non-perpendicular) to the Local x and z axes)

                    - zi, zj, zk:
                        > Local z-axis vector of the bounded space (could be oblique (non-perpendicular) to the Local x and y axes)

                    - a, b, c:
                        > Distance of the space boundary from the origin in its local x, y, & z axes respectively
                        > See https://upload.wikimedia.org/wikipedia/commons/thumb/3/33/Ellipsoide.svg/800px-Ellipsoide.svg.png 
                          for the convention used

                    - a, b, h:
                        > Same as <a, b, c> where a = a, b = b, c = h

                    - r:
                        > Same as <a, b, c> where a = r, b = r, c = r


        Fields:

            typeName
                - Boundary shape type as string


        Functions:

            function Boundary:contains  (x, y, z)                               returns true/false
                - Check if a position vector (x, y, z) is inside the Boundary instance
                - <y> & <z> are optional arguments

            function Boundary:move      (x, y, z)                               returns self
                - Moves the position of origin of the Boundary

            function Boundary:scale     (a, b, c)                               returns self
                - Scales the size of the dimensions of the Boundary in its local x, y, & z axes by a factor of a, b, & c
                  respectively

            function Boundary:rotate    (i, j, k, radians)                      returns self
                - Rotates the local coordinates of the Boundary about the vector<i, j, k> by a certain amount in radians
                - Useful wrapper for .orient()

            function Boundary:orient    (xi, xj, xk, yi, yj, yk, zi, zj, zk)    returns self
                - Changes the direction as well as the scale of the x, y, & z axes on the Boundary's local coordinate system

            function Boundary:castTo    (boundaryTypeId)                        returns self
                - Typecasts the Boundary into a different type


    |--------------|
    | Sample Usage |
    |--------------|
        (Pseudo code)

        local bounds = Boundary.Cone.Normal.new(x, y, z, coneRadius, coneHeight)

        print(bounds.typeName) -- Prints "Cone"
        GroupEnumUnitsInRange(enumGroup, x, y, coneRadius, null)
        loop
            u = FirstOfGroup(enumGroup)
            exitwhen u == null
            GroupRemoveUnit(enumGroup, u)

            -- Damage units inside cone

            if bounds.contains(GetUnitX(u), GetUnitY(u), GetUnitZ(u)) then
                UnitDamageTarget(source, u, coneDamage, true, false, ATTACK_TYPE_HERO, DAMAGE_TYPE_NORMAL, null)
            end
        end

        bounds.castTo(Boundary.Sphere) // transforms into a Sphere with a radius equal to <coneRadius>

        print(bounds.typeName) // Prints "Sphere"
        GroupEnumUnitsInRange(enumGroup, x, y, radius, null)
        loop
            u = FirstOfGroup(enumGroup)
            exitwhen u == null
            GroupRemoveUnit(enumGroup, u)

            -- Damage units inside sphere

            if bounds.contains(GetUnitX(u), GetUnitY(u), GetUnitZ(u)) then
                UnitDamageTarget(source, u, sphereDamage, true, false, ATTACK_TYPE_HERO, DAMAGE_TYPE_NORMAL, null)
            end
        end

]]--

Boundary = setmetatable({}, {})
do
    local bound = getmetatable(Boundary)
    bound.__index = bound

    -------------------------------------------------------------------------------------

    local ObliqueEllipsoid  = {}
    local ObliquePrism      = {}
    local ObliqueCone       = {}
    local ObliqueCylinder   = {}
    local RotatedEllipsoid  = {}
    local RotatedPrism      = {}
    local RotatedCone       = {}
    local RotatedCylinder   = {}
    local Ellipsoid         = {}
    local Sphere            = {}
    local Prism             = {}
    local Cone              = {}
    local Cylinder          = {}

    bound.Sphere            = Sphere
    bound.Ellipsoid         = {Oblique = ObliqueEllipsoid   , Normal = Ellipsoid}
    bound.Prism             = {Oblique = ObliquePrism       , Normal = Prism    }
    bound.Cone              = {Oblique = ObliqueCone        , Normal = Cone     }
    bound.Cylinder          = {Oblique = ObliqueCylinder    , Normal = Cylinder }

    -------------------------------------------------------------------------------------

    --[[
        Space represents a bounded region in 3D space
        vectors x(x, y, z), y(x, y, z), & z(x, y, z) are the orientation axes of the bounded space
            with their default values at x(1, 0, 0), y(0, 1, 0), & z(0, 0, 1) - similar to the game map axes
        vector o(x, y, z) represents the position of origin
        vector s(a, b, c) represents the distance of boundary from origin of the bounded space in the
            axes x, y, z respectively (see https://upload.wikimedia.org/wikipedia/commons/thumb/3/33/Ellipsoide.svg/800px-Ellipsoide.svg.png )
    ]]--
    local Space = {}
    do
        Space.__index = Space

        -- Checks if the orientation axes of the bounded space are equivalent to an oblique coordinate system
        function Space:isOblique()
            return  self.x:scalarProduct(self.y) ~= 0 or
                    self.x:scalarProduct(self.z) ~= 0 or
                    self.y:scalarProduct(self.z) ~= 0
        end

        function Space:orient(xi, xj, xk, yi, yj, yk, zi, zj, zk)
            local vx, vy, vz = self.x, self.y, self.z

            vx:update(xi, xj, xk)
            vy:update(yi, yj, yk)
            vz:update(zi, zj, zk)

            local rx, ry, rz = 1/vx:length(), 1/vy:length(), 1/vz:length()
            local vs = self.s
            vs:update(vs.x/rx, vs.y/ry, vs.z/rz)

            vx:scale(rx, rx, rx)
            vy:scale(ry, ry, ry)
            vz:scale(rz, rz, rz)
        end

        function Space:castTo(boundaryType)
            setmetatable(self, boundaryType)
            self:updateType()
            return self
        end

        function Space:rotate(i, j, k, radians)
            local axis  = Vector{i, j, k}
            local vx    = self.x:new():rotate(axis, radians)
            local vy    = self.y:new():rotate(axis, radians)
            local vz    = self.z:new():rotate(axis, radians)
            self:orient(vx.x, vx.y, vx.z, vy.x, vy.y, vy.z, vz.x, vz.y, vz.z)
            return self
        end

        function Space.__call(ox, oy, ok, xi, xj, xk, yi, yj, yk, zi, zj, zk, a, b, c)
            return setmetatable
            (
                {
                    o = Vector{ox, oy, oz},
                    x = Vector{xi, xj, xk},
                    y = Vector{yi, yj, yk},
                    z = Vector{zi, zj, zk},
                    s = Vector{a, b or a, c or b or a}
                },
                Space
            )
        end
    end

    -------------------------------------------------------------------------------------

    local function calculateProjections(u, v, dx, dy, dz)
        local rx, ry, rz    = u.x + v.x, u.y + v.y, u.z + v.z
        local r             = (dx*rx + dy*ry + dz*rz)/rx*rx + ry*ry + rz*rz

        return dx - r*rx, dy - r*ry, dz - r*rz
    end

    local function getComponent(u, v, w, dx, dy, dz)
        local x, y, z       = calculateProjections(u, v, dx, dy, dz)
        return x/w.x + y/w.y + z/w.z
    end

    local function boundaryAxisContains(l, u, v, w, dx, dy, dz)
        local x, y, z       = calculateProjections(u, v, dx, dy, dz)
        local r             = l*(w.x*x + w.y*y + w.z*z)

        return x*x + y*y + z*z <= r*r
    end

    -- ObliqueEllipsoid
    do
        local shape = ObliqueEllipsoid
        setmetatable(shape, Space)
        shape.__index = shape
        shape.typeName = "ObliqueEllipsoid"

        function shape:updateType()
            if not self:isOblique() then
                if self.x.x == 1 and self.y.y == 1 then
                    if self.s.x == self.s.y and self.s.y == self.s.z then
                        setmetatable(self, Sphere)
                    else
                        setmetatable(self, Ellipsoid)
                    end
                else
                    setmetatable(self, RotatedEllipsoid)
                end
            end
        end

        function shape:contains(x, y, z)
            local vo, vs = self.o, self.s
            local vx, vy, vz = self.x, self.y, self.z
            local dx, dy, dz = x - vo.x, y - vo.y, z - vo.z

            z = getComponent(vx, vy, vz, dx, dy, dz)
            y = getComponent(vx, vz, vy, dx, dy, dz)
            x = getComponent(vy, vz, vx, dx, dy, dz)

            return (x*x)/(vs.x*vs.x) + (y*y)/(vs.y*vs.y) + (z*z)/(vs.z*vs.z) <= 1
        end

        function shape:scale(...)
            self.s:scale(...)
        end

        function shape:orient(...)
            Space.orient(self, ...)
            self:updateType()
        end

        function shape.__call(...)
            return setmetatable(Space(...), shape)
        end
        function shape.new(...)
            return shape(...)
        end
    end

    -- ObliquePrism
    do
        local shape = ObliquePrism
        setmetatable(shape, Space)
        shape.__index = shape
        shape.typeName = "ObliquePrism"

        function shape:updateType()
            if not self:isOblique() then
                if self.x.x == 1 and self.y.y == 1 then
                    setmetatable(self, Prism)
                else
                    setmetatable(self, RotatedPrism)
                end
            end
        end

        function shape:contains(x, y, z)
            local vo, vs = self.o, self.s
            local vx, vy, vz = self.x, self.y, self.z
            local dx, dy, dz = x - vo.x, y - vo.y, z - vo.z

            return
                boundaryAxisContains(vs.z, vx, vy, vz, dx, dy, dz) and
                boundaryAxisContains(vs.y, vx, vz, vy, dx, dy, dz) and
                boundaryAxisContains(vs.x, vy, vz, vx, dx, dy, dz)
        end

        function shape:scale(...)
            self.s:scale(...)
        end

        function shape:orient(...)
            Space.orient(self, ...)
            self:updateType()
        end

        function shape.__call(...)
            return setmetatable(Space(...), shape)
        end
        function shape.new(...)
            return shape(...)
        end
    end

    -- ObliqueCone
    do
        local shape = ObliqueCone
        setmetatable(shape, Space)
        shape.__index = shape
        shape.typeName = "ObliqueCone"

        function shape:updateType()
            if not self:isOblique() then
                if self.x.x == 1 and self.y.y == 1 then
                    setmetatable(self, Cone)
                else
                    setmetatable(self, RotatedCone)
                end
            end
        end

        function shape:contains(x, y, z)
            local vo, vs = self.o, self.s
            local vx, vy, vz = self.x, self.y, self.z
            local dx, dy, dz = x - vo.x, y - vo.y, z - vo.z

            z = 1 - getComponent(vx, vy, vz, dx, dy, dz)/vs.z

            if z >= 0 and z <= 1 then
                x = getComponent(vy, vz, vx, dx, dy, dz)
                y = getComponent(vx, vz, vy, dx, dy, dz)

                return (x*x)/(vs.x*vs.x) + (y*y)/(vs.y*vs.y) <= z*z
            end

            return false
        end

        function shape:scale(...)
            self.s:scale(...)
        end

        function shape:orient(...)
            Space.orient(self, ...)
            self:updateType()
        end

        function shape.__call(...)
            return setmetatable(Space(...), shape)
        end
        function shape.new(...)
            return shape(...)
        end
    end

    -- ObliqueCylinder
    do
        local shape = ObliqueCylinder
        setmetatable(shape, Space)
        shape.__index = shape
        shape.typeName = "ObliqueCylinder"

        function shape:updateType()
            if not self:isOblique() then
                if self.x.x == 1 and self.y.y == 1 then
                    setmetatable(self, Cylinder)
                else
                    setmetatable(self, RotatedCylinder)
                end
            end
        end

        function shape:contains(x, y, z)
            local vo, vs = self.o, self.s
            local vx, vy, vz = self.x, self.y, self.z
            local dx, dy, dz = x - vo.x, y - vo.y, z - vo.z

            z = getComponent(vx, vy, vz, dx, dy, dz)

            if z*z <= vs.z*vs.z then
                x = getComponent(vy, vz, vx, dx, dy, dz)
                y = getComponent(vx, vz, vy, dx, dy, dz)

                return (x*x)/(vs.x*vs.x) + (y*y)/(vs.y*vs.y) <= 1
            end

            return false
        end

        function shape:scale(...)
            self.s:scale(...)
        end

        function shape:orient(...)
            Space.orient(self, ...)
            self:updateType()
        end

        function shape.__call(...)
            return setmetatable(Space(...), shape)
        end
        function shape.new(...)
            return shape(...)
        end
    end

    -------------------------------------------------------------------------------------

    -- RotatedEllipsoid
    do
        local shape = RotatedEllipsoid
        setmetatable(shape, Space)
        shape.__index = shape
        shape.typeName = "RotatedEllipsoid"

        function shape:updateType()
            if self:isOblique() then
                setmetatable(self, ObliqueEllipsoid)

            elseif self.x.x == 1 and self.y.y == 1 then

                if self.s.x == self.s.y and self.s.y == self.s.z then
                    setmetatable(self, Sphere)
                else
                    setmetatable(self, Ellipsoid)
                end
            end
        end

        function shape:contains(x, y, z)
            local v = self.o
            local rx, ry, rz = x - v.x, y - v.y, z - v.z

            v = self.x
            local dx = rx*v.x + ry*v.y + rz*v.z
            v = self.y
            local dy = rx*v.x + ry*v.y + rz*v.z
            v = self.z
            local dz = rx*v.x + ry*v.y + rz*v.z

            v = self.s
            return (dx*dx)/(v.x*v.x) + (dy*dy)/(v.y*v.y) + (dz*dz)/(v.z*v.z) <= 1
        end

        function shape:scale(...)
            self.s:scale(...)
            self:updateType()
        end

        function shape:orient(...)
            Space.orient(self, ...)
            self:updateType()
        end
    end

    -- RotatedPrism
    do
        local shape = RotatedPrism
        setmetatable(shape, Space)
        shape.__index = shape
        shape.typeName = "RotatedPrism"

        function shape:updateType()
            if self:isOblique() then
                setmetatable(self, ObliquePrism)

            elseif self.x.x == 1 and self.y.y == 1 then
                setmetatable(self, Prism)
            end
        end

        function shape:contains(x, y, z)
            local v, vs = self.o, self.s
            x, y, z = x - v.x, y - v.y, z - v.z

            v = self.z
            local dz, rz = x*v.x + y*v.y + z*v.z, vs.z

            if dz*dz <= rz*rz then
                v = self.y
                local dy, ry = x*v.x + y*v.y + z*v.z, vs.y

                if dy*dy <= ry*ry then
                    v = self.x
                    local dx, rx = x*v.x + y*v.y + z*v.z, vs.x

                    return dx*dx < rx*rx
                end

                return false
            end

            return false
        end

        function shape:scale(...)
            self.s:scale(...)
        end

        function shape:orient(...)
            Space.orient(self, ...)
            self:updateType()
        end
    end

    -- RotatedCone
    do
        local shape = RotatedCone
        setmetatable(shape, Space)
        shape.__index = shape
        shape.typeName = "RotatedCone"

        function shape:updateType()
            if self:isOblique() then
                setmetatable(self, ObliqueCone)

            elseif self.x.x == 1 and self.y.y == 1 then
                setmetatable(self, Cone)
            end
        end

        function shape:contains(x, y, z)
            local v, vs = self.o, self.s
            x, y, z = x - v.x, y - v.y, z - v.z

            v = self.z
            local rz = 1 - (x*v.x + y*v.y + z*v.z)/vs.z

            if rz >= 0 and rz <= 1 then
                v, dx = self.x, x*v.x + y*v.y + z*v.z
                v, dy = self.y, x*v.x + y*v.y + z*v.z

                return (dx*dx)/(vs.x*vs.x) + (dy*dy)/(vs.y*vs.y) <= rz*rz
            end

            return false
        end

        function shape:scale(...)
            self.s:scale(...)
        end

        function shape:orient(...)
            Space.orient(self, ...)
            self:updateType()
        end
    end

    -- RotatedCylinder
    do
        local shape = RotatedCylinder
        setmetatable(shape, Space)
        shape.__index = shape
        shape.typeName = "RotatedCylinder"

        function shape:updateType()
            if self:isOblique() then
                setmetatable(self, ObliqueCylinder)

            elseif self.x.x == 1 and self.y.y == 1 then
                setmetatable(self, Cylinder)
            end
        end

        function shape:contains(x, y, z)
            local v, vs = self.o, self.s
            x, y, z = x - v.x, y - v.y, z - v.z

            v = self.z
            local dz = x*v.x + y*v.y + z*v.z
            local rz = vs.z

            if dz*dz <= rz*rz then
                v = self.x
                local dx = x*v.x + y*v.y + z*v.z
                v = self.y
                local dy = x*v.x + y*v.y + z*v.z

                return (dx*dx)/(vs.x*vs.x) + (dy*dy)/(vs.y*vs.y) <= 1
            end

            return false
        end

        function shape:scale(...)
            self.s:scale(...)
        end

        function shape:orient(...)
            Space.orient(self, ...)
            self:updateType()
        end
    end

    -------------------------------------------------------------------------------------

    -- Ellipsoid
    do
        local shape = Ellipsoid
        setmetatable(shape, Space)
        shape.__index = shape
        shape.typeName = "Ellipsoid"

        function shape:updateType()
            if self:isOblique() then
                setmetatable(self, ObliqueEllipsoid)

            elseif self.s.x == self.s.y and self.s.y == self.s.z then
                setmetatable(self, Sphere)

            elseif not (self.x.x == 1 and self.y.y == 1) then
                setmetatable(self, RotatedEllipsoid)
            end
        end

        function shape:contains(x, y, z)
            local v = self.o
            local dx, dy, dz = x - v.x, y - v.y, z - v.z

            v = self.s
            return (dx*dx)/(v.x*v.x) + (dy*dy)/(v.y*v.y) + (dz*dz)/(v.z*v.z) <= 1
        end

        function shape:scale(...)
            self.s:scale(...)
            self:updateType()
        end

        function shape:orient(...)
            Space.orient(self, ...)
            self:updateType()
        end

        function shape.__call(...)
            return setmetatable(Space(...), shape)
        end
        function shape.new(...)
            return shape(...)
        end
    end

    -- Sphere
    do
        local shape = Sphere
        setmetatable(shape, Space)
        shape.__index = shape
        shape.typeName = "Sphere"

        function shape:updateType()
            if self:isOblique() then
                setmetatable(self, ObliqueEllipsoid)

            elseif self.s.x ~= self.s.y or self.s.y ~= self.s.z then

                if self.x.x == 1 and self.y.y == 1 then
                    setmetatable(self, Ellipsoid)
                else
                    setmetatable(self, RotatedEllipsoid)
                end
            end
        end

        function shape:contains(x, y, z)
            local v, r = self.o, self.s.x
            local dx, dy, dz = x - v.x, y - v.y, z - v.z

            return dx*dx + dy*dy + dz*dz <= r*r
        end

        function shape:scale(...)
            self.s:scale(...)
            self:updateType()
        end

        function shape:orient(...)
            Space.orient(self, ...)
            self:updateType()
        end

        function shape.__call(...)
            return setmetatable(Space(...), shape)
        end
        function shape.new(...)
            return shape(...)
        end
    end

    -- Prism
    do
        local shape = Prism
        setmetatable(shape, Space)
        shape.__index = shape
        shape.typeName = "Prism"

        function shape:updateType()
            if self:isOblique() then
                setmetatable(self, ObliquePrism)

            elseif self.x.x ~= 1 or self.y.y ~= 1 then
                setmetatable(self, RotatedPrism)
            end
        end

        function shape:contains(x, y, z)
            local v, w = self.s, self.o

            return
                z >= (w.z - v.z) and
                z <= (w.z + v.z) and
                y >= (w.y - v.y) and
                y <= (w.y + v.y) and
                x >= (w.x - v.x) and
                x <= (w.x + v.x)
        end

        function shape:scale(...)
            self.s:scale(...)
            self:updateType()
        end

        function shape:orient(...)
            Space.orient(self, ...)
            self:updateType()
        end

        function shape.__call(...)
            return setmetatable(Space(...), shape)
        end
        function shape.new(x, y, z, a, b, c)
            return shape(x, y, z, 1, 0, 0, 0, 1, 0, 0, 0, 1, a, b, c)
        end
        function shape.newEx(minX, minY, minZ, maxX, maxY, maxZ)
            return shape.new((minX + maxX)*0.5, (minY + maxY)*0.5, (minZ + maxZ)*0.5, (maxX - minX)*0.5, (maxY - minY)*0.5, (maxZ - minZ)*0.5)
        end
    end

    -- Cone
    do
        local shape = Cone
        setmetatable(shape, Space)
        shape.__index = shape
        shape.typeName = "Cone"

        function shape:updateType()
            if self:isOblique() then
                setmetatable(self, ObliqueCone)

            elseif not (self.x.x == 1 and self.y.y == 1) then
                setmetatable(self, RotatedCone)
            end
        end

        function shape:contains(x, y, z)
            local vo, vs = self.o, self.s
            local rz = 1 - (z - vo.z)/vs.z

            if rz >= 0 and rz <= 1 then
                local dx, dy = x - vo.x, y - vo.y

                return (dx*dx)/(vs.x*vs.x) + (dy*dy)/(vs.y*vs.y) <= rz*rz
            end

            return false
        end

        function shape:scale(...)
            self.s:scale(...)
        end

        function shape:orient(...)
            Space.orient(self, ...)
            self:updateType()
        end

        function shape.__call(...)
            return setmetatable(Space(...), shape)
        end
        function shape.new(x, y, z, a, b, h)
            return shape(x, y, z, 1, 0, 0, 0, 1, 0, 0, 0, 1, a, b, h)
        end
        function shape.newEx(x, y, r, minZ, maxZ)
            return shape.new(x, y, (minZ + maxZ)*0.5, r, r, maxZ - minZ)
        end
    end

    -- Cylinder
    do
        local shape = Cylinder
        setmetatable(shape, Space)
        shape.__index = shape
        shape.typeName = "Cylinder"

        function shape:updateType()
            if self:isOblique() then
                setmetatable(self, ObliqueCylinder)

            elseif not (self.x.x == 1 and self.y.y == 1) then
                setmetatable(self, RotatedCylinder)
            end
        end

        function shape:contains(x, y, z)
            local v, w = self.s, self.o

            if z >= (w.z - v.z) and z <= (w.z + v.z) then
                local dx, dy = x - w.x, y - w.y

                return (dx*dx)/(v.x*v.x) + (dy*dy)/(v.y*v.y) <= 1
            end

            return false
        end

        function shape:scale(...)
            self.s:scale(...)
        end

        function shape:orient(...)
            Space.orient(self, ...)
            self:updateType()
        end

        function shape.__call(...)
            return setmetatable(Space(...), shape)
        end
        function shape.new(x, y, z, a, b, h)
            return shape(x, y, z, 1, 0, 0, 0, 1, 0, 0, 0, 1, a, b, h)
        end
        function shape.newEx(x, y, z, r, minZ, maxZ)
            return shape.new(x, y, (minZ + maxZ)*0.5, r, r, maxZ - minZ)
        end
    end

end