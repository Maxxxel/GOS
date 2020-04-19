local mPCam = {}
local mPCamCo = nil
local mPCan = {}
local mPHer = {}
local mPHerCo = nil
local mPMin = {}
local mPMinCo = nil
local mPMis = {}
local mPMisCo = nil
local mPObj = {}
local mPPar = {}
local mPParCo = nil
local mPTim = nil
local mPTur = {}
local mPTurCo = nil
local mPWar = {}
local mPWarCo = nil

local CampCountOld = Game.CampCount
local CampOld = Game.Camp
local CanUseSpellOld = Game.CanUseSpell
local Game = Game
local HeroCountOld = Game.HeroCount
local HeroOld = Game.Hero
local MinionCountOld = Game.MinionCount
local MinionOld = Game.Minion
local MissileCountOld = Game.MissileCount
local MissileOld = Game.Missile
local ObjectCountOld = Game.ObjectCount
local ObjectOld = Game.Object
local ParticleCountOld = Game.ParticleCount
local ParticleOld = Game.Particle
local TimerOld = Game.Timer
local TurretCountOld = Game.TurretCount
local TurretOld = Game.Turret
local WardCountOld = Game.WardCount
local WardOld = Game.Ward

local CampCountNew = function()
	mPCamCo = mPCamCo == nil and CampCountOld() or mPCamCo

	return mPCamCo
end

local CampNew = function(i)
	if not mPCam[i] then
		mPCam[i] = CampOld(i)
	end

	return mPCam[i]
end

local CanUseSpellNew = function(i)
	if mPCan[i] == nil then
		mPCan[i] = CanUseSpellOld(i)
	end

	return mPCan[i]
end

local HeroCountNew = function()
	mPHerCo = mPHerCo == nil and HeroCountOld() or mPHerCo

	return mPHerCo
end

local HeroNew = function(i)
	if not mPHer[i] then
		mPHer[i] = HeroOld(i)
	end

	return mPHer[i]
end

local MinionCountNew = function()
	mPMinCo = mPMinCo == nil and MinionCountOld() or mPMinCo

	return mPMinCo
end

local MinionNew = function(i)
	if not mPMin[i] then
		mPMin[i] = MinionOld(i)
	end

	return mPMin[i]
end

local MissileCountNew = function()
	mPMisCo = mPMisCo == nil and MissileCountOld() or mPMisCo

	return mPMisCo
end

local MissileNew = function(i)
	if not mPMis[i] then
		mPMis[i] = MissileOld(i)
	end

	return mPMis[i]
end

local ObjectCountNew = function()
	return 10000
end

local ObjectNew = function(i)
	if not mPObj[i] then
		mPObj[i] = ObjectOld(i)
	end

	return mPObj[i]
end

local ParticleCountNew = function()
	mPParCo = mPParCo == nil and ParticleCountOld() or mPParCo

	return mPParCo
end

local ParticleNew = function(i)
	if not mPPar[i] then
		mPPar[i] = ParticleOld(i)
	end

	return mPPar[i]
end

local TimerNew = function()
	mPTim = mPTim == nil and TimerOld() or mPTim

	return mPTim
end

local TurretCountNew = function()
	mPTurCo = mPTurCo == nil and TurretCountOld() or mPTurCo

	return mPTurCo
end

local TurretNew = function(i)
	if not mPTur[i] then
		mPTur[i] = TurretOld(i)
	end

	return mPTur[i]
end

local WardCountNew = function()
	mPWarCo = mPWarCo == nil and WardCountOld() or mPWarCo

	return mPWarCo
end

local WardNew = function(i)
	if not mPWar[i] then
		mPWar[i] = WardOld(i)
	end

	return mPWar[i]
end

_G.Game.Camp = CampNew
_G.Game.CampCount = CampCountNew
_G.Game.CanUseSpell = CanUseSpellNew
_G.Game.Hero = HeroNew
_G.Game.HeroCount = HeroCountNew
_G.Game.Minion = MinionNew
_G.Game.MinionCount = MinionCountNew
_G.Game.Missile = MissileNew
_G.Game.MissileCount = MissileCountNew
_G.Game.Object = ObjectNew
_G.Game.ObjectCount = ObjectCountNew
_G.Game.Particle = ParticleNew
_G.Game.ParticleCount = ParticleCountNew
_G.Game.Timer = TimerNew
_G.Game.Turret = TurretNew
_G.Game.TurretCount = TurretCountNew
_G.Game.Ward = WardNew
_G.Game.WardCount = WardCountNew

local function workOnTick()
	mPCam = {}
	mPCamCo = nil
	mPCan = {}
	mPHer = {}
	mPHerCo = nil
	mPMin = {}
	mPMinCo = nil
	mPMis = {}
	mPMisCo = nil
	mPObj = {}
	mPPar = {}
	mPParCo = nil
	mPTim = nil
	mPTur = {}
	mPTurCo = nil
	mPWar = {}
	mPWarCo = nil
end

Callback.Add("Tick", workOnTick)

print("maxPerformance: Added Functions")
