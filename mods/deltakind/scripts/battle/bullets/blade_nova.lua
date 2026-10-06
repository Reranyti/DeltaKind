-----------------------------------------------------------
-- BLADE NOVA — звезда атаки «Звёзды» (оригинал, фаза 1).
--
-- Графика: ОРИГИНАЛЬНЫЕ спрайты звёзд из спрайт-листа
--   bullets/orig/star_g{0..3}_f{0,1}  (контур; кадры f0/f1 мерцают).
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

local SPEED = 148       -- px/с (оригинал: ~145)
local GROW_DIST = 190   -- расстояние, на котором звезда достигает полного размера
local SPR = 64          -- размер исходного спрайта

function BladeNova:init(x, y, angle, damage, max_scale)
    local g = math.random(0, 3)
    super.init(self, x, y, "bullets/orig/star_g" .. g .. "_f1")
    if self.sprite then self.sprite:stop() end
    self.group = g
    self.sx0, self.sy0 = x, y
    self.angle = angle
    self.speed = SPEED * MathUtils.random(0.85, 1.2)
    self.damage = damage or 40
    -- масштаб относительно 64-px спрайта: у оригинала звёзды ~ от 9 до ~45 px
    self.max_scale = max_scale or 0.6
    self.t = 0
    self.red_t = 0
    self.dist = 0
    self.frame = 1
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
    self:setScale(0.14, 0.14)
    -- опасна только центральная точка звезды (маленький круг в спрайтовых px)
    self.collider = CircleCollider(self, 0, 0, 9)
end

function BladeNova:getStage()
    return (self.wave and self.wave.stage) or "fly"
end

function BladeNova:explode()
    if self.wave then
        local s = math.max(0.5, self.scale_x)
        self.wave:spawnBullet("blade_burst", self.x, self.y, s * 1.7, 0.6)
        local n = 5
        for i = 0, n - 1 do
            local ang = self.base_angle + i * (math.pi * 2 / n) + MathUtils.random(-0.25, 0.25)
            self.wave:spawnBullet("blade_shard", self.x, self.y, ang, MathUtils.random(1.4, 4.5),
                math.ceil(self.damage), MathUtils.random(1.6, 2.2), MathUtils.random(15, 22), math.random() < 0.12)
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
        local s = 0.14 + (self.max_scale - 0.14) * e
        self:setScale(s, s)
        -- мерцание кадров контура
        local f = (math.floor(self.t / 0.12) % 2 == 0) and 0 or 1
        if f ~= self.frame - 1 then
            self.frame = f + 1
            if self.sprite then self.sprite:setTexture("bullets/orig/star_g" .. self.group .. "_f" .. f) end
        end
        if self.x < -70 then self:remove() return end
    elseif stage == "red" then
        self.red_t = self.red_t + DT
        if self.sprite then self.sprite:setColor(0.78, 0.2, 0.2, 0.85) end
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
    -- координаты ниже: в «экранных» пикселях (компенсируем масштаб спрайта)
    local sx = math.max(0.01, self.scale_x)
    love.graphics.push()
    love.graphics.scale(1 / sx, 1 / sx)

    if self:getStage() == "red" then
        local k = math.min(1, self.red_t / 0.9)
        for _, r in ipairs(self.rays) do
            ray(r.a, r.len * (0.4 + 0.6 * k), 0.06 + 0.17 * k)
        end
    end
    -- «строчная» заливка у больших звёзд в полёте (как у оригинала)
    if self:getStage() == "fly" and sx > 0.45 then
        local R = (SPR / 2) * sx * 0.8
        Draw.setColor(1, 1, 1, 0.75)
        love.graphics.setLineWidth(1)
        for y = -R * 0.8, R * 0.8, 4 do
            local half = R * (1 - math.abs(y) / (R * 1.0))
            if half > 1 then love.graphics.line(-half, y, half, y) end
        end
    end
    love.graphics.pop()
    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return BladeNova
