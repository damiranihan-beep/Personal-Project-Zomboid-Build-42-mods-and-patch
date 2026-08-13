-- Smoking Universal Patch 42.20.2 v1.4.2
-- Direct smoking from Base.CigarettePack without replacing vanilla/SSO TimedActions.
-- Build 42.20.2 already routes CigarettePack through ISTakePillAction because the
-- pack is a CONSUMABLE + SMOKABLE DrainableComboItem with CustomContextMenu=Smoke.
-- We only give that existing action the requested label and provide a narrow
-- fallback if another mod removed the vanilla option.

require "ISUI/ISInventoryPane"
require "ISUI/ISInventoryPaneContextMenu"

local PACK_TYPE = "Base.CigarettePack"
local PACK_SMOKE_LABEL = getText("ContextMenu_SmokeFromCigarettePack")

local function getSingleSelectedPack(items)
    if not items then return nil end

    local ok, actualItems = pcall(function()
        return ISInventoryPane.getActualItems(items)
    end)
    if not ok or not actualItems or #actualItems ~= 1 then return nil end

    local item = actualItems[1]
    if not item or not item.getFullType then return nil end
    if item:getFullType() ~= PACK_TYPE then return nil end

    return item
end

local function renameVanillaPackSmokeOption(context, items, pack)
    if not context or not context.options then return false end

    for _, option in ipairs(context.options) do
        if option
        and option.onSelect == ISInventoryPaneContextMenu.onPillsItems
        and option.target == items then
            option.name = PACK_SMOKE_LABEL
            option.itemForTexture = pack
            return true
        end
    end

    return false
end

local function onFillInventoryObjectContextMenu(player, context, items)
    local pack = getSingleSelectedPack(items)
    if not pack then return end

    -- Normal 42.20.2 path: rename the already-created vanilla Smoke option.
    local found = renameVanillaPackSmokeOption(context, items, pack)

    -- First ask vanilla to build its normal smoke entry. This keeps all standard
    -- ignition checks whenever vanilla accepts the selected container.
    if not found and ISInventoryPaneContextMenu.doPillsMenu then
        ISInventoryPaneContextMenu.doPillsMenu(context, items, player, PACK_SMOKE_LABEL)
        found = renameVanillaPackSmokeOption(context, items, pack)
    end

    -- Build 42 may omit CustomContextMenu actions for an item selected from a
    -- backpack/secondary inventory pane. In that exact case expose the same
    -- vanilla onPillsItems handler directly. The action itself remains vanilla,
    -- so SSO still sees only the normal ISTakePillAction path.
    if not found and context.addOption and ISInventoryPaneContextMenu.onPillsItems then
        local option = context:addOption(PACK_SMOKE_LABEL, items, ISInventoryPaneContextMenu.onPillsItems, player)
        if option then
            option.itemForTexture = pack
            found = true
        end
    end

    -- Recalculate width after replacing/adding the label.
    if context and context.calcWidth and context.setWidth then
        context:setWidth(context:calcWidth())
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
