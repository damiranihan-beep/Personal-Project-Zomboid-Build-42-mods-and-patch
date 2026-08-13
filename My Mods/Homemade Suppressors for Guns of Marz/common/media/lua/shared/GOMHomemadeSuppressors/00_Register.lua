-- GOM Homemade Suppressors - standalone SWMG registrations.
-- This file only registers new part IDs; it does not replace Guns of Marz registry files.
local okCSA, CSA = pcall(require, "WeaponSystems/Utils/CustomStatsAttachments")
local okSF, SF = pcall(require, "WeaponSystems/Utils/StatsFactory")
if not okCSA or not okSF then
    print("[GOM HS] WARNING: SWMG custom-stat API not available")
    return
end

CSA.RegisterRestoreStats({"SwingSound","SoundRadius","SoundVolume","MaxDamage","MinDamage","MaxRange"})
CSA.RegisterMultipleParts({
    ["HomemadeSuppressors.HomemadePlasticSuppressor"] = {
        SF.Multiply("SoundRadius",0.55), SF.Multiply("SoundVolume",0.55),
        SF.Multiply("MaxDamage",0.80), SF.Multiply("MinDamage",0.80),
        SF.Multiply("MaxRange",0.80),
        SF.Set("SwingSound","CapGunRifleShoot"),
    },
    ["HomemadeSuppressors.HomemadeCanSuppressor"] = {
        SF.Multiply("SoundRadius",0.45), SF.Multiply("SoundVolume",0.45),
        SF.Multiply("MaxDamage",0.80), SF.Multiply("MinDamage",0.80),
        SF.Multiply("MaxRange",0.80),
        SF.Set("SwingSound","CapGunRifleShoot"),
    },
    ["HomemadeSuppressors.HomemadePipeSuppressor"] = {
        SF.Multiply("SoundRadius",0.35), SF.Multiply("SoundVolume",0.35),
        SF.Multiply("MaxDamage",0.80), SF.Multiply("MinDamage",0.80),
        SF.Multiply("MaxRange",0.80),
        SF.Set("SwingSound","CapGunRifleShoot"),
    },
    ["HomemadeSuppressors.HomemadePlasticSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.85), SF.Multiply("SoundVolume",0.85),
        SF.Multiply("MaxDamage",0.80), SF.Multiply("MinDamage",0.80),
        SF.Multiply("MaxRange",0.80),
    },
    ["HomemadeSuppressors.HomemadeCanSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.75), SF.Multiply("SoundVolume",0.75),
        SF.Multiply("MaxDamage",0.80), SF.Multiply("MinDamage",0.80),
        SF.Multiply("MaxRange",0.80),
    },
    ["HomemadeSuppressors.HomemadePipeSuppressor_Critical"] = {
        SF.Multiply("SoundRadius",0.65), SF.Multiply("SoundVolume",0.65),
        SF.Multiply("MaxDamage",0.80), SF.Multiply("MinDamage",0.80),
        SF.Multiply("MaxRange",0.80),
    },
    ["HomemadeSuppressors.HomemadeCanSuppressor_Broken"] = {
        SF.Multiply("SoundRadius",1.10), SF.Multiply("SoundVolume",1.10),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.70),
    },
    ["HomemadeSuppressors.HomemadePipeSuppressor_Broken"] = {
        SF.Multiply("SoundRadius",1.10), SF.Multiply("SoundVolume",1.10),
        SF.Multiply("MaxDamage",0.90), SF.Multiply("MinDamage",0.90),
        SF.Multiply("MaxRange",0.70),
    },
})

-- Preserve GoM bayonet/muzzle incompatibility without rewriting its Bayonets.lua.
local okB, Bayonet = pcall(require, "WeaponSystems/Utils/Bayonet")
if okB and Bayonet and Bayonet.SetExclusives then
    Bayonet.SetExclusives(
        {"MarzGuns.K98_Bayonet_Attachment","MarzGuns.M5_Bayonet_Attachment","MarzGuns.M9_Bayonet_Attachment"},
        {"HomemadeSuppressors.HomemadePlasticSuppressor","HomemadeSuppressors.HomemadePlasticSuppressor_Critical",
         "HomemadeSuppressors.HomemadeCanSuppressor","HomemadeSuppressors.HomemadeCanSuppressor_Critical","HomemadeSuppressors.HomemadeCanSuppressor_Broken",
         "HomemadeSuppressors.HomemadePipeSuppressor","HomemadeSuppressors.HomemadePipeSuppressor_Critical","HomemadeSuppressors.HomemadePipeSuppressor_Broken"}
    )
end

print("[GOM HS] SWMG stats/exclusives registered")
