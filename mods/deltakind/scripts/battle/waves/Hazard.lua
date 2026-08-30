local Hazard, super = Class(Wave)

function Hazard:onStart()
    self.time = 12
    local enemy = self.attacker or Game.battle:getEnemyBattler("kyle")
    
    self.timer:script(function(wait)
        while self.time > 0 do
            -- Спавним предупреждающую линию (горизонтальную)
            local y = math.random(Game.battle.arena.top, Game.battle.arena.bottom)
            
            -- Рисуем метку (Rectangle)
            -- ПРИМЕЧАНИЕ: раньше это добавлялось напрямую через
            -- Game.battle:addChild(warn), в обход системы
            -- self.objects волны — из-за этого штатная очистка
            -- Wave:clear() (которая срабатывает, если волна
            -- закончится/прервётся раньше, чем дойдёт до
            -- warn:remove() ниже) не знала об этом прямоугольнике
            -- и не могла его убрать. Отсюда баг "красная рамка
            -- остаётся после атаки". Wave:spawnObject() делает
            -- то же добавление в Game.battle, но ещё и
            -- регистрирует объект в self.objects, так что теперь
            -- он гарантированно уберётся при завершении волны,
            -- даже если она прервётся посреди wait().
            local warn = Rectangle(Game.battle.arena.left, y - 2, Game.battle.arena.width, 4)
            warn.color = {1, 0, 0}
            warn.alpha = 0.5
            self:spawnObject(warn)
            
            wait(0.6) -- Время на реакцию
            
            -- Спавним пулю, которая пролетает по этой линии
            Assets.playSound("shatter", 0.4, 1.5)
            warn:remove()
            
            local b = self:spawnBullet("bullets/smallbullet", Game.battle.arena.left - 20, y)
            if b then
                b.physics.speed = 12
                b.damage = (enemy and enemy.attack or 10)
            end
            
            wait(0.4)
        end
    end)
end

return Hazard