-- Inspect Weapon - Guns of Marz Compatibility
-- Fix 4.1 / v0.6.0 / Project Zomboid Build 42.20.2
--
-- Goals:
--   * keep RiskyInspectWeapon's native header/ammo/condition path, while replacing
--     only the misleading hardcoded attachment-slot area for Guns of Marz weapons;
--   * keep the verified live-magazine tooltip fix;
--   * recover installed GoM parts from getAllWeaponParts();
--   * make GoM attachment interaction reversible from the Inspect Weapon window;
--   * respect Guns of Marz / Gunworks dependency, tool and permanent-part rules;
--   * never scan all script items and never run a heavy per-frame candidate search.
--
-- Important compatibility detail:
-- RiskyInspectWeapon was written against an older ISUpgradeWeapon:new signature and
-- passes a fourth numeric argument (50). Gunworks-gang now uses the fourth argument
-- as UniversalAttachment outcomeFullType. For direct GoM installs this patch calls
-- ISUpgradeWeapon:new(character, weapon, part) WITHOUT that legacy fourth argument.

local TAG = "[GOM Inspect Weapon Compat]"

local okCore = (riskyUI ~= nil and true) or pcall(require, "risky_inspect_core")
local okButton = (attachmentButton ~= nil and magazineButton ~= nil and true) or pcall(require, "risky_inspect_button")

if not okCore or riskyUI == nil or not okButton or attachmentButton == nil or magazineButton == nil then
    print(TAG .. " Fix 4.1: Inspect Weapon UI classes unavailable; compatibility hooks not installed")
    return
end

pcall(require, "TimedActions/ISUpgradeWeapon")
pcall(require, "TimedActions/ISRemoveWeaponUpgrade")
pcall(require, "TimedActions/ISEquipWeaponAction")
pcall(require, "ISUI/ISContextMenu")
pcall(require, "ISUI/ISInventoryPane")
pcall(require, "ISUI/ISInventoryPaneContextMenu")
pcall(require, "WeaponSystems/TimedActions/ISBayonetAttach")

local okCapabilities, DirectSlotCapabilities = pcall(require, "GOMInspectWeaponCompat/DirectSlotCapabilities")
if not okCapabilities or type(DirectSlotCapabilities) ~= "table" then DirectSlotCapabilities = {} end

local okPrevent, PreventRemoval = pcall(require, "WeaponSystems/Utils/PreventRemovals")
local okStock, FoldingStock = pcall(require, "WeaponSystems/Utils/FoldingStock")
local okBipod, FoldingBipod = pcall(require, "WeaponSystems/Utils/FoldingBipod")
local okBayonet, Bayonet = pcall(require, "WeaponSystems/Utils/Bayonet")
local okRequired, RequiredAttachment = pcall(require, "WeaponSystems/Utils/RequiredAttachment")
local okUniversal, UniversalAttachment = pcall(require, "WeaponSystems/Utils/UniversalAttachment")
local okExclusive, UpgradeExclusives = pcall(require, "WeaponSystems/Utils/UpgradeExclusives")
local okRailing, Railing = pcall(require, "WeaponSystems/Utils/Railing")
local okUnderbarrel, Underbarrel = pcall(require, "WeaponSystems/Utils/Underbarrel")

if not okPrevent then PreventRemoval = nil end
if not okStock then FoldingStock = nil end
if not okBipod then FoldingBipod = nil end
if not okBayonet then Bayonet = nil end
if not okRequired then RequiredAttachment = nil end
if not okUniversal then UniversalAttachment = nil end
if not okExclusive then UpgradeExclusives = nil end
if not okRailing then Railing = nil end
if not okUnderbarrel then Underbarrel = nil end

local originalSlotTypes = {
    Canon = true,
    Clip = true,
    RecoilPad = true,
    Scope = true,
    Sling = true,
    Stock = true,
}

local hiddenInternalTypes = {
    Slide = true,
    Pump = true,
    Bolt = true,
    Lever = true,
    Barrel = true,
    Clip = true,
}
for i = 1, 9 do
    hiddenInternalTypes["Animated" .. tostring(i)] = true
end

local preferredOrder = {
    "RailUp",
    "RailDown",
    "RailLeft",
    "RailRight",
    "Underbarrel",
    "UnderbarrelIntegrated",
    "Foregrip",
    "LaserRifle",
    "LightRifle",
    "CanonMount",
    "BoosterScope",
    "Shellholder",
    "Bipod",
    "StockIntegrated",
    "BipodIntegrated",
    "BayonetIntegrated",
    "BayonetKnife",
}

local preferredRank = {}
for i, partType in ipairs(preferredOrder) do
    preferredRank[partType] = i
end

-- Translation files are still shipped, but Build 42/mod load ordering can return
-- a raw custom key in some setups. These Russian fallbacks keep the private RU
-- build readable instead of leaking UI_GOMIW_* keys into the window.
local fallbackRU = {
    UI_GOMIW_SLOT_Canon = "Ствол",
    UI_GOMIW_SLOT_Clip = "Магазин",
    UI_GOMIW_SLOT_RecoilPad = "Затыльник",
    UI_GOMIW_SLOT_Scope = "Прицел",
    UI_GOMIW_SLOT_Sling = "Ремень",
    UI_GOMIW_SLOT_Stock = "Приклад",
    UI_GOMIW_SLOT_RailUp = "Верхняя планка",
    UI_GOMIW_SLOT_RailDown = "Нижняя планка",
    UI_GOMIW_SLOT_RailLeft = "Левая планка",
    UI_GOMIW_SLOT_RailRight = "Правая планка",
    UI_GOMIW_SLOT_Underbarrel = "Подствольный модуль",
    UI_GOMIW_SLOT_UnderbarrelIntegrated = "Встроенный подствольный модуль",
    UI_GOMIW_SLOT_Foregrip = "Передняя рукоять",
    UI_GOMIW_SLOT_LaserRifle = "Лазер",
    UI_GOMIW_SLOT_LightRifle = "Фонарь",
    UI_GOMIW_SLOT_CanonMount = "Дульный адаптер",
    UI_GOMIW_SLOT_BoosterScope = "Модуль прицела",
    UI_GOMIW_SLOT_Shellholder = "Патронташ",
    UI_GOMIW_SLOT_Bipod = "Сошки",
    UI_GOMIW_SLOT_StockIntegrated = "Встроенный приклад",
    UI_GOMIW_SLOT_BipodIntegrated = "Встроенные сошки",
    UI_GOMIW_SLOT_BayonetIntegrated = "Встроенный штык",
    UI_GOMIW_SLOT_BayonetKnife = "Штык-нож",
    UI_GOMIW_PERMANENT = "Несъёмное",
    UI_GOMIW_STATE_FOLDED = "Сложено",
    UI_GOMIW_STATE_DEPLOYED = "Разложено",
    UI_GOMIW_STATE_ON = "Включено",
    UI_GOMIW_STATE_OFF = "Выключено",
    UI_GOMIW_STATE = "Состояние",
    UI_GOMIW_NEED_SCREWDRIVER = "нужна отвёртка",
    UI_GOMIW_REQUIREMENTS = "не выполнены требования установки",
    UI_GOMIW_NO_CANDIDATES = "Нет подходящих деталей в инвентаре",
    UI_GOMIW_REMOVE_DEPENDENTS = "сначала снимите зависимый обвес",
    UI_GOMIW_EXIT_UNDERBARREL = "сначала выключите подствольный режим",
    UI_GOMIW_DETACH_ALL = "Снять все насадки",
    UI_GOMIW_DETACH_ALL_DESC = "Снимает все съёмные насадки, соблюдая зависимости Gunworks. Требуется отвёртка.",
    UI_GOMIW_ATTACH = "Установить",
    UI_GOMIW_DETACH = "Снять",
}

local function uiText(key)
    local text = getText(key)
    if text and text ~= key then return text end
    return fallbackRU[key] or key
end

local function isMarzWeapon(weapon)
    if not weapon or not weapon.getFullType then return false end
    local ok, fullType = pcall(function() return weapon:getFullType() end)
    return ok and fullType ~= nil and string.sub(fullType, 1, 9) == "MarzGuns."
end

local function isMarzPart(part)
    if not part or not part.getFullType then return false end
    local ok, fullType = pcall(function() return part:getFullType() end)
    return ok and fullType ~= nil and string.sub(fullType, 1, 9) == "MarzGuns."
end

local function normalizePartType(partType)
    if partType == "Recoil Pad" then return "RecoilPad" end
    return partType
end

local function safePartType(part)
    if not part or not part.getPartType then return nil end
    local ok, value = pcall(function() return part:getPartType() end)
    if not ok then return nil end
    return normalizePartType(value)
end

local function safeFullType(item)
    if not item or not item.getFullType then return nil end
    local ok, value = pcall(function() return item:getFullType() end)
    if not ok then return nil end
    return value
end

local function getScrewdriver(character)
    if not character or not character.getInventory then return nil end
    local inventory = character:getInventory()
    if not inventory then return nil end
    local ok, result = pcall(function()
        return inventory:getFirstTagEvalRecurse(ItemTag.SCREWDRIVER, predicateNotBroken)
    end)
    if not ok then return nil end
    return result
end

local function hasScrewdriver(character)
    return getScrewdriver(character) ~= nil
end

-- Gunworks already routes ordinary GoM WeaponParts through script-level
-- CanAttach/CanDetach checks that require a screwdriver. Detachable bayonets use
-- dedicated timed actions and are the one native path that otherwise bypasses
-- that tool rule. Guard the timed actions themselves so the requirement cannot
-- be bypassed through the context menu, radial menu, Inspect Weapon or another
-- caller. Integrated bayonet fold/unfold is intentionally not affected.
local bayonetToolGuardInstalled = false
local originalBayonetAttachIsValid = nil
local originalBayonetRemoveIsValid = nil

local function installBayonetToolGuard()
    if bayonetToolGuardInstalled then return true end
    if not ISBayonetAttach or not ISBayonetRemove then return false end
    if type(ISBayonetAttach.isValid) ~= "function" or type(ISBayonetRemove.isValid) ~= "function" then
        return false
    end

    originalBayonetAttachIsValid = ISBayonetAttach.isValid
    originalBayonetRemoveIsValid = ISBayonetRemove.isValid

    ISBayonetAttach.isValid = function(self)
        if not originalBayonetAttachIsValid(self) then return false end
        if isMarzWeapon(self.weapon) and not hasScrewdriver(self.character) then return false end
        return true
    end

    ISBayonetRemove.isValid = function(self)
        if not originalBayonetRemoveIsValid(self) then return false end
        if isMarzWeapon(self.weapon) and not hasScrewdriver(self.character) then return false end
        return true
    end

    bayonetToolGuardInstalled = true
    return true
end

installBayonetToolGuard()

local function getInstalledParts(weapon)
    local byType = {}
    local ordered = {}
    if not weapon or not weapon.getAllWeaponParts then return byType, ordered end

    local ok, parts = pcall(function() return weapon:getAllWeaponParts() end)
    if not ok or not parts then return byType, ordered end

    local okSize, size = pcall(function() return parts:size() end)
    if not okSize or not size then return byType, ordered end

    for i = 0, size - 1 do
        local okGet, part = pcall(function() return parts:get(i) end)
        if okGet and part then
            local partType = safePartType(part)
            if partType and partType ~= "" then
                byType[partType] = part
                table.insert(ordered, { partType = partType, part = part })
            end
        end
    end

    return byType, ordered
end

local function getInstalledPartFallback(weapon, partType)
    partType = normalizePartType(partType)
    if not weapon or not partType then return nil end

    if weapon.getWeaponPart then
        local okDirect, directPart = pcall(function() return weapon:getWeaponPart(partType) end)
        if okDirect and directPart then return directPart, false end
    end

    local byType = getInstalledParts(weapon)
    local fallbackPart = byType[partType]
    if fallbackPart then return fallbackPart, true end
    return nil, false
end

local function isVisibleExtraType(partType)
    partType = normalizePartType(partType)
    if not partType or partType == "" then return false end
    if originalSlotTypes[partType] then return false end
    if hiddenInternalTypes[partType] then return false end
    return true
end

local function isVisibleExtra(partType, part)
    return isVisibleExtraType(partType) and isMarzPart(part)
end

local function getCategoryLabel(partType)
    local key = "UI_GOMIW_SLOT_" .. tostring(partType)
    local text = uiText(key)
    if text == key then return tostring(partType) end
    return text
end

local function inferStateFromFullType(part)
    local fullType = safeFullType(part)
    if not fullType then return nil end
    fullType = string.lower(fullType)
    if string.find(fullType, "folded", 1, true) then return uiText("UI_GOMIW_STATE_FOLDED") end
    if string.find(fullType, "deployed", 1, true) then return uiText("UI_GOMIW_STATE_DEPLOYED") end
    if string.find(fullType, "_off", 1, true) then return uiText("UI_GOMIW_STATE_OFF") end
    if string.find(fullType, "_on", 1, true) then return uiText("UI_GOMIW_STATE_ON") end
    return nil
end

local function getPartState(weapon, partType, part)
    if not weapon then return inferStateFromFullType(part) end

    if partType == "StockIntegrated" and FoldingStock and FoldingStock.HasFoldableStock and FoldingStock.IsStockFolded then
        local okHas, has = pcall(FoldingStock.HasFoldableStock, weapon)
        if okHas and has then
            local okFolded, folded = pcall(FoldingStock.IsStockFolded, weapon)
            if okFolded then
                return folded and uiText("UI_GOMIW_STATE_FOLDED") or uiText("UI_GOMIW_STATE_DEPLOYED")
            end
        end
    elseif partType == "BipodIntegrated" and FoldingBipod and FoldingBipod.HasFoldableBipod and FoldingBipod.IsBipodDeployed then
        local okHas, has = pcall(FoldingBipod.HasFoldableBipod, weapon)
        if okHas and has then
            local okDeployed, deployed = pcall(FoldingBipod.IsBipodDeployed, weapon)
            if okDeployed then
                return deployed and uiText("UI_GOMIW_STATE_DEPLOYED") or uiText("UI_GOMIW_STATE_FOLDED")
            end
        end
    elseif partType == "BayonetIntegrated" and Bayonet and Bayonet.HasIntegratedBayonet and Bayonet.IsBayonetDeployed then
        local okHas, has = pcall(Bayonet.HasIntegratedBayonet, weapon)
        if okHas and has then
            local okDeployed, deployed = pcall(Bayonet.IsBayonetDeployed, weapon)
            if okDeployed then
                return deployed and uiText("UI_GOMIW_STATE_DEPLOYED") or uiText("UI_GOMIW_STATE_FOLDED")
            end
        end
    end

    return inferStateFromFullType(part)
end

local function isAttachableBayonetPart(part)
    if not part or not Bayonet or not Bayonet.GetKnifeTypeFromAttachment then return false end
    local fullType = safeFullType(part)
    if not fullType then return false end
    local ok, knifeType = pcall(Bayonet.GetKnifeTypeFromAttachment, fullType)
    return ok and knifeType ~= nil
end

local function isPermanentPart(part, weapon)
    if not part then return false end

    -- Gunworks registers detachable bayonet attachment objects in PreventRemovals
    -- only to stop generic vanilla removal. They are NOT semantically permanent:
    -- they must be removed through Bayonet.RemoveBayonet / ISBayonetRemove.
    if isAttachableBayonetPart(part) then return false end

    if PreventRemoval and PreventRemoval.IsPermanent then
        local fullType = safeFullType(part)
        if fullType then
            local ok, result = pcall(PreventRemoval.IsPermanent, fullType)
            if ok and result == true then return true end
        end
    end

    local partType = safePartType(part)
    if weapon and partType == "StockIntegrated" and FoldingStock and FoldingStock.HasFoldableStock then
        local ok, result = pcall(FoldingStock.HasFoldableStock, weapon)
        if ok and result == true then return true end
    elseif weapon and partType == "BipodIntegrated" and FoldingBipod and FoldingBipod.HasFoldableBipod then
        local ok, result = pcall(FoldingBipod.HasFoldableBipod, weapon)
        if ok and result == true then return true end
    elseif weapon and partType == "BayonetIntegrated" and Bayonet and Bayonet.HasIntegratedBayonet then
        local ok, result = pcall(Bayonet.HasIntegratedBayonet, weapon)
        if ok and result == true then return true end
    end

    return false
end

local function isRemovalBlockedByDependency(weapon, part)
    if not RequiredAttachment or not RequiredAttachment.IsRemovalBlocked then return false end
    local fullType = safeFullType(part)
    if not fullType then return false end
    local ok, blocked = pcall(RequiredAttachment.IsRemovalBlocked, weapon, fullType)
    return ok and blocked == true
end

local function isActiveUnderbarrelPart(weapon, part)
    if not weapon or not part or not Underbarrel then return false end
    if not Underbarrel.IsWeaponInUnderbarrelMode or not Underbarrel.UnderbarrelAttachments then return false end

    local fullType = safeFullType(part)
    if not fullType or not Underbarrel.UnderbarrelAttachments[fullType] then return false end

    local okMode, active = pcall(Underbarrel.IsWeaponInUnderbarrelMode, weapon)
    return okMode and active == true
end

local function isRailingBlocked(weapon, part)
    if not weapon or not part or not Railing or not Railing.HasMountedAccessoryOnRailing then return false end
    local ok, blocked = pcall(Railing.HasMountedAccessoryOnRailing, weapon, part)
    return ok and blocked == true
end

local function getRemovalStatus(character, weapon, part)
    if not part then return false, nil end

    -- The private integration intentionally requires the screwdriver for every
    -- detachable Guns of Marz attachment path, including the dedicated bayonet
    -- action which does not require it by itself in upstream Gunworks.
    if isMarzPart(part) and not hasScrewdriver(character) then
        return false, uiText("UI_GOMIW_NEED_SCREWDRIVER")
    end

    if isAttachableBayonetPart(part) then
        if Bayonet and Bayonet.CanRemoveBayonet then
            local ok, allowed = pcall(Bayonet.CanRemoveBayonet, weapon)
            if ok and allowed then return true, nil end
        end
        return false, uiText("UI_GOMIW_REQUIREMENTS")
    end

    if isPermanentPart(part, weapon) then
        return false, uiText("UI_GOMIW_PERMANENT")
    end

    -- Gunworks blocks removal of an active underbarrel attachment until the
    -- player exits underbarrel mode. Inspect Weapon must follow the same rule.
    if isActiveUnderbarrelPart(weapon, part) then
        return false, uiText("UI_GOMIW_EXIT_UNDERBARREL")
    end

    if isRemovalBlockedByDependency(weapon, part) or isRailingBlocked(weapon, part) then
        return false, uiText("UI_GOMIW_REMOVE_DEPENDENTS")
    end

    -- Universal rails can also be blocked by Gunworks railing rules in addition
    -- to RequiredAttachment dependencies. Ask the framework before queueing the
    -- normal removal action so a mounted child can never be orphaned.
    if UniversalAttachment and UniversalAttachment.IsRegisteredOutcome and UniversalAttachment.CanRemoveInstalledPart then
        local okRegistered, registered = pcall(UniversalAttachment.IsRegisteredOutcome, weapon, part)
        if okRegistered and registered then
            local okCanRemove, canRemove = pcall(UniversalAttachment.CanRemoveInstalledPart, weapon, part)
            if not okCanRemove or not canRemove then
                return false, uiText("UI_GOMIW_REMOVE_DEPENDENTS")
            end
        end
    end

    return true, nil
end

local function closeTooltip(button)
    if not button or not button.toolTip then return end
    pcall(function()
        button.toolTip:setVisible(false)
        button.toolTip:removeFromUIManager()
    end)
end

local function cleanupExtraButtons(ui)
    if not ui or not ui.gomIwExtraSlots then return end
    for _, slot in ipairs(ui.gomIwExtraSlots) do
        closeTooltip(slot.button)
    end
    ui.gomIwExtraSlots = nil
end

local function syncMagazineProxy(slotItem, weapon)
    if not slotItem or not weapon then return end
    if not slotItem.setCurrentAmmoCount or not weapon.getCurrentAmmoCount then return end

    local okCount, count = pcall(function() return weapon:getCurrentAmmoCount() end)
    if not okCount or count == nil then return end

    pcall(function() slotItem:setCurrentAmmoCount(count) end)
end

local function safeMountsOnWeapon(part, weapon)
    if not part or not weapon or not part.getMountOn then return false end
    local ok, mounts = pcall(function() return part:getMountOn() end)
    if not ok or not mounts then return false end
    local weaponType = safeFullType(weapon)
    if not weaponType then return false end
    local okContains, contains = pcall(function() return mounts:contains(weaponType) end)
    return okContains and contains == true
end

local function collectInventoryEntries(container, out, visited)
    if not container or not container.getItems then return end
    out = out or {}
    visited = visited or {}

    local okItems, items = pcall(function() return container:getItems() end)
    if not okItems or not items then return out end

    local okSize, size = pcall(function() return items:size() end)
    if not okSize or not size then return out end

    for i = 0, size - 1 do
        local okGet, item = pcall(function() return items:get(i) end)
        if okGet and item then
            local id = nil
            if item.getID then
                pcall(function() id = item:getID() end)
            end
            local visitKey = id or tostring(item)
            if not visited[visitKey] then
                visited[visitKey] = true
                table.insert(out, { item = item, container = container })

                if instanceof(item, "InventoryContainer") and item.getInventory then
                    local okInv, child = pcall(function() return item:getInventory() end)
                    if okInv and child then
                        collectInventoryEntries(child, out, visited)
                    end
                end
            end
        end
    end

    return out
end

local function getInventoryEntries(character)
    if not character or not character.getInventory then return {} end
    return collectInventoryEntries(character:getInventory(), {}, {})
end

local function isDirectInstallEnabled(character, weapon, part)
    if not part or not weapon then return false end
    local fullType = safeFullType(part)
    if not fullType then return false end

    local partType = safePartType(part)
    if partType and weapon.getWeaponPart then
        local okOccupied, occupied = pcall(function() return weapon:getWeaponPart(partType) end)
        if okOccupied and occupied ~= nil then return false end
    end

    local canAttach = true
    if part.canAttach then
        local ok, result = pcall(function() return part:canAttach(character, weapon) end)
        if ok then canAttach = result == true end
    end
    if not canAttach then return false end

    if RequiredAttachment and RequiredAttachment.IsInstallationBlocked then
        local ok, blocked = pcall(RequiredAttachment.IsInstallationBlocked, weapon, fullType)
        if ok and blocked then return false end
    end

    if UpgradeExclusives and UpgradeExclusives.IsBlockedByExclusive then
        local ok, blocked = pcall(UpgradeExclusives.IsBlockedByExclusive, weapon, fullType)
        if ok and blocked then return false end
    end

    return true
end

local function addCandidate(list, seen, candidate)
    if not candidate or not candidate.key or seen[candidate.key] then return end
    seen[candidate.key] = true
    table.insert(list, candidate)
end

local function buildCandidatesForType(character, weapon, requestedType)
    requestedType = normalizePartType(requestedType)
    local candidates = {}
    local seen = {}
    local entries = getInventoryEntries(character)
    local screwdriver = hasScrewdriver(character)

    -- Direct WeaponPart candidates already present in the player's inventory.
    for _, entry in ipairs(entries) do
        local item = entry.item
        if item and instanceof(item, "WeaponPart") and isMarzPart(item) then
            local partType = safePartType(item)
            if partType == requestedType and safeMountsOnWeapon(item, weapon) then
                local enabled = isDirectInstallEnabled(character, weapon, item)
                local reason = nil
                if not enabled then
                    reason = screwdriver and uiText("UI_GOMIW_REQUIREMENTS") or uiText("UI_GOMIW_NEED_SCREWDRIVER")
                end

                addCandidate(candidates, seen, {
                    key = "direct:" .. tostring(safeFullType(item)),
                    kind = "direct",
                    displayItem = item,
                    sourceItem = item,
                    sourceContainer = entry.container,
                    partType = partType,
                    enabled = enabled,
                    reason = reason,
                })
            end
        end
    end

    -- Gunworks UniversalAttachment: the inventory contains a generic rail item,
    -- while the installed weapon part is a weapon-specific outcome. This is how
    -- e.g. the Mossberg top Picatinny rail must be reinstalled.
    if UniversalAttachment and UniversalAttachment.GetGenericItemTypes and UniversalAttachment.GetOutcomes then
        local okTypes, genericTypes = pcall(UniversalAttachment.GetGenericItemTypes, weapon)
        if okTypes and genericTypes then
            local byFullType = {}
            for _, entry in ipairs(entries) do
                local fullType = safeFullType(entry.item)
                if fullType and not byFullType[fullType] then
                    byFullType[fullType] = entry
                end
            end

            for _, genericType in ipairs(genericTypes) do
                local sourceEntry = byFullType[genericType]
                if sourceEntry then
                    local okOutcomes, outcomes = pcall(UniversalAttachment.GetOutcomes, weapon, genericType)
                    if okOutcomes and outcomes then
                        for _, outcomeType in ipairs(outcomes) do
                            local outcomePart = instanceItem(outcomeType)
                            if outcomePart and instanceof(outcomePart, "WeaponPart") and safePartType(outcomePart) == requestedType then
                                local enabled = false
                                if UniversalAttachment.CanInstallOutcome then
                                    local okEnabled, result = pcall(UniversalAttachment.CanInstallOutcome, weapon, outcomeType, character)
                                    enabled = okEnabled and result == true
                                end
                                local reason = nil
                                if not enabled then
                                    reason = screwdriver and uiText("UI_GOMIW_REQUIREMENTS") or uiText("UI_GOMIW_NEED_SCREWDRIVER")
                                end

                                addCandidate(candidates, seen, {
                                    key = "universal:" .. tostring(genericType) .. ">" .. tostring(outcomeType),
                                    kind = "universal",
                                    displayItem = outcomePart,
                                    sourceItem = sourceEntry.item,
                                    sourceContainer = sourceEntry.container,
                                    outcomeType = outcomeType,
                                    partType = requestedType,
                                    enabled = enabled,
                                    reason = reason,
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    -- Bayonets are real knife inventory items converted by Gunworks into a
    -- BayonetKnife WeaponPart. They must use the dedicated bayonet timed action.
    if requestedType == "BayonetKnife" and Bayonet and Bayonet.BayonetKnives then
        for _, entry in ipairs(entries) do
            local item = entry.item
            local fullType = safeFullType(item)
            if fullType and Bayonet.BayonetKnives[fullType] then
                local frameworkAllowed = false
                if Bayonet.CanAttachBayonet then
                    local okEnabled, result = pcall(Bayonet.CanAttachBayonet, weapon, item)
                    frameworkAllowed = okEnabled and result == true
                end
                local screwdriverReady = hasScrewdriver(character)
                local enabled = frameworkAllowed and screwdriverReady
                local reason = nil
                if not screwdriverReady then
                    reason = uiText("UI_GOMIW_NEED_SCREWDRIVER")
                elseif not frameworkAllowed then
                    reason = uiText("UI_GOMIW_REQUIREMENTS")
                end
                addCandidate(candidates, seen, {
                    key = "bayonet:" .. tostring(fullType),
                    kind = "bayonet",
                    displayItem = item,
                    sourceItem = item,
                    sourceContainer = entry.container,
                    partType = requestedType,
                    enabled = enabled,
                    reason = reason,
                })
            end
        end
    end

    table.sort(candidates, function(a, b)
        local an = a.displayItem and a.displayItem:getDisplayName() or a.key
        local bn = b.displayItem and b.displayItem:getDisplayName() or b.key
        return string.lower(tostring(an)) < string.lower(tostring(bn))
    end)

    return candidates
end

local function getCandidateExtraTypes(character, weapon)
    local types = {}
    local entries = getInventoryEntries(character)

    for _, entry in ipairs(entries) do
        local item = entry.item
        if item and instanceof(item, "WeaponPart") and isMarzPart(item) then
            local partType = safePartType(item)
            if isVisibleExtraType(partType) and safeMountsOnWeapon(item, weapon) then
                types[partType] = true
            end
        end
    end

    if UniversalAttachment and UniversalAttachment.GetGenericItemTypes and UniversalAttachment.GetOutcomes then
        local byFullType = {}
        for _, entry in ipairs(entries) do
            local fullType = safeFullType(entry.item)
            if fullType then byFullType[fullType] = true end
        end

        local okTypes, genericTypes = pcall(UniversalAttachment.GetGenericItemTypes, weapon)
        if okTypes and genericTypes then
            for _, genericType in ipairs(genericTypes) do
                if byFullType[genericType] then
                    local okOutcomes, outcomes = pcall(UniversalAttachment.GetOutcomes, weapon, genericType)
                    if okOutcomes and outcomes then
                        for _, outcomeType in ipairs(outcomes) do
                            local part = instanceItem(outcomeType)
                            if part and instanceof(part, "WeaponPart") then
                                local partType = safePartType(part)
                                if isVisibleExtraType(partType) then
                                    types[partType] = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if Bayonet and Bayonet.BayonetKnives and Bayonet.BayonetMountableWeapons then
        local weaponType = safeFullType(weapon)
        local accepted = weaponType and Bayonet.BayonetMountableWeapons[weaponType] or nil
        if accepted then
            for _, entry in ipairs(entries) do
                local knifeType = safeFullType(entry.item)
                local knifeEntry = knifeType and Bayonet.BayonetKnives[knifeType] or nil
                if knifeEntry and accepted[knifeEntry.bayonetType] then
                    types.BayonetKnife = true
                    break
                end
            end
        end
    end

    return types
end

local function moveCandidateToMainInventory(character, candidate)
    if not character or not candidate or not candidate.sourceItem then return false end
    local main = character:getInventory()
    local source = candidate.sourceContainer
    if source and source ~= main then
        local ok = pcall(function()
            source:Remove(candidate.sourceItem)
            main:AddItem(candidate.sourceItem)
        end)
        if not ok then return false end
        candidate.sourceContainer = main
    end
    return true
end

local function queueReequip(character, weapon)
    if not character or not weapon or not ISEquipWeaponAction then return end
    ISTimedActionQueue.add(ISEquipWeaponAction:new(
        character,
        weapon,
        50,
        true,
        weapon:isRequiresEquippedBothHands()
    ))
end

local function performCandidateInstall(character, weapon, candidate)
    if not character or not weapon or not candidate or not candidate.enabled then return end
    if not hasScrewdriver(character) then return end
    if not moveCandidateToMainInventory(character, candidate) then return end

    if candidate.kind == "bayonet" then
        if ISBayonetAttach then
            ISTimedActionQueue.add(ISBayonetAttach:new(character, weapon, candidate.sourceItem))
        elseif Bayonet and Bayonet.AttachBayonet then
            -- No unsafe direct fallback: without the framework timed action we
            -- deliberately do nothing rather than bypass synchronization.
            print(TAG .. " Fix 4.1: ISBayonetAttach unavailable; bayonet install skipped")
        end
        return
    end

    if candidate.kind == "universal" then
        if ISUpgradeWeapon then
            ISTimedActionQueue.add(ISUpgradeWeapon:new(character, weapon, candidate.sourceItem, candidate.outcomeType))
            queueReequip(character, weapon)
        end
        return
    end

    if candidate.kind == "direct" then
        if ISUpgradeWeapon then
            -- DO NOT pass RiskyInspectWeapon's legacy 50 here. Gunworks uses
            -- argument #4 as UniversalAttachment outcomeFullType.
            ISTimedActionQueue.add(ISUpgradeWeapon:new(character, weapon, candidate.sourceItem))
            queueReequip(character, weapon)
        end
    end
end

local function openCandidateMenu(button)
    if not button or not button.character or not button.attachingTo then return end
    local character = button.character
    local weapon = button.attachingTo
    local partType = normalizePartType(button.attachmentType)
    if not isMarzWeapon(weapon) or not partType then return end

    local candidates = buildCandidatesForType(character, weapon, partType)
    local playerNum = character:getPlayerNum()
    local window = riskyInspectWindow and riskyInspectWindow[playerNum] or nil
    if not window then return end

    local x = window:getX() + button:getX() + button:getWidth() + 4
    local y = window:getY() + button:getY()
    local context = ISContextMenu.get(playerNum, x, y)
    context.origin = window

    if #candidates == 0 then
        local option = context:addOption(uiText("UI_GOMIW_NO_CANDIDATES"))
        option.notAvailable = true
    else
        for _, candidate in ipairs(candidates) do
            local name = candidate.displayItem and candidate.displayItem:getDisplayName() or candidate.key
            if not candidate.enabled and candidate.reason then
                name = tostring(name) .. " — " .. tostring(candidate.reason)
            end
            local option = context:addOption(name, candidate, function(c)
                performCandidateInstall(character, weapon, c)
            end)
            if not candidate.enabled then
                option.notAvailable = true
            end
        end
    end

    context:bringToTop()
    if getJoypadFocus and setJoypadFocus then
        pcall(function() setJoypadFocus(playerNum, context) end)
    end
end

local function removeGoMPart(button)
    if not button or not button.slotItem or not button.character or not button.attachingTo then return end
    local character = button.character
    local weapon = button.attachingTo
    local part = button.slotItem

    local allowed = getRemovalStatus(character, weapon, part)
    if not allowed then return end

    if isAttachableBayonetPart(part) then
        if ISBayonetRemove then
            ISTimedActionQueue.add(ISBayonetRemove:new(character, weapon))
        end
        return
    end

    local partType = safePartType(part) or normalizePartType(button.attachmentType)
    if partType and ISRemoveWeaponUpgrade then
        ISTimedActionQueue.add(ISRemoveWeaponUpgrade:new(character, weapon, partType))
    end
end

-- --------------------------------------------------------------------------
-- Base attachment slot recovery
-- --------------------------------------------------------------------------
local originalAttachmentNew = attachmentButton.new
function attachmentButton:new(x, y, w, h, slotItem, attachingTo, attachmentType, character)
    local fallbackUsed = false
    local normalizedType = normalizePartType(attachmentType)

    if slotItem == nil and isMarzWeapon(attachingTo) and originalSlotTypes[normalizedType] then
        local recovered, usedFallback = getInstalledPartFallback(attachingTo, normalizedType)
        if recovered then
            slotItem = recovered
            fallbackUsed = usedFallback
        end
    end

    local button = originalAttachmentNew(self, x, y, w, h, slotItem, attachingTo, attachmentType, character)
    if button and fallbackUsed then
        button.gomIwRecoveredInstalledPart = true
    end
    return button
end

-- --------------------------------------------------------------------------
-- Magazine proxy synchronization
-- --------------------------------------------------------------------------
local originalMagazineNew = magazineButton.new
function magazineButton:new(x, y, w, h, slotItem, attachingTo, character)
    syncMagazineProxy(slotItem, attachingTo)
    return originalMagazineNew(self, x, y, w, h, slotItem, attachingTo, character)
end

local originalMagazineRender = magazineButton.render
function magazineButton:render()
    syncMagazineProxy(self.slotItem, self.attachingTo)
    return originalMagazineRender(self)
end

-- --------------------------------------------------------------------------
-- Interaction adaptation
-- --------------------------------------------------------------------------
local originalDoubleClick = attachmentButton.onMouseDoubleClick
function attachmentButton:onMouseDoubleClick()
    if isMarzWeapon(self.attachingTo) and self.slotItem and isMarzPart(self.slotItem) then
        return removeGoMPart(self)
    end
    return originalDoubleClick(self)
end

local originalMouseUp = attachmentButton.onMouseUp
function attachmentButton:onMouseUp()
    if isMarzWeapon(self.attachingTo) and self.slotItem == nil then
        -- Show the candidate menu even when the screwdriver is absent. Invalid
        -- choices remain visible but disabled with an explicit reason.
        return openCandidateMenu(self)
    end
    return originalMouseUp(self)
end

local originalJoypadConfirm = attachmentButton.joypadConfirm
function attachmentButton:joypadConfirm()
    if isMarzWeapon(self.attachingTo) then
        if self.slotItem then
            return removeGoMPart(self)
        end
        return openCandidateMenu(self)
    end
    return originalJoypadConfirm(self)
end

local originalJoypadPrompt = attachmentButton.joypadPrompt
function attachmentButton:joypadPrompt()
    if isMarzWeapon(self.attachingTo) then
        if self.slotItem then
            local allowed, reason = getRemovalStatus(self.character, self.attachingTo, self.slotItem)
            if allowed then return uiText("UI_GOMIW_DETACH") end
            return reason
        end
        return uiText("UI_GOMIW_ATTACH")
    end
    return originalJoypadPrompt(self)
end

-- RiskyInspectWeapon's own addAttachmentButton calls
-- ISUpgradeWeapon:new(character, weapon, part, 50), which Gunworks interprets as
-- universal outcome "50". Intercept actual GoM candidates and use the modern
-- direct three-argument call. Non-GoM behavior remains untouched.
if addAttachmentButton then
    local originalAddMouseDown = addAttachmentButton.onMouseDown
    function addAttachmentButton:onMouseDown()
        if self.slotItem and self.enabled and isMarzWeapon(self.attachingTo) and isMarzPart(self.slotItem) then
            local enabled = isDirectInstallEnabled(self.character, self.attachingTo, self.slotItem)
            if not enabled then return end

            if self.container ~= nil then
                self.container:Remove(self.slotItem)
                self.character:getInventory():AddItem(self.slotItem)
            end

            if ISUpgradeWeapon then
                ISTimedActionQueue.add(ISUpgradeWeapon:new(self.character, self.attachingTo, self.slotItem))
                queueReequip(self.character, self.attachingTo)
            end
            return
        end
        return originalAddMouseDown(self)
    end

    local originalAddJoypad = addAttachmentButton.joypadConfirm
    function addAttachmentButton:joypadConfirm()
        if self.slotItem and self.enabled and isMarzWeapon(self.attachingTo) and isMarzPart(self.slotItem) then
            local enabled = isDirectInstallEnabled(self.character, self.attachingTo, self.slotItem)
            if not enabled then return end

            if self.container ~= nil then
                self.container:Remove(self.slotItem)
                self.character:getInventory():AddItem(self.slotItem)
            end

            if ISUpgradeWeapon then
                ISTimedActionQueue.add(ISUpgradeWeapon:new(self.character, self.attachingTo, self.slotItem))
                queueReequip(self.character, self.attachingTo)
            end
            return
        end
        return originalAddJoypad(self)
    end
end

-- --------------------------------------------------------------------------
-- Fix 4.1 dynamic model-aware attachment layout
-- --------------------------------------------------------------------------
local managedSlotOrder = {
    "Canon",
    "Clip",
    "CanonMount",
    "RailUp",
    "Scope",
    "Underbarrel",
    "Stock",
    "RecoilPad",
    "Sling",
    "RailDown",
    "Foregrip",
    "Bipod",
    "RailLeft",
    "LightRifle",
    "RailRight",
    "LaserRifle",
    "BoosterScope",
    "Shellholder",
    "BayonetKnife",
    "UnderbarrelIntegrated",
    "StockIntegrated",
    "BipodIntegrated",
    "BayonetIntegrated",
}

local managedSlotRank = {}
for i, partType in ipairs(managedSlotOrder) do managedSlotRank[partType] = i end

local function isManagedVisibleType(partType)
    partType = normalizePartType(partType)
    if not partType or partType == "" then return false end
    if partType == "Clip" then return true end
    if hiddenInternalTypes[partType] then return false end
    return true
end

local function addCapability(capabilities, partType)
    partType = normalizePartType(partType)
    if isManagedVisibleType(partType) then capabilities[partType] = true end
end

local function mergeRuntimeCapabilities(weapon, capabilities)
    if not weapon then return end

    -- A detachable magazine is a real inspectable slot. Fixed/internal magazines
    -- are ammunition state, not an attachment slot, and therefore are not drawn.
    local okMag, magazineType = pcall(function() return weapon:getMagazineType() end)
    if okMag and magazineType then capabilities.Clip = true end

    -- Always retain a genuinely installed visible part even if another mod added
    -- that capability after the supplied Guns of Marz scripts were generated.
    local _, ordered = getInstalledParts(weapon)
    for _, entry in ipairs(ordered) do
        addCapability(capabilities, entry.partType)
    end

    -- UniversalAttachment registrations are model-specific Gunworks rails. Add
    -- their outcome PartTypes even when the player does not currently own a rail,
    -- so the Inspect window describes the gun model instead of the inventory.
    if UniversalAttachment and UniversalAttachment.GetGenericItemTypes and UniversalAttachment.GetOutcomes then
        local okTypes, genericTypes = pcall(UniversalAttachment.GetGenericItemTypes, weapon)
        if okTypes and genericTypes then
            for _, genericType in ipairs(genericTypes) do
                local okOutcomes, outcomes = pcall(UniversalAttachment.GetOutcomes, weapon, genericType)
                if okOutcomes and outcomes then
                    for _, outcomeType in ipairs(outcomes) do
                        local outcome = instanceItem(outcomeType)
                        if outcome and instanceof(outcome, "WeaponPart") then
                            addCapability(capabilities, safePartType(outcome))
                        end
                    end
                end
            end
        end
    end

    -- Gunworks bayonets are knife -> WeaponPart conversions, so they do not have
    -- a normal direct MountOn entry. The registry itself is authoritative.
    if Bayonet and Bayonet.BayonetMountableWeapons then
        local fullType = safeFullType(weapon)
        if fullType and Bayonet.BayonetMountableWeapons[fullType] then
            capabilities.BayonetKnife = true
        end
    end
end

local function getModelCapabilities(weapon)
    local capabilities = {}
    local fullType = safeFullType(weapon)
    local direct = fullType and DirectSlotCapabilities[fullType] or nil
    if direct then
        for partType, allowed in pairs(direct) do
            if allowed then addCapability(capabilities, partType) end
        end
    end
    mergeRuntimeCapabilities(weapon, capabilities)
    return capabilities
end

local function createMagazineProxy(weapon)
    if not weapon or not weapon.getMagazineType then return nil end
    local okType, magazineType = pcall(function() return weapon:getMagazineType() end)
    if not okType or not magazineType then return nil end
    local okContains, contains = pcall(function() return weapon:isContainsClip() end)
    if not okContains or not contains then return nil end

    local proxy = nil
    local ok = pcall(function()
        local tempContainer = ItemContainer.new("gomInspectMagazine", nil, nil)
        proxy = tempContainer:AddItem(magazineType)
        tempContainer:clear()
    end)
    if not ok then return nil end
    syncMagazineProxy(proxy, weapon)
    return proxy
end

local function hideNativeBaseSlots(ui)
    if not ui or not ui.elements then return end
    for index = 2, 7 do
        local button = ui.elements[index]
        if button then
            closeTooltip(button)
            if button.setVisible then pcall(function() button:setVisible(false) end) end
        end
    end
end

local function cleanupManagedButtons(ui)
    if not ui then return end

    -- Close both our previous tooltips and the six native Inspect Weapon
    -- tooltips before the original renderer clears/rebuilds its children. This is
    -- the important stale-tooltip fix for the red/garbled floating text.
    if ui.elements then
        for index = 2, 7 do closeTooltip(ui.elements[index]) end
        -- Also clear stale dynamic joypad references from a previous GoM gun.
        -- The original renderer will repopulate its native 2..7 slots immediately
        -- afterwards; this matters when the window switches from GoM to non-GoM.
        for index = 2, 64 do ui.elements[index] = nil end
    end
    cleanupExtraButtons(ui)
    if ui.gomIwManagedSlots then
        for _, slot in ipairs(ui.gomIwManagedSlots) do closeTooltip(slot.button) end
    end
    ui.gomIwManagedSlots = nil
end

local function getManagedCategoryLabel(partType)
    local key = "UI_GOMIW_SLOT_" .. tostring(partType)
    local text = uiText(key)
    if text ~= key then return text end
    return getCategoryLabel(partType)
end

-- Managed GoM attachment buttons deliberately do not open ISToolTipInv. The
-- original tooltip path is where WeaponPart MountOn/custom wrappers were leaking
-- mojibake and stale red text into this window. The panel itself shows the part
-- name/category/state, while normal inventory tooltips remain completely intact.
local originalAttachmentRenderFix4 = attachmentButton.render
function attachmentButton:render()
    if self.gomIwManaged and isMarzWeapon(self.attachingTo) then
        ISButton.render(self)
        if self.slotItem then
            self:setImage(self.slotItem:getTexture())
            if self.currentTint ~= nil then
                self:setTextureRGBA(
                    self.currentTint:getRedFloat(),
                    self.currentTint:getGreenFloat(),
                    self.currentTint:getBlueFloat(),
                    self.currentTint:getAlphaFloat()
                )
            end
        end
        return
    end
    return originalAttachmentRenderFix4(self)
end

local function setupManagedJoypad(ui, slots, repairBtn)
    if not ui or not ui.elements then return end

    -- Native slots occupy indices 2..7. Replace those references with one compact,
    -- contiguous model-aware grid so joypad navigation cannot focus hidden slots.
    for index = 2, 64 do ui.elements[index] = nil end

    for i, slot in ipairs(slots) do
        local elementIndex = i + 1
        local button = slot.button
        ui.elements[elementIndex] = button
        slot.elementIndex = elementIndex

        local leftIndex = (i % 2 == 0) and elementIndex - 1 or nil
        local rightIndex = (i % 2 == 1 and i < #slots) and elementIndex + 1 or nil
        local upIndex = nil
        local downIndex = nil
        if i > 2 then
            upIndex = elementIndex - 2
        elseif repairBtn then
            upIndex = 1
        end
        if i + 2 <= #slots then downIndex = elementIndex + 2 end

        button.leftFocus = leftIndex
        button.rightFocus = rightIndex
        button.upFocus = upIndex
        button.downFocus = downIndex
        button.joy_x = ((i - 1) % 2) + 1
        button.joy_y = math.floor((i - 1) / 2) + 1
    end

    if #slots > 0 then
        ui.downFocus = 2
        if repairBtn then repairBtn.downFocus = 2 end
    else
        ui.downFocus = repairBtn and 1 or nil
    end

    if ui.currentFocus and ui.currentFocus > (#slots + 1) then ui.currentFocus = 0 end
end

local originalRenderInventory = riskyUI.renderInventory
function riskyUI:renderInventory()
    cleanupManagedButtons(self)
    originalRenderInventory(self)

    local weapon = self.character and self.character:getPrimaryHandItem() or nil
    self.gomIwManagedSlots = {}
    self.gomIwExtraSlots = self.gomIwManagedSlots -- compatibility with old cleanup path

    if not weapon or not weapon:IsWeapon() or not weapon:isRanged() or not isMarzWeapon(weapon) then
        return
    end

    hideNativeBaseSlots(self)

    local capabilities = getModelCapabilities(weapon)
    local installedByType, orderedParts = getInstalledParts(weapon)
    local signatureBits = {}
    for _, entry in ipairs(orderedParts) do
        table.insert(signatureBits, tostring(entry.partType) .. "=" .. tostring(safeFullType(entry.part) or "?"))
    end

    local partTypes = {}
    for partType, allowed in pairs(capabilities) do
        if allowed and isManagedVisibleType(partType) then table.insert(partTypes, partType) end
    end
    table.sort(partTypes, function(a, b)
        local ra = managedSlotRank[a] or 1000
        local rb = managedSlotRank[b] or 1000
        if ra ~= rb then return ra < rb end
        return tostring(a) < tostring(b)
    end)

    -- The original renderer uses indices 2..7 for hardcoded slots. Keep only a
    -- currently created repair button at index 1, if there really is one.
    local repairBtn = nil
    local okFixes, fixes = pcall(function() return FixingManager.getFixes(weapon) end)
    local conditionPerc = (weapon:getCondition() * 100) / weapon:getConditionMax()
    if okFixes and fixes and not fixes:isEmpty() and conditionPerc < 100 then
        repairBtn = self.elements and self.elements[1] or nil
    elseif self.elements then
        self.elements[1] = nil
    end

    local rowHeight = 54
    local yStart = 130
    local leftX = 20
    local rightX = math.max(250, math.floor((self.panelWidth or 420) / 2) + 5)

    for index, partType in ipairs(partTypes) do
        local column = ((index - 1) % 2) + 1
        local row = math.floor((index - 1) / 2) + 1
        local x = (column == 1) and leftX or rightX
        local y = yStart + (row - 1) * rowHeight
        local part = installedByType[partType]
        local button = nil

        if partType == "Clip" then
            local magazine = createMagazineProxy(weapon)
            button = magazineButton:new(x, y, 40, 40, magazine, weapon, self.character)
        else
            button = attachmentButton:new(x, y, 40, 40, part, weapon, partType, self.character)
            button.gomIwManaged = true
            -- Constructor registered ISToolTipInv already; remove it immediately.
            -- Our managed renderer never brings it back.
            closeTooltip(button)
        end

        button:bringToTop()
        self:addChild(button)

        local state = part and getPartState(weapon, partType, part) or nil
        local removable, removalReason = false, nil
        if part and partType ~= "Clip" then
            removable, removalReason = getRemovalStatus(self.character, weapon, part)
        end

        local slot = {
            button = button,
            part = part,
            partType = partType,
            x = x,
            y = y,
            state = state,
            removable = removable,
            removalReason = removalReason,
        }
        table.insert(self.gomIwManagedSlots, slot)

        local displayItem = part
        if partType == "Clip" then displayItem = button.slotItem end
        local name = displayItem and displayItem:getDisplayName() or getText("IGUI_RISKY_NONE")
        local label = getManagedCategoryLabel(partType)
        local meta = ""
        if state then meta = uiText("UI_GOMIW_STATE") .. ": " .. state end
        if removalReason then
            if meta ~= "" then meta = meta .. " | " end
            meta = meta .. removalReason
        end

        local xText = x + 50
        self.panelWidth = math.max(
            self.panelWidth or 0,
            xText + getTextManager():MeasureStringX(UIFont.Small, name) + 20,
            xText + getTextManager():MeasureStringX(UIFont.Small, label) + 20,
            xText + getTextManager():MeasureStringX(UIFont.Small, meta) + 20
        )
    end

    local rows = math.ceil(#partTypes / 2)
    local neededHeight = (#partTypes > 0) and (yStart + rows * rowHeight + 8) or 128
    self.panelHeight = math.max(neededHeight, 280)
    self:setWidth(self.panelWidth)
    self:setHeight(self.panelHeight)

    setupManagedJoypad(self, self.gomIwManagedSlots, repairBtn)

    table.sort(signatureBits)
    local capabilityBits = {}
    for _, partType in ipairs(partTypes) do table.insert(capabilityBits, partType) end
    local signature = table.concat(signatureBits, "|") .. " :: slots=" .. table.concat(capabilityBits, ",")
    if self.gomIwLastLoggedSignature ~= signature then
        self.gomIwLastLoggedSignature = signature
        local okAmmo, ammo = pcall(function() return weapon:getCurrentAmmoCount() end)
        local okMag, mag = pcall(function() return weapon:getMagazineType() end)
        print(TAG .. " Fix 4.1 inspect " .. tostring(weapon:getFullType())
            .. " ammo=" .. tostring(okAmmo and ammo or "?")
            .. " magazine=" .. tostring(okMag and mag or "?")
            .. " parts=[" .. table.concat(signatureBits, "|") .. "]"
            .. " slots=[" .. table.concat(capabilityBits, ",") .. "]")
    end
end

-- --------------------------------------------------------------------------
-- Draw only the slots that the current Guns of Marz model actually supports
-- --------------------------------------------------------------------------
local originalPrerender = riskyUI.prerender
function riskyUI:prerender()
    originalPrerender(self)

    local weapon = self.character and self.character:getPrimaryHandItem() or nil
    if not weapon or not isMarzWeapon(weapon) then return end

    -- Erase only RiskyInspectWeapon's six hardcoded attachment rows. Header,
    -- condition, ammo counters and title remain untouched.
    local clearWidth = math.max(0, (self.panelWidth or self:getWidth() or 420) - 30)
    local clearHeight = math.max(0, (self.panelHeight or 290) - 124)
    self:drawRect(15, 124, clearWidth, clearHeight, 0.98, 0, 0, 0)

    for _, slot in ipairs(self.gomIwManagedSlots or {}) do
        local x = slot.x + 50
        local displayItem = slot.part
        if slot.partType == "Clip" and slot.button then displayItem = slot.button.slotItem end
        local name = displayItem and displayItem:getDisplayName() or getText("IGUI_RISKY_NONE")
        local category = getManagedCategoryLabel(slot.partType)

        self:drawText(name, x, slot.y + 1, 1, 1, 1, 1, UIFont.Small)
        self:drawText(category, x, slot.y + 16, 1, 1, 1, 1, UIFont.Small)

        local meta = ""
        if slot.state then meta = uiText("UI_GOMIW_STATE") .. ": " .. slot.state end
        if slot.removalReason then
            if meta ~= "" then meta = meta .. " | " end
            meta = meta .. slot.removalReason
        end
        if meta ~= "" then
            self:drawText(meta, x, slot.y + 31, 0.75, 0.85, 1.0, 1.0, UIFont.Small)
        end
    end
end

-- --------------------------------------------------------------------------
-- Context-menu: remove every currently removable external attachment
-- --------------------------------------------------------------------------
local function removeAllStableRank(entry)
    local partType = entry and entry.partType or ""
    local rank = preferredRank[partType]
    if rank then return rank end
    if originalSlotTypes[partType] then
        if partType == "Canon" then return 200 end
        if partType == "Scope" then return 201 end
        if partType == "RecoilPad" then return 202 end
        if partType == "Sling" then return 203 end
        if partType == "Stock" then return 204 end
    end
    return 500
end

local function isRemoveAllCandidate(character, weapon, entry)
    if not entry or not entry.part then return false end
    local part = entry.part
    local partType = normalizePartType(entry.partType or safePartType(part))
    if not partType or partType == "" then return false end

    -- Clip is a magazine state, not a weapon attachment. Internal animation and
    -- operating parts are implementation details and must never be detached here.
    if partType == "Clip" or hiddenInternalTypes[partType] then return false end
    if isPermanentPart(part, weapon) then return false end
    if isActiveUnderbarrelPart(weapon, part) then return false end

    if isAttachableBayonetPart(part) then
        if Bayonet and Bayonet.CanRemoveBayonet then
            local okBayonet, canRemove = pcall(Bayonet.CanRemoveBayonet, weapon)
            return okBayonet and canRemove == true
        end
        return false
    end

    -- Let the part's own script-level CanDetach rule veto the bulk action too.
    -- For current GoM parts this checks the screwdriver by inventory presence;
    -- dependencies are handled separately below because children can be queued
    -- before their parent in the same bulk operation.
    if hasScrewdriver(character) and part.canDetach then
        local okDetach, canDetach = pcall(function() return part:canDetach(character, weapon) end)
        if okDetach and canDetach ~= true then return false end
    end

    return true
end

local function collectInstalledFullTypes(weapon)
    local installed = {}
    local _, ordered = getInstalledParts(weapon)
    for _, entry in ipairs(ordered) do
        local fullType = safeFullType(entry.part)
        if fullType then installed[fullType] = true end
    end
    return installed, ordered
end

local function addDependencyChildren(out, children)
    if type(children) ~= "table" then return end
    for key, value in pairs(children) do
        if type(key) == "number" then
            if type(value) == "string" then out[value] = true end
        elseif value then
            out[key] = true
        end
    end
end

local function getInstalledDependencyChildren(parentFullType, installedFullTypes)
    local result = {}
    if not parentFullType then return result end

    if RequiredAttachment and RequiredAttachment.Dependents then
        addDependencyChildren(result, RequiredAttachment.Dependents[parentFullType])
    end
    if Railing and Railing.AcceptedAccessories then
        addDependencyChildren(result, Railing.AcceptedAccessories[parentFullType])
    end

    for childType, _ in pairs(result) do
        if not installedFullTypes[childType] then result[childType] = nil end
    end
    return result
end

-- Build a leaf-first plan. A parent rail/adapter is queued only after every
-- installed child that depends on it has also been scheduled for removal.
-- If a child is permanent/active-underbarrel/not safely removable, its parent is
-- deliberately left installed rather than bypassing Gunworks protections.
local function buildRemoveAllPlan(character, weapon)
    local installedFullTypes, ordered = collectInstalledFullTypes(weapon)
    local candidates = {}
    local candidateByFullType = {}

    for _, entry in ipairs(ordered) do
        if isRemoveAllCandidate(character, weapon, entry) then
            local fullType = safeFullType(entry.part)
            if fullType then
                local candidate = {
                    part = entry.part,
                    partType = normalizePartType(entry.partType),
                    fullType = fullType,
                    rank = removeAllStableRank(entry),
                }
                table.insert(candidates, candidate)
                candidateByFullType[fullType] = candidate
            end
        end
    end

    table.sort(candidates, function(a, b)
        if a.rank ~= b.rank then return a.rank < b.rank end
        if tostring(a.partType) ~= tostring(b.partType) then return tostring(a.partType) < tostring(b.partType) end
        return tostring(a.fullType) < tostring(b.fullType)
    end)

    local blocked = {}
    local remaining = {}
    for _, candidate in ipairs(candidates) do remaining[candidate.fullType] = candidate end

    -- A dependency child that is installed but not in the candidate set makes
    -- its parent unsafe for this bulk operation.
    for _, candidate in ipairs(candidates) do
        local children = getInstalledDependencyChildren(candidate.fullType, installedFullTypes)
        for childType, _ in pairs(children) do
            if not candidateByFullType[childType] then
                blocked[candidate.fullType] = true
                break
            end
        end
    end

    local plan = {}
    while true do
        local progressed = false
        for _, candidate in ipairs(candidates) do
            if remaining[candidate.fullType] and not blocked[candidate.fullType] then
                local hasRemainingChild = false
                local children = getInstalledDependencyChildren(candidate.fullType, installedFullTypes)
                for childType, _ in pairs(children) do
                    if remaining[childType] then
                        hasRemainingChild = true
                        break
                    end
                end
                if not hasRemainingChild then
                    table.insert(plan, candidate)
                    remaining[candidate.fullType] = nil
                    progressed = true
                end
            end
        end
        if not progressed then break end
    end

    return plan
end

local function queueDetachAll(character, weapon)
    if not character or not weapon or not isMarzWeapon(weapon) then return end
    local screwdriver = getScrewdriver(character)
    if not screwdriver then return end

    local plan = buildRemoveAllPlan(character, weapon)
    if #plan == 0 then return end

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.transferIfNeeded then
        ISInventoryPaneContextMenu.transferIfNeeded(character, weapon)
    end

    -- The dedicated bayonet action requires the weapon in the primary hand in
    -- single-player. Keep the native bayonet conversion/condition path, then
    -- equip the screwdriver for every normal WeaponPart removal.
    local hasBayonet = false
    for _, candidate in ipairs(plan) do
        if isAttachableBayonetPart(candidate.part) then
            hasBayonet = true
            break
        end
    end

    if hasBayonet and ISBayonetRemove then
        if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.equipWeapon then
            local twoHands = false
            if weapon.isTwoHandWeapon then
                local okTwo, result = pcall(function() return weapon:isTwoHandWeapon() end)
                twoHands = okTwo and result == true
            end
            ISInventoryPaneContextMenu.equipWeapon(weapon, true, twoHands, character:getPlayerNum())
        end
        for _, candidate in ipairs(plan) do
            if isAttachableBayonetPart(candidate.part) then
                ISTimedActionQueue.add(ISBayonetRemove:new(character, weapon))
            end
        end
    end

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.equipWeapon then
        ISInventoryPaneContextMenu.equipWeapon(screwdriver, true, false, character:getPlayerNum())
    end

    for _, candidate in ipairs(plan) do
        if not isAttachableBayonetPart(candidate.part) and candidate.partType and ISRemoveWeaponUpgrade then
            -- Do not call the context-menu wrapper here: it evaluates parent
            -- dependencies before earlier queued child removals have completed.
            -- The native timed action + Gunworks isValid re-check them at the
            -- correct execution time, while our leaf-first plan also preserves
            -- Railing order and excludes active-underbarrel/permanent parts.
            ISTimedActionQueue.add(ISRemoveWeaponUpgrade:new(character, weapon, candidate.partType))
        end
    end
end

local function getSingleContextWeapon(items)
    if not items then return nil end
    local actual = items
    if ISInventoryPane and ISInventoryPane.getActualItems then
        local ok, resolved = pcall(ISInventoryPane.getActualItems, items)
        if ok and type(resolved) == "table" then actual = resolved end
    end

    local found = nil
    for _, item in ipairs(actual) do
        if item and instanceof(item, "HandWeapon") and isMarzWeapon(item) then
            if found and found ~= item then return nil end
            found = item
        end
    end
    return found
end

local function markContextOptionNeedsScrewdriver(context, option)
    if not option then return end
    option.notAvailable = true

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.addToolTip then
        local tooltip = option.toolTip or ISInventoryPaneContextMenu.addToolTip()
        tooltip.description = uiText("UI_GOMIW_NEED_SCREWDRIVER")
        option.toolTip = tooltip
    end

    -- Gunworks creates a submenu when more than one compatible bayonet knife is
    -- available. Disable its children as well, so single-menu and classic menu
    -- modes behave identically.
    if option.subOption and context and context.getSubMenu then
        local okSub, subMenu = pcall(function() return context:getSubMenu(option.subOption) end)
        if okSub and subMenu and subMenu.options then
            for _, subOption in ipairs(subMenu.options) do
                subOption.notAvailable = true
                if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.addToolTip then
                    local subTip = subOption.toolTip or ISInventoryPaneContextMenu.addToolTip()
                    subTip.description = uiText("UI_GOMIW_NEED_SCREWDRIVER")
                    subOption.toolTip = subTip
                end
            end
        end
    end
end

local function guardBayonetContextOptions(playerNum, context, items)
    if not context or not items then return end
    local weapon = getSingleContextWeapon(items)
    if not weapon then return end

    local character = getSpecificPlayer(playerNum)
    if not character or hasScrewdriver(character) then return end

    -- These are the exact keys used by Gunworks' own context-menu entries. The
    -- timed-action guard above is the authoritative safety check; this layer is
    -- only the user-facing disabled state and explanation.
    if context.getOptionFromName then
        markContextOptionNeedsScrewdriver(context, context:getOptionFromName(getText("IGUI_AttachBayonet")))
        markContextOptionNeedsScrewdriver(context, context:getOptionFromName(getText("IGUI_RemoveBayonet")))
    end
end

local function addDetachAllContextOption(playerNum, context, items)
    if not context or not items then return end
    local weapon = getSingleContextWeapon(items)
    if not weapon then return end

    local character = getSpecificPlayer(playerNum)
    if not character then return end

    local plan = buildRemoveAllPlan(character, weapon)
    if #plan == 0 then return end

    local optionName = uiText("UI_GOMIW_DETACH_ALL")
    local removeName = getText("ContextMenu_Remove_Weapon_Upgrade")
    local option = nil
    if context.getOptionFromName and context:getOptionFromName(removeName) and context.insertOptionAfter then
        option = context:insertOptionAfter(removeName, optionName, character, queueDetachAll, weapon)
    else
        option = context:addOption(optionName, character, queueDetachAll, weapon)
    end

    if option and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.addToolTip then
        option.toolTip = ISInventoryPaneContextMenu.addToolTip()
        option.toolTip.description = uiText("UI_GOMIW_DETACH_ALL_DESC")
    end
    if option and not hasScrewdriver(character) then
        option.notAvailable = true
    end
end

if Events and Events.OnFillInventoryObjectContextMenu then
    -- Gunworks is loaded before this compatibility mod, so its bayonet entries
    -- already exist when this handler runs.
    Events.OnFillInventoryObjectContextMenu.Add(guardBayonetContextOptions)
    Events.OnFillInventoryObjectContextMenu.Add(addDetachAllContextOption)
end

-- --------------------------------------------------------------------------
-- Tidy Up Meister compatibility: Inspect Weapon is observational, not an
-- operation that should trigger automatic return-to-origin cleanup.
-- --------------------------------------------------------------------------
local tidyPolicyRegistered = false
local function registerTidyInspectPolicy()
    if tidyPolicyRegistered then return true end
    local api = _G and _G.P4TidyUpMeister or nil
    if not api or type(api.registerActionPolicy) ~= "function" then return false end

    local ok, result = pcall(api.registerActionPolicy, "riskyInspectAction", { ignore = true })
    if ok and result ~= false then
        tidyPolicyRegistered = true
        print(TAG .. " Fix 4.1: Tidy Up Meister ignores riskyInspectAction")
        return true
    end
    return false
end

-- Register immediately when load order already provides the API; OnGameStart
-- retries after all client Lua has loaded, covering the opposite load order too.
registerTidyInspectPolicy()

local function onGameStart()
    installBayonetToolGuard()
    registerTidyInspectPolicy()
    print(TAG .. " Fix 4.1 v0.6.0 loaded - model-aware slots + remove-all + Tidy inspect exclusion + screwdriver-safe Gunworks attachment actions")
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(onGameStart)
end
