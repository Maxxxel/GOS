if GetObjectName(myHero) ~= "Katarina" then return end

local Name = "Vals Katarina - GOS Edition"
local Version = "1"
local Credits = "Valdorian my friend"

require "DamageLib"
require("Inspired")

----Globals----
local colorcyan, coloryellow, cc, colorred, colororange, colorgreen = 0xFF00FFFF, 0xFFFFFF00, 0, 0xffff0000, 0xffffc800, 0xff00ff00
--Spell Stuff--
local QRDY, WRDY, ERDY, RRDY = 0, 0, 0, 0
local locus = false
local Rtimer = 0
local BC, HG = 0, 0
--Target Stuff--
local target
local JumpSpotToDraw
--Tables--
local Minions = {}
local Enemies = {}
local KSK = {}
local GotDaggered = {}
local IsBuffed = {}
local goodSpots = {}
local WardsPlaced = {}
--Auto Pot--
local wUsedAt, vUsedAt, Pot_Timer, bluePil, bUsedAt = 0, 0, GetTickCount(), nil, 0
--Ignite Values--
local summonerNameOne = GetCastName(myHero,SUMMONER_1)
local summonerNameTwo = GetCastName(myHero,SUMMONER_2)
local Ignite = (summonerNameOne:lower():find("summonerdot") and SUMMONER_1 or (summonerNameTwo:lower():find("summonerdot") and SUMMONER_2 or nil))
local IRDY = 0

-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------

	Katarina = MenuConfig("Katarina", "Katarina")
	Katarina:Menu("Hotkeys", "1. Hotkeys")
	Katarina.Hotkeys:Key("Combo", "Combo", string.byte(" "))
	Katarina.Hotkeys:Key("Harass", "Harass", string.byte("X"))
	Katarina.Hotkeys:Key("Farm", "Lasthit", string.byte("T"))
	Katarina.Hotkeys:Key("Espell", "Escape/Ward Jump", string.byte("E"))
	
	Katarina:Menu("Options", "2. Main options")
	Katarina.Options:Boolean("Killsteal", "Killsteal", true)
	Katarina.Options:Boolean("Move_Mouse", "Move to Mouse", true)
	Katarina.Options:Boolean("Auto_Zonyas", "Auto Zhonyas", true)
	Katarina.Options:Slider("healthpercent", "Min. health% to use auto Zhonyas", 25, 0, 100, 1)
	Katarina.Options:Boolean("Auto_W", "Auto W", true)

	Katarina:Menu("Draw", "3. Draw options")
	Katarina.Draw:Boolean("Draw_Stuns", "Draw Stuns", true)
	Katarina.Draw:DropDown("Draw_Stuns_Color", "Stun Color", 1, {"Blue", "Yellow", "Red", "Orange", "Green"})
	Katarina.Draw:Slider("Draw_Stuns_Radius", "Stun Radius", 50, 10, 100, 1)
	Katarina.Draw:Slider("Draw_Stuns_Width", "Stun Width", 0, 0, 20, 1)
	Katarina.Draw:Boolean("Draw_Escapes", "Draw Escapes", true)
	Katarina.Draw:DropDown("Draw_Escapes_Color", "Escape Color", 2, {"Blue", "Yellow", "Red", "Orange", "Green"})
	Katarina.Draw:Slider("Draw_Escapes_Radius", "Escape Radius", 40, 10, 100, 1)
	Katarina.Draw:Slider("Draw_Escapes_Width", "Escape Width", 0, 0, 20, 1)
	Katarina.Draw:Boolean("E_helper", "Use E helper", true)
	Katarina.Draw:DropDown("E_helper_Color", "Jumpspot Color", 5, {"Blue", "Yellow", "Red", "Orange", "Green"})
	Katarina.Draw:Slider("E_helper_Radius", "Jumpspot Radius", 50, 10, 100, 1)
	Katarina.Draw:Slider("E_helper_Width", "Jumpspot Width", 0, 0, 20, 1)
	Katarina.Draw:Boolean("Roamhelper", "Roamhelper", true)
	Katarina.Draw:Boolean("Healthpercent", "Draw health %", true)
	Katarina.Draw:Boolean("Show_ranges", "Show your own range", true)
	Katarina.Draw:DropDown("Show_ranges_Color", "Range Color", 2, {"Blue", "Yellow", "Red", "Orange", "Green"})
	Katarina.Draw:Slider("Show_ranges_Width", "Range Width", 0, 0, 20, 1)
	Katarina.Draw:Boolean("Show_target", "Show your current target", true)
	Katarina.Draw:DropDown("Show_target_Color", "Target Color", 4, {"Blue", "Yellow", "Red", "Orange", "Green"})
	Katarina.Draw:Slider("Show_target_Radius", "Target Radius", 75, 10, 100, 1)
	Katarina.Draw:Slider("Show_target_Width", "Target Width", 0, 0, 20, 1)
	Katarina.Draw:Boolean("DrawLS", "Show killable minions", true)
	Katarina.Draw:DropDown("DrawLS_Color", "Minions Color", 3, {"Blue", "Yellow", "Red", "Orange", "Green"})
	Katarina.Draw:Slider("DrawLS_Size", "Minions Text Size", 8, 0, 20, 1)
	
	Katarina:Menu("Misc", "4. Misc options")
	Katarina.Misc:Boolean("BreakUltKS", "Break ult for Killsteal", true)
	Katarina.Misc:Boolean("StopUlt", "Stop ult when nobody is in range", false)
	Katarina.Misc:Boolean("UseItemsCombo", "Auto cast Items during combo", true)
	Katarina.Misc:Slider("CalcR", "Calculated R hits", 5, 0, 10, 1)
	Katarina.Misc:Boolean("EFarm", "E for Farm", false)
	Katarina.Misc:Slider("EFarmRange", "E Farm Range", 300, 0, 700, 10)
	Katarina.Misc:Boolean("AdvancedFarm", "Advanced Farm Mechs", false)
	Katarina.Misc:Boolean("WardEscape", "Use ward if no spot", true)

	Katarina:Menu("AutoLevel", "5. AutoLevel")
	Katarina.AutoLevel:Boolean("AutoLevel", "Auto level spells", false)
	Katarina.AutoLevel:DropDown("Spellorder", "Spell order", 1, {"(1-3: Q-W-E), Q-W-E", "(1-3: Q-W-E), W-Q-E"})
	
	Katarina:Menu("Pots", "6. Auto potions")
	Katarina.Pots:Boolean("Health_Potion", "Health Potions", true)
	Katarina.Pots:Boolean("Chrystalline_Flask", "Refillable Potion", true)
	Katarina.Pots:Boolean("Elixir_of_Fortitude", "Elixir of Iron", true)
	Katarina.Pots:Boolean("Biscuit", "Biscuit", true)
	Katarina.Pots:Slider("Health_Potion_Value", "Health Potion Value", 75, 0, 100, 1)
	Katarina.Pots:Slider("Chrystalline_Flask_Value", "Refillable Potion", 75, 0, 100, 1)
	Katarina.Pots:Slider("Elixir_of_Fortitude_Value", "Elixir of Iron", 30, 0, 100, 1)
	Katarina.Pots:Slider("Biscuit_Value", "Biscuit Value", 60, 0, 100, 1)

	Katarina:Empty("lb01", 1)
	Katarina:Info("lb02", "Katarina ver."..tostring(Version))
	Katarina:Info("lb03", "by Valdorian/Maxxxel")


local function CountEnemyHeroInRange(range)
	local eEnemies = {}
	for i = 1, #Enemies do
		local enemy = Enemies[i]
		if enemy and not IsDead(enemy) then
			if GetDistance(enemy) <= range then
				table.insert(eEnemies, enemy)
			end
		end
	end

	return #eEnemies
end

local function GetEnemyMinionsInRange(object, range)
	object = object or myHero
	range = range or 700
	local eMinions = {}
	for aMinion = 0, #minionManager.objects do
		local aminion = minionManager.objects[aMinion]
		if aminion and not GetObjectBaseName(aminion):lower():find("dummy") and not IsDead(aminion) and  GetTeam(aminion) ~= GetTeam(myHero) and GetDistance(aminion, object) < range then --all living Minions that are not friendly into a list
			table.insert(eMinions, aminion)
		end
	end
	return eMinions
end

local function validEntry(data, array)
	local valid = {}
	if #array > 0 then
	 	for i = 1, #array do
	 		if array[i] then
	  			valid[array[i]] = true
	  		end
	 	end
	 	if valid[data] then
	  		return false
	 	else
	  		return true
	 	end
	else
		return true
	end
end 	

local function GetJumpableSpots(object, range)
	object = object or myHero
	range = range or 1000
	local AllObjs = {}
	for index = 1, #minionManager.objects do
		local checkObj = minionManager.objects[index]
		if checkObj and not IsDead(checkObj) and IsVisible(checkObj) and GetDistance(checkObj, object) < range then
			table.insert(AllObjs, checkObj)
		end
	end
	for i = 1, heroManager.iCount do
		local Hero = heroManager:getHero(i)
		if Hero and Hero ~= object and not IsDead(Hero) and IsVisible(Hero) and GetDistance(Hero, object) <= range then
			table.insert(AllObjs, Hero)
		end
	end
	for index = 1, #WardsPlaced do
		local checkObj = WardsPlaced[index]
		if checkObj and checkObj ~= object and not IsDead(checkObj) and GetDistance(checkObj, object) <= range then
			table.insert(AllObjs, checkObj)
		end
	end
	return AllObjs
end

local function GetCDs()
	QRDY = GetCastLevel(myHero, _Q) > 0 and CanUseSpell(myHero, _Q) == 0 and 1 or 0
	WRDY = GetCastLevel(myHero, _W) > 0 and CanUseSpell(myHero, _W) == 0 and 1 or 0
	ERDY = GetCastLevel(myHero, _E) > 0 and CanUseSpell(myHero, _E) == 0 and 1 or 0
	RRDY = GetCastLevel(myHero, _R) > 0 and (CanUseSpell(myHero, _R) == 8 or CanUseSpell(myHero, _R) == 0) and 1 or 0
	IRDY = Ignite and CanUseSpell(myHero, Ignite) == 0 and 1 or 0
	--Bilgewater
	BC = 	BC == 0 and GetItemSlot(myHero, 3144) == 6 and CanUseSpell(myHero, 6) == 0 and 1 or 
			BC == 0 and GetItemSlot(myHero, 3144) == 7 and CanUseSpell(myHero, 7) == 0 and 1 or 
			BC == 0 and GetItemSlot(myHero, 3144) == 8 and CanUseSpell(myHero, 8) == 0 and 1 or 
			BC == 0 and GetItemSlot(myHero, 3144) == 9 and CanUseSpell(myHero, 9) == 0 and 1 or 
			BC == 0 and GetItemSlot(myHero, 3144) == 10 and CanUseSpell(myHero, 10) == 0 and 1 or 
			BC == 0 and GetItemSlot(myHero, 3144) == 11 and CanUseSpell(myHero, 11) == 0 and 1 or 
			BC == 1 and 1 or 0
	--Hextech Gunblade
	HG = 	HG == 0 and GetItemSlot(myHero, 3146) == 6 and CanUseSpell(myHero, 6) == 0 and 1 or 
			HG == 0 and GetItemSlot(myHero, 3146) == 7 and CanUseSpell(myHero, 7) == 0 and 1 or 
			HG == 0 and GetItemSlot(myHero, 3146) == 8 and CanUseSpell(myHero, 8) == 0 and 1 or 
			HG == 0 and GetItemSlot(myHero, 3146) == 9 and CanUseSpell(myHero, 9) == 0 and 1 or 
			HG == 0 and GetItemSlot(myHero, 3146) == 10 and CanUseSpell(myHero, 10) == 0 and 1 or 
			HG == 0 and GetItemSlot(myHero, 3146) == 11 and CanUseSpell(myHero, 11) == 0 and 1 or 
			HG == 1 and 1 or 0
end

local function TargetSelector()
	local t, p = nil, 10000
	for i = 1, #Enemies do
		local enemy = Enemies[i]
	  	if enemy then
			local prio = GetDistance(enemy, GetMousePos())
			if ValidTarget(enemy, math.max(QRDY * 700, WRDY * 375, ERDY * 700, RRDY * 550, 240)) and prio < p then
		  		target = enemy
		  		p = prio
			end
	  	end
	end
end

local function AutoPotions()
	if not bluePill and not locus then
		if Katarina.Pots.Health_Potion:Value() and GetCurrentHP(myHero) < GetMaxHP(myHero) * (Katarina.Pots.Health_Potion_Value:Value() * .01) and GetTickCount() > wUsedAt + 15000 then
			local slot = GetItemSlot(myHero, 2003)
			if slot ~= 0 then CastTargetSpell(myHero, slot) end
			wUsedAt = GetTickCount()
		elseif Katarina.Pots.Chrystalline_Flask:Value() and GetCurrentHP(myHero) < GetMaxHP(myHero) * (Katarina.Pots.Chrystalline_Flask_Value:Value() * .01) and GetTickCount() > vUsedAt + 12000 then
			local slot = GetItemSlot(myHero, 2031)
			if slot ~= 0 then CastTargetSpell(myHero, slot) end
			vUsedAt = GetTickCount()
		elseif Katarina.Pots.Biscuit:Value() and GetCurrentHP(myHero) < GetMaxHP(myHero) * (Katarina.Pots.Biscuit_Value:Value() * .01) and GetTickCount() > bUsedAt + 15000 then
			local slot1, slot2 = GetItemSlot(myHero, 2009), GetItemSlot(myHero, 2010)
			if slot1 ~= 0 then CastTargetSpell(myHero, slot1) end
			if slot2 ~= 0 then CastTargetSpell(myHero, slot2) end
			bUsedAt = GetTickCount()
		elseif Katarina.Pots.Elixir_of_Fortitude:Value() and GetCurrentHP(myHero) < GetMaxHP(myHero) * (Katarina.Pots.Elixir_of_Fortitude_Value:Value() * .01) then 
			local slot = GetItemSlot(myHero, 2138)
			if slot ~= 0 then CastTargetSpell(myHero, slot) end
		end
	end
	if (GetTickCount() < Pot_Timer + 5000) then 
		bluePill = nil 
	end 
end

local function LocusCheck()
	local num = CountEnemyHeroInRange(500)
	local locusV = ((GetTickCount() - Rtimer > 2750) or IsDead(myHero)) and 1 or 0
	locus = locusV ~= 1
	if locus and num == 0 and Katarina.Misc.StopUlt:Value() then
		locus = false
		MoveToXYZ(GetMousePos())
	end
end

local function GotDaggerInHisRottenBody(tar)
	local ID = tar and GetNetworkID(tar)
	return tar and ID and (GotDaggered[ID] or 0) > 0
end

local function WardReady()
	local slot = 0
	if slot == 0 then
		for i = 6, 12 do
			slot =  slot == 0 and GetItemSlot(myHero, 3340) == i and CanUseSpell(myHero, i) == 0 and i or --trinket
					slot == 0 and GetItemSlot(myHero, 2049) == i and CanUseSpell(myHero, i) == 0 and i or --SS
					slot == 0 and GetItemSlot(myHero, 2045) == i and CanUseSpell(myHero, i) == 0 and i or --SS2
					slot == 0 and GetItemSlot(myHero, 2043) == i and CanUseSpell(myHero, i) == 0 and i or --VWard
					slot == 0 and GetItemSlot(myHero, 2301) == i and CanUseSpell(myHero, i) == 0 and i or 
					slot == 0 and GetItemSlot(myHero, 2302) == i and CanUseSpell(myHero, i) == 0 and i or 
					slot == 0 and GetItemSlot(myHero, 2303) == i and CanUseSpell(myHero, i) == 0 and i or slot
		end
	end
	return slot
end

local function DoWard(slot, x, y)
	local MyMousePos = not x and GetMousePos() or GetOrigin(x)
    local MyPos = GetOrigin(myHero)
    local MyPosVector = Vector(MyPos.x, MyPos.y, MyPos.z)
    local MyMousePosVector = Vector(MyMousePos.x, MyMousePos.y, MyMousePos.z)
    local distance = 650
    local distance2 = GetDistance(MyMousePosVector)
    local CastPos = nil
    if distance2 <= distance then
		CastPos = MyMousePosVector
    elseif distance2 > distance then
    	CastPos = MyPosVector -( MyPosVector - MyMousePosVector) * (distance / distance2)
    end
    if CastPos and slot then
    	CastSkillShot(slot, CastPos)
    end
    if y then
    	return CastPos
    end
end

local function GetFartestSpot(table, pos, range)
	local spot = nil
	for k,v in pairs(table) do 
		if not spot and v then spot = v end
		if spot and v and GetDistanceSqr(GetOrigin(spot), pos) > GetDistanceSqr(GetOrigin(v), pos) and GetDistance(spot) < range then
			spot = v
		elseif GetDistance(spot) > range then
			spot = nil
		end
	end
	return spot
end

local function ClearSpots(table, pos, range)
	if #table > 0 then
		for i = 1, #table do
			local check = table[i]
			if check and GetDistance(check, pos) > range then
				table[i] = nil
			end
		end
	end
end

function E_NEAREST()
	if ERDY == 1 then
		local JSpots = GetJumpableSpots(myHero, 1000) --works
		local doWard = false
		local check = 0
		local CheckSpot = DoWard(nil, false, true) --works
		local slot = WardReady()
		if #JSpots > 0 then --if there are spots to jump on do...
			for i = 1, #JSpots do
				local object = JSpots[i]
				--Ward Placing
				if GetDistance(CheckSpot, object) < 300 and validEntry(object, goodSpots) then --we only want to escape in special spots not 200 range jumps.. --works
					table.insert(goodSpots, object)
				elseif GetDistance(CheckSpot, object) > 300 then
					if Katarina.Hotkeys.Espell:Value() then
						DoWard(slot)
					end
				end
				--Get best Spot
				if #goodSpots > 1 then
					JumpSpotToDraw = GetFartestSpot(goodSpots, CheckSpot, 650)
					if Katarina.Hotkeys.Espell:Value() and JumpSpotToDraw then
						CastTargetSpell(JumpSpotToDraw, _E)	
					end
				else
					JumpSpotToDraw = GetDistance(object, CheckSpot) < 300 and object or nil
					if Katarina.Hotkeys.Espell:Value() and JumpSpotToDraw then
						CastTargetSpell(JumpSpotToDraw, _E)	
					end
				end
			end
		else
			if Katarina.Hotkeys.Espell:Value() then
				DoWard(slot)
			end
		end
		if Katarina.Hotkeys.Espell:Value() and JumpSpotToDraw then
			CastTargetSpell(JumpSpotToDraw, _E)	
		end
		ClearSpots(goodSpots, CheckSpot, 300)
	end
end

local function Killsteal_Speed()
	for i = 1, #Enemies do
		local enemy = Enemies[i]
		if enemy and ValidTarget(enemy) then
			if (GotDaggerInHisRottenBody(enemy) or (IsBuffed[GetNetworkID(enemy)] and IsBuffed[GetNetworkID(enemy)].name == "katarina_bouncingBlades_mis")) or QRDY == 1 then 
				xQ2RDY = 1 
			else 
				xQ2RDY = 0 
			end
			local xQ = 	(getdmg("Q", enemy, myHero, 1)) * QRDY
			local xQ2 = (getdmg("Q", enemy, myHero, 2))* QRDY
			local xW = 	(getdmg("W", enemy, myHero)) * WRDY
			local xE = 	(getdmg("E", enemy, myHero)) * ERDY
			local xR = 	(getdmg("R", enemy, myHero)) * Katarina.Misc.CalcR:Value() * RRDY
			local xBC = ((CalcDamage(myHero, enemy, 0, 100))) * BC
			local xHG = ((CalcDamage(myHero, enemy, 0, 150 + .4 * GetBonusAP(myHero)))) * HG
			local xI = ((50 + 20 * GetLevel(myHero))) * IRDY + xBC + xHG
			local xAA = (CalcDamage(myHero, enemy, GetBaseDamage(myHero) + GetBonusDmg(myHero), 0))
			local eHP = GetCurrentHP(enemy)
			KSK[0]	= {a=0,b=0,c=0,d=n,e=n, dist=650 , spell="_B", buff=n, dam=xI}										--Ignite
			KSK[1]  = {a=n,b=1,c=n,d=n,e=n, dist=375 , spell="_W", buff=n, dam=xW} 										-- xW
			KSK[2]  = {a=n,b=n,c=1,d=n,e=n, dist=700 , spell="_E", buff=n, dam=xE} 										-- xE
			KSK[3]  = {a=n,b=1,c=1,d=n,e=n, dist=700 , spell="_E", buff=n, dam=xW+xE} 									-- EW
			KSK[4]  = {a=1,b=n,c=n,d=n,e=n, dist=675 , spell="_Q", buff=n, dam=xQ} 										-- xQ
			KSK[5]  = {a=1,b=n,c=1,d=n,e=n, dist=700 , spell="_E", buff=n, dam=xQ+xE} 									-- EQ
			KSK[6]  = {a=1,b=1,c=n,d=n,e=n, dist=375 , spell="_W", buff=n, dam=xQ+xW}									-- WQ
			KSK[7]  = {a=1,b=1,c=1,d=n,e=n, dist=700 , spell="_E", buff=n, dam=xQ+xW+xE} 								-- EWQ
			KSK[8]  = {a=1,b=n,c=1,d=n,e=1, dist=675 , spell="_Q", buff=n, dam=xQ+xQ2+xE} 	
			KSK[9]  = {a=n,b=n,c=1,d=n,e=1, dist=700 , spell="_E", buff=1, dam=xQ2+xE} 									-- QEx2
			KSK[10] = {a=1,b=1,c=n,d=n,e=1, dist=375 , spell="_Q", buff=n, dam=xQ+xQ2+xW} 		
			KSK[11] = {a=n,b=1,c=n,d=n,e=1, dist=375 , spell="_W", buff=1, dam=xQ2+xW} 									-- QWx2
			KSK[12] = {a=1,b=1,c=1,d=n,e=1, dist=700 , spell="_E", buff=n, dam=xQ+xQ2+xW+xE} 	
			KSK[13] = {a=1,b=1,c=n,d=n,e=1, dist=675 , spell="_Q", buff=n, dam=xQ2+xW}		
			KSK[14] = {a=n,b=1,c=1,d=n,e=n, dist=1075, spell="_J", buff=n, dam=xW} 										-- xW long
			KSK[15] = {a=1,b=n,c=1,d=n,e=n, dist=1375, spell="_J", buff=n, dam=xQ} 										-- xQ long
			KSK[16] = {a=1,b=1,c=1,d=n,e=n, dist=1075, spell="_J", buff=n, dam=xQ+xW} 									-- WQ long
			KSK[17] = {a=1,b=1,c=1,d=n,e=1, dist=1075, spell="_J", buff=n, dam=xQ+xQ2+xW} 								-- QW long
			KSK[18] = {a=0,b=0,c=0,d=n,e=n, dist=230,  spell="_A", buff=n, dam=xAA} 									-- AA
			KSK[19] = {a=0,b=0,c=0,d=n,e=n, dist=230,  spell="_A", buff=1, dam=xAA+xQ2} 								-- AA*2
			KSK[20] = {a=0,b=0,c=0,d=n,e=n, dist=910,  spell="_J", buff=n, dam=xAA} 									-- AA long
			KSK[21] = {a=0,b=0,c=0,d=n,e=n, dist=910,  spell="_J", buff=1, dam=xAA+xQ2}									-- AA*2 long
			KSK[22] = {a=1,b=1,c=1,d=n,e=n, dist=700,  spell="_E", buff=n, dam=((xQ+xQ2+xW))+xE+xI, dam2=xQ+xQ2+xW+xE}
			KSK[23] = {a=1,b=1,c=1,d=n,e=n, dist=700,  spell="_E", buff=n, dam=((xQ+xW))+xE+xI, dam2=xQ+xW+xE}
			KSK[24] = {a=1,b=n,c=1,d=n,e=n, dist=700,  spell="_E", buff=n, dam=(xQ)+xE+xI, dam2=xQ+xE}
			KSK[25] = {a=n,b=1,c=1,d=n,e=n, dist=700,  spell="_E", buff=n, dam=(xW)+xE+xI, dam2=xW+xE}
			KSK[26] = {a=n,b=1,c=1,d=n,e=n, dist=1075, spell="_J", buff=n, dam=(xW)+xI, dam2=xW} 					-- IW long
			KSK[27] = {a=1,b=n,c=1,d=n,e=n, dist=1375, spell="_J", buff=n, dam=(xQ)+xI, dam2=xQ} 					-- IQ long
			KSK[28] = {a=1,b=1,c=1,d=n,e=n, dist=1075, spell="_J", buff=n, dam=((xQ+xW))+xI, dam2=xQ+xW} 			-- IWQ long
			KSK[29] = {a=1,b=1,c=1,d=n,e=1, dist=1075, spell="_J", buff=n, dam=((xQ+xQ2+xW))+xI, dam2=xQ+xQ2+xW} 	-- IQW long		
			KSK[30] = {a=1,b=1,c=n,d=n,e=n, dist=375,  spell='_B', buff=n, dam=((xQ+xQ2+xW))+xI, dam2=xQ+xQ2+xW}
			KSK[31] = {a=1,b=1,c=n,d=n,e=n, dist=375,  spell='_B', buff=n, dam=((xQ+xW))+xI, dam2=xQ+xW}
			KSK[32] = {a=1,b=n,c=n,d=n,e=n, dist=625,  spell='_B', buff=n, dam=(xQ)+xI, dam2=xQ}
			KSK[33] = {a=n,b=1,c=n,d=n,e=n, dist=375,  spell='_B', buff=n, dam=(xW)+xI, dam2=xW}
			KSK[34] = {a=1,b=1,c=1,d=n,e=n, dist=625,  spell='_B', buff=n, dam=((xQ+xQ2+xW+xE))+xI, dam2=xQ+xQ2+xW+xE}
			KSK[35] = {a=1,b=n,c=1,d=n,e=n, dist=625,  spell='_B', buff=n, dam=((xQ+xQ2+xE))+xI, dam2=xQ+xQ2+xE}
			KSK[36] = {a=1,b=1,c=1,d=n,e=n, dist=625,  spell='_B', buff=n, dam=((xQ+xW+xE))+xI, dam2=xQ+xW+xE}
			KSK[37] = {a=1,b=n,c=1,d=n,e=n, dist=625,  spell='_B', buff=n, dam=((xQ+xE))+xI, dam2=xQ+xE} 
			KSK[38] = {a=n,b=n,c=1,d=n,e=n, dist=625,  spell='_B', buff=n, dam=(xE)+xI, dam2=xE}

			if Katarina.Options.Killsteal:Value() then
				for v = 0, 38 do
					if ValidTarget(enemy)  then
						if not locus or Katarina.Misc.BreakUltKS:Value() then
							if (QRDY == KSK[v].a or KSK[v].a == n) and (WRDY == KSK[v].b or KSK[v].b == n) and (ERDY == KSK[v].c or KSK[v].c == n) and (RRDY == KSK[v].d or KSK[v].d == n) and ((xQ2RDY ~= nil and xQ2RDY == KSK[v].e) or KSK[v].e == n) then
								if GetDistance(enemy) < KSK[v].dist then
									if eHP < KSK[v].dam and (KSK[v].dam2 == nil or eHP > KSK[v].dam2) then 
										if  ((KSK[v].buff == 1 and GotDaggerInHisRottenBody(enemy))  or KSK[v].buff == n) then
											if 		KSK[v].spell == '_B' then
												CastTargetSpell(enemy, Ignite)
												CastOffensiveItems(enemy)
											elseif 	KSK[v].spell == "_Q" then
												CastTargetSpell(enemy, _Q)
											elseif KSK[v].spell == "_W" then
												CastSpell(_W)
											elseif KSK[v].spell == "_E" then
												CastTargetSpell(enemy, _E)
											elseif KSK[v].spell == "_A" then 
												AttackUnit(enemy)
											elseif KSK[v].spell == "_J" then
												E_NEAREST()
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

local function SetVariables()
	Minions = GetEnemyMinionsInRange(myHero, 2000)
	Enemies = GetEnemyHeroes()
	GetCDs()
	TargetSelector()
	AutoPotions()
	LocusCheck()
	Killsteal_Speed()
	E_NEAREST()
end

local function Move()
	if not locus then
		MoveToXYZ(GetMousePos())
	end
end

function Farm()
	local AArange = 240
	local myRange = math.max(QRDY*675, WRDY*375, ERDY*700, RRDY*550, AArange)
	if not locus then
		if Katarina.Options.Move_Mouse:Value() and (QRDY+WRDY == 0) or (Katarina.Misc.EFarm:Value() and QRDY+WRDY+ERDY == 0) then
			Move()
		end
		if #Minions > 0 then 
			for i = 1, #Minions do
				local minion = Minions[i]
				if GetDistance(minion) < myRange then 
			        if minion and IsVisible(minion) and not IsDead(minion) then
			            local xQ = 	((getdmg("Q", minion, myHero, 1) - 10)* QRDY)
			            local xQ2 = (getdmg("Q", minion, myHero, 2) - 10)
			            local xW = 	((getdmg("W", minion, myHero) - 10)* WRDY)
			            local xE = 	((getdmg("E", minion, myHero) - 10)* ERDY)
			            local xA = 	(CalcDamage(myHero, minion, GetBaseDamage(myHero) + GetBonusDmg(myHero) - 10, 0))
			            --killable with AA?
			            if ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xA + xQ2) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xA)) and GetDistance(minion) < 230 then
			            	AttackUnit(minion)
			            --killable with W?
			            elseif ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xW + xQ2) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xW)) and GetDistance(minion) < 375 then
			                CastSpell(_W)
			            --killable with Q?
			            elseif ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xQ2) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ)) and GetDistance(minion) < 675 then
			                CastTargetSpell(minion, _Q)
			            --killable with E?
			            elseif Katarina.Misc.EFarm:Value() and ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xE + xQ2) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xE)) and GetDistance(minion) < Katarina.Misc.EFarmRange:Value() then
			            	CastTargetSpell(minion, _E)
			        --ADVANCED--
			        	elseif Katarina.Misc.AdvancedFarm:Value() then
			            --killable with AA-W
				       		if ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xA + xW + xQ2) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xA + xW)) and GetDistance(minion) < 230 then
				            	AttackUnit(minion)
				            --killable with AA-E
				            elseif Katarina.Misc.EFarm:Value() and ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xE + xQ2 + xA) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xE + xA)) and GetDistance(minion) < Katarina.Misc.EFarmRange:Value() then
				            	CastTargetSpell(minion, _E)
				            --killable with Q-Q2-AA
				            elseif ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xQ2 + xA) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xA)) and GetDistance(minion) < 230 then
				                CastTargetSpell(minion, _Q)
				            --killable with E-W
				            elseif Katarina.Misc.EFarm:Value() and ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xE + xQ2 + xW) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xE + xW)) and GetDistance(minion) < Katarina.Misc.EFarmRange:Value() then
				            	CastTargetSpell(minion, _E)
				            --killable with Q-Q2-E
				            elseif Katarina.Misc.EFarm:Value() and ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xQ2 + xE) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xE)) and GetDistance(minion) < Katarina.Misc.EFarmRange:Value() then
				                CastTargetSpell(minion, _Q)
				            --killable with Q-Q2-W
				            elseif ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xQ2 + xW) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xW)) and GetDistance(minion) < 375 then
				                CastTargetSpell(minion, _Q)
				            --killable with Q-Q2-E-W
				            elseif Katarina.Misc.EFarm:Value() and ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xQ2 + xE + xW) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xW + xE)) and GetDistance(minion) < Katarina.Misc.EFarmRange:Value() then
				                CastTargetSpell(minion, _Q)
				            --killable with Q-Q2-E-AA
				           	elseif Katarina.Misc.EFarm:Value() and ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xQ2 + xE + xA) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xA + xE)) and GetDistance(minion) < Katarina.Misc.EFarmRange:Value() then
				                CastTargetSpell(minion, _Q)
				            --killable with E-AA-W
				            elseif Katarina.Misc.EFarm:Value() and ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xE + xQ2 + xW + xA) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xE + xW + xA)) and GetDistance(minion) < Katarina.Misc.EFarmRange:Value() then
				            	CastTargetSpell(minion, _E)
				            --killable with Q-Q2-AA-W
				            elseif ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xQ2 + xW + xA) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xW + xA)) and GetDistance(minion) < 230  then
				                CastTargetSpell(minion, _Q)
				            --killable with Q-Q2-E-AA-W
				            elseif Katarina.Misc.EFarm:Value() and ((GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xQ2 + xE + xA + xW) or (not GotDaggerInHisRottenBody(minion) and GetCurrentHP(minion) < xQ + xA + xE + xW)) and GetDistance(minion) < Katarina.Misc.EFarmRange:Value() then
				                CastTargetSpell(minion, _Q)
				            --else move
							else
								if Katarina.Options.Move_Mouse:Value() then 
									Move(true)
								end
							end
						else
							if Katarina.Options.Move_Mouse:Value() then 
								Move(true)
							end
						end
					else
						if Katarina.Options.Move_Mouse:Value() then 
							Move(true)
						end
			        end
		        else
					if Katarina.Options.Move_Mouse:Value() then 
						Move(true)
					end
		        end
		    end
	    else
			if Katarina.Options.Move_Mouse:Value() then 
				Move(true)
			end
		end
	end
end

local function AutoLevel()
	local attempts, lastAttempt = 0, 0
	if Katarina.AutoLevel.Spellorder:Value() == 1 then
		skillingOrder = {_Q,_E,_W,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E}
	else
		skillingOrder = {_Q,_E,_W,_W,_W,_R,_W,_Q,_W,_Q,_R,_Q,_Q,_E,_E,_R,_E,_E}
	end
	spellLevelSum = (GetCastLevel(myHero, _Q) + GetCastLevel(myHero, _W) + GetCastLevel(myHero, _E) + GetCastLevel(myHero, _R))
	if attempts <= 10 or (attempts > 10 and GetTickCount() > lastAttempt + 1500) then
		if spellLevelSum < GetLevel(myHero) then
			if lastSpellLevelSum ~= spellLevelSum then attempts = 0 end
			letter = skillingOrder[spellLevelSum + 1]
			LevelSpell(letter)
			attempts = attempts + 1
			lastAttempt = GetTickCount()
			lastSpellLevelSum = spellLevelSum
		else
			attempts = 0
		end
	end
end

local function AutoZonyas()
	local HP, mHP, HPp, nE, slot = GetCurrentHP(myHero), GetMaxHP(myHero), Katarina.Options.healthpercent:Value(), CountEnemyHeroInRange(1000), 0
	if not locus and HP <= mHP * HPp * .01 and (nE > 0 or HP < 150) then
		slot = slot == 0 and GetItemSlot(myHero, 3157) or slot == 0 and GetItemSlot(myHero, 3090) or 0
		CastSpell(slot)
	end
end

local function AutoW()
	for i = 1, #Enemies do
		local Hero = Enemies[i]
		if Hero and ValidTarget(Hero) and not locus and WRDY == 1 and QRDY == 0 and (not _Q_ or GotDaggerInHisRottenBody(Hero)) and GetDistance(Hero) < 375 then
			CastSpell(_W)
		end
	end
end

local function Harass(target)
	local range = math.max(QRDY*675, WRDY*375, ERDY*700, RRDY*550, 240)
    if not locus and ValidTarget(target) then
		if 		ERDY == 1 and GetDistance(target) < 700 and not (WRDY == 0 and ERDY == 1 and _Q_) then
			CastTargetSpell(target, _E)
		elseif	QRDY == 1 and ERDY == 0 and GetDistance(target) < 675 then
			CastTargetSpell(target, _Q)
		elseif	QRDY + ERDY == 0 and WRDY == 1 and GetDistance(target) < 375 and not _Q_ then
		 	CastSpell(_W)
		elseif	((WRDY + ERDY == 0) or GotDaggerInHisRottenBody(target)) and GetDistance(target) < 240 then
			AttackUnit(target)
		elseif Katarina.Options.Move_Mouse:Value() then
			Move()
		end 
    elseif Katarina.Options.Move_Mouse:Value() and not locus or not target or IsDead(target) or not ValidTarget(target, range) then
		Move()
	end
end

local function Combo(target)
	local range = math.max(QRDY*675, WRDY*375, ERDY*700, RRDY*550, 240)
	GetCDs()
    if not locus and ValidTarget(target, range) then
    	local itemRange = 550 * BC > 0 and 550 or 700 + HG > 0 and 700 or 0
		if    	not locus and ((QRDY + WRDY + ERDY == 3 and GetDistance(target) < itemRange) or (RRDY == 1 and GetDistance(target) < 425)) and (HG ~= 0 or BC ~= 0) and Katarina.Misc.UseItemsCombo:Value() then
			CastOffensiveItems(target)
		elseif	not locus and ERDY == 1 and not ((WRDY + RRDY == 0) and _Q_) and GetDistance(target) <= 700 then
			CastTargetSpell(target, _E)
		elseif	not locus and QRDY == 1 and GetDistance(target) <= 675 then
			CastTargetSpell(target, _Q)
		elseif	not locus and QRDY + ERDY == 0 and WRDY == 1 and not (QRDY + ERDY + RRDY == 0 and _Q_) and GetDistance(target) <= 375 then
			CastSpell(_W)
		elseif	QRDY + WRDY + ERDY == 0 and RRDY == 1 and GetDistance(target) <= 425 then
			CastSpell(_R)
		elseif 	not locus and ((QRDY + WRDY + ERDY == 0) or GotDaggerInHisRottenBody(target)) and GetDistance(target) < 240 then
			AttackUnit(target)
		elseif	not locus and  QRDY + WRDY + ERDY + RRDY == 0 and Katarina.Options.Move_Mouse:Value() then
			Move()
		end
    elseif Katarina.Options.Move_Mouse:Value() and not locus or not target or IsDead(target) or not ValidTarget(target, range) then
		Move()
	end
end

local function Round(val, decimal, num, idp)
	if val and (decimal) then
		return math.floor( (val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
	elseif val then
		return math.floor(val + 0.5)
	elseif num and idp then
		local mult = 10^(idp or 0)
		return math.floor(num * mult + 0.5) / mult
	end
end

local function Roamhelper()
	for i = 1, #Enemies do
		local Hero = Enemies[i]
		if Hero then
			if (GotDaggerInHisRottenBody(Hero) or (IsBuffed[GetNetworkID(Hero)] and IsBuffed[GetNetworkID(Hero)].name == "katarina_bouncingBlades_mis")) or QRDY == 1 then 
				xQ2RDY = 1 
			else 
				xQ2RDY = 0 
			end
			local xQ = 	(getdmg("Q", Hero, myHero, 1)) * QRDY
			local xQ2 = (getdmg("Q", Hero, myHero, 2))* xQ2RDY
			local xW = 	(getdmg("W", Hero, myHero)) * WRDY
			local xE = 	(getdmg("E", Hero, myHero)) * ERDY
			local xR = 	(getdmg("R", Hero, myHero)) * Katarina.Misc.CalcR:Value() * RRDY
			local xBC = ((CalcDamage(myHero, Hero, 0, 100))) * BC
			local xHG = ((CalcDamage(myHero, Hero, 0, 150 + .4 * GetBonusAP(myHero)))) * HG
			local xIGN = ((50 + 20 * GetLevel(myHero)) *.2 * (Katarina.Misc.CalcR:Value() * .25)) * IRDY
			local Damage = Round(xQ + xQ2 + xW + xE + xR + xBC + xHG + xIGN, 0, nil, nil)
			local S = GetResolution()
			local PosX = (13.3 / 16) * S.x + 75
			local GSY = S.y - 200

			DrawText("Champion: "..GetObjectName(Hero), 10, PosX, ((15 / 900) * GSY) * i + ((53 / 90) * GSY), colorcyan)

			if IsVisible(Hero) and not IsDead(Hero) then
				if Damage < GetCurrentHP(Hero) then 
					DrawText("HP left:  ".. math.ceil(GetCurrentHP(Hero) - Damage), 10, PosX + 150, ((15 / 900) * GSY) * i + ((53 / 90) * GSY), coloryellow)
				elseif Damage > GetCurrentHP(Hero) then 
					DrawText("Killable!", 10, PosX + 150, ((15 / 900) * GSY) * i + ((53 / 90) * GSY), colorred) 
				end
			elseif not IsVisible(Hero) and not IsDead(Hero) then
				DrawText("MIA", 10, PosX + 150, ((15 / 900) * GSY) * i + ((53 / 90) * GSY), colororange)
			else
				DrawText("Dead", 10, PosX + 150, ((15 / 900) * GSY) * i + ((53 / 90) * GSY), colorgreen)
			end
		end
	end
end

local function EscapeDraw()
    for i = 1, #Enemies do
        local enemy = Enemies[i]
        if GetTeam(enemy) ~= GetTeam(myHero) and IsVisible(enemy) and not IsDead(enemy) then
            local QREADY = CanUseSpell(enemy, _Q) > 1 and GetCastLevel(enemy, _Q) > 0
            local WREADY = CanUseSpell(enemy, _W) > 1 and GetCastLevel(enemy, _W) > 0
            local EREADY = CanUseSpell(enemy, _E) > 1 and GetCastLevel(enemy, _E) > 0
            local RREADY = CanUseSpell(enemy, _R) > 1 and GetCastLevel(enemy, _R) > 0
			local EnemiePos = GetOrigin(enemy)
			local EnemyName = GetObjectName(enemy)
			local ID = GetNetworkID(enemy)
			local eIgnite = (GetCastName(enemy, SUMMONER_1):lower():find("summonerdot") and SUMMONER_1 or (GetCastName(enemy, SUMMONER_2):lower():find("summonerdot") and SUMMONER_2 or nil))
			local DrawEscapesColor =	Katarina.Draw.Draw_Escapes_Color:Value() == 1 and colorcyan or
										Katarina.Draw.Draw_Escapes_Color:Value() == 2 and coloryellow or
										Katarina.Draw.Draw_Escapes_Color:Value() == 3 and colorred or
										Katarina.Draw.Draw_Escapes_Color:Value() == 4 and colororange or
										Katarina.Draw.Draw_Escapes_Color:Value() == 5 and colorgreen
			if eIgnite and CanUseSpell(enemy, eIgnite) == 0 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Aatrox'		and QREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Ahri'			and RREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Azir' 			and EREADY and IsBuffed[enemy].name == 'Azir_Base_P_Soldier_Ring' then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end -- enemy soldier particle name?
            if EnemyName == 'Caitlyn' 		and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Corki'  		and WREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Elise'  		and ((EREADY and GetRange(enemy) < 550) or (EREADY and RREADY and GetRange(enemy) >= 550)) then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Ezreal' 		and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Fiora'  		and RREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Fizz'   		and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Gnar'   		and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Gragas'  		and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Graves'  		and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Hecarim' 		and RREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'JarvanIV'		and QREADY and (EREADY or (IsBuffed[enemy] and IsBuffed[enemy].name == 'Flag_Name')) then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end -- Need flag name
            if EnemyName == 'Jax'			and QREADY and #GetJumpableSpots(enemy, 700) > 0 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Kassadin'		and RREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Kennen'   		and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Khazix'  		and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Leblanc' 		and ((WREADY and GetSpellName(enemy, _W) == 'LeblancSlide') or (RREADY and  GetSpellName(enemy, _R) == 'LeblancSlideM') or GetSpellName(enemy, _W) == 'leblancslidereturn' or GetSpellName(enemy, _R) == 'leblancslidereturnm') then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'LeeSin'  		and GetSpellName(enemy, _Q) == 'blindmonkqtwo' then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Lissandra'		and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Lucian'  		and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Nautilus'		and QREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Nocturne' 		and RREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Quinn'        	and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Renekton'     	and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Riven'        	and (QREADY or EREADY) then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Sejuani'     	and QREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Shaco'        	and QREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Shen'         	and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Shyvana'     	and RREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Tristana'    	and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Tryndramere'	and EREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Vayne'        	and QREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
            if EnemyName == 'Vladimir'     	and WREADY then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
        
            for i = 1, #GetAllyHeroes() do
                local ally = GetAllyHeroes()[i]
                if ally and GetTeam(ally) == GetTeam(myHero) and IsVisible(ally) and not IsDead(ally) and GetObjectName(ally) ~= GetObjectName(myHero) and GetDistance(ally) > 375 then
                    if EnemyName == 'Akali'  		and RREADY and GetDistance(ally, enemy)< 825 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Diana'    		and RREADY and GetDistance(ally, enemy)< 825 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Fiora'   		and QREADY and GetDistance(ally, enemy)< 600 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Fizz'         	and QREADY and GetDistance(ally, enemy)< 550 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Irelia'        and QREADY and GetDistance(ally, enemy)< 650 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Jax'         	and QREADY and GetDistance(ally, enemy)< 700 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Maokai'        and WREADY and GetDistance(ally, enemy)< 525 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'MasterYi'  	and QREADY and GetDistance(ally, enemy)< 600 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'MonkeyKing'	and EREADY and GetDistance(ally, enemy)< 625 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Pantheon'    	and WREADY and GetDistance(ally, enemy)< 600 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Talon'   		and EREADY and GetDistance(ally, enemy)< 700 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Vi'            and RREADY and GetDistance(ally, enemy)< 800 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Warwick'   	and RREADY and GetDistance(ally, enemy)< 700 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'XinZhao'    	and EREADY and GetDistance(ally, enemy)< 600 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Yasuo'      	and EREADY and GetDistance(ally, enemy)< 475 and not IsBuffed[GetNetworkID(ally)].name == 'Yasuo_E_buff' then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                end
            end
            for i = 1, #minionManager.objects do
            	local minion = minionManager.objects[i]
                if minion and IsVisible(minion) and not IsDead(minion) and GetTeam(minion) == GetTeam(myHero) and GetDistance(minion) > 375 then
                    if EnemyName == 'Akali'        	and RREADY and GetDistance(minion, enemy) < 825 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Fiora'        	and QREADY and GetDistance(minion, enemy) < 600 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Fizz'       	and QREADY and GetDistance(minion, enemy) < 550 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'MasterYi'   	and QREADY and GetDistance(minion, enemy) < 600 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'MonkeyKing'	and EREADY and GetDistance(minion, enemy) < 625 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Pantheon'   	and WREADY and GetDistance(minion, enemy) < 600 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'XinZhao'     	and EREADY and GetDistance(minion, enemy) < 600 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Yasuo'        	and EREADY and GetDistance(minion, enemy) < 475 and not IsBuffed[GetNetworkID(minion)].name == 'Yasuo_E_buff' then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Jax'       	and QREADY and GetDistance(minion, enemy) < 700 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                    if EnemyName == 'Irelia'        and QREADY and GetDistance(minion, enemy) < 650 then DrawCircle(enemy, Katarina.Draw.Draw_Escapes_Radius:Value(), Katarina.Draw.Draw_Escapes_Width:Value(), 0, DrawEscapesColor) end
                end
            end
        end
    end
end

function GetTargetCC(typeCC,enemie)
	local HardCC = 0
	local QREADY = CanUseSpell(enemie, _Q) > 1 and GetCastLevel(enemie, _Q) > 0
    local WREADY = CanUseSpell(enemie, _W) > 1 and GetCastLevel(enemie, _W) > 0
    local EREADY = CanUseSpell(enemie, _E) > 1 and GetCastLevel(enemie, _E) > 0
    local RREADY = CanUseSpell(enemie, _R) > 1 and GetCastLevel(enemie, _R) > 0
    local EnemieName = GetObjectName(enemie)
    local ID = GetNetworkID(enemie)
	if EnemieName == "Aatrox" then
		if QREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Ahri" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Alistar" then
		if QREADY then HardCC = HardCC+1 end
		if WREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Amumu" then
		if QREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Anivia" then
		if QREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Annie" then
		if IsBuffed[ID] and IsBuffed[ID].name == 'pyromania_particle' and (QREADY or WREADY or RREADY) then HardCC = HardCC+1 end
	elseif EnemieName == "Ashe" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Azir" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Blitzcrank" then
		if QREADY or IsBuffed[ID].name == 'Powerfist_buf' then HardCC = HardCC+1 end
		if EREADY then HardCC = HardCC+1 end
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Brand" then
		if QREADY and ((IsBuffed[GetNetworkID(myHero)] and IsBuffed[GetNetworkID(myHero)].name == 'BrandFireMark') or WREADY or EREADY or RREADY) then HardCC = HardCC+1 end
	elseif EnemieName == "Braum" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Cassiopeia" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Chogath" then
		if QREADY then HardCC = HardCC+1 end
		if WREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Darius" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Diana" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Draven" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Elise" then
		if EREADY and GetSpellName(enemie, _E) == 'EliseHumanE' then HardCC = HardCC+1 end
	elseif EnemieName == "FiddleSticks" then
		if QREADY then HardCC = HardCC+1 end
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Fizz" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Galio" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Garen" then
		if QREADY or IsBuffed[ID] and IsBuffed[ID].name == 'Garen_Base_Q_Cas_Sword' then HardCC = HardCC+1 end
	elseif EnemieName == "Gnar" then
		if WREADY and GetSpellName(enemie, _W) == 'gnarbigw' then HardCC = HardCC+1 end
		if RREADY and GetRange(enemie) < 410 then HardCC = HardCC+1 end
	elseif EnemieName == "Gragas" then
		if WREADY then HardCC = HardCC+1 end
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Hecarim" then
		if EREADY or IsBuffed[ID] and IsBuffed[ID].name == 'Hecarim_E_buf' then HardCC = HardCC+1 end
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Heimerdinger" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Irelia" then
		if EREADY and GetCurrentHP(enemie) < GetCurrentHP(myHero) then HardCC = HardCC+1 end		
	elseif EnemieName == "Janna" then
		if QREADY then HardCC = HardCC+1 end
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "JarvanIV" then
		if QREADY and EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Jax" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Jayce" then
		if EREADY and GetSpellName(enemie, _E) == 'JayceThunderingBlow' then HardCC = HardCC+1 end
	elseif EnemieName == "Kennen" then
		if (QREADY and WREADY and EREADY) or ((IsBuffed[GetNetworkID(myHero)] and IsBuffed[GetNetworkID(myHero)].name == 'kennen_mos') and (QREADY or WREADY or EREADY or RREADY)) or RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "LeeSin" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Leona" then
		if QREADY or IsBuffed[ID] and IsBuffed[ID].name == 'Leona_ShieldOfDaybreak_cas' then HardCC = HardCC+1 end
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Lissandra" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Lulu" then
		if WREADY then HardCC = HardCC+1 end
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Malphite" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Malzahar" then
		if QREADY then HardCC = HardCC+1 end
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Maokai" then
		if QREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Nami" then
		if QREADY then HardCC = HardCC+1 end
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Nautilus" then
		if QREADY then HardCC = HardCC+1 end
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Nocturne" then
		if EREADY then HardCC = HardCC+1 end	
	elseif EnemieName == "Orianna" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Pantheon" then
		if WREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Poppy" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Quinn" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Rammus" then
		if QREADY then HardCC = HardCC+1 end
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Renekton" then
		if WREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Rengar" then
		if EREADY and GetCurrentMP(enemies) ==5 then HardCC = HardCC+1 end
	elseif EnemieName == "Riven" then
		if QREADY then HardCC = HardCC+1 end
		if WREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Sejuani" then
		if QREADY then HardCC = HardCC+1 end
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Shen" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Shyvana" then
		if RREADY then HardCC = HardCC+1 end -- Need this champ
	elseif EnemieName == "Singed" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Sion" then 
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Skarner" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Sona" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Soraka" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Syndra" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Taric" then 
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Thresh" then
		if QREADY then HardCC = HardCC+1 end
		if EREADY then HardCC = HardCC+1 end -- Need this champ
	elseif EnemieName == "Tristana" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Trundle" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "TwistedFate" then
		if GetSpellName(enemy, _W) == "goldcardlock" then HardCC = HardCC+1 end
	elseif EnemieName == "Udyr" then
		if IsBuffed[GetNetworkID(myHero)] and not IsBuffed[GetNetworkID(myHero)].name == 'Udyr_Base_E_timer' then HardCC = HardCC+1 end
	elseif EnemieName == "Urgot" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Vayne" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Veigar" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Velkoz" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Vi" then
		if QREADY then HardCC = HardCC+1 end
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Viktor" then
		if WREADY then HardCC = HardCC+1 end
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Volibear" then
		if QREADY then HardCC = HardCC+1 end -- Need this champ
	elseif EnemieName == "Warwick" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "MonkeyKing" then
		if RREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Xerath" then
		if EREADY then HardCC = HardCC+1 end
	elseif EnemieName == "XinZhao" then
		if IsBuffed[ID] and IsBuffed[ID].name ==  'xenZiou_ChainAttack_indicator' then HardCC = HardCC+1 end
		if RREADY and IsBuffed[GetNetworkID(myHero)] and not IsBuffed[GetNetworkID(myHero)].name ==  'xen_ziou_intimidate' then HardCC = HardCC+1 end
	elseif EnemieName == "Yasuo" then
		if GetCastName(enemie, _Q) == 'yasuoq3w' then HardCC = HardCC+1 end
	elseif EnemieName == "Ziggs" then
		if WREADY then HardCC = HardCC+1 end
	elseif EnemieName == "Zyra" then
		if RREADY then HardCC = HardCC+1 end
	end
	if typeCC == "HardCC" then return HardCC else return 0 end
end

local function StunDraw()
	local amountCC = 0
	for i = 1, #Enemies do
	local enemie = Enemies[i]
		if (enemie and GetTeam(enemie) ~= GetTeam(myHero) and IsVisible(enemie) and not IsDead(enemie)) then
			local targetCC = GetTargetCC("HardCC", enemie)
			if targetCC > 0 then
				local EnemiePos = GetOrigin(enemie)
				DrawCircle(enemie, 60, 0, 0, colorcyan)
			end
		end
	end
end

local function GetKillableMinions()
	local mList = {}
	for i = 1, #Minions do
		local minion = Minions[i]
		if minion and IsVisible(minion) and not IsDead(minion) and GetDistance(minion) < 2000 then --Get All valid Minions.
			local xQ = 	((getdmg("Q", minion, myHero, 1) - 10) * QRDY)
            local xQ2 = (QRDY == 1 or GotDaggerInHisRottenBody(minion)) and (getdmg("Q", minion, myHero, 2) - 10) or 0
            local xW = 	((getdmg("W", minion, myHero) - 10) * WRDY)
            local xE = 	Katarina.Misc.EFarm:Value() and ((getdmg("E", minion, myHero) - 10) * ERDY) or 0
            local xA =  (CalcDamage(myHero, minion, GetBaseDamage(myHero) + GetBonusDmg(myHero) - 10, 0)) or 0
            local maxDamage = xQ + xQ2 + xW + xE + xA --Look if they are killable with any Combo.
            local mHP = GetCurrentHP(minion)
	        if mHP < maxDamage and validEntry(minion, mList) then
	        	table.insert(mList, minion)
	        end
	    end
	end
	return mList
end

OnTick(function(myHero)
	SetVariables()
	BlockF7OrbWalk(true)
	BlockF7Dodge(true)
	if Katarina.AutoLevel.AutoLevel:Value() then 
		AutoLevel() 
	end
	if Katarina.Options.Auto_Zonyas:Value() then 
		AutoZonyas()
	end
	if locus or not target or IsDead(myHero) or target and GotDaggerInHisRottenBody(target) then 
		_Q_ = false 
	end
	if Katarina.Hotkeys.Farm:Value() then
		Farm() 
	end
	if Katarina.Hotkeys.Combo:Value() then 
		Combo(target)
	end
	if Katarina.Hotkeys.Harass:Value() then 
		Harass(target)
	end
	if Katarina.Options.Auto_W:Value() and WRDY == 1 then 
		AutoW() 
	end
end)

OnDraw(function(myHero)
	if Katarina.Draw.Roamhelper:Value() then 
		Roamhelper() 
	end
	if Katarina.Draw.Draw_Stuns:Value() then
		StunDraw() 
	end
	if Katarina.Draw.Draw_Escapes:Value() then 
		EscapeDraw() 
	end
	if not IsDead(myHero) then 
		if Katarina.Draw.Show_ranges:Value() then
			local rangeS = math.max(QRDY*675, WRDY*375, ERDY*700, RRDY*550)
			local DrawRangesColor =		Katarina.Draw.Show_ranges_Color:Value() == 1 and colorcyan or
										Katarina.Draw.Show_ranges_Color:Value() == 2 and coloryellow or
										Katarina.Draw.Show_ranges_Color:Value() == 3 and colorred or
										Katarina.Draw.Show_ranges_Color:Value() == 4 and colororange or
										Katarina.Draw.Show_ranges_Color:Value() == 5 and colorgreen
			DrawCircle(myHero, rangeS, Katarina.Draw.Show_ranges_Width:Value(), 0, DrawRangesColor) 
		end
		if ValidTarget(target) and Katarina.Draw.Show_target:Value() then
			local DrawTargetColor =		Katarina.Draw.Show_target_Color:Value() == 1 and colorcyan or
										Katarina.Draw.Show_target_Color:Value() == 2 and coloryellow or
										Katarina.Draw.Show_target_Color:Value() == 3 and colorred or
										Katarina.Draw.Show_target_Color:Value() == 4 and colororange or
										Katarina.Draw.Show_target_Color:Value() == 5 and colorgreen
			DrawCircle(target, Katarina.Draw.Show_target_Radius:Value(), Katarina.Draw.Show_target_Width:Value(), 0, DrawTargetColor) 
		end
	end
	if not Katarina.Hotkeys.Combo:Value() and not Katarina.Hotkeys.Harass:Value() and Katarina.Draw.DrawLS:Value() then
		local list = GetKillableMinions()
		local DrawMinionsColor =		Katarina.Draw.DrawLS_Color:Value() == 1 and colorcyan or
										Katarina.Draw.DrawLS_Color:Value() == 2 and coloryellow or
										Katarina.Draw.DrawLS_Color:Value() == 3 and colorred or
										Katarina.Draw.DrawLS_Color:Value() == 4 and colororange or
										Katarina.Draw.DrawLS_Color:Value() == 5 and colorgreen
		for i = 1, #list do
			local check = list[i]
			local Pos = GetOrigin(check.object)
			DrawText3D("Killable", Pos.x, 0, Pos.z, Katarina.Draw.DrawLS_Size:Value(), DrawMinionsColor)
		end
	end
	if Katarina.Draw.E_helper:Value() and JumpSpotToDraw and IsVisible(JumpSpotToDraw) and not IsDead(JumpSpotToDraw) and GetDistance(JumpSpotToDraw) < 800 + 500 and ERDY == 1 then
		local DrawSpotColor =	Katarina.Draw.E_helper_Color:Value() == 1 and colorcyan or
								Katarina.Draw.E_helper_Color:Value() == 2 and coloryellow or
								Katarina.Draw.E_helper_Color:Value() == 3 and colorred or
								Katarina.Draw.E_helper_Color:Value() == 4 and colororange or
								Katarina.Draw.E_helper_Color:Value() == 5 and colorgreen
		DrawCircle(JumpSpotToDraw, Katarina.Draw.E_helper_Radius:Value(), Katarina.Draw.E_helper_Width:Value(), 0, colorgreen) 
	end
	if Katarina.Draw.Healthpercent:Value() then
		for i = 1, #Enemies do
			local enemy = Enemies[i]
			if enemy and ValidTarget(enemy) then
				local xQ = 	((getdmg("Q", enemy, myHero, 1)) * QRDY)
           		local xQ2 = (QRDY == 1 or GotDaggerInHisRottenBody(enemy)) and (getdmg("Q", enemy, myHero, 2)) or 0
            	local xW = 	((getdmg("W", enemy, myHero)) * WRDY)
            	local xE = 	((getdmg("E", enemy, myHero)) * ERDY)
            	local xR =	((getdmg("R", enemy, myHero, 1)) * Katarina.Misc.CalcR:Value() * RRDY)
           	 	local xA = (CalcDamage(myHero, enemy, GetBaseDamage(myHero) + GetBonusDmg(myHero), 0)) or 0
				local xI = ((50 + 20 * GetLevel(myHero)) *.2 * (Katarina.Misc.CalcR:Value() * .25)) * IRDY
				local xBC = ((CalcDamage(myHero, enemy, 0, 100))) * BC
				local xHG = ((CalcDamage(myHero, enemy, 0, 150 + .4 * GetBonusAP(myHero)))) * HG
				local eHP = GetCurrentHP(enemy)
				local emHP = GetMaxHP(enemy)
				local Damage_A = Round(nil, nil, (eHP - (xA + xQ + xQ2 + xW + xE)) / emHP * 100, 0) --Harass
				local Damage_B = Round(nil, nil, (eHP - (xA + xQ + xQ2 + xW + xE + xI + xR + xBC + xHG)) / emHP * 100, 0) --Combo
				local EnemyPos = GetOrigin(enemy)
				if Damage_A < 0 then 
					Damage_C = "KILL" 
				else 
					Damage_C = Damage_A.."% , " 
				end
				if Damage_B < 0 then 
					Damage_D = "KILL" 
				else 
					Damage_D = Damage_B.."%" 
				end
				if Damage_A < 0 then
					DrawText3D(Damage_C, EnemyPos.x, 0, EnemyPos.z, 10, colorred)
				elseif Damage_B<0 then 
					DrawText3D(Damage_C..Damage_D, EnemyPos.x, 0, EnemyPos.z, 10, coloryellow)
				else
					if RRDY == 0 then 
						DrawText3D(Damage_C, EnemyPos.x, 0, EnemyPos.z, 10, colorcyan)
					else 
						DrawText3D(Damage_C..Damage_D, EnemyPos.x, 0, EnemyPos.z, 10, colorcyan) 
					end
				end
			end
		end
	end
end)

OnDeleteObj(function(Object)
	if Object and (GetObjectBaseName(Object) == "Katarina_deathLotus_cas.troy" or GetObjectBaseName(Object) == "Katarina_deathLotus_empty.troy") and GetDistance(Object) < 50 then
		locus = false 
	end
	if GetObjectBaseName(Object):find("Ward") then
		for i, aWard in pairs(WardsPlaced) do
			if GetNetworkID(aWard) == GetNetworkID(Object) and GetOrigin(aWard) == GetObjectName(Object) then
				WardsPlaced[i] = nil
			end
		end
	end
end)

OnUpdateBuff(function(unit,buff)
	if GetTeam(unit) ~= GetTeam(myHero) and buff.Name:lower():find("katarinaqmark") then
		local ID = GetNetworkID(unit)
		DelayAction(function()
			GotDaggered[ID] = buff.Count
		end, .3)
	else
		local ID = GetNetworkID(unit)
		DelayAction(function()
			IsBuffed[ID] = {state = true, name = buff.Name}
		end, .3)
	end
end)

OnRemoveBuff(function(unit,buff)
	if GetTeam(unit) ~= GetTeam(myHero) and buff.Name:lower():find("katarinaqmark") then
		local ID = GetNetworkID(unit)
		DelayAction(function()
			GotDaggered[ID] = 0
		end, .3)
	else
		local ID = GetNetworkID(unit)
		if IsBuffed[ID] and IsBuffed[ID].name:find(buff.Name) then
			DelayAction(function()
				IsBuffed[ID] = {state = false, name = "No Buff"}
			end, .3)
		end
	end
end)

OnProcessSpell(function(unit, spell)
	if unit == myHero then
		if spell.name == "KatarinaQ" and spell.target then
			_Q_ = true 
		end
		if spell.name == "KatarinaR" then
			Rtimer = GetTickCount()
			locus = true
		end
	end
end)

OnProcessSpellComplete(function(object, spell)
	if object == myHero and (GetObjectBaseName(object) == "Katarina_deathLotus_cas.troy" or GetObjectBaseName(object) == "Katarina_deathLotus_empty.troy") and GetDistance(object) < 50 then
		locus = false 
	end
end)

OnCreateObj(function(obj)
	if obj then  
		if GetObjectBaseName(obj):find("Katarina") and GetObjectBaseName(obj) == "Katarina_deathLotus_empty.troy" and GetDistance(obj) < 50 then
			locus = false 
		end
		if GetDistance(obj) < 100 and GetObjectBaseName(obj):find("ountain") or GetObjectBaseName(obj):find("fountain_heal") then
			Pot_Timer = GetTickCount()
			bluePill  = obj
		end
		if obj and (GetObjectBaseName(obj) == "Ward_Wriggles_Idle" or GetObjectBaseName(obj) == "SightWard" or GetObjectBaseName(obj) == "Global_Trinket_Yellow" or GetObjectBaseName(obj):find("Ward")) and not GetObjectBaseName(obj):find("WardDeath") and not GetObjectBaseName(obj):find("WardCorpse") and not GetObjectBaseName(obj):find("Ward_Blue") then
			table.insert(WardsPlaced, obj)
		end
	end
end)

OnObjectLoad(function(Object)
	if Object and (GetObjectBaseName(Object) == "Ward_Wriggles_Idle" or GetObjectBaseName(Object) == "SightWard" or GetObjectBaseName(Object) == "Global_Trinket_Yellow" or GetObjectBaseName(Object):find("Ward")) and not GetObjectBaseName(Object):find("WardDeath") and not GetObjectBaseName(Object):find("WardCorpse") and not GetObjectBaseName(Object):find("Ward_Blue") then
		table.insert(WardsPlaced, Object)
	end
	if GetDistance(Object) < 100 and GetObjectBaseName(Object):find("ountain") or GetObjectBaseName(Object):find("fountain_heal") then
		Pot_Timer = GetTickCount()
		bluePill  = Object
	end
end)
