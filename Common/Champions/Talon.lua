--Note:
--[[
To check if AAReset is possible use: AttackReadiness()<1
--]]

Talon=Menu("Talon","Maxxxel Talon God")
Talon:Key("Combo","Combo",string.byte(" "))
Talon:SubMenu("KS","Killfunctions")
Talon.KS:Boolean("Ignite","Auto-Ignite",true)
Talon.KS:Boolean("R", "Smart Ulti",true)
Talon.KS:Boolean("Percent","Show % Kill",true)

--Variables--
local version = 0.7 --updated ignite
local xHydra,HRDY,QRDY,WRDY,ERDY,R1RDY,R2RDY,HydraCast,HydraCastTime,LastWhisper=0,0,0,0,0,0,0,0,0,1
local target
local xAA,xQ,xQ2,xW,xE,xR,from,to,IRDY,xIgnite
local Check = 0

local KSN = {}
local enemies = {}
local Enemy = {}
local Attack = {Target=nil,Time ={Start=0,Reset =0}}
local Damage = {Success=false}
local myHero = GetMyHero()

--Every Loop do following funcs--
OnLoop(function(myHero)
	if not IsDead(myHero) then
		CheckItemCD()
		DamageFunc()
		SpellSequence()
		AAHandling()
		EnemyHandling()
	end
end)
--AA stuff
function AAHandling()
	if (AttackReadiness() >= 1 and Damage.Success) or (AttackReadiness() >=1 and Attack.Time.Start>GetTickCount()+1500) then
		Attack = {
     Time = { 
      Start= 0,
      End  =0,
      Reset=0},
     Target=nil,
     Pos = {
      Start = {
       x = 0,
       y = 0,
       z = 0},
      End = {
       x = 0,
       y = 0,
       z = 0}},
     Type  =nil}
		Damage = {Success=false,
     Position = {
      x = 0,
      y = 0,
      z = 0},
     Time = 0}
  end
end
--Check Cooldown of Hydra Function--
function CheckItemCD()
	if GetItemSlot(myHero,3035)>0 then --LW ready
		LastWhisper=0.65
	else
		LastWhisper=1
	end
	if HydraCastTime~=0 and HydraCast==1 and (GetTickCount()-HydraCastTime)>=10000 then
		HydraCast=0 HydraCastTime=0
	end
	if (GetItemSlot(myHero,3074)+GetItemSlot(myHero,3077))>0 and HydraCast==0 then
		HRDY=1
	else 
		HRDY=0
	end
	if CanUseSpell(myHero,Ignite)==0 then
		IRDY=1
	else 
		IRDY=0
	end
end
--Set Damage for skills
function DamageFunc()
	xAA = (GetBaseDamage(myHero)+GetBonusDmg(myHero))
	xQ = xAA+30*GetCastLevel(myHero,_Q)+(.3*GetBonusDmg(myHero))
	xQ2 = (10*GetCastLevel(myHero,_Q))+(GetBonusDmg(myHero)) --over 6 seconds
	xW = 2*(5+(25*GetCastLevel(myHero,_W))+(.6*GetBonusDmg(myHero))) --can hit 2 times, took into account
	xE = 1+((GetCastLevel(myHero,_E)*3)*.01)
	xR = 70+(GetCastLevel(myHero,_R)*50)+(.75*GetBonusDmg(myHero)) --can hit 2 times, needs double cast
	xHYDRA = (.6*(GetBaseDamage(myHero)+GetBonusDmg(myHero)))*HRDY
	xIgnite = (50+GetLevel(myHero)*20)*IRDY
end
--Attack 2.0--
function AttackReadiness()
	if Damage.Success then
		local time = GetTickCount()
		local APS = (Attack.Time.End-time)/2 --time between DamageProcs
	  local xTime = (Attack.Time.Start~=0 and Attack.Time.Start + APS) or time
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
--Check Talon Attacks for AA-Reset, and Hydra Cast--
OnProcessSpell(function(Object,Spell)
  local ObjName = GetObjectName(Object)
  if Object and ObjName == GetObjectName(myHero) then
  	local time= GetTickCount()
    if Spell.name:lower():find("attack") then --so we know our hero attacks
      Attack = {
       Time = { 
        Start=time,
        End  =time+Spell.animationTime*1000,
        Reset=time+Spell.windUpTime*1000},
       Target=Spell.target,
       Pos = {
        Start = {
         x = Spell.startPos.x,
         y = Spell.startPos.y,
         z = Spell.startPos.z},
        End = {
         x = Spell.endPos.x,
         y = Spell.endPos.y,
         z = Spell.endPos.z}},
       Type = "Basic"}
    elseif Spell.name:lower():find("noxiandiploma") then
      Attack = {
       Time = { 
        Start=time,
        End  =time+Spell.animationTime*1000,
        Reset=0},
       Target=Spell.target,
       Pos = {
        Start = {
         x = Spell.startPos.x,
         y = Spell.startPos.y,
         z = Spell.startPos.z},
        End = {
         x = Spell.endPos.x,
         y = Spell.endPos.y,
         z = Spell.endPos.z}},
       Type = "Q"}
    end
		if GetObjectName(Spell) and GetObjectname(Spell) =="ItemTiamatCleave" and HydraCast==0 then
			HydraCast=1
			HydraCastTime=GetTickCount()
		end
	end
end)
--Check for aa finishs
OnCreateObj(function(Object)
	if Object and GOS:GetDistance(Object)<=700 then
	  local Name  = GetObjectBaseName(Object)
	  if Name:lower():find("bloodslash") then
	  	if Attack.Target then
	  		local Pos2D   = GetOrigin(Object)
	 		  local Pos = WorldToScreen(1,Pos2D)
	      if GetDistanceXYZ(Pos2D.x,Pos2D.z,Attack.Pos.End.x,Attack.Pos.End.z)<100 then
	          Damage = {Success=true,
	           Position = {
	            x = Pos.x,
	            y = Pos.y,
	            z = Pos.z},
	           Time = GetTickCount()}
	      end
	    end
	  end 
	end       
end)
--Enemies---
function EnemyHandling()
	for i,enemy in pairs(GoS:GetEnemyHeroes()) do
		if #enemies~= 5 then --check if an enemy isnt in table yet.
			local entry = {hero = CheckEnemy(GetObjectName(enemy))} --returns nil if an enemy isnt in list already. and returns enemy for added enemies.
			if entry.hero == nil then
				--PrintChat("Empty entry found, adding "..GetObjectName(enemy))
				drawPos= GetOrigin(enemy)
				Enemy = {hero = enemy, name = GetObjectName(enemy), maxHealth = GetMaxHP(enemy)*((100+(((GetArmor(enemy)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(enemy)*6 ,health = GetCurrentHP(enemy)*((100+(((GetArmor(enemy)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(enemy)*6, Pos ={x=drawPos.x,y=drawPos.y,z=drawPos.z}}
        table.insert(enemies, Enemy)
			elseif entry.hero ~= enemy then
				entry.hero = enemy
			end
		end
	end
	if #enemies > 0 then
    for i,enemy in ipairs(enemies) do
			if enemy == nil or enemy.hero == nil or not enemy then
				table.remove(enemies,i)
			elseif enemy.name == nil or GetObjectName(enemy.hero):find(enemy.name) == nil then
				table.remove(enemies,i)
      else
				if IsVisible(enemy.hero) then
					drawPos = GetOrigin(enemy.hero)
					if GetCurrentHP(enemy.hero)*((100+(((GetArmor(enemy.hero)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(enemy.hero)*6 ~= enemy.health then
						--PrintChat("Health update on "..enemy.name)
						enemy.health = GetCurrentHP(enemy.hero)*((100+(((GetArmor(enemy.hero)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(enemy.hero)*6
					end
					if GetMaxHP(enemy.hero)*((100+(((GetArmor(enemy.hero)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(enemy.hero)*6 ~= enemy.maxHealth then
						--PrintChat("Health update on "..enemy.name)
						enemy.maxHealth = GetMaxHP(enemy.hero)*((100+(((GetArmor(enemy.hero)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(enemy.hero)*6
					end
					if enemy.Pos.x~= drawPos.x then
						enemy.Pos.x=drawPos.x
						enemy.Pos.y=drawPos.y
						enemy.Pos.z=drawPos.z
					end
				end
			end
		end
	end
end
--Main Function, calcs the Killnotis and which Spell to use on Combo--
function SpellSequence()
--Skill Sequences--
	KSN[1]  = {a=1,b=0,c=0,d=1,e=0,H=xAA+xQ+xQ2+xR, text='AA-Q-R1'}
	KSN[2]  = {a=1,b=0,c=0,d=0,e=0,H=xAA+xQ+xQ2, text='AA-Q'}
	KSN[3]  = {a=1,b=0,c=0,d=0,e=1,H=xAA+xQ+xQ2+xR, text='AA-Q-R2'}
	KSN[4]  = {a=1,b=0,c=0,d=1,e=n,H=xAA+xQ+xQ2+xR*2, text='AA-Q+R1R2'}
	KSN[5]  = {a=1,b=1,c=0,d=1,e=0,H=xAA+xQ+xQ2+xR+xW, text='AA-Q-W-R1'}
	KSN[6]  = {a=1,b=1,c=0,d=0,e=0,H=xQ+xQ2+xW, text='Q-W'}
	KSN[7]  = {a=1,b=1,c=0,d=0,e=1,H=xAA+xQ+xQ2+xR+xW, text='AA-Q-W-R2'}
	KSN[8]  = {a=1,b=1,c=0,d=1,e=n,H=xAA+xQ+xQ2+xW+xR*2, text='R1-AA-Q-W-R2'}	
	KSN[9]  = {a=1,b=0,c=1,d=1,e=0,H=((xAA+xQ)*(xE+0.1))+xR*xE+xQ2, text='E-AA-Q-R1'}
	KSN[10] = {a=1,b=0,c=1,d=0,e=0,H=((xAA+xQ)*(xE+0.1))+xQ2, text='E-AA-Q'}
	KSN[11] = {a=1,b=0,c=1,d=0,e=1,H=((xAA+xQ)*(xE+0.1))+xR*xE+xQ2, text='E-AA-Q-R2'}
	KSN[12] = {a=1,b=0,c=1,d=1,e=n,H=((xAA+xQ)*(xE+0.1))+xQ2+(xR*2)*xE, text='E-AA-Q-R1-R2'}	
	KSN[13] = {a=1,b=1,c=1,d=1,e=0,H=((xAA+xQ)*(xE+0.1))+xQ2+(xW+xR)*xE, text='E-AA-Q-W-R1'}
	KSN[14] = {a=1,b=1,c=1,d=0,e=0,H=xW*xE+xQ2+(xQ+xAA)*(0.1+xE), text='E-AA-Q-W'}
	KSN[15] = {a=1,b=1,c=1,d=0,e=1,H=((xAA+xQ)*(xE+0.1))+xQ2+(xW+xR)*xE, text='E-AA-Q-W-R2'}	
	KSN[16] = {a=1,b=1,c=1,d=1,e=n,H=((xAA+xQ)*(xE+0.1))+(xW+xR)*xE+xQ2+xR, text='E-AA-Q-W-R1R2'}
	KSN[17] = {a=1,b=1,c=1,d=1,e=n,H=((xQ+xAA)*(xE+0.1))+(xW+xR)*xE+xQ2+xR, text='E-AA-Q-W-R1R2'}	
	KSN[18] = {a=0,b=0,c=0,d=1,e=0,H=xR, text='R1'}
	KSN[19] = {a=0,b=0,c=0,d=0,e=0,H=xAA, text='AA'}
	KSN[20] = {a=0,b=0,c=0,d=0,e=1,H=xR, text='R2'}
	KSN[21] = {a=0,b=0,c=0,d=1,e=n,H=xR*2, text='R1R2'}
	KSN[22] = {a=0,b=1,c=0,d=1,e=0,H=xW+xR, text='W-R1'}
	KSN[23] = {a=0,b=1,c=0,d=0,e=0,H=xW, text='W'}
	KSN[24] = {a=0,b=1,c=0,d=0,e=1,H=xW+xR, text='W-R2'}	
	KSN[25] = {a=0,b=1,c=0,d=1,e=n,H=xW+xR*2, text='W+R1R2'}
	KSN[26] = {a=0,b=0,c=1,d=1,e=0,H=xR*xE, text='E-R1'}
	KSN[27] = {a=0,b=0,c=1,d=0,e=1,H=xR*xE, text='E-R2'}
	KSN[28] = {a=0,b=0,c=1,d=1,e=n,H=xR+xR*xE, text='E+R1R2'}
	KSN[29] = {a=0,b=1,c=1,d=1,e=0,H=(xW+xR)*(xE), text='E-W-R1'}
	KSN[30] = {a=0,b=1,c=1,d=0,e=0,H=xW*xE, text='E-W'}
	KSN[31] = {a=0,b=1,c=1,d=0,e=1,H=(xW+xR)*(xE), text='E-W-R2'}
	KSN[32] = {a=0,b=1,c=1,d=0,e=1,H=(xW+xR*2)*xE, text='E-R1-W-R2'}
	
	if 		 CD(1,0,0,n,n)==1 then
		from=1
		to=4
	elseif CD(1,1,0,n,n)==1 then
		from=5
		to=8
	elseif CD(1,0,1,n,n)==1 then
		from=9
		to=12
	elseif CD(1,1,1,n,n)==1 then
		from=13
		to=17
	elseif CD(0,0,0,n,n)==1 then
		from=18
		to=21
	elseif CD(0,1,0,n,n)==1 then
		from=22
		to=25
	elseif CD(0,0,1,n,n)==1 then
		from=26
		to=28
	elseif CD(0,1,1,n,n)==1 then
		from=29
		to=32
	end
	if #enemies > 0 then
    for i,enemy in ipairs(enemies) do
    	if GOS:GetDistance(enemy.hero)<=2000 and Talon.KS.Percent and Valid(enemy.hero) then
	    	local drawing = WorldToScreen(1,enemy.Pos.x,enemy.Pos.y,enemy.Pos.z)
	    	local SUM=0
				for v=from,to do
					if HRDY*IRDY==1 and CD(KSN[v].a,KSN[v].b,KSN[v].c,KSN[v].d,KSN[v].e)==1 and Mana(KSN[v].a,KSN[v].b,KSN[v].c,KSN[v].d,KSN[v].e)==1 and enemy.health<KSN[v].H+xHydra+xIgnite then
						DrawCircle(enemy.Pos.x,enemy.Pos.y,enemy.Pos.z,200,10,0,0xffff0000)
						enemy.KillType=1
					elseif HRDY==1 and CD(KSN[v].a,KSN[v].b,KSN[v].c,KSN[v].d,KSN[v].e)==1 and Mana(KSN[v].a,KSN[v].b,KSN[v].c,KSN[v].d,KSN[v].e)==1 and enemy.health<KSN[v].H+xHydra then
						DrawCircle(enemy.Pos.x,enemy.Pos.y,enemy.Pos.z,200,10,0,0xffff0000)
						enemy.KillType=2
					elseif IRDY==1 and CD(KSN[v].a,KSN[v].b,KSN[v].c,KSN[v].d,KSN[v].e)==1 and Mana(KSN[v].a,KSN[v].b,KSN[v].c,KSN[v].d,KSN[v].e)==1 and enemy.health<KSN[v].H+xIgnite then
						DrawCircle(enemy.Pos.x,enemy.Pos.y,enemy.Pos.z,200,10,0,0xffff0000)
						enemy.KillType=3
					elseif CD(KSN[v].a,KSN[v].b,KSN[v].c,KSN[v].d,KSN[v].e)==1 and Mana(KSN[v].a,KSN[v].b,KSN[v].c,KSN[v].d,KSN[v].e)==1 and enemy.health<KSN[v].H then
						DrawCircle(enemy.Pos.x,enemy.Pos.y,enemy.Pos.z,100,10,0,0xffff0000)
						enemy.KillType=nil
					else
						SUM= math.max(
							KSN[1].H*CD(KSN[1].a,KSN[1].b,KSN[1].c,KSN[1].d,KSN[1].e)*Mana(KSN[1].a,KSN[1].b,KSN[1].c,KSN[1].d,KSN[1].e),
							KSN[2].H*CD(KSN[2].a,KSN[2].b,KSN[2].c,KSN[2].d,KSN[2].e)*Mana(KSN[2].a,KSN[2].b,KSN[2].c,KSN[2].d,KSN[2].e),
							KSN[3].H*CD(KSN[3].a,KSN[3].b,KSN[3].c,KSN[3].d,KSN[3].e)*Mana(KSN[3].a,KSN[3].b,KSN[3].c,KSN[3].d,KSN[3].e),
							KSN[4].H*CD(KSN[4].a,KSN[4].b,KSN[4].c,KSN[4].d,KSN[4].e)*Mana(KSN[4].a,KSN[4].b,KSN[4].c,KSN[4].d,KSN[4].e),
							KSN[5].H*CD(KSN[5].a,KSN[5].b,KSN[5].c,KSN[5].d,KSN[5].e)*Mana(KSN[5].a,KSN[5].b,KSN[5].c,KSN[5].d,KSN[5].e),
							KSN[6].H*CD(KSN[6].a,KSN[6].b,KSN[6].c,KSN[6].d,KSN[6].e)*Mana(KSN[6].a,KSN[6].b,KSN[6].c,KSN[6].d,KSN[6].e),
							KSN[7].H*CD(KSN[7].a,KSN[7].b,KSN[7].c,KSN[7].d,KSN[7].e)*Mana(KSN[7].a,KSN[7].b,KSN[7].c,KSN[7].d,KSN[7].e),
							KSN[8].H*CD(KSN[8].a,KSN[8].b,KSN[8].c,KSN[8].d,KSN[8].e)*Mana(KSN[8].a,KSN[8].b,KSN[8].c,KSN[8].d,KSN[8].e),
							KSN[9].H*CD(KSN[9].a,KSN[9].b,KSN[9].c,KSN[9].d,KSN[9].e)*Mana(KSN[9].a,KSN[9].b,KSN[9].c,KSN[9].d,KSN[9].e),
							KSN[10].H*CD(KSN[10].a,KSN[10].b,KSN[10].c,KSN[10].d,KSN[10].e)*Mana(KSN[10].a,KSN[10].b,KSN[10].c,KSN[10].d,KSN[10].e),
							KSN[11].H*CD(KSN[11].a,KSN[11].b,KSN[11].c,KSN[11].d,KSN[11].e)*Mana(KSN[11].a,KSN[11].b,KSN[11].c,KSN[11].d,KSN[11].e),
							KSN[12].H*CD(KSN[12].a,KSN[12].b,KSN[12].c,KSN[12].d,KSN[12].e)*Mana(KSN[12].a,KSN[12].b,KSN[12].c,KSN[12].d,KSN[12].e),
							KSN[13].H*CD(KSN[13].a,KSN[13].b,KSN[13].c,KSN[13].d,KSN[13].e)*Mana(KSN[13].a,KSN[13].b,KSN[13].c,KSN[13].d,KSN[13].e),
							KSN[14].H*CD(KSN[14].a,KSN[14].b,KSN[14].c,KSN[14].d,KSN[14].e)*Mana(KSN[14].a,KSN[14].b,KSN[14].c,KSN[14].d,KSN[14].e),
							KSN[15].H*CD(KSN[15].a,KSN[15].b,KSN[15].c,KSN[15].d,KSN[15].e)*Mana(KSN[15].a,KSN[15].b,KSN[15].c,KSN[15].d,KSN[15].e),
							KSN[16].H*CD(KSN[16].a,KSN[16].b,KSN[16].c,KSN[16].d,KSN[16].e)*Mana(KSN[16].a,KSN[16].b,KSN[16].c,KSN[16].d,KSN[16].e),
							KSN[17].H*CD(KSN[17].a,KSN[17].b,KSN[17].c,KSN[17].d,KSN[17].e)*Mana(KSN[17].a,KSN[17].b,KSN[17].c,KSN[17].d,KSN[17].e),
							KSN[18].H*CD(KSN[18].a,KSN[18].b,KSN[18].c,KSN[18].d,KSN[18].e)*Mana(KSN[18].a,KSN[18].b,KSN[18].c,KSN[18].d,KSN[18].e),
							KSN[19].H*CD(KSN[19].a,KSN[19].b,KSN[19].c,KSN[19].d,KSN[19].e)*Mana(KSN[19].a,KSN[19].b,KSN[19].c,KSN[19].d,KSN[19].e),
							KSN[20].H*CD(KSN[20].a,KSN[20].b,KSN[20].c,KSN[20].d,KSN[20].e)*Mana(KSN[20].a,KSN[20].b,KSN[20].c,KSN[20].d,KSN[20].e),
							KSN[21].H*CD(KSN[21].a,KSN[21].b,KSN[21].c,KSN[21].d,KSN[21].e)*Mana(KSN[21].a,KSN[21].b,KSN[21].c,KSN[21].d,KSN[21].e),
							KSN[22].H*CD(KSN[22].a,KSN[22].b,KSN[22].c,KSN[22].d,KSN[22].e)*Mana(KSN[22].a,KSN[22].b,KSN[22].c,KSN[22].d,KSN[22].e),
							KSN[23].H*CD(KSN[23].a,KSN[23].b,KSN[23].c,KSN[23].d,KSN[23].e)*Mana(KSN[23].a,KSN[23].b,KSN[23].c,KSN[23].d,KSN[23].e),
							KSN[24].H*CD(KSN[24].a,KSN[24].b,KSN[24].c,KSN[24].d,KSN[24].e)*Mana(KSN[24].a,KSN[24].b,KSN[24].c,KSN[24].d,KSN[24].e),
							KSN[25].H*CD(KSN[25].a,KSN[25].b,KSN[25].c,KSN[25].d,KSN[25].e)*Mana(KSN[25].a,KSN[25].b,KSN[25].c,KSN[25].d,KSN[25].e),
							KSN[26].H*CD(KSN[26].a,KSN[26].b,KSN[26].c,KSN[26].d,KSN[26].e)*Mana(KSN[26].a,KSN[26].b,KSN[26].c,KSN[26].d,KSN[26].e),
							KSN[27].H*CD(KSN[27].a,KSN[27].b,KSN[27].c,KSN[27].d,KSN[27].e)*Mana(KSN[27].a,KSN[27].b,KSN[27].c,KSN[27].d,KSN[27].e),
							KSN[28].H*CD(KSN[28].a,KSN[28].b,KSN[28].c,KSN[28].d,KSN[28].e)*Mana(KSN[28].a,KSN[28].b,KSN[28].c,KSN[28].d,KSN[28].e),
							KSN[29].H*CD(KSN[29].a,KSN[29].b,KSN[29].c,KSN[29].d,KSN[29].e)*Mana(KSN[29].a,KSN[29].b,KSN[29].c,KSN[29].d,KSN[29].e),
							KSN[30].H*CD(KSN[30].a,KSN[30].b,KSN[30].c,KSN[30].d,KSN[30].e)*Mana(KSN[30].a,KSN[30].b,KSN[30].c,KSN[30].d,KSN[30].e),
							KSN[31].H*CD(KSN[31].a,KSN[31].b,KSN[31].c,KSN[31].d,KSN[31].e)*Mana(KSN[31].a,KSN[31].b,KSN[31].c,KSN[31].d,KSN[31].e),
							KSN[32].H*CD(KSN[32].a,KSN[32].b,KSN[32].c,KSN[32].d,KSN[32].e)*Mana(KSN[32].a,KSN[32].b,KSN[32].c,KSN[32].d,KSN[32].e))
						if Round(((enemy.health-SUM)/enemy.maxHealth*100),0)>0 then 
							DrawText("\n\n" .. Round(((enemy.health-SUM)/enemy.maxHealth*100),0) .. "%",15,drawing.x,drawing.y,0xffff0000) 
						end
					end
					if enemy.KillType==1 and GOS:GetDistance(enemy.hero)<=600 then
						if GOS:GetDistance(enemy.hero)<=300 and HRDY==1 then
							GOS:CastOffensiveItems(enemy.hero)
						end
						if IRDY==1 then
							CastTargetSpell(enemy.hero,Ignite)
						end
					elseif enemy.KillType==3 and GOS:GetDistance(enemy.hero)<=600 and IRDY==1 then
						CastTargetSpell(enemy.hero,Ignite)
					elseif enemy.KillType==2 and GOS:GetDistance(enemy.hero)<=300 and HRDY==1 then
						GOS:CastOffensiveItems(enemy.hero)
					end
				end
			end
		end
	end
	if Talon.Combo:Value() and not IsDead(myHero) then
		target=GetCurrentTarget()
		if target and Valid(target) and GOS:GetDistance(target)<=700 then
			if ((AttackReadiness()~=1 and CanUseSpell(myHero,_Q)~=0 and QRDY==0) or GOS:GetDistance(target)>260) and GOS:GetDistance(target)>100 then
				MoveToMouse()
			end
			local DMG = math.max((CD(0,0,1,1,n)*Mana(0,0,1,1,n)*xR*2*xE),(CD(0,0,1,0,1)*Mana(0,0,1,0,0)*xE*xR),(CD(1,0,1,1,n)*Mana(1,0,1,1,n)*((xAA+xQ)*(0.1+xE)+xQ2+xR*2*xE)),(CD(1,0,1,0,1)*Mana(1,0,1,0,0)*((xAA+xQ)*(0.1+xE)+xQ2+xR*xE)),(CD(0,1,1,1,n)*Mana(0,1,1,1,n)*xE*(xW+xR*2)),(CD(0,1,1,0,1)*Mana(0,1,1,0,0)*xE*(xW+xR)),(CD(1,1,1,1,n)*Mana(1,1,1,1,n)*((xQ+xAA)*(0.1+xE)+(xW+xR*2)*xE)),(CD(1,1,1,0,1)*Mana(1,1,1,0,0)*((xQ+xAA)*(0.1+xE)+(xW+xR)*xE)))
			if Talon.KS.R and GOS:GetDistance(target)<=650 and (GetCurrentHP(target)*((100+(((GetArmor(target)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(target)*6 -DMG)<=0 then
				if (GetCurrentHP(target)*((100+(((GetArmor(target)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(target)*6 -(DMG-xR*2))<=0 then
					if ((CD(1,0,1,1,n)==1 and Mana(1,0,1,1,n)==1) or (CD(1,0,1,0,1)==1 and Mana(1,0,1,0,0)==1) or (CD(0,1,1,1,n)==1 and Mana(0,1,1,1,n)==1) or (CD(0,1,1,0,1)==1 and Mana(0,1,1,0,0)==1) or (CD(1,1,1,1,n)==1 and Mana(1,1,1,1,n)==1) or (CD(1,1,1,0,1)==1 and Mana(1,1,1,0,0)==1)) then
						E(target)
					end
				else
					if ((CD(0,0,1,1,n)==1 and Mana(0,0,1,1,n)==1) or (CD(0,0,1,0,1)==1 and Mana(0,0,1,0,0)==1) or (CD(0,0,1,0,n)==1 and Mana(0,0,1,0,0)==1) or (CD(1,0,1,1,n)==1 and Mana(1,0,1,1,n)==1) or (CD(1,0,1,0,1)==1 and Mana(1,0,1,0,0)==1) or (CD(n,0,1,0,n)==1 and Mana(0,0,1,0,0)==1) or (CD(0,1,1,1,n)==1 and Mana(0,1,1,1,n)==1) or (CD(0,1,1,0,1)==1 and Mana(0,1,1,0,0)==1) or (CD(0,n,1,0,n)==1 and Mana(0,0,1,0,0)==1) or (CD(1,1,1,1,n)==1 and Mana(1,1,1,1,n)==1) or (CD(1,1,1,0,1)==1 and Mana(1,1,1,0,0)==1) or (CD(n,n,1,0,n)==1 and Mana(0,0,1,0,0)==1)) then
						E(target)
					end
				end
			elseif Talon.KS.R and (GetCurrentHP(target)*((100+(((GetArmor(target)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(target)*6 -DMG)>0 then
				if ((CD(0,0,1,0,0)==1 and Mana(0,0,1,0,0)==1) or (CD(1,0,1,0,0)==1 and Mana(1,0,1,0,0)==1) or (CD(n,0,1,0,0)==1 and Mana(0,0,1,0,0)==1) or (CD(0,1,1,0,0)==1 and Mana(0,1,1,0,0)==1) or (CD(0,n,1,0,0)==1 and Mana(0,0,1,0,0)==1) or (CD(0,0,1,1,n)==1 and Mana(0,0,1,1,n)==1) or (CD(0,0,1,n,0)==1 and Mana(0,0,1,0,0)==1) or (CD(0,0,1,0,1)==1 and Mana(0,0,1,0,0)==1) or (CD(0,0,1,0,n)==1 and Mana(0,0,1,0,0)==1) or (CD(1,1,1,0,0)==1 and Mana(1,1,1,0,0)==1) or (CD(n,n,1,0,0)==1 and Mana(0,0,1,0,0)==1) or (CD(1,0,1,1,n)==1 and Mana(1,0,1,1,n)==1) or (CD(n,0,1,n,0)==1 and Mana(0,0,1,0,0)==1) or (CD(1,0,1,0,1)==1 and Mana(1,0,1,0,0)==1) or (CD(n,0,1,0,n)==1 and Mana(0,0,1,0,0)==1) or (CD(0,1,1,1,n)==1 and Mana(0,1,1,1,n)==1) or (CD(0,n,1,n,0)==1 and Mana(0,0,1,0,0)==1) or (CD(0,1,1,0,1)==1 and Mana(0,1,1,0,0)==1) or (CD(0,n,1,0,n)==1 and Mana(0,0,1,0,0)==1) or 	(CD(1,1,1,1,n)==1 and Mana(1,1,1,1,n)==1) or (CD(n,n,1,n,0)==1 and Mana(0,0,1,0,0)==1) or (CD(1,1,1,0,1)==1 and Mana(1,1,1,0,0)==1) or (CD(n,n,1,0,n)==1 and Mana(0,0,1,0,0)==1)) then
					E(target)
				end
			else
				if ((CD(0,0,1,0,0)==1 and Mana(0,0,1,0,0)==1) or (CD(1,0,1,0,0)==1 and Mana(1,0,1,0,0)==1) or (CD(n,0,1,0,0)==1 and Mana(0,0,1,0,0)==1) or (CD(0,1,1,0,0)==1 and Mana(0,1,1,0,0)==1) or (CD(0,n,1,0,0)==1 and Mana(0,0,1,0,0)==1) or (CD(0,0,1,1,n)==1 and Mana(0,0,1,1,n)==1) or (CD(0,0,1,n,0)==1 and Mana(0,0,1,0,0)==1) or (CD(0,0,1,0,1)==1 and Mana(0,0,1,0,0)==1) or (CD(0,0,1,0,n)==1 and Mana(0,0,1,0,0)==1) or (CD(1,1,1,0,0)==1 and Mana(1,1,1,0,0)==1) or (CD(n,n,1,0,0)==1 and Mana(0,0,1,0,0)==1) or (CD(1,0,1,1,n)==1 and Mana(1,0,1,1,n)==1) or (CD(n,0,1,n,0)==1 and Mana(0,0,1,0,0)==1) or (CD(1,0,1,0,1)==1 and Mana(1,0,1,0,0)==1) or (CD(n,0,1,0,n)==1 and Mana(0,0,1,0,0)==1) or (CD(0,1,1,1,n)==1 and Mana(0,1,1,1,n)==1) or (CD(0,n,1,n,0)==1 and Mana(0,0,1,0,0)==1) or (CD(0,1,1,0,1)==1 and Mana(0,1,1,0,0)==1) or (CD(0,n,1,0,n)==1 and Mana(0,0,1,0,0)==1) or (CD(1,1,1,1,n)==1 and Mana(1,1,1,1,n)==1) or (CD(n,n,1,n,0)==1 and Mana(0,0,1,0,0)==1) or (CD(1,1,1,0,1)==1 and Mana(1,1,1,0,0)==1) or (CD(n,n,1,0,n)==1 and Mana(0,0,1,0,0)==1)) then
					E(target)
				end
			end
			if GOS:GetDistance(target)<=700-(GetMoveSpeed(target)*.15) and ((AttackReadiness()<1 and CanUseSpell(myHero,_Q)~=0 and QRDY==0 ) or (CanUseSpell(myHero,_Q)==0 and GOS:GetDistance(target)>260)) then
				W(target)
			end
			if GOS:GetDistance(target)<=650 then
				if GetCastName(myHero,_R)~="talonshadowassaulttoggle" then
					local DMG = math.max(((CD(0,0,0,1,n)*Mana(0,0,0,1,n))*xR*2),((CD(1,0,0,1,n)*Mana(1,0,0,1,n))*(xAA+xQ+xQ2+xR*2)),((CD(n,0,0,1,n)* Mana(0,0,0,1,n))*xR*2),((CD(0,1,0,1,n)*Mana(0,1,0,1,n))*(xW+xR*2)),((CD(0,n,0,1,n)*Mana(0,0,0,1,n))*(xR*2)),((CD(1,1,0,1,n)*Mana(1,1,0,1,n))*(xAA+xQ+xQ2+xW+xR*2)),((CD(n,n,0,1,n)*Mana(0,0,0,1,n)))*xR*2)
					if Talon.KS.R and (GetCurrentHP(target)*((100+(((GetArmor(target)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(target)*6-DMG)<=0 then --if 2xR kills him
						if (GetCurrentHP(target)*((100+(((GetArmor(target)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(target)*6-(DMG-xR*2))<=0 then --if killable without R
							if 		 (CD(1,0,0,1,n)==1 and Mana(1,0,0,1,n)==1) and GOS:GetDistance(target)<=250 and AttackReadiness()<1 then
								CastSpell(_Q)
							elseif ((CD(0,1,0,1,n)==1 and Mana(0,1,0,1,n)==1) or (CD(1,1,0,1,n)==1 and Mana(1,1,0,1,n)==1)) and GOS:GetDistance(target)<=700-(GetMoveSpeed(target)*.15) then
								W(target)
							end
						elseif (GetCurrentHP(target)*((100+(((GetArmor(target)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(target)*6-DMG)<=0 then
							if ((CD(0,0,0,1,n)==1 and Mana(0,0,0,1,n)==1) or (CD(1,0,0,1,n)==1 and Mana(1,0,0,1,n)==1) or	(CD(n,0,0,1,n)==1 and Mana(0,0,0,1,n)==1) or (CD(0,1,0,1,n)==1 and Mana(0,1,0,1,n)==1) or (CD(0,n,0,1,n)==1 and Mana(0,0,0,1,n)==1) or (CD(1,1,0,1,n)==1 and Mana(1,1,0,1,n)==1) or (CD(n,n,0,1,n)==1 and Mana(0,0,0,1,n)==1)) then
								R1(target)
							end
						end
					elseif Talon.KS.R and (GetCurrentHP(target)*((100+(((GetArmor(target)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(target)*6 -DMG)>0 then
						if		 (CD(0,0,0,1,n)==1 and Mana(0,0,0,1,n)==1) or (CD(n,0,0,1,n)==1 and Mana(0,0,0,1,n)==1) or (CD(0,0,0,1,n)==1 and Mana(0,0,0,1,n)==1) or (CD(0,n,0,1,n)==1 and Mana(0,0,0,1,n)==1) or (CD(0,0,0,1,n)==1 and Mana(0,0,0,1,n)==1) or (CD(n,n,0,1,n)==1 and Mana(0,0,0,1,n)==1) then 
							--PrintChat("TO MUCH DMG 1")
						elseif (CD(1,0,0,1,n)==1 and Mana(1,0,0,1,n)==1) and GOS:GetDistance(target)<=250 and AttackReadiness()<1 then
							CastSpell(_Q)
						elseif ((CD(0,1,0,1,n)==1 and Mana(0,1,0,1,n)==1) or (CD(n,1,0,1,n)==1 and Mana(0,1,0,1,n)==1)) and GOS:GetDistance(target)<=700-(GetMoveSpeed(target)*.15) then 
							W(target)
						elseif (CD(1,1,0,1,n)==1 and Mana(1,1,0,1,n)==1) and GOS:GetDistance(target)<=700-(GetMoveSpeed(target)*.15) then 
							W(target)
						end
					else
						if ((CD(0,0,0,1,n)==1 and Mana(0,0,0,1,n)==1) or (CD(1,0,0,1,n)==1 and Mana(1,0,0,1,n)==1) or (CD(n,0,0,1,n)==1 and Mana(0,0,0,1,n)==1) or (CD(0,1,0,1,n)==1 and Mana(0,1,0,1,n)==1) or (CD(0,n,0,1,n)==1 and Mana(0,0,0,1,n)==1) or (CD(1,1,0,1,n)==1 and Mana(1,1,0,1,n)==1) or (CD(n,n,0,1,n)==1 and Mana(0,0,0,1,n)==1)) then
							R1(target)
						end
					end
				elseif GetCastName(myHero,_R)=="talonshadowassaulttoggle" then
					local DMG= math.max((CD(0,0,0,0,1)*Mana(0,0,0,0,0)*xR),(CD(1,0,0,0,1)*Mana(1,0,0,0,0)*(xAA+xQ+xQ2+xR)),(CD(n,0,0,0,1)*Mana(0,0,0,0,0)*xR),(CD(0,1,0,0,1)*Mana(0,1,0,0,0)*(xW+xR)),(CD(0,n,0,0,1)*Mana(0,0,0,0,0)*xR),(CD(1,1,0,0,1)*Mana(1,1,0,0,0)*(xAA+xQ+xQ2+xR)),(CD(n,n,0,0,1)*Mana(0,0,0,0,0)*xR))
					if Talon.KS.R and (GetCurrentHP(target)*((100+(((GetArmor(target)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(target)*6 -DMG)<=0 then
						if (GetCurrentHP(target)*((100+(((GetArmor(target)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(target)*6 -(DMG-xR))<=0 then --killable without the ult?
							if 		  (CD(1,0,0,0,1)==1 and Mana(1,0,0,0,0)==1) and GOS:GetDistance(target)<=250 and AttackReadiness()<1 then
								CastSpell(_Q)
							elseif ((CD(0,1,0,0,1)==1 and Mana(0,1,0,0,0)==1) or (CD(1,1,0,0,1)==1 and Mana(1,1,0,0,0)==1)) and GOS:GetDistance(target)<=700-(GetMoveSpeed(target)*.15) then
								W(target)
							end
						else
							if ((CD(0,0,0,0,1)==1 and Mana(0,0,0,0,0)==1) or (CD(1,0,0,0,1)==1 and Mana(1,0,0,0,0)==1) or (CD(n,0,0,0,1)==1 and Mana(0,0,0,0,0)==1) or (CD(0,1,0,0,1)==1 and Mana(0,1,0,0,0)==1) or (CD(0,n,0,0,1)==1 and Mana(0,0,0,0,0)==1) or (CD(1,1,0,0,1)==1 and Mana(1,1,0,0,0)==1) or (CD(n,n,0,0,1)==1 and Mana(0,0,0,0,0)==1)) then
								R2(target)
							end
						end
					elseif Talon.KS.R and (GetCurrentHP(target)*((100+(((GetArmor(target)*LastWhisper)-GetArmorPenFlat(myHero))*GetArmorPenPercent(myHero)))/100)+GetHPRegen(target)*6 -DMG)>0 then
						if 		 ((CD(0,0,0,0,1)==1 and Mana(0,0,0,0,0)==1)) or ((CD(n,0,0,0,1)==1 and Mana(0,0,0,0,0)==1)) or ((CD(0,n,0,0,1)==1 and Mana(0,0,0,0,0)==1)) or ((CD(n,n,0,0,1)==1 and Mana(0,0,0,0,0)==1)) then
							--PrintChat("TO MUCH DMG 2")
						elseif (CD(1,0,0,0,1)==1 and Mana(1,0,0,0,0)==1) and GOS:GetDistance(target)<=250 and AttackReadiness()<1 then
							CastSpell(_Q)
						elseif ((CD(0,1,0,0,1)==1 and Mana(0,1,0,0,0)==1) or (CD(1,1,0,0,1)==1 and Mana(1,1,0,0,0)==1)) and GOS:GetDistance(target)<=700-(GetMoveSpeed(target)*.15) then 
							W(target)
						end
					else
						if ((CD(0,0,0,0,1)==1 and Mana(0,0,0,0,0)==1) or	(CD(1,0,0,0,1)==1 and Mana(1,0,0,0,0)==1) or	(CD(n,0,0,0,1)==1 and Mana(0,0,0,0,0)==1) or	(CD(0,1,0,0,1)==1 and Mana(0,1,0,0,0)==1) or	(CD(0,n,0,0,1)==1 and Mana(0,0,0,0,0)==1) or (CD(1,1,0,0,1)==1 and Mana(1,1,0,0,0)==1) or (CD(n,n,0,0,1)==1 and Mana(0,0,0,0,0)==1)) then
							R2(target)
						end
					end
				end
				if GOS:GetDistance(target)<400-GetMoveSpeed(target)*.15 then 
					GOS:CastOffensiveItems(target)
					if GOS:GetDistance(target)<=250-GetMoveSpeed(target)*.07 then
						if AttackReadiness()<1 then
							CastSpell(_Q)
						else
							AttackUnit(target)
						end
					end
				end
			end	
		else
			MoveToMouse()
		end
	end
end
--Spells
function W(o)
	if GOS:GetDistance(o)<=700-GetMoveSpeed(o)*.15 then
		CastTargetSpell(o,_W)
	end
end
function E(o)
	if GOS:GetDistance(o)<=700 then
		CastTargetSpell(o,_E)
	end
end
function R1(o)
	if GOS:GetDistance(o)<=650-GetMoveSpeed(o)*.15 then
		CastSpell(_R)
	end
end
function R2(o)
	if GOS:GetDistance(o)<=650 then
		CastSpell(_R)
	end
	if GetCastName(myHero,_R)=="talonshadowassaulttoggle" and GOS:GetDistance(o)>640 then
	  CastSpell(_R)
	end
end
--MISC--
--My Own MoveToMouse function so Talon can optimaly do AAs--
function MoveToMouse()
	MoveToXYZ(GetMousePos())
end
--Check Spells for CD--
function CD(a,b,c,d,e)
	if (GetCastName(myHero,_Q)=="TalonNoxianDiplomacy" and GetCastLevel(myHero,_Q)>= 1 and CanUseSpell(myHero, _Q)==READY) or GotBuff(myHero,"talonnoxiandiplomacybuff")~=0 then QRDY = 1 else QRDY = 0 end
	if 	GetCastName(myHero,_W)=="TalonRake" and GetCastLevel(myHero,_W)>= 1 and CanUseSpell(myHero, _W)==READY then WRDY = 1 else WRDY = 0 end
	if  GetCastName(myHero,_E)=="TalonCutthroat" and GetCastLevel(myHero,_E)>= 1 and CanUseSpell(myHero, _E)==READY then ERDY = 1 else ERDY = 0 end
	if  GetCastName(myHero,_R)=="TalonShadowAssault" and GetCastName(myHero,_R)~="talonshadowassaulttoggle" and GetCastLevel(myHero,_R)>= 1 and CanUseSpell(myHero, _R)==READY then R1RDY = 1 else R1RDY = 0 end
	if (GetCastName(myHero,_R)=="talonshadowassaulttoggle" or R1RDY==1) and GetCastLevel(myHero,_R)>= 1 and CanUseSpell(myHero, _R)==READY then R2RDY = 1 else R2RDY = 0 end
	if (QRDY == a or a == n) and (WRDY == b or b == n) and (ERDY == c or c == n) and (R1RDY == d or d == n) and (R2RDY == e or e == n) then
		return 1
	else
		return 0
	end
end
--Check Spells for Mana--
function Mana(a,b,c,d,e)
	if a == 1 then a = 35+(GetCastLevel(myHero,_Q)*5) else a = 0  end
	if b == 1 then b = 55+(GetCastLevel(myHero,_W)*5) else b = 0  end
	if c == 1 then c = 30+(GetCastLevel(myHero,_E)*5) else c = 0 end
	if d ==1 then d = 70+(GetCastLevel(myHero,_R)*10) else d = 0 end
	if GetCurrentMana(myHero) > a+b+c+d then 
		return 1
	else
		return 0
	end
end
--Function to round the numbers in Killnotis--
function Round(val, decimal)
	if (decimal) then
		return math.floor( (val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
	else
		return math.floor(val + 0.5)
	end
end
function GetDistanceXYZ(x,z,x2,z2)
	if (x and z and x2 and z2)~=nil then
		a=x2-x
		b=z2-z
		if (a and b)~=nil then
			a2=a*a
			b2=b*b
			if (a2 and b2)~=nil then
				return math.sqrt(a2+b2)
			else
				return 99999
			end
		else
			return 99999
		end
	end	
end
function CheckEnemy(name)
	if #enemies > 0 then
		for i,enemy in ipairs(enemies) do
			if enemy.hero and enemy.hero~= nil and GetObjectName(enemy.hero):find(name) then return enemy end
		end
	end
	return nil
end
function Valid(unit)
  if unit and not IsDead(unit) and IsTargetable(unit) and not IsImmune(unit) and IsVisible(unit) then
    return true
  else
    return false
  end
end
