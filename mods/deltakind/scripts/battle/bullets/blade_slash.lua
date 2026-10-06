-----------------------------------------------------------
-- BLADE SLASH — линия-разрез
--
-- Линия идёт через точку (x, y) под углом angle, на length
-- в каждую сторону. Три фазы:
--   1. телеграф (windup)  — тонкая пульсирующая красная линия, без урона
--   2. удар (active)      — толстая белая линия, урон есть
--   3. затухание (~0.25с) — белая линия тает, урона нет
-- Рисуется процедурно, спрайтов нет.
-----------------------------------------------------------

local BladeSlash, super = Class(Bullet)

local FADE_TIME = 0.25

function BladeSlash:init(x, y, angle, length, windup, active, width, damage)
    super.init(self, x, y)

    self.angle = angle or 0
    self.length = length or 300
    self.windup = windup or 0.7
    self.active = active or 0.12
    self.slash_width = width or 28
    self.damage = damage or 200

    self.phase = "windup"
    self.phase_time = 0
    self.pulse = 0

    self.can_graze = false
    self.destroy_on_hit = false
    self.remove_offscreen = false
    self:setScale(1, 1)

    -- Опасной зоны нет, пока не наступит удар (nil безопасен: Object:meetsCollider возвращает false)
    self.collider = nil

    -- TODO: звук телеграфа (файла пока нет)
end

--- Четыре точки повёрнутого прямоугольника в локальных координатах пули.
function BladeSlash:getSlashPoints()
    local dx, dy = math.cos(self.angle), math.sin(self.angle)
    -- нормаль к линии
    local nx, ny = -dy, dx
    local l = self.length
    local h = self.slash_width / 2
    return {
        {-dx * l + nx * h, -dy * l + ny * h},
        { dx * l + nx * h,  dy * l + ny * h},
        { dx * l - nx * h,  dy * l - ny * h},
        {-dx * l - nx * h, -dy * l - ny * h},
    }
end

function BladeSlash:setPhase(phase)
    self.phase = phase
    self.phase_time = 0

    if phase == "strike" then
        self.collider = PolygonCollider(self, self:getSlashPoints())
        -- TODO: звук удара (файла пока нет)
    else
        self.collider = nil
    end
end

function BladeSlash:update()
    -- DT — секунды кадра (в Kristal DT = DTMULT / 30)
    self.phase_time = self.phase_time + DT
    self.pulse = self.pulse + DT

    if self.phase == "windup" then
        if self.phase_time >= self.windup then
            self:setPhase("strike")
        end
    elseif self.phase == "strike" then
        if self.phase_time >= self.active then
            self:setPhase("fade")
        end
    elseif self.phase == "fade" then
        if self.phase_time >= FADE_TIME then
            self:remove()
            return
        end
    end

    super.update(self)
end

function BladeSlash:draw()
    local dx, dy = math.cos(self.angle), math.sin(self.angle)
    local x1, y1 = -dx * self.length, -dy * self.length
    local x2, y2 = dx * self.length, dy * self.length

    love.graphics.setLineStyle("rough")

    if self.phase == "windup" then
        local progress = math.min(self.phase_time / self.windup, 1)
        local pulse = 0.5 + 0.5 * math.sin(self.pulse * (10 + progress * 20))
        local alpha = 0.35 + 0.45 * pulse
        -- линия слегка толстеет к концу телеграфа
        Draw.setColor(1, 0.1, 0.1, alpha)
        love.graphics.setLineWidth(1 + progress * 2)
        love.graphics.line(x1, y1, x2, y2)
    elseif self.phase == "strike" then
        local pts = self:getSlashPoints()
        Draw.setColor(1, 1, 1, 1)
        love.graphics.polygon("fill",
            pts[1][1], pts[1][2], pts[2][1], pts[2][2],
            pts[3][1], pts[3][2], pts[4][1], pts[4][2])
    else
        -- затухание: белый росчерк сужается и гаснет
        local t = math.min(self.phase_time / FADE_TIME, 1)
        local h = (self.slash_width / 2) * (1 - t)
        local nx, ny = -dy, dx
        Draw.setColor(1, 1, 1, 1 - t)
        love.graphics.polygon("fill",
            x1 + nx * h, y1 + ny * h, x2 + nx * h, y2 + ny * h,
            x2 - nx * h, y2 - ny * h, x1 - nx * h, y1 - ny * h)
    end

    love.graphics.setLineWidth(1)
    Draw.setColor(1, 1, 1, 1)

    super.draw(self)
end

return BladeSlash
