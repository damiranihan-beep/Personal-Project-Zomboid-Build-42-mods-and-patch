## Текущая версия: 2.8.0 / Fix 4.4

# Weapon Attachment Tooltip Cleaner

UI-only compatibility/tooltip patch for Project Zomboid Build 42.20.2 + Guns of Marz.

Current version: **2.8.0**.

What v2.8.0 does:
- полностью скрывает видимый блок `MountOn` / «Можно прикрепить/закрепить на» вместе со списком оружия;
- во время `WeaponPart:DoTooltip()` подставляет только валидный пустой `ArrayList`, а сразу после рендера восстанавливает **тот же исходный Java MountOn**;
- не перерисовывает никакой собственный compatibility list;
- сохраняет отдельные GoM information lines и Show Weapon Stats Plus;
- не меняет реальные `MountOn`, совместимость, характеристики, ID или игровые данные.

The mod is intentionally UI-only.
