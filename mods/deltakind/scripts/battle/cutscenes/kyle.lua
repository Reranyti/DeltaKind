-----------------------------------------------------------
-- Общие цветовые теги реплик (раздел 9 канона):
--   Кайл / Рыцарь -> [color:red]
--   Крис          -> [color:blue]
-----------------------------------------------------------

local RED = "[color:red]*[color:reset] "
local BLUE = "[color:blue]*[color:reset] "

local function _side_b_qte(cutscene)
        local kyle = cutscene:getCharacter("kyle")

        if not ContinueQTE.FINAL_TEXTIND_PLACEHOLDER then
            cutscene:setSpeaker(nil)
            cutscene:text(
                "[color:yellow]* (DEV) final_textind не задан -- " ..
                "QTE не может\n" ..
                "* корректно завершиться. Возвращаю бой " ..
                "в обычный режим.[color:reset]"
            )

            if kyle and kyle.setSideBButtonsLocked then
                kyle:setSideBButtonsLocked(false)
            end

            return
        end

        local qte = ContinueQTE(ContinueQTE.FINAL_TEXTIND_PLACEHOLDER)

        local FAKE_PATHS = {
            "C:/deltakind/save/side_b.dat",
            "C:/deltakind/save/kris_route.tmp",
            "C:/deltakind/cache/soul_data.bin",
            "C:/deltakind/save/meta_slot.dat",
        }

        local scare_text = Text("", 4, 4, 220, 90)
        Game.battle:addChild(scare_text)

        local function escalationSound()
            -- Раздел 31: 3 ступени звука (имена -- fallback-
            -- заглушки, канон явно это разрешает на этапе
            -- разработки). Плюс pitch растёт с textind внутри
            -- каждой ступени (раздел 30: "тон статики
            -- повышается") -- Assets.playSound(sound, volume,
            -- pitch) поддерживает pitch как реальный параметр
            -- движка (src/engine/assets.lua:417).
            local pitch = 1 + math.min(qte.textind, 40) * 0.01

            if qte.textind >= 41 then
                Assets.playSound("snd_ominous_hell_super", nil, pitch)
            elseif qte.textind >= 23 then
                Assets.playSound("snd_ominous_hell", nil, pitch)
            else
                Assets.playSound("snd_ominous", nil, pitch)
            end
        end

        local function fileScareTick()
            if qte.textind > 0 and qte.textind % 5 == 0 then
                local path = FAKE_PATHS[
                    (math.floor(qte.textind / 5) - 1) %
                    #FAKE_PATHS + 1
                ]
                scare_text:setText(
                    (scare_text.text and scare_text.text.text or "") ..
                    "Удалено: " .. path .. "\n"
                )
            end
        end

        cutscene:setSpeaker(nil)

        -------------------------------------------------
        -- ГЛОБАЛЬНЫЙ ПРОГРЕСС QTE (раздел 30-31 канона):
        -- static/pitch должны расти по мере приближения к
        -- концу QTE в целом, не только к концу ТЕКУЩЕГО
        -- вопроса (это отдельная величина от
        -- qte:getTimerProgress(), который про один вопрос).
        --
        -- ПРЕДПОЛОЖЕНИЕ: раз final_textind не подтверждён,
        -- глобальный прогресс приближённо считается через
        -- FAST_SEGMENT как ориентир (0 в начале, ~1 к концу
        -- быстрого сегмента). Это грубое приближение, не
        -- точная формула -- канон не даёт формулы для
        -- глобальной эскалации звука/шума, только сам факт
        -- эскалации (раздел 31: 3 ступени звука).
        -------------------------------------------------

        local function globalProgress()
            local approx_end =
                ContinueQTE.FAST_SEGMENT_START +
                ContinueQTE.FAST_SEGMENT_COUNT

            return MathUtils.clamp(
                qte.textind / approx_end, 0, 1
            )
        end

        while not qte.done and not qte.failed do

            local _, choice_box =
                cutscene:choicer({ "Продолжай." }, { wait = false })

            cutscene:wait(function()
                qte:update()

                local gprog = globalProgress()
                local qprog = qte:getTimerProgress()

                -----------------------------------------
                -- Whiteout (раздел 30) -- растёт с прогрессом
                -- текущего вопроса (баг с Fader:setColor уже
                -- исправлен, см. предыдущее ревью).
                -----------------------------------------

                if Game.fader then
                    Game.fader.fade_color = { 1, 1, 1 }
                    Game.fader.alpha = 0.6 * qprog
                end

                -----------------------------------------
                -- "Статика" (раздел 30) -- НЕТ готового
                -- шум-шейдера в движке (не найден при
                -- поиске), поэтому это ПРИБЛИЖЕНИЕ: слабый
                -- случайный тряс камеры, усиливающийся с
                -- глобальным прогрессом. Это НЕ настоящий
                -- визуальный шум/static-текстура.
                -----------------------------------------

                if gprog > 0.3 and math.random() < gprog * 0.15 then
                    Game.battle:shake(1 + gprog * 3)
                end

                -----------------------------------------
                -- "Подсказки становятся менее заметными"
                -- (раздел 30) -- альфа choice_box снижается
                -- с глобальным прогрессом, но не до конца
                -- (иначе будет невозможно понять, что жать).
                -- ПРЕДПОЛОЖЕНИЕ: ChoiceBox наследует .alpha
                -- от Object и учитывает его при отрисовке --
                -- не проверено запуском движка.
                -----------------------------------------

                choice_box.alpha =
                    MathUtils.clamp(1 - gprog * 0.6, 0.4, 1)

                -----------------------------------------
                -- "SOUL остаётся видимой почти до конца"
                -- (раздел 30) -- ПОКА НЕ ГАРАНТИРОВАНО:
                -- Fader обычно рисуется поверх сцены как
                -- полноэкранный прямоугольник, а объект
                -- SOUL/сердца здесь никак не выводится
                -- поверх него. Порядок отрисовки НЕ
                -- проверен -- честно оставляю как
                -- неподтверждённый риск, а не как решённый
                -- пункт.
                -----------------------------------------

                return choice_box.done or qte.failed
            end)

            if qte.failed then
                break
            end

            qte:choose()
            escalationSound()
            fileScareTick()
        end

        cutscene:closeText()
        scare_text:remove()

        if Game.fader then
            Game.fader.alpha = 0
        end

        if qte.failed then

            -----------------------------------------------
            -- ПЛОХОЙ ИСХОД (раздел 18) -- ИМИТАЦИЯ КРАША
            --
            -- love.event.quit() по-прежнему реально закрывает
            -- игру (буквальная трактовка "игра должна
            -- вылететь") -- это не изменилось и не может быть
            -- изменено без нарушения буквального текста
            -- канона. Добавлена только визуальная подводка
            -- перед закрытием: быстрое мигание случайным
            -- цветом + тряска экрана, чтобы это ощущалось как
            -- сбой, а не как чистый переход в меню.
            -----------------------------------------------

            cutscene:setSpeaker(nil)
            cutscene:closeText()

            for _ = 1, 8 do
                Game.battle:shake(10)

                if Game.fader then
                    Game.fader.fade_color = {
                        math.random(),
                        math.random(),
                        math.random(),
                    }
                    Game.fader.alpha = 1
                end

                cutscene:wait(0.05)
            end

            if Game.fader then
                Game.fader.fade_color = { 0, 0, 0 }
                Game.fader.alpha = 1
            end

            cutscene:wait(0.3)

            love.event.quit()
            return
        end

        -----------------------------------------------
        -- ХОРОШИЙ ИСХОД (раздел 18-19)
        -----------------------------------------------

        if kyle and kyle.onSideBQteSuccess then
            kyle:onSideBQteSuccess()
        end
    end
end

return {
    -- The inclusion of the below line tells the language server that the first parameter of the cutscene is `BattleCutscene`.
    ---@param cutscene BattleCutscene

    -----------------------------------------------------------
    -- SIDE B: ВСТУПИТЕЛЬНЫЙ МОНОЛОГ КАЙЛА
    --
    -- Источник: DELTAKIND MASTER CONTEXT, раздел 10.1.
    -- Текст реплик воспроизведён буквально, порядок не менялся.
    --
    -- ПРЕДПОЛОЖЕНИЕ (не КАНОН, требует подтверждения автором):
    --   1. Разбивка реплик на отдельные текстовые окна (по одному
    --      cutscene:text() на смысловой блок) выбрана на основе
    --      разбиения абзацев в мастер-контексте. Точная разбивка
    --      по нажатиям может отличаться.
    --   2. Реакция "Крис вздрагивает" реализована как
    --      battler:flash() — это ВРЕМЕННЫЙ визуальный маркер,
    --      не утверждённая анимация. Точный визуальный эффект
    --      "вздрагивания" в каноне не описан -> TODO.
    --   3. Портрет/лицо (face) Кайла и Криса не заданы, так как
    --      конкретные face-спрайты не упомянуты в каноне -> TODO.
    --   4. Точка вызова этой cutscene: по решению автора,
    --      при HP Кайла <= 25% (см. Kyle:update()).
    -----------------------------------------------------------

    side_b_intro = function(cutscene)
        local kyle = cutscene:getCharacter("kyle")
        cutscene:setSpeaker(kyle and kyle.actor or nil)

        cutscene:text(
            RED .. "Мы прозвали себя кайл.\n" ..
            RED .. "Отвергнутые.\n" ..
            RED .. "Тонущие.\n" ..
            RED .. "Задыхающиеся."
        )

        cutscene:text(
            RED .. "Ты специально привёл нас к озеру с крисом.\n" ..
            RED .. "Так ведь?"
        )

        cutscene:text(
            RED .. "Нам уже не важно крис с нами или нет."
        )

        cutscene:text(
            RED .. "Пророчество не исполнено."
        )

        cutscene:text(
            RED .. "И мы убьём тебя.\n" ..
            RED .. "Проклятая Душа."
        )

        cutscene:text(
            RED .. "...давай мы ЗАСТАВИМ почувствовать тебя\n" ..
            RED .. "то, что чувствовали Я и Ноэль."
        )

        ---------------------------------------------------
        -- "Крис вздрагивает" -- ПРЕДПОЛОЖЕНИЕ (см. заметку выше)
        ---------------------------------------------------

        local kris = cutscene:getCharacter("kris")
        if kris then
            kris:flash()
            cutscene:wait(0.4)
        end

        cutscene:setSpeaker(kris and kris.actor or nil)
        cutscene:text(BLUE .. "...")

        cutscene:setSpeaker(kyle and kyle.actor or nil)
        cutscene:text(
            RED .. "Ох, не бойся...\n" ..
            RED .. "Ты ничего не почувствуешь."
        )

        cutscene:setSpeaker(nil)

        -----------------------------------------------
        -- "НАДЕНЬ" (раздел 11 канона)
        --
        -- ПРЕДПОЛОЖЕНИЕ: показано как обычный текст без
        -- "*" и без указания говорящего -- канон описывает
        -- это как появляющуюся КОМАНДУ, а не реплику
        -- персонажа. Если это неверно -- нужно уточнение.
        -----------------------------------------------

        cutscene:wait(0.5)
        cutscene:text("Надень.")

        if kyle and kyle.setSideBActFilter then
            kyle:setSideBActFilter(true)
        end
    end,

    -----------------------------------------------------------
    -- SIDE B: НАДЕВАНИЕ МЕЧА + "теперь. ПРОДОЛЖАЙ." (разделы
    -- 12-14 канона)
    --
    -- Запускается из Kyle:onAct() через
    -- Game.battle:startActCutscene("kyle", "side_b_wear")
    -- когда Крис выбирает ACT "Надеть".
    --
    -- ПРЕДПОЛОЖЕНИЯ (не КАНОН):
    --   1. Строка "* Крис надел Искажённый меч." — связующий
    --      текст, которого нет дословно в мастер-контексте.
    --      Нужна как минимум как техническое подтверждение
    --      действия игроку; цвет/формулировка не утверждены.
    --   2. "Крис начинает задыхаться" (раздел 14) — визуальный
    --      эффект НЕ реализован здесь (это часть whiteout/
    --      distortion, отдельный пункт плана). Пока только
    --      текст и блокировка кнопок.
    --   3. Экранные эффекты ("..." на экране, красный экран,
    --      искажение) — НЕ реализованы в этом блоке, см. TODO.
    -----------------------------------------------------------

    side_b_wear = function(cutscene)
        local kyle = cutscene:getCharacter("kyle")
        local kris = cutscene:getCharacter("kris")

        if kris then
            kris.chara:setWeapon("twistedswd")
            kris:flash()
        end

        cutscene:setSpeaker(nil)
        cutscene:text("* Крис надел Искажённый меч.")

        cutscene:wait(0.6)

        cutscene:setSpeaker(kyle and kyle.actor or nil)
        cutscene:text(
            RED .. "теперь.\n" ..
            RED .. "ПРОДОЛЖАЙ."
        )

        cutscene:setSpeaker(nil)

        ---------------------------------------------------
        -- ACT-меню Кайла возвращается к обычному списку
        -- (раздел 11 больше не активен), но ВСЕ кнопки боя
        -- теперь блокируются полностью (раздел 14: "блокирует
        -- все кнопки") — это уже не только ACT-ограничение
        -- для Криса, а полная блокировка для всей группы.
        ---------------------------------------------------

        if kyle and kyle.setSideBActFilter then
            kyle:setSideBActFilter(false)
        end

        -- Кнопки блокируются только на время этой катсцены.
        -- После "теперь. ПРОДОЛЖАЙ." игрок снова может действовать --
        -- кнопки возвращаются, но HP Криса падает от меча (twistedswd).
        -- Когда HP достигает динамического порога (600 + kris_support_k_count * 600),
        -- Kyle:update() запускает side_b_continue_resist.
        if kyle and kyle.setSideBButtonsLocked then
            kyle:setSideBButtonsLocked(true)
        end

        -- Небольшая пауза чтобы текст "ПРОДОЛЖАЙ." был виден
        cutscene:wait(0.5)

        -- Снимаем блокировку -- игрок снова может действовать
        if kyle and kyle.setSideBButtonsLocked then
            kyle:setSideBButtonsLocked(false)
        end
    end,

    -----------------------------------------------------------
    -- SIDE B: ТРЕБОВАНИЕ "ПРОДОЛЖАЙ" + 4 СОПРОТИВЛЕНИЯ КРИСА
    -- (раздел 15 канона)
    --
    -- Запускается из Kyle:onSideBContinueThreshold() когда HP
    -- Криса опускается до 600 или ниже.
    --
    -- ПРЕДПОЛОЖЕНИЯ (не КАНОН):
    --   1. Канон описывает "Крис сопротивляется этому действию
    --      четыре раза" как факт истории, не как явно описанный
    --      игровой ввод. Реализовано как 4 повторения:
    --      подсказка "Продолжай." (через cutscene:choicer,
    --      игрок должен подтвердить) + текст Криса "...". Это
    --      интерпретация, не буквальный игровой алгоритм.
    --   2. После 4-го раза текст "Продолжай." появляется снова
    --      (раздел 15, последняя строка) и запускает QTE
    --      (side_b_qte).
    -----------------------------------------------------------

    side_b_continue_resist = function(cutscene)
        local kyle = cutscene:getCharacter("kyle")
        local kris = cutscene:getCharacter("kris")

        cutscene:setSpeaker(kyle and kyle.actor or nil)
        cutscene:text(
            RED .. "Ты должен будешь сказать эти слова...\n" ..
            RED .. "Прошу.\n" ..
            RED .. "Выкрикни их."
        )

        cutscene:setSpeaker(kris and kris.actor or nil)
        cutscene:text(BLUE .. "...")

        for i = 1, 4 do
            cutscene:setSpeaker(nil)
            cutscene:choicer({ "Продолжай." })

            cutscene:setSpeaker(kris and kris.actor or nil)
            cutscene:text(BLUE .. "...")
        end

        cutscene:setSpeaker(nil)
        cutscene:text("Продолжай.")

        -- Вызываем side_b_qte напрямую как локальную функцию --
        -- нельзя startCutscene изнутри активной катсцены.
        _side_b_qte(cutscene)
    end,

    -----------------------------------------------------------
    -- SIDE B: ФИНАЛЬНОЕ QTE (разделы 16-19, 27-31 канона)
    --
    -- Использует ContinueQTE (scripts/globals/ContinueQTE.lua)
    -- для утверждённой формулы Tbase/faillimit.
    --
    -- ВАЖНО: final_textind НЕ подтверждён каноном (раздел 28-29,
    -- 42). Пока ContinueQTE.FINAL_TEXTIND_PLACEHOLDER == nil,
    -- этот блок НЕ пытается имитировать успешное завершение --
    -- он честно сообщает об этом и возвращает бой в обычный
    -- режим, вместо того чтобы зависнуть или придумать число.
    --
    -- ПРЕДПОЛОЖЕНИЯ (не КАНОН):
    --   1. Whiteout реализован через Game.fader (белый цвет,
    --      alpha растёт с прогрессом таймера текущего вопроса).
    --      Раздел 30 описывает более сложную эскалацию (шум,
    --      "подсказки становятся менее заметными", SOUL остаётся
    --      видимой) -- здесь реализована только базовая яркостная
    --      часть, шумовой/статик-эффект НЕ реализован (нужен
    --      отдельный шейдер, не найден готовый в движке).
    --   2. Звук: snd_ominous / snd_ominous_hell /
    --      snd_ominous_hell_super -- ИМЕНА-ЗАГЛУШКИ (раздел 31
    --      прямо разрешает временный fallback). Если таких
    --      файлов нет в assets/sounds, Assets.playSound может
    --      не сыграть ничего или выдать ошибку движка -- нужно
    --      подставить реальные пути ассетов.
    --   3. File-scare реализован как отдельный Text-объект в
    --      углу экрана с фальшивыми путями (раздел 17: пути
    --      обязаны быть фальшивыми). Список путей ниже выдуман
    --      специально как безопасные фейковые строки, а не как
    --      сюжетный канон.
    --   4. Провал (timeout) -> love.event.quit() -- буквальная
    --      трактовка "игра должна вылететь" (раздел 18).
    -----------------------------------------------------------

    side_b_qte = _side_b_qte,

}
