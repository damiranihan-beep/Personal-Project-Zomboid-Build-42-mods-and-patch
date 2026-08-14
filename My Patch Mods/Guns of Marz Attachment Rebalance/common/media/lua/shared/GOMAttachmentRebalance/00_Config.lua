-- Guns of Marz Attachment Rebalance v2.0.0
-- Single source of truth for approved generations, stat modifiers, and rarity factors.
local C = {}

C.SpawnFactors = {
    ["I"] = 1.6,
    ["II"] = 1.35,
    ["III"] = 1.1,
    ["IV"] = 0.9,
    ["V"] = 0.7,
    ["VI"] = 0.5,
    ["VII"] = 0.35,
    ["U"] = 1,
}

C.Items = {
    ["MarzGuns.PJ-3_Laser"] = { generation = "III", modifiers = {
        { stat = "AimingTime", multiplier = 0.9 },
        { stat = "HitChance", multiplier = 1.06 },
        { stat = "CriticalChance", multiplier = 1.06 },
    } },
    ["MarzGuns.PX1_Laser"] = { generation = "I", modifiers = {
        { stat = "AimingTime", multiplier = 0.95 },
        { stat = "HitChance", multiplier = 1.02 },
        { stat = "CriticalChance", multiplier = 1.02 },
    } },
    ["MarzGuns.TR-1_Laser"] = { generation = "II", modifiers = {
        { stat = "AimingTime", multiplier = 0.92 },
        { stat = "HitChance", multiplier = 1.04 },
        { stat = "CriticalChance", multiplier = 1.04 },
    } },
    ["MarzGuns.AimRight_Laser"] = { generation = "II", modifiers = {
        { stat = "AimingTime", multiplier = 0.92 },
        { stat = "HitChance", multiplier = 1.04 },
        { stat = "CriticalChance", multiplier = 1.04 },
    } },
    ["MarzGuns.LRX-7_Laser"] = { generation = "I", modifiers = {
        { stat = "AimingTime", multiplier = 0.95 },
        { stat = "HitChance", multiplier = 1.02 },
        { stat = "CriticalChance", multiplier = 1.02 },
    } },
    ["MarzGuns.PL4_Sight"] = { generation = "I", modifiers = {
        { stat = "HitChance", multiplier = 1.02 },
        { stat = "CriticalChance", multiplier = 1.02 },
    } },
    ["MarzGuns.PS1_Sight"] = { generation = "II", modifiers = {
        { stat = "HitChance", multiplier = 1.04 },
        { stat = "CriticalChance", multiplier = 1.04 },
        { stat = "MaxSightRange", multiplier = 1.03 },
        { stat = "MinSightRange", multiplier = 1.03 },
    } },
    ["MarzGuns.PM2_Sight"] = { generation = "III", modifiers = {
        { stat = "HitChance", multiplier = 1.07 },
        { stat = "CriticalChance", multiplier = 1.07 },
        { stat = "MaxSightRange", multiplier = 1.06 },
        { stat = "MinSightRange", multiplier = 1.06 },
    } },
    ["MarzGuns.ReflexS2_Sight"] = { generation = "III", modifiers = {
        { stat = "AimingTime", multiplier = 0.92 },
        { stat = "HitChance", multiplier = 1.1 },
        { stat = "CriticalChance", multiplier = 1.1 },
    } },
    ["MarzGuns.Kobra_Sight"] = { generation = "I", modifiers = {
        { stat = "AimingTime", multiplier = 0.96 },
        { stat = "HitChance", multiplier = 1.06 },
        { stat = "CriticalChance", multiplier = 1.06 },
    } },
    ["MarzGuns.OKP3_Sight"] = { generation = "II", modifiers = {
        { stat = "AimingTime", multiplier = 0.94 },
        { stat = "HitChance", multiplier = 1.08 },
        { stat = "CriticalChance", multiplier = 1.08 },
    } },
    ["MarzGuns.JS14_Sight"] = { generation = "VI", modifiers = {
        { stat = "AimingTime", multiplier = 0.9 },
        { stat = "HitChance", multiplier = 1.16 },
        { stat = "CriticalChance", multiplier = 1.16 },
        { stat = "MaxSightRange", multiplier = 1.12 },
        { stat = "MinSightRange", multiplier = 1.12 },
    } },
    ["MarzGuns.EXPS3_Sight"] = { generation = "V", modifiers = {
        { stat = "AimingTime", multiplier = 0.91 },
        { stat = "HitChance", multiplier = 1.13 },
        { stat = "CriticalChance", multiplier = 1.13 },
        { stat = "MaxSightRange", multiplier = 1.09 },
        { stat = "MinSightRange", multiplier = 1.09 },
    } },
    ["MarzGuns.EXPS1_Sight"] = { generation = "IV", modifiers = {
        { stat = "AimingTime", multiplier = 0.92 },
        { stat = "HitChance", multiplier = 1.11 },
        { stat = "CriticalChance", multiplier = 1.11 },
        { stat = "MaxSightRange", multiplier = 1.06 },
        { stat = "MinSightRange", multiplier = 1.06 },
    } },
    ["MarzGuns.Aimpoint_Sight"] = { generation = "VII", modifiers = {
        { stat = "AimingTime", multiplier = 0.88 },
        { stat = "HitChance", multiplier = 1.2 },
        { stat = "CriticalChance", multiplier = 1.2 },
        { stat = "MaxSightRange", multiplier = 1.15 },
        { stat = "MinSightRange", multiplier = 1.15 },
    } },
    ["MarzGuns.LR4X_Scope"] = { generation = "II", modifiers = {
        { stat = "AimingTime", multiplier = 1.12 },
        { stat = "HitChance", multiplier = 1.1 },
        { stat = "CriticalChance", multiplier = 1.1 },
        { stat = "MaxSightRange", multiplier = 1.25 },
        { stat = "MinSightRange", multiplier = 1.25 },
    } },
    ["MarzGuns.TA28_Scope"] = { generation = "III", modifiers = {
        { stat = "AimingTime", multiplier = 1.15 },
        { stat = "HitChance", multiplier = 1.13 },
        { stat = "CriticalChance", multiplier = 1.13 },
        { stat = "MaxSightRange", multiplier = 1.35 },
        { stat = "MinSightRange", multiplier = 1.35 },
    } },
    ["MarzGuns.ElcanX2_Scope"] = { generation = "I", modifiers = {
        { stat = "AimingTime", multiplier = 1.1 },
        { stat = "HitChance", multiplier = 1.08 },
        { stat = "CriticalChance", multiplier = 1.08 },
        { stat = "MaxSightRange", multiplier = 1.2 },
        { stat = "MinSightRange", multiplier = 1.2 },
    } },
    ["MarzGuns.TR06X_Scope"] = { generation = "IV", modifiers = {
        { stat = "AimingTime", multiplier = 1.18 },
        { stat = "HitChance", multiplier = 1.16 },
        { stat = "CriticalChance", multiplier = 1.16 },
        { stat = "MaxSightRange", multiplier = 1.45 },
        { stat = "MinSightRange", multiplier = 1.45 },
    } },
    ["MarzGuns.PSO1_Scope"] = { generation = "V", modifiers = {
        { stat = "AimingTime", multiplier = 1.22 },
        { stat = "HitChance", multiplier = 1.2 },
        { stat = "CriticalChance", multiplier = 1.2 },
        { stat = "MaxSightRange", multiplier = 1.6 },
        { stat = "MinSightRange", multiplier = 1.6 },
    } },
    ["MarzGuns.LR10X_Scope"] = { generation = "VI", modifiers = {
        { stat = "AimingTime", multiplier = 1.26 },
        { stat = "HitChance", multiplier = 1.25 },
        { stat = "CriticalChance", multiplier = 1.25 },
        { stat = "MaxSightRange", multiplier = 1.75 },
        { stat = "MinSightRange", multiplier = 1.75 },
    } },
    ["MarzGuns.LRX12X_Scope"] = { generation = "VII", modifiers = {
        { stat = "AimingTime", multiplier = 1.3 },
        { stat = "HitChance", multiplier = 1.3 },
        { stat = "CriticalChance", multiplier = 1.3 },
        { stat = "MaxSightRange", multiplier = 2 },
        { stat = "MinSightRange", multiplier = 2 },
    } },
    ["MarzGuns.Stub_Foregrip"] = { generation = "I", modifiers = {
        { stat = "AimingTime", multiplier = 0.9 },
        { stat = "HitChance", multiplier = 1.1 },
        { stat = "CriticalChance", multiplier = 1.1 },
    } },
    ["MarzGuns.MKC_Foregrip"] = { generation = "II", modifiers = {
        { stat = "AimingTime", multiplier = 0.85 },
        { stat = "HitChance", multiplier = 1.15 },
        { stat = "CriticalChance", multiplier = 1.15 },
    } },
    ["MarzGuns.MK2_Foregrip"] = { generation = "III", modifiers = {
        { stat = "AimingTime", multiplier = 0.8 },
        { stat = "HitChance", multiplier = 1.2 },
        { stat = "CriticalChance", multiplier = 1.2 },
    } },
}

C.UniqueItems = {
    ["MarzGuns.PRL1_Scope"] = "U",
    ["MarzGuns.Booster_Scope"] = "U",
    ["MarzGuns.Booster_Scope_Off"] = "U",
    ["MarzGuns.Bipod_Deployed"] = "U",
    ["MarzGuns.Bipod_Folded"] = "U",
}

function C.getGeneration(fullType)
    local entry = C.Items[fullType]
    if entry then return entry.generation end
    return C.UniqueItems[fullType]
end

function C.getSpawnFactor(fullType)
    local generation = C.getGeneration(fullType)
    return generation and C.SpawnFactors[generation] or 1
end

return C
