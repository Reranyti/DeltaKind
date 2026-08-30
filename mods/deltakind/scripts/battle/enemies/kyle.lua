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
    end

    return super.onAct(
        self,
        battler,
        name
    )
end

return Kyle

