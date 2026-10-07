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
        -- вытянутая рука: разгон (кадры 1-5, остаётся на 5-м), удержание пока бьёт луч
        ["point_in"]     = {"point", 0.07, false, frames = {1, 2, 3, 4, 5}},
        -- возврат руки и в стойку
        ["point_out"]    = {"point", 0.09, false, frames = {6, 7, 8, 9}, next = "idle"},
        ["slash"]        = {"slash", 0.14, false},
        ["flurry"]       = {"flurry", 0.07, true},
        ["rush_clash"]   = {"rush_clash", 0.07, true},

        -- Финал («Рёв»)
        ["front"]        = {"front", 1, false},
        ["roaring"]      = {"roaring", 0.07, true},
        ["slash_front"]  = {"slash_front", 0.16, false},
    }

    -- Кадры разного размера выравниваем по нижнему ПРАВОМУ краю кадра idle (136x146), широкие позы растут влево:
    -- ox = 136 - w, oy = 146 - h.
    local sizes = {
        idle         = {136, 146},
        battle_intro = {244, 281},
        hurt         = {153, 130},
        afterimage   = {180, 146},
        point        = {158, 134},
        slash        = {234, 230},
        flurry       = {226, 156},
        rush_clash   = {166, 148},
        front        = {140, 160},
        roaring      = {140, 160},
        slash_front  = {266, 282},
    }

    self.offsets = {}
    for name, size in pairs(sizes) do
        local off = {136 - size[1], 146 - size[2]}
        self.offsets[name] = off
    end
end

return actor
