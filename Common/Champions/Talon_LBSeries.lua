if GetObjectName(myHero) ~= "Talon" then return end

Talon=MenuConfig("Talon","Maxxxel Talon God")
Talon:Key("Combo","Combo",string.byte(" "))
Talon:Boolean("M", "Mouse", false)
Talon:Menu("KS","Killfunctions")
Talon.KS:Boolean("Ignite","Auto-Ignite",true)
Talon.KS:Boolean("R", "Smart Ulti",true)
Talon.KS:Boolean("AR", "AOE Ulti", true)
Talon.KS:Slider("AOER", "AOE Ulti, Enemies >", 3, 0, 5, 1)
Talon.KS:Boolean("Percent","Show % Kill",true)
Talon:Menu("Harass", "Harass Menu")
Talon.Harass:Key("DoIt","Harass",string.byte("X"))
Talon.Harass:Boolean("Auto", "Auto Harass", false)
Talon.Harass:Slider("Mana", "Minimum Mana %", 40, 0, 100, 1)
------------------------------------------
--version = 1.7
--Ignite Fix
------------------------------------------

------------------------------------------
--Variables
------------------------------------------
local xHydra, HRDY, QRDY, WRDY, ERDY, R1RDY, R2RDY, HydraCast, HydraCastTime, xAA, xQ, xQ2, xW, xE, xR, IRDY, xIgnite, Wtime, dmgOverTime, Check, lastAA, AAREADY = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
local target, LS
local summonerNameOne = GetCastName(myHero,SUMMONER_1)
local summonerNameTwo = GetCastName(myHero,SUMMONER_2)
local Ignite = (summonerNameOne:lower():find("summonerdot") and SUMMONER_1 or (summonerNameTwo:lower():find("summonerdot") and SUMMONER_2 or nil))
local myHero = GetMyHero()
local stopMove, doQ = false, false
------------------------------------------
--Tables
------------------------------------------
local KSN = {}
local n = {}
------------------------------------------
--Check for Items
------------------------------------------
local function CheckItemCD()
  HydraCast = HydraCastTime ~= 0 and HydraCast == 1 and (GetTickCount() - HydraCastTime) >= 10000 and 0 or HydraCast
  HydraCastTime = HydraCastTime ~= 0 and HydraCast == 1 and (GetTickCount() - HydraCastTime) >= 10000 and 0 or HydraCastTime
  HRDY = GetItemSlot(myHero,3077) + GetItemSlot(myHero,3074) > 0 and HydraCast == 0 and 1 or 0
  IRDY = Ignite and CanUseSpell(myHero, Ignite) == 0 and 1 or 0
end
------------------------------------------
--Check for Spell Damage
------------------------------------------
local function DamageFunc()
	local base = GetBaseDamage(myHero)
	local bonus = GetBonusDmg(myHero)
	xAA = base + bonus
	xQ = xAA + 30 * GetCastLevel(myHero,_Q) + .3 * bonus
	xQ2 = (9 * GetCastLevel(myHero,_Q) + bonus) - dmgOverTime
	xW = 2 * (5 + 25 * GetCastLevel(myHero,_W) + .6 * bonus)
	xE = 1 + GetCastLevel(myHero,_E) * .03
	xR = 70 + GetCastLevel(myHero,_R) * 50 + .75 * bonus
	xHYDRA = .6 * xAA *HRDY
	xIgnite = (50 + GetLevel(myHero) * 20) * IRDY
end
------------------------------------------
--MISC
------------------------------------------
local function MoveToMouse()
	if Talon.M:Value() == true then
		if LS ~= "E" or stopMove == true then
			MoveToXYZ(GetMousePos())
  	end
  end
end

local function Valid(unit)
  return unit and not IsDead(unit) and IsTargetable(unit) and not IsImmune(unit, myHero) and IsVisible(unit) or false
end

local function HasE(unit)
	return GotBuff(unit,"talondamageamp") ~= 0 or false
end

local function Emulti(unit)
  return HasE(unit) and ERDY == 0 and 1 or 0
end

local function Wmulti()
  return GetTickCount() - Wtime <= 0 and WRDY == 0 and 1 or 0
end

local function HasQ2(unit)
	return GotBuff(unit,"talonbleeddebuff") ~= 0 or false
end

local function IsMoving(unit)
	local t = GetPredictionForPlayer(GetOrigin(myHero), unit, GetMoveSpeed(unit), 99999, 0, 2000, 1, false, false)
	local k = {x = t.PredPos.x, y = t.PredPos.y, z = t.PredPos.z}
	local p = GetOrigin(unit)
	local d1 = GetDistance(p)
	local d2 = GetDistance(k)
	return d1 < d2 and 1 or 0
end
------------------------------------------
--Get Target to Harass
------------------------------------------
function GetTarget(range, damageType)	
	damageType = damageType or 2
    local target, steps = nil, 10000
    for _, k in pairs(GetEnemyHeroes()) do
        local step = GetCurrentHP(k) / CalcDamage(GetMyHero(), k, DAMAGE_PHYSICAL == damageType and 100 or 0, DAMAGE_MAGIC == damageType and 100 or 0)
        if k and ValidTarget(k, range) and step < steps then
            target = k
            steps = step
        end
    end
    return target
end
------------------------------------------
--Check Spells for CD
------------------------------------------
local function CD(a,b,c,d,e)
	QRDY = GetCastName(myHero,_Q) == "TalonNoxianDiplomacy" and GetCastLevel(myHero,_Q) >= 1 and CanUseSpell(myHero, _Q) == READY and 1 or GotBuff(myHero,"talonnoxiandiplomacybuff") ~= 0 and 1 or 0
	WRDY = GetCastName(myHero,_W) == "TalonRake" and GetCastLevel(myHero,_W) >= 1 and CanUseSpell(myHero, _W) == READY and 1 or 0
	ERDY = GetCastName(myHero,_E) == "TalonCutthroat" and GetCastLevel(myHero,_E) >= 1 and CanUseSpell(myHero, _E) == READY and 1 or 0
	R1RDY = GetCastName(myHero,_R) == "TalonShadowAssault" and GetCastName(myHero,_R) ~= "talonshadowassaulttoggle" and GetCastLevel(myHero,_R) >= 1 and CanUseSpell(myHero, _R) == READY and 1 or 0
	R2RDY = GetCastName(myHero,_R) == "talonshadowassaulttoggle" and GetCastLevel(myHero,_R) >= 1 and CanUseSpell(myHero, _R) == READY and 1 or 0
	return (QRDY == a or a == n) and (WRDY == b or b == n) and (ERDY == c or c == n) and (R1RDY == d or d == n) and (R2RDY == e or e == n) and 1 or 0
end
------------------------------------------
--Check Spells for Mana
------------------------------------------
local function Mana(a,b,c,d,e)
	a = a == 1 and 35 + GetCastLevel(myHero,_Q) * 5 or 0
	b = b == 1 and 55 + GetCastLevel(myHero,_W) * 5 or 0
	c = c == 1 and 30 + GetCastLevel(myHero,_E) * 5 or 0
	d = d == 1 and 70 + GetCastLevel(myHero,_R) * 10 or 0
	return GetCurrentMana(myHero) > a + b + c + d and 1 or 0
end
------------------------------------------
--Spells
------------------------------------------
local function W(o)
	if GetDistance(o) <= 700 - GetMoveSpeed(o) * IsMoving(o) * .1 then
		local WSS = GetPredictionForPlayer(GetOrigin(myHero), o, GetMoveSpeed(o), 1200, 250, 700, (700 - GetDistance(o)) * .5, false, false)
		if WSS.HitChance == 1 then
			CastSkillShot(_W, WSS.PredPos)
		end
	end
end

local function E(o)
	if GetDistance(o) <= 700 then
		stopMove = true
		CastTargetSpell(o, _E)
		if AAREADY ~= 1 and doQ and GetDistance(o) <= 300 then
			CastSpell(_Q)
		end
	end
end

local function R1(o)
	if GetDistance(o) <= 650 - GetMoveSpeed(o) * IsMoving(o) * .15 then
		CastSpell(_R)
	end
end

local function R2(o)
	if GetCastName(myHero, _R) == "talonshadowassaulttoggle" and GetDistance(o) <= 650 - GetMoveSpeed(o) * IsMoving(o) * .15 then
	  CastSpell(_R)
	end
end
------------------------------------------
--Function to round the numbers in Killnotis
------------------------------------------
local function Round(val, decimal)
		return decimal ~= nil and math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal) or math.floor(val + 0.5)
end
------------------------------------------
--Main Function, calcs the Killnotis and which Spell to use on Combo
------------------------------------------
local function SpellSequence()
	if #n > 0 then
		for  i = 1, #n do
	    local name = GetObjectName(n[i])
	  	local armor = GetArmor(n[i])
	  	local hp = GetCurrentHP(n[i])
	  	local mhp = GetMaxHP(n[i])
	  	local hpreg = GetHPRegen(n[i])
			local shield = GetDmgShield(n[i])
		 	local maxHealth = mhp * ((100 + ((armor - GetArmorPenFlat(myHero)) * GetArmorPenPercent(myHero))) * .01) + hpreg * 6 + shield
		 	local health = hp * ((100 + ((armor - GetArmorPenFlat(myHero)) * GetArmorPenPercent(myHero))) * .01) + hpreg * 6 + shield
    	if GetDistance(n[i]) <= 2000 and Talon.KS.Percent and Valid(n[i]) then
	      local maxDMG = 		xHYDRA + xIgnite + (xAA * ((1 + (-1 * (ERDY + Emulti(n[i])))) + xE * (ERDY + Emulti(n[i])))) + ((xQ * QRDY) * ((1 + (-1 * (ERDY * Emulti(n[i])))) + xE * (ERDY + Emulti(n[i]))) + (xQ2 * QRDY)) + xW * (WRDY + Wmulti()) * ((1 + (-1 * (ERDY + Emulti(n[i]))) + xE * (ERDY + Emulti(n[i])))) + xR * (R1RDY + R2RDY) * ((1 + (-1 * (ERDY + Emulti(n[i]))) + xE * (ERDY + Emulti(n[i]))) * (2 -  R2RDY))
	      local maxDMGNoR = xHYDRA + xIgnite + (xAA * ((1 + (-1 * (ERDY + Emulti(n[i])))) + xE * (ERDY + Emulti(n[i])))) + ((xQ * QRDY) * ((1 + (-1 * (ERDY + Emulti(n[i])))) + xE * (ERDY + Emulti(n[i]))) + (xQ2 * QRDY)) + xW * (WRDY + Wmulti()) * ((1 + (-1 * (ERDY + Emulti(n[i]))) + xE * (ERDY + Emulti(n[i]))))
    		local seconds = 0
    		local Q2Timer = 0
    		Q2Timer = HasQ2(n[i]) and Q2Timer == 0 and GetTickCount() or seconds >= 6 and 0 or Q2Timer
    		seconds = HasQ2(n[i]) and Q2Timer ~= 0 and (GetTickCount() - Q2Timer) * .001 or 0
    		dmgOverTime = HasQ2(n[i]) and seconds ~= 0 and ((10 * GetCastLevel(myHero,_Q) + GetBonusDmg(myHero)) / 6) * seconds or 0
    		if health < R2RDY * xR then
    			R2(n[i])
    		end
    		if		 HRDY == 1 and IRDY == 1 and health < maxDMG and GetDistance(n[i]) <= 300 and Talon.Combo:Value() and target and n[i] == target then
					CastOffensiveItems(n[i])
					CastTargetSpell(n[i], Ignite)
    		elseif HRDY == 1 and IRDY == 0 and health < maxDMG and GetDistance(n[i]) <= 300 and Talon.Combo:Value() and target and n[i] == target then
    			CastOffensiveItems(n[i])
    		elseif HRDY == 0 and IRDY == 1 and health < maxDMG and GetDistance(n[i]) <= 300 and Talon.Combo:Value() and target and n[i] == target then
    			CastTargetSpell(n[i], Ignite)
    		elseif IRDY == 1 and health < xIgnite and GetDistance(n[i]) <= 600 then
    			CastTargetSpell(n[i], Ignite)
    		end
			end
		end
	end
end
--
local function Combo()
	target = GetCurrentTarget()
	if target and Valid(target) and GetDistance(target) <= 750 then
		local DIST = GetDistance(target)
		local ARMOR = GetArmor(target)
		local HPREG = GetHPRegen(target)
		local HP = GetCurrentHP(target)
		local MOVE = GetMoveSpeed(target)
		local SHIELD = GetDmgShield(target)
		local LIFE = HP * ((100 + ((ARMOR - GetArmorPenFlat(myHero)) * GetArmorPenPercent(myHero))) * .01) + HPREG * 6 + SHIELD
		local myRange = GetRange(myHero) + GetHitBox(target) + GetHitBox(myHero) - (IsMoving(target) * 5) * IsMoving(target) * (GetWindUp(myHero) + GetLatency() * .001)
		local maxDMG = 		xHYDRA + xIgnite + (xAA * ((1 + (-1 * (ERDY + Emulti(target)))) + xE * (ERDY + Emulti(target)))) + ((xQ * QRDY) * ((1 + (-1 * (ERDY * Emulti(target)))) + xE * (ERDY + Emulti(target))) + (xQ2 * QRDY)) + xW * (WRDY + Wmulti()) * ((1 + (-1 * (ERDY + Emulti(target))) + xE * (ERDY + Emulti(target)))) + xR * (R1RDY + R2RDY) * ((1 + (-1 * (ERDY + Emulti(target))) + xE * (ERDY + Emulti(target))) * (2 -  R2RDY))
 		local maxDMGNoR = xHYDRA + xIgnite + (xAA * ((1 + (-1 * (ERDY + Emulti(target)))) + xE * (ERDY + Emulti(target)))) + ((xQ * QRDY) * ((1 + (-1 * (ERDY + Emulti(target)))) + xE * (ERDY + Emulti(target))) + (xQ2 * QRDY)) + xW * (WRDY + Wmulti()) * ((1 + (-1 * (ERDY + Emulti(target))) + xE * (ERDY + Emulti(target))))
		if ERDY == 1 and DIST < 700 then HoldPosition() E(target) end
		if DIST < 650 and not Talon.KS.R:Value() or LIFE < maxDMG and LIFE > maxDMGNoR or Talon.KS.AR:Value() and Talon.KS.AOER:Value() <= EnemiesAround(myHeroPos(), myRange) then
			R1(target)
		end
		if DIST < 300 and (AAREADY ~= 1 or LS == "Q" or DIST > myRange) then CastOffensiveItems(target) end
		if (AAREADY == 1 or GotBuff(myHero,"talonnoxiandiplomacybuff") ~= 0) and DIST < myRange then
			AttackUnit(target)
		end
		if DIST < myRange and QRDY == 1 and GotBuff(myHero,"talonnoxiandiplomacybuff") == 0 and (doQ or AAREADY ~= 1) then
			CastSpell(_Q)
		end
		if (AAREADY == 1 or GotBuff(myHero,"talonnoxiandiplomacybuff") ~= 0) and DIST < myRange then
			AttackUnit(target)
		end
		if WRDY == 1 and DIST > myRange + 50 or DIST < myRange and GotBuff(myHero,"talonnoxiandiplomacybuff") == 0 and QRDY == 0 then
			W(target) 
		end
		if (AAREADY == 1 or GotBuff(myHero,"talonnoxiandiplomacybuff") ~= 0) and DIST < myRange then
			AttackUnit(target)
		end
		if DIST > myRange + 50 then
			MoveToMouse()
		elseif DIST < myRange and AAREADY ~= 1 and QRDY == 0 and GotBuff(myHero,"talonnoxiandiplomacybuff") == 0 then
			MoveToMouse()
		end
	else
		doQ = false
		MoveToMouse()
	end
end
--
local function Harass()
	if GetCurrentMana(myHero) / (GetMaxMana(myHero) * .01) >= Talon.Harass.Mana:Value() then
		if WRDY == 1 then
			local targetH = GetTarget(700, DAMAGE_PHYSICAL)
			if targetH and GetDistance(targetH) < 700 then W(targetH) end
			if Talon.Harass.DoIt:Value() then MoveToMouse() end
		else
			if Talon.Harass.DoIt:Value() then MoveToMouse() end
		end
	end
end
--
local function MISC()
	local buffer = 0
	buffer = not LS and GetTickCount() or LS and buffer
	LS = GetTickCount() - buffer < 2800 and LS ~= "E" and LS or GetTickCount() - buffer < 50 and LS == "E" and LS or nil
	stopMove = LS ~= "E" and false or stopMove
	AAREADY = (GetTickCount() - lastAA) * .001 + 0.01 >= GetWindUp(myHero) and 1 or 0
	lastAA = AAREADY == 1 and 0 or 1
	doQ = doQ and AAREADY == 1 and false or doQ
end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------- OnLoop, OnProcessSpell, OnCreateObject, all those Globals	----------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------
--Check for Attack cast by Talon
------------------------------------------
OnProcessSpellComplete(function(Object,Spell)
	if Object == GetMyHero() then
		if Talon.Combo:Value() then
			if Spell.name:lower():find("attack") then
				doQ = true
				LS = "AA"
				lastAA = GetTickCount()
	    elseif Spell.name:lower():find("noxiandiplomacy") then
	    	doQ = false
	    	QRDY = 0
	    	LS = "Q"
	    	lastAA = GetTickCount()
	    end
	  end
     if Spell.name:lower():find("rake") then 
    	LS = "W"
    	Wtime = Spell.animationTime * 50 + GetTickCount()
    end
    if Spell.name:lower():find("cutthroat") then
    	LS = "E"
    	doQ = false
    end
		HydraCast = Spell.name == "ItemTiamatCleave" and 1 or HydraCast
		HydraCastTime = Spell.name == "ItemTiamatCleave" and GetTickCount() or HydraCastTime
	end
end)
------------------------------------------
--Loop, which functions are perma called
------------------------------------------
OnDraw(function(myHero)
	if #n > 0 then
		for  i = 1, #n do
			if GetDistance(n[i]) < 2000 and Valid(n[i]) then
				local drawPos = GetOrigin(n[i])
		  	local armor = GetArmor(n[i])
		  	local hp = GetCurrentHP(n[i])
		  	local mhp = GetMaxHP(n[i])
		  	local hpreg = GetHPRegen(n[i])
				local shield = GetDmgShield(n[i])
			 	local maxHealth = mhp * ((100 + ((armor - GetArmorPenFlat(myHero)) * GetArmorPenPercent(myHero))) * .01) + hpreg * 6 + shield
			 	local health = hp * ((100 + ((armor - GetArmorPenFlat(myHero)) * GetArmorPenPercent(myHero))) * .01) + hpreg * 6 + shield
			 	local maxDMG = xHYDRA + xIgnite + ((xQ * QRDY) * ((1 + (-1 * (ERDY * Emulti(n[i]))) + xE * (ERDY + Emulti(n[i])))) + (xQ2 * QRDY)) + xW * (WRDY + Wmulti()) * ((1 + (-1 * (ERDY + Emulti(n[i]))) + xE * (ERDY + Emulti(n[i])))) + xR * (R1RDY + R2RDY) * ((1 + (-1 * (ERDY + Emulti(n[i]))) + xE * (ERDY + Emulti(n[i]))) * (2 -  R2RDY))
		    local maxDMGNoR = xHYDRA + xIgnite + ((xQ * QRDY) * ((1 + (-1 * (ERDY + Emulti(n[i])))) + xE * (ERDY + Emulti(n[i]))) + (xQ2 * QRDY)) + xW * (WRDY + Wmulti()) * ((1 + (-1 * (ERDY + Emulti(n[i]))) + xE * (ERDY + Emulti(n[i]))))
	    	if Talon.KS.Percent then
	      	if Round(((health - maxDMG) / maxHealth * 100), 0) > 0 then
						local drawing = WorldToScreen(1, GetOrigin(n[i]))
						local rounded = Round(((health - maxDMG) / maxHealth * 100), 0)
						DrawText("\n\n" .. rounded .. "%", 15, drawing.x, drawing.y, 0xffff0000) 
					end
				end
				if health < xIgnite then
	  			DrawCircle(drawPos, 50, 0, 0, 0xff00ff00) --green
	  		elseif health < maxDMGNoR then
	  			DrawCircle(drawPos, 100, 0, 0, 0xffffff00) --yellow
	  		elseif health < maxDMG then
	  			DrawCircle(drawPos, 150, 0, 0, 0xffff0000) --red
	  		end
	  	end
	  end
	end
end)

OnTick(function(myHero)
	n = GetEnemyHeroes()
	if not IsDead(myHero) then
		CheckItemCD()
		DamageFunc()
		SpellSequence()
		CD()
  	if Talon.Combo:Value() then
    	Combo()
  	elseif Talon.Harass.DoIt:Value() or Talon.Harass.Auto:Value() then
  		Harass()
  	end
	end
	MISC()
end)
