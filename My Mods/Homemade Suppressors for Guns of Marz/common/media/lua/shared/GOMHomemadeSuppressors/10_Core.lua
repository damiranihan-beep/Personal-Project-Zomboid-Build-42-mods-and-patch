-- GOM Homemade Suppressors Fix 3.14 - B42.20.2
GOMHomemade = GOMHomemade or {}
local okAnim, Animations = pcall(require, "WeaponSystems/Utils/Animations")
local okSF, StatsFactory = pcall(require, "WeaponSystems/Utils/StatsFactory")
local okROF, RateOfFire = pcall(require, "WeaponSystems/Utils/RateOfFire")
pcall(require, "TimedActions/ISReloadWeaponAction")
local RNG = newrandom()

local CFG = {
    plastic={baseType="HomemadeSuppressors.HomemadePlasticSuppressor",criticalType="HomemadeSuppressors.HomemadePlasticSuppressor_Critical",brokenType="HomemadeSuppressors.HomemadePlasticSuppressor_Broken",req=1,min=10,max=30,bonus=1,autoDrop=true},
    can={baseType="HomemadeSuppressors.HomemadeCanSuppressor",criticalType="HomemadeSuppressors.HomemadeCanSuppressor_Critical",brokenType="HomemadeSuppressors.HomemadeCanSuppressor_Broken",req=3,min=40,max=80,bonus=2,autoDrop=false},
    pipe={baseType="HomemadeSuppressors.HomemadePipeSuppressor",criticalType="HomemadeSuppressors.HomemadePipeSuppressor_Critical",brokenType="HomemadeSuppressors.HomemadePipeSuppressor_Broken",req=5,min=90,max=160,bonus=3,autoDrop=false},
}
local TYPE_STATE={}
for kind,c in pairs(CFG) do
    TYPE_STATE[c.baseType]={kind=kind,state="working"}
    TYPE_STATE[c.criticalType]={kind=kind,state="critical"}
    TYPE_STATE[c.brokenType]={kind=kind,state="broken"}
end

-- Compatibility with items created by the older integrated GoM patch.
-- Keeping these IDs recognized means an existing save does not need a new world
-- only because the standalone mod moved the items to HomemadeSuppressors.*.
local LEGACY = {
    plastic={baseType="MarzGuns.HomemadePlasticSuppressor",criticalType="MarzGuns.HomemadePlasticSuppressor_Critical",brokenType="MarzGuns.HomemadePlasticSuppressor_Broken"},
    can={baseType="MarzGuns.HomemadeCanSuppressor",criticalType="MarzGuns.HomemadeCanSuppressor_Critical",brokenType="MarzGuns.HomemadeCanSuppressor_Broken"},
    pipe={baseType="MarzGuns.HomemadePipeSuppressor",criticalType="MarzGuns.HomemadePipeSuppressor_Critical",brokenType="MarzGuns.HomemadePipeSuppressor_Broken"},
}
for kind,c in pairs(LEGACY) do
    TYPE_STATE[c.baseType]={kind=kind,state="working",legacy=true}
    TYPE_STATE[c.criticalType]={kind=kind,state="critical",legacy=true}
    TYPE_STATE[c.brokenType]={kind=kind,state="broken",legacy=true}
end

local function sync(player,weapon)
    -- Direct detach/attach calls do not reliably re-run Gunworks custom-stat
    -- layers. Reapply them after every suppressor state swap so the critical
    -- shot really uses its louder 20-percentage-point-worse suppression and
    -- a detached/broken suppressor cannot leave stale stats on the gun.
    if weapon and okSF and StatsFactory and StatsFactory.ReapplyAllModifiers then
        pcall(StatsFactory.ReapplyAllModifiers, weapon)
    end
    if okAnim and Animations and Animations.CallSyncHandWeaponFields then
        pcall(Animations.CallSyncHandWeaponFields,player,weapon)
    end
end
local function resolvePlayer(...)
    local a={...}
    for i=1,#a do
        local v=a[i]
        if v and instanceof and instanceof(v,"IsoGameCharacter") then return v end
    end
    return getPlayer and getPlayer() or nil
end
local function range(player,cfg)
    local lvl=cfg.req
    if player and Perks and Perks.Maintenance then lvl=player:getPerkLevel(Perks.Maintenance) end
    local add=math.max(0,lvl-cfg.req)*cfg.bonus
    return cfg.min+add,cfg.max+add,lvl
end
local function initPart(part,player,cfg)
    if not part then return end
    local md=part:getModData()
    if md.GOMHSInitialized then return end
    local lo,hi,lvl=range(player,cfg)
    local rolled=lo
    if hi>lo then rolled=lo+RNG:random(hi-lo+1) end
    part:setConditionMax(rolled); part:setCondition(rolled); part:setBroken(false)
    md.GOMHSInitialized=true; md.GOMHSCraftMaintenance=lvl; md.GOMHSRolledCondition=rolled
end
local function findCreated(data,fullType)
    if not data then return nil end
    local ok,items=pcall(function() return data:getAllCreatedItems() end)
    if ok and items then
        for i=0,items:size()-1 do
            local it=items:get(i)
            if it and it:getFullType()==fullType then return it end
        end
    end
    return nil
end
local function onCreate(kind,...)
    local cfg=CFG[kind]; local a={...}; local result=findCreated(a[1],cfg.baseType)
    if not result then
        for i=1,#a do
            local v=a[i]
            if v and instanceof and instanceof(v,"InventoryItem") and v:getFullType()==cfg.baseType then result=v; break end
        end
    end
    if result then initPart(result,resolvePlayer(...),cfg) end
end
function GOMHomemade.OnCreatePlastic(...) onCreate("plastic",...) end
function GOMHomemade.OnCreateCan(...) onCreate("can",...) end
function GOMHomemade.OnCreatePipe(...) onCreate("pipe",...) end

local function copyState(oldPart,newPart)
    newPart:setConditionMax(oldPart:getConditionMax()); newPart:setCondition(oldPart:getCondition())
    local a,b=oldPart:getModData(),newPart:getModData()
    b.GOMHSInitialized=true; b.GOMHSCraftMaintenance=a.GOMHSCraftMaintenance; b.GOMHSRolledCondition=a.GOMHSRolledCondition or oldPart:getConditionMax()
end
local function swap(player,weapon,oldPart,newType,newCondition,broken)
    if not player or not weapon or not oldPart then return nil end
    local np=instanceItem(newType); if not np then return nil end
    copyState(oldPart,np); if newCondition~=nil then np:setCondition(newCondition) end; if broken then np:setBroken(true) end
    weapon:detachWeaponPart(oldPart); weapon:attachWeaponPart(np); sync(player,weapon); return np
end
local function dropBrokenPlastic(player,weapon,part,cfg)
    local maxc=part:getConditionMax()
    weapon:detachWeaponPart(part)

    local b=instanceItem(cfg.brokenType)
    if not b then
        print("[GOM HS] ERROR: could not create broken plastic suppressor item")
        sync(player,weapon)
        return
    end

    b:setConditionMax(maxc)
    b:setCondition(0)
    b:setBroken(true)
    local md=b:getModData()
    md.GOMHSInitialized=true
    md.GOMHSRolledCondition=maxc

    -- Drop on the PLAYER'S CURRENT SQUARE, not the square in front.
    -- The previous front-square placement could make the item look as if it
    -- simply vanished. Use the explicit transmit overload and verify success.
    local sq=player:getCurrentSquare()
    local placed=nil
    if sq then
        local ok, result = pcall(function()
            return sq:AddWorldInventoryItem(b,0.50,0.50,0.05,true)
        end)
        if ok then placed=result end
    end

    if placed then
        print("[GOM HS] broken plastic suppressor dropped on current square")
    else
        -- Never delete the broken suppressor. If world placement fails for any
        -- reason, return it to player inventory as a guaranteed fallback.
        player:getInventory():AddItem(b)
        print("[GOM HS] WARNING: floor drop failed; broken plastic suppressor returned to inventory")
    end

    sync(player,weapon)
end

local function getCanon(weapon)
    if not weapon then return nil end

    -- MarzGuns Sound Overhaul uses getCanon(); prefer the same API so both mods
    -- resolve the exact same muzzle attachment. Keep getWeaponPart("Canon") as
    -- a Build-42/Gunworks-compatible fallback.
    if weapon.getCanon then
        local ok, part = pcall(weapon.getCanon, weapon)
        if ok and part then return part end
    end
    if weapon.getWeaponPart then
        local ok, part = pcall(weapon.getWeaponPart, weapon, "Canon")
        if ok then return part end
    end
    return nil
end

-- Keep the audible report suppressed for BOTH working and critical/last-shot
-- states. Fix 3.8 only enforced the sound for "working", so the final shot could
-- suddenly use the gun's normal report even though gameplay suppression remained.
local function enforceAttachmentSound(weapon)
    if not weapon or not instanceof(weapon,"HandWeapon") or not weapon:isRanged() then return end
    local part=getCanon(weapon); if not part then return end
    local info=TYPE_STATE[part:getFullType()]
    if not info or not weapon.setSwingSound then return end

    if info.state=="working" or info.state=="critical" then
        if GOMHomemade.ApplySuppressedSwingSound then
            GOMHomemade.ApplySuppressedSwingSound(weapon)
        else
            weapon:setSwingSound("CapGunRifleShoot")
        end
    elseif info.state=="broken" and (info.kind=="can" or info.kind=="pipe") then
        -- MarzGuns Sound Overhaul treats any Canon item whose type contains
        -- "Suppressor" as live, including our broken metal shells. Force the
        -- native weapon report back while the broken can/pipe remains mounted.
        if GOMHomemade.ApplyBrokenSwingSound then
            GOMHomemade.ApplyBrokenSwingSound(weapon)
        end
    end
end

local function onWeaponSwingAudio(attacker,weapon)
    enforceAttachmentSound(weapon)
end
Events.OnWeaponSwing.Add(onWeaponSwingAudio)

local function enforcePlayerWeaponSound(player)
    if not player then return end
    local held=player:getPrimaryHandItem()
    if held and instanceof(held,"HandWeapon") then enforceAttachmentSound(held) end
end
local function onEquipPrimarySound(player)
    enforcePlayerWeaponSound(player)
end
Events.OnEquipPrimary.Add(onEquipPrimarySound)

-- MarzGuns Sound Overhaul itself rewrites SwingSound from OnPlayerUpdate.
-- This mod loads after it. The single periodic OnPlayerUpdate handler below
-- reasserts sound every update and performs slower maintenance work every 60
-- updates, avoiding several competing per-frame handlers.

-- Gunworks RealBurst schedules follow-up rounds through RateOfFire.startBurst
-- and calls a captured attackHook directly from OnTick. Those follow-up rounds
-- can bypass normal hook timing. Guard the captured hook so every scheduled
-- burst round gets the correct sound immediately before the engine fires it.
local function installBurstSoundGuard()
    if not okROF or not RateOfFire or type(RateOfFire.startBurst) ~= "function" then return end
    if GOMHomemade._burstSoundGuardInstalled then return end
    GOMHomemade._burstSoundGuardInstalled=true
    local originalStartBurst=RateOfFire.startBurst
    RateOfFire.startBurst=function(player,weapon,intervalMs,attackHook,chargeDelta)
        local guardedHook=attackHook
        if type(attackHook)=="function" then
            guardedHook=function(p,cd,w)
                enforceAttachmentSound(w)
                return attackHook(p,cd,w)
            end
        end
        enforceAttachmentSound(weapon)
        return originalStartBurst(player,weapon,intervalMs,guardedHook,chargeDelta)
    end
    print("[GOM HS] Fix 3.16 Gunworks burst sound guard installed")
end
installBurstSoundGuard()

-- RealAuto and the FIRST round of RealBurst still travel through Hook.Attack.
-- Install this after Gunworks' own OnGameStart hook replacement, so the sound
-- state is fixed at the last possible Lua point immediately before the shot.
local function installAttackSoundGuard()
    if not Hook or not Hook.Attack or not ISReloadWeaponAction then return end
    local target=ISReloadWeaponAction.RAFattackHook or ISReloadWeaponAction.attackHook
    if type(target)~="function" then return end
    if GOMHomemade._attackSoundGuardInstalled then return end

    local guarded=function(character,chargeDelta,weapon)
        enforceAttachmentSound(weapon)
        return target(character,chargeDelta,weapon)
    end

    local okRemove=pcall(function() Hook.Attack.Remove(target) end)
    local okAdd=pcall(function() Hook.Attack.Add(guarded) end)
    if okAdd then
        GOMHomemade._attackSoundGuardInstalled=true
        GOMHomemade._attackSoundGuard=guarded
        print("[GOM HS] Fix 3.16 global attack sound guard installed")
    elseif okRemove then
        -- Defensive fallback: never leave the attack hook removed if adding our
        -- wrapper unexpectedly fails on another Gunworks build.
        pcall(function() Hook.Attack.Add(target) end)
    end
end
Events.OnGameStart.Add(installAttackSoundGuard)

local function playCriticalFailureWhistle(player)
    if not player or not player.playSound then return end
    pcall(function() player:playSound("GOMHS_SuppressorFailureWhistle") end)
end

local function playBrokenMetalWhistle(player)
    if not player or not player.playSound then return end
    pcall(function() player:playSound("GOMHS_SuppressorBrokenWhistle") end)
end

local function processShot(player,weapon)
    enforceAttachmentSound(weapon)
    if not player or not weapon or not instanceof(weapon,"HandWeapon") or not weapon:isRanged() then return end
    local part=getCanon(weapon); if not part then return end
    local info=TYPE_STATE[part:getFullType()]; if not info then return end
    if info.state=="broken" then
        if info.kind=="can" or info.kind=="pipe" then
            -- Permanent penalty while the broken metal suppressor is still mounted:
            -- native/louder weapon report from stats + a stronger whistle on EVERY shot.
            enforceAttachmentSound(weapon)
            playBrokenMetalWhistle(player)
        end
        return
    end
    local cfg=CFG[info.kind]; initPart(part,player,cfg)
    if info.state=="critical" or part:getCondition()<=1 then
        -- Audible cue on the actual final shot. Gameplay noise/radius is also
        -- already 20 percentage points less suppressed in the critical state.
        playCriticalFailureWhistle(player)
        part:setCondition(0); part:setBroken(true)
        if cfg.autoDrop then dropBrokenPlastic(player,weapon,part,cfg) else swap(player,weapon,part,cfg.brokenType,0,true) end
        return
    end
    local n=math.max(1,part:getCondition()-1)
    if n==1 then swap(player,weapon,part,cfg.criticalType,1,false) else part:setCondition(n) end
end
Events.OnWeaponSwingHitPoint.Add(processShot)

local RECIPES={
 plastic={"MakeHomemadePlasticSuppressor"},
 can={"MakeHomemadeCanSuppressor"},
 pipe={"MakeHomemadePipeSuppressor"},
}
local function learnList(player,list)
    for i=1,#list do local r=list[i]; if not player:isRecipeKnown(r) then player:learnRecipe(r) end end
end
local function autoLearn(player)
    if not player or not Perks then return end
    local m=player:getPerkLevel(Perks.Maintenance); local w=player:getPerkLevel(Perks.MetalWelding)
    local md=player:getModData(); local sig=m*100+w
    if md.GOMHSRecipeSig==sig then return end; md.GOMHSRecipeSig=sig
    if m>=1 then learnList(player,RECIPES.plastic) end
    if m>=3 then learnList(player,RECIPES.can) end
    if m>=5 and w>=3 then learnList(player,RECIPES.pipe) end
end
local counter=0
local function periodic(player)
    if not player then return end
    enforcePlayerWeaponSound(player)
    counter=counter+1; if counter<60 then return end; counter=0
    autoLearn(player)
    local weapon=player:getPrimaryHandItem()
    if weapon and instanceof(weapon,"HandWeapon") then
        local part=getCanon(weapon); local info=part and TYPE_STATE[part:getFullType()] or nil
        if info and info.state=="working" then
            local cfg=CFG[info.kind]; initPart(part,player,cfg)
            if part:getCondition()<=1 then swap(player,weapon,part,cfg.criticalType,1,false) end
        end
    end
end
Events.OnPlayerUpdate.Add(periodic)
print("[GOM HS] Fix 3.16 core loaded - unified Marz audio resolver + burst/auto guard active")
