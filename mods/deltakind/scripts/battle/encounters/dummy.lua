local Dummy, super = Class(Encounter)

function Dummy:init()
    super.init(self)

    self.text =
        "* Воздух тяжелеет. Рыцарь Пустоты преграждает вам путь. Возможно единственное что вы можете делать...это ДЕЙСТВОВАТЬ."

    -- Стартовый трек выбирается по режиму.
    -- Battle.lua hook переключает на Phase 2 автоматически.
    if Kristal.Config.sideB then
        self.music = "BLACK_KNIFE_SideB_phase1"
    else
        self.music = "BLACK_KNIFE_SideA_phase1"
    end
    self.background = true

    -------------------------------------------------------
    -- КАЙЛ
    -------------------------------------------------------

    local kyle =
        self:addEnemy("kyle")

    -------------------------------------------------------
    -- ПОЗИЦИЯ КАЙЛА В БОЮ
    -------------------------------------------------------

    kyle.x = 520
    kyle.y = 202

    -------------------------------------------------------
    -- ПОЗИЦИИ ПАРТИИ
    -------------------------------------------------------

    self.party_positions = {
        {280, 70},
        {240, 160},
        {170, 250}
    }
end

function Dummy:createBackground()
    return Game.battle:addChild(KnightBackground())
end

return Dummy
