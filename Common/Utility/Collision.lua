--[[
	Changelog:
	 0.31: Changed to many things to count and removed WayPoints
	 0.32: Added Hero Collision
	 0.33: Fixed small bug
	 0.34: Added Pathing
	 0.35: Fixed small bug
	 0.36: Fxed some bugs
	 0.37: Fixed some small bugs
	 0.38: Added check for Multiload and delayed the UpdateCheck
--]]
if _G.Collision then return end

local VersionCollision = 0.38

local function AutoUpdate(data)
    local num = tonumber(data)
    if num > VersionCollision then
	PrintChat("New version found! " .. data)
	PrintChat("Downloading update, please wait...")
	DownloadFileAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/Collision.lua", COMMON_PATH .. "Collision.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    end
end

DelayAction(function()
	GetWebResultAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/Collision.version", AutoUpdate)
end, 1)

if not FileExist(COMMON_PATH.."Pathing.lua") then
	PrintChat("A Lib is missing...Downloading...")
	DownloadFileAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/Pathing.lua", COMMON_PATH.."Pathing.lua", function() PrintChat("Download Completed, please 2x F6!") return end)
	return
end

require '2DGeometry'
require 'Pathing'

local Next, insert = next, table.insert
local function MergeTables(table1, table2)
    if type(table1) == 'table' and type(table2) == 'table' then
    	local newTable = {}
    	if Next(table2) ~= nil then
	        for k,v in pairs(table2) do
	        	if type(v) == 'table' and type(table1[k] or false) == 'table' then 
	        		self:MergeTables(table1[k], v) 
	        	else 
	        		table1[k] = v 
	        	end 
	        	return table1
	        end
	    else
	    	return table1
	    end
    end
end

class 'Collision'
    ALL = 1
    ENEMY = 2
    ALLY = 3
    JUNGLE = 4
    ENEMYANDJUNGLE = 5

	--init the Collision
	function Collision:__init(range, projSpeed, delay, width)
		self.ping = GetLatency()
		self.range = range
		self.projSpeed = projSpeed
		self.delay = delay
		self.width = width
		Path:__init(range)
	end
	--GetCollision for all Units
	function Collision:__GetCollision(startPos, endPos, mode, exclude, maxRange)
		if not mode then mode = ENEMY end
		local collidingUnits = {}

		local MinionInWay, collidingMinions = self:__GetMinionCollision(startPos, endPos, mode, exclude, maxRange)
		local HeroInWay, collidingHeroes = self:__GetHeroCollision(startPos, endPos, mode, exclude, maxRange)

		collidingUnits = MergeTables(collidingMinions, collidingHeroes)

		if not (MinionInWay or HeroInWay) then return false end

		return (MinionInWay or HeroInWay), collidingUnits
	end
	--collision with enemy
	function Collision:__GetHeroCollision(startPos, endPos, mode, exclude, maxRange)
		--1. translate startPos and endPos to same level
		local Start = {x = 0, y = 0, z = 0}
		if type(startPos) == "Object" or type(startPos) == "table" or type(startPos) == "Point" then
			Start.x = startPos.x
			Start.y = not startPos.z and startPos.y or 0
			Start.z = startPos.z and startPos.z or 0
		else
			print("Collision: Error, startPos has wrong format.")
		end

		local End = {x = 0, y = 0, z = 0}
		if type(endPos) == "Object" or type(endPos) == "table" or type(endPos) == "Point" then
			End.x = endPos.x
			End.y = not endPos.z and endPos.y or 0
			End.z = endPos.z and endPos.z or 0

			if maxRange then
				End = Vector(startPos) - (Vector(startPos) - Vector(endPos)) * (self.range / GetDistance(startPos, endPos))
			end
		else
			print("Collision: Error, endPos has wrong format.")
		end
		------------

		--2. Set needed tables
		local collidingHeroes = {}
		local HeroInWay = false
		local distance = GetDistance(Start, End) > self.range and self.range or GetDistance(Start, End)
		local collidingLine = LineSegment(Point(Start), Point(End)) or nil
		------------

		--Get Minions + Collision wrapped together
		if not mode then mode = ENEMY end
		local team = mode == 3 and myHero.team or
			  		 mode == 4 and 300 or
			  		 mode == 2 and (myHero.team == 100 and 200 or 100) or
			  		 mode == 5 and 400 or
			  		 mode == 1 and 0
		local normal = mode == 2 or mode == 3 or mode == 4

		if collidingLine then
			for i = 1, #heroManager.iCount do
				local __ = heroManager.iCount[i]
				if __ and __.valid and __.visible and not __.dead and ((normal and __.team == team) or (not normal and (team == 400 and (__.team == 300 or __.team == (myHero.team == 100 and 200 or 100)) or team == 0))) and (maxRange and GetDistance(startPos, endPos) < self.range or not maxRange) then
					if type(exclude) == "Object" then
						if exclude.networkID ~= __.networkID then
							local Place = Point(Path:GetPositionAfter(__, __.distance / self.projSpeed))
							if Place:__distance(collidingLine) <= (self.width + __.boundingRadius) * .5 then
								HeroInWay = true
								insert(collidingHeroes, __)
							end
						end
					elseif Next(exclude) ~= nil then
						for i = 1, #exclude do
							local check = exclude[i]
							if __.networkID ~= check.networkID then
								local Place = Point(Path:GetPositionAfter(__, __.distance / self.projSpeed))
								if Place:__distance(collidingLine) <= (self.width + __.boundingRadius) * .5 then
									HeroInWay = true
								insert(collidingHeroes, __)
								end
							end
						end
					else
						local Place = Point(Path:GetPositionAfter(__, __.distance / self.projSpeed))
						if Place:__distance(collidingLine) <= (self.width + __.boundingRadius) * .5 then
							HeroInWay = true
							insert(collidingHeroes, __)
						end
					end
				end
			end
		else
			collidingHeroes = {}
			HeroInWay = false
		end
		------------
		return HeroInWay, collidingHeroes
	end
	--collision with minion
	function Collision:__GetMinionCollision(startPos, endPos, mode, exclude, maxRange)
		--1. translate startPos and endPos to same level
		local Start = {x = 0, y = 0, z = 0}
		if type(startPos) == "Object" or type(startPos) == "table" or type(startPos) == "Point" then
			Start.x = startPos.x
			Start.y = not startPos.z and startPos.y or 0
			Start.z = startPos.z and startPos.z or 0
		else
			print("Collision: Error, startPos has wrong format.")
		end

		local End = {x = 0, y = 0, z = 0}
		if type(endPos) == "Object" or type(endPos) == "table" or type(endPos) == "Point" then
			End.x = endPos.x
			End.y = not endPos.z and endPos.y or 0
			End.z = endPos.z and endPos.z or 0

			if maxRange then
				End = Vector(startPos) - (Vector(startPos) - Vector(endPos)) * (self.range / GetDistance(startPos, endPos))
			end
		else
			print("Collision: Error, endPos has wrong format.")
		end
		------------

		--2. Set needed tables
		local collidingMinions = {}
		local MinionInWay = false
		local distance = GetDistance(Start, End) > self.range and self.range or GetDistance(Start, End)
		local collidingLine = LineSegment(Point(Start), Point(End)) or nil
		------------

		--Get Minions + Collision wrapped together
		if not mode then mode = ENEMY end
		local team = mode == 3 and myHero.team or
			  		 mode == 4 and 300 or
			  		 mode == 2 and (myHero.team == 100 and 200 or 100) or
			  		 mode == 5 and 400 or
			  		 mode == 1 and 0
		local normal = mode == 2 or mode == 3 or mode == 4

		if collidingLine then
			for i = 1, #minionManager.objects do
				local __ = minionManager.objects[i]
				if __ and not __.charName:lower():find("dummy") and __.valid and __.visible and not __.dead and ((normal and __.team == team) or (not normal and (team == 400 and (__.team == 300 or __.team == (myHero.team == 100 and 200 or 100)) or team == 0))) and (maxRange and GetDistance(startPos, endPos) < self.range or not maxRange) then
					if type(exclude) == "Object" then
						if exclude.networkID ~= __.networkID then
							local Place = Point(Path:GetPositionAfter(__, __.distance / self.projSpeed))
							if Place:__distance(collidingLine) < self.width + __.boundingRadius - 15  then
								MinionInWay = true
								insert(collidingMinions, __)
							end
						end
					elseif Next(exclude) ~= nil then
						for i = 1, #exclude do
							local check = exclude[i]
							if __.networkID ~= check.networkID then
								local Place = Point(Path:GetPositionAfter(__, __.distance / self.projSpeed))
								if Place:__distance(collidingLine) <= self.width + __.boundingRadius - 15 then
									MinionInWay = true
									insert(collidingMinions, __)
								end
							end
						end
					else
						local Place = Point(Path:GetPositionAfter(__, __.distance / self.projSpeed))
						if Place:__distance(collidingLine) <= self.width + __.boundingRadius - 15  then
							MinionInWay = true
							insert(collidingMinions, __)
						end
					end
				end
			end
		else
			collidingMinions = {}
			MinionInWay = false
		end
		------------
		return MinionInWay, collidingMinions
	end
