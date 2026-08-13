require "TimedActions/ISEatFoodAction"
require "TimedActions/ISTakePillAction"
require "SmokingSoundsOverhaul/SSO_Library"
require "SmokingSoundsOverhaul/SSO_Schedule"
require "SmokingSoundsOverhaul/SSO_Playback"
require "SmokingSoundsOverhaul/SSO_Config"

SmokingSoundsOverhaul = SmokingSoundsOverhaul or {}
local SSO = SmokingSoundsOverhaul
local Sched, PB, Cfg = SSO.Schedule, SSO.Playback, SSO.Config

-- Smoking Universal Patch 42.20.2 v1.3 Lite
-- Scope: compatibility for Smoking Sounds Overhaul + Where Are My Zang Cigs,
-- plus direct smoking from cigarette packs. No inventory/container return logic.

-- Defensive wrapper: a Lua playback error must never abort the actual smoking action.
local function ssoSafeCall(fn, ...)
	if not fn then return false end
	local ok, err = pcall(fn, ...)
	if not ok then
		print("[Smoking Universal Patch] SSO playback error: " .. tostring(err))
	end
	return ok
end

-- This Lite patch intentionally does NOT move packs or ignition items between containers.
-- Container return/management is left to the user's separate inventory QoL mod.

-- public surface, used by True Smoking
SSO_last_match_sound = 0
SSO_last_lighter_sound = 0
SSO_last_puff_sound = 0
SSO_last_lighting_sound = ""

function SmokingSoundsOverhaul:getPuffSound(isFemale)
	SSO_last_puff_sound = 1
	return "Smoking_puff1" .. (isFemale and "f" or "m")
end

function SmokingSoundsOverhaul:getLightingSound(player)
	return SSO_last_lighting_sound
end

-- CustomEatSound values we claim; anything else, another mod set its own sound
SSO.claimedEatSounds = {
	[""] = true, ["Eating"] = true,
	["sm_smoking"] = true,   -- MCM
	["GF_LightUp"] = true,   -- J's Green Fire
}

function SSO.isSmokable(item)
	if not item then return false end
	local eatType = item.getEatType and item:getEatType() or nil
	if eatType == "Pipe" then return Cfg.pipes() end
	if ItemTag and ItemTag.SMOKABLE and item.hasTag and item:hasTag(ItemTag.SMOKABLE) then
		return true
	end
	return eatType == "Cigarettes"
end

function SSO.shouldOverride(item)
	if not SSO.enableScheduler then return false end
	if not SSO.isSmokable(item) then return false end
	local ces = ""
	if item.getCustomEatSound then ces = item:getCustomEatSound() or "" end
	return SSO.claimedEatSounds[ces] == true
end

-- what is being used to light it, from the item the action consumes; nil = no strike
local function ignitionFamily(action)
	if action.carLighter or action.openFlame then return nil end
	if not action.getRequiredItem then return nil end
	local ok, item = pcall(function() return action:getRequiredItem() end)
	if not ok or not item then return nil end
	return Sched.familyOf(item:getFullType())
end

local function settingsFor(action)
	local family = ignitionFamily(action)
	local mode = Cfg.modeName()
	if mode == "assembled" and not family then mode = "puffs" end
	local fam = family or "lighter"
	return {
		family = fam,
		gender = action.character:isFemale() and "f" or "m",
		minGap = Cfg.minGap(),
		lidClose = Cfg.lidClose(),
		mode = mode,
		setNum = Cfg.setNum(fam),
		flicks = Cfg.flicksFor(fam),
		ignVol = Cfg.ignVol(),
		puffVol = Cfg.puffVol(),
	}
end

-- Classic: one original combined clip
local function classicSound(action)
	local family = ignitionFamily(action) or "lighter"
	local gender = action.character:isFemale() and "f" or "m"
	local set = SSO.Lib.legacy[family] and SSO.Lib.legacy[family][gender]
	if not set or #set == 0 then return nil end
	local n = ZombRand(#set) + 1
	if family == "lighter" then SSO_last_lighter_sound = n else SSO_last_match_sound = n end
	SSO_last_lighting_sound = set[n]
	return set[n]
end

-- ISEatFoodAction: loose cigarettes, cigars, rollups, cigarillos, pipes
local eat_start   = ISEatFoodAction.start
local eat_update  = ISEatFoodAction.update
local eat_stop    = ISEatFoodAction.stop
local eat_perform = ISEatFoodAction.perform

function ISEatFoodAction:start()
	if getActivatedMods():contains("Susceptible") then
		--Susceptible support for removing mask before smoking/eating * Not my code! *
		if SusceptibleMod.isPlayerSusceptible(self.character) then
			local threat = SusceptibleMod.threatByPlayer[self.character];
			if threat and threat > 0 then
				self:forceStop();
				return;
			end

			local mask = SusceptibleMod.getEquippedMaskItemAndData(self.character);
			if mask then
				self:stop();
				self:autoManageMask(mask);
				return;
			end
		end
	end

	if not SSO.shouldOverride(self.item) then
		eat_start(self)
		return
	end

	if Cfg.isClassic() then
		self.eatSound = classicSound(self) or ""
		eat_start(self)
		self.eatSound = ""   -- clear so update() does not replay it
		return
	end

	self.eatSound = ""
	eat_start(self)
	ssoSafeCall(PB.start, self, settingsFor(self))
end

function ISEatFoodAction:update()
	eat_update(self)
	ssoSafeCall(PB.tick, self)
end

function ISEatFoodAction:stop()
	ssoSafeCall(PB.stop, self)
	eat_stop(self)
end

function ISEatFoodAction:perform()
	ssoSafeCall(PB.stop, self)
	eat_perform(self)
end

-- ISTakePillAction: smoking straight from the pack (routed here, not to ISEatFoodAction)
local pill_start   = ISTakePillAction.start
local pill_update  = ISTakePillAction.update
local pill_stop    = ISTakePillAction.stop
local pill_perform = ISTakePillAction.perform

function ISTakePillAction:start()
	if not SSO.shouldOverride(self.item) then
		pill_start(self)
		return
	end

	-- decide before the original runs (it consumes the lighter/matches)
	local cfg = Cfg.isClassic() and nil or settingsFor(self)
	local classic = Cfg.isClassic() and classicSound(self) or nil

	pill_start(self)

	if classic then
		local em = self.character:getEmitter()
		local h = em and em:playSound(classic)
		self.sso = { events = {}, next = 1, elapsed = 0, handles = {}, lastMs = 0 }
		if h and h ~= 0 then self.sso.handles[1] = h end
	elseif cfg then
		ssoSafeCall(PB.start, self, cfg)
	end
end

function ISTakePillAction:update()
	pill_update(self)
	ssoSafeCall(PB.tick, self)
end

function ISTakePillAction:stop()
	ssoSafeCall(PB.stop, self)
	pill_stop(self)
end

function ISTakePillAction:perform()
	ssoSafeCall(PB.stop, self)
	pill_perform(self)
end
