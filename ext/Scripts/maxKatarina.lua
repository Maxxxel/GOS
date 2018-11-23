local version = 0.01
local author = "Maxxxel"

if myHero.charName ~= "Katarina" then return end

local Game = Game
local time = Game.Timer
local Control = Control
local Move = Control.Move
local Cast = Control.CastSpell
local table = table
local rem = table.remove
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

function Dagger:timeTillLand()
	return self.castTime - time() + self.landingTime
end

function Dagger:isDropped()
	if self.dropped then return true end
	local timer = self:timeTillLand()

	if timer <= 0 then
		self.dropped = true
		return true
	end

	return false
end

function Dagger:getClosestSpot(unit, override)
	local closestDagger = override and override[1] or self:getClosestDagger(unit)

	if closestDagger then
		local pos = closestDagger.obj or closestDagger
		local daggerType = override and override[2] or closestDagger:getDamageType(unit)

		if daggerType == "All" then
			return pos.pos
		elseif daggerType == "Attack" then
			return pos.pos - (pos.pos - unit.pos):Normalized() * 140
		-- elseif daggerType == "Walk" then
		-- 	return pos.pos - (pos.pos - unit.pos):Normalized() * (140 + myHero.boundingRadius), daggerType
		-- elseif daggerType == "Jump" then
		-- 	return pos.pos - (pos.pos - unit.pos):Normalized() * (140 + myHero.boundingRadius), daggerType
		else
			return pos.pos - (pos.pos - unit.pos):Normalized() * (140 + myHero.boundingRadius)
		end
	end
end

function Dagger:getDamageType(unit, unit2, noDagger)
	if not unit then return "None" end

	local isDmgDoing = noDagger or self:isDropped()
	local o = noDagger and unit2.pos or self.obj.pos
	local distance = unit.pos:DistanceTo(o)
	local closest = 140 + unit.boundingRadius
	--Inside
	local inside = closest >= distance --and isDmgDoing
	if inside then return "All" end
	--Jump for DaggerDmg + AA after E on its edge
	local attackable = closest + myHero.boundingRadius + myHero.range >= distance --and isDmgDoing
	if attackable then return "Attack" end
	--Jump for DaggerDmg after E on its edge
	local jumpable = closest + 275 >= distance
	if jumpable then return "Jump" end
	if unit2 then return "None" end
	--Jump for DaggerDmg after walking to its edge
	-- local walkable = closest + 275 + myHero.boundingRadius >= distance
	-- if walkable then return "Walk" end

	return "None"
end

function Dagger:getClosestDagger(unit1, unit2)
	local retDagger = nil
	local dMax = 999999
	local Daggers = self:getDaggers()

	for i = 1, #Daggers do
		local _Dagger = Daggers[i]

		if unit2 then
			local d1 = unit1.pos:DistanceTo(_Dagger.obj)
			local d2 = unit2.pos:DistanceTo(_Dagger.obj)
			local d = d1 + d2

			if d <= dMax then
				dMax = d
				retDagger = _Dagger
			end
		else
			local d = unit1.pos:DistanceTo(_Dagger.obj)

			if d <= dMax then
				dMax = d
				retDagger = _Dagger
			end
		end
	end

	return retDagger
end

function Dagger:getDaggers()
	return self.list
end

function Dagger:getDaggersInRange(unit, range)
	local Daggers = self:getDaggers()
	local retDaggers = {}
	local retCount = 0

	for i = 1, #Daggers do
		local _Dagger = Daggers[i]

		if unit.pos:DistanceTo(_Dagger.obj.pos) <= range then
			retCount = retCount + 1
			retDaggers[retCount] = _Dagger
		end
	end

	return retDaggers
end

function Dagger:isCloserThanMe(unit, obj)
	local o = obj or self.obj
	local daggerToUnit = o.pos:DistanceTo(unit.pos) - Katarina.Spells.W.procRadius
	local daggerToMe = o.distance - Katarina.Spells.W.procRadius
	local unitToMe = unit.distance
	local goodOne = daggerToMe <= Katarina.Spells.E.range and unitToMe >= Katarina.Spells.E.range

	return goodOne and daggerToUnit <= Katarina.Spells.R.range and "comboJumpR" or  
		   goodOne and daggerToUnit <= Katarina.Spells.Ignite.range and "comboJumpI" or 
		   goodOne and daggerToUnit <= Katarina.Spells.Q.range and "comboJumpQ" or 
		   "None"
end

function Dagger:getKSDaggers(unit)
	local _Daggers = {}
	local count = 0
	local list = self.list

	for i = 1, #list do
		local _Dagger = list[i]
		local dmgType = _Dagger:getDamageType(unit)

		if dmgType == "None" then
			dmgType = _Dagger:isCloserThanMe(unit)
		end

		if dmgType ~= "None" and _Dagger.obj.distance - Katarina.Spells.W.procRadius < Katarina.Spells.E.range then
			count = count + 1
			_Daggers[count] = {_Dagger, dmgType, "dagger"}
		end
	end

	return _Daggers
end

function Dagger:delete(num)
	rem(self.list, num)
	self.ids[self.id] = nil
end

local function newDagger(obj)
	local ID = obj.networkID

	if not Dagger.ids[ID] then
		Dagger.ids[ID] = true

		local proxy = {
			landingTime = 1,
			dropped = false,
			castTime = time(),
			duration = 4,
			obj = obj,
			width = 150,
			lookout = 0,
			id = ID,
			typeOf = 'Dagger'
		}
		proxy.pos = proxy.obj.pos
		proxy.remainingTime = function()
			return self:isDropped() and (self.duration - (time() - self.castTime + self.landingTime)) or 999
		end

		local _Dagger = setmetatable(proxy, Dagger)
		Dagger.list[#Dagger.list + 1] = _Dagger

		return true
	end

	return false
end
--=== Start of Orbwalker Class ===--
local kataOrbwalker = {}  

local function setOrbwalkerSettings()
	kataOrbwalker.Move = function(self, pos)
		_G.SDK.Orbwalker:MoveToPos(pos)
	end

	kataOrbwalker.Attack = function(self, unit)
		_G.SDK.Orbwalker:Attack(unit)
	end

	kataOrbwalker.setMovement = function(self, bool)
		_G.SDK.Orbwalker.MovementEnabled = bool
	end

	kataOrbwalker.setAttack = function(self, bool)
		_G.SDK.Orbwalker.AttackEnabled = bool
	end

	kataOrbwalker.setTarget = function(self, unit)
		_G.SDK.OrbwalkerMenu.ts.selected.enable:Value(true)
		_G.SDK.TargetSelector.SelectedTarget = unit
	end

	kataOrbwalker.canAttack = function(self)
		return _G.SDK.Orbwalker:CanAttack()
	end

	kataOrbwalker.canMove = function(self)
		return _G.SDK.Orbwalker:CanMove()
	end

	kataOrbwalker.isAttacking = function(self)
		return _G.SDK.Orbwalker:IsAutoAttacking()
	end

	kataOrbwalker.getMode = function(self)
		for i = 0, 4 do
			if _G.SDK.Orbwalker.Modes[i] then
				return orbModes[i]
			end
		end

		return ""
	end

	kataOrbwalker.getTarget = function(self, range, type)
		local unit = _G.SDK.TargetSelector:GetTarget(range)

		return unit
	end

	kataOrbwalker.isForcedTarget = function(self, unit)
		return _G.SDK.TargetSelector.SelectedTarget and _G.SDK.TargetSelector.SelectedTarget.networkID == unit.networkID
	end
end

local function newOrbwalker()
	setOrbwalkerSettings()

	return kataOrbwalker
end
--=== Start of Katarina Class ===--
function Katarina:init()
	if not _G.GamsteronOrbwalkerLoaded then print("You need Gamsteron Orbwalker") return end
	if not self:loadTables() then return end
	self:loadMenu()
	self:loadCallbacks()
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
	self.Menu:MenuElement({id = "Hotkeys", name = "8. Special Keys", type = MENU})
		self.Menu.Hotkeys:MenuElement({id = "AutoJump", name = "1. Jump to nearest Enemy", key = string.byte("E")})
		self.Menu.Hotkeys:MenuElement({id = "WallJump", name = "2. Small Wall Jump", key = string.byte("T")})
end

function Katarina:loadCallbacks()
	Callback.Add("Tick", function() Katarina:Main() end)
	Callback.Add("Draw", function() Katarina:GFX() end)
	Callback.Add("WndMsg", function(a, b) Katarina:Cast(a, b) end)
end

function Katarina:loadTables()
	self.Orbwalker = newOrbwalker()
	if not self.Orbwalker then return end

	self.Daggers = Dagger
	self.isKillstealing = false

	self.Enemies = {}
	self.Allies = {}
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
		procRadius = 140, --distance to myHero's boundingRadius
		damageRadius = 300, --around myHero
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

function Katarina:loadUnits()
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)

		if hero.team == myHero.team and hero.networkID ~= myHero.networkID then
			self.Allies[#self.Allies + 1] = hero
		elseif hero.team ~= myHero.team then
			self.Enemies[#self.Enemies + 1] = hero
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
	self:daggerAliveCheck()
	--R
	if self:isUltying() then
		self:RStop()
		self.Orbwalker:setAttack(false)
		self.Orbwalker:setMovement(false)
	else
		self.Orbwalker:setAttack(true)
		self.Orbwalker:setMovement(true)
	end 
end

function Katarina:GFX()
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
						Type: ]] .. tostring(t.is) .. "\n"..[[
						DMG: ]] .. (t.totalDamage or 0) .. [[
						]]
						, enemy.pos2D.x + 50, enemy.pos2D.y - 80)

						if t.jump then
							local p = t.jump[1].pos:To2D()
							Draw.Line(enemy.pos2D.x, enemy.pos2D.y, p.x, p.y)
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
			end
		end
	end
end

function Katarina:RStop()
	if self.Menu.Options.RStop:Value() then
		local enemies = #self:getHeroesInRange(myHero, self.Spells.R.range, false, true)

		if enemies == 0 then
			Move(myHero.pos)
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

function Katarina:daggerAliveCheck()
	local Daggers = self.Daggers:getDaggers()

	if #Daggers > 0 then
		for i = 1, #Daggers do
			local _Dagger = Daggers[i]

			if _Dagger then
				if _Dagger.obj.name == "" then
					_Dagger:delete(i)
				end
			end
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

function Katarina:getKSJumpSpots(unit, Q, R, I)
	local tableAccess = self.Spells
	local maxRange = 
		Q and tableAccess.Q.range or
		R and tableAccess.R.range or
		I and tableAccess.Ignite.range

	if unit and maxRange then
		return self:getJumpSpots(unit, maxRange, nil, true)
	end

	return {}
end

function Katarina:analyzeSituation(unit, A, Q, W, E, R, I)
	local _Daggers = self.Daggers:getKSDaggers(unit)
	local Others = E and self:getKSJumpSpots(unit, Q, R, I) or {}
	local list = mergeTables(Others, _Daggers)
	local dist = unit.distance
	local tableAccess = self.Spells
	local aaDagger, wDagger, situation = nil, nil, {}
	local _q, _w, _e, _r, _i = Q and dist < tableAccess.Q.range and 1, W and dist < tableAccess.W.damageRadius + myHero.boundingRadius and 1, E and dist < tableAccess.E.range and 1, R and dist < tableAccess.R.range and 1, I and dist < tableAccess.Ignite.range and 1
	local best, prio, notTheBest = nil, 9

	if #list > 0 and E then
		for i = 1, #list do
			local Data = list[i]
			local dmgType = Data[2]
			local willBe = Data[4]

			if dmgType == "All" then
				local d = Data[3] == "dagger"

				situation = {jump = Data, AA = A and 2, W = _w or W and 2, Q = _q or Q and 2, Dagger = d and 1, E = 1, R = _r or R and 2, Ignite = I and 2, is = dmgType}
				aaDagger = d
				wDagger = d

				if prio == 1 or (d and best) then 
					local betterJumpTarget = closestPoint(situation.jump, best.jump, unit)
					situation.jump = betterJumpTarget
					best = situation
				elseif prio > 1 then
					prio = 1
					best = situation
				end

				notTheBest = _e and situation.jump[3] == "unit"
			elseif dmgType == "Attack" then
				local d = Data[3] == "dagger"

				situation = {jump = Data, AA = A and 2, W = _w or W and 2, Q = _q or Q and 2, Dagger = d and 1, E = _e, R = _r or R and 2, Ignite = I and 2, is = dmgType}
				aaDagger = d
				wDagger = d

				if prio == 2 or (d and best) then
					local betterJumpTarget = closestPoint(situation.jump, best.jump, unit)
					situation.jump = betterJumpTarget
					best = situation
				elseif prio > 2 then
					prio = 2
					best = situation
				end

				notTheBest = _e and situation.jump[3] == "unit"
			elseif dmgType == "Jump" then
				local d = Data[3] == "dagger"
				
				situation = {jump = Data, Q = _q or Q and 2, Dagger = d and 1, E = _e, R = _r or R and 2, Ignite = I and 2, is = dmgType}
				wDagger = d

				if prio == 3 or (d and best) then
					local betterJumpTarget = closestPoint(situation.jump, best.jump, unit)
					situation.jump = betterJumpTarget
					best = situation
				elseif prio > 3 then
					prio = 3
					best = situation
				end

				notTheBest = _e and situation.jump[3] == "unit"
			elseif dmgType == "comboJumpR" then
				situation = {jump = Data, Q = Q and 2, W = _w or W and 2, R = R and 2, Ignite = I and 2, is = dmgType}

				if prio == 4 then
					local betterJumpTarget = closestPoint(situation.jump, best.jump, unit)
					situation.jump = betterJumpTarget
					best = situation
				elseif prio > 4 then
					prio = 4
					best = situation
				end
			elseif dmgType == "comboJumpI" then
				situation = {jump = Data, Q = Q and 2, Ignite = I and 2, is = dmgType}

				if prio == 5 then
					local betterJumpTarget = closestPoint(situation.jump, best.jump, unit)
					situation.jump = betterJumpTarget
					best = situation
				elseif prio > 5 then
					prio = 5
					best = situation
				end
			elseif dmgType == "comboJumpQ" then
				situation = {jump = Data, Q = Q and 2, is = dmgType}

				if prio == 6 then
					local betterJumpTarget = closestPoint(situation.jump, best.jump, unit)
					situation.jump = betterJumpTarget
					best = situation
				elseif prio > 6 then
					prio = 6
					best = situation
				end
			-- else
			-- 	print("Debug: unpredicted dmgType->"..dmgType)
			end
		end
	end

	if best and not notTheBest then return best end

	if tableAccess.AA.inRange(unit) then
		situation = {
			AA = A and 1, 
			Q = _q, 
			W = _w,
			E = _e, 
			R = _r, 
			Ignite = _i}
	elseif  _w then
		situation = {
			Jump = E and unit, 
			AA = A and E and 2, 
			Q = _q, 
			W = _w,
			E = _e, 
			R = 1, 
			Ignite = _i}
	elseif 	_r then
		situation = {
			Jump = E and unit, 
			AA = A and E and 2, 
			Q = _q, 
			W = W and E and 2,
			E = _e, 
			R = 1, 
			Ignite = _i}
	elseif 	_i then
		situation = {
			Jump = E and unit, 
			AA = A and E and 2, 
			Q = _q, 
			W = W and E and 2,
			E = _e, 
			R = R and E and 2, 
			Ignite = 1}
	elseif 	_q then
		situation = {
			Jump = E and unit, 
			AA = A and E and 2, 
			Q = 1, 
			W = W and E and 2,
			E = _e, 
			R = R and E and 2, 
			Ignite = I and E and 2}
	elseif 	_e then
		situation = {
			Jump = E and unit,
			AA = A and E and 2,
			Q = Q and E and 2,
			W = W and E and 2,
			E = _e,
			R = R and E and 2,
			Ignite = I and E and 2
		}
	end

	return situation
end

function Katarina:getJumpPos(pos, target)
	if target then --jump on pos to get in target range
		return Dagger:getClosestSpot(pos, target)
	else --jump directly on target (behind/front?)
		return pos
	end
end

function Katarina:getRCastPos(unit, combo)
	if not combo.jump then
		if combo.E == 1 then --in E Range jump on the target
			return self:getJumpPos(unit)
		else --E not ready, we need to cast from here
			return myHero.pos
		end
	else
		return self:getJumpPos(unit, combo.jump)
	end
end

function Katarina:calcDamage(combo, unit, Q, E, R, I)
	local tPD, tMD, tTD = 0, 0, 0
	local dagger = 0
	local tableAccess = self.Spells

	if combo.AA then
		tPD = tPD + tableAccess.AA.rawDamage()
	end

	if combo.Q and Q then
		tMD = tMD + tableAccess.Q.rawDamage()
	end

	if combo.Dagger and E then
		dagger = CalcMagicalDamage(myHero, unit, tableAccess.W.rawDamage())
	end

	if combo.E and E then
		local D = combo.jump and combo.jump[3] and combo.jump[2]

		if not D or (D == "All" or D == "Attack") then
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

	if totalDamage > unit.health then return true, false end
	if totalDamage + dagger > unit.health then return true, true end

	return false
end

function Katarina:getCombos()
	local tableAccess = self.Spells
	local Q, W, E, R, I, A = tableAccess.Q.ready(), tableAccess.W.ready(), tableAccess.E.ready(), tableAccess.R.ready(), tableAccess.Ignite.ready(), self.Orbwalker:canAttack()
	
	if Q or E or R or I then
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
					local comboCanKill, killNeedDaggerDmg = (ksMenu.Enabled:Value() and self:calcDamage(tbl, enemy, ksQ, ksE, ksR, ksI))

					if comboCanKill and not (self:isUltying() and not self.Menu.Options.RCancel:Value()) then
						self:Killsteal(enemy, tbl, ksQ, ksE, ksR, ksI, killNeedDaggerDmg)
					elseif not self:isUltying() then
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

function Katarina:Combo(target, combo)
	local menuAccess = self.Menu.Combo
	local Q, W, E, R = menuAccess.Q.Enabled:Value(), menuAccess.W.Enabled:Value(), menuAccess.E.Enabled:Value(), menuAccess.R.Enabled:Value()

	if Q or W or E or R then
		if E and not self.Spells.Q.pressed then
			local m2 = menuAccess.E.Mode2:Value()
			local m3 = menuAccess.W.Mode:Value()
			local m4 = menuAccess.R.Mode:Value()

			if m2 ~= 3 then
				if m2 == 1 and combo.E then --direct Cast + AA(?)
					local whenCastW = self:getWCast(W, m3, combo.W)
					local whenCastR = R and combo.R and m4 == 1 and whenCastW

					self:castE(target, combo.AA, whenCastW, whenCastR, combo.AA == 1 and menuAccess.E.AA:Value())
					combo.E = nil
				elseif m2 == 2 then
					if combo.jump then
						if combo.Dagger and combo.jump[1]:isDropped() then
							local m = menuAccess.E.Mode:Value()

							if m == 1 or (m == 2 and combo.AA) then
								local pos = self:getJumpPos(target, combo.jump)

								if pos then --jump on dagger + AA(?)
									local whenCastW = self:getWCast(W, m3, combo.W)
									local whenCastR = R and combo.R and m4 == 1 and whenCastW

									self:castE(pos, combo.AA, whenCastW, whenCastR, combo.AA == 1 and menuAccess.E.AA:Value())
									combo.E = nil
								end
							end
						end
					elseif combo.E and self.Orbwalker:isForcedTarget(target) then --direct cast + AA(?)
						local whenCastW = self:getWCast(W, m3, combo.W)
						local whenCastR = R and combo.R and m4 == 1 and whenCastW

						self:castE(target, combo.AA, whenCastW, whenCastR, combo.AA == 1 and menuAccess.E.AA:Value())
						combo.E = nil
					end
				end
			end

			if combo.E == 1 and 
				not (((combo.Q or self.Spells.Q.readyIn() < 2) and Q) or ((combo.R or self.Spells.R.readyIn() < 2) and R) or ((combo.W or self.Spells.W.readyIn() < 2) and W)) and 
				not (combo.jump or self:qCasted(.2)) and 
				not combo.AA and self.Spells.AA.inRange(target) and menuAccess.E.AR:Value() then
				self:castE(target, true)
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

			if not ((Q and combo.Q) or (W and combo.W) or (E and combo.E)) and m ~= 1 then
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
				local Ds = self.Daggers:getKSDaggers(target)

				for i = 1, #Ds do
					local type = Ds[i][2]

					if type == "Attack" or type == "Jump" or type == "All" then
						local pos = Ds[i]
						local jp = self:getJumpPos(target, pos)

						if jp and pos[1]:isDropped() then
							self:castE(jp, false, menuAccess.WAfter:Value() and 2)
						end
					end
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
				local _daggers = self.Daggers:getDaggersInRange(myHero, Spells.E.range)
				local bestDagger = nil
				local bestHits = 0

				for i = 1, #_daggers do
					local _dagger = _daggers[i]
					local farmMinions = _dagger:isDropped() and self:getMinionsInRange(_dagger.obj, Spells.W.damageRadius + 50) or {}

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
							bestDagger = _dagger.obj
						end
					else
						if #farmMinions > bestHits then
							bestHits = #farmMinions
							bestDagger = _dagger.obj
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
					local farmMinions = self:getMinionsInRange(myHero, Spells.E.range - 350, false, true)

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
						local hits = self:getMinionsInRange(endPos, Spells.W.damageRadius + 50)

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
				local _daggers = self.Daggers:getDaggersInRange(myHero, Spells.E.range)
				local bestDagger = nil
				local bestHits = 0

				for i = 1, #_daggers do
					local _dagger = _daggers[i]
					local farmMinions = _dagger:isDropped() and self:getMinionsInRange(_dagger.obj, Spells.W.damageRadius + 50) or {}

					if #farmMinions < minHits then break end

					local pos = self:getCircularAOEPos(farmMinions, Spells.W.damageRadius, _dagger.obj)

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
						local hits = self:getMinionsInRange(endPos, Spells.W.damageRadius + 50)

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

function Katarina:Killsteal(unit, combo, Q, E, R, I, D)
	local menuAccess = self.Menu.Killsteal

	if combo.jump and E then
		if D and combo.Dagger and combo.jump[1]:isDropped() then
			local pos = self:getJumpPos(unit, combo.jump)

			if pos then
				self:castE(pos)
			end
		elseif not D then
			local pos = self:getJumpPos(unit, combo.jump)

			if pos then
				self:castE(pos)
			end
		end
	elseif combo.E and E then
		self:castE(unit)
	end

	if combo.Q and Q then
		self:castQ(unit)
	end

	if combo.I and I then
		castIgnite(unit)
	end

	if combo.R and R then
		self:castR()
	end
end

function Katarina:getMinionsInRange(unit, range, inE)
	local list = {}
	local c = 0

	for i = 1, Game.MinionCount() do
		local obj = Game.Minion(i)
		local d = obj.pos:DistanceTo(unit)

		if inE and unit.networkID ~= obj.networkID and obj.distance < self.Spells.E.range then
			local dmgType = Dagger:getDamageType(obj, unit, true)

			if dmgType == "None" then
				dmgType = Dagger:isCloserThanMe(unit, obj)
			end

			if dmgType ~= "None" and obj.distance - self.Spells.W.procRadius < self.Spells.E.range then
				c = c + 1
				list[c] = {obj, dmgType, "unit"}
			end
		elseif not inE and obj.team ~= myHero.team and obj.pos:DistanceTo(unit.pos or unit) <= range then
			c = c + 1
			list[c] = obj
		end
	end

	return list
end

function Katarina:getHeroesInRange(unit, range, inE, enemiesOnly)
	local list = {}
	local c = 0
	local Units = not enemiesOnly and mergeTables(self.Allies, self.Enemies) or self.Enemies

	for i = 1, #Units do
		local obj = Units[i]

		if obj.valid then
			local d = obj.pos:DistanceTo(unit)

			if inE and unit.networkID ~= obj.networkID and obj.distance < self.Spells.E.range then
				local dmgType = Dagger:getDamageType(obj, unit, true)

				if dmgType == "None" then
					dmgType = Dagger:isCloserThanMe(unit, obj)
				end

				if dmgType ~= "None" and obj.distance - self.Spells.W.procRadius < self.Spells.E.range then
					c = c + 1
					list[c] = {obj, dmgType, "unit"}
				end
			elseif not inE and obj.distance <= range then
				c = c + 1
				list[c] = obj
			end
		end
	end

	return list
end

function Katarina:getJumpSpots(unit, range, useDaggers, inJumpRange)
	local Daggers = useDaggers and self.Daggers:getDaggersInRange(unit, range) or {}
	local Minions = self:getMinionsInRange(unit, range, inJumpRange)
	local Heroes = self:getHeroesInRange(unit, range, inJumpRange)
	local merge = mergeTables(Daggers, Minions, Heroes)

	return merge
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
