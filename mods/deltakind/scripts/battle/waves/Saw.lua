local Saw, super = Class(Wave)

-- =========================================================
-- KYLE SAW
--
-- ФАЗА 1:
-- Большая пила катится по НИЗУ арены.
-- После неё вверх вылетают мелкие осколки.
--
-- ФАЗА 2:
-- Большие кольца появляются по арене.
-- В некоторых секторах появляются крупные пули.
-- Нужно dash'иться из кольца в кольцо.
--
-- Soul:
-- Используется OrangeSoul.
-- F = dash.
-- =========================================================

function Saw:init()
    super.init(self)

    self.time = 22

    self.phase = 1

    self.saw_active = false
    self.saw_finished = false

    self.saw_direction = 1
    self.saw_x = 0
    self.saw_y = 0

    self.saw_parts = {}

    self.rotation = 0

    self.variant_timer = 0
end

-- =========================================================
-- START
-- =========================================================

function Saw:onStart()

    local enemy =
        self.attacker or
        Game.battle:getEnemyBattler("kyle")

    if not enemy then
        return
    end

    self.phase =
        enemy.phase or 1

    ---------------------------------------------------------
    -- БОЛЬШАЯ АРЕНА
    ---------------------------------------------------------

    if Game.battle.arena then

        if self.phase >= 2 then
            Game.battle.arena:setSize(
                300,
                210
            )
        else
            Game.battle.arena:setSize(
                330,
                175
            )
        end
    end

    ---------------------------------------------------------
    -- ОРАНЖЕВАЯ ДУША
    ---------------------------------------------------------

    if self.phase >= 2 then

        local soul =
            OrangeSoul()

        Game.battle:swapSoul(
            soul
        )
    end

    ---------------------------------------------------------
    -- ФАЗА 1
    ---------------------------------------------------------

    if self.phase == 1 then

        self.timer:script(function(wait)

            wait(0.8)

            while self.time > 0 do

                -------------------------------------------------
                -- ВАЖНО:
                -- НОВАЯ ПИЛА НЕ ПОЯВИТСЯ,
                -- ПОКА ПРЕДЫДУЩАЯ НЕ ЗАКОНЧИЛА ПРОКАТ.
                -------------------------------------------------

                self.saw_active = true
                self.saw_finished = false

                self:spawnRollingSaw(
                    enemy
                )

                while self.saw_active
                and self.time > 0 do

                    wait(0.05)
                end

                -------------------------------------------------
                -- ТОЛЬКО ПОСЛЕ ПИЛЫ ПОЯВЛЯЕТСЯ СЛЕД.
                -------------------------------------------------

                if self.saw_finished
                and self.time > 0 then

                    self:spawnSawTrail(
                        enemy
                    )
                end

                -------------------------------------------------
                -- ПЕРЕДЫШКА
                -------------------------------------------------

                wait(
                    self:getPhase1Delay(
                        enemy
                    )
                )

                -------------------------------------------------
                -- СЛЕДУЮЩАЯ ПИЛА С ДРУГОЙ СТОРОНЫ.
                -------------------------------------------------

                self.saw_direction =
                    -self.saw_direction
            end
        end)

    ---------------------------------------------------------
    -- ФАЗА 2
    ---------------------------------------------------------

    else

        self.timer:script(function(wait)

            wait(0.8)

            while self.time > 0 do

                self:spawnDashRingPattern(
                    enemy
                )

                wait(
                    self:getPhase2Delay(
                        enemy
                    )
                )
            end
        end)
    end
end

-- =========================================================
-- ФАЗА 1
-- СКОРОСТЬ ЗАВИСИТ ОТ HP БОССА
-- =========================================================

function Saw:getPhase1Progress(enemy)

    if not enemy then
        return 0
    end

    local max_hp =
        enemy.max_health or
        enemy.health

    if not max_hp or max_hp <= 0 then
        return 0
    end

    ---------------------------------------------------------
    -- ВАЖНО:
    -- Берём диапазон только от 100% до 50%.
    --
    -- Поэтому на 50% прогресс = 1.
    -- Ниже 50% первая вариация НЕ становится ещё быстрее.
    ---------------------------------------------------------

    local hp =
        math.max(
            enemy.health,
            max_hp * 0.5
        )

    local progress =
        1 -
        (
            (hp - max_hp * 0.5) /
            (max_hp * 0.5)
        )

    return MathUtils.clamp(
        progress,
        0,
        1
    )
end

function Saw:getPhase1Delay(enemy)

    local progress =
        self:getPhase1Progress(enemy)

    return
        0.75 -
        progress * 0.30
end

-- =========================================================
-- БОЛЬШАЯ ПИЛА
-- =========================================================

function Saw:spawnRollingSaw(enemy)

    local arena =
        Game.battle.arena

    if not arena then
        self.saw_active = false
        return
    end

    ---------------------------------------------------------
    -- ПРОГРЕСС СЛОЖНОСТИ
    ---------------------------------------------------------

    local progress =
        self:getPhase1Progress(
            enemy
        )

    ---------------------------------------------------------
    -- РАЗМЕР ПИЛЫ
    ---------------------------------------------------------

    local radius =
        34 +
        progress * 10

    ---------------------------------------------------------
    -- СКОРОСТЬ
    ---------------------------------------------------------

    local speed =
        3.2 +
        progress * 1.5

    ---------------------------------------------------------
    -- НИЖНЯЯ ЧАСТЬ АРЕНЫ
    ---------------------------------------------------------

    local y =
        arena.bottom -
        radius -
        3

    self.saw_y = y

    local direction =
        self.saw_direction

    ---------------------------------------------------------
    -- НАЧАЛЬНАЯ И КОНЕЧНАЯ ПОЗИЦИЯ
    ---------------------------------------------------------

    local start_x

    local end_x

    if direction > 0 then

        start_x =
            arena.left -
            radius -
            20

        end_x =
            arena.right +
            radius +
            20

    else

        start_x =
            arena.right +
            radius +
            20

        end_x =
            arena.left -
            radius -
            20
    end

    self.saw_x =
        start_x

    self.saw_parts = {}

    ---------------------------------------------------------
    -- КОЛИЧЕСТВО ЗУБЬЕВ
    ---------------------------------------------------------

    local teeth =
        math.floor(
            24 +
            progress * 12
        )

    ---------------------------------------------------------
    -- СОЗДАЁМ КРУГ ИЗ МАЛЕНЬКИХ ПУЛЬ
    ---------------------------------------------------------

    for i = 1, teeth do

        local angle =
            (
                (math.pi * 2) /
                teeth
            ) *
            (i - 1)

        local x =
            start_x +
            math.cos(angle) *
            radius

        local py =
            y +
            math.sin(angle) *
            radius

        local bullet =
            self:spawnBullet(
                "bullets/smallbullet",
                x,
                py
            )

        if bullet then

            bullet.damage =
                enemy.attack or 10

            bullet.physics.speed = 0

            bullet:setScale(
                2.2 +
                progress * 0.6
            )

            bullet:setColor(
                1,
                0.15,
                0.15
            )

            table.insert(
                self.saw_parts,
                {
                    bullet = bullet,
                    angle = angle,
                    radius = radius
                }
            )
        end
    end

    ---------------------------------------------------------
    -- ЦЕНТР
    ---------------------------------------------------------

    local center =
        self:spawnBullet(
            "bullets/smallbullet",
            start_x,
            y
        )

    if center then

        center.damage =
            enemy.attack or 10

        center.physics.speed = 0

        center:setScale(
            3.0 +
            progress * 0.8
        )

        center:setColor(
            0.8,
            0.05,
            0.05
        )

        table.insert(
            self.saw_parts,
            {
                bullet = center,
                angle = 0,
                radius = 0
            }
        )
    end

    self.rotation = 0

    Assets.playSound(
        "shroomlight_place",
        0.8,
        0.7
    )

    ---------------------------------------------------------
    -- ПРОКАТ
    ---------------------------------------------------------

    self.timer:script(function(wait)

        local x =
            start_x

        while true do

            -------------------------------------------------
            -- ДВИЖЕНИЕ ВПРАВО / ВЛЕВО
            -------------------------------------------------

            x =
                x +
                speed *
                direction

            self.saw_x =
                x

            -------------------------------------------------
            -- ВРАЩЕНИЕ ПИЛЫ
            -------------------------------------------------

            self.rotation =
                self.rotation +
                0.15 *
                direction

            -------------------------------------------------
            -- ДВИГАЕМ КАЖДЫЙ ЗУБ
            -------------------------------------------------

            for _, data in ipairs(
                self.saw_parts
            ) do

                local bullet =
                    data.bullet

                if bullet and
                   not bullet:isRemoved() then

                    local angle =
                        data.angle +
                        self.rotation

                    bullet.x =
                        x +
                        math.cos(angle) *
                        data.radius

                    bullet.y =
                        y +
                        math.sin(angle) *
                        data.radius

                    bullet.rotation =
                        angle +
                        math.pi / 2
                end
            end

            -------------------------------------------------
            -- ПРОВЕРКА КОНЦА ПРОКАТА
            -------------------------------------------------

            if direction > 0
            and x >= end_x then

                break
            end

            if direction < 0
            and x <= end_x then

                break
            end

            wait(0.016)
        end

        -----------------------------------------------------
        -- ПИЛА ЗАКОНЧИЛА ПРОКАТ
        -----------------------------------------------------

        for _, data in ipairs(
            self.saw_parts
        ) do

            local bullet =
                data.bullet

            if bullet and
               not bullet:isRemoved() then

                bullet:remove()
            end
        end

        self.saw_parts = {}

        -----------------------------------------------------
        -- ТОЛЬКО ЗДЕСЬ СТАВИМ FALSE.
        --
        -- Это гарантирует, что следующая пила
        -- не появится раньше.
        -----------------------------------------------------

        self.saw_finished = true
        self.saw_active = false
    end)
end

-- =========================================================
-- СЛЕД ПИЛЫ
-- =========================================================

function Saw:spawnSawTrail(enemy)

    local arena =
        Game.battle.arena

    if not arena then
        return
    end

    ---------------------------------------------------------
    -- Чем меньше HP, тем больше осколков.
    ---------------------------------------------------------

    local progress =
        self:getPhase1Progress(
            enemy
        )

    local count =
        math.floor(
            7 +
            progress * 5
        )

    local spacing =
        arena.width /
        (count + 1)

    ---------------------------------------------------------
    -- ПУЛИ ПОЯВЛЯЮТСЯ ПОСЛЕ ПИЛЫ.
    ---------------------------------------------------------

    for i = 1, count do

        local x =
            arena.left +
            spacing * i

        local y =
            arena.bottom +
            8

        local bullet =
            self:spawnBullet(
                "bullets/smallbullet",
                x,
                y
            )

        if bullet then

            bullet.damage =
                math.floor(
                    (enemy.attack or 10) *
                    0.55
                )

            bullet.physics.speed =
                4.0 +
                progress * 1.5

            bullet.physics.direction =
                -math.pi / 2

            bullet:setScale(
                1.5 +
                progress * 0.4
            )

            bullet:setColor(
                1,
                0.3,
                0.3
            )
        end
    end
end

-- =========================================================
-- ФАЗА 2
-- КРУГИ ДЛЯ DASH
-- =========================================================

function Saw:getPhase2Delay(enemy)

    local hp =
        enemy.health or
        enemy.max_health

    local max_hp =
        enemy.max_health or
        hp

    if max_hp <= 0 then
        return 2.0
    end

    local progress =
        1 -
        (
            hp /
            max_hp
        )

    progress =
        MathUtils.clamp(
            progress,
            0,
            1
        )

    return
        2.0 -
        progress * 0.65
end

function Saw:spawnDashRingPattern(enemy)

    local arena =
        Game.battle.arena

    if not arena then
        return
    end

    ---------------------------------------------------------
    -- ТРИ ПОЗИЦИИ ПО ГОРИЗОНТАЛИ
    ---------------------------------------------------------

    local positions = {
        arena.left + arena.width * 0.20,
        arena.left + arena.width * 0.50,
        arena.left + arena.width * 0.80
    }

    local ring_y =
        arena.y

    ---------------------------------------------------------
    -- СЛУЧАЙНОЕ ПЕРЕМЕЩЕНИЕ
    ---------------------------------------------------------

    local safe =
        math.random(
            1,
            #positions
        )

    for i, x in ipairs(
        positions
    ) do

        local radius =
            42

        local parts =
            20

        for j = 1, parts do

            local angle =
                (
                    math.pi * 2 /
                    parts
                ) *
                (j - 1)

            -------------------------------------------------
            -- ДЕЛАЕМ ПРОХОД.
            --
            -- Игрок должен dash-нуться через разрыв.
            -------------------------------------------------

            local gap =
                5

            if i == safe then
                gap = 7
            end

            local in_gap =
                j >= 9
                and j <= 9 + gap

            if not in_gap then

                local bx =
                    x +
                    math.cos(angle) *
                    radius

                local by =
                    ring_y +
                    math.sin(angle) *
                    radius

                local bullet =
                    self:spawnBullet(
                        "bullets/smallbullet",
                        bx,
                        by
                    )

                if bullet then

                    bullet.damage =
                        math.floor(
                            (enemy.attack or 10) *
                            0.65
                        )

                    bullet.physics.speed = 0

                    bullet:setScale(
                        2.0
                    )

                    bullet:setColor(
                        1,
                        0.2,
                        0.2
                    )
                end
            end
        end

        -----------------------------------------------------
        -- В НЕКОТОРЫХ КРУГАХ БОЛЬШАЯ ПУЛЯ.
        -----------------------------------------------------

        if i ~= safe
        and math.random() < 0.55 then

            local big =
                self:spawnBullet(
                    "bullets/smallbullet",
                    x,
                    ring_y
                )

            if big then

                big.damage =
                    enemy.attack or 10

                big.physics.speed =
                    2.5

                local target =
                    Game.battle.soul

                if target then

                    big.physics.direction =
                        MathUtils.angle(
                            big.x,
                            big.y,
                            target.x,
                            target.y
                        )

                    big.rotation =
                        big.physics.direction

                    big.physics.match_rotation =
                        true
                end

                big:setScale(
                    4.5
                )

                big:setColor(
                    1,
                    0.8,
                    0.2
                )
            end
        end
    end

    Assets.playSound(
        "sparkle_glitter",
        0.45,
        0.9
    )
end

-- =========================================================
-- UPDATE
-- =========================================================

function Saw:update()

    super.update(self)
end

-- =========================================================
-- END
-- =========================================================

function Saw:onEnd()

    ---------------------------------------------------------
    -- УДАЛЯЕМ ОСТАВШИЕСЯ ЧАСТИ ПИЛЫ.
    ---------------------------------------------------------

    for _, data in ipairs(
        self.saw_parts
    ) do

        local bullet =
            data.bullet

        if bullet and
           not bullet:isRemoved() then

            bullet:remove()
        end
    end

    self.saw_parts = {}

    ---------------------------------------------------------
    -- ВОЗВРАЩАЕМ ОБЫЧНУЮ ДУШУ.
    ---------------------------------------------------------

    if Game.battle.soul then

        local normal_soul =
            Soul()

        Game.battle:swapSoul(
            normal_soul
        )
    end

    ---------------------------------------------------------
    -- ВОЗВРАЩАЕМ РАЗМЕР АРЕНЫ.
    ---------------------------------------------------------

    if Game.battle.arena then

        Game.battle.arena:setSize(
            142,
            142
        )
    end

    if Game.battle.soul then
        Game.battle.soul.alpha = 1
    end

    self.saw_active = false
    self.saw_finished = false

    super.onEnd(self)
end

return Saw

