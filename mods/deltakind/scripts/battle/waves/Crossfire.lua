-----------------------------------------------------------
-- CROSSFIRE — новая атака (фаза 1)
--
-- Из левого и правого верхних углов арены по очереди
-- вылетают диагональные очереди пуль, пересекающие арену
-- крест-накрест (X). В отличие от Fracture (пули летят к
-- душе) здесь направление фиксированное геометрическое —
-- нужно уворачиваться в "окна" между очередями, а не от
-- слежения. Использует только существующий smallbullet.
-----------------------------------------------------------

local Crossfire, super = Class(Wave)

function Crossfire:onStart()
    self.time = 14

    local enemy =
        self.attacker or
        Game.battle:getEnemyBattler("kyle")

    local is_phase2 =
        enemy and
        enemy.phase == 2

    local arena = Game.battle.arena

    self.timer:script(function(wait)
        local from_left = true

        while self.time > 0 do

            if not enemy then
                break
            end

            local multiplier =
                (enemy.getDifficultyMultiplier and
                enemy:getDifficultyMultiplier()) or
                1

            local count = is_phase2 and 6 or 4
            local spacing = arena.width / (count + 1)

            for i = 1, count do
                local spawn_x, spawn_y, angle

                if from_left then
                    spawn_x = arena.left + spacing * i
                    spawn_y = arena.top - 20
                    angle = math.rad(60)
                else
                    spawn_x = arena.right - spacing * i
                    spawn_y = arena.top - 20
                    angle = math.rad(120)
                end

                local b =
                    self:spawnBullet(
                        "bullets/smallbullet",
                        spawn_x,
                        spawn_y
                    )

                if b then
                    b.physics.direction = angle
                    b.physics.speed = 6 + multiplier * 1.5

                    b.damage =
                        math.ceil(
                            (enemy.attack or 10) *
                            multiplier
                        )
                end
            end

            from_left = not from_left

            wait(is_phase2 and 0.5 or 0.7)
        end
    end)
end

return Crossfire
