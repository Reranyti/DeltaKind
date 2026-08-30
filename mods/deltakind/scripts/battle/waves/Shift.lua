local Shift, super = Class(Wave)

function Shift:onStart()
    self.time = 12

    local enemy =
        self.attacker or
        Game.battle:getEnemyBattler("kyle")

    local is_phase2 =
        enemy and
        enemy.phase == 2

    self.timer:script(function(wait)
        local side = 1

        while self.time > 1 do

            if not enemy then
                break
            end

            local x =
                (side == 1)
                and Game.battle.arena.left - 200
                or Game.battle.arena.right + 200

            local gap_y =
                math.random(
                    Game.battle.arena.top + 20,
                    Game.battle.arena.bottom - 20
                )

            local step =
                is_phase2 and 11 or 15

            local speed =
                is_phase2 and 17 or 11

            local wait_time =
                is_phase2 and 0.45 or 0.9

            for y =
                Game.battle.arena.top - 20,
                Game.battle.arena.bottom + 20,
                step do

                local gap_size =
                    is_phase2 and 22 or 30

                local in_gap =
                    math.abs(y - gap_y) < gap_size

                if not in_gap then

                    local bullet =
                        self:spawnBullet(
                            "bullets/smallbullet",
                            x,
                            y
                        )

                    if bullet then
                        bullet.physics.speed =
                            speed

                        bullet.physics.direction =
                            (side == 1)
                            and 0
                            or math.pi

                        if is_phase2 then
                            bullet:setColor(
                                1,
                                1,
                                0
                            )
                        end

                        bullet.damage =
                            enemy.attack *
                            enemy:getDifficultyMultiplier()
                    end

                else

                    if is_phase2
                    or math.random() > 0.5 then

                        local trap =
                            self:spawnBullet(
                                "bullets/smallbullet",
                                x,
                                y
                            )

                        if trap then
                            trap.physics.speed =
                                speed * 0.4

                            trap.physics.direction =
                                (side == 1)
                                and 0
                                or math.pi

                            trap:setColor(
                                0,
                                1,
                                1
                            )

                            trap.damage =
                                enemy.attack * 0.5
                        end
                    end
                end
            end

            Assets.playSound(
                "shatter",
                0.4,
                is_phase2 and 1.2 or 0.8
            )

            side =
                side * -1

            wait(wait_time)
        end
    end)
end

return Shift