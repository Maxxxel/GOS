--version 0.1
--fixed for new Loader

local myHero = GetMyHero()
local lastattackposition={true,true,true}

function IsFacing(targetFace,range,unit) --returns true if targetFace is facing UNIT in given RANGE
	range=range or 99999
	unit=unit or myHero
	targetFace=targetFace
	if (targetFace and unit)~=nil and (ValidtargetUnit(targetFace,range,unit)) and GetDistance2(targetFace,unit)<=range then
		local unitXYZ= GetOrigin(unit)
		local targetFaceXYZ=GetOrigin(targetFace)
		local lastwalkway={true,true,true}
		local walkway = GetPredictionForPlayer(GetOrigin(unit),targetFace,GetMoveSpeed(targetFace),0,1000,2000,0,false,false)
		--1. look if enemy is standing
		if walkway.PredPos.x==targetFaceXYZ.x then
			--2. if enemy is standing look if there is a last walkway position
			if lastwalkway.x~=nil then
				--3. if Position found then Draw it and check for face
				local d1 = GetDistance2(targetFace,unit)
    		local d2 = GetDistance2XYZ(lastwalkway.x,lastwalkway.z,unitXYZ.x,unitXYZ.z)
    		return d2 < d1
    		--4. if there is no Position found then set one as soon as enemy walks -->5.
    		--6. if enemy just keeps standing then check for attack direction ALPHA
    	elseif lastwalkway.x==nil then
    		if lastattackposition.x~=nil and lastattackposition.name==GetObjectName(targetFace) then
					local d1 = GetDistance2(targetFace,unit)
    			local d2 = GetDistance2XYZ(lastattackposition.x,lastattackposition.z,unitXYZ.x,unitXYZ.z)
    			return d2 < d1
    		end
    	end
    elseif walkway.PredPos.x~=targetFaceXYZ.x then
    	lastwalkway={x=walkway.PredPos.x,y=walkway.PredPos.y,z=walkway.PredPos.z} --last Position enemy looked
    	--5. if enemy keeps movin then check for face
    	if lastwalkway.x~=nil then
				local d1 = GetDistance2(targetFace,unit)
    		local d2 = GetDistance2XYZ(lastwalkway.x,lastwalkway.z,unitXYZ.x,unitXYZ.z)
    		return d2 < d1
    	end
    end
	end
end

function IsMoving(targetFace,range,unit)
end

function IsFleeing(targetFace,range,unit)
end

function IsChasing(targetFace,range,unit)
end

--MISC--
--Distances
function ValidtargetUnit(targetFace,range,unit)
    range = range or 25000
    unit = unit or myHero
    if targetFace == nil or GetOrigin(targetFace) == nil or IsImmune(targetFace,unit) or IsDead(targetFace) or not IsVisible(targetFace) or GetTeam(targetFace) == GetTeam(unit) or GetDistance2(targetFace,unit)>range then return false end
    return true
end
function GetDistance2(p1,p2)
    p1 = GetOrigin(p1) or p1
    p2 = GetOrigin(p2) or p2
    return math.sqrt(GetDistance2Sqr(p1,p2))
end
function GetDistance2Sqr(p1,p2)
    p2 = p2 or GetMyHeroPos()
    local dx = p1.x - p2.x
    local dz = (p1.z or p1.y) - (p2.z or p2.y)
    return dx*dx + dz*dz
end
function GetDistance2XYZ(x,z,x2,z2)
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

OnProcessSpell(function(Object,spellProc)
	local Obj_Type = GetObjectType(Object)
	if Object~=nil and Obj_Type==Obj_AI_Hero then
		if spellProc.name~=nil then
			for i,enemy in pairs(GetEnemyHeroes()) do
				if ValidtargetUnit(enemy,25000) then
					local targetFaceXYZ=GetOrigin(enemy)
					if (spellProc.name:find('Basic') or spellProc.name:find('Crit') and  spellProc.BaseName~=nil and spellProc.BaseName:find(GetObjectName(enemy))) then --if enemy does auto attack then set attack direction
						--1. check if targetFace is really the one attacking
						if spellProc.startPos.x==targetFaceXYZ.x and spellProc.startPos.y==targetFaceXYZ.y and spellProc.startPos.z==targetFaceXYZ.z then --so enemy is the one attacking, now check the attack direction
							if spellProc.endPos.x ~=targetFaceXYZ.x and spellProc.endPos.y ~=targetFaceXYZ.y and spellProc.endPos.z ~=targetFaceXYZ.z then --so enemy is attacking a unit
								--2. set the attacked units position as face direction
								lastattackposition={x=spellProc.endPos.x,y=spellProc.endPos.y,z=spellProc.endPos.z,Name=GetObjectName(enemy)}
								break
							else
								break
							end
						else
							break
						end
					else
						break
					end
				else
					break
				end
			end
			--[[
			elseif spellProc.name:find(GetObjectName(targetFace)) then --if enemy casts a spell BETA
				--1. check if targetFace is really the one attacking
				if spellProc.startPos.x==targetFaceXYZ.x and spellProc.startPos.y==targetFaceXYZ.y and spellProc.startPos.z==targetFaceXYZ.z then --so enemy is the one attacking, now check the attack direction
					if spellProc.endPos.x ~=targetFaceXYZ.x and spellProc.endPos.y ~=targetFaceXYZ.y and spellProc.endPos.z ~=targetFaceXYZ.z then --so enemy is attacking a unit
						--2. set the attacked units position as face direction
						lastattackposition={x=spellProc.endPos.x,y=spellProc.endPos.y,z=spellProc.endPos.z}
					end
				end
				break
			end
			]]--
		end
	end
end)
