-----------------------------------------------------------
-- DELTAKIND META SAVE
--
-- Три постоянных мета-слота, независимых от обычных
-- слотов сохранения Kristal.
-----------------------------------------------------------

local DeltaKindMeta = {}

DeltaKindMeta.FILE = "deltakind_meta"
DeltaKindMeta.LEGACY_FILE = "deltakind_progress.json"
DeltaKindMeta.SLOT_COUNT = 3
DeltaKindMeta.active_slot = nil

local function makeSlot()
    return {
        beat_side_a = false,
        beat_side_b = false,
        unlocked_side_c = false,
        unlocked_colorful = false,
        archive_link = "...",
    }
end

local function makeData()
    return {
        meta_intro_seen = false,
        slots = {
            makeSlot(),
            makeSlot(),
            makeSlot(),
        },
    }
end

local function normalizeSlot(slot)
    local defaults = makeSlot()
    if type(slot) ~= "table" then
        return defaults
    end

    for key, value in pairs(defaults) do
        if slot[key] == nil then
            slot[key] = value
        end
    end

    return slot
end

local function normalizeData(data)
    local defaults = makeData()
    if type(data) ~= "table" then
        return defaults
    end

    if type(data.slots) ~= "table" then
        data.slots = defaults.slots
    end

    for i = 1, DeltaKindMeta.SLOT_COUNT do
        data.slots[i] = normalizeSlot(data.slots[i])
    end

    if data.meta_intro_seen == nil then
        data.meta_intro_seen = false
    end

    return data
end

local function getSavePath()
    return TARGET_MOD or "deltakind"
end

function DeltaKindMeta.load()
    local data = Kristal.loadData(DeltaKindMeta.FILE, getSavePath())
    if data then
        return normalizeData(data)
    end

    -- Переносим старый единый прогресс версии 1.0.1 в мета-слот 1.
    local legacy = Kristal.loadData(DeltaKindMeta.LEGACY_FILE, getSavePath())
    if legacy then
        data = makeData()
        data.slots[1] = normalizeSlot(legacy)
        return data
    end

    return makeData()
end

function DeltaKindMeta.save(data)
    data = normalizeData(data)
    Kristal.saveData(DeltaKindMeta.FILE, data, getSavePath())
    return data
end

function DeltaKindMeta.loadSlot(slot)
    slot = math.max(1, math.min(DeltaKindMeta.SLOT_COUNT, tonumber(slot) or 1))
    local data = DeltaKindMeta.load()
    return data.slots[slot]
end

function DeltaKindMeta.saveSlot(slot, slot_data)
    slot = math.max(1, math.min(DeltaKindMeta.SLOT_COUNT, tonumber(slot) or 1))
    local data = DeltaKindMeta.load()
    data.slots[slot] = normalizeSlot(slot_data)
    DeltaKindMeta.save(data)
end

function DeltaKindMeta.hasSlot(slot)
    local data = DeltaKindMeta.loadSlot(slot)
    for _, value in pairs(data) do
        if value ~= false and value ~= "..." and value ~= nil then
            return true
        end
    end
    return false
end

function DeltaKindMeta.eraseSlot(slot)
    slot = math.max(1, math.min(DeltaKindMeta.SLOT_COUNT, tonumber(slot) or 1))
    local data = DeltaKindMeta.load()
    data.slots[slot] = makeSlot()
    DeltaKindMeta.save(data)
end

function DeltaKindMeta.copySlot(source, target)
    source = math.max(1, math.min(DeltaKindMeta.SLOT_COUNT, tonumber(source) or 1))
    target = math.max(1, math.min(DeltaKindMeta.SLOT_COUNT, tonumber(target) or 1))
    local data = DeltaKindMeta.load()
    data.slots[target] = normalizeSlot(TableUtils.copy(data.slots[source]))
    DeltaKindMeta.save(data)
end

function DeltaKindMeta.setIntroSeen(value)
    local data = DeltaKindMeta.load()
    data.meta_intro_seen = value == true
    DeltaKindMeta.save(data)
end

function DeltaKindMeta.hasSeenIntro()
    return DeltaKindMeta.load().meta_intro_seen == true
end

function DeltaKindMeta.setActiveSlot(slot)
    slot = math.max(1, math.min(DeltaKindMeta.SLOT_COUNT, tonumber(slot) or 1))
    DeltaKindMeta.active_slot = slot
    return slot
end

function DeltaKindMeta.getActiveSlot()
    if not DeltaKindMeta.active_slot then
        DeltaKindMeta.active_slot = 1
    end
    return DeltaKindMeta.active_slot
end

function DeltaKindMeta.getActiveSlotData()
    return DeltaKindMeta.loadSlot(DeltaKindMeta.getActiveSlot())
end

function DeltaKindMeta.saveActiveSlot(data)
    DeltaKindMeta.saveSlot(DeltaKindMeta.getActiveSlot(), data)
end

return DeltaKindMeta
