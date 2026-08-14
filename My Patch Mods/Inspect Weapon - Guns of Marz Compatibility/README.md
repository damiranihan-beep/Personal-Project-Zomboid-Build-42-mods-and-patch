# Inspect Weapon - Guns of Marz Compatibility — Fix 3 / 0.4.0

Target: Project Zomboid Build 42.20.2.

Fix 2 proved the display path stable: magazine ammo, runtime optics and non-standard Guns of Marz parts are now visible without the old crashing Stage 1 renderer. Fix 3 adapts the interaction path so removal is reversible and uses the current Gunworks rules.

## What Fix 3 changes

- Keeps RiskyInspectWeapon's native renderer and the verified live-magazine tooltip synchronization from Fix 2.
- Keeps runtime recovery through `HandWeapon:getAllWeaponParts()` for installed Guns of Marz parts.
- Empty GoM attachment slots now show compatible items that are actually in the player's inventory. There is no `getAllItems()` / global script-item scan.
- Direct Guns of Marz WeaponPart installation uses the current Gunworks-safe three-argument `ISUpgradeWeapon:new(character, weapon, part)` call. The old Inspect Weapon fourth numeric argument is not passed.
- Gunworks UniversalAttachment rails use their generic inventory item plus the registered weapon-specific outcome. This makes weapon-specific rails removable and reinstallable without inventing duplicate items.
- Detachable bayonets use Gunworks `ISBayonetAttach` / `ISBayonetRemove`, preserving the framework's knife↔WeaponPart conversion and condition handling.
- GoM removal now respects RequiredAttachment dependencies. A rail cannot be removed while an optic or another dependent attachment still needs it.
- Universal rails additionally respect Gunworks `CanRemoveInstalledPart`, including railing-mounted-child checks.
- Detachable GoM WeaponParts respect the screwdriver requirement. If the tool is missing, the candidate remains visible but is disabled with an explicit reason instead of the Inspect Weapon window silently doing nothing.
- Integrated/permanent parts remain protected.
- Custom labels have local fallbacks, so `RailUp`, `BayonetKnife` and raw `UI_GOMIW_*` keys should no longer leak into the window.
- Weapon stats, attachment stats, `MountOn`, ammunition data, condition and repair counters are not changed.

## Why reinstalling failed before

RiskyInspectWeapon was written for an older weapon-upgrade call and uses a fourth numeric argument (`50`) when installing. Current Gunworks uses argument #4 as a UniversalAttachment outcome full type. Fix 3 never sends that legacy numeric argument for a direct GoM install.

The original Inspect Weapon window also opens its attachment chooser only when a screwdriver is present. Fix 3 still enforces the tool rule, but shows the available candidate and the reason it is unavailable.

## Target checks

1. M1911 + PL-4: remove the optic; the empty Scope slot should offer PL-4 again. With no screwdriver it should be visible but unavailable; with a screwdriver it should reinstall.
2. M1911 + Colt Mount: remove the optic first, then the rail. The returned rail should be offered for reinstall.
3. Mossberg 590 + JS14 + top Picatinny rail: the rail must be blocked while JS14 depends on it; after removing JS14, the rail can be removed and the generic Picatinny item can be used to restore the weapon-specific top rail.
4. Trench Gun + M5 bayonet: label should be `Штык-нож`, with no raw `BayonetKnife` / `UI_GOMIW_PERMANENT`; removal and reinstallation must use the dedicated bayonet action.
5. Magazine tooltip should continue to match the icon count.

## Safety boundaries

- No replacement of RiskyInspectWeapon's main renderer.
- No global script item scan.
- No per-frame candidate database search.
- No direct detach/attach bypass for framework-managed rails or bayonets.
- No stat/balance changes.
