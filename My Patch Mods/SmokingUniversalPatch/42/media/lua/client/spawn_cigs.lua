-- Smoking Universal Patch 42.20.2
-- Replaces the outdated B42 startup-trait check from Where Are My Zang Cigs.
-- This absorbs the separate 42.13+ patch.

local function hasSmokerTrait(player)
	if not player then return false end

	local traits = player:getCharacterTraits()
	if not traits then return false end

	-- B42 trait API (42.13+ / 42.20.x)
	if traits.getKnownTraits and CharacterTraitDefinition and CharacterTrait then
		local ok, knownTraits = pcall(function() return traits:getKnownTraits() end)
		if ok and knownTraits then
			for i = 0, knownTraits:size() - 1 do
				local traitDef = CharacterTraitDefinition.getCharacterTraitDefinition(knownTraits:get(i))
				if traitDef and traitDef:getType() == CharacterTrait.SMOKER then
					return true
				end
			end
		end
	end

	-- Compatibility fallback for older API / other trait wrappers.
	if traits.contains then
		local ok, result = pcall(function() return traits:contains("Smoker") end)
		if ok and result then return true end
	end

	return false
end

local function OnNewGame(player, square)
	if not hasSmokerTrait(player) then return end

	local inv = player:getInventory()
	if not inv then return end

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
