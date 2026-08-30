--- DeltaKind 750-point Tension Bar glow.
---
--- Uses the same 750 TP system as TensionBar.
---@class TensionBarGlow : Object
---@field parent TensionBar?
---@field current_alpha number
---@field apparent number
local TensionBarGlow, super = Class(Object)

-- =========================================================
-- SETTINGS
-- =========================================================

local DELTAKIND_MAX_TENSION = 750
local GLOW_HEIGHT = 18

local GLOW_OUTER_COLOR = {
    0.55, 0.005, 0.005, 1
}

local GLOW_COLOR = {
    1.0, 0.04, 0.04, 1
}

local GLOW_EDGE_COLOR = {
    1.0, 0.12, 0.12, 1
}

-- =========================================================
-- HELPERS
-- =========================================================

function TensionBarGlow:getMaxTension()
    return DELTAKIND_MAX_TENSION
end

function TensionBarGlow:getTension()
    return MathUtils.clamp(
        Game:getTension(),
        0,
        self:getMaxTension()
    )
end

-- =========================================================
-- INITIALIZATION
-- =========================================================

function TensionBarGlow:init(x, y)
    super.init(
        self,
        x,
        y
    )

    self.apparent =
        self:getTension()

    self.current_alpha = 1
end

-- =========================================================
-- UPDATE
-- =========================================================

function TensionBarGlow:update()
    super.update(self)

    local target =
        self:getTension()

    local difference =
        target - self.apparent

    if math.abs(difference) < 10 then
        self.apparent = target
    elseif difference > 0 then
        self.apparent =
            self.apparent +
            math.min(
                difference,
                20 * DTMULT
            )
    else
        self.apparent =
            self.apparent -
            math.min(
                math.abs(difference),
                20 * DTMULT
            )
    end

    self.apparent =
        MathUtils.clamp(
            self.apparent,
            0,
            self:getMaxTension()
        )

    self.current_alpha =
        MathUtils.approach(
            self.current_alpha,
            0,
            0.15 * DTMULT
        )

    if self.current_alpha <= 0 then
        self:remove()
    end
end

-- =========================================================
-- DRAW
-- =========================================================

function TensionBarGlow:draw()
    if not self.parent then
        return
    end

    local max_tension =
        self:getMaxTension()

    local tension =
        MathUtils.clamp(
            self.apparent,
            0,
            max_tension
        )

    -- 750-point system.
    local percentage =
        tension / max_tension

    local bar_width =
        self.parent:getBarWidth()

    local bar_x =
        self.parent:getBarX()

    local bar_y =
        self.parent:getBarY()

    local fill_width =
        bar_width * percentage

    if fill_width <= 0 then
        return
    end

    love.graphics.setBlendMode("add")

    -- =====================================================
    -- OUTER GLOW
    -- =====================================================

    Draw.setColor(
        GLOW_OUTER_COLOR[1],
        GLOW_OUTER_COLOR[2],
        GLOW_OUTER_COLOR[3],
        0.20 * self.current_alpha
    )

    love.graphics.rectangle(
        "fill",
        bar_x - 4,
        bar_y - 4,
        fill_width + 8,
        GLOW_HEIGHT + 8
    )

    -- =====================================================
    -- MAIN GLOW
    -- =====================================================

    Draw.setColor(
        GLOW_COLOR[1],
        GLOW_COLOR[2],
        GLOW_COLOR[3],
        0.45 * self.current_alpha
    )

    love.graphics.rectangle(
        "fill",
        bar_x - 2,
        bar_y - 2,
        fill_width + 4,
        GLOW_HEIGHT + 4
    )

    -- =====================================================
    -- EDGE
    -- =====================================================

    Draw.setColor(
        GLOW_EDGE_COLOR[1],
        GLOW_EDGE_COLOR[2],
        GLOW_EDGE_COLOR[3],
        0.80 * self.current_alpha
    )

    love.graphics.rectangle(
        "fill",
        bar_x + fill_width - 2,
        bar_y - 2,
        4,
        GLOW_HEIGHT + 4
    )

    love.graphics.setBlendMode("alpha")

    super.draw(self)
end

return TensionBarGlow