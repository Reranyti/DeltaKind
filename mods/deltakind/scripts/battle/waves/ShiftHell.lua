-----------------------------------------------------------
-- SHIFT HELL — вариация Shift специально для фазы 2
--
-- В обычном Shift стены прилетают ПООЧЕРЁДНО то слева,
-- то справа (см. Shift.lua, side = side * -1). Здесь обе
-- стены летят ОДНОВРЕМЕННО, с независимыми случайными
-- позициями разрыва — нужно искать общий безопасный
-- промежуток между двумя разными разрывами сразу, а не
-- просто следить за одной стеной за раз.
--
-- Файл предназначен исключительно для hell_waves (2 фаза),
-- поэтому параметры сразу "жёсткие", без ветвления
-- is_phase2, как в оригинальном Shift.
-----------------------------------------------------------

local ShiftHell, super = Class(Wave)

function ShiftHell:onStart()
    self.time = 12

    local enemy =
        self.attacker or
        Game.battle:getEnemyBattler("kyle")

    local arena = Game.battle.arena

    local step = 11
    local speed = 17
    local gap_size = 24
    local wait_time = 0.55

    self.timer:script(function(wait)
        while self.time > 1 do

            if not enemy then
                break
            end

            local multiplier =
                (enemy.getDifficultyMultiplier and
                enemy:getDifficultyMultiplier()) or
                1

            local gap_y_left =
                math.random(
                    arena.top + 20,
                    arena.bottom - 20
                )

            local gap_y_right =
                math.random(
                    arena.top + 20,
                    arena.bottom - 20
                )

            for y = arena.top - 20, arena.bottom + 20, step do

                -- Левая стена -> летит вправо
                if math.abs(y - gap_y_left) >= gap_size then
                    local b_left =
                        self:spawnBullet(
                            "bullets/smallbullet",
                            arena.left - 200,
                            y
                        )

                    if b_left then
                        b_left.physics.speed = speed
                        b_left.physics.direction = 0
                        b_left:setColor(1, 1, 0)
                        b_left.damage =
                            math.ceil(
                                (enemy.attack or 10) *
                                multiplier
                            )
                    end
                end

                -- Правая стена -> летит влево
                if math.abs(y - gap_y_right) >= gap_size then
                    local b_right =
                        self:spawnBullet(
                            "bullets/smallbullet",
                            arena.right + 200,
                            y
                        )

                    if b_right then
                        b_right.physics.speed = speed
                        b_right.physics.direction = math.pi
                        b_right:setColor(1, 1, 0)
                        b_right.damage =
                            math.ceil(
                                (enemy.attack or 10) *
                                multiplier
                            )
                    end
                end
            end

            Assets.playSound("shatter", 0.4, 1.2)

            wait(wait_time)
        end
    end)
end

return ShiftHell
