-- Weapon Reload Menu Cleaner
-- v1.0.0 / Project Zomboid Build 42.20.2
--
-- Normalizes the several vanilla/modded firearm-unload entries into one menu:
--   Разрядить оружие > Магазин и ствол / Только магазин / Ствол
-- Uses only vanilla reload timed actions so Guns of Marz / Gunworks hooks remain active.

local TAG = "[Weapon Reload Menu Cleaner]"

pcall(require, "ISUI/ISInventoryPaneContextMenu")
pcall(require, "ISUI/ISContextMenu")
pcall(require, "TimedActions/ISEjectMagazine")
pcall(require, "TimedActions/ISUnloadBulletsFromFirearm")
pcall(require, "TimedActions/ISRackFirearm")

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

        if firstRemoved then
            -- After deletions, clamp to the first position belonging to this
            -- weapon's reload block.
            local insertIndex = math.max(before + 1, math.min(firstRemoved, #context.options + 1))
            addUnifiedUnloadMenu(context, weapon, playerObj, insertIndex)
        end
    end

    ISInventoryPaneContextMenu.doReloadMenuForWeapon = wrapper
    print(TAG .. " v1.0.0 installed over final reload-menu chain")
    return true
end

-- Try immediately, then once again after all active mods have completed loading.
pcall(install)
if Events and Events.OnGameStart then Events.OnGameStart.Add(function() pcall(install) end) end
