-- Realistic Combat - Fix 3.8 - Build 42.20.2
-- Off-hand attacks are real SwipeStatePlayer attacks.  The mod only chooses
-- which equipped one-handed melee weapon the vanilla combat pipeline sees.

local states = {}

local function stateFor(player)
    local idx = player:getIndex()
    local s = states[idx]
    if not s then
        s = {
            phase = nil,
            swapPending = false,
            primary = nil,
            secondary = nil,
            offhandWeapon = nil,
            lastWasShove = false,
            lastWasGround = false,
            strainBefore = nil,
            strainTransferPending = false,
            strainTransferDelay = 0,
            armSlotsSaved = nil,
            armSwapAge = 0,
            nextPhase = nil,
            launchPending = false,
            launchDelay = 0,
            ownsMeleeInput = false,
            handSwapOwned = false,
        }
        states[idx] = s
    end
    return s
end

local function clearAnimFlags(player)
    player:setVariable("DWL_Offhand", false)
    player:setVariable("DWL_OffhandStab", false)
end

-- While the alternating chain is active, suppress only the input-driven melee
-- DoAttack() path. Direct player:pressedAttack() calls still go through vanilla
-- CombatManager, but the held LMB can no longer steal the first weapon-ready
-- frame and start another right-hand swing before our off-hand attack.
local function takeOverMeleeInput(player, s)
    if not s.ownsMeleeInput then
        player:setAuthorizeMeleeAction(false)
        s.ownsMeleeInput = true
    end
end

local function releaseMeleeInput(player, s)
    if s.ownsMeleeInput then
        player:setAuthorizeMeleeAction(true)
        s.ownsMeleeInput = false
    end
end

local function isValidOneHandedMelee(weapon)
    return weapon
        and instanceof(weapon, "HandWeapon")
        and weapon:isMelee()
        and not weapon:isRanged()
        and not weapon:isBroken()
        and not weapon:isRequiresEquippedBothHands()
        and not weapon:isTwoHandWeapon()
end

-- Strict balance rule:
-- any melee weapon marked by the game's own scripts as two-handed must occupy
-- both hands. This uses the vanilla item flags (TwoHandWeapon /
-- RequiresEquippedBothHands), so the rule automatically follows the actual
-- weapon scripts instead of maintaining a hard-coded weapon list.
local function isTwoHandedMelee(weapon)
    return weapon
        and instanceof(weapon, "HandWeapon")
        and weapon:isMelee()
        and not weapon:isRanged()
        and (weapon:isRequiresEquippedBothHands() or weapon:isTwoHandWeapon())
end

local function hasTwoHandedConflict(player)
    if not player then return false end

    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()

    if isTwoHandedMelee(primary) and secondary ~= primary then
        return true
    end
    if isTwoHandedMelee(secondary) and primary ~= secondary then
        return true
    end
    return false
end

local function enforceTwoHandedMelee(player)
    if not player then return false end

    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()

    if isTwoHandedMelee(primary) then
        if secondary ~= primary then
            player:setSecondaryHandItem(primary)
            player:setUseHandWeapon(primary)
            return true
        end
        return false
    end

    if isTwoHandedMelee(secondary) then
        if primary ~= secondary then
            player:setPrimaryHandItem(secondary)
            player:setUseHandWeapon(secondary)
            return true
        end
    end

    return false
end

local function getDualWeapons(player)
    if not player or player:isDead() then return nil, nil end

    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()

    if not isValidOneHandedMelee(primary) then return nil, nil end
    if not isValidOneHandedMelee(secondary) then return nil, nil end
    if primary == secondary then return nil, nil end

    return primary, secondary
end

local function isAttackButtonHeld(player)
    local playerIndex = player:getIndex()

    -- Mouse/keyboard: only LMB. Space/melee remains completely vanilla.
    if playerIndex == 0 and wasMouseActiveMoreRecentlyThanJoypad() then
        return isMouseButtonDown(0)
    end

    -- Joypad: RT is attack; LT/melee remains vanilla shove behavior.
    return isJoypadRTPressed(playerIndex)
end

local function wantsVanillaMeleeAction(player)
    -- Do not chain over shove/grapple controls. These are intentionally left
    -- to the base game rather than being consumed by the dual-wield loop.
    if player:isMeleePressed() then return true end
    if player:isGrapplePressed() then return true end
    return false
end

-- A zombie hit/bite can kick the player out of SwipeStatePlayer without the
-- normal OnPlayerAttackFinished callback.  getHitReaction() is inherited from
-- IsoGameCharacter and is the cleanest signal that vanilla has interrupted the
-- attack.  Never keep our input lock or temporary hand/body swap through that
-- reaction.
local function hasActiveHitReaction(player)
    local ok, reaction = pcall(function() return player:getHitReaction() end)
    return ok and reaction ~= nil and tostring(reaction) ~= ""
end

local function isStabWeapon(weapon)
    local swingAnim = weapon and weapon:getSwingAnim()
    return swingAnim and string.lower(tostring(swingAnim)) == "stab"
end

-- Vanilla calculateCombatSpeed() is hard-wired to Hand_R / ForeArm_R /
-- UpperArm_R. During the synchronous off-hand attack setup, temporarily swap
-- the BodyDamage list entries so vanilla reads the real left-arm wounds, pain
-- and muscle stiffness without us reimplementing any injury formula. The list is
-- restored immediately after pressedAttack() returns, before the attack anim runs.
local ARM_SLOT_PAIRS = {
    { BodyPartType.Hand_R, BodyPartType.Hand_L },
    { BodyPartType.ForeArm_R, BodyPartType.ForeArm_L },
    { BodyPartType.UpperArm_R, BodyPartType.UpperArm_L },
}

local function swapArmBodyPartSlots(player)
    local damage = player:getBodyDamage()
    if not damage then return nil end

    local parts = damage:getBodyParts()
    if not parts then return nil end

    local saved = {}
    for i, pair in ipairs(ARM_SLOT_PAIRS) do
        local rightIndex = BodyPartType.ToIndex(pair[1])
        local leftIndex = BodyPartType.ToIndex(pair[2])
        local rightPart = parts:get(rightIndex)
        local leftPart = parts:get(leftIndex)
        saved[i] = { rightIndex, leftIndex, rightPart, leftPart }
        parts:set(rightIndex, leftPart)
        parts:set(leftIndex, rightPart)
    end
    return saved
end

local function restoreArmBodyPartSlots(player, saved)
    if not saved then return end
    local damage = player:getBodyDamage()
    if not damage then return end
    local parts = damage:getBodyParts()
    if not parts then return end

    for _, entry in ipairs(saved) do
        parts:set(entry[1], entry[3])
        parts:set(entry[2], entry[4])
    end
end

local function restorePendingArmSlotSwap(player, s)
    if not s or not s.armSlotsSaved then return end
    restoreArmBodyPartSlots(player, s.armSlotsSaved)
    s.armSlotsSaved = nil
    s.armSwapAge = 0
end

-- Build 42.20.2 exposes AttackVars/CloseKillMove to Lua as Java userdata in this
-- runtime. Direct field reads/writes (even inside pcall) generate engine ERRORs.
-- Fix 3.5 deliberately does not touch those userdata fields. Stability of the
-- real off-hand SwipeStatePlayer attack takes priority over forced finisher suppression.
local function suppressOffhandCloseKill(player, s, weapon)
    -- Intentionally empty: no Java userdata field mutation.
end

local function restoreOffhandCloseKill(s)
    -- Intentionally empty: nothing was mutated.
end

local function pressedAttackUsingLeftArm(player, s)
    -- Keep the left-arm substitution alive until OnWeaponSwing. In B42.20.2
    -- combat speed/weapon setup can finish after pressedAttack() has returned.
    -- Restoring immediately here made off-hand attacks ignore left-arm injuries.
    restorePendingArmSlotSwap(player, s)
    s.armSlotsSaved = swapArmBodyPartSlots(player)
    s.armSwapAge = 0

    local ok, err = pcall(function()
        player:pressedAttack()
    end)

    if not ok then
        restorePendingArmSlotSwap(player, s)
        print("[RealisticCombat] off-hand pressedAttack failed: " .. tostring(err))
        return false
    end
    return true
end

local function restoreHands(player, s)
    if not s.primary or not s.secondary then return false end

    local currentPrimary = player:getPrimaryHandItem()
    local currentSecondary = player:getSecondaryHandItem()

    -- Fancy Handwork and other equipment UI mods deliberately preserve the
    -- secondary hand. Never overwrite an external equip/unequip that happened
    -- while our tiny attack-only swap was active. We restore only if the hands
    -- are still exactly the pair that Realistic Combat itself swapped.
    if currentPrimary == s.primary and currentSecondary == s.secondary then
        s.handSwapOwned = false
        return true
    end
    if not s.handSwapOwned then return false end
    if currentPrimary ~= s.secondary or currentSecondary ~= s.primary then
        s.handSwapOwned = false
        return false
    end

    player:setPrimaryHandItem(s.primary)
    player:setSecondaryHandItem(s.secondary)
    s.handSwapOwned = false
    return true
end

local function cancelOffhandLaunch(player, s)
    restoreOffhandCloseKill(s)
    restorePendingArmSlotSwap(player, s)
    restoreHands(player, s)
    releaseMeleeInput(player, s)
    local currentPrimary = player:getPrimaryHandItem()
    if currentPrimary and instanceof(currentPrimary, "HandWeapon") then
        player:setUseHandWeapon(currentPrimary)
    end
    player:setInitiateAttack(false)
    player:setAttackStarted(false)
    -- Do not index/call AttackVars.clear here. In B42.20.2 getAttackVars()
    -- is Java userdata and the old :clear() access throws before Lua can guard it.
    clearAnimFlags(player)

    s.phase = nil
    s.swapPending = false
    s.primary = nil
    s.secondary = nil
    s.offhandWeapon = nil
    s.armSlotsSaved = nil
    s.nextPhase = nil
    s.launchPending = false
    s.launchDelay = 0
    s.handSwapOwned = false
end

local function startOffhandAttack(player)
    local primary, secondary = getDualWeapons(player)
    if not primary then return false end
    if player:isAimAtFloor() or player:isDoShove() or player:isDoStomp() then return false end
    if wantsVanillaMeleeAction(player) then return false end

    local s = stateFor(player)
    s.phase = "offhand"
    s.swapPending = true
    s.primary = primary
    s.secondary = secondary
    s.offhandWeapon = secondary

    player:setVariable("DWL_Offhand", true)
    player:setVariable("DWL_OffhandStab", isStabWeapon(secondary))

    -- Keep the swap alive through pressedAttack() AND SwipeStatePlayer:enter().
    -- Both WeaponType/calculateCombatSpeed and SwipeStatePlayer.doAttack read the
    -- primary hand. OnWeaponSwing fires from SwipeStatePlayer:enter after that
    -- setup is complete; we restore the visible hand assignment there.
    player:setPrimaryHandItem(secondary)
    player:setSecondaryHandItem(primary)
    s.handSwapOwned = true

    -- Fix 3.5: do not mutate CloseKillMove/AttackVars here. Those are Java userdata
    -- in B42.20.2 and were the direct source of the repeated second-hand ERRORs.
    suppressOffhandCloseKill(player, s, secondary)

    -- Let vanilla calculate the off-hand attack with the left arm's actual
    -- wounds/pain/stiffness substituted into its hard-coded attack-arm slots.
    if not pressedAttackUsingLeftArm(player, s) then
        cancelOffhandLaunch(player, s)
        return false
    end

    -- pressedAttack can reject an attack (state, weapon readiness, etc.).
    if not player:isAttackStarted() then
        cancelOffhandLaunch(player, s)
        return false
    end

    -- Dual-wield floor attacks are deliberately not generated. Leave prone
    -- attacks/stomps to vanilla input rather than forcing a left-hand floor hit.
    if player:isAimAtFloor() or player:isDoShove() or player:isDoGrapple() then
        cancelOffhandLaunch(player, s)
        return false
    end

    return true
end

local function startMainAttack(player)
    local primary, secondary = getDualWeapons(player)
    if not primary then return false end
    if player:isAimAtFloor() or player:isDoShove() or player:isDoStomp() then return false end
    if wantsVanillaMeleeAction(player) then return false end

    local s = stateFor(player)
    s.phase = "main"
    s.primary = primary
    s.secondary = secondary
    s.offhandWeapon = nil
    s.swapPending = false

    clearAnimFlags(player)
    player:setUseHandWeapon(primary)
    player:pressedAttack()

    if not player:isAttackStarted() then
        s.phase = nil
        return false
    end

    return true
end

local function onWeaponSwing(attacker, weapon)
    if not instanceof(attacker, "IsoPlayer") then return end

    local s = stateFor(attacker)

    -- This is the exact point we were waiting for: SwipeStatePlayer.doAttack()
    -- has already selected the temporarily-swapped off-hand weapon. Restore the
    -- player's actual hand layout before the attack animation is rendered, then
    -- keep useHandWeapon pinned to the off-hand weapon for sound/collision/hit.
    if s.phase == "offhand" and s.swapPending and weapon == s.offhandWeapon then
        -- At this point SwipeStatePlayer has already selected/calculated the
        -- off-hand attack. Restore the real body-part layout before normal UI
        -- and damage updates continue.
        restorePendingArmSlotSwap(attacker, s)
        restoreHands(attacker, s)
        attacker:setUseHandWeapon(s.offhandWeapon)
        attacker:setVariable("DWL_Offhand", true)
        attacker:setVariable("DWL_OffhandStab", isStabWeapon(s.offhandWeapon))
        s.swapPending = false
    end
end

local function bodyPartStiffness(player, partType)
    local damage = player:getBodyDamage()
    if not damage then return 0 end
    local part = damage:getBodyPart(partType)
    if not part then return 0 end
    return part:getStiffness()
end

local function snapshotRightArmStrain(player, s)
    s.strainBefore = {
        hand = bodyPartStiffness(player, BodyPartType.Hand_R),
        forearm = bodyPartStiffness(player, BodyPartType.ForeArm_R),
        upperarm = bodyPartStiffness(player, BodyPartType.UpperArm_R),
    }
    s.strainTransferPending = true
    s.strainTransferDelay = 1
end

local function transferOnePart(player, rightType, leftType, before)
    local damage = player:getBodyDamage()
    if not damage then return 0 end

    local right = damage:getBodyPart(rightType)
    local left = damage:getBodyPart(leftType)
    if not right or not left then return 0 end

    local currentRight = right:getStiffness()
    local delta = currentRight - before
    if delta <= 0 then return 0 end

    -- Vanilla B42.20.2 adds melee strain to the right arm. For a confirmed
    -- off-hand collision, move exactly the stiffness vanilla just added to the
    -- corresponding left-arm body part; no custom strain amount is invented.
    right:setStiffness(math.max(0, currentRight - delta))
    left:setStiffness(math.min(100, left:getStiffness() + delta))
    return delta
end

local function transferVanillaStrainToLeft(player, s)
    if not s.strainBefore then return end

    local moved = 0
    moved = moved + transferOnePart(player, BodyPartType.Hand_R, BodyPartType.Hand_L, s.strainBefore.hand)
    moved = moved + transferOnePart(player, BodyPartType.ForeArm_R, BodyPartType.ForeArm_L, s.strainBefore.forearm)
    moved = moved + transferOnePart(player, BodyPartType.UpperArm_R, BodyPartType.UpperArm_L, s.strainBefore.upperarm)


    s.strainBefore = nil
    s.strainTransferPending = false
    s.strainTransferDelay = 0
end

local function onWeaponSwingHitPoint(attacker, weapon)
    if not instanceof(attacker, "IsoPlayer") then return end

    local s = stateFor(attacker)
    s.lastWasShove = attacker:isDoShove() or (weapon and weapon:getType() == "BareHands")
    s.lastWasGround = attacker:isAimAtFloor() or attacker:isShoveStompAnim() or attacker:isDoStomp()

    if s.phase == "offhand" and weapon == s.offhandWeapon then
        -- CombatManager applies its normal endurance + combat muscle strain just
        -- after this Lua event returns. Snapshot now, transfer that exact resulting
        -- stiffness to the left arm on the following player update.
        snapshotRightArmStrain(attacker, s)
    end
end

local function resetState(player, s)
    restoreOffhandCloseKill(s)
    restorePendingArmSlotSwap(player, s)
    if s.swapPending then
        restoreHands(player, s)
    end
    releaseMeleeInput(player, s)
    clearAnimFlags(player)
    if player:getPrimaryHandItem() and instanceof(player:getPrimaryHandItem(), "HandWeapon") then
        player:setUseHandWeapon(player:getPrimaryHandItem())
    end

    s.phase = nil
    s.swapPending = false
    s.primary = nil
    s.secondary = nil
    s.offhandWeapon = nil
    s.armSlotsSaved = nil
    s.armSwapAge = 0
    s.lastWasShove = false
    s.lastWasGround = false
    s.nextPhase = nil
    s.launchPending = false
    s.launchDelay = 0
    s.handSwapOwned = false
end

local function onPlayerAttackFinished(player, weapon)
    if not instanceof(player, "IsoPlayer") then return end
    local s = stateFor(player)

    -- Fix 3.5 compatibility hook; currently no Java userdata is mutated.
    restoreOffhandCloseKill(s)

    -- SwipeStatePlayer fires this event before the character has fully returned
    -- to weapon-ready. Fix 2 also takes ownership of input-driven melee here:
    -- the physical held-attack input is temporarily unauthorized, while our
    -- direct pressedAttack() calls remain vanilla CombatManager attacks. This
    -- prevents the base game's right-hand auto-repeat from starving the off-hand.
    local canContinue = isAttackButtonHeld(player)
        and not s.lastWasShove
        and not s.lastWasGround
        and not wantsVanillaMeleeAction(player)

    s.lastWasShove = false
    s.lastWasGround = false

    if not canContinue then
        resetState(player, s)
        return
    end

    local primary, secondary = getDualWeapons(player)
    if not primary then
        resetState(player, s)
        return
    end

    takeOverMeleeInput(player, s)

    if s.phase == "offhand" then
        s.nextPhase = "main"
    else
        s.nextPhase = "offhand"
    end
    s.launchPending = true
    s.launchDelay = 1
end

local function onPlayerUpdate(player)
    if not player then return end

    local s = states[player:getIndex()]

    if hasTwoHandedConflict(player) then
        if s then
            resetState(player, s)
        end
        enforceTwoHandedMelee(player)
        return
    end

    if not s then
        enforceTwoHandedMelee(player)
        return
    end
    if player:isDead() then
        resetState(player, s)
        return
    end

    -- Injury/hit-reaction watchdog: if vanilla interrupts either hand while
    -- Realistic Combat owns melee input, immediately give control back.  This
    -- specifically prevents the "left arm bitten -> neither hand can attack"
    -- deadlock even if isAttackStarted() has not been cleared yet by Java state.
    if (s.ownsMeleeInput or s.swapPending or s.armSlotsSaved) and hasActiveHitReaction(player) then
        resetState(player, s)
        return
    end

    if s.strainTransferPending then
        if s.strainTransferDelay > 0 then
            s.strainTransferDelay = s.strainTransferDelay - 1
        else
            transferVanillaStrainToLeft(player, s)
        end
    end

    -- The left/right BodyDamage substitution is supposed to live only until
    -- OnWeaponSwing in the same attack setup. If the player is bitten/hit and
    -- SwipeStatePlayer is interrupted before that event, never leave the body
    -- part list swapped indefinitely. Two player-update frames are a generous
    -- fail-safe window; normal attacks restore it earlier in onWeaponSwing().
    if s.armSlotsSaved then
        s.armSwapAge = (s.armSwapAge or 0) + 1
        if s.armSwapAge > 2 then
            restorePendingArmSlotSwap(player, s)
        end
    end

    -- Fix 3.8: setAuthorizeMeleeAction(false) is owned by Realistic Combat only
    -- while it is waiting to continue an alternating chain. A hit reaction can
    -- interrupt the attack without firing OnPlayerAttackFinished. In Fix 3.7
    -- that left ownsMeleeInput=true with launchPending=false forever, so BOTH
    -- hands stopped attacking even after the off-hand weapon was removed.
    -- Recover that orphaned ownership as soon as the current attack is no longer
    -- active. Also recover immediately if the dual-wield pair ceased to exist.
    if s.ownsMeleeInput and not player:isAttackStarted() and not s.swapPending then
        local watchdogPrimary = getDualWeapons(player)
        local chainOrphaned = not s.launchPending
        local pairGone = watchdogPrimary == nil
        local inputReleased = not isAttackButtonHeld(player)
        if chainOrphaned or pairGone or inputReleased or wantsVanillaMeleeAction(player) then
            resetState(player, s)
            return
        end
    end

    -- Safety recovery if an off-hand setup was interrupted after the temporary
    -- hand swap but before OnWeaponSwing restored the visible hand layout.
    if s.swapPending and not player:isAttackStarted() and not s.launchPending then
        resetState(player, s)
        return
    end

    if not s.launchPending then return end

    if not isAttackButtonHeld(player) or wantsVanillaMeleeAction(player) then
        resetState(player, s)
        return
    end

    local primary, secondary = getDualWeapons(player)
    if not primary then
        resetState(player, s)
        return
    end

    -- Let SwipeStatePlayer finish its state transition first. CombatManager's
    -- pressedAttack() explicitly rejects a normal melee attack while WeaponReady
    -- is false, which is the race that made the previous build stop after hand 1.
    if player:isAttackStarted() or not player:isWeaponReady() then return end

    if s.launchDelay > 0 then
        s.launchDelay = s.launchDelay - 1
        return
    end

    local nextPhase = s.nextPhase
    s.launchPending = false
    s.nextPhase = nil

    local started = false
    if nextPhase == "offhand" then
        started = startOffhandAttack(player)
    else
        clearAnimFlags(player)
        player:setUseHandWeapon(primary)
        started = startMainAttack(player)
    end

    if not started then
        resetState(player, s)
    end
end

local function onCreatePlayer(playerIndex, player)
    states[playerIndex] = nil
    clearAnimFlags(player)
    player:setAuthorizeMeleeAction(true)
    enforceTwoHandedMelee(player)
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnWeaponSwing.Add(onWeaponSwing)
Events.OnWeaponSwingHitPoint.Add(onWeaponSwingHitPoint)
Events.OnPlayerAttackFinished.Add(onPlayerAttackFinished)
Events.OnPlayerUpdate.Add(onPlayerUpdate)

print("[RealisticCombat] Fix 3.8 loaded - injury interruption watchdog + Fancy Handwork-safe restore")
