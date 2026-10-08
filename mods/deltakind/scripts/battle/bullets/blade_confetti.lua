-----------------------------------------------------------
-- BLADE CONFETTI — белые осколки-«звёздочки» (спрайты starchild из листа),
-- разлетаются по всему экрану в конце «Рёва». Только визуал, урона нет.
-----------------------------------------------------------

local BladeConfetti, super = Class(Bullet)

function BladeConfetti:init(x, y, angle, speed, life)
    local f = math.random(1, 3)
    super.init(self, x, y, "bullets/orig/starchild_" .. f)
    if self.sprite then self.sprite:stop() end
    self.life = life or 1.6
    self.t = 0
    self.collider = nil
    self.can_graze = false
    self.remove_offscreen = false
    self:setOrigin(0.5, 0.5)
    local s = MathUtils.random(0.5, 1.0)
    self:setScale(s, s)
    self.rotation = MathUtils.random(0, math.pi * 2)
    self.spin = MathUtils.random(-4, 4)
    self.physics.direction = angle
    self.physics.speed = speed
    self.layer = BATTLE_LAYERS["bullets"] + 5
end

function BladeConfetti:update()
    self.t = self.t + DT
    if self.t >= self.life then self:remove() return end
    self.rotation = self.rotation + self.spin * DT
    self.physics.speed = self.physics.speed * (1 - 0.8 * DT)
    if self.sprite then self.sprite:setColor(1, 1, 1, 1 - math.max(0, (self.t / self.life - 0.6) / 0.4)) end
    super.update(self)
end

return BladeConfetti
