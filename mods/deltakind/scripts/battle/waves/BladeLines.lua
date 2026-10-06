-----------------------------------------------------------
-- BLADE LINES («Рассечение») — клинки и разрезы, атака 1
--
-- Серия из 6 ударов. В каждом ударе несколько красных линий
-- через позицию души на момент начала удара; после телеграфа
-- они вспыхивают белым и бьют. Число линий:
--   фаза 1: 1-2-2-3-3-4, телеграф 0.7 с
--   фаза 2: 3-3-4-4-4-4, телеграф 0.4 с
-- Между ударами пауза 0.5 с.
-----------------------------------------------------------

local BladeLines, super = Class(Wave)

local COUNTS_P1 = {1, 2, 2, 3, 3, 4}
local COUNTS_P2 = {3, 3, 4, 4, 4, 4}

local ACTIVE_TIME = 0.12
local FADE_TIME = 0.25
local PAUSE_TIME = 0.5
local MIN_ANGLE_GAP = 25 -- градусов между линиями (с учётом разброса)

--- Углы (радианы) для n линий: равномерно по полуокружности + случайный сдвиг и разброс.
local function pickAngles(n)
    local step = 180 / n
    local jitter = math.min(10, (step - MIN_ANGLE_GAP) / 2)
    local base = MathUtils.random(0, 180)
    local angles = {}
    for i = 1, n do
        local deg = base + (i - 1) * step + MathUtils.random(-jitter, jitter)
        table.insert(angles, math.rad(deg))
    end
    return angles
end

function BladeLines:onStart()
    local enemy =
        self.attacker or
        Game.battle:getEnemyBattler("kyle")

    local is_phase2 = enemy and enemy.phase == 2

    local counts = is_phase2 and COUNTS_P2 or COUNTS_P1
    local windup = is_phase2 and 0.4 or 0.7

    -- Волна кончается после затухания последнего удара (+ небольшой запас)
    self.time = #counts * (windup + ACTIVE_TIME)
        + (#counts - 1) * PAUSE_TIME
        + FADE_TIME + 0.25

    local multiplier =
        (enemy and enemy.getDifficultyMultiplier and
        enemy:getDifficultyMultiplier()) or
        1
    local damage = math.ceil(200 * (1 + (multiplier - 1) * 0.25))

    local arena = Game.battle.arena
    -- Достаточно, чтобы линия пересекала всю арену из любой точки внутри неё
    local length = math.sqrt(arena.width ^ 2 + arena.height ^ 2) + 40

    self.timer:script(function(wait)
        for i, count in ipairs(counts) do
            -- Позиция души фиксируется в начале удара
            local soul = Game.battle.soul
            local sx, sy
            if soul then
                sx, sy = soul.x, soul.y
            else
                sx, sy = arena.x, arena.y
            end

            -- TODO: общий звук начала телеграфа (файла пока нет)
            for _, angle in ipairs(pickAngles(count)) do
                self:spawnBullet(
                    "blade_slash",
                    sx, sy,
                    angle, length,
                    windup, ACTIVE_TIME,
                    nil, damage
                )
            end

            wait(windup + ACTIVE_TIME)
            if i < #counts then
                wait(PAUSE_TIME)
            end
        end
    end)
end

return BladeLines
