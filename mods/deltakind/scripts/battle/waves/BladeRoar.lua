-----------------------------------------------------------
-- BLADE ROAR («Рёв») — финал.
--
-- Рыцарь встаёт в центр экрана, рамки арены нет, душа летает по всему
-- полю. Фон меняет цвет (красный → фиолетовый → синий → пауза → снова,
-- см. blade_field). Из Рыцаря по спирали идут звёзды (оригинальные спрайты),
-- в конце красные звёзды разом, белая вспышка с конфетти из осколков
-- и финальный красно-белый разрез через центр.
-- Урон: звёзды 60, финальный разрез 75.
-----------------------------------------------------------

local BladeRoar, super = Class(Wave)

local T_STREAM_A = { 1.0, 5.0 }
local T_STREAM_B = { 5.8, 8.4 }
local T_RED = 8.0
local T_FLASH = 8.9
local T_SLASH = 9.3
local WINDUP_FINAL = 0.8
local T_END = 11.4

function BladeRoar:onStart()
    local enemy = self.attacker or Game.battle:getEnemyBattler("kyle")
    local arena = Game.battle.arena

    -- Арена на весь экран, рамка скрыта
    self:setArenaSize(560, 330)
    self:setArenaPosition(SCREEN_WIDTH / 2, 175)
    if arena and arena.setBackgroundColor then arena:setBackgroundColor(0, 0, 0, 0) end
    self.arena_alpha = arena and arena.alpha
    if arena then arena.alpha = 0 end

    self.time = T_END

    local multiplier =
        (enemy and enemy.getDifficultyMultiplier and enemy:getDifficultyMultiplier()) or 1
    local damage = math.ceil(60 * (1 + (multiplier - 1) * 0.25))
    local slash_damage = math.ceil(75 * (1 + (multiplier - 1) * 0.25))

    -- Рыцарь в центр экрана на время атаки
    self.home_x, self.home_y = enemy and enemy.x, enemy and enemy.y
    local target_x, target_y = SCREEN_WIDTH / 2 - 7, 200
    if enemy then self.timer:tween(0.8, enemy, { x = target_x, y = target_y }, "in-out-cubic") end

    -- центр Рыцаря (подобран по спрайту)
    local cx, cy = target_x + 7, target_y - 8

    self:spawnBullet("blade_field", cx, cy)
    Assets.playSound("knight_drawpower", 1)

    self.timer:script(function(wait)
        local t = 0
        local function at(time)
            if time > t then wait(time - t); t = time end
        end

        at(T_STREAM_A[1])
        while t < T_STREAM_A[2] do
            for _ = 1, 2 do
                local s = self:spawnBullet("blade_star", cx, cy, MathUtils.random(0, math.pi * 2), 110, damage, 0.9)
                if s then s.wave = self end
            end
            wait(0.28); t = t + 0.28
        end

        at(T_STREAM_B[1])
        while t < T_STREAM_B[2] do
            for _ = 1, 2 do
                local s = self:spawnBullet("blade_star", cx, cy, MathUtils.random(0, math.pi * 2), 150, damage, -1.1)
                if s then s.wave = self end
            end
            wait(0.22); t = t + 0.22
        end

        -- красные звёзды разом
        at(T_RED)
        for i = 0, 9 do
            local a = i / 10 * math.pi * 2
            local s = self:spawnBullet("blade_star", cx, cy, a, 190, damage, 0, true)
            if s then s.wave = self end
        end

        -- белая вспышка и конфетти
        at(T_FLASH)
        Assets.playSound("knight_star_explosion_close", 1)
        Game.battle:shakeCamera(6, 6, 0.5)
        for _ = 1, 70 do
            self:spawnBullet("blade_confetti", cx, cy, MathUtils.random(0, math.pi * 2), MathUtils.random(120, 340), MathUtils.random(1.0, 1.6))
        end

        -- финальный разрез через центр
        at(T_SLASH)
        local a = Game.battle.arena
        local length = math.sqrt(a.width ^ 2 + a.height ^ 2) / 2 + 40
        if enemy and enemy.playPose then enemy:playPose("slash", WINDUP_FINAL + 0.4) end
        self:spawnBullet("blade_slash", cx, cy, math.rad(MathUtils.random(60, 120)), length, WINDUP_FINAL, 0.2, 40, slash_damage, 0, "rot", true)

        -- Рыцарь возвращается на своё место
        at(T_END - 0.9)
        if enemy and self.home_x then self.timer:tween(0.7, enemy, { x = self.home_x, y = self.home_y }, "in-out-cubic") end
    end)
end

function BladeRoar:onEnd()
    local arena = Game.battle and Game.battle.arena
    if arena then arena.alpha = self.arena_alpha or 1 end
    local enemy = self.attacker or (Game.battle and Game.battle:getEnemyBattler("kyle"))
    if enemy and self.home_x then enemy.x, enemy.y = self.home_x, self.home_y end
    super.onEnd(self)
end

return BladeRoar
