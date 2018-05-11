# +++ extLib +++
A Collection of usefull functions for GOS External Version.
Created by Maxxxel


## Supported functions:
- OnProcessSpell

## How-To
1. Download extLib.lua and place it inside your "Common" folder
2. Write the following code at the first lines of your script
```lua 
local extLib = require 'extLib'
```
3. Create a function to handle the desired extLib-function
	- OnProcessSpell example:
    ```lua
    local function OnProcessSpell()
		local unit, spell = extLib.OnProcessSpell()

		if unit and spell then
			print(unit.charName .. " is Casting " .. spell.name)
		end
	end
    ```
4. Add your custom function to some Event
	- OnProcessSpell example:
 	```lua
	Callback.Add("Tick", OnProcessSpell)
	```
