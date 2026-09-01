function Mod:init()
    print("Loaded " .. self.info.name .. "!")
end

-----------------------------------------------------------
-- SIDE B: ТОЧКА ПОДКЛЮЧЕНИЯ ДЛЯ АЧИВОК (раздел 40 канона)
--
-- Раздел 40/42: названия и условия достижений НЕ придуманы
-- здесь -- канон прямо запрещает выдумывать их без автора.
-- Это только СТРУКТУРНЫЙ хук: Kyle.lua вызывает
-- Mod:onDeltaKindEvent(id) в нужные моменты (например,
-- "side_b_cleared"), а сама логика unlock/условий должна
-- быть дописана здесь, когда список достижений будет
-- утверждён.
-----------------------------------------------------------

function Mod:onDeltaKindEvent(id)
    -- TODO: заполнить, когда будут утверждены названия и
    -- условия достижений (раздел 40 канона).
end

-----------------------------------------------------------
-- SIDE B: "НАДЕНЬ" -- принудительно оставляет только кнопку
-- "Акт" у Криса, пока Kyle.side_b_force_act_only == true.
--
-- Раздел 11 канона: "все кнопки заменяются на: Акт".
-- ПРЕДПОЛОЖЕНИЕ: ограничено только Крисом -- см. подробный
-- комментарий у Kyle:setSideBActFilter в
-- scripts/battle/enemies/kyle.lua.
-----------------------------------------------------------

function Mod:getActionButtons(battler, btn_types)

    if not battler
    or not battler.chara then
        return
    end

    -- Раздел 21-22: исчезнувшие (Сьюзи/Ральзей во 2 фазе
    -- Side B) не должны иметь доступных кнопок.
    if battler.deltakind_vanished then
        return {}
    end

    if not Game.battle
    or not Game.battle.enemies then
        return
    end

    for _, enemy in ipairs(Game.battle.enemies) do

        -- Раздел 14: "теперь. ПРОДОЛЖАЙ." блокирует ВСЕ
        -- кнопки, для любого battler.
        if enemy.side_b_buttons_locked then
            return {}
        end

        -- Раздел 11: "Надень" ограничивает только Криса
        -- одной кнопкой "Акт".
        if enemy.side_b_force_act_only
        and battler.chara.id == "kris" then
            return { "act" }
        end
    end
end

function Mod:onGameStart()
    -- Выдаем книгу в инвентарь (склад предметов), если её еще нет
    if not Game.inventory:hasItem("angel_path") then
        Game.inventory:addItem("angel_path")
    end
end

function Mod:registerDebugOptions(debug)
    -- Отдельное меню для тестирования постоянного прогресса DeltaKind.
    debug:registerMenu("deltakind_meta", "Мета DeltaKind")

    debug:registerOption(
        "main",
        "Мета DeltaKind",
        function()
            return "Открыть управление мета-сохранением DeltaKind."
        end,
        function()
            debug:enterMenu("deltakind_meta", 1)
        end
    )

    debug:registerOption(
        "deltakind_meta",
        "Активный мета-слот",
        function()
            return "Активный слот: " .. DeltaKindMeta.getActiveSlot()
        end,
        function()
            local next_slot = DeltaKindMeta.getActiveSlot() + 1
            if next_slot > DeltaKindMeta.SLOT_COUNT then
                next_slot = 1
            end
            DeltaKindMeta.setActiveSlot(next_slot)
        end
    )

    local flags = {
        { "meta_intro_seen", "Вступительная сцена просмотрена" },
        { "beat_side_a", "Кайл пройден на Стороне А" },
        { "beat_side_b", "Кайл пройден на Стороне Б" },
        { "unlocked_side_c", "Открыть Сторону С" },
        { "unlocked_colorful", "Открыть «Разноцветный»" },
    }

    for _, entry in ipairs(flags) do
        local key, name = entry[1], entry[2]
        debug:registerOption(
            "deltakind_meta",
            name,
            function()
                local data
                if key == "meta_intro_seen" then
                    data = DeltaKindMeta.load().meta_intro_seen
                else
                    data = DeltaKindMeta.getActiveSlotData()[key]
                end
                return debug:appendBool(name, data == true)
            end,
            function()
                if key == "meta_intro_seen" then
                    DeltaKindMeta.setIntroSeen(not DeltaKindMeta.hasSeenIntro())
                else
                    local data = DeltaKindMeta.getActiveSlotData()
                    data[key] = not data[key]
                    DeltaKindMeta.saveActiveSlot(data)
                end
            end
        )
    end

    debug:registerOption(
        "deltakind_meta",
        "Стереть активный мета-слот",
        "Стереть весь мета-прогресс активного слота.",
        function()
            DeltaKindMeta.eraseSlot(DeltaKindMeta.getActiveSlot())
        end
    )

    -------------------------------------------------------
    -- SIDE B: ОТЛАДОЧНЫЕ КНОПКИ ДЛЯ ТЕСТИРОВАНИЯ ПЕРЕХОДОВ
    --
    -- Оба варианта НЕ подменяют переход напрямую (не ставят
    -- self.phase = 2 / не открывают Continue-диалог вручную).
    -- Они только сдвигают HP до порога, который уже проверяет
    -- существующий Kyle:update() каждый кадр -- то есть
    -- реально проходит ТОТ ЖЕ код (исчезновение партии,
    -- очистку actions/attack_boxes через
    -- vanishSideBPartyMember, UI и т.д.), а не имитацию.
    -------------------------------------------------------

    local function getKyle()
        if not Game.battle
        or not Game.battle.enemies then
            return nil
        end

        for _, enemy in ipairs(Game.battle.enemies) do
            -- Проверяем не enemy.id (не нашёл гарантии, что
            -- EnemyBattler всегда его выставляет), а наличие
            -- метода, который есть только у Kyle -- надёжнее.
            if enemy.triggerSideBIntro then
                return enemy
            end
        end

        return nil
    end

    local function inKyleBattle()
        return getKyle() ~= nil
    end

    debug:registerOption(
        "deltakind_meta",
        "Side B: тест переходов",
        function()
            return "Открыть отладочные кнопки Side B (только в бою с Кайлом)."
        end,
        function()
            debug:enterMenu("deltakind_sideb_debug", 1)
        end,
        inKyleBattle
    )

    debug:registerMenu("deltakind_sideb_debug", "Side B: тест переходов")

    debug:registerOption(
        "deltakind_sideb_debug",
        "Force Kyle Phase 2",
        "Опустить HP Кайла до 50% -- дальше сработает обычный переход из Kyle:update().",
        function()
            local kyle = getKyle()
            if kyle then
                kyle.health = MathUtils.round(kyle.max_health * 0.5)
            end
        end,
        inKyleBattle
    )

    debug:registerOption(
        "deltakind_sideb_debug",
        "Force Continue Threshold",
        "Опустить HP Криса до 600 -- дальше сработает обычная проверка порога из Kyle:update(). Работает только ПОСЛЕ того, как уже прошла сцена 'Надень'/'теперь. ПРОДОЛЖАЙ.' (нужен side_b_buttons_locked == true), иначе Kyle:update() просто не дойдёт до этой проверки.",
        function()
            local kris = Game.battle and Game.battle:getPartyBattler("kris")
            if kris then
                kris.chara:setHealth(600)
            end
        end,
        inKyleBattle
    )

    debug:registerOption(
        "deltakind_sideb_debug",
        "Назад",
        "Вернуться в предыдущее меню.",
        function()
            debug:returnMenu()
        end
    )

    debug:registerOption(
        "deltakind_meta",
        "Назад",
        "Вернуться в предыдущее меню.",
        function()
            debug:returnMenu()
        end
    )
end
