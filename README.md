# Personal Project Zomboid Build 42 Mods and Patches

Target: **Project Zomboid Build 42.20.2**

## My Mods
- Russian Translation Collection for Mods — **v4.4.1** — consolidated Russian localization fixes.
- Homemade Suppressors for Guns of Marz — **Fix 3.15 TEST** — three homemade suppressors only; mechanics are the tested Fix 3.14 baseline, v3.15 changes tooltip text only.
- Realistic Combat — preserved unchanged from the repository history.

## My Patch Mods
- SmokingUniversalPatch — preserved unchanged.
- Guns of Marz Attachment Rebalance — **v1.0.1** — PL-4 / PS-1 / PM-2 / PRL-1 balance and only their matching descriptions.
- Weapon Attachment Tooltip Cleaner — **v2.1 TEST** — native GoM tooltip with short exact weapon models, exact magazine model compatibility and Russian GoM info/stat lines.

## Separation rule
- Suppressors own suppressor crafting, compatibility, balance, audio, wear/break behavior and suppressor tooltip text only.
- Attachment Rebalance owns modified optic numbers only.
- Weapon Attachment Tooltip Cleaner owns GoM attachment/magazine presentation only and restores all temporary render-time changes immediately.

## Current live-test focus
1. TR-1: `Информация` + Russian stats.
2. AA-12 / P226 / TEC-9 / STANAG magazines: native ammo/capacity rows stay; generic weapon classes are replaced by concrete model names.
3. Homemade suppressors: numeric stats are visible; broken plastic says only `Непригоден.`; broken metal suppressors show their actual penalties.
