--[[
		maxActivator v0.02
		
		by Maxxxel
	
	
		Changelog:
			0.01 - Creation
			0.02 - Restructured, Added Ward System
--]]
local version = 0.02

local Timer = Game.Timer
local sqrt = math.sqrt
local MapID = Game.mapID
local Base = 
			MapID == TWISTED_TREELINE and myHero.team == 100 and {x=1076, y=150, z=7275} or myHero.team == 200 and {x=14350, y=151, z=7299} or
			MapID == SUMMONERS_RIFT and myHero.team == 100 and {x=419,y=182,z=438} or myHero.team == 200 and {x=14303,y=172,z=14395} or
			MapID == HOWLING_ABYSS and myHero.team == 100 and {x=971,y=-132,z=1180} or myHero.team == 200 and {x=11749,y=-131,z=11519} or
			MapID == CRYSTAL_SCAR and {x = 0, y = 0, z = 0}

local itemsIndex = {
	[3341] = {name = "Sweeping Lens",				type = "anti", id = 3341, range = 1700, radius = 550},
	[3364] = {name = "Oracle Alteration", 			type = "anti", id = 3364, range = 0000, radius = 720},
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
	["sgt"] = {name = "Sightstone", 		id = 2049, range = 600},
	-- ["tkn"] = {name = "Tracker's Knife", 	id = 0000, range = 600},
	["rsg"] = {name = "Ruby Sightstone", 	id = 2045, range = 600},
	["eoo"] = {name = "Eye of the Oasis", 	id = 2302, range = 600},
	["eow"] = {name = "Eye of the Watchers", id = 2301, range = 600},
	["eoe"] = {name = "Eye of the Equinox", id = 2303, range = 600},
	["ctw"] = {name = "Control Ward", 		id = 2055, range = 600},
	["fsg"] = {name = "Farsight Alteration", id = 3363, range = 4000}
}

local shieldItems = {
	["stw"] = {name = "Stopwatch", 				id = 2420, target = "self", effect = "Stasis"},
	["zhg"] = {name = "Zhonya's Hourglass", 	id = 3157, target = "self", effect = "Stasis"},
	-- ["eon"] = {name = "Edge of Night", 			id = 3814, target = "self", effect = "Spell Shield"}, to Situational
	["qss"] = {name = "Quicksilver Sash", 		id = 3140, target = "self", effect = "CC"},
	["msc"] = {name = "Mercurial Scimittar", 	id = 3139, target = "self", effect = "CC"},
	["mcr"] = {name = "Mikael's Crucible", 		id = 3222, target = "unit", range = 0650, effect = "CC"},
	["lis"] = {name = "Locket of the Iron Solari", id = 3190, target = "unit", range = 0700, effect = "Shield"},
	["fom"] = {name = "Face of the Mountain", 	id = 3401, target = "unit", range = 1100, effect = "Shield"},
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
				-- self.menu.anti:MenuElement({id = "_e", 	name = "Enable Anti-Ward", value = true})

			self.menu:MenuElement({id = "shld", 	name = "Shield", type = MENU})
				-- self.menu.shld:MenuElement({id = "_e", 	name = "Enable Shield", value = true})
				-- for short, data in pairs(shieldItems) do
				-- 	self.menu.shld:MenuElement({id = short, name = data.name, type = MENU})
				-- 	self.menu.shld[short]:MenuElement({id = "_e", name = "Enable", value = true})

				-- 	if data.effect == "Stasis" then
				-- 		self.menu.shld[short]:MenuElement({id = "hp", name = "If HP will drop below (%)", value = 10, min = 0, max = 100, step = 1})
				-- 	elseif data.effect == "Shield" then
				-- 		self.menu.shld[short]:MenuElement({id = "hp", name = "If HP will drop below (%)", value = 10, min = 0, max = 100, step = 1})
						
				-- 		for i = 1, #self.Heroes.Allies do
				-- 			if i == 1 then
				-- 				self.menu.shld[short]:MenuElement({id = "info", name = "+++ ALLIES +++", type = SPACE})
				-- 			end

				-- 			local ally = self.Heroes.Allies[i]

				-- 			if ally.networkID ~= myHero.networkID then
				-- 				self.menu.shld[short]:MenuElement({id = "ahp", name = "Help " .. ally.charName .. "?", value = true})
				-- 			end
				-- 		end
				-- 	elseif data.effect == "CC" then
				-- 		self.menu.shld[short]:MenuElement({id = "Airborne", name = "Clear Airborne", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Slow", name = "Clear Slow", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Disarm", name = "Clear Disarm", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Charm", name = "Clear Charm", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Root", name = "Clear Root", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Silence", name = "Clear Silence", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Slow", name = "Clear Slow", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Stun", name = "Clear Stun", value = true})
						
				-- 		if short ~= "mcr" then
				-- 			self.menu.shld[short]:MenuElement({id = "Suppression", name = "Clear Suppression", value = true})
				-- 			self.menu.shld[short]:MenuElement({id = "Blind", name = "Clear Blind", value = true})
				-- 			self.menu.shld[short]:MenuElement({id = "Nearsight", name = "Clear Nearsight", value = true})
				-- 		end

				-- 		if short == "mcr" then
				-- 			for i = 1, #self.Heroes.Allies do
				-- 				if i == 1 then
				-- 					self.menu.shld[short]:MenuElement({id = "info", name = "+++ ALLIES +++", type = SPACE})
				-- 				end

				-- 				local ally = self.Heroes.Allies[i]

				-- 				if ally.networkID ~= myHero.networkID then
				-- 					self.menu.shld[short]:MenuElement({id = "help", name = "Help: " .. ally.charName .. "?", value = true})
				-- 				end
				-- 			end
				-- 		end
				-- 	end
				-- end

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
	end

	function maxActivator:__loadCallbacks()
		Callback.Add("Tick", function() self:__OnTick() end)
		Callback.Add("Draw", function() self:__OnDraw() end)
	end

	function maxActivator:__loadTables()
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
		if unit == myHero or GetDistance(myHero, unit) <= range then
			local keyIndex = self:__getSlot(id) - 5
			local key = self.itemKey[keyIndex]

			if key then
				if unit ~= myHero then
					Control.CastSpell(key, unit.pos or unit)
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
		local readyWard = nil

		for short, data in pairs(wardItems) do
			if self:itemReady(data.id) and self.menu.ward[short]:Value() then
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
--==========================================================--
--==================== SHIELD MODULE ====================--
--=======================================================--
--==================== DAMAGE MODULE ====================--
	function maxActivator:doDamageLogic()
		local damgMenu = self.menu.damg
		local combo = self:isCombo()

		for short, data in pairs(damageItems) do
			local target = self:itemReady(data.id) and damgMenu.short._e:Value() and not (damgMenu.short._c:Value() and not combo) and self:getDamgMode(damgMenu.short.mode:Value()) and self:getDamgTarget(damgMenu.short.target:Value())

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
			local cnsmMenu = self.menu.cnsm

			for short, data in pairs(consumableItems) do
				if cnsmMenu[short]._e:Value() then
					local ready = self:itemReady(data.id)

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

-- for i = 6, 12 do print(myHero:GetItemData(i)) end
