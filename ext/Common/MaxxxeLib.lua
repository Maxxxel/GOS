--[[
	Maxxxel's Library that is used by most of his Scripts

	0.1: Release for ext

--]]
if _G._MaxxxeLib then return end

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

local Version = 0.1
MapID = Game.mapID --HOWLING_ABYSS, TWISTED_TREELINE, CRYSTAL_SCAR, SUMMONERS_RIFT
insert, remove, concat = table.insert, table.remove, table.concat
Next = next
max, min = math.max, math.min
ceil, floor = math.ceil, math.floor
abs = math.abs
sqrt = math.sqrt
huge = math.huge
ASCENDINGSORT = function(t, a, b) return t[b] > t[a] end
DESCENDINGSORT = function(t, a, b) return t[b] < t[a] end
local QREADY = function(unit) return unit:GetSpellData(_Q).currentCd == 0 and unit:GetSpellData(_Q).level > 0 end
local WREADY = function(unit) return unit:GetSpellData(_Q).currentCd == 0 and unit:GetSpellData(_W).level > 0 end
local EREADY = function(unit) return unit:GetSpellData(_Q).currentCd == 0 and unit:GetSpellData(_E).level > 0 end
local RREADY = function(unit) return unit:GetSpellData(_Q).currentCd == 0 and unit:GetSpellData(_R).level > 0 end
local Libs = {
	["MapPositionGOS"] = {path = "https://raw.githubusercontent.com/Maxxxel/GOS/master/ext/Common/MapPositionGOS.lua", name = "MapPositionGOS"},
	["runrunrun"] = {path = "https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/runrunrun.lua", name = "runrunrun.lua"},
	["2DGeometry"] = {path = "https://raw.githubusercontent.com/Maxxxel/GOS/master/ext/Common/2DGeometry", name = "2DGeometry.lua"},
	["DamageLib"] = {path = "https://raw.githubusercontent.com/D3ftsu/GoSExt/master/Common/DamageLib.lua", name = "DamageLib.lua"},
	--["Collision"] = {path = "https://raw.githubusercontent.com/Maxxxel/GOS/master/Common/Utility/Collision.lua", name = "Collision.lua"},
	--["Analytics"] = {path = "https://raw.githubusercontent.com/LoggeL/GoS/master/Analytics.lua", name = "Analytics.lua"},
	--["IPrediction"] = {path = nil, name = "IPrediction.lua"},
	--["OpenPredict"] = {path = nil, name = "OpenPredict.lua"}
}
------------------

function UpdateLibs()
	--Check for missing Libs
	for _, Lib in pairs(Libs) do
		if not file_exists(COMMON_PATH .. Lib.name) then
			if Lib.path then
				print("\n\n\n\n\n\n\n\n\n")
				PrintChat(Lib.name .. " is missing. \nDownloading now...")
				DownloadFileAsync(Lib.path, COMMON_PATH .. Lib.name, function() return end)
				DelayAction(function()
					print("\n\n\n\n\n\n\n\n\n")
					PrintChat("Press 2x F6 to reload.")
				end, 5)
				return false
			else
				print("\n\n\n\n\n\n\n\n\n")
				print(_ .. " is missing and cant be downloaded. Download it manually. Script is ending now.")
				return false
			end
		end
	end

	return true
end

if not UpdateLibs() then return false end

require 'runrunrun'
require '2DGeometry'
require 'DamageLib'

local function VectorPointProjectionOnLineSegment(v1, v2, v)
    assert(v1 and v2 and v, "VectorPointProjectionOnLineSegment: wrong argument types (3 <Vector> expected)")
    local v = v.pos
    local v1 = v1.pos
    local v2 = v2.pos
    local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
    local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
    local isOnSegment = rS == rL
    local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
    return pointSegment, pointLine, isOnSegment
end

function GetDistance(A, B)
	B = B or myHero
	local PosA = {x = A.x or A.pos.x, y = A.y or (A.pos and A.pos.y) or 0, z = A.z or (A.pos and A.pos.z) or 0}
	local PosB = {x = B.x or B.pos.x, y = B.y or (B.pos and B.pos.y) or 0, z = B.z or (B.pos and B.pos.z) or 0}
	local value = sqrt((PosA.x - PosB.x) * (PosA.x - PosB.x) + (PosA.y - PosB.y) * (PosA.y - PosB.y) + (PosA.z - PosB.z) * (PosA.z - PosB.z))
	return value
end

class '_MaxxxeLib'

	function _MaxxxeLib:__init(Load)
		Callback.Add("Load", function() self:Load() end)
		--TS
		self.selectedChamp = nil
		self.targetSelector = {}
		self.TSChamps = {}
		self.TSCount = 0
		self.TStypeDmg = nil
		self.TSPriority = nil
		self.TSSelectable = nil
		self._TS = {[1] = "DMG", [2] = "Close", [3] = "HP"}
		--Buff
		self.Dusked = false
		self.Sheen = false
		self.Trinity = false
		self.ShadowAssault = false
		--Orbwalker variables
		self.Orb = nil
		self.Mode = ""
		--Autolevel variables
		self.levelUP = nil
		--Autopots variables		
		self.wUsedAt = 0
		self.vUsedAt = 0
		self.bUsedAt = 0
		self.eUsedAt = 0
		self.Base = 
			MapID == TWISTED_TREELINE and myHero.team == 100 and {x=1076, y=150, z=7275} or myHero.team == 200 and {x=14350, y=151, z=7299} or
			MapID == SUMMONERS_RIFT and myHero.team == 100 and {x=419,y=182,z=438} or myHero.team == 200 and {x=14303,y=172,z=14395} or
			MapID == HOWLING_ABYSS and myHero.team == 100 and {x=971,y=-132,z=1180} or myHero.team == 200 and {x=11749,y=-131,z=11519} or
			MpaID == CRYSTAL_SCAR and {x = 0, y = 0, z = 0}
		self.PotSlots = {
			[2003] = "HP", 
			[2031] = "Crystal", 
			[2009] = "Biscuit", 
			[2010] = "Biscuit", 
			[2138] = "Elixir"
		}
		--Wards
		self.WardSlots = {
			[1] = 3340,
			[2] = 2049,
			[3] = 2045,
			[4] = 2043,
			[5] = 2401,
			[6] = 2402,
			[7] = 2403
		}
		--Spell/Summs variables
		self.Ludensstacks = 0
		self._I = myHero:GetSpellData(SUMMONER_1).name:lower():find("summonerdot") and SUMMONER_1 or myHero:GetSpellData(SUMMONER_2).name:lower():find("summonerdot") and SUMMONER_2 or nil
		self.Ludens = {ready = function() return self.Ludensstacks == 100 end, damage = function(unit) return unit and CalcMagicalDamage(myHero, unit, 100 + .1 * myHero.ap) or 0 end}
		self.Ignite = {range = 650, ready = function() return self._I and myHero:GetSpellData(self._I).currentCd == 0 end, damage = function() return myHero.levelData.lvl * 20 + 50 end}
		--CC tables
		self.HardCC = {
			[5] = true, 
			[8] = true, 
			[10] = true, 
			[11] = true, 
			[18] = true, 
			[21] = true, 
			[22] = true, 
			[24] = true, 
			[29] = true
		}
		self.CCName = {
			["Aura"] = 1,
			["CombatEnchancer"] = 2,
			["CombatDehancer"] = 3,
			["SpellShield"] = 4,
			["Stun"] = 5,
			["Invisibility"] = 6,
			["Silence"] = 7,
			["Taunt"] = 8,
			["Polymorph"] = 9,
			["Slow"] = 10,
			["Snare"] = 11,
			["Damage"] = 12,
			["Heal"] = 13,
			["Haste"] = 14,
			["SpellImmunity"] = 15,
			["PhysicalImmunity"] = 16,
			["Invulnerability"] = 17,
			["Sleep"] = 18,
			["NearSight"] = 19,
			["Frenzy"] = 20,
			["Fear"] = 21,
			["Charm"] = 22,
			["Poison"] = 23,
			["Suppression"] = 24,
			["Blind"] = 25,
			["Counter"] = 26,
			["Shred"] = 27,
			["Flee"] = 28,
			["Knockup"] = 29,
			["Knockback"] = 30,
			["Disarm"] = 31,
			["AllHard"] = 65
		}
		self.Escapes = {
		    ['Aatrox'] = {bool = function(enemy) return (QREADY(enemy)) end},
		    ['Ahri'] = {bool = function(enemy) return (RREADY(enemy)) end},
		    ['Azir'] = {bool = function(enemy) return (EREADY(enemy) and _MaxxxeLib.IsBuffed[enemy.networkID] and _MaxxxeLib.IsBuffed[enemy.networkID].name == 'Azir_Base_P_Soldier_Ring') end},
		    ['Caitlyn'] = {bool = function(enemy) return (EREADY(enemy)) end},
		    ['Corki'] = {bool = function(enemy) return (WREADY(enemy)) end},
		    ['Elise'] = {bool = function(enemy) return (((EREADY(enemy) and enemy.range < 550) or (EREADY(enemy) and RREADY(enemy) and enemy.range >= 550))) end},
		    ['Ezreal'] = {bool = function(enemy) return (EREADY(enemy)) end},
		    ['Fiora'] = {bool = function(enemy) return ((RREADY(enemy)) or (QREADY(enemy) and AlliesAround(enemy, 600) > 0) or (QREADY(enemy) and MinionsAround(enemy, 600) > 0)) end},
		    ['Fizz'] = {bool = function(enemy) return (EREADY(enemy) or (QREADY(enemy) and AlliesAround(enemy, 550) > 0) or (QREADY(enemy) and MinionsAround(enemy, 550) > 0)) end},
		    ['Gnar'] = {bool = function(enemy) return (EREADY(enemy)) end},
		    ['Gragas'] = {bool = function(enemy) return (EREADY(enemy)) end},
		    ['Graves'] = {bool = function(enemy) return (EREADY(enemy)) end},
		    ['Hecarim'] = {bool = function(enemy) return (RREADY(enemy)) end},
		    ['JarvanIV'] = {bool = function(enemy) return (QREADY(enemy) and (EREADY(enemy) or (_MaxxxeLib.IsBuffed[enemy.networkID] and _MaxxxeLib.IsBuffed[enemy.networkID].name == 'Flag_Name'))) end},
		    ['Jax'] = {bool = function(enemy) return ((QREADY(enemy) and #Katarina_LBSeries:GetJumpableSpots(enemy, 700) > 0) or (QREADY(enemy) and AlliesAround(enemy, 700) > 0) or (QREADY(enemy) and MinionsAround(enemy, 700) > 0)) end},
		    ['Kassadin'] = {bool = function(enemy) return (RREADY(enemy)) end},
		    ['Kennen'] = {bool = function(enemy) return (EREADY(enemy)) end},
		    ['Khazix'] = {bool = function(enemy) return (EREADY(enemy)) end},
		    ['Leblanc'] = {bool = function(enemy) return (((WREADY(enemy) and enemy and GetCastName(enemy, _W) == 'LeblancSlide') or (RREADY(enemy) and enemy and GetCastName(enemy, _R) == 'LeblancSlideM') or enemy and GetCastName(enemy, _W) == 'leblancslidereturn' or enemy and GetCastName(enemy, _R) == 'leblancslidereturnm')) end},
		    ['LeeSin'] = {bool = function(enemy) return (enemy and GetCastName(enemy, _Q) == 'blindmonkqtwo') end},
		    ['Lissandra'] = {bool = function(enemy) return (EREADY(enemy)) end},
		    ['Lucian'] = {bool = function(enemy) return (EREADY(enemy)) end},
		    ['Nautilus'] = {bool = function(enemy) return (QREADY(enemy)) end},
		    ['Nocturne'] = {bool = function(enemy) return (RREADY(enemy)) end},
		    ['Quinn'] = {bool = function(enemy) return (EREADY(enemy)) end},
		    ['Renekton'] = {bool = function(enemy) return (EREADY(enemy)) end},
		    ['Riven'] = {bool = function(enemy) return (QREADY(enemy) or EREADY(enemy)) end},
		    ['Sejuani'] = {bool = function(enemy) return (QREADY(enemy)) end},
		    ['Shaco'] = {bool = function(enemy) return (QREADY(enemy)) end},
		    ['Shen' ] = {bool = function(enemy) return (EREADY(enemy)) end},
		    ['Shyvana'] = {bool = function(enemy) return (RREADY(enemy)) end},
		    ['Tristana'] = {bool = function(enemy) return (EREADY(enemy)) end},
		    ['Tryndramere'] = {bool = function(enemy) return (EREADY(enemy)) end},
		    ['Vayne'] = {bool = function(enemy) return (QREADY(enemy)) end},
		    ['Vladimir'] = {bool = function(enemy) return (WREADY(enemy)) end},
		    ['Akali'] = {bool = function(enemy) return ((RREADY(enemy) and AlliesAround(enemy, 825) > 0) or (RREADY(enemy) and MinionsAround(enemy, 825) > 0)) end},
		    ['Diana'] = {bool = function(enemy) return (RREADY(enemy) and AlliesAround(enemy, 825) > 0) end},
		    ['Irelia'] = {bool = function(enemy) return ((QREADY(enemy) and AlliesAround(enemy, 650) > 0) or (QREADY(enemy) and MinionsAround(enemy, 650) > 0)) end},
		    ['Maokai'] = {bool = function(enemy) return (WREADY(enemy) and AlliesAround(enemy, 525) > 0) end},
		    ['MasterYi'] = {bool = function(enemy) return ((QREADY(enemy) and AlliesAround(enemy, 600) > 0) or (QREADY(enemy) and MinionsAround(enemy, 600) > 0)) end},
		    ['MonkeyKing'] = {bool = function(enemy) return ((EREADY(enemy) and AlliesAround(enemy, 625) > 0) or (EREADY(enemy) and MinionsAround(enemy, 625) > 0)) end},
		    ['Pantheon'] = {bool = function(enemy) return ((WREADY(enemy) and AlliesAround(enemy, 600) > 0) or (WREADY(enemy) and MinionsAround(enemy, 600) > 0)) end},
		    ['Talon'] = {bool = function(enemy) return (EREADY(enemy) and AlliesAround(enemy, 700) > 0) end},
		    ['Vi'] = {bool = function(enemy) return (RREADY(enemy) and AlliesAround(enemy, 800) > 0) end},
		    ['Warwick'] = {bool = function(enemy) return (RREADY(enemy) and AlliesAround(enemy, 700) > 0) end},
		    ['XinZhao'] = {bool = function(enemy) return ((EREADY(enemy) and AlliesAround(enemy, 600) > 0) or (EREADY(enemy) and MinionsAround(enemy, 600) > 0)) end},
		    ['Yasuo'] = {bool = function(enemy) return ((EREADY(enemy) and AlliesAround(enemy, 475) > 0) or (EREADY(enemy) and MinionsAround(enemy, 475) > 0)) end}
		}
		self. Stuns = {
			["Aatrox"] = {bool = function(enemy) return QREADY(enemy) end},
			["Ahri"] = {bool = function(enemy) return EREADY(enemy) end},
			["Alistar"] = {bool = function(enemy) return QREADY(enemy) or WREADY(enemy) end},
			["Amumu"] = {bool = function(enemy) return QREADY(enemy) end},
			["Anivia"] = {bool = function(enemy) return QREADY(enemy) end},
			["Annie"] = {bool = function(enemy) return enemy and (_MaxxxeLib.IsBuffed[enemy.networkID] and _MaxxxeLib.IsBuffed[enemy.networkID].name == 'pyromania_particle' and (QREADY(enemy) or WREADY(enemy) or RREADY(enemy))) end},
			["Ashe"] = {bool = function(enemy) return RREADY(enemy) end},
			["Azir"] = {bool = function(enemy) return RREADY(enemy) end},
			["Blitzcrank"] = {bool = function(enemy) return enemy and (QREADY(enemy) or (_MaxxxeLib.IsBuffed[enemy.networkID] and _MaxxxeLib.IsBuffed[enemy.networkID].name == 'Powerfist_buf') or EREADY(enemy) or RREADY(enemy)) end},
			["Brand"] = {bool = function(enemy) return (QREADY(enemy) and ((_MaxxxeLib.IsBuffed[myHero.networkID] and _MaxxxeLib.IsBuffed[myHero.networkID].name == 'brandablaze') or WREADY(enemy) or EREADY(enemy) or RREADY(enemy))) end},
			["Braum"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Cassiopeia"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Chogath"] = {bool = function(enemy) return (QREADY(enemy) or WREADY(enemy)) end},
			["Darius"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Diana"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Draven"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Elise"] = {bool = function(enemy) return enemy and (EREADY(enemy) and GetCastName(enemy, _E) == 'EliseHumanE') end},
			["FiddleSticks"] = {bool = function(enemy) return (QREADY(enemy) or EREADY(enemy)) end},
			["Fizz"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Galio"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Garen"] = {bool = function(enemy) return enemy and (QREADY(enemy) or (_MaxxxeLib.IsBuffed[enemy.networkID] and _MaxxxeLib.IsBuffed[enemy.networkID].name == 'Garen_Base_Q_Cas_Sword')) end},
			["Gnar"] = {bool = function(enemy) return ((WREADY(enemy) and GetCastName(enemy, _W) == 'gnarbigw') or RREADY(enemy) and enemy.range < 410) end},
			["Gragas"] = {bool = function(enemy) return (WREADY(enemy) or RREADY(enemy)) end},
			["Hecarim"] = {bool = function(enemy) return enemy and (EREADY(enemy) or (_MaxxxeLib.IsBuffed[enemy.networkID] and _MaxxxeLib.IsBuffed[enemy.networkID].name == 'Hecarim_E_buf') or RREADY(enemy)) end},
			["Heimerdinger"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Irelia"] = {bool = function(enemy) return (EREADY(enemy) and enemy.health < myHero.health) end},
			["Janna"] = {bool = function(enemy) return (QREADY(enemy) or RREADY(enemy)) end},
			["JarvanIV"] = {bool = function(enemy) return (QREADY(enemy) and EREADY(enemy)) end},
			["Jax"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Jayce"] = {bool = function(enemy) return (EREADY(enemy) and GetCastName(enemy, _E) == 'JayceThunderingBlow') end},
			["Kennen"] = {bool = function(enemy) return enemy and ((QREADY(enemy) and WREADY(enemy) and EREADY(enemy)) or ((_MaxxxeLib.IsBuffed[myHero.networkID] and _MaxxxeLib.IsBuffed[myHero.networkID].name == 'kennen_mos') and (QREADY(enemy) or WREADY(enemy) or EREADY(enemy) or RREADY(enemy))) or RREADY(enemy)) end},
			["LeeSin"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Leona"] = {bool = function(enemy) return enemy and (QREADY(enemy) or (_MaxxxeLib.IsBuffed[enemy.networkID] and _MaxxxeLib.IsBuffed[enemy.networkID].name == 'Leona_ShieldOfDaybreak_cas') or RREADY(enemy)) end},
			["Lissandra"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Lulu"] = {bool = function(enemy) return (WREADY(enemy) or RREADY(enemy)) end},
			["Malphite"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Malzahar"] = {bool = function(enemy) return (QREADY(enemy) or RREADY(enemy)) end},
			["Maokai"] = {bool = function(enemy) return (QREADY(enemy)) end},
			["Nami"] = {bool = function(enemy) return (QREADY(enemy) or RREADY(enemy)) end},
			["Nautilus"] = {bool = function(enemy) return (QREADY(enemy) or RREADY(enemy)) end},
			["Nocturne"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Orianna"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Pantheon"] = {bool = function(enemy) return (WREADY(enemy)) end},
			["Poppy"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Quinn"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Rammus"] = {bool = function(enemy) return (QREADY(enemy) or EREADY(enemy)) end},
			["Renekton"] = {bool = function(enemy) return (WREADY(enemy)) end},
			["Rengar"] = {bool = function(enemy) return (EREADY(enemy) and enemy.mana == 5) end},
			["Riven"] = {bool = function(enemy) return (QREADY(enemy) or WREADY(enemy)) end},
			["Sejuani"] = {bool = function(enemy) return (QREADY(enemy) or RREADY(enemy)) end},
			["Shen"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Shyvana"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Singed"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Sion"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Skarner"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Sona"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Soraka"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Syndra"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Taric"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Thresh"] = {bool = function(enemy) return (QREADY(enemy) or EREADY(enemy)) end},
			["Tristana"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Trundle"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["TwistedFate"] = {bool = function(enemy) return enemy and (GetCastName(enemy, _W) == "goldcardlock") end},
			--["Udyr"] = {bool = function(enemy) return (_MaxxxeLib.IsBuffed[myHero.networkID] and not _MaxxxeLib.IsBuffed[myHero.networkID].name == 'Udyr_Base_E_timer') end},
			["Urgot"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Vayne"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Veigar"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Velkoz"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["Vi"] = {bool = function(enemy) return (QREADY(enemy) or RREADY(enemy)) end},
			["Viktor"] = {bool = function(enemy) return (WREADY(enemy) or RREADY(enemy)) end},
			["Volibear"] = {bool = function(enemy) return (QREADY(enemy)) end},
			["Warwick"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["MonkeyKing"] = {bool = function(enemy) return (RREADY(enemy)) end},
			["Xerath"] = {bool = function(enemy) return (EREADY(enemy)) end},
			["XinZhao"] = {bool = function(enemy) return enemy and ((_MaxxxeLib.IsBuffed[enemy.networkID] and _MaxxxeLib.IsBuffed[enemy.networkID].name ==  'xenZiou_ChainAttack_indicator') or RREADY(enemy) and _MaxxxeLib.IsBuffed[myHero.networkID] and not _MaxxxeLib.IsBuffed[myHero.networkID].name ==  'xen_ziou_intimidate') end},
			["Yasuo"] = {bool = function(enemy) return enemy and (GetCastName(enemy, _Q) == 'yasuoq3w') end},
			["Ziggs"] = {bool = function(enemy) return (WREADY(enemy)) end},
			["Zyra"] = {bool = function(enemy) return (RREADY(enemy)) end}
		}
		--Tables holding units
		self.Freezed = {}
		self.Burning = {}
		self._ = {}
		self.Towers = {["allied"] = {}, ["enemy"] = {}}
		self.Enemies = {}
		self.Ignited = {}
		self.BleedStacks = {}
		self.Bleeding = {}
		self.Debuffs = {}
		self.Moving = {}
		self.Orbbuffed = {}
		self.Chained = {}
		self.IsBuffed = {}
		--Items
		self.Items = { 		--holds all items
			["Tiamat"] = 3077, 
			["Hydra"] = 3074, 
			["Hydra2"] = 3748, 
			["Youmuu"] = 3142,
			["Sheen"] = 3057,
			["Trinity"] = 3078
		}
		--Predictions		
		self.Predictions = {
			[1] = "GOS", 
			[2] = "IP", 
			[3] = "OP", 
			[4] = "Custom"
		}
		--Colors
		self.Colors = {
			[1] = Draw.Color(255, 255, 0, 0),
			[2] = Draw.Color(255, 0, 0, 255),
			[3] = Draw.Color(255, 0, 255, 0),
			[4] = Draw.Color(255, 255, 255, 0),
			[5] = Draw.Color(255, 0, 0, 0),
			[6] = Draw.Color(255, 255, 255, 255),
			[7] = Draw.Color(255, 255, 0, 255),
			[8] = Draw.Color(255, 0, 255, 255)
		}
		self.Colors["Red"] = self.Colors[1]
		self.Colors["Blue"] = self.Colors[2]
		self.Colors["Green"] = self.Colors[3]
		self.Colors["Yellow"] = self.Colors[4]
		self.Colors["Black"] = self.Colors[5]
		self.Colors["White"] = self.Colors[6]
		self.Colors["Pink"] = self.Colors[7]
		self.Colors["Cyan"] = self.Colors[8]
		self.Colors["LightGrey"] = Draw.Color(128, 0, 0, 0)
		self.Colors["DarkWhite"] = Draw.Color(128, 255, 255, 255)
		--Libs
	end

	function _MaxxxeLib:spairs(t, order)
	    -- collect the keys
	    local keys = {}
	    for k in pairs(t) do keys[#keys+1] = k end

	    -- if order function given, sort by it by passing the table and keys a, b,
	    -- otherwise just sort the keys 
	    if order then
	        table.sort(keys, function(a,b) return order(t, a, b) end)
	    else
	        table.sort(keys)
	    end

	    -- return the iterator function
	    local i = 0
	    return function()
	        i = i + 1
	        if keys[i] then
	            return keys[i], t[keys[i]]
	        end
	    end
	end

	function _MaxxxeLib:GetMinionsInRange(object, range, teamx)
		local _ = {}

		local team = teamx == "Ally" and myHero.team or
			  		 teamx == "Jungle" and 300 or
			  		 teamx == "Enemy" and (myHero.team == 100 and 200 or 100) or
			  		 teamx == "EnemyAndJungle" and 400 or
			  		 teamx == "All" and 0

		local normal = teamx == "Ally" or teamx == "Jungle" or teamx == "Enemy"

		for i = 1, Game.MinionCount() do
			local __ = Game.Minion(i)
			if __ and not __.charName:lower():find("dummy") and self:GoodTarget(__) and ((normal and __.team == team) or (not normal and (team == 400 and (__.team == 300 or __.team == (myHero.team == 100 and 200 or 100)) or team == 0) ) ) and GetDistance(__, object) < range then
				insert(_, __)
			end
		end

		return _
	end

	function _MaxxxeLib:GetEnemyHeroInRange(range, pos, exclude)
		local _ = {}

		for i = 1, #self.Enemies do
			local __ = self.Enemies[i]
			if __ and self:GoodTarget(__) and GetDistance(pos, __) <= range and not (exclude and exclude.networkID == __.networkID) then
				insert(_, __)
			end
		end

		return _
	end

	function _MaxxxeLib:AA(bool)
		-- if 		_G.GoSWalkLoaded then
		-- 	_G.GoSWalk:EnableAttack(bool) 
		-- elseif 	_G.DAC_Loaded then
		-- 	DAC:AttacksEnabled(bool)
		-- elseif	_G.IOW_Loaded then
		-- 	IOW.attacksEnabled = bool 
		-- elseif 	_G.PW_Loaded then
		-- 	PW.attacksEnabled = bool
		-- elseif _G.AutoCarry_Loaded then
		-- 	DACR.attacksEnabled = bool
		-- end
	end

	function _MaxxxeLib:Move(bool)
		-- if 		_G.GoSWalkLoaded then
		-- 	_G.GoSWalk:EnableMovement(bool) 
		-- elseif 	_G.DAC_Loaded then
		-- 	DAC:MovementEnabled(bool)
		-- elseif	_G.IOW_Loaded then
		-- 	IOW.movementEnabled = bool 
		-- elseif 	_G.PW_Loaded then
		-- 	PW.movementEnabled = bool
		-- elseif _G.AutoCarry_Loaded then
		-- 	DACR.movementEnabled = bool
		-- end
	end

	function _MaxxxeLib:targetSet(unit)
		-- if 		_G.GoSWalkLoaded then
		-- 	_G.GoSWalk:ForceTarget(unit)
		-- elseif 	_G.DAC_Loaded then
		-- elseif	_G.IOW_Loaded then
		-- 	IOW.forceTarget = unit 
		-- elseif 	_G.PW_Loaded then
		-- 	PW.forceTarget = unit
		-- elseif _G.AutoCarry_Loaded then
		-- 	DACR.forceTarget = unit
		-- end
	end

	function _MaxxxeLib:SetMode()
		if _G.Orbwalker then
			self.Mode = _G.Orbwalker.Combo:Value() and "Combo" or _G.Orbwalker.Harass:Value() and "Harass" or _G.Orbwalker.LastHit:Value() and "LastHit" or _G.Orbwalker.Farm:Value() and "LaneClear" or nil
			self.Orb = "EXT"
		end
		-- if _G.GoSWalkLoaded then --GOS 
		-- 	self.Mode = GoSWalk.CurrentMode == 0 and "Combo" or GoSWalk.CurrentMode == 1 and "Harass" or GoSWalk.CurrentMode == 3 and "LastHit" or GoSWalk.CurrentMode == 2 and "LaneClear"
		-- 	self.Orb = "GOS"
		-- elseif _G.DAC_Loaded then --DAC
		-- 	self.Mode = DAC:Mode() -- return the 4 modes as string : "Combo", "Harass", "LaneClear", "LastHit"
		-- 	self.Orb = "DAC"
		-- elseif _G.IOW_Loaded then --IOW
		-- 	self.Mode = IOW:Mode() -- return the 4 modes as string : "Combo", "Harass", "LaneClear", "LastHit"
		-- 	self.Orb = "IOW"
		-- elseif _G.PW_Loaded then --Platy
		-- 	self.Mode = PW:Mode()
		-- 	self.Orb = "Platy"
		-- elseif _G.AutoCarry_Loaded then --DACR
		-- 	self.Mode = DACR:Mode() -- return one of the 5 modes : "Combo", "Harass", "LaneClear", "LastHit", "Freeze"
		-- 	self.Orb = "DACR"
		-- end
	end

	function _MaxxxeLib:OnScreen(unit)
		local check = Vector(unit.pos2D)
		return not (check.x < 0 or check.y < 0)
	end

	function _MaxxxeLib:GoodTarget(unit, range)
		range = range or 25000
		return 	unit and 
				unit.valid and 
				unit.visible and 
				not unit.dead and 
				self:OnScreen(unit) and 
				unit.distance <= range and
				unit.health > 0
	end

	function _MaxxxeLib:AutoPotions(a, a1, b, b1, c, c1, d, d1)
		if myHero:DistanceTo(self.Base) > 500 then
			for Pot, Type in pairs(self.PotSlots) do
				local slot = GetItemSlot(myHero, Pot)
				if slot ~= 0 then
					if Type == "HP" and a and myHero.health < myHero.maxHealth * (a1 * .01) and os.clock() > self.wUsedAt + 15 then
						myHero:Cast(slot)
						self.wUsedAt = os.clock()
					elseif Type == "Crystal" and b and myHero.health < myHero.maxHealth * (b1 * .01) and os.clock() > self.vUsedAt + 12 then
						myHero:Cast(slot)
						self.vUsedAt = os.clock()
					elseif Type == "Biscuit" and c and myHero.health < myHero.maxHealth * (c1 * .01) and os.clock() > self.bUsedAt + 15 then
						myHero:Cast(slot)
						self.bUsedAt = os.clock()
					elseif Type == "Elixir" and d and myHero.health < myHero.maxHealth * (d1 * .01) and os.clock() > self.eUsedAt + 180 then 
						myHero:Cast(slot)
						self.eUsedAt = os.clock()
					end
				end
			end
		end 
	end

	function _MaxxxeLib:Round(num, idp)
		local mult = 10^(idp or 0) 
		return floor(num * mult + 0.5) / mult 
	end

	function _MaxxxeLib:Length(table, sec) 
		local count = 0

		if sec then
			for ID, _ in pairs(table) do
				count = count + 1
			end
		else
			for ID, _ in pairs(table) do
				count = count + #_
			end 
		end
		
		return count
	end

	function _MaxxxeLib:tablecontains(table, element)
		for _, value in pairs(table) do
			if value == element then
				return true
			end
		end
		return false
	end

	function _MaxxxeLib:MergeTables(table1, table2)
	    if type(table1) == 'table' and type(table2) == 'table' then
	    	local newTable = {}
	    	if Next(table2) ~= nil then
		        for k,v in pairs(table2) do
		        	if type(v) == 'table' and type(table1[k] or false) == 'table' then 
		        		self:MergeTables(table1[k], v) 
		        	else 
		        		table1[k] = v 
		        	end 
		        	return table1
		        end
		    else
		    	return table1
		    end
	    end
	end

	function _MaxxxeLib:TargetSelectorInit()
		DelayAction(function()
			for i = 1, #self.Enemies do
				local target = self.Enemies[i]

				if target.team ~= myHero.team then
					if myHero.charName == "Talon" then _G.Talon_NFSS_Menu.TS:Slider(target.charName, target.name .." ("..target.charName..")", 1, 1, 7, 1) end
					if myHero.charName == "Katarina" then _G.Katarina_LBSeries_Menu.TS:Slider(target.charName, target.name .." ("..target.charName..")", 1, 1, 7, 1) end
					if myHero.charName == "Leblanc" then _G.LeBlanc_NFSS_Menu.TS:Slider(target.charName, target.name .." ("..target.charName..")", 1, 1, 7, 1) end
					if myHero.charName == "Anivia" then _G.Anivia_LBSeries_Menu.TS:MenuElement({id = target.charName, name = target.name .." ("..target.charName..")", value = 1, min = 1, max = 7, step = 1}) end
				end

				self.TSChamps[target.charName] = true
				self.TSCount = self.TSCount + 1
			end
		end, .1)
	end

	function _MaxxxeLib:TargetSelector(typeDmg, priority, selectable)
		self.TStypeDmg = typeDmg or "AD"
		self.TSPriority = self._TS[priority] or "DMG"
		self.TSSelectable = selectable
	end

	function _MaxxxeLib:setMarkedTargetTS()
		if Control.IsKeyDown(0x01) then
			self.selectedChamp = nil
			for i = 1, #self.Enemies do
				local target = self.Enemies[i]
				if self:GoodTarget(target) then
					if GetDistance(target, mousePos) <= 200 then
						self.selectedChamp = target
						break
					end
				end
			end
		end
	end

	function _MaxxxeLib:GetMarkedTargetTS()
		if self:GoodTarget(self.selectedChamp) then
			return self.selectedChamp
		end

		return nil
	end

	function _MaxxxeLib:getTSTarget(TSRange, excludeIndex)
		local targetReturn = nil
		local priorityReturn = nil

		if self.TSSelectable then
			self:setMarkedTargetTS()
		end
		
		if self.targetSelector then			
			local any1live = nil
			
			if self.TSSelectable and self:GetMarkedTargetTS() then
				targetReturn = self:GetMarkedTargetTS()
				priorityReturn = self:getTSTargetPriority(targetReturn)
			else
				local damageDealt = -1
				for i = 1, #self.Enemies do
					local target = self.Enemies[i]
					if self:GoodTarget(target, TSRange) and (not excludeIndex or not excludeIndex[target.charName]) then 
						local delitel = 1
						if self.targetSelector[target.charName] then
							delitel = targetSelector[target.charName]
						end
						
						if delitel < 7 then
							local conCheck = true
							-- if delitel == 6 then
							-- 	if not any1live then
							-- 		any1live = false
							-- 		for j = 1, #self.Enemies do
							-- 			local target2 = self.Enemies[j]
							-- 			if self:GoodTarget(target2) then
							-- 				if targetSelector[target2.charName..self:GetIndex(target2)] < 6 then
							-- 					any1live = true
							-- 					break
							-- 				end
							-- 			end
							-- 		end
							-- 	end
								
							-- 	if any1live then
							-- 		conCheck = false
							-- 	end
							-- end
							
							if conCheck then
								if self.TSPriority == "DMG" then
									local dmgTake = 0
									if self.TStypeDmg == "AD" then
										dmgTake = CalcPhysicalDamage(myHero, target, 300)
									else
										dmgTake = CalcMagicalDamage(myHero, target, 300)
									end
									dmgTake = dmgTake / delitel
									
									if (dmgTake / target.health) > damageDealt or damageDealt == -1 then
										targetReturn = target
										priorityReturn = delitel
										damageDealt = (dmgTake / target.health)
									end
								elseif self.TSPriority == "Close" then
									targetReturn = GetCurrentTarget()
									priorityReturn = delitel
								else
									if damageDealt == -1 or damageDealt < (target.health * delitel) then
										targetReturn = target
										priorityReturn = delitel
										damageDealt = (target.health * delitel)
									end
								end
							end
						end
					end
				end
			end
		end

		return targetReturn, priorityReturn
	end

	function _MaxxxeLib:getTSTargetPriority(target)
		if myHero.charName == "Talon" then return _G.Talon_NFSS_Menu.TS[target.charName]:Value() end
		if myHero.charName == "Katarina" then return _G.Katarina_LBSeries_Menu.TS[target.charName]:Value() end
		if myHero.charName == "Leblanc" then return _G.LeBlanc_NFSS_Menu.TS[target.charName]:Value() end
		if myHero.charName == "Anivia" then return _G.Anivia_LBSeries_Menu.TS[target.charName]:Value() end
	end

	function _MaxxxeLib:AutoLevel(Enabled, SkillingTable, num, Delay)
		if Enabled and not self.levelUP then
			if (myHero:GetSpellData(_Q).level + myHero:GetSpellData(_W).level + myHero:GetSpellData(_E).level + myHero:GetSpellData(_R).level) == 18 then return end

			if myHero.level == 1 then
				run_once(Print, "Auto Level starts in 5 seconds")
			end

			DelayAction(function()
				local skillingOrder = {}

				skillingOrder = SkillingTable[num]

				local realLevel		= myHero.levelData.lvl 														--gives the Current Level
				local difference 	= myHero.levelData.lvlPts 										--gives the Level Points avaiable

				local QL, WL, EL, RL = 0, 0, 0, 0
				if difference > 0 then --there are Points to invest
					--check if last skilling orders were ordered correctly
					for i = 1, realLevel do
						if skillingOrder[i] == 0 then 		--Q
							QL = QL + 1
						elseif skillingOrder[i] == 1 then	--W
							WL = WL + 1
						elseif skillingOrder[i] == 2 then 	--E
							EL = EL + 1
						elseif skillingOrder[i] == 3 then	--R
							RL = RL + 1
						end
					end

					--print(QL .. " - " .. WL .. " - " .. EL .. " - " .. RL)

					if myHero:GetSpellData(_R).level < RL then
						self.levelUP = true
						DelayAction(function()
							self.levelUP = false
						end, Delay)
						return
					elseif myHero:GetSpellData(_Q).level < QL then
						self.levelUP = true
						DelayAction(function()
							self.levelUP = false
						end, Delay)
						return
					elseif myHero:GetSpellData(_W).level < WL then
						self.levelUP = true
						DelayAction(function()
							self.levelUP = false
						end, Delay)
						return
					elseif myHero:GetSpellData(_E).level < EL then
						self.levelUP = true
						DelayAction(function()
							self.levelUP = false
						end, Delay)
						return
					end
				end
			end, myHero.levelData.lvl == 1 and 5 or 0)
		end
	end

	function _MaxxxeLib:GetFarthestPoint(table)
		local range = 0
		local obj = nil

		for i = 1, #table do
			if table[i].distance > range then
				range = table[i].distance
				obj =  table[i]
			end
		end

		return obj.pos or obj
	end

	function _MaxxxeLib:ExcludeFurthest(point, tbl, delete, starTarget)
		delete = delete or false
		if delete then
			local newTable = tbl
			for i = 1, #newTable do
				if newTable[i].networkID == point.networkID then
					newTable[i] = nil
				end
			end
			return newTable
		else
		    local removalId = 1
		    for i=2, #tbl do
		        if GetDistance(point, tbl[i]) > GetDistance(point, tbl[removalId]) and not (starTarget and tbl[i].networkID == starTarget.networkID) then
		            removalId = i
		        end
		    end
		    
		    local newTable = {}
		    for i=1, #tbl do
		        if (starTarget and tbl[i].networkID == starTarget.networkID) or i ~= removalId then
		            newTable[#newTable+1] = tbl[i]
		        end
		    end
		    return newTable
		end
	end

	function _MaxxxeLib:GetBestCircularAOECastPosition(aoe_radius, listOfEntities, starTarget, noExcusion)
		local average = {x = 0, y = 0, z = 0, count = 0, list = {}}
		if #listOfEntities == 0 then return average end

	    for i = 1, #listOfEntities do
	        local ori = listOfEntities[i].pos
	        average.x = average.x + ori.x
	        average.y = average.y + ori.y
	        average.z = average.z + ori.z
	        average.count = average.count + 1
	    end

	    if starTarget then
	        local ori = starTarget.pos
	        average.x = average.x + ori.x
	        average.y = average.y + ori.y
	        average.z = average.z + ori.z
	        average.count = average.count + 1
	    end

	    average.x = average.x / average.count
	    average.y = average.y / average.count
	    average.z = average.z / average.count

	    local targetsInRange = 0
	    for i = 1, #listOfEntities do
	        if GetDistance(average, listOfEntities[i]) <= aoe_radius + listOfEntities[i].boundingRadius then
	            targetsInRange = targetsInRange + 1
	            insert(average.list, listOfEntities[i])
	        end
	    end

	    if starTarget and GetDistance(average, starTarget.pos) <= aoe_radius + listOfEntities[i].boundingRadius then
	        targetsInRange = targetsInRange + 1
	        insert(average.list, starTarget)
	    end

	    if targetsInRange == average.count then
	        return average
	    else
	    	if noExcusion then
	    		return average
	    	else
	        	return self:GetBestCircularAOECastPosition(aoe_radius, self:ExcludeFurthest(average, listOfEntities, false), starTarget)
	        end
	    end
	end

	function _MaxxxeLib:GetBestLinearAOECastPosition(aoe_radius, range, li, starTarget)
		local average = {x = 0, y = 0, z = 0, count = 0, list = {}}
		if #li <= 1 then return average end
		local Max, Minion = 0, nil
		local _ = {}
		local C = Point(myHero.pos.x, myHero.pos.y, myHero.pos.z)

		for i = 1, #li do
			local First = li[i]
			local A = Point(First.pos.x, First.pos.y, First.pos.z)
			local D = LineSegment(C, A)
			_[First] = {}
			local Count = 0
			--check Collision for First
			for j = 1, #li do
				local Second = li[j]
				if First ~= Second then
					local B = Point(Second.pos.x, Second.pos.y, Second.pos.z)
					if B:__distance(D) - aoe_radius * .5 - Second.boundingRadius * .5 <= 0 then
						Count = Count + 1
						insert(_[First], Second)
					end
				end
			end
			if Count >= Max then
				Max = Count + 1
				Minion = First
			end
		end

		insert(_[Minion], Minion)
		local Data = {x = Minion.pos.x, y = Minion.pos.y, z = Minion.pos.z, count = Max, list = _[Minion], x2 = Minion.pos2D.x, y2 = Minion.pos2D.y, z2 = Minion.pos2D.z}
		return Data
	end

	function _MaxxxeLib:isBuffed(unit, direct, excludeFromHardCC)
		local cache = self.Debuffs[unit.networkID]

		for i = 1, 65 do
			if direct and self.CCName[direct] == i then
				return cache and cache[i] > 0 and cache
			elseif excludeFromHardCC and self.CCName[excludeFromHardCC] ~= i and self.HardCC[i] and cache and cache[i] > 0 then
				return cache[i]
			end
		end

		return false
	end

	function _MaxxxeLib:IsIgnited(unit)
		return unit and self.Ignited[unit.networkID]
	end

	function _MaxxxeLib:IsOrWillBeIgnited(unit)
		local ir = _MaxxxeLib.Ignite.ready()
		return ir or _MaxxxeLib:IsIgnited(unit)
	end

	function _MaxxxeLib:ItemsReady(name, slotRet) --return {[item] = true/false}
		local slot = GetItemSlot(myHero, self.Items[name])
		return 
			slot ~= 0 and 
				(slotRet and slot or 
				myHero:CanUseSpell(slot) == READY and slot or 
				0) or 
			0
	end

	function _MaxxxeLib:ManaUp(mana)
		return mana < myHero.mana * 100 / myHero.maxMana
	end

	function _MaxxxeLib:TravelTime(speed, unit, obj)
		if obj then return GetDistance(unit, obj) / speed end
		return GetDistance(unit) / speed
	end

	function _MaxxxeLib:doIgnite(unit, wait)
		if self.Ignite.ready() and unit.distance < self.Ignite.range then
			--myHero:Cast(self._I, unit)
		else
			if wait and not self.Ignite.ready() then return true elseif wait then return false end
		end
	end

	function _MaxxxeLib:GetPercentHP(unit)
		return unit.health * 100 / unit.maxHealth
	end

	function _MaxxxeLib:SortTowers()
		for name, data in pairs(self._) do
			if data.team == myHero.team then
				insert(self.Towers.allied, data)
			else
				insert(self.Towers.enemy, data)
			end
		end

		self._ = nil
	end

	function _MaxxxeLib:Load()
		for i = 1, Game.HeroCount() do
			local unit = Game.Hero(i)
			if unit.team ~= myHero.team then
				insert(self.Enemies, unit)
			end
		end
		self.Ludensstacks = GotBuff(myHero, "itemmagicshankcharge") or 0
		for i = 1, #self.Enemies do
			self.Moving[self.Enemies[i].networkID] = false
			self.Ignited[self.Enemies[i].networkID] = false
			if myHero.charName == "Leblanc" then
				self.Orbbuffed[self.Enemies[i].networkID] = {bool = false, expire = GetGameTimer()}
				self.Chained[self.Enemies[i].networkID] = {bool = false, expire = GetGameTimer()}
			elseif myHero.charName == "Brand" then
				self.Burning[self.Enemies[i].networkID] = {bool = false, expire = GetGameTimer(), stacks = 0, unit = self.Enemies[i]}
			elseif myHero.charName == "Talon" then
			end
		end

		--self._ = GetTurrets()
	end

	function _MaxxxeLib:__buffGet(unit, buff)
		if unit == myHero and buff.Name == "itemmagicshankcharge" then
  			self.Ludensstacks = buff.Count
  		elseif unit == myHero and buff.Name == "TalonRStealth" then
  			self.ShadowAssault = true
  		elseif unit == myHero and buff.Name == "itemdusknightstalkerdamageproc" then
  			self.Dusked = true
  		elseif unit == myHero and buff.Name == "sheen" then
  			if self:ItemsReady("Sheen") > 0 then
  				self.Sheen = true
  			elseif self:ItemsReady("Trinity") > 0 then
  				self.Trinity = true
  			end
  		elseif unit.team ~= myHero.team  then
  			if (buff.Name == "summonerdot" or buff.Name == "SummonerDot") then
  				self.Ignited[unit.networkID] = buff.ExpireTime
  			elseif myHero.charName == "Brand" and buff.Name == "BrandAblaze" then
				self.Burning[unit.networkID] = {bool = true, expire = buff.ExpireTime, stacks = buff.Count, unit = unit}
			elseif myHero.charName == "Leblanc" and buff.Name:lower():find("leblance") then
				self.Chained[unit.networkID] = {bool = true, expire = buff.ExpireTime}
			elseif myHero.charName == "Leblanc" and (buff.Name:lower():find("leblancpmark") or buff.Name:lower():find("leblancpminion")) then
				self.Orbbuffed[unit.networkID] = {bool = true, expire = buff.ExpireTime}
			elseif myHero.charName == "Talon" and buff.Name == "TalonPassiveStack" then
				self.BleedStacks[unit.networkID] = {bool = true, expire = buff.ExpireTime, stacks = buff.Count, unit = unit}
			elseif myHero.charName == "Talon" and buff.Name == "TalonPassiveBleed" then
				self.Bleeding[unit.networkID] = {bool = true, expire = buff.ExpireTime, stacks = buff.Count, unit = unit}
			elseif myHero.charName == "Anivia" and buff.Name == "aniviaiced" then
				self.Freezed[unit.networkID] = {bool = true, expireTime = buff.ExpireTime}
  			else
  				if not self.Debuffs[unit.networkID] then self.Debuffs[unit.networkID] = {} end
  				self.Debuffs[unit.networkID][buff.Type] = buff.ExpireTime
  				DelayAction(function()
					self.IsBuffed[unit.networkID] = {state = true, name = buff.Name}
				end, .1)
  			end
		end
	end

	function _MaxxxeLib:__buffLose(unit, buff)
		if unit == myHero and buff.Name == "itemmagicshankcharge" then 
  			self.Ludensstacks = 0
  		elseif unit == myHero and buff.Name == "TalonRStealth" then
  			self.ShadowAssault = false
  		elseif unit == myHero and buff.Name == "itemdusknightstalkerdamageproc" then
  			self.Dusked = false
  		elseif unit == myHero and buff.Name == "sheen" then
  			self.Sheen = false
  			self.Trinty = false
  		elseif unit.team ~= myHero.team then
  			if (buff.Name == "summonerdot" or buff.Name == "SummonerDot") then
  				self.Ignited[unit.networkID] = nil
  			elseif myHero.charName == "Brand" and buff.Name == "BrandAblaze" then
				self.Burning[unit.networkID] = nil
			elseif myHero.charName == "Leblanc" and buff.Name:lower():find("leblanceroot") then
				self.Chained[unit.networkID] = nil
			elseif myHero.charName == "Leblanc" and buff.Name:lower():find("leblancpexpire") then
				self.Orbbuffed[unit.networkID] = nil
			elseif myHero.charName == "Talon" and buff.Name == "TalonPassiveStack" then
				self.BleedStacks[unit.networkID] = nil
			elseif myHero.charName == "Talon" and buff.Name == "TalonPassiveBleed" then
				self.Bleeding[unit.networkID] = nil
			elseif myHero.charname == "Anivia" and buff.Name == "aniviaiced" then
				self.Freezed[unit.networkID] = nil
  			else
  				if self.Debuffs[unit.networkID] and self.Debuffs[unit.networkID][buff.Type] then
  					self.Debuffs[unit.networkID][buff.Type] = 0
  				end

  				if self.IsBuffed[unit.networkID] and self.IsBuffed[unit.networkID].name:find(buff.Name) then
					DelayAction(function()
						self.IsBuffed[unit.networkID] = nil
					end, .1)
				end
  			end
		end
	end

	function _MaxxxeLib:__AnimationTracker(unit, state) --WORKS
		if  unit.team ~= myHero.team and unit.type == myHero.type and unit.distance < 3000 then
			if state == "Run" then
				local visPos = Vector(unit) + Vector(GetDirection(unit)):normalized() * (125 + myHero.boundingRadius + unit.boundingRadius)

				local d1 = unit.distance
				local d2 = myHero:DistanceTo(visPos) --distance to visPos

				if d2 > d1 then --33 = 100 / 3
					self.Moving[unit.networkID] = true
				else
					self.Moving[unit.networkID] = false
				end
			else
				self.Moving[unit.networkID] = false
			end
		end
	end
return true
--[[
	How to use:

	place at the very top of your Script:
		local M = require 'MaxxxeLib'
		if not M then return end
		_MaxxxeLib:__init()

	Following Tables exist:
		.Ludens
			.ready (Ludens buff is Up on myHero)
			.damage(unit) (Damage of the buff on an unit)
		.Ignite
			.range (Ignite range)
			.ready (Ignite is ready to cast)
			.damage (Ignites true damage)
		.HardCC
			[5] = true --Stun
			[8] = true --Taunt
			[10] = true --Slow
			[11] = true --Snare
			[18] = true --Sleep
			[21] = true --Fear
			[22] = true --Charm
			[24] = true --Suppression
			[29] = true --Knockup
			(Holds all Harder CCs sorted by their number)
		.CCName
			[Aura] = 1,
			[CombatEnchancer] = 2,
			[CombatDehancer] = 3,
			[SpellShield] = 4,
			[Stun] = 5,
			[Invisibility] = 6,
			[Silence] = 7,
			[Taunt] = 8,
			[Polymorph] = 9,
			[Slow] = 10,
			[Snare] = 11,
			[Damage] = 12,
			[Heal] = 13,
			[Haste] = 14,
			[SpellImmunity] = 15,
			[PhysicalImmunity] = 16,
			[Invulnerability] = 17,
			[Sleep] = 18,
			[NearSight] = 19,
			[Frenzy] = 20,
			[Fear] = 21,
			[Charm] = 22,
			[Poison] = 23,
			[Suppression] = 24,
			[Blind] = 25,
			[Counter] = 26,
			[Shred] = 27,
			[Flee] = 28,
			[Knockup] = 29,
			[Knockback] = 30,
			[Disarm] = 31
			[AllHard] = 65
			(Holds all CC names with their index)
		.Enemies
			(Holds all enemy heroes)
		.Ignited
			.unit.networkID
			(Holds units if ignited with remainingTime)
		.Debuffs
			.unit.networkID
			(Holds units whom got a buff with remainingTime)
		.Moving
			.unit.networkID
			(Holds units whom are moving away from myHero)
		.PotSlots
			[2003] = "HP", 
			[2031] = "Crystal"
			[2009] = "Biscuit"
			[2010] = "Biscuit"
			[2138] = "Elixir"
			(Holds all healing potions sorted by itemID)
		.Predictions
			[1] = "GOS"
			[2] = "IP"
			[3] = "OP"
			[4] = "Custom" --like Anivia
			(Some Scripts need it)
		.Colors
			[1] = GoS.Red
			[2] = GoS.Blue
			[3] = GoS.Green
			[4] = GoS.Yellow
			[5] = GoS.White
			[6] = GoS.Black
			[7] = GoS.Pink
			[8] = GoS.Cyan}
			(Holds Colors)
	Folowing Methods exist:
	
--]]
