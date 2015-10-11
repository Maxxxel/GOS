require 'MapPositionGOS'
--require Valdorian xD

LeBlanc = Menu("LeBlanc", "LeBlanc")
LeBlanc:SubMenu("Keys","Keys")
LeBlanc.Keys:Key("DoQ", "Q", string.byte("Q"))
LeBlanc.Keys:Key("DoE", "E", string.byte("E"))
LeBlanc.Keys:Key("Harass", "Harass", string.byte("X"))
LeBlanc.Keys:Key("Combo", "Combo", string.byte(" "))
LeBlanc:SubMenu("KS","Kill Functions")
LeBlanc.KS:Boolean("Mult", "Calc 2 E proc", false)
LeBlanc.KS:Boolean("KSNotes", "KS Notes", true)
LeBlanc.KS:Boolean("Percent", "Percent Notes", true)
LeBlanc:SubMenu("Misc","Misc")
LeBlanc.Misc:Boolean("Draw", "Draw Circles", true)
LeBlanc.Misc:Boolean("MR", "Manual Return", true)
--Variables--
--version = 0.5 --added manual return option
local mapID = GetMapID()
local ls
local target
local myHero = GetMyHero()
local VoidStaff = 1
local multi = 1
local xQ,xW,xE,xR,xRW
local from,to,SUM,Wall,WallT = 0,0,0,0,0
local WPos,W2Pos,WPred,EPred,EPos,HPos
--Tables--
local KSN = {}
local HNS = {}
local n = {}
--Valid target
local function Valid(unit)
  if unit and not IsDead(unit) and IsTargetable(unit) and not IsImmune(unit, myHero) and IsVisible(unit) then
    return true
  else
    return false
  end
end
local function GetDistanceXYZ(x,z,x2,z2)
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
--Mana Handling--
local function Mana(a,b,c) --Q,W,R only have mana
	if a == 1 then 
		a = 40+(GetCastLevel(myHero,_Q)*10) 
	else 
		a = 0  
	end
	if b == 1 then 
		b = 75+(GetCastLevel(myHero,_W)*5)
	else 
		b = 0 
	end
	if c == 1 then 
		c = 80
	else 
		c = 0 
	end
	if GetCurrentMana(myHero) > a+b+c then 
		return 1
	else
		return 0
	end
end
--CD Handling--
local function CD(a,b,c,d,e,f,g,h,i)
--Q
	if GetCastName(myHero,_Q) == 'LeblancChaosOrb' and GetCastLevel(myHero,_Q)>= 1 and CanUseSpell(myHero, _Q)==READY then 
		Q1RDY = 1
	else
		Q1RDY = 0 
	end
--RQ
	if GetCastName(myHero,_R) == 'LeblancChaosOrbM' and GetCastLevel(myHero,_R)>= 1 and CanUseSpell(myHero, _R)==READY then 
		Q2RDY = 1
	else 
		Q2RDY = 0 
	end
--W
	if GetCastName(myHero,_W) == 'LeblancSlide' and GetCastLevel(myHero,_W)>= 1 and CanUseSpell(myHero, _W)==READY then 
		W1RDY = 1
	else 
		W1RDY = 0 
	end
--W2
	if GetCastName(myHero,_W) == 'leblancslidereturn' and GetCastLevel(myHero,_W)>= 1 and CanUseSpell(myHero, _W)==READY then 
		W2RDY = 1
	else 
		W2RDY = 0 
	end
--RW
	if GetCastName(myHero,_R) == 'LeblancSlideM' and GetCastLevel(myHero,_R)>= 1 and CanUseSpell(myHero, _R)==READY then 
		W3RDY = 1
	else 
		W3RDY = 0 
	end
--RW2
	if GetCastLevel(myHero,_R)>= 1 and GetCastName(myHero,_R) ~= 'leblancslidereturnm' and CanUseSpell(myHero, _R)==READY then 
		W4RDY = 1
	else 
		W4RDY = 0 
	end
--E
	if GetCastName(myHero,_E) == 'LeblancSoulShackle' and GetCastLevel(myHero,_E)>= 1 and CanUseSpell(myHero, _E)==READY then 
		E1RDY = 1
	else
	  E1RDY = 0 
	end
--RE
	if GetCastName(myHero,_R) == 'LeblancSoulShackleM' and GetCastLevel(myHero,_R)>= 1 and CanUseSpell(myHero, _R)==READY then 
		E2RDY = 1
	else 
		E2RDY = 0 
	end
	if GetCastLevel(myHero,_R)>= 1 and CanUseSpell(myHero, _R)==READY then 
		RRDY = 1
	else 
		RRDY = 0
	end
	if (Q1RDY == a or a == n) and (Q2RDY == b or b == n) and (W1RDY == c or c == n) and (W2RDY == d or d == n) and (W3RDY == e or e == n) and (W4RDY == f or f == n) and (E1RDY == g or g == n) and (E2RDY == h or h == n) and (RRDY == i or i == n) then
		return 1
	else
		return 0
	end
end
--Spell functions--
local function Q(o)
	CastTargetSpell(o,_Q)
end
local function QR(o)
	CastTargetSpell(o,_R)
end
local function W(o)
	WPred = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),1450,250,600,250,false,true)
	if WPred.HitChance==1 then
		CastSkillShot(_W,WPred.PredPos.x,WPred.PredPos.y,WPred.PredPos.z)
	end
end
local function W2(o)
	CastSpell(_W)
end
local function WR(o)
	WPred = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),1450,250,600,250,false,true)
	if WPred.HitChance==1 then
		CastSkillShot(_R,WPred.PredPos.x,WPred.PredPos.y,WPred.PredPos.z)
	end
end
local function WR2(o)
	CastSpell(_R)
end
local function E(o)
	EPred = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),1550,150,950,55,true,true)
	if EPred.HitChance==1 then
		CastSkillShot(_E,EPred.PredPos.x,EPred.PredPos.y,EPred.PredPos.z)
	end
end
local function ER(o)
	EPred = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),1550,150,950,55,true,true)
	if EPred.Hithance==1 then
		CastSkillShot(_R,EPred.PredPos.x,EPred.PredPos.y,EPred.PredPos.z)
	end
end
local function WL(o)
	local Pos=GetOrigin(o)
	if GetCastName(myHero,_W)~= 'leblancslidereturn' then 
		CastSkillShot(_W,Pos.x,Pos.y,Pos.z) 
	end
end

--harass--
local function Harass()
	WPred = GetPredictionForPlayer(GetOrigin(myHero),target,GetMoveSpeed(target),1450,250,600,250,false,true)
	if mapID==SUMMONERS_RIFT then
		EPos = Vector(targetPos.x,0,targetPos.z)
		HPos = Vector(myHeroPos.x,0,myHeroPos.z)
		WPos = HPos+(HPos-EPos)*(-650/GOS:GetDistance(HPos,EPos))
		if MapPosition:inWall(Point(WPos.x,WPos.y,WPos.z))==true then 
			Wall = 1
		else 
			Wall = 0 
		end
	else
		--No Other Maps Supported atm
		Wall=0
	end
	if LeBlanc.Keys.Harass:Value() and GOS:GetDistance(target)<=700 then
		if 		 CD(1,n,1,n,n,n,n,n,n)==1 and Mana(1,1,n)==1 then Q(target)
		elseif CD(n,n,1,n,n,n,n,n,n)==1 and Mana(n,1,n)==1 and Wall==0 then W(target)
		elseif CD(n,n,n,1,n,n,n,n,n)==1 then W2()
		end
	end
end
--Damage Calc--
local function DamageCalc()
	xQ = GetCastLevel(myHero,_Q)*25+30+.4*GetBonusAP(myHero)
	xW = GetCastLevel(myHero,_W)*40+45+.6*GetBonusAP(myHero)
	xE = GetCastLevel(myHero,_E)*25+15+.5*GetBonusAP(myHero)
	xR = GetCastLevel(myHero,_R)*100+.65*GetBonusAP(myHero)
	xRW = GetCastLevel(myHero,_R)*150+.975*GetBonusAP(myHero)
end
--ITEM CD--
local function CheckItemCD()
	if GetItemSlot(myHero,3135)>0 then
		VoidStaff=0.65
	else
		VoidStaff=1
	end
end
--Draw
local function Draw()
	if not IsDead(myHero) then
		local myHeroWorld = WorldToScreen(1,myHeroPos.x,myHeroPos.y,myHeroPos.z)
		if (CD(1,n,n,n,n,n,n,n,n)==1 and Mana(1,n,n)==1) or CD(0,1,n,n,n,n,n,1)==1 then 
			DrawCircle(GetOrigin(myHero),700,0,0,0xffff0000)
		end
		if (CD(0,n,1,n,n,0,n,n,n)==1 and Mana(0,1,n)==1) or CD(0,n,0,1,n,0,n,1)==1 then 
			DrawCircle(GetOrigin(myHero),600,0,0,0xffff0000)
		end
		if (CD(1,n,1,n,n,n,n,n,n)==1 and Mana(1,1,n)==1) or CD(1,n,0,1,n,n,n,1)==1 then 
			DrawCircle(GetOrigin(myHero),1300,0,0,0xffffff00)
		end
		local number=0
		if CanUseSpell(myHero,_Q)==READY and GetCastName(myHero,_R) ~= 'LeblancChaosOrbM' then
			HNS[1]  = {a=1,b=0,c=0,d=n,e=0,f=n,g=0,h=0,i=n, text ="Q"}
			HNS[2]  = {a=1,b=0,c=1,d=n,e=0,f=n,g=0,h=0,i=n, text ="Q-W"}
			HNS[3]  = {a=1,b=0,c=0,d=n,e=1,f=n,g=0,h=0,i=1, text ="Q-W(R)"}
			HNS[4]  = {a=1,b=0,c=0,d=n,e=0,f=n,g=1,h=0,i=n, text ="Q-E"}
			HNS[5]  = {a=1,b=0,c=0,d=n,e=0,f=n,g=0,h=1,i=1, text ="Q-E(R)"}
			HNS[6] = {a=1,b=0,c=1,d=n,e=0,f=n,g=1,h=0,i=n, text ="Q-W-E"}
			HNS[7] = {a=1,b=0,c=0,d=n,e=1,f=n,g=1,h=0,i=1, text ="Q-W(R)-E"}
			HNS[8] = {a=1,b=0,c=1,d=n,e=0,f=n,g=0,h=1,i=1, text ="Q-W-E(R)"}
			HNS[9] = {a=1,b=0,c=1,d=n,e=1,f=n,g=0,h=0,i=1, text ="Q-W-W(R)"}
			HNS[10] = {a=1,b=0,c=0,d=n,e=0,f=n,g=1,h=1,i=1, text ="Q-E-E(R)"}
			HNS[11] = {a=1,b=0,c=1,d=n,e=1,f=n,g=1,h=0,i=1, text ="Q-W-W(R)-E"}
			HNS[12] = {a=1,b=0,c=1,d=n,e=0,f=n,g=1,h=1,i=1, text ="Q-W-E-E(R)"}
			number=12
		elseif (CanUseSpell(myHero,_R)==READY and GetCastName(myHero,_R) == 'LeblancChaosOrbM') then
			HNS[1]  = {a=0,b=1,c=0,d=n,e=0,f=n,g=0,h=0,i=1, text ="Q(R)"}
			HNS[2]  = {a=1,b=1,c=0,d=n,e=0,f=n,g=0,h=0,i=1, text ="Q-Q(R)"}
			HNS[3]  = {a=0,b=1,c=1,d=n,e=0,f=n,g=0,h=0,i=1, text ="Q(R)-W"}
			HNS[4]  = {a=0,b=1,c=0,d=n,e=0,f=n,g=1,h=0,i=1, text ="Q(R)-E"}
			HNS[5] = {a=0,b=1,c=1,d=n,e=0,f=n,g=1,h=0,i=1, text ="Q(R)-W-E"}
			HNS[6] = {a=1,b=1,c=1,d=n,e=0,f=n,g=0,h=0,i=1, text ="Q-Q(R)-W"}
			HNS[7] = {a=1,b=1,c=0,d=n,e=0,f=n,g=1,h=0,i=1, text ="Q-Q(R)-E"}
			HNS[8] = {a=1,b=1,c=1,d=n,e=0,f=n,g=1,h=0,i=1, text ="Q-Q(R)-W-E"}
			number=8
		elseif CanUseSpell(myHero,_W)==READY or (CanUseSpell(myHero,_R)==READY and GetCastName(myHero,_R) == 'LeblancSlideM') then
			HNS[1] = {a=0,b=0,c=1,d=n,e=0,f=n,g=0,h=0,i=n, text ="W"}
			HNS[2] = {a=0,b=0,c=0,d=n,e=1,f=n,g=0,h=0,i=1, text ="W(R)"}
			HNS[3] = {a=0,b=0,c=1,d=n,e=1,f=n,g=0,h=0,i=1, text ="W-W(R)"}
			HNS[4] = {a=0,b=0,c=1,d=n,e=0,f=n,g=1,h=0,i=n, text ="W-E"}
			HNS[5] = {a=0,b=0,c=0,d=n,e=1,f=n,g=1,h=0,i=1, text ="W(R)-E"}
			HNS[6] = {a=0,b=0,c=1,d=n,e=0,f=n,g=0,h=1,i=1, text ="W-E(R)"}
			HNS[7] = {a=0,b=0,c=1,d=n,e=1,f=n,g=1,h=0,i=1, text ="W-W(R)-E"}
			HNS[8] = {a=0,b=0,c=1,d=n,e=0,f=n,g=1,h=1,i=1, text ="W-E-E(R)"}
			number=8
		else
			HNS[1] = {a=0,b=0,c=0,d=n,e=0,f=n,g=1,h=0,i=n, text ="E"}
			HNS[2] = {a=0,b=0,c=0,d=n,e=0,f=n,g=0,h=1,i=1, text ="E(R)"}
			HNS[3] = {a=0,b=0,c=0,d=n,e=0,f=n,g=1,h=1,i=1, text ="E-E(R)"}
			number=3
		end
		for v=1,number do
			if CD(HNS[v].a,HNS[v].b,HNS[v].c,HNS[v].d,HNS[v].e,HNS[v].f,HNS[v].g,HNS[v].h,HNS[v].i)==1 and Mana(HNS[v].a,HNS[v].c,HNS[v].g)==1 then
				DrawText(HNS[v].text,15,myHeroWorld.x,myHeroWorld.y,0xffffff00)
				break
			end
		end
	end
end      
--Round--
local function Round(val, decimal)
	if (decimal) then
		return math.floor( (val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
	else
		return math.floor(val + 0.5)
	end
end
--Spell Sequence--
local function SpellSequence()
	if #n > 0 then
		for  i = 1, #n do
	    local maxHealth = GetMaxHP(n[i])*((100+(((GetMagicResist(n[i])*VoidStaff)-GetMagicPenFlat(myHero))*GetMagicPenPercent(myHero)))/100)+GetHPRegen(n[i])*6 
	    local health = GetCurrentHP(n[i])*((100+(((GetMagicResist(n[i])*VoidStaff)-GetMagicPenFlat(myHero))*GetMagicPenPercent(myHero)))/100)+GetHPRegen(n[i])*6
	    local drawPos = GetOrigin(n[i])
	    local testPos = WorldToScreen(1, drawPos)
    	if Valid(n[i]) then
    		if GOS:GetDistance(n[i])<=2000 then
					EPred = GetPredictionForPlayer(GetOrigin(myHero),n[i],GetMoveSpeed(n[i]),1550,150,950,55,true,true)
					WPred = GetPredictionForPlayer(GetOrigin(myHero),n[i],GetMoveSpeed(n[i]),1450,250,600,250,false,true)
					if mapID==SUMMONERS_RIFT then
						EPos = Vector(drawPos.x,0,drawPos.z)
						HPos = Vector(myHeroPos.x,0,myHeroPos.z)
						WPos = HPos+(HPos-EPos) * (-650 / GOS:GetDistance(HPos,EPos))
						if MapPosition:inWall(Point(WPos.x,WPos.y,WPos.z))==true then 
							Wall = 1
						else 
							Wall = 0 
						end
					else
						--No Other Maps Supported atm
						Wall=0
					end
					if EPred.HitChance==1 then
						Block=0
					else
						Block=1
					end
					--ULTI CD
				  KSN[1] = {a=1,b=0,c=0,d=n,e=0,f=n,g=0,h=0,i=n, Dist=0, Block=0, Wall=0, Damage= xQ,text ="Q"}
				  KSN[2] = {a=1,b=n,c=1,d=n,e=n,f=n,g=n,h=n,i=n, Dist=0, Block=0, Wall=1, Damage= xQ*2+xW,text ="Q-W"}
				  KSN[3] = {a=1,b=n,c=n,d=n,e=n,f=n,g=1,h=n,i=n, Dist=0, Block=1, Wall=0, Damage= xQ*2+xE*multi,text ="Q-E"}
				  KSN[4] = {a=1,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=n, Dist=0, Block=1, Wall=1, Damage= xQ*2+xW+xE*multi,text ="Q-W-E"}
				  KSN[5] = {a=1,b=0,c=1,d=n,e=n,f=0,g=n,h=0,i=n, Dist=1, Block=0, Wall=1, Damage= xQ,text ="W-Q Long "}
				  KSN[6] = {a=1,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=n, Dist=1, Block=1, Wall=1, Damage= xQ*2+xE*multi,text ="W-E-Q Long "}
				  KSN[7] = {a=0,b=0,c=1,d=n,e=0,f=n,g=0,h=0,i=n, Dist=0, Block=0, Wall=1, Damage= xW,text ="W"}
				  KSN[8] = {a=0,b=0,c=0,d=n,e=0,f=n,g=1,h=0,i=n, Dist=0, Block=1, Wall=0, Damage= xE*multi,text ="E"}
				  KSN[9] = {a=n,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=n, Dist=0, Block=1, Wall=1, Damage= xW+xE*multi,text ="W-E"}
				  KSN[10] = {a=0,b=0,c=1,d=n,e=n,f=0,g=1,h=0,i=n, Dist=1, Block=1, Wall=1, Damage= xE*multi,text ="W-E Long "}
	--ULTI READY, ULTI Q, NO E  
				  KSN[11] = {a=0,b=1,c=0,d=n,e=0,f=n,g=0,h=0,i=1, Dist=0, Block=0, Wall=0, Damage= xR,text ="Q(R)"}
				  KSN[12] = {a=1,b=n,c=0,d=n,e=n,f=n,g=0,h=n,i=1, Dist=0, Block=0, Wall=0, Damage= xQ*2+xR,text ="Q-Q(R)"}
					KSN[13] = {a=1,b=1,c=0,d=n,e=0,f=n,g=0,h=0,i=1, Dist=0, Block=0, Wall=0, Damage= xQ+xR*2,text ="Q(R)-Q"}
					KSN[14] = {a=n,b=1,c=1,d=n,e=0,f=n,g=n,h=0,i=1, Dist=0, Block=0, Wall=1, Damage= xR*2+xW,text ="Q(R)-W"}
					KSN[15] = {a=0,b=1,c=1,d=n,e=0,f=0,g=n,h=0,i=1, Dist=1, Block=0, Wall=1, Damage= xR,text ="W-Q(R) Long "}
				  KSN[16] = {a=1,b=n,c=1,d=n,e=n,f=n,g=n,h=n,i=1, Dist=1, Block=0, Wall=1, Damage= xQ*2+xR,text ="W-Q-Q(R) Long "}
					KSN[17] = {a=1,b=1,c=1,d=n,e=0,f=n,g=n,h=0,i=1, Dist=1, Block=0, Wall=1, Damage= xR*2+xQ,text ="W-Q(R)-Q Long "}
					KSN[18] = {a=1,b=n,c=1,d=n,e=n,f=n,g=n,h=n,i=1, Dist=0, Block=0, Wall=1, Damage= xQ*2+xR*2+xW,text ="Q-Q(R)-W"}
					KSN[19] = {a=1,b=1,c=1,d=n,e=0,f=n,g=n,h=0,i=1, Dist=0, Block=0, Wall=1, Damage= xQ*2+xR*2+xW,text ="Q(R)-Q-W"}
	--ULTI READY, ULTI Q, AND E  
					KSN[20] = {a=1,b=n,c=n,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=0, Damage= xQ*2+xR*2+xE*multi,text ="Q-Q(R)-E"}
					KSN[21] = {a=n,b=1,c=n,d=n,e=0,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=0, Damage= xR*2+xE*multi,text ="Q(R)-E"}
					KSN[22] = {a=n,b=1,c=1,d=n,e=0,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=1, Damage= xR*2+xW+xE*multi,text ="Q(R)-W-E"}
					KSN[23] = {a=1,b=1,c=n,d=n,e=0,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=0, Damage= xQ*2+xR*2+xE*multi,text ="Q(R)-Q-E"}
					KSN[24] = {a=1,b=1,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xR*2+xW+xE*multi,text ="Q-Q(R)-W-E"}
					KSN[25] = {a=1,b=1,c=1,d=n,e=0,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xR*2+xW+xE*multi,text ="Q(R)-Q-W-E"}
					KSN[26] = {a=0,b=1,c=1,d=n,e=0,f=n,g=1,h=0,i=1, Dist=1, Block=1, Wall=1, Damage= xR*2+xE*multi,text ="W-E-Q(R) Long "}
					KSN[27] = {a=1,b=1,c=1,d=n,e=0,f=n,g=1,h=0,i=1, Dist=1, Block=1, Wall=1, Damage= xE*multi+xR*2+xQ*2,text ="W-Q(R)-Q-E Long "}
					KSN[28] = {a=1,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=1, Block=1, Wall=1, Damage= xE*multi+xR*2+xQ*2,text ="W-Q-Q(R)-E Long "}
	--ULTI READY, ULTI W, NO E 
				  KSN[29] = {a=1,b=0,c=n,d=n,e=1,f=n,g=n,h=0,i=1, Dist=0, Block=0, Wall=1, Damage= xQ*2+xRW,text ="Q-W(R)"}
				  KSN[30] = {a=1,b=n,c=1,d=n,e=n,f=n,g=n,h=n,i=1, Dist=0, Block=0, Wall=1, Damage= xQ*2+xW+xRW,text ="Q-W-W(R)"}
					KSN[31] = {a=1,b=0,c=1,d=n,e=1,f=n,g=n,h=0,i=1, Dist=0, Block=0, Wall=1, Damage= xQ*2+xW+xRW,text ="Q-W(R)-W"}
					KSN[32] = {a=1,b=0,c=1,d=n,e=n,f=n,g=0,h=0,i=1, Dist=1, Block=0, Wall=1, Damage= xQ*2+xRW,text ="Q-W-W(R) Long"}
					KSN[33] = {a=0,b=0,c=0,d=n,e=1,f=n,g=0,h=0,i=1, Dist=0, Block=0, Wall=1, Damage= xRW,text ="W(R)"}
					KSN[34] = {a=0,b=n,c=1,d=n,e=n,f=n,g=0,h=n,i=1, Dist=0, Block=0, Wall=1, Damage= xW+xRW,text ="W-W(R)"}
					KSN[35] = {a=0,b=0,c=1,d=n,e=1,f=n,g=0,h=0,i=1, Dist=0, Block=0, Wall=1, Damage= xW+xRW,text ="W(R)-W"}
					--KSN[36] = {a=1,b=0,c=1,d=n,e=n,f=n,g=0,h=0,i=1, Dist=2, Block=0, Wall=2, Damage= xQ,text ="Q-W-W(R) Very Long"}
					KSN[37] = {a=0,b=0,c=1,d=n,e=n,f=n,g=0,h=0,i=1, Dist=1, Block=0, Wall=1, Damage= xRW,text ="W-W(R) Long "}
	--ULTI READY, ULTI W, AND E				
				  KSN[38] = {a=1,b=0,c=n,d=n,e=1,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xRW+xE*multi,text ="Q-W(R)-E"}				  
					KSN[39] = {a=1,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xW+xRW+xE*multi,text ="Q-W-W(R)-E"}
					KSN[40] = {a=1,b=0,c=1,d=n,e=1,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xW+xRW+xE*multi,text ="Q-W(R)-W-E"}					
					KSN[41] = {a=1,b=0,c=1,d=n,e=n,f=n,g=1,h=0,i=1, Dist=1, Block=1, Wall=1, Damage= xQ*2+xRW+xE*multi,text ="Q-W-W(R)-E Long"}					
					--KSN[42] = {a=1,b=0,c=1,d=n,e=n,f=n,g=1,h=0,i=1, Dist=2, Block=2, Wall=2, Damage= xQ*2+xE*multi,text ="Q-W-W(R)-E Very Long"}					
					KSN[43] = {a=n,b=0,c=n,d=n,e=1,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=1, Damage= xRW+xE*multi,text ="W(R)-E"}
					KSN[44] = {a=n,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=1, Damage= xW+xRW+xE*multi,text ="W-W(R)-E"}
					KSN[45] = {a=n,b=0,c=1,d=n,e=1,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=1, Damage= xW+xRW+xE*multi,text ="W(R)-W-E"}					
					KSN[46] = {a=0,b=0,c=1,d=n,e=n,f=n,g=1,h=0,i=1, Dist=1, Block=1, Wall=1, Damage= xRW+xE*multi,text ="W-W(R)-E Long"}
					--KSN[47] = {a=0,b=0,c=1,d=n,e=n,f=n,g=1,h=0,i=1, Dist=2, Block=2, Wall=2, Damage= xE*multi,text ="W-W(R)-E Very Long"}					
	--ULTI READY, UTLI E, AND W, AND Q
					KSN[48] = {a=1,b=0,c=1,d=n,e=0,f=n,g=n,h=1,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xW+xR*multi,text ="Q-W-E(R)"}
					KSN[49] = {a=1,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xW+xE*multi+xR*multi,text ="Q-W-E-E(R)"}
					KSN[50] = {a=1,b=0,c=1,d=n,e=0,f=n,g=1,h=1,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xW+xE*multi+xR*multi,text ="Q-W-E-E(R)"}					
					KSN[51] = {a=1,b=0,c=1,d=n,e=0,f=n,g=0,h=n,i=1, Dist=1, Block=1, Wall=1, Damage= xQ*2+xR*multi,text ="W-Q-E(R) Long "}					
					KSN[52] = {a=1,b=0,c=1,d=n,e=0,f=n,g=1,h=1,i=1, Dist=1, Block=1, Wall=1, Damage= xE*multi+xR*multi+xQ*2,text ="W-Q-E(R)-E Long "}
					KSN[53] = {a=1,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=1, Block=1, Wall=1, Damage= xE*multi+xR*multi+xQ*2,text ="W-Q-E-E(R) Long "}
	--ULTI READY, ULTI E, AND W, NO Q
					KSN[54] = {a=n,b=0,c=1,d=n,e=0,f=n,g=n,h=1,i=1, Dist=0, Block=1, Wall=1, Damage= xW+xE*multi,text ="W-E(R)"}					
					KSN[55] = {a=n,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=1, Damage= xW+xE*multi+xR*multi,text ="W-E-E(R)"}
					KSN[56] = {a=n,b=0,c=1,d=n,e=0,f=n,g=1,h=1,i=1, Dist=0, Block=1, Wall=1, Damage= xW+xE*multi+xR*multi,text ="W-E(R)-E"}					
					KSN[57] = {a=0,b=0,c=1,d=n,e=0,f=0,g=0,h=1,i=1, Dist=1, Block=1, Wall=1, Damage= xR*multi,text ="W-E(R) Long "}
					KSN[58] = {a=0,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=1, Block=1, Wall=1, Damage= xE*multi+xR*multi,text ="W-E-E(R) Long "}
					KSN[59] = {a=0,b=0,c=1,d=n,e=0,f=n,g=1,h=1,i=1, Dist=1, Block=1, Wall=1, Damage= xE*multi+xR*multi,text ="W-E(R)-E Long "}
	--ULTI READY, UTLI E, NO W	
				  KSN[60] = {a=1,b=0,c=n,d=n,e=0,f=n,g=n,h=1,i=1, Dist=0, Block=1, Wall=0, Damage= xQ*2+xR*multi,text ="Q-E(R)"}								
					KSN[61] = {a=1,b=n,c=n,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=0, Damage= xQ*2+xE*multi+xR*multi,text ="Q-E-E(R)"}
					KSN[62] = {a=1,b=0,c=n,d=n,e=0,f=n,g=1,h=1,i=1, Dist=0, Block=1, Wall=0, Damage= xQ*2+xE*multi+xR*multi,text ="Q-E(R)-E"}										
					KSN[63] = {a=0,b=0,c=0,d=n,e=0,f=n,g=0,h=1,i=1, Dist=0, Block=1, Wall=0, Damage= xE*multi,text ="E(R)"}
					KSN[64] = {a=0,b=n,c=0,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=0, Damage= xE*multi+xR*multi,text ="E-E(R)"}
					KSN[65] = {a=0,b=0,c=0,d=n,e=0,f=n,g=1,h=1,i=1, Dist=0, Block=1, Wall=0, Damage= xE*multi+xR*multi,text ="E(R)-E"}				
								
					if CanUseSpell(myHero,_R)~=READY then
						from=1
						to=10
					elseif CanUseSpell(myHero,_R)==READY and GetCastName(myHero,_R) == 'LeblancChaosOrbM' and CanUseSpell(myHero,_E)~=READY then
						from=11
						to=19
					elseif CanUseSpell(myHero,_R)==READY and GetCastName(myHero,_R) == 'LeblancChaosOrbM' and CanUseSpell(myHero,_E)==READY then
						from=20
						to=28
					elseif CanUseSpell(myHero,_R)==READY and GetCastName(myHero,_R) == 'LeblancSlideM' and CanUseSpell(myHero,_E)~=READY then
						from=29
						to=37
					elseif CanUseSpell(myHero,_R)==READY and GetCastName(myHero,_R) == 'LeblancSlideM' and CanUseSpell(myHero,_E)==READY then
						from=38
						to=47
					elseif CanUseSpell(myHero,_R)==READY and GetCastName(myHero,_R) == 'LeblancChaosOrbM' and CanUseSpell(myHero,_W)==READY and CanUseSpell(myHero,_Q)==READY then
						from=48
						to=53
					elseif CanUseSpell(myHero,_R)==READY and GetCastName(myHero,_R) == 'LeblancChaosOrbM' and CanUseSpell(myHero,_W)==READY and CanUseSpell(myHero,_Q)~=READY then
						from=54
						to=59
					elseif CanUseSpell(myHero,_R)==READY and GetCastName(myHero,_R) == 'LeblancSoulShackleM' then
						from=60
						to=65
					else
						from = 1
						to = 1
					end
					for v=from,to do
						if CD(KSN[v].a,KSN[v].b,KSN[v].c,KSN[v].d,KSN[v].e,KSN[v].f,KSN[v].g,KSN[v].h,KSN[v].i)==1 and Mana(KSN[v].a,KSN[v].c,KSN[v].g)==1 and health < KSN[v].Damage then
							if KSN[v].Dist==1 and GOS:GetDistance(n[i])>700 and GOS:GetDistance(n[i])<=1300 - GetMoveSpeed(n[i]) * .3 and LeBlanc.KS.KSNotes:Value() then
								if (KSN[v].Block==1 and Block==1) or (KSN[v].Wall==1 and Wall==1) then 
									DrawCircle(drawPos.x,drawPos.y,drawPos.z,100,0,0,0xffffff00)
								else 
									DrawCircle(drawPos.x,drawPos.y,drawPos.z,100,0,0,0xffff0000)
								end
							elseif KSN[v].Dist==0 and GOS:GetDistance(n[i])<700 and LeBlanc.KS.KSNotes:Value() then
								if (KSN[v].Block==1 and Block==1) or (KSN[v].Wall==1 and Wall==1) then 
									DrawCircle(drawPos.x,drawPos.y,drawPos.z,100,0,0,0xffffff00)
								else 
									DrawCircle(drawPos.x,drawPos.y,drawPos.z,100,0,0,0xffff0000)
								end
							end
						else
							if to==10 then
								SUM= math.max(
								KSN[1].Damage*CD(KSN[1].a,KSN[1].b,KSN[1].c,KSN[1].d,KSN[1].e,KSN[1].f,KSN[1].g,KSN[1].h,KSN[1].i)*Mana(KSN[1].a,KSN[1].c,KSN[1].g),
								KSN[2].Damage*CD(KSN[2].a,KSN[2].b,KSN[2].c,KSN[2].d,KSN[2].e,KSN[2].f,KSN[2].g,KSN[2].h,KSN[2].i)*Mana(KSN[2].a,KSN[2].c,KSN[2].g),
								KSN[3].Damage*CD(KSN[3].a,KSN[3].b,KSN[3].c,KSN[3].d,KSN[3].e,KSN[3].f,KSN[3].g,KSN[3].h,KSN[3].i)*Mana(KSN[3].a,KSN[3].c,KSN[3].g),
								KSN[4].Damage*CD(KSN[4].a,KSN[4].b,KSN[4].c,KSN[4].d,KSN[4].e,KSN[4].f,KSN[4].g,KSN[4].h,KSN[4].i)*Mana(KSN[4].a,KSN[4].c,KSN[4].g),
								KSN[5].Damage*CD(KSN[5].a,KSN[5].b,KSN[5].c,KSN[5].d,KSN[5].e,KSN[5].f,KSN[5].g,KSN[5].h,KSN[5].i)*Mana(KSN[5].a,KSN[5].c,KSN[5].g),
								KSN[6].Damage*CD(KSN[6].a,KSN[6].b,KSN[6].c,KSN[6].d,KSN[6].e,KSN[6].f,KSN[6].g,KSN[6].h,KSN[6].i)*Mana(KSN[6].a,KSN[6].c,KSN[6].g),
								KSN[7].Damage*CD(KSN[7].a,KSN[7].b,KSN[7].c,KSN[7].d,KSN[7].e,KSN[7].f,KSN[7].g,KSN[7].h,KSN[7].i)*Mana(KSN[7].a,KSN[7].c,KSN[7].g),
								KSN[8].Damage*CD(KSN[8].a,KSN[8].b,KSN[8].c,KSN[8].d,KSN[8].e,KSN[8].f,KSN[8].g,KSN[8].h,KSN[8].i)*Mana(KSN[8].a,KSN[8].c,KSN[8].g),
								KSN[9].Damage*CD(KSN[9].a,KSN[9].b,KSN[9].c,KSN[9].d,KSN[9].e,KSN[9].f,KSN[9].g,KSN[9].h,KSN[9].i)*Mana(KSN[9].a,KSN[9].c,KSN[9].g),
								KSN[10].Damage*CD(KSN[10].a,KSN[10].b,KSN[10].c,KSN[10].d,KSN[10].e,KSN[10].f,KSN[10].g,KSN[10].h,KSN[10].i)*Mana(KSN[10].a,KSN[10].c,KSN[10].g))
							elseif to==19 then
								SUM= math.max(
								KSN[11].Damage*CD(KSN[11].a,KSN[11].b,KSN[11].c,KSN[11].d,KSN[11].e,KSN[11].f,KSN[11].g,KSN[11].h,KSN[11].i)*Mana(KSN[11].a,KSN[11].c,KSN[11].g),
								KSN[12].Damage*CD(KSN[12].a,KSN[12].b,KSN[12].c,KSN[12].d,KSN[12].e,KSN[12].f,KSN[12].g,KSN[12].h,KSN[12].i)*Mana(KSN[12].a,KSN[12].c,KSN[12].g),
								KSN[13].Damage*CD(KSN[13].a,KSN[13].b,KSN[13].c,KSN[13].d,KSN[13].e,KSN[13].f,KSN[13].g,KSN[13].h,KSN[13].i)*Mana(KSN[13].a,KSN[13].c,KSN[13].g),
								KSN[14].Damage*CD(KSN[14].a,KSN[14].b,KSN[14].c,KSN[14].d,KSN[14].e,KSN[14].f,KSN[14].g,KSN[14].h,KSN[14].i)*Mana(KSN[14].a,KSN[14].c,KSN[14].g),
								KSN[15].Damage*CD(KSN[15].a,KSN[15].b,KSN[15].c,KSN[15].d,KSN[15].e,KSN[15].f,KSN[15].g,KSN[15].h,KSN[15].i)*Mana(KSN[15].a,KSN[15].c,KSN[15].g),
								KSN[16].Damage*CD(KSN[16].a,KSN[16].b,KSN[16].c,KSN[16].d,KSN[16].e,KSN[16].f,KSN[16].g,KSN[16].h,KSN[16].i)*Mana(KSN[16].a,KSN[16].c,KSN[16].g),
								KSN[17].Damage*CD(KSN[17].a,KSN[17].b,KSN[17].c,KSN[17].d,KSN[17].e,KSN[17].f,KSN[17].g,KSN[17].h,KSN[17].i)*Mana(KSN[17].a,KSN[17].c,KSN[17].g),
								KSN[18].Damage*CD(KSN[18].a,KSN[18].b,KSN[18].c,KSN[18].d,KSN[18].e,KSN[18].f,KSN[18].g,KSN[18].h,KSN[18].i)*Mana(KSN[18].a,KSN[18].c,KSN[18].g),
								KSN[19].Damage*CD(KSN[19].a,KSN[19].b,KSN[19].c,KSN[19].d,KSN[19].e,KSN[19].f,KSN[19].g,KSN[19].h,KSN[19].i)*Mana(KSN[19].a,KSN[19].c,KSN[19].g))
							elseif to==28 then
								SUM= math.max(
								KSN[20].Damage*CD(KSN[20].a,KSN[20].b,KSN[20].c,KSN[20].d,KSN[20].e,KSN[20].f,KSN[20].g,KSN[20].h,KSN[20].i)*Mana(KSN[20].a,KSN[20].c,KSN[20].g),
								KSN[21].Damage*CD(KSN[21].a,KSN[21].b,KSN[21].c,KSN[21].d,KSN[21].e,KSN[21].f,KSN[21].g,KSN[21].h,KSN[21].i)*Mana(KSN[21].a,KSN[21].c,KSN[21].g),
								KSN[22].Damage*CD(KSN[22].a,KSN[22].b,KSN[22].c,KSN[22].d,KSN[22].e,KSN[22].f,KSN[22].g,KSN[22].h,KSN[22].i)*Mana(KSN[22].a,KSN[22].c,KSN[22].g),
								KSN[23].Damage*CD(KSN[23].a,KSN[23].b,KSN[23].c,KSN[23].d,KSN[23].e,KSN[23].f,KSN[23].g,KSN[23].h,KSN[23].i)*Mana(KSN[23].a,KSN[23].c,KSN[23].g),
								KSN[24].Damage*CD(KSN[24].a,KSN[24].b,KSN[24].c,KSN[24].d,KSN[24].e,KSN[24].f,KSN[24].g,KSN[24].h,KSN[24].i)*Mana(KSN[24].a,KSN[24].c,KSN[24].g),
								KSN[25].Damage*CD(KSN[25].a,KSN[25].b,KSN[25].c,KSN[25].d,KSN[25].e,KSN[25].f,KSN[25].g,KSN[25].h,KSN[25].i)*Mana(KSN[25].a,KSN[25].c,KSN[25].g),
								KSN[26].Damage*CD(KSN[26].a,KSN[26].b,KSN[26].c,KSN[26].d,KSN[26].e,KSN[26].f,KSN[26].g,KSN[26].h,KSN[26].i)*Mana(KSN[26].a,KSN[26].c,KSN[26].g),
								KSN[27].Damage*CD(KSN[27].a,KSN[27].b,KSN[27].c,KSN[27].d,KSN[27].e,KSN[27].f,KSN[27].g,KSN[27].h,KSN[27].i)*Mana(KSN[27].a,KSN[27].c,KSN[27].g),
								KSN[28].Damage*CD(KSN[28].a,KSN[28].b,KSN[28].c,KSN[28].d,KSN[28].e,KSN[28].f,KSN[28].g,KSN[28].h,KSN[28].i)*Mana(KSN[28].a,KSN[28].c,KSN[28].g))
							elseif to==37 then
								SUM= math.max(
								KSN[29].Damage*CD(KSN[29].a,KSN[29].b,KSN[29].c,KSN[29].d,KSN[29].e,KSN[29].f,KSN[29].g,KSN[29].h,KSN[29].i)*Mana(KSN[29].a,KSN[29].c,KSN[29].g),
								KSN[30].Damage*CD(KSN[30].a,KSN[30].b,KSN[30].c,KSN[30].d,KSN[30].e,KSN[30].f,KSN[30].g,KSN[30].h,KSN[30].i)*Mana(KSN[30].a,KSN[30].c,KSN[30].g),
								KSN[31].Damage*CD(KSN[31].a,KSN[31].b,KSN[31].c,KSN[31].d,KSN[31].e,KSN[31].f,KSN[31].g,KSN[31].h,KSN[31].i)*Mana(KSN[31].a,KSN[31].c,KSN[31].g),
								KSN[32].Damage*CD(KSN[32].a,KSN[32].b,KSN[32].c,KSN[32].d,KSN[32].e,KSN[32].f,KSN[32].g,KSN[32].h,KSN[32].i)*Mana(KSN[32].a,KSN[32].c,KSN[32].g),
								KSN[33].Damage*CD(KSN[33].a,KSN[33].b,KSN[33].c,KSN[33].d,KSN[33].e,KSN[33].f,KSN[33].g,KSN[33].h,KSN[33].i)*Mana(KSN[33].a,KSN[33].c,KSN[33].g),
								KSN[34].Damage*CD(KSN[34].a,KSN[34].b,KSN[34].c,KSN[34].d,KSN[34].e,KSN[34].f,KSN[34].g,KSN[34].h,KSN[34].i)*Mana(KSN[34].a,KSN[34].c,KSN[34].g),
								KSN[35].Damage*CD(KSN[35].a,KSN[35].b,KSN[35].c,KSN[35].d,KSN[35].e,KSN[35].f,KSN[35].g,KSN[35].h,KSN[35].i)*Mana(KSN[35].a,KSN[35].c,KSN[35].g),
								--KSN[36].Damage*CD(KSN[36].a,KSN[36].b,KSN[36].c,KSN[36].d,KSN[36].e,KSN[36].f,KSN[36].g,KSN[36].h,KSN[36].i)*Mana(KSN[36].a,KSN[36].c,KSN[36].g),
								KSN[37].Damage*CD(KSN[37].a,KSN[37].b,KSN[37].c,KSN[37].d,KSN[37].e,KSN[37].f,KSN[37].g,KSN[37].h,KSN[37].i)*Mana(KSN[37].a,KSN[37].c,KSN[37].g))
							elseif to==47 then
								SUM= math.max(
								KSN[38].Damage*CD(KSN[38].a,KSN[38].b,KSN[38].c,KSN[38].d,KSN[38].e,KSN[38].f,KSN[38].g,KSN[38].h,KSN[38].i)*Mana(KSN[38].a,KSN[38].c,KSN[38].g),
								KSN[39].Damage*CD(KSN[39].a,KSN[39].b,KSN[39].c,KSN[39].d,KSN[39].e,KSN[39].f,KSN[39].g,KSN[39].h,KSN[39].i)*Mana(KSN[39].a,KSN[39].c,KSN[39].g),
								KSN[40].Damage*CD(KSN[40].a,KSN[40].b,KSN[40].c,KSN[40].d,KSN[40].e,KSN[40].f,KSN[40].g,KSN[40].h,KSN[40].i)*Mana(KSN[40].a,KSN[40].c,KSN[40].g),
								KSN[41].Damage*CD(KSN[41].a,KSN[41].b,KSN[41].c,KSN[41].d,KSN[41].e,KSN[41].f,KSN[41].g,KSN[41].h,KSN[41].i)*Mana(KSN[41].a,KSN[41].c,KSN[41].g),
								--KSN[42].Damage*CD(KSN[42].a,KSN[42].b,KSN[42].c,KSN[42].d,KSN[42].e,KSN[42].f,KSN[42].g,KSN[42].h,KSN[42].i)*Mana(KSN[42].a,KSN[42].c,KSN[42].g),
								KSN[43].Damage*CD(KSN[43].a,KSN[43].b,KSN[43].c,KSN[43].d,KSN[43].e,KSN[43].f,KSN[43].g,KSN[43].h,KSN[43].i)*Mana(KSN[43].a,KSN[43].c,KSN[43].g),
								KSN[44].Damage*CD(KSN[44].a,KSN[44].b,KSN[44].c,KSN[44].d,KSN[44].e,KSN[44].f,KSN[44].g,KSN[44].h,KSN[44].i)*Mana(KSN[44].a,KSN[44].c,KSN[44].g),
								KSN[45].Damage*CD(KSN[45].a,KSN[45].b,KSN[45].c,KSN[45].d,KSN[45].e,KSN[45].f,KSN[45].g,KSN[45].h,KSN[45].i)*Mana(KSN[45].a,KSN[45].c,KSN[45].g),
								KSN[46].Damage*CD(KSN[46].a,KSN[46].b,KSN[46].c,KSN[46].d,KSN[46].e,KSN[46].f,KSN[46].g,KSN[46].h,KSN[46].i)*Mana(KSN[46].a,KSN[46].c,KSN[46].g))
								--KSN[47].Damage*CD(KSN[47].a,KSN[47].b,KSN[47].c,KSN[47].d,KSN[47].e,KSN[47].f,KSN[47].g,KSN[47].h,KSN[47].i)*Mana(KSN[47].a,KSN[47].c,KSN[47].g))
							elseif to==53 then
								SUM= math.max(
								KSN[48].Damage*CD(KSN[48].a,KSN[48].b,KSN[48].c,KSN[48].d,KSN[48].e,KSN[48].f,KSN[48].g,KSN[48].h,KSN[48].i)*Mana(KSN[48].a,KSN[48].c,KSN[48].g),
								KSN[49].Damage*CD(KSN[49].a,KSN[49].b,KSN[49].c,KSN[49].d,KSN[49].e,KSN[49].f,KSN[49].g,KSN[49].h,KSN[49].i)*Mana(KSN[49].a,KSN[49].c,KSN[49].g),
								KSN[50].Damage*CD(KSN[50].a,KSN[50].b,KSN[50].c,KSN[50].d,KSN[50].e,KSN[50].f,KSN[50].g,KSN[50].h,KSN[50].i)*Mana(KSN[50].a,KSN[50].c,KSN[50].g),
								KSN[51].Damage*CD(KSN[51].a,KSN[51].b,KSN[51].c,KSN[51].d,KSN[51].e,KSN[51].f,KSN[51].g,KSN[51].h,KSN[51].i)*Mana(KSN[51].a,KSN[51].c,KSN[51].g),
								KSN[52].Damage*CD(KSN[52].a,KSN[52].b,KSN[52].c,KSN[52].d,KSN[52].e,KSN[52].f,KSN[52].g,KSN[52].h,KSN[52].i)*Mana(KSN[52].a,KSN[52].c,KSN[52].g),
								KSN[53].Damage*CD(KSN[53].a,KSN[53].b,KSN[53].c,KSN[53].d,KSN[53].e,KSN[53].f,KSN[53].g,KSN[53].h,KSN[53].i)*Mana(KSN[53].a,KSN[53].c,KSN[53].g))
							elseif to==59 then
								SUM= math.max(
								KSN[54].Damage*CD(KSN[54].a,KSN[54].b,KSN[54].c,KSN[54].d,KSN[54].e,KSN[54].f,KSN[54].g,KSN[54].h,KSN[54].i)*Mana(KSN[54].a,KSN[54].c,KSN[54].g),
								KSN[55].Damage*CD(KSN[55].a,KSN[55].b,KSN[55].c,KSN[55].d,KSN[55].e,KSN[55].f,KSN[55].g,KSN[55].h,KSN[55].i)*Mana(KSN[55].a,KSN[55].c,KSN[55].g),
								KSN[56].Damage*CD(KSN[56].a,KSN[56].b,KSN[56].c,KSN[56].d,KSN[56].e,KSN[56].f,KSN[56].g,KSN[56].h,KSN[56].i)*Mana(KSN[56].a,KSN[56].c,KSN[56].g),
								KSN[57].Damage*CD(KSN[57].a,KSN[57].b,KSN[57].c,KSN[57].d,KSN[57].e,KSN[57].f,KSN[57].g,KSN[57].h,KSN[57].i)*Mana(KSN[57].a,KSN[57].c,KSN[57].g),
								KSN[58].Damage*CD(KSN[58].a,KSN[58].b,KSN[58].c,KSN[58].d,KSN[58].e,KSN[58].f,KSN[58].g,KSN[58].h,KSN[58].i)*Mana(KSN[58].a,KSN[58].c,KSN[58].g),
								KSN[59].Damage*CD(KSN[59].a,KSN[59].b,KSN[59].c,KSN[59].d,KSN[59].e,KSN[59].f,KSN[59].g,KSN[59].h,KSN[59].i)*Mana(KSN[59].a,KSN[59].c,KSN[59].g))
							elseif to==65 then
								SUM= math.max(
								KSN[60].Damage*CD(KSN[60].a,KSN[60].b,KSN[60].c,KSN[60].d,KSN[60].e,KSN[60].f,KSN[60].g,KSN[60].h,KSN[60].i)*Mana(KSN[60].a,KSN[60].c,KSN[60].g),
								KSN[61].Damage*CD(KSN[61].a,KSN[61].b,KSN[61].c,KSN[61].d,KSN[61].e,KSN[61].f,KSN[61].g,KSN[61].h,KSN[61].i)*Mana(KSN[61].a,KSN[61].c,KSN[61].g),
								KSN[62].Damage*CD(KSN[62].a,KSN[62].b,KSN[62].c,KSN[62].d,KSN[62].e,KSN[62].f,KSN[62].g,KSN[62].h,KSN[62].i)*Mana(KSN[62].a,KSN[62].c,KSN[62].g),
								KSN[63].Damage*CD(KSN[63].a,KSN[63].b,KSN[63].c,KSN[63].d,KSN[63].e,KSN[63].f,KSN[63].g,KSN[63].h,KSN[63].i)*Mana(KSN[63].a,KSN[63].c,KSN[63].g),
								KSN[64].Damage*CD(KSN[64].a,KSN[64].b,KSN[64].c,KSN[64].d,KSN[64].e,KSN[64].f,KSN[64].g,KSN[64].h,KSN[64].i)*Mana(KSN[64].a,KSN[64].c,KSN[64].g),
								KSN[65].Damage*CD(KSN[65].a,KSN[65].b,KSN[65].c,KSN[65].d,KSN[65].e,KSN[65].f,KSN[65].g,KSN[65].h,KSN[65].i)*Mana(KSN[65].a,KSN[65].c,KSN[65].g))						
							end
						end
						if LeBlanc.KS.Percent:Value() then
							if Round(((health-SUM)/maxHealth*100),0)>0 then
								DrawText("\n\n" .. Round(((health-SUM)/maxHealth*100),0) .. "%",15,testPos.x,testPos.y,0xffffff00)
								break
							elseif Round(((health-SUM)/maxHealth*100),0)<=0 then
								DrawText("\n\n"..KSN[v].text.." KILL",15,testPos.x,testPos.y,0xffffff00)
								break
							end
						end
					end
				end
			end
		end
	end
	if LeBlanc.Keys.Combo:Value() and Valid(target) and not IsDead(myHero) then
		if GOS:GetDistance(target)<=2000 then
			local targetPos = GetOrigin(target)
			local targetHP = ( GetCurrentHP(target)*((100+(((GetMagicResist(target)*VoidStaff)-GetMagicPenFlat(myHero))*GetMagicPenPercent(myHero)))/100)+GetHPRegen(target)*6)
			EPred = GetPredictionForPlayer(GetOrigin(myHero),target,GetMoveSpeed(target),1550,150,950,55,true,true)
			WPred = GetPredictionForPlayer(GetOrigin(myHero),target,GetMoveSpeed(target),1450,250,600,250,false,true)
			if mapID==SUMMONERS_RIFT then
				EPos = Vector(targetPos.x,0,targetPos.z)
				HPos = Vector(myHeroPos.x,0,myHeroPos.z)
				WPos = HPos+(HPos-EPos)*(-650/GOS:GetDistance(HPos,EPos))
				if MapPosition:inWall(Point(WPos.x,WPos.y,WPos.z))==true then 
					WallT = 1
				else 
					WallT = 0 
				end
			else
				--No other maps supported atm
				WallT=0
			end
			if GOS:GetDistance(target)<=700 then
			 --killable
			 --normal
						if (CD(1,0,0,n,0,n,0,0,n)==1 and Mana(1,0,0)==1 or
								CD(1,n,0,n,n,n,0,n,1)==1 and Mana(1,0,0)==1 or
								CD(1,n,1,n,n,n,n,n,n)==1 and Mana(1,1,0)==1 or
								CD(1,0,n,n,0,n,n,0,n)==1 and Mana(1,0,0)==1 or
								CD(1,n,n,n,n,n,1,n,n)==1 and Mana(1,0,1)==1 or
								CD(1,n,1,n,n,n,1,n,n)==1 and Mana(1,1,1)==1 or
								CD(1,0,n,n,0,n,1,0,n)==1 and Mana(1,0,1)==1 or
								CD(1,0,1,n,0,n,n,0,n)==1 and Mana(1,1,0)==1 or
								CD(1,n,1,n,n,n,n,n,1)==1 and Mana(1,1,0)==1 or
								CD(1,n,n,n,n,n,1,n,1)==1 and Mana(1,0,1)==1 or
								CD(1,0,1,n,0,n,1,0,n)==1 and Mana(1,1,1)==1 or
								CD(1,n,1,n,n,n,1,n,1)==1 and Mana(1,1,1)==1 or
								CD(1,0,1,n,0,n,1,1,1)==1 and Mana(1,1,1)==1) then
					Q(target) PrintChat("Q")
				elseif (CD(0,1,0,n,0,n,0,0,1)==1 and Mana(0,0,0)==1 or
								CD(1,1,0,n,0,n,0,0,1)==1 and Mana(1,0,0)==1 or
								CD(n,1,1,n,0,n,n,0,1)==1 and Mana(0,1,0)==1 or
								CD(n,1,n,n,0,n,1,0,1)==1 and Mana(0,0,1)==1 or
								CD(n,1,1,n,0,n,1,0,1)==1 and Mana(0,1,1)==1 or
								CD(0,1,1,n,0,n,n,0,1)==1 and Mana(0,1,0)==1 or
								CD(1,1,1,n,0,n,n,0,1)==1 and Mana(1,1,0)==1 or
								CD(0,1,n,n,0,n,1,0,1)==1 and Mana(0,0,1)==1 or
								CD(1,1,n,n,0,n,1,0,1)==1 and Mana(1,0,1)==1 or
								CD(1,1,1,n,n,n,1,n,1)==1 and Mana(1,1,1)==1 or
								CD(1,1,1,n,0,n,1,0,1)==1 and Mana(1,1,1)==1) then
					QR(target) PrintChat("QR")
				elseif (CD(0,0,1,n,0,n,0,0,0)==1 and Mana(0,1,0)==1 or
								CD(0,n,1,n,n,n,0,n,1)==1 and Mana(0,1,0)==1 or
								CD(0,n,1,n,n,n,n,n,0)==1 and Mana(0,1,0)==1 or
								CD(n,0,1,n,0,n,n,0,0)==1 and Mana(0,1,0)==1 or
								CD(n,n,1,n,n,n,1,n,0)==1 and Mana(0,1,1)==1 or
								CD(0,n,1,n,n,n,1,n,0)==1 and Mana(0,1,1)==1 or
								CD(n,0,1,n,0,n,1,0,0)==1 and Mana(0,1,1)==1 or
								CD(0,0,1,n,0,n,n,0,0)==1 and Mana(0,1,0)==1 or
								CD(n,n,1,n,n,n,1,n,1)==1 and Mana(0,1,1)==1 or
								CD(0,0,1,n,0,n,1,0,0)==1 and Mana(0,1,1)==1 or
								CD(0,n,1,n,n,n,1,n,1)==1 and Mana(0,1,1)==1 or
								CD(0,1,1,n,0,n,1,0,1)==1 and Mana(0,1,1)==1) and WallT==0 then
					W(target) PrintChat("W")
				elseif (CD(0,0,0,n,1,n,0,0,1)==1 and Mana(0,0,0)==1 or
								CD(0,0,1,n,1,n,0,0,1)==1 and Mana(0,1,0)==1 or
								CD(1,0,n,n,1,n,n,0,1)==1 and Mana(1,0,0)==1 or
								CD(n,0,n,n,1,n,1,0,1)==1 and Mana(0,0,1)==1 or
								CD(1,0,n,n,1,n,1,0,1)==1 and Mana(1,0,1)==1 or
								CD(1,0,1,n,1,n,n,0,1)==1 and Mana(1,1,0)==1 or
								CD(n,0,0,n,1,n,1,0,1)==1 and Mana(0,0,1)==1 or
								CD(n,0,1,n,1,n,1,0,1)==1 and Mana(0,1,1)==1 or
								CD(0,0,0,n,1,n,1,n,1)==1 and Mana(0,0,1)==1 or
								CD(1,0,1,n,1,n,1,0,1)==1 and Mana(1,1,1)==1) and WallT==0 then
					WR(target) PrintChat("WR")
				elseif (CD(0,0,0,n,0,n,1,0,n)==1 and Mana(0,0,1)==1 or
								CD(0,n,0,n,n,n,1,n,1)==1 and Mana(0,0,1)==1 or
								CD(0,n,n,n,n,n,1,n,n)==1 and Mana(0,0,1)==1 or
								CD(n,0,n,n,0,n,1,0,0)==1 and Mana(0,0,1)==1 or
								CD(n,n,0,n,n,n,1,n,n)==1 and Mana(0,0,1)==1 or
								CD(n,0,0,n,0,n,1,0,0)==1 and Mana(0,0,1)==1 or
								CD(0,0,n,n,0,n,1,0,0)==1 and Mana(0,0,1)==1 or
								CD(0,n,0,n,n,n,1,n,n)==1 and Mana(0,0,1)==1 or
								CD(n,0,0,n,0,n,1,0,0)==1 and Mana(0,0,1)==1 or
								CD(0,0,0,0,0,0,1,0,0)==1 and Mana(0,0,1)==1 or
								CD(0,0,0,n,0,n,1,n,0)==1 and Mana(0,0,1)==1) and EPred.HitChance==1 then
					E(target) PrintChat("E")
				elseif (CD(0,0,0,n,0,n,0,1,1)==1 and Mana(0,0,0)==1 or											
								CD(0,0,0,n,0,n,1,1,1)==1 and Mana(0,0,1)==1 or							
								CD(1,0,n,n,0,n,n,1,1)==1 and Mana(1,0,0)==1 or								
								CD(n,0,1,n,0,n,n,1,1)==1 and Mana(0,1,0)==1 or							
								CD(1,0,1,n,0,n,n,1,1)==1 and Mana(1,1,0)==1 or
								CD(1,0,n,n,0,n,1,1,1)==1 and Mana(1,0,1)==1 or								
								CD(n,0,1,n,0,n,1,1,1)==1 and Mana(0,1,1)==1 or
								CD(0,0,0,n,1,n,1,0,1)==1 and Mana(0,0,1)==1 or
								CD(0,0,0,0,0,0,0,1,1)==1 and Mana(0,0,0)==1 or
								CD(0,0,0,n,0,n,0,1,1)==1 and Mana(0,0,0)==1) and EPred.HitChance==1 then
					ER(target) PrintChat("ER")
				end
			elseif GOS:GetDistance(target)>700 and GOS:GetDistance(target)<1300 - GetMoveSpeed(target) * .3 then
				if 			CD(1,n,1,n,n,n,1,n,n)==1 and Mana(1,1,0)==1 and WallT==0 then WL(target) end	
			end
		end
		if not LeBlanc.Misc.MR:Value() then
			if	CD(0,0,0,1,0,1,0,0,1)==1 or CD(0,0,0,0,0,1,0,0,1)==1 then
				WR2() 
			elseif CD(0,0,0,1,0,0,0,0,0)==1 then
				W2()
			end
		end
	end
	if Valid(target) and not IsDead(myHero) then
		if LeBlanc.Keys.DoQ:Value() and Valid(target) and GOS:GetDistance(target)<=700 then
			if 			CD(1,n,n,n,n,n,n,n,n)==1 and Mana(1,n,n)==1 then Q(target)
			elseif 	CD(n,1,n,n,n,n,n,n,1)==1 and Mana(n,n,n)==1 then QR(target)
			end
		end
		if LeBlanc.Keys.DoE:Value() and Valid(target) and GOS:GetDistance(target)<=950 then
			if 			CD(n,n,n,n,n,n,1,n,n)==1 and Mana(n,n,1)==1 then E(target)
			elseif	CD(n,n,n,n,n,n,n,1,1 )==1 and Mana(n,n,n)==1 then ER(target)
			end
		end
	end
end

--Check for lastSpell--
OnProcessSpell(function(unit, spell)
	if unit and spell and GetObjectName(unit) == GetObjectName(myHero) then
		if spell.name == 'LeblancChaosOrb' then	ls = 'Q' end
		if spell.name == 'LeblancChaosOrbM' then ls = 'QR' end
		if spell.name == 'LeblancSlide' then ls = 'W' end
		if spell.name == 'LeblancSoulShackle' then ls = 'E' end
		if spell.name == 'LeblancSlideM' then 	ls = 'WR' end
		if spell.name == 'LeblancSoulShackleM' then ls = 'ER' end
	end
end)

OnLoop(function(myHero)
	n = GOS:GetEnemyHeroes()
	myHeroPos = GetOrigin(myHero)
	target = GetCurrentTarget()
	targetPos = GetOrigin(target)
	multi = LeBlanc.KS.Mult:Value() and 2 or 1
	DamageCalc()
	SpellSequence()
	CheckItemCD()
	if LeBlanc.Keys.Harass:Value() and target then Harass() end
	if LeBlanc.Misc.Draw:Value() then Draw() end
end)
