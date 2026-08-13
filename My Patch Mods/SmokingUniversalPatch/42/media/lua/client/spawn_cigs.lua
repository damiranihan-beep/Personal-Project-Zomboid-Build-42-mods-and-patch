-- Smoking Universal Patch 42.20.2 v1.4 Safe
-- Where Are My Zang Cigs startup compatibility.
-- Based on the old WhereAreMyZangCigs-42.13-patch trait fix.
-- IMPORTANT: world-loot multipliers are intentionally NOT duplicated here.
-- The original Where Are My Zang Cigs Distrubtions_cigs.lua already doubles
-- cigarette spawn chances and adds cigarettes to extra loot tables/zombies.

local function hasSmokerTrait(player)
    if not player then return false end

    local traits = player:getCharacterTraits()
    if not traits then return false end

    -- Build 42.13+ / 42.20.x API used by the old compatibility patch.
    if traits.getKnownTraits and CharacterTraitDefinition and CharacterTrait then
        local ok, knownTraits = pcall(function()
            return traits:getKnownTraits()
        end)

        if ok and knownTraits then
            for i = 0, knownTraits:size() - 1 do
                local traitDef = CharacterTraitDefinition.getCharacterTraitDefinition(knownTraits:get(i))
                if traitDef and traitDef:getType() == CharacterTrait.SMOKER then
                    return true
                end
            end
        end
    end

    -- Defensive fallback for wrappers/mods that still expose contains().
    if traits.contains then
        local okEnum, enumResult = pcall(function()
            return CharacterTrait and traits:contains(CharacterTrait.SMOKER)
        end)
        if okEnum and enumResult then return true end

        local okString, stringResult = pcall(function()
            return traits:contains("Smoker")
        end)
        if okString and stringResult then return true end
    end

    return false
end

local function OnNewGame(player, square)
    if not hasSmokerTrait(player) then return end

    local inv = player:getInventory()
    if not inv then return end

    -- Same immersion ranges as the old 42.13+ compatibility patch.
    local pack = inv:AddItem("Base.CigarettePack")
    if pack and pack.setUses then
        pack:setUses(ZombRand(3, 10))
    end

    local lighter = inv:AddItem("Base.LighterDisposable")
    if lighter and lighter.setUses then
        lighter:setUses(ZombRand(6, 25))
    end
end

Events.OnNewGame.Add(OnNewGame)
