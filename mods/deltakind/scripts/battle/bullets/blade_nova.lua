-----------------------------------------------------------
-- BLADE NOVA — звезда атаки «Звёзды» (оригинал, фаза 1).
--
-- Механика по раскадровке оригинала:
--   * рождается мелкой у кончика меча и медленно (~110 px/с) идёт налево
--     веером (угол внутри конуса); растёт по мере удаления; не
--     останавливается в арене и может уйти за левый край;
--   * большие звёзды получают горизонтальную «строчную» заливку;
--   * стадия "red" (общая для всех звёзд волны): замирает, краснеет,
--     из неё идут мягкие лучи света;
--   * стадия "boom": все звёзды взрываются: серая вспышка + осколки.
-- Опасна только центральная точка звезды.
-----------------------------------------------------------

local BladeNova, super = Class(Bullet)

local SPEED = 110       -- px/с
local GROW_DIST = 300   -- расстояние, на котором звезда достигает полного размера

function BladeNova:init(x, y, angle, damage, max_scale)
    super.init(self, x, y, "bullets/knight_bullet_star_0")
    if self.sprite then self.sprite:stop() end
    self.sx0, self.sy0 = x, y
    self.angle = angle
    self.speed = SPEED * MathUtils.random(0.85, 1.2)
    self.damage = damage or 40
    self.max_scale = max_scale or 1.2
    self.t = 0
    self.red_t = 0
    self.dist = 0
    self.base_angle = MathUtils.random(0, math.pi * 2)

    -- лучи для красной стадии (короткие мягкие + иногда вертикальный)
    self.rays = {}
    for i = 1, 6 do
        self.rays[i] = {
            a = self.base_angle + i * (math.pi * 2 / 6) + MathUtils.random(-0.3, 0.3),
            len = MathUtils.random(40, 80),
        }
    end
    if math.random() < 0.5 then
        self.rays[#self.rays + 1] = { a = -math.pi / 2, len = 130 }
    end

    self.can_graze = true
    self.destroy_on_hit = true
    self.remove_offscreen = false
    self:setOrigin(0.5, 0.5)
    self:setScale(0.15, 0.15)
    self.collider = CircleCollider(self, 0, 0, 5)
end

function BladeNova:getStage()
    return (self.wave and self.wave.stage) or "fly"
end

function BladeNova:explode()
    if self.wave then
        self.wave:spawnBullet("blade_burst", self.x, self.y, math.max(0.8, self.scale_x) * 1.15, 0.6)
        local n = 5
        for i = 0, n - 1 do
            local ang = self.base_angle + i * (math.pi * 2 / n) + MathUtils.random(-0.25, 0.25)
            self.wave:spawnBullet("blade_shard", self.x, self.y, ang, MathUtils.random(1.4, 4.5),
                math.ceil(self.damage), MathUtils.random(1.6, 2.2), MathUtils.random(11, 17), math.random() < 0.12)
        end
    end
    self:remove()
end

function BladeNova:update()
    self.t = self.t + DT
    local stage = self:getStage()

    if stage == "fly" then
        self.dist = self.dist + self.speed * DT
        self.x = self.sx0 + math.cos(self.angle) * self.dist
        self.y = self.sy0 + math.sin(self.angle) * self.dist
        local e = math.min(1, self.dist / GROW_DIST)
        local s = 0.15 + (self.max_scale - 0.15) * e
        self:setScale(s, s)
        if self.sprite then self.sprite.rotation = self.t * 1.0 end
        if self.x < -70 then self:remove() return end
    elseif stage == "red" then
        self.red_t = self.red_t + DT
        if self.sprite then
            self.sprite:setColor(0.75, 0.2, 0.2, 0.8)
            self.sprite.rotation = self.sprite.rotation + DT * 0.5
        end
    else
        self:explode()
        return
    end
    super.update(self)
end

local function ray(a, len, alpha)
    local w = 0.07
    Draw.setColor(1, 1, 1, alpha)
    love.graphics.polygon("fill", 0, 0,
        math.cos(a - w) * len * 0.35, math.sin(a - w) * len * 0.35,
        math.cos(a) * len, math.sin(a) * len,
        math.cos(a + w) * len * 0.35, math.sin(a + w) * len * 0.35)
end

function BladeNova:draw()
    local sx = math.max(0.01, self.scale_x)
    love.graphics.push()
    love.graphics.scale(1 / sx, 1 / sx)

    if self:getStage() == "red" then
        local k = math.min(1, self.red_t / 0.9)
        for _, r in ipairs(self.rays) do
            ray(r.a, r.len * (0.4 + 0.6 * k), 0.06 + 0.17 * k)
        end
    end
    -- «строчная» заливка у больших звёзд в полёте
    if self:getStage() == "fly" and sx > 0.85 then
        local R = 30 * sx
        Draw.setColor(1, 1, 1, 0.75)
        love.graphics.setLineWidth(1)
        for y = -R * 0.8, R * 0.8, 5 do
            local half = R * 0.75 * (1 - math.abs(y) / (R * 0.95))
            love.graphics.line(-half, y, half, y)
        end
    end
    love.graphics.pop()
    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return BladeNova
