-----------------------------------------------------------
-- BLADE FIELD — полноэкранное поле финала «Рёв».
-- Фон меняет цвет по ходу атаки: чёрный → красный → фиолетовый → синий →
-- пауза → красный → фиолетовый → синий → белая вспышка → фиолетовый.
-- Из центра (где стоит Рыцарь) идут вращающиеся лучи. Урона нет.
-----------------------------------------------------------

local BladeField, super = Class(Bullet)

local S = 0.75   -- общий множитель времени (быстрее оригинала)

-- {время, r, g, b}
local KEYS = {
    { 0.0, 0.00, 0.00, 0.00 },
    { 1.0, 0.00, 0.00, 0.00 },
    { 1.4, 0.16, 0.02, 0.03 },
    { 2.4, 0.46, 0.04, 0.06 },
    { 3.4, 0.40, 0.05, 0.30 },
    { 4.0, 0.34, 0.10, 0.55 },
    { 5.0, 0.07, 0.12, 0.62 },
    { 6.4, 0.06, 0.10, 0.55 },
    { 7.0, 0.10, 0.04, 0.18 },
    { 7.4, 0.00, 0.00, 0.00 },
    { 7.9, 0.46, 0.04, 0.05 },
    { 9.0, 0.40, 0.05, 0.22 },
    { 9.8, 0.30, 0.08, 0.50 },
    { 10.6, 0.06, 0.10, 0.60 },
    { 11.6, 0.06, 0.10, 0.55 },
    { 11.9, 0.85, 0.85, 1.00 },
    { 12.3, 0.30, 0.10, 0.42 },
    { 14.0, 0.30, 0.10, 0.42 },
}

local function palette(t)
    t = t / S
    for i = 1, #KEYS - 1 do
        local a, b = KEYS[i], KEYS[i + 1]
        if t <= b[1] then
            local k = (t - a[1]) / math.max(1e-6, b[1] - a[1])
            k = k * k * (3 - 2 * k)
            return a[2] + (b[2] - a[2]) * k, a[3] + (b[3] - a[3]) * k, a[4] + (b[4] - a[4]) * k
        end
    end
    local l = KEYS[#KEYS]
    return l[2], l[3], l[4]
end

function BladeField:init(cx, cy)
    super.init(self, 0, 0)
    self.cx, self.cy = cx, cy
    self.t = 0
    self.collider = nil
    self.can_graze = false
    self.remove_offscreen = false
    self:setScale(1, 1)
    -- под боевыми спрайтами рыцаря, но поверх фона
    self.layer = BATTLE_LAYERS["below_battlers"]
end

function BladeField:update()
    self.t = self.t + DT
    super.update(self)
end

function BladeField:draw()
    local r, g, b = palette(self.t)
    local W, H = SCREEN_WIDTH, SCREEN_HEIGHT
    local cx, cy = self.cx, self.cy

    -- радиальный градиент: ярче у центра, темнее по краям
    local verts = { { cx, cy, 0, 0, math.min(1, r * 1.5), math.min(1, g * 1.5), math.min(1, b * 1.5), 1 } }
    local R = math.sqrt(W * W + H * H)
    for i = 0, 32 do
        local a = i / 32 * math.pi * 2
        verts[#verts + 1] = { cx + math.cos(a) * R, cy + math.sin(a) * R, 0, 0, r * 0.35, g * 0.35, b * 0.35, 1 }
    end
    Draw.setColor(1, 1, 1, 1)
    love.graphics.draw(love.graphics.newMesh(verts, "fan", "stream"))

    -- лучи света из центра
    local lum = math.min(1, (r + g + b) * 1.2)
    local spin = self.t * 0.25
    for i = 1, 14 do
        local a = spin + i / 14 * math.pi * 2
        local w = 0.05 + 0.03 * math.sin(self.t * 1.7 + i)
        Draw.setColor(1, 1, 1, 0.05 + 0.07 * lum)
        love.graphics.polygon("fill", cx, cy,
            cx + math.cos(a - w) * R, cy + math.sin(a - w) * R,
            cx + math.cos(a + w) * R, cy + math.sin(a + w) * R)
    end
    -- свечение вокруг Рыцаря
    for i = 1, 4 do
        Draw.setColor(1, 1, 1, 0.05 * lum)
        love.graphics.circle("fill", cx, cy, 30 + i * 22)
    end
    Draw.setColor(1, 1, 1, 1)
end

return BladeField
