--[[
		maxActivator v0.082
		
		by Maxxxel
	
	
		Changelog:
			0.01 - Creation
			0.02 - Restructured, Added Ward System
			0.03 - Added Anti Ward/Stealth
			0.04 - Added Anti CC
			0.05 - 8.2 Changes to Support Items/Ward Items
			0.06 - Fixed Anti-Stealth and Damage Modules
			0.07 - Fixed Pot onDeath, added Base Debug Drawing, increased Base Range, Added Arcane Sweeper
			0.08 - Fixed Pot Ammo, added new way of AA Detection, fixed Damage Items
			0.081 - Bugfix
			0.082 - Fixed AntiWard double Menu Entry
			0.083 - Bugfix

		To-Do:
			-Special Items
			-Summoners
			-Shield Items
--]]
local version = 0.083

local Timer = Game.Timer
local sqrt, abs = math.sqrt, math.abs
local MapID = Game.mapID
local Base = 
			MapID == TWISTED_TREELINE and myHero.team == 100 and {x=1076, y=150, z=7275} or myHero.team == 200 and {x=14350, y=151, z=7299} or
			MapID == SUMMONERS_RIFT and myHero.team == 100 and {x=419,y=182,z=438} or myHero.team == 200 and {x=14303,y=172,z=14395} or
			MapID == HOWLING_ABYSS and myHero.team == 100 and {x=971,y=-132,z=1180} or myHero.team == 200 and {x=11749,y=-131,z=11519} or
			MapID == CRYSTAL_SCAR and {x = 0, y = 0, z = 0}

local itemsIndex = {
	[3060] = {name = "Banner of Command", 			type = "spcl", id = 3060, target = "unit", effect = "Boost Minion"},
	-- [3069] = {name = "Talisman of Ascension", 		type = "spcl", id = 3069, target = "self", effect = "Speed"},
	-- [3092] = {name = "Frost Queen's Claim", 		type = "spcl", id = 3092, target = "self", effect = "Slow"},
	[3050] = {name = "Zeke's Convergence", 			type = "spcl", id = 3050, target = "bind", effect = "Boost Ally"},
	[3056] = {name = "Ohmwrecker", 					type = "spcl", id = 3056, target = "self", effect = "Stop Turrets"},
	[3800] = {name = "Righteous Glory", 			type = "spcl", id = 3800, target = "self", effect = "Speed"},
	[3512] = {name = "Zz'Rot Portal", 				type = "spcl", id = 3512, target = "spot", effect = "Portal"},
	[3142] = {name = "Youmuu's Ghostblade", 		type = "spcl", id = 3142, target = "self", effect = "Speed"},
	[3143] = {name = "Randuin's Omen", 				type = "spcl", id = 3143, target = "self", effect = "Slow"},
}

local damageItems = {
	["tia"] = {name = "Tiamat", id = 3077, range = 300},
	["hyd"] = {name = "Ravenous Hydra", id = 3074, range = 300},
	["tit"] = {name = "Titanic Hydra", id = 3748, range = 300},
	["bot"] = {name = "Blade of the Ruined King", id = 3153, range = 600},
	["bil"] = {name = "Bilgewater Cutlass", id = 3144, range = 600},
	["pro"] = {name = "Hextech Protobelt-01", id = 3152, range = 800},
	["glp"] = {name = "Hextech GLP-800", id = 3030, range = 800},
	["gun"] = {name = "Hextech Gunblade", id = 3146, range = 700}
}

local consumableItems = {
	["bor"] = {name = "Biscuit of Rejuvenation", id = 2010, type = "", buffName = "ItemMiniRegenPotion"},
	["hpp"] = {name = "Health Potion", id = 2003, type = "", buffName = "RegenerationPotion"},
	["rfp"] = {name = "Refillable Potion", id = 2031, type = "", buffName = "ItemCrystalFlask"},
	["hup"] = {name = "Hunter's Potion", id = 2032, type = "mph", buffName = "ItemCrystalFlaskJungle"},
	["crp"] = {name = "Corrupting Potion", id = 2033, type = "mph", buffName = "ItemDarkCrystalFlask"},
	["eos"] = {name = "Elixir of Sorcery", id = 2139, type = "mph", buffName = "ElixirOfSorcery"},
	["eoi"] = {name = "Elixir of Iron", id = 2138, type = "", buffName = "ElixirOfIron"}
}

local wardItems = {
	["wrt"] = {name = "Warding Totem", 		id = 3340, range = 600},
	["eof"] = {name = "Frostfang", 		id = 3098, range = 600},
	["eow"] = {name = "Remnant of the Watchers", id = 3092, range = 600},
	["frf"] = {name = "Nomad's Medallion", 		id = 3096, range = 600},
	["roa"] = {name = "Remnant of the Ascended", id = 3069, range = 600},
	["tab"] = {name = "Targon's Brace", 		id = 3097, range = 600},
	["frf"] = {name = "Remnant of the Aspect", 	id = 3401, range = 600},
	["ctw"] = {name = "Control Ward", 		id = 2055, range = 600},
	["fsg"] = {name = "Farsight Alteration", id = 3363, range = 4000}
}

local shieldItems = {
	-- ["stw"] = {name = "Stopwatch", 				id = 2420, target = "self", effect = "Stasis"},
	-- ["zhg"] = {name = "Zhonya's Hourglass", 	id = 3157, target = "self", effect = "Stasis"},
	-- ["eon"] = {name = "Edge of Night", 			id = 3814, target = "self", effect = "Spell Shield"}, to Situational
	["qss"] = {name = "Quicksilver Sash", 		id = 3140, target = "self", effect = "CC"},
	["msc"] = {name = "Mercurial Scimittar", 	id = 3139, target = "self", effect = "CC"},
	["mcr"] = {name = "Mikael's Crucible", 		id = 3222, target = "unit", range = 0650, effect = "CC"},
	-- ["lis"] = {name = "Locket of the Iron Solari", id = 3190, target = "unit", range = 0700, effect = "Shield"},
	-- ["fom"] = {name = "Face of the Mountain", 	id = 3401, target = "unit", range = 1100, effect = "Shield"},
}

local sweepModRange = {
	500, 500, 500,
	800, 800, 800,
	1100, 1100, 1100,
	1400, 1400, 1400,
	1700, 1700, 1700,
	2000, 2000, 2000
}

local sweepModRadius = {
	450, 450, 450,
	475, 475, 475,
	500, 500, 500,
	525, 525, 525,
	550, 550, 550,
	575, 575, 575
}

local oracleModRadius = {
	660, 660, 660, 660, 660, 660, 660, 660, 660, 660,
	690, 690, 690,
	720, 720, 720,
	750, 750
}

local antiWardItems = {
	["swe"] = {name = "Sweeping Lens", id = 3341, range = -1, radius = -1},
	["orc"] = {name = "Oracle Alteration", id = 3364, range = 0000, radius = -2},
	["ctw"] = {name = "Control Ward", id = 2055, range = 600, radius = 600},
	["hts"] = {name = "Arcane Sweeper", id = 3348, range = 800, radius = 375}
}

local function GetDistance(A, B)
	local A = A.pos or A
	local B = B.pos or B

	local ABX, ABZ = A.x - B.x, A.z - B.z

	return sqrt(ABX * ABX + ABZ * ABZ)
end

class 'maxActivator'

	function maxActivator:__init()
		self:__loadTables()
		self:__loadUnits()
		self:__loadMenu()
		self:__loadCallbacks()
	end

	function maxActivator:__loadMenu()
		self.menu = MenuElement({id = "maxActivator", name = "maxActivator v" .. version .. "", type = MENU})
			self.menu:MenuElement({id = "ward", name = "Ward", type = MENU})
				self.menu.ward:MenuElement({id = "_e", name = "Enable Ward", value = true})
				self.menu.ward:MenuElement({id = "_m", name = "Warding Mode", value = 1, drop = {"Auto", "Mouse Hover"}})
				self.menu.ward:MenuElement({id = "_d", name = "Draw Spots", value = true})
				self.menu.ward:MenuElement({id = "info", name = "+++ ITEMS +++", type = SPACE})
				for short, data in pairs(wardItems) do
					self.menu.ward:MenuElement({id = short, name = data.name, value = true})
				end

			self.menu:MenuElement({id = "anti", 	name = "Anti-Ward", type = MENU})
				self.menu.anti:MenuElement({id = "_e", 	name = "Enable Anti-Ward", value = true})
				self.menu.anti:MenuElement({id = "_d", 	name = "Draw Enemy Wards", value = true})
				self.menu.anti:MenuElement({id = "info", name = "+++ ITEMS +++", type = SPACE})
				for short, data in pairs(antiWardItems) do
					self.menu.anti:MenuElement({id = short, name = data.name, value = true})
				end
				for unit in pairs(self.antiWardUnits) do
					for i = 1, #self.Heroes.Enemies do
						local enemy = self.Heroes.Enemies[i]

						if enemy.charName == unit then
							if not self.enableAntiUnit then
								self.enableAntiUnit = true
								self.menu.anti:MenuElement({id = "info", name = "+++ ENEMIES +++", type = SPACE})
							end

							self.menu.anti:MenuElement({id = unit, name = "Reveal " .. unit, type = MENU})

							for short, data in pairs(antiWardItems) do
								self.menu.anti[unit]:MenuElement({id = short, name = data.name, value = true})
							end
						end
					end
				end

			self.menu:MenuElement({id = "shld", 	name = "Shield", type = MENU})
				self.menu.shld:MenuElement({id = "_e", 	name = "Enable Shield", value = true})
				for short, data in pairs(shieldItems) do
					self.menu.shld:MenuElement({id = short, name = data.name, type = MENU})
					self.menu.shld[short]:MenuElement({id = "_e", name = "Enable", value = true})

					if data.effect == "Stasis" then
						-- self.menu.shld[short]:MenuElement({id = "hp", name = "If HP will drop below (%)", value = 10, min = 0, max = 100, step = 1})
					elseif data.effect == "Shield" then
						-- self.menu.shld[short]:MenuElement({id = "hp", name = "If HP will drop below (%)", value = 10, min = 0, max = 100, step = 1})
						
						-- for i = 1, #self.Heroes.Allies do
						-- 	if i == 1 then
						-- 		self.menu.shld[short]:MenuElement({id = "info", name = "+++ ALLIES +++", type = SPACE})
						-- 	end

						-- 	local ally = self.Heroes.Allies[i]

						-- 	if ally.networkID ~= myHero.networkID then
						-- 		self.menu.shld[short]:MenuElement({id = "ahp", name = "Help " .. ally.charName .. "?", value = true})
						-- 	end
						-- end
					elseif data.effect == "CC" then
						self.menu.shld[short]:MenuElement({id = "Airborne", name = "Clear Airborne", value = true})
						self.menu.shld[short]:MenuElement({id = "Cripple", name = "Clear Cripple", value = false})
						self.menu.shld[short]:MenuElement({id = "Charm", name = "Clear Charm", value = true})
						self.menu.shld[short]:MenuElement({id = "Fear", name = "Clear Fear", value = true})
						self.menu.shld[short]:MenuElement({id = "Flee", name = "Clear Flee", value = true})
						self.menu.shld[short]:MenuElement({id = "Taunt", name = "Clear Taunt", value = true})
						self.menu.shld[short]:MenuElement({id = "Snare", name = "Clear Root/Snare", value = true})
						self.menu.shld[short]:MenuElement({id = "Polymorph", name = "Clear Polymorph", value = true})
						self.menu.shld[short]:MenuElement({id = "Silence", name = "Clear Silence", value = true})
						self.menu.shld[short]:MenuElement({id = "Sleep", name = "Clear Sleep", value = true})
						self.menu.shld[short]:MenuElement({id = "Slow", name = "Clear Slow", value = true})
						self.menu.shld[short]:MenuElement({id = "Stun", name = "Clear Stun", value = true})
						self.menu.shld[short]:MenuElement({id = "Poison", name = "Clear Poison", value = true})
						self.menu.shld[short]:MenuElement({id = "Disarm", name = "Clear Disarm", value = true})

						if short ~= "mcr" then
							self.menu.shld[short]:MenuElement({id = "Blind", name = "Clear Blind", value = true})
							self.menu.shld[short]:MenuElement({id = "Nearsight", name = "Clear Nearsight", value = true})
							self.menu.shld[short]:MenuElement({id = "Suppression", name = "Clear Suppression", value = true})
						end

						if short == "mcr" then
							for i = 1, #self.Heroes.Allies do
								if i == 1 and #self.Heroes.Allies > 1 then
									self.menu.shld[short]:MenuElement({id = "info", name = "+++ ALLIES +++", type = SPACE})
								end

								local ally = self.Heroes.Allies[i]

								if ally.networkID ~= myHero.networkID then
									self.menu.shld[short]:MenuElement({id = "help" .. ally.charName, name = "Help: " .. ally.charName .. "?", value = true})
								end
							end
						end
					end
				end

			self.menu:MenuElement({id = "damg", 	name = "Damage", type = MENU})
				self.menu.damg:MenuElement({id = "_e", 	name = "Enable Damage", value = true})
				for short, data in pairs(damageItems) do
					self.menu.damg:MenuElement({id = short, name = data.name, type = MENU})
					self.menu.damg[short]:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.damg[short]:MenuElement({id = "_c", name = "Only on Combo", value = true})
					self.menu.damg[short]:MenuElement({id = "mode", name = "Mode", value = 3, drop = {"Before Attack", "After Attack", "Always"}})
					self.menu.damg[short]:MenuElement({id = "target", name = "Target", value = 2, drop = {"Orb Target", "Near Mouse", "Near myHero"}})
				end

			self.menu:MenuElement({id = "cnsm", 	name = "Consume", type = MENU})
				self.menu.cnsm:MenuElement({id = "_e", 	name = "Enable Consume", value = true})
				for short, data in pairs(consumableItems) do
					self.menu.cnsm:MenuElement({id = short, name = data.name, type = MENU})
					self.menu.cnsm[short]:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.cnsm[short]:MenuElement({id = "min", name = "Minimum HP %", value = 50, min = 0, max = 100, step = 1})

					if data.type == "mph" then
						self.menu.cnsm[short]:MenuElement({id = "swi", name = "---------------->", value = 1, drop = {"Ignore Mana", "AND", "OR"}})
						self.menu.cnsm[short]:MenuElement({id = "man", name = "Minimum MP %", value = 50, min = 0, max = 100, step = 1})
					end
				end

			self.menu:MenuElement({id = "spcl", 	name = "Special", type = MENU})
				-- self.menu.spcl:MenuElement({id = "_e", 	name = "Enable Special", value = true})
				-- {name = "Banner of Command", 			type = "spcl", id = 3060, target = "unit", effect = "Boost Minion"},
				-- {name = "Talisman of Ascension", 		type = "spcl", id = 3069, target = "self", effect = "Speed"},
				-- {name = "Frost Queen's Claim", 		type = "spcl", id = 3092, target = "self", effect = "Slow"},
				-- {name = "Zeke's Convergence", 			type = "spcl", id = 3050, target = "bind", effect = "Boost Ally"},
				-- {name = "Ohmwrecker", 					type = "spcl", id = 3056, target = "self", effect = "Stop Turrets"},
				-- {name = "Righteous Glory", 			type = "spcl", id = 3800, target = "self", effect = "Speed"},
				-- {name = "Zz'Rot Portal", 				type = "spcl", id = 3512, target = "spot", effect = "Portal"},
				-- {name = "Youmuu's Ghostblade", 		type = "spcl", id = 3142, target = "self", effect = "Speed"},
				-- {name = "Randuin's Omen", 				type = "spcl", id = 3143, target = "self", effect = "Slow"},

			self.menu:MenuElement({id = "summs", 	name = "Summoner", type = MENU})
				-- self.menu.summs:MenuElement({id = "_e", 	name = "Enable Summoner", value = true})
				-- Heal
				-- Barrier
				-- Exhaust
				-- Cleanse
				-- Ignite
				-- Smite

			self.menu:MenuElement({id = "_se", 		name = "Settings", type = MENU})
				self.menu._se:MenuElement({id = "_e", 	name = "Global Enable", value = true})
				self.menu._se:MenuElement({id = "_b", 	name = "DebugBase", value = false})
				self.menu._se:MenuElement({id = "_r", 	name = "No Pots Range", value = 1000, min = 0, max = 2000, step = 100})
	end

	function maxActivator:__loadCallbacks()
		Callback.Add("Tick", function() self:__OnTick() end)
		Callback.Add("Draw", function() self:__OnDraw() end)
	end

	function maxActivator:__loadTables()
		self.itemAmmoStorage = {
			[2031] = {maxStorage = 2, savedStorage = 0},
			[2032] = {maxStorage = 5, savedStorage = 0},
			[2033] = {maxStorage = 3, savedStorage = 0}
		}

		self.wards = {
			["preSpots"] = {
				{x = 10383, y = 50, z = 3081},
				{x = 11882, y = -70, z = 4121},
				{x = 9703, y = -32, z = 6338},
				{x = 8618, y = 52, z = 4768},
				{x = 5206, y = -46, z = 8511},
				{x = 3148, y = -66, z = 10814},
				{x = 4450, y = 56, z = 11803},
				{x = 6287, y = 54, z = 10150},
				{x = 8268, y = 49, z = 10225},
				{x = 11590, y = 51, z = 7115},
				{x = 10540, y = -62, z = 5117},
				{x = 4421, y = -67, z = 9703},
				{x = 2293, y = 52, z = 9723},
				{x = 7044, y = 54, z = 11352}
			}
		}

		self.antiWardUnits = {
			["Akali"] = _W,
			["Talon"] = _R,
			["Twitch"] = _Q,
			["MonkeyKing"] = _W,
			["Shaco"] = _Q,
			["KhaZix"] = _R,
			["Vayne"] = _Q
		}

		self.unitShields = {
			["Alistar"] = {
				{type = Active, spell = _E, range = 575, shieldType = "heal"},
            	{type = Active, spell = _R, shieldType = "self"}
			},
            ["Bard"] = {
            	{type = Skillshot, spell = _W, range = 800, shieldType = "heal"},
            	{type = Skillshot, spell = _R, range = 900, shieldType = "protect"}
			},
            ["Braum"] = {
            	{type = Targeted, spell = _W, range = 650, shieldType = "shield"},
            	{type = Skillshot, spell = _E, range = 600, shieldType = "wall"}
            },
            ["Diana"] = {type = Active, spell = _W, shieldType = "self"},
            ["DrMundo"] = {type = Active, spell = _R, shieldType = "self"},
            ["Ekko"] = {type = Active, spell = _R, shieldType = "self"},
            ["Evelynn"] = {type = Skillshot, spell = _R, range = 650, shieldType = "enemy"},
            ["Fiora"] = {type = Skillshot, spell = _W, range = 400, shieldType = "self"},
            ["Fizz"] = {type = Skillshot, spell = _E, range = 600, shieldType = "self"},
            ["Galio"] = {type = Targeted, spell = _W, range = 800, shieldType = "shield"},
            ["Gangplank"] = {type = Active, spell = _W, shieldType = "self"},
            ["Garen"] = {type = Active, spell = _W, shieldType = "self"},
            ["Janna"] = {type = Targeted, spell = _E, range = 800, shieldType = "shield"},
            ["JarvanIV"] = {type = Active, spell = _W, shieldType = "self"},
            ["Karma"] = {type = Targeted, spell = _E, range = 675, shieldType = "shield"},
            ["Kayle"] = {
            	{type = Targeted, spell = _W, range = 900, shieldType = "heal"},
            	{type = Targeted, spell = _R, range = 900, shieldType = "protect"}
			},
            ["Kindred"] = {type = Active, spell = _R, range = 500, shieldType = "protect"},
            ["LeeSin"] = {type = Targeted, spell = _W, range = 700, shieldType = "shield"},
            ["Leona"] = {type = Active, spell = _W, shieldType = "self"},
            ["Lissandra"] = {type = Targeted, spell = _R, range = 600, shieldType = "self"},
            ["Lulu"] = {
            	{type = Targeted, spell = _E, range = 650, shieldType = "shield"},
            	{type = Targeted, spell = _R, range = 650, shieldType = "protect"}
            },
            ["Lux"] = {type = Skillshot, spell = _W, range = 1075, shieldType = "shield"},
            ["Morgana"] = {type = Targeted, spell = _E, range = 800, shieldType = "shield"},
            ["Nami"] = {type = Targeted, spell = _W, range = 725, shieldType = "heal"},
            ["Nasus"] = {type = Active, spell = _R, shieldType = "self"},
            ["Nautilus"] = {type = Active, spell = _W, shieldType = "self"},
            ["Nidalee"] = {type = Targeted, spell = _E, range = 600, shieldType = "heal"},
            ["Nocturne"] = {type = Active, spell = _W, shieldType = SpellBlock},
            ["Orianna"] = {type = Targeted, spell = _E, range = 1100, shieldType = "shield"},
            ["Renekton"] = {type = Active, spell = _R, shieldType = "self"},
            ["Rengar"] = {type = Active, spell = _W, shieldType = "self"},
            ["Riven"] = {type = Skillshot, spell = _E, range = 325, shieldType = "self"},
            ["Rumble"] = {type = Active, spell = _W, shieldType = "self"},
            ["Sion"] = {type = Active, spell = _W, shieldType = "self"},
            ["Sivir"] = {type = Active, spell = _E, shieldType = SpellBlock},
            ["Skarner"] = {type = Active, spell = _W, shieldType = "self"},
            ["Sona"] = {type = Active, spell = _W, range = 1000, shieldType = "heal"},
            ["Soraka"] = {
            	{type = Targeted, spell = _W, range = 550, shieldType = "heal"},
            	{type = Active, spell = _R, shieldType = "protect"}
            },
            ["Shen"] = {type = Targeted, spell = _R, shieldType = "protect"},
            ["TahmKench"] = {
            	{type = Targeted, spell = _W, range = 250, shieldType = "shield"},
            	{type = Active, spell = _E, shieldType = "self"}
            },
            ["Taric"] = {
            	{type = Active, spell = _Q, range = 350, shieldType = "heal"},
            	{type = Targeted, spell = _W, range = 800, shieldType = "shield"},
            	{type = Active, spell = _R, range = 400, shieldType = "protect"}
            },
            ["Thresh"] = {type = Active, spell = _W, range = 950, shieldType = "shield"},
            ["Tryndamere"] = {type = Active, spell = _R, shieldType = "self"},
            ["Urgot"] = {type = Active, spell = _W, shieldType = "self"},
            ["Viktor"] = {type = Targeted, spell = _Q, range = 600, shieldType = "enemy"},
            ["Yasuo"] = {type = Skillshot, spell = _W, range = 400, shieldType = "wall"},
			["Zilean"] = {type = Targeted, spell = _R, range = 900, shieldType = "protect"}
		}

		self.itemKey = {
		}

		self.ccNames = {
			["Cripple"] = 3,
			["Stun"] = 5,
			["Silence"] = 7,
			["Taunt"] = 8,
			["Polymorph"] = 9,
			["Slow"] = 10,
			["Snare"] = 11,
			["Sleep"] = 18,
			["Nearsight"] = 19,
			["Fear"] = 21,
			["Charm"] = 22,
			["Poison"] = 23,
			["Suppression"] = 24,
			["Blind"] = 25,
			-- ["Shred"] = 27,
			["Flee"] = 28,
			-- ["Knockup"] = 29,
			["Airborne"] = 30,
			["Disarm"] = 31
		}
		
		self.lastAttack = 0
		self.damgTarget = {}
		self.Heroes = {Enemies = {}, Allies = {}}
	end

	function maxActivator:__loadUnits()
		for i = 1, Game.HeroCount() do
			local unit = Game.Hero(i)

			if unit.team ~= myHero.team then
				self.Heroes.Enemies[#self.Heroes.Enemies + 1] = unit
			else
				self.Heroes.Allies[#self.Heroes.Allies + 1] = unit
			end
		end
	end

	function maxActivator:__OnTick()
		if #self.itemKey == 0 then
			self.itemKey = {
				HK_ITEM_1,
				HK_ITEM_2,
				HK_ITEM_3,
				HK_ITEM_4,
				HK_ITEM_5,
				HK_ITEM_6,
				HK_ITEM_7
			}
		end

		-- for i = 6, 12 do
			-- local itemID = myHero:GetItemData(i)

			-- if itemID.itemID ~= 0 then 
				
			-- end
			-- local item = myHero:GetSpellData(i)
			-- if item.name ~= "" then
			-- 	print(item)
			-- 	print("\n")
			-- 	print("\n")
			-- 	print("\n")
			-- 	print("\n")
			-- 	print("\n")
			-- end
		-- end

		-- for i = 0, 63 do
		-- 	local buff = myHero:GetBuff(i)

		-- 	-- if buff.count > 0 and buff.name ~= "" and buff.name == "frostquestdisplay" then print((buff.expireTime - buff.duration) / 10 * 2) print("\n") print("\n") print("\n") print("\n") print("\n") end
		-- end

		if self.menu._se._e:Value() and not myHero.dead then
			--Ward Stuff
			if self.menu.ward._e:Value() then
				self:doWardLogic()
			end
			--Damage Stuff
			if self.menu.damg._e:Value() then
				self:AAState()
				self:doDamageLogic()
			end
			--Consumables Stuff
			if self.menu.cnsm._e:Value() then
				self:doConsumLogic()
			end
			--Anti Ward Stuff
			if self.menu.anti._e:Value() then
				self:doAntiLogic()
			end
			--Shield Stuff
			if self.menu.shld._e:Value() then
				self:doShieldLogic()
			end
		end
	end

	function maxActivator:__OnDraw()
		if self.menu.ward._d:Value() then
			self:doWardDrawings()
		end

		if self.menu.anti._d:Value() then
			self:doAntiDrawings()
		end
		
		if self.menu._se._b:Value() then
			Draw.Circle(Vector(Base), self.menu._se._r:Value())
		end
	end

	function maxActivator:__getSlot(id)
		for i = 6, 12 do
			if myHero:GetItemData(i).itemID == id then
				return i
			end
		end

		return 0
	end

	function maxActivator:itemReady(id, ward, pot)
		local slot = self:__getSlot(id)

		if slot then
			local cd = myHero:GetSpellData(slot).currentCd == 0

			if cd then
				if ward then
					local wardNum = myHero:GetSpellData(slot).ammo

					return wardNum ~= 0 and wardNum < 10
				elseif pot then
					if not self.itemAmmoStorage[id] then return true end
					if self.itemAmmoStorage[id].savedStorage == 0 then
						self.itemAmmoStorage[id].savedStorage = myHero:GetItemData(slot).ammo
					end

					local potNum = myHero:GetItemData(slot).ammo
					local saved = self.itemAmmoStorage[id].savedStorage
					local num = abs(saved - potNum - self.itemAmmoStorage[id].maxStorage) 

					return num > 0 and num <= 5
				else
					return true
				end
			end
		end

		return false
	end

	function maxActivator:AAState()
		if not self.AALoaded then
			self.state = 0
			self.AAHitIn = 0
			self.NextAAIn = 0
			self.ReadyIn = 100

			self.AALoaded = true
		end

		local as = myHero.activeSpell
		local ad = myHero.attackData

		if as.valid and not as.isChanneling then
			if self.state == 0 then
				self.NextAAIn = Timer() + as.animation
				self.AAHitIn = as.windup + Timer() + ad.attackDelayOffsetPercent
				self.state = 1
			elseif self.AAHitIn - Timer() < 0 and self.state == 1 then
				self.state = 2

				DelayAction(function()
					self.state = 3

					DelayAction(function()
						self.state = 0
					end, self.NextAAIn - Timer() - 0.01)
				end, 0.01)
			end
		elseif self.state == 1 then
			self.state = 3

			DelayAction(function()
				self.state = 0
			end, Timer() - self.AAHitIn)
		end
	end

	function maxActivator:castItem(unit, id, range)
		if unit == myHero or GetDistance(myHero, unit) <= range then
			local keyIndex = self:__getSlot(id) - 5
			local key = self.itemKey[keyIndex]

			if key then
				if unit ~= myHero then
					Control.CastSpell(key, unit.pos or unit)
				else
					Control.CastSpell(key, myHero)
				end
			end
		end
	end

	function maxActivator:getPercentHP(unit)
		return unit.health * 100 / unit.maxHealth
	end

	function maxActivator:getPercentMP(unit)
		return unit.mana * 100 / unit.maxMana
	end

	function maxActivator:checkBuff(unit, name, _type)
		for i = 0, 63 do
			local buff = unit:GetBuff(i)

			if buff.count > 0 and buff.name ~= "" and (buff.name == name or _type and buff.type == _type) then return true end
		end

		return false
	end
--==================== WARD MODULE ====================--
	function maxActivator:doWardLogic()
		local mode = self.menu.ward._m:Value()
		local readyWard = nil

		for short, data in pairs(wardItems) do
			if self:itemReady(data.id, true) and self.menu.ward[short]:Value() then
				readyWard = data
			end
		end

		if readyWard then
			for i = 1, #self.wards.preSpots do
				local ward = Vector(self.wards.preSpots[i])

				if ward:To2D().onScreen and GetDistance(ward, (mode == 1 and myHero or mousePos)) <= (mode == 1 and readyWard.range or 100) then
					local c, d = self:getNearesetWardToPos(ward)

					if not (c and d < 600) and not (self.lastWard and Timer() - self.lastWard < 1) then
						self.lastWard = Timer()
						self:castItem(ward, readyWard.id, readyWard.range)
					end
				end
			end
		end
	end

	function maxActivator:doWardDrawings()
		for i = 1, #self.wards.preSpots do
			local wardSpot = Vector(self.wards.preSpots[i]):To2D()

			if wardSpot.onScreen then
				Draw.Text("Ward Spot", 10, wardSpot.x, wardSpot.y)
			end
		end
	end

	function maxActivator:getNearesetWardToPos(pos)
		local closest, distance = nil, 999999

		for i = 1, Game.WardCount() do
			local ward = Game.Ward(i)

			if ward.team == myHero.team then
				local d = GetDistance(ward, pos) 

				if d < distance then
					distance = d
					closest = ward
				end
			end
		end

		return closest, distance
	end
--=====================================================--
--==================== ANTI WARD MODULE ====================--
	function maxActivator:doAntiLogic()
		for i = 1, Game.WardCount() do
			local ward = Game.Ward(i)

			if ward.health ~= 0 and ward.team ~= myHero.team and not ward.visible then
				for short, data in pairs(antiWardItems) do
					if self.menu.anti[short]:Value() and self:itemReady(data.id) then
						local d = ward.distance
						local ra, rd = data.range, data.radius
						ra = ra == -1 and sweepModRange[myHero.levelData.lvl] or ra
						rd = rd == -1 and sweepModRadius[myHero.levelData.lv] or rd == -2 and oracleModRadius[myHero.levelData.lvl] or rd

						if d < ra + rd then
							local castPos = myHero.pos - (myHero.pos - ward.pos):Normalized() * (d)

							self:castItem(castPos, data.id, ra + rd)
						end
					end
				end
			end
		end

		if self.enableAntiUnit then
			for i = 1, #self.Heroes.Enemies do
				local enemy = self.Heroes.Enemies[i]
				local db = self.antiWardUnits[enemy.charName]

				if db then
					local _ = enemy:GetSpellData(db)
					local casted = _.castTime - Timer() > 1

					if enemy.activeSpellSlot == db and enemy.activeSpell.valid or casted then
						for short, data in pairs(antiWardItems) do
							if self.menu.anti[enemy.charName][short]:Value() and self:itemReady(data.id) then
								local d = enemy.distance
								local ra, rd = data.range, data.radius

								ra = ra == -1 and sweepModRange[myHero.levelData.lvl] or ra
								rd = rd == -1 and sweepModRadius[myHero.levelData.lv] or rd == -2 and oracleModRadius[myHero.levelData.lvl] or rd

								if d < ra + rd then
									local castPos = myHero.pos - (myHero.pos - enemy.pos):Normalized() * (d - ra)

									self:castItem(castPos, data.id, ra + rd)
								end
							end
						end
					end
				end
			end
		end
	end

	function maxActivator:doAntiDrawings()
		for i = 1, Game.WardCount() do
			local ward = Game.Ward(i)

			if ward.health ~= 0 and ward.team ~= myHero.team then
				Draw.Text("Enemy Ward", 10, ward.pos2D.x, ward.pos2D.y, Draw.Color(0xffff0000))
			end
		end
	end
--==========================================================--
--==================== SHIELD MODULE ====================--
	function maxActivator:doShieldLogic()
		local shldMenu = self.menu.shld
		local qssMenu, mscMenu, mcrMenu = shldMenu["qss"], shldMenu["msc"], shldMenu["mcr"]

		if qssMenu._e:Value() or mscMenu._e:Value() or mcrMenu._e:Value() then --Anti CC
			if self:itemReady(3140) then
				for ccName, ccType in pairs(self.ccNames) do
					if qssMenu[ccName] and qssMenu[ccName]:Value() and self:checkBuff(myHero, "", ccType) then
						self:castItem(myHero, 3140)
					end
				end
			elseif self:itemReady(3139) then
				for ccName, ccType in pairs(self.ccNames) do
					if mscMenu[ccName] and mscMenu[ccName]:Value() and self:checkBuff(myHero, "", ccType) then
						self:castItem(myHero, 3139)
					end
				end
			elseif self:itemReady(3222) then
				for i = 1, #self.Heroes.Allies do
					local ally = self.Heroes.Allies[i]

					if ally.networkID ~= myHero.networkID and mcrMenu["help" .. ally.charName]:Value() then
						for ccName, ccType in pairs(self.ccNames) do
							if mcrMenu[ccName] and mcrMenu[ccName]:Value() and self:checkBuff(ally, "", ccType) then
								self:castItem(ally, 3222, 650)
							end
						end
					end
				end

				for ccName, ccType in pairs(self.ccNames) do
					if mcrMenu[ccName] and mcrMenu[ccName]:Value() and self:checkBuff(myHero, "", ccType) then
						self:castItem(myHero, 3222)
					end
				end
			end
		end
	end
--=======================================================--
--==================== DAMAGE MODULE ====================--
	function maxActivator:doDamageLogic()
		local damgMenu = self.menu.damg
		local combo = self:isCombo()

		for short, data in pairs(damageItems) do
			local target = self:itemReady(data.id) and damgMenu[short]._e:Value() and not (damgMenu[short]._c:Value() and not combo) and self:getDamgMode(damgMenu[short].mode:Value()) and self:getDamgTarget(damgMenu[short].target:Value())

			if target then
				self:castItem(target, data.id, data.range)
			end
		end
	end

	function maxActivator:getDamgTarget(mode)
		local target = nil
		--Orb Target, Near Mouse, Near myHero
		if mode == 1 then
			target = 
				_G.EOWLoaded and _G.EOW:GetTarget() or 
				_G.SDK and _G.SDK.Orbwalker:GetTarget() or 
				_G.GOS and _G.GOS:GetTarget()
		else
			local nearest, range = nil, 99999

			for i = 1, #self.Heroes.Enemies do
				local enemy = self.Heroes.Enemies[i]

				if mode == 2 then
					local d = GetDistance(enemy, mousePos)

					if d < range then
						nearest, range = enemy, d
					end
				else
					if enemy.distance < range then
						nearest, range = enemy, enemy.distance
					end
				end
			end

			target = nearest
		end

		return target and not target.dead and target.health > 0 and target.valid and target.isTargetable and target
	end

	function maxActivator:getDamgMode(mode)
		if mode == 3 then return true end

		local state = false
		local Access = self.state

		if mode == 1 then
			state = Access == 0
		elseif mode == 2 then
			state = Access == 2 or Access == 3
		else
			state = true
		end

		return state
	end

	function maxActivator:isCombo()
		local mode = 
			_G.EOWLoaded and _G.EOW:Mode() or
			_G.SDK and (_G.SDK.Orbwalker.Modes[0] and "Combo" or _G.SDK.Orbwalker.Modes[1] and "Harass" or _G.SDK.Orbwalker.Modes[4] and "LastHit" or _G.SDK.Orbwalker.Modes[2] and "LaneClear" or "") or
			_G.GOS and _G.GOS:GetMode() or ""

		return mode == "Combo"
	end
--=======================================================--
--==================== CONSUMABLE MODULE ====================--
	function maxActivator:doConsumLogic()
		if GetDistance(myHero, Base) > self.menu._se._r:Value() then
			local cnsmMenu = self.menu.cnsm

			for short, data in pairs(consumableItems) do
				if cnsmMenu[short]._e:Value() then
					local ready = self:itemReady(data.id, false, true)

					if ready and not self:checkBuff(myHero, data.buffName) then
						if data.type == "mph" then
							local A = self:getPercentHP(myHero) <= cnsmMenu[short].min:Value()
							local B = cnsmMenu[short].swi:Value()
							local C = self:getPercentMP(myHero) <= cnsmMenu[short].man:Value()

							if (B == 1 and A) or (B == 2 and A and C) or (B == 3 and (A or C)) then
								self:castItem(myHero, data.id)
							end
						elseif self:getPercentHP(myHero) <= cnsmMenu[short].min:Value() then
							self:castItem(myHero, data.id)
						end
					end
				end
			end
		end
	end
--===========================================================--
--==================== SPECIAL MODULE ====================--
--========================================================--
--==================== SUMMONER MODULE ====================--
--=========================================================--

maxActivator()
print("maxActivator v" .. version .. " loaded.")
