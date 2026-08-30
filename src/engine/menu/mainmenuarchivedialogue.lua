-----------------------------------------------------------
-- MAIN MENU ARCHIVE DIALOGUE
--
-- Секретный экран, открывающийся с разблокированной кнопки
-- на тайтл-скрине (после прохождения Кайла и на сайде А, и
-- на сайде Б). Чёрный фон, текст появляется по буквам,
-- дальше — по confirm. В двух местах — выбор Да/Нет.
--
-- Сценарий и ветвления — по ТЗ автора проекта, дословно;
-- сюжет/реплики не придуманы мной.
-----------------------------------------------------------

---@class MainMenuArchiveDialogue : StateClass
---@overload fun(menu:MainMenu) : MainMenuArchiveDialogue
local MainMenuArchiveDialogue, super = Class(StateClass)

local PROGRESS_FILE = "deltakind_progress.json"

local function loadProgress()
    local data = {
        beat_side_a = false,
        beat_side_b = false,
        unlocked_side_c = false,
        unlocked_colorful = false,
        archive_link = "...",
    }

    if love.filesystem.getInfo(PROGRESS_FILE) then
        local ok, decoded = pcall(JSON.decode, love.filesystem.read(PROGRESS_FILE))
        if ok and type(decoded) == "table" then
            for k, v in pairs(decoded) do
                data[k] = v
            end
        end
    end

    return data
end

local function saveProgress(data)
    love.filesystem.write(PROGRESS_FILE, JSON.encode(data))
end

-- UTF-8-безопасные счёт символов / обрезка строки. Обычные
-- #text и string.sub считают БАЙТЫ, а не символы — кириллица
-- в UTF-8 занимает 2 байта на букву, поэтому печать "по одному
-- символу за кадр" через них могла резать русский текст
-- посередине буквы. utf8 подключён глобально в main.lua.
local function utf8Length(text)
    return utf8.len(text) or #text
end

local function utf8Sub(text, char_count)
    local total = utf8Length(text)

    if char_count >= total then
        return text
    end

    if char_count <= 0 then
        return ""
    end

    local byte_offset = utf8.offset(text, char_count + 1)
    return string.sub(text, 1, (byte_offset or (#text + 1)) - 1)
end

-- Простой шейдер инверсии цвета для финального "чёрное
-- становится белым, белое — чёрным".
local INVERT_SHADER = love.graphics.newShader([[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
    {
        vec4 texcolor = Texel(texture, texture_coords);
        return vec4(vec3(1.0) - texcolor.rgb, texcolor.a) * color;
    }
]])

function MainMenuArchiveDialogue:init(menu)
    self.menu = menu
end

function MainMenuArchiveDialogue:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("update", self.update)
    self:registerEvent("draw", self.draw)
end

-------------------------------------------------------------------------------
-- Управление сценарием
-------------------------------------------------------------------------------

function MainMenuArchiveDialogue:onEnter(old_state)
    self.progress_data = loadProgress()

    self.reveal_speed = 28 -- символов в секунду
    self.invert_screen = false

    self:goToLine("intro_1")
end

--- Показывает строку текста (печатается по буквам).
function MainMenuArchiveDialogue:goToLine(step)
    self.step = step
    self.mode = "line"
    self.text = self:getLineText(step)
    self.revealed = 0
    self.reveal_timer = 0
    self.choice_options = nil
    self.choice_selected = 1
end

--- Показывает выбор Да/Нет.
function MainMenuArchiveDialogue:goToChoice(step)
    self.step = step
    self.mode = "choice"
    self.text = self:getLineText(step)
    self.revealed = utf8Length(self.text)
    self.choice_options = { "Да", "Нет" }
    self.choice_selected = 1
end

function MainMenuArchiveDialogue:getLineText(step)
    local lines = {
        intro_1 = "ОЧЕНЬ...",
        intro_2 = "ИНТЕРЕСНО.",
        ask_know = "ВЫ...ХОТИТЕ УЗНАТЬ ЧТО ВЫ НАДЕЛАЛИ?",

        foolish_1 = "ГЛУПЫЕ...",
        foolish_2 = "ДОЖДИТЕСЬ КОГДА ВАШИ ПОСЛЕДСТВИЯ СЫГРАЮТ РОЛЬ.",

        irresponsible = "ВЫ ОЧЕНЬ БЕЗОТВЕТСТВЕННЫЕ...ХОРОШО...ТОГДА ПОЗВОЛЬТЕ СПРОСИТЬ",
        ask_colors = "...ВЫ ЛЮБИТЕ...ЦВЕТА?",

        colorful_result = "Хорошо. тогда теперь вам решать кем вы будете.",
    }

    return lines[step] or ""
end

--- Обрабатывает переход после того, как строка/выбор завершены.
function MainMenuArchiveDialogue:advance()
    local step = self.step

    if step == "intro_1" then
        self:goToLine("intro_2")

    elseif step == "intro_2" then
        self:goToChoice("ask_know")

    elseif step == "ask_know" then
        if self.choice_selected == 1 then -- Да
            self:tryOpenArchive()
        else -- Нет
            self:goToLine("irresponsible")
        end

    elseif step == "irresponsible" then
        self:goToLine("ask_colors")

    elseif step == "ask_colors" then
        if self.choice_selected == 1 then -- Да
            self:goToLine("colorful_result")
        else -- Нет
            -- "игра вылетит и вас переведёт на твоя
            -- последственность" — тот же исход, что и
            -- неуказанный архив.
            self:closeToConsequence()
        end

    elseif step == "colorful_result" then
        self.progress_data.unlocked_colorful = true
        saveProgress(self.progress_data)
        self.invert_screen = true
        self.mode = "invert_hold"
        self.invert_timer = 0
    end
end

--- Ветка "Да" на "хотите узнать, что вы наделали?" —
--- проверяет, указана ли ссылка на архив (другую игру).
function MainMenuArchiveDialogue:tryOpenArchive()
    local link = self.progress_data.archive_link

    if not link or link == "..." or link == "" then
        self:goToLine("foolish_1")
    else
        love.system.openURL(link)
        self:closeToConsequence()
    end
end

--- Общий исход "не сложилось" — закрывает игру и
--- разблокирует "Сторона С" / "ТВОЯ ПОСЛЕДСТВЕННОСТЬ".
function MainMenuArchiveDialogue:closeToConsequence()
    self.progress_data.unlocked_side_c = true
    saveProgress(self.progress_data)

    -- Даём последней строке дочитаться, затем выходим.
    self.mode = "quitting"
    self.quit_timer = 1.2
end

-------------------------------------------------------------------------------
-- Ввод
-------------------------------------------------------------------------------

function MainMenuArchiveDialogue:update()
    if self.mode == "line" then
        local char_count = utf8Length(self.text)

        if self.revealed < char_count then
            self.reveal_timer = self.reveal_timer + self.reveal_speed * DT
            self.revealed = math.min(char_count, math.floor(self.reveal_timer))

            if Input.pressed("confirm") then
                self.revealed = char_count
            end
        elseif Input.pressed("confirm") then
            Assets.stopAndPlaySound("ui_select")

            if self.step == "foolish_2" then
                self:closeToConsequence()
            elseif self.step == "foolish_1" then
                self:goToLine("foolish_2")
            else
                self:advance()
            end
        end

    elseif self.mode == "choice" then
        if Input.pressed("left") or Input.pressed("right") or Input.pressed("up") or Input.pressed("down") then
            self.choice_selected = (self.choice_selected == 1) and 2 or 1
            Assets.stopAndPlaySound("ui_move")
        end

        if Input.pressed("confirm") then
            Assets.stopAndPlaySound("ui_select")
            self:advance()
        end

    elseif self.mode == "invert_hold" then
        self.invert_timer = self.invert_timer + DT

        if self.invert_timer > 2.5 then
            self.menu:setState("TITLE")
        end

    elseif self.mode == "quitting" then
        self.quit_timer = self.quit_timer - DT

        if self.quit_timer <= 0 then
            love.event.quit()
        end
    end
end

-------------------------------------------------------------------------------
-- Отрисовка
-------------------------------------------------------------------------------

function MainMenuArchiveDialogue:draw()
    if self.invert_screen then
        love.graphics.setShader(INVERT_SHADER)
    end

    Draw.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    Draw.setColor(1, 1, 1, 1)

    local shown_text = utf8Sub(self.text or "", self.revealed or 0)

    Draw.printShadow(shown_text, 40, SCREEN_HEIGHT / 2 - 40, nil, "left", SCREEN_WIDTH - 80)

    if self.mode == "choice" and self.revealed >= utf8Length(self.text) then
        for i, option in ipairs(self.choice_options) do
            local x = 40 + (i - 1) * 120
            local y = SCREEN_HEIGHT / 2 + 40

            if self.choice_selected == i then
                Draw.printShadow("> " .. option, x, y)
            else
                Draw.printShadow("  " .. option, x, y)
            end
        end
    end

    if self.invert_screen then
        love.graphics.setShader()
    end
end

return MainMenuArchiveDialogue
