-- Code ------------------------------------------------------------------------

class "Point" -- {
    function Point:__init(x, y)
    	local pos = GetOrigin(x) or type(x) ~= "number" and x or nil
        self.x = pos and pos.x or x
        self.y = pos and pos.y or y
        self.points = {self}
    end

    function Point:__type()
        return "Point"
    end

    function Point:__eq(spatialObject)
        return spatialObject:__type() == "Point" and self.x == spatialObject.x and self.y == spatialObject.y
    end

    function Point:__unm()
        return Point(-self.x, -self.y)
    end

    function Point:__add(p)
        return Point(self.x + p.x, self.y + p.y)
    end

    function Point:__sub(p)
        return Point(self.x - p.x, self.y - p.y)
    end

    function Point:__mul(p)
        if type(p) == "number" then
            return Point(self.x * p, self.y * p)
        else
            return Point(self.x * p.x, self.y * p.y)
        end
    end

    function Point:tostring()
        return "Point(" .. tostring(self.x) .. ", " .. tostring(self.y) .. ")"
    end

    function Point:__div(p)
        if type(p) == "number" then
            return Point(self.x / p, self.y / p)
        else
            return Point(self.x / p.x, self.y / p.y)
        end
    end

    function Point:between(point1, point2)
        local normal = Line(point1, point2):normal()

        return Line(point1, point1 + normal):side(self) ~= Line(point2, point2 + normal):side(self)
    end

    function Point:len()
        return math.sqrt(self.x * self.x + self.y * self.y)
    end

    function Point:normalize()
        len = self:len()

        self.x = self.x / len
        self.y = self.y / len

        return self
    end

    function Point:clone()
        return Point(self.x, self.y)
    end

    function Point:normalized()
        local a = self:clone()
        a:normalize()
        return a
    end

    function Point:getPoints()
        return self.points
    end

    function Point:getLineSegments()
        return {}
    end

    function Point:perpendicularFoot(line)
        local distanceFromLine = line:distance(self)
        local normalVector = line:normal():normalized()

        local footOfPerpendicular = self + normalVector * distanceFromLine
        if line:distance(footOfPerpendicular) > distanceFromLine then
            footOfPerpendicular = self - normalVector * distanceFromLine
        end

        return footOfPerpendicular
    end

    function Point:contains(spatialObject)
        if spatialObject:__type() == "Line" then
            return false
        elseif spatialObject:__type() == "Circle" then
            return spatialObject.point == self and spatialObject.radius == 0
        else
        for i, point in ipairs(spatialObject:getPoints()) do
            if point ~= self then
                return false
            end
        end
    end

        return true
    end

    function Point:polar()
        if math.close(self.x, 0) then
            if self.y > 0 then return 90
            elseif self.y < 0 then return 270
            else return 0
            end
        else
            local theta = math.deg(math.atan(self.y / self.x))
            if self.x < 0 then theta = theta + 180 end
            if theta < 0 then theta = theta + 360 end
            return theta
        end
    end

    function Point:insideOf(spatialObject)
        return spatialObject.contains(self)
    end

    function Point:distance(spatialObject)
        if spatialObject:__type() == "Point" then
            return math.sqrt((self.x - spatialObject.x)^2 + (self.y - spatialObject.y)^2)
        elseif spatialObject:__type() == "Line" then
            denominator = (spatialObject.points[2].x - spatialObject.points[1].x)
            if denominator == 0 then
                return math.abs(self.x - spatialObject.points[2].x)
            end

            m = (spatialObject.points[2].y - spatialObject.points[1].y) / denominator

            return math.abs((m * self.x - self.y + (spatialObject.points[1].y - m * spatialObject.points[1].x)) / math.sqrt(m * m + 1))
        elseif spatialObject:__type() == "Circle" then
            return self:distance(spatialObject.point) - spatialObject.radius
        elseif spatialObject:__type() == "LineSegment" then
            local t = ((self.x - spatialObject.points[1].x) * (spatialObject.points[2].x - spatialObject.points[1].x) + (self.y - spatialObject.points[1].y) * (spatialObject.points[2].y - spatialObject.points[1].y)) / ((spatialObject.points[2].x - spatialObject.points[1].x)^2 + (spatialObject.points[2].y - spatialObject.points[1].y)^2)

            if t <= 0.0 then
                return self:distance(spatialObject.points[1])
            elseif t >= 1.0 then
                return self:distance(spatialObject.points[2])
            else
                return self:distance(Line(spatialObject.points[1], spatialObject.points[2]))
            end
        else
            local minDistance = nil

            for i, lineSegment in ipairs(spatialObject:getLineSegments()) do
                if minDistance == nil then
                    minDistance = self:distance(lineSegment)
                else
                    minDistance = math.min(minDistance, self:distance(lineSegment))
                end
            end

            return minDistance
        end
    end
-- }

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
--[[
class "Line" -- {
    function Line:__init(point1, point2)
        self.points = {point1, point2}
    end

    function Line:__type()
        return "Line"
    end

    function Line:__eq(spatialObject)
        return spatialObject:__type() == "Line" and self:distance(spatialObject) == 0
    end

    function Line:getPoints()
        return self.points
    end

    function Line:getLineSegments()
        return {}
    end

    function Line:direction()
        return self.points[2] - self.points[1]
    end

    function Line:normal()
        return Point(- self.points[2].y + self.points[1].y, self.points[2].x - self.points[1].x)
    end

    function Line:perpendicularFoot(point)
        return point:perpendicularFoot(self)
    end

    function Line:side(spatialObject)
        leftPoints = 0
        rightPoints = 0
        onPoints = 0
        for i, point in ipairs(spatialObject:getPoints()) do
            local result = ((self.points[2].x - self.points[1].x) * (point.y - self.points[1].y) - (self.points[2].y - self.points[1].y) * (point.x - self.points[1].x))

            if result < 0 then
                leftPoints = leftPoints + 1
            elseif result > 0 then
                rightPoints = rightPoints + 1
            else
                onPoints = onPoints + 1
            end
        end

        if leftPoints ~= 0 and rightPoints == 0 and onPoints == 0 then
            return -1
        elseif leftPoints == 0 and rightPoints ~= 0 and onPoints == 0 then
            return 1
        else
            return 0
        end
    end

    function Line:contains(spatialObject)
        if spatialObject:__type() == "Point" then
            return spatialObject:distance(self) == 0
        elseif spatialObject:__type() == "Line" then
            return self.points[1]:distance(spatialObject) == 0 and self.points[2]:distance(spatialObject) == 0
        elseif spatialObject:__type() == "Circle" then
            return spatialObject.point:distance(self) == 0 and spatialObject.radius == 0
        elseif spatialObject:__type() == "LineSegment" then
            return spatialObject.points[1]:distance(self) == 0 and spatialObject.points[2]:distance(self) == 0
        else
        for i, point in ipairs(spatialObject:getPoints()) do
            if point:distance(self) ~= 0 then
                return false
            end
            end

            return true
        end

        return false
    end

    function Line:insideOf(spatialObject)
        return spatialObject:contains(self)
    end

    function Line:distance(spatialObject)
        if spatialObject:__type() == "Circle" then
            return spatialObject.point:distance(self) - spatialObject.radius
        elseif spatialObject:__type() == "Line" then
            distance1 = self.points[1]:distance(spatialObject)
            distance2 = self.points[2]:distance(spatialObject)
            if distance1 ~= distance2 then
                return 0
            else
                return distance1
            end
        else
            local minDistance = nil
            for i, point in ipairs(spatialObject:getPoints()) do
                distance = point:distance(self)
                if minDistance == nil or distance <= minDistance then
                    minDistance = distance
                end
            end

            return minDistance
        end
    end
-- }
--]]
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
--Makes problems with Cirlces():draw
--[[
class "Circle" -- {
    function Circle:__init(point, radius)
        uniqueId = uniqueId + 1
        self.uniqueId = uniqueId

        self.point = point
        self.radius = radius

        self.points = {self.point}
    end

    function Circle:__type()
        return "Circle"
    end

    function Circle:__eq(spatialObject)
        return spatialObject:__type() == "Circle" and (self.point == spatialObject.point and self.radius == spatialObject.radius)
    end

    function Circle:getPoints()
        return self.points
    end

    function Circle:getLineSegments()
        return {}
    end

    function Circle:contains(spatialObject)
        if spatialObject:__type() == "Line" then
            return false
        elseif spatialObject:__type() == "Circle" then
            return self.radius >= spatialObject.radius + self.point:distance(spatialObject.point)
        else
            for i, point in ipairs(spatialObject:getPoints()) do
                if self.point:distance(point) >= self.radius then
                    return false
                end
            end

            return true
        end
    end

    function Circle:insideOf(spatialObject)
        return spatialObject:contains(self)
    end

    function Circle:distance(spatialObject)
        return self.point:distance(spatialObject) - self.radius
    end

    function Circle:intersectionPoints(spatialObject)
        local result = {}

        dx = self.point.x - spatialObject.point.x
        dy = self.point.y - spatialObject.point.y
        dist = math.sqrt(dx * dx + dy * dy)

        if dist > self.radius + spatialObject.radius then
            return result
        elseif dist < math.abs(self.radius - spatialObject.radius) then
            return result
        elseif (dist == 0) and (self.radius == spatialObject.radius) then
            return result
        else
            a = (self.radius * self.radius - spatialObject.radius * spatialObject.radius + dist * dist) / (2 * dist)
            h = math.sqrt(self.radius * self.radius - a * a)

            cx2 = self.point.x + a * (spatialObject.point.x - self.point.x) / dist
            cy2 = self.point.y + a * (spatialObject.point.y - self.point.y) / dist

            intersectionx1 = cx2 + h * (spatialObject.point.y - self.point.y) / dist
            intersectiony1 = cy2 - h * (spatialObject.point.x - self.point.x) / dist
            intersectionx2 = cx2 - h * (spatialObject.point.y - self.point.y) / dist
            intersectiony2 = cy2 + h * (spatialObject.point.x - self.point.x) / dist

            table.insert(result, Point(intersectionx1, intersectiony1))

            if intersectionx1 ~= intersectionx2 or intersectiony1 ~= intersectiony2 then
                table.insert(result, Point(intersectionx2, intersectiony2))
            end
        end

        return result
    end

    function Circle:tostring()
        return "Circle(Point(" .. self.point.x .. ", " .. self.point.y .. "), " .. self.radius .. ")"
    end

-- }
--]]
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--

class "LineSegment" -- {
    function LineSegment:__init(point1, point2)
        self.points = {point1, point2}
    end

    function LineSegment:__type()
        return "LineSegment"
    end

    function LineSegment:__eq(spatialObject)
        return spatialObject:__type() == "LineSegment" and ((self.points[1] == spatialObject.points[1] and self.points[2] == spatialObject.points[2]) or (self.points[2] == spatialObject.points[1] and self.points[1] == spatialObject.points[2]))
    end

    function LineSegment:getPoints()
        return self.points
    end

    function LineSegment:getLineSegments()
        return {self}
    end

    function LineSegment:direction()
        return self.points[2] - self.points[1]
    end

    function LineSegment:len()
        return (self.points[1] - self.points[2]):len()
    end

    function LineSegment:contains(spatialObject)
        if spatialObject:__type() == "Point" then
            return spatialObject:distance(self) == 0
        elseif spatialObject:__type() == "Line" then
            return false
        elseif spatialObject:__type() == "Circle" then
            return spatialObject.point:distance(self) == 0 and spatialObject.radius == 0
        elseif spatialObject:__type() == "LineSegment" then
            return spatialObject.points[1]:distance(self) == 0 and spatialObject.points[2]:distance(self) == 0
        else
        for i, point in ipairs(spatialObject:getPoints()) do
            if point:distance(self) ~= 0 then
                return false
            end
            end

            return true
        end

        return false
    end

    function LineSegment:insideOf(spatialObject)
        return spatialObject:contains(self)
    end

    function LineSegment:distance(spatialObject)
        if spatialObject:__type() == "Circle" then
            return spatialObject.point:distance(self) - spatialObject.radius
        elseif spatialObject:__type() == "Line" then
            return math.min(self.points[1]:distance(spatialObject), self.points[2]:distance(spatialObject))
        else
            local minDistance = nil
            for i, point in ipairs(spatialObject:getPoints()) do
                distance = point:distance(self)
                if minDistance == nil or distance <= minDistance then
                    minDistance = distance
                end
            end

            return minDistance
        end
    end

    function LineSegment:intersects(spatialObject)
        return #self:intersectionPoints(spatialObject) >= 1
    end

    function LineSegment:intersectionPoints(spatialObject)
        if spatialObject:__type()  == "LineSegment" then
            d = (spatialObject.points[2].y - spatialObject.points[1].y) * (self.points[2].x - self.points[1].x) - (spatialObject.points[2].x - spatialObject.points[1].x) * (self.points[2].y - self.points[1].y)

            if d ~= 0 then
                ua = ((spatialObject.points[2].x - spatialObject.points[1].x) * (self.points[1].y - spatialObject.points[1].y) - (spatialObject.points[2].y - spatialObject.points[1].y) * (self.points[1].x - spatialObject.points[1].x)) / d
                ub = ((self.points[2].x - self.points[1].x) * (self.points[1].y - spatialObject.points[1].y) - (self.points[2].y - self.points[1].y) * (self.points[1].x - spatialObject.points[1].x)) / d

                if ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1 then
                    return {Point (self.points[1].x + (ua * (self.points[2].x - self.points[1].x)), self.points[1].y + (ua * (self.points[2].y - self.points[1].y)))}
                end
            end
        end

        return {}
    end

    function LineSegment:draw(color, width)
        drawLine(self, color or 0XFF00FF00, width or 4)
    end

-- }

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--

class "Polygon" -- {
    function Polygon:__init(...)
        self.points = {...}
    end

    function Polygon:__type()
        return "Polygon"
    end

    function Polygon:__eq(spatialObject)
        return spatialObject:__type() == "Polygon" -- TODO
    end

    function Polygon:getPoints()
        return self.points
    end

    function Polygon:addPoint(point)
        table.insert(self.points, point)
        self.lineSegments = nil
        self.triangles = nil
    end

    function Polygon:getLineSegments()
        if self.lineSegments == nil then
            self.lineSegments = {}
            for i = 1, #self.points, 1 do
                table.insert(self.lineSegments, LineSegment(self.points[i], self.points[(i % #self.points) + 1]))
            end
        end

        return self.lineSegments
    end

    function Polygon:contains(spatialObject)
        if spatialObject:__type() == "Line" then
            return false
        elseif #self.points == 3 then
            for i, point in ipairs(spatialObject:getPoints()) do
                corner1DotCorner2 = ((point.y - self.points[1].y) * (self.points[2].x - self.points[1].x)) - ((point.x - self.points[1].x) * (self.points[2].y - self.points[1].y))
                corner2DotCorner3 = ((point.y - self.points[2].y) * (self.points[3].x - self.points[2].x)) - ((point.x - self.points[2].x) * (self.points[3].y - self.points[2].y))
                corner3DotCorner1 = ((point.y - self.points[3].y) * (self.points[1].x - self.points[3].x)) - ((point.x - self.points[3].x) * (self.points[1].y - self.points[3].y))

                if not (corner1DotCorner2 * corner2DotCorner3 >= 0 and corner2DotCorner3 * corner3DotCorner1 >= 0) then
                    return false
                end
            end

            if spatialObject:__type() == "Circle" then
                for i, lineSegment in ipairs(self:getLineSegments()) do
                    if spatialObject.point:distance(lineSegment) <= 0 then
                        return false
                    end
                end
            end

            return true
        else
            for i, point in ipairs(spatialObject:getPoints()) do
                inTriangles = false
                for j, triangle in ipairs(self:triangulate()) do
                    if triangle:contains(point) then
                        inTriangles = true
                        break
                    end
                end
                if not inTriangles then
                    return false
                end
            end

            return true
        end
    end

    function Polygon:insideOf(spatialObject)
        return spatialObject.contains(self)
    end

    function Polygon:direction()
        if self.directionValue == nil then
            local rightMostPoint = nil
            local rightMostPointIndex = nil
            for i, point in ipairs(self.points) do
                if rightMostPoint == nil or point.x >= rightMostPoint.x then
                    rightMostPoint = point
                    rightMostPointIndex = i
                end
            end

            rightMostPointPredecessor = self.points[(rightMostPointIndex - 1 - 1) % #self.points + 1]
            rightMostPointSuccessor   = self.points[(rightMostPointIndex + 1 - 1) % #self.points + 1]

            z = (rightMostPoint.x - rightMostPointPredecessor.x) * (rightMostPointSuccessor.y - rightMostPoint.y) - (rightMostPoint.y - rightMostPointPredecessor.y) * (rightMostPointSuccessor.x - rightMostPoint.x)
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

    function Polygon:triangulate()
        if self.triangles == nil then
            self.triangles = {}

            if #self.points > 3 then
                tempPoints = {}
                for i, point in ipairs(self.points) do
                    table.insert(tempPoints, point)
                end
        
                triangleFound = true
                while #tempPoints > 3 and triangleFound do
                    triangleFound = false
                    for i, point in ipairs(tempPoints) do
                        point1Index = (i - 1 - 1) % #tempPoints + 1
                        point2Index = (i + 1 - 1) % #tempPoints + 1

                        point1 = tempPoints[point1Index]
                        point2 = tempPoints[point2Index]

                        if ((((point1.x - point.x) * (point2.y - point.y) - (point1.y - point.y) * (point2.x - point.x))) * self:direction()) < 0 then
                            triangleCandidate = Polygon(point1, point, point2)

                            anotherPointInTriangleFound = false
                            for q = 1, #tempPoints, 1 do
                                if q ~= i and q ~= point1Index and q ~= point2Index and triangleCandidate:contains(tempPoints[q]) then
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

    function Polygon:intersects(spatialObject)
        for i, lineSegment1 in ipairs(self:getLineSegments()) do
            for j, lineSegment2 in ipairs(spatialObject:getLineSegments()) do
                if lineSegment1:intersects(lineSegment2) then
                    return true
                end
            end
        end

        return false
    end

    function Polygon:distance(spatialObject)
        local minDistance = nil
        for i, lineSegment in ipairs(self:getLineSegment()) do
            distance = point:distance(self)
            if minDistance == nil or distance <= minDistance then
                minDistance = distance
            end
        end

        return minDistance
    end

    function Polygon:tostring()
        local result = "Polygon("

        for i, point in ipairs(self.points) do
            if i == 1 then
                result = result .. point:tostring()
            else
                result = result .. ", " .. point:tostring()
            end
        end

        return result .. ")"
    end

    function Polygon:draw(color, width)
        for i, lineSegment in ipairs(self:getLineSegments()) do
            lineSegment:draw(color, width)
        end
    end
-- }
