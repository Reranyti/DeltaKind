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
                is_phase2 and 10 or 13

            local speed =
                is_phase2 and 18 or 13

            local wait_time =
                is_phase2 and 0.5 or 0.9

            for y =
                Game.battle.arena.top - 20,
                Game.battle.arena.bottom + 20,
                step do

                -- gap_size увеличен: разрыв должен быть проходимым
                local gap_size =
                    is_phase2 and 32 or 40

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
                    -- В Phase 2 в разрыве спавним медленную ловушку
                    -- только с вероятностью 40% -- разрыв остаётся проходимым
                    if is_phase2 and math.random() > 0.6 then

                        local trap =
                            self:spawnBullet(
                                "bullets/smallbullet",
                                x,
                                y
                            )

                        if trap then
                            trap.physics.speed =
                                speed * 0.3

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
                                enemy.attack * 0.4
                        end
                    end
                end
            end

            -- 1-2 медленные пули строго внутри разрыва -- дезориентируют
            -- но не закрывают проход полностью
            local slow_offsets = is_phase2 and {-8, 8} or {0}
            for _, off in ipairs(slow_offsets) do
                local slow = self:spawnBullet(
                    "bullets/smallbullet",
                    x, gap_y + off
                )
                if slow then
                    slow.physics.speed = speed * 0.4
                    slow.physics.direction =
                        (side == 1) and 0 or math.pi
                    slow:setColor(1, 0.4, 0)
                    slow.damage = enemy.attack * 0.5
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