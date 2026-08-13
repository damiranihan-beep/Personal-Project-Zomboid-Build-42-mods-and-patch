local MarzGuns_TooltipsTable = {}

MarzGuns_TooltipsTable.tooltipsPergun = {
    ["MarzGuns.HomemadePlasticSuppressor"] = { getText("Tooltip_HS_Plastic_1"), getText("Tooltip_HS_Plastic_2"), getText("Tooltip_HS_Plastic_3"), getText("Tooltip_HS_Plastic_4") },
    ["MarzGuns.HomemadePlasticSuppressor_Critical"] = { getText("Tooltip_HS_PlasticCritical_1"), getText("Tooltip_HS_Critical_2") },
    ["MarzGuns.HomemadePlasticSuppressor_Broken"] = { getText("Tooltip_HS_PlasticBroken_1") },
    ["MarzGuns.HomemadeCanSuppressor"] = { getText("Tooltip_HS_Can_1"), getText("Tooltip_HS_Can_2"), getText("Tooltip_HS_Can_3"), getText("Tooltip_HS_Can_4") },
    ["MarzGuns.HomemadeCanSuppressor_Critical"] = { getText("Tooltip_HS_CanCritical_1"), getText("Tooltip_HS_Critical_2") },
    ["MarzGuns.HomemadeCanSuppressor_Broken"] = { getText("Tooltip_HS_BrokenMetal_1"), getText("Tooltip_HS_BrokenMetal_2") },
    ["MarzGuns.HomemadePipeSuppressor"] = { getText("Tooltip_HS_Pipe_1"), getText("Tooltip_HS_Pipe_2"), getText("Tooltip_HS_Pipe_3"), getText("Tooltip_HS_Pipe_4") },
    ["MarzGuns.HomemadePipeSuppressor_Critical"] = { getText("Tooltip_HS_PipeCritical_1"), getText("Tooltip_HS_Critical_2") },
    ["MarzGuns.HomemadePipeSuppressor_Broken"] = { getText("Tooltip_HS_BrokenMetal_1"), getText("Tooltip_HS_BrokenMetal_2") },
    ["MarzGuns.M16A1"] = {
        getText("UI_MRT_MarzTooltip_001"),
        getText("UI_MRT_MarzTooltip_002"),
        getText("UI_MRT_MarzTooltip_003"),
        getText("UI_MRT_MarzTooltip_004")
    },
    ["MarzGuns.M16A2"] = {
        getText("UI_MRT_MarzTooltip_001"),
        getText("UI_MRT_MarzTooltip_005"),
        getText("UI_MRT_MarzTooltip_003"),
        getText("UI_MRT_MarzTooltip_004"),
    },
    ["MarzGuns.M16A2_M203"] = {
        getText("UI_MRT_MarzTooltip_001"),
        getText("UI_MRT_MarzTooltip_006"),
        getText("UI_MRT_MarzTooltip_003")
    },
    ["MarzGuns.M16A3"] = {
        getText("UI_MRT_MarzTooltip_001"),
        getText("UI_MRT_MarzTooltip_005"),
        getText("UI_MRT_MarzTooltip_003"),
        getText("UI_MRT_MarzTooltip_004"),
    },
    ["MarzGuns.AR15"] = {
        getText("UI_MRT_MarzTooltip_007"),
        getText("UI_MRT_MarzTooltip_002"),
        getText("UI_MRT_MarzTooltip_004"),
    },
    ["MarzGuns.FNC"] = {
        getText("UI_MRT_MarzTooltip_001"),
        getText("UI_MRT_MarzTooltip_006")
    },
    ["MarzGuns.CAR15"] = {
        getText("UI_MRT_MarzTooltip_001"),
        getText("UI_MRT_MarzTooltip_005"),
        getText("UI_MRT_MarzTooltip_003")
    },
    ["MarzGuns.XM177"] = {
        getText("UI_MRT_MarzTooltip_001"),
        getText("UI_MRT_MarzTooltip_005")
    },
    ["MarzGuns.M4A1"] = {
        getText("UI_MRT_MarzTooltip_001"),
        getText("UI_MRT_MarzTooltip_005"),
        getText("UI_MRT_MarzTooltip_003"),
        getText("UI_MRT_MarzTooltip_008")
    },
    ["MarzGuns.M4"] = {
        getText("UI_MRT_MarzTooltip_001"),
        getText("UI_MRT_MarzTooltip_003")
    },
    ["MarzGuns.G36C"] = {
        getText("UI_MRT_MarzTooltip_001"),
        getText("UI_MRT_MarzTooltip_005"),
        getText("UI_MRT_MarzTooltip_003"),
        getText("UI_MRT_MarzTooltip_008")
    },
    ["MarzGuns.G36"] = {
        getText("UI_MRT_MarzTooltip_001"),
        getText("UI_MRT_MarzTooltip_009"),
        getText("UI_MRT_MarzTooltip_003"),
        getText("UI_MRT_MarzTooltip_008")
    },
    ["MarzGuns.AK74"] = {
        getText("UI_MRT_MarzTooltip_010"),
        getText("UI_MRT_MarzTooltip_011"),
        getText("UI_MRT_MarzTooltip_012")
    },
    ["MarzGuns.AKS74U"] = {
        getText("UI_MRT_MarzTooltip_010"),
        getText("UI_MRT_MarzTooltip_011"),
        getText("UI_MRT_MarzTooltip_013"),
        getText("UI_MRT_MarzTooltip_012"),
        getText("UI_MRT_MarzTooltip_008")
    },
    ["MarzGuns.ASVAL"] = {
        getText("UI_MRT_MarzTooltip_014"),
        getText("UI_MRT_MarzTooltip_011"),
        getText("UI_MRT_MarzTooltip_009"),
        getText("UI_MRT_MarzTooltip_008"),
    },
    ["MarzGuns.FAMAS"] = {
        getText("UI_MRT_MarzTooltip_001"),
        getText("UI_MRT_MarzTooltip_002"),
        getText("UI_MRT_MarzTooltip_003"),
        getText("UI_MRT_MarzTooltip_004"),
    },
    ["MarzGuns.AK47"] = {
        getText("UI_MRT_MarzTooltip_015"),
        getText("UI_MRT_MarzTooltip_011"),
        getText("UI_MRT_MarzTooltip_012"),
    },
    ["MarzGuns.M14"] = {
        getText("UI_MRT_MarzTooltip_016"),
        getText("UI_MRT_MarzTooltip_002"),
        getText("UI_MRT_MarzTooltip_004"),
    },
    ["MarzGuns.M1_GARAND"] = {
        getText("UI_MRT_MarzTooltip_017"),
        getText("UI_MRT_MarzTooltip_004"),
    },
    ["MarzGuns.FAL"] = {
        getText("UI_MRT_MarzTooltip_016"),
        getText("UI_MRT_MarzTooltip_005")
    },
    ["MarzGuns.G3"] = {
        getText("UI_MRT_MarzTooltip_016"),
        getText("UI_MRT_MarzTooltip_005"),
        getText("UI_MRT_MarzTooltip_004"),
    },
    ["MarzGuns.MOSIN"] = {
        getText("UI_MRT_MarzTooltip_018"),
        getText("UI_MRT_MarzTooltip_019"),
        getText("UI_MRT_MarzTooltip_004"),
    },
    ["MarzGuns.M24"] = {
        getText("UI_MRT_MarzTooltip_016"),
        getText("UI_MRT_MarzTooltip_006"),
        getText("UI_MRT_MarzTooltip_020")
    },
    ["MarzGuns.M1903"] = {
        getText("UI_MRT_MarzTooltip_017"),
        getText("UI_MRT_MarzTooltip_019"),
        getText("UI_MRT_MarzTooltip_004"),
    },
    ["MarzGuns.M79"] = {
        getText("UI_MRT_MarzTooltip_021")
    },
    ["MarzGuns.W1894"] = {
        getText("UI_MRT_MarzTooltip_022"),
        getText("UI_MRT_MarzTooltip_006")
    },
    ["MarzGuns.M1895"] = {
        getText("UI_MRT_MarzTooltip_023"),
        getText("UI_MRT_MarzTooltip_006")
    },
    ["MarzGuns.W1887"] = {
        getText("UI_MRT_MarzTooltip_024"),
        getText("UI_MRT_MarzTooltip_006")
    },
    ["MarzGuns.W1873"] = {
        getText("UI_MRT_MarzTooltip_025"),
        getText("UI_MRT_MarzTooltip_006")
    },
    ["MarzGuns.W1873_CARBINE"] = {
        getText("UI_MRT_MarzTooltip_025")
    },
    ["MarzGuns.M60"] = {
        getText("UI_MRT_MarzTooltip_016"),
        getText("UI_MRT_MarzTooltip_020")
    },
    ["MarzGuns.BAR"] = {
        getText("UI_MRT_MarzTooltip_017"),
        getText("UI_MRT_MarzTooltip_020")
    },
    ["MarzGuns.SVD"] = {
        getText("UI_MRT_MarzTooltip_018"),
        getText("UI_MRT_MarzTooltip_011"),
        getText("UI_MRT_MarzTooltip_013")
    },
    ["MarzGuns.SKS"] = {
        getText("UI_MRT_MarzTooltip_015"),
        getText("UI_MRT_MarzTooltip_026"),
    },
    ["MarzGuns.PSG1"] = {
        getText("UI_MRT_MarzTooltip_016"),
        getText("UI_MRT_MarzTooltip_002")
    },
    ["MarzGuns.MOSSBERG_590"] = {
        getText("UI_MRT_MarzTooltip_024"),
        getText("UI_MRT_MarzTooltip_006"),
        getText("UI_MRT_MarzTooltip_004"),
    },
    ["MarzGuns.TRENCHGUN"] = {
        getText("UI_MRT_MarzTooltip_024"),
        getText("UI_MRT_MarzTooltip_004"),
    },
    ["MarzGuns.BENELLI_M4"] = {
        getText("UI_MRT_MarzTooltip_024"),
        getText("UI_MRT_MarzTooltip_006"),
        getText("UI_MRT_MarzTooltip_004"),
    },
    ["MarzGuns.SPAS12"] = {
        getText("UI_MRT_MarzTooltip_024")
    },
    ["MarzGuns.STEVENS_555"] = {
        getText("UI_MRT_MarzTooltip_024")
    },
    ["MarzGuns.DOUBLEBARREL"] = {
        getText("UI_MRT_MarzTooltip_024")
    },
    ["MarzGuns.AA12"] = {
        getText("UI_MRT_MarzTooltip_024"),
        getText("UI_MRT_MarzTooltip_009")
    },
    ["MarzGuns.REMINGTON_870"] = {
        getText("UI_MRT_MarzTooltip_024"),
        getText("UI_MRT_MarzTooltip_006"),
        getText("UI_MRT_MarzTooltip_004"),
    },
    ["MarzGuns.TOZ34"] = {
        getText("UI_MRT_MarzTooltip_024")
    },
    ["MarzGuns.THOMPSON"] = {
        getText("UI_MRT_MarzTooltip_027")
    },
    ["MarzGuns.MP5"] = {
        getText("UI_MRT_MarzTooltip_028"),
        getText("UI_MRT_MarzTooltip_005"),
    },
    ["MarzGuns.MP5SD"] = {
        getText("UI_MRT_MarzTooltip_028"),
        getText("UI_MRT_MarzTooltip_005")
    },
    ["MarzGuns.MP5A2"] = {
        getText("UI_MRT_MarzTooltip_028"),
        getText("UI_MRT_MarzTooltip_005"),
    },
    ["MarzGuns.MP5K"] = {
        getText("UI_MRT_MarzTooltip_028"),
        getText("UI_MRT_MarzTooltip_006")
    },
    ["MarzGuns.TEC9"] = {
        getText("UI_MRT_MarzTooltip_028")
    },
    ["MarzGuns.MAC10"] = {
        getText("UI_MRT_MarzTooltip_027"),
        getText("UI_MRT_MarzTooltip_029")
    },
    ["MarzGuns.M92FS"] = {
        getText("UI_MRT_MarzTooltip_028"),
        getText("UI_MRT_MarzTooltip_030"),
        getText("UI_MRT_MarzTooltip_031")
    },
    ["MarzGuns.M93R"] = {
        getText("UI_MRT_MarzTooltip_028"),
        getText("UI_MRT_MarzTooltip_030"),
        getText("UI_MRT_MarzTooltip_031")
    },
    ["MarzGuns.HIPOWER"] = {
        getText("UI_MRT_MarzTooltip_028"),
        getText("UI_MRT_MarzTooltip_030"),
        getText("UI_MRT_MarzTooltip_031")
    },
    ["MarzGuns.P226"] = {
        getText("UI_MRT_MarzTooltip_028"),
        getText("UI_MRT_MarzTooltip_030"),
        getText("UI_MRT_MarzTooltip_031")
    },
    ["MarzGuns.M1911"] = {
        getText("UI_MRT_MarzTooltip_027"),
        getText("UI_MRT_MarzTooltip_032"),
        getText("UI_MRT_MarzTooltip_029")
    },
    ["MarzGuns.USP"] = {
        getText("UI_MRT_MarzTooltip_027"),
        getText("UI_MRT_MarzTooltip_032"),
        getText("UI_MRT_MarzTooltip_029")
    },
    ["MarzGuns.DEAGLE"] = {
        getText("UI_MRT_MarzTooltip_033"),
        getText("UI_MRT_MarzTooltip_034")
    },
    ["MarzGuns.SW629"] = {
        getText("UI_MRT_MarzTooltip_035")
    },
    ["MarzGuns.PYTHON"] = {
        getText("UI_MRT_MarzTooltip_025"),
        getText("UI_MRT_MarzTooltip_036")
    },
    ["MarzGuns.RHINO"] = {
        getText("UI_MRT_MarzTooltip_025")
    },
    ["MarzGuns.MP412"] = {
        getText("UI_MRT_MarzTooltip_037")
    },
    ["MarzGuns.COLT_SINGLE"] = {
        getText("UI_MRT_MarzTooltip_027")
    },
    ["MarzGuns.DETECTIVE_38"] = {
        getText("UI_MRT_MarzTooltip_037")
    },

    ---- Attachments
    ["MarzGuns.Booster_Scope"] = {
        getText("UI_MRT_MarzTooltip_038"),
        getText("UI_MRT_MarzTooltip_039")
    },
    ["MarzGuns.Booster_Scope_Off"] = {
        getText("UI_MRT_MarzTooltip_040")
    },
    ["MarzGuns.ReflexS2_Sight"] = {
        getText("UI_MRT_MarzTooltip_041"),
        getText("UI_MRT_MarzTooltip_038")
    },
    ["MarzGuns.Kobra_Sight"] = {
        getText("UI_MRT_MarzTooltip_042"),
        getText("UI_MRT_MarzTooltip_043")
    },
    ["MarzGuns.OKP3_Sight"] = {
        getText("UI_MRT_MarzTooltip_044"),
        getText("UI_MRT_MarzTooltip_045")
    },
    ["MarzGuns.JS14_Sight"] = {
        getText("UI_MRT_MarzTooltip_046")
    },
    ["MarzGuns.EXPS3_Sight"] = {
        getText("UI_MRT_MarzTooltip_047"),
        getText("UI_MRT_MarzTooltip_048")
    },
    ["MarzGuns.EXPS1_Sight"] = {
        getText("UI_MRT_MarzTooltip_047"),
        getText("UI_MRT_MarzTooltip_049")
    },
    ["MarzGuns.Aimpoint_Sight"] = {
        getText("UI_MRT_MarzTooltip_050"),
        getText("UI_MRT_MarzTooltip_051")
    },
    ["MarzGuns.LR4X_Scope"] = {
        getText("UI_MRT_MarzTooltip_052"),
        getText("UI_MRT_MarzTooltip_053"),
        getText("UI_MRT_MarzTooltip_054")
    },
    ["MarzGuns.TA28_Scope"] = {
        getText("UI_MRT_MarzTooltip_055"),
        getText("UI_MRT_MarzTooltip_043"),
        getText("UI_MRT_MarzTooltip_056")
    },
    ["MarzGuns.ElcanX2_Scope"] = {
        getText("UI_MRT_MarzTooltip_057"),
        getText("UI_MRT_MarzTooltip_058"),
        getText("UI_MRT_MarzTooltip_056")
    },
    ["MarzGuns.TR06X_Scope"] = {
        getText("UI_MRT_MarzTooltip_059"),
        getText("UI_MRT_MarzTooltip_045"),
        getText("UI_MRT_MarzTooltip_060")
    },
    ["MarzGuns.PSO1_Scope"] = {
        getText("UI_MRT_MarzTooltip_061"),
        getText("UI_MRT_MarzTooltip_046"),
        getText("UI_MRT_MarzTooltip_062")
    },
    ["MarzGuns.LR10X_Scope"] = {
        getText("UI_MRT_MarzTooltip_063"),
        getText("UI_MRT_MarzTooltip_064"),
        getText("UI_MRT_MarzTooltip_065")
    },
    ["MarzGuns.LRX12X_Scope"] = {
        getText("UI_MRT_MarzTooltip_066"),
        getText("UI_MRT_MarzTooltip_067"),
        getText("UI_MRT_MarzTooltip_068")
    },
    ["MarzGuns.PL4_Sight"] = {
        getText("UI_MRT_MarzTooltip_047")
    },
    ["MarzGuns.PS1_Sight"] = {
        getText("UI_MRT_MarzTooltip_050")
    },
    ["MarzGuns.PM2_Sight"] = {
        getText("UI_MRT_MarzTooltip_069"),
        getText("UI_MRT_MarzTooltip_070")
    },
    ["MarzGuns.PRL1_Scope"] = {
        getText("UI_MRT_MarzTooltip_043"),
        getText("UI_MRT_MarzTooltip_048")
    },

    ["MarzGuns.Stub_Foregrip"] = {
        getText("UI_MRT_MarzTooltip_071"),
        getText("UI_MRT_MarzTooltip_045")
    },
    ["MarzGuns.MKC_Foregrip"] = {
        getText("UI_MRT_MarzTooltip_044"),
        getText("UI_MRT_MarzTooltip_072")
    },
    ["MarzGuns.MK2_Foregrip"] = {
        getText("UI_MRT_MarzTooltip_073"),
        getText("UI_MRT_MarzTooltip_043")
    },
    ["MarzGuns.MKI_Suppressor"] = {
        getText("UI_MRT_MarzTooltip_074"),
        getText("UI_MRT_MarzTooltip_075"),
        getText("UI_MRT_MarzTooltip_076"),
        getText("UI_MRT_MarzTooltip_077"),
        getText("UI_MRT_MarzTooltip_078"),
    },
    ["MarzGuns.NDR_Suppressor"] = {
        getText("UI_MRT_MarzTooltip_074"),
        getText("UI_MRT_MarzTooltip_075"),
        getText("UI_MRT_MarzTooltip_076"),
        getText("UI_MRT_MarzTooltip_077"),
        getText("UI_MRT_MarzTooltip_078"),
    },
    ["MarzGuns.PBS-1_Suppressor"] = {
        getText("UI_MRT_MarzTooltip_079"),
        getText("UI_MRT_MarzTooltip_075"),
        getText("UI_MRT_MarzTooltip_076"),
        getText("UI_MRT_MarzTooltip_077"),
        getText("UI_MRT_MarzTooltip_080"),
    },
    ["MarzGuns.M&P_Suppressor"] = {
        getText("UI_MRT_MarzTooltip_081"),
        getText("UI_MRT_MarzTooltip_075"),
        getText("UI_MRT_MarzTooltip_076"),
        getText("UI_MRT_MarzTooltip_077"),
        getText("UI_MRT_MarzTooltip_082"),
    },
    ["MarzGuns.Shh9_Suppressor"] = {
        getText("UI_MRT_MarzTooltip_081"),
        getText("UI_MRT_MarzTooltip_075"),
        getText("UI_MRT_MarzTooltip_076"),
        getText("UI_MRT_MarzTooltip_077"),
        getText("UI_MRT_MarzTooltip_082"),
    },
    ["MarzGuns.P45_Suppressor"] = {
        getText("UI_MRT_MarzTooltip_083"),
        getText("UI_MRT_MarzTooltip_075"),
        getText("UI_MRT_MarzTooltip_076"),
        getText("UI_MRT_MarzTooltip_077"),
        getText("UI_MRT_MarzTooltip_084"),
    },
    ["MarzGuns.PJ-3_Laser"] = {
        getText("UI_MRT_MarzTooltip_041"),
        getText("UI_MRT_MarzTooltip_050")
    },
    ["MarzGuns.PX1_Laser"] = {
        getText("UI_MRT_MarzTooltip_041"),
        getText("UI_MRT_MarzTooltip_050")
    },
    ["MarzGuns.TR-1_Laser"] = {
        getText("UI_MRT_MarzTooltip_041"),
        getText("UI_MRT_MarzTooltip_050")
    },
    ["MarzGuns.LP_Light"] = {
        getText("UI_MRT_MarzTooltip_085")
    },
    ["MarzGuns.TL_Light"] = {
        getText("UI_MRT_MarzTooltip_085")
    },
    ["MarzGuns.AimRight_Laser"] = {
        getText("UI_MRT_MarzTooltip_044"),
        getText("UI_MRT_MarzTooltip_038")
    },
    ["MarzGuns.LRX-7_Laser"] = {
        getText("UI_MRT_MarzTooltip_041"),
        getText("UI_MRT_MarzTooltip_050")
    },
    ["MarzGuns.BrightPoint-5_Light"] = {
        getText("UI_MRT_MarzTooltip_085")
    },
    ["MarzGuns.SR7_Light"] = {
        getText("UI_MRT_MarzTooltip_085")
    },
    ["MarzGuns.AR_Muzzle_Mount_Device"] = {
        getText("UI_MRT_MarzTooltip_086"),
        getText("UI_MRT_MarzTooltip_087")
    },
    ["MarzGuns.AK_Muzzle_Mount_Device"] = {
        getText("UI_MRT_MarzTooltip_086"),
        getText("UI_MRT_MarzTooltip_088")
    },
    ["MarzGuns.Pistol_Muzzle_Mount_Device"] = {
        getText("UI_MRT_MarzTooltip_086"),
        getText("UI_MRT_MarzTooltip_089")
    },
    ["MarzGuns.45_Muzzle_Mount_Device"] = {
        getText("UI_MRT_MarzTooltip_086"),
        getText("UI_MRT_MarzTooltip_090")
    },
    ["MarzGuns.LR2_Compensator"] = {
        getText("UI_MRT_MarzTooltip_091"),
        getText("UI_MRT_MarzTooltip_077")
    },
    ["MarzGuns.LX_Flashhider"] = {
        getText("UI_MRT_MarzTooltip_092"),
        getText("UI_MRT_MarzTooltip_077")
    },
    ["MarzGuns.Trix42_Muzzlebreak"] = {
        getText("UI_MRT_MarzTooltip_092"),
        getText("UI_MRT_MarzTooltip_077")
    },

    ["MarzGuns.Bipod_Deployed"] = {
        getText("UI_MRT_MarzTooltip_052"),
        getText("UI_MRT_MarzTooltip_045"),
    },
    ["MarzGuns.Bipod_Folded"] = {
        getText("UI_MRT_MarzTooltip_093"),
    },

    --- Bayonets
    ["MarzGuns.K98_BAYONET"] = {
        getText("UI_MRT_MarzTooltip_094"),
    },
    ["MarzGuns.M5_BAYONET"] = {
        getText("UI_MRT_MarzTooltip_094"),
    },
    ["MarzGuns.M9_BAYONET"] = {
        getText("UI_MRT_MarzTooltip_094"),
    },

    ---- Ammunitions
    ["MarzGuns.556x45_Bullet_ArmorPiercing"] = {
        getText("UI_MRT_MarzTooltip_095"),
        getText("UI_MRT_MarzTooltip_096"),
        getText("UI_MRT_MarzTooltip_097"),
    },
    ["MarzGuns.556x45_Bullet_HollowPoint"] = {
        getText("UI_MRT_MarzTooltip_098"),
        getText("UI_MRT_MarzTooltip_099"),
    },
    ["MarzGuns.223_Bullet"] = {
        getText("UI_MRT_MarzTooltip_100"),
        getText("UI_MRT_MarzTooltip_101"),
    },
    ["MarzGuns.556x45_Bullet_Overpressured"] = {
        getText("UI_MRT_MarzTooltip_102"),
        getText("UI_MRT_MarzTooltip_103"),
        getText("UI_MRT_MarzTooltip_096"),
        getText("UI_MRT_MarzTooltip_104"),
    },
    ["MarzGuns.556x45_Bullet_Subsonic"] = {
        getText("UI_MRT_MarzTooltip_105"),
        getText("UI_MRT_MarzTooltip_106"),
        getText("UI_MRT_MarzTooltip_107"),
        getText("UI_MRT_MarzTooltip_108"),
        getText("UI_MRT_MarzTooltip_109"),
        getText("UI_MRT_MarzTooltip_110"),
    },
    ["MarzGuns.308_Bullet"] = {
        getText("UI_MRT_MarzTooltip_111"),
        getText("UI_MRT_MarzTooltip_101"),
    },
    ["MarzGuns.12Gauge_Shell_Slug"] = {
        getText("UI_MRT_MarzTooltip_112"),
        getText("UI_MRT_MarzTooltip_096"),
        getText("UI_MRT_MarzTooltip_113"),
        getText("UI_MRT_MarzTooltip_114"),
    },

    --- Others
    ["MarzGuns.Picatinny_Rail"] = {
        getText("UI_MRT_MarzTooltip_115")
    },
    ["MarzGuns.AK_Mount"] = {
        getText("UI_MRT_MarzTooltip_116")
    },
    ["MarzGuns.Sniper_Mount"] = {
        getText("UI_MRT_MarzTooltip_117")
    },
    ["MarzGuns.Beretta_Mount"] = {
        getText("UI_MRT_MarzTooltip_118")
    },
    ["MarzGuns.Colt_Mount"] = {
        getText("UI_MRT_MarzTooltip_119")
    },
    ["MarzGuns.Heavy_Pistol_Rail"] = {
        getText("UI_MRT_MarzTooltip_120")
    },

    ["MarzGuns.Shellholder"] = {
        getText("UI_MRT_MarzTooltip_121")
    },
    ["MarzGuns.Beretta_Stock_Deployed"] = {
        getText("UI_MRT_MarzTooltip_041"),
        getText("UI_MRT_MarzTooltip_122"),
    },
    ["MarzGuns.Beretta_Stock_Folded"] = {
        getText("UI_MRT_MarzTooltip_123"),
    },
    ["MarzGuns.M203"] = {
        getText("UI_MRT_MarzTooltip_124")
    },
}

return MarzGuns_TooltipsTable
