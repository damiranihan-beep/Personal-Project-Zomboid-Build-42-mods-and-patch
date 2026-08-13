-- Adds only ModelWeaponPart params to current GoM script objects at Lua-load time.
local plastic={"M92FS","M93R","HIPOWER","P226","M1911","USP","DEAGLE","VP70M"}
local can={"M92FS","M93R","HIPOWER","P226","M1911","USP","DEAGLE","VP70M","THOMPSON","MP5","MP5A2","MP5K","TEC9","MAC10","W1873_CARBINE"}
local pipe={"M92FS","M93R","HIPOWER","P226","M1911","USP","DEAGLE","VP70M","THOMPSON","MP5","MP5A2","MP5K","TEC9","MAC10","W1873_CARBINE","M16A1","M16A2","M16A2_M203","M16A3","AR15","FNC","CAR15","XM177","M4A1","M4","G36C","G36","AK74","AKS74U","FAMAS","AK47","M14","M1_GARAND","FAL","G3","MOSIN","M24","M1903","W1894","M1895","W1873","M60","BAR","SVD","SKS","PSG1"}
local function add(weapon,part,model)
    local sm=getScriptManager and getScriptManager() or nil
    if not sm then return end
    local script=sm:getItem("MarzGuns."..weapon)
    if not script or not script.DoParam then return end
    pcall(function() script:DoParam("ModelWeaponPart = MarzGuns."..part.." MarzGuns."..model.." canon canon") end)
end
local function addSet(list,kind)
    for i=1,#list do
        local w=list[i]
        if kind=="plastic" then
            add(w,"HomemadePlasticSuppressor","HomemadePlasticSuppressor")
            add(w,"HomemadePlasticSuppressor_Critical","HomemadePlasticSuppressor")
        elseif kind=="can" then
            add(w,"HomemadeCanSuppressor","HomemadeCanSuppressor")
            add(w,"HomemadeCanSuppressor_Critical","HomemadeCanSuppressor")
            add(w,"HomemadeCanSuppressor_Broken","HomemadeCanSuppressor_Broken")
        elseif kind=="pipe" then
            add(w,"HomemadePipeSuppressor","HomemadePipeSuppressor")
            add(w,"HomemadePipeSuppressor_Critical","HomemadePipeSuppressor")
            add(w,"HomemadePipeSuppressor_Broken","HomemadePipeSuppressor_Broken")
        end
    end
end
addSet(plastic,"plastic"); addSet(can,"can"); addSet(pipe,"pipe")
print("[GOM HS] weapon model mappings applied without weapon-script overrides")
