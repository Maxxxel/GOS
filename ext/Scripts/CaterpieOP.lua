require '2DGeometry'

local sqrt, cos, sin, rad = math.sqrt, math.cos, math.sin, math.rad
local QRange = 650
local BounceRange = 450
local Angle = 62.5

function GetDistance(A, B)
	local ABX, ABY = A.x - B.x, A.z - B.z

	return sqrt(ABX * ABX + ABY * ABY)
end

function RotateVector2D(v, n, theta)
	x,y = v.x, v.z
	x_origin, y_origin = n.x, n.z
    local cs = cos(theta)
	local sn = sin(theta)
	local translated_x = x - x_origin
	local translated_y = y - y_origin
	local result_x = translated_x * cs - translated_y * sn
	local result_y = translated_x * sn + translated_y * cs

	result_x = result_x + x_origin
	result_y = result_y + y_origin

	return Vector(result_x, v.y, result_y)
end

local function Main()
	local Me = Vector(myHero.pos)
	local Where = Vector(mousePos)
	local Dist = GetDistance(Me, Where)
	local CastPos = Me - (Me - Where):Normalized() * (Dist > QRange and QRange or Dist)
	Draw.Line(Me:To2D(), CastPos:To2D(), 5)
	Draw.Circle(CastPos, 50, 1)
	--GetMaxBounceSpot
	local MaxSpot = CastPos - (CastPos - Me):Normalized() * (-BounceRange)
	Draw.Circle(MaxSpot, 25, 1)
	--Get Angle Points
	local PointA = RotateVector2D(MaxSpot, CastPos, rad(Angle))
	local PointB = RotateVector2D(MaxSpot, CastPos, rad(-Angle))
	Draw.Circle(PointA, 20, 1)
	Draw.Circle(PointB, 20, 1)
	--Enter Points to Polygon
	local P = Polygon()
	P.points[1] = CastPos
	P.points[2] = PointA
	P.points[3] = MaxSpot
	P.points[4] = PointB
	P:__draw()
end

Callback.Add("Draw", function() Main() end)
