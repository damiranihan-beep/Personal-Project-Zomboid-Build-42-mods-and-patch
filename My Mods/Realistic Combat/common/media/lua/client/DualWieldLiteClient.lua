-- Realistic Combat - Fix 2 - Build 42.20.2
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
            nextPhase = nil,
            launchPending = false,
            launchDelay = 0,
            ownsMeleeInput = false,
            debugOffhandStarts = 0,
            debugStrainTransfers = 0,
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

local function pressedAttackUsingLeftArm(player)
    local saved = swapArmBodyPartSlots(player)
    local ok, err = pcall(function()
        player:pressedAttack()
    end)
    restoreArmBodyPartSlots(player, saved)

    if not ok then
        print("[DualWieldingLite] off-hand pressedAttack failed: " .. tostring(err))
        return false
    end
    return true
end

local function restoreHands(player, s)
    if not s.primary or not s.secondary then return end

    if player:getPrimaryHandItem() ~= s.primary then
        player:setPrimaryHandItem(s.primary)
    end
    if player:getSecondaryHandItem() ~= s.secondary then
        player:setSecondaryHandItem(s.secondary)
    end
end

local function cancelOffhandLaunch(player, s)
    restoreHands(player, s)
    releaseMeleeInput(player, s)
    player:setUseHandWeapon(s.primary)
    player:setInitiateAttack(false)
    player:setAttackStarted(false)
    player:getAttackVars():clear()
    clearAnimFlags(player)

    s.phase = nil
    s.swapPending = false
    s.primary = nil
    s.secondary = nil
    s.offhandWeapon = nil
    s.nextPhase = nil
    s.launchPending = false
    s.launchDelay = 0
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

    -- Let vanilla calculate the off-hand attack with the left arm's actual
    -- wounds/pain/stiffness substituted into its hard-coded attack-arm slots.
    if not pressedAttackUsingLeftArm(player) then
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

    if s.debugOffhandStarts < 3 then
        s.debugOffhandStarts = s.debugOffhandStarts + 1
        print("[RealisticCombat] off-hand vanilla attack started: " .. tostring(secondary:getFullType()))
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

    if moved > 0 and s.debugStrainTransfers < 3 then
        s.debugStrainTransfers = s.debugStrainTransfers + 1
        print("[RealisticCombat] moved vanilla off-hand muscle strain to left arm: " .. tostring(moved))
    end

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
    s.lastWasShove = false
    s.lastWasGround = false
    s.nextPhase = nil
    s.launchPending = false
    s.launchDelay = 0
end

local function onPlayerAttackFinished(player, weapon)
    if not instanceof(player, "IsoPlayer") then return end
    local s = stateFor(player)

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
    if not s then return end
    if player:isDead() then
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
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnWeaponSwing.Add(onWeaponSwing)
Events.OnWeaponSwingHitPoint.Add(onWeaponSwingHitPoint)
Events.OnPlayerAttackFinished.Add(onPlayerAttackFinished)
Events.OnPlayerUpdate.Add(onPlayerUpdate)

print("[RealisticCombat] Fix 2 loaded - owned vanilla alternating attack chain")
