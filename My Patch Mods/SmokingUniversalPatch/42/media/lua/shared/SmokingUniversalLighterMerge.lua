-- v1.4.3: allow vanilla consolidation of partially used lighters.
-- This only changes consolidation flags. It does NOT move/return items between containers.
local lighterTypes = { "Base.Lighter", "Base.LighterDisposable" }

for _, fullType in ipairs(lighterTypes) do
    local item = ScriptManager.instance:FindItem(fullType)
    if item then
        item:DoParam("cantBeConsolided", "false")
        item:DoParam("ConsolidateOption", "ContextMenu_Merge")
    end
end
