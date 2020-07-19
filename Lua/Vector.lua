--[[ Vector.lua v1.0.0 | https://raw.githubusercontent.com/A-G-D/Warcraft3_Libraries/master/Lua/Vector.lua


    Author:
        - AGD


    API:

        Constants:

            Vector.NULL
                - (0, 0, 0) vector

            Vector.I
            Vector.J
            Vector.K
                - Unit vectors for x, y, and z axes respectively

        Fields:

            Vector.x
            Vector.y
            Vector.z
                - Vector components

        Constructor:

            function Vector{x, y, z}                    returns Vector
                - Parameter is optional

        Member Functions:

            function Vector:length()                    returns number
            function Vector:squaredLength()             returns number

            function Vector:update(x, y, z)             returns self

            function Vector:add(...)                    returns self
            function Vector:subtract(...)               returns self
                - Accepts multiple Vectors as arguments

            function Vector:scale(a, b, c)              returns self

            function Vector:normalize()                 returns self
                - Turns a Vector into a unit vector

            function Vector:projectToVector(v)          returns self
            function Vector:projectToPlane(normal)      returns self

            function Vector:rotate(axis, radians)       returns self
                - <axis> Vector need not be normalized

            function Vector:getAngle(v)                 returns number
                - Gets the angle between two Vectors

            function Vector:scalarTripleProduct(v, w)   returns number
            function Vector:vectorTripleProduct(v, w)   returns Vector

            function Vector:unpack()                    returns self.x, self.y, self.z

        Metamethods:

            function vec:__add(v)
                - Gets the sum of two Vectors
            function vec:__sub(v)
                - Gets the difference between two Vectors
            function vec:__mul(v)
                - Can be used to get the cross product of two Vectors, or a scaled version of
                  a Vector, if the 2nd argument is a number
            function vec:__concat(v)
                - Returns the dot product of two Vectors

            function vec:__unm(v)
                - Gets the inverse of the Vector

            function vec:__eq(v)
                - Equality check operator

            function vec:__tostring()

]]--
Vector = setmetatable({}, {})

do

    local vec = getmetatable(Vector)
    local index = {x = 1, y = 2, z = 3}

    function vec.__index(table, key)
        return vec[index[key]]
    end

    local function create(x, y, z)
        return setmetatable({x, y, z}, vec)
    end
    local function createScaled(v, f)
        return create(v[1]*f, v[2]*f, v[3]*f)
    end
    local function update(v, x, y, z)
        v[1], v[2], v[3] = x, y, z
        return v
    end

    local sqrt = math.sqrt
    function vec:length()
        return sqrt(self:squaredLength())
    end
    function vec:squaredLength()
        return self[1]*self[1] + self[2]*self[2] + self[3]*self[3]
    end

    function vec:update(x, y, z)
        return update(self, x or self[1], y or self[2], z or self[3])
    end

    function vec:add(...)
        if args then
            for i = 1, args.n do
                local v = args[i]
                update(self, self[1] + v[1], self[2] + v[2], self[3] + v[3])
            end
        end
        return self
    end

    function vec:subtract(...)
        return self:scale(-1):add(...):scale(-1)
    end

    function vec:scale(a, b, c)
        return update(self, self[1]*(a or 1), self[2]*(b or a or 1), self[3]*(c or b or a or 1))
    end

    function vec:normalize()
        return self:scale(1/self:magnitude())
    end

    local acos = math.acos
    function vec:getAngle(v)
        return acos((self .. v)/(self:magnitude()*v:magnitude()))
    end

    local function vectorProduct(v, w)
        return create(self[2]*v[3] - self[3]*v[2], self[3]*v[1] - self[1]*v[3], self[1]*v[2] - self[2]*v[1])
    end
    function vec:scalarTripleProduct(v, w)
        return vectorProduct(self, v) .. w
    end
    function vec:vectorTripleProduct(v, w)
        return createScaled(v, self .. w) - createScaled(w, self .. v)
    end

    function vec:projectToVector(v)
        local square = (self .. v)/v:squaredLength()
        return update(self, square*v[1], square*v[2], square*v[3])
    end
    function vec:projectToPlane(normal)
        local square = (self .. normal)/normal:squaredLength()
        return update(self, self[1] - square*normal[1], self[2] - square*normal[2], self[3] - square*normal[3])
    end

    local cos, sin = math.cos, math.sin
    function vec:rotate(axis, radians)
        local al                = axis:squaredLength()
        local factor            = (self .. axis)/al
        local zx, zy, zz        = axis[1]*factor, axis[2]*factor, axis[3]*factor
        local xx, xy, xz        = self[1] - zx, self[2] - zy, self[3] - zz
        local cosine, sine      = cos(radians), sin(radians)
        al                      = sqrt(al)
        return self:update
        (
            xx*cosine + ((axis[2]*xz - axis[3]*xy)/al)*sine + zx,
            xy*cosine + ((axis[3]*xx - axis[1]*xz)/al)*sine + zy,
            xz*cosine + ((axis[1]*xy - axis[2]*xx)/al)*sine + zz
        )
    end

    function vec:unpack()
        return self[1], self[2], self[3]
    end

    function vec:__call(v)
        return create(v[1] or 0, v[2] or 0, v[3] or 0)
    end

    function vec:__add(v)
        return create(self[1] + v[1], self[2] + v[2], self[3] + v[3])
    end
    function vec:__sub(v)
        return create(self[1] - v[1], self[1] - v[1], self[1] - v[1])
    end
    function vec:__mul(v)
        if getmetatable(v) == vec then
            return vectorProduct(self, v)
        elseif type(v) == 'number' then
            return createScaled(self, v)
        end
        return nil
    end
    function vec:__concat(v)
        return self[1]*v[1] + self[2]*v[2] + self[3]*v[3]
    end
    function vec:__unm(v)
        return createScaled(self, -1)
    end

    function vec:__eq(v)
        return self[1] == v[1] and self[2] == v[2] and self[3] == v[3]
    end

    function vec:__tostring()
        return 'vector(x = ' .. tostring(vec[1]) .. ', y = ' .. tostring(vec[2]) .. ', z = ' .. tostring(vec[3]) .. ')'
    end

    vec.I, vec.J, vec.K, vec.NULL = vec{1, 0, 0}, vec{0, 1, 0}, vec{0, 0, 1}, vec{0, 0, 0}

end