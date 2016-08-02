-- port of MapPosition, without modifying original files - yonderboi
--
-- v01 - 5/23/2013 10:13:43 AM - initial release
-- v02 - 5/23/2013 12:02:16 PM - added support for the two wall functions, isWall and intersectsWall
-- v03 - 5/23/2013 5:18:35 PM  - added a new function, MapPosition:inBush(unit)
-- v04 - 5/23/2013 5:50:41 PM  - added MapPosition:inMyBase(unit) and MapPosition:inMyJungle(unit)
-- v05 - 5/23/2013 7:42:07 PM  - uses spatial map for inBush, Common dir now required, inWall/inBush also accept units
-- v06 - 11/28/2014 12:20:00 PM - updated Bushes and Walls for S5 (Maxxxel)
-- v07 - 12/10/2015 19:13:00 PM - added all maps (Maxxxel)
-- v08 - 04/01/2016 13:51 - changed SCRIPTPATH
-- v09 - 04/11/2016		- fixed bushes error, added auto update
--
-- requires MapPosition.lua and 2DGeometry.lua
--
-- the script will generate cache files on the first run, this takes ~3 seconds on jit
--
-- see MapPosition.lua for documentation
if _G.MapPositionGOS then return end
local Version = 0.92
function AutoUpdate(data)
    if tonumber(data) > tonumber(Version) then
        PrintChat("New version found! " .. data)
        PrintChat("Downloading update, please wait...")
        DownloadFileAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/MapPositionGOS.lua", COMMON_PATH .. "MapPositionGOS.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    end
end

GetWebResultAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/MapPositionGOS.version", AutoUpdate)

require 'MapPosition'
local mapID = GetMapID()
local open, insert = io.open, table.insert

local function file_exists(path)
    local f = open(path, "r") if f ~= nil then f:close() return true else return false end
end

local lclass = class
local function bclass(name)
    local c = lclass()
    _G[name] = c
end

class = bclass
class = lclass

local walls_cached
local bushes_cached

if mapID == HOWLING_ABYSS then
	walls_cached = file_exists(COMMON_PATH .. "MapPosition_walls_1_2.lua")
	bushes_cached = file_exists(COMMON_PATH .. "MapPosition_bushes_2.lua")
elseif mapID == CRYSTAL_SCAR then
	walls_cached = file_exists(COMMON_PATH .. "MapPosition_walls_1_3.lua")
	bushes_cached = file_exists(COMMON_PATH .. "MapPosition_bushes_3.lua")
elseif mapID == TWISTED_TREELINE then
	walls_cached = file_exists(COMMON_PATH .. "MapPosition_walls_1_4.lua")
	bushes_cached = file_exists(COMMON_PATH .. "MapPosition_bushes_4.lua")
else
	walls_cached = file_exists(COMMON_PATH .. "MapPosition_walls_1_1.lua")
	bushes_cached = file_exists(COMMON_PATH .. "MapPosition_bushes_1.lua")
end


local bushQuads = { 
-- this data slightly inaccurate in places
--Bush #1 left Base, right after base entryy,mid lane, if inaccurate modify the values
	 	{x1=5440,x2=5386,x3=5734,x4=5824,z1=3218,z2=3522,z3=3582,z4=3508 },
--Bush #2 more right, under Red, if inaccurate modify the values
		{x1=6574,x2=6558,x3=7104,x4=7174,z1=3158,z2=3002,z3=2998,z4=3208 },
--Bush #3 under Red, if inaccurate modify the values
		{x1=7848,x2=7778,x3=8046,x4=8364,z1=3618,z2=3486,z3=3334,z4=3638 },
--Bush #5 left from Red, if inaccurate modify the values
		{x1=6694,x2=6372,x3=6442,x4=6712,z1=4524,z2=4470,z3=4860,z4=4848 },
--Bush #6 over Red ,if inaccurate modify the values
		{x1=8402,x2=8642,x3=8710,x4=8618,z1=4876,z2=4974,z3=4562,z4=4460 },
--Bush #7 bot golems, if inaccurate modify the values
		{x1=8922,x2=9072,x3=9493,x4=9352,z1=2208,z2=1958,z3=2010,z4=2340 },
--Bush #8 tribush bot, if inaccurate modify the values INACCURATE
		{x1=10322,x2=10638,x3=10272,x4=10178,z1=2808,z2=2970,z3=3258,z4=2950 },
		{x1=10656,x2=10372,x3=10218,x4=10176,z1=31468,z2=3258,z3=3282,z4=2910 },
--Bush #9 botlane bush1, if inaccurate modify the values
		{x1=12128,x2=12038,x3=12800,x4=13000,z1=1130,z2=1356,z3=1938,z4=1596 },
--Bush #10 botlane bush2, if inaccurate modify the values
		{x1=13192,x2=13068,x3=13480,x4=14000,z1=2000,z2=2200,z3=2904,z4=2610 },
--Bush #11 botlane bush3 if inaccurate modify the values
		{x1=12060,x2=11830,x3=11698,x4=12064,z1=3632,z2=3613,z3=4158,z4=4267 },
--Bush #12 drake bush, if inaccurate modify the values
		{x1=9449,x2=9588,x3=9454,x4=9290,z1=5506,z2=5577,z3=5751,z4=5674 },
--Bush #13 mid river bush right, if inaccurate modify the values
		{x1=8222,x2=7920,x3=8575,x4=8827,z1=6058,z2=6234,z3=6803,z4=6650 },
--Bush #14 river to blue bot, if inaccurate modify the values
		{x1=9786,x2=10036,x3=9855,x4=9536,z1=6224,z2=6558,z3=6735,z4=6432 },
--Bush #15 tribush botlane red base, if inaccurate modify the values
		{x1=12558,x2=12281,x3=12272,x4=12586,z1=4890,z2=5043,z3=5297,z4=5554 },
		{x1=12724,x2=12693,x3=12582,x4=12293,z1=5403,z2=4903,z3=4816,z4=5113 },
--Bush #16 blue buff bot, if inaccurate modify the values
		{x1=11602,x2=11596,x3=11318,x4=11300,z1=7230,z2=7032,z3=7066,z4=7309 },
--Bush #17 bot lane bush halfway, if inaccurate modify the values
		{x1=14031,x2=14009,x3=14236,x4=14288,z1=7166,z2=6783,z3=6763,z4=7182 },
--Bush #18 over blue bot, if inaccurate modify the values
		{x1=10131,x2=9974,x3=9701,x4=9857,z1=7715,z2=8106,z3=8109,z4=7702 },
--Bush #19 between top/bot if inaccurate modify the values
		{x1=4674,x2=4784,x3=4927,x4=4918,z1=7236,z2=6992,z3=6954,z4=7284 },
--Bush #20 blue buf top lane, if inaccurate modify the values
		{x1=3253,x2=3274,x3=3574,x4=3557,z1=7867,z2=7706,z3=7706,z4=7859 },
--Bush #21 top lane bush leftside, if inaccurate modify the values
		{x1=926,x2=896,x3=627,x4=636,z1=7916,z2=8312,z3=8390,z4=7890 },
--Bush #22 tribush top lane leftside, if inaccurate modify the values
		{x1=2133,x2=2144,x3=2322,x4=2418,z1=9520,z2=9966,z3=10076,z4=9644 },
		{x1=2224,x2=2578,x3=2579,x4=2284,z1=9456,z2=9632,z3=9782,z4=9860 },
--Bush #23 baron bush mid, if inaccurate modify the values
		{x1=5232,x2=5379,x3=5191,x4=5024,z1=8964,z2=9140,z3=9301,z4=9166 },
--Bush #24 mid river left, if inaccurate modify the values
		{x1=6122,x2=6770,x3=6942,x4=6324,z1=8159,z2=8660,z3=8526,z4=8056 },
--Bush #25 toplane river, if inaccurate modify the values
		{x1=3164,x2=2993,x3=2724,x4=2908,z1=10764,z2=11422,z3=11356,z4=10726 },
--Bush #26 toplane tribush, if inaccurate modify the values
		{x1=4481,x2=4574,x3=4724,x4=4514,z1=11449,z2=11556,z3=11956,z4=12058 },
		{x1=4514,x2=4214,x3=4172,x4=4400,z1=12058,z2=11984,z3=11750,z4=11546 },
--Bush #27 toplane bush 1, if inaccurate modify the values
		{x1=956,x2=1220,x3=1420,x4=1003,z1=12030,z2=12048,z3=12474,z4=12675 },
--Bush #28 toplane bush 2, if inaccurate modify the values
		{x1=1369,x2=1640,x3=1902,x4=1665,z1=12901,z2=12755,z3=13027,z4=13494 },
--Bush #29 toplane bush 3, if inaccurate modify the values
		{x1=2063,x2=2251,x3=2722,x4=2626,z1=13466,z2=13259,z3=13489,z4=13752 },
--Bush #30 toplane midway, if inaccurate modify the values
		{x1=5998,x2=5829,x3=5404,x4=5416,z1=12688,z2=12947,z3=12752,z4=12564 },
--Bush #31 top red bush, if inaccurate modify the values
		{x1=6982,x2=7070,x3=6872,x4=6385,z1=11281,z2=11385,z3=11548,z4=11402 },
		{x1=6385,x2=6540,x3=7008,x4=6680,z1=11402,z2=11238,z3=11275,z4=11540 },
--Bush #32 top red chicken, if inaccurate modify the values
		{x1=8167,x2=8348,x3=8410,x4=8179,z1=10114,z2=10056,z3=10425,z4=10462 },
--Bush #33 over red top, if inaccurate modify the values
		{x1=8254,x2=8274,x3=7873,x4=7618,z1=11684,z2=11856,z3=11933,z4=11730 },
--Bush #34 top.mid after base, if inaccurate modify the values
		{x1=8984,x2=9417,x3=9432,x4=8968,z1=11347,z2=11340,z3=11634,z4=11410 },
--Bushes #35 and 36, after second towers top(lila) and botlane(blue)
		{x1=7586,x2=7654,x3=7998,x4=8022,z1=744,z2=880,z3=898,z4=758},
		{x1=6924,x2=6976,x3=7282,x4=7372,z1=14106,z2=14022,z3=14048,z4=14106},
--Bushes #37 top lane red left
		{x1=6358,x2=6242,x3=6118,x4=6224,z1=10084,z2=10078,z3=10472,z4=10556}
}

local bushQuadsHA = {
}

local bushQuadsCS = {
}

local bushQuadsTT = {
}

bushes = {}
local bushesformap

if mapID == HOWLING_ABYSS then
	bushesformap = bushQuadsHA
elseif mapID == CRYSTAL_SCAR then
	bushesformap = bushQuadsCS
elseif mapID == TWISTED_TREELINE then
	bushesformap = bushQuadsTT
else
	bushesformap = bushQuads
end

if bushesformap then
	for i=1,#bushesformap do
    local b = bushesformap[i]
    local poly = Polygon(Point(b.x1,b.z1), Point(b.x2,b.z2), Point(b.x3,b.z3), Point(b.x4,b.z4))
    insert(bushes, poly)
	end
end

-- adding 'inMyBase' & 'inMyJungle'

function MapPosition:inMyBase(unit)
    local team = GetTeam(myHero)
    if team == 100 then
        return MapPosition:inLeftBase(unit)
    elseif team == 200 then
        return MapPosition:inRightBase(unit)
    else
        error('unknown team: '..tostring(team))
    end
end

function MapPosition:inMyJungle(unit)
    local team = GetTeam(myHero)
    if team == 100 then
        return MapPosition:inLeftJungle(unit)
    elseif team == 200 then
        return MapPosition:inRightJungle(unit)
    else
    end
end

-- spatial maps --
if walls_cached then
    PrintChat('*** MapPositionGOS: loading wall cache')
else
    PrintChat('*** MapPositionGOS: generating wall cache')
end
MapPosition:__init()

-- wrap inWall so it accepts units as well as points
MapPosition.inWallReal = MapPosition.inWall
function MapPosition:inWall(o)
    local point    
    
    if o.z ~= nil then
        point = Point(o.x, o.z)    
    else
        point = o
    end
    return MapPosition:inWallReal(point)
end

if bushes_cached then
    PrintChat('*** MapPositionGOS: loading bush cache')
else
    PrintChat('*** MapPositionGOS: generating bush cache')
end
if mapID == HOWLING_ABYSS then
	MapPosition.bushSpatialHashMap = SpatialHashMap(bushes, 400, "bushes_2")
elseif mapID == CRYSTAL_SCAR then
	MapPosition.bushSpatialHashMap = SpatialHashMap(bushes, 400, "bushes_3")
elseif mapID == TWISTED_TREELINE then
	MapPosition.bushSpatialHashMap = SpatialHashMap(bushes, 400, "bushes_4")
else
	MapPosition.bushSpatialHashMap = SpatialHashMap(bushes, 400, "bushes_1")
end

function MapPosition:inBush(o)  
    local point    
    if o.z ~= nil then
        point = Point(o.x, o.z)    
    else
        point = o
    end
    for bushId, bush in ipairs(self.bushSpatialHashMap:getSpatialObjects(point)) do
        if bush:__contains(point) then
            return true
        end
    end
    return false
end
