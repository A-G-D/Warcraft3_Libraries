--[[ Vector library


    API:

        struct Vector

          */static constant Vector NULL     /*  Vector(0)

            - Constant unit vectors:
          */static constant Vector X_AXIS   /*
          */static constant Vector Y_AXIS   /*
          */static constant Vector Z_AXIS   /*

            - Fields:
          */real x                          /*
          */real y                          /*
          */real z                          /*
          */real magnitude                  /*
          */boolean zero                    /*  Checks if the vector has zero magnitude
          */debug boolean constant          /*  Checks if the vector is one of the constant unit vectors
          */debug boolean allocated         /*

            - Methods: You can append a negative (-) sign to the vector arguments to temporarily inverse them inside the
                       methods they are passed into, but you can't do this to the vector instance for whom the method is called.
                       For example, if you want to get the difference between two vectors, you can do "Vector.sum(vecA, -vecB)".
          */static method   create              takes real x, real y, real z                            returns Vector/*
          */method          destroy             takes nothing                                           returns nothing/*
            - Constructor/Destructor

          */static method   operator []         takes Vector whichVector                                returns Vector/*
            - Copy Constructor
          */static method   operator []=        takes Vector destination, Vector source                 returns nothing/*
            - Overwrite Operator
          */method          operator ==         takes Vector whichVector                                returns boolean/*
          */method          operator !=         takes Vector whichVector                                returns boolean/*
          */method          operator <          takes Vector whichVector                                returns boolean/*
          */method          operator >          takes Vector whichVector                                returns boolean/*
            - Relational Operators
            - The == and != operators check if the two vectors have the same components
            - The < and > operators compares the magnitude of the two vectors

          */static method   getAngle            takes Vector vecA, Vector vecB                          returns real/*
            - Returns the angle between two vectors in radians

          */static method   sum                 takes Vector vecA, Vector vecB                          returns Vector/*
          */method          add                 takes Vector whichVector                                returns this/*

          */static method   getScaled           takes Vector whichVector, real scaleValue               returns Vector/*
          */method          scale               takes real scaleValue                                   returns this/*

          */static method   getDirection        takes nothing                                           returns Vector/*
            - Returns the vector's unit vector
          */method          setDirection        takes Vector whichVector                                returns this/*
            - <whichVector> need not be a unit vector

          */static method   getRotated          takes Vector whichVector, Vector axis, real radians     returns Vector/*
          */method          rotate              takes Vector axis, real radians                         returns this/*

          */static method   inverse             takes Vector whichVector                                returns Vector/*
            - Returns the negative of this vector as a new vector
          */method          invert              takes nothing                                           returns this/*
            - Turns this vector into its negative

          */static method   scalarProduct       takes Vector vecA, Vector vecB                          returns real/*
            - Performs a dot product between two vectors (vecA.vecB)
          */static method   vectorProduct       takes Vector vecA, Vector vecB                          returns Vector/*
            - Performs a cross product between two vectors (vecA x vecB)

          */static method   scalarTripleProduct takes Vector vecA, Vector vecB, Vector vecC             returns real/*
            - Returns (vecA x vecB . vecC)
          */static method   vectorTripleProduct takes Vector vecA, Vector vecB, Vector vecC             returns Vector/*
            - Returns (vecA x vecB x vecC)

          */static method   vectorProjection    takes Vector whichVector, Vector direction              returns Vector/*
          */method          projectToVector     takes Vector direction                                  returns this/*
            - Direction vector must not be zero

          */static method   planeProjection     takes Vector whichVector, Vector normal                 returns Vector/*
          */method          projectToPlane      takes Vector normal                                     returns this/*
            - Normal vector must not be zero

          */method          hook                takes Vector whichVector                                returns this/*
          */method          unhook              takes Vector whichVector                                returns this/*
          */method          clearHooks          takes nothing                                           returns this/*
          */method          clearLinks          takes nothing                                           returns this/*
            - Hooking a vector causes this vector to be dependent on the properties of the hooked vector, turning this vector
              into a function of another vector (or vectors, since you can hook multiple vectors)
            - In other words, any modification on the hooked vector will also modify this vector
            - Vector(this).x = this.x + hookedVec[1].x + ... + hookedVec[N].x (Where 'this.x' is this vector's 'own x')
            - clearHooks() unhooks all of this vector's hooked vectors
            - clearLinks() unhooks this vector from all of its hookers

]]--
Vector = setmetatable({}, {})

do

    local vec = getmetatable(Vector)
    local index = {x = 1, y = 2, z = 3}

    function vec.__index(table, key)
        return vec[index[key]]
    end

    local sqrt = math.sqrt

    function vec:new()
        setmetatable({self[1] or 0, self[2] or 0, self[3] or 0}, vec)
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
        return vec.new{self[1] - v[1], self[1] - v[1], self[1] - v[1]}
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
    function vec:getScaled(a, b, c)
        return self:new():scale(a, b, c)
    end

    function vec:normalize()
        return self:scale(1/self:magnitude())
    end
    function vec:unitVector()
        return self:new():normalize()
    end

    local acos = math.acos
    function vec:getAngle(v)
        return acos(self:scalarProduct(v)/(self:magnitude()*v:magnitude()))
    end

    function vec:scalarProduct(v)
        return self[1]*v[1] + self[1]*v[1] + self[1]*v[1]
    end
    function vec:vectorProduct(v)
        return vec.new{self[2]*v[3] - self[3]*v[2], self[3]*v[1] - self[1]*v[3], self[1]*v[2] - self[2]*v[1]}
    end

    function vec:scalarTripleProduct(v, w)
        return self:vectorProduct(v):scalarProduct(w)
    end
    function vec:vectorTripleProduct(v, w)
        return v:scale(self:scalarProduct(w)):new():difference(w:scale(self:scalarProduct(v)))
    end

    function vec:projectToVector(v)
        local square = self:squaredLength()/v:squaredLength()
        return self:update(square*v[1], square*v[2], square*v[3])
    end
    function vec:projectToPlane(normal)
        local square = self:squaredLength()/v:squaredLength()
        local x, y, z = square*v[1], square*v[2], square*v[3]
        return self:update(self[1] - x, self[2] - y, self[3] - z)
    end

    function vec:vectorProjection(v)
        return self:new():projectToVector(v)
    end
    function vec:planeProjection(normal)
        return self:new():projectToPlane(normal)
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
    function vec:getRotated(axis, radians)
        return self:new():rotate(axis, radians)
    end

    function vec:unpack()
        return self[1], self[2], self[3]
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
        return self:new():scale(-1)
    end
    function vec:__call(v)
        return self:new(v)
    end

    vec.X_AXIS, vec.Y_AXIS, vec.Z_AXIS = vec{1, 0, 0}, vec{0, 1, 0}, vec{0, 0, 1}

end