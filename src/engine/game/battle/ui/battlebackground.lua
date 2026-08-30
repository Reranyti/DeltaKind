--- The battle background object.
---
---@class BattleBackground : Object
---@field depth_texture love.Texture
---@field depth_center_x number
---@field depth_center_y number
---@field depth_layers table
---@field depth_spawn_timer number
---@field depth_spawn_interval number
---@field depth_speed number
---@field private fading_out boolean
---
---@overload fun() : BattleBackground
local BattleBackground, super = Class(Object)

function BattleBackground:init()
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self.debug_select = false
    self.layer = BATTLE_LAYERS["background"]

    -- =========================================================
    -- DEPTH
    -- =========================================================

    -- Реальный файл:
    -- assets/sprites/ui/battle/depths.png
    self.depth_texture = Assets.getTexture("ui/battle/depths")

    self.depth_center_x = SCREEN_WIDTH / 2
    self.depth_center_y = SCREEN_HEIGHT / 2

    if self.depth_texture then
        self.depth_texture:setFilter("linear", "linear")
    end

    -- =========================================================
    -- ORIGINAL DEPTH INSTANCE SYSTEM
    -- =========================================================
    --
    -- В оригинале новый DEVICE_OBACK_4 появляется каждые
    -- 20 кадров.
    --
    -- Каждый экземпляр:
    --   xstretch = 1
    --   ystretch = 1
    --   растёт на OBSPEED
    --   после ystretch > 2 начинает исчезать
    --   после o_insurance >= 0.5 уничтожается
    --
    -- Так как depths.png уже является ПОЛНЫМ собранным
    -- изображением, четыре зеркальных draw_background_ext
    -- нам здесь не нужны.
    -- =========================================================

    self.depth_layers = {}

    self.depth_spawn_timer = 0
    self.depth_spawn_interval = 20

    -- DEVICE_CONTACT обычно переопределяет это значение:
    --
    -- OBSPEED = 0.01 * OBM
    --
    -- Для обычного состояния OBM = 1:
    self.depth_speed = 0.01

    self.alpha = 0
    self.fading_out = false

    self:setParallax(0, 0)
end

function BattleBackground:createDepthLayer()
    local layer = {
        -- Оригинальные значения DEVICE_OBACK_4.
        siner = 0,
        alpha = 0.2,

        xstretch = 1,
        ystretch = 1,

        o_insurance = 0,
        b_insurance = -0.2,

        OBSPEED = self.depth_speed,

        alive = true
    }

    table.insert(self.depth_layers, layer)
end

function BattleBackground:updateDepthLayer(layer)
    if not layer.alive then
        return
    end

    -- =========================================================
    -- ORIGINAL STEP
    -- =========================================================

    layer.siner = layer.siner + 1

    if layer.OBSPEED > 0 then
        layer.alpha =
            math.sin(layer.siner / 34) * 0.2
    end

    layer.xstretch =
        layer.xstretch + layer.OBSPEED

    layer.ystretch =
        layer.ystretch + layer.OBSPEED

    if layer.b_insurance < 0 then
        layer.b_insurance =
            layer.b_insurance + 0.01
    end

    -- =========================================================
    -- ORIGINAL FADE / DESTROY
    -- =========================================================

    if layer.ystretch > 2 then
        layer.o_insurance =
            layer.o_insurance + 0.01

        if layer.o_insurance >= 0.5 then
            layer.alive = false
        end
    end
end

function BattleBackground:update()
    super.update(self)

    -- =========================================================
    -- SPAWN NEW DEPTH LAYER
    -- =========================================================

    self.depth_spawn_timer =
        self.depth_spawn_timer + DTMULT

    while self.depth_spawn_timer >= self.depth_spawn_interval do
        self.depth_spawn_timer =
            self.depth_spawn_timer - self.depth_spawn_interval

        self:createDepthLayer()
    end

    -- =========================================================
    -- UPDATE EXISTING LAYERS
    -- =========================================================

    for i = #self.depth_layers, 1, -1 do
        local layer = self.depth_layers[i]

        self:updateDepthLayer(layer)

        if not layer.alive then
            table.remove(self.depth_layers, i)
        end
    end

    -- =========================================================
    -- BATTLE BACKGROUND FADE
    -- =========================================================

    if not self.fading_out then
        self.alpha = MathUtils.approach(
            self.alpha,
            1,
            0.1 * DTMULT
        )
    else
        self.alpha = MathUtils.approach(
            self.alpha,
            0,
            0.1 * DTMULT
        )

        if self.alpha <= 0 then
            self:remove()
        end
    end
end

function BattleBackground:getLayerAlpha(layer)
    return (
        (0.2 + layer.alpha)
        - layer.o_insurance
    )
    + layer.b_insurance
end

function BattleBackground:drawDepthLayer(layer, alpha)
    if not self.depth_texture or not layer.alive then
        return
    end

    local width = self.depth_texture:getWidth()
    local height = self.depth_texture:getHeight()

    -- =========================================================
    -- FULL DEPTH SPRITE
    -- =========================================================
    --
    -- depths.png уже содержит полный собранный фон.
    --
    -- Поэтому вместо оригинальных:
    --
    --   +x / +y
    --   -x / +y
    --   -x / -y
    --   +x / -y
    --
    -- рисуем ОДИН полный sprite по центру.
    --
    -- Оригинальные xstretch/ystretch:
    --
    --   1 -> 2 -> 3 -> ...
    --
    -- соответствуют последовательному увеличению.
    --
    -- Но поскольку твой asset уже полный, начальный
    -- коэффициент берём из самого слоя, а не умножаем
    -- его ещё раз на 2.
    -- =========================================================

    local base_scale = math.max(
        SCREEN_WIDTH / width,
        SCREEN_HEIGHT / height
    )

    -- В оригинале слой начинает с xstretch = 1.
    -- Поэтому фактическая относительная глубина здесь:
    --
    --   1.0 -> 1.01 -> 1.02 -> ...
    --
    local scale = base_scale * layer.xstretch

    Draw.setColor(
        1,
        1,
        1,
        alpha
    )

    Draw.draw(
        self.depth_texture,
        self.depth_center_x,
        self.depth_center_y,
        0,
        scale,
        scale,
        width / 2,
        height / 2
    )
end

--- Returns whether the battle background is currently fading out or not.
---@return boolean
function BattleBackground:isFading()
    return self.fading_out
end

--- Request the battle background to fade out.
function BattleBackground:fadeOut()
    self.fading_out = true
end

function BattleBackground:drawBackground()
    -- =========================================================
    -- BLACK BASE
    -- =========================================================

    Draw.setColor(
        0,
        0,
        0,
        self.alpha
    )

    Draw.rectangle(
        "fill",
        -10,
        -10,
        SCREEN_WIDTH + 20,
        SCREEN_HEIGHT + 20
    )

    -- =========================================================
    -- ORIGINAL BASE DEPTH
    -- =========================================================
    --
    -- Сначала обычный depth.
    -- =========================================================

    if self.depth_texture then
        local width = self.depth_texture:getWidth()
        local height = self.depth_texture:getHeight()

        local base_scale = math.max(
            SCREEN_WIDTH / width,
            SCREEN_HEIGHT / height
        )

        Draw.setColor(
            1,
            1,
            1,
            self.alpha
        )

        Draw.draw(
            self.depth_texture,
            self.depth_center_x,
            self.depth_center_y,
            0,
            base_scale,
            base_scale,
            width / 2,
            height / 2
        )
    end

    -- =========================================================
    -- GROWING DEPTH LAYERS
    -- =========================================================
    --
    -- Старые слои находятся поверх базового depth.
    --
    -- Чем старше слой:
    --   тем больше scale
    --   тем сильнее fade
    --
    -- Каждый layer находится в одном и том же центре.
    -- =========================================================

    for i = 1, #self.depth_layers do
        local layer = self.depth_layers[i]

        local layer_alpha =
            self:getLayerAlpha(layer)
            * self.alpha

        if layer_alpha > 0 then
            self:drawDepthLayer(
                layer,
                layer_alpha
            )
        end
    end
end

function BattleBackground:draw()
    self:drawBackground()

    Draw.setColor(
        1,
        1,
        1
    )

    super.draw(self)
end

return BattleBackground