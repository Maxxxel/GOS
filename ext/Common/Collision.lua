--[[
	Changelog:
	 0.01: EXT Release
--]]
if _G.Collision then return else _G.Collision = true end

require '2DGeometry'

local VersionCollision = 0.01
local sqrt, Next = math.sqrt, next

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

local function GetDistance(A, B)
	local B = B or myHero
	local VecA = Vector(A.pos or A)
	local VecB = Vector(B.pos or B)
	local ABX, ABY, ABZ = VecA.x - VecB.x, VecA.y - VecB.y, VecA.z - VecB.z

	return sqrt(ABX * ABX + ABY * ABY + ABZ * ABZ)
end

local function GetMinions(unit, mode)
	local Team = 
		mode == 1 and nil or
		mode == 2 and myHero.team or
		mode == 3 and (myHero.team == 100 and 200 or 100) or
		mode == 4 and 300 or
		mode == 5 and 400 or
		mode == 6 and 500
	local _ = {}

	for i = 1, Game.MinionCount() do
		local Minion = Game.Minion(i)

		if (not Team or Minion.team == Team or Team == 400 and Minion.team ~= myHero.team or Team == 500 and (Minion.team == myHero.team or Minion.team == 300)) then
			_[#_ + 1] = Minion
		end
	end

	return _
end

local Modes = {"ALL", "ALLY", "ENEMY", "JUNGLE", "ENEMYANDJUNGLE", "ALLYANDJUNGLE"}

class 'Collision'

	function Collision:SetSpell(range, projSpeed, delay, width, hitbox)
		self.range = range
		self.projSpeed = projSpeed
		self.delay = delay
		self.width = width
		self.hitbox = hitbox

		return self
	end

	function Collision:CorrectTarget(unit, range, exclude)
		if exclude and exclude.charName then --Unit
			if exclude.networkID == unit.networkID then return false end
		elseif exclude then --Table
			for _, __ in pairs(exclude) do
				if (_ and _.networkID and _.networkID == unit.networkID) or (__ and __.networkID and __.networkID == unit.networkID) then
					return false
				end
			end
		end

		return unit and unit.distance < range and unit.valid and not unit.dead and unit.health > 0 and unit.isTargetable
	end

	function Collision:SetPoint(unitOrPos)
		if unitOrPos.pos then
			return unitOrPos.pos
		else
			if unitOrPos.x then
				if unitOrPos.z then
					if unitOrPos.z == 0 then
						return {x = unitOrPos.x, y = 0, z = unitOrPos.y}
					else
						if unitOrPos.y then
							return unitOrPos
						else
							return {x = unitOrPos.x, y = 0, z = unitOrPos.z}
						end
					end
				end
			else
				print("ERROR for startPos/endPos")
			end
		end
	end

	function Collision:GetModeAsNumber(mode)
		if type(mode) == "number" then 
			return mode
		else
			local str = tostring(mode)
			for i = 1, #Modes do
				if Modes[i] == str or Modes[i]:lower() == str:lower() then
					return i
				end
			end
		end

		print("ERROR @GetModeAsNumber, unknown Value: " .. tostring(mode))
		return 0
	end

	function Collision:__GetCollision(startPos, endPos, mode, exclude)
		local exclude = exclude or {}
		local collidingUnits = {}
		local Start = self:SetPoint(startPos)
		local End = self:SetPoint(endPos)
		local MinionBlock, collidingMinions = self:__GetMinionCollision(Start, End, mode, exclude)
		local HeroBlock, collidingHeroes = self:__GetHeroCollision(Start, End, mode, exclude)

		if not (MinionBlock or HeroBlock) then
			return false
		else
			collidingUnits = MergeTables(collidingMinions, collidingHeroes)

			return (MinionBlock or HeroBlock), collidingUnits
		end
	end

	function Collision:__GetHeroCollision(Start, End, mode, exclude)
		local collidingHeroes = {}
		local HeroBlock = false
		local collidingLine = LineSegment(Start, End)

		if collidingLine then
			local Mode = self:GetModeAsNumber(mode)

			for i = 1, Game.HeroCount() do
				local Hero = Game.Hero(i)

				if Hero.networkID ~= myHero.networkID and self:CorrectTarget(Hero, self.range, exclude) and (Mode == 1 or ((Mode == 2 or Mode == 6) and Hero.team == myHero.team) or ((Mode == 3 or Mode == 4) and Hero.team ~= myHero.team)) then
					local P = Point(Hero)
					if P:__distance(collidingLine) < self.width + (self.hitbox and Hero.boundingRadius or 0) then
						HeroBlock = true
						collidingHeroes[#collidingHeroes + 1] = Hero
					end
				end
			end
		end

		return HeroBlock, collidingHeroes
	end

	function Collision:__GetMinionCollision(Start, End, mode, exclude)
		local allMinions = {}
		local collidingMinions = {}
		local MinionBlock = false
		local collidingLine = LineSegment(Start, End) or nil

		if collidingLine then
			local Mode = self:GetModeAsNumber(mode)
			allMinions = GetMinions(Start, Mode)

			for i = 1, #allMinions do
				local Minion = allMinions[i]

				if self:CorrectTarget(Minion, self.range, exclude) then
					local P = Point(Minion)
					if P:__distance(collidingLine) < self.width + (self.hitbox and Minion.boundingRadius or 0) then
						MinionBlock = true
						collidingMinions[#collidingMinions + 1] = Minion
					end
				end
			end
		end

		return MinionBlock, collidingMinions
	end


--[[
	___Collision API___

	for every Spell you want to check a Collision do one time the initiation
	parameters are: range, projSpeed, delay, width, hitbox
	Example:
				local Q = Collision:SetSpell(1200, 2000, 0.3, 60, true)

	if you want to check for Collision you have the choice to use 3 Functions
		1. __GetCollision checks for Minion + Hero collision
		2. __GetHeroCollision checks for Hero collision
		3. __GetMinionCollision checks for Minion collision

	you have to use one of the advanced filters
		1. "ALL"
		2. "ALLY"
		3. "ENEMY"
		4. "JUNGLE"
		5. "ENEMYANDJUNGLE"
		6. "ALLYANDJUNGLE"

	you can also add an exclude list/unit at the end

	Example:
				local Block, blockingUnits = Q:__GetCollision(myHero, mousePos, 5, {list of Units})
				local Block, blockingUnits = Q:__GetCollision(myHero, mousePos, 5, a_unit_you_want_to_exclude)
				local Block, blockingUnits = Q:__GetCollision(myHero, mousePos, "ENEMY")
				local Block, blockingUnits = Q:__GetCollision(myHero, mousePos, "enemy")
				local Block, blockingUnits = Q:__GetCollision(myHero, mousePos, "EnEmy")

				if Block then print("BLOCKED") else print("not BLOCKED") end
--]]
