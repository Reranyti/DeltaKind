local OrangeSoul, super = Class(Soul)

function OrangeSoul:init(x, y)
    -- Обычная душа, только оранжевая.
    super.init(self, x, y, {1, 0.45, 0.05})

    -- На всякий случай принудительно задаём цвет.
    self:setColor(1, 0.45, 0.05)

    -- Dash.
    self.dashing = false
    self.dash_timer = 0

    -- Сам dash длится недолго.
    self.dash_duration = 0.25

    -- Небольшой cooldown между рывками.
    self.dash_cooldown = 0.65
    self.dash_cooldown_timer = 0

    -- Сколько пикселей проходит один dash.
    self.dash_distance = 90

    -- Последнее горизонтальное направление.
    self.facing = 1
end

function OrangeSoul:doMovement()
    -------------------------------------------------------
    -- COOLDOWN
    -------------------------------------------------------

    if self.dash_cooldown_timer > 0 then
        self.dash_cooldown_timer =
            self.dash_cooldown_timer - DT

        if self.dash_cooldown_timer < 0 then
            self.dash_cooldown_timer = 0
        end
    end

    -------------------------------------------------------
    -- ОПРЕДЕЛЯЕМ НАПРАВЛЕНИЕ
    -------------------------------------------------------

    if Input.down("left") then
        self.facing = -1
    elseif Input.down("right") then
        self.facing = 1
    end

    -------------------------------------------------------
    -- DASH
    -------------------------------------------------------

    if Input.pressed("f")
    and not self.dashing
    and self.dash_cooldown_timer <= 0 then

        self.dashing = true

        self.dash_timer =
            self.dash_duration

        self.dash_cooldown_timer =
            self.dash_cooldown

        Assets.playSound(
            "reflect",
            0.8,
            1.0
        )
    end

    -------------------------------------------------------
    -- ДВИЖЕНИЕ DASH
    -------------------------------------------------------

    if self.dashing then
        self.dash_timer =
            self.dash_timer - DT

        -- Сколько расстояния проходим за этот кадр.
        local move_amount =
            (self.dash_distance /
            self.dash_duration) * DT

        -- Soul:move принимает именно количество
        -- движения, а не скорость в пикселях/секунду.
        self:move(
            self.facing * move_amount,
            0
        )

        self.alpha = 0.5

        if self.dash_timer <= 0 then
            self.dash_timer = 0
            self.dashing = false
            self.alpha = 1
        end

        return
    end

    -------------------------------------------------------
    -- ОБЫЧНОЕ ДВИЖЕНИЕ
    --
    -- Никакой гравитации.
    -- Никакого платформинга.
    -- Просто обычная Soul.
    -------------------------------------------------------

    self.alpha = 1

    super.doMovement(self)
end

function OrangeSoul:update()
    super.update(self)
end

return OrangeSoul