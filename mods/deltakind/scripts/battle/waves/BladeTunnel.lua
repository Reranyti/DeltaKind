-----------------------------------------------------------
-- BLADE TUNNEL («Коридор клинков») — клинки и разрезы, атака 3
--
-- Две шеренги мечей идут через весь экран (сверху остриём вниз,
-- снизу остриём вверх). Между шеренгами — коридор, который плавно
-- ходит вверх-вниз; душа должна оставаться в нём. Мечи рядом с душой
-- краснеют. В конце — залп: красные линии-предупреждения, затем
-- клинки через арену.
--   фаза 1: коридор шире, ход медленнее
--   фаза 2: коридор уже, ход быстрее
-----------------------------------------------------------

local BladeTunnel, super = Class(Wave)

local SPEED = 170          -- px/с, скорость шеренг
local SPACING = 40         -- px между мечами
local MAIN_TIME = 8.0      -- основная часть
local FINISH_WINDUP = 0.9
local FINISH_COUNT = 6

function BladeTunnel:onStart()
    local enemy = self.attacker or Game.battle:getEnemyBattler("kyle")
    local phase2 = enemy and enemy.phase == 2
    local arena = Game.battle.arena

    self.gap = phase2 and 52 or 62
    self.omega = phase2 and 1.9 or 1.4
    self.t = 0
    self.cx, self.cy = arena.x, arena.y
    -- Амплитуда: коридор ходит заметно, но пересечение с ареной всегда >= ~40 px
    local max_amp = arena.height / 2 + self.gap / 2 - 40
    self.amp = math.max(0, math.min(max_amp, phase2 and 40 or 34))

    local multiplier =
        (enemy and enemy.getDifficultyMultiplier and enemy:getDifficultyMultiplier()) or 1
    local k = 1 + (multiplier - 1) * 0.25
    local damage = math.ceil(62 * k)
    local finisher_damage = math.ceil(160 * k)

    self.time = MAIN_TIME + FINISH_WINDUP + 1.6

    -- Шеренги: спавним мечи с постоянным шагом за правым краем экрана
    local dx = SPEED * 0
    self.timer:script(function(wait)
        local spawn_x = SCREEN_WIDTH + 40
        -- Предзаполняем экран, чтобы шеренги были сразу
        local x = spawn_x - SPACING
        while x > -40 do
            self:spawnRow(x, damage)
            x = x - SPACING
        end
        local step = SPACING / SPEED
        local elapsed = 0
        while elapsed < MAIN_TIME do
            wait(step)
            elapsed = elapsed + step
            self:spawnRow(spawn_x, damage)
        end

        -- Финал: красные линии через душу, затем клинки
        local soul = Game.battle.soul
        local sx = soul and soul.x or arena.x
        local sy = soul and soul.y or arena.y
        local length = math.sqrt(arena.width ^ 2 + arena.height ^ 2) + 40
        local base = MathUtils.random(0, 180)
        for i = 1, FINISH_COUNT do
            local ang = math.rad(base + (i - 1) * (180 / FINISH_COUNT) + MathUtils.random(-6, 6))
            if enemy and enemy.playPose and i == 1 then enemy:playPose("flurry", FINISH_WINDUP + 0.3) end
            self:spawnBullet("blade_slash", sx, sy, ang, length, FINISH_WINDUP, 0.12, 18, finisher_damage, 0, "rot", i == 1)
        end
    end)
end

function BladeTunnel:spawnRow(x, damage)
    -- три слоя: дальние сдвинуты по x на полшага, чтобы мечи не сливались
    for layer = 1, 3 do
        local off = (layer == 3) and 0 or (layer == 2 and SPACING * 0.33 or SPACING * 0.66)
        for _, row in ipairs({ "top", "bottom" }) do
            local b = self:spawnBullet("blade_sword", x + off, row, SPEED, damage, layer)
            if b then b.wave = self end
        end
    end
end

--- Положение острия шеренги (общее для всех мечей): коридор ходит по синусоиде.
function BladeTunnel:getTipY(row)
    local center = self.cy + math.sin(self.t * self.omega) * self.amp
    if row == "top" then
        return center - self.gap / 2
    end
    return center + self.gap / 2
end

function BladeTunnel:update()
    super.update(self)
    self.t = (self.t or 0) + DT
end

return BladeTunnel
