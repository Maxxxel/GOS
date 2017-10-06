local Version = 0.01
local rng, c = math.random, math.ceil

local function file_exists(name, path)
	local f = io.open((path or SCRIPT_PATH) .. name, "r")

	if f then 
		io.close(f) 
		return true 
	else 
		return false 
	end
end

class 'BS'

	function BS:__init()
		self:__loadMenu()
		self:__loadSounds()

		Callback.Add("Load", function() PlaySound(self.soundDirectory .. self.Clips[3] .. ".wav") end)
		Callback.Add("ProcessSpellCast", function(unit, spell) self:spellBefore(unit, spell) end)
		Callback.Add("ProcessSpellAttack", function(unit, spell) self:attackBefore(unit, spell) end)
		Callback.Add("ProcessSpellComplete", function(unit, spell) self:After(unit, spell) end)
	end

	function BS:__loadMenu()
		self.Menu = MenuConfig("BigShaq", "Big Shaq")
			self.Menu:Menu("Setup", "Setup")
				self.Menu.Setup:DropDown("AA", "AA Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.Menu.Setup:DropDown("AATime", "Play AA on", 1, {"After Cast", "Before Cast", "Never"})
				self.Menu.Setup:Info("Info0", "")
				self.Menu.Setup:DropDown("Q", "Q Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.Menu.Setup:DropDown("QTime", "Play Q on", 1, {"After Cast", "Before Cast", "Never"})
				self.Menu.Setup:Info("Info1", "")
				self.Menu.Setup:DropDown("W", "W Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.Menu.Setup:DropDown("WTime", "Play W on", 1, {"After Cast", "Before Cast", "Never"})
				self.Menu.Setup:Info("Info2", "")
				self.Menu.Setup:DropDown("E", "E Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.Menu.Setup:DropDown("ETime", "Play E on", 1, {"After Cast", "Before Cast", "Never"})
				self.Menu.Setup:Info("Info3", "")
				self.Menu.Setup:DropDown("R", "R Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.Menu.Setup:DropDown("RTime", "Play R on", 1, {"After Cast", "Before Cast", "Never"})
	end

	function BS:__loadSounds()
		self.soundDirectory = COMMON_PATH .. "Big Shaq\\"
		self.Clips = {
			"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
			"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra" 
		}

		if not DirExists(self.soundDirectory) then
			CreateDir(COMMON_PATH.."Big Shaq\\")
		end

		--Download files
		local reload = false
		for i = 1, #self.Clips do
			local clipName = self.Clips[i]

			if not file_exists(clipName .. ".wav", self.soundDirectory) then
				DownloadFileAsync("https://github.com/Maxxxel/GOS/blob/master/Common/Utility/req/BS/" .. clipName .. ".wav?raw=true", self.soundDirectory .. clipName .. ".wav",
				function() 
				end)

				reload = true
			end
		end

		if reload then PrintChat("<font color='#FFFF00'>Big Shaq says: </font><font color='#FFFFFF'>Download of clips was successful.\nPress 2x F6 to reload.</font>") end
	end

	function BS:attackBefore(unit, spell)
		if unit == myHero and self.Menu.Setup.AATime:Value() == 2 then
			PlaySound(self.soundDirectory .. self.Clips[self.Menu.Setup.AA:Value()] .. ".wav")
		end
	end

	function BS:spellBefore(unit, spell)
		if unit == myHero then
			if spell.name == myHero:GetSpellData(0).name and self.Menu.Setup.QTime:Value() == 2 then
				PlaySound(self.soundDirectory .. self.Clips[self.Menu.Setup.Q:Value()] .. ".wav")
			end
			if spell.name == myHero:GetSpellData(1).name and self.Menu.Setup.WTime:Value() == 2 then
				PlaySound(self.soundDirectory .. self.Clips[self.Menu.Setup.W:Value()] .. ".wav")
			end
			if spell.name == myHero:GetSpellData(2).name and self.Menu.Setup.ETime:Value() == 2 then
				PlaySound(self.soundDirectory .. self.Clips[self.Menu.Setup.E:Value()] .. ".wav")
			end
			if spell.name == myHero:GetSpellData(3).name and self.Menu.Setup.RTime:Value() == 2 then
				PlaySound(self.soundDirectory .. self.Clips[self.Menu.Setup.R:Value()] .. ".wav")
			end			
		end
	end

	function BS:After(unit, spell)
		if unit == myHero then
			if spell.name == myHero:GetSpellData(0).name and self.Menu.Setup.QTime:Value() == 1 then
				PlaySound(self.soundDirectory .. self.Clips[self.Menu.Setup.Q:Value()] .. ".wav")
			end
			if spell.name == myHero:GetSpellData(1).name and self.Menu.Setup.WTime:Value() == 1 then
				PlaySound(self.soundDirectory .. self.Clips[self.Menu.Setup.W:Value()] .. ".wav")
			end
			if spell.name == myHero:GetSpellData(2).name and self.Menu.Setup.ETime:Value() == 1 then
				PlaySound(self.soundDirectory .. self.Clips[self.Menu.Setup.E:Value()] .. ".wav")
			end
			if spell.name == myHero:GetSpellData(3).name and self.Menu.Setup.RTime:Value() == 1 then
				PlaySound(self.soundDirectory .. self.Clips[self.Menu.Setup.R:Value()] .. ".wav")
			end
			if spell.name:lower():find("attack") and self.Menu.Setup.AATime:Value() == 1 then
				PlaySound(self.soundDirectory .. self.Clips[self.Menu.Setup.AA:Value()] .. ".wav")
			end
		end
	end

BS:__init()
