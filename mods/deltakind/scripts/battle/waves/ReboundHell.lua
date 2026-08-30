-----------------------------------------------------------
-- REBOUND HELL — вариация Rebound специально для фазы 2
--
-- В обычном Rebound за раз прилетает ОДНА пуля со
-- СЛУЧАЙНО выбранной стороны (from_left = math.random() >
-- 0.5). Здесь каждый цикл прилетает СРАЗУ ДВЕ пули —
-- одна слева, одна справа одновременно — плюс доля
-- "фальшивых" (лечащих) пуль снижена, то есть в среднем
-- атака ощутимо злее, а не просто "то же самое, но быстрее".
--
-- Использует тот же bullets/knight_rebound и тот же
-- механизм временного сужения арены (setArenaSize/onEnd),
-- что и оригинальный Rebound.
-----------------------------------------------------------

local ReboundHell, super = Class(Wave)

function ReboundHell:init()
    super.init(self)

    self:setArenaSize(190, 190)
end

function ReboundHell:onStart()
    self.time = 10

    local enemy =
        self.attacker or
        Game.battle:getEnemyBattler("kyle")

    if not enemy then
        return
    end

    local fake_chance = 0.2

    self.timer:script(function(wait)
        while self.time > 0 do
            local arena = Game.battle.arena

            if not arena then
                break
            end

            local y_left =
                math.random(arena.top, arena.bottom)

            local y_right =
                math.random(arena.top, arena.bottom)

            local spawn_distance = 40

            self:spawnBullet(
                "knight_rebound",
                arena.left - spawn_distance,
                y_left,
                math.random() < fake_chance,
                0
            )

            self:spawnBullet(
                "knight_rebound",
                arena.right + spawn_distance,
                y_right,
                math.random() < fake_chance,
                math.pi
            )

            wait(0.4)
        end
    end)
end

function ReboundHell:onEnd()
    if Game.battle.arena then
        Game.battle.arena:setSize(142, 142)
    end

    super.onEnd(self)
end

return ReboundHell
