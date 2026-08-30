-----------------------------------------------------------
-- YELLOW SOUL — режим стрельбы.
--
-- Движение как у обычной души. Кнопка "confirm" выпускает
-- YellowShot вверх, который уничтожает вражеские пули при
-- касании. Спрайт визуально перевёрнут (setScale по Y = -1).
-----------------------------------------------------------

local YellowSoul, super = Class(Soul)

function YellowSoul:init(x, y)
    super.init(self, x, y, {1, 0.9, 0.1})

    self:setColor(1, 0.9, 0.1)

    self.sprite:setScale(1, -1)

    self.shot_cooldown = 0
    self.shot_cooldown_time = 0.35
end

function YellowSoul:doMovement()
    super.doMovement(self)

    if self.shot_cooldown > 0 then
        self.shot_cooldown = self.shot_cooldown - DT
    end

    if Input.pressed("confirm") and self.shot_cooldown <= 0 then
        Assets.playSound("snd_laz_c", 0.7, 1.2)

        local shot = YellowShot(self.x, self.y - self.height / 2)
        self.parent:addChild(shot)

        self.shot_cooldown = self.shot_cooldown_time
    end
end

return YellowSoul
