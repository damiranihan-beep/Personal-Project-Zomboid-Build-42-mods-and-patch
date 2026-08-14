-- Guns of Marz Attachment Rebalance v1.0
-- Owns only attachment BALANCE. No suppressor logic and no compatibility-tooltip UI.
local CSA = require("WeaponSystems/Utils/CustomStatsAttachments")
local SF  = require("WeaponSystems/Utils/StatsFactory")

CSA.RegisterMultipleParts({
    ["MarzGuns.PL4_Sight"] = {
        SF.Multiply("CriticalChance", 1.01),
        SF.Multiply("HitChance", 1.01),
        SF.Multiply("MaxSightRange", 1.01),
        SF.Multiply("MinSightRange", 1.01),
    },
    ["MarzGuns.PS1_Sight"] = {
        SF.Multiply("CriticalChance", 1.03),
        SF.Multiply("HitChance", 1.03),
        SF.Multiply("MaxSightRange", 1.03),
        SF.Multiply("MinSightRange", 1.03),
    },
    ["MarzGuns.PM2_Sight"] = {
        SF.Multiply("CriticalChance", 1.06),
        SF.Multiply("HitChance", 1.06),
        SF.Multiply("MaxSightRange", 1.06),
        SF.Multiply("MinSightRange", 1.06),
    },
    ["MarzGuns.PRL1_Scope"] = {
        SF.Multiply("CriticalChance", 1.10),
        SF.Multiply("HitChance", 1.10),
        SF.Multiply("MaxSightRange", 1.10),
        SF.Multiply("MinSightRange", 1.10),
    },
})

print("[GOM Attachment Rebalance] v1.0 optic stats registered")
