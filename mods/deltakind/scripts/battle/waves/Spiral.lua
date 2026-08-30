-----------------------------------------------------------
-- SPIRAL — новая атака (фаза 1)
--
-- Из центра арены раскручивается расширяющаяся спираль
-- пуль: угол выстрела постепенно увеличивается, скорость
-- растёт вместе с множителем сложности. Паттерн не
-- пересекается по структуре ни с одной из существующих
-- волн (CircleBullets — статичное дрейфующее кольцо,
-- RotatingGrid — вращающиеся лезвия, Saw — спиральные
-- arenahazard-триангли + вертикальные капли).
--
-- Соглашения взяты из уже существующих волн (см. Fracture.lua):
-- self.time, self.timer:script, self:spawnBullet(x, y),
-- затем b.physics.direction/b.physics.speed напрямую (в
-- радианах — так во всём движке, см. object.lua:
-- math.cos(physics.direction)). Урон = enemy.attack,
-- отмасштабированный через уже существующий
-- enemy:getDifficultyMultiplier().
-----------------------------------------------------------

local Spiral, super = Class(Wave)

function Spiral:onStart()
    self.time = 16

    local enemy =
        self.attacker or
        Game.battle:getEnemyBattler("kyle")

    local is_phase2 =
        enemy and
        enemy.phase == 2

    local arena = Game.battle.arena

    self.timer:script(function(wait)
        local angle = 0
        local angle_step = math.rad(18)
        local direction = 1

        while self.time > 0 do

            if not enemy then
                break
            end

            local multiplier =
                (enemy.getDifficultyMultiplier and
                enemy:getDifficultyMultiplier()) or
                1

            local b =
                self:spawnBullet(
                    "bullets/smallbullet",
                    arena.x,
                    arena.y
                )

            if b then
                b.physics.direction = angle
                b.physics.speed = 3 + multiplier * 1.2

                b.damage =
                    math.ceil(
                        (enemy.attack or 10) *
                        multiplier
                    )
            end

            angle = angle + angle_step * direction

            -- Во второй фазе спираль периодически меняет
            -- направление закрутки — не даёт душе просто
            -- стоять на месте вслед за одним и тем же вектором.
            if is_phase2 and love.math.random() < 0.05 then
                direction = -direction
            end

            wait(0.06)
        end
    end)
end

return Spiral
