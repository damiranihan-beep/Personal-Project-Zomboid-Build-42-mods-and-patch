require "ISUI/ISToolTipInv"

WeaponAttachmentTooltipCleaner = WeaponAttachmentTooltipCleaner or {}
local WATC = WeaponAttachmentTooltipCleaner
WATC.providers = WATC.providers or {}

local function text(v)
    if v == nil then return "" end
    return tostring(v)
end

local function shortType(fullType)
    return text(fullType):gsub("^MarzGuns%.", ""):gsub("^Base%.", "")
end

local function cleanDisplayName(fullType)
    local sm = getScriptManager and getScriptManager() or nil
    local script = sm and sm:getItem(text(fullType)) or nil
    local name = script and script:getDisplayName() or shortType(fullType):gsub("_", " ")
    name = text(name)
    for _, sep in ipairs({ " — ", "—", " – ", "–" }) do
        local at = string.find(name, sep, 1, true)
        if at then
            name = string.sub(name, 1, at - 1)
            break
        end
    end
    return name:gsub("%s+$", "")
end

local function fullDisplayName(fullType)
    local sm = getScriptManager and getScriptManager() or nil
    local script = sm and sm:getItem(text(fullType)) or nil
    if script and script:getDisplayName() then return text(script:getDisplayName()) end
    return cleanDisplayName(fullType)
end

local function readMountOn(item)
    local out = {}
    if not item or not instanceof(item, "WeaponPart") then return out end
    local mountOn = item:getMountOn()
    if not mountOn then return out end
    for i = 0, mountOn:size() - 1 do
        local v = text(mountOn:get(i))
        if v ~= "" and not string.find(v, "FakeItem", 1, true) then
            out[#out + 1] = v
        end
    end
    return out
end

local function copyList(list)
    local out = {}
    if type(list) == "table" then
        for i = 1, #list do out[i] = list[i] end
    end
    return out
end

local function makeDefaultData(item)
    if not item or not instanceof(item, "WeaponPart") then return nil end
    local raw = readMountOn(item)
    if #raw == 0 then return nil end
    local compat = {}
    for i = 1, #raw do compat[i] = cleanDisplayName(raw[i]) end
    return {
        info = {},
        compat = compat,
        compatRaw = raw,
        compatSource = "mountOn",
    }
end

function WATC.registerProvider(name, fn)
    if type(name) ~= "string" or type(fn) ~= "function" then return end
    WATC.providers[name] = fn
end

local function getProviderData(item)
    for _, provider in pairs(WATC.providers) do
        local ok, data = pcall(provider, item)
        if ok and data then
            data.info = copyList(data.info)
            data.compat = copyList(data.compat)
            data.compatRaw = copyList(data.compatRaw)
            return data
        end
    end
    return makeDefaultData(item)
end

local function addNeedle(t, s)
    s = text(s)
    if s ~= "" and #s >= 3 then t[s] = true end
end

local function buildNeedles(data)
    local needles = {}
    for _, fullType in ipairs(data.compatRaw or {}) do
        addNeedle(needles, fullDisplayName(fullType))
        addNeedle(needles, cleanDisplayName(fullType))
    end
    return needles
end

local COMPAT_LABELS = {
    "Можно закрепить на",
    "Можно прикрепить на",
    "Can be attached to",
    "Can attach to",
}

local MAGAZINE_GENERIC = {
    "Пистолеты и револьверы",
    "Винтовки и дробовики",
    "Pistols and revolvers",
    "Rifles and shotguns",
}

local function rowLooksLikeCompatibility(row, data, needles)
    if not row then return false end
    local joined = text(row.label) .. " " .. text(row.value)

    for _, phrase in ipairs(COMPAT_LABELS) do
        if string.find(joined, phrase, 1, true) then return true end
    end

    if data.compatSource == "magazine" then
        for _, phrase in ipairs(MAGAZINE_GENERIC) do
            if string.find(joined, phrase, 1, true) then return true end
        end
    end

    for needle in pairs(needles) do
        if string.find(joined, needle, 1, true) then
            return true
        end
    end
    return false
end

local function filterCompatibilityRows(layout, data)
    if not layout or not layout.items or not data or not data.compat or #data.compat == 0 then return end
    local needles = buildNeedles(data)
    for i = layout.items:size() - 1, 0, -1 do
        local row = layout.items:get(i)
        if rowLooksLikeCompatibility(row, data, needles) then
            layout.items:remove(i)
        end
    end
end

local function addCustomRows(layout, data)
    for _, line in ipairs(data.info or {}) do
        if line and line ~= "" then
            layout:addItem():setLabel(text(line), 1.0, 1.0, 1.0, 1.0)
        end
    end

    if data.compat and #data.compat > 0 then
        local header = getText("UI_WATC_Compat_Header")
        if not header or header == "" or header == "UI_WATC_Compat_Header" then
            header = "Можно закрепить на:"
        end
        layout:addItem():setLabel(header, 1.0, 1.0, 1.0, 1.0)
        for _, model in ipairs(data.compat) do
            layout:addItem():setLabel(text(model), 1.0, 1.0, 1.0, 1.0)
        end
    end
end

local function renderItemIntoTooltip(tooltip, item, data)
    local padLeft = tooltip.padLeft or 5
    local padBottom = tooltip.padBottom or 5
    local padTop = 5

    local layout = tooltip:beginLayout()
    item:DoTooltip(tooltip, layout)
    filterCompatibilityRows(layout, data)
    addCustomRows(layout, data)
    local endY = layout:render(padLeft, padTop, tooltip)
    tooltip:endLayout(layout)
    tooltip:setHeight(endY + padBottom)
end

WATC.renderItemIntoTooltip = renderItemIntoTooltip
WATC.cleanDisplayName = cleanDisplayName
WATC.readMountOn = readMountOn

local originalRender = ISToolTipInv.render

function ISToolTipInv:render()
    local item = self.item
    if not item then return originalRender(self) end

    local data = getProviderData(item)
    if not data then return originalRender(self) end

    if ISContextMenu.instance and ISContextMenu.instance.visibleCheck then
        return originalRender(self)
    end

    local mx = getMouseX() + 24
    local my = getMouseY() + 24
    if not self.followMouse then
        mx = self:getX()
        my = self:getY()
        if self.anchorBottomLeft then
            mx = self.anchorBottomLeft.x
            my = self.anchorBottomLeft.y
        end
    end

    local PADX = 0
    self.tooltip:setX(mx + PADX)
    self.tooltip:setY(my)
    self.tooltip:setWidth(50)
    self.tooltip:setMeasureOnly(true)
    renderItemIntoTooltip(self.tooltip, item, data)
    self.tooltip:setMeasureOnly(false)

    local core = getCore()
    local maxX = core:getScreenWidth()
    local maxY = core:getScreenHeight()
    local tw = self.tooltip:getWidth()
    local th = self.tooltip:getHeight()

    self.tooltip:setX(math.max(0, math.min(mx + PADX, maxX - tw - 1)))
    if not self.followMouse and self.anchorBottomLeft then
        self.tooltip:setY(math.max(0, math.min(my - th, maxY - th - 1)))
    else
        self.tooltip:setY(math.max(0, math.min(my, maxY - th - 1)))
    end

    if self.contextMenu and self.contextMenu.joyfocus then
        local playerNum = self.contextMenu.player
        self.tooltip:setX(getPlayerScreenLeft(playerNum) + 60)
        self.tooltip:setY(getPlayerScreenTop(playerNum) + 60)
    elseif self.contextMenu and self.contextMenu.currentOptionRect then
        if self.contextMenu.currentOptionRect.height > 32 then
            self:setY(my + self.contextMenu.currentOptionRect.height)
        end
        self:adjustPositionToAvoidOverlap(self.contextMenu.currentOptionRect)
    end

    self:setX(self.tooltip:getX() - PADX)
    self:setY(self.tooltip:getY())
    self:setWidth(tw + PADX)
    self:setHeight(th)

    if self.followMouse and self.contextMenu == nil then
        self:adjustPositionToAvoidOverlap({ x = mx - 48, y = my - 48, width = 48, height = 48 })
    end

    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    renderItemIntoTooltip(self.tooltip, item, data)
end

print("[WATC] safe weapon attachment tooltip cleaner loaded")
return WATC
