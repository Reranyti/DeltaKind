local KnightCircleBullet, super = Class(Bullet)

function KnightCircleBullet:init(
    x,
    y,
    target_x,
    target_y,
    speed,
    is_p2
)
    super.init(
        self,
        x,
        y,
        "bullets/smallbullet"
    )

    self.target_x = target_x
    self.target_y = target_y
    self.is_p2 = is_p2

    -------------------------------------------------------
    -- АНИМАЦИЯ ПОЯВЛЕНИЯ
    -------------------------------------------------------

    self:setScale(0, 0)

    self.spawn_timer = 0
    self.spawn_duration = 0.18

    -------------------------------------------------------
    -- УРОН
    -------------------------------------------------------

    self.damage = math.random(200, 300)

    -------------------------------------------------------
    -- НАПРАВЛЕНИЕ НА ЦЕЛЬ
    -------------------------------------------------------

    self.physics.direction =
        Utils.angle(
            x,
            y,
            target_x,
            target_y
        )

    self.physics.speed =
        speed or 7

    -------------------------------------------------------
    -- ПУЛЯ МОЖЕТ БЫТЬ СНАРУЖИ АРЕНЫ
    -------------------------------------------------------

    self.remove_offscreen = false

    -------------------------------------------------------
    -- СОСТОЯНИЕ ОТСКОКА
    -------------------------------------------------------

    self.has_entered_arena = false
    self.has_bounced = false

    -------------------------------------------------------
    -- ОПРЕДЕЛЯЕМ СТОРОНУ ПОЯВЛЕНИЯ
    -------------------------------------------------------

    local arena =
        Game.battle.arena

    self.spawn_side = nil

    if arena then

        if x < arena.left then

            self.spawn_side = "left"

        elseif x > arena.right then

            self.spawn_side = "right"
        end
    end

    -------------------------------------------------------
    -- СЛОЙ
    -------------------------------------------------------

    self:setLayer(
        BATTLE_LAYERS["above_arena"]
    )

    -------------------------------------------------------
    -- ЦВЕТ
    -------------------------------------------------------

    if is_p2 then

        self:setColor(
            1,
            0.8,
            0.15
        )

    else

        self:setColor(
            0.3,
            0.8,
            1
        )
    end
end

function KnightCircleBullet:update()

    local arena =
        Game.battle.arena

    -------------------------------------------------------
    -- АНИМАЦИЯ ПОЯВЛЕНИЯ
    -------------------------------------------------------

    self.spawn_timer =
        self.spawn_timer + DT

    local progress =
        math.min(
            self.spawn_timer /
            self.spawn_duration,
            1
        )

    self:setScale(
        progress,
        progress
    )

    -------------------------------------------------------
    -- ПУЛЯ СНАЧАЛА ДОЛЖНА РЕАЛЬНО ВОЙТИ В АРЕНУ
    -------------------------------------------------------

    if arena and not self.has_entered_arena then

        if self.spawn_side == "left" then

            if self.x >= arena.left then
                self.has_entered_arena = true
            end

        elseif self.spawn_side == "right" then

            if self.x <= arena.right then
                self.has_entered_arena = true
            end
        end
    end

    -------------------------------------------------------
    -- ОДИН ОТСКОК
    --
    -- До входа в арену этот блок НЕ РАБОТАЕТ.
    -------------------------------------------------------

    if arena
    and self.has_entered_arena
    and not self.has_bounced then

        if self.x <= arena.left then

            self.x =
                arena.left + 1

            self.physics.direction =
                math.pi -
                self.physics.direction

            self.has_bounced = true

        elseif self.x >= arena.right then

            self.x =
                arena.right - 1

            self.physics.direction =
                math.pi -
                self.physics.direction

            self.has_bounced = true

        elseif self.y <= arena.top then

            self.y =
                arena.top + 1

            self.physics.direction =
                -self.physics.direction

            self.has_bounced = true

        elseif self.y >= arena.bottom then

            self.y =
                arena.bottom - 1

            self.physics.direction =
                -self.physics.direction

            self.has_bounced = true
        end
    end

    -------------------------------------------------------
    -- ПОСЛЕ ОТСКОКА УЛЕТАЕМ
    -------------------------------------------------------

    if arena and self.has_bounced then

        if self.x < arena.left - 50
        or self.x > arena.right + 50
        or self.y < arena.top - 50
        or self.y > arena.bottom + 50 then

            self:remove()
            return
        end
    end

    super.update(self)
end

return KnightCircleBullet