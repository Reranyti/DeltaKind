-----------------------------------------------------------
-- BLUE SOUL — режим прыжка/гравитации.
--
-- Управление: влево/вправо — обычное движение, вверх —
-- прыжок (переменная высота: чем дольше держишь, тем
-- выше, пока не отпустишь или не достигнута макс. высота).
-- Гравитация тянет вниз, "пол" — нижняя граница арены
-- (arena.bottom), т.к. у Arena нет физической коллизии
-- (проверено — ни Solid, ни стен у арены не создаётся).
--
-- Структура и стиль — как в уже существующей OrangeSoul.lua
-- этого же проекта: override doMovement(), self:move(dx, dy)
-- принимает КОЛИЧЕСТВО движения (не скорость).
-----------------------------------------------------------

local BlueSoul, super = Class(Soul)

function BlueSoul:init(x, y)
    super.init(self, x, y, {0.1, 0.4, 1})

    self:setColor(0.1, 0.4, 1)

    self.velocity_y = 0
    self.gravity = 0.35
    self.jump_power = -7.5

    -- Гравитация слабее, пока держишь "вверх" во время
    -- подъёма — даёт переменную высоту прыжка.
    self.rising_gravity = 0.16

    self.grounded = false

    -- Разрешаем полноценно замедляться фокусом только
    -- по горизонтали (оригинал Undertale ведёт себя так же
    -- для синего режима).
    self.allow_focus = true
end

function BlueSoul:doMovement()
    local arena = Game.battle.arena

    -------------------------------------------------------
    -- ГОРИЗОНТАЛЬ — как у обычной души
    -------------------------------------------------------

    local speed = self.speed

    if self.allow_focus and Input.down("cancel") then
        speed = speed / 2
    end

    local move_x = 0
    if Input.down("left") then move_x = move_x - 1 end
    if Input.down("right") then move_x = move_x + 1 end

    self.moving_x = move_x
    self.moving_y = 0

    if move_x ~= 0 then
        self:move(move_x * speed * DTMULT, 0)
    end

    -------------------------------------------------------
    -- ГРАВИТАЦИЯ / ПРЫЖОК
    -------------------------------------------------------

    local rising = self.velocity_y < 0

    local g =
        (rising and Input.down("up"))
        and self.rising_gravity
        or self.gravity

    self.velocity_y = self.velocity_y + g * DTMULT

    if self.grounded and Input.pressed("up") then
        self.velocity_y = self.jump_power
        self.grounded = false
        Assets.playSound("ui_move")
    end

    local exact_x, exact_y = self:getExactPosition(self.x, self.y)

    local next_y = exact_y + self.velocity_y * DTMULT

    if arena and next_y >= arena.bottom - self.height / 2 then
        next_y = arena.bottom - self.height / 2
        self.velocity_y = 0
        self.grounded = true
    else
        self.grounded = false
    end

    if arena and next_y <= arena.top + self.height / 2 then
        next_y = arena.top + self.height / 2
        self.velocity_y = 0
    end

    self:setExactPosition(exact_x, next_y)
end

return BlueSoul
