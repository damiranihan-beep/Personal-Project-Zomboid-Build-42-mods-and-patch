-- Fix 3.6: four-tier pistol optic rebalance requested for Guns of Marz.
-- Later registration intentionally replaces the original stats for these exact parts.
local CSA = require("WeaponSystems/Utils/CustomStatsAttachments")
local SF  = require("WeaponSystems/Utils/StatsFactory")

CSA.RegisterMultipleParts({
    -- Generation I: +1% accuracy/critical/sight range.
    ["MarzGuns.PL4_Sight"] = {
        SF.Multiply("CriticalChance", 1.01),
        SF.Multiply("HitChance", 1.01),
        SF.Multiply("MaxSightRange", 1.01),
        SF.Multiply("MinSightRange", 1.01),
    },
    -- Generation II: +3%.
    ["MarzGuns.PS1_Sight"] = {
        SF.Multiply("CriticalChance", 1.03),
        SF.Multiply("HitChance", 1.03),
        SF.Multiply("MaxSightRange", 1.03),
        SF.Multiply("MinSightRange", 1.03),
    },
    -- Generation III: +6%.
    ["MarzGuns.PM2_Sight"] = {
        SF.Multiply("CriticalChance", 1.06),
        SF.Multiply("HitChance", 1.06),
        SF.Multiply("MaxSightRange", 1.06),
        SF.Multiply("MinSightRange", 1.06),
    },
    -- Generation IV: +10%.
    ["MarzGuns.PRL1_Scope"] = {
        SF.Multiply("CriticalChance", 1.10),
        SF.Multiply("HitChance", 1.10),
        SF.Multiply("MaxSightRange", 1.10),
        SF.Multiply("MinSightRange", 1.10),
    },
})
