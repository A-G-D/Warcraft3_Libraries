--[[ Vector3.lua v1.0.0-rc | https://raw.githubusercontent.com/A-G-D/Warcraft3_Libraries/master/Lua/Vector3.lua


    Author:
        - AGD


    API:

        Constants:

            Vector3.NULL
                - (0, 0, 0) vector

            Vector3.I
            Vector3.J
            Vector3.K
                - Unit vectors for x, y, and z axes respectively

        Fields:

            Vector3.x
            Vector3.y
            Vector3.z
                - Vector3 components

        Constructor:

            function Vector3{x, y, z}                    returns Vector3
                - Parameter is optional

        Member Functions:

            function Vector3:magnitude()                 returns number
            function Vector3:length()                    returns number
            function Vector3:squaredLength()             returns number

            function Vector3:update(x, y, z)             returns self

            function Vector3:add(...)                    returns self
            function Vector3:subtract(...)               returns self
                - Accepts multiple Vector3s as arguments

            function Vector3:scale(a, b, c)              returns self

            function Vector3:normalize()                 returns self
                - Turns a Vector3 into a unit vector

            function Vector3:projectToVector3(v)         returns self
            function Vector3:projectToPlane(normal)      returns self

            function Vector3:rotate(axis, radians)       returns self
                - <axis> Vector3 need not be normalized

            function Vector3:getAngle(v)                 returns number
                - Gets the angle between two Vector3s

            function Vector3:scalarTripleProduct(v, w)   returns number
            function Vector3:vectorTripleProduct(v, w)   returns Vector3

            function Vector3:unpack()                    returns self.x, self.y, self.z

        Metamethods:

            function vec:__add(v)
                - Gets the sum of two Vector3s
            function vec:__sub(v)
                - Gets the difference between two Vector3s
            function vec:__mul(v)
                - Can be used to get the cross product of two Vector3s, or a scaled version of
                  a Vector3 if the <v> argument is a number
            function vec:__concat(v)
                - Returns the dot product of two Vector3s

            function vec:__unm(v)
                - Gets the inverse of the Vector3

            function vec:__eq(v)
                - Equality check operator

            function vec:__tostring()

]]--
Vector3 = setmetatable({}, {})

do

    local vec = getmetatable(Vector3)
    local index = {x = 1, y = 2, z = 3}

    function vec.__index(table, key)
        return table[index[key]]
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
    function vec:magnitude()
        return self:length()
    end
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
        local n = select("#", ...)
        if n > 0 then
            for i = 1, n do
                local v = select(i, ...)
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
        return create(v[2]*w[3] - v[3]*w[2], v[3]*w[1] - v[1]*w[3], v[1]*w[2] - v[2]*w[1])
    end
    function vec:scalarTripleProduct(v, w)
        return vectorProduct(self, v) .. w
    end
    function vec:vectorTripleProduct(v, w)
        return createScaled(v, self .. w) - createScaled(w, self .. v)
    end

    function vec:projectToVector3(v)
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

return Vector3