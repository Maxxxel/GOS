local mapID = Game.mapID
local reverse
local walls, bushes, water

if mapID == HOWLING_ABYSS then
	local mapData = require 'MapPositionData_HA'
	walls, bushes, water = mapData[1], mapData[2], {}
	reverse = true
elseif mapID == SUMMONERS_RIFT then
	local mapData = require 'MapPositionData_SR'
	walls, bushes, water = mapData[1], mapData[2], mapData[3]
else
	print("No Map Data - Unsupported Map")
end

local modf = math.modf
MapPosition = {}

local function lineOfSight(A, B)
	local x0, x1, z0, z1 = A.x, B.x, A.z, B.z
	local sx,sz,dx,dz

	if x0 < x1 then
		sx = 1
		dx = x1 - x0
	else
		sx = -1
		dx = x0 - x1
	end

	if z0 < z1 then
		sz = 1
		dz = z1 - z0
	else
		sz = -1
		dz = z0 - z1
	end

	local err, e2 = dx - dz, nil

	if MapPosition:inWall({x = x0, z = z0}, true) then return false end

	while not (x0 == x1 and z0 == z1) do
		e2 = err + err

		if e2 > -dz then
			err = err - dz
			x0  = x0 + sx
		end

		if e2 < dx then
			err = err + dx
			z0  = z0 + sz
		end

		if MapPosition:inWall({x = x0, z = z0}, true) then return false end
	end

	return true
end

function MapPosition:inWall(position, skipTranslation)
	local x = position.x or position.pos.x
	local y = position.z or position.pos.z or position.y or position.pos.y

	if not skipTranslation then
		x = modf(x * 0.03030303)
		y = modf(y * 0.03030303)
	end

	local w = walls[x]

	if reverse then
		return not w or not w[y]
	else
		return w and w[y]
	end
end

function MapPosition:inBush(position)
	local x = modf((position.x or position.pos.x) * .03030303)
	local y = modf((position.z or position.pos.z or position.y or position.pos.y) * .03030303)
	local b = bushes[x]
	
	return b and b[y]
end

function MapPosition:inRiver(position)
	local x = modf((position.x or position.pos.x) * .02)
	local y = modf((position.z or position.pos.z or position.y or position.pos.y) * .02)
	local w = water[x]

	return w and w[y]
end

function MapPosition:intersectsWall(lineOrPointA, pointB)
	local lineA = pointB and lineOrPointA or lineOrPointA.points[1]
	local lineB = pointB or lineOrPointA.points[2]
	local A, B = {}, {}

	A.x = modf(lineA.x * .03030303)
	A.z = modf((lineA.z or lineA.y) * .03030303)
	B.x = modf(lineB.x * .03030303)
	B.z = modf((lineB.z or lineB.y) * .03030303)

	return not lineOfSight(A, B)
end

--Updated 10.2 by Maxxxel @ 26th January 2020
