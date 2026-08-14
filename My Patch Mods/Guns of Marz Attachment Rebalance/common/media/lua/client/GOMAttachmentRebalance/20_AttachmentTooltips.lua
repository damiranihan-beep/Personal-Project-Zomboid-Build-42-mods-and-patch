-- Guns of Marz Attachment Rebalance v2.0.0
-- Replaces stale STOCK tooltip lines only for attachments whose stats are rebalanced.
local ok, tableModule = pcall(require, "MarzWeapons/ItemTooltipsTable")
if not ok or not tableModule or not tableModule.tooltipsPergun then
    print("[GOM Attachment Rebalance] tooltip table unavailable; gameplay rebalance remains active")
    return
end

local T = tableModule.tooltipsPergun
local KEYSETS = {
    ["MarzGuns.PJ-3_Laser"] = {
        "UI_GOMAR2_PJ_3_Laser_Generation",
        "UI_GOMAR2_PJ_3_Laser_Stat1",
        "UI_GOMAR2_PJ_3_Laser_Stat2",
    },
    ["MarzGuns.PX1_Laser"] = {
        "UI_GOMAR2_PX1_Laser_Generation",
        "UI_GOMAR2_PX1_Laser_Stat1",
        "UI_GOMAR2_PX1_Laser_Stat2",
    },
    ["MarzGuns.TR-1_Laser"] = {
        "UI_GOMAR2_TR_1_Laser_Generation",
        "UI_GOMAR2_TR_1_Laser_Stat1",
        "UI_GOMAR2_TR_1_Laser_Stat2",
    },
    ["MarzGuns.AimRight_Laser"] = {
        "UI_GOMAR2_AimRight_Laser_Generation",
        "UI_GOMAR2_AimRight_Laser_Stat1",
        "UI_GOMAR2_AimRight_Laser_Stat2",
    },
    ["MarzGuns.LRX-7_Laser"] = {
        "UI_GOMAR2_LRX_7_Laser_Generation",
        "UI_GOMAR2_LRX_7_Laser_Stat1",
        "UI_GOMAR2_LRX_7_Laser_Stat2",
    },
    ["MarzGuns.PL4_Sight"] = {
        "UI_GOMAR2_PL4_Sight_Generation",
        "UI_GOMAR2_PL4_Sight_Stat1",
    },
    ["MarzGuns.PS1_Sight"] = {
        "UI_GOMAR2_PS1_Sight_Generation",
        "UI_GOMAR2_PS1_Sight_Stat1",
        "UI_GOMAR2_PS1_Sight_Stat2",
    },
    ["MarzGuns.PM2_Sight"] = {
        "UI_GOMAR2_PM2_Sight_Generation",
        "UI_GOMAR2_PM2_Sight_Stat1",
        "UI_GOMAR2_PM2_Sight_Stat2",
    },
    ["MarzGuns.ReflexS2_Sight"] = {
        "UI_GOMAR2_ReflexS2_Sight_Generation",
        "UI_GOMAR2_ReflexS2_Sight_Stat1",
        "UI_GOMAR2_ReflexS2_Sight_Stat2",
    },
    ["MarzGuns.Kobra_Sight"] = {
        "UI_GOMAR2_Kobra_Sight_Generation",
        "UI_GOMAR2_Kobra_Sight_Stat1",
        "UI_GOMAR2_Kobra_Sight_Stat2",
    },
    ["MarzGuns.OKP3_Sight"] = {
        "UI_GOMAR2_OKP3_Sight_Generation",
        "UI_GOMAR2_OKP3_Sight_Stat1",
        "UI_GOMAR2_OKP3_Sight_Stat2",
    },
    ["MarzGuns.JS14_Sight"] = {
        "UI_GOMAR2_JS14_Sight_Generation",
        "UI_GOMAR2_JS14_Sight_Stat1",
        "UI_GOMAR2_JS14_Sight_Stat2",
        "UI_GOMAR2_JS14_Sight_Stat3",
    },
    ["MarzGuns.EXPS3_Sight"] = {
        "UI_GOMAR2_EXPS3_Sight_Generation",
        "UI_GOMAR2_EXPS3_Sight_Stat1",
        "UI_GOMAR2_EXPS3_Sight_Stat2",
        "UI_GOMAR2_EXPS3_Sight_Stat3",
    },
    ["MarzGuns.EXPS1_Sight"] = {
        "UI_GOMAR2_EXPS1_Sight_Generation",
        "UI_GOMAR2_EXPS1_Sight_Stat1",
        "UI_GOMAR2_EXPS1_Sight_Stat2",
        "UI_GOMAR2_EXPS1_Sight_Stat3",
    },
    ["MarzGuns.Aimpoint_Sight"] = {
        "UI_GOMAR2_Aimpoint_Sight_Generation",
        "UI_GOMAR2_Aimpoint_Sight_Stat1",
        "UI_GOMAR2_Aimpoint_Sight_Stat2",
        "UI_GOMAR2_Aimpoint_Sight_Stat3",
    },
    ["MarzGuns.LR4X_Scope"] = {
        "UI_GOMAR2_LR4X_Scope_Generation",
        "UI_GOMAR2_LR4X_Scope_Stat1",
        "UI_GOMAR2_LR4X_Scope_Stat2",
        "UI_GOMAR2_LR4X_Scope_Stat3",
    },
    ["MarzGuns.TA28_Scope"] = {
        "UI_GOMAR2_TA28_Scope_Generation",
        "UI_GOMAR2_TA28_Scope_Stat1",
        "UI_GOMAR2_TA28_Scope_Stat2",
        "UI_GOMAR2_TA28_Scope_Stat3",
    },
    ["MarzGuns.ElcanX2_Scope"] = {
        "UI_GOMAR2_ElcanX2_Scope_Generation",
        "UI_GOMAR2_ElcanX2_Scope_Stat1",
        "UI_GOMAR2_ElcanX2_Scope_Stat2",
        "UI_GOMAR2_ElcanX2_Scope_Stat3",
    },
    ["MarzGuns.TR06X_Scope"] = {
        "UI_GOMAR2_TR06X_Scope_Generation",
        "UI_GOMAR2_TR06X_Scope_Stat1",
        "UI_GOMAR2_TR06X_Scope_Stat2",
        "UI_GOMAR2_TR06X_Scope_Stat3",
    },
    ["MarzGuns.PSO1_Scope"] = {
        "UI_GOMAR2_PSO1_Scope_Generation",
        "UI_GOMAR2_PSO1_Scope_Stat1",
        "UI_GOMAR2_PSO1_Scope_Stat2",
        "UI_GOMAR2_PSO1_Scope_Stat3",
    },
    ["MarzGuns.LR10X_Scope"] = {
        "UI_GOMAR2_LR10X_Scope_Generation",
        "UI_GOMAR2_LR10X_Scope_Stat1",
        "UI_GOMAR2_LR10X_Scope_Stat2",
        "UI_GOMAR2_LR10X_Scope_Stat3",
    },
    ["MarzGuns.LRX12X_Scope"] = {
        "UI_GOMAR2_LRX12X_Scope_Generation",
        "UI_GOMAR2_LRX12X_Scope_Stat1",
        "UI_GOMAR2_LRX12X_Scope_Stat2",
        "UI_GOMAR2_LRX12X_Scope_Stat3",
    },
    ["MarzGuns.Stub_Foregrip"] = {
        "UI_GOMAR2_Stub_Foregrip_Generation",
        "UI_GOMAR2_Stub_Foregrip_Stat1",
        "UI_GOMAR2_Stub_Foregrip_Stat2",
    },
    ["MarzGuns.MKC_Foregrip"] = {
        "UI_GOMAR2_MKC_Foregrip_Generation",
        "UI_GOMAR2_MKC_Foregrip_Stat1",
        "UI_GOMAR2_MKC_Foregrip_Stat2",
    },
    ["MarzGuns.MK2_Foregrip"] = {
        "UI_GOMAR2_MK2_Foregrip_Generation",
        "UI_GOMAR2_MK2_Foregrip_Stat1",
        "UI_GOMAR2_MK2_Foregrip_Stat2",
    },
}

local FALLBACK = {
    ["UI_GOMAR2_PJ_3_Laser_Generation"] = "Generation III",
    ["UI_GOMAR2_PJ_3_Laser_Stat1"] = "Aiming Time reduced by 10%",
    ["UI_GOMAR2_PJ_3_Laser_Stat2"] = "Critical and Hit Chance increased by 6%",
    ["UI_GOMAR2_PX1_Laser_Generation"] = "Generation I",
    ["UI_GOMAR2_PX1_Laser_Stat1"] = "Aiming Time reduced by 5%",
    ["UI_GOMAR2_PX1_Laser_Stat2"] = "Critical and Hit Chance increased by 2%",
    ["UI_GOMAR2_TR_1_Laser_Generation"] = "Generation II",
    ["UI_GOMAR2_TR_1_Laser_Stat1"] = "Aiming Time reduced by 8%",
    ["UI_GOMAR2_TR_1_Laser_Stat2"] = "Critical and Hit Chance increased by 4%",
    ["UI_GOMAR2_AimRight_Laser_Generation"] = "Generation II",
    ["UI_GOMAR2_AimRight_Laser_Stat1"] = "Aiming Time reduced by 8%",
    ["UI_GOMAR2_AimRight_Laser_Stat2"] = "Critical and Hit Chance increased by 4%",
    ["UI_GOMAR2_LRX_7_Laser_Generation"] = "Generation I",
    ["UI_GOMAR2_LRX_7_Laser_Stat1"] = "Aiming Time reduced by 5%",
    ["UI_GOMAR2_LRX_7_Laser_Stat2"] = "Critical and Hit Chance increased by 2%",
    ["UI_GOMAR2_PL4_Sight_Generation"] = "Generation I",
    ["UI_GOMAR2_PL4_Sight_Stat1"] = "Critical and Hit Chance increased by 2%",
    ["UI_GOMAR2_PS1_Sight_Generation"] = "Generation II",
    ["UI_GOMAR2_PS1_Sight_Stat1"] = "Critical and Hit Chance increased by 4%",
    ["UI_GOMAR2_PS1_Sight_Stat2"] = "Sight Range increased by 3%",
    ["UI_GOMAR2_PM2_Sight_Generation"] = "Generation III",
    ["UI_GOMAR2_PM2_Sight_Stat1"] = "Critical and Hit Chance increased by 7%",
    ["UI_GOMAR2_PM2_Sight_Stat2"] = "Sight Range increased by 6%",
    ["UI_GOMAR2_ReflexS2_Sight_Generation"] = "Generation III",
    ["UI_GOMAR2_ReflexS2_Sight_Stat1"] = "Aiming Time reduced by 8%",
    ["UI_GOMAR2_ReflexS2_Sight_Stat2"] = "Critical and Hit Chance increased by 10%",
    ["UI_GOMAR2_Kobra_Sight_Generation"] = "Generation I",
    ["UI_GOMAR2_Kobra_Sight_Stat1"] = "Aiming Time reduced by 4%",
    ["UI_GOMAR2_Kobra_Sight_Stat2"] = "Critical and Hit Chance increased by 6%",
    ["UI_GOMAR2_OKP3_Sight_Generation"] = "Generation II",
    ["UI_GOMAR2_OKP3_Sight_Stat1"] = "Aiming Time reduced by 6%",
    ["UI_GOMAR2_OKP3_Sight_Stat2"] = "Critical and Hit Chance increased by 8%",
    ["UI_GOMAR2_JS14_Sight_Generation"] = "Generation VI",
    ["UI_GOMAR2_JS14_Sight_Stat1"] = "Aiming Time reduced by 10%",
    ["UI_GOMAR2_JS14_Sight_Stat2"] = "Critical and Hit Chance increased by 16%",
    ["UI_GOMAR2_JS14_Sight_Stat3"] = "Sight Range increased by 12%",
    ["UI_GOMAR2_EXPS3_Sight_Generation"] = "Generation V",
    ["UI_GOMAR2_EXPS3_Sight_Stat1"] = "Aiming Time reduced by 9%",
    ["UI_GOMAR2_EXPS3_Sight_Stat2"] = "Critical and Hit Chance increased by 13%",
    ["UI_GOMAR2_EXPS3_Sight_Stat3"] = "Sight Range increased by 9%",
    ["UI_GOMAR2_EXPS1_Sight_Generation"] = "Generation IV",
    ["UI_GOMAR2_EXPS1_Sight_Stat1"] = "Aiming Time reduced by 8%",
    ["UI_GOMAR2_EXPS1_Sight_Stat2"] = "Critical and Hit Chance increased by 11%",
    ["UI_GOMAR2_EXPS1_Sight_Stat3"] = "Sight Range increased by 6%",
    ["UI_GOMAR2_Aimpoint_Sight_Generation"] = "Generation VII",
    ["UI_GOMAR2_Aimpoint_Sight_Stat1"] = "Aiming Time reduced by 12%",
    ["UI_GOMAR2_Aimpoint_Sight_Stat2"] = "Critical and Hit Chance increased by 20%",
    ["UI_GOMAR2_Aimpoint_Sight_Stat3"] = "Sight Range increased by 15%",
    ["UI_GOMAR2_LR4X_Scope_Generation"] = "Generation II",
    ["UI_GOMAR2_LR4X_Scope_Stat1"] = "Aiming Time increased by 12%",
    ["UI_GOMAR2_LR4X_Scope_Stat2"] = "Critical and Hit Chance increased by 10%",
    ["UI_GOMAR2_LR4X_Scope_Stat3"] = "Sight Range increased by 25%",
    ["UI_GOMAR2_TA28_Scope_Generation"] = "Generation III",
    ["UI_GOMAR2_TA28_Scope_Stat1"] = "Aiming Time increased by 15%",
    ["UI_GOMAR2_TA28_Scope_Stat2"] = "Critical and Hit Chance increased by 13%",
    ["UI_GOMAR2_TA28_Scope_Stat3"] = "Sight Range increased by 35%",
    ["UI_GOMAR2_ElcanX2_Scope_Generation"] = "Generation I",
    ["UI_GOMAR2_ElcanX2_Scope_Stat1"] = "Aiming Time increased by 10%",
    ["UI_GOMAR2_ElcanX2_Scope_Stat2"] = "Critical and Hit Chance increased by 8%",
    ["UI_GOMAR2_ElcanX2_Scope_Stat3"] = "Sight Range increased by 20%",
    ["UI_GOMAR2_TR06X_Scope_Generation"] = "Generation IV",
    ["UI_GOMAR2_TR06X_Scope_Stat1"] = "Aiming Time increased by 18%",
    ["UI_GOMAR2_TR06X_Scope_Stat2"] = "Critical and Hit Chance increased by 16%",
    ["UI_GOMAR2_TR06X_Scope_Stat3"] = "Sight Range increased by 45%",
    ["UI_GOMAR2_PSO1_Scope_Generation"] = "Generation V",
    ["UI_GOMAR2_PSO1_Scope_Stat1"] = "Aiming Time increased by 22%",
    ["UI_GOMAR2_PSO1_Scope_Stat2"] = "Critical and Hit Chance increased by 20%",
    ["UI_GOMAR2_PSO1_Scope_Stat3"] = "Sight Range increased by 60%",
    ["UI_GOMAR2_LR10X_Scope_Generation"] = "Generation VI",
    ["UI_GOMAR2_LR10X_Scope_Stat1"] = "Aiming Time increased by 26%",
    ["UI_GOMAR2_LR10X_Scope_Stat2"] = "Critical and Hit Chance increased by 25%",
    ["UI_GOMAR2_LR10X_Scope_Stat3"] = "Sight Range increased by 75%",
    ["UI_GOMAR2_LRX12X_Scope_Generation"] = "Generation VII",
    ["UI_GOMAR2_LRX12X_Scope_Stat1"] = "Aiming Time increased by 30%",
    ["UI_GOMAR2_LRX12X_Scope_Stat2"] = "Critical and Hit Chance increased by 30%",
    ["UI_GOMAR2_LRX12X_Scope_Stat3"] = "Sight Range increased by 100%",
    ["UI_GOMAR2_Stub_Foregrip_Generation"] = "Generation I",
    ["UI_GOMAR2_Stub_Foregrip_Stat1"] = "Aiming Time reduced by 10%",
    ["UI_GOMAR2_Stub_Foregrip_Stat2"] = "Critical and Hit Chance increased by 10%",
    ["UI_GOMAR2_MKC_Foregrip_Generation"] = "Generation II",
    ["UI_GOMAR2_MKC_Foregrip_Stat1"] = "Aiming Time reduced by 15%",
    ["UI_GOMAR2_MKC_Foregrip_Stat2"] = "Critical and Hit Chance increased by 15%",
    ["UI_GOMAR2_MK2_Foregrip_Generation"] = "Generation III",
    ["UI_GOMAR2_MK2_Foregrip_Stat1"] = "Aiming Time reduced by 20%",
    ["UI_GOMAR2_MK2_Foregrip_Stat2"] = "Critical and Hit Chance increased by 20%",
}

local function resolve(key)
    local okText, value = pcall(getText, key)
    if okText and value ~= nil and tostring(value) ~= tostring(key) then return value end
    return FALLBACK[key] or ""
end

local function applyTooltips()
    local count = 0
    for fullType, keys in pairs(KEYSETS) do
        local out = {}
        for i = 1, #keys do out[#out + 1] = resolve(keys[i]) end
        T[fullType] = out
        count = count + 1
    end
    print("[GOM Attachment Rebalance] v2.0.0 tooltips applied; items=" .. tostring(count))
end

if Events and Events.OnGameStart then Events.OnGameStart.Add(applyTooltips) end
