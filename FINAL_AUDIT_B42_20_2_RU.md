# FINAL AUDIT — Project Zomboid Build 42.20.2

Date: 2026-08-14

## Package status

Five project mods were rebuilt from the last complete Fix 3.9 package and statically re-audited.

### Homemade Suppressors for Guns of Marz — Fix 3.10
- Working balance preserved: plastic -45% noise, can -55%, pipe -65%.
- Working damage/range/critical chance: -10%.
- Critical/last shot: -25/-35/-45% noise, other working penalties preserved.
- Broken can/pipe: +10% noise, -20% damage, -20% range, -10% crit chance, -20% crit damage.
- Plastic break: floor drop on current square with inventory fallback.
- Automatic-fire fail-safe now reasserts suppressed SwingSound on OnWeaponSwing, OnWeaponSwingHitPoint, OnPlayerUpdate and OnTick while a working/critical homemade suppressor is attached. The mod is also ordered after MarzGunsSoundOverhaul so our handlers register later.
- Exact compatibility provider restored from the Guns of Marz source-derived map.
- Four-tier handgun optic rebalance preserved: 1% / 3% / 6% / 10% to hit, crit and sight range.

### Weapon Attachment Tooltip Cleaner — v1.2
- Removed the broken ZZZ implementation that called setMountOn(nil).
- MountOn is never modified or cleared.
- Filters only the generic horizontal compatibility row.
- Exact compatible models are listed vertically without the redundant "Можно закрепить на:" header.
- Standard DoTooltip data stays present. A fallback restores magazine ammo-count/ammo-type rows only if they are missing.
- GoM custom tooltip lines are supplied by the provider and raw UI_* keys are re-resolved at render time.

### Russian Translation Collection — v4.4.0
- Target metadata unified to Build 42.20.2.
- Removed legacy Build-41 root media tree and old 41.x root mod.info.
- Fixed corrupted "ќтрезать рукава" -> "Отрезать рукава".
- Preserved existing escaped-percent strings unless runtime proved a key wrong; fixed Zoom and Rally Group Size Variance specifically.
- Translation remains translation-only; no duplicate Guns of Marz tooltip renderer is included.
- loadLast/load-after metadata preserved.

### Realistic Combat — Fix 3.4
- No gameplay rewrite in this pass because the latest log showed no new stack trace from its Lua.
- Unsafe AttackVars.clear is absent.
- Left-arm injury speed path and off-hand finisher suppression remain enabled.

### Smoking Universal Patch — v1.4.3
- No gameplay rewrite in this pass because the latest log showed no direct stack trace from the patch.
- "Курить с пачки сигарет" and lighter consolidation remain.
- No logic was added to return the pack/lighter to the original container; that remains the separate user mod.

## Static checks performed
- All JSON files parse.
- All text/Lua/JSON files decode as UTF-8.
- No U+FFFD replacement characters.
- No corrupted "ќтрезать" strings.
- No setMountOn(nil).
- No Java AttackVars :clear call.
- No duplicate ZZZ WATC Lua.
- No Base.Aluminum or Base.AluminumFragments in pipe suppressor recipe.
- Final mod metadata targets 42.20.2.
- ZIP CRC/integrity checked after packaging.

## Latest-log boundary
The latest console also contained one formatter warning for `AEBS_random_3`; that key is not present in any of these five project mods, so it is outside this package.
The same console contains ImportedSkeleton bone-name errors (`Body`, L85/SA80, MP5). They are not Lua stack traces from the five project scripts and are not uniquely attributable to Realistic Combat because Guns of Marz also ships custom X animation assets. They were not blindly modified in this package; animation changes still require an A/B live test.

## Still requires live confirmation
Static validation cannot prove audio/event order inside the running game. Verify:
1. sustained automatic fire with each homemade suppressor for several full bursts; no unsuppressed round should leak;
2. hover magazines, rails, scopes and homemade suppressors for 20-30 seconds; ERROR counter must not grow;
3. magazine ammo count/type remains visible;
4. only the generic horizontal MountOn row disappears; vertical exact models remain;
5. PL-4/PS-1/PM-2/PRL-1 show translated 1/3/6/10% stats;
6. broken plastic appears at the player's feet or falls back into inventory;
7. off-hand attack never selects a close-kill finisher.
