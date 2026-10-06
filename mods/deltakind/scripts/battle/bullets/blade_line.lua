-----------------------------------------------------------
-- BLADE LINE — горизонтальная линия через весь экран.
--   dashed (по умолчанию): тонкая пунктирная белая линия-прицел;
--   solid + thick: толстая белая вспышка-полоса (конец ветра).
-- Урона нет.
-----------------------------------------------------------

local BladeLine, super = Class(Bullet)

function BladeLine:init(y, life, thick, solid)
    super.init(self, 0, y)
    self.life = life or 0.6
    self.thick = thick or 1
    self.solid = solid
    self.t = 0
    self.collider = nil
    self.can_graze = false
    self.remove_offscreen = false
    self:setScale(1, 1)
end

function BladeLine:update()
    self.t = self.t + DT
    if self.t >= self.life then self:remove() return end
    super.update(self)
end

function BladeLine:draw()
    local k = self.t / self.life
    love.graphics.setLineWidth(self.thick)
    if self.solid then
        Draw.setColor(1, 1, 1, 1 - k * k)
        love.graphics.line(0, 0, SCREEN_WIDTH, 0)
    else
        Draw.setColor(1, 1, 1, 0.85)
        local x = (self.t * 40) % 30
        while x < SCREEN_WIDTH do
            local seg = 52 + (math.floor(x) * 7 % 40)
            love.graphics.line(x, 0, math.min(SCREEN_WIDTH, x + seg), 0)
            x = x + seg + 22
        end
    end
    love.graphics.setLineWidth(1)
    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return BladeLine
