-- Repair already-affected saves/inventories after the FN FNC integrated stock
-- was detached by the missing permanent-attachment registration.

local ok, FoldingStock = pcall(require, "WeaponSystems/Utils/FoldingStock")
if not ok or type(FoldingStock) ~= "table" or type(FoldingStock.RestoreFoldedStockState) ~= "function" then
    print("[GoM Core Fixes] FoldingStock unavailable; existing FNC repair skipped")
    return
end

local function isAffectedFNC(item)
    return item
        and instanceof(item, "HandWeapon")
        and item:getFullType() == "MarzGuns.FNC"
        and item:getWeaponPart("StockIntegrated") == nil
end

local function repairWeapon(weapon)
    if not isAffectedFNC(weapon) then return false end
    FoldingStock.RestoreFoldedStockState(weapon)
    local repaired = weapon:getWeaponPart("StockIntegrated") ~= nil
    if repaired then
        print("[GoM Core Fixes] restored missing FN FNC integrated stock")
    end
    return repaired
end

local function repairPlayer(player)
    if not player or player:isDead() then return end

    local seen = {}
    local function tryRepair(item)
        if not item then return end
        local id = tostring(item:getID())
        if seen[id] then return end
        seen[id] = true
        repairWeapon(item)
    end

    tryRepair(player:getPrimaryHandItem())
    tryRepair(player:getSecondaryHandItem())

    local inventory = player:getInventory()
    if not inventory then return end

    local list = inventory:getAllEvalRecurse(function(item)
        return item ~= nil and instanceof(item, "HandWeapon") and item:getFullType() == "MarzGuns.FNC"
    end, ArrayList.new())

    if not list then return end
    for i = 0, list:size() - 1 do
        tryRepair(list:get(i))
    end
end

if Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(function(_, player)
        repairPlayer(player)
    end)
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        repairPlayer(getPlayer())
    end)
end

print("[GoM Core Fixes] v1.0 FNC existing-save repair installed")
