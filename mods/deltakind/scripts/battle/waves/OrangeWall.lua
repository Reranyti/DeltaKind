local OrangeWall, super = Class(Wave)

function OrangeWall:init()
    super.init(self)

    self.time = 25
    self.last_color = nil
    self.same_color_count = 0
    self.orange_soul = nil
end

function OrangeWall:onStart()
    local enemy =
        self.attacker or
        Game.battle:getEnemyBattler("kyle")

    if not enemy then
        return
    end

    local is_phase2 =
        enemy.phase == 2

    self.time =
        is_phase2 and 28 or 25

    if Game.battle.arena then
        Game.battle.arena:setSize(
            is_phase2 and 340 or 320,
            150
        )
    end

    self.orange_soul = OrangeSoul()

    Game.battle:swapSoul(
        self.orange_soul
    )

    self.timer:script(function(wait)
        wait(0.7)

        while self.time > 0 do

            self:spawnWall(
                enemy,
                is_phase2
            )

            if is_phase2 then
                wait(1.1)
            else
                wait(1.35)
            end
        end
    end)
end

function OrangeWall:getRandomColor()
    local colors = {
        "red",
        "black",
        "yellow",
        "green",
        "orange"
    }

    local available = {}

    for _, color in ipairs(colors) do
        if color ~= self.last_color
        or self.same_color_count < 3 then

            table.insert(
                available,
                color
            )
        end
    end

    local chosen =
        available[
            math.random(
                1,
                #available
            )
        ]

    if chosen == self.last_color then
        self.same_color_count =
            self.same_color_count + 1
    else
        self.last_color = chosen
        self.same_color_count = 1
    end

    return chosen
end

function OrangeWall:spawnWall(
    enemy,
    is_phase2
)
    local arena =
        Game.battle.arena

    if not arena then
        return
    end

    local left =
        arena.left

    local right =
        arena.right

    local top =
        arena.top

    local bottom =
        arena.bottom

    local spacing =
        is_phase2 and 17 or 19

    local count =
        math.floor(
            (bottom - top) /
            spacing
        ) + 5

    local spawn_x =
        right + 45

    local speed =
        is_phase2 and 4.6 or 4.0

    local difficulty =
        enemy:getDifficultyMultiplier()

    if not difficulty then
        difficulty = 1
    end

    local base_damage =
        (enemy.attack or 10) *
        difficulty

    for i = -2, count do

        local y =
            top -
            spacing +
            i * spacing

        local bullet_type =
            self:getRandomColor()

        y =
            y +
            math.random(-2, 2)

        local bullet =
            self:spawnBullet(
                "knight_fan_bullet",
                spawn_x,
                y,
                bullet_type,
                speed,
                base_damage
            )

        if bullet then

            bullet.physics.direction =
                math.pi

            bullet.physics.speed =
                speed

            bullet.rotation =
                math.pi

            bullet.physics.match_rotation =
                true

            if bullet_type == "black" then

                bullet:setScale(
                    5.5,
                    2.8
                )

            elseif bullet_type == "yellow"
            or bullet_type == "green"
            or bullet_type == "orange" then

                bullet:setScale(
                    4.8,
                    2.4
                )

            else

                bullet:setScale(
                    5,
                    2.5
                )
            end
        end
    end

    Assets.playSound(
        "shroomlight_place",
        0.7,
        is_phase2 and 0.65 or 0.75
    )
end

function OrangeWall:update()
    super.update(self)
end

function OrangeWall:onEnd()
    if Game.battle.soul then
        local normal_soul = Soul()

        Game.battle:swapSoul(
            normal_soul
        )
    end

    if Game.battle.arena then
        Game.battle.arena:setSize(
            142,
            142
        )
    end

    if Game.battle.soul then
        Game.battle.soul.alpha = 1
    end

    self.orange_soul = nil

    super.onEnd(self)
end

return OrangeWall