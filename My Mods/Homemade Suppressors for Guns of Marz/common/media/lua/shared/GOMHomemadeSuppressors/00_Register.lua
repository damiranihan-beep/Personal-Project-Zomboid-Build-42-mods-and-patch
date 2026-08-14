-- GOM Homemade Suppressors - standalone SWMG registrations.
-- Fix 3.11: final agreed suppressor balance for Build 42.20.2.
local okCSA, CSA = pcall(require, "WeaponSystems/Utils/CustomStatsAttachments")
local okSF, SF = pcall(require, "WeaponSystems/Utils/StatsFactory")
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
        SF.Set("SwingSound","CapGunRifleShoot"),
    },
    ["HomemadeSuppressors.HomemadeCanSuppressor"] = {
        SF.Multiply("SoundRadius",0.45), SF.Multiply("SoundVolume",0.45),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        SF.Set("SwingSound","CapGunRifleShoot"),
    },
    ["HomemadeSuppressors.HomemadePipeSuppressor"] = {
        SF.Multiply("SoundRadius",0.35), SF.Multiply("SoundVolume",0.35),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        SF.Set("SwingSound","CapGunRifleShoot"),
    },

    -- Last shot: suppression is 20 percentage points worse, but the shot
    -- still uses the suppressor sound. Other working penalties stay active.
    ["HomemadeSuppressors.HomemadePlasticSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.75), SF.Multiply("SoundVolume",0.75),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        SF.Set("SwingSound","CapGunRifleShoot"),
    },
    ["HomemadeSuppressors.HomemadeCanSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.65), SF.Multiply("SoundVolume",0.65),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        SF.Set("SwingSound","CapGunRifleShoot"),
    },
    ["HomemadeSuppressors.HomemadePipeSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.55), SF.Multiply("SoundVolume",0.55),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        SF.Set("SwingSound","CapGunRifleShoot"),
    },

    -- Broken metal suppressors remain attached.
    ["HomemadeSuppressors.HomemadeCanSuppressor_Broken"] = {
        SF.Multiply("SoundRadius",1.10), SF.Multiply("SoundVolume",1.10),
        SF.Multiply("MaxDamage",0.80), SF.Multiply("MinDamage",0.80),
        SF.Multiply("MaxRange",0.80),
        SF.Multiply("CriticalChance",0.90),
        SF.Multiply("CritDmgMultiplier",0.80),
    },
    ["HomemadeSuppressors.HomemadePipeSuppressor_Broken"] = {
        SF.Multiply("SoundRadius",1.10), SF.Multiply("SoundVolume",1.10),
        SF.Multiply("MaxDamage",0.80), SF.Multiply("MinDamage",0.80),
        SF.Multiply("MaxRange",0.80),
        SF.Multiply("CriticalChance",0.90),
        SF.Multiply("CritDmgMultiplier",0.80),
    },

    ["MarzGuns.HomemadePlasticSuppressor"] = {
        SF.Multiply("SoundRadius",0.55), SF.Multiply("SoundVolume",0.55),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        SF.Set("SwingSound","CapGunRifleShoot"),
    },
    ["MarzGuns.HomemadeCanSuppressor"] = {
        SF.Multiply("SoundRadius",0.45), SF.Multiply("SoundVolume",0.45),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        SF.Set("SwingSound","CapGunRifleShoot"),
    },
    ["MarzGuns.HomemadePipeSuppressor"] = {
        SF.Multiply("SoundRadius",0.35), SF.Multiply("SoundVolume",0.35),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        SF.Set("SwingSound","CapGunRifleShoot"),
    },

    -- Last shot: suppression is 20 percentage points worse, but the shot
    -- still uses the suppressor sound. Other working penalties stay active.
    ["MarzGuns.HomemadePlasticSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.75), SF.Multiply("SoundVolume",0.75),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        SF.Set("SwingSound","CapGunRifleShoot"),
    },
    ["MarzGuns.HomemadeCanSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.65), SF.Multiply("SoundVolume",0.65),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        SF.Set("SwingSound","CapGunRifleShoot"),
    },
    ["MarzGuns.HomemadePipeSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.55), SF.Multiply("SoundVolume",0.55),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.90),
        SF.Multiply("CriticalChance",0.90),
        SF.Set("SwingSound","CapGunRifleShoot"),
    },

    -- Broken metal suppressors remain attached.
    ["MarzGuns.HomemadeCanSuppressor_Broken"] = {
        SF.Multiply("SoundRadius",1.10), SF.Multiply("SoundVolume",1.10),
        SF.Multiply("MaxDamage",0.80), SF.Multiply("MinDamage",0.80),
        SF.Multiply("MaxRange",0.80),
        SF.Multiply("CriticalChance",0.90),
        SF.Multiply("CritDmgMultiplier",0.80),
    },
    ["MarzGuns.HomemadePipeSuppressor_Broken"] = {
        SF.Multiply("SoundRadius",1.10), SF.Multiply("SoundVolume",1.10),
        SF.Multiply("MaxDamage",0.80), SF.Multiply("MinDamage",0.80),
        SF.Multiply("MaxRange",0.80),
        SF.Multiply("CriticalChance",0.90),
        SF.Multiply("CritDmgMultiplier",0.80),
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

print("[GOM HS] Fix 3.11 stats/exclusives registered")
