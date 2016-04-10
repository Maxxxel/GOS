--Credits all to Yonderboi
--Version 0.2
--fixed YDistance
--ported and modified for GOS

local active_objects = {}
local reused = {}

local output1 = io.open(SCRIPT_PATH .. '_objectspeed_.csv', 'a+')
local dirty = false

--set all objects u want to check
local included = {
    '_mis.troy' -- only missiles
}
--force exlude some expressions
local excluded = {
    'cm_ba_mis.troy'
}

local function Sample(o)
    return {x=GetOrigin(o).x, y=GetOrigin(o).y, z=GetOrigin(o).z, time=GetTickCount()/1000 }
end

local function HandleCompletedCalc(stream, charname, distance, time, speed)
    if charname then
        local s = string.format('Name: %s, Distance: %.3fm, Time: %.3fs, Speed: %.3fm/s', charname, distance, time, speed)
        print("writing...")
        stream:write(s)
        stream:write('\n')
    end
end

local function GetYDistance(p1, p2)
    p1 = GetOrigin(p1) or p1
    p2 = GetOrigin(p2) or p2 or myHeroPos()
    return math.sqrt((p1.x - p2.x)*(p1.x - p2.x) + (p1.y - p2.y)*(p1.y - p2.y) + (p1.z - p2.z)*(p1.z - p2.z))
end

local function HandleCompletedObject(id, t)
    local n = #t.samples
    local first = t.samples[1]
    local last = t.samples[n]
    local distance = math.sqrt((first.x - last.x)*(first.x - last.x) + (first.y - last.y)*(first.y - last.y) + (first.z - last.z)*(first.z - last.z))--GetYDistance(first, last)
    local time = last.time-first.time
    local speed = distance/time    
    if speed > 0 and speed < 20000 then
        dirty = true
        if n < 4 then
            print("not enough samples for  calc on ".. t.charName ..", it needs more than 4, got: ".. n .." do another one")
        else        
            HandleCompletedCalc(output1, t.charName, distance, time, speed)
            print(t.charName.." calculations finished and saved")
        end
    else
        print('object discounted due to basic speed calc (s,d,t)' .."-".. speed .."-".. distance .."-".. time .."-".. n)
    end
end

local function MonitorObjects(tick)
    for id,t in pairs(active_objects) do
        local o = t.object
        if o == nil or GetObjectBaseName(o) == nil or not IsObjectAlive(o) then -- object life over
            --print('object life is over: ' .. id)
            HandleCompletedObject(id, t)
            active_objects[id] = nil -- remove from active_objects
            reused[id] = nil -- remove any id conflict
        else
            if id == GetObjectBaseName(o) then -- same id now as created with
                if o then
                    local sample = Sample(o)
                    table.insert(t.samples, sample)
                else
                    print('*** object no longer valid' .."ID: ".. GetObjectBaseName(o) ..", Name: ".. GetObjectBaseName(o))
                end
            end
        end
    end
end

local tick = 0
local function ConsiderFlush()
    if tick == 300 then -- ~10 seconds
        if dirty then
            dirty = false
            output1:flush()       
        end
        tick = 0
    end
    tick = tick + 1    
end

local function IsSensibleString(s)
    if s == nil then return false end
    -- match 0 or more words/punctuation/spaces
    return string.match(s,'^[%w%p ]*$') ~= nil
end

-- for now, to avoid all the garbage that comes through OnCreateObj, require . in charName
local function IsFilteredString(s)
    return string.find(s, '[.]') ~= nil
end

OnTick(function(myHero)
    MonitorObjects()
    ConsiderFlush()
end)

OnCreateObj(function(obj)
    if obj then
        if GetObjectType(obj):lower():find("generalparticleemitter") and IsSensibleString(GetObjectBaseName(obj)) and IsFilteredString(GetObjectBaseName(obj)) then
            if active_objects[GetObjectBaseName(obj)] == nil then
                local include = false
                local exclude = false
                if GetObjectBaseName(obj):find("Syndra") then print(GetObjectBaseName(obj)) end
                for i,v in ipairs(included) do
                    if GetObjectBaseName(obj):lower():find(v) then
                        include = true
                        break
                    end
                end
                for i,v in ipairs(excluded) do
                    if GetObjectBaseName(obj):lower():find(v) then
                        exclude = true
                        break
                    end
                end
                if include and not exclude then
                    active_objects[GetObjectBaseName(obj)] = {
                        object = obj,
                        samples = {},
                        charName = GetObjectBaseName(obj),
                        startPos = GetOrigin(obj)
                    }
                end
            else -- if a new object is created with same id as an active object, then it just got re-used
                --print("reused object detected, Name: ".. GetObjectBaseName(obj))
                reused[GetObjectBaseName(obj)] = true
            end
        else
            return
        end
    end
end)
