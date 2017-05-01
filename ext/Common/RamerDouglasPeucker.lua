require '2DGeometry'

local function DP(points, start, last, epsilon)
	points = points.points or points
	local dmax = 0
	local index = start

	for i = index + 1, last do
		local d = points[i]:__distance(Line(points[start], points[last]))
		if d > dmax then
			index = i
			dmax = d
		end
	end

	if dmax > epsilon then
		local res1 = DP(points, start, index, epsilon)
		local res2 = DP(points, index, last, epsilon)
		local finalRes = {}

		for i = 1, #res1 do
			finalRes[#finalRes + 1] = res1[i]
		end

		for i = 1, #res2 do
			finalRes[#finalRes + 1] = res2[i]
		end

		return finalRes
	else
		return {points[start], points[last]}
	end
end

--[[Example:
require 'MapPositionGOS'
local reduced = (DP(walls[1], 1, #walls[1].points, 50))
local P = Polygon()
P.points = reduced

--Look Dragon Wall
OnDraw = function( ... )
	walls[1]:__draw(1)
	P:__draw(1, 1)
	print(#P.points)
end
--]]
