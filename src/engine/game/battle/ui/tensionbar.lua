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

local SCREEN_MARGIN = 36
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

function TensionBar:drawBack()
    local x = self:getBarX()
    local y = self:getBarY()
    local width = self:getBarWidth()

    Draw.setColor(COLOR_BORDER)

    love.graphics.rectangle(
        "fill",
        x - 3,
        y - 3,
        width + 6,
        BAR_HEIGHT + 6
    )

    Draw.setColor(COLOR_BORDER_INNER)

    love.graphics.rectangle(
        "fill",
        x - 1,
        y - 1,
        width + 2,
        BAR_HEIGHT + 2
    )

    Draw.setColor(COLOR_BACK)

    love.graphics.rectangle(
        "fill",
        x,
        y,
        width,
        BAR_HEIGHT
    )
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
    local x = self:getBarX()
    local y = self:getBarY()
    local width = self:getBarWidth()

    -- REAL 750-point percentage.
    local percentage =
        MathUtils.clamp(
            self.current / self:getMaxTension(),
            0,
            1
        )

    local fill_width =
        width * percentage

    if fill_width <= 0 then
        return
    end

    local color =
        self:getFillColor()

    if self.maxed then
        color =
            self:getFillMaxColor()
    end

    Draw.setColor(color)

    love.graphics.rectangle(
        "fill",
        x,
        y,
        fill_width,
        BAR_HEIGHT
    )

    Draw.setColor(
        COLOR_HIGHLIGHT
    )

    love.graphics.rectangle(
        "fill",
        x,
        y,
        fill_width,
        2
    )

    -- =====================================================
    -- PREVIEW
    -- =====================================================

    if self.tension_preview > 0 then
        local preview_target =
            MathUtils.clamp(
                self.tension_preview,
                0,
                self:getMaxTension()
            )

        local preview_percentage =
            preview_target /
            self:getMaxTension()

        local preview_width =
            width *
            preview_percentage

        local additional_width =
            preview_width -
            fill_width

        if additional_width > 0 then
            local pulse =
                math.abs(
                    math.sin(
                        self.tension_preview_timer / 8
                    ) * 0.5
                ) + 0.2

            Draw.setColor(
                1,
                0.08,
                0.08,
                pulse
            )

            love.graphics.rectangle(
                "fill",
                x + fill_width,
                y,
                math.min(
                    additional_width,
                    width - fill_width
                ),
                BAR_HEIGHT
            )
        end
    end

    -- End marker.
    if fill_width > 0
    and fill_width < width then

        Draw.setColor(
            1,
            0.28,
            0.28,
            1
        )

        love.graphics.rectangle(
            "fill",
            x + fill_width - 1,
            y,
            2,
            BAR_HEIGHT
        )
    end
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