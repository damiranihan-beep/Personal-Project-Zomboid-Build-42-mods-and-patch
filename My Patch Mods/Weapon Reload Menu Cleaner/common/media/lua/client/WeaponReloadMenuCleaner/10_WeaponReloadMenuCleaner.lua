-- Weapon Reload Menu Cleaner
-- v1.2.0 / Project Zomboid Build 42.20.2
--
-- Normalizes the several vanilla/modded firearm-unload entries into one menu:
--   Разрядить оружие > Магазин и ствол / Только магазин / Ствол
-- Uses only vanilla reload timed actions so Guns of Marz / Gunworks hooks remain active.

local TAG = "[Weapon Reload Menu Cleaner]"

local okAmmo, Ammo = pcall(require, "WeaponSystems/Utils/Ammo")
if not okAmmo or type(Ammo) ~= "table" then Ammo = nil end

pcall(require, "ISUI/ISInventoryPaneContextMenu")
pcall(require, "ISUI/ISContextMenu")
pcall(require, "ISUI/ISInventoryPane")
pcall(require, "TimedActions/ISEjectMagazine")
pcall(require, "TimedActions/ISUnloadBulletsFromFirearm")
pcall(require, "TimedActions/ISRackFirearm")
pcall(require, "TimedActions/ISLoadBulletsInMagazine")
pcall(require, "TimedActions/ISUnloadBulletsFromMagazine")
pcall(require, "TimedActions/ISInventoryTransferUtil")

local function tr(key, fallback)
    if getText then
        local text = getText(key)
        if text and text ~= key then return text end
    end
    return fallback
end

local function safeCall(default, object, methodName)
    if not object or type(methodName) ~= "string" then return default end
    local method = object[methodName]
    if not method then return default end
    local ok, value = pcall(method, object)
    if ok then return value end
    return default
end

local function isMarzWeapon(weapon)
    local fullType = safeCall(nil, weapon, "getFullType")
    return type(fullType) == "string" and string.sub(fullType, 1, 9) == "MarzGuns."
end

local function hasDetachableMagazine(weapon)
    return safeCall(nil, weapon, "getMagazineType") ~= nil
end

local function containsMagazine(weapon)
    return safeCall(false, weapon, "isContainsClip") == true
end

local function internalAmmoCount(weapon)
    return tonumber(safeCall(0, weapon, "getCurrentAmmoCount")) or 0
end

local function isChambered(weapon)
    return safeCall(false, weapon, "isRoundChambered") == true
end

local function isJammed(weapon)
    return safeCall(false, weapon, "isJammed") == true
end

local function equipForReload(playerObj, weapon)
    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.equipWeapon then
        ISInventoryPaneContextMenu.equipWeapon(weapon, true, false, playerObj:getPlayerNum())
    end
end

local function queueMagazineUnload(playerObj, weapon)
    if not playerObj or not weapon then return end
    equipForReload(playerObj, weapon)

    if hasDetachableMagazine(weapon) then
        if containsMagazine(weapon) and ISEjectMagazine then
            ISTimedActionQueue.add(ISEjectMagazine:new(playerObj, weapon))
        end
    elseif internalAmmoCount(weapon) > 0 and ISUnloadBulletsFromFirearm then
        ISTimedActionQueue.add(ISUnloadBulletsFromFirearm:new(playerObj, weapon))
    end
end

local function queueChamberUnload(playerObj, weapon)
    if not playerObj or not weapon or not isChambered(weapon) then return end
    equipForReload(playerObj, weapon)
    if ISRackFirearm then
        ISTimedActionQueue.add(ISRackFirearm:new(playerObj, weapon))
    end
end

local function unloadMagazineOnly(playerObj, weapon)
    queueMagazineUnload(playerObj, weapon)
end

local function unloadChamberOnly(playerObj, weapon)
    queueChamberUnload(playerObj, weapon)
end

local function unloadMagazineAndChamber(playerObj, weapon)
    -- Order is intentional: remove/empty the magazine first, then rack the
    -- chamber. That prevents the rack action from feeding a fresh round.
    queueMagazineUnload(playerObj, weapon)
    queueChamberUnload(playerObj, weapon)
end

local function knownUnloadName(name, weapon)
    if type(name) ~= "string" then return false end
    local displayName = safeCall("", weapon, "getDisplayName") or ""

    local names = {
        getText and getText("ContextMenu_EjectMagazine") or nil,
        getText and getText("ContextMenu_UnloadRounds", displayName) or nil,
        getText and getText("ContextMenu_Rack", displayName) or nil,
        getText and getText("ContextMenu_UnloadRoundFrom", displayName) or nil,
    }
    for _, candidate in ipairs(names) do
        if candidate and name == candidate then return true end
    end

    if P4PickingMeister and P4PickingMeister.Menu_RetrieveAllAmmo and name == P4PickingMeister.Menu_RetrieveAllAmmo then
        return true
    end
    return false
end

local function shouldRemoveOption(option, weapon, keptUnjam)
    if not option then return false, keptUnjam end
    local callback = option.onSelect

    if ISInventoryPaneContextMenu then
        if callback == ISInventoryPaneContextMenu.onEjectMagazine then return true, keptUnjam end
        if callback == ISInventoryPaneContextMenu.onUnloadBulletsFromFirearm then return true, keptUnjam end
        if callback == ISInventoryPaneContextMenu.onRackGun then
            if isJammed(weapon) and not keptUnjam then
                -- Keep one real unjam action.
                return false, true
            end
            if not isChambered(weapon) then
                -- A plain "rack/cycle action" with no chambered round is not an
                -- unload duplicate. Keep it so pump/bolt/manual cycling is never
                -- lost just because we cleaned up the unload entries.
                return false, keptUnjam
            end
            -- When a round is actually chambered, the rack action is the chamber
            -- half of our unified unload command and is folded into the submenu.
            return true, keptUnjam
        end
    end

    if P4PickingMeister and P4PickingMeister.onRetrieveAllAmmo and callback == P4PickingMeister.onRetrieveAllAmmo then
        return true, keptUnjam
    end

    -- A few mods duplicate the vanilla entry with a small wrapper callback. Exact
    -- vanilla/P4 labels in the reload-menu segment are still safe to fold, except
    -- a genuine manual Rack action when no round is currently chambered.
    if knownUnloadName(option.name, weapon) then
        local displayName = safeCall("", weapon, "getDisplayName") or ""
        local unjamName = getText and getText("ContextMenu_Unjam", displayName) or ""
        local rackName = getText and getText("ContextMenu_Rack", displayName) or ""
        if isJammed(weapon) and option.name == unjamName and not keptUnjam then
            return false, true
        end
        if not isJammed(weapon) and not isChambered(weapon) and option.name == rackName then
            return false, keptUnjam
        end
        return true, keptUnjam
    end

    return false, keptUnjam
end

local function normalizeContextOptions(context)
    if not context or not context.options then return end
    for i, option in ipairs(context.options) do
        if type(option) == "table" then option.id = i end
    end
    context.numOptions = #context.options + 1
end

local function addUnifiedUnloadMenu(context, weapon, playerObj, insertIndex)
    local detachable = hasDetachableMagazine(weapon)
    local hasMagazineAmmo = detachable and containsMagazine(weapon) or (not detachable and internalAmmoCount(weapon) > 0)
    local chambered = isChambered(weapon)

    if not hasMagazineAmmo and not chambered then return end

    local parent = context:addOption(tr("UI_WRMC_UnloadWeapon", "Разрядить оружие"), nil, nil)
    local submenu = context:getNew(context)
    context:addSubMenu(parent, submenu)

    if hasMagazineAmmo and chambered then
        submenu:addOption(tr("UI_WRMC_MagazineAndChamber", "Магазин и ствол"), playerObj, unloadMagazineAndChamber, weapon)
        submenu:addOption(tr("UI_WRMC_MagazineOnly", "Только магазин"), playerObj, unloadMagazineOnly, weapon)
    elseif hasMagazineAmmo then
        submenu:addOption(tr("UI_WRMC_MagazineOnly", "Только магазин"), playerObj, unloadMagazineOnly, weapon)
    elseif chambered then
        submenu:addOption(tr("UI_WRMC_ChamberOnly", "Ствол"), playerObj, unloadChamberOnly, weapon)
    end

    -- Put the unified entry where the first old unload action used to be rather
    -- than appending it below unrelated actions such as "Place item".
    if insertIndex and insertIndex >= 1 and insertIndex < #context.options then
        local added = table.remove(context.options, #context.options)
        table.insert(context.options, insertIndex, added)
    end
    normalizeContextOptions(context)
end

local installedBase = nil
local wrapper = nil

local function install()
    if not ISInventoryPaneContextMenu or type(ISInventoryPaneContextMenu.doReloadMenuForWeapon) ~= "function" then
        return false
    end
    if ISInventoryPaneContextMenu.doReloadMenuForWeapon == wrapper then return true end

    local base = ISInventoryPaneContextMenu.doReloadMenuForWeapon
    installedBase = base

    wrapper = function(playerObj, weapon, context)
        local before = #context.options
        base(playerObj, weapon, context)

        local firstRemoved = nil
        local keptUnjam = false
        for i = #context.options, before + 1, -1 do
            local remove, nowKeptUnjam = shouldRemoveOption(context.options[i], weapon, keptUnjam)
            keptUnjam = nowKeptUnjam
            if remove then
                firstRemoved = i
                table.remove(context.options, i)
            end
        end

        normalizeContextOptions(context)

        if firstRemoved then
            -- Guns of Marz gets the compact single/bulk unload actions from the
            -- Inspect Weapon compatibility layer (including grouped inventory
            -- stacks). Do not add a second text submenu for the same firearm.
            if not isMarzWeapon(weapon) then
                -- After deletions, clamp to the first position belonging to this
                -- weapon's reload block.
                local insertIndex = math.max(before + 1, math.min(firstRemoved, #context.options + 1))
                addUnifiedUnloadMenu(context, weapon, playerObj, insertIndex)
            end
        end
    end

    ISInventoryPaneContextMenu.doReloadMenuForWeapon = wrapper
    print(TAG .. " v1.2.0 installed over final reload-menu chain")
    return true
end

-- Try immediately, then once again after all active mods have completed loading.
pcall(install)
if Events and Events.OnGameStart then Events.OnGameStart.Add(function() pcall(install) end) end


-- --------------------------------------------------------------------------
-- Bulk magazine operations (Fix 4.4)
-- --------------------------------------------------------------------------
-- A grouped inventory row can represent many real magazine objects.  Resolve the
-- hidden items and queue normal B42 timed actions for every magazine, regardless
-- of whether the row came from the player's inventory, floor or an open crate.

local function addContainerUnique(out, seen, container)
    if not container then return end
    local key = tostring(container)
    if seen[key] then return end
    seen[key] = true
    table.insert(out, container)
end

local function getAccessibleContainers(playerObj)
    local out, seen = {}, {}
    if not playerObj then return out end
    addContainerUnique(out, seen, playerObj:getInventory())

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.getContainers then
        local ok, list = pcall(ISInventoryPaneContextMenu.getContainers, playerObj)
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

    local function addPage(page)
        if not page then return end
        local backpacks = page.backpacks
        if not backpacks and page.inventoryPane then backpacks = page.inventoryPane.backpacks end
        if type(backpacks) ~= "table" then return end
        for _, entry in pairs(backpacks) do
            local container = entry and (entry.inventory or entry.container) or nil
            if not container and entry and entry.getItems then container = entry end
            addContainerUnique(out, seen, container)
        end
    end

    local playerNum = playerObj:getPlayerNum()
    if getPlayerInventory then
        local ok, page = pcall(getPlayerInventory, playerNum)
        if ok then addPage(page) end
    end
    if getPlayerLoot then
        local ok, page = pcall(getPlayerLoot, playerNum)
        if ok then addPage(page) end
    end
    return out
end

local function isMagazineItem(item)
    if not item or instanceof(item, "HandWeapon") then return false end
    if not item.getCurrentAmmoCount or not item.getMaxAmmo then return false end
    local okMax, maxAmmo = pcall(function() return item:getMaxAmmo() end)
    return okMax and tonumber(maxAmmo) and tonumber(maxAmmo) > 0
end

local function getActualContextMagazines(items)
    if not items then return {} end
    local actual = items
    if ISInventoryPane and ISInventoryPane.getActualItems then
        local ok, resolved = pcall(ISInventoryPane.getActualItems, items)
        if ok and type(resolved) == "table" then actual = resolved end
    end
    local out, seen = {}, {}
    for _, item in ipairs(actual) do
        if isMagazineItem(item) then
            local id = item.getID and item:getID() or tostring(item)
            if not seen[id] then
                seen[id] = true
                table.insert(out, item)
            end
        end
    end
    return out
end

local function queueReturnItem(playerObj, item, destination)
    if not playerObj or not item or not destination then return end
    local main = playerObj:getInventory()
    if destination == main then return end
    if not ISInventoryTransferUtil or not ISInventoryTransferUtil.newInventoryTransferAction then return end
    local ok, action = pcall(ISInventoryTransferUtil.newInventoryTransferAction,
        playerObj, item, main, destination, nil)
    if ok and action then
        if action.setAllowMissingItems then pcall(function() action:setAllowMissingItems(true) end) end
        ISTimedActionQueue.add(action)
    end
end

local function queueBulkUnloadMagazines(playerObj, magazines)
    if not playerObj or type(magazines) ~= "table" or not ISUnloadBulletsFromMagazine then return end
    for _, magazine in ipairs(magazines) do
        local count = tonumber(safeCall(0, magazine, "getCurrentAmmoCount")) or 0
        if count > 0 then
            local origin = magazine.getContainer and magazine:getContainer() or nil
            ISInventoryPaneContextMenu.transferIfNeeded(playerObj, magazine)
            ISTimedActionQueue.add(ISUnloadBulletsFromMagazine:new(playerObj, magazine))
            queueReturnItem(playerObj, magazine, origin)
        end
    end
end

local function getCurrentAmmoKey(magazine)
    if not magazine or not magazine.getAmmoType then return nil end
    local ok, ammoType = pcall(function() return magazine:getAmmoType() end)
    if not ok or not ammoType then return nil end
    local okKey, key = pcall(function() return ammoType:getItemKey() end)
    return okKey and key or nil
end

local function getCompatibleAmmoTypes(magazine)
    local fullType = safeCall(nil, magazine, "getFullType")
    if Ammo and fullType and Ammo.ItemAmmoFamily and Ammo.GetBulletTypesForFamily then
        local family = Ammo.ItemAmmoFamily[fullType]
        if family then
            local ok, types = pcall(Ammo.GetBulletTypesForFamily, family)
            if ok and type(types) == "table" then return types end
        end
    end
    local key = getCurrentAmmoKey(magazine)
    return key and { key } or {}
end

local function collectAmmoItems(playerObj, bulletType)
    local out, seen = {}, {}
    for _, container in ipairs(getAccessibleContainers(playerObj)) do
        local ok, list = pcall(function() return container:getAllTypeRecurse(bulletType) end)
        if ok and list then
            local okSize, size = pcall(function() return list:size() end)
            if okSize and size then
                for i = 0, size - 1 do
                    local okGet, item = pcall(function() return list:get(i) end)
                    if okGet and item then
                        local id = item.getID and item:getID() or tostring(item)
                        if not seen[id] then
                            seen[id] = true
                            table.insert(out, item)
                        end
                    end
                end
            end
        end
    end
    return out
end

local function chooseAmmoType(magazine, pools)
    local compatible = getCompatibleAmmoTypes(magazine)
    if #compatible == 0 then return nil end
    local currentCount = tonumber(safeCall(0, magazine, "getCurrentAmmoCount")) or 0
    local currentKey = getCurrentAmmoKey(magazine)

    -- Never change ammunition type inside an already partially loaded magazine.
    if currentCount > 0 and currentKey then
        for _, candidate in ipairs(compatible) do
            if candidate == currentKey and pools[candidate] and #pools[candidate] > 0 then return candidate end
        end
        return nil
    end

    -- Empty magazine: Gunworks registration order is the same priority used by
    -- its automatic reload helper, so use the first type that is actually present.
    for _, candidate in ipairs(compatible) do
        if pools[candidate] and #pools[candidate] > 0 then return candidate end
    end
    return nil
end

local function queueBulkLoadMagazines(playerObj, magazines)
    if not playerObj or type(magazines) ~= "table" or not ISLoadBulletsInMagazine then return end

    -- Build one shared pool and reserve concrete bullet items before queuing any
    -- actions. This prevents two magazines from both claiming the same cartridges.
    local allTypes, pools = {}, {}
    for _, magazine in ipairs(magazines) do
        for _, bulletType in ipairs(getCompatibleAmmoTypes(magazine)) do allTypes[bulletType] = true end
    end
    for bulletType, _ in pairs(allTypes) do pools[bulletType] = collectAmmoItems(playerObj, bulletType) end

    local plans = {}
    for _, magazine in ipairs(magazines) do
        local current = tonumber(safeCall(0, magazine, "getCurrentAmmoCount")) or 0
        local maximum = tonumber(safeCall(0, magazine, "getMaxAmmo")) or 0
        local free = math.max(0, maximum - current)
        if free > 0 then
            local bulletType = chooseAmmoType(magazine, pools)
            if bulletType then
                local reserved = {}
                for _ = 1, math.min(free, #pools[bulletType]) do
                    table.insert(reserved, table.remove(pools[bulletType], 1))
                end
                if #reserved > 0 then
                    table.insert(plans, { magazine = magazine, bulletType = bulletType, bullets = reserved })
                end
            end
        end
    end

    for _, plan in ipairs(plans) do
        local magazine = plan.magazine
        local origin = magazine.getContainer and magazine:getContainer() or nil
        ISInventoryPaneContextMenu.transferIfNeeded(playerObj, magazine)

        -- B42/Gunworks transferIfNeeded accepts a Java ArrayList. Batch the
        -- reserved cartridges for this magazine so a 15-magazine stack does not
        -- create one transfer call per single round. Keep a conservative fallback
        -- for environments where ArrayList is unavailable.
        if ArrayList and ArrayList.new then
            local bulletItems = ArrayList.new()
            for _, bullet in ipairs(plan.bullets) do bulletItems:add(bullet) end
            ISInventoryPaneContextMenu.transferIfNeeded(playerObj, bulletItems)
        else
            for _, bullet in ipairs(plan.bullets) do
                ISInventoryPaneContextMenu.transferIfNeeded(playerObj, bullet)
            end
        end

        if Ammo and Ammo.MagazineAmmoProfileSetter then
            pcall(Ammo.MagazineAmmoProfileSetter, magazine, plan.bulletType)
            -- Gunworks' constructor extension accepts ammoLimit + ammoTypeOverride,
            -- keeping mixed-ammo magazine bookkeeping correct.
            ISTimedActionQueue.add(ISLoadBulletsInMagazine:new(
                playerObj, magazine, #plan.bullets, #plan.bullets, plan.bulletType))
        else
            ISTimedActionQueue.add(ISLoadBulletsInMagazine:new(playerObj, magazine, #plan.bullets))
        end
        queueReturnItem(playerObj, magazine, origin)
    end
end

local function removeNativeMagazineUnloadEntry(context)
    if not context or type(context.options) ~= "table" then return end
    local nativeName = getText and getText("ContextMenu_UnloadMagazine") or nil
    for i = #context.options, 1, -1 do
        local option = context.options[i]
        if type(option) == "table" then
            local isNativeCallback = ISInventoryPaneContextMenu
                and ISInventoryPaneContextMenu.onUnloadBulletsFromMagazine
                and option.onSelect == ISInventoryPaneContextMenu.onUnloadBulletsFromMagazine
            if isNativeCallback or (nativeName and option.name == nativeName) then
                table.remove(context.options, i)
            end
        end
    end
    normalizeContextOptions(context)
end

local function addBulkMagazineContext(playerNum, context, items)
    if not context or not items then return end
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end
    local magazines = getActualContextMagazines(items)
    if #magazines == 0 then return end

    local canUnload, canLoad = false, false
    for _, mag in ipairs(magazines) do
        local current = tonumber(safeCall(0, mag, "getCurrentAmmoCount")) or 0
        local maximum = tonumber(safeCall(0, mag, "getMaxAmmo")) or 0
        if current > 0 then canUnload = true end
        if current < maximum then canLoad = true end
    end
    if not canUnload and not canLoad then return end

    -- Guarantee the user's "any cell" case even for one magazine on the floor or
    -- in a crate. Replace the upstream unload entry with our transfer-safe path.
    if #magazines == 1 then
        if canUnload then
            removeNativeMagazineUnloadEntry(context)
            context:addOption("Разрядить магазин", playerObj, queueBulkUnloadMagazines, magazines)
        end
        return
    end

    -- A real grouped stack/selection gets one bulk submenu operating on every
    -- concrete magazine hidden behind the inventory row.
    removeNativeMagazineUnloadEntry(context)
    local parent = context:addOption("Магазины — групповые действия")
    local sub = context:getNew(context)
    context:addSubMenu(parent, sub)
    if canUnload then
        sub:addOption("Разрядить все магазины", playerObj, queueBulkUnloadMagazines, magazines)
    end
    if canLoad then
        sub:addOption("Зарядить все магазины", playerObj, queueBulkLoadMagazines, magazines)
    end
end

if Events and Events.OnFillInventoryObjectContextMenu then
    Events.OnFillInventoryObjectContextMenu.Add(addBulkMagazineContext)
end

print(TAG .. " v1.2.0 bulk magazine load/unload enabled for grouped stacks in inventory/floor/open containers")
