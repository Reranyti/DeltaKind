-----------------------------------------------------------
-- ИСКАЖЁННЫЙ МЕЧ (Twisted Sword) -- DeltaKind override
--
-- Базовый предмет уже существует в чистом Kristal/Deltarune
-- как data/items/weapons/twistedswd.lua:
--   name = "TwistedSwd", type = "weapon",
--   bonuses.attack = 16, bonus_name = "Trance",
--   can_equip = { kris = true }, can_sell = false.
--
-- Это ТОЧНО совпадает с каноном DeltaKind (раздел 12):
--   не кольцо; неиспользуемый ассет Deltarune; доступен
--   только Крису; ATK +16; эффект "Транс".
--
-- Этот файл -- ПОЛНОЕ переопределение (мод-override по id
-- "twistedswd"), поэтому все поля базового предмета
-- продублированы буквально, плюс добавлена логика раздела 13
-- канона ("Искажённый меч начинает отнимать 1 HP каждую
-- секунду"), которой в чистом Kristal нет.
--
-- ПРЕДПОЛОЖЕНИЯ (не КАНОН):
--   1. Утечка HP активна всё время, пока меч экипирован --
--      как у ThornRing (data/items/weapons/thornring.lua),
--      который использует именно такую схему
--      (onBattleUpdate + счётчик кадров). Канон не говорит,
--      прекращается ли эффект при особых условиях (например,
--      при определённом % HP) -- нижнего порога НЕТ, в отличие
--      от ThornRing (у которого урон прекращается при HP <=
--      1/3 макс.). Если нужен порог -- это нужно уточнить.
--   2. "1 HP каждую секунду" реализовано как ровно 1 HP за
--      30 кадров (DTMULT суммарно = 30 в секунду, см.
--      src/engine/statevars.lua: DTMULT = DT * 30).
--   3. Эффект работает только в бою (onBattleUpdate вызывается
--      только для боевого PartyBattler), так как раздел 13
--      описывает именно боевую сцену.
-----------------------------------------------------------

local item, super = Class(Item, "twistedswd")

function item:init()
    super.init(self)

    -- Display name
    self.name = "TwistedSwd"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/sword"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A strange blade"

    -- Default shop price (sell price is halved)
    self.price = 1
    -- Whether the item can be sold
    self.can_sell = false

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "none"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        attack = 16,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Trance"
    self.bonus_icon = "ui/menu/icon/down"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        kris = true,
    }

    -- Character reactions
    self.reactions = {
        susie = "... uhh, looks bad.",
        ralsei = "It's like a spiral.",
        noelle = "It's... kind of scary...",
    }
end

-----------------------------------------------------------
-- SIDE B: 1 HP/сек (раздел 13 канона)
-----------------------------------------------------------

function item:onBattleUpdate(battler)

    battler.deltakind_twistedswd_timer =
        (battler.deltakind_twistedswd_timer or 0) +
        DTMULT

    if battler.deltakind_twistedswd_timer >= 30 then

        battler.deltakind_twistedswd_timer =
            battler.deltakind_twistedswd_timer - 30

        battler.chara:setHealth(
            battler.chara:getHealth() - 1
        )
    end
end

return item
