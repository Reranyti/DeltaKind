local Rain, super = Class(Wave)

function Rain:onStart()
    local enemy =
        self.attacker or
        Game.battle:getEnemyBattler("kyle")

    local is_phase2 =
        enemy and enemy.phase == 2

    self.time =
        is_phase2 and 15 or 10

    local mode =
        math.random(1, 3)

    self.timer:script(function(wait)
        while self.time > 0 do

            for i = 1, 2 do

                local bg_x =
                    math.random(
                        Game.battle.arena.left - 100,
                        Game.battle.arena.right + 100
                    )

                local bg =
                    self:spawnBullet(
                        "bullets/smallbullet",
                        bg_x,
                        -40
                    )

                if bg then
                    bg.remove_offscreen = false
                    bg.collidable = false

                    bg:setScale(
                        0.6,
                        5
                    )

                    bg.color = {
                        0.4,
                        0.4,
                        0.4,
                        0.4
                    }

                    bg.physics.speed =
                        math.random(20, 30)

                    bg.physics.direction =
                        math.rad(100)

                    bg.layer =
                        BATTLE_LAYERS["below_bullets"]
                end
            end

            local x =
                math.random(
                    Game.battle.arena.left,
                    Game.battle.arena.right
                )

            local bullet =
                self:spawnBullet(
                    "bullets/smallbullet",
                    x,
                    -20
                )

            if bullet then
                bullet.remove_offscreen = false

                if mode == 1 then

                    bullet.physics.speed =
                        is_phase2 and 18 or 15

                    bullet.physics.direction =
                        math.rad(90)

                elseif mode == 2 then

                    bullet.physics.speed =
                        is_phase2 and 15 or 12

                    bullet.physics.direction =
                        math.rad(
                            70 +
                            math.random(40)
                        )

                else

                    bullet.physics.speed =
                        is_phase2 and 26 or 22

                    bullet:setScale(
                        1,
                        is_phase2 and 6 or 4
                    )

                    bullet.physics.direction =
                        math.rad(90)
                end

                if is_phase2 then
                    bullet.color = {
                        1,
                        1,
                        0
                    }
                else
                    bullet.color = {
                        0,
                        0.8,
                        1
                    }
                end

                bullet.damage =
                    (enemy and enemy.attack or 10) *
                    (
                        enemy and
                        enemy:getDifficultyMultiplier() or
                        1
                    )

                bullet.destroy_on_hit = true
            end

            local wait_time =
                is_phase2
                and 0.07
                or (
                    mode == 3
                    and 0.25
                    or 0.12
                )

            wait(wait_time)
        end
    end)
end

return Rain