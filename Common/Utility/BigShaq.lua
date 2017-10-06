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

local Enemies = {}

class 'BS'

	function BS:__init()
		self:__loadMenu()
		self:__loadSounds()

		Callback.Add("ProcessSpellCast", function(unit, spell) self:spellBefore(unit, spell) end)
		Callback.Add("ProcessSpellAttack", function(unit, spell) self:attackBefore(unit, spell) end)
		Callback.Add("ProcessSpellComplete", function(unit, spell) self:After(unit, spell) end)
	end

	function BS:__loadMenu()
		self.BSMenu = MenuConfig("Menu", "Big Shaq")
			self.BSMenu:Menu("Setup", "Setup")
				self.BSMenu.Setup:Menu("Me", "My Settings")
				self.BSMenu.Setup.Me:DropDown("AA", "AA Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.BSMenu.Setup.Me:DropDown("AATime", "Play AA on", 1, {"After Cast", "Before Cast", "Never"})
				self.BSMenu.Setup.Me:Info("Info0", "")
				self.BSMenu.Setup.Me:DropDown("Q", "Q Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.BSMenu.Setup.Me:DropDown("QTime", "Play Q on", 1, {"After Cast", "Before Cast", "Never"})
				self.BSMenu.Setup.Me:Info("Info1", "")
				self.BSMenu.Setup.Me:DropDown("W", "W Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.BSMenu.Setup.Me:DropDown("WTime", "Play W on", 1, {"After Cast", "Before Cast", "Never"})
				self.BSMenu.Setup.Me:Info("Info2", "")
				self.BSMenu.Setup.Me:DropDown("E", "E Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.BSMenu.Setup.Me:DropDown("ETime", "Play E on", 1, {"After Cast", "Before Cast", "Never"})
				self.BSMenu.Setup.Me:Info("Info3", "")
				self.BSMenu.Setup.Me:DropDown("R", "R Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.BSMenu.Setup.Me:DropDown("RTime", "Play R on", 1, {"After Cast", "Before Cast", "Never"})
			for i = 1, #Enemies do
				local enemy = Enemies[i]
				local val = enemy.charName

				self.BSMenu.Setup:Menu(val, val .. " Settings")
				self.BSMenu.Setup[val]:Boolean("On", "Enabled", false)
				self.BSMenu.Setup[val]:DropDown("AA", "AA Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.BSMenu.Setup[val]:DropDown("AATime", "Play AA on", 1, {"After Cast", "Before Cast", "Never"})
				self.BSMenu.Setup[val]:Info("Info0", "")
				self.BSMenu.Setup[val]:DropDown("Q", "Q Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.BSMenu.Setup[val]:DropDown("QTime", "Play Q on", 1, {"After Cast", "Before Cast", "Never"})
				self.BSMenu.Setup[val]:Info("Info1", "")
				self.BSMenu.Setup[val]:DropDown("W", "W Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.BSMenu.Setup[val]:DropDown("WTime", "Play W on", 1, {"After Cast", "Before Cast", "Never"})
				self.BSMenu.Setup[val]:Info("Info2", "")
				self.BSMenu.Setup[val]:DropDown("E", "E Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.BSMenu.Setup[val]:DropDown("ETime", "Play E on", 1, {"After Cast", "Before Cast", "Never"})
				self.BSMenu.Setup[val]:Info("Info3", "")
				self.BSMenu.Setup[val]:DropDown("R", "R Sound", rng(1, 22), {"44", "All_Time_I_Sneak", "Big_Shaq", "Boom", "Boom2", "Boom3", "Brother", "Charles2", "Chipmunk", "Concentry", "ConMansHeadRuf", "Dulukrupulpubum",
								"Just_Sauce", "Man_Say_Squadeded", "No_Ketchup", "Pupurrubum", "Quak", "Quick_Maths", "Raw_Sauce", "Rrratnu", "Skia", "Skrrrrrra"})
				self.BSMenu.Setup[val]:DropDown("RTime", "Play R on", 1, {"After Cast", "Before Cast", "Never"})
			end

		return true
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
		if unit == myHero and self.BSMenu.Setup.Me.AATime:Value() == 2 then
			PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup.Me.AA:Value()] .. ".wav")
		end

		for i = 1, #Enemies do
			local enemy = Enemies[i]

			if unit == enemy and self.BSMenu.Setup[enemy.charName].On:Value() and self.BSMenu.Setup[enemy.charName].AATime:Value() == 2 then
				PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup[enemy.charName].AA:Value()] .. ".wav")
			end
		end
	end

	function BS:spellBefore(unit, spell)
		if unit == myHero then
			if spell.name == myHero:GetSpellData(0).name and self.BSMenu.Setup.Me.QTime:Value() == 2 then
				PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup.Me.Q:Value()] .. ".wav")
			end
			if spell.name == myHero:GetSpellData(1).name and self.BSMenu.Setup.Me.WTime:Value() == 2 then
				PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup.Me.W:Value()] .. ".wav")
			end
			if spell.name == myHero:GetSpellData(2).name and self.BSMenu.Setup.Me.ETime:Value() == 2 then
				PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup.Me.E:Value()] .. ".wav")
			end
			if spell.name == myHero:GetSpellData(3).name and self.BSMenu.Setup.Me.RTime:Value() == 2 then
				PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup.Me.R:Value()] .. ".wav")
			end			
		end

		for i = 1, #Enemies do
			local enemy = Enemies[i]

			if unit == enemy and self.BSMenu.Setup[enemy.charName].On:Value() then
				if spell.name == enemy:GetSpellData(0).name and self.BSMenu.Setup[enemy.charName].QTime:Value() == 2 then
					PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup[enemy.charName].Q:Value()] .. ".wav")
				end
				if spell.name == enemy:GetSpellData(1).name and self.BSMenu.Setup[enemy.charName].WTime:Value() == 2 then
					PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup[enemy.charName].W:Value()] .. ".wav")
				end
				if spell.name == enemy:GetSpellData(2).name and self.BSMenu.Setup[enemy.charName].ETime:Value() == 2 then
					PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup[enemy.charName].E:Value()] .. ".wav")
				end
				if spell.name == enemy:GetSpellData(3).name and self.BSMenu.Setup[enemy.charName].RTime:Value() == 2 then
					PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup[enemy.charName].R:Value()] .. ".wav")
				end			
			end
		end
	end

	function BS:After(unit, spell)
		if unit == myHero then
			if spell.name == myHero:GetSpellData(0).name and self.BSMenu.Setup.Me.QTime:Value() == 1 then
				PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup.Me.Q:Value()] .. ".wav")
			end
			if spell.name == myHero:GetSpellData(1).name and self.BSMenu.Setup.Me.WTime:Value() == 1 then
				PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup.Me.W:Value()] .. ".wav")
			end
			if spell.name == myHero:GetSpellData(2).name and self.BSMenu.Setup.Me.ETime:Value() == 1 then
				PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup.Me.E:Value()] .. ".wav")
			end
			if spell.name == myHero:GetSpellData(3).name and self.BSMenu.Setup.Me.RTime:Value() == 1 then
				PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup.Me.R:Value()] .. ".wav")
			end
			if spell.name:lower():find("attack") and self.BSMenu.Setup.Me.AATime:Value() == 1 then
				PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup.Me.AA:Value()] .. ".wav")
			end
		end

		for i = 1, #Enemies do
			local enemy = Enemies[i]

			if unit == enemy and self.BSMenu.Setup[enemy.charName].On:Value() then
				if spell.name == enemy:GetSpellData(0).name and self.BSMenu.Setup[enemy.charName].QTime:Value() == 1 then
					PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup[enemy.charName].Q:Value()] .. ".wav")
				end
				if spell.name == enemy:GetSpellData(1).name and self.BSMenu.Setup[enemy.charName].WTime:Value() == 1 then
					PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup[enemy.charName].W:Value()] .. ".wav")
				end
				if spell.name == enemy:GetSpellData(2).name and self.BSMenu.Setup[enemy.charName].ETime:Value() == 1 then
					PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup[enemy.charName].E:Value()] .. ".wav")
				end
				if spell.name == enemy:GetSpellData(3).name and self.BSMenu.Setup[enemy.charName].RTime:Value() == 1 then
					PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup[enemy.charName].R:Value()] .. ".wav")
				end
				if spell.name:lower():find("attack") and self.BSMenu.Setup[enemy.charName].AATime:Value() == 1 then
					PlaySound(self.soundDirectory .. self.Clips[self.BSMenu.Setup[enemy.charName].AA:Value()] .. ".wav")
				end	
			end
		end
	end

DelayAction(function()
	Enemies = GetEnemyHeroes()

	BS:__init()
end, .1)
