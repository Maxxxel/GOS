--[[
		maxBaseUlt
		by Maxxxel

		Supported Champions:
			-Ashe
			-Corki
			-Draven
			-Ezreal
			-Fizz
			-Gangplank
			-Jayce
			-Jhin
			-Jinx
			-Karthus
			-Kogmaw
			-Lux
			-MissFortune
			-Nami
			-Nidalee
			-Pantheon
			-Rumble
			-TwistedFate
			-Varus
			-Xerath
			-Ziggs
--]]

local version = 0.01
local supportedChampions = { --Ranges greater than 1200
	["Ashe"] = {
		{
			name = "EnchantedCrystalArrow",
			missileName = "EnchantedCrystalArrow",
			range = 25000,
			speed = 1600,
			delay = 0.25,
			width = 125,
			radius = 0,
			slot = _R,
			block = {"hero"},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Corki"] = {
		{
			name = "MissileBarrageMissile",
			missileName = "MissileBarrageMissile",
			range = 1225,
			speed = 1950,
			delay = 0.175,
			width = 37.5,
			radius = 75,
			slot = _R,
			block = {'hero', 'minion'},
			damage = function(source, target, time)
				return 0
			end
		},
		{
			name = "MissileBarrageMissile2",
			missileName = "MissileBarrageMissile2",
			range = 1225,
			speed = 1950,
			delay = 0.175,
			width = 75,
			radius = 150,
			slot = _R,
			block = {'hero', 'minion'},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Draven"] = {
		{
			name = "DravenRCast",
			missileName = "DravenR",
			range = 25000,
			speed = 2000,
			delay = 0.5,
			width = 65,
			radius = 130,
			slot = _R,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Ezreal"] = {
		{
			name = "EzrealTrueshotBarrage",
			missileName = "EzrealTrueshotBarrage",
			range = 25000,
			speed = 2000,
			delay = 1,
			width = 80,
			radius = 160,
			slot = _R,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Fizz"] = {
		{
			name = "FizzR",
			missileName = "FizzRMissile",
			range = 1300,
			speed = 1300,
			delay = 0.25,
			width = 60,
			radius = 120,
			slot = _R,
			block = {'hero'},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Gangplank"] = { --need work
		{
			name = "",
			range = 25000,
			speed = 0,
			delay = 0.25,
			width = 200,
			radius = 600,
			slot = _R,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Jayce"] = { --accelerated
		{
			name = "JayceShockBlast",
			range = 1600,
			speed = 2350,
			delay = 0.214,
			width = 70,
			radius = 140,
			slot = _W,
			block = {'hero', 'minion'},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Jhin"] = {
		{
			name = "JhinW",
			missileName = "",
			range = 3000,
			speed = 5000,
			delay = 0.75,
			width = 40,
			radius = 0,
			slot = _W,
			block = {'hero'},
			damage = function(source, target, time)
				return 0
			end
		},
		{
			name = "JhinR",
			missileName = "JhinRShotMis",
			extraMissileName = "JhinRShotMis4",
			range = 3500,
			speed = 5000,
			delay = 0.25,
			width = 80,
			radius = 0,
			slot = _R,
			block = {'hero'},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Jinx"] = {
		{
			name = "JinxW",
			missileName = "JinxWMissile",
			range = 1450,
			speed = 3200,
			delay = 0.6,
			width = 50,
			radius = 0,
			slot = _W,
			block = {'hero', 'minion'},
			damage = function(source, target, time)
				return 0
			end
		},
		{
			name = "JinxR",
			missileName = "JinxR",
			range = 25000,
			speed = 1500,
			maxSpeed = 2500,
			delay = 0.5,
			width = 112.5,
			radius = 225,
			slot = _R,
			block = {'hero'},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Karthus"] = {
		{
			name = "KarthusFallenOne",
			range = 25000,
			speed = 0,
			delay = 3000,
			width = 0,
			radius = 0,
			slot = _R,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
		{
			name = "KarthusFallenOne2",
			range = 25000,
			speed = 0,
			delay = 3000,
			width = 0,
			radius = 0,
			slot = _R,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Kogmaw"] = {
		{
			name = "KogMawVoidOoze",
			missileName = "KogMawVoidOozeMissile",
			range = 1280,
			speed = 1350,
			delay = 0.25,
			width = 57.5,
			radius = 115,
			slot = _E,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
		{
			name = "KogMawLivingArtillery",
			range = 1800,
			speed = 0,
			delay = 0.85,
			width = 100,
			radius = 200,
			slot = _R,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Lux"] = {
		{
			name = "LuxMaliceCannon",
			missileName = "LuxRVfxMis",
			range = 3340,
			speed = 0,
			delay = 1,
			width = 57.5,
			radius = 115,
			slot = _R,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["MissFortune"] = {
		{
			name = "MissFortuneBulletTime",
			range = 1400,
			speed = 0,
			delay = 0.1,
			width = 0,
			radius = 0,
			slot = _R,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Nami"] = {
		{
			name = "NamiR",
			missileName = "NamiRMissile",
			range = 2750,
			speed = 850,
			delay = 0.5,
			width = 107.5,
			radius = 215,
			slot = _R,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Nidalee"] = {
		{
			name = "JavelinToss",
			missileName = "JavelinToss",
			range = 1500,
			speed = 1300,
			delay = 0.25,
			width = 20,
			radius = 0,
			slot = _W,
			block = {'hero', 'minion'},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Pantheon"] = { --Troll xD
		{
			name = "PantheonRFall",
			range = 5500,
			speed = 0,
			delay = 3.5,
			width = 350,
			radius = 700,
			slot = _R,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Rumble"] = { --need work
		{
			name = "",
			range = 1700,
			speed = 0,
			delay = 0.25,
			width = 0,
			radius = 0,
			slot = nil,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["TwistedFate"] = {
		{
			name = "WildCards",
			missileName = "SealFateMissile",
			range = 1450,
			speed = 1000,
			delay = 0.25,
			width = 35,
			radius = 0,
			slot = _Q,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Varus"] = {
		{
			name = "VarusQ",
			missileName = "VarusQMissile",
			range = 1625,
			speed = 1850,
			delay = 0.25,
			width = 20,
			radius = 40,
			slot = _Q,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Xerath"] = {
		{
			name = "XerathArcanopulse2",
			range = 1400,
			speed = 0,
			delay = 0.5,
			width = 37.5,
			radius = 75,
			slot = _Q,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
		{
			name = "XerathRMissileWrapper",
			missileName = "XerathLocusPulse",
			range = 6160,
			speed = 0,
			delay = 0.6,
			width = 100,
			radius = 200,
			slot = _R,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
	},
	["Ziggs"] = { --need work
		{
			name = "",
			range = 1400,
			speed = 1700,
			delay = 0.25,
			width = 75,
			radius = 180,
			slot = _Q,
			block = {'minion', 'hero'},
			damage = function(source, target, time)
				return 0
			end
		},
		{
			name = "",
			range = 5300,
			speed = 0,
			delay = 3.5,
			width = 275,
			radius = 550,
			slot = _R,
			block = {},
			damage = function(source, target, time)
				return 0
			end
		},
	},
}

if not supportedChampions[myHero.charName] then
	print("maxBaseSpells: Sorry, this champion is currently not supported. The script will now end.")
	print("maxBaseSpells: To see a list of supported champions, visit the forum or open the script with any text editor.")

	return
else
	print("maxBaseSpells: " .. myHero.charName .. " loaded.")
end

require 'DamageLib'

local timer = Game.Timer
local Cast = Control.CastSpell

local maxBaseSpells = {}
function maxBaseSpells:load()
	self:loadVariables()
	self:loadMenu()
	self:loadCallbacks()
end

function maxBaseSpells:loadVariables()
	self.allies = {nil, nil, nil, nil}
	self.enemies = {nil, nil, nil, nil, nil}
	self.recalls = {nil, nil, nil, nil, nil}
	self.missing = {nil, nil, nil, nil, nil}

	self.enemyBase = nil
	self.enable = true

	local eCount, aCount = 0, 0
	--Load Units
	for i = 1, Game.HeroCount() do
        local unit = Game.Hero(i)
        
        if not unit.isMe then 
            if unit.isAlly then
            	aCount = aCount + 1
                self.allies[aCount] = unit
                self.allies[unit.networkID] = aCount
            else
            	eCount = eCount + 1
                self.enemies[eCount] = unit
                self.enemies[unit.networkID] = eCount
                self.recalls[eCount] = {unit = unit, start = 0, duration = 0, isRecalling = false, missing = 0}
            end
        end
    end
    --Load Enemy Base
    for i = 1, Game.ObjectCount() do
        local obj = Game.Object(i)
        
        if not obj.isAlly and obj.type == Obj_AI_SpawnPoint then 
            self.enemyBase = obj
            break
        end
	end
end

function maxBaseSpells:loadMenu()
	self.menu = MenuElement({id = "maxBaseSpells", name = "maxBaseSpells Version: " .. version, type = MENU})
	self.menu:MenuElement({id = "Enable", name = "1. Enable", value = true, callback = function(self) self.enable = self.menu.Enable:Value() end})
	self.menu:MenuElement({id = "Mode", name = "2. Cast Mode", value = 2, drop = {"Minimap Casting (legit)", "Screen Area Cast (cheater)"}})
end

function maxBaseSpells:loadCallbacks()
	Callback.Add("Tick", function() self:OnDraw() end)
	Callback.Add("ProcessRecall", function(unit, recall) self:OnRecall(unit, recall) end)
	Callback.Add("Draw", function() self:OnTick() end)
end

function maxBaseSpells:OnDraw()
	if self.enable then
	end
end

function maxBaseSpells:OnRecall(unit, recall)
	if self.enable and unit.isEnemy then
		local ID = self.enemies[unit.networkID]

		if recall.isStart then
			print(unit.charName .. " is recalling.")
			self.recalls[ID].start = timer()
			self.recalls[ID].duration = recall.totalTime * 0.001
			self.recalls[ID].isRecalling = true
		else
			print(unit.charName .. " finished recalling.")
			self.recalls[ID].isRecalling = false
		end
	end
end

function maxBaseSpells:OnTick()
	if self.enable then
		local Enemies = self.enemies

		for i = 1, #Enemies do
			local enemy = Enemies[i]

			if not enemy.visible then
				self.recalls[i].missing = timer()
			end

			local recall = self.recalls[i]

			if recall.isRecalling then
				local spellDB = supportedChampions[myHero.charName]
				local recallTime = recall.start + recall.duration - timer()

				for j = 1, #spellDB do
					local spellData = spellDB[j]
					local spellName = spellData.name
					local _spell = myHero:GetSpellData(spellData.slot)

					if _spell.name == spellName and _spell.currentCd == 0 then
						local hitTime = self:calcTravelTimeToBase(myHero, spellData)
						local timeDiff = hitTime - recallTime
						-- local moveRange = enemy.movespeed * timeDiff

						if timeDiff > 0 then --moving range?
							local health = enemy.health
							local hpReg = enemy.hpRegen
							local fountainReg = enemy.maxHealth * 0.021 -- per 0.25 seconds

							health = health + hitTime * hpReg

							if not enemy.visisble then
								local timeMissing = timer() - recall.missing
								
								health = health + timeMissing * hpReg
							end

							if timer() > 1200 then --homeguard
								local missingHealth = enemy.maxHealth - health
								fountainReg = fountainReg + missingHealth * 0.12
							end

							local fountainHeal = timeDiff * 4 * fountainReg
							local slot = spellData.slot
							local shield = 0
							local spell = slot == _Q and "Q" or slot == _W and "W" or slot == _E and "E" or "R"
							local damage = getdmg(spell, enemy)
							local collision = false

							if health + shield + fountainHeal <= damage and not collision then
								if slot == _Q then 
									slot = HK_Q
								elseif slot == _W then 
									slot = HK_W
								elseif slot == _E then 
									slot = HK_E
								elseif slot == _R then 
									slot = HK_R
								end

								local castPos = self:getCastPos()
								Control.SetCursorPos(castPos)
								Cast(slot, castPos)
							end
						end
					end
				end
			end
		end
	end
end

function maxBaseSpells:calcTravelTimeToBase(unit, data)
	local base = self.enemyBase
	local distance = unit.pos:DistanceTo(base.pos)
	local speed = data.speed
	local delay = data.delay + 0.1 -- castDelay

	if distance > data.range then return 0 end
	if speed == 0 then return delay end
	if data.maxSpeed then return (distance - speed) / data.maxSpeed + delay + 1 end

	local time = distance / speed + delay

	return time
end

function maxBaseSpells:getCastPos()
	local mode = self.menu.Mode:Value()

	if mode == 1 then --legit
		local mm = self.enemyBase.pos:ToMM()

		return Vector(mm.x, mm.y)
	else
		local cp = myHero.pos - (myHero.pos - self.enemyBase.pos):Normalized() * 300

		return cp
	end
end

function OnLoad()
	maxBaseSpells:load()
end
