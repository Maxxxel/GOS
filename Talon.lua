AddInfo("Talon", "Talon:")
AddButton("W", "W in Combo", true)
AddButton("E", "E in Combo", true)
AddButton("R", "R in Combo(ready)", true)
AddButton("RK", "R in Combo(kill)", true)
AddButton("AutoHarass", "AutoHarass W", true)
--AddButton("Killsteal", "Killsteal", true)
--AddButton("KillstealR", "Use R to KS", true)
AddButton("Killnotification", "Killnotifications", true)
AddButton("PercentKill", "Show HP in % left", true)

local version = 0.2
local TalonTarget
local killable=0
local Q,W,E,R = 'Q','W','E','R'
TargetableSpots={'Minion','Superminion','Golem','Lizard','Wraith','Dragon','Wolf','Tibbers','HeimerTYellow','HeimerTBlue','Mundo','Lucian','Karthus','ZyraThornPlant','ZyraGraspingPlant','Veigar','Ziggs','Zyra','Graves','Nasus','Vladimir','Soraka','Kayle','Evelynn','Caitlyn','Nidalee','Cassiopeia','Taric','Malphite','Fiddlesticks','Talon','Ahri','Ezreal','Quinn','Shyvana','Sion','Shen','Ryze','Renekton','Nasus','Annie'}

AddAfterObjectLoopEvent(function(myHero)
	--DrawText('Terror Talon 0.2 WIP ported to GOS',100,0,Color.Red)
	TalonTarget = GetTarget(700)
	local targetPos1 = GetOrigin(myHero)
	local drawPos1 = WorldToScreen(1,targetPos1.x,targetPos1.y,targetPos1.z)
	DrawText("killable:" .. killable,20,drawPos1.x,drawPos1.y,0xffff0000)
	GetCD()
  DrawMenu()
  IWalk()
  KillFunctions()
  if GetKeyValue("Combo") then
  	Combo()
  elseif GetButtonValue("AutoHarass") then
  	AutoHarass()
  end
end)

function GetCD()
	if CanUseSpell(myHero, _Q) == READY then
		QRDY = 1
	else 
		QRDY = 0 
	end
	if CanUseSpell(myHero, _W) == READY then
		WRDY = 1
	else 
		WRDY = 0 
	end
	if CanUseSpell(myHero, _E) == READY then
		ERDY = 1
	else 
		ERDY = 0 
	end
	if CanUseSpell(myHero, _R) == READY then
		RRDY = 1
	else 
		RRDY = 0 
	end
end

function AutoHarass()
	if TalonTarget~=nil and GetCurrentMana(myHero)>100 then
		CastW(TalonTarget)
	end
end

function Combo()
	if TalonTarget~=nil then
		if GetButtonValue("RK") and killable==1 then
			if GetDistance(TalonTarget)<=600 and ERDY==0 then
				CastTargetSpell(myHero,_R)
			end			
			if GetDistance(TalonTarget)<=700 then 
				if ERDY==1 then 
					CastTargetSpell(TalonTarget,_E)
				elseif ERDY==0 then 
					CastW(TalonTarget) 
				end
			end
		elseif GetButtonValue("R") and GetDistance(TalonTarget)<=600 then
			if ERDY==0 and WRDY==0 then 
				CastTargetSpell(myHero,_R)
			end
			if GetDistance(TalonTarget)<=700 then 
				if ERDY==1 then 
					CastTargetSpell(TalonTarget,_E)
				elseif ERDY==0 then 
					CastW(TalonTarget)
				end
			end
		else
			if GetDistance(TalonTarget)<=700 then 
				if ERDY==1 then 
					CastTargetSpell(TalonTarget,_E)
				elseif ERDY==0 then 
					CastW(TalonTarget)
				end
			end
		end
	end
end

function CastW(target)
	CastTargetSpell(target,_W)
end

function KillFunctions()
	for _,enemy in pairs(GetEnemyHeroes()) do
  	if ValidTarget(enemy, 25000) then
  		local AADmg = GetBonusDmg(myHero)
  		local AA = CalcDamage(myHero, enemy, (AADmg+GetBaseDamage(myHero)))
			local QDmg = 30*GetCastLevel(myHero,_Q)+.3*AADmg+10*GetCastLevel(myHero,_Q)+1.2*AADmg+AA
			local WDmg = (25*GetCastLevel(myHero,_W)+5+.6* AADmg)*2
			local EDmg = 1+GetCastLevel(myHero,_E)*.03
			local RDmg = (50*GetCastLevel(myHero,_R)+70+.9*AADmg)*2
			local QDMG = CalcDamage(myHero, enemy, QDmg)
			local WDMG = CalcDamage(myHero, enemy, WDmg)
			local EDMG = EDmg
			local RDMG = CalcDamage(myHero, enemy, RDmg)
			local Passive=0.1
			local KSValue=0
			
			--IGNITE part will do it when i know how to use Summoners
			
			--local IGN=0
			--local IgniteDmg= 50+(20*myHero.selflevel)
			--if myHero.SummonerD == 'SummonerDot' and myHero.SpellTimeD>1 then IGN=1
			--elseif myHero.SummonerF == 'SummonerDot' and myHero.SpellTimeF>1 then IGN=0 end
			--local totaldamage=(AA*2+(QDMG*QRDY)*(1+WRDY/10)+(ERDY*(EDMG-1)))+(WDMG*WRDY)*1+(ERDY*(EDMG-1))+IgniteDmg*IGN
			--local totaldamageR=(AA*2+(QDMG*QRDY)+RDMG*RRDY)*(1+WRDY/10)+(ERDY*(EDMG-1))+(WDMG*WRDY)*1+(ERDY*(EDMG-1))+IgniteDmg*IGN
			
			local totaldamage=(AA+(QDMG*QRDY)*(1+WRDY/10)+(ERDY*(EDMG-1)))+(WDMG*WRDY)*1+(ERDY*(EDMG-1))
			local totaldamageR=(AA+(QDMG*QRDY)+RDMG*RRDY)*(1+WRDY/10)+(ERDY*(EDMG-1))+(WDMG*WRDY)*1+(ERDY*(EDMG-1))
			local SUM=(GetCurrentHP(enemy)-totaldamage)/GetMaxHP(enemy)*100
			local SUM1=(GetCurrentHP(enemy)-totaldamageR)/GetMaxHP(enemy)*100
			local targetPos = GetOrigin(enemy)
			local drawPos = WorldToScreen(1,targetPos.x,targetPos.y,targetPos.z)

			if SUM<=0 and SUM1>0 then
				killable=0
				if GetButtonValue("Killnotification") then
					DrawCircle(drawPos.x,drawPos.y,50,10,0,0xffff0000)
					DrawText("Kill!!!",20,drawPos.x,drawPos.y,0xffff0000)
				end
				if GetButttonValue("PercentKill") and SUM<0 then
					SUM=0
					DrawText("\n\n" .. Round(SUM,0) .. "%" .. " | " .. Round(SUM1,0) .. "%",20,drawPos.x,drawPos.y,0xffffffff)
				end
			elseif SUM<=0 and SUM1<=0 then
				killable=0
				if GetButtonValue("Killnotification") then
					DrawCircle(drawPos.x,drawPos.y,50,10,0,0xffff0000)
					DrawText("Kill!!!",20,drawPos.x,drawPos.y,0xffff0000)
				end
				if GetButtonValue("PercentKill") and SUM<0 and SUM1<0 then
					SUM=0 SUM1=0
					DrawText("\n\n" .. Round(SUM,0) .. "%" .. " | " .. Round(SUM1,0) .. "%",20,drawPos.x,drawPos.y,0xffffffff)
				end
			elseif SUM>0 and SUM1<=0 then
				killable=1
				if GetButtonValue("Killnotification") then
					DrawCircle(drawPos.x,drawPos.y,50,10,0,0xffff0000)
					DrawText("Kill with Ulti!",20,drawPos.x,drawPos.y,0xffff0000)
				end
				if GetButtonValue("PercentKill") and SUM1<0 then
					SUM1=0
					DrawText("\n\n" .. Round(SUM,0) .. "%" .. " | " .. Round(SUM1,0) .. "%",20,drawPos.x,drawPos.y,0xffffffff)
				end
			elseif SUM>0 and SUM1>0 then
				killable=0
				if GetButtonValue("PercentKill") then
					DrawText("\n\n" .. Round(SUM,0) .. "%" .. " | " .. Round(SUM1,0) .. "%",20,drawPos.x,drawPos.y,0xffffffff)
				end
			end
			--[[ if GetButtonValue("Killsteal") then
				if enemy.health<AA*EDMG*ERDY and GetDistance(enemy)<=700 then
					CastSpellTarget("E",enemy)
					if GetDistance(enemy)<=yayo.MyRange(enemy)+50 then
						yayo.Attack(enemy)
						print("\nKS2\n")
					end 
				elseif enemy.health<QDMG*QRDY+AA and GetDistance(enemy)<=yayo.MyRange(enemy)+50 then
					if QRDY==1 and IsBuffed(enemy,"globalhit_bloodslash") and yayo.AttackReadiness()~=1 then
						CastSpellTarget("Q",myHero)
					elseif (yayo.AttackReadiness()==1 or  IsBuffed(myHero,"talon_Q_on_hit_ready_01")) then 
						yayo.Attack(enemy)
						print("\nKS3\n")
					end
				elseif enemy.health<WDMG*WRDY and GetDistance(enemy)<=700 then
					CastW(enemy) print("\nKS4\n")
				elseif enemy.health<WDMG*WRDY+IgniteDmg*IGN and GetDistance(enemy)<1400 and GetDistance(enemy)>700 then
					if WRDY==1 then
					for i = 1, objManager:GetMaxObjects(), 1 do
						local object = objManager:GetObject(i)
						if object~=nil and GetDistance(object)<700 and (object.type==20 or object.type==12) then
							for i, spot in pairs(TargetableSpots) do
								if string.find(object.name,spot) and object.charName~=myHero.charName and object.team~=myHero.team and GetDistance(object,enemy)<700 and GetDistance(object)<700 then
									if ERDY==1 then 
										CastSpellTarget('E',object)
									end
                                							CastW(enemy)
									print("\nKS4.1\n")
									if myHero.SummonerD =='SummonerDot' then
										if IsSpellReady('D')==1 then CastSpellTarget('D',enemy) end
									elseif myHero.SummonerF== 'SummonerDot' then
										if IsSpellReady('F')==1 then CastSpellTarget('F',enemy) end
									end	
								end
							end
						end 
					end end
				elseif enemy.health<QDMG*EDMG*QRDY*ERDY+AA and GetDistance(enemy)<=700 then
					CastSpellTarget("E",enemy)
					if GetDistance(enemy)<=yayo.MyRange(enemy)+50 then
						CastSpellTarget('Q',myHero)
						if IsBuffed(myHero,"talon_Q_on_hit_ready_01") then
							yayo.Attack(enemy)
							print("\nKS5\n")
						end
					end
				elseif enemy.health<WDMG*EDMG*WRDY*ERDY and GetDistance(enemy)<=700 then
					CastSpellTarget("E",enemy)
					CastW(enemy)
					print("\nKS6\n")
				elseif enemy.health<QDMG*QRDY+AA+AA and GetDistance(enemy)<=yayo.MyRange(enemy)-10 then
					yayo.DisableMove()
					if QRDY==1 and IsBuffed(enemy,"globalhit_bloodslash") and yayo.AttackReadiness()~=1 then
						CastSpellTarget("Q",myHero)
					elseif (yayo.AttackReadiness()==1 or  IsBuffed(myHero,"talon_Q_on_hit_ready_01")) then 
						yayo.Attack(enemy)
						print("\nKS7\n")
					end
				elseif enemy.health<(AA)*1.1+WDMG*WRDY and GetDistance(enemy)<=700 then
					if GetDistance(enemy)<=yayo.MyRange(enemy)+50 and WRDY==0 then
						yayo.Attack(enemy)
						print("\nKS8\n")
					else
						if GetDistance(enemy)<=700 and (yayo.AttackReadiness()<1 or GetDistance(enemy)>=yayo.MyRange(enemy)+50) then
							CastW(enemy)
						end
					end
				elseif enemy.health<(QDMG*QRDY+AA+AA)*EDMG*ERDY and GetDistance(enemy)<=700 then
					CastSpellTarget("E",enemy)
					if GetDistance(enemy)<=yayo.MyRange(enemy)-10 then
						yayo.DisableMove()
						if QRDY==1 and IsBuffed(enemy,"globalhit_bloodslash") and yayo.AttackReadiness()~=1 then
							CastSpellTarget("Q",myHero)
						elseif (yayo.AttackReadiness()==1 or  IsBuffed(myHero,"talon_Q_on_hit_ready_01")) then 
							yayo.Attack(enemy)
							print("\nKS9\n")
						end
					end
				elseif enemy.health<AA*(Passive+EDMG*ERDY)+WDMG*WRDY*EDMG*ERDY and GetDistance(enemy)<=700 then
					CastSpellTarget("E",enemy)
					if GetDistance(enemy)<=yayo.MyRange(enemy)+50 and WRDY==0 then
						yayo.Attack(enemy)
						print("\nKS10\n")
					else
						if GetDistance(enemy)<=700 and (yayo.AttackReadiness()<1 or GetDistance(enemy)>=yayo.MyRange(enemy)+50) then
							CastW(enemy)
						end
					end
				elseif enemy.health<RDMG and CfgTalonSettings.KillstealR and GetDistance(enemy)<=600 then
					CastSpellTarget("R",myHero)
					if IsBuffed(myHero,"talon_invis_cas") then CastSpellTarget("R",myHero) end
					print("\nKS11.5\n")
				elseif enemy.health<WDMG*WRDY+QDMG*QRDY*1.1+AA and GetDistance(enemy)<=700 then
					if GetDistance(enemy)<=yayo.MyRange(enemy)+50 and WRDY==0 then
						if IsBuffed(myHero,"talon_Q_on_hit_ready_01") then 
							yayo.Attack(enemy)
							print("\nKS11\n")
						else
							CastSpellTarget('Q',myHero)
						end
					else
						if GetDistance(enemy)<=700 or GetDistance(enemy)>=yayo.MyRange(enemy)+50 then
							CastW(enemy)
						end
					end
				elseif enemy.health<WDMG*EDMG*WRDY*ERDY+QDMG*QRDY*(Passive+EDMG)+AA and GetDistance(enemy)<=700 then
					CastSpellTarget("E",enemy)
					if GetDistance(enemy)<=yayo.MyRange(enemy)+50 and WRDY==0 then
						if IsBuffed(myHero,"talon_Q_on_hit_ready_01") then 
							yayo.Attack(enemy)
							print("\nKS12\n")
						else
							CastSpellTarget('Q',myHero)
						end
					else
						if GetDistance(enemy)<=700 or GetDistance(enemy)>=yayo.MyRange(enemy)+50 then
							CastW(enemy)
						end
					end
				elseif enemy.health<(AA+AA+QDMG*QRDY)*1.1+WDMG*WRDY and  GetDistance(enemy)<=700 then
					if GetDistance(enemy)<=yayo.MyRange(enemy)-10 and WRDY==0 then
						yayo.DisableMove()
						if QRDY==1 and IsBuffed(enemy,"globalhit_bloodslash") and yayo.AttackReadiness()~=1 then
							CastSpellTarget("Q",myHero)
						elseif (yayo.AttackReadiness()==1 or  IsBuffed(myHero,"talon_Q_on_hit_ready_01")) then 
							yayo.Attack(enemy)
							print("\nKS13\n")
						end
					else
						if GetDistance(enemy)<=700 or GetDistance(enemy)>=yayo.MyRange(enemy)+50 then
							CastW(enemy)
						end
					end
				elseif enemy.health<(AA+AA+QDMG*QRDY)*(Passive+EDMG*ERDY)+WDMG*WRDY*EDMG and GetDistance(enemy)<=700 then
					CastSpellTarget("E",enemy)
					if GetDistance(enemy)<=yayo.MyRange(enemy)-10 and WRDY==0 then
						yayo.DisableMove()
						if QRDY==1 and IsBuffed(enemy,"globalhit_bloodslash") and yayo.AttackReadiness()~=1 then
							CastSpellTarget("Q",myHero)
						elseif (yayo.AttackReadiness()==1 or  IsBuffed(myHero,"talon_Q_on_hit_ready_01")) then 
							yayo.Attack(enemy)
							print("\nKS14\n")
						end
					else
						if GetDistance(enemy)<=700 or GetDistance(enemy)>=yayo.MyRange(enemy)+50 then
							CastW(enemy)
						end
					end
				end
				if GetDistance(enemy)>yayo.MyRange(enemy) then
					yayo.EnableMove()
				end
			end
			--]]
		end
	end
end

--MISC--

function Round(val, decimal)
        if (decimal) then
                return math.floor( (val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
        else
                return math.floor(val + 0.5)
        end
end
