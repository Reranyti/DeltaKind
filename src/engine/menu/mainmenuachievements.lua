-----------------------------------------------------------
-- MAIN MENU ACHIEVEMENTS
--
-- Заглушка-экран (полноценная система ачивок — отдельная
-- задача на потом). Показывает список известных ачивок,
-- полученных через прогресс-файл, без экрана-галереи.
-----------------------------------------------------------

---@class MainMenuAchievements : StateClass
---@overload fun(menu:MainMenu) : MainMenuAchievements
local MainMenuAchievements, super = Class(StateClass)

function MainMenuAchievements:init(menu)
    self.menu = menu
end

function MainMenuAchievements:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("update", self.update)
    self:registerEvent("draw", self.draw)
end

function MainMenuAchievements:onEnter(old_state)
    self.progress_data = DeltaKindMeta.getActiveSlotData()
end

function MainMenuAchievements:update()
    if Input.pressed("cancel") or Input.pressed("confirm") then
        self.menu:setState("TITLE")
        self.menu.title_screen:selectOption("achievements")
        Assets.stopAndPlaySound("ui_move")
    end
end

function MainMenuAchievements:draw()
    Draw.printShadow("ДОСТИЖЕНИЯ", 40, 60)

    local y = 110

    if self.progress_data.unlocked_side_c then
        Draw.printShadow("Твоя последственность", 40, y)
        y = y + 32
    end

    if self.progress_data.unlocked_colorful then
        Draw.printShadow("Разноцветный", 40, y)
        y = y + 32
    end

    if y == 110 then
        Draw.printShadow("Пока пусто...", 40, y)
    end

    Draw.printShadow("(Отмена/Подтвердить) — назад", 40, SCREEN_HEIGHT - 40)
end

return MainMenuAchievements
