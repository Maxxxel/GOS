require '2DGeometry'
local remove = table.remove

local function slice(table, from, to)
	to = to or #table
	local newTable = {}

	for _, data in pairs(table) do
		if _ <= to and _ > from then
			newTable[#newTable + 1] = data
		end
	end

	return newTable
end

local function merge(A, B)
	local newTable = {}

	for i = 1, #A do
		newTable[#newTable + 1] = A[i]
	end

	for i = 1, #B do
		newTable[#newTable + 1] = B[i]
	end

	return newTable
end

function RDPA(points, tolerance)
	points = points.points or points
	local distanceMax, index = 0, 0
	local pointsEnd = #points
	for i = 2, pointsEnd do
		local distance = points[i]:__distance(LineSegment(points[1], points[pointsEnd]))
		if distance > distanceMax then
			index = i
			distanceMax = distance
		end
	end

	if distanceMax > tolerance then
		local firstHalf = RDPA(
			slice(points, 1, index + 1),
			tolerance
		)
		local secondHalf = RDPA(
			slice(points, index),
			tolerance
		)
		remove(secondHalf, 1)
		points = merge(firstHalf, secondHalf)
	else
		points = {points[1], points[pointsEnd]}
	end

	return points
end

--[[Example:
require 'MapPositionGOS'
local reduced = (RDPA(walls[1], 50))
local P = Polygon()
P.points = reduced

--Look Dragon Wall
OnDraw = function( ... )
	walls[1]:__draw(1)
	P:__draw(1, 1)
	print(#P.points)
end
--]]
