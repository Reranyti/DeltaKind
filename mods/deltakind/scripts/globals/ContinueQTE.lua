-----------------------------------------------------------
-- CONTINUE QTE CONTROLLER
--
-- Реализует формулу из раздела 27 канона ДОСЛОВНО (1:1 перенос
-- математики, подтверждено автором):
--
--   wprog(t,a,b)  = clamp((t-a)/(b-a), 0, 1)
--   Tbase(t)      = 450                                  если t <= 22
--                   lerp(150, 30, wprog(t,23,40))         если 23 <= t <= 40
--                   30                                    если t >= 41
--   faillimit(t)  = Tbase(t) + 45   если t принадлежит {15,17,24,29,35}
--                   Tbase(t)        иначе
--
-- Единицы: РЕЗУЛЬТАТ Tbase/faillimit -- это лимит в кадрах при
-- 30 FPS (450 кадров = 15 сек, 30 кадров = 1 сек), это следует
-- из значений формулы и совпадает с DT = 1/30 в движке
-- (src/engine/statevars.lua).
--
-- t = индекс текущего вопроса/выбора (textind), НЕ время.
--
-- НЕ КАНОН / НЕ ОПРЕДЕЛЕНО (раздел 28-29, 42 канона):
--   - final_textind (на каком textind заканчивается QTE) --
--     НЕ утверждено. final_textind = 74 был явно ОТКЛОНЁН
--     автором как неподтверждённое предположение прошлой
--     сессии. Здесь он НЕ восстановлен и НЕ пересчитан заново
--     (даже por формуле "14-й вопрос + 60 быстрых выборов",
--     потому что канон прямо запрещает досчитывать это
--     самостоятельно). См. FINAL_TEXTIND ниже -- это плейсхолдер,
--     который обязательно нужно заменить перед реальным
--     использованием в игре.
--   - FAST_SEGMENT_START = 14 (раздел 28: "14-й вопрос") и
--     FAST_SEGMENT_COUNT = 60 (раздел 28: "60 быстрых выборов")
--     -- это единственные подтверждённые числа про быстрый
--     сегмент. Они используются только для вычисления вспышки
--     звука/тона, а НЕ для вычисления final_textind.
-----------------------------------------------------------

local ContinueQTE, super = Class()

-- ПРЕДПОЛОЖЕНИЕ / TODO: заменить на подтверждённое значение.
-- До тех пор ContinueQTE:isFinished() всегда возвращает false,
-- то есть цикл не завершится сам -- вызывающий код обязан
-- либо передать final_textind явно через ContinueQTE(...),
-- либо останавливать цикл по другому подтверждённому условию.
ContinueQTE.FINAL_TEXTIND_PLACEHOLDER = nil

ContinueQTE.FAST_SEGMENT_START = 14
ContinueQTE.FAST_SEGMENT_COUNT = 60

function ContinueQTE:init(final_textind)
    self.textind = 0
    self.timer = 0
    self.final_textind = final_textind or ContinueQTE.FINAL_TEXTIND_PLACEHOLDER

    self.failed = false
    self.done = false
end

function ContinueQTE.wprog(t, a, b)
    return MathUtils.clamp((t - a) / (b - a), 0, 1)
end

function ContinueQTE.Tbase(t)
    if t <= 22 then
        return 450
    elseif t <= 40 then
        return MathUtils.lerp(150, 30, ContinueQTE.wprog(t, 23, 40))
    else
        return 30
    end
end

local BONUS_INDICES = { [15] = true, [17] = true, [24] = true, [29] = true, [35] = true }

function ContinueQTE.faillimit(t)
    local base = ContinueQTE.Tbase(t)
    if BONUS_INDICES[t] then
        return base + 45
    end
    return base
end

--- Advances the current question's index and resets the timer for it.
--- Call this when the player successfully confirms a "Продолжай" prompt.
function ContinueQTE:choose()
    self.textind = self.textind + 1
    self.timer = 0

    if self.final_textind and self.textind >= self.final_textind then
        self.done = true
    end
end

--- Call once per fixed 30fps tick (matches DTMULT / DT convention used
--- elsewhere in this codebase). Returns true if this tick caused a
--- timeout failure.
function ContinueQTE:update()
    if self.done or self.failed then
        return false
    end

    self.timer = self.timer + DTMULT

    if self.timer >= ContinueQTE.faillimit(self.textind) then
        self.failed = true
        return true
    end

    return false
end

--- Returns 0-1 progress of the current question's timer toward its
--- fail limit (1 = about to time out). Intended for whiteout/static
--- intensity scaling (see cutscenes/kyle.lua side_b_qte).
function ContinueQTE:getTimerProgress()
    local limit = ContinueQTE.faillimit(self.textind)
    if limit <= 0 then
        return 1
    end
    return MathUtils.clamp(self.timer / limit, 0, 1)
end

--- True once past FAST_SEGMENT_START (raw index, not offset-adjusted --
--- exact relationship to final_textind is NOT confirmed, see header).
function ContinueQTE:isFastSegment()
    return self.textind >= ContinueQTE.FAST_SEGMENT_START
end

return ContinueQTE
