function Mod:init()
    print("Loaded " .. self.info.name .. "!")
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

    debug:registerOption(
        "deltakind_meta",
        "Назад",
        "Вернуться в предыдущее меню.",
        function()
            debug:returnMenu()
        end
    )
end
