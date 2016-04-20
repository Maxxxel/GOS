--[[
    2D Geometry 1.3 by Husky
    version 0.2 port by Maxxxel
--]]

-- Code ------------------------------------------------------------------------
local Version = 0.3
function AutoUpdate(data)
    if tonumber(data) > tonumber(Version) then
        PrintChat("New version found! " .. data)
        PrintChat("Downloading update, please wait...")
        DownloadFileAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/2DGeometry.lua", COMMON_PATH .. "2DGeometry.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    end
end

GetWebResultAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/2DGeometry.version", AutoUpdate)
class "Point" --{
--initiating
  function Point:__init(x,y,z)
    local pos= type(x)~="number" and GetOrigin(x) or nil
    self.x = pos and pos.x or x 
    self.y = pos and pos.y or y
    self.z = pos and pos.z or z or 0
    self.points = {self}
  end
--type method
  function Point:__type()
    return "Point"
  end
--is an object equal
  function Point:__equal(Object)
    return Object:__type() == "Point" and self.x==Object.x and self.y==Object.y and self.z==Object.z
  end
--make point negative
  function Point:__makeNegative()
    return Point(-self.x,-self.y,-self.z)
  end
--addition with point
  function Point:__addition(v)
  	if type(v)=="number" then
  		return Point(self.x+v,self.y+v,self.z+v)
  	elseif v:__type()=="Point" then
   		return Point(self.x+v.x,self.y+v.y,self.z+v.z)
    else
    	PrintChat("Error on Point:__addition, value is unexpected")
    end
  end
--give addidtion value
  function Point:__additionValue()
    return self.x+self.y+self.z
  end
--substract a point
  function Point:__substract(v)
  	if type(v)=="number" then
      return Point(self.x-v,self.y-v,self.z-v)
    elseif v:__type()=="Point" then
      return Point(self.x-v.x,self.y-v.y,self.z-v.z)
    else
    	PrintChat("Error on Point:__substract, value is unexpected")
    end
  end
--multiply Point by value or Point
  function Point:__multiply(v)
    if type(v)=="number" then
      return Point(self.x*v,self.y*v,self.z*v)
     elseif v:__type()=="Point" or type(v)=="table" then
  		return Point(self.x*v.x,self.y*v.y,self.z*v.z)
    else
      PrintChat("Error on Point:__multiply, value is unexpected"..type(v))
    end
  end
--divide by value or point
function Point:__divide(v)
	if type(v)=="number" then
    return Point(self.x/v,self.y/v,self.z/v)
  elseif v:__type()=="Point" then
		return Point(self.x/v.x,self.y/v.y,self.z/v.z)
  else
    PrintChat("Error on Point:divide, value is unexpected")
  end
end
--length of point vector
  function Point:__lenght()
    return math.sqrt((self:__expand()):__additionValue())
  end
--^2 a point values
  function Point:__expand()
    return Point(self.x*self.x,self.y*self.y,self.z*self.z)
  end
--To string
  function Point:__toString()
  	if self:__type()=="Point" then
    	return "Point("..tostring(self.x)..","..tostring(self.y)..","..tostring(self.z)..")"
    else
    	PrintChat("Error on toString")
    end
  end
--clone point
  function Point:__clone()
    return Point(self.x,self.y,self.z)
  end
--get all points
  function Point:__getPoints()
    return self.points
  end
--point is inside of an object
  function Point:__insideOf(Object)
    return Object:__contains(self)
  end
--distances point: point,line,circle
  function Point:__distance(Object)
    if Object:__type()=="Point" then
      return (self:__substract(Object)):__lenght()
    elseif Object:__type()=="Line" then
      return Object:__distance(self)
    elseif Object:__type()=="LineSegment" then
      return Object:__distance(self)
    elseif Object:__type()=="Circle" then
      --missing
    end
  end

    function Point:__ClosestPointInSegmentTo(Object)
      if Object:__type() == "LineSegment" then
        xDelta = Object.points[2].x - Object.points[1].x;
        yDelta = Object.points[2].y - Object.points[1].y;

        if ((xDelta == 0) and (yDelta == 0)) then
          print("Segment start equals segment end");
        end

        u = ((self.x - Object.points[1].x) * xDelta + (self.y - Object.points[1].y) * yDelta) / (xDelta * xDelta + yDelta * yDelta);

        closestPoint = nil
        if (u < 0) then
          closestPoint = Point(Object.points[1].x, Object.points[1].y);
        elseif (u > 1) then
          closestPoint = Point(Object.points[2].x, Object.points[2].y);
        else
          closestPoint = Point(math.ceil(Object.points[1].x + u * xDelta),  math.ceil(Object.points[1].y + u * yDelta));
        end

        return closestPoint;
      end
    end

    function Point:__GetClosestBorderPointTo(Object)
      bestDistance = 999999
      bestSegment = nil
      bestPoint = nil
      if Object:__type() == "Polygon" then
        for i, s in ipairs(Object:__getLineSegments()) do
          closestInS = self:__ClosestPointInSegmentTo(s)
          d = self:__distance(closestInS)
          if (d < bestDistance) then
            bestDistance = d
            bestSegment = s
            s:__draw()
            bestPoint = closestInS
          end
        end
      end
      return bestPoint, bestSegment
    end
--}

class "Line" --{
--init
	function Line:__init(Point1,Point2)
		self.points = {Point1,Point2}
	end
--type
	function Line:__type()
		return "Line"
	end
--equal with object
	function Line:__equal(Object)
		return Object:__type() == "Line" and self:distance(Object)==0
  end
--get Points of Line
	function Line:__getPoints()
		return self.points
	end
--Line Segment
  function Line:__getLineSegments()
		return {self}
  end
--does the line contains an object
	function Line:__contains(Object)
	  if Object:__type() == "Point" then
	  	return Object:__distance(self) == 0
	  elseif Object:__type() == "Line" then
			return self.points[1]:__distance(Object) == 0 and self.points[2]:__distance(Object) == 0
	  elseif Object:__type() == "Circle" then
			return Object.point:__distance(self) == 0 and Object.radius == 0
	  elseif Object:__type() == "LineSegment" then
			return Object.points[1]:__distance(self) == 0 and Object.points[2]:__distance(self) == 0
	  else
	  	PrintChat("Error on Line:__contains, ObjectType is unexpected")
	  end
	end
--is Line is an other object
	function Line:__insideOf(Object)
		return Object:__contains(self)
	end
--distance to other objects
	function Line:__distance(Object)
    if Object:__type() == "Circle" then
			return Object.point:distance(self)-Object.radius
    elseif Object:__type() == "Line" then
      distance1 = self.points[1]:__distance(Object)
      distance2 = self.points[2]:__distance(Object)
      if distance1 ~= distance2 then
      	return 0 --they touch in a point
      else
      	return distance1
      end
    elseif Object:__type() == "Point" then
    	denominator = (self.points[2].x-self.points[1].x)
			if denominator== 0 then
				return math.abs(Object.x-self.points[2].x)
      end
			m = (self.points[2].y-self.points[1].y)/denominator
			return math.abs((m*Object.x-Object.y+(self.points[1].y-m*self.points[1].x))/math.sqrt(m*m+1))
		else
    	PrintChat("Error on Line:__distance, ObjectType is unexpected")
    end
	end
	function Line:__draw(color, width)
		local newPoint1 = WorldToScreen(1, self.points[1].x, self.points[1].y, self.points[1].z)
		local newPoint2 = WorldToScreen(1, self.points[2].x, self.points[2].y, self.points[2].z)
		DrawLine(newPoint1.x, newPoint1.y, newPoint2.x, newPoint2.y ,width or 4,color or 0XFF00FF00);
  end
--}

class "Circle" -- {
    function Circle:__init(point, radius)

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

    function Circle:__getPoints()
        return self.points
    end

    function Circle:__getLineSegments()
        return {}
    end

    function Circle:__contains(spatialObject)
        if spatialObject:__type() == "Line" then
            return false
        elseif spatialObject:__type() == "Circle" then
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

    function Circle:__insideOf(spatialObject)
        return spatialObject:__contains(self)
    end

    function Circle:__distance(spatialObject)
        return self.point:__distance(spatialObject) - self.radius
    end

    function Circle:__intersectionPoints(spatialObject)
      local result = {}
      if spatialObject:__type() == "Circle" then
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
      end
      return result
    end

    function Circle:__tostring()
        return "Circle(Point(" .. self.point.x .. ", " .. self.point.y .. "), " .. self.radius .. ")"
    end

-- }

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

    function LineSegment:__getPoints()
        return self.points
    end

    function LineSegment:__getLineSegments()
        return {self}
    end

    function LineSegment:__direction()
        return self.points[2] - self.points[1]
    end

    function LineSegment:__len()
        return (self.points[1] - self.points[2]):len()
    end

    function LineSegment:__contains(spatialObject)
      if spatialObject:__type() == "Point" then
          return spatialObject:__distance(self) == 0
      elseif spatialObject:__type() == "Line" then
          return false
      elseif spatialObject:__type() == "Circle" then
          return spatialObject.point:__distance(self) == 0 and spatialObject.radius == 0
      elseif spatialObject:__type() == "LineSegment" then
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

    function LineSegment:__insideOf(spatialObject)
        return spatialObject:__contains(self)
    end

    function LineSegment:__distance(spatialObject)
        if spatialObject:__type() == "Circle" then
            return spatialObject.point:__distance(self) - spatialObject.radius
        elseif spatialObject:__type() == "Line" then
            return math.min(self.points[1]:__distance(spatialObject), self.points[2]:__distance(spatialObject))
        else
            local minDistance = nil
            for i, point in ipairs(self:__getPoints()) do
                distance = point:__distance(spatialObject)
                if minDistance == nil or distance <= minDistance then
                    minDistance = distance
                end
            end

            return minDistance
        end
    end

    --function LineSegment:__intersects(spatialObject)
    --    return #self:__intersectionPoints(spatialObject) >= 1
    --end

    function LineSegment:__intersects(spatialObject, a, b)
      -- parameter conversion
      local L1 = {X1=self.points[1].x,Y1=self.points[1].y,X2=self.points[2].x,Y2=self.points[2].y}
      local L2 = {X1=spatialObject.points[1].x,Y1=spatialObject.points[1].y,X2=spatialObject.points[2].x,Y2=spatialObject.points[2].y}
      
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
        return true, {x=x, y=y}
      end
      
      return false
    end

    function LineSegment:__draw(color, width)
    	local newPoint1 = WorldToScreen(1, self.points[1].x, 0, self.points[1].y)
			local newPoint2 = WorldToScreen(1, self.points[2].x, 0, self.points[2].y)
			if newPoint1.flag and newPoint2.flag then
				DrawLine(newPoint1.x, newPoint1.y, newPoint2.x, newPoint2.y ,width or 4,color or 0XFF00FF00);
			end
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

    function Polygon:__getPoints()
        return self.points
    end

    function Polygon:__addPoint(point)
        table.insert(self.points, point)
        self.lineSegments = nil
        self.triangles = nil
    end

    function Polygon:__getLineSegments()
        if self.lineSegments == nil then
            self.lineSegments = {}
            for i = 1, #self.points, 1 do
                table.insert(self.lineSegments, LineSegment(self.points[i], self.points[(i % #self.points) + 1]))
            end
        end

        return self.lineSegments
    end

    function Polygon:__contains(spatialObject)
        if spatialObject:__type() == "Line" then
            return false
        elseif #self.points == 3 then
            for i, point in ipairs(spatialObject:__getPoints()) do
                corner1DotCorner2 = ((point.y - self.points[1].y) * (self.points[2].x - self.points[1].x)) - ((point.x - self.points[1].x) * (self.points[2].y - self.points[1].y))
                corner2DotCorner3 = ((point.y - self.points[2].y) * (self.points[3].x - self.points[2].x)) - ((point.x - self.points[2].x) * (self.points[3].y - self.points[2].y))
                corner3DotCorner1 = ((point.y - self.points[3].y) * (self.points[1].x - self.points[3].x)) - ((point.x - self.points[3].x) * (self.points[1].y - self.points[3].y))

                if not (corner1DotCorner2 * corner2DotCorner3 >= 0 and corner2DotCorner3 * corner3DotCorner1 >= 0) then
                    return false
                end
            end

            if spatialObject:__type() == "Circle" then
                for i, lineSegment in ipairs(self:__getLineSegments()) do
                    if spatialObject.point:__distance(lineSegment) <= 0 then
                        return false
                    end
                end
            end

            return true
        else
            for i, point in ipairs(spatialObject:__getPoints()) do
                inTriangles = false
                for j, triangle in ipairs(self:__triangulate()) do
                    if triangle:__contains(point) then
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

    function Polygon:__insideOf(spatialObject)
        return spatialObject:__contains(self)
    end

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

    function Polygon:__triangulate()
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

                        if ((((point1.x - point.x) * (point2.y - point.y) - (point1.y - point.y) * (point2.x - point.x))) * self:__direction()) < 0 then
                            triangleCandidate = Polygon(point1, point, point2)

                            anotherPointInTriangleFound = false
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
    table.sort( points, function(a,b) return math.lengthOf(e,a) > math.lengthOf(e,b) end )
  end
  
  return points
end

    function Polygon:__distance(spatialObject)
        local minDistance = nil
        for i, lineSegment in ipairs(self:__getLineSegments()) do
            distance = lineSegment:__distance(spatialObject)
            if minDistance == nil or distance <= minDistance then
                minDistance = distance
            end
        end

        return minDistance
    end

    function Polygon:__tostring()
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

    function Polygon:__draw(color, width)
        for i, lineSegment in ipairs(self:__getLineSegments()) do
            lineSegment:__draw(color, width)
        end
    end
-- }
