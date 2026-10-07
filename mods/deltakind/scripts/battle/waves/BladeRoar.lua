-----------------------------------------------------------
-- BLADE ROAR («Рёв») — финал, фаза 4
--
-- Арена расширяется почти на весь экран. Звёзды летят к Рыцарю,
-- расходятся по спирали, возвращаются и взрываются ромбами в 6
-- сторон. В конце — белый разрез через всё поле.
-- Урон: звёзды/ромбы 40, разрез 75 (по таблице референса).
-----------------------------------------------------------

local BladeRoar, super = Class(Wave)

local STARS = 12
local STAR_STEP = 0.22
local WINDUP_FINAL = 0.9

function BladeRoar:onStart()
    local enemy = self.attacker or Game.battle:getEnemyBattler("kyle")
    local arena = Game.battle.arena

    -- Арена почти на весь экран
    self:setArenaSize(520, 300)
    self:setArenaPosition(SCREEN_WIDTH / 2, 150)
    -- Прозрачный фон арены: на финале видно Рыцаря и фон боя
    if arena and arena.setBackgroundColor then arena:setBackgroundColor(0, 0, 0, 0) end

    local cx = enemy and (enemy.x - 50) or 520
    local cy = enemy and (enemy.y - 90) or 170

    self.time = STARS * STAR_STEP + 0.8 + 1.0 + 0.8 + 0.7 + WINDUP_FINAL + 1.0

    self.timer:script(function(wait)
        for i = 1, STARS do
            local ang = MathUtils.random(0, math.pi * 2)
            local s = self:spawnBullet("blade_star", cx, cy, ang, MathUtils.random(160, 230), 40)
            if s then s.wave = self end
            wait(STAR_STEP)
        end
        wait(0.8 + 1.0 + 0.8 + 0.7)
        Assets.playSound("knight_drawpower", 1)

        -- Финальный разрез через центр поля (почти по вертикали)
        local a = Game.battle.arena
        local length = math.sqrt(a.width ^ 2 + a.height ^ 2) + 60
        self:spawnBullet("blade_slash", a.x, a.y, math.rad(MathUtils.random(70, 110)), length, WINDUP_FINAL, 0.2, 46, 75)
    end)
end

return BladeRoar
