-----------------------------------------------------------
-- GMConvert -- утилиты для точного переноса атак Рыцаря из
-- оригинального (декомпилированного) GameMaker-кода в Kristal.
--
-- Источник расхождений и доказательства -- см.
-- GAMEMAKER_TO_KRISTAL_NOTES.md в корне мода. Кратко:
--
--   GameMaker: direction в ГРАДУСАХ, 0=право, 90=ВВЕРХ,
--   против часовой стрелки. Движение: dx=cos(dir), dy=-sin(dir).
--   (manual.gamemaker.io: GML_Reference/.../direction.htm)
--
--   Kristal (наш форк, src/engine/object.lua): direction в
--   РАДИАНАХ, dx=cos(direction), dy=sin(direction) -- БЕЗ
--   минуса. Значит 90° = ВНИЗ.
--
--   Из совпадения экранного смещения выводится:
--     kristal_rad = -math.rad(gm_deg)
--
-- Используем эту функцию для ЛЮБОГО значения direction /
-- gravity_direction / image_angle, взятого буквально из .gml
-- (а не вычисленного внутри уже сконвертированной Lua-логики --
-- относительные вычисления типа `direction - 180` конвертировать
-- второй раз НЕ нужно, они уже в системе координат Kristal).
-----------------------------------------------------------

GMConvert = {}

--- Переводит GameMaker-направление (градусы, 90=вверх, CCW)
--- в direction Kristal (радианы, 90°=вниз, как в физике движка).
---@param gm_deg number Угол в градусах, как в оригинальном .gml
---@return number # Угол в радианах для self.physics.direction / gravity_direction
function GMConvert.dir(gm_deg)
    return -math.rad(gm_deg)
end

--- Обратное преобразование: Kristal-радианы -> GM-градусы.
--- Нужно редко (например, для сверки с оригиналом в дебаге).
---@param kristal_rad number
---@return number
function GMConvert.gmDeg(kristal_rad)
    return -math.deg(kristal_rad)
end

--- GameMaker friction -- линейное вычитание из speed каждый шаг
--- (manual.gamemaker.io: .../friction.htm: "subtracting an amount
--- from the speed every step until the object has a speed of 0").
--- Kristal (object.lua:1905): physics.speed = MathUtils.approach(
--- physics.speed, 0, (physics.friction or 0) * DTMULT) -- тоже
--- линейно, за кадр при 30 FPS. Значения friction/speed/gravity
--- из .gml переносятся 1:1 В ПРЕДПОЛОЖЕНИИ, что комната
--- оригинала шла на room_speed = 30 (стандарт для Deltarune;
--- ТРЕБУЕТ подтверждения через .yyp/room-настройки при
--- расхождении на глаз). Эта функция ничего не считает -- это
--- просто фиксация факта в коде, чтобы не искать её заново.
GMConvert.SPEED_UNITS_MATCH_AT_ROOM_SPEED = 30

-- ВАЖНО (найдено на реальном крэше при тесте): scripts/globals/
-- регистрируется через Registry.initGlobals -> iterScripts, который
-- ИСПОЛНЯЕТ чанк файла и берёт РОВНО ТО, ЧТО ФАЙЛ ВОЗВРАЩАЕТ (см.
-- src/engine/registry.lua:656-664 и addChunk/iterScripts) -- присвоение
-- голой глобальной переменной (`GMConvert = {}`) без `return` в конце
-- НЕ регистрируется в реальный _G (чанк, похоже, исполняется в своём
-- sandboxed _ENV, а "наружу" уходит только возвращаемое значение).
-- Без этой строки код, использующий `GMConvert.dir(...)`, падал с
-- "attempt to index global 'GMConvert' (a nil value)". Использование
-- в knight_roaring_star.lua на данный момент заменено на инлайн
-- (-math.rad(angle)) по совету в чате, но сам файл оставлен
-- рабочим/правильным на будущее -- пример корректного паттерна:
-- сравните с уже работающим scripts/globals/ContinueQTE.lua, который
-- ВСЕГДА заканчивается на `return ContinueQTE` -- именно поэтому он
-- не ловил эту же ошибку.
return GMConvert
