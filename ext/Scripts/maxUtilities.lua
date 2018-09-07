--[[
		maxUtilities
		(by Maxxxel)
	
	
		Changelog:
			0.01 	- Creation
			0.02 	- Restructured, Added Ward System
			0.03 	- Added Anti Ward/Stealth
			0.04 	- Added Anti CC
			0.05 	- 8.2 Changes to Support Items/Ward Items
			0.06 	- Fixed Anti-Stealth and Damage Modules
			0.07 	- Fixed Pot onDeath, added self.base Debug Drawing, increased self.base Range, Added Arcane Sweeper
			0.08 	- Fixed Pot Ammo, added new way of AA Detection, fixed Damage Items
			0.081 	- Bugfix
			0.082 	- Fixed AntiWard double Menu Entry
			0.083 	- Bugfix
			0.084 	- Bugfix (no item changes)
			0.09 	- Added gamsteron orb support, fixed shielding
			0.091 	- Disabled Cripple Buff
			0.1 	- 8.17 + AutoUpdate + removed some Items + AutoLevel + Renaming + AntiAFK
			0.11 	- Little Bugfix
			0.12 	- Smaller Bug Fixes, new Menu Icons, Disabled Anti-CC (GoS Bugs), Improved Auto-Level, Anti-AFK Timer Menu, Added DrawCircleHack
			0.13 	- HotFix for Download Issue
			0.14 	- HotFix for AutoLevel
			0.15 	- Fixed API for latest gsoOrbwalker, changed some AA detection features

		To-Do:
			-Summoners including Auto-Smite
			-Special Items
			-More Shield Items
			-AntiAFK Timer Menu (lazy)
--]]

local version = 0.15
local _presetData
local Timer = Game.Timer
local Control = Control
local sqrt, abs = math.sqrt, math.abs
local MapID = Game.mapID

local itemsIndex = {
	[3060] = {name = "Banner of Command", 			type = "spcl", id = 3060, target = "unit", effect = "Boost Minion"},
	[3069] = {name = "Talisman of Ascension", 		type = "spcl", id = 3069, target = "self", effect = "Speed"},
	[3092] = {name = "Frost Queen's Claim", 		type = "spcl", id = 3092, target = "self", effect = "Slow"},
	[3050] = {name = "Zeke's Convergence", 			type = "spcl", id = 3050, target = "bind", effect = "Boost Ally"},
	[3056] = {name = "Ohmwrecker", 					type = "spcl", id = 3056, target = "self", effect = "Stop Turrets"},
	[3800] = {name = "Righteous Glory", 			type = "spcl", id = 3800, target = "self", effect = "Speed"},
	[3512] = {name = "Zz'Rot Portal", 				type = "spcl", id = 3512, target = "spot", effect = "Portal"},
	[3142] = {name = "Youmuu's Ghostblade", 		type = "spcl", id = 3142, target = "self", effect = "Speed"},
	[3143] = {name = "Randuin's Omen", 				type = "spcl", id = 3143, target = "self", effect = "Slow"},
	[0000] = {name = "Gargoyle Stoneplate", 		type = "defe", id = 0000, target = "self", effect = "Def Up"},
	[0000] = {name = "Knight's Vow", 				type = "defe", id = 0000, target = "both", effect = "Def Up"},
	[0000] = {name = "Shurelya's Reverie", 			type = "spcl", id = 0000, target = "both", effect = "Speed"},
	[0000] = {name = "Zeke's Convergence",			type = "spcl", id = 0000, target = "both", effect = "Damage"},
	[0000] = {name = "Twin Shadows", 				type = "defe", id = 0000, target = "self", effect = "Slow"},
	[0000] = {name = "Redemption", 					type = "spcl", id = 0000, target = "both", effect = "Hybrid"},
}

local damageItems = {
	["tia"] = {name = "Tiamat", id = 3077, range = 300, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/e/e3/Tiamat_item.png"},
	["hyd"] = {name = "Ravenous Hydra", id = 3074, range = 300, icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/e/e8/Ravenous_Hydra_item.png"},
	["tit"] = {name = "Titanic Hydra", id = 3748, range = 300, icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/2/22/Titanic_Hydra_item.png"},
	["bot"] = {name = "Blade of the Ruined King", id = 3153, range = 600, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/2f/Blade_of_the_Ruined_King_item.png"},
	["bil"] = {name = "Bilgewater Cutlass", id = 3144, range = 600, icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/4/44/Bilgewater_Cutlass_item.png"},
	["pro"] = {name = "Hextech Protobelt-01", id = 3152, range = 800, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/8/8d/Hextech_Protobelt-01_item.png"},
	["glp"] = {name = "Hextech GLP-800", id = 3030, range = 800, icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/c/c9/Hextech_GLP-800_item.png"},
	["gun"] = {name = "Hextech Gunblade", id = 3146, range = 700, icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/6/64/Hextech_Gunblade_item.png"},
}

local consumableItems = {
	["bor"] = {name = "Total Biscuit of Everlasting Will", id = 2010, type = "mph", buffName = "Item2010", icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/1/10/Total_Biscuit_of_Everlasting_Will_item.png"},
	["hpp"] = {name = "Health Potion", id = 2003, type = "", buffName = "RegenerationPotion", icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/1/13/Health_Potion_item.png"},
	["rfp"] = {name = "Refillable Potion", id = 2031, type = "", buffName = "ItemCrystalFlask", icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/7/7f/Refillable_Potion_item.png"},
	["hup"] = {name = "Hunter's Potion", id = 2032, type = "mph", buffName = "ItemCrystalFlaskJungle", icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/63/Hunter%27s_Potion_item.png"},
	["crp"] = {name = "Corrupting Potion", id = 2033, type = "mph", buffName = "ItemDarkCrystalFlask", icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/8/87/Corrupting_Potion_item.png"},
	-- ["eos"] = {name = "Elixir of Sorcery", id = 2139, type = "mph", buffName = "ElixirOfSorcery", icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/2/27/Elixir_of_Sorcery_item.png"},
	["eoi"] = {name = "Elixir of Iron", id = 2138, type = "", buffName = "ElixirOfIron", icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/6/65/Elixir_of_Iron_item.png"},
	["map"] = {name = "Mana Potion (Cleptomancy)", id = 2004, type = "man", buffName = "FlaskOfCrystalWater", icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/1/1d/Mana_Potion_item.png"},
	["sly"] = {name = "Sly Sack of Gold (Cleptomancy)", id = 2319, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/4/48/Sly_Sack_of_Gold_item.png"},
	["pil"] = {name = "Pilfered Health Potion (Cleptomancy)", id = 2061, type = "", buffName = "LootedRegenerationPotion", icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/a/a9/Pilfered_Health_Potion_item.png"},
	["tra"] = {name = "Travelsize Elixir of Iron (Cleptomancy)", id = 2058, type = "", buffName = "TravelSizeElixirOfIron", icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/d/d6/Travel_Size_Elixir_of_Iron_item.png"},
	["eos"] = {name = "Elixir of Skill (Cleptomancy)", id = 2011, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/3/31/Ichor_of_Illumination_item.png"}
}

local wardItems = {
	["wrt"] = {name = "Warding Totem", 		id = 3340, range = 600, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/e/e2/Warding_Totem_item.png"},
	["eof"] = {name = "Eye of Frost", 		id = 3098, range = 600, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/2/26/Eye_of_Frost_item.png"},
	["eow"] = {name = "Eye of the Watchers", id = 3092, range = 600, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/1/18/Eye_of_the_Watchers_item.png"},
	["frf"] = {name = "Nomad's Eye", 		id = 3096, range = 600, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/a/a8/Nomad%27s_Eye_item.png"},
	["roa"] = {name = "Eye of the Ascension", id = 3069, range = 600, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/b/b4/Eye_of_Ascension_item.png"},
	["tab"] = {name = "Celestial Eye", 		id = 3097, range = 600, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/2/29/Celestial_Eye_item.png"},
	["frf"] = {name = "Eye of the Aspect", 	id = 3401, range = 600, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/6/64/Eye_of_the_Aspect_item.png"},
	["ctw"] = {name = "Control Ward", 		id = 2055, range = 600, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/1/1b/Control_Ward_item.png"},
	["fsg"] = {name = "Farsight Alteration", id = 3363, range = 4000, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/7/75/Farsight_Alteration_item.png"},
	["pil"] = {name = "Pilfered Stealth Ward (Cleptomancy)", id = 2056, range = 600, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/d/d1/Stealth_Ward_%28Item%29_item.png"},
	["pee"] = {name = "Peering Farsight Ward (Cleptomancy)", id = 2057, range = 2000, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/7/75/Farsight_Alteration_item.png"}
}

local shieldItems = {
	-- ["stw"] = {name = "Stopwatch", 				id = 2420, target = "self", effect = "Stasis"},
	-- ["zhg"] = {name = "Zhonya's Hourglass", 	id = 3157, target = "self", effect = "Stasis"},
	-- ["eon"] = {name = "Edge of Night", 			id = 3814, target = "self", effect = "Spell Shield"}, to Situational
	["qss"] = {name = "Quicksilver Sash", 		id = 3140, target = "self", effect = "CC", icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/f9/Quicksilver_Sash_item.png"},
	["msc"] = {name = "Mercurial Scimittar", 	id = 3139, target = "self", effect = "CC", icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/0a/Mercurial_Scimitar_item.png"},
	["mcr"] = {name = "Mikael's Crucible", 		id = 3222, target = "unit", range = 0650, effect = "CC", icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/d/de/Mikael%27s_Crucible_item.png"},
	-- ["lis"] = {name = "Locket of the Iron Solari", id = 3190, target = "unit", range = 0700, effect = "Shield"},
	-- ["fom"] = {name = "Face of the Mountain", 	id = 3401, target = "unit", range = 1100, effect = "Shield"},4
	-- Seraphs Embrace
}

-- local sweepModRange = {
-- 	500, 500, 500,
-- 	800, 800, 800,
-- 	1100, 1100, 1100,
-- 	1400, 1400, 1400,
-- 	1700, 1700, 1700,
-- 	2000, 2000, 2000
-- }

-- local sweepModRadius = {
-- 	450, 450, 450,
-- 	475, 475, 475,
-- 	500, 500, 500,
-- 	525, 525, 525,
-- 	550, 550, 550,
-- 	575, 575, 575
-- }

local oracleModRadius = {
	660, 660, 660, 660, 660, 660, 660, 660, 660, 660,
	690, 690, 690,
	720, 720, 720,
	750, 750
}

local antiWardItems = {
	-- ["swe"] = {name = "Sweeping Lens", id = 3341, range = -1, radius = -1},
	["orc"] = {name = "Oracle Lens", id = 3364, range = 0000, radius = -2, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/c/c2/Oracle_Lens_item.png"},
	["ctw"] = {name = "Control Ward", id = 2055, range = 600, radius = 600, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/1/1b/Control_Ward_item.png"},
	-- ["hts"] = {name = "Arcane Sweeper", id = 3348, range = 800, radius = 375, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/8/8d/Hextech_Sweeper_item.png"},
}

local function ReadFile(path, fileName)
	local file = io.open(path .. fileName, "r")
	if not file then return false end
	local result = file:read()
	file:close()
	return result
end

if ReadFile(COMMON_PATH, 'levelPresets.lua') then
	_presetData = require 'levelPresets'
end

local function GetDistance(A, B)
	local A = A.pos or A
	local B = B.pos or B

	local ABX, ABZ = A.x - B.x, A.z - B.z

	return sqrt(ABX * ABX + ABZ * ABZ)
end

local maxUtilities = setmetatable({}, {
	__call = function(self)
		self:__loadTables()
		self:__loadUnits()
		self:__loadMenu()
		self:__loadCallbacks()
	end
})

	function maxUtilities:__loadMenu()
		self.menu = MenuElement({id = "maxUtilities", name = " maxUtilities v" .. version .. "", type = MENU, leftIcon = "http://img4host.net/upload//021635045b8bf518531d2.png"})
			self.menu:MenuElement({id = "ward", 	name = " 1. Ward", type = MENU, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/0a/Classic_Ward.png"})
				self.menu.ward:MenuElement({id = "_e", name = "Enable Ward", value = true})
				self.menu.ward:MenuElement({id = "_m", name = "Warding Mode", value = 1, drop = {"Auto", "Mouse Hover"}})
				self.menu.ward:MenuElement({id = "_d", name = "Draw Spots", value = true})
				self.menu.ward:MenuElement({id = "info", name = "+++ ITEMS +++", type = SPACE})
				for short, data in pairs(wardItems) do
					self.menu.ward:MenuElement({id = short, name = data.name, value = true, leftIcon = data.icon})
				end

			self.menu:MenuElement({id = "anti", 	name = " 2. Anti-Ward", type = MENU, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/05/Vision_Ward_item.png"})
				self.menu.anti:MenuElement({id = "_e", 	name = "Enable Anti-Ward", value = true})
				self.menu.anti:MenuElement({id = "_d", 	name = "Draw Enemy Wards", value = true})
				self.menu.anti:MenuElement({id = "info", name = "+++ ITEMS +++", type = SPACE})
				for short, data in pairs(antiWardItems) do
					self.menu.anti:MenuElement({id = short, name = data.name, value = true, leftIcon = data.icon})
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
								self.menu.anti[unit]:MenuElement({id = short, name = data.name, value = true, leftIcon = data.icon})
							end
						end
					end
				end

			self.menu:MenuElement({id = "shld", 	name = " 3. Shield (DISABLED - GOS BUG)", type = MENU, leftIcon = "https://vignette.wikia.nocookie.net/theavengersmovie/images/3/37/Cap_shield.png"})
				-- self.menu.shld:MenuElement({id = "_e", 	name = "Enable Shield", value = true})
				-- for short, data in pairs(shieldItems) do
				-- 	self.menu.shld:MenuElement({id = short, name = data.name, type = MENU, leftIcon = data.icon})
				-- 	self.menu.shld[short]:MenuElement({id = "_e", name = "Enable", value = true})

				-- 	if data.effect == "Stasis" then
				-- 		-- self.menu.shld[short]:MenuElement({id = "hp", name = "If HP will drop below (%)", value = 10, min = 0, max = 100, step = 1})
				-- 	elseif data.effect == "Shield" then
				-- 		-- self.menu.shld[short]:MenuElement({id = "hp", name = "If HP will drop below (%)", value = 10, min = 0, max = 100, step = 1})
						
				-- 		-- for i = 1, #self.Heroes.Allies do
				-- 		-- 	if i == 1 then
				-- 		-- 		self.menu.shld[short]:MenuElement({id = "info", name = "+++ ALLIES +++", type = SPACE})
				-- 		-- 	end

				-- 		-- 	local ally = self.Heroes.Allies[i]

				-- 		-- 	if ally.networkID ~= myHero.networkID then
				-- 		-- 		self.menu.shld[short]:MenuElement({id = "ahp", name = "Help " .. ally.charName .. "?", value = true})
				-- 		-- 	end
				-- 		-- end
				-- 	elseif data.effect == "CC" then
				-- 		self.menu.shld[short]:MenuElement({id = "Airborne", name = "Clear Airborne", value = true})
				-- 		-- self.menu.shld[short]:MenuElement({id = "Cripple", name = "Clear Cripple", value = false})
				-- 		self.menu.shld[short]:MenuElement({id = "Charm", name = "Clear Charm", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Fear", name = "Clear Fear", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Flee", name = "Clear Flee", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Taunt", name = "Clear Taunt", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Snare", name = "Clear Root/Snare", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Polymorph", name = "Clear Polymorph", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Silence", name = "Clear Silence", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Sleep", name = "Clear Sleep", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Slow", name = "Clear Slow", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Stun", name = "Clear Stun", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Poison", name = "Clear Poison", value = true})
				-- 		self.menu.shld[short]:MenuElement({id = "Disarm", name = "Clear Disarm", value = true})

				-- 		if short ~= "mcr" then
				-- 			self.menu.shld[short]:MenuElement({id = "Blind", name = "Clear Blind", value = true})
				-- 			self.menu.shld[short]:MenuElement({id = "Nearsight", name = "Clear Nearsight", value = true})
				-- 			self.menu.shld[short]:MenuElement({id = "Suppression", name = "Clear Suppression", value = true})
				-- 		end

				-- 		if short == "mcr" then
				-- 			for i = 1, #self.Heroes.Allies do
				-- 				if i == 1 and #self.Heroes.Allies > 1 then
				-- 					self.menu.shld[short]:MenuElement({id = "info", name = "+++ ALLIES +++", type = SPACE})
				-- 				end

				-- 				local ally = self.Heroes.Allies[i]

				-- 				if ally.networkID ~= myHero.networkID then
				-- 					self.menu.shld[short]:MenuElement({id = "help" .. ally.charName, name = "Help: " .. ally.charName .. "?", value = true})
				-- 				end
				-- 			end
				-- 		end
				-- 	end
				-- end

			self.menu:MenuElement({id = "damg", 	name = " 4. Damage", type = MENU, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/a/aa/Ace_in_the_Hole.png"})
				self.menu.damg:MenuElement({id = "_e", 	name = "Enable Damage", value = true})
				for short, data in pairs(damageItems) do
					self.menu.damg:MenuElement({id = short, name = data.name, type = MENU, leftIcon = data.icon})
					self.menu.damg[short]:MenuElement({id = "_e", name = "Enable", value = true})
					self.menu.damg[short]:MenuElement({id = "_c", name = "Only on Combo", value = true})
					self.menu.damg[short]:MenuElement({id = "mode", name = "Mode", value = 3, drop = {"Before Attack", "After Attack", "Always"}})
					self.menu.damg[short]:MenuElement({id = "target", name = "Target", value = 2, drop = {"Orb Target", "Near Mouse", "Near myHero"}})
				end

			self.menu:MenuElement({id = "cnsm", 	name = " 5. Consume", type = MENU, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/3/3d/Ahri_Lore_2.png"})
				self.menu.cnsm:MenuElement({id = "_e", 	name = "Enable Consume", value = true})
				for short, data in pairs(consumableItems) do
					self.menu.cnsm:MenuElement({id = short, name = data.name, type = MENU, leftIcon = data.icon})
					local t = data.type

					if t then
						self.menu.cnsm[short]:MenuElement({id = "_e", name = "Enable", value = true})
						
						if t == "mph" or t == "" then
							self.menu.cnsm[short]:MenuElement({id = "min", name = "Minimum HP %", value = 50, min = 0, max = 100, step = 1})
						end

						if t == "mph" or t == "man" then
							if t == "mph" then
								self.menu.cnsm[short]:MenuElement({id = "swi", name = "---------------->", value = 1, drop = {"Ignore Mana", "AND", "OR"}})
							end

							self.menu.cnsm[short]:MenuElement({id = "man", name = "Minimum MP %", value = 50, min = 0, max = 100, step = 1})
						end
					else
						self.menu.cnsm[short]:MenuElement({id = "_e", name = "AutoUse", value = true})
					end
				end

			self.menu:MenuElement({id = "spcl", 	name = " 6. Special (NOT IMPLEMENTED)", type = MENU, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/b/b9/Amplifying_Tome_item.png"})
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

			self.menu:MenuElement({id = "summs", 	name = " 7. Summoner (NOT IMPLEMENTED)", type = MENU, leftIcon = "https://vignette.wikia.nocookie.net/yugioh/images/9/9b/BAM-Destroy_Spell.png"})
				-- self.menu.summs:MenuElement({id = "_e", 	name = "Enable Summoner", value = true})
				-- Heal
				-- Barrier
				-- Exhaust
				-- Cleanse
				-- Ignite
				-- Smite

			self:doAutoLevelMenu()

			self.menu:MenuElement({id = "aafk", 	name = " 9. Anti-AFK", type = MENU, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/2/20/Amumu_Almost-PromKingCircle.png"})
				self.menu.aafk:MenuElement({id = "_e", name = "Enabled", value = true})
				self.menu.aafk:MenuElement({id = "_t", name = "AFK-Time till move [s]", value = 30, min = 30, max = 100, step = 1})

			self.menu:MenuElement({id = "_se", 		name = " 10. Settings", type = MENU, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/d/dc/April_Fools_2015_Welcome_to_Planet_Urf.png"})
				self.menu._se:MenuElement({id = "_e", 	name = "Global Enable", value = true})
				self.menu._se:MenuElement({id = "_b", 	name = "DebugBase", value = false})
				self.menu._se:MenuElement({id = "_r", 	name = "No Pots Range", value = 1000, min = 0, max = 2000, step = 100})
				self.menu._se:MenuElement({id = "_h", 	name = "GoS DrawCircle Quality Hack", value = _G.drawCircleQuality, min = 4, max = 64, step = 1})
	end

	function maxUtilities:__loadCallbacks()
		Callback.Add("Tick", function() self:__OnTick() end)
		Callback.Add("Draw", function() self:__OnDraw() end)
		Callback.Add("WndMsg", function(...) self:antiAFKDetect(...) end)
	end

	function maxUtilities:__loadTables()
		self.buffs = {}

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
			-- [3] = "Cripple",
			[5] = "Stun",
			[7] = "Silence",
			[8] = "Taunt",
			[9] = "Polymorph",
			[10] = "Slow",
			[11] = "Snare",
			[18] = "Sleep",
			[19] = "Nearsight",
			[21] = "Fear",
			[22] = "Charm",
			[23] = "Poison",
			[24] = "Suppression",
			[25] = "Blind",
			[28] = "Flee",
			[30] = "Airborne",
			[31] = "Disarm"
			-- ["Shred"] = 27,
			-- ["Knockup"] = 29,
		}
		
		self.damgTarget = {}
		self.Heroes = {Enemies = {}, Allies = {}}
		self.state = 0
		self.AAHitIn = 0
		self.NextAAIn = 0
		self.lastAction = Timer()

		for i = 1, Game.ObjectCount() do
	        local obj = Game.Object(i)
	        
	        if obj.isAlly and obj.type == Obj_AI_SpawnPoint then
	            self.base = obj.pos
	            break
	        end
		end
	end

	function maxUtilities:__loadUnits()
		for i = 1, Game.HeroCount() do
			local unit = Game.Hero(i)

			if unit.team ~= myHero.team then
				self.Heroes.Enemies[#self.Heroes.Enemies + 1] = unit
			else
				self.Heroes.Allies[#self.Heroes.Allies + 1] = unit
			end
		end
	end

	function maxUtilities:__OnTick()
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
		-- 	local itemID = myHero:GetItemData(i)

		-- 	if itemID.itemID ~= 0 then 
		-- 		-- print(itemID)
		-- 		-- print("\n")
		-- 		-- print("\n")
		-- 		-- print("\n")
		-- 	end
		-- 	local item = myHero:GetSpellData(i)
		-- 	if item.name ~= "" and item.name ~= "BaseSpell" then
		-- 		print(item.name .. " | " .. item.ammo)
		-- 		print(item)
		-- 		print("\n")
		-- 		print("\n")
		-- 		print("\n")
		-- 		print("\n")
		-- 		print("\n")
		-- 	end
		-- end

		-- for i = 0, 63 do
		-- 	local buff = myHero:GetBuff(i)

		-- 	if buff.count > 0 and buff.name ~= "" then 
		-- 		if not a then a = true print(buff) end
		-- 		self.buffs[#self.buffs + 1] = buff
		-- 	end
		-- end

		if Game.IsOnTop and self.menu._se._e:Value() and not myHero.dead then
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
			-- if self.menu.shld._e:Value() then
			-- 	self:doShieldLogic()
			-- end
			--Auto-Level
			if self.menu.al.on:Value() then
				self:doAutoLevelLogic()
			end
			--Anti-AFK
			if self.menu.aafk._e:Value() then
				self:doAntiAFKLogic()
			end
		end
	end

	function maxUtilities:__OnDraw()
		if self.menu._se._e:Value() then
			_G.drawCircleQuality = self.menu._se._h:Value()

			if self.menu.ward._d:Value() then
				self:doWardDrawings()
			end

			if self.menu.anti._d:Value() then
				self:doAntiDrawings()
			end
			
			if self.menu._se._b:Value() then
				Draw.Circle(self.base, self.menu._se._r:Value())

				if #self.buffs > 0 then
					for i = 1, #self.buffs do
						local b = self.buffs[i]

						Draw.Text(b.name .. ", " .. b.type,myHero.pos2D.x, myHero.pos2D.y + i * 15)
					end

					self.buffs = {}
				end
			end
		end
	end

	function maxUtilities:__getSlot(id)
		for i = 6, 12 do
			if myHero:GetItemData(i).itemID == id then
				return i
			end
		end

		return nil
	end

	function maxUtilities:itemReady(id, ward, pot)
		local slot = self:__getSlot(id)

		if slot then
			local cd = myHero:GetSpellData(slot).currentCd == 0

			if cd then
				if ward then
					local wardNum = id == 3340 and myHero:GetSpellData(slot).ammo or myHero:GetItemData(slot).stacks --id ~= 2057 and myHero:GetSpellData(slot).ammo or 

					return wardNum ~= 0 and wardNum < 10
				elseif pot then
					if not self.itemAmmoStorage[id] then return true end
					local potNum = id ~= 2061 and myHero:GetItemData(slot).ammo or myHero:GetItemData(slot).stacks

					if self.itemAmmoStorage[id].savedStorage == 0 then
						self.itemAmmoStorage[id].savedStorage = potNum
					end

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

	function maxUtilities:AAState()
		local as = myHero.activeSpell
		local ad = myHero.attackData

		if as.valid and not myHero.isChanneling then
			if self.state == 0 then
				self.NextAAIn = Timer() + as.animation
				self.AAHitIn = as.windup + Timer()
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

	function maxUtilities:castItem(unit, id, range, checked)
		if checked or unit == myHero or GetDistance(myHero, unit) <= range then
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

	function maxUtilities:getPercentHP(unit)
		return unit.health * 100 / unit.maxHealth
	end

	function maxUtilities:getPercentMP(unit)
		return unit.mana * 100 / unit.maxMana
	end

	function maxUtilities:checkBuff(unit, name, _type)
		for i = 0, 63 do
			local buff = unit:GetBuff(i)

			if buff.count > 0 and buff.name ~= "" and (buff.name == name or _type and buff.type == _type) then return true end
		end

		return false
	end
--==================== WARD MODULE ====================--
	function maxUtilities:doWardLogic()
		local mode = self.menu.ward._m:Value()

		if not (self.lastWard and Timer() - self.lastWard < 2) then 
			for short, data in pairs(wardItems) do
				if self:itemReady(data.id, true) and self.menu.ward[short]:Value() then
					for i = 1, #self.wards.preSpots do
						local ward = Vector(self.wards.preSpots[i])

						if ward:To2D().onScreen and GetDistance(ward, (mode == 1 and myHero or mousePos)) <= (mode == 1 and data.range or 100) then
							local c, d = self:getNearesetWardToPos(ward)

							if not (c and d < 600) then
								self.lastWard = Timer()
								self:castItem(ward, data.id, data.range, true)
								return
							end
						end
					end
				end
			end
		end
	end

	function maxUtilities:doWardDrawings()
		for i = 1, #self.wards.preSpots do
			local wardSpot = Vector(self.wards.preSpots[i]):To2D()

			if wardSpot.onScreen then
				Draw.Text("Ward Spot", 10, wardSpot.x, wardSpot.y)
			end
		end
	end

	function maxUtilities:getNearesetWardToPos(pos)
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
--==================== ANTI WARD MODULE ===============--
	function maxUtilities:doAntiLogic()
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

	function maxUtilities:doAntiDrawings()
		for i = 1, Game.WardCount() do
			local ward = Game.Ward(i)

			if ward.health ~= 0 and ward.team ~= myHero.team then
				Draw.Text("Enemy Ward", 10, ward.pos2D.x, ward.pos2D.y, Draw.Color(0xffff0000))
			end
		end
	end
--=====================================================--
--==================== SHIELD MODULE ==================--
	function maxUtilities:doShieldLogic()
		local shldMenu = self.menu.shld
		local qssMenu, mscMenu, mcrMenu = shldMenu["qss"], shldMenu["msc"], shldMenu["mcr"]

		if qssMenu._e:Value() or mscMenu._e:Value() or mcrMenu._e:Value() then --Anti CC
			if self:itemReady(3140) then --QSS
				for i = 1, 31 do
					local ccName = self.ccNames[i]

					if ccName then
						if qssMenu[ccName] and qssMenu[ccName]:Value() and self:checkBuff(myHero, "", i) then
							self:castItem(myHero, 3140)
						end
					end
				end
			elseif self:itemReady(3139) then --Mercury
				for i = 1, 31 do
					local ccName = self.ccNames[i]

					if ccName then
						if mscMenu[ccName] and mscMenu[ccName]:Value() and self:checkBuff(myHero, "", i) then
							self:castItem(myHero, 3139)
						end
					end
				end
			end

			if self:itemReady(3222) then --Mikael
				for i = 1, #self.Heroes.Allies do
					local ally = self.Heroes.Allies[i]

					ally = ally.networkID ~= myHero.networkID and mcrMenu["help" .. ally.charName]:Value() or myHero
					for i = 1, 31 do
						local ccName = self.ccNames[i]

						if ccName then
							if mcrMenu[ccName] and mcrMenu[ccName]:Value() and self:checkBuff(ally, "", i) then
								self:castItem(ally, 3222, 650)
							end
						end
					end
				end
			end
		end
	end
--=====================================================--
--==================== DAMAGE MODULE ==================--
	function maxUtilities:doDamageLogic()
		local damgMenu = self.menu.damg
		local combo = self:isCombo()

		for short, data in pairs(damageItems) do
			local target = self:itemReady(data.id) and 
				damgMenu[short]._e:Value() and 
				not (damgMenu[short]._c:Value() and not combo) and 
				self:getDamgMode(damgMenu[short].mode:Value()) and 
				self:getDamgTarget(damgMenu[short].target:Value())

			if target then
				self:castItem(target, data.id, data.range)
			end
		end
	end

	function maxUtilities:getDamgTarget(mode)
		local target = nil
		--Orb Target, Near Mouse, Near myHero
		if mode == 1 then
			target = 
				_G.EOWLoaded and _G.EOW:GetTarget() or 
				_G.SDK and _G.SDK.Orbwalker:GetTarget() or 
				_G.GOS and _G.Orbwalker.Enabled:Value() and _G.GOS:GetTarget()
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

	function maxUtilities:getDamgMode(mode)
		if mode == 3 then return true end

		local state = false
		local Access = self.state

		if mode == 1 then
			state = Access == 0 
			or _G.SDK and _G.SDK.Orbwalker:CanAttack()
			or _G.GOS:CanAttack()
		elseif mode == 2 then
			state = Access == 2 or (Access == 3 and self.NextAAIn - Timer() - 0.01 > 0.7)
		else
			state = true
		end

		return state
	end

	function maxUtilities:isCombo()
		local mode = 
			_G.EOWLoaded and _G.EOW:Mode() or
			_G.SDK and (_G.SDK.Orbwalker.Modes[0] and "Combo" or _G.SDK.Orbwalker.Modes[1] and "Harass" or _G.SDK.Orbwalker.Modes[4] and "LastHit" or _G.SDK.Orbwalker.Modes[2] and "LaneClear" or "") or
			_G.GOS and _G.Orbwalker.Enabled:Value() and _G.GOS:GetMode() or ""

		return mode == "Combo"
	end
--=====================================================--
--==================== CONSUMABLE MODULE ==============--
	function maxUtilities:doConsumLogic()
		if GetDistance(myHero, self.base) > self.menu._se._r:Value() then
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
						elseif data.type == "man" and self:getPercentMP(myHero) <= cnsmMenu[short].man:Value() then
							self:castItem(myHero, data.id)
						elseif data.type == "" and self:getPercentHP(myHero) <= cnsmMenu[short].min:Value() then
							self:castItem(myHero, data.id)
						elseif not data.type then
							self:castItem(myHero, data.id)
						end
					end
				end
			end
		end
	end
--=====================================================--
--==================== SPECIAL MODULE =================--
--=====================================================--
--==================== SUMMONER MODULE ================--
--=====================================================--
--==================== AUTO-LEVEL MODULE ==============--
	function maxUtilities:doAutoLevelLogic()
		if not self.levelUP then
			local actualLevel = myHero.levelData.lvl
			local levelPoints = myHero.levelData.lvlPts

			if actualLevel == 18 and levelPoints == 0 then return end

			if levelPoints > 0 then
				local mode = self.menu.al.mo:Value() == 1 and "mostUsed" or "highestRate"

				local skillingOrder = self.autoLevelPresets[mode]
				local QL, WL, EL, RL = 0, 0, 0, myHero.charName == "Karma" and 1 or 0
				local Delay = self.menu.al.wt:Value()
				--Check which level the spell should have
				for i = 1, actualLevel do
					if skillingOrder[i] == "Q" then 		--Q
						QL = QL + 1
					elseif skillingOrder[i] == "W" then		--W
						WL = WL + 1
					elseif skillingOrder[i] == "E" then 	--E
						EL = EL + 1
					elseif skillingOrder[i] == "R" then		--R
						RL = RL + 1
					end
				end

				local diffR = myHero:GetSpellData(_R).level - RL < 0
				local lowest = 99
				local spell
				local lowHK_Q = myHero:GetSpellData(_Q).level - QL
				local lowHK_W = myHero:GetSpellData(_W).level - WL
				local lowHK_E = myHero:GetSpellData(_E).level - EL

				if lowHK_Q < lowest then
					lowest = lowHK_Q
					spell = HK_Q
				end

				if lowHK_W < lowest then
					lowest = lowHK_W
					spell = HK_W
				end

				if lowHK_E < lowest then
					lowest = lowHK_E
					spell = HK_E
				end

				if diffR then
					spell = HK_R
				end

				if spell then
					self.levelUP = true

					DelayAction(function()
						Control.KeyDown(HK_LUS)
						Control.KeyDown(spell)
						Control.KeyUp(spell)
						Control.KeyUp(HK_LUS)

						DelayAction(function()
							self.levelUP = false
						end, .25)
					end, Delay)
				end
			end
		end
	end

	function maxUtilities:doAutoLevelMenu()
		self:getChampionPreset()
		local list = {"NO LEVEL DATA"}

		self.menu:MenuElement({id = "al", name = " 8. Auto Level", type = MENU, leftIcon = "https://vignette.wikia.nocookie.net/fossilfighters/images/5/5b/LevelUP.png"})
		self.menu.al:MenuElement({id = "on", name = "Enabled", value = true})
		self.menu.al:MenuElement({id = "wt", name = "Wait time [s]", value = 2, min = 0 , max = 10, step = .5})

		if not self.autoLevelPresets then 
			print("No Auto-Level presets found for " .. myHero.charName)
			self.menu.al.on:Value(false)
		else
			list = {"most Used: ", "highest Winrate: "}

			for i = 1, 18 do
				list[1] = list[1] .. self.autoLevelPresets['mostUsed'][i]
				list[2] = list[2] .. self.autoLevelPresets['highestRate'][i]
			end
		end

		self.menu.al:MenuElement({id = "mo", name = " ", value = 1, drop = list})
	end

	function maxUtilities:getChampionPreset()
		self.autoLevelPresets = nil
		local tbl = _presetData[1]
		local Name = myHero.charName:lower()

		for name, data in pairs(tbl) do
			if name:lower():find(Name) then
				self.autoLevelPresets = data
				break
			end
		end

		self.keyTranslation = {["Q"] = HK_Q, ["W"] = HK_W, ["E"] = HK_E, ["R"] = HK_R}
		_presetData = nil

		local byteCheck = string.char(HK_Q)

		if byteCheck ~= "Q" then
			print("maxUtilities: Using non-default Hotkeys, please re-check your lol and GoS Hotkeys if you experience problems.")
		end
	end
--=====================================================--
--==================== ANTI-AFK Module ================--
	function maxUtilities:doAntiAFKLogic()
		if Timer() - self.lastAction > self.menu.aafk._t:Value() then
			local pos = myHero.pos
			Control.Move(pos.x + 20, pos.y, pos.z + 20)
		end
	end

	function maxUtilities:antiAFKDetect(a, b)
		if b == 2 then
			self.lastAction = Timer()
		end
	end
--=====================================================--
--==================== AUTO-UPDATE ====================--
	local function DownloadFile(url, path, fileName)
	    DownloadFileAsync(url, path .. fileName, function() end)
	    while not FileExist(path .. fileName) do end
	end

	local function AutoUpdate()
	    DownloadFile("https://raw.githubusercontent.com/Maxxxel/GOS/master/ext/Scripts/maxUtilities.version", COMMON_PATH, "maxUtilities.version")
	    DownloadFile("https://raw.githubusercontent.com/Maxxxel/GOS/master/ext/Common/levelPresets.version", COMMON_PATH, "levelPresets.version")

	    local newVersionScript = tonumber(ReadFile(COMMON_PATH, "maxUtilities.version"))
	    local newVersionLevels = tonumber(ReadFile(COMMON_PATH, "levelPresets.version"))

	    if not _presetData or newVersionLevels > _presetData[2] then
	        DownloadFile("https://raw.githubusercontent.com/Maxxxel/GOS/master/ext/Common/levelPresets.lua", COMMON_PATH, "levelPresets.lua")
	        print("maxUtilities: Updated Auto-Level presets to " .. newVersionLevels .. ". Please Reload with 2x F6")
	        return false
	    end

	    if newVersionScript > version then
	        DownloadFile("https://raw.githubusercontent.com/Maxxxel/GOS/master/ext/Scripts/maxUtilities.lua", SCRIPT_PATH, "maxUtilities.lua")
	        print("maxUtilities: Updated to " .. newVersionScript .. ". Please Reload with 2x F6")
	        return false
	    else
	        print("maxUtilities: No Updates Found (" ..version .. ")")
	        return true
	    end
	end
--=====================================================--

if AutoUpdate() then
	maxUtilities()
end
