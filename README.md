# Project Zomboid Build 42.20.2 — Personal Mod Repository

Актуальное состояние пользовательских модов и патчей после прохода **16.08.2026 / Fix 4.3**.

## Текущие версии

- **Guns of Marz Attachment Rebalance — 2.0.0** — утверждённый stock-based ребаланс поколений I–VII/U + редкость.
- **Weapon Attachment Tooltip Cleaner — 2.7.2 TEST** — UI-совместимость насадок без изменения игрового `MountOn`.
- **Russian Translation Collection for Mods — 4.5.2** — текущая коллекция переводов, включая RetroDashboard/Barricaded World/короткие inventory-типы GoM.
- **Homemade Suppressors for Guns of Marz — 3.17 TEST** — три самодельных глушителя + native B42 Crafting UI integration.
- **Guns of Marz Core Fixes — 1.1** — FNC stock + M24 integrated bipod permanent fixes.
- **Inspect Weapon - Guns of Marz Compatibility — 0.8.0 / Fix 4.3** — чистые модельные слоты, иконки, правильный MountOn, соседние инструменты, bulk detach/unload, context crash guard.
- **Weapon Reload Menu Cleaner — 1.1.0** — unified unload для не-GoM; GoM compact unload делегирован Inspect compatibility.
- **Realistic Combat — 3.8 TEST**, ID `RealisticCombat`.
- **Smoking Universal Patch — 1.4.4** — корректный выбор пачки из grouped stack + штатный SSO/vanilla path.

## Fix 4.3 — главное

### Inspect Weapon / Guns of Marz

- Убраны старые кракозябры и бессмысленные `Ничего` в блоке навесного оборудования. Пустой реальный слот показывает **`Нет насадки`** / **`Требуется совместимая насадка`**.
- Все slot labels полные и русские. Внутри Inspect Weapon также разворачиваются короткие suffix-типы самого оружия: `(пист.)` -> `(пистолет)`, `(ГВ)` -> `(гражданская винтовка)` и т.д. Обычный inventory list остаётся компактным.
- Пустой слот открывает **иконки совместимых деталей**; длинные текстовые `Добавить/Убрать насадку` для GoM удаляются из обычного ПКМ.
- Direct GoM attachments проходят реальную `MountOn`-проверку и в UI, и в timed action. `Beretta_Mount` больше не подходит AR-15; старое простое invalid rail-state может быть осторожно восстановлено.
- Отвёртка ищется в main inventory, сумках и **открытых доступных соседних контейнерах** и переносится автоматически.
- Detachable bayonet снова quick-release: **без отвёртки**. Integrated fold/deploy не подменяется.
- `Снять все насадки` работает с оружием из других ячеек; detached parts возвращаются в исходный контейнер оружия.
- Grouped stack раскрывается до реальных предметов: **`Снять насадки со всего оружия`** / **`Разрядить всё оружие`**.
- Разрядка использует только штатные B42 actions; chambered round не сбрасывается вручную и возвращается через `ISRackFirearm`.
- Добавлена защита от подтверждённого свежим логом конфликта **Gunworks `filterPermanentParts` -> `ISContextMenu.removeOptionByName` -> CleanUI**.

### Weapon Reload Menu Cleaner 1.1.0

- Для `MarzGuns.*` больше не добавляется второй длинный unload-submenu; остаются compact actions Fix 4.3.
- Для остального оружия прежнее единое меню сохранено.
- После удаления/перестановки options нормализуются B42 `id=1..N`, `numOptions=N+1`.

### Smoking Universal Patch 1.4.4

- В stack из нескольких `CigarettePack` выбирается реальная непустая пачка; приоритет — частично использованная.
- Действие идёт через vanilla `takePill`, поэтому SSO wrappers и штатный возврат/transfer path не дублируются.

### Homemade Suppressors 3.17

- Все 3 `craftRecipe` приведены к native B42 Crafting UI: `category = Weaponry`, `timedAction = Making`.
- Система избранного/сердечек остаётся штатной — собственный fake UI не рисуется.
- Альтернативные ингредиенты, инструменты, навыки и gameplay-баланс не переписывались.

## Рекомендуемый порядок загрузки

1. Hot Brass / Gunworks framework dependencies
2. Guns of Marz (`SWMG`, `MarzGuns`)
3. Guns of Marz Core Fixes 1.1
4. MarzGuns Sound Overhaul
5. Guns of Marz Attachment Rebalance 2.0.0
6. Homemade Suppressors for Guns of Marz 3.17 TEST
7. Inspect Weapon (`RiskyInspectWeapon`)
8. CleanUI / Picking Meister / Tidy Up Meister — если используются
9. Weapon Reload Menu Cleaner 1.1.0
10. Inspect Weapon - Guns of Marz Compatibility 0.8.0 / Fix 4.3
11. Banger's Retro Car Dashboard (`RetroDashboard`)
12. Russian Translation Collection 4.5.2 (`loadLast=on`)
13. Weapon Attachment Tooltip Cleaner 2.7.2 TEST (`loadLast=on` согласно текущей сборке)
14. Fancy Handwork / compatibility patch
15. Realistic Combat 3.8 TEST

`mod.info` Fix 4.3 дополнительно содержит `loadModAfter` для CleanUI / Picking / Tidy / WeaponReloadMenuCleaner, чтобы защитные wrappers ставились поздно.

## Обязательный runtime-тест

Полный чеклист: `Planning/FIX_4_3_TEST_CHECKLIST_RU.md`.

Особенно проверить:

- P226/AR-15: полные типы в Inspect, без кракозябр и raw slot keys;
- AR-15 не принимает Beretta rail;
- отвёртка работает из открытого соседнего ящика;
- штык снимается без отвёртки;
- 3 оружия в одном stack действительно обрабатываются bulk actions;
- detached parts возвращаются в исходный контейнер;
- chambered cartridge после `Разрядить` не исчезает;
- свежий лог не содержит `removeOptionByName -> filterPermanentParts -> CleanUI`;
- две пачки сигарет (full + partial) дают рабочее `Курить с пачки сигарет`;
- три suppressor-рецепта работают с Favorites нового Crafting UI.

## Структура репозитория

- `README.md` — текущее состояние.
- `CHANGELOG_RU.txt` — общий журнал.
- `My Mods/` — основные пользовательские моды.
- `My Patch Mods/` — compatibility/UI/rebalance патчи.
- `Planning/` — утверждённые таблицы + ТЗ/чеклист текущего прохода.
