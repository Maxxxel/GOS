local Version = 0.02
local Author = "Maxxxel"
--Set Display Range
local X, Y = Game.Resolution().x, Game.Resolution().y
--Get Centerpoint
local Centerpoint = Vector(X * .5, Y * .5, 0)
--Setup Values
local Time = 0
local Last = cursorPos
local StartUp = false
local sqrt = math.sqrt
--Settings-Menu
Controller = MenuElement({id = "Controller", name = "LOL-Controller v." .. Version .. " [Made by " .. Author .. "]", type = MENU})
Controller:MenuElement({id = "Settings", name = "Settings", type = MENU})
Controller.Settings:MenuElement({id = "MouseMoveRange", name = "Mouse Move Range", value = 300, min = 300, max = Y * .5 - 50, step = 50})
Controller.Settings:MenuElement({id = "MouseResetDelay", name = "Mouse Reset Delay", value = .1, min = .01, max = .5, step = .01})
Controller:MenuElement({id = "Keys", name = "Keys", type = MENU})
Controller.Keys:MenuElement({id = "Enabled", name = "Global On/Off ( . )", key = string.byte("."), toggle = true})
Controller.Keys:MenuElement({id = "Enabled2", name = "Range Limit On/Off ( , )", key = 188, toggle = true})
Controller.Keys:MenuElement({id = "Enabled3", name = "Reset Limit On/Off ( - )", key = 189, toggle = true})
--Main Program
function GetDistance(A, B)
	local ABX, ABY = A.x - B.x, A.y - B.y

	return sqrt(ABX * ABX + ABY * ABY)
end

local function Main()
	if not StartUp then
		Controller.Keys.Enabled:Value(false)
		StartUp = true
	end
	
	if Controller.Keys.Enabled:Value() and Controller.Keys.Enabled2:Value() then
		if GetDistance(cursorPos, Centerpoint) > Controller.Settings.MouseMoveRange:Value() then
			local c = Vector(cursorPos.x, cursorPos.y, 0)
			local newPos = Centerpoint - (Centerpoint - c):Normalized() * Controller.Settings.MouseMoveRange:Value()

			Draw.Circle(newPos, 50)
			Control.SetCursorPos(newPos.x, newPos.y)
		end
	end

	if Controller.Keys.Enabled:Value() and Controller.Keys.Enabled3:Value() then
		Last = GetDistance(Last, cursorPos) > 0 and cursorPos
		Time = Last and Game.Timer() or Time

		if Game.Timer() - Time > Controller.Settings.MouseResetDelay:Value() then
			Control.SetCursorPos(Centerpoint.x, Centerpoint.y)
		end

		Last = cursorPos
	end
end

Callback.Add("Tick", function() Main() end)
