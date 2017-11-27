--[[
		maxActivator v0.01
		
		by Maxxxel
	

	Warding Logic

		-premade Points with hover effect
		-remember last 5 warding spots
		-dis/enable auto logic

	Anti-Invisible Logic

		-scan premade Points
		-remember enemy warding spots
		-dis/enable auto logic

	Shield Logic

		-protect self and allys
		-if under % HP
--]]
local version = 0.01

local Timer = Game.Timer
local sqrt = math.sqrt
local MapID = Game.mapID
local Base = 
			MapID == TWISTED_TREELINE and myHero.team == 100 and {x=1076, y=150, z=7275} or myHero.team == 200 and {x=14350, y=151, z=7299} or
			MapID == SUMMONERS_RIFT and myHero.team == 100 and {x=419,y=182,z=438} or myHero.team == 200 and {x=14303,y=172,z=14395} or
			MapID == HOWLING_ABYSS and myHero.team == 100 and {x=971,y=-132,z=1180} or myHero.team == 200 and {x=11749,y=-131,z=11519} or
			MapID == CRYSTAL_SCAR and {x = 0, y = 0, z = 0}

local itemsIndex = {
	[3340] = {name = "Warding Totem", 				type = "ward", id = 3340, range = 600},
	[2049] = {name = "Sightstone", 					type = "ward", id = 2049, range = 600},
	[0000] = {name = "Tracker's Knife", 			type = "ward", id = 0000, range = 600},
	[2045] = {name = "Ruby Sightstone", 			type = "ward", id = 2045, range = 600},
	[2302] = {name = "Eye of the Oasis", 			type = "ward", id = 2302, range = 600},
	[2301] = {name = "Eye of the Watchers", 		type = "ward", id = 2301, range = 600},
	[2303] = {name = "Eye of the Equinox", 			type = "ward", id = 2303, range = 600},
	[2055] = {name = "Control Ward", 				type = "ward", id = 2055, range = 600},
	[3363] = {name = "Farsight Alteration", 		type = "ward", id = 3363, range = 4000},
	[3341] = {name = "Sweeping Lens",				type = "anti", id = 3341, range = 1700, radius = 550},
	[3364] = {name = "Oracle Alteration", 			type = "anti", id = 3364, range = 0000, radius = 720},
	[2420] = {name = "Stopwatch", 					type = "shld", id = 2420, target = "self", effect = "Stasis"},
	[3157] = {name = "Zhonya's Hourglass", 			type = "shld", id = 3157, target = "self", effect = "Stasis"},
	[3814] = {name = "Edge of Night", 				type = "shld", id = 3814, target = "self", effect = "Spell Shield"},
	[3140] = {name = "Quicksilver Sash", 			type = "shld", id = 3140, target = "self", effect = "CC"},
	[3139] = {name = "Mercurial Scimittar", 		type = "shld", id = 3139, target = "self", effect = "CC"},
	[3222] = {name = "Mikael's Crucible", 			type = "shld", id = 3222, target = "unit", range = 0650, effect = "CC"},
	[3190] = {name = "Locket of the Iron Solari", 	type = "shld", id = 3190, target = "unit", range = 0700, effect = "Shield"},
	[3401] = {name = "Face of the Mountain", 		type = "shld", id = 3401, target = "unit", range = 1100, effect = "Shield"},
	[3077] = {name = "Tiamat", 						type = "damg", id = 3077, target = "self", range = 300},
	[3144] = {name = "Bilgewater Cutlass", 			type = "damg", id = 3144, target = "unit", range = 0600, effect = "Slow"},
	[3152] = {name = "Hextech Protobelt-01", 		type = "damg", id = 3152, target = "unit", range = 0800},
	[3030] = {name = "Hextech GLP-800", 			type = "damg", id = 3030, target = "unit", range = 0800},
	[3146] = {name = "Hextech Gunblade", 			type = "damg", id = 3146, target = "unit", range = 0700, effect = "Slow"},
	[3153] = {name = "Blade of the Ruined King", 	type = "damg", id = 3153, target = "unit", range = 0600, effect = "Slow"},
	[3074] = {name = "Ravenous Hydra", 				type = "damg", id = 3074, target = "self", range = 300},
	[3748] = {name = "Titanic Hydra", 				type = "damg", id = 3748, target = "self", range = 300},
	[2003] = {name = "Health Potion", 				type = "cnsm", id = 2003, effect = "life"},
	[2031] = {name = "Refillable Potion", 			type = "cnsm", id = 2031, effect = "life"},
	[2010] = {name = "Biscuit of Rejuvenation", 	type = "cnsm", id = 2010, effect = "life"},
	[2032] = {name = "Hunter's Potion", 			type = "cnsm", id = 2032, effect = "both"},
	[2033] = {name = "Corrupting Potion", 			type = "cnsm", id = 2033, effect = "both", active = "damage"},
	[2139] = {name = "Elixir of Sorcery", 			type = "cnsm", id = 2139, effect = "both", active = "damage"},
	[2140] = {name = "Elixir of Wrath", 			type = "cnsm", id = 2140, effect = "none", active = "damage"},
	[2138] = {name = "Elixir of Iron", 				type = "cnsm", id = 2138, effect = "life", active = "defensive"},
	[3060] = {name = "Banner of Command", 			type = "spcl", id = 3060, target = "unit", effect = "Boost Minion"},
	[3069] = {name = "Talisman of Ascension", 		type = "spcl", id = 3069, target = "self", effect = "Speed"},
	[3092] = {name = "Frost Queen's Claim", 		type = "spcl", id = 3092, target = "self", effect = "Slow"},
	[3050] = {name = "Zeke's Convergence", 			type = "spcl", id = 3050, target = "bind", effect = "Boost Ally"},
	[3056] = {name = "Ohmwrecker", 					type = "spcl", id = 3056, target = "self", effect = "Stop Turrets"},
	[3800] = {name = "Righteous Glory", 			type = "spcl", id = 3800, target = "self", effect = "Speed"},
	[3512] = {name = "Zz'Rot Portal", 				type = "spcl", id = 3512, target = "spot", effect = "Portal"},
	[3142] = {name = "Youmuu's Ghostblade", 		type = "spcl", id = 3142, target = "self", effect = "Speed"},
	[3143] = {name = "Randuin's Omen", 				type = "spcl", id = 3143, target = "self", effect = "Slow"},
}

local function GetDistance(A, B)
	local A = A.pos or A
	local B = B.pos or B

	local ABX, ABZ = A.x - B.x, A.z - B.z

	return sqrt(ABX * ABX + ABZ * ABZ)
end

class 'maxActivator'

	function maxActivator:__init()
		self:__loadMenu()
		self:__loadCallbacks()
		self:__loadTables()
		self:__loadUnits()
	end

	function maxActivator:__loadMenu()
		self.menu = MenuElement({id = "maxActivator", name = "maxActivator v" .. version .. "", type = MENU})
			self.menu:MenuElement({id = "ward", name = "Ward", type = MENU})
				self.menu.ward:MenuElement({id = "_e", name = "Enable Ward", value = true})
				self.menu.ward:MenuElement({id = "_m", name = "Warding Mode", value = 1, drop = {"Auto", "Hover"}})
				self.menu.ward:MenuElement({id = "_d", name = "Draw Spots", value = true})

			self.menu:MenuElement({id = "anti", 	name = "Anti-Ward", type = MENU})
				self.menu.anti:MenuElement({id = "_e", 	name = "Enable Anti-Ward", value = true})

			self.menu:MenuElement({id = "shld", 	name = "Shield", type = MENU})
				self.menu.shld:MenuElement({id = "_e", 	name = "Enable Shield", value = true})
				-- "Stopwatch", 					type = "shld", id = 2420, target = "self", effect = "Stasis"},
				-- "Zhonya's Hourglass", 			type = "shld", id = 3157, target = "self", effect = "Stasis"},
				-- "Edge of Night", 				type = "shld", id = 3814, target = "self", effect = "Spell Shield"},
				-- "Quicksilver Sash", 			type = "shld", id = 3140, target = "self", effect = "CC"},
				-- "Mercurial Scimittar", 		type = "shld", id = 3139, target = "self", effect = "CC"},
				-- "Mikael's Crucible", 			type = "shld", id = 3222, target = "unit", range = 0650, effect = "CC"},
				-- "Locket of the Iron Solari", 	type = "shld", id = 3190, target = "unit", range = 0700, effect = "Shield"},
				-- "Face of the Mountain", 		type = "shld", id = 3401, target = "unit", range = 1100, effect = "Shield"},
				-- Seraph's Embrace

			self.menu:MenuElement({id = "damg", 	name = "Damage", type = MENU})
				self.menu.damg:MenuElement({id = "_e", 	name = "Enable Damage", value = true})
				self.menu.damg:MenuElement({id = "tia", name = "Tiamat", type = MENU})
					self.menu.damg.tia:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.damg.tia:MenuElement({id = "_c", name = "Only on Combo", value = true})
					self.menu.damg.tia:MenuElement({id = "mode", name = "Mode", value = 3, drop = {"Before Attack", "After Attack", "Always"}})
					self.menu.damg.tia:MenuElement({id = "target", name = "Target", value = 2, drop = {"Orb Target", "Near Mouse", "Near myHero"}})
				self.menu.damg:MenuElement({id = "hyd", name = "Ravenous Hydra", type = MENU})
					self.menu.damg.hyd:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.damg.hyd:MenuElement({id = "_c", name = "Only on Combo", value = true})
					self.menu.damg.hyd:MenuElement({id = "mode", name = "Mode", value = 3, drop = {"Before Attack", "After Attack", "Always"}})
					self.menu.damg.hyd:MenuElement({id = "target", name = "Target", value = 2, drop = {"Orb Target", "Near Mouse", "Near myHero"}})
				self.menu.damg:MenuElement({id = "tit", name = "Titanic Hydra", type = MENU})
					self.menu.damg.tit:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.damg.tit:MenuElement({id = "_c", name = "Only on Combo", value = true})
					self.menu.damg.tit:MenuElement({id = "mode", name = "Mode", value = 3, drop = {"Before Attack", "After Attack", "Always"}})
					self.menu.damg.tit:MenuElement({id = "target", name = "Target", value = 2, drop = {"Orb Target", "Near Mouse", "Near myHero"}})
				self.menu.damg:MenuElement({id = "bot", name = "Blade of the Ruined King", type = MENU})
					self.menu.damg.bot:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.damg.bot:MenuElement({id = "_c", name = "Only on Combo", value = true})
					self.menu.damg.bot:MenuElement({id = "mode", name = "Mode", value = 3, drop = {"Before Attack", "After Attack", "Always"}})
					self.menu.damg.bot:MenuElement({id = "target", name = "Target", value = 2, drop = {"Orb Target", "Near Mouse", "Near myHero"}})
				self.menu.damg:MenuElement({id = "bil", name = "Bilgewater Cutlass", type = MENU})
					self.menu.damg.bil:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.damg.bil:MenuElement({id = "_c", name = "Only on Combo", value = true})
					self.menu.damg.bil:MenuElement({id = "mode", name = "Mode", value = 3, drop = {"Before Attack", "After Attack", "Always"}})
					self.menu.damg.bil:MenuElement({id = "target", name = "Target", value = 2, drop = {"Orb Target", "Near Mouse", "Near myHero"}})
				self.menu.damg:MenuElement({id = "pro", name = "Hextech Protobelt-01", type = MENU})
					self.menu.damg.pro:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.damg.pro:MenuElement({id = "_c", name = "Only on Combo", value = true})
					self.menu.damg.pro:MenuElement({id = "mode", name = "Mode", value = 3, drop = {"Before Attack", "After Attack", "Always"}})
					self.menu.damg.pro:MenuElement({id = "target", name = "Target", value = 2, drop = {"Orb Target", "Near Mouse", "Near myHero"}})
				self.menu.damg:MenuElement({id = "glp", name = "Hextech GLP-800", type = MENU})
					self.menu.damg.glp:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.damg.glp:MenuElement({id = "_c", name = "Only on Combo", value = true})
					self.menu.damg.glp:MenuElement({id = "mode", name = "Mode", value = 3, drop = {"Before Attack", "After Attack", "Always"}})
					self.menu.damg.glp:MenuElement({id = "target", name = "Target", value = 2, drop = {"Orb Target", "Near Mouse", "Near myHero"}})
				self.menu.damg:MenuElement({id = "gun", name = "Hextech Gunblade", type = MENU})
					self.menu.damg.gun:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.damg.gun:MenuElement({id = "_c", name = "Only on Combo", value = true})
					self.menu.damg.gun:MenuElement({id = "mode", name = "Mode", value = 3, drop = {"Before Attack", "After Attack", "Always"}})
					self.menu.damg.gun:MenuElement({id = "target", name = "Target", value = 2, drop = {"Orb Target", "Near Mouse", "Near myHero"}})

			self.menu:MenuElement({id = "cnsm", 	name = "Consume", type = MENU})
				self.menu.cnsm:MenuElement({id = "_e", 	name = "Enable Consume", value = true})
				self.menu.cnsm:MenuElement({id = "bor", name = "Biscuit of Rejuvenation", type = MENU})
					self.menu.cnsm.bor:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.cnsm.bor:MenuElement({id = "min", name = "Minimum HP %", value = 50, min = 0, max = 100, step = 1})
				self.menu.cnsm:MenuElement({id = "hpp", name = "Health Potion", type = MENU})
					self.menu.cnsm.hpp:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.cnsm.hpp:MenuElement({id = "min", name = "Minimum HP %", value = 50, min = 0, max = 100, step = 1})
				self.menu.cnsm:MenuElement({id = "rfp", name = "Refillable Potion", type = MENU})
					self.menu.cnsm.rfp:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.cnsm.rfp:MenuElement({id = "min", name = "Minimum HP %", value = 50, min = 0, max = 100, step = 1})
				self.menu.cnsm:MenuElement({id = "hup", name = "Hunter's Potion", type = MENU})
					self.menu.cnsm.hup:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.cnsm.hup:MenuElement({id = "min", name = "Minimum HP %", value = 50, min = 0, max = 100, step = 1})
					self.menu.cnsm.hup:MenuElement({id = "swi", name = "---------------->", value = 1, drop = {"Ignore Mana", "AND", "OR"}})
					self.menu.cnsm.hup:MenuElement({id = "man", name = "Minimum MP %", value = 50, min = 0, max = 100, step = 1})
				self.menu.cnsm:MenuElement({id = "crp", name = "Corrupting Potion", type = MENU})
					self.menu.cnsm.crp:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.cnsm.crp:MenuElement({id = "min", name = "Minimum HP %", value = 50, min = 0, max = 100, step = 1})
					self.menu.cnsm.crp:MenuElement({id = "swi", name = "---------------->", value = 1, drop = {"Ignore Mana", "AND", "OR"}})
					self.menu.cnsm.crp:MenuElement({id = "man", name = "Minimum MP %", value = 50, min = 0, max = 100, step = 1})
				self.menu.cnsm:MenuElement({id = "eos", name = "Elixir of Sorcery", type = MENU})
					self.menu.cnsm.eos:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.cnsm.eos:MenuElement({id = "min", name = "Minimum HP %", value = 50, min = 0, max = 100, step = 1})
					self.menu.cnsm.eos:MenuElement({id = "swi", name = "---------------->", value = 1, drop = {"Ignore Mana", "AND", "OR"}})
					self.menu.cnsm.eos:MenuElement({id = "man", name = "Minimum MP %", value = 50, min = 0, max = 100, step = 1})
				self.menu.cnsm:MenuElement({id = "eow", name = "Elixir of Wrath", type = MENU})
					self.menu.cnsm.eow:MenuElement({id = "info", name = "Not Supported", type = SPACE})
				self.menu.cnsm:MenuElement({id = "eoi", name = "Elixir of Iron", type = MENU})
					self.menu.cnsm.eoi:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.cnsm.eoi:MenuElement({id = "min", name = "Minimum HP %", value = 50, min = 0, max = 100, step = 1})

			self.menu:MenuElement({id = "spcl", 	name = "Special", type = MENU})
				self.menu.spcl:MenuElement({id = "_e", 	name = "Enable Special", value = true})
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
				self.menu.summs:MenuElement({id = "_e", 	name = "Enable Summoner", value = true})
				-- Heal
				-- Barrier
				-- Exhaust
				-- Cleanse
				-- Ignite
				-- Smite


			self.menu:MenuElement({id = "_se", 		name = "Settings", type = MENU})
				self.menu._se:MenuElement({id = "_e", 	name = "Global Enable", value = true})
	end

	function maxActivator:__loadCallbacks()
		Callback.Add("Tick", function() self:__OnTick() end)
		Callback.Add("Draw", function() self:__OnDraw() end)
	end

	function maxActivator:__loadTables()
		self.wards = {
			["preSpots"] = {}
		}

		self.itemKey = {
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

		if self.menu._se._e:Value() then
			--Ward Stuff
			if self.menu.ward._e:Value() then
				self:doWardLogic()
			end
			--Damage Stuff
			if self.menu.damg._e:Value() then
				self:doDamageLogic()
			end
			--Consumables Stuff
			if self.menu.cnsm._e:Value() then
				self:doConsumLogic()
			end
		end
	end

	function maxActivator:__OnDraw()
		if self.menu.ward._d:Value() then
			self:doWardDrawings()
		end
	end

	function maxActivator:__getSlot(id)
		for i = 6, 12 do
			if myHero:GetItemData(i).itemID == id then
				return i
			end
		end

		return nil
	end

	function maxActivator:itemReady(id)
		local slot = self:__getSlot(id)

		if slot then
			return myHero:GetSpellData(slot).currentCd == 0
		end
	end

	function maxActivator:castItem(unit, id, range)
		if unit == myHero or GetDistance(myHero, mousePos) <= range then
			local keyIndex = self:__getSlot(id) - 5
			local key = self.itemKey[keyIndex]

			if key then
				if unit ~= myHero then
					Control.CastSpell(key, unit.pos)
				else
					Control.CastSpell(key)
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

	function maxActivator:checkBuff(unit, name)
		for i = 0, 63 do
			local buff = unit:GetBuff(i)

			if buff.count > 0 and buff.name == name then return true end
		end

		return false
	end
--==================== WARD MODULE ====================--
	function maxActivator:doWardLogic()
		local mode = self.menu.ward._m:Value()

		if mode == 1 then --Auto
			--[[
					1. Do we have wards in inv?
					2.
			--]]
		else --Hover
		end
	end

	function maxActivator:doWardDrawings()
		for i = 1, #self.wards.preSpots do
			local wardSpot = self.wards.preSpots[i]:To2D()

			if wardSpot.onScreen then
				Draw.Text("Ward Spot", 10, wardSpot.x, wardSpot.y)
			end
		end
	end
--=====================================================--
--==================== ANTI WARD MODULE ====================--
--==========================================================--
--==================== SHIELD MODULE ====================--
--=======================================================--
--==================== DAMAGE MODULE ====================--
	function maxActivator:doDamageLogic()
		local damgMenu = self.menu.damg

		self.damgTarget.tia = self:itemReady(3077) and damgMenu.tia._e:Value() and not (damgMenu.tia._c:Value() and not self:isCombo()) and self:getDamgMode(damgMenu.tia.mode:Value()) and self:getDamgTarget(damgMenu.tia.target:Value())
		self.damgTarget.hyd = self:itemReady(3074) and damgMenu.hyd._e:Value() and not (damgMenu.hyd._c:Value() and not self:isCombo()) and self:getDamgMode(damgMenu.hyd.mode:Value()) and self:getDamgTarget(damgMenu.hyd.target:Value())
		self.damgTarget.tit = self:itemReady(3748) and damgMenu.tit._e:Value() and not (damgMenu.tit._c:Value() and not self:isCombo()) and self:getDamgMode(damgMenu.tit.mode:Value()) and self:getDamgTarget(damgMenu.tit.target:Value())
		self.damgTarget.bot = self:itemReady(3153) and damgMenu.bot._e:Value() and not (damgMenu.bot._c:Value() and not self:isCombo()) and self:getDamgMode(damgMenu.bot.mode:Value()) and self:getDamgTarget(damgMenu.bot.target:Value())
		self.damgTarget.bil = self:itemReady(3144) and damgMenu.bil._e:Value() and not (damgMenu.bil._c:Value() and not self:isCombo()) and self:getDamgMode(damgMenu.bil.mode:Value()) and self:getDamgTarget(damgMenu.bil.target:Value())
		self.damgTarget.pro = self:itemReady(3152) and damgMenu.pro._e:Value() and not (damgMenu.pro._c:Value() and not self:isCombo()) and self:getDamgMode(damgMenu.pro.mode:Value()) and self:getDamgTarget(damgMenu.pro.target:Value())
		self.damgTarget.glp = self:itemReady(3030) and damgMenu.glp._e:Value() and not (damgMenu.glp._c:Value() and not self:isCombo()) and self:getDamgMode(damgMenu.glp.mode:Value()) and self:getDamgTarget(damgMenu.glp.target:Value())
		self.damgTarget.gun = self:itemReady(3146) and damgMenu.gun._e:Value() and not (damgMenu.gun._c:Value() and not self:isCombo()) and self:getDamgMode(damgMenu.gun.mode:Value()) and self:getDamgTarget(damgMenu.gun.target:Value())

		if self.damgTarget.tia then
			self:castItem(self.damgTarget.tia, 3077, itemsIndex[3077].range)
		end

		if self.damgTarget.hyd then
			self:castItem(self.damgTarget.hyd, 3074, itemsIndex[3074].range)
		end

		if self.damgTarget.tit then
			self:castItem(self.damgTarget.tit, 3748, itemsIndex[3748].range)
		end

		if self.damgTarget.bot then
			self:castItem(self.damgTarget.bot, 3153, itemsIndex[3153].range)
		end

		if self.damgTarget.bil then
			self:castItem(self.damgTarget.bil, 3144, itemsIndex[3144].range)
		end

		if self.damgTarget.pro then
			self:castItem(self.damgTarget.pro, 3152, itemsIndex[3152].range)
		end

		if self.damgTarget.glp then
			self:castItem(self.damgTarget.glp, 3030, itemsIndex[3030].range)
		end

		if self.damgTarget.gun then
			self:castItem(self.damgTarget.gun, 3146, itemsIndex[3146].range)
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
		local Access = myHero.attackData
		local readiness = Access.state == 1 and 100 or (Access.endTime - Timer()) * 100 / Access.animationTime
		--Before Attack, After Attack, Always
		if mode == 1 then
			state = readiness == 100
		elseif mode == 2 then
			state = readiness <= 60
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
		if GetDistance(myHero, Base) > 600 then
			local a = self:itemReady(2003)
			local b = self:itemReady(2031)
			local c = self:itemReady(2032)
			local d = self:itemReady(2033)
			local e = self:itemReady(2139)
			local f = self:itemReady(2138)
			local g = self:itemReady(2010)

			if (a or b or c or d or e or f or g) then
				local cnsmMenu = self.menu.cnsm

				if a and cnsmMenu.hpp._e:Value() and not self:checkBuff(myHero, "RegenerationPotion") and self:getPercentHP(myHero) <= cnsmMenu.hpp.min:Value() then
					self:castItem(myHero, 2003)
				end

				if b and cnsmMenu.rfp._e:Value() and not self:checkBuff(myHero, "ItemCrystalFlask") and self:getPercentHP(myHero) <= cnsmMenu.rfp.min:Value() then
					self:castItem(myHero, 2031)
				end

				if c and cnsmMenu.hup._e:Value() and not self:checkBuff(myHero, "ItemCrystalFlaskJungle") then
					local A = self:getPercentHP(myHero) <= cnsmMenu.hup.min:Value()
					local B = cnsmMenu.hup.swi:Value()
					local C = self:getPercentMP(myHero) <= cnsmMenu.hup.man:Value()

					if (B == 1 and A) or (B == 2 and A and C) or (B == 3 and (A or C)) then
						self:castItem(myHero, 2032)
					end
				end

				if d and cnsmMenu.crp._e:Value() and not self:checkBuff(myHero, "ItemDarkCrystalFlask") then
					local A = self:getPercentHP(myHero) <= cnsmMenu.crp.min:Value()
					local B = cnsmMenu.crp.swi:Value()
					local C = self:getPercentMP(myHero) <= cnsmMenu.crp.man:Value()

					if (B == 1 and A) or (B == 2 and A and C) or (B == 3 and (A or C)) then
						self:castItem(myHero, 2033)
					end
				end

				if e and cnsmMenu.eos._e:Value() and not self:checkBuff(myHero, "ElixirOfSorcery") then
					local A = self:getPercentHP(myHero) <= cnsmMenu.eos.min:Value()
					local B = cnsmMenu.eos.swi:Value()
					local C = self:getPercentMP(myHero) <= cnsmMenu.eos.man:Value()

					if (B == 1 and A) or (B == 2 and A and C) or (B == 3 and (A or C)) then
						self:castItem(myHero, 2139)
					end
				end

				if f and cnsmMenu.eoi._e:Value() and not self:checkBuff(myHero, "ElixirOfIron") and self:getPercentHP(myHero) <= cnsmMenu.eoi.min:Value() then
					self:castItem(myHero, 2138)
				end

				if g and cnsmMenu.bor._e:Value() and not self:checkBuff(myHero, "ItemMiniRegenPotion") and self:getPercentHP(myHero) <= cnsmMenu.bor.min:Value() then
					self:castItem(myHero, 2010)
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

-- for i = 6, 12 do print(myHero:GetItemData(i)) end
