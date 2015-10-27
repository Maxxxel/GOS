if GetObjectName(myHero) ~= "Brand" then return end
--Version 1.0 // new Menu

Brand = MenuConfig("Brand", "Brand")
Brand:KeyBinding("Combo", "Combo", 32)

Brand:Menu("Spells", "Spells")
Brand.Spells:Info("InfoSpells", "En-/Disable Spells to use in Combo")
Brand.Spells:Boolean("CQ", "Q", true)
Brand.Spells:Boolean("CW", "W", true)
Brand.Spells:Boolean("CE", "E", true)
Brand.Spells:Boolean("CR", "R", true)
Brand.Spells:Info("InfoSpells2", "Will cast R only if target will be")
Brand.Spells:Info("InfoSpells3", "killed by it")
Brand.Spells:Boolean("KR", "R to kill only", true)

Brand:Menu("KS", "Killstuff")
Brand.KS:Info("InfoKS", "Ignite: Will auto ignite target")
Brand.KS:Info("InfoKS1", " if its killable")
Brand.KS:Boolean("I", "Ignite", true)
Brand.KS:Info("InfoKS2", "Killsteal: auto cast spells to")
Brand.KS:Info("InfoKS2.1", "secure the kill")
Brand.KS:Boolean("KS", "Killsteal", true)
Brand.KS:Info("InfoKS3", "Note: draws circle under killable")
Brand.KS:Info("InfoKS4", "enemy. Percent: show percent of")
Brand.KS:Info("InfoKS5", "HP left after full Combo")
Brand.KS:Boolean("Note", "Notes", true)
Brand.KS:Boolean("Percent", "Percent", true)
Brand.KS:Info("InfoKS6", "Long Ulti: cast Ulti if target behind")
Brand.KS:Info("InfoKS7", "another target can be killed")
Brand.KS:Boolean("KSR", "Long Ulti", true)

Brand:Menu("Draw", "Drawings")
Brand.Draw:Boolean("Draw", "Draw", true)
Brand.Draw:Boolean("DQ", "Draw Q", true)
Brand.Draw:Boolean("DW", "Draw W", true)
Brand.Draw:Boolean("DE", "Draw E", false)
Brand.Draw:Boolean("DR", "Draw R", false)

--Variables
local myHero = GetMyHero()
local n = {}
local target, Q, W, E, R, KR
local dQ, dW, dE, dR = 0, 0, 0, 0
local QDmg, WDmg, EDmg, RDmg, AP, xIgnite, TotalDamage = 0, 0, 0, 0, 0, 0, 0
local QRDY, WRDY, ERDY, RRDY, IRDY = 0, 0, 0, 0, 0
local myRange, DIST, VoidStaff = 0, 0, 0
--Items CD
local function GetItemCD()
  IRDY = Ignite and CanUseSpell(myHero, Ignite) == 0 and 1 or 0
end

--Damage
local function Damage()
  AP = GetBonusAP(myHero)
  QDmg = GetCastLevel(myHero,_Q) * 40 + 40 + .65 * AP
  WDmg = GetCastLevel(myHero,_W) * 45 + 30 + .6 * AP
  EDmg = GetCastLevel(myHero,_E) * 35 + 35 + .55 * AP
  RDmg = GetCastLevel(myHero,_R) * 150 + .5 * AP
  xIgnite = (GetLevel(myHero) * 20 + 50) * IRDY
end
--SpellCD
local function GetSpellCD()
  QRDY = GetCastLevel(myHero, _Q) > 0 and CanUseSpell(myHero, _Q) == 0 and 1 or 0
  WRDY = GetCastLevel(myHero, _W) > 0 and CanUseSpell(myHero, _W) == 0 and 1 or 0
  ERDY = GetCastLevel(myHero, _E) > 0 and CanUseSpell(myHero, _E) == 0 and 1 or 0
  RRDY = GetCastLevel(myHero, _R) > 0 and CanUseSpell(myHero, _R) == 0 and 1 or 0
end
--Mana ready
local function Mana(mq,mw,me,mr)
  local Qmana = 50
  local Wmana = 5 * GetCastLevel(myHero, _W) + 65
  local Emana = 5 * GetCastLevel(myHero, _E) + 65
  local Rmana = 100
  return Qmana * mq + Wmana * mw + Emana * me + Rmana * mr < GetCurrentMana(myHero) and 1 or 0
end
--Spells
local function doQ(o)
  if Q and GetDistance(o) < 1050 then
    local QPred = GetPredictionForPlayer(GetOrigin(myHero), o ,GetMoveSpeed(o) ,(math.floor(math.random() * 400) + 1600), 250, 1050, 70, true, true)
    if QPred.HitChance == 1 then
      CastSkillShot(_Q, QPred.PredPos.x, QPred.PredPos.y, QPred.PredPos.z)
    end
  end
end
local function doW(o)
  if W and GetDistance(o) < 875 then
    local WPred = GetPredictionForPlayer(GetOrigin(myHero), o, GetMoveSpeed(o), 99999, (math.floor(math.random() * 300) + 325), 875, 185, false, false)
		if WPred.HitChance == 1 then
      CastSkillShot(_W, WPred.PredPos.x, WPred.PredPos.y, WPred.PredPos.z)
    end
  end
end
local function doE(o)
  if E and GetDistance(o) < 650 then
    CastTargetSpell(o, _E)
  end
end
local function dooR(o)
  if R and GetDistance(o) < 750 then
    CastTargetSpell(o, _R)
  end
end
local function doEW(o)
	local WPred = GetPredictionForPlayer(GetOrigin(myHero), o, GetMoveSpeed(o), 99999, (math.floor(math.random() * 300) + 325) + 125, 875, 185, false, false)
	if WPred.HitChance == 1 and GetDistance(o) < 650 then
		CastTargetSpell(o, _E)
		CastSkillShot(_W, WPred.PredPos.x, WPred.PredPos.y, WPred.PredPos.z)
	end
end
local function doQE(o)
	local QPred = GetPredictionForPlayer(GetOrigin(myHero), o ,GetMoveSpeed(o) ,(math.floor(math.random() * 400) + 1600), 250 + 125, 1050, 70, true, true)
	if QPred.HitChance == 1 and GetDistance(o) < 650 then
		CastSkillShot(_Q, QPred.PredPos.x, QPred.PredPos.y, QPred.PredPos.z)
		CastTargetSpell(o, _E)
	end
end
local function doWQ(o)
	local QPred = GetPredictionForPlayer(GetOrigin(myHero), o ,GetMoveSpeed(o) ,(math.floor(math.random() * 400) + 1600), 250 + 125, 1050, 70, true, true)
	local WPred = GetPredictionForPlayer(GetOrigin(myHero), o, GetMoveSpeed(o), 99999, (math.floor(math.random() * 300) + 325), 875, 185, false, false)
	if WPred.HitChance == 1 and QPred.HitChance == 1 and GetDistance(o) < 875 then
		CastSkillShot(_W, WPred.PredPos.x, WPred.PredPos.y, WPred.PredPos.z)
		CastSkillShot(_Q, QPred.PredPos.x, QPred.PredPos.y, QPred.PredPos.z)
	end
end
local function doQW(o)
	local QPred = GetPredictionForPlayer(GetOrigin(myHero), o ,GetMoveSpeed(o) ,(math.floor(math.random() * 400) + 1600), 250, 1050, 70, true, true)
	local WPred = GetPredictionForPlayer(GetOrigin(myHero), o, GetMoveSpeed(o), 99999, (math.floor(math.random() * 300) + 325) + 125, 875, 185, false, false)
	if WPred.HitChance == 1 and QPred.HitChance == 1 and GetDistance(o) < 875 then
		CastSkillShot(_Q, QPred.PredPos.x, QPred.PredPos.y, QPred.PredPos.z)
		CastSkillShot(_W, WPred.PredPos.x, WPred.PredPos.y, WPred.PredPos.z)
	end
end
local function doEQW(o)
	local QPred = GetPredictionForPlayer(GetOrigin(myHero), o ,GetMoveSpeed(o) ,(math.floor(math.random() * 400) + 1600), 250 + 125, 1050, 70, true, true)
	local WPred = GetPredictionForPlayer(GetOrigin(myHero), o, GetMoveSpeed(o), 99999, (math.floor(math.random() * 300) + 325) + 250, 875, 185, false, false)
	if WPred.HitChance == 1 and QPred.HitChance == 1 and GetDistance(o) < 650 then
		CastTargetSpell(o, _E)
		CastSkillShot(_Q, QPred.PredPos.x, QPred.PredPos.y, QPred.PredPos.z)
		CastSkillShot(_W, WPred.PredPos.x, WPred.PredPos.y, WPred.PredPos.z)
	end
end
--Valid?
local function Valid(unit)
  return unit and not IsDead(unit) and IsTargetable(unit) and not IsImmune(unit, myHero) and IsVisible(unit) or false
end
--
local function CountEnemyHeroInRange(object, range)
  object = object or myHero
  local enemyInRange = 0
  for i, enemy in pairs(GetEnemyHeroes()) do
    if (enemy~=nil and GetTeam(myHero)~=GetTeam(enemy) and IsDead(enemy)==false) and GetDistance(object, enemy) <= range then
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
--Enemy Heroes/Minions in range
local function CountEnemyObjectsInRange(Object, range)
  Object = Object or myHero
  range = range or 99999
  local objectInRange = 0
  local a = CountEnemyHeroInRange(Object, range)
  local b = CountEnemyMinionInRange(Object, range)
  return a + b
end
--Burns?!
local function IsBurning(o)
  return GotBuff(o, "brandablaze") ~= 0 and 1 or 0
end
--Bouncing fire :)
local function GetRBounce(o)
	local Speed = o and GetMoveSpeed(o) or 0
	local NumEnemies = (math.min(CountEnemyObjectsInRange(o, 400 - Speed * .25), 4) - 1)
	return o and NumEnemies == 1 and 2 or o and NumEnemies == 2 and 1 or o and NumEnemies >= 3 and 0 or 0
end
--have ignite?
local function IsIgnited(o)
  return GotBuff(o, "summonerdot") ~= 0 and 1 or 0
end
--Ignites debuff
local function IsOrWillBeIgnited(o)
  return IRDY == 1 and 1 or IsIgnited(o) == 1 and 1 or 0
end
--Roundiround
local function Round(val, decimal)
		return decimal and math.floor( (val * 10 ^ decimal) + 0.5) / (10 ^ decimal) or math.floor(val + 0.5)
end
--Combo
local function Combo()
  target = GetCurrentTarget()
  myRange = 1050
  DIST = GetDistance(target)
  local QPred = GetPredictionForPlayer(GetOrigin(myHero), target, GetMoveSpeed(target), (math.floor(math.random() * 200) + 1600), 250, 1050, 60, true, false)
  local WPred = GetPredictionForPlayer(GetOrigin(myHero), target, GetMoveSpeed(target), 99999, (math.floor(math.random() * 500) + 500), 875, 200, false, false)
  local QH = QPred.HitChance == 1 and 1 or 0
  local WH = WPred.HitChance == 1 and 1 or 0
	local test = Q and QRDY * QH > 0 and QRDY * 1050 or W and WRDY * WH > 0 and WRDY * 875 or E and ERDY > 0 and ERDY * 650 or R and RRDY > 0 and RRDY * 750 or IRDY * 650 or 0
  if DIST < test then
    local armor = GetArmor(target)
	  local hp = GetCurrentHP(target)
	  local mhp = GetMaxHP(target)
	  local hpreg = GetHPRegen(target) * (1 - (IsOrWillBeIgnited(target) * .5))
    local Health = hp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(target)
    local maxHealth = mhp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(target)
    local care = GetBuffData(target, "brandablaze")
    local burntime = care.ExpireTime - GetTickCount() > 0 and (care.ExpireTime - GetTickCount()) * .001 or 4
    local PDMG = ((maxHealth * .02 * burntime) - (hpreg * .2 * burntime)) * IsBurning(target)
    local TotalDamage = xIgnite * IRDY + (QDmg * QRDY + WDmg * WRDY + WDmg * WRDY * IsBurning(target) * 1.25 + EDmg * ERDY + RDmg * RRDY * (1 + GetRBounce(target)) + PDMG) * Mana(QRDY, WRDY, ERDY, RRDY)
    local TotalDamageNoR = xIgnite * IRDY + (QDmg * QRDY + WDmg * WRDY + WDmg * WRDY * IsBurning(target) * 1.25 + EDmg * ERDY + PDMG) * Mana(QRDY, WRDY, ERDY, RRDY)
    local TotalDamageNoIgnite = (QDmg * QRDY + WDmg * WRDY + WDmg * WRDY * IsBurning(target) * 1.25 + EDmg * ERDY + RDmg * RRDY * (1 + GetRBounce(target)) + PDMG) * Mana(QRDY, WRDY, ERDY, RRDY)
    local TotalDamageNoRNoIgnite = (QDmg * QRDY + WDmg * WRDY + WDmg * WRDY * IsBurning(target) * 1.25 + EDmg * ERDY + PDMG) * Mana(QRDY, WRDY, ERDY, RRDY)
    if Health < TotalDamageNoR then
      if ERDY == 1 then doE(target) end
      if QRDY == 1 then doQ(target) end
      if WRDY == 1 then
        if IsBurning(target) == 1 or (ERDY == 0 and QRDY == 0) or (QRDY == 1 and QH ~= 1) then
          doW(target)
        end
      end
      if not KR then
        if RRDY == 1 then
          dooR(target)
        end
      end
      if Brand.KS.I:Value() and Health > TotalDamageNoRNoIgnite and DIST < 650 then
        CastTargetSpell(target, Ignite)
      end
    elseif Health < TotalDamage then
    	if ERDY == 1 then doE(target) end
    	if QRDY == 1 then doQ(target) end
      if IsBurning(target) == 1 then
        doW(target)
      end
    	if RRDY == 1 and Health < TotalDamage then
      	dooR(target)
      end
      if Brand.KS.I:Value() and Health > TotalDamageNoIgnite and DIST < 650 then
        CastTargetSpell(target, Ignite)
      end
    else
      if IsBurning(target) == 1 then
        if QRDY == 1 then doQ(target) end
        if ERDY == 1 then doE(target) end
        if WRDY == 1 then doW(target) end
        if RRDY == 1 then
        	if not KR then
         	  dooR(target)
        	end
        end
      else
      	if ERDY == 1 then doE(target) end
      	if WRDY == 1 then doW(target) end
        if QRDY == 1 then
	        if (ERDY + WRDY == 0) or (DIST > 875) or (WRDY == 1 and WH == 0) or (ERDY == 1 and DIST > 650) then
	          doQ(target)
	        end
	      end
	      if RRDY == 1 then
       	  if not KR then
          	dooR(target)
          end
        end
      end
    end
  end
end
--Kills
local function Kills()
  for i = 1, #n do
  	local DIST = GetDistance(n[i])
    if Valid(n[i]) and DIST < 2000 then
      local armor = GetArmor(n[i])
	    local hp = GetCurrentHP(n[i])
	    local mhp = GetMaxHP(n[i])
	    local hpreg = GetHPRegen(n[i]) * (1 - (IsOrWillBeIgnited(n[i]) * .5))
      local Health = hp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(n[i])
      local maxHealth = mhp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(n[i])
      local PDMG = (maxHealth * .08 - hpreg * .8) * IsBurning(n[i])
      local QPred = GetPredictionForPlayer(GetOrigin(myHero), n[i], GetMoveSpeed(n[i]), (math.floor(math.random() * 200) + 1600), 250, 1050, 60, true, false)
  		local WPred = GetPredictionForPlayer(GetOrigin(myHero), n[i], GetMoveSpeed(n[i]), 99999, (math.floor(math.random() * 500) + 500), 875, 200, false, false)
    	TotalDamage = xIgnite * IRDY + (QDmg * QRDY + WDmg * WRDY + WDmg * WRDY * IsBurning(n[i]) * 1.25 + EDmg * ERDY + RDmg * RRDY * (1 + GetRBounce(target)) + PDMG) * Mana(QRDY, WRDY, ERDY, RRDY)
    	local QH = QPred.HitChance == 1 and 1 or 0
  		local WH = WPred.HitChance == 1 and 1 or 0
			local test = Q and QRDY * QH > 0 and QRDY * 1050 or W and WRDY * WH > 0 and WRDY * 875 or E and ERDY > 0 and ERDY * 650 or R and RRDY > 0 and RRDY * 750 or IRDY * 650 or 0
      if Brand.KS.KS:Value() then
	      if Health < QDmg + PDMG and QRDY == 1 and GetCurrentMana(myHero) >= 50 and QH == 1 and DIST < test then
					doQ(n[i])	
				elseif Health < WDmg + PDMG  and WRDY == 1 and Mana(0,1,0,0) == 1 and WH == 1 and DIST < test then
					doW(n[i])
				elseif Health < EDmg + PDMG  and ERDY == 1 and Mana(0,0,1,0) == 1 and DIST < 650 then
					doE(n[i])
				elseif Health < EDmg + WDmg * 1.25 + PDMG and ERDY == 1 and WRDY == 1 and Mana(0,1,1,0) == 1 and DIST < test and WH == 1 then
					doEW(n[i])
				elseif Health < EDmg + QDmg + PDMG  and ERDY == 1 and QRDY == 1 and Mana(1,0,1,0) == 1 and DIST < test and QH == 1 then
					doQE(n[i])
				elseif Health < QDmg + WDmg + PDMG  and QRDY == 1 and WRDY == 1 and Mana(1,1,0,0) == 1 and DIST < test and QH == 1 and WH == 1 then
					doWQ(n[i])
				elseif Health < QDmg + WDmg * 1.25 + PDMG  and QRDY == 1 and WRDY == 1 and Mana(1,1,0,0) == 1 and DIST < test and QH == 1 and WH == 1 then
					doQW(n[i])
				elseif Health < QDmg + WDmg + EDmg + PDMG  and QRDY == 1 and WRDY == 1 and ERDY == 1 and Mana(1,1,1,0) == 1 and DIST < test and QH == 1 and WH == 1 then
					doEQW(n[i])
				end
				for j = 1, #n do
					if n[j] ~= n[i] and n[j] ~= 0 and n[i] ~= 0 then
						local hp = GetCurrentHP(n[j])
						local armor = GetArmor(n[j])
						local hpreg = GetHPRegen(n[j]) * (1 - (IsOrWillBeIgnited(n[j]) * .5))
						local Health = hp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(n[j])
						local PDMG = (maxHealth * .08 - hpreg * .8) * IsBurning(n[j])
						if Health < (RDmg * RRDY + PDMG) * Mana(0,0,0,1) and Brand.KS.KSR:Value() and DIST < 750 and GetDistance(n[j]) > 750 and GetDistance(n[i], n[j]) <= 400 - (GetMoveSpeed(n[j]) + GetMoveSpeed(n[i]))* .5 * .25 then
							dooR(n[i])
						end
					end
				end
			end
    end
  end
end
--Draw things
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
	  for i = 1, #n do
  		local DIST = GetDistance(n[i])
    	if Valid(n[i]) and DIST < 2000 then
	      local drawPos = GetOrigin(n[i])
	      local armor = GetArmor(n[i])
		    local hp = GetCurrentHP(n[i])
		    local mhp = GetMaxHP(n[i])
		    local hpreg = GetHPRegen(n[i]) * (1 - (IsOrWillBeIgnited(n[i]) * .5))
	      local Health = hp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(n[i])
	      local maxHealth = mhp * ((100 + ((armor - GetMagicPenFlat(myHero)) * GetMagicPenPercent(myHero))) * .01) + hpreg * 6 + GetMagicShield(n[i])
	    	if Health < TotalDamage - RDmg * RRDY * (1 + GetRBounce(n[i])) then
	    		if Brand.KS.Note:Value() then
	          DrawCircle(drawPos.x, drawPos.y, drawPos.z, 50, 0, 0, 0xffff0000)
	        end
	      elseif Health < TotalDamage then
	        if Brand.KS.Note:Value() then
	          DrawCircle(drawPos.x, drawPos.y, drawPos.z, 100, 0, 0, 0xffff0000)
	        end
	      else
	      	if Round(((Health - TotalDamage) / maxHealth * 100), 0) > 0 and Brand.KS.Percent:Value() then
						local drawing = WorldToScreen(1, drawPos)
						local rounded = Round(((Health - TotalDamage) / maxHealth * 100), 0)
						DrawText("\n\n" .. rounded .. "%", 15, drawing.x, drawing.y, 0xffff0000) 
					end
	      end
	    end
	  end
	end
end)
--Call every loop
OnTick(function(myHero)
  GetItemCD()
  GetSpellCD()
  Damage()
  Q, W, E, R, KR = Brand.Spells.CQ:Value(), Brand.Spells.CW:Value(), Brand.Spells.CE:Value(), Brand.Spells.CR:Value(), Brand.Spells.KR:Value()
  n = GetEnemyHeroes()
  if Brand.Combo:Value() then
    Combo()
  end
  Kills()
end)
