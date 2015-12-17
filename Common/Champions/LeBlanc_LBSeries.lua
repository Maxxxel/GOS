require('Inspired')
if GetObjectName(myHero) ~= "Leblanc" then return end
require('MapPositionGOS')
require('Collision')

--version = 1.1
--some improvements

LeBlanc = MenuConfig("LeBlanc", "LeBlanc")
LeBlanc:Menu("Keys","Keys")
LeBlanc.Keys:Key("DoQ", "Q", string.byte("Q"))
LeBlanc.Keys:Key("DoE", "E", string.byte("E"))
LeBlanc.Keys:Key("Harass", "Harass", string.byte("X"))
LeBlanc.Keys:Key("Combo", "Combo", string.byte(" "))
LeBlanc.Keys:Boolean("Long", "Long Range Kills", true)
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
local xQ,xW,xE,xR,xRW,xRE
local xIgnite,IRDY = 0, 0
local nmy = {}
local KillText = {}
local Position = {"Out of Range", "in double W range", "in W range", "in Combo range"}
local colorText

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
	Q1RDY = GetCastName(myHero,_Q) == 'LeblancChaosOrb' 	and GetCastLevel(myHero,_Q) >= 1 	and CanUseSpell(myHero, _Q) == READY and 1 or 0 
	Q2RDY = GetCastName(myHero,_R) == 'LeblancChaosOrbM' 	and GetCastLevel(myHero,_R) >= 1 	and CanUseSpell(myHero, _R) == READY and 1 or 0
	W1RDY = GetCastName(myHero,_W) == 'LeblancSlide' 		and GetCastLevel(myHero,_W) >= 1 	and CanUseSpell(myHero, _W) == READY and 1 or 0 
	W2RDY = GetCastName(myHero,_W) == 'leblancslidereturn' 	and GetCastLevel(myHero,_W) >= 1 	and CanUseSpell(myHero, _W) == READY and 1 or 0
	W3RDY = GetCastName(myHero,_R) == 'LeblancSlideM' 		and GetCastLevel(myHero,_R) >= 1 	and CanUseSpell(myHero, _R)	== READY and 1 or 0
	W4RDY = GetCastName(myHero,_R) == 'leblancslidereturnm' and GetCastLevel(myHero,_R) >= 1 	and CanUseSpell(myHero, _R)	== READY and 1 or 0 
	E1RDY = GetCastName(myHero,_E) == 'LeblancSoulShackle' 	and GetCastLevel(myHero,_E) >= 1 	and CanUseSpell(myHero, _E)	== READY and 1 or 0 
	E2RDY = GetCastName(myHero,_R) == 'LeblancSoulShackleM' and GetCastLevel(myHero,_R) >= 1 	and CanUseSpell(myHero, _R)	== READY and 1 or 0 
	RRDY  = GetCastLevel(myHero,_R) >= 1 and CanUseSpell(myHero, _R) == READY and 1 or 0
	return (Q1RDY == a or a == n) and (Q2RDY == b or b == n) and (W1RDY == c or c == n) and (W2RDY == d or d == n) and (W3RDY == e or e == n) and (W4RDY == f or f == n) and (E1RDY == g or g == n) and (E2RDY == h or h == n) and (RRDY == i or i == n) and 1 or 0
end
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
--Cast Functions
------------------------------------------
local function Q(o)
	CastTargetSpell(o,_Q)
end
local function QR(o)
	CastTargetSpell(o,_R)
end
local function W(o)
	CastSkillShot(_W, GetOrigin(o))
end
local function W2()
	CastSpell(_W)
end
local function WR(o)
	local WPred = GetPredictionForPlayer(GetOrigin(myHero),o,GetMoveSpeed(o),1450,250,700,200,false,true)
	if WPred.HitChance == 1 then
		CastSkillShot(_R,WPred.PredPos.x,WPred.PredPos.y,WPred.PredPos.z)
	end
end
local function WR2()
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
	--print("SHORT")
	local WPred = GetOrigin(o)
	local ChampionPos = GetOrigin(myHero)
	local EPos = Vector(WPred.x, 0, WPred.z)
	local HPos = Vector(ChampionPos.x, 0, ChampionPos.z)
	local WPos = HPos + (HPos - EPos) * ( -650 / GetDistance(HPos, EPos))
	DrawCircle(WPos, 100,0,0,0xffff0000)
	if not MapPosition:inWall(Point(WPos.x,WPos.y,WPos.z)) then
		CastSkillShot(_W, WPred)
	end
end
local function WvL(o)
	--print("LONG")
	local WPred = GetOrigin(o)
	local ChampionPos = GetOrigin(myHero)
	local EPos = Vector(WPred.x, 0, WPred.z)
	local HPos = Vector(ChampionPos.x, 0, ChampionPos.z)
	local WPos = HPos + (HPos - EPos) * ( -650 / GetDistance(HPos, EPos))
	local WPos2 = HPos + (HPos - EPos) * ( -1300 / GetDistance(HPos, EPos))
	DrawCircle(WPos, 100,0,0,0xffff0000)
	DrawCircle(WPos2, 100,0,0,0xffff0000)
	if not MapPosition:inWall(Point(WPos.x,WPos.y,WPos.z)) and not MapPosition:inWall(Point(WPos2.x,WPos2.y,WPos2.z)) then
		CastSkillShot(_W, WPred)
		--print("Time "..GetTickCount())
		DelayAction(function()
			--print("Delay start "..GetTickCount())
			if W3RDY == 1 then 
				--print("OK "..GetTickCount())
				CastSkillShot(_R,WPred)
			end
		end, 500)
	end
end
------------------------------------------
--Harass
------------------------------------------
local function Harass()
	local Wall
	local WPred = GetPredictionForPlayer(GetOrigin(myHero),target,GetMoveSpeed(target),1450,250,700,200,false,true)
	local ChampionPos = GetOrigin(myHero)
	local EPos = Vector(WPred.PredPos.x, 0, WPred.PredPos.z)
	local HPos = Vector(ChampionPos.x, 0, ChampionPos.z)
	local WPos = HPos + (HPos - EPos) * ( -650 / GetDistance(HPos, EPos))
	Wall = MapPosition:inWall(Point(WPos.x, WPos.y, WPos.z)) == true and 1 or 0 
	if 		CD(1,n,1,n,n,n,n,n,n)==1 and Mana(1,1,n)==1 and Wall == 0 then 
		Q(target)
	elseif 	CD(n,n,1,n,n,n,n,n,n)==1 and Mana(0,1,0)==1 and Wall == 0 and ls == "Q" then
		W(target)
	elseif 	CD(n,n,n,1,n,n,n,n,n)==1 then W2()
	end
end
------------------------------------------
--Auto Ignite
------------------------------------------
local function AutoIgnite()
	for i = 1, #nmy do
		local Target = nmy[i]
		if Valid(Target) then
			local HP = GetCurrentHP(Target)
			if HP <= xIgnite and GetDistance(Target) <= 600 then
				if Q1RDY == 1 and HP <= xQ then
					Q(Target)
				elseif W1RDY == 1 and HP <= xW then
					if W2RDY == 0 then 
						W(Target)
					end
				else
					if IRDY == 1 then
						CastTargetSpell(Target, Ignite)
					end
				end
			end
		end
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
	for i = 1, #nmy do
		local enemy = nmy[i]
		if Valid(enemy) then
			local myMana = GetCurrentMana(myHero)
			local eHP 	= GetCurrentHP(enemy)
			local zQ 	= (Q1RDY == 1 and CalcDamage(myHero, enemy, 0, xQ)) or 0
    		local zW 	= (W1RDY == 1 and CalcDamage(myHero, enemy, 0, xW)) or 0
			local zE 	= (E1RDY == 1 and CalcDamage(myHero, enemy, 0, xE)) or 0
			local zQp 	= (Q1RDY == 1 and CalcDamage(myHero, enemy, 0, xQ)) or 0
			local zR 	= (RRDY == 1  and CalcDamage(myHero, enemy, 0, xR)) or 0
			local zRW 	= (RRDY == 1  and CalcDamage(myHero, enemy, 0, xRW)) or 0
			local zRE 	= (RRDY == 1  and CalcDamage(myHero, enemy, 0, xRE)) or 0
      		if eHP > (zQ + zQp * 2 + zW + zR + zE + xIgnite) then
				KillText[i] = "Harras Him!"
				colorText = ARGB(255,0,0,255)
			elseif eHP <= (zQ + (zQp*2) + zW + zR + zE + xIgnite) then
				if Mana(1,1,1) == 1 and eHP > (zQ + zW + zE + zQp) then
					KillText[i] = "Killable"
					colorText = ARGB(255,255,0,0)
				end
			else
				KillText[i] = "No Mana or Spells on CD"
			end
		end
	end
end
------------------------------------------
--Draw Stuff
------------------------------------------
local function Draw()
	if not IsDead(myHero) then
		if LeBlanc.Draw.DrawQ:Value() and (CD(1,n,n,n,n,n,n,n,n)==1 and Mana(1,0,0)==1) or CD(0,1,n,n,n,n,n,1)==1 then 
			DrawCircle(GetOrigin(myHero),750,0,0,0xffff0000)
		end
		if LeBlanc.Draw.DrawW:Value() and (CD(n,n,1,n,n,n,n,n,n)==1 and Mana(0,1,0)==1) or CD(n,n,0,n,1,n,n,1)==1 then 
			DrawCircle(GetOrigin(myHero),650,0,0,0xffff0000)
		end
		if LeBlanc.Draw.DrawQW:Value() and (CD(1,n,1,n,n,n,n,n,n)==1 and Mana(1,1,0)==1) or CD(1,n,0,n,1,n,n,1)==1 and Mana(1,0,0)==1 then 
			DrawCircle(GetOrigin(myHero),1400,0,0,0xffffff00)
			DrawCircle(GetOrigin(myHero),2050,0,0,0xffffff00)
		end
		if LeBlanc.Draw.DrawE:Value() and (CD(n,n,n,n,n,n,1,n,n)==1 and Mana(0,0,1)==1) or CD(n,n,n,n,n,0,1,1)==1 then 
			DrawCircle(GetOrigin(myHero),950,0,0,0xffffff00)
		end
		if LeBlanc.Draw.Spells:Value() then
			for i = 1, #nmy do
        local Unit = nmy[i]
        if Valid(Unit) then
        	local drawPos = GetOrigin(Unit)
  				local testPos = WorldToScreen(1, drawPos)
        	if KillText[i] then DrawText(KillText[i], 15, testPos.x, testPos.y, 0xffff0000) end
				end
			end
    end
	end
end
------------------------------------------
--Combo Stuff
------------------------------------------
local function ComboToText(Combo)
	local Result = ""
	for i = 1, #Combo do
		local spell = Combo[i]
		if spell == _Q then
			Result = Result.."Q->"
		elseif spell == _W then
			Result = Result.."W->"
		elseif spell == _E then
			Result = Result.."E->"
		elseif spell == _R then
			Result = Result.."R->"
		elseif spell == _IGNITE then
			Result = Result.."IGNITE->"
		end
	end
	return Result
end
local function ECanHit(unit)
	local EPred = GetPredictionForPlayer(GetOrigin(myHero),unit,GetMoveSpeed(unit),1550,150,950,55,true,false)
	local CollisionE = Collision(950, 1550, 150, 55)
	local CollisionCheck, Objects = CollisionE:__GetMinionCollision(myHero,Point(EPred.PredPos.x, EPred.PredPos.z),ENEMY)
	--print
	if EPred.PredPos and EPred.HitChance == 1 then
		if not CollisionCheck then
			return true
		end
	end
end
local function AnalyzeSituation(enemy)
	local B
	local Dist = GetDistance(enemy)
	if		(Dist < 950 and E1RDY == 1 and ECanHit(enemy)) or (Dist < 725) then --normalrange
		B = Position[4] 
	elseif 	Dist < 1475 and Dist > 725 and ((W1RDY == 1 and Mana(0,1,0) == 1) or W3RDY == 1) then --wrange
		B = Position[3]
	elseif 	Dist > 1475 and Dist < 2050 and W1RDY == 1 and Mana(0,1,0) == 1 and RRDY == 1 then --2wrange
		B = Position[2]
	else
		B = Position[1]
	end
	return B
end
local function GetDamage(Skill, enemy)
	if enemy then
		local TotalMagicDamage = 0
		local TrueDamage = 0
		if Q1RDY == 1 and (Skill == "doQ") then
			TotalMagicDamage = TotalMagicDamage + xQ
		end
		if W1RDY == 1 and (Skill == "doW") then
			TotalMagicDamage = TotalMagicDamage + xW
		end
		if E1RDY == 1 and (Skill == "doE") then
			TotalMagicDamage = TotalMagicDamage + xE
		end
		if 		RRDY == 1 and (Skill == "doR") and (Q2RDY == 1 or Q1RDY == 1) then
			TotalMagicDamage = TotalMagicDamage + xR
		else
			if 	RRDY == 1 and (Skill == "doR") and (W3RDY == 1 or W1RDY == 1) then
				TotalMagicDamage = TotalMagicDamage + xRW
			else
				if 	RRDY == 1 and (Skill == "doR") and (E2RDY == 1 or E1RDY == 1) then
					TotalMagicDamage = TotalMagicDamage + xRE
				end
			end
		end
		TrueDamage = CalcDamage(myHero, enemy, 0, TotalMagicDamage)
		if IRDY == 1 and Skill == "IGNITE" then
			TrueDamage = TrueDamage + xIgnite
		end
		return TrueDamage
	end
end
local function ComboGetDamage(Skills, enemy)
	local TotalDamage = 0
	if Skills then
		for i, spell in ipairs(Skills) do
			TotalDamage = TotalDamage + GetDamage(spell, enemy)
		end
	end
	return TotalDamage
end
local function KillCheck(enemy, Combo)
	local health = GetCurrentHP(enemy)
	local ComboDamage
	ComboDamage = ComboGetDamage(Combo, enemy)
	return ComboDamage > health and true or false
end
local function CCCheck(enemy)
	if (E1RDY == 1 and Mana(0,0,1) == 1) or E2RDY == 1 then --we can CC
		local eHP = GetCurrentHP(enemy)
		local mHP = GetCurrentHP(myHero)
		local eMS = GetMoveSpeed(enemy)
		local mMS = GetMoveSpeed(myHero)
		if mHP < eHP and mHP < 150 then --if your low on HP CC him
			return true
		else
			if mMS > eMS * 0.75 and GetDistance(enemy) + (eMS * 0.75 - mMS) * 2 < 950 and GetDistance(enemy) + (eMS * 0.75 - mMS) * 2 < 750 then --if enemy will be slower than you after E and u can cast A Q also do it. Else leave it.
				return true
			else
				return false
			end
		end
	else
		return false
	end
end
local function GetBestCombo(enemy)
	local distance = GetDistance(enemy)
	local resultB = AnalyzeSituation(enemy)
	local bestcombo = {}
	local checkcombo = {}
	if resultB == Position[1] then --Out of range
		bestCombo = {}
	elseif resultB == Position[2] and LeBlanc.Keys.Long:Value() then --2W range
		checkcombo = {"doQ", "doE", "IGNITE"} --set highest Damage
		if KillCheck(enemy, checkCombo) then --check if enemy can be killed with Combo
			--print("killable with "..checkcombo)
			bestcombo = {"doW", "doR" ,"doQ", "doE", "IGNITE"}
			----print("Kill Long")
------------------------------DISABLED BECAUSE USELESS ATM (except u want LeBlanc to use Spells to poke enemy long range)------------------------------
		--[[
		else
			if CCCheck(enemy) then --check if you need to E the enemy
				--print("CCable with "..checkcombo)
				bestcombo = {"doW", "doR" ,"doE", "doQ"}
				----print("CC Long")
			else
				if LeBlanc.Keys.Priority:Value() == (1 or 2 or 4) then --Cast Q before E
					bestcombo = {"doW", "doR" ,"doQ", "doE"}
					--print("QE Long")
				else
					bestcombo = {"doW", "doR" ,"doE", "doQ"}
					--print("EQ Long")
				end
			end
		--]]
		end
	elseif resultB == Position[3] then --1W range
		if W1RDY == 1 then
			checkcombo = {"doQ", "doR", "doE", "IGNITE"}
		elseif W1RDY == 0 and W3RDY == 1 then
			checkcombo = {"doQ", "doE", "IGNITE"}
		end
		if KillCheck(enemy, checkcombo) then
			--print("killable with "..checkcombo)
			if W1RDY == 1 then
				bestcombo = {"doW", "doQ", "doR", "doE", "IGNITE"}
				----print("Kill short 1")
			elseif W1RDY == 0 and W3RDY == 1 then
				bestcombo = {"doR", "doQ", "doE", "IGNITE"}
				----print("Kill short 2")
			end
		else
			if CCCheck(enemy) then
				if E1RDY == 1 then
					bestcombo = {"doW", "doE", "doQ", "doR"}
					----print("CC short 1")
				end
			else
				if W1RDY == 1 then
					if LeBlanc.Keys.Priority:Value() == (1 or 2) then
						bestcombo = {"doW", "doQ", "doR", "doE"}
						----print("QRE short")
					elseif LeBlanc.Keys.Priority:Value() == 3 then --Cast E then
						bestcombo = {"doW", "doE", "doQ", "doR"}
						----print("REQ short")
					elseif LeBlanc.Keys.Priority:Value() == 4 then --Cast Q then
						bestcombo = {"doW", "doQ", "doR", "doE"}
						----print("RQE short")
					elseif LeBlanc.Keys.Priority:Value() == (5 or 6) then --Cast E then
						bestcombo = {"doW", "doE", "doR", "doQ"}
						----print("ERQ short")
					end
				elseif W1RDY == 0 and W3RDY == 1 then
					if LeBlanc.Keys.Priority:Value() == (1 or 2 or 4) then --Cast Q before all
						bestcombo = {"doR" ,"doQ", "doE"}
						----print("QE short")
					elseif LeBlanc.Keys.Priority:Value() == (3 or 5 or 6) then --Cast W before all
						bestcombo = {"doR" ,"doE", "doQ"}
						----print("EQ short")
					end
				end
			end
		end
	elseif resultB == Position[4] then --full combo range
		if multi == 2 then 
			checkcombo = {"doE", "doQ", "doR", "doW", "IGNITE"} 
		else
			checkcombo = {"doQ", "doR", "doW", "doE", "IGNITE"}
		end
		if KillCheck(enemy, checkcombo) then
			bestcombo = checkcombo
			----print("Kill")
		else
			if CCCheck(enemy) then --check if you need to E the enemy
				if E1RDY == 1 then
					bestcombo = {"doE", "doQ", "doR", "doW"}
					----print("CC 1")
				elseif E1RDY == 0 and E2RDY == 1 then
					bestcombo = {"doR", "doQ", "doW"}
					----print("CC 2")
				end
			else
				if LeBlanc.Keys.Priority:Value() == 1 then --Cast Q before all
					bestcombo = {"doQ" ,"doR", "doW", "doE"}
					----print("QRWE")
				elseif LeBlanc.Keys.Priority:Value() == 2 then
					bestcombo = {"doQ", "doR", "doE", "doW"}
					----print("QREW")
				elseif LeBlanc.Keys.Priority:Value() == 3 then
					bestcombo = {"doW" ,"doR", "doE", "doQ"}
					----print("WREQ")
				elseif LeBlanc.Keys.Priority:Value() == 4 then
					bestcombo = {"doW" ,"doR", "doQ", "doE"}
					----print("WRQE")
				elseif LeBlanc.Keys.Priority:Value() == 5 then
					bestcombo = {"doE" ,"doR", "doQ", "doW"}
					----print("ERQW")
				elseif LeBlanc.Keys.Priority:Value() == 6 then
					bestcombo = {"doE" ,"doR", "doW", "doQ"}
					----print("ERWQ")
				end
			end
		end
	else
		bestcombo = nil
	end
	return bestcombo
end
local function CastSkill(Skill, enemy)
	if Skill == "doQ" then
		if GetDistanceSqr(GetOrigin(enemy)) > 562500 or Q1RDY == 0 then
			----print("Out of Q range")
			return false
		end
			----print("Doing Q")
		Q(enemy)
		return true
	elseif Skill == "doW" then
		local resultB = AnalyzeSituation(enemy)
		if (resultB == Position[1]) or W1RDY == 0 then
			----print("Out of 2W range")
			return false
		elseif resultB == Position[2] then
			WvL(enemy)
			return true
		elseif resultB == Position[3] then
			----print("Doing 2W")
			WL(enemy)
			return true
		else
			local WPred = GetPredictionForPlayer(GetOrigin(myHero),enemy,GetMoveSpeed(enemy),1450,250,650, 125,false,true)
			if WPred.HitChance == 1 and not MapPosition:inWall(Point(WPred.PredPos.x, WPred.PredPos.y, WPred.PredPos.z)) then
				----print("Doing W")
				W(enemy)
				return true
			else
				return false
			end
		end
	elseif Skill == "doE"  then
		if GetDistanceSqr(GetOrigin(enemy)) > 902500 or E1RDY == 0 then
			----print("Out of E range")
			return false
		end
		local EPred = GetPredictionForPlayer(GetOrigin(myHero),enemy,GetMoveSpeed(enemy),1550,150,950,55,true,false)
		local CollisionE = Collision(950, 1550, 150, 55)
		local CollisionCheck, Objects = CollisionE:__GetMinionCollision(myHero,Point(EPred.PredPos.x, EPred.PredPos.z),ENEMY)
		--print
		if EPred.PredPos and EPred.HitChance == 1 and not CollisionCheck then
			----print("Doing E")
			CastSkillShot(_E, EPred.PredPos)
			return true
		else
			return false
		end
	elseif Skill == "doR" then
		local Distance = GetDistanceSqr(GetOrigin(enemy))
		if ls == "Q" or Q2RDY == 1 then
			if Distance <= 562500 then
				----print("Doing RQ")
				CastTargetSpell(enemy, _R)
				return true
			else
				----print("Out of RQ range")
				return false
			end
		elseif ls == "W" or W3RDY == 1 then
			local resultB = AnalyzeSituation(enemy)
			if resultB == Position[1] then
				----print("Out of 2WR range")
				return false
			elseif resultB == (Position[2] or Position[3]) then
				----print("Doing 2WR")
				WvL(enemy)
				return true
			else
				local WPred = GetPredictionForPlayer(GetOrigin(myHero),enemy,GetMoveSpeed(enemy),1450,250,650, 125,false,true)
				if WPred.HitChance == 1 and not MapPosition:inWall(Point(WPred.PredPos.x, WPred.PredPos.y, WPred.PredPos.z)) then
					----print("Doing WR")
					WR(enemy)
					return true
				else
					return false
				end
			end
		elseif ls == "E" or E2RDY == 1 then
			if Distance <= 902500 then
				local EPred = GetPredictionForPlayer(GetOrigin(myHero),enemy,GetMoveSpeed(enemy),1550,150,950,55,true,true)
				local CollisionE = Collision(950, 1550, 150, 55)
				local CollisionCheck, Objects = CollisionE:__GetMinionCollision(myHero,Point(EPred.PredPos.x, EPred.PredPos.z),ENEMY)
				--print
				if EPred.PredPos and EPred.HitChance == 1 and not CollisionCheck then
					----print("Doing ER")
					CastSkillShot(_E, EPred.PredPos)
					return true
				else
					----print("ER blocked")
					return false
				end
			else
				----print("Out of ER range")
				return false
			end
		end
	elseif Skill == "IGNITE" then
		if IRDY == 1 then
			CastTargetSpell(enemy, Ignite)
			return true
		else
			return false
		end
	end
end
local function ExecuteCombo(Skills, enemy)
	for i, spell in ipairs(Skills) do
		CastSkill(spell, enemy)
	end
end
------------------------------------------
--Combo
------------------------------------------
local function Combo()
	if target and Valid(target) and not IsDead(myHero) and IsInDistance(target, 2050) then
		local BestCombo = GetBestCombo(target)
		----print(BestCombo)
		ExecuteCombo(BestCombo, target)
	elseif IsDead(target) and not LeBlanc.Misc.MR:Value() then
		if W4RDY == 1 then
			WR2()
		elseif W2RDY == 1 and W4RDY ~= 1 then
			W2()
		end
	elseif LeBlanc.Misc.MR:Value() then
		if W4RDY == 1 then
			WR2()
		elseif W2RDY == 1 and W4RDY ~= 1 then
			W2()
		end
	end
end
------------------------------------------
--Variables
------------------------------------------
local function SetVariables()
	nmy = GetEnemyHeroes()
	target = GetCurrentTarget()
	multi = LeBlanc.KS.Multi:Value() and 2 or 1
end
------------------------------------------
--OnProcessSpell
------------------------------------------
OnProcessSpellComplete(function(unit, spell)
	if unit and spell and GetObjectName(unit) == GetObjectName(myHero) then
		ls = spell.name == 'LeblancChaosOrb' and 'Q' or spell.name == 'LeblancChaosOrbM' and 'QR' or spell.name == 'LeblancSlide' and 'W' or spell.name == 'LeblancSlideM' and 'WR' or spell.name == 'LeblancSoulShackle' and 'E' or spell.name == 'LeblancSoulShackleM' and 'ER' or ls
	end
end)
------------------------------------------
--OnTick
------------------------------------------
OnTick(function(myHero)
	SetVariables()
	DamageCalc()
	if LeBlanc.Keys.Combo:Value() then
		Combo()
	elseif LeBlanc.Keys.Harass:Value() and target and GetDistance(target) < 750 then 
		IOW.attacksEnabled = false 
		Harass() 
	elseif LeBlanc.Keys.DoQ:Value() and target and Valid(target) and GetDistance(target) <= 750 then
		if 		CD(1,n,n,n,n,n,n,n,n)==1 and Mana(1,n,n)==1 then Q(target)
		elseif 	CD(n,1,n,n,n,n,n,n,1)==1 and Mana(n,n,n)==1 then QR(target)
		end
	elseif LeBlanc.Keys.DoE:Value() and target and Valid(target) and GetDistance(target) <= 950 then
		if 		CD(n,n,n,n,n,n,1,n,n)==1 and Mana(n,n,1)==1 then E(target)
		elseif	CD(n,n,n,n,n,n,n,1,1 )==1 and Mana(n,n,n)==1 then ER(target)
		end
	else 
		IOW.attacksEnabled = true 
	end
	if LeBlanc.KS.Ignite:Value() then
		AutoIgnite()
	end
end)
------------------------------------------
--OnDraw
------------------------------------------
OnDraw(function(myHero)
	if LeBlanc.Draw.DrawON:Value() then 
		Draw() 
	end
end)
