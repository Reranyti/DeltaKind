---@class KnightGridTP : Bullet
local KnightGridTP, super = Class(Bullet)

function KnightGridTP:init(x, y)
    super.init(self, x, y, "effects/spare/star")

    -- =====================================================
    -- НАСТРОЙКИ
    -- =====================================================

    self.damage = 30
    self.tp_amount = 10

    self.move_speed = 1.8

    self.remove_offscreen = false

    self.hit = false

    -- Случайное направление при появлении.
    self.direction = math.random() * math.pi * 2

    self.physics.speed = 0

    -- Визуал
    self:setColor(1, 0.85, 0.15)

    self.scale_x = 0.65
    self.scale_y = 0.65

    self.float_timer =
        math.random() * math.pi * 2
end

-- =========================================================
-- UPDATE
-- =========================================================

function KnightGridTP:update()

    self.float_timer =
        self.float_timer + DT

    -- Лёгкое вращение.
    self.rotation =
        self.float_timer * 2

    -- Лёгкая пульсация.
    local pulse =
        math.sin(
            self.float_timer * 4
        ) * 0.08

    self.scale_x =
        0.65 + pulse

    self.scale_y =
        0.65 + pulse

    -- =====================================================
    -- ПОСТОЯННОЕ ДВИЖЕНИЕ
    -- =====================================================

    self.x =
        self.x +
        math.cos(self.direction) *
        self.move_speed *
        DTMULT

    self.y =
        self.y +
        math.sin(self.direction) *
        self.move_speed *
        DTMULT

    -- =====================================================
    -- ОТСКОК ОТ ГРАНИЦ АРЕНЫ
    -- =====================================================

    local arena =
        Game.battle.arena

    if arena then

        local padding = 8

        if self.x <= arena.left + padding then
            self.x =
                arena.left + padding

            self.direction =
                math.pi -
                self.direction
        end

        if self.x >= arena.right - padding then
            self.x =
                arena.right - padding

            self.direction =
                math.pi -
                self.direction
        end

        if self.y <= arena.top + padding then
            self.y =
                arena.top + padding

            self.direction =
                -self.direction
        end

        if self.y >= arena.bottom - padding then
            self.y =
                arena.bottom - padding

            self.direction =
                -self.direction
        end
    end

    super.update(self)
end

-- =========================================================
-- СТОЛКНОВЕНИЕ
-- =========================================================

function KnightGridTP:onCollide(soul)

    if self.hit then
        return
    end

    self.hit = true

    -- +10 TP
    Game:giveTension(
        self.tp_amount
    )

    -- 30 урона
    super.onCollide(
        self,
        soul
    )

    -- Сообщение
    local battler = nil

    if Game.battle.party
       and #Game.battle.party > 0 then

        battler =
            Game.battle.party[1]
    end

    if battler then

        local message =
            DeltaStatusText(
                battler.x,
                battler.y -
                battler.height / 2 -
                16,
                "+10 TP",
                {1, 0.9, 0.05}
            )

        Game.battle:addChild(
            message
        )
    end

    self:remove()
end

return KnightGridTP