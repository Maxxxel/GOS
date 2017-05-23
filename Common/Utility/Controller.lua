local Version = 0.01
--Set Display Range
local X, Y = GetResolution().x, GetResolution().y
--Get Centerpoint
local Centerpoint = Vector(X * .5, Y * .5)
--Setup Values
local Time = 0
local Last = GetCursorPos()
local StartUp = false
--Settings-Menu
Controller = MenuConfig("COntroller", "LOL-Controller v." .. Version)
Controller:Menu("Settings", "Settings")
Controller.Settings:Slider("MouseMoveRange", "Mouse Move Range", 300, 300, Y * .5 - 100, 50)
Controller.Settings:Slider("MouseResetDelay", "Mouse Reset Delay", .1, .01, .5, .01)
Controller:Menu("Keys", "Keys")
Controller.Keys:Key("Enabled", "Global On/Off ( . )", string.byte("."), true)
Controller.Keys:Key("Enabled2", "Range Limit On/Off ( , )", 188, true)
Controller.Keys:Key("Enabled3", "Reset Limit On/Off ( - )", 189, true)
--Border Check
OnTick(function()
	if not StartUp then
		Controller.Keys.Enabled:Value(false)
		StartUp = true
	end
	
	if Controller.Keys.Enabled:Value() and Controller.Keys.Enabled2:Value() then
		local M = GetCursorPos()
		if GetDistance(M, Centerpoint) > Controller.Settings.MouseMoveRange:Value() then
			local newPos = Centerpoint - (Centerpoint - M):normalized() * Controller.Settings.MouseMoveRange:Value()
			SetCursorPos(newPos.x, newPos.y)
		end
	end

	if Controller.Keys.Enabled:Value() and Controller.Keys.Enabled3:Value() then
		local M = GetCursorPos()
		Last = GetDistance(Last, M) > 0 and M
		Time = Last and GetGameTimer() or Time

		if GetGameTimer() - Time > Controller.Settings.MouseResetDelay:Value() then
			SetCursorPos(Centerpoint.x, Centerpoint.y)
		end

		Last = M
	end
end)
