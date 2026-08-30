local CircleBullets, super = Class(Wave)

function CircleBullets:init()
    super.init(self)

    self.time = 20

    self:setArenaSize(390, 230)

    self.circle_x = 0
    self.circle_y = 0

    self.circle_radius = 64

    self.circle_bullets = {}

    self.circle_angle = 0
    self.circle_rotation_speed = 0.035

    self.move_angle = 0
    self.move_timer = 0
    self.circle_speed = 0.9

    self.boundary_damage = 20
    self.boundary_damage_timer = 0
end

function CircleBullets:onStart()
    local enemy =
        self.attacker or
        Game.battle:getEnemyBattler("kyle")

    if not enemy then
        return
    end

    local is_p2 =
        enemy.phase == 2

    local arena =
        Game.battle.arena

    if not arena then
        return
    end

    self.circle_radius =
        is_p2 and 70 or 64

    self.circle_speed =
        is_p2 and 1.05 or 0.9

    self.circle_rotation_speed =
        is_p2 and 0.045 or 0.035

    self.circle_x =
        arena.x

    self.circle_y =
        arena.y

    self.move_angle =
        math.random() *
        math.pi * 2

    self.move_timer =
        math.random(1, 3)

    self.circle_angle = 0

    self:createCircle()

    self.timer:script(function(wait)

        wait(0.6)

        while self.time > 0 do

            self:spawnIncomingBullets(
                enemy,
                is_p2
            )

            wait(
                is_p2
                and 0.95
                or 1.15
            )
        end
    end)
end

-----------------------------------------------------------
-- СОЗДАНИЕ КРУГА
-----------------------------------------------------------

function CircleBullets:createCircle()
    local arena =
        Game.battle.arena

    if not arena then
        return
    end

    local count = 16

    for i = 1, count do

        local angle =
            ((i - 1) / count) *
            math.pi * 2

        local x =
            self.circle_x +
            math.cos(angle) *
            self.circle_radius

        local y =
            self.circle_y +
            math.sin(angle) *
            self.circle_radius

        local bullet =
            self:spawnBullet(
                "bullets/smallbullet",
                x,
                y
            )

        if bullet then

            bullet.collidable = false
            bullet.remove_offscreen = false

            bullet:setScale(
                1.4,
                1.4
            )

            bullet:setColor(
                0.2,
                0.75,
                1
            )

            table.insert(
                self.circle_bullets,
                {
                    obj = bullet,
                    offset = angle
                }
            )
        end
    end
end

-----------------------------------------------------------
-- ДВИЖЕНИЕ КРУГА
-----------------------------------------------------------

function CircleBullets:updateCircle()
    local arena =
        Game.battle.arena

    if not arena then
        return
    end

    self.move_timer =
        self.move_timer - DT

    if self.move_timer <= 0 then

        self.move_timer =
            math.random(1, 3)

        self.move_angle =
            math.random() *
            math.pi * 2
    end

    self.circle_x =
        self.circle_x +
        math.cos(self.move_angle) *
        self.circle_speed

    self.circle_y =
        self.circle_y +
        math.sin(self.move_angle) *
        self.circle_speed

    local margin =
        self.circle_radius + 8

    if self.circle_x <
       arena.left + margin then

        self.circle_x =
            arena.left + margin

        self.move_angle =
            math.pi -
            self.move_angle
    end

    if self.circle_x >
       arena.right - margin then

        self.circle_x =
            arena.right - margin

        self.move_angle =
            math.pi -
            self.move_angle
    end

    if self.circle_y <
       arena.top + margin then

        self.circle_y =
            arena.top + margin

        self.move_angle =
            -self.move_angle
    end

    if self.circle_y >
       arena.bottom - margin then

        self.circle_y =
            arena.bottom - margin

        self.move_angle =
            -self.move_angle
    end

    self.circle_angle =
        self.circle_angle +
        self.circle_rotation_speed

    for _, data in ipairs(
        self.circle_bullets
    ) do

        local bullet =
            data.obj

        if bullet and
           not bullet:isRemoved() then

            local angle =
                data.offset +
                self.circle_angle

            bullet.x =
                self.circle_x +
                math.cos(angle) *
                self.circle_radius

            bullet.y =
                self.circle_y +
                math.sin(angle) *
                self.circle_radius

            bullet.rotation =
                angle
        end
    end
end

-----------------------------------------------------------
-- ВХОДЯЩИЕ ПУЛИ
-----------------------------------------------------------

function CircleBullets:spawnIncomingBullets(
    enemy,
    is_p2
)
    local arena =
        Game.battle.arena

    if not arena then
        return
    end

    local count =
        is_p2 and 5 or 4

    local speed =
        is_p2 and 8.0 or 6.5

    for i = 1, count do

        local side =
            math.random(1, 4)

        local x
        local y

        if side == 1 then

            x =
                arena.left - 30

            y =
                math.random(
                    math.floor(arena.top),
                    math.floor(arena.bottom)
                )

        elseif side == 2 then

            x =
                arena.right + 30

            y =
                math.random(
                    math.floor(arena.top),
                    math.floor(arena.bottom)
                )

        elseif side == 3 then

            x =
                math.random(
                    math.floor(arena.left),
                    math.floor(arena.right)
                )

            y =
                arena.top - 30

        else

            x =
                math.random(
                    math.floor(arena.left),
                    math.floor(arena.right)
                )

            y =
                arena.bottom + 30
        end

        self:spawnBullet(
            "knight_circle_bullet",
            x,
            y,
            self.circle_x,
            self.circle_y,
            speed,
            is_p2
        )
    end
end

-----------------------------------------------------------
-- ГРАНИЦА КРУГА
-----------------------------------------------------------

function CircleBullets:checkCircleBoundary()
    local soul =
        Game.battle.soul

    if not soul then
        return
    end

    local dx =
        soul.x - self.circle_x

    local dy =
        soul.y - self.circle_y

    local distance =
        math.sqrt(
            dx * dx +
            dy * dy
        )

    if distance >
       self.circle_radius then

        if self.boundary_damage_timer <= 0 then

            self.boundary_damage_timer =
                0.18

            Game.battle:hurt(
                self.boundary_damage,
                true,
                "ALL",
                false
            )
        end
    end
end

-----------------------------------------------------------
-- UPDATE
-----------------------------------------------------------

function CircleBullets:update()

    self.boundary_damage_timer =
        self.boundary_damage_timer - DT

    if self.boundary_damage_timer < 0 then
        self.boundary_damage_timer = 0
    end

    self:updateCircle()

    self:checkCircleBoundary()

    super.update(self)
end

-----------------------------------------------------------
-- КОНЕЦ
-----------------------------------------------------------

function CircleBullets:onEnd()

    for _, data in ipairs(
        self.circle_bullets
    ) do

        local bullet =
            data.obj

        if bullet and
           not bullet:isRemoved() then

            bullet:remove()
        end
    end

    self.circle_bullets = {}

    super.onEnd(self)
end

return CircleBullets