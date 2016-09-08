--version 0.31
--[[
	Changelog:
	 0.31: Changed to many things to count and included Hero Collision and removed WayPoints
--]]

local VersionCollision = 0.31

function AutoUpdate(data)
    if tonumber(data) > tonumber(VersionCollision) then
        PrintChat("New version found! " .. data)
        PrintChat("Downloading update, please wait...")
        DownloadFileAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/Collision.lua", COMMON_PATH .. "Collision.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    end
end

GetWebResultAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/Collision.version", AutoUpdate)

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
	--[[
	DEACTIVATED
		function Collision:__GetHeroCollision(start,endu,mode)
			local Pos1 = type~="number" and GetOrigin(start) or nil
			local Pos2 = type~="number" and GetOrigin(endu)  or nil
			local heroes = {}
			local hCollision = {}
			if not mode then mode = ENEMY end
			if mode == ALLY then
				for i, mate in pairs(GOS:GetAllyHeroes()) do
					table.insert(heroes, mate)
				end
			elseif mode == ALL then
				for i, all in pairs(GOS:FindHeroes()) do
					table.insert(heroes, all)
				end
			elseif mode == ENEMY then
				for i, enemy in pairs(GOS:GetEnemyHeroes()) do
					table.insert(heroes, enemy)
	      end
			end
			local distance = GOS:GetDistance(start,endu)
			if distance > self.range then
				distance = self.range
			end
			local Track
			local distance = 0
			if Pos1 and Pos2 then
				distance = GOS:GetDistance(start,endu)
				Track = Line(Point(Pos1.x,Pos1.z),Point(Pos2.x,Pos2.z))
			elseif Pos1 and not Pos2 then
				local t = Point(Pos1.x,Pos1.z)
				distance = t:__distance(endu)
				Track = Line(Point(Pos1.x,Pos1.z),endu)
			elseif not Pos1 and Pos2 then
				local t = Point(Pos2.x,Pos2.z)
				distance = t:__distance(start)
				Track = Line(start,Point(Pos2.x,Pos2.z))
			else
				distance = start:__distance(endu)
				Track = Line(Point(start.x,start.z),Point(endu.x,endu.z))
			end
			for i, hero in ipairs(heroes) do
				if hero and not IsDead(hero) and IsVisible(hero) and Track then
					local hPos = GetOrigin(hero)
					local hP = Point(hPos.x,hPos.z)
					if (GOS:GetDistance(start,hero) < distance) or type(start)~="userdata" and (start:__distance(hP) < distance) then
						if 		 GetObjectType(start)==Obj_AI_Hero and GetObjectType(endu)==Obj_AI_Hero and endu~=hero then
							local Pos3 = GetPredictionForPlayer(GetOrigin(start),hero,GetMoveSpeed(hero),self.projSpeed,self.delay,self.range.self.width*2,false,false)
							local P = Point(Pos3.PredPos.x,Pos3.PredPos.z)
							if P:__distance(Track)<=self.width+GetHitBox(hero) then
								table.insert(hCollision,hero)
							end
						elseif GetObjectType(endu)==Obj_AI_Hero and endu~=hero and endu~=myHero and GetObjectType(start)~=Obj_AI_Hero then
							local Pos3 = GetPredictionForPlayer(start:__getPoints(),hero,GetMoveSpeed(hero),self.projSpeed,self.delay,self.range.self.width*2,false,true)
							local P = Point(Pos3.PredPos.x,Pos3.PredPos.z)
							if P:__distance(Track)<=self.width+GetHitBox(hero) then
								table.insert(hCollision,hero)
							end
						elseif GetObjectType(endu)==Obj_AI_Hero and endu~=hero and GetObjectType(start)~=Obj_AI_Hero then
							local Pos3 = GetPredictionForPlayer(start:__getPoints(),hero,GetMoveSpeed(hero),self.projSpeed,self.delay,self.range,self.width*2,false,true)
							DrawCircle(Pos3.PredPos.x,Pos3.PredPos.y,Pos3.PredPos.z,100,0,0,0xffff0000)
							local P = Point(Pos3.PredPos.x,Pos3.PredPos.z)
							if P:__distance(Track)<=self.width+GetHitBox(hero) then
								table.insert(hCollision,hero)
							end
						else
							if hP:__distance(Track)<=self.width+GetHitBox(hero) then
								table.insert(hCollision,hero)
							end
						end
					end
				end
			end
			if #hCollision > 0 then return true, hCollision else return false, hCollision end
		end
		--]]
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
			collidingLine:__draw()
			for i = 1, #minionManager.objects do
				local __ = minionManager.objects[i]
				if __ and not __.charName:lower():find("dummy") and __.valid and __.visible and not __.dead and ((normal and __.team == team) or (not normal and (team == 400 and (__.team == 300 or __.team == (myHero.team == 100 and 200 or 100)) or team == 0))) and (maxRange and GetDistance(startPos, endPos) < self.range or not maxRange) then
					if type(exclude) == "Object" then
						if exclude.networkID ~= __.networkID then
							local Place = Point(__)
							if Place:__distance(collidingLine) <= (self.width + __.boundingRadius) * .5 then
								MinionInWay = true
								insert(collidingMinions, __)
							end
						end
					elseif Next(exclude) ~= nil then
						for i = 1, #exclude do
							local check = exclude[i]
							if __.networkID ~= check.networkID then
								local Place = Point(__)
								if Place:__distance(collidingLine) <= (self.width + __.boundingRadius) * .5 then
									MinionInWay = true
									insert(collidingMinions, __)
								end
							end
						end
					else
						local Place = Point(__)
						if Place:__distance(collidingLine) <= (self.width + __.boundingRadius) * .5 then
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
