-----------------------------------------------------------
-- BLADE DART — меч атаки «Tracking Swords» (оригинал).
--
-- Графика: ОРИГИНАЛЬНЫЙ спрайт меча из спрайт-листа
--   bullets/orig/sword_knight.png  (орнаментальный меч с глазом, смотрит вправо).
--
-- Механика по раскадровке оригинала (38–46 с):
--   aim    — меч стоит СНАРУЖИ арены, на линии от души (по сторонам света /
--            диагоналям), остриём на душу, и ходит вместе с ней; блеклый;
--   red    — краснеет, замирает на месте (последняя доля секунды);
--   strike — белая вспышка: меч заливается белым и пролетает через поле
--            по линии на душу, оставляя белый росчерк (blade_slash).
-----------------------------------------------------------

local BladeDart, super = Class(Bullet)

local RED_TIME = 0.32
local SLASH_WIDTH = 14
local MARGIN = 26   -- насколько меч стоит дальше границы арены

function BladeDart:init(x, y, dir_angle, aim_time, damage)
    super.init(self, x, y, "bullets/orig/sword_knight")
    if self.sprite then self.sprite:stop() end

    self.dir_angle = dir_angle      -- направление от души к мечу
    self.aim_time = aim_time or 1
    self.damage = damage or 206
    self.state = "aim"
    self.t = 0
    self.appear = 0

    self.can_graze = false
    self.destroy_on_hit = false
    self.collider = nil
    self.remove_offscreen = false
    self:setOrigin(0.5, 0.5)
    self:setScale(0.66, 0.66)
    self.alpha = 0
end

local function soulPos()
    local soul = Game.battle and Game.battle.soul
    if soul then return soul.x, soul.y end
    local a = Game.battle and Game.battle.arena
    if a then return a.x, a.y end
    return 320, 240
end

--- Расстояние от точки (px,py) до границы арены (прямоугольник) вдоль луча dir.
local function distToArena(px, py, dir)
    local a = Game.battle and Game.battle.arena
    if not a then return 70 end
    local dx, dy = math.cos(dir), math.sin(dir)
    local best = math.huge
    local L, R, T, B = a:getLeft(), a:getRight(), a:getTop(), a:getBottom()
    if dx > 1e-4 then best = math.min(best, (R - px) / dx) elseif dx < -1e-4 then best = math.min(best, (L - px) / dx) end
    if dy > 1e-4 then best = math.min(best, (B - py) / dy) elseif dy < -1e-4 then best = math.min(best, (T - py) / dy) end
    return math.max(20, best)
end

function BladeDart:update()
    self.t = self.t + DT

    if self.state == "aim" then
        local sx, sy = soulPos()
        local r = distToArena(sx, sy, self.dir_angle) + MARGIN
        self.x = sx + math.cos(self.dir_angle) * r
        self.y = sy + math.sin(self.dir_angle) * r
        self.rotation = self.dir_angle + math.pi            -- остриё на душу
        self.alpha = math.min(0.75, self.t / 0.25)          -- блеклый, проявляется
        if self.sprite then self.sprite:setColor(1, 1, 1, self.alpha) end
        if self.t >= self.aim_time - RED_TIME then
            self.state = "red"
            self.t = 0
            self.lock_x, self.lock_y = sx, sy
            self.slash_angle = self.rotation
        end
    elseif self.state == "red" then
        -- замер на месте, красный; к концу мигание
        local blink = 0.7 + 0.3 * math.sin(self.t * 40)
        if self.sprite then self.sprite:setColor(1, 0.25, 0.25, blink) end
        if self.t >= RED_TIME then
            -- удар: белый росчерк через душу и белая вспышка меча
            local arena = Game.battle.arena
            local length = math.sqrt(arena.width ^ 2 + arena.height ^ 2) + 120
            self.wave:spawnBullet("blade_slash",
                self.lock_x, self.lock_y, self.slash_angle,
                length, 0.001, 0.12, SLASH_WIDTH, self.damage)
            self.state = "strike"
            self.t = 0
            self:setScale(0.85, 0.85)
        end
    else -- strike: белая вспышка меча, быстро летит к душе и гаснет
        local k = self.t / 0.18
        if k >= 1 then self:remove() return end
        local ex, ey = self.lock_x, self.lock_y
        self.x = self.x + (ex - self.x) * math.min(1, DT * 18)
        self.y = self.y + (ey - self.y) * math.min(1, DT * 18)
        if self.sprite then self.sprite:setColor(1, 1, 1, 1 - k) end
    end
    super.update(self)
end

return BladeDart
