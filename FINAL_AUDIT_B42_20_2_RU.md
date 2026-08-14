# FINAL AUDIT — Project Zomboid Build 42.20.2

Date: 2026-08-14

## GoM architecture split

### Homemade Suppressors — Fix 3.12
- Contains only the three homemade suppressors and their gameplay systems.
- No optic rebalance.
- No copied `MarzWeapons/ItemTooltipsTable.lua`.
- No compatibility provider / `MarzCompatibilityData.lua`.
- No `UI_HS_Optic_*` or `UI_HS_Compat_*` active translation keys.
- No WATC dependency.

### Guns of Marz Attachment Rebalance — v1.0
- New standalone balance mod.
- PL-4 / PS-1 / PM-2 / PRL-1 = +1 / +3 / +6 / +10% Hit, Crit and Sight Range.
- Patches only four entries in the original GoM tooltip table at runtime instead of replacing the full table.
- Uses its own `UI_GOMAR_*` localization and resolves the text with `getText`.

### Weapon Attachment Tooltip Cleaner — v1.5 TEST
- Standalone UI-only compatibility renderer.
- Original horizontal `Можно закрепить на ...` row is removed from tooltip layout only.
- New `Можно закрепить на:` block lists exact compatible models vertically, one per line.
- Read-only compatibility map is local to WATC for magazines/FakeItem categories.
- No `setMountOn`, no MountOn mutation, no stats, no suppressor logic.

## Static checks
- Active HS files contain no optic IDs, WATC require/provider or GoM tooltip override.
- Active WATC files contain no `setMountOn` and no provider bridge.
- Active Rebalance files contain no suppressor/WATC dependency.
- No active `UI_HS_*` code/translation keys remain in the split repository.
- Rebalance percent signs are escaped as `%%` in translation files.
- JSON files parse as UTF-8 JSON.

## Live confirmation still required
1. PL-4: no raw key; normal generation/stat text; vertical compatibility.
2. Reflex S2: no horizontal compatibility wall across the screen.
3. GoM magazines: ammo/type/weight preserved; compatibility vertical.
4. Picatinny rail: exact models vertical.
5. Hover 20–30 seconds without ERROR growth.
6. Suppressor automatic fire and break behavior unchanged.
