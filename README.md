# Personal Project Zomboid Build 42 Mods and Patches

Target: **Project Zomboid Build 42.20.2**  
Architecture split: **2026-08-14**

## My Mods
- Homemade Suppressors for Guns of Marz — **Fix 3.12** — only the three homemade suppressors.
- Realistic Combat — **Fix 3.5**
- Russian Translation Collection for Mods — **v4.4.0**

## My Patch Mods
- Guns of Marz Attachment Rebalance — **v1.0** — optic/attachment balance only.
- Weapon Attachment Tooltip Cleaner — **v1.5 TEST** — compatibility tooltip UI only.
- SmokingUniversalPatch — **v1.4.3**

## New separation
- `Homemade Suppressors` no longer contains optic rebalance, GoM tooltip tables, compatibility providers or UI_HS optic/compat keys.
- `Guns of Marz Attachment Rebalance` owns PL-4 / PS-1 / PM-2 / PRL-1 = 1 / 3 / 6 / 10% Hit+Crit+Sight and their four tooltip descriptions.
- `Weapon Attachment Tooltip Cleaner` hides the original long horizontal `Можно закрепить на ...` row and redraws the exact compatible models vertically, one per line. It never mutates `MountOn`.

The package intentionally keeps the full repository structure and may contain repeated reports/instructions. This is deliberate for direct GitHub replacement/update.

See `ARCHITECTURE_SPLIT_RU.md`, `VALIDATION_SPLIT_3_MODS.txt`, `CURRENT_FIXES_AND_TESTS_RU.txt` and the per-mod reports.
