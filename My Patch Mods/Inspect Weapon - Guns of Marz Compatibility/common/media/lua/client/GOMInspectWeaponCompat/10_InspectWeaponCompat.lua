-- Inspect Weapon - Guns of Marz Compatibility
-- Fix 3 / v0.4.0 / Project Zomboid Build 42.20.2
--
-- Goals:
--   * keep RiskyInspectWeapon's native renderer and layout;
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
    print(TAG .. " Fix 3: Inspect Weapon UI classes unavailable; compatibility hooks not installed")
    return
end

pcall(require, "TimedActions/ISUpgradeWeapon")
pcall(require, "TimedActions/ISRemoveWeaponUpgrade")
pcall(require, "TimedActions/ISEquipWeaponAction")
pcall(require, "ISUI/ISContextMenu")
pcall(require, "ISUI/ISInventoryPaneContextMenu")
pcall(require, "WeaponSystems/TimedActions/ISBayonetAttach")

local okPrevent, PreventRemoval = pcall(require, "WeaponSystems/Utils/PreventRemovals")
local okStock, FoldingStock = pcall(require, "WeaponSystems/Utils/FoldingStock")
local okBipod, FoldingBipod = pcall(require, "WeaponSystems/Utils/FoldingBipod")
local okBayonet, Bayonet = pcall(require, "WeaponSystems/Utils/Bayonet")
local okRequired, RequiredAttachment = pcall(require, "WeaponSystems/Utils/RequiredAttachment")
local okUniversal, UniversalAttachment = pcall(require, "WeaponSystems/Utils/UniversalAttachment")
local okExclusive, UpgradeExclusives = pcall(require, "WeaponSystems/Utils/UpgradeExclusives")

if not okPrevent then PreventRemoval = nil end
if not okStock then FoldingStock = nil end
if not okBipod then FoldingBipod = nil end
if not okBayonet then Bayonet = nil end
if not okRequired then RequiredAttachment = nil end
if not okUniversal then UniversalAttachment = nil end
if not okExclusive then UpgradeExclusives = nil end

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

local function hasScrewdriver(character)
    if not character or not character.getInventory then return false end
    local inventory = character:getInventory()
    if not inventory then return false end
    local ok, result = pcall(function()
        return inventory:getFirstTagEvalRecurse(ItemTag.SCREWDRIVER, predicateNotBroken)
    end)
    return ok and result ~= nil
end

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

local function getRemovalStatus(character, weapon, part)
    if not part then return false, nil end
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

    if isRemovalBlockedByDependency(weapon, part) then
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

    -- Every detachable Guns of Marz WeaponPart in the supplied source uses
    -- ItemCodeOnTest.hasScrewdriver for CanDetach. Keep Inspect Weapon consistent
    -- with that rule instead of allowing one-way removal without the tool.
    if isMarzPart(part) and not hasScrewdriver(character) then
        return false, uiText("UI_GOMIW_NEED_SCREWDRIVER")
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
                local enabled = false
                if Bayonet.CanAttachBayonet then
                    local okEnabled, result = pcall(Bayonet.CanAttachBayonet, weapon, item)
                    enabled = okEnabled and result == true
                end
                addCandidate(candidates, seen, {
                    key = "bayonet:" .. tostring(fullType),
                    kind = "bayonet",
                    displayItem = item,
                    sourceItem = item,
                    sourceContainer = entry.container,
                    partType = requestedType,
                    enabled = enabled,
                    reason = enabled and nil or uiText("UI_GOMIW_REQUIREMENTS"),
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
    if not moveCandidateToMainInventory(character, candidate) then return end

    if candidate.kind == "bayonet" then
        if ISBayonetAttach then
            ISTimedActionQueue.add(ISBayonetAttach:new(character, weapon, candidate.sourceItem))
        elseif Bayonet and Bayonet.AttachBayonet then
            -- No unsafe direct fallback: without the framework timed action we
            -- deliberately do nothing rather than bypass synchronization.
            print(TAG .. " Fix 3: ISBayonetAttach unavailable; bayonet install skipped")
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
        ISTimedActionQueue.add(ISRemoveWeaponUpgrade:new(character, weapon, partType, 50))
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
-- Append installed/candidate GoM-only part types without any script-wide scan
-- --------------------------------------------------------------------------
local originalRenderInventory = riskyUI.renderInventory
function riskyUI:renderInventory()
    cleanupExtraButtons(self)
    originalRenderInventory(self)

    local weapon = self.character and self.character:getPrimaryHandItem() or nil
    self.gomIwExtraSlots = {}
    if not weapon or not weapon:IsWeapon() or not weapon:isRanged() or not isMarzWeapon(weapon) then
        return
    end

    local _, orderedParts = getInstalledParts(weapon)
    local extraByType = {}
    local signatureBits = {}

    for _, entry in ipairs(orderedParts) do
        local partType = entry.partType
        local part = entry.part
        local fullType = safeFullType(part) or "?"
        table.insert(signatureBits, tostring(partType) .. "=" .. tostring(fullType))
        if isVisibleExtra(partType, part) then
            extraByType[partType] = { partType = partType, part = part }
        end
    end

    -- Keep an empty custom row after removal whenever the player still owns a
    -- compatible replacement candidate (direct part, universal rail, bayonet).
    local candidateTypes = getCandidateExtraTypes(self.character, weapon)
    for partType, _ in pairs(candidateTypes) do
        if isVisibleExtraType(partType) and not extraByType[partType] then
            extraByType[partType] = { partType = partType, part = nil }
        end
    end

    local extras = {}
    for _, entry in pairs(extraByType) do
        table.insert(extras, entry)
    end

    table.sort(extras, function(a, b)
        local ra = preferredRank[a.partType] or 1000
        local rb = preferredRank[b.partType] or 1000
        if ra ~= rb then return ra < rb end
        return tostring(a.partType) < tostring(b.partType)
    end)

    -- Expand width for recovered original slots because the native width
    -- measurement saw nil before our constructor fallback substituted the part.
    local baseIndexes = {2, 4, 5, 6, 7}
    for _, index in ipairs(baseIndexes) do
        local button = self.elements and self.elements[index] or nil
        if button and button.gomIwRecoveredInstalledPart and button.slotItem then
            local name = button.slotItem:getDisplayName()
            local right = button:getX() + 50 + getTextManager():MeasureStringX(UIFont.Small, name) + 20
            self.panelWidth = math.max(self.panelWidth or 0, right)
        end
    end

    if #extras > 0 then
        local rowHeight = 54
        local yStart = 300
        local leftX = 20
        local rightX = math.max(260, math.floor((self.panelWidth or 420) / 2) + 10)
        local rows = math.ceil(#extras / 2)

        for index, entry in ipairs(extras) do
            local column = ((index - 1) % 2) + 1
            local row = math.floor((index - 1) / 2) + 1
            local x = (column == 1) and leftX or rightX
            local y = yStart + (row - 1) * rowHeight

            local button = attachmentButton:new(x, y, 40, 40, entry.part, weapon, entry.partType, self.character)
            button.gomIwExtra = true
            button:bringToTop()
            self:addChild(button)

            local state = entry.part and getPartState(weapon, entry.partType, entry.part) or nil
            local removable, removalReason = false, nil
            if entry.part then
                removable, removalReason = getRemovalStatus(self.character, weapon, entry.part)
            end

            table.insert(self.gomIwExtraSlots, {
                button = button,
                part = entry.part,
                partType = entry.partType,
                x = x,
                y = y,
                state = state,
                removable = removable,
                removalReason = removalReason,
            })

            local name = entry.part and entry.part:getDisplayName() or getText("IGUI_RISKY_NONE")
            local label = getCategoryLabel(entry.partType)
            local meta = ""
            if state then meta = uiText("UI_GOMIW_STATE") .. ": " .. state end
            if removalReason then
                if meta ~= "" then meta = meta .. " | " end
                meta = meta .. removalReason
            end

            local xText = x + 50
            self.panelWidth = math.max(self.panelWidth or 0,
                xText + getTextManager():MeasureStringX(UIFont.Small, name) + 20,
                xText + getTextManager():MeasureStringX(UIFont.Small, label) + 20,
                xText + getTextManager():MeasureStringX(UIFont.Small, meta) + 20)
        end

        self.panelHeight = math.max(self.panelHeight or 0, yStart + rows * rowHeight + 10)
    end

    self:setWidth(self.panelWidth)
    self:setHeight(self.panelHeight)

    table.sort(signatureBits)
    local signature = table.concat(signatureBits, "|")
    if self.gomIwLastLoggedSignature ~= signature then
        self.gomIwLastLoggedSignature = signature
        local okAmmo, ammo = pcall(function() return weapon:getCurrentAmmoCount() end)
        local okMag, mag = pcall(function() return weapon:getMagazineType() end)
        print(TAG .. " Fix 3 inspect " .. tostring(weapon:getFullType())
            .. " ammo=" .. tostring(okAmmo and ammo or "?")
            .. " magazine=" .. tostring(okMag and mag or "?")
            .. " parts=[" .. signature .. "]")
    end
end

-- --------------------------------------------------------------------------
-- Correct recovered base-slot text and draw appended custom rows
-- --------------------------------------------------------------------------
local originalPrerender = riskyUI.prerender
function riskyUI:prerender()
    originalPrerender(self)

    local weapon = self.character and self.character:getPrimaryHandItem() or nil
    if not weapon or not isMarzWeapon(weapon) then return end

    local baseIndexes = {2, 4, 5, 6, 7}
    for _, index in ipairs(baseIndexes) do
        local button = self.elements and self.elements[index] or nil
        if button and button.gomIwRecoveredInstalledPart and button.slotItem then
            local x = button:getX() + 50
            local y = button:getY() + 7
            local actualName = button.slotItem:getDisplayName()
            local staleWidth = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_RISKY_NONE"))
            local actualWidth = getTextManager():MeasureStringX(UIFont.Small, actualName)
            local clearWidth = math.max(staleWidth, actualWidth) + 4
            self:drawRect(x - 2, y - 1, clearWidth + 2, 14, 0.96, 0, 0, 0)
            self:drawText(actualName, x, y, 1, 1, 1, 1, UIFont.Small)
        end
    end

    for _, slot in ipairs(self.gomIwExtraSlots or {}) do
        local x = slot.x + 50
        local name = slot.part and slot.part:getDisplayName() or getText("IGUI_RISKY_NONE")
        local category = getCategoryLabel(slot.partType)

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

local function onGameStart()
    print(TAG .. " Fix 3 v0.4.0 loaded - reversible GoM attachment actions + dependency/tool guards + live magazine tooltip")
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(onGameStart)
end
