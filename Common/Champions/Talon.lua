Talon=Menu("Talon","Maxxxel Talon God")
Talon:Key("Combo","Combo",string.byte(" "))
Talon:SubMenu("KS","Killfunctions")
Talon.KS:Boolean("Ignite","Auto-Ignite",true)
Talon.KS:Boolean("R", "Smart Ulti",true)
Talon.KS:Boolean("Percent","Show % Kill",true)

------------------------------------------
--version = 1.0
--updated Performance, Code Syntax
------------------------------------------

------------------------------------------
--Variables
------------------------------------------
local xHydra, HRDY, QRDY, WRDY, ERDY, R1RDY, R2RDY, HydraCast, HydraCastTime, xAA, xQ, xQ2, xW, xE, xR, IRDY, xIgnite, Wtime, dmgOverTime, Check = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
local target, LS
local myHero = GetMyHero()
local stopMove = false
------------------------------------------
--Tables
------------------------------------------
local KSN = {}
local n = {}
local Attack = {Target = nil, Time = {Start = 0, Reset = 0, End = 0}}
local Damage = {Success = false}
------------------------------------------
--Check for Items
------------------------------------------
local function CheckItemCD()
  HydraCast = HydraCastTime ~= 0 and HydraCast == 1 and (GetTickCount() - HydraCastTime) >= 10000 and 0 or HydraCast
  HydraCastTime = HydraCastTime ~= 0 and HydraCast == 1 and (GetTickCount() - HydraCastTime) >= 10000 and 0 or HydraCastTime
  HRDY = GetItemSlot(myHero,3077) + GetItemSlot(myHero,3074) > 0 and HydraCast == 0 and 1 or 0
  IRDY = CanUseSpell(myHero, Ignite) == 0 and 1 or 0
end
------------------------------------------
--Check for Spell Damage
------------------------------------------
local function DamageFunc()
	local base = GetBaseDamage(myHero)
	local bonus = GetBonusDmg(myHero)
	xAA = base + bonus
	xQ = xAA + 30 * GetCastLevel(myHero,_Q) + .3 * bonus
	xQ2 = (10 * GetCastLevel(myHero,_Q) + bonus) - dmgOverTime
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
	if LS ~= "E" or stopMove == true then
		MoveToXYZ(GetMousePos())
  end
end

local function Valid(unit)
  return unit and not IsDead(unit) and IsTargetable(unit) and not IsImmune(unit, myHero) and IsVisible(unit) or false
end

local function HasE(unit)
	return GotBuff(unit,"talondamageamp") ~= 0 or false
end

local function Emulti(unit)
  return HasE(unit) and 1 or 0
end

local function Wmulti()
  return GetTickCount() - Wtime <= 0 and 1 or 0
end

local function HasQ2(unit)
	return GotBuff(unit,"talonbleeddebuff") ~= 0 or false
end

local function IsMoving(unit)
	local t = GetPredictionForPlayer(GetOrigin(myHero), unit, GetMoveSpeed(unit), 99999, 0, 2000, 1, false, false)
	local k = {x = t.PredPos.x, y = t.PredPos.y, z = t.PredPos.z}
	local p = GetOrigin(unit)
	local d1 = GOS:GetDistance(p)
	local d2 = GOS:GetDistance(k)
	return d1 < d2 and 1 or 0
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
--Check if Attack is ready
------------------------------------------
function AttackReadiness()
	if Damage.Success then
		local time = GetTickCount()
		local APS = (Attack.Time.End - time) --time between DamageProcs
	  local xTime = (Attack.Time.Start ~= 0 and Attack.Time.Start + APS) or time
	  local value = time-xTime
	  if Check == 0 then
			Check = value
		elseif Check~=0 and value>APS or (Attack.Time.Reset<=value and not Damage.Success) then
			Check = 0
		end
		return Check~=0 and 1-value/Check<1 and 1-value/Check or 1
	else
		return 1
	end
end
------------------------------------------
--Spells
------------------------------------------
local function W(o)
	if GOS:GetDistance(o) <= 700 - GetMoveSpeed(o) * IsMoving(o) * .1 then
		CastTargetSpell(o, _W)
	end
end

local function E(o)
	if GOS:GetDistance(o) <= 700 then
		stopMove = true
		CastTargetSpell(o, _E)
		if (AttackReadiness() ~= 1 or Damage.Success) and GOS:GetDistance(o) <= 300 then
			CastSpell(_Q)
		end
	end
end

local function R1(o)
	if GOS:GetDistance(o) <= 650 - GetMoveSpeed(o) * IsMoving(o) * .15 then
		CastSpell(_R)
	end
end

local function R2(o)
	if GetCastName(myHero, _R) == "talonshadowassaulttoggle" and GOS:GetDistance(o) <= 650 - GetMoveSpeed(o) * IsMoving(o) * .15 then
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
--Distance to xyz (xz) position
------------------------------------------
local function GetDistanceXYZ(x, z, x2, z2)
	a = x2 - x or nil
	b = z2 - z or nil
  return math.sqrt( a * a + b * b) or 99999
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
			local drawPos = GetOrigin(n[i])
			local shield = GetDmgShield(n[i])
		 	local maxHealth = mhp * ((100 + ((armor - GetArmorPenFlat(myHero)) * GetArmorPenPercent(myHero))) * .01) + hpreg * 6 + shield
		 	local health = hp * ((100 + ((armor - GetArmorPenFlat(myHero)) * GetArmorPenPercent(myHero))) * .01) + hpreg * 6 + shield
    	if GOS:GetDistance(n[i]) <= 2000 and Talon.KS.Percent and Valid(n[i]) then
      	local maxDMG = xHYDRA + xIgnite + ((xQ * QRDY) * ((1 + (-1 * (ERDY * Emulti(n[i]))) + xE * (ERDY + Emulti(n[i])))) + (xQ2 * QRDY)) + xW * (WRDY + Wmulti()) * ((1 + (-1 * (ERDY + Emulti(n[i]))) + xE * (ERDY + Emulti(n[i])))) + xR * (R1RDY + R2RDY) * ((1 + (-1 * (ERDY + Emulti(n[i]))) + xE * (ERDY + Emulti(n[i]))) * (2 -  R2RDY))
	      local maxDMGNoR = xHYDRA + xIgnite + ((xQ * QRDY) * ((1 + (-1 * (ERDY + Emulti(n[i])))) + xE * (ERDY + Emulti(n[i]))) + (xQ2 * QRDY)) + xW * (WRDY + Wmulti()) * ((1 + (-1 * (ERDY + Emulti(n[i]))) + xE * (ERDY + Emulti(n[i]))))
    		local seconds = 0
    		local Q2Timer = 0
    		Q2Timer = HasQ2(n[i]) and Q2Timer == 0 and GetTickCount() or seconds >= 6 and 0 or Q2Timer
    		seconds = HasQ2(n[i]) and Q2Timer ~= 0 and (GetTickCount() - Q2Timer) * .001 or 0
    		dmgOverTime = HasQ2(n[i]) and seconds ~= 0 and ((10 * GetCastLevel(myHero,_Q) + GetBonusDmg(myHero)) / 6) * seconds or 0
    		if health < xIgnite then
    			DrawCircle(drawPos, 50, 0, 0, 0xff00ff00) --green
    		elseif health < maxDMGNoR then
    			DrawCircle(drawPos, 100, 0, 0, 0xffffff00) --yellow
    		elseif health < maxDMG then
    			DrawCircle(drawPos, 150, 0, 0, 0xffff0000) --red
    		end
    		if health < R2RDY * xR then
    			R2(n[i])
    		end
    		if		 HRDY == 1 and IRDY == 1 and health < maxDMG and GOS:GetDistance(n[i]) <= 300 and Talon.Combo:Value() and target and n[i] == target then
					GOS:CastOffensiveItems(n[i])
					CastTargetSpell(n[i], Ignite)
    		elseif HRDY == 1 and IRDY == 0 and health < maxDMG and GOS:GetDistance(n[i]) <= 300 and Talon.Combo:Value() and target and n[i] == target then
    			GOS:CastOffensiveItems(n[i])
    		elseif HRDY == 0 and IRDY == 1 and health < maxDMG and GOS:GetDistance(n[i]) <= 300 and Talon.Combo:Value() and target and n[i] == target then
    			CastTargetSpell(n[i], Ignite)
    		elseif IRDY == 1 and health < xIgnite and GOS:GetDistance(n[i]) <= 600 then
    			CastTargetSpell(n[i], Ignite)
    		end
				if Round(((health - maxDMG) / maxHealth * 100), 0) > 0 then
					local drawing = WorldToScreen(1, GetOrigin(n[i]))
					local rounded = Round(((health - maxDMG) / maxHealth * 100), 0)
					DrawText("\n\n" .. rounded .. "%", 15, drawing.x, drawing.y, 0xffff0000) 
				end
			end
		end
	end
end
--
local function Combo()
	target = GetCurrentTarget()
	if target and Valid(target) and GOS:GetDistance(target) <= 725 then
		local DIST = GOS:GetDistance(target)
		local ARMOR = GetArmor(target)
		local HPREG = GetHPRegen(target)
		local HP = GetCurrentHP(target)
		local MOVE = GetMoveSpeed(target)
		local SHIELD = GetDmgShield(target)
		local LIFE = HP * ((100 + ((ARMOR - GetArmorPenFlat(myHero)) * GetArmorPenPercent(myHero))) * .01) + HPREG * 6 + SHIELD
		local myRange = GetRange(myHero) + GetHitBox(target) + GetHitBox(myHero) - (GetMoveSpeed(myHero) - GetMoveSpeed(target)) * IsMoving(target) * ((Attack.Time.Reset - Attack.Time.Start) * .001 + GetLatency() * .001)
		local maxDMG = xHYDRA + xIgnite + xAA * ((1 + (-1 * (ERDY + Emulti(target))) + xE * (ERDY + Emulti(target)))) + ((xQ * QRDY) * ((1 + (-1 * (ERDY * Emulti(target))) + xE * (ERDY + Emulti(target)))) + (xQ2 * QRDY)) + xW * (WRDY + Wmulti()) * ((1 + (-1 * (ERDY + Emulti(target))) + xE * (ERDY + Emulti(target)))) + xR * (R1RDY + R2RDY) * ((1 + (-1 * (ERDY + Emulti(target))) + xE * (ERDY + Emulti(target))) * (2 -  R2RDY))
 		local maxDMGNoR = xHYDRA + xIgnite + (xAA * ((1 + (-1 * (ERDY + Emulti(target)))) + xE * (ERDY + Emulti(target)))) + ((xQ * QRDY) * ((1 + (-1 * (ERDY + Emulti(target)))) + xE * (ERDY + Emulti(target))) + (xQ2 * QRDY)) + xW * (WRDY + Wmulti()) * ((1 + (-1 * (ERDY + Emulti(target))) + xE * (ERDY + Emulti(target))))
		if ERDY == 1 then E(target) end
		if (AttackReadiness() == 1 or GotBuff(myHero,"talonnoxiandiplomacybuff") ~= 0) and DIST < myRange then
			AttackUnit(target)
			GOS:CastOffensiveItems(target)
		end
		if (AttackReadiness() ~= 1 or Damage.Success) and DIST < myRange and QRDY == 1 and GotBuff(myHero,"talonnoxiandiplomacybuff") == 0 then
			CastSpell(_Q)
		end
		if not Talon.KS.R:Value() or LIFE < maxDMG and LIFE > maxDMGNoR then
			R1(target)
		end
		if WRDY == 1 and (AttackReadiness() ~= 1 and GotBuff(myHero,"talonnoxiandiplomacybuff") == 0 and QRDY == 0 or DIST > myRange) then W(target) end
		if DIST > myRange + 50 then
			MoveToMouse()
		elseif DIST < myRange and AttackReadiness() <= 0.5 and QRDY == 0 and GotBuff(myHero,"talonnoxiandiplomacybuff") == 0 then
			MoveToMouse()
		end
	else
		MoveToMouse()
	end
end
------------------------------------------
--AAHandling resets the variables for AA
------------------------------------------
local function AAHandling()
	--Attack = AttackReadiness() == 1 and (Damage.Success or Attack.Time.End + (Attack.Time.End - Attack.Time.Start) * 2 < GetTickCount()) and {Time = {Start = 0, End  = 0, Reset = 0}, Target = nil, Pos = {Start = {x = 0, y = 0, z = 0}, End = {x = 0, y = 0, z = 0}}, Type = nil} or Attack
	Damage = AttackReadiness() == 1 and (Damage.Success or Attack.Time.End < GetTickCount()) and {Success = false, Position = {x = 0, y = 0, z = 0}, Time = 0} or Damage
end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------- OnLoop, OnProcessSpell, OnCreateObject, all those Globals	----------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------
--Check for Attack cast by Talon
------------------------------------------
OnProcessSpell(function(Object,Spell)
  local ObjName = GetObjectName(Object)
  if Object and ObjName == GetObjectName(myHero) then
    if Spell.name:lower():find("attack") then
    	stopMove = true
      local time = GetTickCount()
      Attack = {Time = {Start = time, End  = time + Spell.animationTime * 1000, Reset = time + Spell.windUpTime * 1000}, Target = Spell.target, Pos = {Start = {x = Spell.startPos.x, y = Spell.startPos.y, z = Spell.startPos.z}, End = {x = Spell.endPos.x, y = Spell.endPos.y, z = Spell.endPos.z}}, Type = "Basic"}
    elseif Spell.name:lower():find("noxiandiplomacy") then
    	QRDY = 1
    	LS = "Q"
      local time = GetTickCount()
      Attack = {Time = {Start = time, End  = time + Spell.animationTime * 1000, Reset = 0}, Target = Spell.target, Pos = {Start = {x = Spell.startPos.x, y = Spell.startPos.y, z = Spell.startPos.z}, End = {x = Spell.endPos.x, y = Spell.endPos.y, z = Spell.endPos.z}}, Type = "Q"}
    end
    if Spell.name:lower():find("rake") then 
    	LS = "W"
    	Wtime = Spell.animationTime * 125 + GetTickCount()
    end
    if Spell.name:lower():find("cutthroat") then
    	LS = "E"
    end
		HydraCast = Spell.name == "ItemTiamatCleave" and 1 or HydraCast
		HydraCastTime = Spell.name == "ItemTiamatCleave" and GetTickCount() or HydraCastTime
	end
end)
------------------------------------------
--Check for aa finishs
------------------------------------------
OnCreateObj(function(Object)
	if Object and GOS:GetDistance(Object) <= 500 then
	  local Name  = GetObjectBaseName(Object)
	  if Name == "globalhit_bloodslash.troy" or Name == "Pulverize_cas3.troy" then
	  	if Attack.Target then
	  		local Pos = GetOrigin(Object)
		    if GetDistanceXYZ(Pos.x, Pos.z, Attack.Pos.Start.x, Attack.Pos.Start.z) > 50 then
		    	stopMove = false
		      Damage = {Success = true, Position = {x = Pos.x, y = Pos.y, z = Pos.z}, Time = GetTickCount()}
		   	end
		  end
	  end 
	end       
end)
------------------------------------------
--Loop, which functions are perma called
------------------------------------------
OnLoop(function(myHero)
	n = GOS:GetEnemyHeroes()
	if not IsDead(myHero) then
		CheckItemCD()
		DamageFunc()
		SpellSequence()
		AAHandling()
		CD()
  	if Talon.Combo:Value() then
    	Combo()
  	end
	end
	local buffer = 0
	buffer = not LS and GetTickCount() or LS and buffer
	LS = GetTickCount() - buffer < 2800 and LS ~= "E" and LS or GetTickCount() - buffer < 50 and LS == "E" and LS or nil
	stopMove = LS ~= "E" and false or stopMove
end)
