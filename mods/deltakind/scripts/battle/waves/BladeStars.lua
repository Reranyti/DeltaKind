-----------------------------------------------------------
-- BLADE STARS («Звёзды») — клинки и разрезы, атака 1 (по оригиналу)
--
-- Тонкая белая линия из ладони через арену, затем фиолетовый конус;
-- по нему вылетают шестиконечные звёзды, растут и расходятся по арене,
-- краснеют, взрываются осколками (3 коротких + 3 длинных).
-- Фаза 2: звёзд больше.
-----------------------------------------------------------

local BladeStars, super = Class(Wave)

function BladeStars:onStart()
    local enemy = self.attacker or Game.battle:getEnemyBattler("kyle")
    local phase2 = enemy and enemy.phase == 2
    local arena = Game.battle.arena

    local count = phase2 and 18 or 13
    local step = phase2 and 0.13 or 0.17

    local multiplier =
        (enemy and enemy.getDifficultyMultiplier and enemy:getDifficultyMultiplier()) or 1
    local damage = math.ceil(75 * (1 + (multiplier - 1) * 0.25))

    -- Ладонь Рыцаря
    local px = enemy and (enemy.x - 78) or 440
    local py = enemy and (enemy.y - 82) or 178

    self.time = 0.7 + count * step + 1.2 + 0.7 + 1.6

    self.timer:script(function(wait)
        -- 1. линия-прицел из ладони через арену
        local ang = math.atan2(arena.y - py, arena.x - px)
        local len = math.sqrt(arena.width ^ 2 + arena.height ^ 2) + 200
        self:spawnBullet("blade_slash", px, py, ang, len, 0.5, 0.05, 2, 0)
        wait(0.55)

        -- 2. конус и звёзды
        self:spawnBullet("blade_cone", px, py, math.pi, 480, 0.42, 1.2 + count * step + 0.7)
        for i = 1, count do
            local tx = arena.x + MathUtils.random(-0.5, 0.5) * (arena.width + 40)
            local ty = arena.y + MathUtils.random(-0.5, 0.5) * (arena.height + 40)
            local s = self:spawnBullet("blade_nova", px, py, tx, ty, damage)
            if s then s.wave = self end
            wait(step)
        end
    end)
end

return BladeStars
