function Mod:init()
    print("Loaded " .. self.info.name .. "!")
end

function Mod:onGameStart()
    -- Выдаем книгу в инвентарь (склад предметов), если её еще нет
    if not Game.inventory:hasItem("angel_path") then
        Game.inventory:addItem("angel_path")
    end
end