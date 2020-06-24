library MapBounds /* v1.0.0


    Author: AGD
    Based on Nestharus's WorldBounds

    *///! novjass

    |=====|
    | API |
    |=====|

        struct MapBounds extends array      // Refers to initial playable map bounds
        struct WorldBounds extends array    // Refers to world bounds

            readonly static real centerX
            readonly static real centerY
            readonly static real minX
            readonly static real minY
            readonly static real maxX
            readonly static real maxY
            readonly static rect rect
            readonly static region region

            static method getArea takes nothing returns real

            static method getBoundedX takes real x returns real
            static method getBoundedY takes real y returns real/*
                - Returns a coordinate that is inside the bounds
          */static method containsX takes real x returns boolean
            static method containsY takes real y returns boolean/*
                - Checks if the bound contains the input coordinate
    */

    //! endnovjass

    private module CommonMembers
        readonly static real centerX
        readonly static real centerY
        readonly static real minX
        readonly static real minY
        readonly static real maxX
        readonly static real maxY
        readonly static rect rect
        readonly static region region

        static method getArea takes nothing returns real
            return (maxX - minX)*(maxY - minY)
        endmethod

        static method getBoundedX takes real x returns real
            if x < minX then
                return minX
            elseif x > maxX then
                return maxX
            endif
            return x
        endmethod
        static method getBoundedY takes real y returns real
            if y < minY then
                return minY
            elseif y > maxY then
                return maxY
            endif
            return y
        endmethod

        static method containsX takes real x returns boolean
            return getBoundedX(x) == x
        endmethod
        static method containsY takes real y returns boolean
            return getBoundedY(y) == y
        endmethod

        private static method onInit takes nothing returns nothing
            set region = CreateRegion()
            set rect = getRect()
            set minX = GetRectMinX(rect)
            set minY = GetRectMinY(rect)
            set maxX = GetRectMaxX(rect)
            set maxY = GetRectMaxY(rect)
            set centerX = (minX + maxX)/2.00
            set centerY = (minY + maxY)/2.00
            call RegionAddRect(region, rect)
        endmethod
    endmodule

    struct MapBounds extends array
        private static method getRect takes nothing returns rect
            return bj_mapInitialPlayableArea
        endmethod
        implement CommonMembers
    endstruct

    struct WorldBounds extends array
        private static method getRect takes nothing returns rect
            return GetWorldBounds()
        endmethod
        implement CommonMembers
    endstruct


endlibrary
