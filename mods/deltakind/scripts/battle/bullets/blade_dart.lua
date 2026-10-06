-----------------------------------------------------------
-- BLADE DART — меч атаки «Tracking Swords» (оригинал).
--
-- Меч появляется на одной из 8 сторон от души и ходит вместе с ней
-- (держит смещение), смотрит остриём на неё. Через aim_time краснеет и
-- замирает (lock), затем исчезает, оставляя белый разрез через душу.
-- Спрайт: assets/sprites/bullets/knight_sword_alt.png (смотрит вправо).
-----------------------------------------------------------

local BladeDart, super = Class(Bullet)

local LOCK_TIME = 0.3
local STRIKE_WIDTH = 14

function BladeDart:init(x, y, dir_angle, dist, aim_time, damage)
    super.init(self, x, y, "bullets/knight_sword_alt")

    self.sprite:stop()
    self.sprite:setOrigin(0.5, 0.5)

    self.dir_angle = dir_angle      -- откуда появился (от души к мечу)
    self.dist = dist or 95
    self.aim_time = aim_time or 1
    self.damage = damage or 206
    self.state = "aim"
    self.state_t = 0
    self.slash_angle = 0

    self.can_graze = false
    self.destroy_on_hit = false
    self.collider = nil
    self.remove_offscreen = false
    self:setScale(1, 1)
    self:setOrigin(0.5, 0.5)
end

local function soulPos()
    local soul = Game.battle and Game.battle.soul
    if soul then return soul.x, soul.y end
    local a = Game.battle and Game.battle.arena
    if a then return a.x, a.y end
    return 320, 240
end

function BladeDart:update()
    self.state_t = self.state_t + DT

    if self.state == "aim" then
        local sx, sy = soulPos()
        -- держим смещение относительно души
        self.x = sx + math.cos(self.dir_angle) * self.dist
        self.y = sy + math.sin(self.dir_angle) * self.dist
        -- остриё на душу
        self.rotation = self.dir_angle + math.pi
        -- к концу прицеливания чуть сближаемся
        local p = self.state_t / self.aim_time
        self.dist = self.dist - DT * 20 * p
        if self.state_t >= self.aim_time then
            self.state = "lock"
            self.state_t = 0
            self.lock_x, self.lock_y = sx, sy
            self.slash_angle = self.rotation
            if self.sprite then self.sprite:setColor(1, 0.2, 0.2, 1) end
        end
    else -- lock: замер, затем разрез
        if self.state_t >= LOCK_TIME then
            local arena = Game.battle.arena
            local length = math.sqrt(arena.width ^ 2 + arena.height ^ 2) + 40
            self.wave:spawnBullet("blade_slash",
                self.lock_x, self.lock_y, self.slash_angle,
                length, 0.001, 0.12, STRIKE_WIDTH, self.damage)
            self:remove()
            return
        end
    end
    super.update(self)
end

return BladeDart
