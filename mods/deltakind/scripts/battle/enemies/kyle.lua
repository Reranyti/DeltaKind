local Kyle, super = Class(EnemyBattler)

function Kyle:init()
    super.init(self)

    self.name = "Кайл"
    self.destiny_name = "Рыцарь"

    self.max_health = 11000
    self.health = 11000
    self.attack = 629
    self.defense = 11
    self.money = 1000000

    -------------------------------------------------------
    -- SIDE-B УСИЛЕНИЕ
    -------------------------------------------------------

    self.side_b_hp_multiplier = 1.25
    self.side_b_attack_multiplier = 1.15

    if Kristal.Config.sideB then
        self.max_health = math.floor(
            self.max_health * self.side_b_hp_multiplier
        )

        self.health = self.max_health

        self.attack = math.floor(
            self.attack * self.side_b_attack_multiplier
        )
    end

    -------------------------------------------------------
    -- ФАЗА
    -------------------------------------------------------

    self.phase = 1

    self.temp_atk_boost = 0
    self.temp_knight_red = 0
    self.reborn_count = 0
    self.enraged_flag = false

    -------------------------------------------------------
    -- ТАЙМЕРЫ
    -------------------------------------------------------

    self.timers = {
        attack = 0,
        knight_red = 0,
        barrier = 0
    }

    -------------------------------------------------------
    -- ОСНОВНЫЕ АТАКИ
    --
    -- Первые все эти атаки будут проиграны ПО ОЧЕРЕДИ.
    -- После полного прохождения списка начнётся рандом.
    -------------------------------------------------------

    self.waves = {
        "CircleBullets",
        "RotatingGrid",
        "Saw",
        "Fracture",
        "Rebound",
        "Shift",
        "OrangeWall",
        "Hazard",
        "Rain",
        "Spiral",
        "Crossfire"
    }

    -------------------------------------------------------
    -- АТАКИ 2 ФАЗЫ
    --
    -- Оставляем отдельный список, если потом захочешь
    -- сделать именно отдельные hell-атаки.
    --
    -- SIDE B TODO (раздел 24, 43 канона): "Во второй фазе
    -- атаки должны стать сложнее", НО конкретный коэффициент
    -- НЕ утверждён -- ×1.5 был явно ОТКЛОНЁН автором как
    -- самостоятельно придуманный. Здесь сложность НЕ изменена
    -- относительно уже существующей getDifficultyMultiplier()
    -- (она масштабируется по % HP Кайла, не по фазе, и это
    -- существовавшая ДО этой сессии логика, не новая
    -- выдумка). OrangeWall прямо исключён из доработок
    -- (раздел 25) -- трогать не нужно.
    -------------------------------------------------------

    self.hell_waves = {
        "Hazard",
        "CircleBullets",
        "RotatingGrid",
        "Rain",
        "ShiftHell",
        "ReboundHell"
    }

    -------------------------------------------------------
    -- СИСТЕМА ПОСЛЕДОВАТЕЛЬНОГО ПРОХОЖДЕНИЯ
    -------------------------------------------------------

    self.wave_sequence_index = 1

    -- Пока false, атаки идут строго по self.waves.
    self.random_waves_started = false

    -------------------------------------------------------
    -- ТЕКУЩАЯ АТАКА И ВАРИАЦИЯ
    -------------------------------------------------------

    self.current_wave = nil
    self.current_variation = nil

    -------------------------------------------------------
    -- ВАРИАЦИИ АТАК
    --
    -- ВАЖНО:
    -- phase2 = true означает:
    -- вариация запрещена до перехода во 2 фазу.
    --
    -- weight = относительный вес вариации.
    --
    -- Если у атаки пока нет вариаций, просто оставляем
    -- пустую таблицу.
    --
    -- Примеры ниже можно расширять.
    -------------------------------------------------------

    self.wave_variations = {

        CircleBullets = {
            {
                id = "normal",
                weight = 60,
                phase2 = false
            },
            {
                id = "fast",
                weight = 30,
                phase2 = false
            },
            {
                id = "hell",
                weight = 10,
                phase2 = true
            }
        },

        RotatingGrid = {
            {
                id = "normal",
                weight = 65,
                phase2 = false
            },
            {
                id = "fast",
                weight = 25,
                phase2 = false
            },
            {
                id = "hell",
                weight = 10,
                phase2 = true
            }
        },

        Saw = {
            {
                id = "normal",
                weight = 70,
                phase2 = false
            },
            {
                id = "double",
                weight = 20,
                phase2 = false
            },
            {
                id = "hell",
                weight = 10,
                phase2 = true
            }
        },

        Fracture = {
            {
                id = "normal",
                weight = 70,
                phase2 = false
            },
            {
                id = "dense",
                weight = 30,
                phase2 = false
            },
            {
                id = "hell",
                weight = 10,
                phase2 = true
            }
        },

        Rebound = {
            {
                id = "normal",
                weight = 70,
                phase2 = false
            },
            {
                id = "fast",
                weight = 30,
                phase2 = false
            },
            {
                id = "hell",
                weight = 10,
                phase2 = true
            }
        },

        Shift = {
            {
                id = "normal",
                weight = 70,
                phase2 = false
            },
            {
                id = "fast",
                weight = 30,
                phase2 = false
            },
            {
                id = "hell",
                weight = 10,
                phase2 = true
            }
        },

        OrangeWall = {
            {
                id = "normal",
                weight = 70,
                phase2 = false
            },
            {
                id = "fast",
                weight = 30,
                phase2 = false
            },
            {
                id = "hell",
                weight = 10,
                phase2 = true
            }
        },

        Hazard = {
            {
                id = "normal",
                weight = 70,
                phase2 = false
            },
            {
                id = "dense",
                weight = 30,
                phase2 = false
            },
            {
                id = "hell",
                weight = 10,
                phase2 = true
            }
        },

        Rain = {
            {
                id = "normal",
                weight = 70,
                phase2 = false
            },
            {
                id = "dense",
                weight = 30,
                phase2 = false
            },
            {
                id = "hell",
                weight = 10,
                phase2 = true
            }
        }
    }

    -------------------------------------------------------
    -- АКТЫ
    -------------------------------------------------------

  self:setActor("kyle")
  self:setScale(0.9)

  self.x = 498
  self.y = 199

    self.acts = {}

    self:registerAct(
        "Решимость",
        "Поднимает АТК\nвсей группе",
        nil,
        100
    )

    self:registerAct(
        "Единство",
        "Лечит 6500HP\nвсей группе",
        nil,
        250
    )

    self:registerAct(
        "Анализ",
        "Снижает АТК\nКайла на 150",
        nil,
        50
    )

    self:registerAct(
        "Барьер",
        "Режет входящий\nурон вдвое",
        nil,
        100
    )

    self:registerAct(
        "Поддержка К",
        "+1900макс ОЗ\nТратит свой ход",
        "kris",
        490
    )

    self:registerAct(
        "Поддержка С",
        "+1900макс ОЗ\nТратит ход Криса!",
        "susie",
        490
    )

    self:registerAct(
        "Поддержка Р",
        "+1900макс ОЗ\nТратит ход Криса!",
        "ralsei",
        490
    )

    -------------------------------------------------------
    -- SIDE B: "НАДЕТЬ" (раздел 11 канона)
    --
    -- Скрыт по умолчанию (act.hidden = true). Становится
    -- единственным видимым ACT, когда запускается сценарий
    -- "Надень" (см. Kyle:setSideBActFilter).
    -- Ограничен персонажем "kris" (раздел 12: меч доступен
    -- только Крису).
    -------------------------------------------------------

    self.act_wear = self:registerAct(
        "Надеть",
        "Наденьте\nИскажённый меч.",
        nil,
        0
    )
    self.act_wear.character = "kris"
    self.act_wear.hidden = true

    self.side_b_intro_played = false
    self.side_b_force_act_only = false
end

-----------------------------------------------------------
-- НАЧАЛО БИТВЫ
-----------------------------------------------------------

function Kyle:onBattleStart()
    -------------------------------------------------------
    -- Усиливаем только SFX.
    -- Музыку это не трогает.
    -------------------------------------------------------

    self._original_playSound = Assets.playSound

    Assets.playSound = function(
        name,
        volume,
        pitch,
        ...
    )
        volume =
            math.min(
                (volume or 1) * 1.35,
                1
            )

        return self._original_playSound(
            name,
            volume,
            pitch,
            ...
        )
    end

    -------------------------------------------------------
    -- Сбрасываем систему атак.
    -------------------------------------------------------

    self.wave_sequence_index = 1
    self.random_waves_started = false

    self.current_wave = nil
    self.current_variation = nil
end

-----------------------------------------------------------
-- SIDE B: ВСТУПИТЕЛЬНЫЙ МОНОЛОГ КАЙЛА (раздел 10.1)
--
-- Текст реплик находится в:
--   scripts/battle/cutscenes/kyle.lua -> side_b_intro
--
-- TODO (НЕ КАНОН, требует решения автора):
--   Момент вызова этой сцены (после какой фазы / какого HP-порога
--   у Кайла или у Криса она должна начинаться) не указан в
--   мастер-контексте. Раздел 15 говорит только, что кнопка
--   "Продолжай" появляется при HP Криса <= 600 -- это уже ПОСЛЕ
--   монолога, "Надень" и надевания меча, а не сам триггер монолога.
--
-- Пока эта функция вызывается вручную (например, из консоли
-- отладки Kristal: `Game.battle.enemies[1]:triggerSideBIntro()`)
-- и НЕ подключена автоматически ни к одному игровому событию.
-----------------------------------------------------------

function Kyle:triggerSideBIntro()

    if not Kristal.Config.sideB then
        return
    end

    if self.side_b_intro_played then
        return
    end

    self.side_b_intro_played = true

    Game.battle:startCutscene(
        "kyle",
        "side_b_intro"
    )
end

-----------------------------------------------------------
-- SIDE B: ФИЛЬТРАЦИЯ ACT-МЕНЮ ДЛЯ "НАДЕНЬ" (раздел 11)
--
-- active = true  -> виден только акт "Надеть" (только для Криса);
--                    кнопки Криса ограничиваются одним "Акт"
--                    через Mod:getActionButtons в mod.lua.
-- active = false -> обычный список актов / обычные кнопки.
--
-- Согласно разделу 23/43 канона, это ВРЕМЕННАЯ фильтрация
-- (act.hidden), а не необратимое удаление через table.remove.
--
-- ПРЕДПОЛОЖЕНИЕ: канон не говорит, ограничиваются ли также
-- кнопки Сьюзи/Ральзея в этот момент (раздел 11 упоминает
-- только замену кнопок в общем, без указания, что это только
-- Крис). Реализовано так: ограничивается ТОЛЬКО Крис, так как
-- именно ему адресовано "Надень" (раздел 12: меч доступен
-- только Крису). Если это неверно -- нужно скорректировать
-- Mod:getActionButtons в mod.lua.
-----------------------------------------------------------

function Kyle:setSideBActFilter(active)

    for _, act in ipairs(self.acts) do

        if act.name == "Надеть" then
            act.hidden = not active
        elseif act.name ~= "Надеть" then
            act.hidden = active or false
        end
    end

    self.side_b_force_act_only = active

    ---------------------------------------------------
    -- Пересоздаём кнопки Криса, чтобы изменение
    -- вступило в силу немедленно (ActionBox создаётся
    -- один раз на бой и не обновляется автоматически).
    ---------------------------------------------------

    if Game.battle
    and Game.battle.battle_ui
    and Game.battle.battle_ui.action_boxes then

        for _, box in ipairs(
            Game.battle.battle_ui.action_boxes
        ) do

            if box.battler
            and box.battler.chara.id == "kris" then
                box:createButtons()
            end
        end
    end
end

-----------------------------------------------------------
-- SIDE B: ПОЛНАЯ БЛОКИРОВКА КНОПОК (раздел 14 канона)
--
-- "теперь. ПРОДОЛЖАЙ." -> Кайл блокирует ВСЕ кнопки, для
-- всей группы, а не только для Криса.
--
-- ПРЕДПОЛОЖЕНИЕ: "заблокированы" реализовано как ПОЛНОЕ
-- отсутствие кнопок (Mod:getActionButtons возвращает пустую
-- таблицу для любого battler, пока флаг активен). Канон не
-- уточняет, должна ли коробка действий вообще исчезать
-- визуально или просто быть пустой -- оставлено как пустой
-- список кнопок, чтобы не выдумывать отсутствующую механику
-- (например, отдельную иконку "замка").
-----------------------------------------------------------

function Kyle:setSideBButtonsLocked(locked)

    self.side_b_buttons_locked = locked

    if Game.battle
    and Game.battle.battle_ui
    and Game.battle.battle_ui.action_boxes then

        for _, box in ipairs(
            Game.battle.battle_ui.action_boxes
        ) do
            box:createButtons()
        end
    end
end

-----------------------------------------------------------
-- SIDE B: СЮЖЕТНОЕ ИСЧЕЗНОВЕНИЕ (раздел 21-22 канона)
--
-- НЕ вызывает battler:down() (метод) -- см. раздел 22: сам
-- МЕТОД down() тянет за собой анимацию поражения, возможную
-- revival-логику и т.д. Вместо этого поле is_down выставляется
-- НАПРЯМУЮ, без вызова метода.
--
-- ПРОВЕРЕНО ЧТЕНИЕМ ДВИЖКА (не предположение):
--   - Battle:checkGameOver() (battle.lua:2556) требует, чтобы
--     ВСЕ party.is_down были true -- значит, пока Крис активен,
--     game over не сработает от одних Сьюзи/Ральзея.
--   - Battle:isActive() / nextParty() / selectNextActive()
--     (battle.lua:2391-2498) читают is_down через isActive() --
--     значит, очередь хода их пропускает.
--   - Battle:getActiveParty() (battle.lua:3204) фильтрует
--     ИМЕННО по is_down -- значит, таргетинг атак противника
--     (случайный выбор цели) их тоже исключает.
--   - Уже выбранный экшен (если Phase 2 наступила посреди
--     выбора хода) снимается через Battle:removeAction(index)
--     (battle.lua:1873) -- существующий метод движка, не
--     самодельный.
-----------------------------------------------------------

function Kyle:vanishSideBPartyMember(id)

    local pb = Game.battle:getPartyBattler(id)

    if not pb then
        return
    end

    local index = Game.battle:getPartyIndex(id)

    if index and Game.battle:hasAction(index) then
        Game.battle:removeAction(index)
    end

    ---------------------------------------------------
    -- RUNTIME CRASH FIX (battle.lua:3713, найдено по
    -- реальному стектрейсу):
    --
    -- Battle:handleAttackingInput() (battle.lua:3688-3721)
    -- работает НЕ по self.character_actions, а по отдельному
    -- списку self.battle_ui.attack_boxes -- визуальным
    -- AttackBox-объектам ATTACKING-состояния (полоска
    -- ритм-мини-игры FIGHT). Battle:removeAction() выше
    -- чистит только self.character_actions -- AttackBox
    -- битвы остаётся жив и всё ещё реагирует на Input.
    -- Когда игрок жмёт подтверждение, handleAttackingInput
    -- находит этот box, вызывает
    -- self:getActionBy(attack.battler, true), получает nil
    -- (экшен уже удалён выше) и падает на
    -- `action.points = points`.
    --
    -- ИСПРАВЛЕНИЕ (по реальному API движка, не костыль):
    -- находим AttackBox этого battler'а в
    -- battle_ui.attack_boxes и убираем его -- тем же
    -- способом, каким это делает сам движок при обычном
    -- завершении атаки (BattleUI:beginAttack(), строки
    -- 107-109: `box:remove()` + пересборка массива).
    ---------------------------------------------------

    if Game.battle.battle_ui
    and Game.battle.battle_ui.attack_boxes then

        local remaining = {}

        for _, box in ipairs(
            Game.battle.battle_ui.attack_boxes
        ) do
            if box.battler == pb then
                box:remove()
            else
                table.insert(remaining, box)
            end
        end

        Game.battle.battle_ui.attack_boxes = remaining
    end

    -- То же самое семейство бага: если Phase 2 наступила
    -- ДО того, как этот battler успел атаковать (box ещё не
    -- hit), он может всё ещё числиться в self.attackers /
    -- self.normal_attackers / self.auto_attackers -- эти
    -- списки движок сам чистит через TableUtils.removeValue
    -- при обычном завершении атаки (battle.lua:1397-1398),
    -- воспроизводим тот же паттерн.
    if Game.battle.attackers then
        TableUtils.removeValue(Game.battle.attackers, pb)
    end
    if Game.battle.normal_attackers then
        TableUtils.removeValue(Game.battle.normal_attackers, pb)
    end
    if Game.battle.auto_attackers then
        TableUtils.removeValue(Game.battle.auto_attackers, pb)
    end

    pb.visible = false
    pb.deltakind_vanished = true
    pb.is_down = true

    if Game.battle.battle_ui
    and Game.battle.battle_ui.action_boxes then

        for _, box in ipairs(
            Game.battle.battle_ui.action_boxes
        ) do
            if box.battler == pb then
                box.visible = false
            end
        end
    end

    ---------------------------------------------------
    -- RUNTIME CRASH FIX #2 (actionbox.lua:172, найдено по
    -- реальному стектрейсу):
    --
    -- Battle:handleActionSelectInput() (battle.lua:3645-3685)
    -- берёт ActionBox НАПРЯМУЮ по индексу:
    --   local actbox = self.battle_ui.action_boxes[self.current_selecting]
    -- Если current_selecting в этот момент указывает именно
    -- на исчезающего battler'а, его ActionBox теперь имеет 0
    -- кнопок (Mod:getActionButtons в mod.lua возвращает {}
    -- для deltakind_vanished) -- ActionBox:select()
    -- (actionbox.lua:170-173) делает
    -- `buttons[self.selected_button]:select()`, а buttons
    -- пустой -> nil -> краш.
    --
    -- ИСПРАВЛЕНИЕ ЧЕРЕЗ ШТАТНЫЙ МЕХАНИЗМ, А НЕ `if action
    -- then`: Battle:nextParty() (battle.lua:2391-2421) -- это
    -- ТА ЖЕ функция, которую движок сам вызывает, когда игрок
    -- обычным способом переходит к следующему невыбравшему
    -- действие battler'у. Она уже содержит корректную логику
    -- "пропустить неактивных" (через isActive(), которую
    -- is_down = true выше как раз и переключает) и, если
    -- выбирать больше некому, сама вызывает
    -- Battle:startProcessing() -- то есть round пойдёт в
    -- обработку, если, например, Крис уже выбрал действие, а
    -- выбирать стало больше некому.
    --
    -- ОДИН ПОБОЧНЫЙ ЭФФЕКТ nextParty(), который пришлось
    -- дополнительно поправить: она пушит СТАРЫЙ
    -- current_selecting (то есть индекс исчезающего battler'а)
    -- в self.selected_character_stack как точку возврата для
    -- Cancel. Если это оставить, игрок через Cancel сможет
    -- вернуться на скрытого battler'а и снова словить тот же
    -- краш в ActionBox:select(). Поэтому сразу после
    -- nextParty() эта конкретная запись (и парная запись в
    -- selected_action_stack) снимается -- остальная история
    -- навигации не трогается.
    --
    -- ОБЛАСТЬ ПРИМЕНЕНИЯ (честно): проверен и исправлен
    -- именно путь ACTIONSELECT (это единственное состояние,
    -- где репортился краш). MENUSELECT/PARTYSELECT (выбор
    -- цели для ACT/предмета/заклинания) читают
    -- current_selecting по-другому и НЕ проверялись -- если
    -- краш всплывёт там, это отдельная задача.
    ---------------------------------------------------

    if Game.battle:getState() == "ACTIONSELECT"
    and Game.battle.current_selecting == index then

        Game.battle:nextParty()

        local char_stack = Game.battle.selected_character_stack
        local action_stack = Game.battle.selected_action_stack

        if char_stack[#char_stack] == index then
            table.remove(char_stack, #char_stack)
            table.remove(action_stack, #action_stack)
        end
    end
end

-----------------------------------------------------------
-- SIDE B: ЗАПУСК CONTINUE-ПОСЛЕДОВАТЕЛЬНОСТИ (раздел 15+)
-----------------------------------------------------------

function Kyle:onSideBContinueThreshold()

    if Game.battle:hasCutscene() then
        return
    end

    Game.battle:startCutscene(
        "kyle",
        "side_b_continue_resist"
    )
end

-----------------------------------------------------------
-- SIDE B: УСПЕШНЫЙ ИСХОД QTE (разделы 18-19 канона)
--
-- "При хорошем прохождении Крис выживает. Side B сейв
-- удаляется. Флаг прохождения засчитывается. Финальная
-- надпись: ГОТОВА!"
--
-- ПРЕДПОЛОЖЕНИЯ (не КАНОН):
--   1. "Сейв Side B удаляется" реализовано как стирание
--      активного мета-слота через DeltaKindMeta.eraseSlot
--      (тот же метод, что уже используется в debug-меню
--      mod.lua). Канон не уточняет, весь ли мета-слот
--      стирается, или только какая-то часть прогресса -- взял
--      самую буквальную трактовку "сейв удаляется".
--   2. "ГОТОВА!" показана как обычный battleText без цвета/
--      анимации -- канон не описывает конкретное оформление.
--   3. После надписи бой завершается через
--      Battle:returnToWorld() (реальный метод движка) -- канон
--      не говорит, что происходит с игрой ПОСЛЕ "ГОТОВА!"
--      (обратно в мир? на титульный экран?). Возврат в мир --
--      самый безопасный вариант, не ломающий обычный игровой
--      цикл, но это ПРЕДПОЛОЖЕНИЕ.
-----------------------------------------------------------

function Kyle:onSideBQteSuccess()

    -----------------------------------------------------------
    -- ИСПРАВЛЕНИЕ ПРЕДПОЛОЖЕНИЯ: изначально здесь также
    -- вызывался DeltaKindMeta.eraseSlot(...), что СТИРАЛО бы
    -- именно тот флаг beat_side_b, который нужно сохранить --
    -- противоречие с "флаг прохождения засчитывается". Судя по
    -- разделу 3 канона, DeltaKindMeta -- это именно хранилище
    -- флага прохождения, а "сейв Side B" (раздел 18) -- скорее
    -- всего ОТДЕЛЬНЫЙ обычный игровой сейв (Kristal save file),
    -- а не мета-слот. Удаление обычного сейва НЕ реализовано
    -- здесь -- я не нашёл/не проверил точный API для этого в
    -- рамках этой сессии, а стирать наугад не хочу, чтобы не
    -- уничтожить прогресс по ошибке. TODO: подтвердить, что
    -- именно должно быть удалено, и каким методом.
    -----------------------------------------------------------

    local data = DeltaKindMeta.getActiveSlotData()
    data.beat_side_b = true
    DeltaKindMeta.saveActiveSlot(data)

    if Kristal.modCall then
        Kristal.modCall("onDeltaKindEvent", "side_b_cleared")
    end

    if self.setSideBButtonsLocked then
        self:setSideBButtonsLocked(false)
    end

    Game.battle:battleText(
        "ГОТОВА!",
        function()
            Game.battle:returnToWorld()
            return true
        end
    )
end

-----------------------------------------------------------
-- КОНЕЦ БИТВЫ
-----------------------------------------------------------

function Kyle:onDefeat(damage, battler)
    super.onDefeat(self, damage, battler)

    -- Записываем прогресс "прошёл Кайла на сайде А/Б" в
    -- отдельный файл вне обычных сейв-слотов (deltakind_progress.json,
    -- тот же принцип, что и settings.json движка) — это читает
    -- тайтл-скрин, чтобы решить, разблокирована ли скрытая кнопка.
    local data = DeltaKindMeta.getActiveSlotData()

    if Kristal.Config.sideB then
        data.beat_side_b = true
    else
        data.beat_side_a = true
    end

    DeltaKindMeta.saveActiveSlot(data)
end

function Kyle:onEnd()
    if self._original_playSound then
        Assets.playSound =
            self._original_playSound

        self._original_playSound = nil
    end

    super.onEnd(self)
end

-----------------------------------------------------------
-- UPDATE
-----------------------------------------------------------

function Kyle:onUpdate()
    super.onUpdate(self)
end

function Kyle:update()
    super.update(self)

    -------------------------------------------------------
    -- ПЕРЕХОД ВО 2 ФАЗУ
    -------------------------------------------------------

    if self.phase == 1
    and self.health <= (self.max_health / 2) then

        self.phase = 2

        if Game.music.current ~= "knight_phase2" then
            Game.music:stop()
            Game.music:play("knight_phase2")
        end

        self:flash()

        Game.battle:shake(6)

        if Kristal.Config.sideB then
            self.attack =
                self.attack + 125
        else
            self.attack =
                self.attack + 100
        end

        Game.battle:setEncounterText(
            "* Кайл сбросил оковы!\n" ..
            "* Грядёт Лазерный Фонтан!"
        )

        -------------------------------------------------
        -- SIDE B: раздел 21 -- во 2 фазе Сьюзи и Ральзей
        -- исчезают сюжетно, Крис остаётся один. Раздел 22:
        -- НЕ используем down() (это боевое поражение) --
        -- используем отдельный флаг/скрытие.
        -- Раздел 23: Поддержка С/Р скрываются (временная
        -- фильтрация act.hidden), Поддержка К остаётся.
        -------------------------------------------------

        if Kristal.Config.sideB then

            self:vanishSideBPartyMember("susie")
            self:vanishSideBPartyMember("ralsei")

            for _, act in ipairs(self.acts) do
                if act.name == "Поддержка С"
                or act.name == "Поддержка Р" then
                    act.hidden = true
                end
            end
        end
    end

    -------------------------------------------------------
    -- SIDE B: ЗАПУСК ВСТУПИТЕЛЬНОГО МОНОЛОГА (по решению
    -- автора: при 25% HP Кайла).
    -------------------------------------------------------

    if Kristal.Config.sideB
    and not self.side_b_intro_played
    and self.health <= (self.max_health * 0.25)
    and not Game.battle:hasCutscene() then

        self:triggerSideBIntro()
    end

    -------------------------------------------------------
    -- SIDE B: ПОРОГ 600 HP (раздел 15 канона)
    --
    -- "Когда у Криса остаётся 600 HP или меньше появляется
    -- кнопка Продолжай."
    --
    -- Здесь определяется только МОМЕНТ пересечения порога.
    -- Сама кнопка "Продолжай" и последующий диалог (раздел 15:
    -- "Ты должен будешь сказать эти слова...", 4 сопротивления
    -- Криса) -- это отдельная система (пункт плана "Continue-
    -- система"), ЕЩЁ НЕ РЕАЛИЗОВАНА. Kyle:onSideBContinueThreshold
    -- пока ничего не делает и служит точкой подключения.
    -------------------------------------------------------

    if self.side_b_buttons_locked
    and not self.side_b_continue_threshold_hit then

        local kris =
            Game.battle:getPartyBattler(
                "kris"
            )

        if kris
        and kris.chara:getHealth() <= 600 then

            self.side_b_continue_threshold_hit = true

            self:onSideBContinueThreshold()
        end
    end

    -------------------------------------------------------
    -- TP
    -------------------------------------------------------

    Game:setMaxTension(750)

    Game:setTension(
        MathUtils.clamp(
            Game:getTension(),
            0,
            750
        )
    )

    -------------------------------------------------------
    -- СТАТЫ ГРУППЫ
    -------------------------------------------------------

    if not self.stats_applied then

        local party_data = {
            kris = {
                hp = 1530,
                atk = 10
            },

            susie = {
                hp = 1670,
                atk = 14
            },

            ralsei = {
                hp = 1340,
                atk = 8
            }
        }

        for _, battler in ipairs(
            Game.battle.party
        ) do

            local id =
                battler.chara.id

            if party_data[id] then

                battler.chara.stats["health"] =
                    party_data[id].hp

                battler.chara.health =
                    party_data[id].hp

                battler:flash()
            end
        end

        ---------------------------------------------------
        -- 8 Ultimate Candy
        ---------------------------------------------------

        local candy_count =
            Game.inventory:getItemCount(
                "ultimate_candy"
            )

        if candy_count < 8 then

            for i = 1, 8 - candy_count do
                Game.inventory:addItem(
                    "ultimate_candy"
                )
            end
        end

        self.stats_applied = true
    end
end

-----------------------------------------------------------
-- ВЫБОР ВАРИАЦИИ
-----------------------------------------------------------

function Kyle:selectVariation(wave_id)

    local variations =
        self.wave_variations[wave_id]

    -------------------------------------------------------
    -- У АТАКИ НЕТ ВАРИАЦИЙ
    -------------------------------------------------------

    if not variations
    or #variations == 0 then
        return nil
    end

    -------------------------------------------------------
    -- Собираем только доступные вариации.
    -------------------------------------------------------

    local available = {}

    for _, variation in ipairs(
        variations
    ) do

        ---------------------------------------------------
        -- phase2-вариации запрещены в первой фазе.
        ---------------------------------------------------

        if not variation.phase2
        or self.phase >= 2 then

            local weight =
                variation.weight or 1

            ------------------------------------------------
            -- Во 2 фазе сложные вариации получают
            -- повышенный шанс.
            ------------------------------------------------

            if self.phase >= 2
            and variation.phase2 then

                weight =
                    weight * 4
            end

            table.insert(
                available,
                {
                    data = variation,
                    weight = weight
                }
            )
        end
    end

    if #available == 0 then
        return nil
    end

    -------------------------------------------------------
    -- Взвешенный рандом.
    -------------------------------------------------------

    local total_weight = 0

    for _, entry in ipairs(
        available
    ) do
        total_weight =
            total_weight +
            entry.weight
    end

    local roll =
        math.random() *
        total_weight

    local current = 0

    for _, entry in ipairs(
        available
    ) do

        current =
            current +
            entry.weight

        if roll <= current then
            return entry.data.id
        end
    end

    return available[
        #available
    ].data.id
end

-----------------------------------------------------------
-- ВЫБОР АТАКИ
-----------------------------------------------------------
--
-- Kristal вызывает selectWave() для выбора атаки.
-- Именно здесь мы делаем:
--
-- 1. Сначала последовательность.
-- 2. Потом случайные атаки.
-- 3. После выбора атаки выбираем её вариацию.
--
-----------------------------------------------------------

function Kyle:selectWave()

    -------------------------------------------------------
    -- wave_override имеет приоритет.
    -------------------------------------------------------

    if self.wave_override then

        local wave =
            self.wave_override

        self.wave_override = nil

        self.current_wave =
            wave

        self.current_variation =
            self:selectVariation(wave)

        return wave
    end

    -------------------------------------------------------
    -- ПЕРВЫЙ ПРОХОД:
    -- все атаки строго по очереди.
    -------------------------------------------------------

    if not self.random_waves_started then

        local wave =
            self.waves[
                self.wave_sequence_index
            ]

        ---------------------------------------------------
        -- Если индекс вышел за пределы списка,
        -- переключаемся на рандом.
        ---------------------------------------------------

        if not wave then

            self.random_waves_started =
                true

        else

            self.wave_sequence_index =
                self.wave_sequence_index + 1

            ------------------------------------------------
            -- После последней атаки следующий выбор
            -- уже будет случайным.
            ------------------------------------------------

            if self.wave_sequence_index >
                #self.waves then

                self.random_waves_started =
                    true
            end

            self.current_wave =
                wave

            self.current_variation =
                self:selectVariation(
                    wave
                )

            return wave
        end
    end

    -------------------------------------------------------
    -- РАНДОМНЫЙ РЕЖИМ
    -------------------------------------------------------

    local pool

    if self.phase >= 2 then

        ---------------------------------------------------
        -- Во 2 фазе используем hell_waves как
        -- дополнительный пул тяжёлых атак.
        --
        -- Но остальные атаки НЕ исчезают.
        ---------------------------------------------------

        pool = {}

        for _, wave in ipairs(
            self.waves
        ) do

            table.insert(
                pool,
                wave
            )
        end

        ---------------------------------------------------
        -- Добавляем hell_waves ещё раз.
        -- Это повышает вероятность их выпадения.
        ---------------------------------------------------

        for _, wave in ipairs(
            self.hell_waves
        ) do

            table.insert(
                pool,
                wave
            )
        end

    else

        pool = self.waves
    end

    -------------------------------------------------------
    -- Случайная атака.
    -------------------------------------------------------

    local wave =
        pool[
            math.random(
                1,
                #pool
            )
        ]

    -------------------------------------------------------
    -- Случайная вариация выбранной атаки.
    -------------------------------------------------------

    local variation =
        self:selectVariation(wave)

    self.current_wave =
        wave

    self.current_variation =
        variation

    return wave
end

-----------------------------------------------------------
-- GET NEXT WAVES
-----------------------------------------------------------
--
-- Не заменяем selectWave().
-- Kristal по документации использует selectWave()
-- для фактического выбора атаки.
--
-----------------------------------------------------------

function Kyle:getNextWaves()

    if self.wave_override then

        local wave =
            self.wave_override

        self.wave_override = nil

        return {
            wave
        }
    end

    return self.waves
end

-----------------------------------------------------------
-- ПОЛУЧЕНИЕ СЛОЖНОСТИ
-----------------------------------------------------------

function Kyle:getDifficultyMultiplier()

    local hp_p =
        (self.health /
        self.max_health) *
        100

    if hp_p <= 3 then
        return 4.0

    elseif hp_p <= 7 then
        return 3.5

    elseif hp_p <= 10 then
        return 3.0

    elseif hp_p <= 19 then
        return 2.8

    elseif hp_p <= 25 then
        return 2.5

    elseif hp_p <= 40 then
        return 2.2

    elseif hp_p <= 55 then
        return 2.0

    elseif hp_p <= 80 then
        return 1.5

    elseif hp_p <= 95 then
        return 1.3

    else
        return 1.0
    end
end

-----------------------------------------------------------
-- НАЧАЛО ХОДА
-----------------------------------------------------------

function Kyle:onTurnStart()

    -------------------------------------------------------
    -- РЕШИМОСТЬ
    -------------------------------------------------------

    if self.timers.attack > 0 then

        self.timers.attack =
            self.timers.attack - 1

        if self.timers.attack == 0 then

            for _, pb in ipairs(
                Game.battle.party
            ) do

                pb.chara.stats["attack"] =
                    pb.chara.stats["attack"] -
                    35
            end

            Game.battle:battleText(
                "* Эффект Решимости исчерпан!"
            )
        end
    end

    -------------------------------------------------------
    -- БАРЬЕР
    -------------------------------------------------------

    if self.timers.barrier > 0 then

        self.timers.barrier =
            self.timers.barrier - 1

        if self.timers.barrier == 0 then

            Game.battle:battleText(
                "* Барьер исчез!"
            )
        end
    end

    -------------------------------------------------------
    -- KNIGHT RED
    -------------------------------------------------------

    if self.timers.knight_red > 0 then

        self.timers.knight_red =
            self.timers.knight_red - 1

        if self.timers.knight_red == 0 then

            self.attack =
                self.attack +
                self.temp_knight_red

            self.temp_knight_red = 0
        end
    end

    super.onTurnStart(self)
end

-----------------------------------------------------------
-- УРОН ПО ГРУППЕ
-----------------------------------------------------------

function Kyle:onHurtParty(
    battler,
    damage
)

    if self.timers.barrier > 0 then
        damage =
            math.ceil(
                damage / 2
            )
    end

    return damage
end

-----------------------------------------------------------
-- ACT
-----------------------------------------------------------

function Kyle:onAct(
    battler,
    name
)

    local txt =
        "[font:deltarune-cyrillic1,14]" ..
        "[spacing:2]"

    -------------------------------------------------------
    -- ПОДДЕРЖКА
    -------------------------------------------------------

    if name == "Поддержка К"
    or name == "Поддержка С"
    or name == "Поддержка Р" then

        local target_id = "kris"
        local face = ""

        if name == "Поддержка С" then

            target_id = "susie"
            face =
                "[face:susie/smile]"

        elseif name == "Поддержка Р" then

            target_id = "ralsei"
            face =
                "[face:ralsei/blush_pleased]"
        end

        local target_battler =
            Game.battle:getPartyBattler(
                target_id
            )

        if target_battler then

            if target_id ~= "kris" then

                local kris =
                    Game.battle:getPartyBattler(
                        "kris"
                    )

                if kris then
                    kris.action_finished =
                        true

                    Game.battle:removeAction(
                        "kris"
                    )
                end
            end

            target_battler.chara.stats["health"] =
                target_battler.chara.stats["health"] +
                1900

            target_battler:heal(1200)
            target_battler:flash()

            return {
                face ..
                txt ..
                "* " ..
                target_battler.chara.name:upper() ..
                " увеличил ОЗ!"
            }
        end

    -------------------------------------------------------
    -- РЕШИМОСТЬ
    -------------------------------------------------------

    elseif name == "Решимость" then

        if self.timers.attack > 0 then
            return {
                "* Решимость уже активна!"
            }
        end

        self.timers.attack = 3

        for _, pb in ipairs(
            Game.battle.party
        ) do

            pb.chara.stats["attack"] =
                pb.chara.stats["attack"] +
                39

            pb:flash()
        end

        return {
            "[face:ralsei/smile]" ..
            txt ..
            "* АТК повышена на 2 хода!"
        }

    -------------------------------------------------------
    -- ЕДИНСТВО
    -------------------------------------------------------

    elseif name == "Единство" then

        for _, pb in ipairs(
            Game.battle.party
        ) do

            pb:heal(6500)
            pb:flash()
        end

        return {
            "[face:ralsei/blush_pleased]" ..
            txt ..
            "* Группа исцелена!"
        }

    -------------------------------------------------------
    -- АНАЛИЗ
    -------------------------------------------------------

    elseif name == "Анализ" then

        self.attack =
            self.attack - 230

        return {
            "[face:susie/smile]" ..
            txt ..
            "* Атака Кайла упала!"
        }

    -------------------------------------------------------
    -- БАРЬЕР
    -------------------------------------------------------

    elseif name == "Барьер" then

        self.timers.barrier = 2

        return {
            txt ..
            "* Барьер активирован!"
        }

    -------------------------------------------------------
    -- SIDE B: "НАДЕТЬ" (разделы 11-14 канона)
    --
    -- Логика надевания меча + "теперь. ПРОДОЛЖАЙ." + полная
    -- блокировка кнопок вынесена в cutscene
    -- scripts/battle/cutscenes/kyle.lua -> side_b_wear
    -- (запускается через Battle:startActCutscene, см. пример
    -- в mod_template/scripts/battle/enemies/dummy.lua).
    -- ATK+16 и утечка 1 HP/сек реализованы В ПРЕДМЕТЕ
    -- (scripts/data/items/twistedswd.lua), не здесь.
    -------------------------------------------------------

    elseif name == "Надеть" then

        Game.battle:startActCutscene(
            "kyle",
            "side_b_wear"
        )

        return
    end

    return super.onAct(
        self,
        battler,
        name
    )
end

return Kyle

