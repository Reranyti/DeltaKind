-----------------------------------------------------------
-- PURPLE SOUL — режим рельс (паутина).
--
-- Движение только влево/вправо. Вверх/вниз переключает
-- между фиксированными "линиями" (дорожками) по высоте.
-- Замедление фокусом ("cancel"/Shift) в этом режиме
-- отключено — как и в оригинале.
-----------------------------------------------------------

local PurpleSoul, super = Class(Soul)

function PurpleSoul:init(x, y)
    super.init(self, x, y, {0.7, 0.2, 0.9})

    self:setColor(0.7, 0.2, 0.9)

    self.lane_count = 5
    self.current_lane = math.ceil(self.lane_count / 2)

    self.allow_focus = false
end

function PurpleSoul:getLanes()
    local arena = Game.battle.arena

    if not arena then
        return {}
    end

    local margin = self.height

    local top = arena.top + margin
    local bottom = arena.bottom - margin

    local lanes = {}

    for i = 1, self.lane_count do
        local t = (self.lane_count == 1) and 0.5
            or (i - 1) / (self.lane_count - 1)

        lanes[i] = top + (bottom - top) * t
    end

    return lanes
end

function PurpleSoul:doMovement()
    local lanes = self:getLanes()

    if #lanes == 0 then
        return
    end

    -------------------------------------------------------
    -- СМЕНА ЛИНИИ
    -------------------------------------------------------

    if Input.pressed("up") and self.current_lane > 1 then
        self.current_lane = self.current_lane - 1
        Assets.playSound("ui_move")
    elseif Input.pressed("down") and self.current_lane < #lanes then
        self.current_lane = self.current_lane + 1
        Assets.playSound("ui_move")
    end

    -------------------------------------------------------
    -- ГОРИЗОНТАЛЬНОЕ ДВИЖЕНИЕ
    -------------------------------------------------------

    local move_x = 0
    if Input.down("left") then move_x = move_x - 1 end
    if Input.down("right") then move_x = move_x + 1 end

    self.moving_x = move_x
    self.moving_y = 0

    if move_x ~= 0 then
        self:move(move_x * self.speed * DTMULT, 0)
    end

    -------------------------------------------------------
    -- ПРИТЯГИВАНИЕ К ТЕКУЩЕЙ ЛИНИИ
    -------------------------------------------------------

    local target_y = lanes[self.current_lane]
    local exact_x, exact_y = self:getExactPosition(self.x, self.y)

    local new_y = MathUtils.lerp(exact_y, target_y, 0.4)

    self:setExactPosition(exact_x, new_y)
end

return PurpleSoul
