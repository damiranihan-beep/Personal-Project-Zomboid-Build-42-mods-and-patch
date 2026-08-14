-- Weapon Attachment Tooltip Cleaner v2.1 TEST
-- Project Zomboid 42.20.2 / Guns of Marz
--
-- v2.1 deliberately keeps the game's / Guns of Marz tooltip pipeline.
-- It changes presentation only while one tooltip is being rendered:
--   * magazine FakeItem category -> exact compatible GoM weapon fullTypes;
--   * target display names -> short model names;
--   * GoM hard-coded English custom-info block -> existing translated UI_MRT text.
-- Every temporary ScriptItem/MountOn change is restored before render returns.
-- No permanent compatibility/stat/item mutation is performed.

require "ISUI/ISToolTipInv"

WeaponAttachmentTooltipCleaner = WeaponAttachmentTooltipCleaner or {}
local WATC = WeaponAttachmentTooltipCleaner

local okData, Data = pcall(require, "WeaponAttachmentTooltipCleaner/GOMCompatibility")
local okKeys, TooltipKeys = pcall(require, "WeaponAttachmentTooltipCleaner/MarzTooltipKeys")
local okTable, TooltipModule = pcall(require, "MarzWeapons/ItemTooltipsTable")

if not okData or type(Data) ~= "table" then
    print("[WATC] v2.1: compatibility data unavailable; patch disabled")
    return WATC
end

if not okKeys or type(TooltipKeys) ~= "table" then TooltipKeys = {} end
local TooltipTable = okTable and TooltipModule and TooltipModule.tooltipsPergun or nil

local REBALANCE_OWNS = {
    ["MarzGuns.PL4_Sight"] = true,
    ["MarzGuns.PS1_Sight"] = true,
    ["MarzGuns.PM2_Sight"] = true,
    ["MarzGuns.PRL1_Scope"] = true,
}

local function asText(value)
    if value == nil then return nil end
    return tostring(value)
end

local function fullTypeOf(item)
    if not item then return nil end
    local ok, value = pcall(function() return item:getFullType() end)
    return ok and value and asText(value) or nil
end

local function isGoMWeaponPart(item)
    local ft = fullTypeOf(item)
    return ft and string.sub(ft, 1, 9) == "MarzGuns."
        and instanceof(item, "WeaponPart")
end

local function shortName(fullType)
    return Data.shortNames[fullType]
        or string.gsub(string.gsub(fullType or "", "^MarzGuns%.", ""), "_", " ")
end

local function safeScript(fullType)
    if not fullType or fullType == "" then return nil end
    local manager = getScriptManager and getScriptManager() or nil
    if not manager then return nil end
    local ok, script = pcall(function() return manager:getItem(fullType) end)
    return ok and script or nil
end

local function javaListSnapshot(list)
    if not list then return nil end
    local okSize, size = pcall(function() return list:size() end)
    if not okSize or not size then return nil end
    local values = {}
    for i = 0, size - 1 do
        local okGet, value = pcall(function() return list:get(i) end)
        if okGet and value then values[#values + 1] = asText(value) end
    end
    return values
end

local function replaceJavaList(list, values)
    if not list then return false end
    local okClear = pcall(function() list:clear() end)
    if not okClear then return false end
    for i = 1, #(values or {}) do
        local okAdd = pcall(function() list:add(values[i]) end)
        if not okAdd then return false end
    end
    return true
end

local function getMountOnList(item)
    if not item or not instanceof(item, "WeaponPart") then return nil end
    local ok, list = pcall(function() return item:getMountOn() end)
    return ok and list or nil
end

local function pushRename(state, script, newName)
    if not script or not newName or newName == "" or state.renamed[script] then return end
    local okOld, oldName = pcall(function() return script:getDisplayName() end)
    if not okOld or oldName == nil then return end
    local okSet = pcall(function() script:setDisplayName(newName) end)
    if not okSet then return end
    state.renamed[script] = true
    state.renames[#state.renames + 1] = { script = script, oldName = oldName }
end

local function renameTargets(state, targets)
    for i = 1, #(targets or {}) do
        local ft = targets[i]
        if ft and string.sub(ft, 1, 9) == "MarzGuns."
            and not string.find(ft, "FakeItem", 1, true) then
            pushRename(state, safeScript(ft), shortName(ft))
        end
    end
end

local function compactSpecialLabel(itemType, models)
    if itemType == "MarzGuns.Picatinny_Rail" then
        return "M16/M4, AR-15, FN FNC, AKS-74U, AS VAL, FAMAS, CAR-15/XM177, G36, M14/FAL/G3, M24, Mossberg 590, Benelli M4, AA-12, Remington 870, SVD/PSG-1, Winchester/Marlin, MP5"
    end
    local names = {}
    for i = 1, #(models or {}) do names[#names + 1] = shortName(models[i]) end
    return table.concat(names, ", ")
end

local function preparePresentation(item)
    local state = {
        item = item,
        mountList = nil,
        oldMounts = nil,
        renames = {},
        renamed = {},
    }

    if not isGoMWeaponPart(item) then return state end

    local ft = fullTypeOf(item)
    local mountList = getMountOnList(item)
    local currentMounts = javaListSnapshot(mountList) or {}

    local magazineTargets = Data.magazines[ft]
    if magazineTargets and mountList then
        -- GoM magazines expose FakeItemPistols/FakeItemRifles to the tooltip,
        -- while Gunworks magazine profiles contain the real compatibility.
        -- Swap the INSTANCE list only for this render frame, then restore it.
        state.mountList = mountList
        state.oldMounts = currentMounts
        if replaceJavaList(mountList, magazineTargets) then
            renameTargets(state, magazineTargets)
        else
            -- Fallback: if Java list mutation is blocked, restore the original
            -- list immediately and rename the fake category only for this frame.
            pcall(function() replaceJavaList(mountList, currentMounts) end)
            local labelParts = {}
            for i = 1, #magazineTargets do labelParts[#labelParts + 1] = shortName(magazineTargets[i]) end
            local label = table.concat(labelParts, ", ")
            for i = 1, #currentMounts do
                if string.find(currentMounts[i], "FakeItem", 1, true) then
                    pushRename(state, safeScript(currentMounts[i]), label)
                end
            end
        end
        return state
    end

    local specialTargets = Data.specialFakeTargets[ft]
    if specialTargets then
        local label = compactSpecialLabel(ft, specialTargets)
        for i = 1, #currentMounts do
            if string.find(currentMounts[i], "FakeItem", 1, true) then
                pushRename(state, safeScript(currentMounts[i]), label)
            end
        end
        return state
    end

    -- Normal GoM attachments already carry exact MountOn targets. Only shorten
    -- each target's display name (e.g. role/category suffixes disappear).
    renameTargets(state, currentMounts)
    return state
end

local function restorePresentation(state)
    if not state then return end
    if state.mountList and state.oldMounts then
        pcall(function() replaceJavaList(state.mountList, state.oldMounts) end)
    end
    for i = #state.renames, 1, -1 do
        local change = state.renames[i]
        pcall(function() change.script:setDisplayName(change.oldName) end)
    end
end

local function withPresentation(item, fn)
    local state = preparePresentation(item)
    local ok, result = pcall(fn)
    restorePresentation(state)
    if not ok then error(result) end
    return result
end

local function translated(key)
    local ok, value = pcall(getText, key)
    if ok and value and asText(value) ~= key then return value end
    return nil
end

local function patchGoMInfoTranslations()
    if not TooltipTable then return end
    local count = 0
    for fullType, keys in pairs(TooltipKeys) do
        if not REBALANCE_OWNS[fullType] and type(keys) == "table" then
            local lines = {}
            local allTranslated = true
            for i = 1, #keys do
                local line = translated(keys[i])
                if not line then
                    allTranslated = false
                    break
                end
                lines[#lines + 1] = line
            end
            if allTranslated and #lines > 0 then
                TooltipTable[fullType] = lines
                count = count + 1
            end
        end
    end
    print("[WATC] v2.1 translated GoM info entries: " .. tostring(count))
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
            if line ~= nil and line ~= "" then lines[#lines + 1] = line end
        end
        return lines
    end
    return nil
end

local function getCustomTooltipLines(item)
    if not TooltipTable or not item or not instanceof(item, "InventoryItem") then return nil end
    local entry = TooltipTable[item:getFullType()]
    if not entry then return nil end
    local lines = normalizeTooltipLines(entry)
    return lines and #lines > 0 and lines or nil
end

local function infoHeader()
    return translated("UI_WATC_InfoHeader")
        or translated("UI_MRT_MarzTooltip_Header_001")
        or "Информация"
end

local function appendCustomTooltipBlock(tooltip, lines)
    local padLeft = tooltip.padLeft or 5
    local padBottom = tooltip.padBottom or 5
    local currentHeight = tooltip:getHeight()
    local layout = tooltip:beginLayout()
    layout:addItem():setLabel(infoHeader(), 1, 0.02, 0.02, 1)
    for _, line in ipairs(lines) do
        layout:addItem():setLabel(line, 1.0, 1.0, 1.0, 1.0)
    end
    local endY = layout:render(padLeft, currentHeight - padBottom, tooltip)
    tooltip:endLayout(layout)
    tooltip:setHeight(endY + padBottom)
end

local function renderItemTooltip(tooltip, item, lines)
    item:DoTooltip(tooltip)
    appendCustomTooltipBlock(tooltip, lines)
end

local function renderItemSlotTooltip(tooltip, itemSlot, lines)
    itemSlot:drawTooltip(tooltip)
    appendCustomTooltipBlock(tooltip, lines)
end

local function renderCustomInventory(self, item, lines)
    if ISContextMenu.instance and ISContextMenu.instance.visibleCheck then return end

    local mx = getMouseX() + 24
    local my = getMouseY() + 24
    if not self.followMouse then
        mx = self:getX(); my = self:getY()
        if self.anchorBottomLeft then mx = self.anchorBottomLeft.x; my = self.anchorBottomLeft.y end
    end

    local PADX = 0
    self.tooltip:setX(mx + PADX); self.tooltip:setY(my); self.tooltip:setWidth(50)
    self.tooltip:setMeasureOnly(true)
    renderItemTooltip(self.tooltip, item, lines)
    self.tooltip:setMeasureOnly(false)

    local core = getCore(); local maxX = core:getScreenWidth(); local maxY = core:getScreenHeight()
    local tw = self.tooltip:getWidth(); local th = self.tooltip:getHeight()
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
        if self.contextMenu.currentOptionRect.height > 32 then self:setY(my + self.contextMenu.currentOptionRect.height) end
        self:adjustPositionToAvoidOverlap(self.contextMenu.currentOptionRect)
    end

    self:setX(self.tooltip:getX() - PADX); self:setY(self.tooltip:getY())
    self:setWidth(tw + PADX); self:setHeight(th)
    if self.followMouse and not self.contextMenu then
        self:adjustPositionToAvoidOverlap({ x = mx - 48, y = my - 48, width = 48, height = 48 })
    end
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    renderItemTooltip(self.tooltip, item, lines)
end

local function installItemSlotHook()
    if not ISToolTipItemSlot or not ISToolTipItemSlot.render then return end
    if ISToolTipItemSlot.render == WATC._slotWrapper then return end
    local base = ISToolTipItemSlot.render
    local wrapper
    wrapper = function(self)
        local item = self.item
        local lines = item and getCustomTooltipLines(item) or nil
        if not item or not lines then
            return withPresentation(item, function() return base(self) end)
        end
        return withPresentation(item, function()
            if ISContextMenu.instance and ISContextMenu.instance.visibleCheck then return end
            local mx = getMouseX() + 24; local my = getMouseY() + 24
            if not self.followMouse then
                mx = self:getX(); my = self:getY()
                if self.anchorBottomLeft then mx = self.anchorBottomLeft.x; my = self.anchorBottomLeft.y end
            end
            local PADX = 0
            self.tooltip:setX(mx + PADX); self.tooltip:setY(my); self.tooltip:setWidth(50)
            self.tooltip:setMeasureOnly(true)
            if self.itemSlot then renderItemSlotTooltip(self.tooltip, self.itemSlot, lines) end
            self.tooltip:setMeasureOnly(false)
            local core = getCore(); local tw = self.tooltip:getWidth(); local th = self.tooltip:getHeight()
            self.tooltip:setX(math.max(0, math.min(mx + PADX, core:getScreenWidth() - tw - 1)))
            if not self.followMouse and self.anchorBottomLeft then
                self.tooltip:setY(math.max(0, math.min(my - th, core:getScreenHeight() - th - 1)))
            else
                self.tooltip:setY(math.max(0, math.min(my, core:getScreenHeight() - th - 1)))
            end
            self:setX(self.tooltip:getX() - PADX); self:setY(self.tooltip:getY())
            self:setWidth(tw + PADX); self:setHeight(th)
            if self.followMouse then
                self:adjustPositionToAvoidOverlap({ x = mx - 48, y = my - 48, width = 48, height = 48 })
            end
            self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
            self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
            if self.itemSlot then renderItemSlotTooltip(self.tooltip, self.itemSlot, lines) end
        end)
    end
    WATC._slotBase = base; WATC._slotWrapper = wrapper
    ISToolTipItemSlot.render = wrapper
end

local function install()
    patchGoMInfoTranslations()
    if not ISToolTipInv or not ISToolTipInv.render then return end
    if ISToolTipInv.render == WATC._inventoryWrapper then return end

    local base = ISToolTipInv.render
    local wrapper
    wrapper = function(self)
        installItemSlotHook()
        local item = self.item
        local lines = item and getCustomTooltipLines(item) or nil
        if not item or not lines then
            return withPresentation(item, function() return base(self) end)
        end
        return withPresentation(item, function() return renderCustomInventory(self, item, lines) end)
    end
    WATC._inventoryBase = base; WATC._inventoryWrapper = wrapper
    ISToolTipInv.render = wrapper
    installItemSlotHook()
    print("[WATC] v2.1 installed - native item data, exact magazine models, RU GoM info")
end

install()
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(patchGoMInfoTranslations)
end

WATC.version = "2.1"
WATC.install = install
WATC.patchGoMInfoTranslations = patchGoMInfoTranslations
print("[WATC] v2.1 loaded; temporary presentation changes are always restored")
return WATC
