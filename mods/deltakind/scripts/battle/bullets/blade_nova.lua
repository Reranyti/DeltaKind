-----------------------------------------------------------
-- BLADE NOVA — звезда атаки «Звёзды» (оригинал, фаза 1).
--
-- Графика: ОРИГИНАЛЬНЫЕ спрайты звёзд из спрайт-листа
--   bullets/orig/star_g{0..3}_f{0,1}  (контур; кадры f0/f1 мерцают).
--
-- Механика (раскадровка оригинала):
--   * рождается мелкой у кончика меча и идёт налево веером (~148 px/с),
--     растёт с расстоянием, может уйти за левый край;
--   * стадия "red" (общая): замирает, краснеет, из неё идут лучи света;
--   * стадия "boom": все звёзды взрываются: вспышка, серая звезда, осколки.
-- Анимация: «выскок» при появлении, покачивание, пульс, шлейф-послеобразы,
-- вращающиеся лучи, заряд с дрожью перед взрывом.
-----------------------------------------------------------

local BladeNova, super = Class(Bullet)

local SPEED = 148
local GROW_DIST = 190
local SPR = 64
local TRAIL = 4
local TRAIL_STEP = 0.045

function BladeNova:init(x, y, angle, damage, max_scale)
    local g = math.random(0, 3)
    super.init(self, x, y, "bullets/orig/star_g" .. g .. "_f1")
    if self.sprite then self.sprite:stop() end
    self.group = g
    self.sx0, self.sy0 = x, y
    self.angle = angle
    self.speed = SPEED * MathUtils.random(0.85, 1.2)
    self.damage = damage or 40
    self.max_scale = max_scale or 0.6
    self.t = 0
    self.red_t = 0
    self.dist = 0
    self.frame = 1
    self.phase = MathUtils.random(0, math.pi * 2)
    self.base_angle = MathUtils.random(0, math.pi * 2)
    self.trail = {}
    self.trail_t = 0
    self.shake_x, self.shake_y = 0, 0
    self.cur_scale = 0.14

    -- лучи света при покраснении: как в оригинале — высокие мягкие столбы
    -- вверх/вниз и пара косых
    self.rays = {}
    local function addRay(a, len, w) self.rays[#self.rays + 1] = { a = a, len = len, w = w, ph = MathUtils.random(0, 6.28) } end
    addRay(-math.pi / 2 + MathUtils.random(-0.12, 0.12), MathUtils.random(150, 230), 0.17)
    addRay(math.pi / 2 + MathUtils.random(-0.12, 0.12), MathUtils.random(120, 190), 0.15)
    for i = 1, 2 do
        addRay(-math.pi / 2 + MathUtils.random(-0.9, 0.9), MathUtils.random(90, 150), 0.12)
    end

    self.can_graze = true
    self.destroy_on_hit = true
    self.remove_offscreen = false
    self:setOrigin(0.5, 0.5)
    self:setScale(0.05, 0.05)
    self.collider = CircleCollider(self, 0, 0, 9)
end

function BladeNova:getStage()
    return (self.wave and self.wave.stage) or "fly"
end

function BladeNova:explode()
    if self.wave then
        local s = math.max(0.5, self.cur_scale)
        self.wave:spawnBullet("blade_burst", self.x, self.y, s * 1.7, 0.6)
        -- ровно 6 осколков через 60° (как в оригинале): 3 коротких и медленных
        -- (внутренний треугольник) и 3 длинных и быстрых (внешний), через один
        for i = 0, 5 do
            local ang = self.base_angle + i * math.pi / 3
            local long = (i % 2 == 0)
            self.wave:spawnBullet("blade_shard", self.x, self.y, ang,
                long and 4.8 or 2.2, math.ceil(self.damage),
                long and 2.0 or 1.5, long and 20 or 16, false)
        end
    end
    self:remove()
end

function BladeNova:update()
    self.t = self.t + DT
    local stage = self:getStage()
    self.sm = (self.wave and self.wave.speed_mult) or 1

    if stage == "fly" then
        self.dist = self.dist + self.speed * self.sm * DT
        local wob = math.sin(self.t * 5 + self.phase) * 3
        self.x = self.sx0 + math.cos(self.angle) * self.dist
        self.y = self.sy0 + math.sin(self.angle) * self.dist + wob
        local e = math.min(1, self.dist / GROW_DIST)
        local base = 0.14 + (self.max_scale - 0.14) * e
        -- «выскок» при появлении и лёгкий пульс
        local pop = 1 + 0.35 * math.sin(math.min(1, self.t / 0.22) * math.pi)
        local pulse = 1 + 0.05 * math.sin(self.t * 12 + self.phase)
        self.cur_scale = base * pop * pulse
        self:setScale(self.cur_scale, self.cur_scale)
        if self.sprite then self.sprite.rotation = math.sin(self.t * 2 + self.phase) * 0.25 end
        -- мерцание кадров контура
        local f = (math.floor(self.t / 0.12) % 2 == 0) and 0 or 1
        if f ~= self.frame - 1 then
            self.frame = f + 1
            if self.sprite then self.sprite:setTexture("bullets/orig/star_g" .. self.group .. "_f" .. f) end
        end
        -- шлейф: запоминаем прошлые позиции
        self.trail_t = self.trail_t + DT
        if self.trail_t >= TRAIL_STEP then
            self.trail_t = 0
            table.insert(self.trail, 1, { x = self.x, y = self.y, s = self.cur_scale })
            if #self.trail > TRAIL then table.remove(self.trail) end
        end
        if self.x < -70 then self:remove() return end
    elseif stage == "red" then
        self.red_t = self.red_t + DT
        -- заряд: пульс, к концу дрожь и набухание
        local charge = math.min(1, self.red_t / 1.0)
        local pulse = 1 + 0.07 * math.sin(self.red_t * (10 + charge * 20))
        local grow = 1 + 0.12 * charge * charge
        local s = self.cur_scale * pulse * grow
        self:setScale(s, s)
        if charge > 0.6 then
            self.shake_x = MathUtils.random(-1.6, 1.6) * charge
            self.shake_y = MathUtils.random(-1.6, 1.6) * charge
        end
        if self.sprite then
            local b = 0.65 + 0.25 * math.sin(self.red_t * 9)
            self.sprite:setColor(1, 1, 1, 0)
            self.sprite.rotation = self.sprite.rotation + DT * 0.5
        end
        self.trail = {}
    else
        self:explode()
        return
    end
    super.update(self)
end

local ray_mesh
local function ray(a, len, alpha, w)
    -- мягкий луч: яркий у основания, плавно гаснет к концу
    if not ray_mesh then
        ray_mesh = love.graphics.newMesh({
            {0, 0, 0, 0, 1, 1, 1, 1},
            {1, -1, 0, 0, 1, 1, 1, 0},
            {1,  1, 0, 0, 1, 1, 1, 0},
            {0, 0, 0, 0, 1, 1, 1, 1},
        }, "fan")
    end
    love.graphics.push()
    love.graphics.rotate(a)
    love.graphics.scale(len, len * w)
    for pass = 1, 2 do
        local k = (pass == 1) and 1 or 0.45
        love.graphics.setColor(1, 1, 1, alpha * (pass == 1 and 0.55 or 1))
        love.graphics.push()
        love.graphics.scale(1, k)
        love.graphics.draw(ray_mesh)
        love.graphics.pop()
    end
    love.graphics.pop()
end

function BladeNova:draw()
    local sx = math.max(0.01, self.scale_x)
    love.graphics.push()
    love.graphics.scale(1 / sx, 1 / sx)

    -- шлейф-послеобразы (за звездой, затухающие)
    if self:getStage() == "fly" and #self.trail > 0 then
        local tex = Assets.getTexture("bullets/orig/star_g" .. self.group .. "_f0")
        if tex then
            for i, h in ipairs(self.trail) do
                local a = 0.28 * (1 - (i - 1) / TRAIL)
                Draw.setColor(1, 1, 1, a)
                Draw.draw(tex, h.x - self.x, h.y - self.y, 0, h.s, h.s, SPR / 2, SPR / 2)
            end
        end
    end

    if self:getStage() == "red" then
        local k = math.min(1, self.red_t / 0.5)
        for _, r in ipairs(self.rays) do
            local pulse = 0.8 + 0.2 * math.sin(self.red_t * 9 + r.ph)
            local grow = 1 - (1 - k) * (1 - k)
            ray(r.a, r.len * grow * pulse, 0.5 * k, r.w)
        end
        -- красная звезда с белой сердцевиной и гранатом, как в оригинале
        local rs = Assets.getTexture("bullets/orig/red_star")
        local wf = Assets.getTexture("bullets/orig/star_g" .. self.group .. "_f2")
        local b = 0.75 + 0.25 * math.sin(self.red_t * 12)
        if rs then
            Draw.setColor(1, 0.1 + 0.15 * b, 0.1, 1)
            Draw.draw(rs, 0, 0, 0, self.cur_scale * 1.0, self.cur_scale * 1.0, SPR / 2, SPR / 2)
        end
        if wf then
            Draw.setColor(1, 1, 1, 0.95)
            Draw.draw(wf, 0, 0, 0, self.cur_scale * 0.55, self.cur_scale * 0.55, SPR / 2, SPR / 2)
        end
        Draw.setColor(0.75, 0.05, 0.1, 1)
        local g = self.cur_scale * 9
        love.graphics.polygon("fill", 0, -g, g * 0.7, 0, 0, g, -g * 0.7, 0)
        Draw.setColor(1, 1, 1, 0.9)
        love.graphics.polygon("fill", 0, -g * 0.4, g * 0.28, 0, 0, g * 0.4, -g * 0.28, 0)
    end
    -- «строчная» заливка у больших звёзд в полёте
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

    -- дрожь перед взрывом
    if self.shake_x ~= 0 or self.shake_y ~= 0 then
        love.graphics.push()
        love.graphics.translate(self.shake_x / sx, self.shake_y / sx)
        super.draw(self)
        love.graphics.pop()
    else
        super.draw(self)
    end
end

return BladeNova
