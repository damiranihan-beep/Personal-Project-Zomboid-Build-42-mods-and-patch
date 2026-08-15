-- Inspect Weapon - Guns of Marz Compatibility
-- Fix 4.3 / v0.8.0 / Project Zomboid Build 42.20.2
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
    print(TAG .. " Fix 4.3: Inspect Weapon UI classes unavailable; compatibility hooks not installed")
    return
end

pcall(require, "TimedActions/ISUpgradeWeapon")
pcall(require, "TimedActions/ISRemoveWeaponUpgrade")
pcall(require, "TimedActions/ISEquipWeaponAction")
pcall(require, "ISUI/ISContextMenu")
pcall(require, "ISUI/ISInventoryPane")
pcall(require, "ISUI/ISInventoryPaneContextMenu")
pcall(require, "ISUI/ISPanel")
pcall(require, "ISUI/ISButton")
pcall(require, "TimedActions/ISEjectMagazine")
pcall(require, "TimedActions/ISUnloadBulletsFromFirearm")
pcall(require, "TimedActions/ISRackFirearm")
pcall(require, "TimedActions/ISReloadWeaponAction")
pcall(require, "TimedActions/ISBaseTimedAction")
pcall(require, "TimedActions/ISInventoryTransferUtil")
pcall(require, "WeaponSystems/TimedActions/ISBayonetAttach")
pcall(require, "WeaponSystems/TimedActions/ISBayonetRemove")

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
    UI_GOMIW_EMPTY = "Нет насадки",
    UI_GOMIW_EMPTY_HINT = "Требуется совместимая насадка",
    UI_GOMIW_BULK = "Оружие — групповые действия",
    UI_GOMIW_DETACH_ALL_WEAPONS = "Снять насадки со всего оружия",
    UI_GOMIW_DETACH_ALL_WEAPONS_DESC = "Снимает все доступные съёмные насадки со всех выбранных единиц оружия. Для обычных насадок отвёртка может быть взята из открытого соседнего контейнера.",
    UI_GOMIW_UNLOAD_ONE = "Разрядить",
    UI_GOMIW_UNLOAD_ALL_WEAPONS = "Разрядить всё оружие",
    UI_GOMIW_UNLOAD_ALL_WEAPONS_DESC = "Разряжает все выбранные единицы оружия: извлекает магазины, выгружает патроны и выбрасывает патрон из патронника штатным действием, не уничтожая его.",
}

local function uiText(key)
    -- Fix 4.3: these private UI strings are display-only.  In the user's RU setup
    -- another translation wrapper can return mojibake instead of the literal key,
    -- so merely comparing getText(key) ~= key is not enough.  Prefer our known-good
    -- UTF-8 Russian fallback for every GOMIW label and never expose raw/internal
    -- slot initials in the Inspect Weapon window.
    if fallbackRU[key] then return fallbackRU[key] end
    local ok, text = pcall(getText, key)
    if ok and text and text ~= key then return text end
    return key
end

local weaponTitleSuffixes = {
    ["(пист.)"] = "(пистолет)",
    ["(рев.)"] = "(револьвер)",
    ["(авт. ДР)"] = "(автоматический дробовик)",
    ["(П/А ДР)"] = "(полуавтоматический дробовик)",
    ["(2-ств. ДР)"] = "(двуствольный дробовик)",
    ["(подств. ДР)"] = "(подствольный дробовик)",
    ["(ДР)"] = "(дробовик)",
    ["(ШВ + M203)"] = "(штурмовая винтовка + M203)",
    ["(ШВ)"] = "(штурмовая винтовка)",
    ["(ГВ)"] = "(гражданская винтовка)",
    ["(БВ)"] = "(боевая винтовка)",
    ["(авт. винт.)"] = "(автоматическая винтовка)",
    ["(П/А винт.)"] = "(полуавтоматическая винтовка)",
    ["(винт.)"] = "(винтовка)",
    ["(болт.)"] = "(болтовая винтовка)",
    ["(СВ)"] = "(снайперская винтовка)",
    ["(пулем.)"] = "(пулемёт)",
    ["(гранатом.)"] = "(гранатомёт)",
    ["(ПП)"] = "(пистолет-пулемёт)",
    ["(АП)"] = "(автоматический пистолет)",
    ["(караб.)"] = "(карабин)",
}

local function getInspectWeaponDisplayName(weapon)
    if not weapon or not weapon.getDisplayName then return "" end
    local ok, displayName = pcall(function() return weapon:getDisplayName() end)
    if not ok or not displayName then return "" end
    local name = tostring(displayName)
    for shortSuffix, fullSuffix in pairs(weaponTitleSuffixes) do
        if string.sub(name, -#shortSuffix) == shortSuffix then
            return string.sub(name, 1, #name - #shortSuffix) .. fullSuffix
        end
    end
    return name
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

local function addContainerUnique(out, seen, container)
    if not container then return end
    local key = tostring(container)
    if seen[key] then return end
    seen[key] = true
    table.insert(out, container)
end

local function getAccessibleContainers(character)
    local out, seen = {}, {}
    if not character then return out end

    if character.getInventory then
        addContainerUnique(out, seen, character:getInventory())
    end

    -- B42's own crafting/context-menu helper contains character inventories plus
    -- currently accessible surrounding loot containers (crates, cupboards, etc.).
    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.getContainers then
        local ok, list = pcall(ISInventoryPaneContextMenu.getContainers, character)
        if ok and list then
            local okSize, size = pcall(function() return list:size() end)
            if okSize and size then
                for i = 0, size - 1 do
                    local okGet, container = pcall(function() return list:get(i) end)
                    if okGet then addContainerUnique(out, seen, container) end
                end
            elseif type(list) == "table" then
                for _, container in ipairs(list) do addContainerUnique(out, seen, container) end
            end
        end
    end

    return out
end

local function getScrewdriver(character)
    for _, container in ipairs(getAccessibleContainers(character)) do
        local ok, result = pcall(function()
            return container:getFirstTagEvalRecurse(ItemTag.SCREWDRIVER, predicateNotBroken)
        end)
        if ok and result then return result end
    end
    return nil
end

local function hasScrewdriver(character)
    return getScrewdriver(character) ~= nil
end

local function queueTransferIfNeeded(character, item)
    if not character or not item then return false end
    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.transferIfNeeded then
        local ok = pcall(ISInventoryPaneContextMenu.transferIfNeeded, character, item)
        return ok
    end
    return item:getContainer() == character:getInventory()
end

-- Bulk attachment removal may temporarily take a weapon from a backpack or an
-- open nearby crate. The user explicitly wants detached parts to follow that
-- weapon back instead of being stranded in the main inventory. Queue a normal
-- inventory transfer *after* the detach action; allowMissingItems is important
-- because the WeaponPart is still attached when this transfer is constructed.
local function queueReturnItemToContainer(character, item, destination)
    if not character or not item or not destination then return false end
    local main = character:getInventory()
    if not main or destination == main then return true end
    if not ISInventoryTransferUtil or not ISInventoryTransferUtil.newInventoryTransferAction then return false end

    local ok, action = pcall(ISInventoryTransferUtil.newInventoryTransferAction, character, item, main, destination, nil)
    if not ok or not action then return false end
    if action.setAllowMissingItems then pcall(function() action:setAllowMissingItems(true) end) end
    ISTimedActionQueue.add(action)
    return true
end

local function snapshotMainInventoryIds(character, fullType)
    local ids = {}
    if not character or not fullType then return ids end
    local inventory = character:getInventory()
    if not inventory or not inventory.getItems then return ids end
    local items = inventory:getItems()
    if not items then return ids end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and safeFullType(item) == fullType then
            local id = item.getID and item:getID() or tostring(item)
            ids[id] = true
        end
    end
    return ids
end

-- ISBayonetRemove converts the installed WeaponPart back into a NEW knife item,
-- so unlike a normal WeaponPart we cannot queue a transfer for the old object.
-- This zero-time follow-up finds only the newly-created knife and returns it to
-- the weapon's original container. Gunworks still performs the actual removal.
local GOMReturnCreatedBayonet = ISBaseTimedAction and ISBaseTimedAction:derive("GOMReturnCreatedBayonet") or nil
if GOMReturnCreatedBayonet then
    function GOMReturnCreatedBayonet:isValid() return true end
    function GOMReturnCreatedBayonet:update() end
    function GOMReturnCreatedBayonet:start() end
    function GOMReturnCreatedBayonet:stop() ISBaseTimedAction.stop(self) end
    function GOMReturnCreatedBayonet:perform()
        local inventory = self.character and self.character:getInventory() or nil
        local found = nil
        if inventory and self.knifeType then
            local items = inventory:getItems()
            if items then
                for i = 0, items:size() - 1 do
                    local item = items:get(i)
                    if item and safeFullType(item) == self.knifeType then
                        local id = item.getID and item:getID() or tostring(item)
                        if not self.knownIds[id] then
                            found = item
                            break
                        end
                    end
                end
            end
        end
        if found then queueReturnItemToContainer(self.character, found, self.destination) end
        ISBaseTimedAction.perform(self)
    end
    function GOMReturnCreatedBayonet:new(character, knifeType, knownIds, destination)
        local o = ISBaseTimedAction.new(self, character)
        o.knifeType = knifeType
        o.knownIds = knownIds or {}
        o.destination = destination
        o.maxTime = 0
        o.stopOnWalk = false
        o.stopOnRun = false
        return o
    end
end

-- Fix 4.3: a detachable bayonet is intentionally quick-release.  Upstream
-- Gunworks does not require a screwdriver for ISBayonetAttach/ISBayonetRemove,
-- so do not add one here.  Fold/deploy behavior of integrated stocks/bayonets
-- is left entirely to Gunworks.
local function installBayonetToolGuard()
    return true
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

    -- Normal GoM WeaponParts use a screwdriver.  Detachable bayonets are the
    -- explicit exception: their dedicated Gunworks action is a quick-release path.
    if isMarzPart(part) and not isAttachableBayonetPart(part) and not hasScrewdriver(character) then
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
    local out, visited = {}, {}
    for _, container in ipairs(getAccessibleContainers(character)) do
        collectInventoryEntries(container, out, visited)
    end
    return out
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

    -- MountOn is authoritative for direct WeaponParts.  This closes the vanilla
    -- B42 loophole where CanAttach only checked for a screwdriver and allowed a
    -- Beretta rail to be offered for an AR-15.
    if isMarzPart(part) and not safeMountsOnWeapon(part, weapon) then return false end

    if isMarzPart(part) then
        -- Every direct GoM WeaponPart currently uses ItemCodeOnTest.hasScrewdriver.
        -- Our accessible-tool lookup deliberately includes nearby open containers;
        -- the tool is transferred before the timed action is queued.
        if not hasScrewdriver(character) then return false end
    elseif part.canAttach then
        local ok, result = pcall(function() return part:canAttach(character, weapon) end)
        if not ok or result ~= true then return false end
    end

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
                                local enabled = screwdriver
                                if enabled and weapon.getWeaponPart then
                                    local outcomePartType = safePartType(outcomePart)
                                    local okOccupied, occupied = pcall(function() return weapon:getWeaponPart(outcomePartType) end)
                                    if okOccupied and occupied ~= nil then enabled = false end
                                end
                                if enabled and UniversalAttachment.IsRegisteredOutcome then
                                    local okReg, registered = pcall(UniversalAttachment.IsRegisteredOutcome, weapon, outcomeType)
                                    enabled = okReg and registered == true
                                end
                                if enabled and RequiredAttachment and RequiredAttachment.IsInstallationBlocked then
                                    local okBlocked, blocked = pcall(RequiredAttachment.IsInstallationBlocked, weapon, outcomeType)
                                    if okBlocked and blocked then enabled = false end
                                end
                                if enabled and UpgradeExclusives and UpgradeExclusives.IsBlockedByExclusive then
                                    local okBlocked, blocked = pcall(UpgradeExclusives.IsBlockedByExclusive, weapon, outcomeType)
                                    if okBlocked and blocked then enabled = false end
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
                local enabled = frameworkAllowed
                local reason = frameworkAllowed and nil or uiText("UI_GOMIW_REQUIREMENTS")
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
    return queueTransferIfNeeded(character, candidate.sourceItem)
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

    -- Bring the selected weapon/part in through the same B42 transfer queue used
    -- by normal inventory actions.  No direct Remove/Add mutation of loot crates.
    queueTransferIfNeeded(character, weapon)
    if not moveCandidateToMainInventory(character, candidate) then return end

    if candidate.kind == "bayonet" then
        if ISBayonetAttach then
            ISTimedActionQueue.add(ISBayonetAttach:new(character, weapon, candidate.sourceItem))
        elseif Bayonet and Bayonet.AttachBayonet then
            -- No unsafe direct fallback: without the framework timed action we
            -- deliberately do nothing rather than bypass synchronization.
            print(TAG .. " Fix 4.3: ISBayonetAttach unavailable; bayonet install skipped")
        end
        return
    end

    local screwdriver = getScrewdriver(character)
    if not screwdriver then return end
    queueTransferIfNeeded(character, screwdriver)
    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.equipWeapon then
        -- Match vanilla upgrade ergonomics: attachment/off-hand, screwdriver/main.
        ISInventoryPaneContextMenu.equipWeapon(candidate.sourceItem, false, false, character:getPlayerNum())
        ISInventoryPaneContextMenu.equipWeapon(screwdriver, true, false, character:getPlayerNum())
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

local GOMCandidatePane = ISPanel:derive("GOMCandidatePane")
local activeCandidatePanes = {}

function GOMCandidatePane:new(x, y, candidates, character, weapon)
    local cols = 5
    local rows = math.max(1, math.ceil(#candidates / cols))
    local o = ISPanel:new(x, y, cols * 42 + 8, rows * 42 + 8)
    setmetatable(o, self)
    self.__index = self
    o.candidates = candidates or {}
    o.character = character
    o.weapon = weapon
    o.backgroundColor = { r=0, g=0, b=0, a=0.96 }
    o.borderColor = { r=0.8, g=0.8, b=0.8, a=0.8 }
    o.origin = riskyInspectWindow and riskyInspectWindow[character:getPlayerNum()] or nil
    o.buttons = {}
    return o
end

function GOMCandidatePane:createChildren()
    ISPanel.createChildren(self)
    for index, candidate in ipairs(self.candidates) do
        local col = (index - 1) % 5
        local row = math.floor((index - 1) / 5)
        local button = ISButton:new(4 + col * 42, 4 + row * 42, 40, 40, "", self, GOMCandidatePane.onCandidate)
        button:initialise()
        button.candidate = candidate
        button.enable = candidate.enabled == true
        if candidate.displayItem and candidate.displayItem.getTexture then
            local okTex, tex = pcall(function() return candidate.displayItem:getTexture() end)
            if okTex and tex then button:setImage(tex) end
        end
        local displayName = candidate.displayItem and candidate.displayItem:getDisplayName() or candidate.key
        local tip = tostring(displayName or "")
        if not candidate.enabled and candidate.reason then
            tip = tip .. "\n" .. tostring(candidate.reason)
        end
        if button.setTooltip then button:setTooltip(tip) end
        if not candidate.enabled then
            button.backgroundColorMouseOver = {r=0.35, g=0.35, b=0.35, a=0.35}
        end
        self:addChild(button)
        table.insert(self.buttons, button)
    end
end

function GOMCandidatePane:onCandidate(button)
    local candidate = button and button.candidate or nil
    if not candidate or not candidate.enabled then return end
    performCandidateInstall(self.character, self.weapon, candidate)
    self:close()
end

function GOMCandidatePane:close()
    if self.character then activeCandidatePanes[self.character:getPlayerNum()] = nil end
    self:setVisible(false)
    self:removeFromUIManager()
end

function GOMCandidatePane:onMouseDownOutside(x, y)
    self:close()
    return true
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

    if activeCandidatePanes[playerNum] then
        pcall(function() activeCandidatePanes[playerNum]:close() end)
    end

    if #candidates == 0 then
        -- Keep the slot itself as the explanation.  Do not open an empty text
        -- context menu; the UI now uses the author's original icon-grid concept.
        return
    end

    local x = window:getX() + button:getX() + button:getWidth() + 4
    local y = window:getY() + button:getY()
    local pane = GOMCandidatePane:new(x, y, candidates, character, weapon)
    pane:initialise()
    pane:addToUIManager()
    pane:setVisible(true)
    pane:bringToTop()
    activeCandidatePanes[playerNum] = pane
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
        -- The Inspect window may be operating on a weapon/tool that originated in
        -- an open nearby container. Queue the same safe transfer path used by the
        -- vanilla inventory menu before the removal action starts.
        queueTransferIfNeeded(character, weapon)
        local screwdriver = getScrewdriver(character)
        if not screwdriver then return end
        queueTransferIfNeeded(character, screwdriver)
        if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.equipWeapon then
            ISInventoryPaneContextMenu.equipWeapon(screwdriver, true, false, character:getPlayerNum())
        end
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

            queueTransferIfNeeded(self.character, self.attachingTo)
            queueTransferIfNeeded(self.character, self.slotItem)
            local screwdriver = getScrewdriver(self.character)
            if not screwdriver then return end
            queueTransferIfNeeded(self.character, screwdriver)

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

            queueTransferIfNeeded(self.character, self.attachingTo)
            queueTransferIfNeeded(self.character, self.slotItem)
            local screwdriver = getScrewdriver(self.character)
            if not screwdriver then return end
            queueTransferIfNeeded(self.character, screwdriver)

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

local safeRepairPartTypes = {
    RailUp = true, RailDown = true, RailLeft = true, RailRight = true,
    CanonMount = true,
}

local function repairInvalidMountState(character, weapon)
    if not character or not weapon or not isMarzWeapon(weapon) then return end
    local _, ordered = getInstalledParts(weapon)
    for _, entry in ipairs(ordered) do
        local part = entry.part
        local partType = normalizePartType(entry.partType)
        if part and safeRepairPartTypes[partType] and isMarzPart(part)
            and not safeMountsOnWeapon(part, weapon) then

            local isUniversal = false
            if UniversalAttachment and UniversalAttachment.IsRegisteredOutcome then
                local okU, result = pcall(UniversalAttachment.IsRegisteredOutcome, weapon, part)
                isUniversal = okU and result == true
            end

            local hasChildren = false
            local fullType = safeFullType(part)
            if not isUniversal and fullType and RequiredAttachment and RequiredAttachment.GetInstalledChildren then
                local okC, children = pcall(RequiredAttachment.GetInstalledChildren, weapon, fullType)
                hasChildren = okC and children ~= nil
            end

            -- Repair only the simple corrupted rail/adapter state created by the
            -- old compatibility bug.  Do not tear down dependency trees silently.
            if not isUniversal and not hasChildren and not isPermanentPart(part, weapon) then
                local okDetach = pcall(function() weapon:detachWeaponPart(character, part) end)
                if okDetach then
                    character:getInventory():AddItem(part)
                    if sendAddItemToContainer then
                        pcall(sendAddItemToContainer, character:getInventory(), part)
                    end
                    if syncHandWeaponFields then
                        pcall(syncHandWeaponFields, character, weapon)
                    end
                    print(TAG .. " Fix 4.3 repaired invalid saved mount " .. tostring(fullType)
                        .. " from " .. tostring(safeFullType(weapon)))
                end
            end
        end
    end
end

local originalRenderInventory = riskyUI.renderInventory
function riskyUI:renderInventory()
    cleanupManagedButtons(self)
    originalRenderInventory(self)

    local weapon = self.character and self.character:getPrimaryHandItem() or nil
    if weapon and isMarzWeapon(weapon) then
        repairInvalidMountState(self.character, weapon)
    end
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
        local name = displayItem and displayItem:getDisplayName() or uiText("UI_GOMIW_EMPTY")
        local label = getManagedCategoryLabel(partType)
        local meta = ""
        if not displayItem then meta = uiText("UI_GOMIW_EMPTY_HINT") end
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

    -- Inspect Weapon title: expand the Russian shorthand used by the collection
    -- translation (e.g. "пист.", "ГВ", "ШВ") into full readable weapon classes.
    local inspectTitle = getInspectWeaponDisplayName(weapon)
    if inspectTitle ~= "" then
        self.panelWidth = math.max(self.panelWidth or 0,
            getTextManager():MeasureStringX(UIFont.Medium, inspectTitle) + 100)
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
        print(TAG .. " Fix 4.3 inspect " .. tostring(weapon:getFullType())
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

    -- The base mod draws weapon:getDisplayName() with abbreviations. Cover only
    -- that title line and redraw the expanded title; condition/repair lines stay
    -- untouched below it.
    local inspectTitle = getInspectWeaponDisplayName(weapon)
    if inspectTitle ~= "" and inspectTitle ~= tostring(weapon:getDisplayName()) then
        local titleClearWidth = math.max(0, (self.panelWidth or self:getWidth() or 420) - 65)
        self:drawRect(62, 32, titleClearWidth, 22, 0.98, 0, 0, 0)
        self:drawText(inspectTitle, 65, 35, 1, 1, 1, 1, UIFont.Medium)
    end

    -- Erase only RiskyInspectWeapon's six hardcoded attachment rows. Header,
    -- condition, ammo counters and title remain untouched.
    local clearWidth = math.max(0, (self.panelWidth or self:getWidth() or 420) - 30)
    local clearHeight = math.max(0, (self.panelHeight or 290) - 124)
    self:drawRect(15, 124, clearWidth, clearHeight, 0.98, 0, 0, 0)

    for _, slot in ipairs(self.gomIwManagedSlots or {}) do
        local x = slot.x + 50
        local displayItem = slot.part
        if slot.partType == "Clip" and slot.button then displayItem = slot.button.slotItem end
        local name = displayItem and displayItem:getDisplayName() or uiText("UI_GOMIW_EMPTY")
        local category = getManagedCategoryLabel(slot.partType)

        self:drawText(name, x, slot.y + 1, 1, 1, 1, 1, UIFont.Small)
        self:drawText(category, x, slot.y + 16, 1, 1, 1, 1, UIFont.Small)

        local meta = ""
        if not displayItem then meta = uiText("UI_GOMIW_EMPTY_HINT") end
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
    if not isAttachableBayonetPart(part) and not hasScrewdriver(character) then
        return false
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

    local plan = buildRemoveAllPlan(character, weapon)
    if #plan == 0 then return end

    -- Capture before transferIfNeeded: this is the logical destination for both
    -- the weapon and every detached accessory when the action came from another
    -- backpack/loot cell.
    local originContainer = weapon.getContainer and weapon:getContainer() or nil
    queueTransferIfNeeded(character, weapon)

    -- Bayonet is quick-release and needs no screwdriver.
    local hasNormalPart = false
    for _, candidate in ipairs(plan) do
        if not isAttachableBayonetPart(candidate.part) then
            hasNormalPart = true
            break
        end
    end

    local screwdriver = nil
    if hasNormalPart then
        screwdriver = getScrewdriver(character)
        if not screwdriver then return end
        queueTransferIfNeeded(character, screwdriver)
        if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.equipWeapon then
            ISInventoryPaneContextMenu.equipWeapon(screwdriver, true, false, character:getPlayerNum())
        end
    end

    for _, candidate in ipairs(plan) do
        if isAttachableBayonetPart(candidate.part) then
            if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.equipWeapon then
                local twoHands = weapon.isTwoHandWeapon and weapon:isTwoHandWeapon() or false
                ISInventoryPaneContextMenu.equipWeapon(weapon, true, twoHands, character:getPlayerNum())
            end
            if ISBayonetRemove then
                local knifeType = nil
                if Bayonet and Bayonet.GetKnifeTypeFromAttachment then
                    local okKnife, result = pcall(Bayonet.GetKnifeTypeFromAttachment, safeFullType(candidate.part))
                    if okKnife then knifeType = result end
                end
                local knownIds = snapshotMainInventoryIds(character, knifeType)
                ISTimedActionQueue.add(ISBayonetRemove:new(character, weapon))
                if originContainer and originContainer ~= character:getInventory() and knifeType and GOMReturnCreatedBayonet then
                    ISTimedActionQueue.add(GOMReturnCreatedBayonet:new(character, knifeType, knownIds, originContainer))
                end
            end
        elseif candidate.partType and ISRemoveWeaponUpgrade then
            ISTimedActionQueue.add(ISRemoveWeaponUpgrade:new(character, weapon, candidate.partType))
            queueReturnItemToContainer(character, candidate.part, originContainer)
        end
    end
end

local function getActualContextWeapons(items)
    if not items then return {} end
    local actual = items
    if ISInventoryPane and ISInventoryPane.getActualItems then
        local ok, resolved = pcall(ISInventoryPane.getActualItems, items)
        if ok and type(resolved) == "table" then actual = resolved end
    end

    local out, seen = {}, {}
    for _, item in ipairs(actual) do
        if item and instanceof(item, "HandWeapon") then
            local id = item.getID and item:getID() or tostring(item)
            if not seen[id] then
                seen[id] = true
                table.insert(out, item)
            end
        end
    end
    return out
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

local function guardBayonetContextOptions(playerNum, context, items)
    -- Fix 4.3: intentionally no screwdriver gate for detachable bayonets.
end

local function queueDetachAllWeapons(character, weapons)
    if not character or type(weapons) ~= "table" then return end
    for _, weapon in ipairs(weapons) do
        if isMarzWeapon(weapon) then
            queueDetachAll(character, weapon)
        end
    end
end

local function weaponNeedsUnload(weapon)
    if not weapon or not instanceof(weapon, "HandWeapon") or not weapon:isRanged() then return false end
    local hasClip = weapon.isContainsClip and weapon:isContainsClip() or false
    local count = weapon.getCurrentAmmoCount and weapon:getCurrentAmmoCount() or 0
    local chambered = weapon.haveChamber and weapon:haveChamber()
        and weapon.isRoundChambered and weapon:isRoundChambered() or false
    local jammed = weapon.isJammed and weapon:isJammed() or false
    return hasClip or (count and count > 0) or chambered or jammed
end

local function queueUnloadWeapon(character, weapon)
    if not character or not weapon or not weaponNeedsUnload(weapon) then return end
    queueTransferIfNeeded(character, weapon)

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.equipWeapon then
        ISInventoryPaneContextMenu.equipWeapon(weapon, true, false, character:getPlayerNum())
    end

    local hasMagazineType = weapon.getMagazineType and weapon:getMagazineType() ~= nil
    local containsClip = weapon.isContainsClip and weapon:isContainsClip() or false
    local ammoCount = weapon.getCurrentAmmoCount and weapon:getCurrentAmmoCount() or 0

    if hasMagazineType and containsClip and ISEjectMagazine then
        ISTimedActionQueue.add(ISEjectMagazine:new(character, weapon))
    elseif not hasMagazineType and ammoCount and ammoCount > 0 and ISUnloadBulletsFromFirearm then
        ISTimedActionQueue.add(ISUnloadBulletsFromFirearm:new(character, weapon))
    end

    -- Vanilla ISRackFirearm:removeBullet() creates the ammo item in the player's
    -- inventory.  This is deliberately used instead of mutating chamber state so
    -- a chambered cartridge can never silently disappear.
    local canRack = false
    if ISReloadWeaponAction and ISReloadWeaponAction.canRack then
        local ok, result = pcall(ISReloadWeaponAction.canRack, weapon)
        canRack = ok and result == true
    end
    if (canRack or (weapon.isJammed and weapon:isJammed())) and ISRackFirearm then
        ISTimedActionQueue.add(ISRackFirearm:new(character, weapon))
    end
end

local function queueUnloadAllWeapons(character, weapons)
    if not character or type(weapons) ~= "table" then return end
    for _, weapon in ipairs(weapons) do
        queueUnloadWeapon(character, weapon)
    end
end

local function addBulkWeaponContextOptions(playerNum, context, items)
    if not context or not items then return end
    local character = getSpecificPlayer(playerNum)
    if not character then return end

    local weapons = getActualContextWeapons(items)
    if #weapons == 0 then return end

    local marzWeapons = {}
    local hasDetach = false
    local hasUnload = false
    for _, weapon in ipairs(weapons) do
        if isMarzWeapon(weapon) then
            table.insert(marzWeapons, weapon)
            if #buildRemoveAllPlan(character, weapon) > 0 then hasDetach = true end
        end
        if weaponNeedsUnload(weapon) then hasUnload = true end
    end

    if not hasDetach and not hasUnload then return end

    -- Single weapon: keep the menu compact and human-readable.  Do not append
    -- the weapon name to "Разрядить" — the selected row already tells the user
    -- what weapon the action applies to.
    if #weapons == 1 then
        local weapon = weapons[1]
        if hasDetach and isMarzWeapon(weapon) then
            local opt = context:addOption(uiText("UI_GOMIW_DETACH_ALL"), character, queueDetachAll, weapon)
            if opt and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.addToolTip then
                opt.toolTip = ISInventoryPaneContextMenu.addToolTip()
                opt.toolTip.description = uiText("UI_GOMIW_DETACH_ALL_WEAPONS_DESC")
            end
        end
        if hasUnload then
            local opt = context:addOption(uiText("UI_GOMIW_UNLOAD_ONE"), character, queueUnloadWeapon, weapon)
            if opt and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.addToolTip then
                opt.toolTip = ISInventoryPaneContextMenu.addToolTip()
                opt.toolTip.description = uiText("UI_GOMIW_UNLOAD_ALL_WEAPONS_DESC")
            end
        end
        return
    end

    -- Grouped/stacked weapons: one parent menu controls every actual item hidden
    -- behind the inventory stack row.
    local parent = context:addOption(uiText("UI_GOMIW_BULK"))
    local sub = context:getNew(context)
    context:addSubMenu(parent, sub)

    if hasDetach then
        local opt = sub:addOption(uiText("UI_GOMIW_DETACH_ALL_WEAPONS"), character, queueDetachAllWeapons, marzWeapons)
        if opt and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.addToolTip then
            opt.toolTip = ISInventoryPaneContextMenu.addToolTip()
            opt.toolTip.description = uiText("UI_GOMIW_DETACH_ALL_WEAPONS_DESC")
        end
    end

    if hasUnload then
        local opt = sub:addOption(uiText("UI_GOMIW_UNLOAD_ALL_WEAPONS"), character, queueUnloadAllWeapons, weapons)
        if opt and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.addToolTip then
            opt.toolTip = ISInventoryPaneContextMenu.addToolTip()
            opt.toolTip.description = uiText("UI_GOMIW_UNLOAD_ALL_WEAPONS_DESC")
        end
    end
end

-- Harden ISContextMenu against the exact Gunworks/CleanUI stack trace from the
-- user's log.  Gunworks removes empty attachment submenus; if another UI wrapper
-- leaves a non-table entry in options, vanilla removeOptionByName dereferences it.
local safeContextRemoveWrapper = nil
local function installSafeContextRemove()
    if not ISContextMenu or type(ISContextMenu.removeOptionByName) ~= "function" then return end
    if safeContextRemoveWrapper and ISContextMenu.removeOptionByName == safeContextRemoveWrapper then return end

    local wrapper
    wrapper = function(self, optName)
        local oldOptions = self.options or {}
        local newOptions = {}
        local removed = false
        local indexed = {}

        -- Do not rely on ipairs here. A previous wrapper can leave sparse numeric
        -- indices as well as non-table garbage. Rebuild all numeric entries in
        -- their original order and discard anything that cannot be a menu option.
        for index, option in pairs(oldOptions) do
            if type(index) == "number" and type(option) == "table" then
                table.insert(indexed, { index = index, option = option })
            end
        end
        table.sort(indexed, function(a, b) return a.index < b.index end)

        for _, entry in ipairs(indexed) do
            local option = entry.option
            if not removed and option.name == optName then
                removed = true
                if self.optionPool then table.insert(self.optionPool, option) end
            else
                table.insert(newOptions, option)
            end
        end

        self.options = newOptions
        -- ISContextMenu uses a 1-based next-free-slot counter: after N visible
        -- options numOptions must be N+1 and option.id must match its array index.
        self.numOptions = #newOptions + 1
        for i, option in ipairs(newOptions) do
            option.id = i
        end
        if self.calcHeight then self:calcHeight() end
        if self.calcWidth and self.setWidth then self:setWidth(self:calcWidth()) end
    end
    safeContextRemoveWrapper = wrapper
    ISContextMenu.removeOptionByName = wrapper
end
installSafeContextRemove()

-- Timed-action safety net: direct GoM WeaponParts must obey MountOn even when a
-- third-party context menu offers them incorrectly.  UniversalAttachment outcomes
-- use their own registered mapping and are intentionally exempt from this check.
local upgradeMountGuardWrapper = nil
local function installUpgradeMountGuard()
    if not ISUpgradeWeapon or type(ISUpgradeWeapon.isValid) ~= "function" then return end
    if upgradeMountGuardWrapper and ISUpgradeWeapon.isValid == upgradeMountGuardWrapper then return end
    local previous = ISUpgradeWeapon.isValid
    local wrapper
    wrapper = function(self)
        if not previous(self) then return false end
        if not self.outcomeFullType and self.weapon and self.part
            and isMarzWeapon(self.weapon) and isMarzPart(self.part) then
            if not safeMountsOnWeapon(self.part, self.weapon) then return false end
        end
        return true
    end
    upgradeMountGuardWrapper = wrapper
    ISUpgradeWeapon.isValid = wrapper
end
installUpgradeMountGuard()

local function suppressTextAttachmentContextForMarz(playerNum, context, items)
    if not context or not items or not context.removeOptionByName then return end
    local weapons = getActualContextWeapons(items)
    local hasMarz = false
    for _, weapon in ipairs(weapons) do
        if isMarzWeapon(weapon) then
            hasMarz = true
            break
        end
    end
    if not hasMarz then return end

    -- Guns of Marz attachment management is intentionally routed through the
    -- Inspect Weapon icon grid. The long vanilla/Gunworks text submenus are both
    -- redundant and were the path that exposed incompatible pistol rails on ARs.
    pcall(function() context:removeOptionByName(getText("ContextMenu_Add_Weapon_Upgrade")) end)
    pcall(function() context:removeOptionByName(getText("ContextMenu_Remove_Weapon_Upgrade")) end)
end

if Events and Events.OnFillInventoryObjectContextMenu then
    Events.OnFillInventoryObjectContextMenu.Add(suppressTextAttachmentContextForMarz)
    Events.OnFillInventoryObjectContextMenu.Add(addBulkWeaponContextOptions)
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
        print(TAG .. " Fix 4.3: Tidy Up Meister ignores riskyInspectAction")
        return true
    end
    return false
end

-- Register immediately when load order already provides the API; OnGameStart
-- retries after all client Lua has loaded, covering the opposite load order too.
registerTidyInspectPolicy()

local function onGameStart()
    installSafeContextRemove()
    installUpgradeMountGuard()
    registerTidyInspectPolicy()
    print(TAG .. " Fix 4.3 v0.8.0 loaded - full slot names + icon attachment picker + nearby tools + MountOn guard + bulk detach/unload")
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(onGameStart)
end
