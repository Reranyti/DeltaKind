-----------------------------------------------------------
-- BLADE SEEK («Прицел») — клинки и разрезы, атака 3
--
-- Мечи появляются вокруг души, разворачиваются остриём к ней и
-- следят за ней; затем направление фиксируется (меч краснеет) и меч
-- летит по зафиксированной линии. Мечи идут один за другим, поэтому
-- нужно постоянно двигаться, а не стоять на месте.
--   фаза 1: 8 мечей, прицеливание 0.75 с, шаг 0.55 с
--   фаза 2: 12 мечей, прицеливание 0.5 с, шаг 0.35 с
-----------------------------------------------------------

local BladeSeek, super = Class(Wave)

function BladeSeek:onStart()
    local enemy = self.attacker or Game.battle:getEnemyBattler("kyle")
    local phase2 = enemy and enemy.phase == 2

    -- Как в оригинале: 10 мечей, интервал и время прицеливания сокращаются
    local count = 10
    local aim_start = phase2 and 0.8 or 1.0
    local aim_end = phase2 and 0.4 or 0.55

    local multiplier =
        (enemy and enemy.getDifficultyMultiplier and enemy:getDifficultyMultiplier()) or 1
    local damage = math.ceil(206 * (1 + (multiplier - 1) * 0.25))

    -- Время волны: сумма интервалов + последний прицел + разрез
    local total = 0
    for i = 1, count do
        local t = MathUtils.lerp(aim_start, aim_end, (i - 1) / (count - 1))
        total = total + t * 0.8
    end
    self.time = total + aim_end + 0.3 + 0.9

    -- Маленькая квадратная арена, как в оригинале
    self:setArenaSize(104, 104)

    -- 8 сторон света (кардинальные и интеркардинальные)
    local dirs = {}
    for i = 0, 7 do dirs[#dirs + 1] = i * math.pi / 4 end
    local last_i = nil

    self.timer:script(function(wait)
        for i = 1, count do
            local aim = MathUtils.lerp(aim_start, aim_end, (i - 1) / (count - 1))
            local di
            repeat di = math.random(1, 8) until di ~= last_i
            last_i = di

            local b = self:spawnBullet("blade_dart", 0, 0, dirs[di], aim, damage)
            if b then b.wave = self end
            wait(aim * 0.8)
        end
    end)
end

return BladeSeek
