-----------------------------------------------------------
-- BLADE CONE — конус ветра из кончика меча Рыцаря (атака «Звёзды»).
--
-- Рисуется ОРИГИНАЛЬНЫМИ текстурами из спрайт-листа (VFX «Bullet flow»):
--   fx_flow_purple — фиолетовая дымка (медленно плывёт),
--   fx_flow_lines  — розовые линии (бегут влево).
-- Вспыхивает бело-розовым в начале и в конце. Урона нет.
-----------------------------------------------------------

local BladeCone, super = Class(Bullet)

local FLASH = 0.16

function BladeCone:init(x, y, angle, length, spread, life)
    super.init(self, x, y)
    self.angle, self.length, self.spread, self.life = angle, length, spread, life or 3.5
    self.t = 0
    self.collider = nil
    self.can_graze = false
    self.remove_offscreen = false
    self:setScale(1, 1)
    self.layer = BATTLE_LAYERS["bullets"] - 5

    self.tex_smoke = Assets.getTexture("bullets/orig/fx_flow_purple")
    self.tex_lines = Assets.getTexture("bullets/orig/fx_flow_lines")
    for _, t in ipairs({ self.tex_smoke, self.tex_lines }) do
        if t then t:setWrap("repeat", "repeat") end
    end
end

function BladeCone:update()
    self.t = self.t + DT
    if self.t >= self.life then self:remove() return end
    super.update(self)
end

-- Треугольник конуса как меш с текстурой, UV считаются от мировых координат
local function coneMesh(self, tex, du, dv, spread_mul)
    local l, sp, a = self.length, self.spread * (spread_mul or 1), self.angle
    local pts = {
        { 0, 0 },
        { math.cos(a - sp) * l, math.sin(a - sp) * l },
        { math.cos(a + sp) * l, math.sin(a + sp) * l },
    }
    local verts = {}
    -- текстура плотнее (×2), чтобы дымка не растягивалась; к дальнему краю конус тает
    for i, p in ipairs(pts) do
        local wx, wy = self.x + p[1], self.y + p[2]
        local a = (i == 1) and 1 or 0.2
        verts[#verts + 1] = { p[1], p[2], wx / SCREEN_WIDTH * 2 + du, wy / SCREEN_HEIGHT * 2 + dv, 1, 1, 1, a }
    end
    local mesh = love.graphics.newMesh(verts, "fan", "stream")
    mesh:setTexture(tex)
    return mesh
end

function BladeCone:draw()
    local l = self.length
    local sp = self.spread
    local flash = (self.t < FLASH) or (self.t > self.life - FLASH * 1.4)

    if flash then
        -- вспышка: ярко у кончика, к дальнему краю тает (без жёсткого края)
        local m = love.graphics.newMesh({
            { 0, 0, 0, 0, 1, 0.85, 1, 0.85 },
            { math.cos(self.angle - sp) * l, math.sin(self.angle - sp) * l, 0, 0, 1, 0.85, 1, 0.08 },
            { math.cos(self.angle + sp) * l, math.sin(self.angle + sp) * l, 0, 0, 1, 0.85, 1, 0.08 },
        }, "fan", "stream")
        Draw.setColor(1, 1, 1, 1)
        love.graphics.draw(m)
    else
        local k = math.min(1, (self.t - FLASH) / 0.35)
        if self.tex_smoke then
            -- размытие ветра: несколько проходов с разным раствором (мягкие края) + пульс
            local pulse = 1 + 0.08 * math.sin(self.t * 7)
            local du, dv = self.t * 0.04, self.t * 0.015
            Draw.setColor(1, 1, 1, 0.16 * k)
            love.graphics.draw(coneMesh(self, self.tex_smoke, du, dv, 1.14))
            Draw.setColor(1, 1, 1, 0.22 * k)
            love.graphics.draw(coneMesh(self, self.tex_smoke, du * 1.2, dv, 1.07))
            local m = coneMesh(self, self.tex_smoke, du, dv)
            Draw.setColor(1, 1, 1, (0.45 + 0.2 * k) * pulse)
            love.graphics.draw(m)
            -- второй проход со сложением: делает дымку ярким фиолетовым, как в оригинале
            love.graphics.setBlendMode("add")
            Draw.setColor(1.0, 0.7, 1.0, 0.55 * k)
            love.graphics.draw(m)
            love.graphics.setBlendMode("alpha")
        end
        if self.tex_lines then
            Draw.setColor(1, 1, 1, 0.95)
            love.graphics.draw(coneMesh(self, self.tex_lines, self.t * 0.35, 0))
        end
    end
    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return BladeCone
