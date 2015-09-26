--Maxxxel Edit--
Config = Menu("Brand", "Brand_One_Key")
Config:Boolean("Q", "Use Q", true)
Config:Boolean("W", "Use W", true)
Config:Boolean("E", "Use E", true)
Config:Boolean("R", "Use R If Killabe", true)
Config:Boolean("KS", "Killsteal", true)
Config:Key("Combo", "Combo", string.byte(" "))
Config:Boolean("Note", "Note", true)
Config:Boolean("Percent","Percent",true)
--Ignite--
AutoIgniteMenu = Menu("AutoIgnite", "Auto Ignite")
AutoIgniteMenu:Boolean("Enabled", "Enabled", true)
--Damage Stuff
local myHero = GetMyHero()
local killable=0
local BonusAP = GetBonusAP(myHero)
--Q Damage
local SpellQ= (GetCastLevel(myHero,_Q)*40)+40+(.65*BonusAP)
--W Damage
local SpellW= (GetCastLevel(myHero,_W)*45)+30+(.6*BonusAP)
--E Damage
local SpellE= (GetCastLevel(myHero,_E)*35)+35+(.55*BonusAP)
--1 hit ulti, up to 3 times per target
local Pyroclasm = (GetCastLevel(myHero,_R)*150)+(.5*BonusAP)
--On Spacebar pressed:
OnLoop(function(myHero)
	local target = GetCurrentTarget()
	local myHeroPos = GetOrigin(myHero)
	Killsteal()
	if Config.Combo:Value() and IsObjectAlive(target) and GOS:ValidTarget(target,1100) and killable==0 then
		local QPred = GetPredictionForPlayer(GetOrigin(myHero),target,GetMoveSpeed(target),(math.floor(math.random()*400)+1600),250,950,60,true,true)
		local WPred = GetPredictionForPlayer(GetOrigin(myHero),target,GetMoveSpeed(target),99999,(math.floor(math.random()*250)+250),800,220,false,true)
		if (GOS:GetDistance(target)<=650 and CanUseSpell(myHero, _E) == READY) and Config.E:Value() then
			CastE(target)
		elseif (GOS:GetDistance(target)<=800 and CanUseSpell(myHero, _W) == READY) and Config.W:Value() and WPred.HitChance == 1 then
			CastSkillShot(_W,WPred.PredPos.x,WPred.PredPos.y,WPred.PredPos.z)
		elseif (GOS:GetDistance(target)<=950 and CanUseSpell(myHero, _Q) == READY) and Config.Q:Value() and QPred.HitChance == 1 then
		--Cast if target burns
			if GotBuff(target,"brandablaze")~=0 then
				CastSkillShot(_Q,QPred.PredPos.x,QPred.PredPos.y,QPred.PredPos.z)
		--Cast when all Spells on CD or out of range
			elseif (CanUseSpell(myHero, _W) ~= READY or GOS:GetDistance(target)>800) and (CanUseSpell(myHero, _E) ~= READY or GOS:GetDistance(target)>650) then
				CastSkillShot(_Q,QPred.PredPos.x,QPred.PredPos.y,QPred.PredPos.z)
			else
				CastSkillShot(_Q,QPred.PredPos.x,QPred.PredPos.y,QPred.PredPos.z)
			end
		end	
		--Ulti if killable
		if (GOS:CalcDamage(myHero, target, 0, Pyroclasm) > GetCurrentHP(target) + GetHPRegen(target)) and CanUseSpell(myHero, _Q) ~= READY and CanUseSpell(myHero, _W) ~= READY and CanUseSpell(myHero, _E) ~= READY then
			if Config.R:Value() then
				if CanUseSpell(myHero,_R) == READY and GOS:GetDistance(target)<=GetCastRange(myHero,_R) then
					CastR(target)
				end
			end
		end
	end
	for i,enemy in pairs(GoS:GetEnemyHeroes()) do
		if Ignite and AutoIgniteMenu.Enabled:Value() then
  		if CanUseSpell(myHero, Ignite) == READY and 20*GetLevel(myHero)+50 > GetCurrentHP(enemy)+GetDmgShield(enemy)+GetHPRegen(enemy)*2.5 and GoS:ValidTarget(enemy, 600) then
  			CastTargetSpell(enemy, Ignite)
  		end
		end
	end
end )
--Functions
function CastW(o)
	local WPred2 = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),20000,(math.floor(math.random()*500)+250),800,200,false,false)
	if WPred2.HitChance == 1 then
		CastSkillShot(_W,WPred2.PredPos.x,WPred2.PredPos.y,WPred2.PredPos.z)
	end
end
function CastE(o)
	CastTargetSpell(o, _E)
end
function CastR(o)
	CastTargetSpell(o,_R)
end
-------------------------------------------------------------------------------------------------------------------------
--Advanced Combos for KS
function CastQWStun(o)
	local QPred2 = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),(math.floor(math.random()*400)+1600),250,950,60,true,true)
	local WPred2 = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),20000,(math.floor(math.random()*500)+250),800,200,false,false)
	if (WPred2.HitChance == 1 or (CanUseSpell(myHero, _W) ~= READY)) then
		if QPred2.HitChance == 1 then
			CastSkillShot(_W,WPred2.PredPos.x,WPred2.PredPos.y,WPred2.PredPos.z)
			if GotBuff(o,"brandablaze")~=0 then
				CastSkillShot(_Q,QPred2.PredPos.x,QPred2.PredPos.y,QPred2.PredPos.z)
			end
		end
	end
end
function CastQWDamage(o)
	local QPred2 = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),(math.floor(math.random()*400)+1600),250,950,60,true,true)
	local WPred2 = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),20000,(math.floor(math.random()*500)+250),800,200,false,false)
	if (QPred2.HitChance == 1 or (CanUseSpell(myHero, _Q) ~= READY)) then
		if WPred2.HitChance == 1 then
			CastSkillShot(_Q,QPred2.PredPos.x,QPred2.PredPos.y,QPred2.PredPos.z)
			if GotBuff(o,"brandablaze")~=0 then
				CastSkillShot(_W,WPred2.PredPos.x,WPred2.PredPos.y,WPred2.PredPos.z)
			end
		end
	end
end
function CastQE(o)
	local QPred2 = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),(math.floor(math.random()*400)+1600),250,950,60,true,true)
	if (QPred2.HitChance == 1 or (CanUseSpell(myHero, _Q) ~= READY)) then
		CastTargetSpell(o, _E)
		if GotBuff(o,"brandablaze")~=0 then
				CastSkillShot(_Q,QPred2.PredPos.x,QPred2.PredPos.y,QPred2.PredPos.z)
		end
	end
end
function CastEW(o)
	local WPred2 = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),20000,(math.floor(math.random()*500)+250),800,200,false,false)
	if (WPred2.HitChance == 1 or (CanUseSpell(myHero, _W) ~= READY)) then
		CastTargetSpell(o, _E)
		if GotBuff(o,"brandablaze")~=0 then
				CastSkillShot(_W,WPred2.PredPos.x,WPred2.PredPos.y,WPred2.PredPos.z)
		end
	end
end
function CastQWE(o)
	local QPred2 = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),(math.floor(math.random()*400)+1600),250,950,60,true,true)
	local WPred2 = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),20000,(math.floor(math.random()*500)+250),800,200,false,false)
	if (QPred2.HitChance == 1 or (CanUseSpell(myHero, _Q) ~= READY) or (CanUseSpell(myHero, _E) ~= READY)) then
		if WPred2.HitChance == 1 then
			CastTargetSpell(o, _E)
			if GotBuff(o,"brandablaze")~=0 then
				CastSkillShot(_Q,QPred2.PredPos.x,QPred2.PredPos.y,QPred2.PredPos.z)
				CastSkillShot(_W,WPred2.PredPos.x,WPred2.PredPos.y,WPred2.PredPos.z)
			end
		end
	end
end
-------------------------------------------------------------------------------------------------------------------------
function Killsteal()
	for i,enemy in pairs(GOS:GetEnemyHeroes()) do
		if GOS:ValidTarget(enemy,25000) then
-------------------------------------------------------------------------------------------------------------------------
			local targetPos = GetOrigin(enemy)
			local drawPos = WorldToScreen(1,targetPos.x,targetPos.y,targetPos.z)
			local enemyhp = GetCurrentHP(enemy)+(GetHPRegen(enemy)/5)
			local QDMG,WDMG,EDMG,RDMG=0,0,0,0
			if CanUseSpell(myHero, _Q) == READY then
			QDMG=GOS:CalcDamage(myHero, enemy, 0, SpellQ)
			else
			QDMG=0
			end
			if CanUseSpell(myHero, _W) == READY then
			WDMG=GOS:CalcDamage(myHero, enemy, 0, SpellW)
				else
			WDMG=0
			end
			if CanUseSpell(myHero, _E) == READY then
			EDMG=GOS:CalcDamage(myHero, enemy, 0, SpellE)
			else
			EDMG=0
			end
			if CanUseSpell(myHero, _R) == READY then
			RDMG=GOS:CalcDamage(myHero, enemy, 0, Pyroclasm)
			else
			RDMG=0
			end
			local PDMG= GOS:CalcDamage(myHero, enemy, 0, ((((GetMaxHP(enemy)/100)*2)*4)-((GetHPRegen(enemy)/5)*4)))
			local totaldamage		=QDMG+WDMG+EDMG+PDMG
			local totaldamageR	=QDMG+WDMG+EDMG+RDMG+PDMG
			local SUM=100/(enemyhp/(enemyhp-totaldamage))
			local SUM1=100/(enemyhp/(enemyhp-totaldamageR))
-------------------------------------------------------------------------------------------------------------------------
			if SUM<=0 and SUM1>0 then
			if Config.Note:Value() then
				DrawCircle(drawPos.x,drawPos.y,50,10,0,0xffff0000)
				DrawText("Kill!!!",20,drawPos.x,drawPos.y,0xffff0000)
			end
			if Config.Percent:Value() and SUM<0 then
				SUM=0
				DrawText("\n\n" .. Round(SUM,0) .. "%" .. " | " .. Round(SUM1,0) .. "%",10,drawPos.x,drawPos.y,0xffffffff)
			end
			elseif SUM<=0 and SUM1<=0 then
			if Config.Note:Value() then
				DrawCircle(drawPos.x,drawPos.y,50,10,0,0xffff0000)
				DrawText("Kill!!!",20,drawPos.x,drawPos.y,0xffff0000)
			end
			if Config.Percent:Value() and SUM<0 and SUM1<0 then
				SUM=0 SUM1=0
				DrawText("\n\n" .. Round(SUM,0) .. "%" .. " | " .. Round(SUM1,0) .. "%",10,drawPos.x,drawPos.y,0xffffffff)
			end
			elseif SUM>0 and SUM1<=0 then
			if Config.Note:Value() then
				DrawCircle(drawPos.x,drawPos.y,50,10,0,0xffff0000)
				DrawText("Kill with Ulti!!!",20,drawPos.x,drawPos.y,0xffff0000)
			end
			if Config.Percent:Value() and SUM1<0 then
				SUM1=0
				DrawText("\n\n" .. Round(SUM,0) .. "%" .. " | " .. Round(SUM1,0) .. "%",10,drawPos.x,drawPos.y,0xffffffff)
			end
			elseif SUM>0 and SUM1>0 then
			if Config.Percent:Value() then
				DrawText("\n\n" .. Round(SUM,0) .. "%" .. " | " .. Round(SUM1,0) .. "%",10,drawPos.x,drawPos.y,0xffffffff)
			end
			end
-------------------------------------------------------------------------------------------------------------------------
			if Config.KS:Value() and ((GotBuff(enemy,"brandablaze")==0) or (GotBuff(enemy,"brandablaze")~=0 and enemyhp>PDMG)) then
				local QPred2 = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),(math.floor(math.random()*400)+1600),250,950,60,true,true)
				if GOS:ValidTarget(enemy,950) and enemyhp < QDMG+PDMG and CanUseSpell(myHero, _Q) == READY and GetCurrentMana(myHero)>=50 then
					if QPred2.HitChance == 1 then
						CastSkillShot(_Q,QPred2.PredPos.x,QPred2.PredPos.y,QPred2.PredPos.z)
						killable=1
					end
				elseif GOS:ValidTarget(enemy,800) and enemyhp < WDMG+PDMG  and CanUseSpell(myHero, _W) == READY and GetCurrentMana(myHero)>=((GetCastLevel(myHero,_W))*5+65) then
					CastW(enemy)
					killable=1
				elseif GOS:ValidTarget(enemy,650) and enemyhp < EDMG+PDMG  and CanUseSpell(myHero, _E) == READY and GetCurrentMana(myHero)>=((GetCastLevel(myHero,_E))*5+65) then
					CastE(enemy)
					killable=1
				elseif GOS:ValidTarget(enemy,650) and enemyhp < EDMG+WDMG*1.25+PDMG and CanUseSpell(myHero, _E) == READY and CanUseSpell(myHero, _W) == READY and GetCurrentMana(myHero)>=(((GetCastLevel(myHero,_W))*5+65)+(((GetCastLevel(myHero,_E))*5+65))) then
					CastEW(enemy)
					killable=1
				elseif GOS:ValidTarget(enemy,650) and enemyhp < EDMG+QDMG+PDMG  and CanUseSpell(myHero, _E) == READY and CanUseSpell(myHero, _Q) == READY and GetCurrentMana(myHero)>=((GetCastLevel(myHero,_E))*5+65)+50 then
					local QPred2 = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),(math.floor(math.random()*400)+1600),250,950,60,true,true)					if QPred2.HitChance == 1 then
						CastQE(enemy)
						killable=1
					end
				elseif GOS:ValidTarget(enemy,800) and enemyhp < QDMG+WDMG+PDMG  and CanUseSpell(myHero, _Q) == READY and CanUseSpell(myHero, _W) == READY and GetCurrentMana(myHero)>=((GetCastLevel(myHero,_W))*5+65)+50 then
					if QPred2.HitChance == 1 then
						CastQWStun(enemy)
						killable=1
					end
				elseif GOS:ValidTarget(enemy,800) and enemyhp < QDMG+WDMG*1.25+PDMG  and CanUseSpell(myHero, _Q) == READY and CanUseSpell(myHero, _W) == READY and GetCurrentMana(myHero)>=((GetCastLevel(myHero,_W))*5+65)+50 then
					if QPred2.HitChance == 1 then
						CastQWDamage(enemy)
						killable=1
					end
				elseif GOS:ValidTarget(enemy,650) and enemyhp < QDMG+WDMG+EDMG+PDMG  and CanUseSpell(myHero, _Q) == READY and CanUseSpell(myHero, _W) == READY and CanUseSpell(myHero, _E) == READY and GetCurrentMana(myHero)>=((GetCastLevel(myHero,_W))*5+65)+((GetCastLevel(myHero,_E))*5+65)+50 then
					if QPred2.HitChance == 1 then
						CastQWE(enemy)
						killable=1
					end
				elseif GOS:ValidTarget(enemy,GetCastRange(myHero,_R)) and enemyhp < GOS:CalcDamage(myHero, enemy, 0, (Pyroclasm*2)) and CanUseSpell(myHero, _R) == READY and ((CountEnemyHeroInRange(enemy,400)>=2 and CountEnemyHeroInRange(enemy,400)<=4) or (CountEnemyMinionInRange(enemy,400)>=1)) and GetCurrentMana(myHero)>=100 then
					CastR(enemy)
					killable=1
				elseif GOS:ValidTarget(enemy,GetCastRange(myHero,_R)) and enemyhp < GOS:CalcDamage(myHero, enemy, 0, (Pyroclasm*3)) and CanUseSpell(myHero, _R) == READY and ((CountEnemyHeroInRange(enemy,400)==2) or (CountEnemyMinionInRange(enemy,400)<=3 and (CountEnemyMinionInRange(enemy,400)>=1) and GotBuff(enemy,"brandablaze")~=0 )) and GetCurrentMana(myHero)>=100 then
					CastR(enemy)
					killable=1
				else
					killable=0
				end
			end
		end
	end
end
-------------------------------------------------------------------------------------------------------------------------
function CountEnemyHeroInRange(object,range)
  object = object or myHero
  local enemyInRange = 0
  for i, enemy in pairs(GOS:GetEnemyHeroes()) do
    if (enemy~=nil and GetTeam(myHero)~=GetTeam(enemy) and IsDead(enemy)==false) and GOS:GetDistance(object, enemy)<= range then
    	enemyInRange = enemyInRange + 1
    end
  end
  return enemyInRange
end
-------------------------------------------------------------------------------------------------------------------------
function Round(val, decimal)
	if (decimal) then
		return math.floor( (val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
	else
		return math.floor(val + 0.5)
	end
end
function CountEnemyMinionInRange(object,range)
	local minion = nil
	local minionInRange=0
	for k,v in pairs(GOS:GetAllMinions()) do
		local objTeam = GetTeam(v)
		if not minion and v and objTeam == GetTeam(object) then 
			minion = v 
		end
		if minion and v and objTeam == GetTeam(object) and GOS:GetDistanceSqr(GetOrigin(minion),GetOrigin(object)) > GOS:GetDistanceSqr(GetOrigin(v),GetOrigin(object)) then
			minion = v
		end
		if minion and v and objTeam == GetTeam(object) and GOS:GetDistance(GetOrigin(minion),GetOrigin(object))<=range then
			minionInRange=minionInRange+1
		end
	end
  return minionInRange
end
