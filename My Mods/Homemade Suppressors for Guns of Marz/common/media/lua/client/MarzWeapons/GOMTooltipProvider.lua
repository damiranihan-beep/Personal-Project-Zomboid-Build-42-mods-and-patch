local tooltipsTable=require("MarzWeapons/ItemTooltipsTable")
local compatibilityData=require("MarzWeapons/MarzCompatibilityData")
local okWATC,WATC=pcall(require,"WeaponAttachmentTooltipCleaner")
if not okWATC or not WATC or not WATC.registerProvider then
    print("[GOM HS] WATC provider skipped: cleaner not available")
    return
end

local FAMILY={
 M16A1={"M16","A1"},M16A2={"M16","A2"},M16A2_M203={"M16","A2+M203"},M16A3={"M16","A3"},
 MP5={"MP5","баз."},MP5A2={"MP5","A2"},MP5K={"MP5","K"},MP5SD={"MP5","SD"},
 M4={"M4","баз."},M4A1={"M4","A1"},G36={"G36","баз."},G36C={"G36","C"},
 W1873={"Winchester 1873","винт."},W1873_CARBINE={"Winchester 1873","кар."},
}
local function resolve(line)
    line=tostring(line or "")
    if line=="" then return "" end
    if string.sub(line,1,3)=="UI_" or string.sub(line,1,8)=="Tooltip_" then
        local ok,v=pcall(getText,line)
        if ok and v and v~="" and v~=line then return tostring(v) end
    end
    return line
end
local function normalize(entry)
    local out={}
    if type(entry)=="string" then
        for line in string.gmatch(entry,"[^\r\n]+") do line=resolve(line); if line~="" then out[#out+1]=line end end
    elseif type(entry)=="table" then
        for i=1,#entry do local line=resolve(entry[i]); if line~="" then out[#out+1]=line end end
    end
    return out
end
local function short(full) return tostring(full):gsub("^MarzGuns%.","") end
local function pretty(full)
    local mapped=compatibilityData.pretty[tostring(full)]; if mapped and mapped~="" then return mapped end
    local sm=getScriptManager and getScriptManager() or nil; local sc=sm and sm:getItem(tostring(full)) or nil
    local n=sc and sc:getDisplayName() or short(full):gsub("_"," "); n=tostring(n)
    for _,sep in ipairs({" — ","—"," – ","–"}) do local at=string.find(n,sep,1,true); if at then n=string.sub(n,1,at-1); break end end
    return n:gsub("%s+$","")
end
local function compact(models)
    local out,groups,order={},{},{}
    for _,full in ipairs(models) do
        local fam=FAMILY[short(full)]
        if fam then
            if not groups[fam[1]] then groups[fam[1]]={members={},types={}}; order[#order+1]={kind="family",key=fam[1]} end
            groups[fam[1]].members[#groups[fam[1]].members+1]=fam[2]; groups[fam[1]].types[#groups[fam[1]].types+1]=full
        else order[#order+1]={kind="single",value=full} end
    end
    for _,e in ipairs(order) do
        if e.kind=="single" then out[#out+1]=pretty(e.value)
        else local g=groups[e.key]; if #g.types==1 then out[#out+1]=pretty(g.types[1]) else out[#out+1]=e.key.." ("..table.concat(g.members,"/")..")" end end
    end
    return out
end
local function mountOn(item)
    local out={}; if not item or not instanceof(item,"WeaponPart") then return out end
    local ok,l=pcall(function() return item:getMountOn() end); if not ok or not l then return out end
    for i=0,l:size()-1 do local v=tostring(l:get(i)); if v~="" and not string.find(v,"FakeItem",1,true) then out[#out+1]=v end end
    return out
end
local function models(item,ft)
    local m=compatibilityData.magazines[ft]
    if m then local o={}; for i=1,#m do o[i]=m[i] end; return o,"magazine" end
    m=compatibilityData.special[ft]; if m then local o={}; for i=1,#m do o[i]=m[i] end; return o,"mountOn" end
    local o=mountOn(item); if #o>0 then return o,"mountOn" end
    return {},nil
end
local function tooltipFromItem(item)
    local ok,key=pcall(function() return item:getTooltip() end)
    if not ok or not key or tostring(key)=="" then return {} end
    local value=resolve(key); if value==tostring(key) and string.sub(tostring(key),1,8)=="Tooltip_" then return {} end
    return normalize(value)
end
WATC.registerProvider("GunsOfMarzExactCompatibility",function(item)
    if not item then return nil end
    local okFT,ft=pcall(function() return item:getFullType() end)
    if not okFT or not ft then return nil end
    ft=tostring(ft)
    local info=normalize(tooltipsTable.tooltipsPergun[ft])
    if #info==0 and (string.find(ft,"HomemadeSuppressors.",1,true) or string.find(ft,"MarzGuns.Homemade",1,true)) then info=tooltipFromItem(item) end
    local raw,source=models(item,ft); local compat=compact(raw)
    if #info==0 and #compat==0 then return nil end
    return {info=info,compat=compat,compatRaw=raw,compatSource=source}
end)
print("[GOM HS] exact tooltip/compatibility provider registered")
