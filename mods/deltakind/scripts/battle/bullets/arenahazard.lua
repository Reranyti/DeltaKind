local ArenaHazard, super = Class(Bullet)

function ArenaHazard:init(x, y, rot)
    super.init(self, x, y, "bullets/arenahazard")

    -- Центр сверху для вращения
    self:setOrigin(0.5, 0)

    -- Устанавливаем хитбокс относительно Origin. 
    -- Если Origin (0.5, 0), то x должен быть -width/2
    self:setHitbox(-self.width/2, 0, self.width, self.height)

    self.rotation = rot or 0
    self.destroy_on_hit = false
end

return ArenaHazard