-- MyRussianTranslations: Russian runtime fixes for mods that draw English text directly in Lua.
-- This file does not alter gameplay logic; it only changes visible labels/text.

local function MRT_T(key)
    if getText then return getText(key) end
    return key
end

local function MRT_plainReplace(text, from, to)
    if type(text) ~= "string" or from == "" then return text end
    local pattern = from:gsub("(%W)", "%%%1")
    return (text:gsub(pattern, function() return to end))
end

local MRT_DRJ_TEXT_CACHE = {}

local function MRT_translateDRJText(text)
    if type(text) ~= "string" or text == "" then return text end

    local cached = MRT_DRJ_TEXT_CACHE[text]
    if cached ~= nil then return cached end
    local original = text

    local replacements = {
        { "No records yet. Play a day to generate stats.", MRT_T("UI_MRT_DRJ_NoRecords") },
        { "Daily Report Journal", MRT_T("UI_MRT_DRJ_Title") },
        { "Daily Report Charts", MRT_T("UI_MRT_DRJ_DailyCharts") },
        { "Daily Average Kills", MRT_T("UI_MRT_DRJ_DailyAverageKills") },
        { "Total Spiffo Rep", MRT_T("UI_MRT_DRJ_TotalSpiffoRep") },
        { "Days Survived", MRT_T("UI_MRT_DRJ_DaysSurvived") },
        { "Total Kills", MRT_T("UI_MRT_DRJ_TotalKills") },
        { "Total XP", MRT_T("UI_MRT_DRJ_TotalXP") },
        { "Zombies Killed", MRT_T("UI_MRT_DRJ_ZombiesKilled") },
        { "Average Kills", MRT_T("UI_MRT_DRJ_AverageKills") },
        { "XP Gains", MRT_T("UI_MRT_DRJ_XPGains") },
        { "Weight Delta", MRT_T("UI_MRT_DRJ_WeightDelta") },
        { "Spiffo Rep", MRT_T("UI_MRT_DRJ_SpiffoRep") },
        { "World Day ", MRT_T("UI_MRT_DRJ_WorldDay") .. " " },
        { "Score:", MRT_T("UI_MRT_DRJ_Score") .. ":" },
        { "(Kills + Avg) * (XP + Days) / 100", getText("UI_MRT_Runtime_001") },
        { "(avg)", "(" .. MRT_T("UI_MRT_DRJ_Avg") .. ")" },
        { "(no streak data)", "(" .. MRT_T("UI_MRT_DRJ_NoStreak") .. ")" },
        { "No XP data", MRT_T("UI_MRT_DRJ_NoXPData") },
        { "No daily report data", MRT_T("UI_MRT_DRJ_NoDailyData") },
        { "No data", MRT_T("UI_MRT_DRJ_NoData") },
        { "XP Charts", MRT_T("UI_MRT_DRJ_XPCharts") },
        { "By Month", MRT_T("UI_MRT_DRJ_ByMonth") },
        { "By Week", MRT_T("UI_MRT_DRJ_ByWeek") },
        { "By Day", MRT_T("UI_MRT_DRJ_ByDay") },
        { "All Time", MRT_T("UI_MRT_DRJ_AllTime") },
        { "In Progress", MRT_T("UI_MRT_DRJ_InProgress") },
        { "Week ", MRT_T("UI_MRT_DRJ_Week") .. " " },
    }

    for i = 1, #replacements do
        text = MRT_plainReplace(text, replacements[i][1], replacements[i][2])
    end

    -- Dynamic day/timestamp and XP-log strings.
    text = MRT_plainReplace(text, "Day ", getText("UI_MRT_Runtime_002"))
    text = MRT_plainReplace(text, " XP ", " " .. MRT_T("UI_MRT_DRJ_XP") .. " ")
    text = MRT_plainReplace(text, " xp", " " .. MRT_T("UI_MRT_DRJ_XP"))
    text = MRT_plainReplace(text, " kills)", getText("UI_MRT_Runtime_003"))
    text = MRT_plainReplace(text, " to ", "–")

    MRT_DRJ_TEXT_CACHE[original] = text
    return text
end

local function MRT_patchRichText(panel)
    if not panel or type(panel.text) ~= "string" then return end
    local translated = MRT_translateDRJText(panel.text)
    if translated == panel.text then return end
    panel.text = translated
    if panel.paginate then pcall(function() panel:paginate() end) end
    if panel.updateScrollbars then pcall(function() panel:updateScrollbars() end) end
end

local function MRT_setButtonTitle(btn, title)
    if not btn then return end
    btn.title = title
end

local function MRT_patchDRJWindow(self)
    if not self then return end
    if self.setTitle then pcall(function() self:setTitle(MRT_T("UI_MRT_DRJ_Title")) end) end

    MRT_setButtonTitle(self.recordTab, MRT_T("UI_MRT_DRJ_Records"))
    MRT_setButtonTitle(self.reportTab, MRT_T("UI_MRT_DRJ_DailyReports"))
    MRT_setButtonTitle(self.XPLogTab, MRT_T("UI_MRT_DRJ_XPReports"))
    MRT_setButtonTitle(self.xpRecentBtn, MRT_T("UI_MRT_DRJ_Recent"))
    MRT_setButtonTitle(self.xpDailyBtn, MRT_T("UI_MRT_DRJ_Daily"))

    if self.reportGraphBtn and self.reportGraphBtn.setTooltip then
        pcall(function() self.reportGraphBtn:setTooltip(MRT_T("UI_MRT_DRJ_Chart")) end)
    end
    if self.xpGraphBtn and self.xpGraphBtn.setTooltip then
        pcall(function() self.xpGraphBtn:setTooltip(MRT_T("UI_MRT_DRJ_Chart")) end)
    end

    MRT_patchRichText(self.rPanel)
    MRT_patchRichText(self.playerPanel)
    MRT_patchRichText(self.recordPanel)

    -- Existing saved reports may already contain the English rich-text string.
    if self.datas and type(self.datas.items) == "table" then
        for i = 1, #self.datas.items do
            local row = self.datas.items[i]
            local payload = row and row.item
            if payload and type(payload.superText) == "string" then
                payload.superText = MRT_translateDRJText(payload.superText)
            end
        end
    end
end

local function MRT_killWord(value)
    local n = math.floor(math.abs(tonumber(value) or 0))
    local n100 = n % 100
    if n100 >= 11 and n100 <= 14 then return getText("UI_MRT_Runtime_004") end
    local n10 = n % 10
    if n10 == 1 then return getText("UI_MRT_Runtime_005") end
    if n10 >= 2 and n10 <= 4 then return getText("UI_MRT_Runtime_006") end
    return getText("UI_MRT_Runtime_004")
end

local MRT_drjInstalled = false
local function MRT_installDRJPatch()
    if not ReportWindow or MRT_drjInstalled then return false end
    MRT_drjInstalled = true

    local oldInitialise = ReportWindow.initialise
    if oldInitialise then
        ReportWindow.initialise = function(self, ...)
            local ret = oldInitialise(self, ...)
            MRT_patchDRJWindow(self)
            return ret
        end
    end

    local oldPopulate = ReportWindow.populateList
    if oldPopulate then
        ReportWindow.populateList = function(self, ...)
            local ret = oldPopulate(self, ...)
            MRT_patchDRJWindow(self)
            return ret
        end
    end

    local oldSwitch = ReportWindow.switchTab
    if oldSwitch then
        ReportWindow.switchTab = function(self, ...)
            local ret = oldSwitch(self, ...)
            MRT_patchDRJWindow(self)
            return ret
        end
    end

    local oldClickItem = ReportWindow.onClickItem
    if oldClickItem then
        ReportWindow.onClickItem = function(self, ...)
            local ret = oldClickItem(self, ...)
            MRT_patchDRJWindow(self)
            return ret
        end
    end

    local oldXPMode = ReportWindow._xpSetMode
    if oldXPMode then
        ReportWindow._xpSetMode = function(self, ...)
            local ret = oldXPMode(self, ...)
            MRT_patchDRJWindow(self)
            return ret
        end
    end

    -- The report list hardcodes the English word "kills" in its draw function.
    ReportWindow.drawDatas = function(self, y, item, alt)
        local a = 0.9
        self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, a,
            self.borderColor.r, self.borderColor.g, self.borderColor.b)
        if self.selected == item.index then
            self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.3, 0.7, 0.35, 0.15)
            self.parent.selectedFaction = item.item.superText
        end
        local dayWord = getText("IGUI_Gametime_day"):gsub("^%l", string.upper)
        local kills = item.item.zombieKD or 0
        local factTxt = dayWord .. " " .. tostring(item.item.day or "") .. " (" .. tostring(kills) .. " " .. MRT_killWord(kills) .. ")"
        self:drawText(factTxt, 10, y + 2, 1, 1, 1, a, self.font)
        return y + self.itemheight
    end

    -- XP history keeps English timestamps/amounts internally for selection restore.
    -- Translate only for the actual draw call, then restore the original values.
    local oldDrawXP = ReportWindow.drawPerkHistory
    if oldDrawXP then
        ReportWindow.drawPerkHistory = function(self, y, item, alt)
            local payload = item and item.item
            if not payload then return oldDrawXP(self, y, item, alt) end
            local oldTS, oldAmount = payload.ts, payload.amountText
            if type(oldTS) == "string" then payload.ts = MRT_translateDRJText(oldTS) end
            if type(oldAmount) == "string" then payload.amountText = MRT_translateDRJText(oldAmount) end
            local ret = oldDrawXP(self, y, item, alt)
            payload.ts, payload.amountText = oldTS, oldAmount
            return ret
        end
    end

    return true
end

local MRT_renderInstalled = false
local function MRT_installDRJRenderPatch()
    if MRT_renderInstalled then return true end
    local ok, render = pcall(require, "DRJ/DRJ_Render")
    if not ok or type(render) ~= "table" or type(render.buildDaily) ~= "function" then return false end
    local oldBuildDaily = render.buildDaily
    render.buildDaily = function(rec)
        return MRT_translateDRJText(oldBuildDaily(rec))
    end
    MRT_renderInstalled = true
    return true
end

local function MRT_patchMHPPanel(panel)
    if not panel or not panel.tickBox or type(panel.tickBox.options) ~= "table" then return end
    local map = {
        ["Always visible"] = MRT_T("UI_MRT_MHP_AlwaysVisible"),
        ["Health bar"] = MRT_T("UI_MRT_MHP_HealthBar"),
        ["Muscle strains"] = MRT_T("UI_MRT_MHP_MuscleStrains"),
        ["Lock window"] = MRT_T("UI_MRT_MHP_LockWindow"),
    }
    for i = 1, #panel.tickBox.options do
        local option = panel.tickBox.options[i]
        if type(option) == "string" and map[option] then
            panel.tickBox.options[i] = map[option]
        elseif type(option) == "table" then
            if type(option.text) == "string" and map[option.text] then option.text = map[option.text] end
            if type(option.name) == "string" and map[option.name] then option.name = map[option.name] end
            if type(option[1]) == "string" and map[option[1]] then option[1] = map[option[1]] end
        end
    end
end

local MRT_mhpInstalled = false
local function MRT_installMHPPatch()
    if not ISMhpSettings or MRT_mhpInstalled then return false end
    MRT_mhpInstalled = true

    local labels = {
        ["Always visible"] = "UI_MRT_MHP_AlwaysVisible",
        ["Health bar"] = "UI_MRT_MHP_HealthBar",
        ["Muscle strains"] = "UI_MRT_MHP_MuscleStrains",
        ["Lock window"] = "UI_MRT_MHP_LockWindow",
    }

    local oldAddOption = ISMhpSettings.addOption
    if oldAddOption then
        ISMhpSettings.addOption = function(self, text, selected, setFunction)
            local key = labels[text]
            if key then text = MRT_T(key) end
            return oldAddOption(self, text, selected, setFunction)
        end
    end

    -- The original mod draws "Settings" directly, so translation files alone cannot affect it.
    ISMhpSettings.prerender = function(self)
        local z = 20
        self:drawRect(0, 0, self.width, self.height,
            self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
        self:drawRectBorder(0, 0, self.width, self.height,
            self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
        local title = MRT_T("UI_MRT_MHP_Settings")
        local x = self.width / 2 - (getTextManager():MeasureStringX(UIFont.Medium, title) / 2)
        self:drawText(title, x, z, 1, 1, 1, 1, UIFont.Medium)
    end

    return true
end

local function MRT_patchExactStrings(root, map, depth, seen)
    if type(root) ~= "table" or depth > 8 then return end
    seen = seen or {}
    if seen[root] then return end
    seen[root] = true
    for key, value in pairs(root) do
        if type(value) == "string" then
            local translated = map[value]
            if translated then root[key] = translated end
        elseif type(value) == "table" then
            MRT_patchExactStrings(value, map, depth + 1, seen)
        end
    end
end

local function MRT_patchVisibleFields(root, map, depth, seen)
    if type(root) ~= "table" or depth > 10 then return end
    seen = seen or {}
    if seen[root] then return end
    seen[root] = true
    local visible = { name = true, text = true, title = true, tooltip = true, label = true, description = true }
    for key, value in pairs(root) do
        if type(value) == "string" then
            if visible[key] and map[value] then root[key] = map[value] end
        elseif type(value) == "table" then
            MRT_patchVisibleFields(value, map, depth + 1, seen)
        end
    end
end

local MRT_HIDDEN_UI_MAP = {
    ["NeatUI XP Drop"] = MRT_T("UI_MRT_Page_NeatUIXPDrop"),
    ["Show XP Window"] = MRT_T("UI_MRT_XPDrop_ShowWindow"),
    ["Shows a movable XP bar and XP drops. Multiplayer XP logging remains active when this is disabled."] = MRT_T("UI_MRT_XPDrop_ShowWindow_Tooltip"),

    ["Select custom textures for moodles"] = MRT_T("UI_MRT_MIL_Description1"),
    ["If new packs do not appear in the list, check if they are listed under the Moodles In Lua mod in Mod Order menu"] = MRT_T("UI_MRT_MIL_Description2"),

    ["Return Items after Opening or Unpacking"] = MRT_T("UI_MRT_ReturnItemsAfterOpening"),
    ["Returns items obtained by opening containers or unpacking boxes to their original container. Leftovers and empty containers produced by opening and eating are returned regardless of this setting."] = MRT_T("UI_MRT_ReturnItemsAfterOpening_Tooltip"),

    ["Gunworks: Toggle underbarrel"] = MRT_T("UI_optionscreen_binding_Gunworks_UnderbarrelUse"),
    ["Gunworks: Open weapon loader UI"] = MRT_T("UI_optionscreen_binding_Gunworks_OpenLoaderUI"),
    ["Gunworks: Cycle fire mode"] = MRT_T("UI_optionscreen_binding_Gunworks_SwitchFirerate"),

    ["Show Auto-close option"] = MRT_T("UI_MRT_ShowAutoCloseOption"),
    ["Show or hide the Auto-close option in the world context menu."] = MRT_T("UI_MRT_ShowAutoCloseOption_Tooltip"),
}

local MRT_SANDBOX_MAP = {
    -- getText-backed strings avoid Cyrillic corruption through the Java/Lua bridge.
    ["Mod TchernoLib"] = MRT_T("Sandbox_TchernoLib"),
    ["Vehicle Repair Overhaul"] = MRT_T("Sandbox_VRO"),
    ["Vehicle Repair Overhaul Mod"] = MRT_T("Sandbox_VRO"),

    -- [B42] Pack Mule raw display labels.
    ["Ear Protector Slot"] = MRT_T("UI_MRT_PackMule_EarProtectorSlot"),
    ["Glasses Slot"] = MRT_T("UI_MRT_PackMule_GlassesSlot"),
    ["Wrist Slot"] = MRT_T("UI_MRT_PackMule_WristSlot"),
    ["Shoulder Pad Slot"] = MRT_T("UI_MRT_PackMule_ShoulderPadSlot"),
    ["Duffel Bag Slot"] = MRT_T("UI_MRT_PackMule_DuffelBagSlot"),
    ["Cloth Gun Case Slot"] = MRT_T("UI_MRT_PackMule_ClothGunCaseSlot"),
    ["School Bag Webbing"] = MRT_T("UI_MRT_PackMule_SchoolBagWebbing"),
    ["Crude Bag Webbing"] = MRT_T("UI_MRT_PackMule_CrudeBagWebbing"),
    ["Hiking Bag Webbing"] = MRT_T("UI_MRT_PackMule_HikingBagWebbing"),
    ["Military Bag Webbing"] = MRT_T("UI_MRT_PackMule_MilitaryBagWebbing"),
    ["Framepack Webbing"] = MRT_T("UI_MRT_PackMule_FramepackWebbing"),
    ["Wallet Slot"] = MRT_T("UI_MRT_PackMule_WalletSlot"),
    ["Pouch Slot"] = MRT_T("UI_MRT_PackMule_PouchSlot"),
    ["Auto-Wallet"] = MRT_T("UI_MRT_PackMule_AutoWallet"),
    ["Auto-Pouch"] = MRT_T("UI_MRT_PackMule_AutoPouch"),

    -- [B42] Pack Mule hover descriptions. These are exact strings used by the
    -- pre-1.1/current-compatible option set; keeping them in the same exact map
    -- lets the sandbox screen be fixed once when it is built.
    ["Enables lanterns to equip to belt slots, and welding torches to equip to back slot."] = MRT_T("UI_MRT_PackMule_Attachment_Tooltip"),
    ["Enables fishing basket and slings to equip to satchel slot."] = MRT_T("UI_MRT_PackMule_Satchel_Tooltip"),
    ["Enables dedicated canteen slot, can be worn with satchels."] = MRT_T("UI_MRT_PackMule_Canteen_Tooltip"),
    ["Enables dedicated ear protection slot, cannot be worn with full helmets."] = MRT_T("UI_MRT_PackMule_EarProtectorSlot_Tooltip"),
    ["Enables dedicated wrist slot for watches and bracelets, can be worn with forearm protection."] = MRT_T("UI_MRT_PackMule_WristSlot_Tooltip"),
    ["Enables dedicated lower back slot for duffel and golf bags, can be worn with backpacks."] = MRT_T("UI_MRT_PackMule_DuffelBagSlot_Tooltip"),
    ["Enables dedicated rifle case slot, can be worn with backpacks."] = MRT_T("UI_MRT_PackMule_ClothGunCaseSlot_Tooltip"),
    ["Enables webbing slots on all small backpacks."] = MRT_T("UI_MRT_PackMule_SchoolBagWebbing_Tooltip"),
    ["Enables webbing slots on all small crafted backpacks."] = MRT_T("UI_MRT_PackMule_CrudeBagWebbing_Tooltip"),
    ["Enables webbing slots on all hiking backpacks."] = MRT_T("UI_MRT_PackMule_HikingBagWebbing_Tooltip"),
    ["Enables webbing slots on all military and survivor backpacks."] = MRT_T("UI_MRT_PackMule_MilitaryBagWebbing_Tooltip"),
    ["Enables webbing slots on all crafted framepacks."] = MRT_T("UI_MRT_PackMule_FramepackWebbing_Tooltip"),
    ["Enables carry capacity on all hunting vests and converts them from a clothing item to a container item. If changed mid-game any already existing vests will disappear."] = MRT_T("UI_MRT_PackMule_HuntingVestCapacity_Tooltip"),
    ["Enables two new vest attachment slots and allows for firearm magazines/cd players to equip to them."] = MRT_T("UI_MRT_PackMule_HuntingVestAttachments_Tooltip"),
    ["Disables gaining holes on all hunting vests, best used with 'Hunting Vest Capacity' as container items are non-repairable."] = MRT_T("UI_MRT_PackMule_HuntingVestProtection_Tooltip"),
    ["Enables repairing all hunting vests, does not work when 'Hunting Vest Capacity' is enabled."] = MRT_T("UI_MRT_PackMule_HuntingVestRepair_Tooltip"),
    ["Enables dedicated wallet slot and gives all wallets 50 weight reduction."] = MRT_T("UI_MRT_PackMule_WalletSlot_Tooltip"),

    ["Useless Zombies"] = MRT_T("UI_MRT_Tcherno_UselessZombies"),
    ["When a zombie loses a target it's forbidden to attack (e.g. an infected player), it's marked useless to stop it re-detecting that target - but useless zombies also stop wandering. Off: zombies keep wandering normally, but may walk towards a forbidden target without attacking it."] = MRT_T("UI_MRT_Tcherno_UselessZombies_Tooltip"),
}

-- Pack Mule 1.1 renamed/split several settings. The exact English sentence can
-- vary between revisions, so these narrow prefix/keyword checks cover only Pack
-- Mule-style descriptions. They are O(length of one tooltip) and run only when
-- the tooltip text changes.
local function MRT_translatePackMuleTooltip(value)
    if type(value) ~= "string" or value == "" then return value end
    local lower = value:lower()

    -- Added/split 1.1 options: do the distinctive cases before generic slot checks.
    if lower:find("wallet", 1, true) and lower:find("keyring", 1, true) then
        return MRT_T("UI_MRT_PackMule_AutoWallet_Tooltip")
    end
    if lower:find("pouch", 1, true) and lower:find("keyring", 1, true) then
        return MRT_T("UI_MRT_PackMule_AutoPouch_Tooltip")
    end
    if lower:find("auto", 1, true) and lower:find("wallet", 1, true) then
        return MRT_T("UI_MRT_PackMule_AutoWallet_Tooltip")
    end
    if lower:find("auto", 1, true) and lower:find("pouch", 1, true) then
        return MRT_T("UI_MRT_PackMule_AutoPouch_Tooltip")
    end

    if lower:find("dedicated", 1, true) and lower:find("glasses", 1, true) and lower:find("slot", 1, true) then
        return MRT_T("UI_MRT_PackMule_GlassesSlot_Tooltip")
    end
    if lower:find("shoulder", 1, true) and lower:find("pad", 1, true) and lower:find("slot", 1, true) then
        return MRT_T("UI_MRT_PackMule_ShoulderPadSlot_Tooltip")
    end
    if lower:find("dedicated", 1, true) and lower:find("wallet", 1, true) and lower:find("slot", 1, true) then
        return MRT_T("UI_MRT_PackMule_WalletSlot_Tooltip")
    end
    if lower:find("dedicated", 1, true) and lower:find("pouch", 1, true) and lower:find("slot", 1, true) then
        return MRT_T("UI_MRT_PackMule_PouchSlot_Tooltip")
    end

    return value
end

local MRT_TOOLTIP_FRAGMENTS = {
    { "Shows a movable XP bar and XP drops.", MRT_T("UI_MRT_XPDrop_ShowWindow_Tooltip_Line1") },
    { "Multiplayer XP logging remains active when this is disabled.", MRT_T("UI_MRT_XPDrop_ShowWindow_Tooltip_Line2") },
    { "Choose how recipe XP is displayed.", MRT_T("UI_MRT_RecipeXP_FormatTooltip_Header") },
    { "Basic XP: Shows the base XP.", MRT_T("UI_MRT_RecipeXP_FormatTooltip_Basic") },
    { "Final XP: Shows the final XP after multipliers.", MRT_T("UI_MRT_RecipeXP_FormatTooltip_Final") },
    { "Multiplier: Shows only the multiplier value(s).", MRT_T("UI_MRT_RecipeXP_FormatTooltip_Multiplier") },
    { "Full breakdown: Shows base XP, multiplier(s) and final XP.", MRT_T("UI_MRT_RecipeXP_FormatTooltip_Full") },
}

local function MRT_translateHiddenText(value)
    if type(value) ~= "string" or value == "" then return value end

    local exact = MRT_HIDDEN_UI_MAP[value] or MRT_SANDBOX_MAP[value]
    if exact then return exact end

    local packMule = MRT_translatePackMuleTooltip(value)
    if packMule ~= value then return packMule end

    -- Fast reject: almost every tooltip/panel in the game exits here.
    if not value:find("XP", 1, true)
        and not value:find("recipe", 1, true)
        and not value:find("Multiplayer", 1, true)
    then
        return value
    end

    local result = value
    for i = 1, #MRT_TOOLTIP_FRAGMENTS do
        local pair = MRT_TOOLTIP_FRAGMENTS[i]
        result = MRT_plainReplace(result, pair[1], pair[2])
    end
    return result
end

local function MRT_patchHiddenEnglishUI()
    -- Patch only visible widget fields. Do not touch option IDs or key-binding IDs.
    if ModOptionsScreen and ModOptionsScreen.instance then
        MRT_patchVisibleFields(ModOptionsScreen.instance, MRT_HIDDEN_UI_MAP, 0, {})
    end
    if MainOptions and MainOptions.instance then
        MRT_patchVisibleFields(MainOptions.instance, MRT_HIDDEN_UI_MAP, 0, {})
    end
    if OptionsScreen and OptionsScreen.instance then
        MRT_patchVisibleFields(OptionsScreen.instance, MRT_HIDDEN_UI_MAP, 0, {})
    end
end

local function MRT_patchSandboxScreens()
    if SandboxOptionsScreen and SandboxOptionsScreen.instance then
        MRT_patchExactStrings(SandboxOptionsScreen.instance, MRT_SANDBOX_MAP, 0, {})
    end
    if ServerSettingsScreen and ServerSettingsScreen.instance then
        MRT_patchExactStrings(ServerSettingsScreen.instance, MRT_SANDBOX_MAP, 0, {})
    end
end

-- Direct-field tooltip patch. Старая версия 4.3.8 рекурсивно обходила an entire tooltip
-- всё дерево объекта подсказки и в prerender(), и в render() каждый кадр.
-- В версии 2 этого нет: проверяются только несколько прямых строковых полей,
-- а неизменившиеся значения пропускаются по кэшу.
local MRT_TOOLTIP_FIELDS = {
    "text", "description", "tooltip", "tooltipText", "hoverText", "tip", "title", "label"
}

local function MRT_patchTooltipFields(self)
    if type(self) ~= "table" then return end

    for i = 1, #MRT_TOOLTIP_FIELDS do
        local field = MRT_TOOLTIP_FIELDS[i]
        local value = self[field]

        if type(value) == "string" then
            local cacheField = "_MRT_V2_" .. field
            if self[cacheField] ~= value then
                local translated = MRT_translateHiddenText(value)
                if translated ~= value then
                    self[field] = translated
                    value = translated
                end
                self[cacheField] = value
            end
        end
    end
end

local function MRT_hookAfter(classTable, methodName, markerName, callback)
    if type(classTable) ~= "table" then return false end
    if classTable[markerName] then return true end

    local oldMethod = classTable[methodName]
    if type(oldMethod) ~= "function" then return false end

    classTable[methodName] = function(self, ...)
        local ret = oldMethod(self, ...)
        pcall(callback, self, ...)
        return ret
    end

    classTable[markerName] = true
    return true
end

local function MRT_patchSandboxInstance(self)
    if self then MRT_patchExactStrings(self, MRT_SANDBOX_MAP, 0, {}) end
end

local function MRT_patchOptionsInstance(self)
    if self then MRT_patchVisibleFields(self, MRT_HIDDEN_UI_MAP, 0, {}) end
end

local MRT_tooltipHooked = false
local MRT_richTextHooked = false

local function MRT_installLightUIHooks()
    -- Sandbox pages are patched only when they are created/rebuilt/reshown.
    MRT_hookAfter(SandboxOptionsScreen, "create", "_MRT_V2_createHooked", MRT_patchSandboxInstance)
    MRT_hookAfter(SandboxOptionsScreen, "initialise", "_MRT_V2_initialiseHooked", MRT_patchSandboxInstance)
    MRT_hookAfter(SandboxOptionsScreen, "setVisible", "_MRT_V2_visibleHooked", MRT_patchSandboxInstance)
    MRT_hookAfter(SandboxOptionsScreen, "onMouseDownListbox", "_MRT_V2_listHooked", MRT_patchSandboxInstance)

    MRT_hookAfter(ServerSettingsScreen, "create", "_MRT_V2_createHooked", MRT_patchSandboxInstance)
    MRT_hookAfter(ServerSettingsScreen, "initialise", "_MRT_V2_initialiseHooked", MRT_patchSandboxInstance)
    MRT_hookAfter(ServerSettingsScreen, "setVisible", "_MRT_V2_visibleHooked", MRT_patchSandboxInstance)
    MRT_hookAfter(ServerSettingsScreen, "onMouseDownListbox", "_MRT_V2_listHooked", MRT_patchSandboxInstance)

    MRT_hookAfter(MainOptions, "create", "_MRT_V2_createHooked", MRT_patchOptionsInstance)
    MRT_hookAfter(OptionsScreen, "create", "_MRT_V2_createHooked", MRT_patchOptionsInstance)

    -- One lightweight tooltip hook, prerender only.
    if not MRT_tooltipHooked and type(ISToolTip) == "table" and type(ISToolTip.prerender) == "function" then
        local oldPre = ISToolTip.prerender
        ISToolTip.prerender = function(self, ...)
            MRT_patchTooltipFields(self)
            return oldPre(self, ...)
        end
        MRT_tooltipHooked = true
    end

    -- Some ModOptions descriptions use ISRichTextPanel directly. Cache by text so
    -- the translation work happens once when the text changes, not every frame.
    if not MRT_richTextHooked and type(ISRichTextPanel) == "table" and type(ISRichTextPanel.prerender) == "function" then
        local oldRichPre = ISRichTextPanel.prerender
        ISRichTextPanel.prerender = function(self, ...)
            local value = self and self.text
            if type(value) == "string" and self._MRT_V2_text ~= value then
                local translated = MRT_translateHiddenText(value)
                if translated ~= value then
                    self.text = translated
                    value = translated
                end
                self._MRT_V2_text = value
            end
            return oldRichPre(self, ...)
        end
        MRT_richTextHooked = true
    end
end


-- Long Term Preservation Extended UI Tweak uses B42 CraftRecipe display names
-- directly. Static Recipes.json entries therefore do not reach Neat Crafting.
-- Patch only the matching recipe objects once during startup; no permanent scan.
local MRT_ltpRecipesPatched = false

local MRT_LTP_RECIPE_NAMES = {
    ["Create Jar Label"] = getText("UI_MRT_Runtime_007"),
    ["Create Paper Mold"] = getText("UI_MRT_Runtime_008"),
    ["Create Paper Sheet Using Paper Mold"] = getText("UI_MRT_Runtime_009"),
    ["Create Pulp Using Bleach"] = getText("UI_MRT_Runtime_010"),
    ["Create Usable Paper Sheets"] = getText("UI_MRT_Runtime_011"),
    ["Pack 6 Empty Labeled Jars in Box"] = getText("UI_MRT_Runtime_012"),
    ["Pack 6 Jars of Preserved Food in Box"] = getText("UI_MRT_Runtime_013"),
    ["Pack 6 Jars of Uncooked Food in Box"] = getText("UI_MRT_Runtime_014"),
    ["Make Glue"] = getText("UI_MRT_Runtime_015"),
    ["Unpack Bag of Salt"] = getText("UI_MRT_Runtime_016"),
    ["Make Jar of Preserved Food (Animal Fat)"] = getText("UI_MRT_Runtime_017"),
    ["Make Jar of Preserved Food (Pemmican)"] = getText("UI_MRT_Runtime_018"),
    ["Open Jar of Preserved Food (Animal Fat)"] = getText("UI_MRT_Runtime_019"),
    ["Open Jar of Preserved Food (Pemmican)"] = getText("UI_MRT_Runtime_020"),
}

local function MRT_translateLTPRecipeName(value)
    if type(value) ~= "string" then return nil end

    local exact = MRT_LTP_RECIPE_NAMES[value]
    if exact then return exact end

    local amount = value:match("^Create Pulp Using Bleach%s*%((%d+)%)$")
    if amount then
        return getText("UI_MRT_Runtime_021") .. amount .. ")"
    end

    amount = value:match("^Create Usable Paper Sheets%s*%((%d+)%)$")
    if amount then
        return getText("UI_MRT_Runtime_022") .. amount .. ")"
    end

    return nil
end

local function MRT_recipeCandidate(recipe, methodName)
    if not recipe or type(methodName) ~= "string" then return nil end
    local method = recipe[methodName]
    if not method then return nil end
    local ok, value = pcall(function() return method(recipe) end)
    if ok and type(value) == "string" then return value end
    return nil
end

local function MRT_patchLTPRecipeNames()
    if MRT_ltpRecipesPatched then return true end
    if not ScriptManager or not ScriptManager.instance or not ScriptManager.instance.getAllCraftRecipes then
        return false
    end

    local okList, recipes = pcall(function() return ScriptManager.instance:getAllCraftRecipes() end)
    if not okList or not recipes then return false end

    local okSize, count = pcall(function() return recipes:size() end)
    if not okSize or type(count) ~= "number" or count <= 0 then return false end

    local patched = 0
    for i = 0, count - 1 do
        local okRecipe, recipe = pcall(function() return recipes:get(i) end)
        if okRecipe and recipe then
            -- getTranslationName() is what B42/Neat Crafting normally displays.
            -- getName() is a fallback for recipe variants that expose the raw title there.
            local shownName = MRT_recipeCandidate(recipe, "getTranslationName")
            local rawName = MRT_recipeCandidate(recipe, "getName")
            local russian = MRT_translateLTPRecipeName(shownName) or MRT_translateLTPRecipeName(rawName)

            if russian and recipe.overrideTranslationName then
                local okPatch = pcall(function() recipe:overrideTranslationName(russian) end)
                if okPatch then patched = patched + 1 end
            end
        end
    end

    if patched > 0 then
        MRT_ltpRecipesPatched = true
        return true
    end

    return false
end


-- Barricaded World and Project Seasons add several context-menu labels directly
-- from Lua instead of localization files. Translate only these exact labels when
-- ISContextMenu.addOption() receives them; no per-frame scanning is needed.
local MRT_WORLD_CONTEXT_KEYS = {
    ["BarricadedWorld"] = "UI_MRT_Runtime_023",
    ["Barricaded World"] = "UI_MRT_Runtime_023",
    ["Enable protection for Door"] = "UI_MRT_Runtime_024",
    ["Enable protection for Window"] = "UI_MRT_Runtime_028",
    ["Protect building"] = "UI_MRT_Runtime_025",
    ["Unprotect building"] = "UI_MRT_Runtime_026",
    ["CleanErosion"] = "UI_MRT_Runtime_027",
    ["cleanerosion"] = "UI_MRT_Runtime_027",
}

local MRT_worldContextHooked = false
local function MRT_installWorldContextPatch()
    if MRT_worldContextHooked then return true end
    if type(ISContextMenu) ~= "table" or type(ISContextMenu.addOption) ~= "function" then
        return false
    end

    local oldAddOption = ISContextMenu.addOption
    ISContextMenu.addOption = function(self, name, ...)
        if type(name) == "string" then
            local key = MRT_WORLD_CONTEXT_KEYS[name]
            if key then name = MRT_T(key) end
        end
        return oldAddOption(self, name, ...)
    end

    MRT_worldContextHooked = true
    return true
end

local function MRT_patchLiveInstances()
    pcall(MRT_patchLTPRecipeNames)
    pcall(MRT_installDRJPatch)
    pcall(MRT_installDRJRenderPatch)
    pcall(MRT_installMHPPatch)
    pcall(MRT_installLightUIHooks)
    pcall(MRT_installWorldContextPatch)

    pcall(MRT_patchHiddenEnglishUI)
    pcall(MRT_patchSandboxScreens)

    if ReportWindow then
        if ReportWindow.instance then pcall(MRT_patchDRJWindow, ReportWindow.instance) end
        if type(ReportWindow.instances) == "table" then
            for _, win in pairs(ReportWindow.instances) do
                if win then pcall(MRT_patchDRJWindow, win) end
            end
        end
    end

    if mhpHandle and mhpHandle.settingsPanel then
        pcall(MRT_patchMHPPanel, mhpHandle.settingsPanel)
    end
end

pcall(MRT_patchLiveInstances)
if Events then
    if Events.OnGameBoot then Events.OnGameBoot.Add(MRT_patchLiveInstances) end
    if Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(MRT_patchLiveInstances) end
    if Events.OnGameStart then Events.OnGameStart.Add(MRT_patchLiveInstances) end
end

-- A few mods define their UI classes slightly after boot. Retry only five times
-- during startup, then remove the handler completely. No permanent polling.
local MRT_bootstrapTicks = 0
local MRT_bootstrapAttempts = 0

local function MRT_bootstrapTick()
    MRT_bootstrapTicks = MRT_bootstrapTicks + 1
    if MRT_bootstrapTicks % 120 ~= 0 then return end

    MRT_bootstrapAttempts = MRT_bootstrapAttempts + 1
    pcall(MRT_patchLiveInstances)

    if MRT_bootstrapAttempts >= 5 and Events and Events.OnTick then
        Events.OnTick.Remove(MRT_bootstrapTick)
    end
end

if Events and Events.OnTick then
    Events.OnTick.Add(MRT_bootstrapTick)
end
