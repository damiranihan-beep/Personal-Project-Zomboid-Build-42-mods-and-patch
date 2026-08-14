-- Guns of Marz Attachment Rebalance v2.0.0
-- Scales standalone loot weights already inserted by Guns of Marz.
-- This deliberately does NOT create new loot routes for lasers/foregrips/etc.
require("Items/ProceduralDistributions/ProceduralDistributions")
require("Vehicles/VehicleDistributions")
require("Items/Distributions")
require("Items/Distribution_BagsAndContainers")

local C = require("GOMAttachmentRebalance/00_Config")
local tables = { ProceduralDistributions.list, VehicleDistributions, SuburbsDistributions, BagsAndContainers }
local applied = false

local function applyLootRarity()
    if applied then return end
    applied = true

    local changed = 0
    for _, lootTable in pairs(tables) do
        for _, data in pairs(lootTable) do
            if data.items then
                for i = 1, #data.items - 1, 2 do
                    local itemType = data.items[i]
                    local weight = data.items[i + 1]
                    if type(itemType) == "string" and type(weight) == "number" then
                        local factor = C.getSpawnFactor(itemType)
                        if factor ~= 1 then
                            data.items[i + 1] = weight * factor
                            changed = changed + 1
                        end
                    end
                end
            end
        end
    end

    print("[GOM Attachment Rebalance] v2.0.0 standalone loot rarity applied; entries=" .. tostring(changed))
end

Events.OnPostDistributionMerge.Add(applyLootRarity)
