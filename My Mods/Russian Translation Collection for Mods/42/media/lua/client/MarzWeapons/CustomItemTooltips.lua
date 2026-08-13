local tooltipsTable = require('MarzWeapons/ItemTooltipsTable')

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

    return nil
end

local function getCustomTooltipLines(item)
    if not item or not instanceof(item, "InventoryItem") then
        return nil
    end

    local entry = tooltipsTable.tooltipsPergun[item:getFullType()]
    if not entry then
        return nil
    end

    local lines = normalizeTooltipLines(entry)
    if not lines or #lines == 0 then
        return nil
    end

    return lines
end

local function appendCustomTooltipBlock(tooltip, lines)
    local padLeft = tooltip.padLeft or 5
    local padBottom = tooltip.padBottom or 5
    local currentHeight = tooltip:getHeight()

    local layout = tooltip:beginLayout()
    layout:addItem():setLabel(getText("UI_MRT_MarzTooltip_Header_001"), 1, 0.02, 0.02, 1)

    for _, line in ipairs(lines) do
        layout:addItem():setLabel(line, 1.0, 1.0, 1.0, 1.0)
    end

    local endY = layout:render(padLeft, currentHeight - padBottom, tooltip)
    tooltip:endLayout(layout)
    tooltip:setHeight(endY + padBottom)
end

local function renderItemTooltip(tooltip, item, lines)
    item:DoTooltip(tooltip)
    appendCustomTooltipBlock(tooltip, lines)
end

local function renderItemSlotTooltip(tooltip, itemSlot, lines)
    itemSlot:drawTooltip(tooltip)
    appendCustomTooltipBlock(tooltip, lines)
end

local originalRender = ISToolTipInv.render

function ISToolTipInv:render()
    local item = self.item
    if not item then
        return originalRender(self)
    end

    local lines = getCustomTooltipLines(item)
    if not lines then
        return originalRender(self)
    end

    if not ISContextMenu.instance or not ISContextMenu.instance.visibleCheck then
        local mx = getMouseX() + 24;
        local my = getMouseY() + 24;
        if not self.followMouse then
            mx = self:getX()
            my = self:getY()
            if self.anchorBottomLeft then
                mx = self.anchorBottomLeft.x
                my = self.anchorBottomLeft.y
            end
        end

        if not ISToolTipItemSlot._TooltipHooked then
            ISToolTipItemSlot._TooltipHooked = true

            local originalItemSlotRender = ISToolTipItemSlot.render

            function ISToolTipItemSlot:render()
                local item = self.item
                if not item then
                    return originalItemSlotRender(self)
                end

                local lines = getCustomTooltipLines(item)
                if not lines then
                    return originalItemSlotRender(self)
                end

                if not ISContextMenu.instance or not ISContextMenu.instance.visibleCheck then
                    local mx = getMouseX() + 24;
                    local my = getMouseY() + 24;
                    if not self.followMouse then
                        mx = self:getX()
                        my = self:getY()
                        if self.anchorBottomLeft then
                            mx = self.anchorBottomLeft.x
                            my = self.anchorBottomLeft.y
                        end
                    end

                    local PADX = 0

                    self.tooltip:setX(mx + PADX);
                    self.tooltip:setY(my);

                    self.tooltip:setWidth(50)
                    self.tooltip:setMeasureOnly(true)
                    if self.itemSlot then renderItemSlotTooltip(self.tooltip, self.itemSlot, lines) end;
                    self.tooltip:setMeasureOnly(false)

                    local myCore = getCore();
                    local maxX = myCore:getScreenWidth();
                    local maxY = myCore:getScreenHeight();

                    local tw = self.tooltip:getWidth();
                    local th = self.tooltip:getHeight();

                    self.tooltip:setX(math.max(0, math.min(mx + PADX, maxX - tw - 1)));
                    if not self.followMouse and self.anchorBottomLeft then
                        self.tooltip:setY(math.max(0, math.min(my - th, maxY - th - 1)));
                    else
                        self.tooltip:setY(math.max(0, math.min(my, maxY - th - 1)));
                    end

                    self:setX(self.tooltip:getX() - PADX);
                    self:setY(self.tooltip:getY());
                    self:setWidth(tw + PADX);
                    self:setHeight(th);

                    if self.followMouse then
                        self:adjustPositionToAvoidOverlap({ x = mx - 24 * 2, y = my - 24 * 2, width = 24 * 2, height = 24 * 2 })
                    end

                    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
                    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
                    if self.itemSlot then renderItemSlotTooltip(self.tooltip, self.itemSlot, lines) end;
                end
            end
        end

        local PADX = 0

        self.tooltip:setX(mx + PADX);
        self.tooltip:setY(my);

        self.tooltip:setWidth(50)
        self.tooltip:setMeasureOnly(true)
        if self.item then renderItemTooltip(self.tooltip, self.item, lines) end;
        self.tooltip:setMeasureOnly(false)

        local myCore = getCore();
        local maxX = myCore:getScreenWidth();
        local maxY = myCore:getScreenHeight();

        local tw = self.tooltip:getWidth();
        local th = self.tooltip:getHeight();

        self.tooltip:setX(math.max(0, math.min(mx + PADX, maxX - tw - 1)));
        if not self.followMouse and self.anchorBottomLeft then
            self.tooltip:setY(math.max(0, math.min(my - th, maxY - th - 1)));
        else
            self.tooltip:setY(math.max(0, math.min(my, maxY - th - 1)));
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

        self:setX(self.tooltip:getX() - PADX);
        self:setY(self.tooltip:getY());
        self:setWidth(tw + PADX);
        self:setHeight(th);

        if self.followMouse and (self.contextMenu == nil) then
            self:adjustPositionToAvoidOverlap({ x = mx - 24 * 2, y = my - 24 * 2, width = 24 * 2, height = 24 * 2 })
        end

        self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
        self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
        if self.item then renderItemTooltip(self.tooltip, self.item, lines) end;
    end
end
