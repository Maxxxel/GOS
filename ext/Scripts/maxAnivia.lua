if myHero.charName ~= 'Anivia' then return end
require '2DGeometry'
require 'PremiumPrediction'

local version = 0.2
local Timer = Game.Timer
local SpellLetters = {[1] = "Q1", [2] = "Q2", [3] = "W", [4] = "E", [5] = "R1", [6] = "R2"}
local rem = table.remove
local Control = Control
local CastSpell = Control.CastSpell
local min, max, sqrt = math.min, math.max, math.sqrt
local myTeam = myHero.team
local enemyTeam = 300 - myTeam
local Colors = {
	[1] = Draw.Color(255, 255, 0, 0),
	[2] = Draw.Color(255, 0, 0, 255),
	[3] = Draw.Color(255, 0, 255, 0),
	[4] = Draw.Color(255, 255, 255, 0),
	[5] = Draw.Color(255, 0, 0, 0),
	[6] = Draw.Color(255, 255, 255, 255),
	[7] = Draw.Color(255, 255, 0, 255),
	[8] = Draw.Color(255, 0, 255, 255)
}
local orbModes = {
	[0] = "Combo",
	[1] = "Harass",
	[2] = "LaneClear",
	[3] = "LaneClear",
	[4] = "lastHit"
}

local Anivia = setmetatable({}, {
	__call = function(self)
		self:init()
	end
})

local function ReadFile(path, fileName)
	local file = io.open(path .. fileName, "r")
	if not file then return false end
	local result = file:read()
	file:close()
	return result
end

local function DownloadFile(url, path, fileName)
    DownloadFileAsync(url, path .. fileName, function() end)
    while not FileExist(path .. fileName) do end
end

local function CalcMagicalDamage(source, target, amount)
	local mr = target.magicResist
	local value = 100 / (100 + (mr * (source.magicPenPercent + 1)) - source.magicPen)

	if mr < 0 then
		value = 2 - 100 / (100 - mr)
	elseif (mr * (source.magicPenPercent + 1)) - source.magicPen < 0 then
		value = 1
	end

	return value * amount
end

local function GetDistance(a, b)
	b = b or myHero
	b = b.pos and b or {pos = b}
	a = a.pos and a or {pos = a}
	local abx = b.pos.x - a.pos.x
	local aby = b.pos.y - a.pos.y
	local abz = b.pos.z - a.pos.z

	return sqrt(abx * abx + aby * aby + abz * abz)
end

local function GetDistance2D(a, b)
	b = b or myHero
	b = b.pos and b or {pos = b}
	a = a.pos and a or {pos = a}
	local abx = b.pos.x - a.pos.x
	local abz = b.pos.z - a.pos.z

	return sqrt(abx * abx + abz * abz)
end

function Anivia:init()
	self:loadVariables()
	self:loadCallbacks()
	self:loadMenu()
end

function Anivia:onTick()
	if not self.unitsLoaded then
		self:loadUnits()
		return
	end

	self:QHandler()
	self:QStunHandler()
	self:EHandler()
	self:RHandler()
	self:AutoQ()
	self:AutoR()
	self:Combo()
	self:Harass()
	self:Farm()
end

function Anivia:onDraw()
	for i = 1, #self.Enemies do
		local unit = self.Enemies[i]

		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)

	        if buff.count > 0 then
	            Draw.Text(
		            "type: " .. tostring(buff.type) .. " | " ..
					"name: " .. tostring(buff.name) .. " | " ..
					"startTime: " .. tostring(buff.startTime) .. " | " ..
					"expireTime: " .. tostring(buff.expireTime) .. " | " ..
					"duration: " .. tostring(buff.duration) .. " | " ..
					"stacks: " .. tostring(buff.stacks) .. " | " ..
					"count: " .. tostring(buff.count), 
				unit.pos2D.x, unit.pos2D.y + i * 20)
	        end
		end
	end

	if not myHero.dead and self.Menu.Draw.Enabled:Value() then
		for spell = 1, 6, 1 do
			local Active = 
				(spell == 1 and self.Spells.Q.ready()) or 
				(spell == 2 and self.Q) or 
				(spell == 3 and self.Spells.W.ready()) or 
				(spell == 4 and self.Spells.E.ready()) or 
				(spell == 5 and self.Spells.R.ready()) or 
				(spell == 6 and self.R)

			local extra = 
				(spell == 2 and self.Q) or 
				(spell == 6 and self.R) or 
				(spell == 4 and self.E) or myHero

			if self.Menu.Draw["Draw" .. SpellLetters[spell]].Draw:Value() and Active then
				local Range = 
					spell == 1 and self.Spells.Q.range or 
					spell == 2 and self.Spells.Q.radius or 
					spell == 3 and self.Spells.W.range or 
					spell == 4 and self.Spells.E.range + myHero.boundingRadius or 
					spell == 5 and self.Spells.R.range or 
					spell == 6 and self.Spells.R.width()
				local Width = self.Menu.Draw["Draw" .. SpellLetters[spell]].Width:Value()
				local Color = Colors[tonumber(self.Menu.Draw["Draw" .. SpellLetters[spell]].Color:Value())]

				Draw.Circle(extra.pos, Range, Width, Color)
			end
		end

		-- if self.Menu.Draw.MissingHP:Value() then
		-- 	for ID, data in pairs(self.DamageCalcs) do
		-- 		if self.Menu.Draw.MissingHP:Value() and Essentials:GoodTarget(data.unit) then
		-- 			Draw.Text(data.text, 10, Vector(data.unit.pos2D), data.color)
		-- 		end
		-- 	end
		-- end
	end
end

function Anivia:onSpellCast()
	if myHero.isChanneling and myHero.activeSpell.valid then
		if myHero.activeSpellSlot == 0 and not self.Q and not self.QCasted then
			self.QCasted = true
			self.Q = self:detectQ()

			DelayAction(function()
				Anivia.QCasted = false
			end, .5)
		elseif myHero.activeSpellSlot == 2 and not self.E then
			self.E = self:detectE()
		end
	end

	if myHero:GetSpellData(0).toggleState == 2 and not self.Q then
		self.Q = self:detectQ()
	end
end

function Anivia:loadMenu()
	self.Menu = MenuElement({id = 'maxAnivia', name = 'maxAnivia v' .. version, type = MENU, leftIcon = "http://orig08.deviantart.net/456c/f/2015/162/1/3/anivia_by_fazie69-d8wuue5.png"})
	self.Menu:MenuElement({id = "Combo", name = " 1. Combo", type = MENU})
		self.Menu.Combo:MenuElement({id = "QMode", name = "1. Q in Combo", value = 1, drop = {"Always", "Manual", "After R"}})
		self.Menu.Combo:MenuElement({id = "WMode", name = "2. W in Combo", value = 1, drop = {"Hold in R", "Manual", "Engage Only - WIP", "Disengage Only - WIP", "Peel Only -WIP"}})
		self.Menu.Combo:MenuElement({id = "EMode", name = "3. E in Combo", value = 3, drop = {"Always", "Manual", "Freezed Only"}})
		self.Menu.Combo:MenuElement({id = "RMode", name = "4. R in Combo", value = 3, drop = {"Always", "Manual", "After Q Stun/Slowed/Close"}})
	self.Menu:MenuElement({id = "Harass", name = " 2. Harass", type = MENU})
		self.Menu.Harass:MenuElement({id = "QMode", name = "1. Q in Harass", value = 1, drop = {"Always", "Manual", "After R"}})
		self.Menu.Harass:MenuElement({id = "WMode", name = "2. W in Harass", value = 1, drop = {"Hold in R", "Manual", "Engage Only - WIP", "Disengage Only - WIP", "Peel Only -WIP"}})
		self.Menu.Harass:MenuElement({id = "EMode", name = "3. E in Harass", value = 3, drop = {"Always", "Manual", "Freezed Only"}})
		self.Menu.Harass:MenuElement({id = "RMode", name = "4. R in Harass", value = 3, drop = {"Always", "Manual", "After Q Stun/Close"}})
		self.Menu.Harass:MenuElement({id = "mana", name = "5. Min. Mana for Harass (%)", value = 25, min = 0, max = 100, step = 1})
	self.Menu:MenuElement({id = "Farm", name = " 3. Farm", type = MENU})
		self.Menu.Farm:MenuElement({id = "Mode", name = "1. Mode", value = 1, drop = {"AA & E", "Advanced (FPS-Hungry)", "None"}})
		self.Menu.Farm:MenuElement({id = "Q", 			name = "2. Q-Menu (advanced)", type = MENU})
			self.Menu.Farm.Q:MenuElement({id = "Enabled", 	name = "1. Enabled", value = true})
			self.Menu.Farm.Q:MenuElement({id = "Mana", 		name = "2. Min. Mana(%): ", value = 25, min = 10, max = 100, step = 1})
			self.Menu.Farm.Q:MenuElement({id = "Hits", 		name = "3. Min. Kills: ", value = 3, min = 1, max = 5, step = 1})
			self.Menu.Farm.Q:MenuElement({id = "OnR", 		name = "4. Wont Q if R!!!", type = SPACE})
		self.Menu.Farm:MenuElement({id = "E", 			name = "3. E-Menu (advanced & 'AA & E')", type = MENU})
			self.Menu.Farm.E:MenuElement({id = "Enabled", 	name = "1. Enabled", value = true})
			self.Menu.Farm.E:MenuElement({id = "Mana", 		name = "2. Min. Mana(%): ", value = 25, min = 10, max = 100, step = 1})
			self.Menu.Farm.E:MenuElement({id = "OnR", 		name = "3. Wont E if R!!!", type = SPACE})
		self.Menu.Farm:MenuElement({id = "R", 			name = "4. R-Menu (advanced)", type = MENU})
			self.Menu.Farm.R:MenuElement({id = "Enabled", 	name = "1. Enabled", value = true})
			self.Menu.Farm.R:MenuElement({id = "Mana", 		name = "2. Min. Mana(%): ", value = 25, min = 10, max = 100, step = 1})
			self.Menu.Farm.R:MenuElement({id = "Hits", 		name = "3. Min. Kills (over Time): ", value = 3, min = 1, max = 5, step = 1})
			self.Menu.Farm.R:MenuElement({id = "Time", 		name = "4. Min. Time: ", value = 3, min = 1, max = 10, step = 1})
	self.Menu:MenuElement({id = "Clear", name = " 4. Clear (FPS-Hungry)", type = MENU})
		self.Menu.Clear:MenuElement({id = "Q", 				name = "1. Q-Menu", type = MENU})
			self.Menu.Clear.Q:MenuElement({id = "Enabled", 		name = "1. Enabled", value = true})
			self.Menu.Clear.Q:MenuElement({id = "Mana", 			name = "2. Min. Mana(%): ", value = 25, min = 0, max = 100, step = 1})
			self.Menu.Clear.Q:MenuElement({id = "Hits", 			name = "3. Min. Hits: ", value = 4, min = 1, max = 5, step = 1})
			self.Menu.Clear.Q:MenuElement({id = "OnR", 			name = "4. Wont Q if R!!!", type = SPACE})
		self.Menu.Clear:MenuElement({id = "E", 				name = "2. E-Menu", type = MENU})
			self.Menu.Clear.E:MenuElement({id = "Enabled", 		name = "1. Enabled", value = true})
			self.Menu.Clear.E:MenuElement({id = "Mana", 		name = "2. Min. Mana(%): ", value = 25, min = 0, max = 100, step = 1})
			self.Menu.Clear.E:MenuElement({id = "OnR", 			name = "3. Wont E if R!!!", type = SPACE})
		self.Menu.Clear:MenuElement({id = "R", 				name = "3. R-Menu", type = MENU})
			self.Menu.Clear.R:MenuElement({id = "Enabled", 		name = "1. Enabled", value = true})
			self.Menu.Clear.R:MenuElement({id = "Mana", 			name = "2. Min. Mana(%): ", value = 25, min = 0, max = 100, step = 1})
			self.Menu.Clear.R:MenuElement({id = "Hits", 			name = "3. Min. Hits: ", value = 4, min = 1, max = 5, step = 1})
	self.Menu:MenuElement({id = "Killsteal", name = " 5. Killsteal (WIP)", type = MENU})
		-- self.Menu.Killsteal:MenuElement({id = "Enabled", name = "1. Enabled", value = true})
		-- self.Menu.Killsteal:MenuElement({id = "Ignite", name = "2. Use Ignite", value = true})
	self.Menu:MenuElement({id = "AddOns", name = " 6. AddOns", type = MENU})
		self.Menu.AddOns:MenuElement({id = "AutoR", name = "1. Auto R", type = MENU})
			self.Menu.AddOns.AutoR:MenuElement({id = "enabled", name = "1. Enabled", value = true})
			self.Menu.AddOns.AutoR:MenuElement({id = "ProcNum", name = "2. Minimum Hits for R to cancel", value = 0, min = 0, max = 10, step = 1})
			self.Menu.AddOns.AutoR:MenuElement({id = "procType", name = "3. Unit type", value = 7, drop = {'Champions', 'Minions', 'Jungle', 'Champions + Minions', 'Champions + Jungle', 'Minions + Jungle', 'Champions + Minions + Jungle'}})
		-- self.Menu.AddOns:MenuElement({id = "AutoQ", name = "2. Auto Q (WIP)", type = MENU})
		-- 	self.Menu.AddOns.AutoQ:MenuElement({id = "enabled", name = "1. Enabled", value = true})
		-- 	self.Menu.AddOns.AutoQ:MenuElement({id = "ProcNum", name = "2. Minimum Hits for Q to proc", value = 2, min = 1, max = 5, step = 1})
		-- 	self.Menu.AddOns.AutoQ:MenuElement({id = "procType", name = "3. Unit type", value = 1, drop = {'Champions', 'Minions', 'Jungle', 'Champions + Minions', 'Champions + Jungle', 'Minions + Jungle', 'Champions + Minions + Jungle'}})
	self.Menu:MenuElement({id = "Options", name = " 7. Options", type = MENU})
		self.Menu.Options:MenuElement({id = "Wall", 	name = "1. Wall Prediction width", value = 25, min = 0, max = 100, step = 1})
		self.Menu.Options:MenuElement({id = "info", name = "Increase value if wall pushes him out", type = SPACE})
	self.Menu:MenuElement({id = "Draw", name = " 8. Draw", type = MENU})
		self.Menu.Draw:MenuElement({id = "Enabled", name = "1. Draw Stuff", value = true})
		
		for spell = 1, 6, 1 do
			self.Menu.Draw:MenuElement({id = "Draw" .. SpellLetters[spell], name = spell + 1 .. ". " .. SpellLetters[spell] .. "-Menu", type = MENU})
				self.Menu.Draw["Draw" .. SpellLetters[spell]]:MenuElement({id = "Draw", name = "Draw "..SpellLetters[spell]..((spell == 2 or spell == 6) and " width" or " range"), value = true})
				self.Menu.Draw["Draw" .. SpellLetters[spell]]:MenuElement({id = "Color", name = "Color", value = 1 , drop = {"Red", "Blue", "Green", "Yellow", "Black", "White", "Pink", "Cyan"}})
				self.Menu.Draw["Draw" .. SpellLetters[spell]]:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 10, step = 1})
		end

		-- self.Menu.Draw:MenuElement({id = "MissingHP", name = "8. HP(%) after Harass/Combo (WIP)", value = true})
end

function Anivia:loadVariables()
	self.Spells = {
		['Q'] = {
			manaCost = function() return myHero:GetSpellData(_Q).level * 10 + 70 end,
			damage = function() return myHero:GetSpellData(_Q).level * 25 + 35 + myHero.ap * .45 end,
			damage2 = function() return myHero:GetSpellData(_Q).level * 25 + 35 + myHero.ap * .45 end,
			stunDuration = function() return myHero:GetSpellData(_Q).level * .1 + 1 end,
			range = 1075,
			width = 110, --needs target.boundingRadius
			radius = 235, --AOE needs target.pos
			delay = .25,
			speed = 850,
			ready = function() return myHero:GetSpellData(_Q).level > 0 and myHero:GetSpellData(_Q).toggleState ~= 2 and myHero:GetSpellData(_Q).currentCd == 0 end
			-- Notes: Slows & Stuns, can damage twice
		},
		['W'] = {
			manaCost = function() return 70 end,
			damage = function(target) return 0 end,
			range = 1000,
			width = function() return myHero:GetSpellData(_W).level * 100 + 300 end,
			duration = 5,
			delay = .25,
			ready = function() return myHero:GetSpellData(_W).level > 0 and myHero:GetSpellData(_W).currentCd == 0 end
		},
		['E'] = {
			manaCost = function() return myHero:GetSpellData(_E).level * 10 + 40 end,
			damage = function(target) return myHero:GetSpellData(_E).level * 25 + 25 + myHero.ap * .5 end,
			range = 650,
			width = 60,
			delay = .3,
			speed = 1600,
			ready = function() return myHero:GetSpellData(_E).level > 0 and myHero:GetSpellData(_E).currentCd == 0 end
			-- Notes: Damage x2 if was Stunned by Q or Full R
		},
		['R'] = {
			manaCost = function() return myHero:GetSpellData(_R).level * 10 + 105 end,
			damage = function(target) return myHero:GetSpellData(_R).level * 20 + 20 + myHero.ap * 0.125 end,
			range = 750,
			width = function(time) return 200 + (time or self:getRDuration()) * 133.333333 end,
			delay = .25,
			ready = function() return myHero:GetSpellData(_R).level > 0 and myHero:GetSpellData(_R).toggleState ~= 2 and myHero:GetSpellData(_R).currentCd == 0 end
			-- Notes: Damage per second
		}
	}

	self.Q = nil
	self.E = nil
	self.R = nil

	self.Enemies = {}
	self.stunned = {}
	self.QTimer = nil
	self.QExploded = nil
	self.QCasted = nil
	self.RTimer = nil

	self.lastAATargets = {}
end

function Anivia:loadCallbacks()
	Callback.Add("Tick", function() Anivia:onSpellCast() end)
	Callback.Add("Tick", function() Anivia:onTick() end)
	Callback.Add("Draw", function() Anivia:onDraw() end)
end

function Anivia:loadUnits()
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)

		if hero.team ~= myHero.team then
			self.Enemies[#self.Enemies + 1] = hero
		end
	end

	if #self.Enemies > 0 then self.unitsLoaded = true end
end
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------

function Anivia:getEnemyMinions(range, type, pos)
	local _temp = {}
	local c = 0
	range = range or 25000

	for i = 1, Game.MinionCount() do
		local unit = Game.Minion(i)
		local t = unit.team

		if type and (((type == 3 or type == 5) and t == 300) or ((type == 2 or type == 4) and t == enemyTeam) or ((type == 6 or type == 7) and t ~= myTeam)) or (not type and t ~= myTeam) then
			if self:GoodTarget(unit, range, pos) then
				c = c + 1
				_temp[c] = unit
			end
		end
	end

	return _temp
end

function Anivia:getEnemyHeroes(range, pos)
	pos = pos or myHero
	range = range or 25000
	local _temp = {}
	local c = 0

	for i = 1, #self.Enemies do
		local unit = self.Enemies[i]

		if self:GoodTarget(unit, range, pos) then
			c = c + 1
			_temp[c] = unit
		end
	end

	return _temp
end

function Anivia:isFreezed(unit, time)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)

		if buff.count > 0 and buff.name == "aniviaiced" then
			return not time and buff.duration or buff.duration - time > 0
		end
	end

	return not time and 0 or nil
end

function Anivia:willBeFreezed(unit, time, rate)
	local hitRate, hitTime = 0, 999999
	local hitRateR, hitTimeR = 0, 999999

	if self.Q then
		local spell = self.Spells.Q
		local travelRoute = LineSegment(self.Q, self.Q.missileData.endPos)
		local distanceRoute = travelRoute:__distance(unit) --b

		if distanceRoute <= spell.radius then
			local distanceObj = unit.pos:DistanceTo(self.Q.pos) --c
			local rangeToHit = sqrt(distanceObj * distanceObj - distanceRoute * distanceRoute) --a
			local timeTillObjInPossibleRange = rangeToHit / spell.speed
			local dodgeRadius = (unit.ms * timeTillObjInPossibleRange)
			
			hitRate = 100 - dodgeRadius * 100 / spell.radius
			hitTime = timeTillObjInPossibleRange
		end
	end

	if self.R then
		local spell = self.Spells.R

		if unit.pos:DistanceTo(self.R.pos) <= spell.width(1.5) then
			local timeTillMax = 1.5 - self:getRDuration()
			local escapeRange = unit.ms * timeTillMax

			hitRateR = 100 - escapeRange * 100 / spell.width(1.5)
			hitTimeR = timeTillMax
		end
	end

	return (hitRate >= rate and hitTime <= time) or (hitRateR >= rate and hitTimeR <= time)
end

function Anivia:detectQ()
	for i = 1, Game.MissileCount() do
		local obj = Game.Missile(i)

		if obj.name == "FlashFrostSpell" then
			self.QCasted = false
			return obj
		end
	end
end

function Anivia:QHandler()
	if self.Q then 
		if self.Q.name ~= "FlashFrostSpell" then
			self.Q = nil
			self.QTimer = Timer()
		end
	end
end

function Anivia:QStunHandler()
	if not self.QExploded and self.QTimer and self:timeBetween(self.QTimer, 0.1, 0.3) then
		for i = Game.ParticleCount(), 1, -1 do
			local unit = Game.Particle(i)

			if unit.name == 'Anivia_Base_Q_Tar_Hit' then
				self.QExploded = true
				local id = unit.pos.x .. unit.pos.y .. unit.pos.z
				self.stunned[id] = Timer() + 3
			end
		end
	elseif self.QExploded then
		if Timer() - self.QTimer > 3 then
			self.QTimer = nil
			self.QExploded = nil
		end
	end
end

function Anivia:detectE()
	for i = Game.MissileCount(), 1, -1 do
		local obj = Game.Missile(i)

		if obj.name == "Frostbite" then
			return obj
		end
	end
end

function Anivia:EHandler()
	if self.E then 
		if self.E.name ~= "Frostbite" then
			self.E = nil
		end
	end
end

function Anivia:RHandler()
	if not self.R then
		local sd = myHero:GetSpellData(3)

		if sd.cd == 1 or sd.toggleState == 2 then
			self.R = self:detectR()
		else
			self.R = nil
		end
	elseif self.R.name ~= "Anivia_Base_R_indicator_ring" then
		self.R = nil
	end
end

function Anivia:detectR()
	for i = Game.ObjectCount(), 1, -1 do
		local obj = Game.Object(i)

		if obj.name == "Anivia_Base_R_indicator_ring" then
			self.RTimer = Timer()
			return obj
		end
	end
end

function Anivia:getRDuration()
	if not self.RTimer then return 0 end

	local diff = Timer() - self.RTimer

	return min(diff, 1.5)
end

function Anivia:Combo()
	if self:getMode() ~= "Combo" then return end

	local target = self:getTarget(2000)

	if self:GoodTarget(target, 2000) then
		local canQ, canW, canE, canR, canQ2
		local Spells = self.Spells
		local dist = target.distance

		local QMode = self.Menu.Combo.QMode:Value()
		local WMode = self.Menu.Combo.WMode:Value()
		local EMode = self.Menu.Combo.EMode:Value()
		local RMode = self.Menu.Combo.RMode:Value()

		if QMode ~= 2 then
			canQ = Spells.Q.ready() and dist <= Spells.Q.range and Spells.Q.manaCost() <= myHero.mana
		end

		if WMode ~= 2 then
			canW = Spells.W.ready() and dist <= Spells.W.range and Spells.W.manaCost() <= myHero.mana
		end

		if EMode ~= 2 then
			canE = Spells.E.ready() and dist <= (Spells.E.range + myHero.boundingRadius + target.boundingRadius) and Spells.E.manaCost() <= myHero.mana
		end

		if RMode ~= 2 then
			canR = Spells.R.ready() and dist <= Spells.R.range and Spells.R.manaCost() <= myHero.mana
		end

		canQ2 = self.Q

		if canQ2 then
			self:timeQProc(target)

			if canR and RMode == 3 and self:isFreezed(target) > 0 then
				self:castR(target)
			end
		end

		if canE then
			self:setAttack(false)

			local hitTime = (dist + myHero.boundingRadius + target.boundingRadius - Spells.E.width) / Spells.E.speed
			local Freeze = EMode == 3 and (self:isFreezed(target, hitTime) or self:willBeFreezed(target, hitTime, 75))

			if EMode == 1 or Freeze then
				CastSpell(HK_E, target)
			end

			self:setAttack(true)
		end

		if canQ then
			if QMode == 1 or (QMode == 3 and self.R or myHero.levelData.lvl < 6) then
				self:castQ(target)
			end
		end

		if canR then 
			if RMode == 1 or (RMode == 3 and (self:isFreezed(target) > 0 or dist < 400)) then
				self:castR(target)
			end
		end

		if canW then
			self:PlaceWall(WMode, target)
		end
	end
end

function Anivia:Harass()
	if self:getMode() ~= "Harass" then return end

	local target = self:getTarget(2000)
	local minMana = self.Menu.Harass.mana:Value()

	if (minMana <= myHero.mana * 100 / myHero.maxMana) and self:GoodTarget(target, 2000) then
		local canQ, canW, canE, canR, canQ2
		local Spells = self.Spells
		local dist = target.distance

		local QMode = self.Menu.Harass.QMode:Value()
		local WMode = self.Menu.Harass.WMode:Value()
		local EMode = self.Menu.Harass.EMode:Value()
		local RMode = self.Menu.Harass.RMode:Value()

		if QMode ~= 2 then
			canQ = Spells.Q.ready() and dist <= Spells.Q.range and Spells.Q.manaCost() <= myHero.mana
		end

		if WMode ~= 2 then
			canW = Spells.W.ready() and dist <= Spells.W.range and Spells.W.manaCost() <= myHero.mana
		end

		if EMode ~= 2 then
			canE = Spells.E.ready() and dist <= (Spells.E.range + myHero.boundingRadius + target.boundingRadius) and Spells.E.manaCost() <= myHero.mana
		end

		if RMode ~= 2 then
			canR = Spells.R.ready() and dist <= Spells.R.range and Spells.R.manaCost() <= myHero.mana
		end

		canQ2 = self.Q

		if canQ2 then
			self:timeQProc(target)
		end

		if canE then
			self:setAttack(false)
			local hitTime = (dist + myHero.boundingRadius + target.boundingRadius - Spells.E.width) / Spells.E.speed
			local Freeze = EMode == 3 and (self:isFreezed(target, hitTime) or self:willBeFreezed(target, hitTime, 75))

			if EMode == 1 or Freeze then
				CastSpell(HK_E, target)
			end
			self:setAttack(true)
		end

		if canQ then
			if QMode == 1 or (QMode == 3 and self.R or myHero.levelData.lvl < 6) then
				self:castQ(target)
			end
		end

		if canR then 
			if RMode == 1 or (RMode == 3 and (self:isFreezedByQ(target) > 0 or dist < 400)) then
				self:castR(target)
			end
		end

		if canW then
			self:PlaceWall(WMode, target)
		end
	end
end

function Anivia:Farm()
	if not (self:getMode() == "lastHit" or self:getMode() == "LaneClear") then self.lastAATargets = {} return end
	local manaPercent = myHero.mana * 100 / myHero.maxMana
	if manaPercent < 10 then return end
	
	local spells = self.Spells
	local QPathMinions = {}
	local QExplodeMinions = {}
	local RMinions = {}
	local Minions1, Minions2 = {}, {}
	local menu = self:getMode() == "lastHit" and self.Menu.Farm or self.Menu.Clear
	local mode = self:getMode() == "lastHit" and menu.Mode:Value() or 3
	local E = menu.E.Enabled:Value() and spells.E.ready() and menu.E.Mana:Value() <= manaPercent

	if mode == 1 and E then
		local farmMinions = self:getEnemyMinions(spells.E.range)
		if #farmMinions == 0 then return end

		local eDMG = spells.E.damage()
		local rw = self.R and spells.R.width()
		local lht = _G.SDK.HealthPrediction:GetLastHitTarget()
		local lct = _G.SDK.HealthPrediction:GetLaneClearTarget()

		if lht or lct then
			self.lastAATargets[lht and lht.networkID or lct and lct.networkID] = true
		end

		for i = 1, #farmMinions do
			local minion = farmMinions[i]
			local isBad = self.lastAATargets[minion.networkID]

			if not isBad or (not self:canAttack() and _G.SDK.Orbwalker.AttackEndTime - Timer() < .5) then
				local inR = rw and minion.pos:DistanceTo(self.R.pos) < rw

				if not inR then
					local hp = minion.health
					local time = minion.distance / spells.E.speed
					local multi = self:isFreezed(minion, time) and 2 or 1
					local dmgE = CalcMagicalDamage(myHero, minion, eDMG * multi)

					if dmgE > hp then
						CastSpell(HK_E, minion)
					end
				end
			end
		end
	elseif mode ~= 1 then
		local Q = not self.Q and menu.Q.Enabled:Value() and spells.Q.ready() and menu.Q.Mana:Value() <= manaPercent
		local R = menu.R.Enabled:Value() and spells.R.ready() and menu.R.Mana:Value() <= manaPercent
		
		if (Q or E or R) then
			local farmMinions = self:getEnemyMinions(Q and spells.Q.range or R and spells.R.range or E and spells.E.range)
			if #farmMinions == 0 then return end

			local eDMG = E and spells.E.damage()
			local rDMG = R and spells.R.damage() * (self:getMode() == "lastHit" and menu.R.Time:Value() or 10)
			local qDMG = Q and spells.Q.damage() --twice
			local rKills = {}
			local rCount = 0
			local qKills = {}
			local q2Kills = {}
			local qCount = 0
			local q2Count = 0

			local rw = self.R and spells.R.width()
			local lht = _G.SDK.HealthPrediction:GetLastHitTarget()
			local lct = _G.SDK.HealthPrediction:GetLaneClearTarget()

			if lht or lct then
				self.lastAATargets[lht and lht.networkID or lct and lct.networkID] = true
			end

			for i = 1, #farmMinions do
				local minion = farmMinions[i]
				local isBad = self.lastAATargets[minion.networkID]

				if not isBad or (not self:canAttack() and _G.SDK.Orbwalker.AttackEndTime - Timer() < .5) then
					local hp = minion.health
					local calcedQ = 0
					local calcedE = 0

					if mode ~= 3 and R and hp < CalcMagicalDamage(myHero, minion, rDMG) then
						rCount = rCount + 1
						rKills[rCount] = minion
					else --if not killable by R we can check other spells
						if mode ~= 3 and Q then
							local QDMG = CalcMagicalDamage(myHero, minion, qDMG)
							if hp < QDMG then
								qCount = qCount + 1
								qKills[qCount] = minion
								q2Count = q2Count + 1
								q2Kills[q2Count] = minion
							elseif hp < QDMG * 2 then
								q2Count = q2Count + 1
								q2Kills[q2Count] = minion
							end
						end

						if E then
							local inR = rw and minion.pos:DistanceTo(self.R.pos) < rw

							if not inR then
								local time = minion.distance / spells.E.speed
								local multi = self:isFreezed(minion, time) and 2 or 1
								local dmgE = CalcMagicalDamage(myHero, minion, eDMG * multi)

								if dmgE > hp then
									CastSpell(HK_E, minion)
								end
							end
						end
					end
				end
			end

			if R then
				if rCount >= menu.R.Hits:Value() or (mode == 3 and #farmMinions > 0) then
					local pos = self:getCircularAOEPos(mode == 3 and farmMinions or rKills, spells.R.width(1.5))

					if pos and pos[2] >= menu.R.Hits:Value() then
						CastSpell(HK_R, pos[1])
					end
				end
			end

			if Q then
				if q2Count > menu.Q.Hits:Value() or (mode == 3 and #farmMinions > 0) then
					local pos = self:getCombinedAOEPos(mode == 3 and farmMinions or q2Kills, spells.Q.width, spells.Q.radius, spells.Q.range)

					if pos and #pos.inCircle + #pos.inLine >= menu.Q.Hits:Value() then
						CastSpell(HK_Q, pos.castPos)
						local t = GetDistance(myHero, pos.castPos) / spells.Q.speed + spells.Q.delay

						DelayAction(function()
							self:procQ()
						end, t - .05)
					end
				end
			end
		end
	end
end

function Anivia:Killsteal()
end

function Anivia:timeQProc(unit)
	if self.Q and not self.QCasted then
		if unit.pos:DistanceTo(self.Q.pos) <= self.Spells.Q.radius then
			self:procQ()
		end
	end
end

function Anivia:castQ(unit)
	if not self.Q and not self.QCasted then
		local spell = self.Spells.Q
		local pos, chance = PremiumPrediction:GetLinearAOEPrediction(myHero, unit, spell.speed, spell.range, spell.delay, spell.width, 0, false)
		
		if pos and chance >= 5 then
		    CastSpell(HK_Q, pos)
		end 
	end
end

function Anivia:castR(unit)
	if not self.R then
		local spell = self.Spells.R
		local pos, chance = PremiumPrediction:GetCircularAOEPrediction(myHero, unit, spell.speed, spell.range, spell.delay, spell.width(), 0, false)

		if pos and chance >= 5 then
			for i = 1, 10 do
		   		CastSpell(HK_R, pos)
		   	end
		end 
	end
end

function Anivia:procQ()
	if self.Q then
		for i = 1, 10 do
			CastSpell(HK_Q)
		end
	end
end

function Anivia:AutoQ()
end

function Anivia:AutoR()
	local m = self.Menu.AddOns.AutoR

	if self.R and m.enabled:Value() and Timer() - self.RTimer > 1 then
		local w = self.Spells.R.width(1.5)
		local t = m.procType:Value()
		local n = m.ProcNum:Value()
		local champs, minions = 0, 0

		if t == 1 or t == 4 or t == 5 or t == 7 then
			champs = #self:getEnemyHeroes(w, self.R)
		end

		if t ~= 1 then
			minions = #self:getEnemyMinions(w, t, self.R)
		end

		if champs + minions < n or champs + minions == 0 then
			CastSpell(HK_R)
		end
	end
end

function Anivia:getCombinedAOEPos(list, width, radius, range)
	if #list == 0 then return nil end
	local pos = Vector(0, 0, 0)
	local count = 0
	local _temp = {}

	--Generate the general average pos
	for i = 1, #list do
		local unit = list[i]

		count = count + 1
		_temp[count] = unit
		pos = pos + unit.pos
	end

	pos = pos / count

	local maxRange = 0
	local toRemove = nil

	--Create the real spell range polygon
	local maxPos = myHero.pos:Extended(pos, range)
	local lineSeg = LineSegment(myHero, maxPos)

	--Check how many Units are in Linear/Circular range
	local c, l = {}, {}
	local cc, lc = 0, 0
	local alreadyAdded = {}
	local ac = 0

	for i = 1, #_temp do
		local unit = _temp[i]
		local lineD = lineSeg:__distance(unit) - unit.boundingRadius
		local circD = unit.pos:DistanceTo(pos)
		local heroD = unit.pos:DistanceTo(myHero.pos)

		if lineD <= width and heroD <= range then
			if not alreadyAdded[unit.networkID] then
				alreadyAdded[unit.networkID] = true
				ac = ac + 1
				lc = lc + 1
				l[lc] = unit
			end
		end

		if lineD > maxRange then
			maxRange = lineD
			toRemove = i
		end
		
		if circD <= radius then
			if not alreadyAdded[unit.networkID] then
				alreadyAdded[unit.networkID] = true
				ac = ac + 1
				cc = cc + 1
				c[cc] = unit
			end
		end

		if circD > maxRange then
			maxRange = circD
			toRemove = i
		end
	end

	if ac >= count then
		return {
			castPos = pos,
			inCircle = c,
			inLine = l
		}
	else
		rem(_temp, toRemove)
		return self:getCombinedAOEPos(_temp, width, radius, range)
	end
end

function Anivia:getCircularAOEPos(list, width, forceTarget, noExcusion)
	local pos = {pos = Vector(), c = 0, l = {}}
	if #list == 0 then return end
	local alreadyIn = false

	for i = 1, #list do
		local unit = list[i]

		pos.pos = pos.pos + unit.pos
		pos.c = pos.c + 1
		pos.l[i] = unit

		if forceTarget and not alreadyIn and unit.networkID == forceTarget.networkID then
			alreadyIn = true
		end
	end

	if forceTarget and not alreadyIn then
		pos.pos = pos.pos + forceTarget.pos
		pos.c = pos.c + 1
		pos.l[#pos.l + 1] = unit
	end

	pos.pos = pos.pos / pos.c

	local inRange = 0
	local furthest = 0
	local fID = 0

	for i = 1, #list do
		local unit = list[i]
		local d = unit.pos:DistanceTo(pos.pos)

		if d <= width then
			inRange = inRange + 1
		end

		if d > furthest then
			furthest = d
			fID = i
		end
	end

	if forceTarget and not alreadyIn and forceTarget.pos:DistanceTo(pos.pos) <= width then
		inRange = inRange + 1
	end

	if inRange == pos.c then
		return {pos.pos, inRange}
	elseif noExcusion then
		return {pos.pos, inRange}
	else
		rem(pos.l, fID)
		return self:getCircularAOEPos(pos.l, width, forceTarget, noExcusion)
	end
end

function Anivia:getLinearAOEPos(list, width, range, forceTarget)
	local pos = {pos = Vector(), c = 0, l = {}}
	if #list == 0 then return end
	local alreadyIn = false

	for i = 1, #list do
		local unit = list[i]

		pos.pos = pos.pos + unit.pos
		pos.c = pos.c + 1
		pos.l[i] = unit

		if forceTarget and not alreadyIn and unit.networkID == forceTarget.networkID then
			alreadyIn = true
		end
	end

	if forceTarget and not alreadyIn then
		pos.pos = pos.pos + forceTarget.pos
		pos.c = pos.c + 1
		pos.l[#pos.l + 1] = unit
	end

	pos.pos = pos.pos / pos.c
	pos.pos = myHero.pos:Extended(pos.pos, range)

	local l = LineSegment(pos.pos, myHero.pos)
	local inRange = 0
	local furthest = 0
	local fID = 0

	for i = 1, #list do
		local unit = list[i]
		local d = l:__distance(unit.pos)

		if d <= width + unit.boundingRadius then
			inRange = inRange + 1
		end

		if d > furthest then
			furthest = d
			fID = i
		end
	end

	if forceTarget and not alreadyIn and l:__distance(forceTarget.pos) <= width + forceTarget.boundingRadius then
		inRange = inRange + 1
	end

	if inRange == pos.c then
		return {pos.pos, inRange}
	elseif noExcusion then
		return {pos.pos, inRange}
	else
		rem(pos.l, fID)
		return self:getLinearAOEPos(pos.l, width, range, forceTarget)
	end
end

function Anivia:timeBetween(value, min, max)
	local now = Timer() - value

	return now >= min and now <= max
end

function Anivia:GoodTarget(unit, range, unit2)
	range = range or 25000

	return 	unit and 
			unit.valid and 
			unit.visible and 
			not unit.dead and 
			unit.pos2D.onScreen and 
			(unit.distance <= range or (unit2 and unit2.pos:DistanceTo(unit.pos) <= range)) and
			unit.health > 0
end

function Anivia:Wall(unit1, unit2, castBehind, range)
end

function Anivia:WallIntoR(unit)
	if self.R and unit and unit.ms > 0 then
		local d = unit.pos:DistanceTo(self.R.pos)
		local actualRadius = self.Spells.R.width(self:getRDuration())
		local maxRadius = self.Spells.R.width(1.5)
		local extra = self.Menu.Options.Wall:Value()

		if d < maxRadius then
			-- if d < actualRadius then
				local Path = unit.pathing
				if Path.pathCount == 0 then return end

				local first = unit:GetPath(1)

				if GetDistance(first, self.R) > actualRadius then
					local a = maxRadius - d
					local delayExtraRange = self.Spells.W.delay * unit.ms + extra

					if a > delayExtraRange then
						local castPos = unit.pos:Extended(first, delayExtraRange)
						CastSpell(HK_W, castPos)
					end
				end
			-- else
				-- print("Not yet implemented")
			-- end
		end
	end
end

function Anivia:Peel(unit)
end

function Anivia:Bait(unit)
end

function Anivia:PlaceWall(menu, unit, unit2, mode, range)
	local unit2 = unit2 or myHero
	local range = range or 0
	--[[
		Modes:
			Keep in R: keeps an unit in R
			Engage: Force new EnemyPath, CatchUp in close areas
			Disengage: Flee
			Peel: Stop enemy from killing lows
			
			(Other: Vision, JunglePathing)

			(Pincer: Try to make angle between wall and walls low)
	--]]

	if menu == 1 or mode == "KeepInR" then
		self:WallIntoR(unit)
	elseif menu == 3 or mode == "Engage" then
		self:Wall(unit, unit2, true, range)
	elseif menu == 4 or mode == "Disengage" then
		self:Wall(unit, unit2, false, range)
	elseif menu == 5 or mode == "Peel" then
		self:Peel(unit)
	elseif mode == "BaitInQ" then
		self:Bait(unit)
	end
end

----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------

function Anivia:Move(pos)
	_G.SDK.Orbwalker:MoveToPos(pos)
end

function Anivia:Attack(unit)
	_G.SDK.Orbwalker:Attack(unit)
end

function Anivia:setMovement(bool)
	_G.SDK.Orbwalker.MovementEnabled = bool
end

function Anivia:setAttack(bool)
	_G.SDK.Orbwalker.AttackEnabled = bool
end

function Anivia:setTarget(unit)
	_G.SDK.OrbwalkerMenu.ts.selected.enable:Value(true)
	_G.SDK.TargetSelector.SelectedTarget = unit
end

function Anivia:canAttack()
	return _G.SDK.Orbwalker:CanAttack()
end

function Anivia:canMove()
	return _G.SDK.Orbwalker:CanMove()
end

function Anivia:isAttacking()
	return _G.SDK.Orbwalker.WaitForResponse
end

function Anivia:getMode()
	for i = 0, 4 do
		if _G.SDK.Orbwalker.Modes[i] then
			return orbModes[i]
		end
	end

	return ""
end

function Anivia:getTarget(range)
	local unit = _G.SDK.TargetSelector:GetTarget(range)
	--gso FIx
	if unit and range and range >= unit.distance then
		return unit
	elseif unit then
		return unit
	end

	return nil
end

local function AutoUpdate()
	-- Get PremiumPrediction
	local PP = ReadFile(COMMON_PATH, "PremiumPrediction.lua")

	if not PP then
		DownloadFile("https://raw.githubusercontent.com/Ark223/GoS-Scripts/master/PremiumPrediction.lua", COMMON_PATH, "PremiumPrediction.lua")
		print("maxAnivia: Downloaded PremiumPrediction. Please Reload with 2x F6")
		return false
	end

    DownloadFile("https://raw.githubusercontent.com/Maxxxel/GOS/master/ext/Scripts/maxAnivia.version", COMMON_PATH, "maxAnivia.version")

    local newVersionScript = tonumber(ReadFile(COMMON_PATH, "maxAnivia.version"))

    if newVersionScript > version then
        DownloadFile("https://raw.githubusercontent.com/Maxxxel/GOS/master/ext/Scripts/maxAnivia.lua", SCRIPT_PATH, "maxAnivia.lua")
        print("maxAnivia: Updated to " .. newVersionScript .. ". Please Reload with 2x F6")
        return false
    else
        print("maxAnivia: No Updates Found (" ..version .. ")")
        return true
    end
end

if AutoUpdate() then
	DelayAction(function()
		if not _G.GamsteronOrbwalkerLoaded then print("You need Gamsteron Orbwalker") return end
		Anivia()
	end, 1)
else
	Anivia = nil
	return
end
