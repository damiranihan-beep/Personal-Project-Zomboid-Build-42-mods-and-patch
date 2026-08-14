-- Guns of Marz Attachment Rebalance v2.0.0
-- Scales EXISTING Guns of Marz optional-attachment rolls by approved generation.
-- No new attachment entries are created. Required mount codes are preserved verbatim.
local C = require("GOMAttachmentRebalance/00_Config")
local ok, AP = pcall(require, "MarzWeapons/OnCreate/AttachmentPointsTable")
if not ok or not AP or not AP.weaponAttachmentTablesAndChances then
    print("[GOM Attachment Rebalance] spawn table unavailable; installed rarity unchanged")
    return
end

local function parse(entry)
    local itemType, chance, mount = string.match(entry, "^([^:]+):([^:]+):([^:]+)$")
    if itemType then return itemType, tonumber(chance) or 0, mount end
    itemType, chance = string.match(entry, "^([^:]+):([^:]+)$")
    if itemType then return itemType, tonumber(chance) or 0, nil end
    return entry, 100, nil
end

local function roundChance(stockChance, factor)
    if stockChance <= 0 then return stockChance end
    local value = math.floor(stockChance * factor + 0.5)
    if value < 1 then value = 1 end
    if value > 100 then value = 100 end
    return value
end

local changed = 0
local inspected = 0
for _, data in pairs(AP.weaponAttachmentTablesAndChances) do
    local optionals = data and data.optionals
    if optionals then
        for i = 1, #optionals do
            local raw = optionals[i]
            local itemType, stockChance, mount = parse(raw)
            local factor = C.getSpawnFactor(itemType)
            if factor ~= 1 then
                inspected = inspected + 1
                local planned = roundChance(stockChance, factor)
                local rebuilt = itemType .. ":" .. tostring(planned)
                if mount then rebuilt = rebuilt .. ":" .. mount end
                if rebuilt ~= raw then
                    optionals[i] = rebuilt
                    changed = changed + 1
                end
            end
        end
    end
end

print("[GOM Attachment Rebalance] v2.0.0 installed rarity applied; targets=" .. tostring(inspected) .. ", changed=" .. tostring(changed))
