-- MyRussianTranslations: late, non-destructive translation patch for PZAPI ModOptions.
-- Russian text is stored in UI.json. This Lua file intentionally contains ASCII only.

local MRT_PAGE_NAMES = {
    CleanUI = "UI_MRT_Page_CleanUI",
    Gunworks = "UI_MRT_Page_Gunworks",
    Neat_Building = "UI_MRT_Page_NeatBuilding",
    Neat_Building_AddonXP = "UI_MRT_Page_NeatBuildingXP",
    Neat_Crafting_Beta = "UI_MRT_Page_NeatCrafting",
    Neat_Crafting_AddonXP = "UI_MRT_Page_NeatCraftingXP",
    OAC = "UI_MRT_Page_OpenAllContainers",
    P4PickingMeister = "UI_MRT_Page_PickingMeister",
    SWSP = "UI_MRT_Page_ShowWeaponStatsPlus",
    P4TidyUpMeister = "UI_MRT_Page_TidyUpMeister",
    MoodlesInLua = "UI_MRT_Page_MoodlesInLua",
    SmokingSoundsOverhaul = "UI_MRT_Page_SmokingSoundsOverhaul",
    TacHold = "UI_MRT_Page_TacHold",
    TacPHold = "UI_MRT_Page_TacPHold",
    RabenRabo_DWA = "UI_MRT_Page_DualWieldingAttacks",
}

local MRT_GLOBAL_TEXT = {
    ["NeatUI XP Drop"] = "UI_MRT_Page_NeatUIXPDrop",
    ["Show XP Window"] = "UI_MRT_XPDrop_ShowWindow",
    ["Shows a movable XP bar and XP drops. Multiplayer XP logging remains active when this is disabled."] = "UI_MRT_XPDrop_ShowWindow_Tooltip",

    ["Select custom textures for moodles"] = "UI_MRT_MIL_Description1",
    ["If new packs do not appear in the list, check if they are listed under the Moodles In Lua mod in Mod Order menu"] = "UI_MRT_MIL_Description2",

    ["Return Items after Opening or Unpacking"] = "UI_MRT_ReturnItemsAfterOpening",
    ["Returns items obtained by opening containers or unpacking boxes to their original container. Leftovers and empty containers produced by opening and eating are returned regardless of this setting."] = "UI_MRT_ReturnItemsAfterOpening_Tooltip",

    ["Gunworks: Toggle underbarrel"] = "UI_optionscreen_binding_Gunworks_UnderbarrelUse",
    ["Gunworks: Open weapon loader UI"] = "UI_optionscreen_binding_Gunworks_OpenLoaderUI",
    ["Gunworks: Cycle fire mode"] = "UI_optionscreen_binding_Gunworks_SwitchFirerate",

    ["Show Auto-close option"] = "UI_MRT_ShowAutoCloseOption",
    ["Show or hide the Auto-close option in the world context menu."] = "UI_MRT_ShowAutoCloseOption_Tooltip",
}


local MRT_TEXT_FRAGMENTS = {
    { "Shows a movable XP bar and XP drops.", "UI_MRT_XPDrop_ShowWindow_Tooltip_Line1" },
    { "Multiplayer XP logging remains active when this is disabled.", "UI_MRT_XPDrop_ShowWindow_Tooltip_Line2" },
    { "Choose how recipe XP is displayed.", "UI_MRT_RecipeXP_FormatTooltip_Header" },
    { "Basic XP: Shows the base XP.", "UI_MRT_RecipeXP_FormatTooltip_Basic" },
    { "Final XP: Shows the final XP after multipliers.", "UI_MRT_RecipeXP_FormatTooltip_Final" },
    { "Multiplier: Shows only the multiplier value(s).", "UI_MRT_RecipeXP_FormatTooltip_Multiplier" },
    { "Full breakdown: Shows base XP, multiplier(s) and final XP.", "UI_MRT_RecipeXP_FormatTooltip_Full" },
}

local function MRT_replaceFragments(value)
    if type(value) ~= "string" or value == "" then return value end
    local result = value
    for i = 1, #MRT_TEXT_FRAGMENTS do
        local pair = MRT_TEXT_FRAGMENTS[i]
        local pattern = pair[1]:gsub("(%W)", "%%%1")
        result = result:gsub(pattern, function() return getText(pair[2]) end)
    end
    return result
end

local function MRT_patchGlobalDisplayFields(entry)
    if type(entry) ~= "table" then return false end
    local changed = false
    local fields = {
        "name", "tooltip", "tooltipText", "description", "text",
        "title", "label", "hoverText", "tip"
    }
    for i = 1, #fields do
        local field = fields[i]
        local value = entry[field]
        if type(value) == "string" then
            if MRT_GLOBAL_TEXT[value] then
                -- Raw/hardcoded display fields need the resolved text, not only a
                -- translation-key name. This also fixes tooltips created after boot.
                entry[field] = getText(MRT_GLOBAL_TEXT[value])
                changed = true
            else
                local replaced = MRT_replaceFragments(value)
                if replaced ~= value then
                    entry[field] = replaced
                    changed = true
                end
            end
        end
    end
    return changed
end

local MRT_PATCHES = {
    MoodlesInLua = {
        byId = {
            MoodleBorderSet = { name = "UI_MRT_MIL_BorderPack", tooltip = "UI_MRT_MIL_BorderPack_Tooltip", values = { "UI_MRT_Value_Default" } },
            MoodleIconSet = { name = "UI_MRT_MIL_IconPack", tooltip = "UI_MRT_MIL_IconPack_Tooltip", values = { "UI_MRT_Value_Disabled", "UI_MRT_Value_Default" } },
        },
        byName = {
            ["Select custom textures for moodles"] = "UI_MRT_MIL_Description1",
            ["If new packs do not appear in the list, check if they are listed under the Moodles In Lua mod in Mod Order menu"] = "UI_MRT_MIL_Description2",
        },
    },
    TacHold = {
        byId = {
            ["Tactical hold"] = { name = "UI_MRT_TacHold_Normal" },
            HighReady = { name = "UI_MRT_TacHold_HighReady" },
            LowReady = { name = "UI_MRT_TacHold_LowReady" },
            GunResting = { name = "UI_MRT_TacHold_GunResting" },
            Vanilla = { name = "UI_MRT_TacHold_Vanilla" },
            ["Cycle animation Key"] = { name = "UI_MRT_TacHold_CycleKey" },
        },
    },
    TacPHold = {
        byId = {
            ["Tactical hold"] = { name = "UI_MRT_TacHold_Normal" },
            HighReady = { name = "UI_MRT_TacHold_HighReady" },
            ["Low Ready"] = { name = "UI_MRT_TacHold_LowReady" },
            Vanilla = { name = "UI_MRT_TacHold_Vanilla" },
        },
    },
    SmokingSoundsOverhaul = {
        byId = {
            mode = { name = "UI_MRT_SSO_SoundMode", tooltip = "UI_MRT_SSO_SoundMode_Tooltip", values = { "UI_MRT_SSO_ModeAssembled", "UI_MRT_SSO_ModePuffs", "UI_MRT_SSO_ModeClassic" } },
            zippoFlicks = { name = "UI_MRT_SSO_ZippoFlicks", tooltip = "UI_MRT_SSO_ZippoFlicks_Tooltip", values = { "UI_MRT_SSO_Random", "1", "2", "3" } },
            matchStrikes = { name = "UI_MRT_SSO_MatchStrikes", tooltip = "UI_MRT_SSO_MatchStrikes_Tooltip", values = { "UI_MRT_SSO_Random", "1", "2", "3" } },
            lighterSet = { name = "UI_MRT_SSO_LighterSound", tooltip = "UI_MRT_SSO_LighterSound_Tooltip", values = { "UI_MRT_SSO_Random", "1", "2", "3" } },
            matchesSet = { name = "UI_MRT_SSO_MatchesSound", tooltip = "UI_MRT_SSO_MatchesSound_Tooltip", values = { "UI_MRT_SSO_Random", "1", "2", "3" } },
            ignVol = { name = "UI_MRT_SSO_IgnitionVolume", tooltip = "UI_MRT_SSO_IgnitionVolume_Tooltip" },
            lidClose = { name = "UI_MRT_SSO_LidClose", tooltip = "UI_MRT_SSO_LidClose_Tooltip" },
            minGap = { name = "UI_MRT_SSO_MinGap", tooltip = "UI_MRT_SSO_MinGap_Tooltip" },
            puffVol = { name = "UI_MRT_SSO_PuffVolume", tooltip = "UI_MRT_SSO_PuffVolume_Tooltip" },
            pipes = { name = "UI_MRT_SSO_CoverPipes", tooltip = "UI_MRT_SSO_CoverPipes_Tooltip" },
            reset = { name = "UI_MRT_SSO_Reset", tooltip = "UI_MRT_SSO_Reset_Tooltip" },
            nowPlaying = { name = "UI_MRT_SSO_NowPlaying", tooltip = "UI_MRT_SSO_NowPlaying_Tooltip" },
            previewZippo = { name = "UI_MRT_SSO_PreviewZippo", tooltip = "UI_MRT_SSO_PreviewZippo_Tooltip" },
            previewMatch = { name = "UI_MRT_SSO_PreviewMatches", tooltip = "UI_MRT_SSO_PreviewMatches_Tooltip" },
            previewStop = { name = "UI_MRT_SSO_StopPreview", tooltip = "UI_MRT_SSO_StopPreview_Tooltip" },
        },
        byName = {
            ["Sounds are built from separate parts, so no two smokes sound the same."] = "UI_MRT_SSO_DescriptionMain",
            ["Lighting"] = "UI_MRT_SSO_TitleLighting",
            ["Specific sound -- lock one exact take instead of rotating."] = "UI_MRT_SSO_DescriptionSpecific",
            ["Puffs"] = "UI_MRT_SSO_TitlePuffs",
            ["Puff spacing below only stretches on long smokes (cigars, pipes, longer-smoke mods) -- a normal cigarette is short."] = "UI_MRT_SSO_DescriptionPuffs",
            ["Other"] = "UI_MRT_SSO_TitleOther",
            ["Preview"] = "UI_MRT_SSO_TitlePreview",
            ["Preview only works from the main menu -- in-game the menu mutes these sounds. Volume sliders apply in-game, not to the preview."] = "UI_MRT_SSO_DescriptionPreview",
        },
    },
}

local function MRT_setField(entry, field, value)
    if not entry or value == nil or entry[field] == value then return false end
    entry[field] = value
    return true
end

local function MRT_applyOptionPatch(option, patch)
    if not option or not patch then return false end
    local changed = false

    if patch.name and MRT_setField(option, "name", patch.name) then changed = true end
    if patch.tooltip and MRT_setField(option, "tooltip", patch.tooltip) then changed = true end

    if patch.values and option.values then
        for i = 1, #patch.values do
            if option.values[i] ~= patch.values[i] then
                option.values[i] = patch.values[i]
                changed = true
            end
        end
    end

    return changed
end

local function MRT_patchPage(page)
    if not page or not page.modOptionsID then return false end

    local pageID = page.modOptionsID
    local changed = false
    local pageName = MRT_PAGE_NAMES[pageID]

    if pageName and page.name ~= pageName then
        page.name = pageName
        changed = true
    end

    local spec = MRT_PATCHES[pageID]

    if MRT_patchGlobalDisplayFields(page) then changed = true end

    if page.data then
        for _, option in ipairs(page.data) do
            if spec then
                local optionPatch = nil

                if spec.byId and option.id then
                    optionPatch = spec.byId[option.id]
                end

                if optionPatch then
                    if MRT_applyOptionPatch(option, optionPatch) then changed = true end
                elseif spec.byName and option.name and spec.byName[option.name] then
                    local translatedName = spec.byName[option.name]
                    if option.name ~= translatedName then
                        option.name = translatedName
                        changed = true
                    end
                end
            end

            if MRT_patchGlobalDisplayFields(option) then changed = true end
        end
    end

    return changed
end

local MRT_refreshGuard = false

local function MRT_refreshOpenScreen()
    if MRT_refreshGuard then return end
    if not ModOptionsScreen or not ModOptionsScreen.instance then return end
    if type(ModOptionsScreen.instance.sortAndRefillListbox) ~= "function" then return end

    MRT_refreshGuard = true
    pcall(function() ModOptionsScreen.instance:sortAndRefillListbox() end)
    MRT_refreshGuard = false
end

local function MRT_patchAll(refreshScreen)
    if not PZAPI or not PZAPI.ModOptions or not PZAPI.ModOptions.Data then return false end

    local changed = false
    for _, page in ipairs(PZAPI.ModOptions.Data) do
        if MRT_patchPage(page) then changed = true end
    end

    if changed and refreshScreen ~= false then
        MRT_refreshOpenScreen()
    end

    return changed
end

-- Patch the data when ModOptions actually rebuilds its list. This replaces the
-- old repeated OnTick rescanning and only runs on a real UI rebuild.
local function MRT_installModOptionsScreenHook()
    if type(ModOptionsScreen) ~= "table" then return false end
    if ModOptionsScreen._MRT_V2_sortHooked then return true end

    local oldSort = ModOptionsScreen.sortAndRefillListbox
    if type(oldSort) ~= "function" then return false end

    ModOptionsScreen.sortAndRefillListbox = function(self, ...)
        if not MRT_refreshGuard then
            pcall(MRT_patchAll, false)
        end
        return oldSort(self, ...)
    end

    ModOptionsScreen._MRT_V2_sortHooked = true
    return true
end

local function MRT_bootstrapModOptions()
    pcall(MRT_patchAll, true)
    pcall(MRT_installModOptionsScreenHook)
end

-- Immediate + lifecycle-only patching. No permanent OnTick loop.
pcall(MRT_bootstrapModOptions)
if Events then
    if Events.OnGameBoot then Events.OnGameBoot.Add(MRT_bootstrapModOptions) end
    if Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(MRT_bootstrapModOptions) end
    if Events.OnGameStart then Events.OnGameStart.Add(MRT_bootstrapModOptions) end
end
