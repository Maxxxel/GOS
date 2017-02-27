--[[
        2D Geometry by Maxxxel
        (Credits Husky for the Original Version)

    0.42 Updated Polygon Contains function
    0.43 Updated Closest Point of Circle for given Point (__pointCircleClosest)
    0.44 Updated LineSegemnt distance to point
    0.45 Changed Point translation
    0.46 Updated LineSegment Distance to point
    0.47 Fixed little Bug
    0.48 Added Multiload check and small bugfix, also delayed the Update
    0.50 Updated for Gos ext
    0.51 Fixed an error with Line
--]]

local Version2DGeometry = 0.51
local uniqueId = 0

class "Point"
    --[[
        Takes a 3D Vector or an obj as input and converts it to a 2D Point
    --]]
    function Point:__init(x, y, z)
        uniqueId = uniqueId + 1
        self.uniqueId = uniqueId
        self.type = "Point"

        if type(x) == "number" then
            self.x = x
            self.y = z and z ~= 0 and z < 999999 and z or y
        else
            self.x = x.pos and x.pos.x or x.x
            self.y = x.pos and (x.pos.z and x.pos.z ~= 0 and x.pos.z < 999999 and x.pos.z or x.pos.y) or (x. z and x.z ~= 0 and x.z < 999999 and x.z or x.y)
        end

        self.points = {self}
    end
    --[[
        Compares 2 points
    --]]
    function Point:__equal(Object)
        return Object.type == "Point" and self.x == Object.x and self.y == Object.y
    end
    --[[
        Neagtativate a Point
    --]]
    function Point:__makeNegative()
        return Point(-self.x, -self.y)
    end
    --[[
        Add a Point to another or by a value
    --]]
    function Point:__addition(v)
        if type(v) == "number" then
            return Point(self.x + v, self.y + v)
        elseif v.type == "Point" then
            return Point(self.x + v.x, self.y + v.y)
        else
            PrintChat("Error on Point:__addition, value is unexpected")
        end
    end
    --[[
        Returns the addition value of the Point
    --]]
    function Point:__additionValue()
        return self.x + self.y
    end
    --[[
        Perependicular
    --]]
    function Point:__perpendicular()
        return Point(self.y, -self.x)
    end
    --[[
        Substract a Point
    --]]
    function Point:__substract(v)
        if type(v) == "number" then
            return Point(self.x - v, self.y - v)
        elseif v.type == "Point" then
            return Point(self.x - v.x, self.y - v.y)
        else
            PrintChat("Error on Point:__substract, value is unexpected")
        end
    end
    --[[
        Multiply a Point
    --]]
    function Point:__multiply(v)
        if type(v) == "number" then
            return Point(self.x * v, self.y * v)
        elseif v.type == "Point" then
            return Point(self.x * v.x, self.y * v.y)
        else
            PrintChat("Error on Point:__multiply, value is unexpected: ".. type(v))
        end
    end
    --[[
        Divide a Point
    --]]
    function Point:__divide(v)
        if type(v) == "number" then
            return Point(self.x / v, self.y / v)
        elseif v.type == "Point" then
            return Point(self.x / v.x, self.y / v.y)
        else
            PrintChat("Error on Point:divide, value is unexpected")
        end
    end
    --[[
        Get the length of a Point
    --]]
    function Point:__length()
        return math.sqrt((self:__expand()):__additionValue())
    end
    --[[
        multiplay a Point by itslef
    --]]
    function Point:__expand()
        return self:__multiply(self)
    end
    --[[
        Translate a Point to a string value
    --]]
    function Point:__toString()
        if self.type == "Point" then
            return "Point("..tostring(self.x)..","..tostring(self.y)..")"
        else
            PrintChat("Error on __toString")
        end
    end
    --[[
        Clone a Point
    --]]
    function Point:__clone()
        return Point(self.x, self.y)
    end
    --[[
        Returns all Points in Point (its just the Point)
    --]]
    function Point:__getPoints()
        return self.points
    end
    --[[
        Check if Point is inside of an object
    --]]
    function Point:__insideOf(Object)
        return Object:__contains(self)
    end
    --[[
        Distance from Point to different objects
    --]]
    function Point:__distance(Object)
        if Object.type == "Point" then
            return (self:__substract(Object)):__length()
        elseif Object.type == "Line" then
            return Object:__distance(self)
        elseif Object.type == "LineSegment" then
            return Object:__distance(self)
        elseif Object.type == "Circle" then
            return (self:__substract(Object.point)):__length() - Object.radius
        else
            return (self:__substract(Point(Object))):__length()
        end
    end
    --[[
        Returns the closest Point to a given Point on a given Segment
    --]]
    function Point:__ClosestPointTo(Object)
        if Object.type == "LineSegment" then
            xDelta = Object.points[2].x - Object.points[1].x
            yDelta = Object.points[2].y - Object.points[1].y

            if ((xDelta == 0) and (yDelta == 0)) then
                print("Segment start equals segment end")
            end

            local u = ((self.x - Object.points[1].x) * xDelta + (self.y - Object.points[1].y) * yDelta) / (xDelta * xDelta + yDelta * yDelta)
            local closestPoint = nil

            if (u < 0) then
                closestPoint = Point(Object.points[1].x, Object.points[1].y)
            elseif (u > 1) then
                closestPoint = Point(Object.points[2].x, Object.points[2].y)
            else
                closestPoint = Point(math.ceil(Object.points[1].x + u * xDelta),  math.ceil(Object.points[1].y + u * yDelta))
            end

            return closestPoint
        elseif Object.type == "Polygon" then
            local bestDistance = 999999
            local bestSegment = nil
            local bestPoint = nil

            for i, s in ipairs(Object:__getLineSegments()) do
                local closestInS = self:__ClosestPointTo(s)
                local d = self:__distance(closestInS)

                if (d < bestDistance) then
                    bestDistance = d
                    bestSegment = s
                    bestPoint = closestInS
                end
            end

            return bestPoint, bestSegment
        elseif Object.type == "Circle" then
            local c = self.point
            local r = self.radius
            local vX = p.x - c.x
            local vY = p.y - c.y
            local magV = math.sqrt(vX * vX + vY * vY)
            local aX = c.x + vX / magV * r
            local aY = c.y + vY / magV * r

            return Point(aX, aY)
            --Test: p = 2, 2, c = 0, 0, r = 1
        end
    end

class "Line"
    --[[
        Creates a Line between 2 Points
    --]]
    function Line:__init(Point1, Point2)
        uniqueId = uniqueId + 1
        self.uniqueId = uniqueId
        self.type = "Line"

        local A, B = Point1, Point2

        if Point1.type ~= "Point" then
            A = Point(Point1)
        end

        if Point2.type ~= "Point" then
            B = Point(Point2)
        end

        self.points = {A, B}
    end
    --[[
        Conmpares 2 Lines
    --]]
    function Line:__equal(Object)
        return Object.type == "Line" and self:distance(Object) == 0
    end
    --[[
        Returns the Points of a Line
    --]]
    function Line:__getPoints()
        return self.points
    end
    --[[
        Returns the Linesegemnts (Line is a infinite Segment)
    --]]
    function Line:__getLineSegments()
        return {self}
    end
    --[[
        Check if Line contains an object
    --]]
    function Line:__contains(Object)
        if Object.type == "Point" then
            return Object:__distance(self) == 0
        elseif Object.type == "Line" then
            return self.points[1]:__distance(Object) == 0 and self.points[2]:__distance(Object) == 0
        elseif Object.type == "Circle" then
            return Object.point:__distance(self) == 0 and Object.radius == 0
        elseif Object.type == "LineSegment" then
            return Object.points[1]:__distance(self) == 0 and Object.points[2]:__distance(self) == 0
        else
            PrintChat("Error on Line:__contains, ObjectType is unexpected")
        end
    end
    --[[
        Chek if the Line is inside an other object
    --]]
    function Line:__insideOf(Object)
        return Object:__contains(self)
    end
    --[[
        Returns the distance of the Line to other objects
    --]]
    function Line:__distance(Object)
        if Object.type == "Circle" then
            return Object.point:distance(self) - Object.radius
        elseif Object.type == "Line" then
            local distance1 = self.points[1]:__distance(Object)
            local distance2 = self.points[2]:__distance(Object)
            if distance1 ~= distance2 then
                return 0 --they touch in a point
            else
                return distance1
            end
        elseif Object.type == "Point" then
            local denominator = self.points[2].x - self.points[1].x
            if denominator == 0 then
                return math.abs(Object.x - self.points[2].x)
            end

            local m = (self.points[2].y - self.points[1].y) / denominator
            return math.abs((m * Object.x - Object.y + (self.points[1].y - m * self.points[1].x)) / math.sqrt(m * m + 1))
        else
            PrintChat("Error on Line:__distance, ObjectType is unexpected")
        end
    end
    --[[
        Draws the Line
    --]]
    function Line:__draw(width, color)
        --local newPoint1 = WorldToScreen(1, self.points[1].x, self.points[1].y, self.points[1].z)
        --local newPoint2 = WorldToScreen(1, self.points[2].x, self.points[2].y, self.points[2].z)
        local A = Vector(self.points[1].x, 0, self.points[1].y):To2D()
    	local B = Vector(self.points[2].x, 0, self.points[2].y):To2D()
    	
    	if A.onScreen and B.onScreen then
        	Draw.Line(A.x, A.y, B.x, B.y, width or 4, color or Draw.Color(255, 255, 0, 0))
        end
    end

class "Circle"
    --[[
        Creates a Cirle
    --]]
    function Circle:__init(point, radius)
        uniqueId = uniqueId + 1
        self.uniqueId = uniqueId
        self.point = point
        self.radius = radius
        self.type = "Circle"

        self.points = {self.point}
    end
    --[[
        Comapres 2 Circles
    --]]
    function Circle:__equal(spatialObject)
        return spatialObject.type == "Circle" and (self.point == spatialObject.point and self.radius == spatialObject.radius)
    end
    --[[
        Retunrs the Points of a circle
    --]]
    function Circle:__getPoints()
        return self.points
    end
    --[[
        Returns the LineSegements of a Circle (Circles dont have LineSegemnts)
    --]]
    function Circle:__getLineSegments()
        return {}
    end
    --[[
        Check if a Circle contains an object
    --]]
    function Circle:__contains(spatialObject)
        if spatialObject.type == "Line" then
            return false
        elseif spatialObject.type == "Circle" then
            return self.radius >= spatialObject.radius + self.point:__distance(spatialObject.point)
        else
            for i, point in ipairs(spatialObject:__getPoints()) do
                if self.point:__distance(point) >= self.radius then
                    return false
                end
            end

            return true
        end
    end
    --[[
        Check if a Circle is inside an object
    --]]
    function Circle:__insideOf(spatialObject)
        return spatialObject:__contains(self)
    end
    --[[
        Retunrs the distance from the circle to an other object
    --]]
    function Circle:__distance(spatialObject)
        return self.point:__distance(spatialObject) - self.radius
    end
    --[[
        Returns the intersection points of the circle and an object
    --]]
    function Circle:__intersectionPoints(spatialObject)
        local result = {}

        if spatialObject.type == "Circle" then
            local dx = self.point.x - spatialObject.point.x
            local dy = self.point.y - spatialObject.point.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist > self.radius + spatialObject.radius then
                return result
            elseif dist < math.abs(self.radius - spatialObject.radius) then
                return result
            elseif (dist == 0) and (self.radius == spatialObject.radius) then
                return result
            else
                local a = (self.radius * self.radius - spatialObject.radius * spatialObject.radius + dist * dist) / (2 * dist)
                local h = math.sqrt(self.radius * self.radius - a * a)

                local cx2 = self.point.x + a * (spatialObject.point.x - self.point.x) / dist
                local cy2 = self.point.y + a * (spatialObject.point.y - self.point.y) / dist

                local intersectionx1 = cx2 + h * (spatialObject.point.y - self.point.y) / dist
                local intersectiony1 = cy2 - h * (spatialObject.point.x - self.point.x) / dist
                local intersectionx2 = cx2 - h * (spatialObject.point.y - self.point.y) / dist
                local intersectiony2 = cy2 + h * (spatialObject.point.x - self.point.x) / dist

                table.insert(result, Point(intersectionx1, intersectiony1))

                if intersectionx1 ~= intersectionx2 or intersectiony1 ~= intersectiony2 then
                    table.insert(result, Point(intersectionx2, intersectiony2))
                end
            end
        end

        return result
    end
    --[[
        Translates a Circle to a string
    --]]
    function Circle:__toString()
        return "Circle(Point(" .. self.point.x .. ", " .. self.point.y .. "), " .. self.radius .. ")"
    end
    --[[
        Draws a Cirlce
    --]]
    function Circle:__draw(width, color)
        Draw.Circle(self.point.x, 0, self.point.y, self.radius, width or 4, color or Draw.Color(255, 255, 0, 0))
    end

class "LineSegment"
    --[[
        Creates a LineSegment
    --]]
    function LineSegment:__init(point1, point2)
    	uniqueId = uniqueId + 1
        self.uniqueId = uniqueId
        self.type = "LineSegment"
        local A, B = point1, point2

        if point1.type ~= "Point" then
            A = Point(point1)
        end

        if point2.type ~= "Point" then
            B = Point(point2)
        end

        self.points = {A, B}
    end
    --[[
        Compares 2 LineSegments
    --]]
    function LineSegment:__equal(spatialObject)
        return spatialObject.type == "LineSegment" and ((self.points[1] == spatialObject.points[1] and self.points[2] == spatialObject.points[2]) or (self.points[2] == spatialObject.points[1] and self.points[1] == spatialObject.points[2]))
    end
    --[[
        Retunrs the Points of a LineSegment
    --]]
    function LineSegment:__getPoints()
        return self.points
    end
    --[[
        Returns the LineSegemnts of a LineSegemnt (self)
    --]]
    function LineSegment:__getLineSegments()
        return {self}
    end
    --[[
        Returns the direction of a LineSegment
    --]]
    function LineSegment:__direction()
        return self.points[2] - self.points[1]
    end
    --[[
        Returns the length of a LineSegment
    --]]
    function LineSegment:__len()
        return (self.points[1] - self.points[2]):len()
    end
    --[[
        Checks if a LineSegment conrains an object
    --]]
    function LineSegment:__contains(spatialObject)
        if spatialObject.type == "Point" then
            return spatialObject:__distance(self) == 0
        elseif spatialObject.type == "Line" then
            return false
        elseif spatialObject.type == "Circle" then
            return spatialObject.point:__distance(self) == 0 and spatialObject.radius == 0
        elseif spatialObject.type == "LineSegment" then
            return spatialObject.points[1]:__distance(self) == 0 and spatialObject.points[2]:__distance(self) == 0
        else
            for i, point in ipairs(spatialObject:__getPoints()) do
                if point:__distance(self) ~= 0 then
                    return false
                end
            end

            return true
        end

        return false
    end
    --[[
        Checks if a LineSegment is inside an object
    --]]
    function LineSegment:__insideOf(spatialObject)
        return spatialObject:__contains(self)
    end
    --[[
        Returns the distance of a LineSegment to an other object
    --]]
    function LineSegment:__distance(spatialObject)
        if spatialObject.type == "Circle" then
            return spatialObject.point:__distance(self) - spatialObject.radius
        elseif spatialObject.type == "Line" then
            return math.min(self.points[1]:__distance(spatialObject), self.points[2]:__distance(spatialObject))
        elseif spatialObject.type == "Point" then
            local z1 = self.points[1].y
            local z2 = self.points[2].y
            local z3 = spatialObject.y

            local y1 = 0
            local y2 = 0
            local y3 = 0

            local A = Vector(self.points[1].x, y1, z1) --from
            local B = Vector(self.points[2].x, y2, z2) --to
            local P = Vector(spatialObject.x, y3, z3) --between

            local pt = {X = spatialObject.x, Y = z3}
            local p1 = {X = self.points[1].x, Y = z1}
            local p2 = {X = self.points[2].x, Y = z2}
            local dx = self.points[2].x - self.points[1].x
            local dy = z2 - z1
            local closest = nil

            if ((dx == 0) and (dy == 0)) then
                --It's a point not a line segment.
                closest = self.points[1]
                dx = spatialObject.x - self.points[1].x
                dy = z3 - z1
                return math.sqrt(dx * dx + dy * dy)
            end

            --Calculate the t that minimizes the distance.
            local t = ((pt.X - p1.X) * dx + (pt.Y - p1.Y) * dy) / (dx * dx + dy * dy)

            --See if this represents one of the segments end points or a point in the middle.
            if (t < 0) then
                closest = Point(p1.X, p1.Y)
                dx = pt.X - p1.X
                dy = pt.Y - p1.Y
            elseif (t > 1) then
                closest = Point(p2.X, p2.Y)
                dx = pt.X - p2.X
                dy = pt.Y - p2.Y
            else
                closest = Point(p1.X + t * dx, p1.Y + t * dy)
                dx = pt.X - closest.x
                dy = pt.Y - closest.y
            end

            return math.sqrt(dx * dx + dy * dy)
        else
            return self:__distance(Point(spatialObject))
        end
    end
    --[[
        Checks for intersiction between a LineSegment and an object
    --]]
    function LineSegment:__intersects(spatialObject, a, b)
        -- parameter conversion
        local L1 = {X1 = self.points[1].x, Y1 = self.points[1].y, X2 = self.points[2].x, Y2 = self.points[2].y}
        local L2 = {X1 = spatialObject.points[1].x, Y1 = spatialObject.points[1].y, X2 = spatialObject.points[2].x, Y2 = spatialObject.points[2].y}

        -- Denominator for ua and ub are the same, so store this calculation
        local d = (L2.Y2 - L2.Y1) * (L1.X2 - L1.X1) - (L2.X2 - L2.X1) * (L1.Y2 - L1.Y1)

        -- Make sure there is not a division by zero - this also indicates that the lines are parallel.
        -- If n_a and n_b were both equal to zero the lines would be on top of each
        -- other (coincidental).  This check is not done because it is not
        -- necessary for this implementation (the parallel check accounts for this).
        if (d == 0) then
            return false
        end

        -- n_a and n_b are calculated as seperate values for readability
        local n_a = (L2.X2 - L2.X1) * (L1.Y1 - L2.Y1) - (L2.Y2 - L2.Y1) * (L1.X1 - L2.X1)
        local n_b = (L1.X2 - L1.X1) * (L1.Y1 - L2.Y1) - (L1.Y2 - L1.Y1) * (L1.X1 - L2.X1)

        -- Calculate the intermediate fractional point that the lines potentially intersect.
        local ua = n_a / d
        local ub = n_b / d

        -- The fractional point will be between 0 and 1 inclusive if the lines
        -- intersect.  If the fractional calculation is larger than 1 or smaller
        -- than 0 the lines would need to be longer to intersect.
        if (ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1) then
            local x = L1.X1 + (ua * (L1.X2 - L1.X1))
            local y = L1.Y1 + (ua * (L1.Y2 - L1.Y1))
            return true, {x = x, y = y}
        end

        return false
    end
    --[[
        Draws a LineSegment
    --]]
    function LineSegment:__draw(width, color)
    	local A = Vector(self.points[1].x, 0, self.points[1].y):To2D()
    	local B = Vector(self.points[2].x, 0, self.points[2].y):To2D()
    	
    	if A.onScreen and B.onScreen then
        	Draw.Line(A.x, A.y, B.x, B.y, width or 4, color or Draw.Color(255, 255, 0, 0))
        end
    end

class "Polygon"
    --[[
        Creates a Polygon
    --]]
    function Polygon:__init(...)
        uniqueId = uniqueId + 1
        self.uniqueId = uniqueId
        self.points = {...}
        self.type = "Polygon"
    end
    --[[
        Comapres 2 Polygons
    --]]
    function Polygon:__equal(spatialObject)
        return spatialObject.type == "Polygon" -- TODO
    end
    --[[
        Retunrs the points of a Polygon
    --]]
    function Polygon:__getPoints()
        return self.points
    end
    --[[
        Add a point to a Polygon
    --]]
    function Polygon:__addPoint(point)
        table.insert(self.points, point)
        self.lineSegments = nil
        self.triangles = nil
    end
    --[[
        Returns the LineSegments of a Polygon
    --]]
    function Polygon:__getLineSegments()
        if self.lineSegments == nil then
            self.lineSegments = {}

            for i = 1, #self.points, 1 do
                table.insert(self.lineSegments, LineSegment(self.points[i], self.points[(i % #self.points) + 1]))
            end
        end

        return self.lineSegments
    end
    --[[
        Checks if a Polygon contains an object
    --]]
    function Polygon:__contains(spatialObject)
        if spatialObject.type == "Line" then
            return false
        elseif #self.points == 3 then
            for i, point in ipairs(spatialObject:__getPoints()) do
                local corner1DotCorner2 = ((point.y - self.points[1].y) * (self.points[2].x - self.points[1].x)) - ((point.x - self.points[1].x) * (self.points[2].y - self.points[1].y))
                local corner2DotCorner3 = ((point.y - self.points[2].y) * (self.points[3].x - self.points[2].x)) - ((point.x - self.points[2].x) * (self.points[3].y - self.points[2].y))
                local corner3DotCorner1 = ((point.y - self.points[3].y) * (self.points[1].x - self.points[3].x)) - ((point.x - self.points[3].x) * (self.points[1].y - self.points[3].y))

                if not (corner1DotCorner2 * corner2DotCorner3 >= 0 and corner2DotCorner3 * corner3DotCorner1 >= 0) then
                    return false
                end
            end

            if spatialObject.type == "Circle" then
                for i, lineSegment in ipairs(self:__getLineSegments()) do
                    if spatialObject.point:__distance(lineSegment) <= 0 then
                        return false
                    end
                end
            end

            return true
        elseif spatialObject.type == "Point" then
            local i, yflag0, yflag1, inside_flag
            local vtx0, vtx1
            local tx, ty = spatialObject.x, spatialObject.y
            local numverts = #self.points

            vtx0 = self.points[numverts]
            vtx1 = self.points[1]

            -- get test bit for above/below X axis
            yflag0 = ( vtx0.y >= ty )
            inside_flag = false

            for i = 2, numverts + 1 do
                yflag1 = ( vtx1.y >= ty )

                if ( yflag0 ~= yflag1 ) then
                    if ( ((vtx1.y - ty) * (vtx0.x - vtx1.x) >= (vtx1.x - tx) * (vtx0.y - vtx1.y)) == yflag1 ) then
                        inside_flag = not inside_flag
                    end
                end
                -- Move to the next pair of vertices, retaining info as possible.
                yflag0  = yflag1
                vtx0    = vtx1
                vtx1    = self.points[i]
            end

            return inside_flag
        end
    end
    --[[
        Checks if a Polygon is inside of an object
    --]]
    function Polygon:__insideOf(spatialObject)
        return spatialObject:__contains(self)
    end
    --[[
        Returns the direction of a Polygon
    --]]
    function Polygon:__direction()
        if self.directionValue == nil then
            local rightMostPoint = nil
            local rightMostPointIndex = nil

            for i, point in ipairs(self.points) do
                if rightMostPoint == nil or point.x >= rightMostPoint.x then
                    rightMostPoint = point
                    rightMostPointIndex = i
                end
            end

            local rightMostPointPredecessor = self.points[(rightMostPointIndex - 1 - 1) % #self.points + 1]
            local rightMostPointSuccessor   = self.points[(rightMostPointIndex + 1 - 1) % #self.points + 1]

            local z = (rightMostPoint.x - rightMostPointPredecessor.x) * (rightMostPointSuccessor.y - rightMostPoint.y) - (rightMostPoint.y - rightMostPointPredecessor.y) * (rightMostPointSuccessor.x - rightMostPoint.x)
            if z > 0 then
                self.directionValue = 1
            elseif z < 0 then
                self.directionValue = -1
            else
                self.directionValue = 0
            end
        end

        return self.directionValue
    end
    --[[
        Triangulate a Polygon
    --]]
    function Polygon:__triangulate()
        if self.triangles == nil then
            self.triangles = {}

            if #self.points > 3 then
                local tempPoints = {}
                for i, point in ipairs(self.points) do
                    table.insert(tempPoints, point)
                end

                local triangleFound = true
                while #tempPoints > 3 and triangleFound do
                    triangleFound = false
                    for i, point in ipairs(tempPoints) do
                        local point1Index = (i - 1 - 1) % #tempPoints + 1
                        local point2Index = (i + 1 - 1) % #tempPoints + 1

                        local point1 = tempPoints[point1Index]
                        local point2 = tempPoints[point2Index]

                        if ((((point1.x - point.x) * (point2.y - point.y) - (point1.y - point.y) * (point2.x - point.x))) * self:__direction()) < 0 then
                            local triangleCandidate = Polygon(point1, point, point2)

                            local anotherPointInTriangleFound = false
                            for q = 1, #tempPoints, 1 do
                                if q ~= i and q ~= point1Index and q ~= point2Index and triangleCandidate:__contains(tempPoints[q]) then
                                    anotherPointInTriangleFound = true
                                    break
                                end
                            end

                            if not anotherPointInTriangleFound then
                                table.insert(self.triangles, triangleCandidate)
                                table.remove(tempPoints, i)
                                i = i - 1

                                triangleFound = true
                            end
                        end
                    end
                end

                if #tempPoints == 3 then
                    table.insert(self.triangles, Polygon(tempPoints[1], tempPoints[2], tempPoints[3]))
                end
            elseif #self.points == 3 then
                table.insert(self.triangles, self)
            end
        end

        return self.triangles
    end
    --[[
        Checks if a Poylgon intersects with an object
    --]]
    function Polygon:__intersects(spatialObject)
        for i, lineSegment1 in ipairs(self:__getLineSegments()) do
            for j, lineSegment2 in ipairs(spatialObject:__getLineSegments()) do
                if lineSegment1:__intersects(lineSegment2) then
                    return true
                end
            end
        end

        return false
    end
    --[[
        Returns the intersection points of an object with a Polygon
    --]]
    function Polygon:__intersectionPoints(spatialObject, sort)
        local points = {}

        for i, lineSegment1 in ipairs(self:__getLineSegments()) do
            local success, pt = lineSegment1:__intersects(spatialObject)

            if (success) then
                pt.lineIndex = i
                points[ #points+1 ] = pt
            end
        end

        if (sort) then
            table.sort(points, function(a,b) return math.lengthOf(e,a) > math.lengthOf(e,b) end)
        end

        return points
    end
    --[[
        Retunrs the diatance of an object to a Polygon
    --]]
    function Polygon:__distance(spatialObject)
        local minDistance = nil
        for i, lineSegment in ipairs(self:__getLineSegments()) do
            local distance = lineSegment:__distance(spatialObject)
            if minDistance == nil or distance <= minDistance then
                minDistance = distance
            end
        end

        return minDistance
    end
    --[[
        Transalte a Polygon to a string
    --]]
    function Polygon:__toString()
        local result = "Polygon("

        for i, point in ipairs(self.points) do
            if i == 1 then
                result = result .. point:__toString()
            else
                result = result .. ", " .. point:__toString()
            end
        end

        return result .. ")"
    end
    --[[
        Draws a Polygon
    --]]
    function Polygon:__draw(width, color)
        for i, lineSegment in ipairs(self:__getLineSegments()) do
            lineSegment:__draw(width, color)
        end
    end
