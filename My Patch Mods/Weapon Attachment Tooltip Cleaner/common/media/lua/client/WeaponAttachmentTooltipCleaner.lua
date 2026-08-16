-- Weapon Attachment Tooltip Cleaner v2.8.0
-- Project Zomboid 42.20.2 / Guns of Marz
--
-- UI-only goals:
--   * hide the entire native MountOn compatibility block from visible tooltips;
--   * do not redraw any "Can attach to" weapon list;
--   * never derive display names from localized weapon names (prevents mojibake and long class suffixes);
--   * resolve GoM/GOMAR tooltip localization keys at render time, after translations are available;
--   * preserve Show Weapon Stats Plus for HandWeapon items;
--   * never permanently change MountOn, compatibility, stats or gameplay data.

require "ISUI/ISToolTipInv"

WeaponAttachmentTooltipCleaner = WeaponAttachmentTooltipCleaner or {}
local WATC = WeaponAttachmentTooltipCleaner

local okKeys, TooltipKeys = pcall(require, "WeaponAttachmentTooltipCleaner/MarzTooltipKeys")
local okTable, TooltipModule = pcall(require, "MarzWeapons/ItemTooltipsTable")
local okCompat, CompatibilityMap = pcall(require, "WeaponAttachmentTooltipCleaner/CompatibilityMap")
local okShort, ShortNames = pcall(require, "WeaponAttachmentTooltipCleaner/WeaponShortNames")

if not okKeys or type(TooltipKeys) ~= "table" then TooltipKeys = {} end
local TooltipTable = okTable and TooltipModule and TooltipModule.tooltipsPergun or nil
if not okCompat or type(CompatibilityMap) ~= "table" then CompatibilityMap = {} end
if not okShort or type(ShortNames) ~= "table" then ShortNames = {} end

-- These four tooltips belong to the separate attachment rebalance module.
-- Keep the balance/data there, but resolve the displayed localization keys here
-- at render time so raw UI_GOMAR_* strings can never leak to the tooltip.
local REBALANCE_TOOLTIP_KEYS = {
    ["MarzGuns.PL4_Sight"] = {
        "UI_GOMAR_Optic_G1",
        "UI_GOMAR_Optic_G1_Stats",
        "UI_GOMAR_Optic_G1_Range",
    },
    ["MarzGuns.PS1_Sight"] = {
        "UI_GOMAR_Optic_G2",
        "UI_GOMAR_Optic_G2_Stats",
        "UI_GOMAR_Optic_G2_Range",
    },
    ["MarzGuns.PM2_Sight"] = {
        "UI_GOMAR_Optic_G3",
        "UI_GOMAR_Optic_G3_Stats",
        "UI_GOMAR_Optic_G3_Range",
    },
    ["MarzGuns.PRL1_Scope"] = {
        "UI_GOMAR_Optic_G4",
        "UI_GOMAR_Optic_G4_Stats",
        "UI_GOMAR_Optic_G4_Range",
    },
}

-- Fallbacks are intentionally duplicated here only as a last-resort display guard.
-- The real translation ownership remains in Guns of Marz Attachment Rebalance.
local REBALANCE_RU_FALLBACK = {
    UI_GOMAR_Optic_G1 = "Поколение I",
    UI_GOMAR_Optic_G1_Stats = "Шанс критического попадания и шанс попадания увеличены на 1%",
    UI_GOMAR_Optic_G1_Range = "Дальность обзора увеличена на 1%",
    UI_GOMAR_Optic_G2 = "Поколение II",
    UI_GOMAR_Optic_G2_Stats = "Шанс критического попадания и шанс попадания увеличены на 3%",
    UI_GOMAR_Optic_G2_Range = "Дальность обзора увеличена на 3%",
    UI_GOMAR_Optic_G3 = "Поколение III",
    UI_GOMAR_Optic_G3_Stats = "Шанс критического попадания и шанс попадания увеличены на 6%",
    UI_GOMAR_Optic_G3_Range = "Дальность обзора увеличена на 6%",
    UI_GOMAR_Optic_G4 = "Поколение IV",
    UI_GOMAR_Optic_G4_Stats = "Шанс критического попадания и шанс попадания увеличены на 10%",
    UI_GOMAR_Optic_G4_Range = "Дальность обзора увеличена на 10%",
}

-- Category placeholders used by Guns of Marz in a few special MountOn lists.
-- These are rendered directly as localized labels (never concatenated), because
-- concatenating a translated Java string was the source of the v2.6 mojibake.
local SPECIAL_COMPAT_NAMES = {
    ["MarzGuns.FakeItemPistols"] = "UI_WATC_Group_Pistols",
    ["MarzGuns.FakeItemRifles"]  = "UI_WATC_Group_Rifles",
    ["MarzGuns.FakeItemRails"]   = "UI_WATC_Group_Rails",
}

local HIDDEN_COMPAT = {
    ["MarzGuns.FakeItem"] = true,
}

local MAX_COMPAT_PIXEL_WIDTH = 430

local function isWeaponPart(item)
    return item ~= nil and instanceof(item, "WeaponPart")
end

local function translated(key)
    if not key then return nil end
    local ok, value = pcall(getText, key)
    if not ok or value == nil then return nil end

    -- Keys are ASCII, so tostring is safe for the comparison only.
    -- Return the original translated value so Cyrillic stays intact.
    if tostring(value) == tostring(key) then return nil end
    return value
end

local function infoHeader()
    return translated("UI_WATC_InfoHeader")
        or translated("UI_MRT_MarzTooltip_Header_001")
        or "Информация"
end

local function compatHeader()
    return translated("UI_WATC_CanAttach") or "Можно прикрепить на:"
end

local function resolveKeyList(keys, fallback)
    if type(keys) ~= "table" then return nil end
    local lines = {}

    for i = 1, #keys do
        local key = keys[i]
        local value = translated(key)
        if not value and fallback then value = fallback[key] end
        if not value then return nil end
        lines[#lines + 1] = value
    end

    return #lines > 0 and lines or nil
end

local function patchGoMInfoTranslations()
    if not TooltipTable then return end

    local count = 0
    for fullType, keys in pairs(TooltipKeys) do
        if type(keys) == "table" then
            local lines = resolveKeyList(keys)
            if lines and #lines > 0 then
                TooltipTable[fullType] = lines
                count = count + 1
            end
        end
    end

    if count > 0 then
        print("[WATC] v2.8.0 translated GoM info entries: " .. tostring(count))
    end
end

local function normalizeTooltipLines(entry)
    if type(entry) == "string" then
        local lines = {}
        for line in string.gmatch(entry, "[^\r\n]+") do
            if line ~= "" then lines[#lines + 1] = line end
        end
        if #lines == 0 and entry ~= "" then lines[1] = entry end
        return lines
    end

    if type(entry) == "table" then
        local lines = {}
        for index = 1, #entry do
            local line = entry[index]
            if line ~= nil and line ~= "" then
                local raw = tostring(line)
                if string.match(raw, "^UI_[%w_%-]+$") then
                    local resolved = translated(raw)
                    -- Never leak raw localization identifiers into the visible tooltip.
                    -- If a third-party key is genuinely unavailable, omitting that one
                    -- cosmetic line is safer than displaying UI_SOMETHING to the player.
                    if resolved then
                        lines[#lines + 1] = resolved
                    end
                else
                    lines[#lines + 1] = line
                end
            end
        end
        return lines
    end

    return nil
end

local function getCustomTooltipLines(item)
    if not item or not instanceof(item, "InventoryItem") then return nil end

    local okType, fullType = pcall(function() return item:getFullType() end)
    if not okType or not fullType then return nil end
    fullType = tostring(fullType)

    local rebalanceKeys = REBALANCE_TOOLTIP_KEYS[fullType]
    if rebalanceKeys then
        local lines = resolveKeyList(rebalanceKeys, REBALANCE_RU_FALLBACK)
        return lines and #lines > 0 and lines or nil
    end

    local sourceKeys = TooltipKeys[fullType]
    if sourceKeys then
        local lines = resolveKeyList(sourceKeys)
        if lines and #lines > 0 then return lines end
    end

    if not TooltipTable then return nil end
    local entry = TooltipTable[fullType]
    if not entry then return nil end
    local lines = normalizeTooltipLines(entry)
    return lines and #lines > 0 and lines or nil
end

local function mountValueToFullType(value)
    if value == nil then return nil end
    if type(value) == "string" then return value end

    local okName, fullName = pcall(function() return value:getFullName() end)
    if okName and fullName and tostring(fullName) ~= "" then return tostring(fullName) end

    local okType, fullType = pcall(function() return value:getFullType() end)
    if okType and fullType and tostring(fullType) ~= "" then return tostring(fullType) end

    return tostring(value)
end

local function javaListValues(list)
    local out = {}
    if not list then return out end

    local okSize, size = pcall(function() return list:size() end)
    local numericSize = okSize and tonumber(size) or nil
    if numericSize then
        for i = 0, numericSize - 1 do
            local okValue, value = pcall(function() return list:get(i) end)
            if okValue and value ~= nil then
                local fullType = mountValueToFullType(value)
                if fullType then out[#out + 1] = fullType end
            end
        end
        return out
    end

    if type(list) == "table" then
        for _, value in ipairs(list) do
            local fullType = mountValueToFullType(value)
            if fullType then out[#out + 1] = fullType end
        end
    end
    return out
end

local function copyList(values)
    local out = {}
    if type(values) ~= "table" then return out end
    for i = 1, #values do out[i] = values[i] end
    return out
end

local function getStaticCompatibility(item)
    if not item then return {} end
    local okType, fullType = pcall(function() return item:getFullType() end)
    if not okType or not fullType then return {} end
    return copyList(CompatibilityMap[tostring(fullType)])
end

local function getOriginalMountOn(item)
    if not isWeaponPart(item) then return nil, {} end
    local ok, list = pcall(function() return item:getMountOn() end)
    if not ok then return nil, getStaticCompatibility(item) end

    local staticValues = getStaticCompatibility(item)
    if #staticValues > 0 then return list, staticValues end
    return list, javaListValues(list)
end

-- IMPORTANT:
-- B42.20.2 WeaponPart:setMountOn() rejects nil and throws a Java NPE.
-- We therefore use only a valid empty ArrayList while native DoTooltip runs.
-- Fix 4.4 does not redraw any compatibility list. The translated native caption is
-- blanked by this load-last UI patch, and the exact original Java MountOn list is
-- restored immediately after DoTooltip so gameplay compatibility is untouched.
local function withNativeMountValuesHidden(item, original, fn)
    if not isWeaponPart(item) or type(fn) ~= "function" then return fn() end
    if original == nil then return fn() end

    local empty = ArrayList.new()
    item:setMountOn(empty)

    local okCall, result = pcall(fn)

    item:setMountOn(original)

    if not okCall then error(result) end
    return result
end

local function fallbackShortName(fullType)
    local value = tostring(fullType or "")
    value = value:gsub("^.-%.", "")
    value = value:gsub("_Weapon$", "")
    value = value:gsub("_", " ")
    return value ~= "" and value or nil
end

local function resolveCompatToken(fullType)
    if not fullType or HIDDEN_COMPAT[fullType] then return nil end

    local specialKey = SPECIAL_COMPAT_NAMES[fullType]
    if specialKey then
        return { translatedKey = specialKey }
    end

    local short = ShortNames[fullType]
    if not short then short = fallbackShortName(fullType) end
    if not short or short == "" then return nil end
    return { text = short }
end

local function measureText(font, text)
    local ok, width = pcall(function()
        return getTextManager():MeasureStringX(font, text)
    end)
    if ok and type(width) == "number" then return width end
    return #tostring(text) * 7
end

-- Returns display labels only. The header is NOT concatenated into these strings.
-- This avoids the exact Cyrillic low-byte corruption seen in v2.6.
local function buildCompatibilityLabels(tooltip, mountTypes)
    local font = tooltip and tooltip:getFont() or UIFont.Small
    local labels = {}
    local current = "  "
    local seen = {}

    local function flushCurrent()
        if current ~= "  " then
            labels[#labels + 1] = current
            current = "  "
        end
    end

    for _, fullType in ipairs(mountTypes or {}) do
        local token = resolveCompatToken(fullType)
        if token then
            if token.translatedKey then
                flushCurrent()
                local value = translated(token.translatedKey)
                if value then labels[#labels + 1] = value end
            elseif token.text and not seen[token.text] then
                seen[token.text] = true
                local separator = (current == "  ") and "" or " / "
                local candidate = current .. separator .. token.text
                if measureText(font, candidate) > MAX_COMPAT_PIXEL_WIDTH and current ~= "  " then
                    flushCurrent()
                    current = "  " .. token.text
                else
                    current = candidate
                end
            end
        end
    end

    flushCurrent()
    return #labels > 0 and labels or nil
end

-- Match the blue used by the vanilla/source-mod line ("Mod: ...") in the
-- current UI.  Values are kept explicit so the compatibility block stays
-- visually distinct without touching any native tooltip colors.
local COMPAT_MOD_BLUE_R = 99 / 255
local COMPAT_MOD_BLUE_G = 148 / 255
local COMPAT_MOD_BLUE_B = 236 / 255

local function appendOurBlocks(tooltip, item, mountTypes, nativeCaptionPresent)
    -- Fix 4.4 requirement: compatibility is gameplay data, not tooltip content.
    -- Native MountOn values are hidden during DoTooltip and we intentionally do
    -- NOT redraw a compact compatibility list. Keep only independent information
    -- lines supplied by GoM / the attachment rebalance patch.
    local infoLines = getCustomTooltipLines(item)
    if not infoLines or #infoLines == 0 then return end

    local padLeft = tooltip.padLeft or 5
    local padBottom = tooltip.padBottom or 5
    local currentHeight = tooltip:getHeight()
    local layout = tooltip:beginLayout()
    layout:addItem():setLabel(infoHeader(), 1.0, 0.02, 0.02, 1.0)
    for _, line in ipairs(infoLines) do
        layout:addItem():setLabel(line, 1.0, 1.0, 1.0, 1.0)
    end
    local endY = layout:render(padLeft, currentHeight - padBottom, tooltip)
    tooltip:endLayout(layout)
    tooltip:setHeight(endY + padBottom)
end

local function renderWeaponPartTooltip(tooltip, item, originalMount, mountTypes)
    withNativeMountValuesHidden(item, originalMount, function()
        item:DoTooltip(tooltip)
    end)
    appendOurBlocks(tooltip, item, mountTypes, originalMount ~= nil)
end

-- WeaponPart-only renderer copied from vanilla B42.20.2 positioning logic.
-- HandWeapon stays in the existing renderer chain, preserving Show Weapon Stats Plus.
local function renderWeaponPartInventory(self)
    local item = self and self.item or nil
    if not isWeaponPart(item) then return false end
    if ISContextMenu.instance and ISContextMenu.instance.visibleCheck then return true end

    local originalMount, mountTypes = getOriginalMountOn(item)

    local mx = getMouseX() + 24
    local my = getMouseY() + 24
    if not self.followMouse then
        mx = self:getX()
        my = self:getY()
        if self.anchorBottomLeft then
            mx = self.anchorBottomLeft.x
            my = self.anchorBottomLeft.y
        end
    end

    local PADX = 0
    self.tooltip:setX(mx + PADX)
    self.tooltip:setY(my)
    self.tooltip:setWidth(50)
    self.tooltip:setMeasureOnly(true)
    renderWeaponPartTooltip(self.tooltip, item, originalMount, mountTypes)
    self.tooltip:setMeasureOnly(false)

    local myCore = getCore()
    local maxX = myCore:getScreenWidth()
    local maxY = myCore:getScreenHeight()
    local tw = self.tooltip:getWidth()
    local th = self.tooltip:getHeight()

    self.tooltip:setX(math.max(0, math.min(mx + PADX, maxX - tw - 1)))
    if not self.followMouse and self.anchorBottomLeft then
        self.tooltip:setY(math.max(0, math.min(my - th, maxY - th - 1)))
    else
        self.tooltip:setY(math.max(0, math.min(my, maxY - th - 1)))
    end

    if self.contextMenu and self.contextMenu.joyfocus then
        local playerNum = self.contextMenu.player
        self.tooltip:setX(getPlayerScreenLeft(playerNum) + 60)
        self.tooltip:setY(getPlayerScreenTop(playerNum) + 60)
    elseif self.contextMenu and self.contextMenu.currentOptionRect then
        if self.contextMenu.currentOptionRect.height > 32 then
            self:setY(my + self.contextMenu.currentOptionRect.height)
        end
        self:adjustPositionToAvoidOverlap(self.contextMenu.currentOptionRect)
    end

    self:setX(self.tooltip:getX() - PADX)
    self:setY(self.tooltip:getY())
    self:setWidth(tw + PADX)
    self:setHeight(th)

    if self.followMouse and (self.contextMenu == nil) then
        self:adjustPositionToAvoidOverlap({ x = mx - 48, y = my - 48, width = 48, height = 48 })
    end

    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    renderWeaponPartTooltip(self.tooltip, item, originalMount, mountTypes)
    return true
end

local function renderWeaponPartSlotTooltip(tooltip, itemSlot, item, originalMount, mountTypes)
    withNativeMountValuesHidden(item, originalMount, function()
        itemSlot:drawTooltip(tooltip)
    end)
    appendOurBlocks(tooltip, item, mountTypes, originalMount ~= nil)
end

local function renderWeaponPartItemSlot(self)
    local item = self and self.item or nil
    if not isWeaponPart(item) or not self.itemSlot then return false end
    if ISContextMenu.instance and ISContextMenu.instance.visibleCheck then return true end

    local originalMount, mountTypes = getOriginalMountOn(item)
    local mx = getMouseX() + 24
    local my = getMouseY() + 24
    if not self.followMouse then
        mx = self:getX()
        my = self:getY()
        if self.anchorBottomLeft then
            mx = self.anchorBottomLeft.x
            my = self.anchorBottomLeft.y
        end
    end

    local PADX = 0
    self.tooltip:setX(mx + PADX)
    self.tooltip:setY(my)
    self.tooltip:setWidth(50)
    self.tooltip:setMeasureOnly(true)
    renderWeaponPartSlotTooltip(self.tooltip, self.itemSlot, item, originalMount, mountTypes)
    self.tooltip:setMeasureOnly(false)

    local myCore = getCore()
    local maxX = myCore:getScreenWidth()
    local maxY = myCore:getScreenHeight()
    local tw = self.tooltip:getWidth()
    local th = self.tooltip:getHeight()

    self.tooltip:setX(math.max(0, math.min(mx + PADX, maxX - tw - 1)))
    if not self.followMouse and self.anchorBottomLeft then
        self.tooltip:setY(math.max(0, math.min(my - th, maxY - th - 1)))
    else
        self.tooltip:setY(math.max(0, math.min(my, maxY - th - 1)))
    end

    self:setX(self.tooltip:getX() - PADX)
    self:setY(self.tooltip:getY())
    self:setWidth(tw + PADX)
    self:setHeight(th)

    if self.followMouse then
        self:adjustPositionToAvoidOverlap({ x = mx - 48, y = my - 48, width = 48, height = 48 })
    end

    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    renderWeaponPartSlotTooltip(self.tooltip, self.itemSlot, item, originalMount, mountTypes)
    return true
end

-- Show Weapon Stats Plus owns HandWeapon rendering. Add translated GoM Information
-- lines to SWSP.Text without replacing SWSP's renderer/stat block.
local function installSWSPHook()
    if type(SWSP) ~= "table" or type(SWSP.initStats) ~= "function" then return false end
    if SWSP.initStats == WATC._swspInitWrapper then return true end

    local base = SWSP.initStats
    local wrapper
    wrapper = function(self, item)
        local enabled = base(self, item)
        if not enabled then return enabled end

        local lines = getCustomTooltipLines(item)
        if not lines or #lines == 0 then return enabled end

        local originalText = self.Text or {}
        local merged = { infoHeader() }
        for _, line in ipairs(lines) do merged[#merged + 1] = line end
        for _, line in ipairs(originalText) do merged[#merged + 1] = line end
        self.Text = merged
        return enabled
    end

    WATC._swspInitBase = base
    WATC._swspInitWrapper = wrapper
    SWSP.initStats = wrapper
    print("[WATC] v2.8.0 Show Weapon Stats Plus compatibility installed")
    return true
end

local function installItemSlotHook()
    if not ISToolTipItemSlot or type(ISToolTipItemSlot.render) ~= "function" then return false end
    if ISToolTipItemSlot.render == WATC._slotWrapper then return true end

    local base = ISToolTipItemSlot.render
    local wrapper
    wrapper = function(self)
        if self and self.item and isWeaponPart(self.item) then
            return renderWeaponPartItemSlot(self)
        end
        return base(self)
    end

    WATC._slotBase = base
    WATC._slotWrapper = wrapper
    ISToolTipItemSlot.render = wrapper
    return true
end

local function installInventoryHook()
    if not ISToolTipInv or type(ISToolTipInv.render) ~= "function" then return false end
    if ISToolTipInv.render == WATC._inventoryWrapper then return true end

    local base = ISToolTipInv.render
    local wrapper
    wrapper = function(self)
        installSWSPHook()
        installItemSlotHook()

        if self and self.item and isWeaponPart(self.item) then
            return renderWeaponPartInventory(self)
        end
        return base(self)
    end

    WATC._inventoryBase = base
    WATC._inventoryWrapper = wrapper
    ISToolTipInv.render = wrapper
    return true
end

local function install()
    patchGoMInfoTranslations()
    installSWSPHook()
    installItemSlotHook()
    if not installInventoryHook() then return false end
    print("[WATC] v2.8.0 installed - MountOn compatibility hidden; no Can-attach list is redrawn")
    return true
end

install()

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        patchGoMInfoTranslations()
        install()
    end)
end

WATC.version = "2.8.0"
WATC.install = install
WATC.patchGoMInfoTranslations = patchGoMInfoTranslations
print("[WATC] v2.8.0 loaded - compatibility block hidden; raw tooltip keys guarded")
return WATC
