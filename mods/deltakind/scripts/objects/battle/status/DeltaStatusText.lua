local DeltaStatusText, super = Class(Object)

function DeltaStatusText:init(x, y, text, color)
    super.init(self, x, y)

    self.text = text
    self.color = color or COLORS.white

    self.alpha = 1
    self.life = 0.9
end

function DeltaStatusText:update()
    self.life = self.life - DT

    self.y = self.y - 18 * DT
    self.alpha = math.max(0, self.life / 0.9)

    if self.life <= 0 then
        self:remove()
        return
    end

    super.update(self)
end

function DeltaStatusText:draw()
    Draw.setColor(self.color, self.alpha)

    love.graphics.setFont(
        Assets.getFont("main")
    )

    love.graphics.printf(
        self.text,
        self.x - 50,
        self.y,
        100,
        "center"
    )

    Draw.setColor(COLORS.white)

    super.draw(self)
end

return DeltaStatusText