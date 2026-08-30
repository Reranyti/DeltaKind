local item, super = Class(HealItem, "ultimate_candy")

function item:init()
    super.init(self)

    self.name = "UltimatCandy"
    self.use_name = "ULTIMATE CANDY"
    self.type = "item"
    
    self.effect = "Max\nTeam Heal"
    self.shop = "Perfection"
    self.description = "Сверкает совершенством.\nВосстанавливает 60% HP всей группе."

    -- Базовое число (на всякий случай)
    self.heal_amount = 500 

    self.target = "party" -- Лечит всех сразу!
    self.usable_in = "all"
    
    self.price = 1000 -- Такой артефакт должен стоить дорого
    self.can_sell = true

    self.reactions = {
        susie = "Эй! Она пустая внутри! Но... я чувствую силу!",
        ralsei = "Какая интересная текстура! Я чувствую себя намного лучше!",
    }
end

-- ПЕРЕПИСЫВАЕМ ЛОГИКУ ЛЕЧЕНИЯ ДЛЯ ЭТОГО ПРЕДМЕТА
function item:getWorldHealAmount(id)
    local chara = Game:getPartyMember(id)
    return math.ceil(chara:getStat("health") * 0.6) -- 60% от макс HP вне боя
end

function item:getBattleHealAmount(id)
    local chara = Game.battle:getPartyBattler(id).chara
    return math.ceil(chara:getStat("health") * 0.6) -- 60% от макс HP в бою
end

return item
