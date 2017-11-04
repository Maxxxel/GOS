--No easter eggs here
--Credits to Noddy for the damage calculations (minikappa)
--Maxxxel R Range Fix @04.11.2017
class "Tristana"
function Tristana:__init()

  self.Menu = Menu("Tristana", "RK's Tristana")
  
  self.Menu:SubMenu("Combo", "Combo")
  self.Menu.Combo:Boolean("Q", "Use Q", true)
  self.Menu.Combo:Boolean("E", "Use E", true)
  self.Menu.Combo:Boolean("R", "Use R", true)
  self.Menu.Combo:Boolean("RE", "Use R is E can kill", true)
  
  self.Menu:SubMenu("KS", "Killsteal")
  self.Menu.KS:Boolean("KSR", "Killsteal with R", true)
  
  self.Menu:SubMenu("Keys", "Keys")
  self.Menu.Keys:KeyBinding("Combo", "Combo Key", 32)

  self.Menu:SubMenu("Draws", "Draws")
  self.Menu.Draws:Boolean("DW", "Draw W", false)
  self.Menu.Draws:Boolean("DR", "Draw R", false) 
  self.Menu.Draws:Boolean("DE", "Draw E", false)

  self.Target = GetCurrentTarget()
  
  OnTick(function() self:Tick() end)
  OnTick(function() self:KS()   end)
  OnDraw(function() self:Draw() end)
  
end

function Tristana:Tick()

  self.Target = GetCurrentTarget()
    if self:Mode() == "Combo" then
      self:Combo()
    end
end

function Tristana:Draw()
  if self.Menu.Draws.DW:Value() then
    DrawCircle(GetOrigin(myHero),900,0,155,ARGB(255, 8, 178, 102))
  end
  if self.Menu.Draws.DR:Value() then
    DrawCircle(GetOrigin(myHero),700,0,155,ARGB(255, 8, 71, 178))
  end
  if self.Menu.Draws.DE:Value() then
    DrawCircle(GetOrigin(myHero),625,0,155,ARGB(255, 226, 217, 45))
  end
end

function Tristana:Combo()
  if self.Menu.Combo.Q:Value() and ValidTarget(self.Target,GetRange(myHero)) and CanUseSpell(myHero, _Q) == READY then
      CastSpell(_Q)
  end
  if self.Menu.Combo.E:Value() and ValidTarget(self.Target,GetRange(myHero)) and CanUseSpell(myHero, _E) == READY then
        CastTargetSpell(self.Target, _E)
  end

  if self.Menu.Combo.R:Value() and CanUseSpell(myHero, _R) == READY and ValidTarget(self.Target,700) and GetCurrentHP(self.Target) < CalcDamage(myHero, self.Target, 0,225 + 100*GetCastLevel(myHero,_R) + GetBonusAP(myHero)) then
      CastTargetSpell(self.Target, _R) 
  end

    if self.Menu.Combo.RE:Value() then
      for _, enemy in pairs(GetEnemyHeroes()) do
          if GotBuff(enemy,"tristanaechargesound") == 1 then
              eDMG = CalcDamage(myHero, enemy, (10*GetCastLevel(myHero,_E)+52+((0.18*(GetCastLevel(myHero,_E))+0.38)*(GetBaseDamage(myHero) + GetBonusDmg(myHero)))+(0.6*GetBonusAP(myHero))) + ((GotBuff(enemy,"tristanaechargesound")-1)*(3*GetCastLevel(myHero,_E)+22+((0.049*(GetCastLevel(myHero,_E))+0.120)*(GetBaseDamage(myHero) + GetBonusDmg(myHero)))+(0.15*GetBonusAP(myHero)))), 0 ) - GetHPRegen(enemy)*4
    elseif GotBuff(enemy,"tristanaechargesound") == 0 then
    eDMG = 0
             if CanUseSpell(myHero, _R) == READY and ValidTarget(enemy,700) then
              rDMG = CalcDamage(myHero, enemy, 0, 100*GetCastLevel(myHero,_R)+ 200 + (GetBonusAP(myHero)))
          if GetCurrentHP(enemy) < rDMG+eDMG then
            CastTargetSpell(enemy, _R)
          end
             end
         end
      end
   end
end

function Tristana:KS()
 if self.Menu.KS.KSR:Value() and CanUseSpell(myHero, _R) == READY and ValidTarget(self.Target,700) and GetCurrentHP(self.Target) < CalcDamage(myHero, self.Target, 0, 200+100*GetCastLevel(myHero,_R) + GetBonusAP(myHero)) then
    CastTargetSpell(self.Target, _R)
  end
end
  
function Tristana:Mode()
  if self.Menu.Keys.Combo:Value() then
      return "Combo"
    end
    return ""
end

function Tristana:Ready(spell)
  return CanUseSpell(myHero, spell) == 0
end

if _G[myHero.charName] then
  _G[myHero.charName]()
end

PrintChat('<font color = \"#aa00ff\">RK Tristana</font> </font> <font color = \"#0094ff\"> Loaded </font>')
PrintChat('<font color = \"#ff3feb\"> By RelaxKid </font>')
