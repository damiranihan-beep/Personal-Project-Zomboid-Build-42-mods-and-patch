-- Dual Wielding Lite - Build 42.20.2
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
        }
        states[idx] = s
    end
    return s
end

local function clearAnimFlags(player)
    player:setVariable("DWL_Offhand", false)
    player:setVariable("DWL_OffhandStab", false)
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
    if not damage then return end

    local right = damage:getBodyPart(rightType)
    local left = damage:getBodyPart(leftType)
    if not right or not left then return end

    local currentRight = right:getStiffness()
    local delta = currentRight - before
    if delta <= 0 then return end

    -- Vanilla B42 assumes melee always originates from the primary/right arm.
    -- Our collision is otherwise fully vanilla, so move only the stiffness it
    -- just added to the actual off-hand/left arm. No custom strain amount exists.
    right:setStiffness(math.max(0, currentRight - delta))
    left:setStiffness(math.min(100, left:getStiffness() + delta))
end

local function transferVanillaStrainToLeft(player, s)
    if not s.strainBefore then return end

    transferOnePart(player, BodyPartType.Hand_R, BodyPartType.Hand_L, s.strainBefore.hand)
    transferOnePart(player, BodyPartType.ForeArm_R, BodyPartType.ForeArm_L, s.strainBefore.forearm)
    transferOnePart(player, BodyPartType.UpperArm_R, BodyPartType.UpperArm_L, s.strainBefore.upperarm)

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
end

local function onPlayerAttackFinished(player, weapon)
    if not instanceof(player, "IsoPlayer") then return end
    local s = stateFor(player)

    -- If the attack button was released, or vanilla shove/stomp/grapple input is
    -- taking over, stop the chain immediately. Normal next clicks remain vanilla.
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

    -- AttackStarted is cleared by SwipeStatePlayer immediately before this event,
    -- so starting the next swing here prevents the held-input path from also
    -- creating a duplicate attack later in the same frame.
    if s.phase == "offhand" then
        clearAnimFlags(player)
        player:setUseHandWeapon(primary)
        startMainAttack(player)
    else
        startOffhandAttack(player)
    end
end

local function onPlayerUpdate(player)
    if not player or player:isDead() then return end
    local s = states[player:getIndex()]
    if not s then return end

    if s.strainTransferPending then
        if s.strainTransferDelay > 0 then
            s.strainTransferDelay = s.strainTransferDelay - 1
        else
            transferVanillaStrainToLeft(player, s)
        end
    end

    -- Safety recovery if an attack is interrupted after the temporary swap but
    -- before OnWeaponSwing can restore it (hit reaction, state cancellation, etc.).
    if s.swapPending and not player:isAttackStarted() then
        resetState(player, s)
    end
end

local function onCreatePlayer(playerIndex, player)
    states[playerIndex] = nil
    clearAnimFlags(player)
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnWeaponSwing.Add(onWeaponSwing)
Events.OnWeaponSwingHitPoint.Add(onWeaponSwingHitPoint)
Events.OnPlayerAttackFinished.Add(onPlayerAttackFinished)
Events.OnPlayerUpdate.Add(onPlayerUpdate)
