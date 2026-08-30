local KnightFanBullet, super = Class(Bullet)

function KnightFanBullet:init(x, y, bullet_type, speed, damage)
    super.init(self, x, y, "bullets/smallbullet")

    self.fan_color = bullet_type or "red"

    -- Все пули летят слева направо/справа налево
    -- в зависимости от того, что задаст сама атака.
    self.physics.direction = 0
    self.physics.speed = speed or 4

    -- Обычный урон этой пули.
    self.damage = damage or 10

    -- Одна пуля может обработать столкновение только один раз.
    self.hit = false

    -- Удаляем пулю после выхода за экран.
    self.remove_offscreen = true

    -------------------------------------------------------
    -- ЧЁРНАЯ = x2 УРОН
    -------------------------------------------------------

    if self.fan_color == "black" then
        self.damage = self.damage * 2
    end

    -------------------------------------------------------
    -- ЦВЕТ
    -------------------------------------------------------

    if self.fan_color == "red" then
        self:setColor(1, 0.15, 0.15)

    elseif self.fan_color == "black" then
        self:setColor(0.08, 0.08, 0.08)

    elseif self.fan_color == "yellow" then
        self:setColor(1, 0.9, 0.05)

    elseif self.fan_color == "green" then
        self:setColor(0.15, 1, 0.2)

    elseif self.fan_color == "orange" then
        self:setColor(1, 0.5, 0.05)
    end

    -------------------------------------------------------
    -- ПУЛЯ СМОТРИТ В СТОРОНУ ДВИЖЕНИЯ
    -------------------------------------------------------

    self.rotation = 0
    self.physics.match_rotation = true
end

-----------------------------------------------------------
-- ВСПЛЫВАЮЩИЙ ТЕКСТ
-----------------------------------------------------------

function KnightFanBullet:showPartyMessage(battler, text, color)
    if not battler then
        return
    end

    -- Показываем текст немного выше персонажа.
    local x = battler.x
    local y = battler.y - battler.height / 2 - 16

    local message = DeltaStatusText(
        x,
        y,
        text,
        color
    )

    Game.battle:addChild(message)
end

-----------------------------------------------------------
-- ПОЛУЧИТЬ УЧАСТНИКА ГРУППЫ ДЛЯ СООБЩЕНИЯ
-----------------------------------------------------------

function KnightFanBullet:getMessageBattler()
    if not Game.battle.party then
        return nil
    end

    -- Для визуального сообщения берём случайного
    -- участника группы.
    if #Game.battle.party > 0 then
        return Utils.pick(Game.battle.party)
    end

    return nil
end

-----------------------------------------------------------
-- СТОЛКНОВЕНИЕ
-----------------------------------------------------------

function KnightFanBullet:onCollide(soul)
    -- Эта конкретная пуля уже сталкивалась.
    if self.hit then
        return
    end

    self.hit = true

    local dashing =
        soul and soul.dashing == true

    -------------------------------------------------------
    -- ЖЁЛТАЯ
    --
    -- Без dash:
    -- обычный урон.
    --
    -- Во время dash:
    -- +3 TP, урон отменяется.
    -------------------------------------------------------

    if self.fan_color == "yellow" then

        if dashing then
            Game:giveTension(3)

            local battler =
                self:getMessageBattler()

            self:showPartyMessage(
                battler,
                "+3 TP",
                {1, 0.9, 0.05}
            )

            self:remove()
            return
        end

        -- Без dash просто обычная пуля.
        super.onCollide(self, soul)
        return
    end

    -------------------------------------------------------
    -- ЗЕЛЁНАЯ
    --
    -- Без dash:
    -- обычный урон.
    --
    -- Во время dash:
    -- лечение всей команды на 20% MAX HP.
    -------------------------------------------------------

    if self.fan_color == "green" then

        if dashing then

            for _, battler in ipairs(Game.battle.party) do
                if battler and battler.chara then

                    local max_hp =
                        battler.chara:getMaxStat("health")

                    local heal_amount =
                        math.max(
                            1,
                            math.ceil(max_hp * 0.20)
                        )

                    battler:heal(heal_amount)

                    self:showPartyMessage(
                        battler,
                        "+" .. heal_amount .. " HP",
                        {0.15, 1, 0.2}
                    )
                end
            end

            self:remove()
            return
        end

        -- Без dash зелёная просто наносит урон.
        super.onCollide(self, soul)
        return
    end

    -------------------------------------------------------
    -- ОРАНЖЕВАЯ
    --
    -- Без dash:
    -- обычный урон.
    --
    -- Во время dash:
    -- -3% текущего TP.
    -------------------------------------------------------

    if self.fan_color == "orange" then

        if dashing then

            local current_tp =
                Game:getTension()

            local lost_tp =
                math.ceil(current_tp * 0.03)

            if lost_tp > 0 then
                Game:removeTension(lost_tp)
            end

            local battler =
                self:getMessageBattler()

            self:showPartyMessage(
                battler,
                "-" .. lost_tp .. " TP",
                {1, 0.5, 0.05}
            )

            self:remove()
            return
        end

        -- Без dash просто обычный урон.
        super.onCollide(self, soul)
        return
    end

    -------------------------------------------------------
    -- КРАСНАЯ
    --
    -- Всегда обычный урон.
    -- Dash ничего не меняет.
    -------------------------------------------------------

    if self.fan_color == "red" then
        super.onCollide(self, soul)
        return
    end

    -------------------------------------------------------
    -- ЧЁРНАЯ
    --
    -- Всегда x2 урон.
    -- Dash ничего не меняет.
    -------------------------------------------------------

    if self.fan_color == "black" then
        super.onCollide(self, soul)
        return
    end

    -------------------------------------------------------
    -- ЕСЛИ ПОЧЕМУ-ТО ПРИШЁЛ НЕИЗВЕСТНЫЙ ЦВЕТ
    -------------------------------------------------------

    super.onCollide(self, soul)
end

return KnightFanBullet
