require 'Pathfinding'

local Path = {}
local Path2 = {}
local Path3 = {}
local Path4 = {}

--[[
	There are 4 Algorithms:

	1. Theta
	2. LazyTheta
	3. StrictTheta
	4. RecursiveStrictTheta

	1. & 2. are the best ones for now, the others are kinda WIP.

	Usage:

	Table = Algorithm:FindPath(fromPosition1, toPosition2)
	--e.g. Path = Theta:FindPath(myHero.pos, mousePos)

	the table holds the points where he changes direction
	so you can loop trough the points in the table and with some small logic on your side you can calc with time where he will be because you know his waypoints.

	--[[
		e.g.

		for i = 1, #Path do
			local Point = Path[i]

			Draw.Circle(Point.x, 0, Point.y)
		end
	--]]
--]]

--Test all Algorithms same time (WILL LAG FOR SURE!!! BETTER USE ONE)
function OnTick()
    if Control.IsKeyDown(string.byte("I")) then
       Path = Theta:FindPath(myHero.pos, mousePos)
       Path1 = LazyTheta:FindPath(myHero.pos, mousePos)
       Path2 = StrictTheta:FindPath(myHero.pos, mousePos)
       Path3 = RecursiveStrictTheta:FindPath(myHero.pos, mousePos)
    end
end

function OnDraw()
	print("_____")
    if Path and #Path > 0 then
    	local length = 0
        for i = 1, #Path do
            local Point = Path[i]
            local Point2 = i + 1 <= #Path and Path[i + 1] or nil

            Draw.Circle(Point.x, 0, Point.y, 40, 0, Draw.Color(255, 0, 0, 0))
            
            if Point2 then
                Draw.Line(Vector(Point.x, 0, Point.y):To2D(), Vector(Point2.x, 0, Point2.y):To2D(), 10, Draw.Color(255, 0, 0, 0))
            end

            length = length + (Point2 and Core:GetDistance(Point, Point2) or 0)
        end

        print("Theta: " .. length)
    end

    if Path1 and #Path1 > 0 then
    	local length = 0
        for i = 1, #Path1 do
            local Point = Path1[i]
            local Point2 = i + 1 <= #Path1 and Path1[i + 1] or nil

            Draw.Circle(Point.x, 0, Point.y, 20, 0, Draw.Color(255, 255, 0, 0))
            
            if Point2 then
                Draw.Line(Vector(Point.x, 0, Point.y):To2D(), Vector(Point2.x, 0, Point2.y):To2D(), 5, Draw.Color(255, 255, 0, 0))
            end

            length = length + (Point2 and Core:GetDistance(Point, Point2) or 0)
        end

        print("LazyTheta: " .. length)
    end

    if Path2 and #Path2 > 0 then
    	local length = 0
        for i = 1, #Path2 do
            local Point = Path2[i]
            local Point2 = i + 1 <= #Path2 and Path2[i + 1] or nil

            Draw.Circle(Point.x, 0, Point.y, 10, 0, Draw.Color(255, 255, 255, 0))
            
            if Point2 then
                Draw.Line(Vector(Point.x, 0, Point.y):To2D(), Vector(Point2.x, 0, Point2.y):To2D(), 2.5, Draw.Color(255, 255, 255, 0))
            end

            length = length + (Point2 and Core:GetDistance(Point, Point2) or 0)
        end

        print("StrictTheta: " .. length)
    end

    if Path3 and #Path3 > 0 then
    	local length = 0
        for i = 1, #Path3 do
            local Point = Path3[i]
            local Point2 = i + 1 <= #Path3 and Path3[i + 1] or nil

            Draw.Circle(Point.x, 0, Point.y, 5, 0, Draw.Color(255, 0, 255, 0))
            
            if Point2 then
                Draw.Line(Vector(Point.x, 0, Point.y):To2D(), Vector(Point2.x, 0, Point2.y):To2D(), 1.25, Draw.Color(255, 0, 255, 0))
            end

            length = length + (Point2 and Core:GetDistance(Point, Point2) or 0)
        end

        print("RecursiveStricTheta: " .. length)
    end
    print("_____")
end
