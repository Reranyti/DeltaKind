-- Рокочущий Рыцарь. Кадры взяты с вики Deltarune (Knight_battle_*),
-- разложены на PNG в assets/sprites/enemies/knight/.
-- Задержки кадров оригинала лежат в durations_ms.json рядом со спрайтами.
local actor, super = Class(Actor, "kyle")

function actor:init()
    super.init(self)

    self.name = "Roaring Knight"

    self.path = "enemies/knight"
    self.default = "idle"

    self.width = 100
    self.height = 88

    self.hitbox = {0, 0, 100, 88}

    self.animations = {
        -- Бой
        ["idle"]         = {"idle", 0.07, true},
        ["battle_intro"] = {"battle_intro", 0.1, false},
        ["hurt"]         = {"hurt", 0.07, false},
        ["afterimage"]   = {"afterimage", 0.05, true},

        -- Атаки
        ["point"]        = {"point", 0.12, false},       -- звёзды
        ["slash"]        = {"slash", 0.14, false},
        ["flurry"]       = {"flurry", 0.07, true},
        ["rush_clash"]   = {"rush_clash", 0.07, true},

        -- Финал («Рёв»)
        ["front"]        = {"front", 1, false},
        ["roaring"]      = {"roaring", 0.07, true},
        ["slash_front"]  = {"slash_front", 0.16, false},
    }

    self.offsets = {}
end

return actor
