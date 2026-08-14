-- Guns of Marz Attachment Rebalance v1.0
-- Patches only the four entries whose numeric stats we change.
-- Important: values are resolved through getText HERE, so raw UI_* keys are never intentionally displayed.
local ok, tableModule = pcall(require, "MarzWeapons/ItemTooltipsTable")
if not ok or not tableModule or not tableModule.tooltipsPergun then
    print("[GOM Attachment Rebalance] tooltip table unavailable; stats still active")
    return
end

local T = tableModule.tooltipsPergun
T["MarzGuns.PL4_Sight"] = {
    getText("UI_GOMAR_Optic_G1"),
    getText("UI_GOMAR_Optic_G1_Stats"),
    getText("UI_GOMAR_Optic_G1_Range"),
}
T["MarzGuns.PS1_Sight"] = {
    getText("UI_GOMAR_Optic_G2"),
    getText("UI_GOMAR_Optic_G2_Stats"),
    getText("UI_GOMAR_Optic_G2_Range"),
}
T["MarzGuns.PM2_Sight"] = {
    getText("UI_GOMAR_Optic_G3"),
    getText("UI_GOMAR_Optic_G3_Stats"),
    getText("UI_GOMAR_Optic_G3_Range"),
}
T["MarzGuns.PRL1_Scope"] = {
    getText("UI_GOMAR_Optic_G4"),
    getText("UI_GOMAR_Optic_G4_Stats"),
    getText("UI_GOMAR_Optic_G4_Range"),
}

print("[GOM Attachment Rebalance] v1.0 optic tooltip entries patched")
