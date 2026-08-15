# Inspect Weapon - Guns of Marz Compatibility — Fix 4.1 / 0.6.0

Target: Project Zomboid Build 42.20.2.

Fix 4.1 keeps the model-aware Inspect Weapon integration from Fix 4 and adds three requested compatibility improvements: universal short firearm type labels, safe bulk attachment removal, and a Tidy Up Meister exclusion for inspection.

## What Fix 4.1 adds

- **`Снять все насадки`** is available from the normal inventory context menu for Guns of Marz firearms when at least one external attachment can be safely detached.
- The bulk action requires a working screwdriver. It never directly mutates weapon parts: bayonets use `ISBayonetRemove`, normal parts use `ISRemoveWeaponUpgrade`.
- Removal is planned **child first / parent second** from Gunworks `RequiredAttachment.Dependents` and `Railing.AcceptedAccessories`, so an optic/underbarrel child is removed before the rail or adapter it depends on.
- Permanent/integrated parts, internal animation parts, the magazine slot, and an active underbarrel attachment are not bulk-removed. If an unremovable child blocks a parent, that parent is left installed too.
- Individual Inspect Weapon removal now also respects Gunworks railing and active-underbarrel restrictions. Dedicated detachable bayonets are also screwdriver-gated at the timed-action level, so the rule applies to Inspect Weapon, Gunworks context-menu and radial-menu calls alike.
- Tidy Up Meister is registered to ignore `riskyInspectAction`; inspecting a weapon from the floor therefore does not arm its automatic return-to-origin cleanup.

## What Fix 4 changes

- The Inspect Weapon window no longer blindly shows Canon / Magazine / Recoil Pad / Scope / Sling / Stock on every Guns of Marz firearm.
- Direct slot capability is generated from the supplied Guns of Marz `WeaponPart MountOn` scripts. Gunworks UniversalAttachment outcomes, bayonet registrations and actually installed runtime parts are merged at runtime.
- A detachable magazine is shown as **Magazine**. Fixed/internal magazines are ammunition state and are not shown as a detachable attachment slot.
- Rails, muzzle adapters, underbarrel modules, stocks, bipods, bayonets and other model-supported PartTypes can appear even when the player currently owns no replacement part. The UI now describes the weapon model, not the contents of the inventory.
- Native unsupported hardcoded slots are hidden and removed from joypad navigation.
- Previous attachment tooltips are explicitly closed before every UI rebuild. Managed Guns of Marz attachment buttons do not open the old `ISToolTipInv` path inside Inspect Weapon, preventing stale red/mojibake tooltip text from surviving attachment changes.
- The live magazine proxy/count synchronization from Fix 2 remains.
- Direct GoM installs keep the modern three-argument `ISUpgradeWeapon` call. Universal rails keep their registered outcome type.
- Removal/installation still respects screwdriver requirements, RequiredAttachment dependencies, UniversalAttachment child checks, permanent/integrated parts and the dedicated Gunworks bayonet actions.
- Weapon/attachment stats, ammo, `MountOn`, condition and repair counters are not changed.

## Model examples from the supplied Guns of Marz scripts

- **Browning Hi-Power:** Canon, Magazine, muzzle adapter, top rail, optic, underbarrel. No fake Sling / Recoil Pad / Stock slots.
- **M92FS:** the same family plus its real Stock capability.
- **Mossberg 590:** top rail / optics (plus runtime Gunworks registrations). No detachable-magazine slot.
- **AR-15:** bipod, optic module, foregrip, lower/top rails and optic.

## Tool rule

Inspect Weapon is not an attachment cheat menu. In this private integration a working screwdriver is required for detachable Guns of Marz attachment operations, including the dedicated bayonet path. The bayonet timed actions are guarded too, preventing a context/radial shortcut around the tool requirement. Integrated bayonet fold/unfold remains a mode toggle and is not treated as installation/removal. Dependency/permanent rules are checked before the timed action is queued.

## Safety boundaries

- No global `getAllItems()` script scan.
- No direct manipulation of weapon attachment state.
- No bypass of Gunworks bayonet / universal rail systems.
- No balance/stat changes.
- The original RiskyInspectWeapon Workshop mod remains a required separate dependency.
