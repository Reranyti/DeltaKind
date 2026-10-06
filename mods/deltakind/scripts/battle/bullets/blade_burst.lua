-----------------------------------------------------------
-- BLADE BURST — взрыв звезды в атаке «Звёзды».
-- ОРИГИНАЛЬНЫЙ спрайт: залитая серая звезда (кадр _f2 группы звёзд),
-- в два слоя разного размера («ступеньки»), растёт и гаснет. Урона нет.
-----------------------------------------------------------

local BladeBurst, super = Class(Bullet)

function BladeBurst:init(x, y, scale, life)
    local g = math.random(0, 3)
    super.init(self, x, y, "bullets/orig/star_g" .. g .. "_f2")
    if self.sprite then self.sprite:stop() end
    self.base = scale or 1
    self.life = life or 0.6
    self.t = 0
    self.collider = nil
    self.can_graze = false
    self.remove_offscreen = false
    self:setOrigin(0.5, 0.5)
    self:setScale(self.base * 0.6, self.base * 0.6)
    self.layer = BATTLE_LAYERS["bullets"] - 1
    self.rot0 = math.random() * math.pi / 3
    self.tex = Assets.getTexture("bullets/orig/star_g" .. g .. "_f2")
end

function BladeBurst:update()
    self.t = self.t + DT
    if self.t >= self.life then self:remove() return end
    local k = self.t / self.life
    local s = self.base * (0.6 + 0.55 * math.min(1, k * 2.2))
    self:setScale(s, s)
    self.rotation = self.rot0
    local white = math.max(0, 1 - self.t / 0.1)   -- белая вспышка первые 0.1 с
    if self.sprite then self.sprite:setColor(0.9 + 0.1 * white, 0.9 + 0.1 * white, 0.9 + 0.1 * white, 0.9 * (1 - k * k) + 0.1 * white) end
    super.update(self)
end

function BladeBurst:draw()
    -- внешний слой побольше и темнее («ступенька»)
    if self.tex then
        local k = self.t / self.life
        local w, h = self.tex:getWidth(), self.tex:getHeight()
        Draw.setColor(0.5, 0.5, 0.5, 0.55 * (1 - k * k))
        Draw.draw(self.tex, 0, 0, 0, 1.22, 1.22, w / 2, h / 2)
        Draw.setColor(1, 1, 1, 1)
    end
    super.draw(self)
end

return BladeBurst
