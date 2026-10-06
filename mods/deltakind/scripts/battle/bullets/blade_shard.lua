-----------------------------------------------------------
-- BLADE SHARD — белый треугольный осколок (взрыв звезды).
-- Летит по прямой, затухает за life секунд. Рисуется процедурно.
-----------------------------------------------------------

local BladeShard, super = Class(Bullet)

function BladeShard:init(x, y, angle, speed, damage, life, size)
    super.init(self, x, y)

    self.angle = angle
    self.speed = speed
    self.life = life or 1.2
    self.t = 0
    self.size = size or 7
    self.damage = damage or 40

    self.can_graze = true
    self.destroy_on_hit = true
    self.remove_offscreen = true
    self:setScale(1, 1)
    self.collider = CircleCollider(self, 0, 0, self.size * 0.5)
    self.physics.direction = angle
    self.physics.speed = speed
end

function BladeShard:update()
    self.t = self.t + DT
    if self.t >= self.life then
        self:remove()
        return
    end
    -- в конце жизни осколок не наносит урон
    if self.t > self.life * 0.8 then self.collider = nil end
    super.update(self)
end

function BladeShard:draw()
    local a = 1 - math.max(0, (self.t - self.life * 0.6) / (self.life * 0.4))
    local s = self.size
    love.graphics.push()
    love.graphics.rotate(self.angle)
    Draw.setColor(1, 1, 1, a)
    love.graphics.polygon("fill", s * 1.4, 0, -s * 0.7, s * 0.8, -s * 0.7, -s * 0.8)
    love.graphics.pop()
    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return BladeShard
