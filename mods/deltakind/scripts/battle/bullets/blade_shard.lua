-----------------------------------------------------------
-- BLADE SHARD — осколок-«ёлочка» после взрыва звезды.
-- ОРИГИНАЛЬНЫЙ спрайт «Starchild» из спрайт-листа (стрелка), повёрнутый
-- остриём вверх, не вращается. Часть осколков серые полупрозрачные.
-----------------------------------------------------------

local BladeShard, super = Class(Bullet)

function BladeShard:init(x, y, angle, speed, damage, life, size, gray)
    local f = math.random(1, 3)
    super.init(self, x, y, "bullets/orig/starchild_" .. f)
    if self.sprite then self.sprite:stop() end
    self.angle = angle
    self.speed = speed
    self.life = life or 1.8
    self.t = 0
    self.gray = gray
    self.damage = damage or 40
    local s = (size or 12) / 32
    self:setOrigin(0.5, 0.5)
    self:setScale(s, s)
    self.rotation = -math.pi / 2   -- остриё вверх, не вращается

    self.can_graze = true
    self.destroy_on_hit = true
    self.remove_offscreen = true
    self.collider = CircleCollider(self, 0, 0, 7)
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
    local k = self.t / self.life
    local a = 1 - math.max(0, (k - 0.55) / 0.45)
    if self.sprite then
        if self.gray then self.sprite:setColor(0.7, 0.7, 0.7, a * 0.8)
        else self.sprite:setColor(1, 1, 1, a) end
    end
    super.update(self)
end

return BladeShard
