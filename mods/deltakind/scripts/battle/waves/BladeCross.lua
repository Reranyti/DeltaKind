-----------------------------------------------------------
-- BLADE CROSS («Крест») — клинки и разрезы, атака 2
--
-- Серия из 5 ударов, оси чередуются:
--   горизонтальный, вертикальный, горизонтальный, вертикальный,
--   затем оба сразу (крест).
-- Каждый разрез — широкая полоса через всю арену со «щелью»,
-- которая собрана из двух линий blade_slash с зазором.
--   фаза 1: щель 70 px, телеграф 0.8 с
--   фаза 2: щель 50 px, телеграф 0.5 с
-- Между ударами пауза 0.4 с.
-- В кресте центр пересечения совпадает с обеими щелями, поэтому
-- там остаётся проходимый квадрат размером со щель.
-----------------------------------------------------------

local BladeCross, super = Class(Wave)

local STRIKES = {"h", "v", "h", "v", "cross"}

local ACTIVE_TIME = 0.12
local FADE_TIME = 0.25
local PAUSE_TIME = 0.3
local BAND_WIDTH = 50    -- толщина разреза
local OVERSHOOT = 40     -- насколько линии выступают за край арены
local MAX_REACH = 0.6    -- щель не дальше этой доли размера арены от души

--- Случайная точка в пределах reach от center, зажатая в [min, max].
local function pickNear(center, reach, min, max)
    local value = center + MathUtils.random(-reach, reach)
    return MathUtils.clamp(value, min, max)
end

function BladeCross:onStart()
    local enemy =
        self.attacker or
        Game.battle:getEnemyBattler("kyle")

    local is_phase2 = enemy and enemy.phase == 2

    local gap = is_phase2 and 50 or 70
    local windup = is_phase2 and 0.4 or 0.55

    -- Волна кончается после затухания последнего удара (+ небольшой запас)
    self.time = #STRIKES * (windup + ACTIVE_TIME)
        + (#STRIKES - 1) * PAUSE_TIME
        + FADE_TIME + 0.25

    local multiplier =
        (enemy and enemy.getDifficultyMultiplier and
        enemy:getDifficultyMultiplier()) or
        1
    local damage = math.ceil(200 * (1 + (multiplier - 1) * 0.25))

    local arena = Game.battle.arena
    if not arena then return end
    local left, right = arena.x - arena.width / 2, arena.x + arena.width / 2
    local top, bottom = arena.y - arena.height / 2, arena.y + arena.height / 2

    -- Один отрезок разреза: ось "h" — горизонтальный на высоте fixed,
    -- ось "v" — вертикальный на x = fixed; from/to — координаты вдоль оси.
    local function spawnSegment(axis, fixed, from, to)
        if to - from <= 0 then return end
        local mid = (from + to) / 2
        local half = (to - from) / 2
        if axis == "h" then
            self:spawnBullet("blade_slash", mid, fixed, 0, half,
                windup, ACTIVE_TIME, BAND_WIDTH, damage, 0, "rot")
        else
            self:spawnBullet("blade_slash", fixed, mid, math.pi / 2, half,
                windup, ACTIVE_TIME, BAND_WIDTH, damage, 0, "rot")
        end
    end

    -- Разрез на всю арену с щелью gap_pos (центр щели) вдоль оси.
    local function spawnCut(axis, fixed, gap_pos)
        local lo = (axis == "h" and left or top) - OVERSHOOT
        local hi = (axis == "h" and right or bottom) + OVERSHOOT
        spawnSegment(axis, fixed, lo, gap_pos - gap / 2)
        spawnSegment(axis, fixed, gap_pos + gap / 2, hi)
    end

    local reach_x = arena.width * MAX_REACH
    local reach_y = arena.height * MAX_REACH

    self.timer:script(function(wait)
        for i, kind in ipairs(STRIKES) do
            -- Позиция души фиксируется в начале удара; щель всегда в зоне
            -- досягаемости от неё, так что удар честный.
            local soul = Game.battle.soul
            local sx, sy
            if soul then
                sx, sy = soul.x, soul.y
            else
                sx, sy = arena.x, arena.y
            end

            -- Щель целиком внутри арены
            local gx = pickNear(sx, reach_x, left + gap / 2, right - gap / 2)
            local gy = pickNear(sy, reach_y, top + gap / 2, bottom - gap / 2)

            if enemy and enemy.playPose then enemy:playPose("flurry", windup + 0.15) end
            if kind == "h" then
                -- полоса накрывает душу (с небольшим разбросом), щель по x
                spawnCut("h", sy + MathUtils.random(-BAND_WIDTH / 3, BAND_WIDTH / 3), gx)
            elseif kind == "v" then
                spawnCut("v", sx + MathUtils.random(-BAND_WIDTH / 3, BAND_WIDTH / 3), gy)
            else
                -- крест: центр пересечения = обе щели
                spawnCut("h", gy, gx)
                spawnCut("v", gx, gy)
            end

            wait(windup + ACTIVE_TIME)
            if i < #STRIKES then
                wait(PAUSE_TIME)
            end
        end
    end)
end

return BladeCross
