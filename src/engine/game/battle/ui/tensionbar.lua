--- DeltaKind 750-point Tension Bar
---
--- Completely replaces the old 100/250-point visual system.
--- The only source of truth is Game:getTension() / Game:getMaxTension().
---
---@class TensionBar : Object
---@overload fun(...) : TensionBar
---@field current_flash TensionBarGlow?
local TensionBar, super = Class(Object)

-- =========================================================
-- DELTAKIND TP SYSTEM
-- =========================================================

-- DeltaKind uses a hard 750 TP battle scale.
local DELTAKIND_MAX_TENSION = 750

-- =========================================================
-- VISUAL SETTINGS
-- =========================================================

local SCREEN_MARGIN = 56
local BAR_HEIGHT = 18
local BAR_Y = 24
local TEXT_GAP = 7

local COLOR_BACK = {0.025, 0.002, 0.002, 1}
local COLOR_BORDER = {0.55, 0.025, 0.025, 1}
local COLOR_BORDER_INNER = {0.24, 0.008, 0.008, 1}

local COLOR_FILL = {0.64, 0.012, 0.012, 1}
local COLOR_FILL_MAX = {0.95, 0.025, 0.025, 1}
local COLOR_HIGHLIGHT = {1.0, 0.10, 0.10, 1}

local COLOR_KRIS = {0.35, 0.75, 1.0, 1}
local COLOR_SUSIE = {0.95, 0.35, 0.75, 1}
local COLOR_RALSEI = {0.55, 1.0, 0.65, 1}

-- =========================================================
-- HELPERS
-- =========================================================

function TensionBar:getMaxTension()
    return DELTAKIND_MAX_TENSION
end

function TensionBar:getTension()
    return MathUtils.clamp(
        Game:getTension(),
        0,
        self:getMaxTension()
    )
end

function TensionBar:getPercentage()
    return MathUtils.clamp(
        self:getTension() / self:getMaxTension(),
        0,
        1
    )
end

function TensionBar:getBarWidth()
    return math.max(
        1,
        SCREEN_WIDTH - (SCREEN_MARGIN * 2)
    )
end

function TensionBar:getBarX()
    return SCREEN_MARGIN
end

function TensionBar:getBarY()
    return BAR_Y
end

-- =========================================================
-- INITIALIZATION
-- =========================================================

function TensionBar:init(x, y, dont_animate)
    super.init(
        self,
        x or 0,
        y or 0
    )

    self.layer = BATTLE_LAYERS["ui"] - 1

    self.width = SCREEN_WIDTH
    self.height = BAR_Y + BAR_HEIGHT + 60

    -- Compatibility with Kristal.
    self.tp_bar_fill =
        Assets.getTexture("ui/battle/tp_bar_fill")

    self.tp_bar_outline =
        Assets.getTexture("ui/battle/tp_bar_outline")

    self.tp_text =
        Assets.getTexture("ui/battle/tp_text")

    self.font =
        Assets.getFont(
            "deltarune-cyrillic1",
            16
        )

    -- =====================================================
    -- IMPORTANT:
    -- These values are REAL TP, not 0-250.
    -- =====================================================

    self.apparent = self:getTension()
    self.current = self:getTension()

    self.change = 0
    self.changetimer = 15

    self.parallax_y = 0

    self.animating_in = not dont_animate
    self.animation_timer = 0

    self.tension_preview_timer = 0
    self.tension_preview = 0

    self.shown = false
    self.maxed = false

    self.timer = self:addChild(Timer())
end

-- =========================================================
-- VISIBILITY
-- =========================================================

function TensionBar:show()
    if not self.shown then
        self:resetPhysics()

        self.shown = true
        self.animating_in = true
        self.animation_timer = 0
    end
end

function TensionBar:hide()
    if self.shown then
        self.animating_in = false
        self.shown = false

        self.physics.speed_x = -10
        self.physics.friction = -0.4
    end
end

-- =========================================================
-- FLASH
-- =========================================================

function TensionBar:flash()
    if self.current_flash == nil
    or self.current_flash:isRemoved() then

        self.current_flash =
            self:addChild(
                TensionBarGlow()
            )
    else
        self.current_flash.current_alpha = 1
        self.current_flash.apparent =
            self:getTension()
    end

    local bar_x = self:getBarX()
    local bar_y = self:getBarY()
    local bar_width = self:getBarWidth()

    for _ = 1, love.math.random(3, 5) do
        local x =
            bar_x +
            love.math.random(0, bar_width)

        local y =
            bar_y +
            love.math.random(
                -3,
                BAR_HEIGHT + 3
            )

        local sparkle =
            self.parent:addChild(
                Sprite(
                    "effects/spare/star",
                    x,
                    y
                )
            )

        sparkle.layer = 999
        sparkle.alpha = 1

        local duration =
            10 +
            love.math.random(0, 5)

        sparkle:play(
            1 / (30 * (5 / duration)),
            true
        )

        sparkle.physics.speed =
            3 +
            love.math.random() * 3

        sparkle.physics.direction =
            -math.rad(90)

        sparkle:fadeTo(
            0.25,
            duration / 30
        )

        self.timer:tween(
            duration / 30,
            sparkle.physics,
            {speed = 0},
            "linear"
        )

        self.timer:after(
            duration / 30,
            function()
                sparkle:remove()
            end
        )
    end
end

-- =========================================================
-- DEBUG
-- =========================================================

function TensionBar:getDebugInfo()
    local info =
        super.getDebugInfo(self)

    local tension =
        self:getTension()

    local max_tension =
        self:getMaxTension()

    local percentage =
        self:getPercentage() * 100

    table.insert(
        info,
        "Tension: " ..
        MathUtils.round(tension) ..
        "/" ..
        MathUtils.round(max_tension)
    )

    table.insert(
        info,
        "Percentage: " ..
        string.format(
            "%.1f",
            percentage
        ) ..
        "%"
    )

    return info
end

-- =========================================================
-- COMPATIBILITY
-- =========================================================

function TensionBar:hasReducedTension()
    return false
end

-- Generic percentage conversion.
-- NEVER converts to 250.
function TensionBar:getPercentageFor(variable)
    return MathUtils.clamp(
        variable / self:getMaxTension(),
        0,
        1
    )
end

function TensionBar:setTensionPreview(amount)
    self.tension_preview =
        MathUtils.clamp(
            amount or 0,
            0,
            self:getMaxTension()
        )

    self.tension_preview_timer = 0
end

-- =========================================================
-- SLIDE IN
-- =========================================================

function TensionBar:processSlideIn()
    if self.animating_in then
        self.animation_timer =
            self.animation_timer +
            DTMULT

        if self.animation_timer > 12 then
            self.animation_timer = 12
            self.animating_in = false
        end

        self.y =
            Ease.outCubic(
                self.animation_timer,
                -50,
                0,
                12
            )
    else
        self.y = 0
    end
end

-- =========================================================
-- TP SMOOTHING
-- =========================================================

function TensionBar:processTension()
    local max_tension =
        self:getMaxTension()

    local target =
        self:getTension()

    -- Hard synchronization if something changed
    -- outside normal battle flow.
    if self.apparent < 0
    or self.apparent > max_tension then
        self.apparent = target
    end

    -- Smooth apparent value.
    local apparent_difference =
        target - self.apparent

    if math.abs(apparent_difference) < 20 then
        self.apparent = target
    else
        local speed =
            math.max(
                20,
                math.abs(apparent_difference) * 0.18
            )

        if apparent_difference > 0 then
            self.apparent =
                self.apparent +
                speed * DTMULT
        else
            self.apparent =
                self.apparent -
                speed * DTMULT
        end
    end

    self.apparent =
        MathUtils.clamp(
            self.apparent,
            0,
            max_tension
        )

    -- Smooth displayed value.
    local difference =
        self.apparent - self.current

    if math.abs(difference) < 2 then
        self.current = self.apparent
    else
        local speed = 2

        if math.abs(difference) > 10 then
            speed = 4
        end

        if math.abs(difference) > 25 then
            speed = 6
        end

        if math.abs(difference) > 50 then
            speed = 10
        end

        if math.abs(difference) > 100 then
            speed = 16
        end

        if difference > 0 then
            self.current =
                self.current +
                speed * DTMULT
        else
            self.current =
                self.current -
                speed * DTMULT
        end
    end

    self.current =
        MathUtils.clamp(
            self.current,
            0,
            max_tension
        )

    if math.abs(
        self.current - self.apparent
    ) < 2 then
        self.current = self.apparent
    end

    self.maxed =
        target >= max_tension

    if self.tension_preview > 0 then
        self.tension_preview_timer =
            self.tension_preview_timer +
            DTMULT
    end
end

function TensionBar:update()
    self:processSlideIn()
    self:processTension()

    super.update(self)
end

-- =========================================================
-- TEXT
-- =========================================================

function TensionBar:drawText()
    local tension =
        math.floor(
            self:getTension() + 0.5
        )

    local max_tension =
        self:getMaxTension()

    local percentage =
        self:getPercentage() * 100

    self.maxed =
        tension >= max_tension

    love.graphics.setFont(self.font)

    local bar_width =
        self:getBarWidth()

    local value_text =
        tostring(tension) ..
        " / " ..
        tostring(max_tension)

    local percentage_text =
        string.format(
            "%.1f%%",
            percentage
        )

    Draw.setColor(
        1,
        1,
        1,
        1
    )

    local value_width =
        self.font:getWidth(value_text)

    local value_x =
        self:getBarX() +
        (bar_width / 2) -
        (value_width / 2)

    local text_y =
        self:getBarY() +
        BAR_HEIGHT +
        TEXT_GAP

    love.graphics.print(
        value_text,
        value_x,
        text_y
    )

    if not self.maxed then
        local percent_width =
            self.font:getWidth(
                percentage_text
            )

        local percent_x =
            self:getBarX() +
            (bar_width / 2) -
            (percent_width / 2)

        love.graphics.print(
            percentage_text,
            percent_x,
            text_y + 18
        )
    else
        local max_x =
            self:getBarX() +
            (bar_width / 2) +
            70

        local max_y =
            text_y - 4

        Draw.setColor(COLOR_KRIS)

        love.graphics.print(
            "M",
            max_x,
            max_y
        )

        Draw.setColor(COLOR_SUSIE)

        love.graphics.print(
            "A",
            max_x + 8,
            max_y + 7
        )

        Draw.setColor(COLOR_RALSEI)

        love.graphics.print(
            "X",
            max_x + 16,
            max_y + 14
        )
    end
end

-- =========================================================
-- BACKGROUND
-- =========================================================

-- Палитры по сторонам: A — голубой→розовый→зелёный, B — синий→чёрный,
-- C — зелёный→чёрный. stops: позиция 0..1 вдоль шкалы.
local PALETTES = {
    A = { accent = {0.55, 0.95, 1.0}, back = {0.01, 0.02, 0.04},
          stops = { {0, {0.15, 0.85, 1.0}}, {0.45, {1.0, 0.38, 0.78}}, {0.72, {1.0, 0.75, 0.5}}, {1, {0.35, 1.0, 0.5}} } },
    B = { accent = {0.35, 0.55, 1.0}, back = {0.0, 0.0, 0.03},
          stops = { {0, {0.25, 0.5, 1.0}}, {0.5, {0.08, 0.18, 0.55}}, {1, {0.0, 0.005, 0.03}} } },
    C = { accent = {0.35, 1.0, 0.5}, back = {0.0, 0.02, 0.0},
          stops = { {0, {0.3, 1.0, 0.45}}, {0.5, {0.06, 0.4, 0.18}}, {1, {0.0, 0.02, 0.005}} } },
}
local SLANT = 10   -- наклон «клинка»

local function getPalette()
    if Kristal.Config.sideC then return PALETTES.C end
    if Kristal.Config.sideB then return PALETTES.B end
    return PALETTES.A
end

local function rgb2hsv(r, g, b)
    local mx, mn = math.max(r, g, b), math.min(r, g, b)
    local d = mx - mn
    local h = 0
    if d > 1e-6 then
        if mx == r then h = ((g - b) / d) % 6
        elseif mx == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
        h = h / 6
    end
    return h, (mx > 0) and d / mx or 0, mx
end

local function hsv2rgb(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then return v, t, p elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v else return v, p, q end
end

-- Переход по RGB со ступеньками-промежуточными цветами: розовый → зелёный идёт
-- через тёплый персиковый, а не через серый.
local function sampleStops(stops, t)
    t = MathUtils.clamp(t, 0, 1)
    for i = 1, #stops - 1 do
        local t0, c0 = stops[i][1], stops[i][2]
        local t1, c1 = stops[i + 1][1], stops[i + 1][2]
        if t <= t1 then
            local k = (t - t0) / math.max(1e-6, t1 - t0)
            k = k * k * (3 - 2 * k)
            return c0[1] + (c1[1] - c0[1]) * k, c0[2] + (c1[2] - c0[2]) * k, c0[3] + (c1[3] - c0[3]) * k
        end
    end
    local c = stops[#stops][2]
    return c[1], c[2], c[3]
end

-- параллелограмм (наклонённый вправо), x..x+w, y..y+h
local function slantPoly(mode, x, y, w, h, sl)
    love.graphics.polygon(mode, x, y + h, x + w, y + h, x + w + sl, y, x + sl, y)
end

-- Переливание: чем больше TP, тем чаще полосы света и тем быстрее они бегут.
local old_update = TensionBar.update
function TensionBar:update()
    old_update(self)
    local p = MathUtils.clamp(self.current / self:getMaxTension(), 0, 1)
    local speed = 0.12 + 3.2 * p * p          -- циклов в секунду
    self.shimmer_phase = ((self.shimmer_phase or 0) + DT * speed) % 1
end

function TensionBar:drawBack()
    local x, y, w = self:getBarX(), self:getBarY(), self:getBarWidth()
    local pal = getPalette()
    local ac = pal.accent
    local h = BAR_HEIGHT

    -- мягкое свечение контура
    Draw.setColor(ac[1], ac[2], ac[3], 0.18)
    slantPoly("fill", x - 4, y - 4, w + 8, h + 8, SLANT)
    -- контур и подложка
    Draw.setColor(ac[1], ac[2], ac[3], 1)
    slantPoly("fill", x - 2, y - 2, w + 4, h + 4, SLANT)
    Draw.setColor(pal.back[1], pal.back[2], pal.back[3], 1)
    slantPoly("fill", x, y, w, h, SLANT)

    -- риски через каждые 10% (как деления клинка)
    Draw.setColor(ac[1], ac[2], ac[3], 0.22)
    love.graphics.setLineWidth(1)
    for i = 1, 9 do
        local tx = x + w * i / 10
        love.graphics.line(tx, y + h, tx + SLANT, y)
    end

    -- надпись «TP» слева от шкалы (цвет стороны, с тёмной обводкой)
    love.graphics.setFont(self.font)
    local sc = 1.6
    local ty = y + (h - self.font:getHeight() * sc) / 2
    local tx = x - 6 - self.font:getWidth("TP") * sc
    Draw.setColor(0, 0, 0, 1)
    for _, o in ipairs({ {-1.5, 0}, {1.5, 0}, {0, -1.5}, {0, 1.5} }) do
        love.graphics.print("TP", tx + o[1], ty + o[2], 0, sc, sc)
    end
    Draw.setColor(ac[1], ac[2], ac[3], 1)
    love.graphics.print("TP", tx, ty, 0, sc, sc)
    Draw.setColor(1, 1, 1, 1)
end

-- =========================================================
-- COLORS
-- =========================================================

function TensionBar:getFillColor()
    return COLOR_FILL
end

function TensionBar:getFillMaxColor()
    return COLOR_FILL_MAX
end

-- =========================================================
-- FILL
-- =========================================================

function TensionBar:drawFill()
    local x, y, width = self:getBarX(), self:getBarY(), self:getBarWidth()
    local h = BAR_HEIGHT
    local pal = getPalette()
    local ac = pal.accent
    local max_t = self:getMaxTension()
    local percentage = MathUtils.clamp(self.current / max_t, 0, 1)
    local fill_width = width * percentage
    local now = love.timer.getTime()

    -- предпросмотр траты TP: пульсирующий хвост цвета стороны
    if self.tension_preview > 0 then
        local pw = width * MathUtils.clamp(self.tension_preview, 0, max_t) / max_t
        local extra = math.min(pw - fill_width, width - fill_width)
        if extra > 0 then
            local pulse = math.abs(math.sin(self.tension_preview_timer / 8) * 0.5) + 0.2
            Draw.setColor(ac[1], ac[2], ac[3], pulse)
            slantPoly("fill", x + fill_width, y, extra, h, SLANT)
        end
    end

    if fill_width <= 0 then
        Draw.setColor(1, 1, 1, 1)
        return
    end

    -- градиентная заливка полосками, скошенными как клинок
    local step = 2
    local px = 0
    while px < fill_width do
        local sw = math.min(step, fill_width - px)
        local r, g, b = sampleStops(pal.stops, (px + sw / 2) / math.max(fill_width, 90))
        local boost = self.maxed and (0.15 + 0.15 * math.sin(now * 10)) or 0
        -- бегущая полоса света цветом шкалы; период короче при большем TP
        local period = 170 - 70 * percentage
        local ph = ((px + sw / 2) / period - (self.shimmer_phase or 0) * 1) % 1
        local sheen = (0.5 - 0.5 * math.cos(ph * 2 * math.pi)) ^ 2 * (0.4 + 0.4 * percentage)
        -- полоска — насыщенный яркий оттенок шкалы (не белый): цвет доводится до полной яркости
        local tr, tg, tb = sampleStops(pal.stops, math.min(1, (px + sw / 2) / width * 0.6 + 0.0))
        local mx = math.max(tr, tg, tb, 0.2)
        local ar, ag, ab = ac[1], ac[2], ac[3]
        tr, tg, tb = (tr / mx) * 0.6 + ar * 0.4, (tg / mx) * 0.6 + ag * 0.4, (tb / mx) * 0.6 + ab * 0.4
        local k = math.min(1, sheen * 1.6)
        r, g, b = r + (tr - r) * k, g + (tg - g) * k, b + (tb - b) * k
        Draw.setColor(math.min(1, r + boost), math.min(1, g + boost), math.min(1, b + boost), 1)
        slantPoly("fill", x + px, y, sw + 1, h, SLANT)
        px = px + step
    end

    -- блик по верху
    Draw.setColor(1, 1, 1, 0.3)
    love.graphics.polygon("fill", x + SLANT * 0.8, y + 3, x + fill_width + SLANT * 0.8, y + 3,
        x + fill_width + SLANT * 0.9, y, x + SLANT, y)

    -- кончик клинка: яркий скошенный штрих на конце заливки
    if fill_width < width then
        Draw.setColor(1, 1, 1, 0.95)
        love.graphics.setLineWidth(2)
        love.graphics.line(x + fill_width, y + h, x + fill_width + SLANT, y)
        Draw.setColor(ac[1], ac[2], ac[3], 0.35)
        love.graphics.setLineWidth(6)
        love.graphics.line(x + fill_width, y + h, x + fill_width + SLANT, y)
        love.graphics.setLineWidth(1)
    end
    Draw.setColor(1, 1, 1, 1)
end

-- =========================================================
-- DRAW
-- =========================================================

function TensionBar:draw()
    self:drawBack()
    self:drawFill()
    self:drawText()

    super.draw(self)
end

return TensionBar