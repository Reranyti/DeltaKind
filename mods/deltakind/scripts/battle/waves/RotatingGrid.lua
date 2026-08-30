local RotatingGrid, super = Class(Wave)

function RotatingGrid:init()
    super.init(self)

    self.time = 20

    self:setArenaSize(210, 210)

    self.angle = 0
    self.spin_direction = 1
    self.blades = {}

    self.spin_paused = false
    self.spin_pause_timer = 0

    self.elapsed_time = 0
    self.next_spin_check = 1

    self.spin_event_chance = 0.08
    self.spin_event_chance_growth = 0.035
    self.spin_event_max_chance = 0.65
end

function RotatingGrid:onStart()
    local enemy =
        self.attacker or
        Game.battle:getEnemyBattler("kyle")

    if not enemy then
        return
    end

    self.angle = 0

    self.spin_direction =
        (math.random() < 0.5) and -1 or 1

    self.blades = {}

    self.spin_paused = false
    self.spin_pause_timer = 0

    self.elapsed_time = 0
    self.next_spin_check = 1

    local is_p2 =
        enemy.phase == 2

    self:spawnTPPickups(is_p2)

    self.timer:script(function(wait)
        while self.time > 0 do

            self:spawnBladeEffect(
                enemy,
                is_p2
            )

            wait(
                is_p2
                and 4.5
                or 5.0
            )

            self:clearBlades()

            wait(0.45)

            self.spin_direction =
                -self.spin_direction
        end
    end)
end

-----------------------------------------------------------
-- TP-ПУЛИ
-----------------------------------------------------------

function RotatingGrid:spawnTPPickups(is_p2)
    local arena = Game.battle.arena

    if not arena then
        Kristal.Console:error(
            "[GRID] TP: arena not found"
        )
        return
    end

    local count =
        is_p2 and 28 or 20

    Kristal.Console:log(
        "[GRID] TP COUNT: " ..
        tostring(count)
    )

    self.timer:script(function(wait)

        for i = 1, count do

            if self.time <= 0 then
                Kristal.Console:log(
                    "[GRID] TP stopped: wave time ended"
                )
                break
            end

            local soul =
                Game.battle.soul

            local x
            local y

            for attempt = 1, 20 do

                x = math.random(
                    math.floor(arena.left + 8),
                    math.floor(arena.right - 8)
                )

                y = math.random(
                    math.floor(arena.top + 8),
                    math.floor(arena.bottom - 8)
                )

                if not soul then
                    break
                end

                local dx =
                    x - soul.x

                local dy =
                    y - soul.y

                local distance =
                    math.sqrt(
                        dx * dx +
                        dy * dy
                    )

                if distance >= 45 then
                    break
                end
            end

            Kristal.Console:log(
                "[GRID] TP " ..
                tostring(i) ..
                " position: " ..
                tostring(x) ..
                ", " ..
                tostring(y)
            )

            local pickup =
                self:spawnBullet(
                    "knight_grid_tp",
                    x,
                    y
                )

            Kristal.Console:log(
                "[GRID] TP SPAWN " ..
                tostring(i) ..
                ": " ..
                tostring(pickup)
            )

            if pickup then

                Kristal.Console:log(
                    "[GRID] TP " ..
                    tostring(i) ..
                    " sprite=" ..
                    tostring(pickup.sprite ~= nil) ..
                    " collider=" ..
                    tostring(pickup.collider ~= nil) ..
                    " removed=" ..
                    tostring(pickup:isRemoved()) ..
                    " x=" ..
                    tostring(pickup.x) ..
                    " y=" ..
                    tostring(pickup.y)
                )

                pickup:setLayer(
                    BATTLE_LAYERS["above_arena"]
                )
            end

            wait(0.20)
        end

        Kristal.Console:log(
            "[GRID] TP SCRIPT FINISHED"
        )
    end)
end

-----------------------------------------------------------
-- ВЕНТИЛЬ
-----------------------------------------------------------

function RotatingGrid:spawnBladeEffect(
    enemy,
    is_p2
)
    local arena =
        Game.battle.arena

    if not arena then
        return
    end

    self:clearBlades()

    local arms =
        is_p2 and 3 or 2

    local blade_count = 8

    local first_distance = 10
    local distance_step = 20

    local spawn_data = {}

    for arm = 1, arms do

        local offset =
            ((math.pi * 2) / arms) *
            (arm - 1)

        for i = 1, blade_count do

            local distance =
                first_distance +
                (i - 1) *
                distance_step

            local angle =
                self.angle +
                offset

            table.insert(
                spawn_data,
                {
                    angle = angle,
                    distance = distance
                }
            )
        end
    end

    local extra_distance = 105

    table.insert(
        spawn_data,
        {
            angle =
                self.angle +
                math.pi / 2,
            distance =
                extra_distance
        }
    )

    table.insert(
        spawn_data,
        {
            angle =
                self.angle +
                math.pi * 1.5,
            distance =
                extra_distance
        }
    )

    local warnings = {}

    for _, data in ipairs(spawn_data) do

        local bx =
            arena.x +
            math.cos(data.angle) *
            data.distance

        local by =
            arena.y +
            math.sin(data.angle) *
            data.distance

        local warning =
            self:spawnObject(
                Rectangle(
                    bx - 4,
                    by - 4,
                    8,
                    8
                )
            )

        warning:setColor(
            0.1,
            0.7,
            1
        )

        warning.alpha = 0.8

        warning:setLayer(
            BATTLE_LAYERS["above_arena"]
        )

        table.insert(
            warnings,
            warning
        )
    end

    self.timer:after(
        0.45,
        function()

            for _, warning in ipairs(warnings) do

                if warning and
                   not warning:isRemoved() then

                    warning:remove()
                end
            end

            Assets.playSound(
                "sparkle_glitter",
                0.45,
                is_p2 and 1.15 or 1.0
            )

            for _, data in ipairs(spawn_data) do

                local bx =
                    arena.x +
                    math.cos(data.angle) *
                    data.distance

                local by =
                    arena.y +
                    math.sin(data.angle) *
                    data.distance

                local blade =
                    self:spawnBullet(
                        "bullets/smallbullet",
                        bx,
                        by
                    )

                if blade then

                    blade.damage =
                        math.random(400, 600)

                    blade.physics.speed = 0

                    if is_p2 then
                        blade:setColor(
                            1,
                            0.85,
                            0.25
                        )
                    else
                        blade:setColor(
                            1,
                            0.25,
                            0.25
                        )
                    end

                    table.insert(
                        self.blades,
                        {
                            obj = blade,
                            distance =
                                data.distance,
                            offset =
                                data.angle -
                                self.angle
                        }
                    )
                end
            end
        end
    )
end

-----------------------------------------------------------
-- UPDATE
-----------------------------------------------------------

function RotatingGrid:update()
    local arena =
        Game.battle.arena

    self.elapsed_time =
        self.elapsed_time + DT

    if self.spin_paused then

        self.spin_pause_timer =
            self.spin_pause_timer - DT

        if self.spin_pause_timer <= 0 then

            self.spin_paused = false
            self.spin_pause_timer = 0

            Assets.playSound(
                "bell",
                0.25,
                1.25
            )
        end
    end

    if self.elapsed_time >=
       self.next_spin_check then

        self.next_spin_check =
            self.next_spin_check + 1

        local seconds =
            math.floor(
                self.elapsed_time
            )

        local chance =
            self.spin_event_chance +
            math.max(
                0,
                seconds - 1
            ) *
            self.spin_event_chance_growth

        chance =
            math.min(
                chance,
                self.spin_event_max_chance
            )

        if math.random() < chance then

            if math.random() < 0.5 then

                self.spin_direction =
                    -self.spin_direction

                Assets.playSound(
                    "bell",
                    0.3,
                    1.15
                )

            else

                self.spin_paused = true
                self.spin_pause_timer = 1.0

                Assets.playSound(
                    "bell",
                    0.3,
                    0.8
                )
            end
        end
    end

    if arena and
       not self.spin_paused then

        local spin_speed =
            self:isPhaseTwo()
            and 0.027
            or 0.022

        self.angle =
            self.angle +
            spin_speed *
            self.spin_direction

        for _, blade_data in ipairs(
            self.blades
        ) do

            local blade =
                blade_data.obj

            if blade and
               not blade:isRemoved() then

                local angle =
                    self.angle +
                    blade_data.offset

                blade.x =
                    arena.x +
                    math.cos(angle) *
                    blade_data.distance

                blade.y =
                    arena.y +
                    math.sin(angle) *
                    blade_data.distance

                blade.rotation =
                    angle
            end
        end
    end

    super.update(self)
end

-----------------------------------------------------------
-- ФАЗА 2
-----------------------------------------------------------

function RotatingGrid:isPhaseTwo()
    local enemy =
        self.attacker or
        Game.battle:getEnemyBattler("kyle")

    return enemy and enemy.phase == 2
end

-----------------------------------------------------------
-- ОЧИСТКА
-----------------------------------------------------------

function RotatingGrid:clearBlades()
    for _, blade_data in ipairs(
        self.blades
    ) do

        local blade =
            blade_data.obj

        if blade and
           not blade:isRemoved() then

            blade:remove()
        end
    end

    self.blades = {}
end

function RotatingGrid:onEnd()
    self:clearBlades()

    if Game.battle.arena then
        Game.battle.arena:setSize(
            142,
            142
        )
    end

    super.onEnd(self)
end

return RotatingGrid