local F = {}
local all_Objs = {}
local base_counts = {}
local base_vars = {}
local obj_types = {
	[Obj_AI_SpawnPoint] = "Obj_AI_SpawnPoint",
	[Obj_AI_Camp] = "Obj_AI_Camp",
	[Obj_AI_Barracks] = "Obj_AI_Barracks",
	[Obj_AI_Hero] = "Obj_AI_Hero",
	[Obj_AI_Minion] = "Obj_AI_Minion",
	[Obj_AI_Turret] = "Obj_AI_Turret",
	[Obj_AI_LineMissle] = "Obj_AI_LineMissle",
	[Obj_AI_Shop] = "Obj_AI_Shop",
	[Obj_AI_Nexus] = "Obj_AI_Nexus"
}
local mapIDs = {
	[CRYSTAL_SCAR] = "CRYSTAL_SCAR",
	[TWISTED_TREELINE] = "TWISTED_TREELINE",
	[SUMMONERS_RIFT] = "SUMMONERS_RIFT",
	[HOWLING_ABYSS] = "HOWLING_ABYSS"
}
local color_by_type = {
	[Obj_AI_Barracks] = 0xff000000,
	[Obj_AI_Camp] = 0xfff00000,
	[Obj_AI_Hero] = 0xffff0000,
	[Obj_AI_LineMissle] = 0xfffff000,
	[Obj_AI_Minion] = 0xff00ff00,
	[Obj_AI_Nexus] = 0xfff00fff,
	[Obj_AI_Shop] = 0xf0f0f0f0,
	[Obj_AI_SpawnPoint] = 0xf00f00ff,
	[Obj_AI_Turret] = 0xf00ff0ff,
}
local countIDs = {
	[0] = "HeroCount",
	[1] = "CampCount",
	[2] = "TurretCount",
	[3] = "MissileCount",
	[4] = "MinionCount",
	[5] = "WardCount",
	[6] = "ParticleCount",
	[7] = "Object Stats",
	[8] = "Attack/Active Spell/Level Data",
	[9] = "Spells/Inventory/Buffs"
}

local max = math.max
local insert = table.insert
local concat = table.concat
local font_size = 13

local function IsValidObj(obj)
	return obj and obj.pos2D.onScreen
end

local function DrawBaseInterface()
	local offset = 0

	for i = 0, 9 do
		Draw.Text("Press Num" .. i .. " to toggle " .. countIDs[i] .. (F[i] and " [ON]" or " [OFF]"), font_size, 100, 400 + offset, F[i] and Draw.Color(0xff00ff00) or Draw.Color(0xffff0000))
		offset = offset + font_size
	end

	offset = offset + font_size * 2

	for name, count in pairs(base_counts) do
		Draw.Text(name .. ": " .. count, font_size, 100, 400 + offset, Draw.Color(0xffff0000))
		offset = offset + font_size
	end

	for name, var in pairs(base_vars) do
		Draw.Text(name .. ": " .. var, font_size, 100, 400 + offset, Draw.Color(0xffff0000))
		offset = offset + font_size
	end
end

local obj_stats = {
	{name = "activeSpellSlot", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "ap", type = {[Obj_AI_Hero] = true}},
	{name = "armor", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "armorPen", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "armorPenPercent", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "attackSpeed", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "baseDamage", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "bonusArmor", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "bonusArmorPenPercent", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "bonusDamage", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "bonusDamagePercent", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "bonusMagicResist", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "boundingRadius", all = true},
	{name = "buffCount", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "cdr", type = {[Obj_AI_Hero] = true}},
	{name = "charName", all = true},
	{name = "chnd", type = {[Obj_AI_Camp] = true}},
	{name = "critChance", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "dead", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "dir", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true}},
	{name = "distance", all = true},
	{name = "flatDamageReduction", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "gold", type = {[Obj_AI_Hero] = true}},
	{name = "handle", all = true},
	{name = "health", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "hpBar", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "hpRegen", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "hudAmmo", type = {[Obj_AI_Hero] = true}},
	{name = "hudMaxAmmo", type = {[Obj_AI_Hero] = true}},
	{name = "isAlly", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "isCampUp", type = {[Obj_AI_Camp] = true}},
	{name = "isChanneling", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "isEnemy", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "isImmortal", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "isMe", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "isTargetable", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "isTargetableToTeam", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "lifeSteal", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "magicPen", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "magicPenPercent", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "magicResist", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "mana", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "maxHealth", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "maxMana", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "mpRegen", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "ms", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true}},
	{name = "name", all = true},
	{name = "networkID", all = true},
	{name = "owner", all = true},
	{name = "pos", all = true},
	{name = "pos2D", all = true},
	{name = "posMM", all = true},
	{name = "posTo", all = true},
	{name = "range", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "shieldAD", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "shieldAP", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "spellVamp", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "targetID", all = true},
	{name = "team", all = true},
	{name = "toScreen", all = true},
	{name = "totalDamage", type = {[Obj_AI_Hero] = true, [Obj_AI_Minion] = true, [Obj_AI_Turret] = true}},
	{name = "totalGold", type = {[Obj_AI_Hero] = true}},
	{name = "type", all = true},
	{name = "valid", all = true},
	{name = "visible", all = true},
}

local attack_data = {
	{name = "animationTime", all = true},
	{name = "attackDelayCastOffsetPercent", all = true},
	{name = "attackDelayOffsetPercent", all = true},
	{name = "castFrame", all = true},
	{name = "endTime", all = true},
	{name = "projectileSpeed", all = true},
	{name = "state", all = true},
	{name = "target", all = true},
	{name = "windDownTime", all = true},
	{name = "windUpTime", all = true},
}

local active_spell = {
	{name = "acceleration", all = true},
	{name = "animation", all = true},
	{name = "castEndTime", all = true},
	{name = "castFrame", all = true},
	{name = "coneAngle", all = true},
	{name = "coneDistance", all = true},
	{name = "endTime", all = true},
	{name = "isAutoAttack", all = true},
	{name = "isChanneling", all = true},
	{name = "isCharging", all = true},
	{name = "isStopped", all = true},
	{name = "level", all = true},
	{name = "mana", all = true},
	{name = "maxSpeed", all = true},
	{name = "minSpeed", all = true},
	{name = "name", all = true},
	{name = "placementPos", all = true},
	{name = "range", all = true},
	{name = "speed", all = true},
	{name = "spellWasCast", all = true},
	{name = "startPos", all = true},
	{name = "startTime", all = true},
	{name = "target", all = true},
	{name = "valid", all = true},
	{name = "width", all = true},
	{name = "windup", all = true},
}

local level_data = {
	{name = "exp", type = {[Obj_AI_Hero] = true}},
	{name = "lvl", type = {[Obj_AI_Hero] = true}},
	{name = "lvlPts", type = {[Obj_AI_Hero] = true}},
}

local spell_data = {
	{name = "acceleration", all = true},
	{name = "ammo", all = true},
	{name = "ammoCd", all = true},
	{name = "ammoCurrentCd", all = true},
	{name = "ammoTime", all = true},
	{name = "castFrame", all = true},
	{name = "castTime", all = true},
	{name = "cd", all = true},
	{name = "coneAngle", all = true},
	{name = "coneDistance", all = true},
	{name = "currentCd", all = true},
	{name = "level", all = true},
	{name = "mana", all = true},
	{name = "maxSpeed", all = true},
	{name = "minSpeed", all = true},
	{name = "name", all = true},
	{name = "range", all = true},
	{name = "speed", all = true},
	{name = "targetingType", all = true},
	{name = "toggleState", all = true},
	{name = "width", all = true},
}

local item_data = {
	{name = "ammo", all = true},
	{name = "itemID", all = true},
	{name = "stacks", all = true},
}

local buff_data = {
	{name = "count", all = true},
	{name = "duration", all = true},
	{name = "expireTime", all = true},
	{name = "name", all = true},
	{name = "sourceName", all = true},
	{name = "sourcenID", all = true},
	{name = "stacks", all = true},
	{name = "startTime", all = true},
	{name = "type", all = true},
}

local function repeatInsert(obj, table, start, dObj, forceColumn, forceRow)
	local InfoStream = {""}
	local cut = 0
	local start = start or 0

	for i = start + 1, #table do
		local stat = table[i]

		if stat.all or stat.type[obj.type] then
			insert(InfoStream, stat.name .. ": " .. (
				table == attack_data and tostring(obj.attackData[stat.name]) or
				table == active_spell and tostring(obj.activeSpell[stat.name]) or
				table == level_data and tostring(obj.levelData[stat.name]) or
				tostring(obj[stat.name])))
			cut = cut + 1

			if cut == 32 or i == #table then
				local String = concat(InfoStream, "\n")
				local dObj = dObj or obj
				Draw.Text(String, font_size, dObj.pos2D.x + (table == level_data and 32 or forceColumn or start) * 10, dObj.pos2D.y + (table == active_spell and font_size * 12 or 0) + (forceRow or 0))
				
				return repeatInsert(obj, table, start + 32, dObj)
			end
		end
	end
end

local function DrawInfos(obj)
	if F[7] then
		repeatInsert(obj, obj_stats)
	end

	if F[8] and (obj.type == Obj_AI_Hero or obj.type == Obj_AI_Minion or obj.type == Obj_AI_Turret) then
		repeatInsert(obj, attack_data)
		repeatInsert(obj, active_spell)
		repeatInsert(obj, level_data)
	end

	if F[9] and obj.type == Obj_AI_Hero then
		for i = 0, 3 do
			repeatInsert(obj:GetSpellData(i), spell_data, nil, obj, i * 25)
		end
	end

	if F[9] and (obj.type == Obj_AI_Hero or obj.type == Obj_AI_Minion or obj.type == Obj_AI_Turret) then
		for i = 0, 6 do
			repeatInsert(obj:GetItemData(i), item_data, nil, obj, i * 10, -200)
		end

		local bc = 0
		for i = 1, obj.buffCount do
			local buff = obj:GetBuff(i)

			if buff.count ~= 0 then
				repeatInsert(buff, buff_data, nil, obj, bc * 25, -400)
				bc = bc + 1
			end
		end
	end
end

local function OnDraw()
	DrawBaseInterface()

	for i = 1, #all_Objs do
		local obj = all_Objs[i]

		if IsValidObj(obj) then
			Draw.Circle(obj, max(obj.boundingRadius, 50), 1, Draw.Color(color_by_type[obj.type]))
			DrawInfos(obj)
		end
	end
end

local function GetGameCounts()
	local c = 0

	local HeroCount = Game.HeroCount()
	base_counts["HeroCount"] = HeroCount
	if F[0] then
		for i = 1, HeroCount do
			local Hero = Game.Hero(i)
			c = c + 1

			all_Objs[c] = Hero
		end
	end

	local CampCount = Game.CampCount()
	base_counts["CampCount"] = CampCount
	if F[1] then
		for i = 1, CampCount do
			local Camp = Game.Camp(i)
			c = c + 1

			all_Objs[c] = Camp
		end
	end

	local TurretCount = Game.TurretCount()
	base_counts["TurretCount"] = TurretCount
	if F[2] then
		for i = 1, TurretCount do
			local Turret = Game.Turret(i)
			c = c + 1

			all_Objs[c] = Turret
		end
	end

	local MissileCount = Game.MissileCount()
	base_counts["MissileCount"] = MissileCount
	if F[3] then
		for i = 1, MissileCount do
			local Missile = Game.Missile(i)
			c = c + 1

			all_Objs[c] = Missile
		end
	end

	local MinionCount = Game.MinionCount()
	base_counts["MinionCount"] = MinionCount
	if F[4] then
		for i = 1, MinionCount do
			local Minion = Game.Minion(i)
			c = c + 1

			all_Objs[c] = Minion
		end
	end

	local WardCount = Game.WardCount()
	base_counts["WardCount"] = WardCount
	if F[5] then
		for i = 1, WardCount do
			local Ward = Game.Ward(i)
			c = c + 1

			all_Objs[c] = Ward
		end
	end

	local ParticleCount = Game.ParticleCount()
	base_counts["ParticleCount"] = ParticleCount
	if F[6] then
		for i = 1, ParticleCount do
			local Particle = Game.Particle(i)
			c = c + 1

			all_Objs[c] = Particle
		end
	end
end

local function GetGameVars()
	base_vars['cursorPos'] = tostring(Game.cursorPos())
	base_vars['FPS'] = Game.FPS()
	base_vars['IsChatOpen'] = tostring(Game.IsChatOpen())
	base_vars['IsOnTop'] = tostring(Game.IsOnTop())
	base_vars['Latency'] = Game.Latency()
	base_vars['mapID'] = mapIDs[Game.mapID]
	base_vars['mousePos'] = tostring(Game.mousePos())
	base_vars['myHero'] = tostring(myHero)
	base_vars['Resolution'] = tostring(Game.Resolution())
	base_vars['Timer'] = Game.Timer()
end

local function OnTick()
	all_Objs = {}
	base_counts = {}
	base_vars = {}

	GetGameCounts()
	GetGameVars()
end

local function OnWnd(msg, param)
	if msg == 257 then
		local numKey = param - 96

		if numKey >= 0 and numKey <= 10 then
			F[numKey] = not F[numKey]
		end
	end
end

Callback.Add("Tick", OnTick)
Callback.Add("Draw", OnDraw)
Callback.Add("WndMsg", OnWnd)

print("Loaded maxAPIControl by Maxxxel")
