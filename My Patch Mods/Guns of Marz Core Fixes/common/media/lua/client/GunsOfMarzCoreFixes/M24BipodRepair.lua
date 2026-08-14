-- Repair already-affected M24 weapons after the stock Guns of Marz permanent
-- registry omitted both state-items of the integrated folding bipod.

local ok, FoldingBipod = pcall(require, "WeaponSystems/Utils/FoldingBipod")
if not ok or type(FoldingBipod) ~= "table" or type(FoldingBipod.RestoreDeployedBipodState) ~= "function" then
    print("[GoM Core Fixes] FoldingBipod unavailable; existing M24 repair skipped")
    return
end

local function isAffectedM24(item)
    return item
        and instanceof(item, "HandWeapon")
        and item:getFullType() == "MarzGuns.M24"
        and item:getWeaponPart("BipodIntegrated") == nil
end

local function repairWeapon(weapon)
    if not isAffectedM24(weapon) then return false end
    FoldingBipod.RestoreDeployedBipodState(weapon)
    local repaired = weapon:getWeaponPart("BipodIntegrated") ~= nil
    if repaired then
        print("[GoM Core Fixes] restored missing M24 integrated bipod")
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
        return item ~= nil and instanceof(item, "HandWeapon") and item:getFullType() == "MarzGuns.M24"
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

print("[GoM Core Fixes] v1.1 M24 existing-save repair installed")
