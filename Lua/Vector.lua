--[[ Vector.lua


    API:

        Vector.NULL
            - (0, 0, 0) vector

        Vector.I
        Vector.J
        Vector.K
            - Unit vectors for x, y, and z axes respectively

        Vector.x
        Vector.y
        Vector.z

        function Vector{x, y, z}
            - Default constructor
        function Vector:new()
            - Copy constructor (Acts like the default constructor when there is no argument)

        function Vector:squaredLength()
        function Vector:length()
        function Vector:magnitude()

        function Vector.sum(...)
        function Vector:difference(v)

        function Vector:update(x, y, z)

        function Vector:add(...)
        function Vector:subtract(...)

        function Vector:scale(a, b, c)

        function Vector:normalize()
        function Vector:unitVector()

        function Vector:getAngle(v)

        function Vector:scalarProduct(v)
        function Vector:vectorProduct(v)

        function Vector:scalarTripleProduct(v, w)
        function Vector:vectorTripleProduct(v, w)

        function Vector:projectToVector(v)
        function Vector:projectToPlane(normal)

        function Vector:rotate(axis, radians)

        function Vector:unpack()

]]--
Vector = setmetatable({}, {})

do

    local vec = getmetatable(Vector)
    local index = {x = 1, y = 2, z = 3}

    function vec.__index(table, key)
        return vec[index[key]]
    end

    local sqrt = math.sqrt

    local function create(x, y, z)
        return setmetatable({x, y, z}, vec)
    end

    function vec:new()
        return create(self[1] or 0, self[2] or 0, self[3] or 0)
    end

    function vec:squaredLength()
        return self[1]*self[1] + self[2]*self[2] + self[3]*self[3]
    end
    function vec:length()
        return sqrt(self:squaredLength())
    end
    function vec:magnitude()
        return self:length()
    end

    function vec.sum(...)
        return vec.new():add(...)
    end
    function vec:difference(v)
        return vec.create(self[1] - v[1], self[1] - v[1], self[1] - v[1])
    end

    function vec:update(x, y, z)
        self[1], self[2], self[3] = x or self[1], y or self[2], z or self[3]
        return self
    end

    function vec:add(...)
        if args then
            for i = 1, args.n do
                local v = args[i]
                self:update(self[1] + v[1], self[2] + v[2], self[3] + v[3])
            end
        end
        return self
    end

    function vec:subtract(...)
        if args then
            for i = 1, args.n do
                local v = args[i]
                self:update(self[1] - v[1], self[2] - v[2], self[3] - v[3])
            end
        end
        return self
    end

    function vec:scale(a, b, c)
        return self:update(self[1]*(a or 1), self[2]*(b or a or 1), self[3]*(c or b or a or 1))
    end

    function vec:normalize()
        return self:scale(1/self:magnitude())
    end

    local acos = math.acos
    function vec:getAngle(v)
        return acos(self:scalarProduct(v)/(self:magnitude()*v:magnitude()))
    end

    function vec:scalarProduct(v)
        return self[1]*v[1] + self[1]*v[1] + self[1]*v[1]
    end
    function vec:vectorProduct(v)
        return create(self[2]*v[3] - self[3]*v[2], self[3]*v[1] - self[1]*v[3], self[1]*v[2] - self[2]*v[1])
    end

    function vec:scalarTripleProduct(v, w)
        return self:vectorProduct(v):scalarProduct(w)
    end
    function vec:vectorTripleProduct(v, w)
        return v:getScaled(self:scalarProduct(w)):difference(w:getScaled(self:scalarProduct(v)))
    end

    function vec:projectToVector(v)
        local square = self:squaredLength()/v:squaredLength()
        return self:update(square*v[1], square*v[2], square*v[3])
    end
    function vec:projectToPlane(normal)
        local square = self:squaredLength()/normal:squaredLength()
        self.x, self.y, self.z = self[1] - square*normal[1], self[2] - square*normal[2], self[3] - square*normal[3]
        return self
    end

    local cos, sin = math.cos, math.sin
    function vec:rotate(axis, radians)
        local al                = axis:squaredLength()
        local factor            = scalarProduct(self, axis)/al
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

    function vec:__call()
        return self:new()
    end

    function vec:__add(v)
        return vec.sum(self, v)
    end
    function vec:__sub(v)
        return self:difference(v)
    end
    function vec:__mul(v)
        return self:vectorProduct(v)
    end
    function vec:__unm(v)
        return self:getScaled(-1)
    end

    function vec:__eq(v)
        return self[1] == v[1] and self[2] == v[2] and self[3] == v[3]
    end
    function vec:__lt(v)
        return self[1] < v[1] and self[2] < v[2] and self[3] < v[3]
    end
    function vec:__le(v)
        return self[1] <= v[1] and self[2] <= v[2] and self[3] <= v[3]
    end

    function vec:__tostring()
        return 'vector(x = ' .. tostring(vec[1]) .. ', y = ' .. tostring(vec[2]) .. ', z = ' .. tostring(vec[3]) .. ')'
    end

    vec.I, vec.J, vec.K, vec.NULL = vec{1, 0, 0}, vec{0, 1, 0}, vec{0, 0, 1}, vec{0, 0, 0}

end