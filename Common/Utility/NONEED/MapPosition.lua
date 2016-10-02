--[[
  Map Position 1.3.2 by Husky and Manciuszz (edited by Maxxxel for Season 5 & 6)
	========================================================================

	Enables you to easily query the semantic position of a unit in the map.
	The jungle (as well as the river) is separated into inner and outer jungle
	to distinct roaming from warding champions.

	The following methods exist and return true if the unit is inside the
	specified area (or false otherwise):

	-- River Positions --------------------------------------------------------

	MapPosition:inRiver(unit)
	MapPosition:inTopRiver(unit)
	MapPosition:inTopInnerRiver(unit)
	MapPosition:inTopOuterRiver(unit)
	MapPosition:inBottomRiver(unit)
	MapPosition:inBottomInnerRiver(unit)
	MapPosition:inBottomOuterRiver(unit)
	MapPosition:inOuterRiver(unit)
	MapPosition:inInnerRiver(unit)

	-- Base Positions ---------------------------------------------------------

	MapPosition:inBase(unit)
	MapPosition:inLeftBase(unit)
	MapPosition:inRightBase(unit)

	-- Lane Positions ---------------------------------------------------------

	MapPosition:onLane(unit)
	MapPosition:onTopLane(unit)
	MapPosition:onMidLane(unit)
	MapPosition:onBotLane(unit)

	-- Jungle Positions -------------------------------------------------------

	MapPosition:inJungle(unit)
	MapPosition:inOuterJungle(unit)
	MapPosition:inInnerJungle(unit)
	MapPosition:inLeftJungle(unit)
	MapPosition:inLeftOuterJungle(unit)
	MapPosition:inLeftInnerJungle(unit)
	MapPosition:inTopLeftJungle(unit)
	MapPosition:inTopLeftOuterJungle(unit)
	MapPosition:inTopLeftInnerJungle(unit)
	MapPosition:inBottomLeftJungle(unit)
	MapPosition:inBottomLeftOuterJungle(unit)
	MapPosition:inBottomLeftInnerJungle(unit)
	MapPosition:inRightJungle(unit)
	MapPosition:inRightOuterJungle(unit)
	MapPosition:inRightInnerJungle(unit)
	MapPosition:inTopRightJungle(unit)
	MapPosition:inTopRightOuterJungle(unit)
	MapPosition:inTopRightInnerJungle(unit)
	MapPosition:inBottomRightJungle(unit)
	MapPosition:inBottomRightOuterJungle(unit)
	MapPosition:inBottomRightInnerJungle(unit)
	MapPosition:inTopJungle(unit)
	MapPosition:inTopOuterJungle(unit)
	MapPosition:inTopInnerJungle(unit)
	MapPosition:inBottomJungle(unit)
	MapPosition:inBottomOuterJungle(unit)
	MapPosition:inBottomInnerJungle(unit)


	The following methods return true if the point is inside a wall or
	intersects a wall:

	-- Wall Functions ---------------------------------------------------------

	MapPosition:inWall(point)
	MapPosition:intersectsWall(pointOrLinesegment)

	Changelog
	~~~~~~~~~

	1.0	- initial release with the most important map areas (jungle, river,
		  lanes and so on)
	1.1	- added walls and the corresponding query methods
		- added a spatial hashmap for faster realtime queries
		- added caching for instant loading
	1.2 - updated regions and walls for S5 (Maxxxel)
	1.3 - added walls for ARAM
	1.33 - added missing bushes
	
--]]

-- Dependencies ----------------------------------------------------------------
local Version = 1.35
function AutoUpdate(data)
    if tonumber(data) > tonumber(Version) then
        PrintChat("New version found! " .. data)
        PrintChat("Downloading update, please wait...")
        DownloadFileAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/MapPosition.lua", COMMON_PATH .. "MapPosition.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    end
end

GetWebResultAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/MapPosition.version", AutoUpdate)
