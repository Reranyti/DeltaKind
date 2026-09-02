local Battle, super = HookSystem.hookScript(Battle)

local MUSIC = {
    side_a = {
        [1] = "Knite_Bandage(Side-a)",
        [2] = "See_Hope(Side-a2)",
    },
    side_b = {
        [1] = "DEEP_WALKS(Side-b)",
        [2] = "The_Black_Death(Side-b2)",
    },
}

function Battle:update()
    super.update(self)

    if not self.enemies then
        return
    end

    local kyle
    for _, enemy in ipairs(self.enemies) do
        if enemy.triggerSideBIntro then
            kyle = enemy
            break
        end
    end

    if not kyle then
        return
    end

    local path = Kristal.Config.sideB and MUSIC.side_b or MUSIC.side_a
    local track = path[kyle.phase or 1]

    if track and self.music.current ~= track then
        self.music:stop()
        self.music:play(track)
    end
end

return Battle
