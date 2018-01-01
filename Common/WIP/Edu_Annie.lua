if GetObjectName(GetMyHero()) ~= "Annie" then return end	--Checks if our hero is named "Annie" and stops the scripts if that's not the case

require("OpenPredict")										--Loads OpenPredict (opotional)

local AnnieMenu = Menu("Annie", "Annie")						--Create a New Menu and call it AnnieMenu (the user only sees "Annie")
AnnieMenu:SubMenu("Combo", "Combo")							--Create a New SubMenu and call it Combo
AnnieMenu.Combo:Boolean("Q", "Use Q", true)						--Add a button to toggle the usage of Q
AnnieMenu.Combo:Boolean("W", "Use W", true)						--Add a button to toggle the usage of W
AnnieMenu.Combo:Boolean("R", "Use R", true)						--Add a button to toggle the usage of R
AnnieMenu.Combo:Boolean("KSQ", "Killsteal with Q", true)		--Add a button to killsteal with Q
AnnieMenu.Combo:Boolean("UOP", "Use OpenPredict for R", true)	--Adds a button so we can check if the user wants to use openPredict	[OPTIONAL]
AnnieMenu.Combo:Boolean("E", "Use E vs Enemy AA", true)			--Add a button to toggle the usage of E

local AnnieR = {delay = 0.075, range = 600, radius = 150, speed = math.huge}		--TABLE for Annie R ONLY if you are using OpenPredict

OnTick(function()									--The code inside the Function runs every tick
	
	local target = GetCurrentTarget()					--Saves the "best" enemy champ to the target variable
		
	if IOW:Mode() == "Combo" then						--Check if we are in Combo mode (holding space)
			
		
		if AnnieMenu.Combo.Q:Value() and Ready(_Q) and ValidTarget(target, 625) then	
			--[[
				AnnieMenu.Combo.Q:Value() returns true if the menu has been ticked
				Ready(_Q) returns true if we are able to cast Q now
				ValidTarget(target, 625) returns true if the target can be attacked and is in a range of 625 (Annie Q range; see wiki)
			]]		
			CastTargetSpell(target , _Q)	--Casts the Q as Point&Click spell on the enemy
		end		--Ends the Q logic
	
		if AnnieMenu.Combo.W:Value() and Ready(_W) and ValidTarget(target, 625) then
			--[[
				AnnieMenu.Combo.W:Value() returns true if the menu has been ticked
				Ready(_W) returns true if we are able to cast W now
				ValidTarget(target, 625) returns true if the target can be attacked and is in a range of 625 (Annie W range; see wiki)
				We don't care that it's conic atm because it's pretty much instant
			]]
			local targetPos = GetOrigin(target)		--saves the XYZ coordinates of the target to the variable
			CastSkillShot(_W , targetPos)			--Since the W is a skillshot (select area), we have to cast it at a point on the ground (targetPos)
		end		--Ends the W logic
		
		if AnnieMenu.Combo.R:Value() and Ready(_R) and ValidTarget(target, 600) then		--Same check as Q/W
			--[[
				Now we need to predict the ult into the enemy path using the function:
				GetPredictionForPlayer(startPos, targetUnit, targetMovespeed, SpellSpeed, SpellDelay, SpellRange, SpellWidth, SpellCollision, additionalHitbox)
				EXPLANATION OF EACH PARAMETER:
				startPos = GetOrigin(myHero)	that's our current spot
				targetUnit = target				that's our current target
				targetMovespeed = GetMoveSpeed(target) current MS of the target
				SpellSpeed = math.huge because it doesn't have to travel, it just appears
				SpellDelay = 75 the time in ms that we need to cast the spell
				SpellRange = 600 the range of R (see wiki)
				SpellWidth = 150 = radius/2 (see wiki)
				SpellCollision = false because the ult doesn't stop if it hits a creep
			]]
			if not AnnieMenu.Combo.UOP:Value() then			--If the user doesn't want to use OpenPred
				local RPred = GetPredictionForPlayer(GetOrigin(myHero), target, GetMoveSpeed(target), math.huge, 75, 600, 150, false, true)
				if RPred.HitChance == 1 then		--If it has calcuated that we can hit the enemy
					CastSkillShot(_R,RPred.PredPos)			--Cast ult at predicted position
				end		--Ends CastR logic
			else		--If the user wants to use OpenPred
				local RPred = GetCircularAOEPrediction(target,AnnieR)	--Now we calc OpenPred Stuff from Table
				if RPred.hitChance < 0.2 then							--Judge HitChance
					CastSkillShot(_R,RPred.castPos)						--Cast ult at OP predicted position
				end
			end
		end	--Ends the R logic
	end		--Ends the Combo Mode
	
	--We start the Killsteal Part now, this NEEDS to be out of the Combo mode, because it has to run even if the user doesn't press Space
	for _, enemy in pairs(GetEnemyHeroes()) do 		--This will cycle 5 times and pass one hero to enemy each cycle
		if AnnieMenu.Combo.Q:Value() and AnnieMenu.Combo.KSQ:Value() and Ready(_Q) and ValidTarget(enemy, 625) then	--same checks as in combo but with KS menu (see ValidTarget now uses enemy)
			--[[
				Q Dmg Calc
				MAGIC DAMAGE: 80 / 115 / 150 / 185 / 220 (+ 80% AP)
				Level 0: 45
				Level 1: 80
				Level 2: 115 ...
				Formula 45 + 35 * CastLevel of Q + AP *0.8
				CalcDamage(startUnit, targetUnit, normalDamage, magicDamage)
			--]]
			if GetCurrentHP(enemy) < CalcDamage(myHero, enemy, 0, 45 + 35 * GetCastLevel(myHero,_Q) + GetBonusAP(myHero) * 0.8) then	--Check if the HP of enemy is lower than Q Dmg
				CastTargetSpell(enemy , _Q)			-- Cast Q
			end										--End dmg check for Q
		end				--end basic check for Q
	end			--end KS
end)		--End of the code that gets run each Tick

--[[
The code below may be a bit more advanced and is only used the autoE 
for that we create a new Callback (like OnTick) which triggeres each time someone casts a spell
AutoAttacks are also considered a spell
Their name is usually something like "AnnieBasicAttack1" so we just try to find "attack" in the spell
--]]

OnProcessSpell(function(unit,spellProc)		--Creates the callback with the object (unit is the casting unit or hero) that casts the spell (spellProc is the spell data)
	if GetTeam(unit) ~= GetTeam(myHero) and GetObjectType(unit) == Obj_AI_Hero and spellProc.name:lower():find("attack") then		--first check makes sure the spell is coming from an enemy, second checks that it is not a minion and the third checks for autoAttacks
		if AnnieMenu.Combo.E:Value() and Ready(_E) then		--usual check
			CastSpell(_E)		--CastE 
		end
	end
end)

print("Annie loaded")	--Little message to show that the script has injected without breaking
