local clock = os.clock

local function Core:GoodTarget(unit, range)
		local range = range or 25000
		return unit and unit.distance < range and not unit.dead and unit.isTargetable and unit.pos2D.onScreen and unit.health > 0
end
  
local function Sleep(time)
		local finish = clock() + time
		repeat until clock() > finish
end

function CastSpell(key, position)
		local _oldPos = mousePos
		if position and position.type == myHero.type then
			if not GoodTarget(position) then
				return
			end
		end

		if position then
			Control.SetCursorPos(position.pos2D and position.pos2D.x, position.pos2D.y or position)
		end

		if Control.KeyDown(key) then 
			Sleep(0.1)

			if Control.KeyUp(key) then
				Control.SetCursorPos(_oldPos)
			end
		end
end
