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
local CLIP_MARGIN = 0    -- росчерк не выходит за границу арены
local last_wind_snd, last_cut_snd = -1, -1

function BladeSlash:init(x, y, angle, length, windup, active, width, damage, spin, style, disc)
    super.init(self, x, y)

    self.angle = angle or 0
    self.length = length or 300
    self.windup = windup or 0.7
    self.active = active or 0.12
    self.slash_width = width or 28
    self.damage = damage or 200
    self.spin = spin or 0
    self.style = style or "white"   -- "rot" = красный «Вращающийся разрез» оригинала
    self.disc = disc            -- рисовать тёмно-красный круг вокруг центра взмаха
    self.dots_time = (self.style == "rot") and math.min(0.2, self.windup * 0.4) or 0

    self.phase = "windup"
    self.phase_time = 0
    self.pulse = 0

    self.can_graze = false
    self.destroy_on_hit = false
    self.remove_offscreen = false
    self:setScale(1, 1)
    self.collider = nil

    if self.spin ~= 0 and self.windup > 0.1 and love.timer.getTime() - last_wind_snd > 0.15 then
        last_wind_snd = love.timer.getTime()
        Assets.playSound("knight_rotatingslash_line", 0.6)
    end
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
        if love.timer.getTime() - last_cut_snd > 0.05 then
            last_cut_snd = love.timer.getTime()
            Assets.playSound(math.random() < 0.5 and "knight_cut" or "knight_cut2", 0.85)
        end
        if Game.battle then Game.battle:shakeCamera(2, 2, 1) end
        self.collider = PolygonCollider(self, self:getSlashPoints())
    else
        self.collider = nil
    end
end

function BladeSlash:update()
    self.phase_time = self.phase_time + DT
    self.pulse = self.pulse + DT

    if self.phase == "windup" then
        if self.spin ~= 0 and self.phase_time > self.dots_time then
            local progress = math.min((self.phase_time - self.dots_time) / math.max(0.05, self.windup - self.dots_time), 1)
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

-- Красный разрез оригинала: пунктир → красные линии-полосы с тёмным кругом →
-- вспышка-клин (красный с розово-белой сердцевиной), выходящий за арену.
function BladeSlash:drawRot()
    local dx, dy = math.cos(self.angle), math.sin(self.angle)
    local nx, ny = -dy, dx
    local L = self.length
    local arena = Game.battle and Game.battle.arena
    local old_sx, old_sy, old_sw, old_sh = love.graphics.getScissor()

    local function clipArena()
        if arena then
            love.graphics.setScissor(math.floor(arena:getLeft()), math.floor(arena:getTop()),
                math.ceil(arena:getRight() - arena:getLeft()), math.ceil(arena:getBottom() - arena:getTop()))
        end
    end

    if self.phase == "windup" then
        clipArena()
        local t = self.phase_time
        if t < self.dots_time then
            -- пунктирная линия-подсказка
            Draw.setColor(1, 1, 1, 0.55 * math.min(1, t / 0.1))
            love.graphics.setLineWidth(1)
            for d = -L, L, 9 do
                love.graphics.line(dx * d, dy * d, dx * (d + 4), dy * (d + 4))
            end
        else
            local k = math.min((t - self.dots_time) / math.max(0.05, self.windup - self.dots_time), 1)
            if self.disc then
                -- тёмно-красный круг вокруг центра взмаха
                local R = 64 * (0.6 + 0.4 * k)
                local verts = { { 0, 0, 0, 0, 0.6, 0, 0, 0.7 } }
                for i = 0, 28 do
                    local a = i / 28 * math.pi * 2
                    verts[#verts + 1] = { math.cos(a) * R, math.sin(a) * R, 0, 0, 0.35, 0, 0, 0.12 }
                end
                love.graphics.draw(love.graphics.newMesh(verts, "fan", "stream"))
            end
            -- линия: тёмная полоса с яркими красными краями
            local h = 5 + 2 * k
            Draw.setColor(0.38, 0, 0, 0.85)
            love.graphics.polygon("fill", -dx * L + nx * h, -dy * L + ny * h, dx * L + nx * h, dy * L + ny * h,
                dx * L - nx * h, dy * L - ny * h, -dx * L - nx * h, -dy * L - ny * h)
            Draw.setColor(1, 0.12, 0.12, 0.95)
            love.graphics.setLineWidth(1.5)
            love.graphics.line(-dx * L + nx * h, -dy * L + ny * h, dx * L + nx * h, dy * L + ny * h)
            love.graphics.line(-dx * L - nx * h, -dy * L - ny * h, dx * L - nx * h, dy * L - ny * h)
            Draw.setColor(1, 0.4, 0.4, 0.35 + 0.3 * k)
            love.graphics.setLineWidth(1)
            love.graphics.line(-dx * L, -dy * L, dx * L, dy * L)
        end
    elseif self.phase == "strike" or self.phase == "fade" then
        clipArena()   -- вспышка не выходит за границу арены
        local k = (self.phase == "strike") and 0 or math.min(self.phase_time / FADE_TIME, 1)
        local W = 46 * ((1 - k) ^ 1.6) * (1 - 0.25 * k)   -- белеющий клин быстро сужается
        local a = 1 - k * k
        local function wedge(width, r, g, b, alpha)
            local pts, N = {}, 22
            for i = 0, N do
                local sgn = (i / N) * 2 - 1
                local hw = width * 0.5 * (1 - math.abs(sgn)) ^ 0.55
                pts[#pts + 1] = { dx * L * sgn + nx * hw, dy * L * sgn + ny * hw }
            end
            for i = N, 0, -1 do
                local sgn = (i / N) * 2 - 1
                local hw = width * 0.5 * (1 - math.abs(sgn)) ^ 0.55
                pts[#pts + 1] = { dx * L * sgn - nx * hw, dy * L * sgn - ny * hw }
            end
            local flat = {}
            for _, p in ipairs(pts) do flat[#flat + 1] = p[1]; flat[#flat + 1] = p[2] end
            Draw.setColor(r, g, b, alpha)
            love.graphics.polygon("fill", unpack(flat))
        end
        -- красное затухает и «возвращается к белому»: цвет уходит в белый
        local wk = math.min(1, k * 1.6)
        wedge(W * 1.5, 1, 0.05 + 0.95 * wk, 0.05 + 0.95 * wk, 0.55 * a)
        wedge(W, 1, 0.12 + 0.88 * wk, 0.12 + 0.88 * wk, a)
        wedge(W * 0.42, 1, 0.82 + 0.18 * wk, 0.86 + 0.14 * wk, a)
    elseif self.phase == "glow" then
        -- тонкая белая линия-послесвечение (как пунктир перед следующим взмахом)
        clipArena()
        local k = math.min(self.phase_time / GLOW_TIME, 1)
        Draw.setColor(1, 1, 1, 0.5 * (1 - k))
        love.graphics.setLineWidth(1.5)
        love.graphics.line(-dx * L, -dy * L, dx * L, dy * L)
        Draw.setColor(1, 1, 1, 0.12 * (1 - k))
        love.graphics.setLineWidth(4)
        love.graphics.line(-dx * L, -dy * L, dx * L, dy * L)
    end

    love.graphics.setScissor(old_sx, old_sy, old_sw, old_sh)
    love.graphics.setLineWidth(1)
    Draw.setColor(1, 1, 1, 1)
end

function BladeSlash:draw()
    if self.style == "rot" then
        self:drawRot()
        Draw.setColor(1, 1, 1, 1)
        return
    end
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
