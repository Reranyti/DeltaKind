-----------------------------------------------------------
-- BLADE SWORD — меч из шеренги «Коридора клинков».
--
-- Вертикальный контурный меч (белый контур, чёрная заливка),
-- остриё направлено в коридор. row = "top" (остриём вниз,
-- тело уходит вверх) или "bottom" (остриём вверх). Вся шеренга
-- синхронно ходит вверх-вниз: положение острия берётся у волны
-- (wave:getTipY(row)). Рядом с душой меч краснеет.
-----------------------------------------------------------

local BladeSword, super = Class(Bullet)

local LENGTH = 150
local BLADE_W = 10

function BladeSword:init(x, row, speed, damage)
    super.init(self, x, 0)

    self.row = row
    self.k = (row == "top") and -1 or 1 -- направление от острия к рукояти
    self.speed = speed or 160
    self.damage = damage or 62
    self.alert = 0

    self.can_graze = false
    self.destroy_on_hit = false
    self.remove_offscreen = false
    self:setScale(1, 1)

    -- Хитбокс — узкая полоса вдоль клинка (локальные координаты, острие в (0,0))
    local y0 = (self.k == -1) and -LENGTH or 0
    self.collider = Hitbox(self, -BLADE_W / 2, y0, BLADE_W, LENGTH)
end

function BladeSword:update()
    self.x = self.x - self.speed * DT
    if self.wave and self.wave.getTipY then
        self.y = self.wave:getTipY(self.row)
    end

    -- Краснеет, когда душа рядом по горизонтали
    local soul = Game.battle and Game.battle.soul
    local near = soul and math.abs(soul.x - self.x) < 46
    self.alert = MathUtils.approach(self.alert, near and 1 or 0, DT * 8)

    if self.x < -60 then
        self:remove()
        return
    end
    super.update(self)
end

local function pts(k, list)
    local out = {}
    for i = 1, #list, 2 do
        out[#out + 1] = list[i]
        out[#out + 1] = list[i + 1] * k
    end
    return out
end

function BladeSword:draw()
    local a = self.alert
    local k = self.k
    local L = LENGTH
    local w = BLADE_W / 2

    -- Клинок: остриё (0,0) -> плечи -> перекладина -> рукоять -> навершие (d вдоль k)
    local blade = pts(k, { 0, 0, w, 16, w, L - 26, -w, L - 26, -w, 16 })
    local guard = pts(k, { -13, L - 26, 13, L - 26, 13, L - 21, -13, L - 21 })
    local grip  = pts(k, { -3, L - 21, 3, L - 21, 3, L - 6, -3, L - 6 })
    local pommel = pts(k, { 0, L - 6, 5, L - 2, 0, L + 2, -5, L - 2 })

    local function part(p)
        Draw.setColor(0.18 * a, 0, 0, 1)
        love.graphics.polygon("fill", p)
        Draw.setColor(1, 1 - 0.85 * a, 1 - 0.85 * a, 1)
        love.graphics.setLineWidth(2)
        love.graphics.polygon("line", p)
    end
    part(blade); part(guard); part(grip); part(pommel)

    -- Лезвие: центральная линия
    Draw.setColor(1, 1 - 0.85 * a, 1 - 0.85 * a, 0.6)
    love.graphics.setLineWidth(1)
    love.graphics.line(0, 4 * k, 0, (L - 28) * k)

    Draw.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
    super.draw(self)
end

return BladeSword
