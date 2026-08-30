local SmallBullet, super = Class(Bullet)

function SmallBullet:init(x, y, dir, speed)
    super.init(self, x, y, "bullets/smallbullet")

    -- Устанавливаем центр
    self:setOrigin(0.5, 0.5)

    -- В Kristal вместо setCollider лучше напрямую задать свойство collider
    -- Или использовать упрощенный метод setHitbox(x, y, w, h)
    self:setHitbox(-4, -4, 8, 8) 

    self.physics.direction = dir or 0
    self.physics.speed = speed or 0
end

return SmallBullet