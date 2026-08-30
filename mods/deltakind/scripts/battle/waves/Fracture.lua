local Fracture, super = Class(Wave)

function Fracture:onStart()
    self.time = 15
    local enemy = self.attacker or Game.battle:getEnemyBattler("kyle")
    local is_p2 = (enemy and enemy.phase == 2)

    -- БЕЗОПАСНАЯ ЧИСТКА: Проверяем, существует ли таблица вообще
    if Game.battle.bullets then
        for _, bullet in ipairs(Game.battle.bullets) do
            -- Убираем только те объекты, которые могут растягиваться в "стену"
            if bullet.obj_name == "arenahazard" then
                bullet:remove()
            end
        end
    end

    self.timer:script(function(wait)
        while self.time > 0 do
            local sides_count = is_p2 and math.random(3, 4) or math.random(2, 4)
            
            local sides = {1, 2, 3, 4}
            Utils.shuffle(sides)
            
            for i = 1, sides_count do
                local side = sides[i]
                local spawn_x, spawn_y
                
                if side == 1 then -- Верх
                    spawn_x, spawn_y = math.random(Game.battle.arena.left, Game.battle.arena.right), Game.battle.arena.top - 60
                elseif side == 2 then -- Право
                    spawn_x, spawn_y = Game.battle.arena.right + 60, math.random(Game.battle.arena.top, Game.battle.arena.bottom)
                elseif side == 3 then -- Низ
                    spawn_x, spawn_y = math.random(Game.battle.arena.left, Game.battle.arena.right), Game.battle.arena.bottom + 60
                else -- Лево
                    spawn_x, spawn_y = Game.battle.arena.left - 60, math.random(Game.battle.arena.top, Game.battle.arena.bottom)
                end

                local b = self:spawnBullet("bullets/smallbullet", spawn_x, spawn_y)
                if b then
                    b.damage = (enemy and enemy.attack or 10)
                    
                    local angle = Utils.angle(b.x, b.y, Game.battle.soul.x, Game.battle.soul.y)
                    b.physics.direction = angle
                    b.physics.speed = is_p2 and 10 or 7
                    
                    -- Масштабирование через ТАЙМЕР ВОЛНЫ
                    b:setScale(0, 0)
                    self.timer:tween(0.15, b, {scale_x = 1, scale_y = 1})
                    
                    if is_p2 then b.color = {1, 0.8, 0.8} end
                end
                
                wait(0.05) 
            end

            wait(is_p2 and 0.2 or 0.4)
        end
    end)
end

return Fracture