--version 0.3
local VersionCollision = 0.3

function AutoUpdate(data)
    if tonumber(data) > tonumber(Version2DGeometry) then
        PrintChat("New version found! " .. data)
        PrintChat("Downloading update, please wait...")
        DownloadFileAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/Collision.lua", COMMON_PATH .. "Collision.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    end
end

GetWebResultAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/Collision.version", AutoUpdate)

local minionWay = {}
class 'Collision' --{
    ALL = 1
    ENEMY = 2
    ALLY = 3
--init the Collision
	function Collision:__init(range,projSpeed,delay,width)
		self.ping = GetLatency()
		self.range = range
		self.projSpeed = projSpeed
		self.delay = delay
		self.width = width/2 --because we will create a line where my hero is the middle
	end
--GetCollision
	function Collision:__GetCollision(start,endu,mode)
		if not mode then mode = ENEMY end
		local units = {}
		local hitM, minions = self:__GetMinionCollision(start,endu,mode)
		--local hitH, heroes = self:__GetHeroCollision(start,endu,mode)
		if not hitM then return false end
		--if not hitH then return hitM, minions end
		for i, enemy in ipairs(heroes) do
			table.insert(units,enemy)
		end
		for i, minion in ipairs(minions) do
			table.insert(units,minion)
		end
		return true, units
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
	function Collision:__GetMinionCollision(start, endu, mode, exclude)
		local Pos1 = type(start) == "Object" and GetOrigin(start) or nil
		local Pos2 = type(endu) == "Object" and GetOrigin(endu)  or nil

		local heroes = {}
		local mCollision = {}

		if not mode then mode = ENEMY end

		if mode == ALLY then
			for i, mate in pairs(minionManager.objects) do
				if exclude and GetTeam(mate) == GetTeam(myHero) then
					if type(exclude) == "table" then
						for i = 1, #exclude do
							if exclude[i].networkID ~= mate.networkID then
								table.insert(heroes, mate)
							end
						end
					else
						if exclude[i].networkID ~= mate.networkID then
							table.insert(heroes, mate)
						end
					end
				elseif GetTeam(mate) == GetTeam(myHero) then
					table.insert(heroes, mate)
				end
			end
		elseif mode == ALL then
			for i, all in pairs(minionManager.objects) do
				if exclude then
					if type(exclude) == "table" then
						for i = 1, #exclude do
							if exclude[i].networkID ~= all.networkID then
								table.insert(heroes, all)
							end
						end
					else
						if exclude[i].networkID ~= all.networkID then
							table.insert(heroes, all)
						end
					end
				else
					table.insert(heroes, all)
				end
			end
		elseif mode == ENEMY then
			for i, enemy in pairs(minionManager.objects) do
				if exclude and GetTeam(enemy) ~= GetTeam(myHero) then
					if type(exclude) == "table" then
						for i = 1, #exclude do
							if exclude[i].networkID ~= enemy.networkID then
								table.insert(heroes, enemy)
							end
						end
					else
						if exclude[i].networkID ~= enemy.networkID then
							table.insert(heroes, enemy)
						end
					end
				elseif GetTeam(enemy) ~= GetTeam(myHero) then
					table.insert(heroes, enemy)
				end
			end
		end

		local distance = 0
		local Track
		if Pos1 and Pos2 then
			distance = GetDistance(start,endu)
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
		if distance > self.range then
			distance = self.range
		end
		for i, hero in ipairs(heroes) do
			if hero and not IsDead(hero) and IsVisible(hero) and Track then
				local hPos = GetOrigin(hero)
				local hP = Point(hPos.x,hPos.z)
				if (GetDistance(start,hero) < distance) or type(start)~="Object" and start:__distance(hP) < distance then
					if hP:__distance(Track)<=self.width+GetHitBox(hero) then
						table.insert(mCollision,hero)
					end
					if minionWay.place and minionWay.ID==GetNetworkID(hero) then
						local mP = Point(place.x,place.z)
						if mP:__distance(Track)<=self.width+GetHitBox(hero) then
							table.insert(mCollision,hero)
						end
					end
					if minionWay.place2 and minionWay.ID2==GetNetworkID(hero) then
						local mP = Point(place2.x,place2.z)
						if mP:__distance(Track)<=self.width+GetHitBox(hero) then
							table.insert(mCollision,hero)
						end
					end
				end
			end
		end
		if #mCollision > 0 then return true, mCollision else return false, mCollision end
	end
-- }

OnProcessWaypoint(function(Object,waypointProc)
	if GetObjectType(Object) == Obj_AI_Minion then
		if GetTeam(Object)~=GetTeam(myHero) then
			local test = {}
			if waypointProc.index == 1 then
				test = {place=waypointProc.position, ID=GetNetworkID(Object)}
				table.insert(minionWay, test)
			end
			if waypointProc.index == 2 then
				test = {place2=waypointProc.position, ID2=GetNetworkID(Object)}
				table.insert(minionWay, test)
			end
		end
	end
end)
