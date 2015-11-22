require('Inspired')
if GetObjectName(myHero) ~= "Leblanc" then return end
require('MapPositionGOS')

--version = 0.9
--added DmgOverHP, Priority

LeBlanc = MenuConfig("LeBlanc", "LeBlanc")
LeBlanc:Menu("Keys","Keys")
LeBlanc.Keys:Key("DoQ", "Q", string.byte("Q"))
LeBlanc.Keys:Key("DoE", "E", string.byte("E"))
LeBlanc.Keys:Key("Harass", "Harass", string.byte("X"))
LeBlanc.Keys:Key("Combo", "Combo", string.byte(" "))
LeBlanc.Keys:DropDown("Priority", "Priority", 1, {"QWE", "QEW", "WEQ", "WQE", "EQW", "EWQ"})

LeBlanc:Menu("KS","Kill Functions")
LeBlanc.KS:Boolean("DmgOverHP", "Draw DMG over HPBar", false)
LeBlanc.KS:Boolean("Multi", "Calc 2 E proc", false)
LeBlanc.KS:Boolean("KSNotes", "KS Notes", true)
LeBlanc.KS:Boolean("Percent", "Percent Notes", true)
LeBlanc.KS:Boolean("Ignite","Auto-Ignite",true)
LeBlanc.KS:Info("INFO", "If u disable a  value, reload Script")

LeBlanc:Menu("Misc","Misc")
LeBlanc.Misc:Boolean("MR", "Manual Return", true)
LeBlanc.Misc:Boolean("Details", "Detailed Kill notes", false)
LeBlanc.Misc:Info("INFO", "Detailed notes always show")
LeBlanc.Misc:Info("INFO", "max Damage possible.")

LeBlanc:Menu("Draw", "Draw")
LeBlanc.Draw:Boolean("DrawON", "Draw Stuff", true)
LeBlanc.Draw:Boolean("DrawQ", "Draw Q", true)
LeBlanc.Draw:Boolean("DrawW", "Draw W", true)
LeBlanc.Draw:Boolean("DrawE", "Draw E", true)
LeBlanc.Draw:Boolean("DrawQW", "Draw QW", true)
LeBlanc.Draw:Boolean("Spells", "Spell Combos", true)

------------------------------------------
--Variables
------------------------------------------
local mapID = GetMapID()
local ls
local target
local myHero = GetMyHero()
local multi = 1
local max_val, key = 0, 0
local xQ,xW,xE,xR,xRW,xRE
local xIgnite,IRDY = 0, 0
local KSN = {}
local HNS = {}
local n = {}
------------------------------------------
--MISC
------------------------------------------
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
local function Valid(unit)
  return unit and not IsDead(unit) and IsTargetable(unit) and not IsImmune(unit, myHero) and IsVisible(unit) and true or false
end
local function Round(val, decimal)
		return decimal ~= nil and math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal) or math.floor(val + 0.5)
end
------------------------------------------
--Mana Handling
------------------------------------------
local function Mana(a,b,c)
	a = a == 1 and 40+(GetCastLevel(myHero,_Q)*10) or 0
	b = b == 1 and 75+(GetCastLevel(myHero,_W)*5) or 0
	c = c == 1 and 80 or 0
	return GetCurrentMana(myHero) > a + b + c and 1 or 0
end
------------------------------------------
--Cooldown Handling
------------------------------------------
local function CD(a,b,c,d,e,f,g,h,i)
	Q1RDY = GetCastName(myHero,_Q) == 'LeblancChaosOrb' 		and GetCastLevel(myHero,_Q) >= 1 	and CanUseSpell(myHero, _Q) == READY and 1 or 0 
	Q2RDY = GetCastName(myHero,_R) == 'LeblancChaosOrbM' 		and GetCastLevel(myHero,_R) >= 1 	and CanUseSpell(myHero, _R) == READY and 1 or 0
	W1RDY = GetCastName(myHero,_W) == 'LeblancSlide' 				and GetCastLevel(myHero,_W) >= 1 	and CanUseSpell(myHero, _W) == READY and 1 or 0 
	W2RDY = GetCastName(myHero,_W) == 'leblancslidereturn' 	and GetCastLevel(myHero,_W) >= 1 	and CanUseSpell(myHero, _W) == READY and 1 or 0
	W3RDY = GetCastName(myHero,_R) == 'LeblancSlideM' 			and GetCastLevel(myHero,_R) >= 1 	and CanUseSpell(myHero, _R)	== READY and 1 or 0
	W4RDY = GetCastName(myHero,_R) == 'leblancslidereturnm' and GetCastLevel(myHero,_R) >= 1 	and CanUseSpell(myHero, _R)	== READY and 1 or 0 
	E1RDY = GetCastName(myHero,_E) == 'LeblancSoulShackle' 	and GetCastLevel(myHero,_E) >= 1 	and CanUseSpell(myHero, _E)	== READY and 1 or 0 
	E2RDY = GetCastName(myHero,_R) == 'LeblancSoulShackleM' and GetCastLevel(myHero,_R) >= 1 	and CanUseSpell(myHero, _R)	== READY and 1 or 0 
	RRDY  = GetCastLevel(myHero,_R) >= 1 and CanUseSpell(myHero, _R) == READY and 1 or 0
	return (Q1RDY == a or a == n) and (Q2RDY == b or b == n) and (W1RDY == c or c == n) and (W2RDY == d or d == n) and (W3RDY == e or e == n) and (W4RDY == f or f == n) and (E1RDY == g or g == n) and (E2RDY == h or h == n) and (RRDY == i or i == n) and 1 or 0
end
------------------------------------------
--Cast Functions
------------------------------------------
local function Q(o)
	CastTargetSpell(o,_Q)
end
local function QR(o)
	CastTargetSpell(o,_R)
end
local function W(o)
	local WPred = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),1450,250,650,250,false,true)
	if WPred.HitChance == 1 then
		CastSkillShot(_W,WPred.PredPos.x,WPred.PredPos.y,WPred.PredPos.z)
	end
end
local function W2(o)
	CastSpell(_W)
end
local function WR(o)
	local WPred = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),1450,250,650,250,false,true)
	if WPred.HitChance == 1 then
		CastSkillShot(_R,WPred.PredPos.x,WPred.PredPos.y,WPred.PredPos.z)
	end
end
local function WR2(o)
	CastSpell(_R)
end
local function E(o)
	local EPred = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),1550,150,950,55,true,true)
	if EPred.HitChance == 1 then
		CastSkillShot(_E,EPred.PredPos.x,EPred.PredPos.y,EPred.PredPos.z)
	end
end
local function ER(o)
	local ERPred = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),1550,150,950,55,true,true)
	if ERPred.HitChance == 1 then
		CastSkillShot(_R,ERPred.PredPos.x,ERPred.PredPos.y,ERPred.PredPos.z)
	end
end
local function WL(o)
	local Pos = GetOrigin(o)
	if CD(n,n,n,0,n,0,n,n,n) == 1 then 
		CastSkillShot(_W,Pos.x,Pos.y,Pos.z) 
	end
end
------------------------------------------
--Harass
------------------------------------------
local function Harass()
	local Wall
	if mapID == SUMMONERS_RIFT then
		local WPred = GetPredictionForPlayer(GetOrigin(myHero),target,GetMoveSpeed(target),1450,250,650,250,false,true)
		local ChampionPos = GetOrigin(myHero)
		local EPos = Vector(WPred.PredPos.x, 0, WPred.PredPos.z)
		local HPos = Vector(ChampionPos.x, 0, ChampionPos.z)
		local WPos = HPos + (HPos - EPos) * ( -650 / GetDistance(HPos, EPos))
		Wall = MapPosition:inWall(Point(WPos.x, WPos.y, WPos.z)) == true and 1 or 0 
	else
		Wall = 0
	end
	if 		 CD(1,n,1,n,n,n,n,n,n)==1 and Mana(1,1,n)==1 and Wall == 0 then Q(target) W(target)
	elseif CD(n,n,n,1,n,n,n,n,n)==1 then W2()
	end
end
------------------------------------------
--Damage Calc
------------------------------------------
local function DamageCalc()
	local AP = GetBonusAP(myHero)
	xQ = 	GetCastLevel(myHero,_Q) * 25 + 30 + .4 * AP
	xW = 	GetCastLevel(myHero,_W) * 40 + 45 + .6 * AP
	xE = 	multi == 1 and (GetCastLevel(myHero,_E) * 25 + 15 + .5 * AP) or multi == 2 and (GetCastLevel(myHero,_E) * 25 + 15 + .5 * AP) * 2
	xR = 	GetCastLevel(myHero,_R) * 100 + .65 	 * AP
	xRE = multi == 1 and (GetCastLevel(myHero,_R) * 100 + .65 	 * AP) or multi == 2 and (GetCastLevel(myHero,_R) * 100 + .65 	 * AP) * 2
	xRW = GetCastLevel(myHero,_R) * 150 + .975 	 * AP
	IRDY = LeBlanc.KS.Ignite:Value() and Ignite and CanUseSpell(myHero, Ignite) == 0 and 1 or 0
	xIgnite = (50 + GetLevel(myHero) * 20) * IRDY
end
------------------------------------------
--Variables 2
------------------------------------------
local function Variables()
	KSN[0]  = {a=0,b=0,c=0,d=n,e=0,f=n,g=0,h=0,i=0, Dist=0, Block=0, Wall=0, Damage= 0,text ="No Spells"}
	KSN[1]  = {a=1,b=0,c=0,d=n,e=0,f=n,g=0,h=0,i=n, Dist=0, Block=0, Wall=0, Damage= xQ,text ="Q"}
	KSN[2]  = {a=1,b=n,c=1,d=n,e=n,f=n,g=n,h=n,i=n, Dist=0, Block=0, Wall=1, Damage= xQ*2+xW,text ="Q-W"}
	KSN[3]  = {a=1,b=n,c=n,d=n,e=n,f=n,g=1,h=n,i=n, Dist=0, Block=1, Wall=0, Damage= xQ*2+xE,text ="Q-E"}
	KSN[4]  = {a=1,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=n, Dist=0, Block=1, Wall=1, Damage= xQ*2+xW+xE,text ="Q-W-E"}
	KSN[5]  = {a=1,b=0,c=1,d=n,e=n,f=0,g=n,h=0,i=n, Dist=1, Block=0, Wall=1, Damage= xQ,text ="W-Q Long "}
	KSN[6]  = {a=1,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=n, Dist=1, Block=1, Wall=1, Damage= xQ*2+xE,text ="W-E-Q Long "}
	KSN[7]  = {a=0,b=0,c=1,d=n,e=0,f=n,g=0,h=0,i=n, Dist=0, Block=0, Wall=1, Damage= xW,text ="W"}
	KSN[8]  = {a=0,b=0,c=0,d=n,e=0,f=n,g=1,h=0,i=n, Dist=0, Block=1, Wall=0, Damage= xE,text ="E"}
	KSN[9]  = {a=n,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=n, Dist=0, Block=1, Wall=1, Damage= xW+xE,text ="W-E"}
	KSN[10] = {a=0,b=0,c=1,d=n,e=n,f=0,g=1,h=0,i=n, Dist=1, Block=1, Wall=1, Damage= xE,text ="W-E Long "}
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
	KSN[20] = {a=1,b=n,c=n,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=0, Damage= xQ*2+xR*2+xE,text ="Q-Q(R)-E"}
	KSN[21] = {a=n,b=1,c=n,d=n,e=0,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=0, Damage= xR*2+xE,text ="Q(R)-E"}
	KSN[22] = {a=n,b=1,c=1,d=n,e=0,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=1, Damage= xR*2+xW+xE,text ="Q(R)-W-E"}
	KSN[23] = {a=1,b=1,c=n,d=n,e=0,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=0, Damage= xQ*2+xR*2+xE,text ="Q(R)-Q-E"}
	KSN[24] = {a=1,b=1,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xR*2+xW+xE,text ="Q-Q(R)-W-E"}
	KSN[25] = {a=1,b=1,c=1,d=n,e=0,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xR*2+xW+xE,text ="Q(R)-Q-W-E"}
	KSN[26] = {a=0,b=1,c=1,d=n,e=0,f=n,g=1,h=0,i=1, Dist=1, Block=1, Wall=1, Damage= xR*2+xE,text ="W-E-Q(R) Long "}
	KSN[27] = {a=1,b=1,c=1,d=n,e=0,f=n,g=1,h=0,i=1, Dist=1, Block=1, Wall=1, Damage= xE+xR*2+xQ*2,text ="W-Q(R)-Q-E Long "}
	KSN[28] = {a=1,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=1, Block=1, Wall=1, Damage= xE+xR*2+xQ*2,text ="W-Q-Q(R)-E Long "}
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
	KSN[38] = {a=1,b=0,c=n,d=n,e=1,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xRW+xE,text ="Q-W(R)-E"}				  
	KSN[39] = {a=1,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xW+xRW+xE,text ="Q-W-W(R)-E"}
	KSN[40] = {a=1,b=0,c=1,d=n,e=1,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xW+xRW+xE,text ="Q-W(R)-W-E"}					
	KSN[41] = {a=1,b=0,c=1,d=n,e=n,f=n,g=1,h=0,i=1, Dist=1, Block=1, Wall=1, Damage= xQ*2+xRW+xE,text ="Q-W-W(R)-E Long"}					
	--KSN[42] = {a=1,b=0,c=1,d=n,e=n,f=n,g=1,h=0,i=1, Dist=2, Block=2, Wall=2, Damage= xQ*2+xE,text ="Q-W-W(R)-E Very Long"}					
	KSN[43] = {a=n,b=0,c=n,d=n,e=1,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=1, Damage= xRW+xE,text ="W(R)-E"}
	KSN[44] = {a=n,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=1, Damage= xW+xRW+xE,text ="W-W(R)-E"}
	KSN[45] = {a=n,b=0,c=1,d=n,e=1,f=n,g=1,h=0,i=1, Dist=0, Block=1, Wall=1, Damage= xW+xRW+xE,text ="W(R)-W-E"}					
	KSN[46] = {a=0,b=0,c=1,d=n,e=n,f=n,g=1,h=0,i=1, Dist=1, Block=1, Wall=1, Damage= xRW+xE,text ="W-W(R)-E Long"}
	--KSN[47] = {a=0,b=0,c=1,d=n,e=n,f=n,g=1,h=0,i=1, Dist=2, Block=2, Wall=2, Damage= xE,text ="W-W(R)-E Very Long"}					
	--ULTI READY, UTLI E, AND W, AND Q
	KSN[48] = {a=1,b=0,c=1,d=n,e=0,f=n,g=n,h=1,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xW+xRE,text ="Q-W-E(R)"}
	KSN[49] = {a=1,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xW+xE+xRE,text ="Q-W-E-E(R)"}
	KSN[50] = {a=1,b=0,c=1,d=n,e=0,f=n,g=1,h=1,i=1, Dist=0, Block=1, Wall=1, Damage= xQ*2+xW+xE+xRE,text ="Q-W-E-E(R)"}					
	KSN[51] = {a=1,b=0,c=1,d=n,e=0,f=n,g=0,h=n,i=1, Dist=1, Block=1, Wall=1, Damage= xQ*2+xRE,text ="W-Q-E(R) Long "}					
	KSN[52] = {a=1,b=0,c=1,d=n,e=0,f=n,g=1,h=1,i=1, Dist=1, Block=1, Wall=1, Damage= xE+xRE+xQ*2,text ="W-Q-E(R)-E Long "}
	KSN[53] = {a=1,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=1, Block=1, Wall=1, Damage= xE+xRE+xQ*2,text ="W-Q-E-E(R) Long "}
	--ULTI READY, ULTI E, AND W, NO Q
	KSN[54] = {a=n,b=0,c=1,d=n,e=0,f=n,g=n,h=1,i=1, Dist=0, Block=1, Wall=1, Damage= xW+xE,text ="W-E(R)"}					
	KSN[55] = {a=n,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=1, Damage= xW+xE+xRE,text ="W-E-E(R)"}
	KSN[56] = {a=n,b=0,c=1,d=n,e=0,f=n,g=1,h=1,i=1, Dist=0, Block=1, Wall=1, Damage= xW+xE+xRE,text ="W-E(R)-E"}					
	KSN[57] = {a=0,b=0,c=1,d=n,e=0,f=0,g=0,h=1,i=1, Dist=1, Block=1, Wall=1, Damage= xRE,text ="W-E(R) Long "}
	KSN[58] = {a=0,b=n,c=1,d=n,e=n,f=n,g=1,h=n,i=1, Dist=1, Block=1, Wall=1, Damage= xE+xRE,text ="W-E-E(R) Long "}
	KSN[59] = {a=0,b=0,c=1,d=n,e=0,f=n,g=1,h=1,i=1, Dist=1, Block=1, Wall=1, Damage= xE+xRE,text ="W-E(R)-E Long "}
	--ULTI READY, UTLI E, NO W	
	KSN[60] = {a=1,b=0,c=n,d=n,e=0,f=n,g=n,h=1,i=1, Dist=0, Block=1, Wall=0, Damage= xQ*2+xRE,text ="Q-E(R)"}								
	KSN[61] = {a=1,b=n,c=n,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=0, Damage= xQ*2+xE+xRE,text ="Q-E-E(R)"}
	KSN[62] = {a=1,b=0,c=n,d=n,e=0,f=n,g=1,h=1,i=1, Dist=0, Block=1, Wall=0, Damage= xQ*2+xE+xRE,text ="Q-E(R)-E"}										
	KSN[63] = {a=0,b=0,c=0,d=n,e=0,f=n,g=0,h=1,i=1, Dist=0, Block=1, Wall=0, Damage= xE,text ="E(R)"}
	KSN[64] = {a=0,b=n,c=0,d=n,e=n,f=n,g=1,h=n,i=1, Dist=0, Block=1, Wall=0, Damage= xE+xRE,text ="E-E(R)"}
	KSN[65] = {a=0,b=0,c=0,d=n,e=0,f=n,g=1,h=1,i=1, Dist=0, Block=1, Wall=0, Damage= xE+xRE,text ="E(R)-E"}	
	
	HNS[1]  = {a=1,b=0,c=0,d=n,e=0,f=n,g=0,h=0,i=n, text ="Q"}
	HNS[2]  = {a=1,b=0,c=1,d=n,e=0,f=n,g=0,h=0,i=n, text ="Q-W"}
	HNS[3]  = {a=1,b=0,c=0,d=n,e=1,f=n,g=0,h=0,i=1, text ="Q-W(R)"}
	HNS[4]  = {a=1,b=0,c=0,d=n,e=0,f=n,g=1,h=0,i=n, text ="Q-E"}
	HNS[5]  = {a=1,b=0,c=0,d=n,e=0,f=n,g=0,h=1,i=1, text ="Q-E(R)"}
	HNS[6]  = {a=1,b=0,c=1,d=n,e=0,f=n,g=1,h=0,i=n, text ="Q-W-E"}
	HNS[7]  = {a=1,b=0,c=0,d=n,e=1,f=n,g=1,h=0,i=1, text ="Q-W(R)-E"}
	HNS[8]  = {a=1,b=0,c=1,d=n,e=0,f=n,g=0,h=1,i=1, text ="Q-W-E(R)"}
	HNS[9]  = {a=1,b=0,c=1,d=n,e=1,f=n,g=0,h=0,i=1, text ="Q-W-W(R)"}
	HNS[10] = {a=1,b=0,c=0,d=n,e=0,f=n,g=1,h=1,i=1, text ="Q-E-E(R)"}
	HNS[11] = {a=1,b=0,c=1,d=n,e=1,f=n,g=1,h=0,i=1, text ="Q-W-W(R)-E"}
	HNS[12] = {a=1,b=0,c=1,d=n,e=0,f=n,g=1,h=1,i=1, text ="Q-W-E-E(R)"}
	HNS[13] = {a=0,b=1,c=0,d=n,e=0,f=n,g=0,h=0,i=1, text ="Q(R)"}
	HNS[14] = {a=1,b=1,c=0,d=n,e=0,f=n,g=0,h=0,i=1, text ="Q-Q(R)"}
	HNS[15] = {a=0,b=1,c=1,d=n,e=0,f=n,g=0,h=0,i=1, text ="Q(R)-W"}
	HNS[16] = {a=0,b=1,c=0,d=n,e=0,f=n,g=1,h=0,i=1, text ="Q(R)-E"}
	HNS[17] = {a=0,b=1,c=1,d=n,e=0,f=n,g=1,h=0,i=1, text ="Q(R)-W-E"}
	HNS[18] = {a=1,b=1,c=1,d=n,e=0,f=n,g=0,h=0,i=1, text ="Q-Q(R)-W"}
	HNS[19] = {a=1,b=1,c=0,d=n,e=0,f=n,g=1,h=0,i=1, text ="Q-Q(R)-E"}
	HNS[20] = {a=1,b=1,c=1,d=n,e=0,f=n,g=1,h=0,i=1, text ="Q-Q(R)-W-E"}
	HNS[21] = {a=0,b=0,c=1,d=n,e=0,f=n,g=0,h=0,i=n, text ="W"}
	HNS[22] = {a=0,b=0,c=0,d=n,e=1,f=n,g=0,h=0,i=1, text ="W(R)"}
	HNS[23] = {a=0,b=0,c=1,d=n,e=1,f=n,g=0,h=0,i=1, text ="W-W(R)"}
	HNS[24] = {a=0,b=0,c=1,d=n,e=0,f=n,g=1,h=0,i=n, text ="W-E"}
	HNS[25] = {a=0,b=0,c=0,d=n,e=1,f=n,g=1,h=0,i=1, text ="W(R)-E"}
	HNS[26] = {a=0,b=0,c=1,d=n,e=0,f=n,g=0,h=1,i=1, text ="W-E(R)"}
	HNS[27] = {a=0,b=0,c=1,d=n,e=1,f=n,g=1,h=0,i=1, text ="W-W(R)-E"}
	HNS[28] = {a=0,b=0,c=1,d=n,e=0,f=n,g=1,h=1,i=1, text ="W-E-E(R)"}
	HNS[29] = {a=0,b=0,c=0,d=n,e=0,f=n,g=1,h=0,i=n, text ="E"}
	HNS[30] = {a=0,b=0,c=0,d=n,e=0,f=n,g=0,h=1,i=1, text ="E(R)"}
	HNS[31] = {a=0,b=0,c=0,d=n,e=0,f=n,g=1,h=1,i=1, text ="E-E(R)"}
	local Damage = {}
	local x, y = 1, 35
	for v = x, y do
		x = v == 35 and 36 or 1
		y = v == 35 and 65 or 35
		Damage[v] = KSN[v].Damage * CD(KSN[v].a,KSN[v].b,KSN[v].c,KSN[v].d,KSN[v].e,KSN[v].f,KSN[v].g,KSN[v].h,KSN[v].i) * Mana(KSN[v].a,KSN[v].c,KSN[v].g)
		if Damage[v] > max_val then
			max_val, key = Damage[v], v
		end
		if Damage[key] == 0 then
			max_val, key = 0, 0
		end
	end
end
------------------------------------------
--Draw Stuff
------------------------------------------
local function Draw()
	if not IsDead(myHero) then
		local ChampionPos = GetOrigin(myHero)
		local myHeroWorld = WorldToScreen(1,ChampionPos.x,ChampionPos.y,ChampionPos.z)
		--Q Range
		if LeBlanc.Draw.DrawQ:Value() and (CD(1,n,n,n,n,n,n,n,n)==1 and Mana(1,0,0)==1) or CD(0,1,n,n,n,n,n,1)==1 then 
			DrawCircle(GetOrigin(myHero),750,0,0,0xffff0000)
		end
		--W Range
		if LeBlanc.Draw.DrawW:Value() and (CD(n,n,1,n,n,n,n,n,n)==1 and Mana(0,1,0)==1) or CD(n,n,0,n,1,n,n,1)==1 then 
			DrawCircle(GetOrigin(myHero),650,0,0,0xffff0000)
		end
		--QW Range
		if LeBlanc.Draw.DrawQW:Value() and (CD(1,n,1,n,n,n,n,n,n)==1 and Mana(1,1,0)==1) or CD(1,n,0,n,1,n,n,1)==1 and Mana(1,0,0)==1 then 
			DrawCircle(GetOrigin(myHero),1400,0,0,0xffffff00)
		end
		--E Range
		if LeBlanc.Draw.DrawE:Value() and (CD(n,n,n,n,n,n,1,n,n)==1 and Mana(0,0,1)==1) or CD(n,n,n,n,n,0,1,1)==1 then 
			DrawCircle(GetOrigin(myHero),950,0,0,0xffffff00)
		end
		if LeBlanc.Draw.Spells:Value() then
			for v = 1,#HNS do
				if CD(HNS[v].a,HNS[v].b,HNS[v].c,HNS[v].d,HNS[v].e,HNS[v].f,HNS[v].g,HNS[v].h,HNS[v].i)==1 and Mana(HNS[v].a,HNS[v].c,HNS[v].g)==1 then
					DrawText(HNS[v].text,15,myHeroWorld.x,myHeroWorld.y,0xffffff00)
					break
				end
			end
		end
		if #n > 0 and #KSN ~= 0 then
			for  l = 1, #n do
				if not IsDead(n[l]) and IsVisible(n[l]) and IsInDistance(n[l], 3000) then
					local x, y = 1, 35
					local health = GetCurrentHP(n[l])*((100+(((GetMagicResist(n[l]))-GetMagicPenFlat(myHero))*GetMagicPenPercent(myHero)))/100)+GetHPRegen(n[l])*6
					local maxHealth = GetMaxHP(n[l])*((100+(((GetMagicResist(n[l]))-GetMagicPenFlat(myHero))*GetMagicPenPercent(myHero)))/100)+GetHPRegen(n[l])*6 
					local drawPos = GetOrigin(n[l])
  				local testPos = WorldToScreen(1, drawPos)
  				if LeBlanc.KS.DmgOverHP:Value() then
						DrawDmgOverHpBar(n[l], GetCurrentHP(n[l]), 0, max_val, 0xffff0000)
					end
					if LeBlanc.KS.Percent:Value() then
	  				if IsInDistance(n[l], 750) then
							if Round(((health-max_val)/maxHealth*100),0)>0 then
								DrawText("\n\n" .. Round(((health-max_val)/maxHealth*100),0) .. "%",15,testPos.x,testPos.y,0xffffff00)
							elseif Round(((health-max_val)/maxHealth*100),0)<=0 then
								if LeBlanc.Misc.Details:Value() then
									DrawText("\n\n"..KSN[key].text.." KILL",15,testPos.x,testPos.y,0xffffff00)
								else
									DrawText("\n\n".." KILL",15,testPos.x,testPos.y,0xffffff00)
								end
							end
						elseif GetDistance(n[l]) > 750 then
							if Round(((health-(max_val - (W1RDY * xW)))/maxHealth*100),0)>0 then
								DrawText("\n\n" .. Round(((health-(max_val - (W1RDY * xW)))/maxHealth*100),0) .. "%",15,testPos.x,testPos.y,0xffffff00)
							elseif Round(((health-(max_val - (W1RDY * xW)))/maxHealth*100),0)<=0 then
								if LeBlanc.Misc.Details:Value() then
									DrawText("\n\n"..KSN[key].text.." KILL",15,testPos.x,testPos.y,0xffffff00)
								else
									DrawText("\n\n".." KILL",15,testPos.x,testPos.y,0xffffff00)
								end
							end
						end
					end
					if LeBlanc.KS.KSNotes:Value() then
						if CD(KSN[key].a,KSN[key].b,KSN[key].c,KSN[key].d,KSN[key].e,KSN[key].f,KSN[key].g,KSN[key].h,KSN[key].i)==1 and Mana(KSN[key].a,KSN[key].c,KSN[key].g)==1 and health < KSN[key].Damage + xIgnite then
							local Wall
							local Block
							if mapID == SUMMONERS_RIFT then
								local WPred = GetPredictionForPlayer(GetOrigin(myHero),n[l],GetMoveSpeed(n[l]),1450,250,650,250,false,true)
								local ChampionPos = GetOrigin(myHero)
								local EPos = Vector(WPred.PredPos.x, 0, WPred.PredPos.z)
								local HPos = Vector(ChampionPos.x, 0, ChampionPos.z)
								local WPos = HPos + (HPos - EPos) * ( -650 / GetDistance(HPos, EPos))
								Wall = MapPosition:inWall(Point(WPos.x, WPos.y, WPos.z)) == true and 1 or 0 
							else
								Wall = 0
							end
							local EPred = GetPredictionForPlayer(GetOrigin(myHero),n[l],GetMoveSpeed(n[l]),1550,150,950,55,true,true)
							if EPred.HitChance==1 then
								Block=0
							else
								Block=1
							end
							if KSN[key].Dist==1 and GetDistance(n[l])>750 and GetDistance(n[l])<=1400 - GetMoveSpeed(n[l]) * .3 then
								if (KSN[key].Block==1 and Block==1) or (KSN[key].Wall==1 and Wall==1) then 
									DrawCircle(drawPos.x,drawPos.y,drawPos.z,100,0,0,0xffffff00)
								else 
									DrawCircle(drawPos.x,drawPos.y,drawPos.z,100,0,0,0xffff0000)
								end
							elseif KSN[key].Dist==0 and GetDistance(n[l])<750 then
								if (KSN[key].Block==1 and Block==1) or (KSN[key].Wall==1 and Wall==1) then 
									DrawCircle(drawPos.x,drawPos.y,drawPos.z,100,0,0,0xffffff00)
								else 
									DrawCircle(drawPos.x,drawPos.y,drawPos.z,100,0,0,0xffff0000)
								end
							end
						end
					end
				end
			end
		end
	end
end      
------------------------------------------
--Combo
------------------------------------------
local function SpellSequence()
	if LeBlanc.Keys.Combo:Value() and Valid(target) and not IsDead(myHero) then
		if GetDistance(target)<=2000 then
			local targetPos = GetOrigin(target)
			local targetHP = ( GetCurrentHP(target)*((100+(((GetMagicResist(target))-GetMagicPenFlat(myHero))*GetMagicPenPercent(myHero)))/100)+GetHPRegen(target)*6)
			local EPred = GetPredictionForPlayer(GetOrigin(myHero),target,GetMoveSpeed(target),1550,150,950,55,true,true)
			local WPred = GetPredictionForPlayer(GetOrigin(myHero),target,GetMoveSpeed(target),1450,250,650,250,false,true)
			local WallT
			if mapID==SUMMONERS_RIFT then
				local ChampionPos = GetOrigin(myHero)
				local EPos = Vector(WPred.PredPos.x,0,WPred.PredPos.z)
				local HPos = Vector(ChampionPos.x,0,ChampionPos.z)
				local WPos = HPos+(HPos-EPos)*(-650/GetDistance(HPos,EPos))
				WallT = MapPosition:inWall(Point(WPos.x,WPos.y,WPos.z))==true and 1 or 0
			else
				--No other maps supported atm
				WallT=0
			end
			if CD(KSN[key].a,KSN[key].b,KSN[key].c,KSN[key].d,KSN[key].e,KSN[key].f,KSN[key].g,KSN[key].h,KSN[key].i)==1 and Mana(KSN[key].a,KSN[key].c,KSN[key].g)==1 and targetHP < KSN[key].Damage + xIgnite and targetHP > KSN[key].Damage and GetDistance(target) < 600 and IRDY == 1 then
				CastTargetSpell(target, Ignite)
			end
			local myRange = LeBlanc.Keys.Priority:Value() == 1 and 750 or LeBlanc.Keys.Priority:Value() == 2 and 750 or LeBlanc.Keys.Priority:Value() == 3 and 650 or LeBlanc.Keys.Priority:Value() == 4 and 650 or LeBlanc.Keys.Priority:Value() == 5 and 950 or LeBlanc.Keys.Priority:Value() == 6 and 950
			if GetDistance(target) <= myRange then
				IOW.attacksEnabled = false
				--{"QWE", "QEW", "WEQ", "WQE", "EQW", "EWQ"}
				if LeBlanc.Keys.Priority:Value() == 1 then
					if (CD(1,0,0,n,0,n,0,0,n)==1 and Mana(1,0,0)==1 or --Q
						CD(1,n,0,n,n,n,0,n,1)==1 and Mana(1,0,0)==1 or --Q-Q(R)
						CD(1,n,1,n,n,n,n,n,n)==1 and Mana(1,1,0)==1 or --Q-Q(R)-W
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
						Q(target)
					elseif (CD(0,1,0,n,0,n,0,0,1)==1 or --ok
						CD(1,1,0,n,0,n,0,0,1)==1 and Mana(1,0,0)==1 or
						CD(n,1,1,n,0,n,n,0,1)==1 and Mana(0,1,0)==1 or
						CD(n,1,n,n,0,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(n,1,1,n,0,n,1,0,1)==1 and Mana(0,1,1)==1 or
						CD(0,1,1,n,0,n,n,0,1)==1 and Mana(0,1,0)==1 or --ok
						CD(1,1,1,n,0,n,n,0,1)==1 and Mana(1,1,0)==1 or
						CD(0,1,n,n,0,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(1,1,n,n,0,n,1,0,1)==1 and Mana(1,0,1)==1 or
						CD(1,1,1,n,n,n,1,n,1)==1 and Mana(1,1,1)==1 or
						CD(1,1,1,n,0,n,1,0,1)==1 and Mana(1,1,1)==1) then
						QR(target)
					elseif (CD(0,0,1,n,0,n,0,0,0)==1 and Mana(0,1,0)==1 or --ok
						CD(0,n,1,n,n,n,0,n,1)==1 and Mana(0,1,0)==1 or
						CD(0,n,1,n,n,n,n,n,0)==1 and Mana(0,1,0)==1 or
						CD(n,0,1,n,0,n,n,0,0)==1 and Mana(0,1,0)==1 or
						CD(n,n,1,n,n,n,1,n,0)==1 and Mana(0,1,1)==1 or
						CD(0,n,1,n,n,n,1,n,0)==1 and Mana(0,1,1)==1 or
						CD(n,0,1,n,0,n,1,0,0)==1 and Mana(0,1,1)==1 or
						CD(0,0,1,n,0,n,n,0,0)==1 and Mana(0,1,0)==1 or --ok
						CD(n,n,1,n,n,n,1,n,1)==1 and Mana(0,1,1)==1 or
						CD(0,0,1,n,0,n,1,0,0)==1 and Mana(0,1,1)==1 or
						CD(0,n,1,n,n,n,1,n,1)==1 and Mana(0,1,1)==1 or
						CD(0,1,1,n,0,n,1,0,1)==1 and Mana(0,1,1)==1) and WallT==0 then
						W(target) 
					elseif (CD(0,0,0,n,1,n,0,0,1)==1 or
						CD(0,0,1,n,1,n,0,0,1)==1 and Mana(0,1,0)==1 or
						CD(1,0,n,n,1,n,n,0,1)==1 and Mana(1,0,0)==1 or
						CD(n,0,n,n,1,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(1,0,n,n,1,n,1,0,1)==1 and Mana(1,0,1)==1 or
						CD(1,0,1,n,1,n,n,0,1)==1 and Mana(1,1,0)==1 or
						CD(n,0,0,n,1,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(n,0,1,n,1,n,1,0,1)==1 and Mana(0,1,1)==1 or
						CD(0,0,0,n,1,n,1,n,1)==1 and Mana(0,0,1)==1 or
						CD(1,0,1,n,1,n,1,0,1)==1 and Mana(1,1,1)==1) and WallT==0 then
						WR(target) 
					elseif CD(n,n,n,n,n,n,1,n,n)==1 and Mana(0,0,1)==1 then
						E(target) 
					elseif (CD(0,0,0,n,0,n,0,1,1)==1 or
						CD(0,0,0,0,0,0,0,1,1)==1 or
						CD(0,0,0,n,0,n,0,1,1)==1) then
						ER(target)
					else
						IOW.attacksEnabled = true
					end
				elseif LeBlanc.Keys.Priority:Value() == 2 then
					if (CD(1,0,0,n,0,n,0,0,n)==1 and Mana(1,0,0)==1 or --Q
						CD(1,n,0,n,n,n,0,n,1)==1 and Mana(1,0,0)==1 or --Q-Q(R)
						CD(1,n,1,n,n,n,n,n,n)==1 and Mana(1,1,0)==1 or --Q-Q(R)-W
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
						Q(target)
					elseif (CD(0,1,0,n,0,n,0,0,1)==1 or --ok
						CD(1,1,0,n,0,n,0,0,1)==1 and Mana(1,0,0)==1 or
						CD(n,1,1,n,0,n,n,0,1)==1 and Mana(0,1,0)==1 or
						CD(n,1,n,n,0,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(n,1,1,n,0,n,1,0,1)==1 and Mana(0,1,1)==1 or
						CD(0,1,1,n,0,n,n,0,1)==1 and Mana(0,1,0)==1 or --ok
						CD(1,1,1,n,0,n,n,0,1)==1 and Mana(1,1,0)==1 or
						CD(0,1,n,n,0,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(1,1,n,n,0,n,1,0,1)==1 and Mana(1,0,1)==1 or
						CD(1,1,1,n,n,n,1,n,1)==1 and Mana(1,1,1)==1 or
						CD(1,1,1,n,0,n,1,0,1)==1 and Mana(1,1,1)==1) then
						QR(target)
					elseif CD(n,n,n,n,n,n,1,n,n)==1 and Mana(0,0,1)==1 then
						E(target) 
					elseif CD(n,n,n,n,n,n,n,1,1)==1 then
						ER(target)
					elseif Mana(0,1,0)==1 and WallT==0 then
						if (CD(0,0,1,n,0,n,n,0,0)==1 or
							CD(0,n,1,n,n,n,n,n,1)==1 or
							CD(n,0,1,n,0,n,n,0,0)==1 or
							CD(n,n,1,n,n,n,n,n,0)==1 or
							CD(0,n,1,n,n,n,n,n,0)==1 or
							CD(n,0,1,n,0,n,n,0,0)==1 or
							CD(0,0,1,n,0,n,n,0,0)==1 or
							CD(n,n,1,n,n,n,n,n,1)==1 or
							CD(0,0,1,n,0,n,n,0,0)==1 or
							CD(0,n,1,n,n,n,n,n,1)==1 or
							CD(0,1,1,n,0,n,n,0,1)==1) then
								W(target) 
						end
					elseif CD(n,n,n,n,1,n,n,n,1)==1 and WallT==0 then
						WR(target) 
					else
						IOW.attacksEnabled = true
					end
				elseif LeBlanc.Keys.Priority:Value() == 3 then
					if (CD(0,0,1,n,0,n,0,0,0)==1 and Mana(0,1,0)==1 or --ok
						CD(0,n,1,n,n,n,0,n,1)==1 and Mana(0,1,0)==1 or
						CD(0,n,1,n,n,n,n,n,0)==1 and Mana(0,1,0)==1 or
						CD(n,0,1,n,0,n,n,0,0)==1 and Mana(0,1,0)==1 or
						CD(n,n,1,n,n,n,1,n,0)==1 and Mana(0,1,1)==1 or
						CD(0,n,1,n,n,n,1,n,0)==1 and Mana(0,1,1)==1 or
						CD(n,0,1,n,0,n,1,0,0)==1 and Mana(0,1,1)==1 or
						CD(0,0,1,n,0,n,n,0,0)==1 and Mana(0,1,0)==1 or --ok
						CD(n,n,1,n,n,n,1,n,1)==1 and Mana(0,1,1)==1 or
						CD(0,0,1,n,0,n,1,0,0)==1 and Mana(0,1,1)==1 or
						CD(0,n,1,n,n,n,1,n,1)==1 and Mana(0,1,1)==1 or
						CD(0,1,1,n,0,n,1,0,1)==1 and Mana(0,1,1)==1) and WallT==0 then
						W(target) 
					elseif (CD(0,0,0,n,1,n,0,0,1)==1 or
						CD(0,0,1,n,1,n,0,0,1)==1 and Mana(0,1,0)==1 or
						CD(1,0,n,n,1,n,n,0,1)==1 and Mana(1,0,0)==1 or
						CD(n,0,n,n,1,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(1,0,n,n,1,n,1,0,1)==1 and Mana(1,0,1)==1 or
						CD(1,0,1,n,1,n,n,0,1)==1 and Mana(1,1,0)==1 or
						CD(n,0,0,n,1,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(n,0,1,n,1,n,1,0,1)==1 and Mana(0,1,1)==1 or
						CD(0,0,0,n,1,n,1,n,1)==1 and Mana(0,0,1)==1 or
						CD(1,0,1,n,1,n,1,0,1)==1 and Mana(1,1,1)==1) and WallT==0 then
						WR(target) 
					elseif CD(n,n,n,n,n,n,1,n,n)==1 and Mana(0,0,1)==1 then
						E(target) 
					elseif CD(n,n,n,n,n,n,n,1,1)==1  then
						ER(target)
					elseif CD(1,n,n,n,n,n,n,n,n)==1 and Mana(1,0,0)==1 then
						Q(target)
					elseif (CD(0,1,0,n,0,n,0,0,1)==1 or --ok
						CD(1,1,0,n,0,n,0,0,1)==1 and Mana(1,0,0)==1 or
						CD(n,1,1,n,0,n,n,0,1)==1 and Mana(0,1,0)==1 or
						CD(n,1,n,n,0,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(n,1,1,n,0,n,1,0,1)==1 and Mana(0,1,1)==1 or
						CD(0,1,1,n,0,n,n,0,1)==1 and Mana(0,1,0)==1 or --ok
						CD(1,1,1,n,0,n,n,0,1)==1 and Mana(1,1,0)==1 or
						CD(0,1,n,n,0,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(1,1,n,n,0,n,1,0,1)==1 and Mana(1,0,1)==1 or
						CD(1,1,1,n,n,n,1,n,1)==1 and Mana(1,1,1)==1 or
						CD(1,1,1,n,0,n,1,0,1)==1 and Mana(1,1,1)==1) then
						QR(target)
					else
						IOW.attacksEnabled = true
					end
				elseif LeBlanc.Keys.Priority:Value() == 4 then
					if (CD(0,0,1,n,0,n,0,0,0)==1 and Mana(0,1,0)==1 or --ok
						CD(0,n,1,n,n,n,0,n,1)==1 and Mana(0,1,0)==1 or
						CD(0,n,1,n,n,n,n,n,0)==1 and Mana(0,1,0)==1 or
						CD(n,0,1,n,0,n,n,0,0)==1 and Mana(0,1,0)==1 or
						CD(n,n,1,n,n,n,1,n,0)==1 and Mana(0,1,1)==1 or
						CD(0,n,1,n,n,n,1,n,0)==1 and Mana(0,1,1)==1 or
						CD(n,0,1,n,0,n,1,0,0)==1 and Mana(0,1,1)==1 or
						CD(0,0,1,n,0,n,n,0,0)==1 and Mana(0,1,0)==1 or --ok
						CD(n,n,1,n,n,n,1,n,1)==1 and Mana(0,1,1)==1 or
						CD(0,0,1,n,0,n,1,0,0)==1 and Mana(0,1,1)==1 or
						CD(0,n,1,n,n,n,1,n,1)==1 and Mana(0,1,1)==1 or
						CD(0,1,1,n,0,n,1,0,1)==1 and Mana(0,1,1)==1) and WallT==0 then
						W(target) 
					elseif (CD(0,0,0,n,1,n,0,0,1)==1 or
						CD(0,0,1,n,1,n,0,0,1)==1 and Mana(0,1,0)==1 or
						CD(1,0,n,n,1,n,n,0,1)==1 and Mana(1,0,0)==1 or
						CD(n,0,n,n,1,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(1,0,n,n,1,n,1,0,1)==1 and Mana(1,0,1)==1 or
						CD(1,0,1,n,1,n,n,0,1)==1 and Mana(1,1,0)==1 or
						CD(n,0,0,n,1,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(n,0,1,n,1,n,1,0,1)==1 and Mana(0,1,1)==1 or
						CD(0,0,0,n,1,n,1,n,1)==1 and Mana(0,0,1)==1 or
						CD(1,0,1,n,1,n,1,0,1)==1 and Mana(1,1,1)==1) and WallT==0 then
						WR(target) 
					elseif (CD(1,0,0,n,0,n,0,0,n)==1 and Mana(1,0,0)==1 or --Q
						CD(1,n,0,n,n,n,0,n,1)==1 and Mana(1,0,0)==1 or --Q-Q(R)
						CD(1,n,1,n,n,n,n,n,n)==1 and Mana(1,1,0)==1 or --Q-Q(R)-W
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
						Q(target)
					elseif (CD(0,1,0,n,0,n,0,0,1)==1 or --ok
						CD(1,1,0,n,0,n,0,0,1)==1 and Mana(1,0,0)==1 or
						CD(n,1,1,n,0,n,n,0,1)==1 and Mana(0,1,0)==1 or
						CD(n,1,n,n,0,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(n,1,1,n,0,n,1,0,1)==1 and Mana(0,1,1)==1 or
						CD(0,1,1,n,0,n,n,0,1)==1 and Mana(0,1,0)==1 or --ok
						CD(1,1,1,n,0,n,n,0,1)==1 and Mana(1,1,0)==1 or
						CD(0,1,n,n,0,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(1,1,n,n,0,n,1,0,1)==1 and Mana(1,0,1)==1 or
						CD(1,1,1,n,n,n,1,n,1)==1 and Mana(1,1,1)==1 or
						CD(1,1,1,n,0,n,1,0,1)==1 and Mana(1,1,1)==1) then
						QR(target)
					elseif CD(n,n,n,n,n,n,1,n,n)==1 and Mana(0,0,1)==1 then
						E(target) 
					elseif CD(n,n,n,n,n,n,n,1,1)==1  then
						ER(target)
					else
						IOW.attacksEnabled = true
					end
				elseif LeBlanc.Keys.Priority:Value() == 5 then
					if CD(n,n,n,n,n,n,1,n,n)==1 and Mana(0,0,1)==1 then
						E(target) 
					elseif CD(n,n,n,n,n,n,n,1,1)==1 or
								CD(1,0,1,0,0,0,0,1,1)==1 then
						ER(target)
					elseif (CD(1,0,0,n,0,n,0,0,n)==1 and Mana(1,0,0)==1 or --Q
						CD(1,n,n,n,n,n,n,n,n)==1 and Mana(1,0,0)== 1 or
						CD(1,n,0,n,n,n,0,n,1)==1 and Mana(1,0,0)==1 or --Q-Q(R)
						CD(1,n,1,n,n,n,n,n,n)==1 and Mana(1,1,0)==1 or --Q-Q(R)-W
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
						Q(target)
					elseif CD(n,1,n,n,n,n,n,n,1)==1 then
						QR(target)
					elseif (CD(0,0,1,n,0,n,0,0,0)==1 and Mana(0,1,0)==1 or --ok
						CD(0,n,1,n,n,n,0,n,1)==1 and Mana(0,1,0)==1 or
						CD(0,n,1,n,n,n,n,n,0)==1 and Mana(0,1,0)==1 or
						CD(n,0,1,n,0,n,n,0,0)==1 and Mana(0,1,0)==1 or
						CD(n,n,1,n,n,n,1,n,0)==1 and Mana(0,1,1)==1 or
						CD(0,n,1,n,n,n,1,n,0)==1 and Mana(0,1,1)==1 or
						CD(n,0,1,n,0,n,1,0,0)==1 and Mana(0,1,1)==1 or
						CD(0,0,1,n,0,n,n,0,0)==1 and Mana(0,1,0)==1 or --ok
						CD(n,n,1,n,n,n,1,n,1)==1 and Mana(0,1,1)==1 or
						CD(0,0,1,n,0,n,1,0,0)==1 and Mana(0,1,1)==1 or
						CD(0,n,1,n,n,n,1,n,1)==1 and Mana(0,1,1)==1 or
						CD(0,1,1,n,0,n,1,0,1)==1 and Mana(0,1,1)==1) and WallT==0 then
						W(target) 
					elseif (CD(0,0,0,n,1,n,0,0,1)==1 or
						CD(0,0,1,n,1,n,0,0,1)==1 and Mana(0,1,0)==1 or
						CD(1,0,n,n,1,n,n,0,1)==1 and Mana(1,0,0)==1 or
						CD(n,0,n,n,1,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(1,0,n,n,1,n,1,0,1)==1 and Mana(1,0,1)==1 or
						CD(1,0,1,n,1,n,n,0,1)==1 and Mana(1,1,0)==1 or
						CD(n,0,0,n,1,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(n,0,1,n,1,n,1,0,1)==1 and Mana(0,1,1)==1 or
						CD(0,0,0,n,1,n,1,n,1)==1 and Mana(0,0,1)==1 or
						CD(1,0,1,n,1,n,1,0,1)==1 and Mana(1,1,1)==1) and WallT==0 then
						WR(target) 
					else
						IOW.attacksEnabled = true
					end
				elseif LeBlanc.Keys.Priority:Value() == 6 then
					if CD(n,n,n,n,n,n,1,n,n)==1 and Mana(0,0,1)==1 then
						E(target) 
					elseif CD(n,n,n,n,n,n,n,1,1)==1 then
						ER(target)
					elseif (CD(0,0,1,n,0,n,0,0,0)==1 and Mana(0,1,0)==1 or --ok
						CD(0,n,1,n,n,n,0,n,1)==1 and Mana(0,1,0)==1 or
						CD(0,n,1,n,n,n,n,n,0)==1 and Mana(0,1,0)==1 or
						CD(n,0,1,n,0,n,n,0,0)==1 and Mana(0,1,0)==1 or
						CD(n,n,1,n,n,n,1,n,0)==1 and Mana(0,1,1)==1 or
						CD(0,n,1,n,n,n,1,n,0)==1 and Mana(0,1,1)==1 or
						CD(n,0,1,n,0,n,1,0,0)==1 and Mana(0,1,1)==1 or
						CD(0,0,1,n,0,n,n,0,0)==1 and Mana(0,1,0)==1 or --ok
						CD(n,n,1,n,n,n,1,n,1)==1 and Mana(0,1,1)==1 or
						CD(0,0,1,n,0,n,1,0,0)==1 and Mana(0,1,1)==1 or
						CD(0,n,1,n,n,n,1,n,1)==1 and Mana(0,1,1)==1 or
						CD(0,1,1,n,0,n,1,0,1)==1 and Mana(0,1,1)==1) and WallT==0 then
						W(target) 
					elseif (CD(0,0,0,n,1,n,0,0,1)==1 or
						CD(0,0,1,n,1,n,0,0,1)==1 and Mana(0,1,0)==1 or
						CD(1,0,n,n,1,n,n,0,1)==1 and Mana(1,0,0)==1 or
						CD(n,0,n,n,1,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(1,0,n,n,1,n,1,0,1)==1 and Mana(1,0,1)==1 or
						CD(1,0,1,n,1,n,n,0,1)==1 and Mana(1,1,0)==1 or
						CD(n,0,0,n,1,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(n,0,1,n,1,n,1,0,1)==1 and Mana(0,1,1)==1 or
						CD(0,0,0,n,1,n,1,n,1)==1 and Mana(0,0,1)==1 or
						CD(1,0,1,n,1,n,1,0,1)==1 and Mana(1,1,1)==1) and WallT==0 then
						WR(target) 
					elseif (CD(1,0,0,n,0,n,0,0,n)==1 and Mana(1,0,0)==1 or --Q
						CD(1,n,0,n,n,n,0,n,1)==1 and Mana(1,0,0)==1 or --Q-Q(R)
						CD(1,n,1,n,n,n,n,n,n)==1 and Mana(1,1,0)==1 or --Q-Q(R)-W
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
						Q(target)
					elseif (CD(0,1,0,n,0,n,0,0,1)==1 or --ok
						CD(1,1,0,n,0,n,0,0,1)==1 and Mana(1,0,0)==1 or
						CD(n,1,1,n,0,n,n,0,1)==1 and Mana(0,1,0)==1 or
						CD(n,1,n,n,0,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(n,1,1,n,0,n,1,0,1)==1 and Mana(0,1,1)==1 or
						CD(0,1,1,n,0,n,n,0,1)==1 and Mana(0,1,0)==1 or --ok
						CD(1,1,1,n,0,n,n,0,1)==1 and Mana(1,1,0)==1 or
						CD(0,1,n,n,0,n,1,0,1)==1 and Mana(0,0,1)==1 or
						CD(1,1,n,n,0,n,1,0,1)==1 and Mana(1,0,1)==1 or
						CD(1,1,1,n,n,n,1,n,1)==1 and Mana(1,1,1)==1 or
						CD(1,1,1,n,0,n,1,0,1)==1 and Mana(1,1,1)==1) then
						QR(target)
					else
						IOW.attacksEnabled = true
					end
				end
			elseif GetDistance(target)>myRange and GetDistance(target)<1400 - GetMoveSpeed(target) * .5 then
				if 			CD(1,n,1,n,n,n,n,n,n)==1 and Mana(1,1,0)==1 and WallT==0 then 
					WL(target)
					Q(target)
				end	
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
		if LeBlanc.Keys.DoQ:Value() and Valid(target) and GetDistance(target)<=750 then
			if 			CD(1,n,n,n,n,n,n,n,n)==1 and Mana(1,n,n)==1 then Q(target)
			elseif 	CD(n,1,n,n,n,n,n,n,1)==1 and Mana(n,n,n)==1 then QR(target)
			end
		end
		if LeBlanc.Keys.DoE:Value() and Valid(target) and GetDistance(target)<=950 then
			if 			CD(n,n,n,n,n,n,1,n,n)==1 and Mana(n,n,1)==1 then E(target)
			elseif	CD(n,n,n,n,n,n,n,1,1 )==1 and Mana(n,n,n)==1 then ER(target)
			end
		end
	end
end
------------------------------------------
--OnProcessSpell
------------------------------------------
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
------------------------------------------
--OnTick
------------------------------------------
OnTick(function(myHero)
	n = GetEnemyHeroes()
	target = GetCurrentTarget()
	targetPos = GetOrigin(target)
	multi = LeBlanc.KS.Multi:Value() and 2 or 1
	DamageCalc()
	Variables()
	SpellSequence()
	if LeBlanc.Keys.Harass:Value() and target then IOW.attacksEnabled = false Harass() else IOW.attacksEnabled = true end
end)
------------------------------------------
--OnDraw
------------------------------------------
OnDraw(function(myHero)
	if LeBlanc.Draw.DrawON:Value() then Draw() end
end)
