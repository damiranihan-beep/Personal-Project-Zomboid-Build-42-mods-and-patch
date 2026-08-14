-- Guns of Marz Attachment Rebalance v2.0.0
-- Replaces ONLY selected Guns of Marz attachment stat registry entries.
-- Suppressors, mounts, lights, unique Booster/PRL-1/Bipod and integrated weapon parts stay stock.
local C   = require("GOMAttachmentRebalance/00_Config")
local CSA = require("WeaponSystems/Utils/CustomStatsAttachments")
local SF  = require("WeaponSystems/Utils/StatsFactory")

local parts = {}
local touchedStats = {}

for fullType, entry in pairs(C.Items) do
    local modifiers = {}
    for _, spec in ipairs(entry.modifiers or {}) do
        touchedStats[spec.stat] = true
        modifiers[#modifiers + 1] = SF.Multiply(spec.stat, spec.multiplier)
    end
    parts[fullType] = modifiers
end

local restore = {}
for statName in pairs(touchedStats) do restore[#restore + 1] = statName end
CSA.RegisterRestoreStats(restore)
CSA.RegisterMultipleParts(parts)

local count = 0
for _ in pairs(parts) do count = count + 1 end
print("[GOM Attachment Rebalance] v2.0.0 stats registered; items=" .. tostring(count))
