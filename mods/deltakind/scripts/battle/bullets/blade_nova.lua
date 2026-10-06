-----------------------------------------------------------
-- BLADE NOVA — звезда атаки «Звёзды» (фаза 1 оригинала).
--
-- 1. вылетает из ладони Рыцаря и растёт по пути к точке в арене;
-- 2. замирает и краснеет, из неё идут тонкие лучи (куда полетят осколки);
-- 3. взрывается: 6 белых осколков (3 коротких и медленных, 3 длинных и быстрых).
-- Опасна только центральная точка звезды. Спрайт: knight_bullet_star_0.
-----------------------------------------------------------

local BladeNova, super = Class(Bullet)

local FLY = 1.2
local HOLD = 0.7

function BladeNova:init(px, py, tx, ty, damage)
    super.init(self, px, py, "bullets/knight_bullet_star_0")
    if self.sprite then self.sprite:stop() end
    self.px, self.py, self.tx, self.ty = px, py, tx, ty
    self.damage = damage or 40
    self.t = 0
    self.state = "fly"
    self.base_angle = MathUtils.random(0, math.pi * 2)

    self.can_graze = true
    self.destroy_on_hit = true
    self.remove_offscreen = false
    self:setOrigin(0.5, 0.5)
    self:setScale(0.25, 0.25)
    self.collider = CircleCollider(self, 0, 0, 5)
end

function BladeNova:update()
    self.t = self.t + DT
    if self.state == "fly" then
        local k = math.min(1, self.t / FLY)
        local e = 1 - (1 - k) * (1 - k)
        self.x = self.px + (self.tx - self.px) * e
        self.y = self.py + (self.ty - self.py) * e
        local s = 0.25 + 0.75 * e
        self:setScale(s, s)
        if self.sprite then self.sprite.rotation = self.t * 2 end
        if k >= 1 then self.state = "hold"; self.t = 0 end
    elseif self.state == "hold" then
        if self.sprite then
            self.sprite:setColor(1, 0.25, 0.25, 1)
            self.sprite.rotation = self.sprite.rotation + DT * 3
        end
        if self.t >= HOLD then
            for i = 0, 5 do
                local ang = self.base_angle + i * math.pi / 3
                local long = (i % 2 == 0)
                if self.wave then
                    self.wave:spawnBullet("blade_shard", self.x, self.y, ang,
                        long and 5.0 or 2.6, math.ceil(self.damage), long and 1.4 or 0.9, long and 8 or 6)
                end
            end
            self:remove()
            return
        end
    end
    super.update(self)
end

function BladeNova:draw()
    super.draw(self)
    if self.state == "hold" then
        -- тонкие лучи-подсказки в 6 направлений
        local a = 0.35 + 0.4 * (self.t / HOLD)
        Draw.setColor(1, 0.3, 0.3, a)
        love.graphics.setLineWidth(1)
        for i = 0, 5 do
            local ang = self.base_angle + i * math.pi / 3
            love.graphics.line(0, 0, math.cos(ang) * 150, math.sin(ang) * 150)
        end
        Draw.setColor(1, 1, 1, 1)
    end
end

return BladeNova
