-----------------------------------------------------------
-- BLADE SPIN («Вращающийся разрез») — клинки и разрезы, атака 4
--
-- Серия из 6 взмахов. В каждом — несколько красных линий через
-- позицию души (на момент начала взмаха): они быстро вращаются,
-- замедляются и замирают, затем бьют белым разрезом.
-- Число линий: фаза 1 — 1-2-2-3-3-4; фаза 2 — 3-3-4-4-4-4.
-- Центр взмаха не следует за душой после старта.
-----------------------------------------------------------

local BladeSpin, super = Class(Wave)

local COUNTS_P1 = {1, 2, 2, 3, 3, 4}
local COUNTS_P2 = {3, 3, 4, 4, 4, 4}
local ACTIVE_TIME = 0.14
local FADE_TIME = 0.25
local PAUSE_TIME = 0.3
local WIDTH = 22

function BladeSpin:onStart()
    local enemy = self.attacker or Game.battle:getEnemyBattler("kyle")
    local phase2 = enemy and enemy.phase == 2

    local counts = phase2 and COUNTS_P2 or COUNTS_P1
    local windup = phase2 and 0.38 or 0.5

    self.time = #counts * (windup + ACTIVE_TIME) + (#counts - 1) * PAUSE_TIME + FADE_TIME + 0.3

    local multiplier =
        (enemy and enemy.getDifficultyMultiplier and enemy:getDifficultyMultiplier()) or 1
    local damage = math.ceil(130 * (1 + (multiplier - 1) * 0.25))

    local arena = Game.battle.arena
    local length = math.sqrt(arena.width ^ 2 + arena.height ^ 2) + 40

    self.timer:script(function(wait)
        for i, count in ipairs(counts) do
            local soul = Game.battle.soul
            local sx = soul and soul.x or arena.x
            local sy = soul and soul.y or arena.y

            if enemy and enemy.playPose then enemy:playPose("flurry", windup + 0.2) end
            local base = MathUtils.random(0, math.pi)
            local spin = (math.random() < 0.5 and -1 or 1) * MathUtils.random(10, 14)
            for k = 1, count do
                local ang = base + (k - 1) * (math.pi / count)
                self:spawnBullet("blade_slash", sx, sy, ang, length, windup, ACTIVE_TIME, WIDTH, damage, spin, "rot", k == 1)
            end

            wait(windup + ACTIVE_TIME)
            if i < #counts then wait(PAUSE_TIME) end
        end
    end)
end

return BladeSpin
