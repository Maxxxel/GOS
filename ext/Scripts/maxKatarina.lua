local version = 0.02
local author = "Maxxxel"

if myHero.charName ~= "Katarina" then return end

local Game = Game
local time = Game.Timer
local Control = Control
local Move = Control.Move
local Cast = Control.CastSpell
local table = table
local rem = table.remove
local insert = table.insert
local concat = table.concat
local math = math
local max = math.max
local floor = math.floor
local Summ1, Summ2 = myHero:GetSpellData(SUMMONER_1), myHero:GetSpellData(SUMMONER_2)
local Ignite = Summ1.name == "SummonerDot" and SUMMONER_1 or Summ2.name == "SummonerDot" and SUMMONER_2
local orbModes = {
	[0] = "Combo",
	[1] = "Harass",
	[2] = "LaneClear",
	[3] = "LaneClear",
	[4] = "LastHit"
}
local SpellLetters = {
	[1] = "Q", 
	[2] = "W", 
	[3] = "E", 
	[4] = "R"
}
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
local damagePriorities = {
	["AttackClose"] = 0,
	["Attack"] = 1,
	["Jump"] = 2,
	["ComboJumpR"] = 3,
	["ComboJumpI"] = 4,
	["ComboJumpQ"] = 5
}
-- WORK IN PROGRESS!!!
-- local wallJumpPositions = {
-- 	{7262,7174,6424,6774}, --x
-- 	{52,58,49,49}, --y
-- 	{5900,5612,5208,5208}  --z
-- }

local Katarina = setmetatable({}, {
	__call = function(self)
		self:init()
	end
})
--=== Start of Helper Functions ===--
local function delayed(func, time)
	DelayAction(function()
		func()
	end, time)
end

local function mergeTables(aa, bb, cc)
	local temp = {}
	local c = 1
	local arg = {aa, bb, cc}

	for i = 1, #arg do
		local tab = arg[i]

		for j = 1, #tab do
			local o = tab[j]

			temp[c] = o
			c = c + 1
		end
	end

	return temp
end

local function closestPoint(pa, pb, unit)
	local isD1 = pa[3] == "dagger"
	local isD2 = pb[3] == "dagger"

	if isD1 and not isD2 then
		return pa
	elseif not isD1 and isD2 then
		return pb
	end

	local d1 = pa[1].pos:DistanceTo(unit)
	local d2 = pb[1].pos:DistanceTo(unit)

	if d1 <= d2 then
		return pa
	else
		return pb
	end
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
--=== Start of Dagger Class ===--
local Dagger = {}
Dagger.list = {}
Dagger.ids = {}
Dagger.__index = Dagger

function Dagger:getDamageType(unit)
	local distance = self.pos:DistanceTo(unit.pos) - 150
	--To close
	if distance <= 150 then
		return "AttackClose"
	end
	--AA
	if distance <= myHero.range + myHero.boundingRadius + unit.boundingRadius then
		return "Attack"
	end
	--Spin DMG
	if distance <= Katarina.Spells.W.damageRadius then
		return "Jump"
	end
	--E --> Double Jump
	-- if distance <= Katarina.Spells.E.range - myHero.boundingRadius then
	-- 	return "DoubleJump"
	-- end
	--R
	if distance <= Katarina.Spells.R.range then
		return "ComboJumpR"
	end
	--I
	if Ignite and distance <= Katarina.Spells.Ignite.range then
		return "ComboJumpI"
	end
	--Q
	if distance <= Katarina.Spells.Q.range then
		return "ComboJumpQ"
	end
	--Out of range
	return
end

function Dagger:getJumpSpot(unit, damageType)
	damageType = damageType or self:getDamageType(unit)
	if not damageType then return end

	if damageType == "AttackClose" then
		local range = self.pos:DistanceTo(unit.pos) - 150
		
		return self.pos:Extended(unit.pos, range)
	else
		return self.pos:Extended(unit.pos, 150)
	end
end

function Dagger:getDaggers()
	return self.list
end

function Dagger:timeTillLand()
	return self.castTime - time() + self.landingTime
end

function Dagger:isDropped()
	if self.dropped then return true end

	local timer = self:timeTillLand()

	if timer <= 0 and timer >= -4 then
		self.dropped = true
		return true
	end

	return false
end

function Dagger:getRemainingTime()
	return self:isDropped() and (self.duration - (time() - self.castTime) + self.landingTime) or self.duration
end

function Dagger:isDead()
	return not self.obj or self.obj.name == "" or self.obj.networkID == 0 or self.obj.networkID ~= self.id or self:getRemainingTime() <= 0
end

function Dagger:checkOnTick()
	if #self.list > 0 then
		for i = 1, #self.list do
			local _dagger = self.list[i]

			if _dagger and _dagger:isDead() then
				_dagger:delete()
			end
		end
	end
end

function Dagger:delete()
	local num = self.ids[self.id]
	rem(self.list, num)
	self.ids[self.id] = nil
end

local function newDagger(obj)
	local ID = obj.networkID

	if not Dagger.ids[ID] then
		local proxy = {
			landingTime = 1,
			dropped = false,
			castTime = time(),
			duration = 4,
			obj = obj,
			id = ID,
			isDagger = true,
			pos = obj.pos
		}

		local _Dagger = setmetatable(proxy, Dagger)
		insert(Dagger.list, _Dagger)
		Dagger.ids[ID] = #Dagger.list

		return true
	end

	return false
end
--=== Start of Orbwalker Functions ===-- 
local function setOrbwalkerSettings()
	local _orbwalker = {}

	_orbwalker.Move = function(self, pos)
		_G.SDK.Orbwalker:MoveToPos(pos)
	end

	_orbwalker.Attack = function(self, unit)
		_G.SDK.Orbwalker:Attack(unit)
	end

	_orbwalker.setMovement = function(self, bool)
		_G.SDK.Orbwalker.MovementEnabled = bool
	end

	_orbwalker.setAttack = function(self, bool)
		_G.SDK.Orbwalker.AttackEnabled = bool
	end

	_orbwalker.setTarget = function(self, unit)
		_G.SDK.OrbwalkerMenu.ts.selected.enable:Value(true)
		_G.SDK.TargetSelector.SelectedTarget = unit
	end

	_orbwalker.canAttack = function(self)
		return _G.SDK.Orbwalker:CanAttack()
	end

	_orbwalker.canMove = function(self)
		return _G.SDK.Orbwalker:CanMove()
	end

	_orbwalker.isAttacking = function(self)
		return _G.SDK.Orbwalker:IsAutoAttacking()
	end

	_orbwalker.getMode = function(self)
		for i = 0, 4 do
			if _G.SDK.Orbwalker.Modes[i] then
				return orbModes[i]
			end
		end

		return ""
	end

	_orbwalker.getTarget = function(self, range, type)
		local unit = _G.SDK.TargetSelector:GetTarget(range)

		return unit
	end

	_orbwalker.isForcedTarget = function(self, unit)
		return _G.SDK.TargetSelector.SelectedTarget and _G.SDK.TargetSelector.SelectedTarget.networkID == unit.networkID
	end

	return _orbwalker
end

local function newOrbwalker()
	return setOrbwalkerSettings()
end
--=== Start of Katarina Class ===--
function Katarina:init()
	if not _G.GamsteronOrbwalkerLoaded then print("You need Gamsteron Orbwalker") return end
	if not self:loadTables() then return end
	self:loadMenu()
	self:loadCallbacks()
	self:loadTowers()
end

function Katarina:loadMenu()
	self.Menu = MenuElement({id = "maxKatarina", name = "maxKatarina v." .. version .. " by Maxxxel", type = MENU})
	self.Menu:MenuElement({id = "Combo",		name = "1. Combo", type = MENU})
		self.Menu.Combo:MenuElement({id = "Q", 		 name = "1. Q", type = MENU})
			self.Menu.Combo.Q:MenuElement({id = "Enabled", name = "1. Use Q", value = true})
			self.Menu.Combo.Q:MenuElement({id = "Mode", name = "2. Q-Cast-Mode", value = 2, drop = {"ASAP", "Only if E ready/After Jump"}})
			self.Menu.Combo.Q:MenuElement({id = "Early", name = "3. Always cast on hero level 1", value = true})
			self.Menu.Combo.Q:MenuElement({id = "Solo", name = "4. Cast if no Spells ready (in 4sec)", value = true})
		self.Menu.Combo:MenuElement({id = "W", 		 name = "2. W", type = MENU})
			self.Menu.Combo.W:MenuElement({id = "Enabled", name = "1. Use W", value = true})
			self.Menu.Combo.W:MenuElement({id = "Mode", name = "2. W-Cast-Mode", value = 2, drop = {"Before Jump + Near Target", "After Jump + Near Target", "Before Jump", "After Jump", "Manual"}})
			self.Menu.Combo.W:MenuElement({id = "Reset", name = "3. Cast W if E on CD and close to target", value = true})
		self.Menu.Combo:MenuElement({id = "E", 		 name = "3. E", type = MENU})
			self.Menu.Combo.E:MenuElement({id = "Enabled", name = "1. Use E", value = true})
			self.Menu.Combo.E:MenuElement({id = "Mode", name = "2. Dagger-Damage-Mode", value = 1, drop = {"Dagger + DMG", "Dagger + AA", "Dont Jump on Daggers???"}})
			self.Menu.Combo.E:MenuElement({id = "Inf1", name = "Dagger + DMG: Jump on Dagger which damages", type = SPACE})
			self.Menu.Combo.E:MenuElement({id = "Inf2", name = "Dagger + AA: Jump on Dagger if AA possible", type = SPACE})
			self.Menu.Combo.E:MenuElement({id = "Mode2", name = "3. General-Jump-Mode", value = 2, drop = {"ASAP (ignores Daggers)", "Dagger/forced Target", "Manual"}})
			self.Menu.Combo.E:MenuElement({id = "Inf3", name = "Dagger/Forced: If 2. or left Click Target", type = SPACE})
			self.Menu.Combo.E:MenuElement({id = "AA", name = "4. E after AA if possible", value = true})
			self.Menu.Combo.E:MenuElement({id = "AR", name = "5. AA-Reset if no Spells ready (in 2sec)", value = true})
		self.Menu.Combo:MenuElement({id = "R", 		 name = "4. R", type = MENU})
			self.Menu.Combo.R:MenuElement({id = "Enabled", name = "1. Use R", value = true})
			self.Menu.Combo.R:MenuElement({id = "Mode", name = "2. Mode", value = 1, drop = {"W Mode", "All on CD + W In range", "All on CD"}})
			self.Menu.Combo.R:MenuElement({id = "Info", name = "And...", type = SPACE})
			self.Menu.Combo.R:MenuElement({id = "HPOn", name = "3. Enemy HP <", value = true})
			self.Menu.Combo.R:MenuElement({id = "HP", name = "	(%HP enemy)", value = 25, min = 0, max = 100, step = 1})
			self.Menu.Combo.R:MenuElement({id = "AOEOn", name = "4. Or #enemies >=", value = true})
			self.Menu.Combo.R:MenuElement({id = "AOE", name = "	(Number enemies)", value = 3, min = 1, max = 5, step = 1})
	self.Menu:MenuElement({id = "Harass", 		name = "2. Harass", type = MENU})
		self.Menu.Harass:MenuElement({id = "Mode", name = "1. Mode", value = 2, drop = {"Q", "Q + E(dagger)"}})
		self.Menu.Harass:MenuElement({id = "WAfter", name = "2. W after E", value = true})
	self.Menu:MenuElement({id = "Farm", 		name = "3. Farm", type = MENU})
		self.Menu.Farm:MenuElement({id = "Mode", name = "1. Farm-Mode", value = 1, drop = {"Q (Kill)", "E on Daggers", "Q + E on Daggers", "Manual"}})
		self.Menu.Farm:MenuElement({id = "MinHits", name = "2. Min. Hits if E Usage", value = 3, min = 0, max = 5, step = 1})
		self.Menu.Farm:MenuElement({id = "Kills", name = "3. Hits need to be deadly", value = true})
	self.Menu:MenuElement({id = "Clear", 		name = "4. Clear", type = MENU})
		self.Menu.Clear:MenuElement({id = "Mode", name = "1. Clear-Mode", value = 3, drop = {"Q (Kill)", "Q (no Kill, first Minion)", "E on Daggers", "Q + E on Daggers", "Manual"}})
		self.Menu.Clear:MenuElement({id = "MinHits", name = "2. Min. Hits if E Usage", value = 3, min = 0, max = 5, step = 1})
		self.Menu.Clear:MenuElement({id = "WAfter", name = "3. Cast W After Jump", value = true})
		self.Menu.Clear:MenuElement({id = "QFarm", name = "4. Q-Farm if possible", value = true})
	self.Menu:MenuElement({id = "Killsteal", 	name = "5. Killsteal", type = MENU})
		self.Menu.Killsteal:MenuElement({id = "Enabled", name = "1. Enabled", value = true})
		self.Menu.Killsteal:MenuElement({id = "Q", 		 name = "2. Use Q", value = true})
		self.Menu.Killsteal:MenuElement({id = "E", 		 name = "3. Use E", value = true})
		self.Menu.Killsteal:MenuElement({id = "R", 		 name = "4. Use R", value = true})
		self.Menu.Killsteal:MenuElement({id = "I", 		 name = "5. Use Ignite", value = true})
	self.Menu:MenuElement({id = "Draw", 		name = "6. Draw", type = MENU})
		for spell = 1, 4, 1 do
			self.Menu.Draw:MenuElement({id = "Draw" .. SpellLetters[spell], name = spell .. ". " .. SpellLetters[spell] .. "-Menu", type = MENU})
				self.Menu.Draw["Draw" .. SpellLetters[spell]]:MenuElement({id = "Draw", name = "1. Draw Spell", value = spell ~= 2})
				self.Menu.Draw["Draw" .. SpellLetters[spell]]:MenuElement({id = "Color", name = "2. Color", value = 1, drop = {"Red", "Blue", "Green", "Yellow", "Black", "White", "Pink", "Cyan"}})
				self.Menu.Draw["Draw" .. SpellLetters[spell]]:MenuElement({id = "Width", name = "3. Width", value = 0, min = 0, max = 10, step = 1})
		end
		self.Menu.Draw:MenuElement({id = "MissingHP", name = "5. HP(%) after Combo", value = true})
		self.Menu.Draw:MenuElement({id = "Enabled", name = "6. Enabled", value = true})
		self.Menu.Draw:MenuElement({id = "Debug", name = "7. Draw Debug", value = false})
	self.Menu:MenuElement({id = "Options", 		name = "7. Options", type = MENU})
		self.Menu.Options:MenuElement({id = "recalcTime", name = "1. Combo/KS Recalc time", value = .1, min = 0, max = .5, step = .05})
		self.Menu.Options:MenuElement({id = "wDelay", name = "2. W Detection Rate", value = .25, min = 0, max = .5, step = .05})
		self.Menu.Options:MenuElement({id = "QDetectionrate", name = "3. Q Detection Rate", value = .3, min = 0, max = .5, step = .05})
		self.Menu.Options:MenuElement({id = "RStop", name = "4. Stop R if no enemy in range", true})
		self.Menu.Options:MenuElement({id = "RCancel", name = "5. Stop R if KS possible", true})
	self.Menu:MenuElement({id = "Hotkeys", 		name = "8. Special Keys", type = MENU})
		self.Menu.Hotkeys:MenuElement({id = "AutoJump", name = "1. Jump to nearest Enemy", key = string.byte("E")})
		self.Menu.Hotkeys:MenuElement({id = "WallJump", name = "2. Small Wall Jump", key = string.byte("T")})
		-- self.Menu.Hotkeys:MenuElement({id = "DamageCalc", name = "3. Perform a damage Calc at mousePos", key = string.byte("U")})
	self.Menu:MenuElement({id = "Escape", 		name = "9. Escape", type = MENU})
		self.Menu.Escape:MenuElement({id = "Enabled", name = "1. Tower Escape", value = true})
		self.Menu.Escape:MenuElement({id = "MinRange", name = "Escape from tower if range <=", value = 875, min = 0, max = 875, step = 25})
		self.Menu.Escape:MenuElement({id = "MinEnemy", name = "(AND if #Enemies <=", value = 0, min = 0, max = 5, step = 1})
		self.Menu.Escape:MenuElement({id = "Switch", name = "=============>", value = 2, drop = {"AND", "OR"}})
		self.Menu.Escape:MenuElement({id = "MinHealth", name = "if %HP <=)", value = 25, min = 0, max = 100, step = 1})
end

function Katarina:loadCallbacks()
	Callback.Add("Tick", function() Katarina:Main() end)
	Callback.Add("Tick", function() Dagger:checkOnTick() end)
	Callback.Add("Draw", function() Katarina:GFX() end)
	Callback.Add("WndMsg", function(a, b) Katarina:Cast(a, b) end)
end

function Katarina:loadTables()
	self.Orbwalker = newOrbwalker()
	if not self.Orbwalker then return end

	self.Daggers = Dagger
	self.isKillstealing = false

	self.Towers = {}
	self.Enemies = {}
	self.Allies = {}
	self.Heroes = {}
	self:loadUnits()
	self.killstealTable = {}
	self.Spells = {}
	self.Spells.AA = {
		inRange = function(unit)
			return unit.distance < myHero.range + myHero.boundingRadius + unit.boundingRadius
		end,
		rawDamage = function()
			return myHero.totalDamage
		end
	}
	self.Spells.Q = {
		pressed = false,
		lastCast = 0,
		range = 620,
		delay = .2,
		speed = 1800,
		ready = function()
			local spell = myHero:GetSpellData(0)
			return spell.level > 0 and spell.currentCd == 0
		end,
		readyIn = function()
			local spell = myHero:GetSpellData(0)
			return spell.level > 0 and spell.currentCd or 999
		end,
		rawDamage = function()
			return 30 * myHero:GetSpellData(_Q).level + 45 + .3 * myHero.ap
		end
	}
	self.Spells.W = {
		lastCast = 0,
		procRadius = 140, -- distance to myHero's boundingRadius
		damageRadius = 340, -- around myHero
		jumpRange = 150, -- 0-150 for Daggers + boundingRadius for Daggers
		ready = function()
			local spell = myHero:GetSpellData(1)
			return spell.level > 0 and spell.currentCd == 0
		end,
		readyIn = function()
			local spell = myHero:GetSpellData(1)
			return spell.level > 0 and spell.currentCd or 999
		end,
		dmgPerLevel = {
			68,72,77,82,89,96,103,112,121,131,142,154,166,180,194,208,224,240
		},
		bonusDmgPerLevel = {
			.55,.55,.55,.55,.55,.70,.70,.70,.70,.70,.85,.85,.85,.85,.85,1,1,1
		},
		rawDamage = function()
			local l = myHero.levelData.lvl
			return self.Spells.W.dmgPerLevel[l] + myHero.bonusDamage + self.Spells.W.bonusDmgPerLevel[l] * myHero.ap
		end
	}
	self.Spells.E = {
		range = 720,
		lastCast = 0,
		ready = function()
			local spell = myHero:GetSpellData(2)
			return spell.level > 0 and spell.currentCd == 0
		end,
		readyIn = function()
			local spell = myHero:GetSpellData(2)
			return spell.level > 0 and spell.currentCd or 999
		end,
		rawDamage = function()
			return 15 * myHero:GetSpellData(_E).level + .25 * myHero.ap + .5 * myHero.totalDamage
		end
	}
	self.Spells.R = {
		lastCast = 0,
		range = 500,
		ready = function()
			local spell = myHero:GetSpellData(3)
			return spell.level > 0 and spell.currentCd == 0
		end,
		readyIn = function()
			local spell = myHero:GetSpellData(3)
			return spell.level > 0 and spell.currentCd or 999
		end,
		rawDamage = function()
			return 12.5 * myHero:GetSpellData(3).level + 12.5 + .19 * myHero.ap + .22 * myHero.bonusDamage --per Dagger; 15 Daggers in 2.5 seconds -> 3 Daggers in .5 seconds -> 1 Dagger in 0.16666 seconds
		end,
		daggerBounces = function(unit, pos)
			if pos then
				pos = pos.pos or pos
				local ms = unit.ms
				local timeToMoveOut = (self.Spells.R.range - pos:DistanceTo(unit.pos)) / ms

				return floor(timeToMoveOut / 0.16666666)
			end

			return 1
		end
	}
	
	if Ignite then
		self.Spells.Ignite = {
			ready = function()
				return myHero:GetSpellData(Ignite).currentCd == 0
			end,
			range = 575,
			rawDamage = function()
				return 25 * myHero.levelData.lvl + 55
			end
		}
	end

	return true
end

function Katarina:loadTowers()
	local c = 0

	for i = 1, Game.TurretCount() do
		local t = Game.Turret(i)

		if t.team ~= myHero.team then
			c = c + 1
			self.Towers[c] = t
		end
	end
end

function Katarina:loadUnits()
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)

		if hero.team == myHero.team and hero.networkID ~= myHero.networkID then
			self.Allies[#self.Allies + 1] = hero
			self.Heroes[#self.Heroes + 1] = hero
		elseif hero.team ~= myHero.team then
			self.Enemies[#self.Enemies + 1] = hero
			self.Heroes[#self.Heroes + 1] = hero
		end
	end

	if #self.Enemies > 0 then self.unitsLoaded = true end
end

function Katarina:Main()
	--Reload Units till we got them
	if not self.unitsLoaded then
		self:loadUnits()
		return
	end
	--Check the Orbwalker for next Actions
	self.mode = not self.isKillstealing and self.Orbwalker:getMode()
	--get Combos for units
	self:getCombos()
	--other modes
	if self.mode == "Harass" then --Harass
		self:Harass()
	elseif self.mode == "LastHit" then --Farm
		self:Farm()
	elseif self.mode == "LaneClear" then --Clear
		self:Clear()
	end
	--Hotkeys
	self:AutoJump()
	self:WallJump()
	--Dagger Management
	self:qDetect()
	--R
	if self:isUltying() then
		self:RStop()
		self.Orbwalker:setAttack(false)
		self.Orbwalker:setMovement(false)
	else
		self.Orbwalker:setAttack(true)
		self.Orbwalker:setMovement(true)
	end
	--Escape
	self:Escape()
end

function Katarina:GFX()
	-- WORK IN PROGRESS!!!
	-- for i = 1, #wallJumpPositions[1] do
	-- 	local pos = Vector(wallJumpPositions[1][i], wallJumpPositions[2][i], wallJumpPositions[3][i])
	-- 	local d = myHero.pos:DistanceTo(pos)
		
	-- 	if d < 50 then
	-- 		Draw.Circle(pos, 40, Colors[2])
			
	-- 		local even = i % 2 == 0
	-- 		local endPoint = even and 
	-- 			pos:Extended(Vector(wallJumpPositions[1][i - 1], wallJumpPositions[2][i - 1], wallJumpPositions[3][i - 1]), 140) or
	-- 			pos:Extended(Vector(wallJumpPositions[1][i + 1], wallJumpPositions[2][i + 1], wallJumpPositions[3][i + 1]), 140)

	-- 		if self.Spells.W.ready() then
	-- 			Cast(HK_W)
	-- 		end

	-- 		local c = 0
	-- 		while self.Spells.E.ready() do
	-- 			Cast(HK_E, endPoint)
	-- 			c = c + 1
	-- 			if c == 20 then break end
	-- 		end
	-- 	else
	-- 		Draw.Circle(pos, 40, Colors[4])
	-- 	end
	-- end
	-- Draw.Text(myHero.pos.x .." , " .. myHero.pos.y .." , " .. myHero.pos.z, myHero.pos:To2D())
	
	if not myHero.dead then
		if self.Menu.Draw.Enabled:Value() then
			if self.Menu.Draw.Debug:Value() then
				for i = 1, #self.Enemies do
					local enemy = self.Enemies[i]
					
					if self.killstealTable[enemy.networkID] then
						local t = self.killstealTable[enemy.networkID]
						Draw.Text(
						[[
						Jump: ]] .. tostring(t.jump) .. "\n"..[[
						AA: ]] .. tostring(t.AA) .. "\n"..[[
						Q: ]] .. tostring(t.Q) .. "\n"..[[
						W: ]] .. tostring(t.W) .. "\n"..[[
						E: ]] .. tostring(t.E) .. "\n"..[[
						R: ]] .. tostring(t.R) .. "\n"..[[
						Ignite: ]] .. tostring(t.Ignite) .. "\n"..[[
						Dagger: ]] .. tostring(t.Dagger) .. "\n"..[[
						Time: ]] .. (time() - t.created) .. "\n"..[[
						Type: ]] .. tostring(t.type) .. "\n"..[[
						DMG: ]] .. (t.totalDamage or 0) .. [[
						]]
						, enemy.pos2D.x + 50, enemy.pos2D.y - 80)

						if t.jump then
							local p = t.jump:To2D()
							Draw.Line(enemy.pos2D.x, enemy.pos2D.y, p.x, p.y)
							Draw.Circle(t.jumpPos, 50)
						end
					end
				end
			else
				for spell = 1, 4, 1 do
					local Active = 
									spell == 1 and self.Spells.Q.ready() and self.Spells.Q.range or 
									spell == 2 and self.Spells.W.ready() and self.Spells.W.damageRadius or 
									spell == 3 and self.Spells.E.ready() and self.Spells.E.range or 
									spell == 4 and self.Spells.R.ready() and self.Spells.R.range or nil
					if  self.Menu.Draw["Draw" .. SpellLetters[spell]].Draw:Value() and Active then
						local Width = self.Menu.Draw["Draw" .. SpellLetters[spell]].Width:Value()
						local Color = Colors[self.Menu.Draw["Draw" .. SpellLetters[spell]].Color:Value()]

						Draw.Circle(myHero.pos, Active, Width, Color)
					end
				end

				if self.Menu.Draw.MissingHP:Value() then
					for i = 1, #self.Enemies do
						local enemy = self.Enemies[i]

						if enemy.valid and enemy.pos2D.onScreen then
							local kt = self.killstealTable[enemy.networkID] or {totalDamage = 0}

							Draw.Text(not kt.killable and floor((enemy.health - kt.totalDamage) * 100 / enemy.maxHealth) .. "%" or "Killable", enemy.pos2D.x + 20, enemy.pos2D.y - 100)
						end
					end
				end

				-- if self.Menu.Hotkeys.DamageCalc:Value() then
				-- 	Draw.Circle(mousePos, 25, 5, Colors[4])
				-- end
			end
		end
	end
end

function Katarina:Escape()
	local menuAccess = self.Menu.Escape

	if menuAccess.Enabled:Value() and self.Spells.E.ready() then
		local tTower = nil
		local tRange = 999999

		for i = 1, #self.Towers do
			local Tower = self.Towers[i]

			if Tower.pos2D.onScreen and Tower.targetID == myHero.networkID then 
				tTower = Tower 
				tRange = Tower.distance
				break
			end
		end

		if tTower then
			local range = menuAccess.MinRange:Value()
			local numEnemies = menuAccess.MinEnemy:Value()
			local minHP = menuAccess.MinHealth:Value()
			local cond = menuAccess.Switch:Value()

			if tTower.distance <= range then
				local a = #self:getHeroesInRange(myHero, 400, true) <= numEnemies
				local b = (myHero.health * 100 / myHero.maxHealth) <= minHP

				if (cond == 1 and a and b) or (cond == 2 and (a or b)) then
					local x = self:getBestDaggerToMyHero(myHero, self.Spells.E.range)

					if x and x.pos:DistanceTo(tTower.pos) >= 875 then
						self:castE(x)
					else
						local y = self:getBestUnitToMyHero(myHero, self.Spells.E.range)

						if y and y.pos:DistanceTo(tTower.pos) >= 875 then
							self:castE(y)
						end
					end
				end
			end
		end
	end
end

function Katarina:RStop()
	if self.Menu.Options.RStop:Value() then
		local enemies = #self:getHeroesInRange(myHero, self.Spells.R.range, true)

		if enemies == 0 then
			Move(mousePos)
			self.Orbwalker:setAttack(true)
			self.Orbwalker:setMovement(true)
		end
	end
end

function Katarina:AutoJump()
	if self.Menu.Hotkeys.AutoJump:Value() and self.Spells.E.ready() then
		local nearest = nil
		local d = 999999

		for i = 1, #self.Enemies do
			local enemy = self.Enemies[i]
			local ed = enemy.distance

			if ed < self.Spells.E.range and ed < d then
				d = ed
				nearest = enemy
			end
		end

		if nearest then
			Cast(HK_E, nearest)
		end
	end
end

function Katarina:WallJump()
	if self.Menu.Hotkeys.WallJump:Value() and (self.Spells.W.ready() or self:wCasted()) and self.Spells.E.ready() then
		self.Orbwalker:setMovement(false)
		local JumpDirection = mousePos
		local castPos = myHero.pos:Extended(JumpDirection, 140 + myHero.boundingRadius)
		
		if self.Spells.W.ready() then
			Cast(HK_W)
		end

		local c = 0
		while self.Spells.E.ready() do
			Cast(HK_E, castPos)
			c = c + 1
			if c == 20 then break end
		end
		
		self.Orbwalker:setMovement(true)	
	end
end

function Katarina:isUltying()
	return myHero.isChanneling and myHero.activeSpell.valid and myHero.activeSpellSlot == 3
end

function Katarina:castIgnite(unit)
	if Ignite and unit then
		local HK = Ignite == SUMMONER_1 and HK_SUMMONER_1 or HK_SUMMONER_2

		Cast(HK, unit)
	end
end

function Katarina:qDetect()
	if myHero.isChanneling and myHero.activeSpell.valid and myHero.activeSpellSlot == 0 then
		if not self.Spells.Q.pressed then
			self.Spells.Q.pressed = true

			DelayAction(function()
				self:findDagger(true)
			end, self.Spells.Q.delay + self.Menu.Options.QDetectionrate:Value())
		end
	end
end

function Katarina:Cast(msg, wParam)
	if wParam == 50 and msg >= 256 then
		if self.Spells.W.ready() then
			self.Spells.W.lastCast = time()
			self.Spells.W.lastCastPos = myHero.pos

			delayed(self.findDagger, self.Menu.Options.wDelay:Value())
		end
	end
end

function Katarina:findDagger(LFQ, notFound)
	local foundQ = false

	for i = 1, Game.ParticleCount() do
		local par = Game.Particle(i)

		if par.name == "Katarina_Base_W_Indicator_Ally" then
			local foundNew = newDagger(par)

			if foundNew and LFQ then 
				Katarina.Spells.Q.pressed = false
				foundQ = true 
			end
		end 
	end

	if LFQ and not foundQ and not notFound then
		DelayAction(function()
			Katarina:findDagger(true, true)
		end, .2)
	elseif not foundQ and notFound then
		Katarina.Spells.Q.pressed = false
		print("Unfortunately Q wasnt detected successfully, please try to increase the Q-Detection-Rate in the Options Menu if it occurs more frequently.")
	end
end

function Katarina:goodTarget(unit)
	return unit and unit.valid and not unit.dead and unit.visible and unit.health > 0 and unit.pos2D.onScreen
end

function Katarina:analyzeSituation(unit, A, Q, W, E, R, I) --if spell isReady
	local tableAccess = self.Spells
	local aRange = myHero.range + myHero.boundingRadius + unit.boundingRadius
	local rangeToUnit = E and (Q and tableAccess.Q.range or R and tableAccess.R.range or I and tableAccess.Ignite.range or aRange) --nil if we cant jump
	local bestTarget, targetType, targetPriority
	local situation = {}
	local distance = unit.distance

	local aState = A and (distance < aRange and 1 or 2)
	local qState = Q and (distance < tableAccess.Q.range and 1 or 2)
	local wState = W and (distance < tableAccess.W.damageRadius and 1 or 2)
	local eState = E and distance < tableAccess.E.range and 1
	local rState = R and (distance < tableAccess.R.range and 1 or 2)
	local iState = I and (distance < tableAccess.Ignite.range and 1 or 2)

	local bestSituation

	if rangeToUnit then
		bestTarget, targetType, targetPriority = self:getBestDaggerToMyHero(unit, rangeToUnit)
		--If there is no Dagger or no AA-Dagger, we check also for units we can jump to
		if targetPriority > 2 or distance > tableAccess.E.range then
			local bestUnit, unitType, unitPriority = self:getBestUnitToMyHero(unit, rangeToUnit)
			
			if unitPriority < targetPriority then
				bestTarget, targetType, targetPriority = bestUnit, unitType, unitPriority
			end
		end

		if bestTarget then
			if targetType == "AttackClose" then --Dagger
				bestSituation = bestTarget.isDagger
				situation.jump = bestTarget.pos
				situation.jumpPos = bestTarget.isDagger and bestTarget:getJumpSpot(unit, targetType) or self:getJumpSpot(bestTarget, unit)
				situation.Dagger = bestTarget.isDagger and bestTarget
				situation.AA = aState
				situation.Q = qState
				situation.W = wState
				situation.E = eState
				situation.R = rState
				situation.Ignite = iState
				situation.type = targetType
			elseif targetType == "Attack" then --Dagger
				bestSituation = bestTarget.isDagger
				situation.jump = bestTarget.pos
				situation.jumpPos = bestTarget.isDagger and bestTarget:getJumpSpot(unit, targetType) or self:getJumpSpot(bestTarget, unit)
				situation.Dagger = bestTarget.isDagger and bestTarget
				situation.AA = aState
				situation.Q = qState
				situation.W = wState
				situation.E = eState
				situation.R = rState
				situation.Ignite = iState
				situation.type = targetType
			elseif targetType == "Jump" then --Dagger
				bestSituation = bestTarget.isDagger
				situation.jump = bestTarget.pos
				situation.jumpPos = bestTarget.isDagger and bestTarget:getJumpSpot(unit, targetType) or self:getJumpSpot(bestTarget, unit)
				situation.Dagger = bestTarget.isDagger and bestTarget
				situation.AA = false
				situation.Q = qState
				situation.W = qState
				situation.E = eState
				situation.R = rState
				situation.Ignite = iState
				situation.type = targetType
			elseif targetType == "ComboJumpR" then --Dagger or Unit
				situation.jump = bestTarget.pos
				situation.jumpPos = bestTarget.isDagger and bestTarget:getJumpSpot(unit, targetType) or self:getJumpSpot(bestTarget, unit)
				situation.Dagger = bestTarget.isDagger and bestTarget
				situation.AA = false
				situation.Q = qState
				situation.W = wState
				situation.E = false
				situation.R = rState
				situation.Ignite = iState
				situation.type = targetType
			elseif targetType == "ComboJumpI" then --Dagger or Unit
				situation.jump = bestTarget.pos
				situation.jumpPos = bestTarget.isDagger and bestTarget:getJumpSpot(unit, targetType) or self:getJumpSpot(bestTarget, unit)
				situation.Dagger = bestTarget.isDagger and bestTarget
				situation.AA = false
				situation.Q = qState
				situation.W = wState
				situation.E = false
				situation.R = false
				situation.Ignite = iState
				situation.type = targetType
			elseif targetType == "ComboJumpQ" then --Dagger or Unit
				situation.jump = bestTarget.pos
				situation.jumpPos = bestTarget.isDagger and bestTarget:getJumpSpot(unit, targetType) or self:getJumpSpot(bestTarget, unit)
				situation.Dagger = bestTarget.isDagger and bestTarget
				situation.AA = false
				situation.Q = qState
				situation.W = wState
				situation.E = false
				situation.R = false
				situation.Ignite = false
				situation.type = targetType
			end

			if bestSituation then return situation end
		end
	end

	if distance < tableAccess.E.range then
		situation.jump = eState == 1 and unit.pos
		situation.jumpPos = situation.jump
		situation.AA = aState == 2 and eState == 1 and 2 or aState == 1 and 1
		situation.Q = qState == 2 and eState == 1 and 2 or qState == 1 and 1
		situation.W = wState == 2 and eState == 1 and 2 or wState == 1 and 1
		situation.E = eState
		situation.R = rState == 2 and eState == 1 and 2 or rState == 1 and 1
		situation.Ignite = iState == 2 and eState == 1 and 2 or iState == 1 and 1
	end

	return situation
end

function Katarina:getRCastPos(unit, combo)
	if not combo.jump then
		if combo.E == 1 then
			return unit.pos
		else
			return myHero.pos
		end
	else
		return combo.jumpPos
	end
end

function Katarina:calcDamage(combo, unit, Q, E, R, I)
	local tPD, tMD, tTD = 0, 0, 0
	local tableAccess = self.Spells
	local canJump = E and combo.jump

	if combo.AA then
		tPD = tPD + tableAccess.AA.rawDamage()
	end

	if combo.Q and Q then
		tMD = tMD + tableAccess.Q.rawDamage()
	end

	if combo.Dagger and E then
		tMD = tMD + tableAccess.W.rawDamage()
	end

	if combo.E and E then
		local D = combo.jump and combo.jump[3] and combo.jump[2]

		if not D or (D == "AttackClose" or D == "Attack") then
			tMD = tMD + tableAccess.E.rawDamage()
		end
	end

	if combo.R and R then
		local pos = self:getRCastPos(unit, combo)
		
		if pos then
			local multi = tableAccess.R.daggerBounces(unit, pos)
			tMD = tMD + tableAccess.R.rawDamage() * 1
		end
	end

	if combo.Ignite and I then
		tTD = tTD + tableAccess.Ignite.rawDamage()
	end

	local totalDamage = CalcPhysicalDamage(myHero, unit, tPD) + CalcMagicalDamage(myHero, unit, tMD) + tTD
	combo.totalDamage = totalDamage

	if totalDamage > unit.health then return true end

	return false
end

function Katarina:getCombos()
	local tableAccess = self.Spells
	local Q, W, E, R, I, A = tableAccess.Q.ready(), tableAccess.W.ready(), tableAccess.E.ready(), tableAccess.R.ready(), tableAccess.Ignite.ready(), self.Orbwalker:canAttack()
	
	if Q or E or R or I or A or W then
		local rTime = self.Menu.Options.recalcTime:Value()

		for i = 1, #self.Enemies do
			local enemy = self.Enemies[i]

			if self:goodTarget(enemy) then
				if not self.killstealTable[enemy.networkID] or time() - self.killstealTable[enemy.networkID].created >= rTime then
					self.killstealTable[enemy.networkID] = self:analyzeSituation(enemy, A, Q, W, E, R, I)
					self.killstealTable[enemy.networkID].created = time()
				end

				local tbl = self.killstealTable[enemy.networkID]

				if tbl then
					local ksMenu = self.Menu.Killsteal
					local ksQ, ksE, ksR, ksI = ksMenu.Q:Value(), ksMenu.E:Value(), ksMenu.R:Value(), ksMenu.I:Value()
					local comboCanKill = ksMenu.Enabled:Value() and self:calcDamage(tbl, enemy, ksQ, ksE, ksR, ksI)
					self.killstealTable[enemy.networkID].killable = comboCanKill

					if comboCanKill and not (self:isUltying() and not self.Menu.Options.RCancel:Value()) then
						self.isKillstealing = true
						self:Killsteal(enemy, tbl, ksQ, ksE, ksR, ksI)
					elseif not self:isUltying() then
						self.isKillstealing = false
						if self.mode == "Combo" and not self:isUltying() then
							self:Combo(enemy, tbl)
						end
					end
				end
			else
				self.killstealTable[enemy.networkID] = nil
			end
		end
	else
		self.killstealTable = {}
	end
end

function Katarina:getWCast(useW, modeW, comboW)
	if not useW then return end

	if comboW == 1 then
		if modeW < 3 then
			return modeW
		else
			return modeW - 2
		end
	elseif comboW == 2 then
		if modeW == 2 then
			return modeW
		else
			return modeW - 2
		end
	end
end

function Katarina:getRCast(target, menu)
	local HP = menu.HPOn:Value()
	local AOE = menu.AOEOn:Value()

	local a =  HP and (target.health * 100 / target.maxHealth) <= menu.HP:Value()
	local b = AOE and #self:getHeroesInRange(target, self.Spells.R.range, true) + 1 >= menu.AOE:Value()

	return a or b
end

function Katarina:Combo(target, combo)
	local menuAccess = self.Menu.Combo
	local Q, W, E, R = menuAccess.Q.Enabled:Value(), menuAccess.W.Enabled:Value(), menuAccess.E.Enabled:Value(), menuAccess.R.Enabled:Value()

	if Q or W or E or R then
		if E and not self.Spells.Q.pressed then
			local m2 = menuAccess.E.Mode2:Value()
			local m3 = W and menuAccess.W.Mode:Value()
			local m4 = R and menuAccess.R.Mode:Value()
			local m5 = R and menuAccess.R

			if m2 ~= 3 then
				if m2 == 1 and combo.E then --direct Cast + AA(?)
					local whenCastW = self:getWCast(W, m3, combo.W)
					local whenCastR = R and combo.R and self:getRCast(target, m5) and m4 == 1 and whenCastW

					self:castE(target, combo.AA, whenCastW, whenCastR, combo.AA == 1 and menuAccess.E.AA:Value())
					combo.E = nil
				elseif m2 == 2 then
					if combo.jump and (damagePriorities[combo.type] or 9) <= 2 then
						if combo.Dagger and combo.Dagger:isDropped() then
							local m = menuAccess.E.Mode:Value()

							if m == 1 or (m == 2 and combo.AA) then
								local whenCastW = self:getWCast(W, m3, combo.W)
								local whenCastR = R and combo.R and self:getRCast(target, m5) and m4 == 1 and whenCastW

								self:castE(combo.jumpPos, combo.AA, whenCastW, whenCastR, combo.AA == 1 and menuAccess.E.AA:Value())
								combo.E = nil
							end
						end
					elseif combo.E and self.Orbwalker:isForcedTarget(target) then --direct cast + AA(?)
						local whenCastW = self:getWCast(W, m3, combo.W)
						local whenCastR = R and combo.R and self:getRCast(target, m5) and m4 == 1 and whenCastW

						self:castE(target, combo.AA, whenCastW, whenCastR, combo.AA == 1 and menuAccess.E.AA:Value())
						combo.E = nil
					end
				end
			end

			if combo.E == 1 then
				local spellStates = ((combo.Q or self.Spells.Q.readyIn() < 2) and Q) or ((combo.R or self.Spells.R.readyIn() < 2) and R) or ((combo.W or self.Spells.W.readyIn() < 2) and W)
				local daggerOrQ = combo.Dagger or self:qCasted(.2)
				local canAAReset = menuAccess.E.AR:Value() and not combo.AA and self.Spells.AA.inRange(target)

				if not spellStates and not daggerOrQ and canAAReset then
					self:castE(target, true)
				end
			end
		elseif combo.AA == 1 and self.Orbwalker:canAttack() then
			self.Orbwalker:Attack(target)
		end

		if Q and combo.Q then
			local m = menuAccess.Q.Mode:Value()

			if combo.Q == 1 and ((menuAccess.Q.Early:Value() and myHero.levelData.lvl == 1) or (m == 1 or (combo.E or self:eCasted()))) then
				self:castQ(target)
				combo.Q = nil
			elseif combo.Q == 1 and menuAccess.Q.Solo:Value() and not (((combo.W or self.Spells.W.readyIn() < 4) and W) or ((combo.E or self.Spells.E.readyIn() < 4) and E) or ((combo.R or self.Spells.R.readyIn() < 4) and R)) then
				self:castQ(target)
				combo.Q = nil
			end
		end

		if W and combo.W == 1 then
			if menuAccess.W.Reset:Value() and self.Spells.E.readyIn() > 3.5 then
				self:castW()
			end
		end

		if R and combo.R == 1 then
			local m = menuAccess.R.Mode:Value()

			if not ((Q and combo.Q) or (W and combo.W) or (E and combo.E)) and m ~= 1 and self:getRCast(target, m5) then
				if m == 2 then
					if self:wCasted() and self.Spells.W.lastCastPos:DistanceTo(myHero.pos) <= 270 + 140 + myHero.boundingRadius then
						self:castR()
					end
				else
					self:castR()
				end
			end
		end
	end

	self.Orbwalker:setMovement(true)
end

function Katarina:Harass()
	local menuAccess = self.Menu.Harass
	local Mode = menuAccess.Mode:Value()

	if Mode ~= 3 then
		local Spells = self.Spells

		if Spells.Q.ready() and (Mode == 1 or (Mode == 2 and Spells.E.ready())) then
			local target = self.Orbwalker:getTarget(Spells.Q.range)

			if target then
				self:castQ(target)
			end
		elseif Mode == 2 and Spells.E.ready() then --2
			local target = self.Orbwalker:getTarget(Spells.E.range)

			if target then
				local dagger, dType, dPrio = self:getBestDaggerToMyHero(target, Spells.E.range)

				if dagger and dPrio <= 2 and dagger:isDropped() then
					self:castE(dagger:getJumpSpot(target, dType), false, menuAccess.WAfter:Value() and 2)
				end
			end
		end
	end
end

function Katarina:Farm()
	local menuAccess = self.Menu.Farm
	local Mode = menuAccess.Mode:Value()

	if Mode ~= 4 then
		local Spells = self.Spells
		local rangeToCheck = (Mode == 1 and (Spells.Q.ready() and Spells.Q.range)) or (Mode == 2 and (Spells.E.ready() and Spells.E.range)) or (Mode == 3 and (Spells.Q.ready() and Spells.Q.range or (Spells.E.ready() and Spells.E.range)))
		
		if rangeToCheck then
			local lastHitTarget = _G.SDK.HealthPrediction:GetLastHitTarget()
			local killableMinions = {Q = {}, D = {}}
			local Q, D = Spells.Q.rawDamage(), Spells.W.rawDamage()
			local minionDamage = {}
			local q, d = 0, 0

			if Mode == 1 or (Mode == 3 and Spells.Q.ready() and not Spells.E.ready()) then
				local farmMinions = self:getMinionsInRange(myHero, rangeToCheck)

				for i = 1, #farmMinions do
					local minion = farmMinions[i]
					
					if not (lastHitTarget and minion.networkID == lastHitTarget.networkID) then
						if not minionDamage[minion.maxHealth] then
							minionDamage[minion.maxHealth] = CalcMagicalDamage(myHero, minion, Q)
						end

						if _G.SDK.HealthPrediction:GetPrediction(minion, minion.distance / Spells.Q.speed) < minionDamage[minion.maxHealth] then
							self:castQ(minion)
							break
						end
					end
				end
			elseif Mode == 2 or (Mode == 3 and Spells.E.ready() and not Spells.Q.ready()) then
				local minHits = menuAccess.MinHits:Value()
				local kills = menuAccess.Kills:Value()
				local _daggers = self:getDaggersInRange(myHero, Spells.E.range)
				local bestDagger = nil
				local bestHits = 0

				for i = 1, #_daggers do
					local _dagger = _daggers[i]
					local farmMinions = _dagger:isDropped() and self:getMinionsInRange(_dagger, Spells.W.damageRadius) or {}

					if #farmMinions < minHits then break end

					if kills then
						for j = 1, #farmMinions do
							local minion = farmMinions[j]

							if not minionDamage[minion.maxHealth] then
								minionDamage[minion.maxHealth] = CalcMagicalDamage(myHero, minion, D)
							end

							if _G.SDK.HealthPrediction:GetPrediction(minion, .1) < minionDamage[minion.maxHealth] then
								d = d + 1
								killableMinions.D[d] = minion
							end
						end

						if d > bestHits and d >= minHits then
							bestHits = d
							bestDagger = _dagger
						end
					else
						if #farmMinions > bestHits then
							bestHits = #farmMinions
							bestDagger = _dagger
						end
					end
				end

				if bestDagger then
					self:castE(bestDagger)
				end
			else --Mode: 3
				local minHits = menuAccess.MinHits:Value()
				local kills = menuAccess.Kills:Value()
				local bestHits = 0
				local bestDagger = nil

				if Spells.Q.ready() then
					local farmMinions = self:getMinionsInRange(myHero, Spells.E.range - 350)

					for i = 1, #farmMinions do
						local minion = farmMinions[i]
						
						if not (lastHitTarget and minion.networkID == lastHitTarget.networkID) then
							if not minionDamage[minion.maxHealth] then
								minionDamage[minion.maxHealth] = {CalcMagicalDamage(myHero, minion, Q)}
							end

							if minion.health < minionDamage[minion.maxHealth][1] then
								q = q + 1
								killableMinions.Q[q] = minion
							end
						end
					end

					if #killableMinions.Q == 0 then
						killableMinions.Q = farmMinions
					end

					for i = 1, #killableMinions.Q do
						local qTarget = killableMinions.Q[i]
						local endPos = qTarget.pos:Shortened(myHero.pos, 350)
						local hits = self:getMinionsInRange(endPos, Spells.W.damageRadius)

						if #hits < minHits then break end

						if kills then
							for j = 1, #hits do
								local minion = hits[j]

								if not minionDamage[minion.maxHealth] then
									minionDamage[minion.maxHealth] = {CalcMagicalDamage(myHero, minion, Q)}
								end

								if not minionDamage[minion.maxHealth][2] then
									minionDamage[minion.maxHealth][2] = CalcMagicalDamage(myHero, minion, D)
								end

								if minion.health < minionDamage[minion.maxHealth][2] then
									d = d + 1
									killableMinions.D[d] = minion
								end
							end

							if d > bestHits and d >= minHits then
								bestHits = d
								bestDagger = qTarget
							end
						else
							if #hits > bestHits then
								bestHits = #hits
								bestDagger = qTarget
							end
						end
					end

					if bestDagger then
						Cast(HK_Q, bestDagger)
					end
				end
			end
		end
	end
end

function Katarina:Clear()
	local menuAccess = self.Menu.Clear
	local Mode = menuAccess.Mode:Value()

	if Mode ~= 5 then
		local Spells = self.Spells
		local rangeToCheck = (Mode == 1 and (Spells.Q.ready() and Spells.Q.range)) or (Mode == 2 and (Spells.Q.ready() and Spells.Q.range)) or (Mode == 3 and (Spells.E.ready() and Spells.E.range)) or (Mode == 4 and (Spells.Q.ready() and Spells.Q.range or (Spells.E.ready() and Spells.E.range)))
		
		if rangeToCheck then
			local lastHitTarget = _G.SDK.HealthPrediction:GetLastHitTarget()
			local killableMinions = {Q = {}, D = {}}
			local Q, D = Spells.Q.rawDamage(), Spells.W.rawDamage()
			local minionDamage = {}
			local q, d = 0, 0

			if (Mode == 1 or Mode == 2) or (Mode == 4 and Spells.Q.ready() and (not Spells.E.ready() or self.QFarm)) then
				self.QFarm = false
				local farmMinions = self:getMinionsInRange(myHero, rangeToCheck)

				for i = 1, #farmMinions do
					local minion = farmMinions[i]
					
					if not (lastHitTarget and minion.networkID == lastHitTarget.networkID) then
						if not minionDamage[minion.maxHealth] then
							minionDamage[minion.maxHealth] = CalcMagicalDamage(myHero, minion, Q)
						end

						if Mode == 2 or _G.SDK.HealthPrediction:GetPrediction(minion, minion.distance / Spells.Q.speed) < minionDamage[minion.maxHealth] then
							self:castQ(minion)
							break
						end
					end
				end
			elseif Mode == 3 or (Mode == 4 and Spells.E.ready() and not Spells.Q.ready()) then
				local minHits = menuAccess.MinHits:Value()
				local wAfter = menuAccess.WAfter:Value()
				local _daggers = self:getDaggersInRange(myHero, Spells.E.range)
				local bestDagger = nil
				local bestHits = 0

				for i = 1, #_daggers do
					local _dagger = _daggers[i]
					local farmMinions = _dagger:isDropped() and self:getMinionsInRange(_dagger, Spells.W.damageRadius) or {}

					if #farmMinions < minHits then break end

					local pos = self:getCircularAOEPos(farmMinions, Spells.W.damageRadius, _dagger)

					if pos and pos[2] > minHits and minHits > bestHits then
						bestHits = minHits
						bestDagger = pos[1]
					end
				end

				if bestDagger then
					self:castE(bestDagger, false, wAfter and 2)
				end
			elseif Mode == 4 then --Mode: 4
				local minHits = menuAccess.MinHits:Value()
				local bestHits = 0
				local bestDagger = nil

				if Spells.Q.ready() then
					local farmMinions = self:getMinionsInRange(myHero, Spells.E.range - 350)

					for i = 1, #farmMinions do
						local qTarget = farmMinions[i]
						local endPos = qTarget.pos:Shortened(myHero.pos, 350)
						local hits = self:getMinionsInRange(endPos, Spells.W.damageRadius)

						if #hits < minHits then break end

						if #hits > bestHits then
							bestHits = #hits
							bestDagger = qTarget
						end
					end

					if bestDagger then
						Cast(HK_Q, bestDagger)
					elseif menuAccess.QFarm:Value() and #farmMinions <= minHits then
						self.QFarm = true
					end
				end
			end
		end
	end
end

function Katarina:getCircularAOEPos(list, width, forceTarget, noExcusion)
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

function Katarina:Killsteal(unit, combo, Q, E, R, I)
	local menuAccess = self.Menu.Killsteal

	if combo.jump and E and ((combo.Dagger and combo.Dagger:isDropped() and combo.Dagger:getRemainingTime() > 0.1) or not combo.Dagger) then
		self:castE(combo.jumpPos)
	elseif combo.E == 1 and E then
		self:castE(unit)
	end

	if combo.Q == 1 and Q then
		self:castQ(unit)
	end

	if combo.Ignite == 1 and I then
		self:castIgnite(unit)
	end

	if combo.R == 1 and R then
		self:castR()
	end
end

function Katarina:getMinionsInRange(unit, range)
	local list = {}
	local c = 0

	for i = 1, Game.MinionCount() do
		local obj = Game.Minion(i)
		local d = obj.pos:DistanceTo(unit.pos)

		if obj.team ~= myHero.team and d <= range then
			c = c + 1
			list[c] = obj
		end
	end

	return list
end

function Katarina:getHeroesInRange(unit, range, enemiesOnly)
	local list = {}
	local c = 0
	local Units = not enemiesOnly and mergeTables(self.Allies, self.Enemies) or self.Enemies

	for i = 1, #Units do
		local obj = Units[i]

		if obj.valid and unit.networkID ~= obj.networkID then
			local d = obj.pos:DistanceTo(unit.pos)

			if d <= range then
				c = c + 1
				list[c] = obj
			end
		end
	end

	return list
end

function Katarina:castQ(unit)
	if self:isUltying() then return end
	local t = time()

	if t - self.Spells.Q.lastCast > 0 then
		Cast(HK_Q, unit)
		self.Spells.Q.lastCast = t + .3
	end
end

function Katarina:castW()
	if self:isUltying() then return end
	Cast(HK_W)
end

function Katarina:castE(pos, attackAfter, castW, castR, wait)
	if self:isUltying() then return end
	self.Orbwalker:setMovement(false)

	if not wait then
		local t = time()

		if t - self.Spells.E.lastCast > 0 then
			self.Spells.E.lastCast = t + .05
			if self.Orbwalker:canMove() and not self.Orbwalker:isAttacking() then 
				if castW == 1 then self:castW() end
				if castR == 1 then self:castR() return end
				
				Cast(HK_E, pos)

				if castW == 2 then 
					DelayAction(function()
						self:castW() 
					end, 0)
				end

				if castR == 2 then 
					DelayAction(function()
						self:castR() 
					end, 0)
				end
			end
		end
	end
end

function Katarina:castR()
	Cast(HK_R)
end

function Katarina:qCasted(timex) --returns true if spell was casted within last .1s
	local dat = myHero:GetSpellData(0)
	return time() - (dat.castTime - dat.cd) < (timex or .1)
end

function Katarina:wCasted() --returns true if spell was casted within last .1s
	local ret = time() - self.Spells.W.lastCast

	if ret < .1 then return true end
	if ret > 2 then self.Spells.W.lastCast = 0

	return false end
end

function Katarina:eCasted() --returns true if spell was casted within last .1s
	local dat = myHero:GetSpellData(2)
	return time() - (dat.castTime - dat.cd) < .1
end

function Katarina:rCasted() --returns true if spell was casted within last .1s
	local ret = time() - self.Spells.R.lastCast

	if ret < .1 then return true end
	if ret > 2 then self.Spells.R.lastCast = 0

	return false end
end

function Katarina:getDamageType(object, unit)
	local distance = object.pos:DistanceTo(unit.pos) - 150
	--To close
	if distance <= 150 then
		return "AttackClose"
	end
	--AA
	if distance <= myHero.range + myHero.boundingRadius + unit.boundingRadius then
		return "Attack"
	end
	--E --> Double Jump
	-- if distance <= Katarina.Spells.E.range - myHero.boundingRadius then
	-- 	return "DoubleJump"
	-- end
	--R
	if distance <= Katarina.Spells.R.range then
		return "ComboJumpR"
	end
	--I
	if Ignite and distance <= Katarina.Spells.Ignite.range then
		return "ComboJumpI"
	end
	--Q
	if distance <= Katarina.Spells.Q.range then
		return "ComboJumpQ"
	end
	--Out of range
	return
end

function Katarina:getBestMinionToMyHero(unit, range, rangeToMyHero)
	local bestUnit = nil
	local bestType = ""
	local bestPriority = 9

	for i = 1, Game.MinionCount() do
		local Minion = Game.Minion(i)

		if Minion.distance <= rangeToMyHero and Minion.pos:DistanceTo(unit.pos) <= range then
			local damageType = self:getDamageType(Minion, unit)
			local priority = damagePriorities[damageType] or 9

			if priority < bestPriority then
				bestPriority = priority
				bestUnit = Minion
				bestType = damageType
			end
		end
	end

	return bestUnit, bestType, bestPriority
end

function Katarina:getBestHeroToMyHero(unit, range, rangeToMyHero)
	local bestUnit = nil
	local bestType = ""
	local bestPriority = 9

	for i = 1, #self.Heroes do
		local Hero = self.Heroes[i]

		if Hero.networkID ~= unit.networkID and Hero.distance <= rangeToMyHero and Hero.pos:DistanceTo(unit.pos) <= range then
			local damageType = self:getDamageType(Hero, unit)
			local priority = damagePriorities[damageType] or 9

			if priority < bestPriority then
				bestPriority = priority
				bestUnit = Hero
				bestType = damageType
			end
		end
	end

	return bestUnit, bestType, bestPriority
end

function Katarina:getBestUnitToMyHero(unit, range)
	local bestUnit = nil
	local bestType = ""
	local bestPriority = 9
	--Minions
	local bestMinion, bestMinionType, bestMinionPriority = self:getBestMinionToMyHero(unit, range + 150, self.Spells.E.range)

	if bestMinionPriority < bestPriority then
		bestUnit = bestMinion
		bestType = bestMinionType
		bestPriority = bestMinionPriority
	end

	--Heroes
	local bestHero, bestHeroType, bestHeroPriority = self:getBestHeroToMyHero(unit, range + 150, self.Spells.E.range)

	if bestHeroPriority < bestPriority then
		bestUnit = bestHero
		bestType = bestHeroType
		bestPriority = bestHeroPriority
	end

	return bestUnit, bestType, bestPriority
end

function Katarina:getBestDaggerToMyHero(unit, range)
	local Daggers = self.Daggers:getDaggers()
	local bestPriority = 9
	local bestDagger = nil
	local bestType = ""

	for i = 1, #Daggers do
		local _dagger = Daggers[i]
		local distance = myHero.pos:DistanceTo(_dagger.pos)

		if distance <= self.Spells.E.range + myHero.boundingRadius and unit.pos:DistanceTo(_dagger.pos) <= range then
			local damageType = _dagger:getDamageType(unit)
			local priority = damagePriorities[damageType] or 9

			if priority < bestPriority then
				bestPriority = priority
				bestDagger = _dagger
				bestType = damageType
			end
		end
	end

	return bestDagger, bestType, bestPriority
end

function Katarina:getDaggersInRange(unit, range)
	local Daggers = self.Daggers:getDaggers()
	local list = {}
	local c = 0

	for i = 1, #Daggers do
		local _dagger = Daggers[i]
		local distance = myHero.pos:DistanceTo(_dagger.pos)

		if distance <= range then
			c = c + 1
			list[c] = _dagger
		end
	end

	return list
end

function Katarina:getJumpSpot(jump, unit)
	return jump.pos:Extended(unit.pos, jump.boundingRadius)
end
--=== Auto Update ==--
local function AutoUpdate()
    DownloadFile("https://raw.githubusercontent.com/Maxxxel/GOS/master/ext/Scripts/maxKatarina.version", COMMON_PATH, "maxKatarina.version")

    local newVersionScript = tonumber(ReadFile(COMMON_PATH, "maxKatarina.version"))

    if newVersionScript > version then
        DownloadFile("https://raw.githubusercontent.com/Maxxxel/GOS/master/ext/Scripts/maxKatarina.lua", SCRIPT_PATH, "maxKatarina.lua")
        print("maxKatarina: Updated to " .. newVersionScript .. ". Please Reload with 2x F6")
        return false
    else
        print("maxKatarina: No Updates Found (" ..version .. ")")
        return true
    end
end
--=== Init the Script ===--
if AutoUpdate() then
	delayed(Katarina, 1)
end
