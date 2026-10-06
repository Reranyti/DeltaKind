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

local RING_INTERVAL = 0.4
local RING_LIFE = 2.6

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
        self.ring_timer = RING_INTERVAL * (hot and 0.55 or 1) * (0.7 + math.random() * 0.6)
        table.insert(self.rings, {
            age = 0,
            spin = (math.random() < 0.5 and -1 or 1) * (0.2 + math.random() * 0.6),
            kind = math.random(1, 3), -- 1 ромб, 2 вращающийся квадрат, 3 двойной ромб
        })
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
        self.slash_timer = (hot and 0.35 or 0.9) + math.random() * 0.8
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


-----------------------------------------------------------
-- SIDE B: зеркальный фиолетовый «калейдоскоп» (шейдер)
-----------------------------------------------------------

local KALEIDO_SRC = [[
extern number time;
extern vec2 res;
extern vec3 mauve;
extern vec3 deepc;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = p * 2.03 + 11.7;
        a *= 0.5;
    }
    return v;
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    vec2 p = (sc / res - 0.5) * vec2(res.x / res.y, 1.0) * 2.0;
    // зеркало по обеим осям
    p = abs(p);
    float t = time * 0.12;
    // искривление: вытянутые полосы, расходящиеся от центра
    vec2 q = vec2(p.x * 0.9 + 0.15 * sin(p.y * 3.0 + t * 3.0), p.y * 1.3);
    float r = length(vec2(p.x, p.y * 1.6));
    float ang = atan(p.y, p.x);
    vec2 w = vec2(r * 2.2 - t * 2.0, ang * 1.6 + 0.6 * sin(r * 3.0 + t * 4.0));
    float n = fbm(w + fbm(q * 2.5 + t));
    float n2 = fbm(w * 1.7 - t * 1.5);

    // палитра: тёмно-фиолетовый -> мальва -> светлый
    vec3 deep = deepc;
    vec3 light = vec3(0.92, 0.86, 0.98);
    float k = smoothstep(0.25, 0.85, n * 0.7 + n2 * 0.5);
    vec3 col = mix(deep, mauve, k);
    col = mix(col, light, smoothstep(0.62, 0.95, k + 0.15 * sin(r * 14.0 - time * 1.2)));

    // светящийся эллипс в центре
    float e = length(vec2(p.x * 0.85, p.y * 1.5));
    float ring = (1.0 - smoothstep(0.20, 0.30, e)) * (0.6 + 0.4 * sin(e * 60.0 - time * 2.0));
    float core = (1.0 - smoothstep(0.0, 0.12, e));
    col += vec3(0.8, 0.7, 1.0) * ring * 0.55 + vec3(0.35, 0.3, 0.6) * core;

    // тёмная виньетка к краям, чтобы читались бой и UI
    float vig = (1.0 - smoothstep(0.35, 1.55, length(p * vec2(0.8, 1.1))));
    col *= 0.35 + 0.65 * vig;
    return vec4(col, 1.0) * color;
}
]]

-- Палитра по HP босса (как в референсе): сиреневый -> коричнево-оранжевый ->
-- зелёный -> красный -> синий. Каждая стопка: {основной тон, тёмный тон}.
local KALEIDO_PALETTE = {
    { {0.45, 0.28, 0.62}, {0.05, 0.01, 0.10} }, -- сиреневый
    { {0.62, 0.40, 0.25}, {0.10, 0.04, 0.02} }, -- коричнево-оранжевый
    { {0.30, 0.58, 0.32}, {0.02, 0.08, 0.03} }, -- зелёный
    { {0.65, 0.22, 0.25}, {0.10, 0.01, 0.02} }, -- красный
    { {0.28, 0.40, 0.70}, {0.02, 0.03, 0.10} }, -- синий
}

function KnightBackground:getKaleidoColors()
    local enemy = Game.battle and Game.battle.enemies and Game.battle.enemies[1]
    local lost = 0
    if enemy and enemy.max_health then
        lost = 1 - MathUtils.clamp(enemy.health / enemy.max_health, 0, 1)
    end
    local f = lost * (#KALEIDO_PALETTE - 1)
    local i = math.min(#KALEIDO_PALETTE - 1, math.floor(f))
    local t = f - i
    local a, b = KALEIDO_PALETTE[i + 1], KALEIDO_PALETTE[i + 2] or KALEIDO_PALETTE[i + 1]
    local function mix(ca, cb)
        return { ca[1] + (cb[1] - ca[1]) * t, ca[2] + (cb[2] - ca[2]) * t, ca[3] + (cb[3] - ca[3]) * t }
    end
    return mix(a[1], b[1]), mix(a[2], b[2])
end

function KnightBackground:drawKaleido(a)
    if not self.kaleido then
        local ok, sh = pcall(love.graphics.newShader, KALEIDO_SRC)
        self.kaleido = ok and sh or false
    end
    if not self.kaleido then return false end
    self.kaleido:send("time", self.time)
    self.kaleido:send("res", { SCREEN_WIDTH, SCREEN_HEIGHT })
    local mauve, deepc = self:getKaleidoColors()
    self.kaleido:send("mauve", mauve)
    self.kaleido:send("deepc", deepc)
    love.graphics.setShader(self.kaleido)
    Draw.setColor(1, 1, 1, a)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    love.graphics.setShader()
    Draw.setColor(1, 1, 1, 1)
    return true
end

function KnightBackground:drawBackground()
    local a = self.alpha
    local cr, cg, cb = self:getAccent()
    local cx, cy = SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2

    -- Side B: калейдоскоп (если шейдер собрался)
    if Kristal.Config.sideB and not Kristal.Config.sideC and self:drawKaleido(a) then
        return
    end

    -- Чёрная пустота
    Draw.setColor(0, 0, 0, a)
    Draw.rectangle("fill", -10, -10, SCREEN_WIDTH + 20, SCREEN_HEIGHT + 20)

    -- Кольца: три вида, вращение, ускоряющийся рост
    love.graphics.setLineWidth(2)
    for _, r in ipairs(self.rings) do
        local t = r.age / RING_LIFE
        local radius = 30 + t * t * 760
        local alpha = (1 - t) * 0.5 * a
        Draw.setColor(cr, cg, cb, alpha)
        if r.kind == 1 then
            diamond(cx, cy, radius)
        elseif r.kind == 2 then
            love.graphics.push()
            love.graphics.translate(cx, cy)
            love.graphics.rotate(r.age * r.spin * 2)
            love.graphics.rectangle("line", -radius * 0.7, -radius * 0.7, radius * 1.4, radius * 1.4)
            love.graphics.pop()
        else
            diamond(cx, cy, radius)
            Draw.setColor(cr, cg, cb, alpha * 0.6)
            diamond(cx, cy, radius * 0.8)
        end
    end

    -- Лучи из центра: медленно вращаются, пульсируют в такт
    local beat = 0.5 + 0.5 * math.sin(self.time * 4)
    love.graphics.setLineWidth(1)
    for i = 0, 11 do
        local ang = self.time * 0.15 + i * math.pi / 6
        Draw.setColor(cr, cg, cb, (0.05 + 0.08 * beat) * a)
        love.graphics.line(cx, cy, cx + math.cos(ang) * 900, cy + math.sin(ang) * 900)
    end

    -- Осколки: мелкие ромбы летят от центра
    for i = 1, 14 do
        local seed = i * 7.31
        local life = (self.time * 0.5 + seed) % 1
        local ang = seed * 2.4
        local dist = life * life * 600 + 30
        local px, py = cx + math.cos(ang) * dist, cy + math.sin(ang) * dist
        Draw.setColor(cr, cg, cb, (1 - life) * 0.6 * a)
        diamond(px, py, 3 + life * 6)
    end

    -- Разрезы: быстрый белый росчерк на весь экран
    for _, s in ipairs(self.slashes) do
        local t = s.age / 0.5
        local alpha = (1 - t) * (1 - t) * 0.9 * a
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
