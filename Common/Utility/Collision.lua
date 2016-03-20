--version 0.2
--fixed type Error
require('Inspired')

class "Point" --{
--initiating
  function Point:__init(x,y,z)
    local pos = type(x) ~= "number" and GetOrigin(x) or nil
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
     elseif v:__type()=="Point" then
  		return Point(self.x*v.x,self.y*v.y,self.z*v.z)
    else
      PrintChat("Error on Point:__multiply, value is unexpected")
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
    elseif Object:__type()=="Circle" then
      --missing
    end
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
  function Line:__getLineSegment()
		return {}
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
--}

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
	function Collision:__GetMinionCollision(start,endu,mode)
		local Pos1 = type(start)~="number" and GetOrigin(start) or nil
		local Pos2 = type(endu)~="number" and GetOrigin(endu)  or nil
		local heroes = {}
		local mCollision = {}
		if not mode then mode = ENEMY end
		if mode == ALLY then
			for i, mate in pairs(minionManager.objects) do
				if GetTeam(mate) == GetTeam(myHero) then
					table.insert(heroes, mate)
				end
			end
		elseif mode == ALL then
			for i, all in pairs(minionManager.objects) do
				table.insert(heroes, all)
			end
		elseif mode == ENEMY then
			for i, enemy in pairs(minionManager.objects) do
				if GetTeam(enemy) ~= GetTeam(myHero) then
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
