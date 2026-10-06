-----------------------------------------------------------
-- BLADE CONE — полупрозрачный фиолетовый конус из ладони Рыцаря
-- (декорация атаки «Звёзды», урона нет).
-----------------------------------------------------------

local BladeCone, super = Class(Bullet)

function BladeCone:init(x, y, angle, length, spread, life)
    super.init(self, x, y)
    self.angle, self.length, self.spread, self.life = angle, length, spread, life or 3.5
    self.t = 0
    self.collider = nil
    self.can_graze = false
    self.remove_offscreen = false
    self:setScale(1, 1)
    self.layer = BATTLE_LAYERS["bullets"] - 5
end

function BladeCone:update()
    self.t = self.t + DT
    if self.t >= self.life then self:remove() return end
    super.update(self)
end

function BladeCone:draw()
    local grow = math.min(1, self.t / 0.35)
    local fade = math.min(1, (self.life - self.t) / 0.5)
    local a = 0.38 * fade
    local l = self.length * grow
    local sp = self.spread
    Draw.setColor(0.6, 0.25, 0.85, a)
    love.graphics.polygon("fill", 0, 0,
        math.cos(self.angle - sp) * l, math.sin(self.angle - sp) * l,
        math.cos(self.angle + sp) * l, math.sin(self.angle + sp) * l)
    Draw.setColor(0.8, 0.5, 1, a * 1.3)
    love.graphics.setLineWidth(1)
    love.graphics.line(0, 0, math.cos(self.angle - sp) * l, math.sin(self.angle - sp) * l)
    love.graphics.line(0, 0, math.cos(self.angle + sp) * l, math.sin(self.angle + sp) * l)
    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return BladeCone
