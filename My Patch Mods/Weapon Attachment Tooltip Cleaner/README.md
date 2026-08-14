# Weapon Attachment Tooltip Cleaner

UI-only compatibility/tooltip patch for Project Zomboid Build 42.20.2 + Guns of Marz.

Current version: **2.7.2**.

What v2.7.2 does:
- The custom compatibility list is blue, matched to the in-game `Mod: ...` source line; the native caption stays untouched.
- adds localized fallbacks for custom GoM WeaponPart type labels so raw keys such as `Tooltip_Weapon_LaserRifle` are not shown;
- keeps exactly one compatibility caption (`Можно прикрепить на`);
- suppresses only the native `MountOn` value during tooltip rendering;
- draws a deterministic short-model compatibility list below the caption with ` / ` separators;
- wraps long lists for smaller inventory windows;
- never builds the list from localized long weapon names, so no `M16A1 — штурмовая винтовка` spam and no Cyrillic concatenation mojibake;
- resolves Guns of Marz and GOM Attachment Rebalance tooltip localization keys at render time;
- preserves Show Weapon Stats Plus weapon stats;
- never permanently changes `MountOn`, attachment compatibility, item stats or gameplay data.

The mod is intentionally UI-only.
