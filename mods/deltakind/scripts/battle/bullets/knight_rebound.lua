local KnightReboundBullet, super = Class(Bullet)

function KnightReboundBullet:init(x, y, is_fake, direction)
    super.init(self, x, y, "bullets/smallbullet")

    self.is_fake = is_fake or false

    -- Отскок происходит только после первого входа в арену.
    self.entered_arena = false
    self.rebounded = false

    self.physics.speed = 8
    self.physics.direction = direction or 0

    -- Цвета похожи, чтобы путать игрока.
    if self.is_fake then
        -- Лечебная.
        self:setColor(0, 1, 0)
    else
        -- Настоящая, но лаймовая.
        self:setColor(0.65, 1, 0.12)
    end
end

function KnightReboundBullet:update()
    super.update(self)

    local arena = Game.battle.arena
    if not arena then
        return
    end

    -- Сначала пуля должна физически войти в арену.
    if not self.entered_arena then
        if self.x >= arena.left and
           self.x <= arena.right and
           self.y >= arena.top and
           self.y <= arena.bottom then

            self.entered_arena = true
        end

        return
    end

    -- Только после входа в арену разрешаем отскок.
    if not self.rebounded then
        local hit_edge =
            self.x <= arena.left or
            self.x >= arena.right or
            self.y <= arena.top or
            self.y >= arena.bottom

        if hit_edge then
            -- Отскок обратно в сторону центра.
            self.physics.direction = Utils.angle(
                self.x,
                self.y,
                arena.x,
                arena.y
            )

            self.rebounded = true

            -- После отскока слегка меняем оттенок,
            -- но сохраняем визуальное сходство типов.
            if self.is_fake then
                self:setColor(0.15, 1, 0.05)
            else
                self:setColor(0.75, 1, 0.18)
            end

            Assets.playSound("bell", 0.4, 1.5)
        end
    end
end

function KnightReboundBullet:onCollide(soul)
    -- ==========================================
    -- ЗЕЛЁНАЯ:
    -- случайный персонаж +2% MAX HP
    -- ==========================================
    if self.is_fake then
        local party = Game.battle.party

        if #party > 0 then
            local target = Utils.pick(party)

            if target and target.chara then
                local max_hp = target.chara:getMaxStat("health")
                local heal_amount = math.max(
                    1,
                    math.ceil(max_hp * 0.02)
                )

                -- Может лечить даже персонажа с 0 HP.
                -- Поэтому потенциально может его поднять.
                target:heal(heal_amount)
            end
        end

        -- Не вызываем super.onCollide().
        -- Это не обычная вражеская пуля.
        self:remove()
        return
    end

    -- ==========================================
    -- ЛАЙМОВАЯ:
    -- -4% MAX HP ВСЕЙ КОМАНДЕ
    -- ==========================================
    for _, target in ipairs(Game.battle.party) do
        if target and target.chara then
            local max_hp = target.chara:getMaxStat("health")
            local damage = math.max(
                1,
                math.ceil(max_hp * 0.04)
            )

            -- exact=true:
            -- ровно заданный процент,
            -- без защиты и элементальных модификаторов.
            --
            -- "all":
            -- урон считается групповым.
            target:hurt(
                damage,
                true,
                nil,
                "all"
            )
        end
    end

    -- Не вызываем стандартную collision-обработку,
    -- иначе душа получила бы ещё один обычный hit.
    self:remove()
end

return KnightReboundBullet