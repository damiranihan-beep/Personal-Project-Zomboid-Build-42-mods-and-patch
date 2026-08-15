-- Smoking Universal Patch 42.20.2 v1.4.4
-- Direct smoking from Base.CigarettePack without replacing vanilla/SSO TimedActions.
-- Build 42.20.2 already routes CigarettePack through ISTakePillAction because the
-- pack is a CONSUMABLE + SMOKABLE DrainableComboItem with CustomContextMenu=Smoke.
-- We only give that existing action the requested label and provide a narrow
-- fallback if another mod removed the vanilla option.

require "ISUI/ISInventoryPane"
require "ISUI/ISInventoryPaneContextMenu"

local PACK_TYPE = "Base.CigarettePack"
local PACK_SMOKE_LABEL = getText("ContextMenu_SmokeFromCigarettePack")
if not PACK_SMOKE_LABEL or PACK_SMOKE_LABEL == "ContextMenu_SmokeFromCigarettePack" then
    PACK_SMOKE_LABEL = "Курить с пачки сигарет"
end

local function getSelectedPack(items)
    if not items then return nil end

    local ok, actualItems = pcall(function()
        return ISInventoryPane.getActualItems(items)
    end)
    if not ok or not actualItems then return nil end

    -- Grouped inventory rows can contain several CigarettePack instances.
    -- Prefer a non-empty partially used pack, then any non-empty pack.  This
    -- avoids the old "two packs = no option" behavior and avoids blindly taking
    -- the first object from the stack.
    local anyPack = nil
    local partialPack = nil
    for _, item in ipairs(actualItems) do
        if item and item.getFullType and item:getFullType() == PACK_TYPE then
            local usable = true
            local delta = nil
            if item.getCurrentUsesFloat then
                local okUses, uses = pcall(function() return item:getCurrentUsesFloat() end)
                if okUses then
                    delta = uses
                    usable = uses > 0
                end
            elseif item.getUsedDelta then
                local okDelta, usedDelta = pcall(function() return item:getUsedDelta() end)
                if okDelta then
                    delta = usedDelta
                    usable = usedDelta > 0
                end
            end
            if usable then
                anyPack = anyPack or item
                if delta and delta < 0.999 then
                    partialPack = partialPack or item
                end
            end
        end
    end
    return partialPack or anyPack
end

local function onSmokeSelectedPack(pack, player)
    if not pack or not ISInventoryPaneContextMenu.takePill then return end
    -- Call the vanilla one-item path directly so a grouped stack cannot make
    -- onPillsItems pick the wrong pack.  Vanilla still handles transfer,
    -- ISTakePillAction/SSO sound hooks and ReturnItemToOriginalContainer.
    ISInventoryPaneContextMenu.takePill(pack, player)
end

local function removeOldPackSmokeOptions(context, items)
    if not context or not context.options then return end
    for i = #context.options, 1, -1 do
        local option = context.options[i]
        if type(option) == "table"
        and option.onSelect == ISInventoryPaneContextMenu.onPillsItems
        and option.target == items
        and tostring(option.name or "") == tostring(PACK_SMOKE_LABEL) then
            table.remove(context.options, i)
        end
    end
    for i, option in ipairs(context.options) do
        if type(option) == "table" then option.id = i end
    end
    context.numOptions = #context.options + 1
end

local function onFillInventoryObjectContextMenu(player, context, items)
    local pack = getSelectedPack(items)
    if not pack then return end

    -- Remove the vanilla grouped-stack handler and expose one deterministic
    -- action that targets the selected real pack instance.
    removeOldPackSmokeOptions(context, items)
    local option = context:addOption(PACK_SMOKE_LABEL, pack, onSmokeSelectedPack, player)
    if option then
        option.itemForTexture = pack
        if pack.getTexture then
            local okTex, tex = pcall(function() return pack:getTexture() end)
            if okTex then option.iconTexture = tex end
        end
    end

    if context and context.calcHeight then context:calcHeight() end
    if context and context.calcWidth and context.setWidth then
        context:setWidth(context:calcWidth())
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
