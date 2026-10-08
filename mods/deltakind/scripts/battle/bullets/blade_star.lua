-----------------------------------------------------------
-- BLADE STAR — звезда финала «Рёв» (оригинальный спрайт из листа).
-- Вылетает из Рыцаря и уходит наружу по спирали, нарастая и размываясь
-- (шлейф из послеобразов). Опасна только центральная точка.
-- red = true — красная звезда с белой сердцевиной (ярко и опасно в конце).
-----------------------------------------------------------

local BladeStar, super = Class(Bullet)

local SPR = 64
local TRAIL = 5

function BladeStar:init(cx, cy, angle, speed, damage, spin, red)
    local g = math.random(0, 3)
    super.init(self, cx, cy, "bullets/orig/star_g" .. g .. "_f0")
    if self.sprite then self.sprite:stop() end
    self.group = g
    self.cx, self.cy = cx, cy
    self.a = angle
    self.speed = speed or 130
    self.spin = spin or 0.9
    self.damage = damage or 40
    self.red = red
    self.t = 0
    self.r = 14
    self.hist = {}
    self.base_rot = math.random() * math.pi

    self.can_graze = true
    self.destroy_on_hit = true
    self.remove_offscreen = false
    self:setOrigin(0.5, 0.5)
    self:setScale(0.2, 0.2)
    self.collider = CircleCollider(self, 0, 0, 7)
end

function BladeStar:update()
    self.t = self.t + DT
    self.r = self.r + (self.speed + self.t * 60) * DT
    self.a = self.a + self.spin * DT * (1 + self.r / 400)
    self.x = self.cx + math.cos(self.a) * self.r
    self.y = self.cy + math.sin(self.a) * self.r
    local s = math.min(0.85, 0.2 + self.r / 330)
    self:setScale(s, s)
    if self.sprite then self.sprite.rotation = self.base_rot + self.t * 1.4 end

    table.insert(self.hist, 1, { x = self.x, y = self.y, s = s })
    if #self.hist > TRAIL then table.remove(self.hist) end

    if self.r > 520 then self:remove() return end
    super.update(self)
end

function BladeStar:draw()
    local sx = math.max(0.01, self.scale_x)
    love.graphics.push()
    love.graphics.scale(1 / sx, 1 / sx)
    local tex = Assets.getTexture("bullets/orig/star_g" .. self.group .. "_f0")
    if tex then
        for i = #self.hist, 2, -1 do          -- шлейф: размытие движением
            local h = self.hist[i]
            Draw.setColor(self.red and 1 or 0.85, self.red and 0.3 or 0.85, self.red and 0.3 or 1, 0.32 * (1 - i / (TRAIL + 1)))
            Draw.draw(tex, h.x - self.x, h.y - self.y, self.base_rot + self.t * 1.4, h.s, h.s, SPR / 2, SPR / 2)
        end
    end
    if self.red then
        local rs = Assets.getTexture("bullets/orig/red_star")
        if rs then
            Draw.setColor(1, 0.15, 0.15, 1)
            Draw.draw(rs, 0, 0, self.base_rot + self.t * 1.4, self.scale_x, self.scale_x, SPR / 2, SPR / 2)
        end
        self.sprite:setColor(1, 1, 1, 0)
    elseif self.sprite then
        self.sprite:setColor(1, 1, 1, 0.95)
    end
    love.graphics.pop()
    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return BladeStar
