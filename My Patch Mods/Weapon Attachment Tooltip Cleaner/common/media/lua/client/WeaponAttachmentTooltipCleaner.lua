require "ISUI/ISToolTipInv"

WeaponAttachmentTooltipCleaner = WeaponAttachmentTooltipCleaner or {}
local WATC = WeaponAttachmentTooltipCleaner

local okCompat, compatibilityData = pcall(require, "WeaponAttachmentTooltipCleaner/MarzCompatibilityData")
if not okCompat or type(compatibilityData) ~= "table" then compatibilityData = { magazines = {}, special = {}, pretty = {}, params = {} } end

local function text(v)
    if v == nil then return "" end
    return tostring(v)
end

local function shortType(fullType)
    return text(fullType):gsub("^MarzGuns%.", ""):gsub("^HomemadeSuppressors%.", ""):gsub("^Base%.", "")
end

local function fullTypeOf(item)
    if not item then return "" end
    local ok, ft = pcall(function() return item:getFullType() end)
    return ok and text(ft) or ""
end

local function cleanDisplayName(fullType)
    fullType = text(fullType)
    if fullType == "" then return "" end

    local sm = getScriptManager and getScriptManager() or nil
    local script = sm and sm:getItem(fullType) or nil
    local name = script and script:getDisplayName() or nil
    if not name or text(name) == "" then name = compatibilityData.pretty and compatibilityData.pretty[fullType] end
    if not name or text(name) == "" then name = shortType(fullType):gsub("_", " ") end
    name = text(name)

    -- Display only the weapon/model name, not its category suffix.
    for _, sep in ipairs({ " — ", "—", " – ", "–" }) do
        local at = string.find(name, sep, 1, true)
        if at then name = string.sub(name, 1, at - 1); break end
    end
    return name:gsub("^%s+", ""):gsub("%s+$", "")
end

local function appendRaw(out, value)
    value = text(value)
    if value == "" or string.find(value, "FakeItem", 1, true) then return end
    out[#out + 1] = value
end

local function copyExact(list)
    local out = {}
    if type(list) == "table" then
        for i = 1, #list do appendRaw(out, list[i]) end
    end
    return out
end

local function splitMountOn(value)
    local out = {}
    value = text(value)
    for part in string.gmatch(value, "[^;]+") do appendRaw(out, part) end
    return out
end

local function runtimeMountOn(item)
    local out = {}
    if not item or not instanceof(item, "WeaponPart") then return out end
    local ok, mountOn = pcall(function() return item:getMountOn() end)
    if not ok or not mountOn then return out end
    local okSize, n = pcall(function() return mountOn:size() end)
    if not okSize or not n then return out end
    for i = 0, n - 1 do
        local okGet, v = pcall(function() return mountOn:get(i) end)
        if okGet then appendRaw(out, v) end
    end
    return out
end

local function exactCompatibility(item)
    local ft = fullTypeOf(item)
    if ft == "" then return {} end

    -- Magazines and a few category-based parts need a source-derived exact map,
    -- because their runtime MountOn may only say FakeItemPistols/FakeItemRifles.
    local mapped = compatibilityData.magazines and compatibilityData.magazines[ft]
    if mapped then return copyExact(mapped) end
    mapped = compatibilityData.special and compatibilityData.special[ft]
    if mapped then return copyExact(mapped) end

    -- For regular parts use source-derived MountOn first; it is stable and exact.
    local params = compatibilityData.params and compatibilityData.params[ft]
    if params and params.mountOn then
        local fromParams = splitMountOn(params.mountOn)
        if #fromParams > 0 then return fromParams end
    end

    return runtimeMountOn(item)
end

local function modelNames(raw)
    local out, seen = {}, {}
    for i = 1, #raw do
        local n = cleanDisplayName(raw[i])
        if n ~= "" and not seen[n] then seen[n] = true; out[#out + 1] = n end
    end
    return out
end

local COMPAT_LABELS = {
    "Можно закрепить на", "Можно прикрепить на", "Can be attached to", "Can attach to",
    "Пистолеты и револьверы", "Винтовки и дробовики", "Pistols and revolvers", "Rifles and shotguns",
}

local function joinedRow(row)
    return text(row and row.label) .. " " .. text(row and row.value)
end

local function rowIsNativeCompatibility(row)
    if not row then return false end
    local joined = joinedRow(row)
    for _, phrase in ipairs(COMPAT_LABELS) do
        if string.find(joined, phrase, 1, true) then return true end
    end
    return false
end

local function rowIsTechnicalGarbage(row)
    local joined = string.lower(joinedRow(row))
    return string.find(joined, "marzguns:bullet", 1, true) ~= nil
        or string.find(joined, "marzguns.bullet", 1, true) ~= nil
end

local function filterNativeCompatibility(layout)
    if not layout or not layout.items then return false end
    local removed = false
    for i = layout.items:size() - 1, 0, -1 do
        local row = layout.items:get(i)
        if rowIsNativeCompatibility(row) then
            layout.items:remove(i)
            removed = true
        elseif rowIsTechnicalGarbage(row) then
            layout.items:remove(i)
        end
    end
    return removed
end

local function getHeader()
    local key = "UI_WATC_Compat_Header"
    local ok, v = pcall(getText, key)
    if ok and v and text(v) ~= "" and text(v) ~= key then return text(v) end
    return "Можно закрепить на:"
end

local function addCompatibilityVertical(layout, models)
    if #models == 0 then return end
    layout:addItem():setLabel(getHeader(), 1, 1, 1, 1)
    for i = 1, #models do
        -- One exact compatible weapon/model per row: no comma wall and no category shorthand.
        layout:addItem():setLabel("  " .. models[i], 1, 1, 1, 1)
    end
end

local function isCandidate(item, raw)
    if not item then return false end
    if #raw > 0 then return true end
    local ft = fullTypeOf(item)
    return string.sub(ft, 1, 9) == "MarzGuns." and instanceof(item, "WeaponPart")
end

local function renderItemIntoTooltip(tooltip, item, models)
    local padLeft = tooltip.padLeft or 5
    local padBottom = tooltip.padBottom or 5
    local layout = tooltip:beginLayout()

    -- Build the normal game/GoM tooltip first, preserving Type, weight, condition,
    -- ammo, stats and every unrelated row. Then remove only the huge compatibility row.
    item:DoTooltip(tooltip, layout)
    filterNativeCompatibility(layout)
    addCompatibilityVertical(layout, models)

    local endY = layout:render(padLeft, 5, tooltip)
    tooltip:endLayout(layout)
    tooltip:setHeight(endY + padBottom)
end

local originalRender = ISToolTipInv.render
function ISToolTipInv:render()
    local item = self.item
    if not item then return originalRender(self) end

    local raw = exactCompatibility(item)
    if not isCandidate(item, raw) then return originalRender(self) end
    if ISContextMenu.instance and ISContextMenu.instance.visibleCheck then return originalRender(self) end

    local models = modelNames(raw)
    local mx = getMouseX() + 24
    local my = getMouseY() + 24
    if not self.followMouse then
        mx = self:getX(); my = self:getY()
        if self.anchorBottomLeft then mx = self.anchorBottomLeft.x; my = self.anchorBottomLeft.y end
    end

    self.tooltip:setX(mx); self.tooltip:setY(my); self.tooltip:setWidth(50); self.tooltip:setMeasureOnly(true)
    renderItemIntoTooltip(self.tooltip, item, models)
    self.tooltip:setMeasureOnly(false)

    local core = getCore(); local tw = self.tooltip:getWidth(); local th = self.tooltip:getHeight()
    self.tooltip:setX(math.max(0, math.min(mx, core:getScreenWidth() - tw - 1)))
    if not self.followMouse and self.anchorBottomLeft then
        self.tooltip:setY(math.max(0, math.min(my - th, core:getScreenHeight() - th - 1)))
    else
        self.tooltip:setY(math.max(0, math.min(my, core:getScreenHeight() - th - 1)))
    end
    self:setX(self.tooltip:getX()); self:setY(self.tooltip:getY()); self:setWidth(tw); self:setHeight(th)
    if self.followMouse and self.contextMenu == nil then
        self:adjustPositionToAvoidOverlap({ x = mx - 48, y = my - 48, width = 48, height = 48 })
    end
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    renderItemIntoTooltip(self.tooltip, item, models)
end

WATC.version = "1.5"
WATC.cleanDisplayName = cleanDisplayName
WATC.exactCompatibility = exactCompatibility
print("[WATC] v1.5 loaded - original compatibility row hidden; exact models redrawn vertically; MountOn untouched")
return WATC
