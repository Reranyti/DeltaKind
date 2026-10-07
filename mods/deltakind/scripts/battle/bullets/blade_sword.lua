-----------------------------------------------------------
-- BLADE SWORD — меч шеренги «Коридора клинков» (оригинальный спрайт
-- sword_vert из листа).
--
-- Три слоя шеренг (как в оригинале): дальние — тусклые и чуть медленнее,
-- без урона; передний — яркий, с уроном; рядом с душой краснеет.
-- row = "top" (остриём вниз) или "bottom" (остриём вверх).
-- Положение острия берётся у волны (wave:getTipY(row)).
-----------------------------------------------------------

local BladeSword, super = Class(Bullet)

local SPR_W, SPR_H = 31, 75
local SCALE = 2
local LENGTH = SPR_H * SCALE
local BLADE_W = 10
local LAYER_ALPHA = { 0.28, 0.5, 1 }
local LAYER_SPEED = { 0.82, 0.91, 1 }
local LAYER_SHIFT = 16   -- на сколько каждый дальний слой отодвинут от коридора

function BladeSword:init(x, row, speed, damage, layer)
    super.init(self, x, 0)

    self.row = row
    self.k = (row == "top") and -1 or 1 -- направление от острия к рукояти
    self.layer = layer or 3
    self.speed = (speed or 160) * LAYER_SPEED[self.layer]
    self.damage = damage or 62
    self.alert = 0
    self.tex = Assets.getTexture("bullets/orig/sword_vert")

    self.can_graze = false
    self.destroy_on_hit = false
    self.remove_offscreen = false
    self:setScale(1, 1)
    self.layer_z = self.layer
    self.layer = BATTLE_LAYERS["bullets"] - (4 - self.layer) -- дальние рисуются под передним

    -- Хитбокс только у переднего слоя: узкая полоса вдоль клинка
    if self.layer_z == 3 then
        local y0 = (self.k == -1) and -LENGTH or 0
        self.collider = Hitbox(self, -BLADE_W / 2, y0, BLADE_W, LENGTH)
    else
        self.collider = nil
    end
end

function BladeSword:update()
    self.x = self.x - self.speed * DT
    if self.wave and self.wave.getTipY then
        self.y = self.wave:getTipY(self.row) + self.k * LAYER_SHIFT * (3 - self.layer_z)
    end

    -- Краснеет, когда душа рядом по горизонтали (только передний слой)
    local soul = Game.battle and Game.battle.soul
    local near = self.layer_z == 3 and soul and math.abs(soul.x - self.x) < 46
    self.alert = MathUtils.approach(self.alert, near and 1 or 0, DT * 8)

    if self.x < -60 then
        self:remove()
        return
    end
    super.update(self)
end

function BladeSword:draw()
    local a = self.alert
    local alpha = LAYER_ALPHA[self.layer_z]
    if self.tex then
        Draw.setColor(1, 1 - 0.8 * a, 1 - 0.8 * a, alpha)
        -- острие спрайта внизу: у верхней шеренги рисуем как есть, у нижней — зеркально
        Draw.draw(self.tex, 0, 0, 0, SCALE, self.k == -1 and SCALE or -SCALE, SPR_W / 2, SPR_H)
    end
    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return BladeSword
