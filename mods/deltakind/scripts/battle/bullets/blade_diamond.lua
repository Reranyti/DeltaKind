-----------------------------------------------------------
-- BLADE DIAMOND — ромб-снаряд атаки «Разрез поля».
-- Белый контур, чёрная заливка, летит по прямой с заданной
-- скоростью (быстрый или медленный). Рисуется процедурно.
-----------------------------------------------------------

local BladeDiamond, super = Class(Bullet)

function BladeDiamond:init(x, y, angle, speed, damage, fast)
    super.init(self, x, y)

    self.angle = angle
    self.speed = speed
    self.fast = fast
    self.damage = damage or 100
    self.can_graze = true
    self.destroy_on_hit = true
    self.remove_offscreen = true
    self:setScale(1, 1)

    self.collider = CircleCollider(self, 0, 0, 6)
    self.physics.direction = angle
    self.physics.speed = speed * 1.0
end

function BladeDiamond:draw()
    local r = 9
    love.graphics.push()
    love.graphics.rotate(self.angle)
    local pts = { r + 3, 0, 0, r * 0.7, -r, 0, 0, -r * 0.7 }
    Draw.setColor(0, 0, 0, 1)
    love.graphics.polygon("fill", pts)
    if self.fast then
        Draw.setColor(1, 0.35, 0.35, 1)
    else
        Draw.setColor(1, 1, 1, 1)
    end
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", pts)
    love.graphics.pop()
    love.graphics.setLineWidth(1)
    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return BladeDiamond
