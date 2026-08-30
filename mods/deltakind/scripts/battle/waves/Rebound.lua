local Rebound, super = Class(Wave)

function Rebound:init()
    super.init(self)

    self:setArenaSize(190, 190)
end

function Rebound:onStart()
    self.time = 10

    local enemy =
        self.attacker or
        Game.battle:getEnemyBattler("kyle")

    if not enemy then
        return
    end

    local fake_chance = 0.35

    self.timer:script(function(wait)
        while self.time > 0 do
            local arena = Game.battle.arena

            if not arena then
                break
            end

            local from_left =
                math.random() > 0.5

            local y =
                math.random(
                    arena.top,
                    arena.bottom
                )

            local x
            local direction

            local spawn_distance = 40

            if from_left then
                x =
                    arena.left -
                    spawn_distance

                direction = 0
            else
                x =
                    arena.right +
                    spawn_distance

                direction = math.pi
            end

            local is_fake =
                math.random() < fake_chance

            self:spawnBullet(
                "knight_rebound",
                x,
                y,
                is_fake,
                direction
            )

            wait(0.55)
        end
    end)
end

function Rebound:update()
    super.update(self)
end

function Rebound:onEnd()
    if Game.battle.arena then
        Game.battle.arena:setSize(
            142,
            142
        )
    end

    super.onEnd(self)
end

return Rebound