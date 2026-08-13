local tooltipsTable = require('MarzWeapons/ItemTooltipsTable')
local compatibilityData = require('MarzWeapons/MarzCompatibilityData')

local function normalizeTooltipLines(entry)
    if type(entry) == "string" then
        local lines = {}
        for line in string.gmatch(entry, "[^\r\n]+") do
            if line ~= "" then
                lines[#lines + 1] = line
            end
        end
        if #lines == 0 and entry ~= "" then
            lines[1] = entry
        end
        return lines
    end

    if type(entry) == "table" then
        local lines = {}
        for index = 1, #entry do
            local line = entry[index]
            if type(line) == "string" and line ~= "" then
                lines[#lines + 1] = line
            end
        end
        return lines
    end

    return {}
end

local FAMILY = {
    M16A1       = { "M16", "A1" },
    M16A2       = { "M16", "A2" },
    M16A2_M203  = { "M16", "A2+M203" },
    M16A3       = { "M16", "A3" },

    MP5         = { "MP5", "баз." },
    MP5A2       = { "MP5", "A2" },
    MP5K        = { "MP5", "K" },
    MP5SD       = { "MP5", "SD" },

    M4          = { "M4", "баз." },
    M4A1        = { "M4", "A1" },

    G36         = { "G36", "баз." },
    G36C        = { "G36", "C" },

    W1873           = { "Winchester 1873", "винт." },
    W1873_CARBINE   = { "Winchester 1873", "кар." },
}

local function shortType(fullType)
    return tostring(fullType):gsub("^MarzGuns%.", "")
end

local function cleanDisplayName(fullType)
    local mapped = compatibilityData.pretty[tostring(fullType)]
    if mapped and mapped ~= "" then
        return mapped
    end

    local short = shortType(fullType)
    local sm = getScriptManager and getScriptManager() or nil
    local script = sm and sm:getItem(tostring(fullType)) or nil
    local name = script and script:getDisplayName() or short:gsub("_", " ")
    name = tostring(name)

    -- Strip translated category prose; keep only the weapon model.
    for _, separator in ipairs({ " — ", "—", " – ", "–" }) do
        local at = string.find(name, separator, 1, true)
        if at then
            name = string.sub(name, 1, at - 1)
            break
        end
    end
    return name:gsub("%s+$", "")
end

local function compactModels(models)
    local result = {}
    local groups = {}
    local order = {}

    for _, fullType in ipairs(models) do
        local short = shortType(fullType)
        local family = FAMILY[short]

        if family then
            local key = family[1]
            if not groups[key] then
                groups[key] = { members = {}, types = {} }
                order[#order + 1] = { kind = "family", key = key }
            end
            groups[key].members[#groups[key].members + 1] = family[2]
            groups[key].types[#groups[key].types + 1] = fullType
        else
            order[#order + 1] = { kind = "single", value = fullType }
        end
    end

    for _, entry in ipairs(order) do
        if entry.kind == "single" then
            result[#result + 1] = cleanDisplayName(entry.value)
        else
            local group = groups[entry.key]
            if #group.types == 1 then
                result[#result + 1] = cleanDisplayName(group.types[1])
            else
                result[#result + 1] = entry.key .. " (" .. table.concat(group.members, "/") .. ")"
            end
        end
    end

    return result
end

local function readMountOn(item)
    local models = {}
    if not item or not instanceof(item, "WeaponPart") then return models end

    local mountOn = item:getMountOn()
    if not mountOn then return models end

    for index = 0, mountOn:size() - 1 do
        local fullType = tostring(mountOn:get(index))
        if fullType ~= "" and not string.find(fullType, "FakeItem", 1, true) then
            models[#models + 1] = fullType
        end
    end
    return models
end

local function getCompatibilityModels(item)
    local fullType = item:getFullType()

    local mapped = compatibilityData.magazines[fullType]
    if mapped then
        local result = {}
        for i = 1, #mapped do result[i] = mapped[i] end
        return result, "magazine"
    end

    local special = compatibilityData.special[fullType]
    if special then
        local result = {}
        for i = 1, #special do result[i] = special[i] end
        return result, "mountOn"
    end

    local mount = readMountOn(item)
    if #mount > 0 then
        return mount, "mountOn"
    end

    return {}, nil
end

local function getTooltipData(item)
    if not item or not instanceof(item, "InventoryItem") then
        return nil
    end

    local info = normalizeTooltipLines(tooltipsTable.tooltipsPergun[item:getFullType()])
    local models, compatSource = getCompatibilityModels(item)
    local compat = compactModels(models)

    if #info == 0 and #compat == 0 then
        return nil
    end

    return {
        info = info,
        compat = compat,
        compatRaw = models,
        compatSource = compatSource,
    }
end

local WATC = require("WeaponAttachmentTooltipCleaner")
WATC.registerProvider("GunsOfMarzExactCompatibility", function(item)
    return getTooltipData(item)
end)

print("[GOM HS] compatibility provider registered with WATC")
