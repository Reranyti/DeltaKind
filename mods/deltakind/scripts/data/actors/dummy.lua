local actor, super = Class(Actor)

function actor:init()
    super.init(self)

    self.name = "Roaring Knight"
    self.id = "dummy"

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
        },

        ["battle_intro"] = function(wait)

            for i = 1, 30 do
                self.sprite:setSprite(
                    "battle_intro_" .. i
                )

                wait(0.1)
            end

        end
    }

    self.offsets = {
        ["idle"] = {0, 0},
        ["battle_intro"] = {0, 0}
    }
end

function actor:onSpriteInit(sprite)
    sprite:setScale(0.5)
end

return actor


