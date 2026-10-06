-----------------------------------------------------------
-- KNIGHT BACKGROUND — фон боя с Рокочущим Рыцарем.
--
-- Наследуем BattleBackground, чтобы работали fadeOut()/isFading()
-- и появление/затухание из движка, но рисуем своё:
--   * чёрная пустота;
--   * расширяющиеся ромбовидные кольца (отсылка к ромбу-шлему);
--   * редкие белые «разрезы» через весь экран;
--   * цвет акцента зависит от фазы и стороны:
--       Side A  — белый,   фаза 2 — красный;
--       Side B  — голубой, фаза 2 — красный;
--       Side C  — зелёный.
-----------------------------------------------------------

local KnightBackground, super = Class(BattleBackground)

local RING_INTERVAL = 0.9
local RING_LIFE = 5.0

function KnightBackground:init()
    super.init(self)

    self.rings = {}
    self.slashes = {}
    self.ring_timer = 0
    self.slash_timer = 1.5
    self.time = 0

    -- Своя "паника" фона: растёт с потерей HP босса (0..1).
    self.tension = 0
end

function KnightBackground:getAccent()
    local phase2 = false
    local enemy = Game.battle and Game.battle.enemies and Game.battle.enemies[1]
    if enemy and enemy.phase and enemy.phase >= 2 then
        phase2 = true
    end

    if phase2 then
        return 1, 0.12, 0.12, true
    end
    if Kristal.Config.sideC then
        return 0.35, 1, 0.45, false
    end
    if Kristal.Config.sideB then
        return 0.3, 0.8, 1, false
    end
    return 1, 1, 1, false
end

function KnightBackground:update()
    super.update(self)

    self.time = self.time + DT

    local _, _, _, hot = self:getAccent()
    local enemy = Game.battle and Game.battle.enemies and Game.battle.enemies[1]
    if enemy and enemy.max_health then
        self.tension = 1 - (enemy.health / enemy.max_health)
    end

    -- Кольца
    self.ring_timer = self.ring_timer - DT
    if self.ring_timer <= 0 then
        self.ring_timer = RING_INTERVAL * (hot and 0.6 or 1)
        table.insert(self.rings, { age = 0 })
    end
    for i = #self.rings, 1, -1 do
        local r = self.rings[i]
        r.age = r.age + DT
        if r.age > RING_LIFE then
            table.remove(self.rings, i)
        end
    end

    -- Разрезы
    self.slash_timer = self.slash_timer - DT
    if self.slash_timer <= 0 then
        self.slash_timer = (hot and 0.8 or 2.2) + math.random() * 1.5
        table.insert(self.slashes, {
            age = 0,
            angle = math.random() * math.pi,
            offset = (math.random() - 0.5) * 300,
        })
    end
    for i = #self.slashes, 1, -1 do
        local s = self.slashes[i]
        s.age = s.age + DT
        if s.age > 0.5 then
            table.remove(self.slashes, i)
        end
    end
end

local function diamond(cx, cy, r)
    love.graphics.polygon("line", cx, cy - r, cx + r, cy, cx, cy + r, cx - r, cy)
end

function KnightBackground:drawBackground()
    local a = self.alpha
    local cr, cg, cb = self:getAccent()
    local cx, cy = SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2

    -- Чёрная пустота
    Draw.setColor(0, 0, 0, a)
    Draw.rectangle("fill", -10, -10, SCREEN_WIDTH + 20, SCREEN_HEIGHT + 20)

    -- Ромбовидные кольца: растут и гаснут
    love.graphics.setLineWidth(2)
    for _, r in ipairs(self.rings) do
        local t = r.age / RING_LIFE
        local radius = 40 + t * t * 700
        local alpha = (1 - t) * 0.35 * a
        Draw.setColor(cr, cg, cb, alpha)
        diamond(cx, cy, radius)
        -- Внутренний тонкий ромб для глубины
        Draw.setColor(cr, cg, cb, alpha * 0.4)
        diamond(cx, cy, radius * 0.92)
    end

    -- Разрезы: быстрый белый росчерк на весь экран
    for _, s in ipairs(self.slashes) do
        local t = s.age / 0.5
        local alpha = (1 - t) * (1 - t) * 0.8 * a
        local dx, dy = math.cos(s.angle), math.sin(s.angle)
        local px, py = cx - dy * s.offset, cy + dx * s.offset
        local len = 900
        love.graphics.setLineWidth(3 * (1 - t) + 1)
        Draw.setColor(cr, cg, cb, alpha)
        love.graphics.line(px - dx * len, py - dy * len, px + dx * len, py + dy * len)
    end

    -- Виньетка: края темнеют, к центру светлее
    Draw.setColor(0, 0, 0, 0.45 * a)
    love.graphics.setLineWidth(60)
    love.graphics.rectangle("line", -30, -30, SCREEN_WIDTH + 60, SCREEN_HEIGHT + 60)

    love.graphics.setLineWidth(1)
    Draw.setColor(1, 1, 1, 1)
end

return KnightBackground
