-----------------------------------------------------------
-- BLADE SLASH — линия-разрез.
--
-- Линия идёт через точку (x, y) под углом angle, на length в каждую сторону.
--   1. телеграф (windup)  — красная полоса: зона будущего удара;
--   2. удар (active)      — белый росчерк, урон есть;
--   3. затухание (0.25 с) — росчерк затухает по кадрам, урона нет;
--   4. «след» (0.35 с)    — тонкая белая линия-послесвечение, урона нет.
-- Росчерк рисуется ОРИГИНАЛЬНЫМИ спрайтами QuickSlash из листа
-- (bullets/orig/fx_qs_0..3); если их нет — запасная полоса.
-----------------------------------------------------------

local BladeSlash, super = Class(Bullet)

local FADE_TIME = 0.25
local GLOW_TIME = 0.35
local CLIP_MARGIN = 90   -- росчерк виден и за границей арены, как у оригинала

function BladeSlash:init(x, y, angle, length, windup, active, width, damage, spin)
    super.init(self, x, y)

    self.angle = angle or 0
    self.length = length or 300
    self.windup = windup or 0.7
    self.active = active or 0.12
    self.slash_width = width or 28
    self.damage = damage or 200
    self.spin = spin or 0

    self.phase = "windup"
    self.phase_time = 0
    self.pulse = 0

    self.can_graze = false
    self.destroy_on_hit = false
    self.remove_offscreen = false
    self:setScale(1, 1)
    self.collider = nil

    self.qs = {}
    for i = 0, 3 do self.qs[i] = Assets.getTexture("bullets/orig/fx_qs_" .. i) end
end

--- Четыре точки повёрнутого прямоугольника в локальных координатах пули.
function BladeSlash:getSlashPoints()
    local dx, dy = math.cos(self.angle), math.sin(self.angle)
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
    else
        self.collider = nil
    end
end

function BladeSlash:update()
    self.phase_time = self.phase_time + DT
    self.pulse = self.pulse + DT

    if self.phase == "windup" then
        if self.spin ~= 0 then
            local progress = math.min(self.phase_time / self.windup, 1)
            self.angle = self.angle + self.spin * DT * (1 - progress) * (1 - progress)
        end
        if self.phase_time >= self.windup then self:setPhase("strike") end
    elseif self.phase == "strike" then
        if self.phase_time >= self.active then self:setPhase("fade") end
    elseif self.phase == "fade" then
        if self.phase_time >= FADE_TIME then self:setPhase("glow") end
    else -- glow
        if self.phase_time >= GLOW_TIME then self:remove() return end
    end
    super.update(self)
end

--- Росчерк спрайтом QuickSlash, растянутым вдоль линии.
function BladeSlash:drawStreak(frame, thick, alpha)
    local tex = self.qs[frame]
    if not tex then return false end
    local w, h = tex:getWidth(), tex:getHeight()
    Draw.setColor(1, 1, 1, alpha)
    Draw.draw(tex, 0, 0, self.angle, (self.length * 2) / w, thick / h, w / 2, h / 2)
    return true
end

function BladeSlash:draw()
    local dx, dy = math.cos(self.angle), math.sin(self.angle)
    local x1, y1 = -dx * self.length, -dy * self.length
    local x2, y2 = dx * self.length, dy * self.length

    local arena = Game.battle and Game.battle.arena
    local old_sx, old_sy, old_sw, old_sh = love.graphics.getScissor()
    if arena then
        local m = CLIP_MARGIN
        local ax, ay = arena:getLeft() - m, arena:getTop() - m
        local aw, ah = arena:getRight() - arena:getLeft() + m * 2, arena:getBottom() - arena:getTop() + m * 2
        love.graphics.setScissor(math.floor(ax), math.floor(ay), math.ceil(aw), math.ceil(ah))
    end
    love.graphics.setLineStyle("rough")

    if self.phase == "windup" then
        local progress = math.min(self.phase_time / self.windup, 1)
        local pulse = 0.5 + 0.5 * math.sin(self.pulse * (10 + progress * 20))
        local pts = self:getSlashPoints()
        Draw.setColor(1, 0.05, 0.05, 0.10 + 0.25 * progress + 0.10 * pulse)
        love.graphics.polygon("fill",
            pts[1][1], pts[1][2], pts[2][1], pts[2][2],
            pts[3][1], pts[3][2], pts[4][1], pts[4][2])
        Draw.setColor(1, 0.15, 0.15, 0.55 + 0.4 * pulse)
        love.graphics.setLineWidth(2)
        love.graphics.line(pts[1][1], pts[1][2], pts[2][1], pts[2][2])
        love.graphics.line(pts[4][1], pts[4][2], pts[3][1], pts[3][2])
        Draw.setColor(1, 0.4, 0.4, 0.5 + 0.5 * pulse)
        love.graphics.setLineWidth(1 + progress * 2)
        love.graphics.line(x1, y1, x2, y2)

    elseif self.phase == "strike" then
        -- жирный росчерк: первый кадр QuickSlash + белая основа
        local w = self.slash_width
        local pts = self:getSlashPoints()
        Draw.setColor(1, 1, 1, 1)
        love.graphics.polygon("fill",
            pts[1][1], pts[1][2], pts[2][1], pts[2][2],
            pts[3][1], pts[3][2], pts[4][1], pts[4][2])
        self:drawStreak(0, w * 2.2, 1)

    elseif self.phase == "fade" then
        -- кадры QuickSlash 1..3 по ходу затухания
        local k = math.min(self.phase_time / FADE_TIME, 1)
        local frame = math.min(3, 1 + math.floor(k * 3))
        local w = self.slash_width * (1.9 - 0.9 * k)
        if not self:drawStreak(frame, w * 2.0, 1 - k * 0.6) then
            local h = (self.slash_width / 2) * (1 - k)
            local nx, ny = -dy, dx
            Draw.setColor(1, 1, 1, 1 - k)
            love.graphics.polygon("fill",
                x1 + nx * h, y1 + ny * h, x2 + nx * h, y2 + ny * h,
                x2 - nx * h, y2 - ny * h, x1 - nx * h, y1 - ny * h)
        end

    else -- glow: тонкий «след» после удара
        local k = math.min(self.phase_time / GLOW_TIME, 1)
        Draw.setColor(1, 1, 1, 0.55 * (1 - k))
        love.graphics.setLineWidth(2)
        love.graphics.line(x1, y1, x2, y2)
        Draw.setColor(1, 1, 1, 0.18 * (1 - k))
        love.graphics.setLineWidth(6)
        love.graphics.line(x1, y1, x2, y2)
    end

    love.graphics.setScissor(old_sx, old_sy, old_sw, old_sh)
    love.graphics.setLineWidth(1)
    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return BladeSlash
