-- Realistic Combat - Fix 3.1
-- Hide vanilla one-hand equip actions for weapons that the actual item scripts
-- mark as two-handed. The two-hand equip action is intentionally left intact.

require "ISUI/ISInventoryPaneContextMenu"

local function getActualItem(entry)
    if not entry then return nil end
    if instanceof(entry, "InventoryItem") then
        return entry
    end
    if entry.items and entry.items[1] then
        return entry.items[1]
    end
    return nil
end

local function isStrictTwoHandedMelee(item)
    return item
        and instanceof(item, "HandWeapon")
        and item:isMelee()
        and not item:isRanged()
        and (item:isRequiresEquippedBothHands() or item:isTwoHandWeapon())
end

local ONE_HAND_TRANSLATION_KEYS = {
    "ContextMenu_Equip_Primary",
    "ContextMenu_Equip_Secondary",
    "ContextMenu_Equip_One_Hand",
    "ContextMenu_Equip_OneHand",
    "ContextMenu_Equip_in_One_Hand",
}

local ONE_HAND_FALLBACK_NAMES = {
    "Взять в одну руку",
    "Взять в основную руку",
    "Взять во вторую руку",
    "Equip in one hand",
    "Equip Primary",
    "Equip Secondary",
}

local function removeOneHandEquipOptions(playerNum, context, items)
    if not context or not items then return end

    local foundTwoHanded = false
    for _, entry in ipairs(items) do
        local item = getActualItem(entry)
        if isStrictTwoHandedMelee(item) then
            foundTwoHanded = true
            break
        end
    end

    if not foundTwoHanded then return end

    -- Translation-key route: language independent when the vanilla key exists.
    for _, key in ipairs(ONE_HAND_TRANSLATION_KEYS) do
        local name = getText(key)
        if name and name ~= "" then
            context:removeOptionByName(name)
        end
    end

    -- Fallbacks for B42 wording / older translation variants.
    for _, name in ipairs(ONE_HAND_FALLBACK_NAMES) do
        context:removeOptionByName(name)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(removeOneHandEquipOptions)
