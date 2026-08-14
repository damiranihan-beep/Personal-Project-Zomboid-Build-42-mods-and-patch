-- Guns of Marz Core Fixes v1.1
-- Build 42.20.2
--
-- Guns of Marz registers almost every integrated folding stock as permanent via
-- Gunworks PreventRemovals, but the FN FNC folded/deployed integrated stock pair
-- is missing from that registry.  The game's upgrade submenu therefore allows
-- the FNC stock to be detached into a loose service WeaponPart that cannot be
-- installed normally (its MountOn is MarzGuns.FakeItem).

local ok, PreventRemoval = pcall(require, "WeaponSystems/Utils/PreventRemovals")
if not ok or type(PreventRemoval) ~= "table" or type(PreventRemoval.Register) ~= "function" then
    print("[GoM Core Fixes] PreventRemovals unavailable; FNC permanent-stock registration skipped")
    return
end

PreventRemoval.Register({
    "MarzGuns.FNC_Integrated_Stock_Folded",
    "MarzGuns.FNC_Integrated_Stock_Deployed",
    "MarzGuns.M24_Integrated_Bipod_Folded",
    "MarzGuns.M24_Integrated_Bipod_Deployed",
})

print("[GoM Core Fixes] v1.1 registered FN FNC stock and M24 bipod as permanent")
