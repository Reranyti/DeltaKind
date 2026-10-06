-----------------------------------------------------------
-- BLADE SPLIT («Разрез поля») — клинки и разрезы, атака 5
--
-- Через арену идёт разрез: сначала красная линия-телеграф, потом
-- белый удар. Из линии разреза в обе стороны вылетают ромбы двух
-- скоростей (быстрые — красноватые, медленные — белые; рядом не
-- больше двух одной скорости). Серия из 7 разрезов.
--   фаза 1: разрезы вертикальные/горизонтальные, с небольшим наклоном
--   фаза 2: направление выбирается заново на каждом разрезе, есть диагонали
-----------------------------------------------------------

local BladeSplit, super = Class(Wave)

local CUTS = 7
local ACTIVE_TIME = 0.12
local FADE_TIME = 0.25
local PAUSE_TIME = 0.55
local WIDTH = 10

function BladeSplit:onStart()
    local enemy = self.attacker or Game.battle:getEnemyBattler("kyle")
    local phase2 = enemy and enemy.phase == 2
    local windup = phase2 and 0.6 or 0.85
    local arena = Game.battle.arena

    self.time = CUTS * (windup + ACTIVE_TIME) + (CUTS - 1) * PAUSE_TIME + 1.4

    local multiplier =
        (enemy and enemy.getDifficultyMultiplier and enemy:getDifficultyMultiplier()) or 1
    local k = 1 + (multiplier - 1) * 0.25
    local diamond_damage = math.ceil(100 * k)

    local length = math.sqrt(arena.width ^ 2 + arena.height ^ 2) + 40
    local base_dir = (math.random() < 0.5) and 0 or (math.pi / 2)

    self.timer:script(function(wait)
        local fast_run = 0
        local last_fast = nil
        for i = 1, CUTS do
            local dir = base_dir
            if phase2 then
                local r = math.random()
                dir = (r < 0.4) and 0 or (r < 0.8) and (math.pi / 2) or (math.pi / 4) * (math.random() < 0.5 and 1 or 3)
            end
            -- небольшое отклонение (несколько градусов)
            dir = dir + math.rad(MathUtils.random(-6, 6))

            -- линия разреза: через центр арены со смещением поперёк
            local nx, ny = -math.sin(dir), math.cos(dir)
            local off = MathUtils.random(-0.28, 0.28) * math.min(arena.width, arena.height)
            local cx, cy = arena.x + nx * off, arena.y + ny * off

            self:spawnBullet("blade_slash", cx, cy, dir, length, windup, ACTIVE_TIME, WIDTH, 30)
            wait(windup + ACTIVE_TIME)

            -- ромбы из линии разреза в обе стороны (перпендикулярно линии)
            local n = 7
            local span = math.sqrt(arena.width ^ 2 + arena.height ^ 2) * 0.55
            for j = 1, n do
                local t = (j - 1) / (n - 1) - 0.5
                local px, py = cx + math.cos(dir) * span * t, cy + math.sin(dir) * span * t
                -- чередуем скорости, не больше двух подряд одинаковых
                local fast = (j % 2 == 0)
                if math.random() < 0.3 then fast = not fast end
                if last_fast == fast then fast_run = fast_run + 1 else fast_run = 1 end
                if fast_run > 2 then fast = not fast; fast_run = 1 end
                last_fast = fast
                local sp = fast and 4.2 or 2.0
                for side = -1, 1, 2 do
                    local ang = dir + (math.pi / 2) * side
                    self:spawnBullet("blade_diamond", px, py, ang, sp, diamond_damage, fast)
                end
            end
            if i < CUTS then wait(PAUSE_TIME) end
        end
    end)
end

return BladeSplit
