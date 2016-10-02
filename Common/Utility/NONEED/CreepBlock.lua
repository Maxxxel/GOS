--version 0.1
--updated for new loader

require('MapPositionGOS')

function CreepBlock(x,y,z,width)
    local PosCheck={x=x,y=y,z=z}
    width=width+40
    if PosCheck.x~=nil then
        local Q=ClosestMinion(PosCheck,MINION_ENEMY)
        local J=ClosestMinion(PosCheck,MINION_JUNGLE)
        local QPos,JPos=GetOrigin(Q),GetOrigin(J)
    if Q~=nil or J~=nil then
            if GetDistanceXYZ(QPos.x,QPos.z,PosCheck.x,PosCheck.z)<=width then
                return 1
            elseif GetDistanceXYZ(JPos.x,JPos.z,PosCheck.x,PosCheck.z)<=width then
                return 1
            elseif MapPosition:inWall(PosCheck)==true then
                return 1
            else
                return 0
            end
        end
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
