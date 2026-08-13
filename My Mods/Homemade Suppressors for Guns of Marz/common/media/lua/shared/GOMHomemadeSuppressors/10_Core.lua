-- GOM Homemade Suppressors B42.20.2
GOMHomemade = GOMHomemade or {}
local okAnim, Animations = pcall(require, "WeaponSystems/Utils/Animations")
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

local function sync(player,weapon)
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
    local maxc=part:getConditionMax(); weapon:detachWeaponPart(part)
    local b=instanceItem(cfg.brokenType)
    if b then
        b:setConditionMax(maxc); b:setCondition(0); b:setBroken(true)
        local md=b:getModData(); md.GOMHSInitialized=true; md.GOMHSRolledCondition=maxc
        local sq=player:getCurrentSquare()
        if sq then sq:AddWorldInventoryItem(b,0.45,0.45,0.0) else player:getInventory():AddItem(b) end
    end
    sync(player,weapon)
end
local function getCanon(weapon)
    if not weapon or not weapon.getWeaponPart then return nil end
    return weapon:getWeaponPart("Canon")
end
local function processShot(player,weapon)
    if not player or not weapon or not instanceof(weapon,"HandWeapon") or not weapon:isRanged() then return end
    local part=getCanon(weapon); if not part then return end
    local info=TYPE_STATE[part:getFullType()]; if not info or info.state=="broken" then return end
    local cfg=CFG[info.kind]; initPart(part,player,cfg)
    if info.state=="critical" or part:getCondition()<=1 then
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
print("[GOM HS] core loaded for B42.20.2")
