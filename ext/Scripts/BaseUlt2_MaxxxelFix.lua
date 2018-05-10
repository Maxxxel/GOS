--[[
        BaseUlt2 - Hotfix Version by Maxxxel
        Credits: Deftsu
    
        I just made it work as it should.
        @Deftsu feel free to push this update.
--]]

require('DamageLib')

local insert, remove, contains, concat = table.insert, table.remove, table.contains, table.concat
local Timer = Game.Timer
local min, ceil = math.min, math.ceil

class "BaseUlt2"
function BaseUlt2:__init()
    if not FileExist(SPRITE_PATH.."MenuElement\\RecallTracker.png") then
        print("BaseUlt2 - Missing sprites, Downloading...")
        local _ = MenuElement({type = MENU, id = "_deleteMe", name = "Press 2xF6 to Reload BaseUlt", leftIcon = "https://raw.githubusercontent.com/D3ftsu/GoSExt/master/BaseUlt2/Ressources/RecallTracker.png"})
        
        return
    end

    self.SupportedMaps, self.SupportedChampions = {CRYSTAL_SCAR, TWISTED_TREELINE, SUMMONERS_RIFT}, {"Ashe", "Draven", "Ezreal", "Jinx", "Karthus", "Lux", "Gangplank", "Ziggs"}
    if not contains(self.SupportedMaps, Game.mapID) then print("BaseUlt2 - Map not supported!") return end
    if not contains(self.SupportedChampions, myHero.charName) then print("BaseUlt2 - Champion not supported!") print("Current supported champions are : " .. concat(self.SupportedChampions, ", ")) return end

    self:LoadData()
    self:LoadRecallTrackerMenu()
    self:LoadBaseUltMenu()

    Callback.Add("Draw", function() self:Draw() end)
    Callback.Add("ProcessRecall", function(unit, recall) self:ProcessRecall(unit, recall) end)
    Callback.Add("Tick", function() self:Tick() end)
end

function BaseUlt2:LoadData()
    self.Sprite = Sprite("MenuElement/RecallTracker.png")
    self.UltimateData = {
        ["Ashe"] = {Delay = 0.25, Speed = 1600, Width = 130, Collision = true, Damage = function(source, target) return getdmg("R", target, source) end},
        ["Draven"] = {Delay = 0.4, Speed = 2000, Width = 160, Collision = true, Damage = function(source, target) return getdmg("R", target, source) * 0.7 end},
        ["Ezreal"] = {Delay = 1, Speed = 2000, Damage = function(source, target) return getdmg("R", target, source) * 0.7 end},
        ["Jinx"] = {Delay = 0.6, Speed = 1700, Width = 140, Collision = true, Damage = function(source, target) return getdmg("R", target, source, 2) end},
        ["Karthus"] = {Delay = 3.125, Speed = math.huge, Damage = function(source, target) return getdmg("R", target, source) end},
        ["Lux"] = {Delay = 1, Speed = math.huge, Damage = function(source, target) return getdmg("R", target, source) end},
        ["Gangplank"] = {Delay = 1, Speed = math.huge, Damage = function(source, target) return getdmg("R", target, source) end},
        ["Ziggs"] = {Delay = 0, Speed = math.huge, Damage = function(source, target) return getdmg("R", target, source) end},
    }
    self.TimeToHit = 0
    self.Allies, self.Enemies, self.RecallData, self.EnemyData, self.IncomingDamages = {}, {}, {}, {}, {}
   
    for i = 1, Game.HeroCount() do
        local unit = Game.Hero(i)
        
        if not unit.isMe then 
            if unit.isAlly then 
                insert(self.Allies, unit)
            else
                self.EnemyData[unit.networkID] = 0
                insert(self.Enemies, unit)
            end
        end
    end

    for i = 1, Game.ObjectCount() do
        local object = Game.Object(i)
        
        if not object.isAlly and object.type == Obj_AI_SpawnPoint then 
            self.EnemySpawnPos = object
            break
        end
    end
end

function BaseUlt2:LoadBaseUltMenu()
    self.Menu:MenuElement({type = MENU, id = "TeamUlt", name = "TeamUlt"})
    for i, ally in pairs(self.Allies) do
        if contains(self.SupportedChampions, ally.charName) then
          self.Menu.TeamUlt:MenuElement({id = ally.charName, name = "TeamUlt with "..ally.charName, value = false})
        end
    end

    self.Menu:MenuElement({type = MENU, id = "BlackList", name = "BlackListed Champions"})
    for i, enemy in pairs(self.Enemies) do
        self.Menu.BlackList:MenuElement({id = enemy.charName, name = enemy.charName, value = false})
    end

    self.Menu:MenuElement({id = "Enabled", name = "Enabled", value = true})
    self.Menu:MenuElement({id = "Collision", name = "Collision Check", value = myHero.charName == "Ashe" or myHero.charName == "Jinx"})
    if myHero.charName ~= "Ashe" and myHero.charName ~= "Jinx" then
        self.Menu.Collision:Hide()
    end
    self.Menu:MenuElement({id = "PanicKey", name = "Don't Use Ultimate in Fight", key = 32})
end

function BaseUlt2:LoadRecallTrackerMenu()
    self.Menu = MenuElement({type = MENU, id = "BaseUlt2", name = "BaseUlt2", leftIcon = "http://vignette2.wikia.nocookie.net/leagueoflegends/images/a/a8/Super_Mega_Death_Rocket%21.png"})
    self.Menu:MenuElement({type = MENU, id = "Tracker", name = "Recall Tracker"})
    self.Menu.Tracker:MenuElement({id = "Enabled", name = "Show Recalls", value = true})
    self.Menu.Tracker:MenuElement({id = "X", name = "X Offset", value = Game.Resolution().x - 260, min = 0, max = Game.Resolution().x - 260, step = 1, callback = function(value) self.Sprite:SetPos(value, self.Sprite.y) end})
    self.Menu.Tracker:MenuElement({id = "Y", name = "Y Offset", value = Game.Resolution().y - 250, min = 0, max = Game.Resolution().y - 51, step = 1, callback = function(value) self.Sprite:SetPos(self.Sprite.x, value) end})
    self.Sprite:SetPos(self.Menu.Tracker.X:Value(), self.Menu.Tracker.Y:Value())
end

function BaseUlt2:ProcessRecall(unit, recall)
    if not unit.isEnemy then return end
    
    if recall.isStart then
        insert(self.RecallData, {object = unit, start = Timer(), duration = (recall.totalTime*0.001)})
    else
        for i, rc in pairs(self.RecallData) do
            if rc.object.networkID == unit.networkID then
                remove(self.RecallData, i)
            end
        end
    end
end

function BaseUlt2:GetRecallData(unit)
    for i, recall in pairs(self.RecallData) do
        if recall.object.networkID == unit.networkID then
            return {isRecalling = true, timeToRecall = recall.start+recall.duration-Timer()}
        end
    end

    return {isRecalling = false, timeToRecall = 0}
end

function BaseUlt2:GetUltimateData(unit)
    return self.UltimateData[unit.charName]
end

function BaseUlt2:GetPredictedHealth(unit, time)
    local shield = 0

    if unit.charName == "Yasuo" then
        if unit.mana == unit.maxMana then
            shield = ({100,105,110,115,120,130,140,150,165,180,200,225,255,290,330,380,440,510})[unit.levelData.lvl]
        end
    elseif unit.charName == "Blitzcrank" then
        if GotBuff(unit, "manabarriericon") > 0 then
            shield = (unit.visible and unit.mana or unit.mana+unit.mpRegen*(Timer()-self.EnemyData[unit.networkID]+time)) * 0.5
        end
    end

    if unit.visible then return unit.health+shield end

    local extraHealth = unit.maxHealth * 0.021 * 2

    return min(unit.maxHealth+shield, unit.health+shield+unit.hpRegen*(Timer()-self.EnemyData[unit.networkID]+time) + extraHealth)
end

function BaseUlt2:GetTimeToReachBase(unit, data)
    if data.Speed == math.huge and data.Delay ~= 0 then return data.Delay end

    local distance = unit.pos:DistanceTo(self.EnemySpawnPos.pos)
    local delay = data.Delay
    local missilespeed = data.Speed 

    if unit.charName == "Ziggs" then
        delay = 1.5 + 1.5 * distance / unit:GetSpellData(3).range
    end

    if unit.charName == "Jinx" then
        missilespeed = distance > 1350 and (2295000 + (distance - 1350) * 2200) / distance or data.Speed
    end

    return distance / missilespeed + delay
end

function BaseUlt2:CanUseUlt(unit)
    return unit.charName == "Draven" and (unit:GetSpellData(3).currentCd == 0 and unit:GetSpellData(3).name == "DravenRCast") or unit:GetSpellData(3).currentCd == 0 
end

function BaseUlt2:ColorGradient(percent) 
    local percent = min(99, percent)
    return Draw.Color(255, percent < 50 and 255 or ceil(255 * ((50 - percent % 50) / 50)), percent >= 50 and 255 or ceil(255 * (percent / 50)), 0)
end

function BaseUlt2:Draw()
    if not self.Menu.Tracker.Enabled:Value() or #self.RecallData == 0 or self.Sprite == 0 then return end
    self.Sprite:Draw()
   
    for i, recall in pairs(self.RecallData) do
        if Timer() - recall.start < recall.duration then
            Draw.Rect(self.Sprite.x+6, self.Sprite.y+13, (recall.start+recall.duration-Timer()) / recall.duration * 238, 7, self:ColorGradient((recall.start+recall.duration-Timer()) / recall.duration * 100))
            Draw.Text(recall.object.charName.. " " ..ceil((1 - (Timer() - recall.start) / recall.duration) * 100) .. "% (" .. ceil(self:GetPredictedHealth(recall.object, 0)) .. " HP)", 15, self.Sprite.x - 40 + ((recall.start+recall.duration-Timer()) / recall.duration) * 238, self.Sprite.y - 10 - i * 15, Draw.Color(255, 255, 255, 255))
            Draw.Line(self.Sprite.x+6+(recall.start+recall.duration-Timer()) / recall.duration * 238, self.Sprite.y+13, self.Sprite.x+6+(recall.start+recall.duration-Timer()) / recall.duration * 238, self.Sprite.y + 5 - i * 15, 2, Draw.Color(150,255,255,255))
           
            if self.TimeToHit ~= 0 then
                Draw.Text("|", 20, self.Sprite.x + 2 + self.TimeToHit/recall.duration * 238, self.Sprite.y+6, Draw.Color(255,255,0,0))
            end
        end
    end
end

function BaseUlt2:GetTotalDamage()
    local n = 0
    
    for i, damage in pairs(self.IncomingDamages) do
        n = n + damage
    end
    
    return n
end

function BaseUlt2:Tick()
    if not self.Menu.Enabled:Value() or myHero.dead or not self:CanUseUlt(myHero) or myHero.pos:DistanceTo(self.EnemySpawnPos.pos) > myHero:GetSpellData(3).range then return end
    
    for i, enemy in pairs(self.Enemies) do
        if enemy.visible then
            self.EnemyData[enemy.networkID] = Timer()
        end
    end

    for i, enemy in pairs(self.Enemies) do
        if enemy.valid and not enemy.dead and not self.Menu.BlackList[enemy.charName]:Value() and self:GetRecallData(enemy).isRecalling then
            for k, ally in pairs(self.Allies) do
                if not contains(self.SupportedChampions, ally.charName) then goto continue end -- not supported for TeamUlt
                if ally.pos:DistanceTo(self.EnemySpawnPos) > ally:GetSpellData(3).range then goto continue end
                
                if ally.valid and not ally.dead and self.Menu.TeamUlt[ally.charName]:Value() and self:CanUseUlt(ally) then
                    if self.Menu.Collision:Value() and self:GetUltimateData(ally).Collision and self:IsColliding(ally.pos, enemy, self:GetUltimateData(ally).Width) then
                        self.IncomingDamages[ally.networkID] = 0
                        goto continue
                    end

                    local timeToHit = self:GetTimeToReachBase(ally, self:GetUltimateData(ally))
                    local timeToRecall = self:GetRecallData(enemy).timeToRecall
                    
                    if timeToRecall >= timeToHit then
                        self.IncomingDamages[ally.networkID] = self:GetUltimateData(ally).Damage(ally, enemy)
                    elseif timeToRecall < timeToHit - 0.125 then
                        self.IncomingDamages[ally.networkID] = 0
                    end
                end
                
                ::continue::
            end

            if self.Menu.Collision:Value() and self:GetUltimateData(myHero).Collision and self:IsColliding(myHero.pos, enemy, self:GetUltimateData(myHero).Width) then return end
            
            local timeToHit = self:GetTimeToReachBase(myHero, self:GetUltimateData(myHero))
            local timeToRecall = self:GetRecallData(enemy).timeToRecall
            
            if timeToRecall >= timeToHit then
                self.IncomingDamages[myHero.networkID] = self:GetUltimateData(myHero).Damage(myHero, enemy)
            else
                self.IncomingDamages[myHero.networkID] = 0
            end
            
            if self:GetTotalDamage() < self:GetPredictedHealth(enemy, timeToRecall) then return end
            
            self.TimeToHit = timeToHit
            if timeToRecall - timeToHit > 0.1 or self.Menu.PanicKey:Value() then return end

            Control.CastSpell(HK_R, self.EnemySpawnPos.posMM.x, self.EnemySpawnPos.posMM.y) -- Minimap casting
            self.TimeToHit = 0
        end
    end
end

function BaseUlt2:ProjectVectorOnSegment(v1, v2, v)
    local cx, cy, ax, ay, bx, by = v.x, v.z, v1.x, v1.z, v2.x, v2.z
    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
    local pointLine = Vector(ax + rL * (bx - ax), 0, ay + rL * (by - ay))
    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
    local isOnSegment = rS == rL
    local pointSegment = isOnSegment and pointLine or Vector(ax + rS * (bx - ax), 0, ay + rS * (by - ay))
    
    return {PointSegment = pointSegment, PointLine = pointLine, IsOnSegment = isOnSegment}
end

function BaseUlt2:IsColliding(from, unit, width)
    for i, enemy in pairs(self.Enemies) do
        if enemy.valid and not enemy.dead and unit.networkID ~= enemy.networkID then
            local ProjectionInfo = self:ProjectVectorOnSegment(from, self.EnemySpawnPos.pos, enemy.pos)
           
            if ProjectionInfo.IsOnSegment and ProjectionInfo.PointSegment:DistanceTo(enemy.pos) < width+enemy.boundingRadius and from:DistanceTo(self.EnemySpawnPos.pos) > from:DistanceTo(enemy.pos) then
                return true
            end
        end
    end

    return false
end

function OnLoad()
    BaseUlt2()
end
