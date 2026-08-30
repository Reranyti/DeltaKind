local actor, super = Class(Actor, "kyle")

function actor:init()
    super.init(self)

    self.name = "Roaring Knight"

    self.path = "enemies/dummy"
    self.default = "idle"

    self.width = 100
    self.height = 88

    self.hitbox = {0, 0, 100, 88}

    self.animations = {
        ["idle"] = {
            "idle",
            0.25,
            true
        }
    }

    self.offsets = {
        ["idle"] = {0, 0}
    }
end

return actor