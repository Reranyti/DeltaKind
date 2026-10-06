-----------------------------------------------------------
-- BLADE STAR — звезда финала «Рёв».
--
-- Жизнь звезды вокруг центра (позиции Рыцаря):
--   1. летит к центру;
--   2. расходится по спирали наружу;
--   3. возвращается к центру (по тому же вращению);
--   4. взрывается шестью ромбами по шести направлениям.
-- Опасна только центральная точка (маленький круг), как в оригинале.
-- Спрайт: assets/sprites/bullets/knight_bullet_star_0.png
-----------------------------------------------------------

local BladeStar, super = Class(Bullet)

local T_IN, T_OUT, T_BACK = 1.0, 1.5, 1.1
local R_MAX = 250
local SPIN = 2.3 -- рад/с

function BladeStar:init(cx, cy, angle, radius, damage)
    super.init(self, cx, cy, "bullets/knight_bullet_star_0")
    if self.sprite then self.sprite:stop() end

    self.cx, self.cy = cx, cy
    self.a = angle
    self.r0 = radius
    self.damage = damage or 40
    self.t = 0

    self.can_graze = true
    self.destroy_on_hit = true
    self.remove_offscreen = false
    self:setScale(1, 1)
    self:setOrigin(0.5, 0.5)
    self.collider = CircleCollider(self, 0, 0, 6)
end

function BladeStar:place(r)
    self.x = self.cx + math.cos(self.a) * r
    self.y = self.cy + math.sin(self.a) * r
end

function BladeStar:update()
    self.t = self.t + DT
    self.a = self.a + SPIN * DT
    if self.sprite then self.sprite.rotation = self.t * 3 end

    local t = self.t
    if t < T_IN then
        local k = t / T_IN
        self:place(self.r0 + (24 - self.r0) * k * k)
    elseif t < T_IN + T_OUT then
        local k = (t - T_IN) / T_OUT
        self:place(24 + (R_MAX - 24) * math.sin(k * math.pi / 2))
    elseif t < T_IN + T_OUT + T_BACK then
        local k = (t - T_IN - T_OUT) / T_BACK
        self:place(R_MAX + (60 - R_MAX) * k * k)
    else
        -- взрыв: шесть ромбов в шесть сторон
        for i = 0, 5 do
            local ang = self.a + i * math.pi / 3
            if self.wave then
                self.wave:spawnBullet("blade_diamond", self.x, self.y, ang, 3.0, math.ceil(self.damage), false)
            end
        end
        self:remove()
        return
    end
    super.update(self)
end

return BladeStar
