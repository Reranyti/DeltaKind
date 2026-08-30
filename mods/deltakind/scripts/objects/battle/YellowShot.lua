-----------------------------------------------------------
-- YELLOW SHOT — снаряд, выпускаемый Жёлтой душой.
-- Летит вверх, уничтожает пули врага при касании.
-- Отдельный класс-файл — тот же паттерн, что и у обычных
-- Bullet-подклассов проекта (Class(Object), т.к. это снаряд
-- игрока, а не Bullet, наносящий урон душе).
-----------------------------------------------------------

local YellowShot, super = Class(Object)

function YellowShot:init(x, y)
    super.init(self, x, y)

    self.width = 4
    self.height = 10

    self.physics.direction = -math.pi / 2
    self.physics.speed = 9

    self.layer = BATTLE_LAYERS["soul"]
end

function YellowShot:draw()
    Draw.setColor(1, 0.9, 0.1)

    love.graphics.rectangle(
        "fill",
        -self.width / 2,
        -self.height / 2,
        self.width,
        self.height
    )

    super.draw(self)
end

function YellowShot:update()
    super.update(self)

    local arena = Game.battle.arena

    if arena and self.y < arena.top - 40 then
        self:remove()
        return
    end

    for _, bullet in ipairs(Game.stage:getObjects(Bullet)) do
        local bw = bullet.width or 10
        local bh = bullet.height or 10

        if bullet.parent
        and math.abs(bullet.x - self.x) < bw / 2 + self.width / 2
        and math.abs(bullet.y - self.y) < bh / 2 + self.height / 2 then

            if bullet.destroy_on_hit ~= false then
                bullet:remove()
            end

            self:remove()
            return
        end
    end
end

return YellowShot
