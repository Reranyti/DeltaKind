-----------------------------------------------------------
-- BLADE SHARD — белый осколок-«ёлочка» (взрыв звёзд).
-- Форма как в оригинале: остриё вверх, два яруса и короткий ствол;
-- часть осколков полупрозрачные серые. Летит и затухает.
-----------------------------------------------------------

local BladeShard, super = Class(Bullet)

-- Ёлочка (остриё к направлению движения, вдоль +x), единичный размер
local TREE = {
    1.0, 0.0,
    0.30, 0.55,   0.62, 0.55,
    -0.15, 1.0,   0.18, 1.0,
    -0.55, 1.25,  -0.55, 0.0,
}

function BladeShard:init(x, y, angle, speed, damage, life, size, gray)
    super.init(self, x, y)

    self.angle = angle
    self.speed = speed
    self.life = life or 1.8
    self.t = 0
    self.size = size or 8
    self.gray = gray
    self.damage = damage or 40
    self.spin = MathUtils.random(-2, 2)

    self.can_graze = true
    self.destroy_on_hit = true
    self.remove_offscreen = true
    self:setScale(1, 1)
    self.collider = CircleCollider(self, 0, 0, self.size * 0.45)
    self.physics.direction = angle
    self.physics.speed = speed
end

function BladeShard:update()
    self.t = self.t + DT
    if self.t >= self.life then
        self:remove()
        return
    end
    self.physics.speed = self.speed * (1 - 0.55 * self.t / self.life)
    if self.t > self.life * 0.75 then self.collider = nil end
    super.update(self)
end

function BladeShard:draw()
    local k = self.t / self.life
    local a = 1 - math.max(0, (k - 0.55) / 0.45)
    local s = self.size
    love.graphics.push()
    love.graphics.rotate(-math.pi / 2)
    local p = {}
    for i = 1, #TREE, 2 do
        p[#p + 1] = TREE[i] * s
        p[#p + 1] = TREE[i + 1] * s * 0.8
    end
    if self.gray then
        Draw.setColor(0.7, 0.7, 0.7, a * 0.8)
    else
        Draw.setColor(1, 1, 1, a)
    end
    love.graphics.polygon("fill", p)
    love.graphics.pop()
    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return BladeShard
