require "ISUI/ISToolTipInv"

-- Weapon Attachment Tooltip Cleaner v1.1
-- IMPORTANT: this version does NOT rebuild the tooltip.
-- It calls whatever renderer is already active (vanilla / Guns of Marz /
-- Armor Makes Sense / other wrappers) and temporarily hides ONLY WeaponPart.MountOn.
-- This preserves weight, ammo count, ammo type, original stat lines and mod-added rows.

WeaponAttachmentTooltipCleaner = WeaponAttachmentTooltipCleaner or {}
local WATC = WeaponAttachmentTooltipCleaner

local function hasMountOn(item)
    if not item or not instanceof(item, "WeaponPart") then return false end
    local ok, list = pcall(function() return item:getMountOn() end)
    return ok and list ~= nil and list:size() > 0
end

local function withMountOnHidden(item, callback, owner)
    if not hasMountOn(item) then
        return callback(owner)
    end

    local saved = nil
    local hidden = false

    local okSave = pcall(function()
        saved = item:getMountOn()
        -- WeaponPart.setMountOn(ArrayList) accepts null.  We do NOT call
        -- clear() on the Java ArrayList (that was the old error-spam source).
        item:setMountOn(nil)
        hidden = true
    end)

    if not okSave or not hidden then
        -- Fail open: if Build 42 changes the API, render the untouched tooltip.
        return callback(owner)
    end

    local okRender, result = pcall(callback, owner)

    -- Always restore the exact original Java list object before returning.
    pcall(function()
        item:setMountOn(saved)
    end)

    if not okRender then
        -- Preserve the original failure semantics without retrying the render
        -- (retrying every frame would create another error flood).
        error(result)
    end

    return result
end

local originalRender = ISToolTipInv.render

function ISToolTipInv:render()
    if self.item and hasMountOn(self.item) then
        return withMountOnHidden(self.item, originalRender, self)
    end
    return originalRender(self)
end

WATC.version = "1.1"
print("[WATC] v1.1 loaded - hides only WeaponPart MountOn; original tooltip preserved")
