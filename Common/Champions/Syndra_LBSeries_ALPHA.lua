if GetObjectName(myHero) ~= "Syndra" then return end
--Version 0.1 // fresh started

Syndra = MenuConfig("Syndra", "Syndra")
Syndra:KeyBinding("Combo", "Combo", 32)
Syndra:KeyBinding("mStun", "Manual Stun", string.byte("T"))

Syndra:Menu("Spells", "Spells")
Syndra.Spells:Info("InfoSpells", "En-/Disable Spells to use in Combo")
Syndra.Spells:Boolean("CQ", "Q", true)
Syndra.Spells:Boolean("CW", "W", true)
Syndra.Spells:Boolean("CE", "E", true)
Syndra.Spells:Boolean("CR", "R", true)

Syndra:Menu("KS", "Killstuff")
Syndra.KS:Info("InfoKS", "Ignite: Will auto ignite target")
Syndra.KS:Info("InfoKS1", " if its killable")
Syndra.KS:Boolean("I", "Ignite", true)
Syndra.KS:Info("InfoKS2", "Killsteal: auto cast spells to")
Syndra.KS:Info("InfoKS2.1", "secure the kill")
Syndra.KS:Boolean("KS", "Killsteal", true)
Syndra.KS:Info("InfoKS3", "Note: draws circle under killable")
Syndra.KS:Info("InfoKS4", "enemy. Percent: show percent of")
Syndra.KS:Info("InfoKS5", "HP left after full Combo")
Syndra.KS:Boolean("Note", "Notes", true)
Syndra.KS:Boolean("Percent", "Percent", true)

Syndra:Menu("Draw", "Drawings")
Syndra.Draw:Boolean("Draw", "Draw", true)
Syndra.Draw:Boolean("DQ", "Draw Q", true)
Syndra.Draw:Boolean("DW", "Draw W", true)
Syndra.Draw:Boolean("DQE", "Draw Stun Range", true)
Syndra.Draw:Boolean("DE", "Draw E", false)
Syndra.Draw:Boolean("DR", "Draw R", false)
Syndra.Draw:Boolean("DB", "Draw Balls", false)

------------------------------------------
--Variables
------------------------------------------
local myHero = GetMyHero()
local myTeam = GetTeam(myHero)
local Balls = {}
local minions = {}
local n = {}
local LS
local target, Q, W, E, R
local xQ, xW, xE, xR, xIgnite = 0, 0, 0, 0, 0
local QRDY, WRDY, ERDY, RRDY = 0, 0, 0, 0
local buffer = 0
------------------------------------------
--MISC
------------------------------------------
local function Valid(unit)
  return unit and not IsDead(unit) and IsTargetable(unit) and not IsImmune(unit, myHero) and IsVisible(unit) or false
end
local function CountBalls(table)
	local count = 0
	for _ in pairs(table) do 
	    count = count + 1 
	end
	return count
end
local function pDistance(x, y, x1, y1, x2, y2)
  local x0 = x
  local y0 = y
  local x1 = x1
  local y1 = y1
  local x2 = x2
  local y2 = y2
  local Dx = (x2 - x1);
  local Dy = (y2 - y1);
  local numerator = math.abs(Dy*x0 - Dx*y0 - x1*y2 + x2*y1);
  local denominator = math.sqrt(Dx*Dx + Dy*Dy);
  if (denominator == 0) then
     --määäh
  end
  return numerator/denominator;
end
------------------------------------------
--Item CD
------------------------------------------
local function GetItemCD()
  IRDY = Ignite and CanUseSpell(myHero, Ignite) == 0 and 1 or 0
end
------------------------------------------
--Damage Calcs
------------------------------------------
local function Damage()
  AP = GetBonusAP(myHero)
  xQ = (GetCastLevel(myHero,_Q) * 45 + 5 + .6 * AP) * math.max(GetCastLevel(myHero,_Q) / ( 5 / 1.15), 1)
  xW = GetCastLevel(myHero,_W) * 40 + 40 + .7 * AP
  xE = GetCastLevel(myHero,_E) * 45 + 25 + .4 * AP
  local rMultiplier = CountBalls(Balls) < 0 and 3 or CountBalls(Balls) > 0 and 3 + CountBalls(Balls) or 3
  xR = (GetCastLevel(myHero,_R) * 45 + 45 + .2 * AP) * rMultiplier
  xIgnite = (GetLevel(myHero) * 20 + 50) * IRDY
end
------------------------------------------
--Spell CD
------------------------------------------
local function GetSpellCD()
  QRDY = GetCastLevel(myHero, _Q) > 0 and CanUseSpell(myHero, _Q) == 0 and 1 or 0
  WRDY = GetCastLevel(myHero, _W) > 0 and CanUseSpell(myHero, _W) == 0 and 1 or 0
  ERDY = GetCastLevel(myHero, _E) > 0 and CanUseSpell(myHero, _E) == 0 and 1 or 0
  RRDY = GetCastLevel(myHero, _R) > 0 and CanUseSpell(myHero, _R) == 0 and 1 or 0
end
------------------------------------------
--Ignite Stuff
------------------------------------------
local function IsIgnited(o)
  return GotBuff(o, "summonerdot") ~= 0 and 1 or 0
end
local function IsOrWillBeIgnited(o)
  return IRDY == 1 and 1 or IsIgnited(o) == 1 and 1 or 0
end
------------------------------------------
--Mana
------------------------------------------
local function Mana(mq,mw,me,mr)
  local Qmana = 10 * GetCastLevel(myHero, _Q) + 30
  local Wmana = 10 * GetCastLevel(myHero, _W) + 50
  local Emana = 50
  local Rmana = 100
  return Qmana * mq + Wmana * mw + Emana * me + Rmana * mr < GetCurrentMana(myHero) and 1 or 0
end
------------------------------------------
--Get minions
------------------------------------------
local function GetMinions()
	if CountBalls(Balls) > 0 then
		for k, v in pairs(Balls) do
			minions[k] = {object = v.O, pos = v.Position}
		end
	end
	for k,v in pairs(minionManager.objects) do --cycle through all minions
    local objTeam = GetTeam(v)
    local objID = GetNetworkID(v)
    local position = GetOrigin(v)
    if objTeam ~= GetTeam(myHero) and GetDistance(v) < 975 then --if minions is not Syndras Team enter it to table
    	minions[objID] = {object = v, pos = position}
    end
  end
end
------------------------------------------
--Catch the Object
------------------------------------------
local function CatchThe(o)
	if GetCastName(myHero, _W) ~= "syndrawcast" then 
		CastSkillShot3(_W, GetOrigin(myHero), GetOrigin(o))
	end
	return o
end
------------------------------------------
--DoQ
------------------------------------------
local function DoQ(o)
	if GetDistance(o) < 850 then
		local QPred = GetPredictionForPlayer(GetOrigin(myHero), o, GetMoveSpeed(o), 99999, 700, 850, 200, false, false)
		if QPred.HitChance == 1 then
			CastSkillShot(_Q, QPred.PredPos)
		end
	end
end
------------------------------------------
--DoW
------------------------------------------
local function DoE(o)
	if GetDistance(o) < 725 then
		local EPred = GetPredictionForPlayer(GetOrigin(myHero), o, GetMoveSpeed(o), 99999, 328, 725, 975 - GetDistance(o) * .3, false, false)
		if EPred.HitChance == 1 then
			CastSkillShot(_E, EPred.PredPos)
		end
	end
end
------------------------------------------
--DoE
------------------------------------------
local function DoW(o)
	if GetDistance(o) < 975 then
		for i, Bomb in pairs(minions) do
			if Bomb then
				local WPred = GetPredictionForPlayer(GetOrigin(myHero), o, GetMoveSpeed(o), 2400, GetDistance(Bomb.object, o), 975, 100, false, false)
				if WPred.HitChance == 1 then
					CastSkillShot3(_W, WPred.PredPos, Bomb.pos )
				end
			end
		end
	end
end
------------------------------------------
--DoR
------------------------------------------
local function DoR(o)
	if GetDistance(o) <= math.max(725, (GetCastLevel(myHero, _R) / 3) * 800) then
		CastTargetSpell(o, _R)
	end
end
------------------------------------------
--Manual Stun
------------------------------------------
local function ManualStun(x)
	if not x then
		local mousePos = GetMousePos()
		local TargetPos = Vector(mousePos.x, mousePos.y, mousePos.z)
		local myHeroPos = GetOrigin(myHero)
		local HeroPos = Vector(myHeroPos.x, myHeroPos.y, myHeroPos.z)
		local Pos = HeroPos-(HeroPos-TargetPos)*(500/GetDistance(mousePos))
		if QRDY == 1 and ERDY == 1 then 
			CastSkillShot(_Q, Pos) 
		end
		if QRDY == 0 then
			local myHeroPos = GetOrigin(myHero)
			if CountBalls(Balls) <2 then
				CastSkillShot(_E, Pos)
			else
				for i, aBall in pairs(Balls) do
					if pDistance(aBall.Position.x,aBall.Position.z,myHeroPos.x,myHeroPos.z,mousePos.x,mousePos.z) <= 5 then
						CastSkillShot(_E, Pos)
					end
				end
			end
		end
	else
		local mousePos = GetPredictionForPlayer(GetOrigin(myHero), x, GetMoveSpeed(x), 2400, 1000, 1300, 50, false, false)
		local TargetPos = Vector(mousePos.PredPos.x, mousePos.PredPos.y, mousePos.PredPos.z)
		local myHeroPos = GetOrigin(myHero)
		local HeroPos = Vector(myHeroPos.x, myHeroPos.y, myHeroPos.z)
		local Pos = HeroPos-(HeroPos-TargetPos)*(500/GetDistance(mousePos.PredPos))
		if QRDY == 1 and ERDY == 1 then 
			CastSkillShot(_Q, Pos) 
		end
		if QRDY == 0 then
			local myHeroPos = GetOrigin(myHero)
			if CountBalls(Balls) <2 then
				CastSkillShot(_E, Pos)
			else
				for i, aBall in pairs(Balls) do
					if pDistance(aBall.Position.x,aBall.Position.z,myHeroPos.x,myHeroPos.z,mousePos.PredPos.x,mousePos.PredPos.z) <= 5 then
						CastSkillShot(_E, Pos)
					end
				end
			end
		end
	end
end
------------------------------------------
--Combo
------------------------------------------
local function Combo()
	if target and Valid(target) then
		if GetDistance(target) <= 1500 then
			local DIST = GetDistance(target)
			local Qadd = (LS == "Q" and 1 or 0)
			local myRange = (QRDY + Qadd) * ERDY > 0 and 1300 or QRDY > 0 and 850 or WRDY > 0 and 975 or ERDY > 0 and 725 or RRDY > 0 and math.max(725, (GetCastLevel(myHero, _R) / 3) * 800) or IRDY > 0 and 650 or GetRange(myHero)
			local maxDamage = xQ*QRDY + xW*WRDY + xE*ERDY + xR*RRDY + xIgnite*IRDY
			local maxDamageNoUlt = xQ*QRDY + xW*WRDY + xE*ERDY + xIgnite*IRDY
			local maxDamageNoIgn = xQ*QRDY + xW*WRDY + xE*ERDY + xR*RRDY
			local maxDamageNoUltIgn = xQ*QRDY + xW*WRDY + xE*ERDY
			local armor = GetArmor(target)
		  local hp = GetCurrentHP(target)
		  local mhp = GetMaxHP(target)
		  local hpreg = GetHPRegen(target) * (1 - (IsOrWillBeIgnited(target) * .5))
	    local Health = hp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(target)
	    local maxHealth = mhp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(target)
	    if Health < maxDamageNoUltIgn and DIST < myRange then
	    	if (QRDY == 1 and ERDY == 1) or (ERDY == 1 and LS == "Q") then ManualStun(target) end
	    	if WRDY == 1 then DoW(target) end
	    elseif Health > maxDamageNoUltIgn and Health < maxDamageNoUlt and DIST < myRange then
	    	if (QRDY == 1 and ERDY == 1) or (ERDY == 1 and LS == "Q") then ManualStun(target) end
	    	if WRDY == 1 then DoW(target) end
	    	if IRDY == 1 and DIST < 650 then CastTargetSpell(target, Ignite) end
	    elseif Health > maxDamageNoUltIgn and Health > maxDamageNoUlt and Health < maxDamageNoIgn and DIST < myRange then
	    	if (QRDY == 1 and ERDY == 1) or (ERDY == 1 and LS == "Q") then ManualStun(target) end
	    	if WRDY == 1 then DoW(target) end
	    	if RRDY == 1 then DoR(target) end
	    elseif Health > maxDamageNoUltIgn and Health > maxDamageNoUlt and Health > maxDamageNoIgn and Health < maxDamage and DIST < myRange then
	    	if (QRDY == 1 and ERDY == 1) or (ERDY == 1 and LS == "Q") then ManualStun(target) end
	    	if WRDY == 1 then DoW(target) end
	    	if IRDY == 1 and DIST < 650 then CastTargetSpell(target, Ignite) end
	    	if RRDY == 1 then DoR(target) end
	    else
	    	if DIST < myRange then
	    		if (QRDY == 1 and ERDY == 1) or (ERDY == 1 and LS == "Q") then ManualStun(target) end
	    		if QRDY == 1 then DoQ(target) end
	    		if WRDY == 1 then DoW(target) end
	    		if ERDY == 1 then DoE(target) end
	    	end
			end
		end
	end
end
------------------------------------------
--Misc function
------------------------------------------
local function Misc()
	GetMinions()
	for v, aBall in pairs(Balls) do
		if not IsObjectAlive(aBall.O) then
			Balls[v] = nil
		end
	end
	for v, aMinion in pairs(minions) do
		if not IsObjectAlive(aMinion.object) or GetDistance(aMinion.object) > 975 then
			minions[v] = nil
		end
	end
	buffer = not LS and GetTickCount() or LS and buffer
	LS = GetTickCount() - buffer < 1500 and LS or nil
end
------------------------------------------
--Main function
------------------------------------------
OnTick(function(myHero)
	GetItemCD()
	Damage()
	GetSpellCD()
	n = GetEnemyHeroes()
	target = GetCurrentTarget()
	Misc()
	Q, W, E, R = Syndra.Spells.CQ:Value(), Syndra.Spells.CW:Value(), Syndra.Spells.CE:Value(), Syndra.Spells.CR:Value()
	if Syndra.Combo:Value() then Combo() end
	if Syndra.mStun:Value() then ManualStun() end
end)
------------------------------------------
--Draw functions
------------------------------------------
OnDraw(function(myHero)
	if Syndra.Draw.Draw:Value() then
		if Syndra.Draw.DQ:Value() and QRDY == 1 then DrawCircle(GetOrigin(myHero),850,0,0,0xffff0000) end
		if Syndra.Draw.DW:Value() and WRDY == 1 then DrawCircle(GetOrigin(myHero),975,0,0,0xffff0000) end
		if Syndra.Draw.DE:Value() and ERDY == 1 then DrawCircle(GetOrigin(myHero),725,0,0,0xffff0000) end
		if Syndra.Draw.DR:Value() and RRDY == 1 then DrawCircle(GetOrigin(myHero),math.max(725, (GetCastLevel(myHero, _R) / 3) * 800),0,0,0xffff0000) end
		if Syndra.Draw.DQE:Value() then 
			local Qadd = (LS == "Q" and 1 or 0)
			local myRange = (QRDY + Qadd) * ERDY > 0 and 1300 or 0
			DrawCircle(GetOrigin(myHero),myRange,0,0,0xffff0000)
		end
		if Syndra.Draw.DB:Value() then
			for v, aBall in pairs(Balls) do
				if IsObjectAlive(aBall.O) then DrawCircle(aBall.Position,200,0,0,0xffff0000) end
			end
		end
	end
end)
------------------------------------------
--Check if Balls are created
------------------------------------------
OnObjectLoop(function(Object,myHero)
	local ObjName = GetObjectBaseName(Object)
	if ObjName == "Seed" and IsObjectAlive(Object) then
		local position = GetOrigin(Object)
		local obj = Object
		local id = GetNetworkID(Object)
		Balls[id] = {O = obj, Position = position,}
	end
end)
------------------------------------------
--Last Spell (LS) Check
------------------------------------------
OnProcessSpell(function(Object, Spell)
	if Object == myHero then
		if Spell.name == "SyndraQ" then LS = "Q"
		elseif (Spell.name == "syndrawcast" or Spell.name == "SyndraW") then LS = "W"
		elseif Spell.name:find("syndrae") then LS = "E"
		elseif Spell.name == GetCastName(myHero, _R) then LS = "R"
		end
	end
end)
