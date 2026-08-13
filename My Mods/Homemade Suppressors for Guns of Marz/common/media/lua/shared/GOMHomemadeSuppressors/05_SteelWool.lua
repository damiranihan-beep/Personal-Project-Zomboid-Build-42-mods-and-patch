-- GOM Homemade Suppressors - Steel Wool quality-of-life patch for B42.20.2.
-- Steel Wool is already a vanilla drainable item (UseDelta = 0.2) and can
-- consolidate by default. Vanilla simply does not assign it a merge label.
-- Set the standard merge option on the script item instead of replacing the
-- inventory context menu or implementing a custom timed action.
local steelWool = ScriptManager.instance:FindItem("Base.SteelWool")
if steelWool then
    steelWool:DoParam("ConsolidateOption", "ContextMenu_Merge")
else
    print("[GOM HS] WARNING: Base.SteelWool script item not found")
end
