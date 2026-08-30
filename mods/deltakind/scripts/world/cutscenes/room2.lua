return {
    arrival = function(cutscene, event)

        local kris = cutscene:getCharacter("kris")
        local susie = cutscene:getCharacter("susie")
        local ralsei = cutscene:getCharacter("ralsei")
        local knight = cutscene:getEvent(6)

        if not kris or not susie or not ralsei or not knight then
            return
        end

        cutscene:detachFollowers()

        -------------------------------------------------------
        -- РЫЦАРЬ ДО АНИМАЦИИ
        -------------------------------------------------------

        knight.x = 659
        knight.y = 349

        cutscene:wait(
            cutscene:fadeIn(2)
        )

        cutscene:wait(0.5)

        cutscene:walkTo(kris, 180, 350, 1.3)
        cutscene:wait(0.25)

        cutscene:walkTo(susie, 200, 350, 1.1)
        cutscene:wait(0.25)

        cutscene:walkTo(ralsei, 220, 350, 0.9)
        cutscene:wait(1.0)

        cutscene:walkTo(kris, 291, 193, 1.0)
        cutscene:wait(0.2)

        cutscene:walkTo(susie, 291, 276, 0.8)
        cutscene:wait(0.2)

        cutscene:walkTo(ralsei, 291, 352, 0.7)
        cutscene:wait(1.0)

        cutscene:look(kris, "right")
        cutscene:look(susie, "right")
        cutscene:look(ralsei, "right")

        -------------------------------------------------------
        -- КАМЕРА
        -------------------------------------------------------

        cutscene:detachCamera()

        local camera_done =
            cutscene:panTo(
                621,
                243,
                1.0
            )

        cutscene:wait(camera_done)

        cutscene:wait(0.8)

        -------------------------------------------------------
        -- ДИАЛОГ
        -------------------------------------------------------

        cutscene:text(
            "[face:susie/surprise,10,10]...Крис?"
        )

        cutscene:text(
            "[face:susie/suspicious,10,10]Ты тоже его видишь...?"
        )

        cutscene:wait(0.8)

        cutscene:text(
            "[face:ralsei/stressed,10,10]Мне кажется... у нас нет выбора."
        )

        cutscene:text(
            "[face:susie/shock,10,10]Чёрт."
        )

        cutscene:wait(1.0)

        -------------------------------------------------------
        -- РЫЦАРЬ ПЕРЕД АНИМАЦИЕЙ МЕЧА
        -------------------------------------------------------

        knight.x = 611
        knight.y = 253

        -------------------------------------------------------
        -- BATTLE INTRO
        -------------------------------------------------------

        for i = 1, 30 do
            cutscene:setSprite(
                knight,
                "battle_intro_" .. i
            )

            cutscene:wait(0.1)
        end

        -------------------------------------------------------
        -- УБИРАЕМ МИРОВОГО РЫЦАРЯ
        -------------------------------------------------------

        knight.visible = false

        -------------------------------------------------------
        -- НАЧАЛО БОЯ
        -------------------------------------------------------

        cutscene:startEncounter("dummy")
    end
}

