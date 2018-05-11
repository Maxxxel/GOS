local extLibVersion = 0.01
local units = {}

--=== Load all Heroes and set table ===--
for i = 1, Game.HeroCount() do
	local unit = Game.Hero(i)
	units[i] = {unit = unit, spell = nil}
end

local function OnProcessSpell()
	for i = 1, #units do
		local unit = units[i].unit
		local last = units[i].spell
		local spell = unit.activeSpell

		if spell and last ~= (spell.name .. spell.startTime) and unit.isChanneling then
			units[i].spell = spell.name .. spell.startTime

			return unit, spell
		end
	end

	return nil, nil
end

return {
	OnProcessSpell = OnProcessSpell
}

--[[
		Usage:
	
	--Load the library
	local extLib = require 'OnProcessSpell'
	
	--Create function to handle OnProcessSpell
	local function OnProcessSpell()
	    local unit, spell = extLib.OnProcessSpell()

	    if unit and spell then
	        print(unit.charName .. " is Casting " .. spell.name)
	    end
	end
	
	--Add the func on Tick
	Callback.Add("Tick", OnProcessSpell)


	OnProcessSpell returns:
		unit: the caster
			...
		spell: the spell object
			.valid
			.level
			.name
			.startPos -- Vector
			.placementPos -- Vector
			.target -- GameObject handle
			.windup
			.animation
			.range
			.mana
			.width
			.speed
			.coneAngle
			.coneDistance
			.acceleration
			.castFrame
			.maxSpeed
			.minSpeed
			.spellWasCast
			.isAutoAttack
			.isCharging
			.isChanneling
			.startTime
			.castEndTime
			.endTime
			.isStopped
--]]
