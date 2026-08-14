-- GOM Homemade Suppressors - standalone SWMG registrations.
-- Fix 3.16: use MarzGuns Sound Overhaul sound map when available; keep stats registration isolated.
local okCSA, CSA = pcall(require, "WeaponSystems/Utils/CustomStatsAttachments")
local okSF, SF = pcall(require, "WeaponSystems/Utils/StatsFactory")

GOMHomemade = GOMHomemade or {}

-- Use MarzGuns Sound Overhaul's own *_silence report when it is present.
-- This avoids a tug-of-war where our old CapGun fallback and the sound overhaul
-- could replace SwingSound between rounds of one automatic burst.
function GOMHomemade.ResolveBaseSwingSound(weapon)
    if weapon and weapon.getType and marzSoundList then
        local base = marzSoundList[weapon:getType()]
        if type(base) == "string" and base ~= "" then
            return string.gsub(base, "_silence$", "")
        end
    end
    if weapon and weapon.getSwingSound then
        local current = weapon:getSwingSound()
        if type(current) == "string" and current ~= "" then
            return string.gsub(current, "_silence$", "")
        end
    end
    return nil
end

function GOMHomemade.ResolveSuppressedSwingSound(weapon)
    if weapon and weapon.getType and marzSoundList then
        local base = marzSoundList[weapon:getType()]
        if type(base) == "string" and base ~= "" then
            if string.find(base, "_silence", 1, true) then return base end
            return base .. "_silence"
        end
    end
    if weapon and weapon.getSwingSound then
        local current = weapon:getSwingSound()
        if type(current) == "string" and string.find(current, "_silence", 1, true) then
            return current
        end
    end
    return "CapGunRifleShoot"
end

function GOMHomemade.ApplySuppressedSwingSound(weapon)
    if not weapon or not weapon.setSwingSound then return end
    weapon:setSwingSound(GOMHomemade.ResolveSuppressedSwingSound(weapon))
end

function GOMHomemade.ApplyBrokenSwingSound(weapon)
    if not weapon or not weapon.setSwingSound then return end
    local base = GOMHomemade.ResolveBaseSwingSound(weapon)
    if base then weapon:setSwingSound(base) end
end

local function ApplySuppressedSwingSoundModifier(weapon, baseStats)
    GOMHomemade.ApplySuppressedSwingSound(weapon)
end
local function ApplyBrokenSwingSoundModifier(weapon, baseStats)
    GOMHomemade.ApplyBrokenSwingSound(weapon)
end
if not okCSA or not okSF then
    print("[GOM HS] WARNING: SWMG custom-stat API not available")
    return
end

CSA.RegisterRestoreStats({"SwingSound","SoundRadius","SoundVolume","MaxDamage","MinDamage","MaxRange","CriticalChance","CritDmgMultiplier"})
CSA.RegisterMultipleParts({
    ["HomemadeSuppressors.HomemadePlasticSuppressor"] = {
        SF.Multiply("SoundRadius",0.55), SF.Multiply("SoundVolume",0.55),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        ApplySuppressedSwingSoundModifier,
    },
    ["HomemadeSuppressors.HomemadeCanSuppressor"] = {
        SF.Multiply("SoundRadius",0.45), SF.Multiply("SoundVolume",0.45),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        ApplySuppressedSwingSoundModifier,
    },
    ["HomemadeSuppressors.HomemadePipeSuppressor"] = {
        SF.Multiply("SoundRadius",0.35), SF.Multiply("SoundVolume",0.35),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        ApplySuppressedSwingSoundModifier,
    },

    -- Last shot: suppression is 20 percentage points worse, but the shot
    -- still uses the suppressor sound. Other working penalties stay active.
    ["HomemadeSuppressors.HomemadePlasticSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.75), SF.Multiply("SoundVolume",0.75),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        ApplySuppressedSwingSoundModifier,
    },
    ["HomemadeSuppressors.HomemadeCanSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.65), SF.Multiply("SoundVolume",0.65),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        ApplySuppressedSwingSoundModifier,
    },
    ["HomemadeSuppressors.HomemadePipeSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.55), SF.Multiply("SoundVolume",0.55),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        ApplySuppressedSwingSoundModifier,
    },

    -- Broken metal suppressors remain attached.
    ["HomemadeSuppressors.HomemadeCanSuppressor_Broken"] = {
        SF.Multiply("SoundRadius",1.10), SF.Multiply("SoundVolume",1.10),
        SF.Multiply("MaxDamage",0.80), SF.Multiply("MinDamage",0.80),
        SF.Multiply("MaxRange",0.80),
        SF.Multiply("CriticalChance",0.90),
        SF.Multiply("CritDmgMultiplier",0.80),
        ApplyBrokenSwingSoundModifier,
    },
    ["HomemadeSuppressors.HomemadePipeSuppressor_Broken"] = {
        SF.Multiply("SoundRadius",1.10), SF.Multiply("SoundVolume",1.10),
        SF.Multiply("MaxDamage",0.80), SF.Multiply("MinDamage",0.80),
        SF.Multiply("MaxRange",0.80),
        SF.Multiply("CriticalChance",0.90),
        SF.Multiply("CritDmgMultiplier",0.80),
        ApplyBrokenSwingSoundModifier,
    },

    ["MarzGuns.HomemadePlasticSuppressor"] = {
        SF.Multiply("SoundRadius",0.55), SF.Multiply("SoundVolume",0.55),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        ApplySuppressedSwingSoundModifier,
    },
    ["MarzGuns.HomemadeCanSuppressor"] = {
        SF.Multiply("SoundRadius",0.45), SF.Multiply("SoundVolume",0.45),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        ApplySuppressedSwingSoundModifier,
    },
    ["MarzGuns.HomemadePipeSuppressor"] = {
        SF.Multiply("SoundRadius",0.35), SF.Multiply("SoundVolume",0.35),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        ApplySuppressedSwingSoundModifier,
    },

    -- Last shot: suppression is 20 percentage points worse, but the shot
    -- still uses the suppressor sound. Other working penalties stay active.
    ["MarzGuns.HomemadePlasticSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.75), SF.Multiply("SoundVolume",0.75),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        ApplySuppressedSwingSoundModifier,
    },
    ["MarzGuns.HomemadeCanSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.65), SF.Multiply("SoundVolume",0.65),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        ApplySuppressedSwingSoundModifier,
    },
    ["MarzGuns.HomemadePipeSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.55), SF.Multiply("SoundVolume",0.55),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        ApplySuppressedSwingSoundModifier,
    },

    -- Broken metal suppressors remain attached.
    ["MarzGuns.HomemadeCanSuppressor_Broken"] = {
        SF.Multiply("SoundRadius",1.10), SF.Multiply("SoundVolume",1.10),
        SF.Multiply("MaxDamage",0.80), SF.Multiply("MinDamage",0.80),
        SF.Multiply("MaxRange",0.80),
        SF.Multiply("CriticalChance",0.90),
        SF.Multiply("CritDmgMultiplier",0.80),
        ApplyBrokenSwingSoundModifier,
    },
    ["MarzGuns.HomemadePipeSuppressor_Broken"] = {
        SF.Multiply("SoundRadius",1.10), SF.Multiply("SoundVolume",1.10),
        SF.Multiply("MaxDamage",0.80), SF.Multiply("MinDamage",0.80),
        SF.Multiply("MaxRange",0.80),
        SF.Multiply("CriticalChance",0.90),
        SF.Multiply("CritDmgMultiplier",0.80),
        ApplyBrokenSwingSoundModifier,
    },

})

-- Preserve GoM bayonet/muzzle incompatibility without rewriting its Bayonets.lua.
local okB, Bayonet = pcall(require, "WeaponSystems/Utils/Bayonet")
if okB and Bayonet and Bayonet.SetExclusives then
    Bayonet.SetExclusives(
        {"MarzGuns.K98_Bayonet_Attachment","MarzGuns.M5_Bayonet_Attachment","MarzGuns.M9_Bayonet_Attachment"},
        {"HomemadeSuppressors.HomemadePlasticSuppressor","HomemadeSuppressors.HomemadePlasticSuppressor_Critical",
         "HomemadeSuppressors.HomemadeCanSuppressor","HomemadeSuppressors.HomemadeCanSuppressor_Critical","HomemadeSuppressors.HomemadeCanSuppressor_Broken",
         "HomemadeSuppressors.HomemadePipeSuppressor","HomemadeSuppressors.HomemadePipeSuppressor_Critical","HomemadeSuppressors.HomemadePipeSuppressor_Broken",
         "MarzGuns.HomemadePlasticSuppressor","MarzGuns.HomemadePlasticSuppressor_Critical",
         "MarzGuns.HomemadeCanSuppressor","MarzGuns.HomemadeCanSuppressor_Critical","MarzGuns.HomemadeCanSuppressor_Broken",
         "MarzGuns.HomemadePipeSuppressor","MarzGuns.HomemadePipeSuppressor_Critical","MarzGuns.HomemadePipeSuppressor_Broken"}
    )
end

print("[GOM HS] Fix 3.16 stats/exclusives registered")
