-----------------------------------------------------------
-- GREEN SOUL — режим щита.
--
-- Душа не двигается. Игрок держит направление (стрелки),
-- щит смотрит в эту сторону и блокирует снаряды, летящие
-- ИМЕННО с этой стороны (по позиции снаряда относительно
-- души в момент столкновения — работает для любых снарядов,
-- а не только с physics.direction). Снаряды с других сторон
-- бьют как обычно.
--
-- Блокировка происходит через override Soul:onCollide —
-- см. soul.lua: "By default, this function is responsible
-- for calling the bullet's collision check, Bullet:onCollide()".
-- Если снаряд заблокирован — просто не вызываем
-- bullet:onCollide(self), урона не будет.
-----------------------------------------------------------

local GreenSoul, super = Class(Soul)

function GreenSoul:init(x, y)
    super.init(self, x, y, {0.1, 0.9, 0.2})

    self:setColor(0.1, 0.9, 0.2)

    -- Направление щита: "up"/"down"/"left"/"right".
    self.shield_facing = "up"

    self.can_move = false
    self.allow_focus = false
end

function GreenSoul:doMovement()
    -- Зелёная душа не перемещается — только выбирает
    -- направление щита по удерживаемой стрелке.
    if Input.down("up") then
        self.shield_facing = "up"
    elseif Input.down("down") then
        self.shield_facing = "down"
    elseif Input.down("left") then
        self.shield_facing = "left"
    elseif Input.down("right") then
        self.shield_facing = "right"
    end

    self.moving_x = 0
    self.moving_y = 0
end

function GreenSoul:isBlocking(bullet)
    local dx = bullet.x - self.x
    local dy = bullet.y - self.y

    -- Определяем, с какой стороны прилетел снаряд, по тому,
    -- какая из осей "доминирует" в его положении относительно
    -- души — простая и надёжная проверка для любых снарядов.
    if math.abs(dx) > math.abs(dy) then
        if dx < 0 then
            return self.shield_facing == "left"
        else
            return self.shield_facing == "right"
        end
    else
        if dy < 0 then
            return self.shield_facing == "up"
        else
            return self.shield_facing == "down"
        end
    end
end

function GreenSoul:onCollide(bullet)
    if self:isBlocking(bullet) then
        Assets.playSound("reflect", 0.8, 1.0)

        if bullet.destroy_on_hit then
            bullet:remove()
        end

        return
    end

    super.onCollide(self, bullet)
end

function GreenSoul:draw()
    super.draw(self)

    -- Небольшая полоска-щит поверх души, показывающая
    -- текущее направление блока — чисто визуальная подсказка.
    local size = 4

    Draw.setColor(0.1, 0.9, 0.2, 0.8)

    if self.shield_facing == "up" then
        love.graphics.rectangle("fill", -self.width / 2, -self.height / 2 - size, self.width, size)
    elseif self.shield_facing == "down" then
        love.graphics.rectangle("fill", -self.width / 2, self.height / 2, self.width, size)
    elseif self.shield_facing == "left" then
        love.graphics.rectangle("fill", -self.width / 2 - size, -self.height / 2, size, self.height)
    elseif self.shield_facing == "right" then
        love.graphics.rectangle("fill", self.width / 2, -self.height / 2, size, self.height)
    end
end

return GreenSoul
