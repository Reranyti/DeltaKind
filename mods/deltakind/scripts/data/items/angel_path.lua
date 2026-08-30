local item, super = Class(Armor, "angel_path")

function item:init()
    super.init(self)

    self.name = "ПУТЬ АНГЕЛА"
    self.type = "armor"
    self.icon = "items/angel_path" 
    self.check = "[font:main_mono][spacing:1]* КНИГА АНГЕЛА.\n* ДАЕТ НЕВЕРОЯТНУЮ СИЛУ ХРАНИТЕЛЮ."

    self.saves_left = 3
    self.broken = false
    self.cooldown = 0
    self.is_important = true 
end

function item:getStatBonus(stat) return 0 end
function item:onWorldUpdate(owner) end

function item:applyBuffs()
    for _, member in ipairs(Game.party) do
        if not member.angel_buff_active then
            member.stats["health"] = (member.stats["health"] or 0) + 1150
            member.stats["defense"] = (member.stats["defense"] or 0) + 30
            member.stats["magic"] = (member.stats["magic"] or 0) + 300
            member.stats["attack"] = (member.stats["attack"] or 0) + 40
            
            member.max_health = member.stats["health"]
            member.health = member.max_health
            member.angel_buff_active = true
            
            -- ПРОВЕРКА: Если битва уже идет И интерфейс готов
            if Game.battle and Game.battle.battle_ui then
                local battler = Game.battle:getPartyBattler(member.id)
                if battler then
                    battler:flash()
                    Game.battle:battleText("* Книга Ангела резонирует с " .. member:getName() .. "!")
                end
            end
        end
    end
    if Game.battle then Game.battle.max_tension = 240 end
end

function item:removeBuffs()
    for _, member in ipairs(Game.party) do
        if member.angel_buff_active then
            member.stats["health"] = math.max(1, (member.stats["health"] or 1151) - 1150)
            member.stats["defense"] = math.max(0, (member.stats["defense"] or 30) - 30)
            member.stats["magic"] = math.max(0, (member.stats["magic"] or 300) - 300)
            member.stats["attack"] = math.max(0, (member.stats["attack"] or 40) - 40)
            
            member.max_health = member.stats["health"]
            if member.health > member.max_health then member.health = member.max_health end
            member.angel_buff_active = false
        end
    end
    if Game.battle then Game.battle.max_tension = 100 end
end

function item:onTakeDamage(trier, damage)
    if self.broken then return damage end
    if damage >= trier.health and trier.health > 1 and self.saves_left > 0 then
        self.saves_left = self.saves_left - 1
        Assets.playSound("shatter") 
        if self.saves_left == 0 then
            self.broken = true
            self.cooldown = 2
            self:removeBuffs()
            if Game.battle then Game.battle:battleText("* КНИГА ПОГАСЛА!") end
        else
            if Game.battle then Game.battle:battleText("* ЗАЩИТА СРАБОТАЛА! (ОСТАЛОСЬ: "..self.saves_left..")") end
        end
        return trier.health - 1
    end
    return damage
end

function item:onBattleUpdate()
    if Game.battle.state == "ENEMYSELECT" then
        if self.broken then
            if self.last_state ~= "ENEMYSELECT" then
                self.cooldown = self.cooldown - 1
                if self.cooldown <= 0 then
                    self.broken = false
                    self.saves_left = 3
                    self:applyBuffs()
                    Assets.playSound("power")
                end
            end
        else
            self.saves_left = 3
        end
    end
    self.last_state = Game.battle.state
    
    local ralsei = Game.battle:getPartyBattler("ralsei")
    if ralsei and ralsei.chara.health <= 0 then
        ralsei.revive_amount = 50 
    end
end

function item:onEquip(character) self:applyBuffs() end
function item:onUnequip(character) self:removeBuffs() end

return item