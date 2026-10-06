-----------------------------------------------------------
-- BLADE CONE — конус ветра из кончика меча Рыцаря (атака «Звёзды»).
-- Вспыхивает бело-розовым в начале и в конце, между вспышками —
-- полупрозрачный фиолетовый с розовыми полосами вдоль. Урона нет.
-----------------------------------------------------------

local BladeCone, super = Class(Bullet)

local FLASH = 0.16

function BladeCone:init(x, y, angle, length, spread, life)
    super.init(self, x, y)
    self.angle, self.length, self.spread, self.life = angle, length, spread, life or 3.5
    self.t = 0
    self.collider = nil
    self.can_graze = false
    self.remove_offscreen = false
    self:setScale(1, 1)
    self.layer = BATTLE_LAYERS["bullets"] - 5
    self.streaks = {}
    for i = 1, 5 do
        self.streaks[i] = {
            y = MathUtils.random(-0.9, 0.9) * math.sin(spread) * length * 0.55,
            len = MathUtils.random(0.2, 0.5) * length,
            speed = MathUtils.random(0.5, 1.2),
            off = MathUtils.random(0, 1),
        }
    end
end

function BladeCone:update()
    self.t = self.t + DT
    if self.t >= self.life then self:remove() return end
    super.update(self)
end

function BladeCone:draw()
    local l = self.length
    local sp = self.spread
    local flash = (self.t < FLASH) or (self.t > self.life - FLASH * 1.4)

    local function tri()
        love.graphics.polygon("fill", 0, 0,
            math.cos(self.angle - sp) * l, math.sin(self.angle - sp) * l,
            math.cos(self.angle + sp) * l, math.sin(self.angle + sp) * l)
    end

    if flash then
        Draw.setColor(1, 0.85, 1, 0.8)
        tri()
    else
        local k = math.min(1, (self.t - FLASH) / 0.35)
        Draw.setColor(0.38, 0.08, 0.52, 0.30 + 0.30 * k)
        tri()
        Draw.setColor(1, 0.3, 0.8, 0.75)
        love.graphics.setLineWidth(1)
        for _, s in ipairs(self.streaks) do
            local x2 = -(((self.t * s.speed + s.off) % 1) * l)
            love.graphics.line(x2, s.y, x2 - s.len, s.y)
        end
    end
    love.graphics.setLineWidth(1)
    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return BladeCone
