-----------------------------------------------------------
-- BLADE BURST — большая залитая серая звезда-вспышка со «ступеньками»
-- (несколько вложенных контуров) и белым ромбом в центре.
-- Взрыв звёзд в атаке «Звёзды». Урона нет.
-----------------------------------------------------------

local BladeBurst, super = Class(Bullet)

local function star(r, rot, inner)
    local pts = {}
    for i = 0, 11 do
        local rad = (i % 2 == 0) and r or r * (inner or 0.45)
        local a = rot + i * math.pi / 6
        pts[#pts + 1] = math.cos(a) * rad
        pts[#pts + 1] = math.sin(a) * rad
    end
    return pts
end

function BladeBurst:init(x, y, scale, life)
    super.init(self, x, y)
    self.r = 30 * (scale or 2)
    self.life = life or 0.6
    self.t = 0
    self.rot = MathUtils.random(0, math.pi / 3)
    self.collider = nil
    self.can_graze = false
    self.remove_offscreen = false
    self:setScale(1, 1)
    self.layer = BATTLE_LAYERS["bullets"] - 1
end

function BladeBurst:update()
    self.t = self.t + DT
    if self.t >= self.life then self:remove() return end
    super.update(self)
end

function BladeBurst:draw()
    local k = self.t / self.life
    local fade = 1 - k * k
    local r = self.r * (0.5 + 0.75 * math.min(1, k * 2.2))
    -- ступеньки: тёмный внешний, светлый средний
    Draw.setColor(0.45, 0.45, 0.45, 0.55 * fade)
    love.graphics.polygon("fill", star(r * 1.18, self.rot, 0.5))
    Draw.setColor(0.8, 0.8, 0.8, 0.85 * fade)
    love.graphics.polygon("fill", star(r, self.rot, 0.45))
    Draw.setColor(0.95, 0.95, 0.95, 0.9 * fade)
    love.graphics.polygon("fill", star(r * 0.55, self.rot, 0.5))
    -- ромб в центре
    Draw.setColor(1, 1, 1, fade)
    love.graphics.polygon("fill", 0, -r * 0.16, r * 0.1, 0, 0, r * 0.16, -r * 0.1, 0)
    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return BladeBurst
