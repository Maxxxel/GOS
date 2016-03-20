require('Inspired')
if GetObjectName(myHero) ~= "Brand" then return end
require('Collision')

--Version 1.4
--fixed DelayAction, OnDrawDmgOverHPBar, QStunOnly

-------------------------------------------------------------------------------
-----------------------------	   MENU		-----------------------------------
-------------------------------------------------------------------------------
Brand = MenuConfig("Brand", "Brand")

Brand:Menu("Keys", "Keys")
Brand.Keys:Key("Combo", "Combo", string.byte(" "))
Brand.Keys:Key("Harass", "Harass", string.byte("X"))
Brand.Keys:DropDown("Priority", "Harass Priority", 7, {"QWE", "QW", "QE", "WE", "Q", "W", "E"})

Brand:Menu("Spells", "Spells")
Brand.Spells:Boolean("QStunOnly", "Only Q to stun?", false)
Brand.Spells:Boolean("KR", "R to kill only", true)
Brand.Spells:Boolean("AutoStun", "Auto Stun", true)
Brand.Spells:Slider("StunRange", "Max. Range", 300, 100, 650, 50)

Brand:Menu("KS", "Killstuff")
Brand.KS:Boolean("KS", "Killsteal", true)
Brand.KS:Boolean("DmgOverHP", "Draw DMG over HPBar", false)
Brand.KS:Boolean("KSNotes", "KS Notes", true)
Brand.KS:Boolean("Percent", "Percent Notes", true)
Brand.KS:Boolean("Ignite","Auto-Ignite", true)
Brand.KS:Boolean("KSR", "Long Ulti", true)

Brand:Menu("Draw", "Drawings")
Brand.Draw:Boolean("Draw", "Draw", true)
Brand.Draw:Boolean("DrawB", "Draw Burning", false)
Brand.Draw:Boolean("StunRangeDraw", "DrawRange", false)
Brand.Draw:Boolean("DQ", "Draw Q", true)
Brand.Draw:Boolean("DW", "Draw W", true)
Brand.Draw:Boolean("DE", "Draw E", false)
Brand.Draw:Boolean("DR", "Draw R", false)

local Enemies = {}
local myHero = GetMyHero()
local GotBlazed = {}
local BlazeEndTime = {}
local LS, WCharge = nil, false
local WEndTime, range = 0, 0
local WPos = nil
local QRDY, WRDY, ERDY, RRDY, IRDY = 0, 0, 0, 0, 0
local QDmg, WDmg, EDmg, RDmg, AP, xIgnite = 0, 0, 0, 0, 0, 0

local function GetSpellCD()
	QRDY = GetCastLevel(myHero, _Q) > 0 and CanUseSpell(myHero, _Q) == 0 and 1 or 0
	WRDY = GetCastLevel(myHero, _W) > 0 and CanUseSpell(myHero, _W) == 0 and 1 or 0
	ERDY = GetCastLevel(myHero, _E) > 0 and CanUseSpell(myHero, _E) == 0 and 1 or 0
	RRDY = GetCastLevel(myHero, _R) > 0 and CanUseSpell(myHero, _R) == 0 and 1 or 0
end

local function GetItemCD()
	IRDY = Ignite and CanUseSpell(myHero, Ignite) == 0 and 1 
	or 0
end

local function Round(val, decimal)
	return decimal and math.floor( (val * 10 ^ decimal) + 0.5) / (10 ^ decimal) 
	or math.floor(val + 0.5)
end

local function Damage()
	AP = GetBonusAP(myHero)
	QDmg = GetCastLevel(myHero,_Q) * 40 + 40 + .65 * AP
	WDmg = GetCastLevel(myHero,_W) * 45 + 30 + .6 * AP
	EDmg = GetCastLevel(myHero,_E) * 35 + 35 + .55 * AP
	RDmg = GetCastLevel(myHero,_R) * 150 + .5 * AP
	xIgnite = (GetLevel(myHero) * 20 + 50) * IRDY
end

local function Mana(mq,mw,me,mr)
	local Qmana = 50
	local Wmana = 10 * GetCastLevel(myHero, _W) + 60
	local Emana = 5 * GetCastLevel(myHero, _E) + 65
	local Rmana = 100
	return Qmana * mq + Wmana * mw + Emana * me + Rmana * mr < GetCurrentMana(myHero) and 1 or 0
end

local function CountEnemyHeroInRange(object, range)
	object = object or myHero
	local enemyInRange = 0
	for i = 1, #Enemies do
		local enemy = Enemies[i]
		if enemy and enemy ~= object and not IsDead(enemy) and GetDistance(object, enemy) <= range then
			enemyInRange = enemyInRange + 1
		end
	end
	return enemyInRange
end

local function CountEnemyMinionInRange(object, range)
	local minion = nil
	local minionInRange = 0
	for k,v in pairs(minionManager.objects) do
		local objTeam = GetTeam(v)
		if not minion and v and objTeam == GetTeam(object) then 
			minion = v 
		end
		if minion and v and objTeam == GetTeam(object) and GetDistanceSqr(GetOrigin(minion),GetOrigin(object)) > GetDistanceSqr(GetOrigin(v),GetOrigin(object)) then
			minion = v
		end
		if minion and v and objTeam == GetTeam(object) and GetDistance(GetOrigin(minion),GetOrigin(object)) <= range then
			minionInRange = minionInRange + 1
		end
	end
	return minionInRange
end

local function CountEnemyObjectsInRange(Object, range)
	Object = Object or myHero
	range = range or 99999
	local a = CountEnemyHeroInRange(Object, range)
	local b = CountEnemyMinionInRange(Object, range)
	return a + b
end

local function resetVariables()
	GetItemCD()
	Damage()
	if GetTickCount() > WEndTime then
		WEndTime = 0
		WCharge = false
		WPos = nil
	end
	GetSpellCD()
	for i = 1, #Enemies do
		local Enemy = Enemies[i]
		if BlazeEndTime[GetNetworkID(Enemy)] and (BlazeEndTime[GetNetworkID(Enemy)] < GetTickCount() or IsDead(Enemy)) then
			BlazeEndTime[GetNetworkID(Enemy)] = nil
			GotBlazed[GetNetworkID(Enemy)] = nil
		end
	end
end

local function QCanHit(unit)
	local QPred = GetPredictionForPlayer(GetOrigin(myHero),unit,GetMoveSpeed(unit),1532,250 + GetLatency(),1044,75,true,false)
	local CollisionE = Collision(1044, 1532, 250 + GetLatency(), 75)
	local CollisionCheck, Objects = CollisionE:__GetMinionCollision(myHero,Point(QPred.PredPos.x, QPred.PredPos.z),ENEMY)
	if QPred.PredPos and QPred.HitChance == 1 then
		if not CollisionCheck then
			return true
		else
			return false
		end
	else
		return false
	end
end

local function WCanHit(unit)
	if unit then
		local WPred = GetPredictionForPlayer(GetOrigin(myHero), unit, GetMoveSpeed(unit), 99999, 900 + GetLatency(), 875, 187, false, true)
		if WPred.HitChance == 1 then
			return true
		else
			return false
		end
	else
		return false
	end
end

local function GetWCharge()
	local time = 0
	if WCharge then
		time = ((WEndTime - GetTickCount())) * .001
		return time
	end
end

local function TravelTime(spell, unit, tick)
	local time = 99999
	local speed = 1
	local Distance = GetDistance(unit)
	local ping = GetLatency()
	local extra = tick and GetTickCount() or 0
	if spell == "Q" then
		speed = 1600
		time = Distance / speed + extra
		return time
	elseif spell == "W" then
		time = GetWCharge() + extra
		return time
	elseif spell == "E" then
		speed = Distance * 4
		time = Distance / speed + extra
		return time
	elseif spell == "R" then
		speed = Distance * 2
		time = Distance / speed + extra
		return time
	else
		return time
	end
end

local function IsTargetedBySpell(unit)
	if WPos and GetDistance(unit, WPos) < 187 + GetHitBox(unit) then --means he is standing in range, now we need to know if he can escape
		local MS = GetMoveSpeed(unit)
		local reactionTime = 1000
		local PossibleWay = (WEndTime - GetTickCount() - reactionTime) * MS
		if PossibleWay < GetDistance(unit, WPos) + GetHitBox(unit) then --means he cant escape, mostly if CC'ed or standing
			return true, "W"
		elseif PossibleWay < GetDistance(unit, WPos) + GetHitBox(unit) + 500 then --means he cant escape if he is noob
			return true, "W"
		else
			return false, nil
		end
	end
end

local function TimeTillBurnIncoming(unit)
	local time = 99999
	state, spell = IsTargetedBySpell(unit)
	if state then
		time = TravelTime(spell, unit)
	else
		time = 99999
	end
	return time
end

local function IsIgnited(o)
	return GotBuff(o, "summonerdot") ~= 0 and 1 
	or 0
end

local function IsOrWillBeIgnited(o)
	return IRDY == 1 and 1 
	or IsIgnited(o) == 1 and 1 
	or 0
end

local function IsBurning(unit, spell)
	local spell = spell or nil
	if not spell and (GotBlazed[GetNetworkID(unit)] or 0) > 0 then --if enemy is burning and no spell is given return true
		return true
	elseif spell and (GotBlazed[GetNetworkID(unit)] or 0) > 0 and (BlazeEndTime[GetNetworkID(unit)] or 0) > TravelTime(spell, unit, tick) then --if enemy is burning and the traveltime of given spell is shorter then his Burning is over return true
		return true
	elseif spell and TimeTillBurnIncoming(unit) < TravelTime(spell, unit) then --if enemy is not burning but any burn spell makes him burn in time before given spell reaches return true
		return true
	else
		return false
	end
end

local function GetRBounce(o)
	local Speed = o and GetMoveSpeed(o) or 0
	local NumEnemies = (math.min(CountEnemyObjectsInRange(o, 400 - Speed * .25), 4) - 1) --example: around the target is no unit RBounce returns: 1, 2 units: 2
	if IsBurning(o) or IsBurning(o, "R") then --it focuses on heroes, so we need to look if enemy heroes are there
		local NumHeroes = CountEnemyHeroInRange(o, 400 - Speed * .25)
		if NumHeroes > 0 then --so there are enemy heroes we need to take into account
			return o and NumHeroes == 1 and 3 or o and NumHeroes == 2 and 2 or o and NumHeroes >= 3 and 1 or 1
		else --so it jumps on hero after each minion
			return o and NumEnemies >= 1 and 3 or 1
		end
	else
		return o and NumEnemies == 1 and 3 or o and NumEnemies == 2 and 2 or o and NumEnemies >= 3 and 1 or 1
	end
end

local function doQ(o)
	if GetDistance(o) < 1044 then
		local QPred = GetPredictionForPlayer(GetOrigin(myHero), o ,GetMoveSpeed(o) ,1532, 250 + GetLatency(), 1044, 75, true, false)
		if QPred.HitChance == 1 then
			CastSkillShot(_Q, QPred.PredPos)
		end
	end
end

local function doW(o)
	if GetDistance(o) < 875 then
    	local WPred = GetPredictionForPlayer(GetOrigin(myHero), o, GetMoveSpeed(o), 99999, 900 + GetLatency(), 875, 187, false, true)
		if WPred.HitChance == 1 then
			CastSkillShot(_W, WPred.PredPos)
    	end
  	end
end

local function doE(o)
	if GetDistance(o) < 650 then
		CastTargetSpell(o, _E)
	end
end

local function dooR(o)
	if GetDistance(o) < 750 then
		CastTargetSpell(o, _R)
	end
end

local function doEW(o)
	local WPred = GetPredictionForPlayer(GetOrigin(myHero), o, GetMoveSpeed(o), 99999, 900 + GetLatency(), 875, 187, false, true)
	if WPred.HitChance == 1 and GetDistance(o) < 650 then
		CastTargetSpell(o, _E)
		CastSkillShot(_W, WPred.PredPos)
	end
end

local function doQE(o)
	local QPred = GetPredictionForPlayer(GetOrigin(myHero), o ,GetMoveSpeed(o) ,1532, 250 + GetLatency(), 1044, 75, true, false)
	if QPred.HitChance == 1 and GetDistance(o) < 650 then
		CastSkillShot(_Q, QPred.PredPos)
		CastTargetSpell(o, _E)
	end
end

local function doWQ(o)
	local QPred = GetPredictionForPlayer(GetOrigin(myHero), o ,GetMoveSpeed(o) ,1532, 250 + GetLatency(), 1044, 75, true, false)
	local WPred = GetPredictionForPlayer(GetOrigin(myHero), o, GetMoveSpeed(o), 99999, 900 + GetLatency(), 875, 187, false, true)
	if WPred.HitChance == 1 and QPred.HitChance == 1 and GetDistance(o) < 875 then
		CastSkillShot(_W, WPred.PredPos)
		CastSkillShot(_Q, QPred.PredPos)
	end
end

local function doQW(o)
	local QPred = GetPredictionForPlayer(GetOrigin(myHero), o ,GetMoveSpeed(o) ,1532, 250 + GetLatency(), 1044, 75, true, false)
	local WPred = GetPredictionForPlayer(GetOrigin(myHero), o, GetMoveSpeed(o), 99999, 900 + GetLatency(), 875, 187, false, true)
	if WPred.HitChance == 1 and QPred.HitChance == 1 and GetDistance(o) < 875 then
		CastSkillShot(_Q, QPred.PredPos)
		CastSkillShot(_W, WPred.PredPos)
	end
end

local function doEQW(o)
	local QPred = GetPredictionForPlayer(GetOrigin(myHero), o ,GetMoveSpeed(o) ,1532, 250 + GetLatency(), 1044, 75, true, false)
	local WPred = GetPredictionForPlayer(GetOrigin(myHero), o, GetMoveSpeed(o), 99999, 900 + GetLatency(), 875, 187, false, true)
	if WPred.HitChance == 1 and QPred.HitChance == 1 and GetDistance(o) < 650 then
		CastTargetSpell(o, _E)
		CastSkillShot(_Q, QPred.PredPos)
		CastSkillShot(_W, WPred.PredPos)
	end
end

local function AutoStun()
	for i = 1, #Enemies do
		local Enemy = Enemies[i]
		IsBurning(Enemy, "Q")
		if GetDistance(Enemy) < Brand.Spells.StunRange:Value() then
			if (QRDY == 1 and QCanHit(Enemy) and ERDY == 1) then
				doE(Enemy)
			elseif (IsBurning(Enemy, "Q") or IsBurning(Enemy)) and QRDY == 1 and QCanHit(Enemy) then
				doQ(Enemy)
			end
		end
	end
end

local function AutoIgnite()
	for i = 1, #Enemies do
		local Target = Enemies[i]
		if ValidTarget(Target) then
			local HP = GetCurrentHP(Target)
			if HP <= xIgnite and GetDistance(Target) <= 600 then
				if QRDY == 1 and HP <= QDmg then
					doQ(Target)
				elseif WRDY == 1 and HP <= WDmg then
					doW(Target)
				elseif ERDY == 1 and HP <= EDmg then
					doE(Target)
				else
					if IRDY == 1 then
						CastTargetSpell(Target, Ignite)
					end
				end
			end
		end
	end
end

local function Harass()
	if ValidTarget(target) then
		if GetDistance(target) < range then
			if Brand.Keys.Priority:Value() == 1 then
				doQ(target)
				doW(target)
				doE(target)
			elseif Brand.Keys.Priority:Value() == 2 then
				doQ(target)
				doW(target)
			elseif Brand.Keys.Priority:Value() == 3 then
				doQ(target)
				doE(target)
			elseif Brand.Keys.Priority:Value() == 4 then
				doW(target)
				doE(target)
			elseif Brand.Keys.Priority:Value() == 5 then
				doQ(target)
			elseif Brand.Keys.Priority:Value() == 6 then
				doW(target)
			elseif Brand.Keys.Priority:Value() == 7 then
				doE(target)
			end
		end
	end
end

local function Combo()
	if ValidTarget(target) then
		if GetDistance(target) < range then
			myRange = 1050
			local DIST = GetDistance(target)
			if DIST < range then
				local armor = GetMagicResist(target)
			  	local hp = GetCurrentHP(target)
			  	local mhp = GetMaxHP(target)
			  	local hpreg = GetHPRegen(target) * (1 - (IsOrWillBeIgnited(target) * .5))
				local Health = hp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(target)
				local maxHealth = mhp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(target)
				local care = GetBuffData(target, "brandablaze")
				local burntime = care.ExpireTime - GetTickCount() > 0 and (care.ExpireTime - GetTickCount()) * .001 or 4
				local PDMG = ((maxHealth * .02 * burntime) - (hpreg * .2 * burntime)) * (IsBurning(target) and 1 or 0)
				local TotalDamage = xIgnite * IRDY + (QDmg * QRDY + WDmg * WRDY * (IsBurning(target) and 1.25 or 1) + EDmg * ERDY + RDmg * RRDY * GetRBounce(target) + PDMG) * Mana(QRDY, WRDY, ERDY, RRDY)
				local TotalDamageNoR = xIgnite * IRDY + (QDmg * QRDY + WDmg * WRDY * (IsBurning(target) and 1.25 or 1) + EDmg * ERDY + PDMG) * Mana(QRDY, WRDY, ERDY, RRDY)
				local TotalDamageNoIgnite = (QDmg * QRDY + WDmg * WRDY * (IsBurning(target) and 1.25 or 1) + EDmg * ERDY + RDmg * RRDY * GetRBounce(target) + PDMG) * Mana(QRDY, WRDY, ERDY, RRDY)
				local TotalDamageNoRNoIgnite = (QDmg * QRDY + WDmg * WRDY * (IsBurning(target) and 1.25 or 1) + EDmg * ERDY + PDMG) * Mana(QRDY, WRDY, ERDY, RRDY)
				if Health < TotalDamageNoR then
					if ERDY == 1 then doE(target) end
					if QRDY == 1 then doQ(target) end
					if WRDY == 1 then doW(target) end
					if not Brand.Spells.KR:Value() then
						if RRDY == 1 then
							dooR(target)
						end
					end
					if Brand.KS.Ignite:Value() and Health > TotalDamageNoRNoIgnite and DIST < 650 then
						CastTargetSpell(target, Ignite)
					end
				elseif Health < TotalDamage then
					if ERDY == 1 then doE(target) end
					if QRDY == 1 then doQ(target) end
					if WRDY == 1 then doW(target) end
					if RRDY == 1 and Health < TotalDamage and Health > TotalDamageNoR then
						dooR(target)
					end
					if Brand.KS.Ignite:Value() and Health > TotalDamageNoIgnite and DIST < 650 then
						CastTargetSpell(target, Ignite)
					end
				else
					if IsBurning(target) then
						if QRDY == 1 then
							if Brand.Spells.QStunOnly:Value() then
								doQ(target)
							elseif WRDY + ERDY == 0 or GetDistance(target) > 875 and GetDistance(target) < 1050 and GetMoveSpeed(target) > GetMoveSpeed(myHero) then
								doQ(target)
							end
						end
						if ERDY == 1 then doE(target) end
						if WRDY == 1 then doW(target) end
						if RRDY == 1 then
							if not Brand.Spells.KR:Value() then
								dooR(target)
							end
						end
					else
						if ERDY == 1 then doE(target) end
						if WRDY == 1 then doW(target) end
						if QRDY == 1 then
							if Brand.Spells.QStunOnly:Value() then
								if IsBurning(target) then
									doQ(target)
								end
							else
								if WRDY + ERDY == 0 or GetDistance(target) > 875 and GetDistance(target) < 1050 and GetMoveSpeed(target) > GetMoveSpeed(myHero) then
									doQ(target)
								end
							end
						end
						if RRDY == 1 then
							if not Brand.Spells.KR:Value() then
								dooR(target)
							end
						end
					end
				end
			end
		end
	end
end

local function Kills()
	for i = 1, #Enemies do
		local Enemy = Enemies[i]
  		local DIST = GetDistance(Enemy)
    	if ValidTarget(Enemy) and DIST < 2000 then
      		local armor = GetMagicResist(Enemy)
	    	local hp = GetCurrentHP(Enemy)
	    	local mhp = GetMaxHP(Enemy)
	    	local hpreg = GetHPRegen(Enemy) * (1 - (IsOrWillBeIgnited(Enemy) * .5))
      		local Health = hp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(Enemy)
      		local maxHealth = mhp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(Enemy)
      		local PDMG = (maxHealth * .08 - hpreg * .8) * (IsBurning(Enemy) and 1 or 0)
    		local TotalDamage = xIgnite * IRDY + (QDmg * QRDY + WDmg * WRDY * (IsBurning(Enemy) and 1.25 or 1) + EDmg * ERDY + RDmg * RRDY * (GetRBounce(Enemy)) + PDMG) * Mana(QRDY, WRDY, ERDY, RRDY)
    		if DIST < range then
	      		if Health < QDmg + PDMG and QRDY == 1 and Mana(1,0,0,0) == 1 and QCanHit(Enemy) then
					doQ(Enemy)	
				elseif Health < WDmg + PDMG  and WRDY == 1 and Mana(0,1,0,0) == 1 and WCanHit(Enemy) then
					doW(Enemy)
				elseif Health < EDmg + PDMG  and ERDY == 1 and Mana(0,0,1,0) == 1 then
					doE(Enemy)
				elseif Health < EDmg + WDmg * 1.25 + PDMG and ERDY == 1 and WRDY == 1 and Mana(0,1,1,0) == 1 and WCanHit(Enemy) then
					doEW(Enemy)
				elseif Health < EDmg + QDmg + PDMG  and ERDY == 1 and QRDY == 1 and Mana(1,0,1,0) == 1 and QCanHit(Enemy) then
					doQE(Enemy)
				elseif Health < QDmg + WDmg + PDMG  and QRDY == 1 and WRDY == 1 and Mana(1,1,0,0) == 1 and QCanHit(Enemy) and WCanHit(Enemy) then
					doWQ(Enemy)
				elseif Health < QDmg + WDmg * 1.25 + PDMG  and QRDY == 1 and WRDY == 1 and Mana(1,1,0,0) == 1 and QCanHit(Enemy) and WCanHit(Enemy) then
					doQW(Enemy)
				elseif Health < QDmg + WDmg * 1.25 + EDmg + PDMG  and QRDY == 1 and WRDY == 1 and ERDY == 1 and Mana(1,1,1,0) == 1 and QCanHit(Enemy) and WCanHit(Enemy) then
					doEQW(Enemy)
				end
				for j = 1, #Enemies do
					local OtherEnemy = Enemies[j]
					if OtherEnemy and Enemy ~= OtherEnemy then
						local HP = GetCurrentHP(OtherEnemy)
						local MHP = GetMaxHP(Enemy)
						local ARMOR = GetMagicResist(OtherEnemy)
						local HPREG = GetHPRegen(OtherEnemy) * (1 - (IsOrWillBeIgnited(OtherEnemy) * .5))
						local HEALTH = HP * ((100 + ((ARMOR - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + HPREG * 6 + GetMagicShield(OtherEnemy)
						local MAXHEALTH = MHP * ((100 + ((ARMOR - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + HPREG * 6 + GetMagicShield(OtherEnemy)
						local pdmg = (MAXHEALTH * .08 - HPREG * .8) * (IsBurning(OtherEnemy) and 1 or 0)
						if HEALTH < (RDmg * RRDY + pdmg) and GetCurrentMana(myHero) >= 100 and Brand.KS.KSR:Value() and DIST < 750 and GetDistance(OtherEnemy) > 750 and GetDistance(Enemy, OtherEnemy) <= 400 - (GetMoveSpeed(OtherEnemy) + GetMoveSpeed(Enemy))* .5 * .25 then
							dooR(Enemy)
						end
					end
				end
			end
		end
	end
end

OnTick(function(myHero)
	Enemies = GetEnemyHeroes()
	target = GetCurrentTarget()
	range = (QRDY == 1 and (target and QCanHit(target) or true) and QRDY * 1050) or (WRDY == 1 and (target and WCanHit(target) or true) and WRDY * 875) or (ERDY > 0 and ERDY * 650) or (RRDY > 0 and RRDY * 750) or (IRDY * 650) or 0 
	resetVariables()
	if Brand.Keys.Combo:Value() then
		Combo()
	elseif Brand.Keys.Harass:Value() then
		Harass()
	else
		if Brand.Spells.AutoStun:Value() then
			AutoStun()
		end
		if Brand.KS.KS:Value() then
			Kills()
		end
	end
	if Brand.KS.Ignite:Value() then
		AutoIgnite()
	end
end)

OnDraw(function(myHero)
	if Brand.Draw.Draw:Value() then
		dQ = QRDY == 1 and Brand.Draw.DQ:Value() and 1050 or 0
		dW = WRDY == 1 and Brand.Draw.DW:Value() and 875 or 0
		dE = ERDY == 1 and Brand.Draw.DE:Value() and 650 or 0
		dR = RRDY == 1 and Brand.Draw.DR:Value() and 750 or 0
		if dQ ~= 0 then DrawCircle(GetOrigin(myHero), dQ, 0, 0, 0xffff0000) end
		if dW ~= 0 then DrawCircle(GetOrigin(myHero), dW, 0, 0, 0xffff0000) end
		if dE ~= 0 then DrawCircle(GetOrigin(myHero), dE, 0, 0, 0xffff0000) end
		if dR ~= 0 then DrawCircle(GetOrigin(myHero), dR, 0, 0, 0xffff0000) end
		for i = 1, #Enemies do
			local Enemy = Enemies[i]
			if Brand.Draw.DrawB:Value() and IsBurning(Enemy) then
				DrawCircle(GetOrigin(Enemy), 100, 0, 0, 0xffff0000)
			end
  			local DIST = GetDistance(Enemy)
    		if ValidTarget(Enemy)  then
				local drawPos = GetOrigin(Enemy)
				local armor = GetMagicResist(Enemy)
				local hp = GetCurrentHP(Enemy)
				local mhp = GetMaxHP(Enemy)
				local hpreg = GetHPRegen(Enemy) * (1 - (IsOrWillBeIgnited(Enemy) * .5))
	      		local Health = hp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(Enemy)
	      		local maxHealth = mhp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(Enemy)
	      		local care = GetBuffData(Enemy, "brandablaze")
				local burntime = care.ExpireTime - GetTickCount() > 0 and (care.ExpireTime - GetTickCount()) * .001 or 4
	      		local PDMG = ((maxHealth * .02 * burntime) - (hpreg * .2 * burntime)) * (IsBurning(Enemy) and 1 or 0)
	      		local TotalDamage = xIgnite * IRDY + (QDmg * QRDY + WDmg * WRDY * (IsBurning(Enemy) and 1 or 1.25) + EDmg * ERDY + RDmg * RRDY * (GetRBounce(Enemy) + PDMG)) * Mana(QRDY, WRDY, ERDY, RRDY)
	    		if Health < TotalDamage - RDmg * RRDY * (GetRBounce(Enemy)) then --no Ulti need
	    			if Brand.KS.KSNotes:Value() then
	         			DrawCircle(GetOrigin(Enemy), 50, 0, 0, 0xffff0000)
	        		end
	      		elseif Health < TotalDamage then
	        		if Brand.KS.KSNotes:Value() then
	          			DrawCircle(GetOrigin(Enemy), 100, 0, 0, 0xffff0000)
	        		end
	      		else
	      			if Round(((Health - TotalDamage) / maxHealth * 100), 0) > 0 and Brand.KS.Percent:Value() then
						local drawing = WorldToScreen(1, drawPos)
						local rounded = Round(((Health - TotalDamage) / maxHealth * 100), 0)
						DrawText("\n\n" .. rounded .. "%", 15, drawing.x, drawing.y, 0xffff0000) 
					end
	      		end
	      		if Brand.KS.DmgOverHP:Value() then
	      			local atotDmg = 0
					local ahp = GetCurrentHP(Enemy)
					if ahp > xIgnite * IRDY + CalcDamage(myHero, Enemy, 0, (QDmg * QRDY + WDmg * WRDY * (IsBurning(Enemy) and 1 or 1.25) + EDmg * ERDY + RDmg * RRDY * (GetRBounce(Enemy) + PDMG)) * Mana(QRDY, WRDY, ERDY, RRDY)) then
						atotDmg = xIgnite * IRDY + CalcDamage(myHero, Enemy, 0, (QDmg * QRDY + WDmg * WRDY * (IsBurning(Enemy) and 1 or 1.25) + EDmg * ERDY + RDmg * RRDY * (GetRBounce(Enemy) + PDMG)) * Mana(QRDY, WRDY, ERDY, RRDY))
					else
						atotDmg = ahp
					end
					DrawDmgOverHpBar(Enemy, ahp, 0, atotDmg, 0xffff0000)
				end
	    	end
		end
		if Brand.Draw.StunRangeDraw:Value() then
			DrawCircle(GetOrigin(myHero), Brand.Spells.StunRange:Value(), 0, 0, 0xffff0000)
		end
	end
end)

OnUpdateBuff(function(unit,buff)
	if GetTeam(unit) ~= GetTeam(myHero) and buff.Name:lower():find("brandablaze") then
		local ID = GetNetworkID(unit)
		DelayAction(function()
			GotBlazed[ID] = buff.Count
			BlazeEndTime[ID] = GetTickCount() + 4000
		end, .3)
	end
end)

OnRemoveBuff(function(unit,buff)
	if GetTeam(unit) ~= GetTeam(myHero) and buff.Name:lower():find("brandablaze") then
		local ID = GetNetworkID(unit)
		DelayAction(function()
			GotBlazed[ID] = 0
			BlazeEndTime[ID] = 0
		end, .3)
	end
end)

OnProcessSpell(function(unit, spell)
	if unit == myHero and spell then
		if spell.name == "BrandFissure" then
			WCharge = true
			WPos = spell.endPos
			WEndTime = GetTickCount() + 1000
		end
	end
end)
