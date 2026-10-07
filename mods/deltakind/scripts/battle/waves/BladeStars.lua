-----------------------------------------------------------
-- BLADE STARS («Звёзды») — атака 1 оригинала Рокочущего Рыцаря.
--
-- Хронология (секунды от начала, по раскадровке оригинала 24.0–32.0):
--   0.0   арена въезжает (маленькая); пунктирная белая линия-прицел
--         на высоте центра поля через весь экран;
--   1.0   конус ветра из кончика меча: белая вспышка, потом фиолетовый;
--         арену сдувает влево всё время, пока он горит;
--   1.6–4.4 звёзды рождаются у кончика меча по одной, идут налево веером
--         (внутри конуса), растут с расстоянием;
--   4.6   конец ветра: вторая белая вспышка конуса; арена дёргается влево;
--   4.8   толстая белая полоса-вспышка на высоте центра поля;
--   4.9   все звёзды разом замирают и краснеют, из них лучи света;
--   6.1   все звёзды разом взрываются: серые вспышки + осколки-«ёлочки»;
--   8.4   конец.
-- Фаза 2: звёзд больше.
-----------------------------------------------------------

local BladeStars, super = Class(Wave)

local ARENA_W, ARENA_H = 128, 100
local SLIDE = 66                 -- полный сдвиг арены влево (px)
local SLIDE_GRADUAL = 0.67       -- доля сдвига, пока дует ветер
local F = 0.68                -- ускорение: все времена оригинала × F
local T_LINE_END = 1.0 * F
local T_CONE_START = 1.0 * F
local T_CONE_END = 4.6 * F
local T_STARS_START = 1.6 * F
local T_RED = 4.9 * F
local T_BOOM = 6.1 * F
local T_END = 8.4 * F

function BladeStars:onStart()
    local enemy = self.attacker or Game.battle:getEnemyBattler("kyle")
    local phase2 = enemy and enemy.phase == 2

    local count = phase2 and 20 or 16
    local step = (4.4 * F - T_STARS_START) / count

    local multiplier =
        (enemy and enemy.getDifficultyMultiplier and enemy:getDifficultyMultiplier()) or 1
    local damage = math.ceil(75 * (1 + (multiplier - 1) * 0.25))

    self.stage = "fly"
    self.speed_mult = 1 / F
    self.snd_red, self.snd_boom = false, false
    self.clock = 0
    self.time = T_END

    -- Арена маленькая; запоминаем исходное положение для сдвига ветром
    self:setArenaSize(ARENA_W, ARENA_H)
    local arena = Game.battle.arena
    self.ax0, self.ay0 = arena.x, arena.y

    -- Кончик меча (вершина конуса) на высоте центра поля
    local tipx = enemy and (enemy.x - 82) or 438
    local tipy = self.ay0

    self.timer:script(function(wait)
        -- 0.0: пунктирная линия-прицел
        Assets.playSound("knight_drawpower", 0.8)
        self:spawnBullet("blade_line", tipy, T_LINE_END)
        wait(T_CONE_START)

        -- 1.0: конус ветра (вспышка в начале и в конце)
        self:spawnBullet("blade_cone", tipx, tipy, math.pi, 700, 0.42, T_CONE_END - T_CONE_START)
        wait(T_STARS_START - T_CONE_START)

        -- 1.6–4.4: звёзды по одной веером внутри конуса
        for i = 1, count do
            local ang = math.pi + MathUtils.random(-0.4, 0.4)
            local scale = (math.random() < 0.2) and MathUtils.random(0.78, 0.95) or MathUtils.random(0.52, 0.72)
            local s = self:spawnBullet("blade_nova", tipx, tipy, ang, damage, scale)
            if s then s.wave = self end
            wait(step)
        end

        -- 4.8: толстая белая полоса на высоте центра поля
        wait(math.max(0.01, T_CONE_END + 0.2 * F - (T_STARS_START + count * step)))
        Assets.playSound("knight_cut", 0.8)
        self:spawnBullet("blade_line", tipy, 0.2, 10, true)
    end)
end

function BladeStars:update()
    super.update(self)
    self.clock = (self.clock or 0) + DT
    local t = self.clock

    -- Стадии звёзд (общие для всех)
    if t >= T_BOOM then
        self.stage = "boom"
        if not self.snd_boom then
            self.snd_boom = true
            Assets.playSound("knight_star_explosion_close", 1)
            Game.battle:shakeCamera(5, 5, 0.4)
        end
    elseif t >= T_RED then
        self.stage = "red"
        if not self.snd_red then
            self.snd_red = true
            Assets.playSound("knight_drawpower", 0.9, 1.15)
        end
    end

    -- Ветер: пока дует конус, арену сдувает влево (ускоряясь);
    -- после конца ветра она дёргается до конечной точки.
    if self.ax0 then
        local k
        if t < T_CONE_START + 0.2 then
            k = 0
        elseif t < T_CONE_END then
            local u = (t - T_CONE_START - 0.2) / (T_CONE_END - T_CONE_START - 0.2)
            k = SLIDE_GRADUAL * u * (0.7 + 0.3 * u)
        else
            local u = MathUtils.clamp((t - T_CONE_END) / 0.25, 0, 1)
            k = SLIDE_GRADUAL + (1 - SLIDE_GRADUAL) * (1 - (1 - u) * (1 - u))
        end
        self:setArenaPosition(self.ax0 - SLIDE * k, self.ay0)
    end
end

return BladeStars
