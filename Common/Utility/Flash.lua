--Credits to Huntera LB

local showCircle = {}

OnLoop(function(myHero)
	for i, obj in pairs(showCircle) do
		if obj and obj.target and not IsDead(obj.target) then
			if obj.timeShow>GetTickCount() then
				if not IsVisible(obj.target) then
					DrawCircle(obj.pos.x,obj.pos.y,obj.pos.z,100,5,0,0xffff0000)
					break
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
