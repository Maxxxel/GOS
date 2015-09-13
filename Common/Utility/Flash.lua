--Credits to Huntera LB

local showCircle = {}
local myHero = GetMyHero()

OnLoop(function(myHero)
  local myHeroPos = GetOrigin(myHero)
	for i, obj in pairs(showCircle) do
		if obj and obj.target and not IsDead(obj.target) then
			if obj.timeShow>GetTickCount() then
				if not IsVisible(obj.target) then
                                  if GetDistanceXYZ(obj.pos.x, obj.pos.z, myHeroPos.x, myHeroPos.z)>700 then
                                    local O=Vector(obj.pos.x, obj.pos.y, obj.pos.z)
                                    local M=Vector(myHeroPos.x, myHeroPos.y, myHeroPos.z)
                                    local Pos=M+(M-O)*(-0.7/GetDistanceXYZ(obj.pos.x, obj.pos.z, myHeroPos.x, myHeroPos.z))  
                                    DrawCircle(Pos.x, Pos.y, Pos.z,100,5,0,0xffff0000) 
				    break
                                  end
				end
			else
				table.remove(showCircle, i)
				break
			end
		end
	end
end)

OnProcessSpell(function(Object,spellProc)
	if (Object and spellProc) then
		if GetObjectType(Object)==Obj_AI_Hero and GetTeam(Object)~=GetTeam(myHero) then
			if 	spellProc.name:lower():find("summonerflash") or spellProc.name:lower():find("ezrealarcaneshift") or spellProc.name:lower():find("leblancslide") or spellProc.name:lower():find("riftwalk") or spellProc.name:lower():find("katarinae") or spellProc.name:lower():find("deceive") or spellProc.name:lower():find("vaynetumble") then
				table.insert(showCircle,{target=Object,name=GetObjectName(Object),timeShow=GetTickCount()+3000,pos={x=spellProc.endPos.x,y=spellProc.endPos.y,z=spellProc.endPos.z}})
			end
		end
	end
end)

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
